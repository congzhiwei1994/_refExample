using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UME.UnitShaderGUIAttribute;

namespace UME {

    public partial class UnitMaterialEditor : ShaderGUI {

        public enum BlendOp {
            Add = 0,
            Subtract = 1,
            ReverseSubtract = 2,
            Min = 3,
            Max = 4,
        }

        public enum ZTest {
            Disabled,
            Never,
            Less,
            Equal,
            LEqual,
            Greater,
            NotEqual,
            GEqual,
            Always,
        }

        public enum RenderMode {
            Opaque = 0,
            Cutout,
            ColorKey,
            Transparent,
            Additive,
            SoftAdditive,
            Custom = 999,
        }

        public static readonly int[] BlendModeValues = ( int[] )Enum.GetValues( typeof( RenderMode ) );
        public static readonly int[] RenderQueueValues = ( int[] )Enum.GetValues( typeof( RenderQueue ) );
        public static readonly string[] BlendModeNames = Enum.GetNames( typeof( RenderMode ) );
        public static readonly string[] CullModeNames = Enum.GetNames( typeof( CullMode ) );

        static MaterialEditor s_curMaterialEditor = null;
        static UnitMaterialEditor s_curShaderGUI = null;
        static Material s_curMaterial = null;
        static Dictionary<Shader, Material> s_templateCache = new Dictionary<Shader, Material>();
        Material m_template = null;

        public static MaterialEditor curMaterialEditor {
            get {
                return s_curMaterialEditor;
            }
        }

        public static UnitMaterialEditor curShaderGUI {
            get {
                return s_curShaderGUI;
            }
        }

        public static Material curMaterial {
            get {
                return s_curMaterial;
            }
        }

        List<UnitMaterialEditor> m_props = new List<UnitMaterialEditor>();
        List<String> m_usedPropNames = null;
        protected MaterialEditor m_MaterialEditor = null;
        protected UnitMaterialEditor m_parent = null;
        protected int m_propIndex = -1;
        protected Vector2 m_uiSpace = new Vector2( 0, 0 );
        protected int m_indent = 0;
        protected String m_group = String.Empty;
        protected String m_id = String.Empty;
        protected JSONObject m_args = null;

        bool m_FirstTimeApply = true;
        bool m_userDefaultEditor = false;
        bool m_editorDirty = true;

        public struct PropEditorSettings {
            public String name;
            public UnitMaterialEditor parent;
            public MaterialProperty[] props;
        }

        static String LastShaderPath = String.Empty;
        static long LastShaderTime = 0;
        static JSONObject LastEditorData = null;

        struct EditorGroupRef {
            internal String shaderAssetPath;
            internal String group;
        }

        class EditorDataGroupNode {
            internal String groupName = null;
            internal String shaderPath = null;
            internal bool editorDataIsReady = false;
            internal List<STuple<JSONObject, EditorGroupRef>> editors = null;
        }

        class EditorDataTree {
            internal String shaderPath = null;
            internal String source = null;
            internal EditorData editorData = null;
            internal bool editorDataIsReady = false;
            internal List<EditorDataGroupNode> children = null;
        }

        class ShaderEditorDataSource {
            internal String path;
            internal long lastWriteTime;
            internal String source;
            internal List<String> includeShaders;
        }

        class EditorData {
            internal JSONObject raw = null;
            internal JSONObject data = null;
            internal EditorDataTree tree = null;
        }

        public static Regex Reg_EditorData = new Regex( @"#BEGINEDITOR((.|\n)+)#ENDEDITOR" );
        public static Regex Reg_LogicRef = new Regex( @"^\s*(!)?\s*\[(.+)\]$" );
        public static Regex Reg_IncludeFile = new Regex( @"\s*\[\s*\{\s*\""#include\""\s*:\s*\""(.+)\""\s*}\s*\]\s*," );
        public static Regex Reg_Command = new Regex( @"\s*\[\s*\{\s*\""#(\w+)\""\s*:\s*\""(.+)\""\s*}\s*\]\s*," );
        public static Regex Reg_MacroRefValue = new Regex( @"\$\(\s*(\w+)\s*\)" );

        protected const String DefaultGroupName = "[default]";
        protected const String AllGroupName = "[all]";
        protected static readonly Char[] GroupSpliters = new Char[] { ',', ';', '|' };
        protected static readonly Char[] DefineSpliters = new Char[] { '=', ':' };
        protected const String Macro_LastIncludeFile = "$(LAST_INCLUDE)";
        protected const String Preprocessor_include = "#include";
        protected const String Preprocessor_delete = "#delete";
        protected const String Preprocessor_define = "#define";
        protected const String Preprocessor_undef = "#undef";

        static Dictionary<String, Type> s_ShaderEditorTypeLut = new Dictionary<String, Type>();
        static Dictionary<String, Func<PropEditorSettings, UnitMaterialEditor>> s_ShaderPropGUIFactory = new Dictionary<String, Func<PropEditorSettings, UnitMaterialEditor>>();
        static Dictionary<String, ShaderEditorDataSource> s_ShaderEditorSourceCache = new Dictionary<String, ShaderEditorDataSource>();
        static Dictionary<String, bool> s_groupFoldoutState = new Dictionary<String, bool>();
        static Shader s_groupFoldoutStateForShader = null;

        static bool editorEnabled {
            get {
                return true;
            }
        }

        public MaterialEditor materialEditor {
            get {
                return m_MaterialEditor;
            }
        }

        public List<String> usedPropNames {
            get {
                return m_usedPropNames;
            }
        }

        public Material template {
            get {
                return m_template;
            }
        }

        public Material target {
            get {
                return m_MaterialEditor.target as Material;
            }
        }

        public Material[] targets {
            get {
                return Array.ConvertAll( m_MaterialEditor.targets, o => o as Material );
            }
        }

        public override String ToString() {
            var sb = new StringBuilder();
            var typename = GetType().Name;
            if ( typename.StartsWith( "ShaderGUI_" ) ) {
                typename = typename.Substring( "ShaderGUI_".Length );
            }
            sb.AppendFormat( "#{0}<{1}>", m_propIndex, typename );
            if ( !String.IsNullOrEmpty( m_id ) ) {
                sb.AppendFormat( ".[{0}]", m_id );
            }
            return sb.ToString();
        }

        public static void ResetEditor() {
            if ( s_groupFoldoutState != null ) {
                foreach ( var kv in s_groupFoldoutState ) {
                    s_groupFoldoutState[ kv.Key ] = true;
                }
            }
        }

        static UnitMaterialEditor() {
            var thisType = typeof( UnitMaterialEditor );
            var assembly = thisType.Assembly;
            var types = assembly.GetTypes();
            var prefix = "ShaderGUI_";
            for ( int i = 0; i < types.Length; ++i ) {
                var t = types[ i ];
                var name = t.Name;
                if ( name.StartsWith( prefix ) && t.IsSubclassOf( thisType ) ) {
                    name = name.Substring( prefix.Length );
                    var creator = t.GetMethod( "Create", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic );
                    if ( creator != null && creator.ReturnType == typeof( UnitMaterialEditor ) ) {
                        s_ShaderEditorTypeLut[ name ] = t;
                        s_ShaderPropGUIFactory[ name ] = s => {
                            return creator.Invoke( null, new object[] { s } ) as UnitMaterialEditor;
                        };
                    }
                }
            }
        }

        protected static bool IsEmptyShader( Shader shader ) {
            return shader == null ||
                shader.name == "Hidden/InternalErrorShader" ||
                shader.name == "Hidden/Built-in/InternalErrorShader";
        }

        protected static List<String> GetIncludeFiles( String shaderPath, out String editorData ) {
            List<String> files = null;
            var record = new HashSet<String>();
            _GetIncludeFiles( shaderPath, out editorData, record, ref files );
            return files;
        }

        protected static long GetShaderEditorDataLastWriteTime( String shaderPath, out String editorData ) {
            editorData = null;
            long last = 0;
            try {
                var files = GetIncludeFiles( shaderPath, out editorData );
                last = File.GetLastWriteTime( shaderPath ).ToFileTime();
                if ( files != null ) {
                    for ( int i = 0; i < files.Count; ++i ) {
                        var time = File.GetLastWriteTime( files[ i ] ).ToFileTime();
                        if ( time > last ) {
                            last = time;
                        }
                    }
                }
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            return last;
        }

        static bool _GetIncludeFiles( String shaderPath, out String editorData, HashSet<String> record, ref List<String> files ) {
            editorData = String.Empty;
            if ( String.IsNullOrEmpty( shaderPath ) ) {
                return false;
            }
            if ( !record.Add( shaderPath ) ) {
                return false;
            }
            if ( !File.Exists( shaderPath ) ) {
                return false;
            }
            var fileTime = File.GetLastWriteTime( shaderPath ).ToFileTime();
            ShaderEditorDataSource dataSource;
            if ( s_ShaderEditorSourceCache.TryGetValue( shaderPath, out dataSource ) ) {
                if ( dataSource.lastWriteTime != fileTime ) {
                    s_ShaderEditorSourceCache.Remove( shaderPath );
                } else {
                    editorData = dataSource.source;
                    if ( dataSource.includeShaders != null ) {
                        for ( int i = 0; i < dataSource.includeShaders.Count; ++i ) {
                            var include = dataSource.includeShaders[ i ];
                            var shader = SearchShader( include );
                            if ( shader != null ) {
                                var includeShaderPath = AssetDatabase.GetAssetPath( shader );
                                if ( !String.IsNullOrEmpty( includeShaderPath ) ) {
                                    String _editorData;
                                    if ( _GetIncludeFiles( includeShaderPath, out _editorData, record, ref files ) ) {
                                        files = files ?? new List<String>();
                                        if ( !files.Contains( includeShaderPath ) ) {
                                            files.Add( includeShaderPath );
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return true;
                }
            }

            dataSource = new ShaderEditorDataSource();
            dataSource.path = shaderPath;
            dataSource.lastWriteTime = fileTime;
            s_ShaderEditorSourceCache.Add( shaderPath, dataSource );
            Dictionary<String, String> defines = null;
            var source = File.ReadAllText( shaderPath );
            try {
                var m = Reg_EditorData.Match( source );
                var text = String.Empty;
                if ( m.Success && m.Groups.Count > 2 ) {
                    text = m.Groups[ 1 ].ToString();
                    if ( !String.IsNullOrEmpty( text ) ) {
                        editorData = text;
                        dataSource.source = editorData;
                        var lastIncludeShaderName = String.Empty;
                        var startIndex = 0;
                        var end = -1;
                        while ( startIndex < text.Length ) {
                            end = text.IndexOf( '\n', startIndex );
                            if ( end < 0 ) {
                                end = text.Length;
                                startIndex = text.Length;
                            }
                            if ( end > startIndex ) {
                                var tagIndex = text.IndexOf( Preprocessor_include, startIndex, end - startIndex );
                                if ( tagIndex >= 0 ) {
                                    var line = text.Substring( startIndex, end - startIndex );
                                    var n = Reg_IncludeFile.Match( line );
                                    if ( n.Success && n.Groups.Count > 1 ) {
                                        var include = n.Groups[ 1 ].ToString().Trim();
                                        var split = include.LastIndexOf( ':' );
                                        if ( split > 0 ) {
                                            include = include.Substring( 0, split ).Trim();
                                        }
                                        if ( include == Macro_LastIncludeFile && !String.IsNullOrEmpty( lastIncludeShaderName ) ) {
                                            include = lastIncludeShaderName;
                                        } else {
                                            var mm = Reg_MacroRefValue.Match( include );
                                            for (; ; ) {
                                                if ( m.Success && mm.Groups.Count > 1 ) {
                                                    var name = mm.Groups[ 1 ].Value;
                                                    String _value;
                                                    if ( defines != null && defines.TryGetValue( name, out _value ) ) {
                                                        include = _value;
                                                    } else {
                                                        Debug.LogErrorFormat( "unrecognized identifier '{0}'", name );
                                                    }
                                                }
                                                lastIncludeShaderName = include;
                                                break;
                                            }
                                        }
                                        dataSource.includeShaders = dataSource.includeShaders ?? new List<String>();
                                        if ( !dataSource.includeShaders.Contains( include ) ) {
                                            dataSource.includeShaders.Add( include );
                                        }
                                        var shader = SearchShader( include );
                                        if ( shader != null ) {
                                            var includeShaderPath = AssetDatabase.GetAssetPath( shader );
                                            if ( !String.IsNullOrEmpty( includeShaderPath ) ) {
                                                String _editorData;
                                                if ( _GetIncludeFiles( includeShaderPath, out _editorData, record, ref files ) ) {
                                                    files = files ?? new List<String>();
                                                    if ( !files.Contains( includeShaderPath ) ) {
                                                        files.Add( includeShaderPath );
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    tagIndex = text.IndexOf( "#", startIndex, end - startIndex );
                                    var line = text.Substring( startIndex, end - startIndex );
                                    var n = Reg_Command.Match( line );
                                    if ( n.Success && n.Groups.Count > 2 ) {
                                        var cmd = n.Groups[ 1 ].Value.Trim();
                                        var svalue = n.Groups[ 2 ].Value;
                                        if ( !String.IsNullOrEmpty( svalue ) ) {
                                            switch ( cmd ) {
                                            case "define": {
                                                    var split = svalue.IndexOfAny( DefineSpliters );
                                                    if ( split >= 0 ) {
                                                        var v = svalue.Substring( split + 1 ).Trim();
                                                        var name = svalue.Substring( 0, split ).Trim();
                                                        if ( defines != null ) {
                                                            if ( !defines.ContainsKey( name ) ) {
                                                                defines.Add( name, v );
                                                            }
                                                        } else {
                                                            defines = new Dictionary<String, String>();
                                                            defines.Add( name, v );
                                                        }
                                                    }
                                                }
                                                break;
                                            case "undef":
                                                if ( defines != null && !String.IsNullOrEmpty( svalue ) && !defines.Remove( svalue ) ) {
                                                    Debug.LogErrorFormat( "unrecognized identifier '{0}' for 'undef' command.", svalue );
                                                }
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            startIndex = end + 1;
                        }
                        return true;
                    }
                }
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            return false;
        }

        protected static Shader SearchShader( String pathOrGUID ) {
            var shader = Shader.Find( pathOrGUID );
            while ( shader == null ) {
                // 完整搜索
                var subs = pathOrGUID.Split( '|' );
                if ( subs.Length > 1 ) {
                    shader = AssetDatabase.LoadAssetAtPath<Shader>( subs[ 1 ].Trim() );
                    if ( shader != null ) {
                        break;
                    }
                }
                if ( subs.Length > 2 ) {
                    var p = AssetDatabase.GUIDToAssetPath( subs[ 2 ].Trim() );
                    if ( !String.IsNullOrEmpty( p ) ) {
                        shader = AssetDatabase.LoadAssetAtPath<Shader>( p );
                    }
                }
                break;
            }
            if ( shader == null && !String.IsNullOrEmpty( pathOrGUID ) ) {
                var filter = Path.GetFileNameWithoutExtension( pathOrGUID ) + " t:Shader";
                var assets = AssetDatabase.FindAssets( filter );
                for ( int i = 0; i < assets.Length; ++i ) {
                    var assetPath = AssetDatabase.GUIDToAssetPath( assets[ i ] );
                    if ( !String.IsNullOrEmpty( assetPath ) ) {
                        var _shader = AssetDatabase.LoadAssetAtPath<Shader>( assetPath );
                        if ( _shader == null || String.IsNullOrEmpty( _shader.name ) ) {
                            _shader = null;
                            var importer = AssetImporter.GetAtPath( assetPath ) as ShaderImporter;
                            if ( importer != null ) {
                                importer.SaveAndReimport();
                            }
                            _shader = AssetDatabase.LoadAssetAtPath<Shader>( assetPath );
                        }
                        if ( _shader != null && _shader.name == pathOrGUID ) {
                            shader = _shader;
                            break;
                        }
                    }
                }
                if ( shader == null ) {
                    Debug.LogErrorFormat( "Shader not found: '{0}'", pathOrGUID );
                }
            }
            return shader;
        }

        protected static String MakeShaderSearchKey( Shader shader ) {
            if ( IsEmptyShader( shader ) ) {
                return String.Empty;
            }
            var assetPath = AssetDatabase.GetAssetPath( shader );
            if ( !File.Exists( assetPath ) ) {
                return shader.name;
            }
            var guid = AssetDatabase.AssetPathToGUID( assetPath );
            return String.Format( "{0} | {1} | {2}", shader.name, assetPath, guid );
        }

        static EditorData GetEditorDataInternal( String shaderPath, String source, ref Dictionary<String, EditorDataTree> treeDict, String refGroup = null, Stack<String> stack = null ) {
            if ( !File.Exists( shaderPath ) ) {
                return null;
            }
            if ( refGroup != null && DefaultGroupName == refGroup ) {
                refGroup = String.Empty;
            }
            stack = stack ?? new Stack<String>();
            EditorData editorData = null;
            var lastIncludeShaderName = String.Empty;
            for (; ; ) {
                EditorDataTree tree;
                EditorDataTree curTree;
                treeDict = treeDict ?? new Dictionary<String, EditorDataTree>();
                if ( !treeDict.TryGetValue( shaderPath, out tree ) ) {
                    JSONObject raw = null;
                    try {
                        if ( String.IsNullOrEmpty( source ) ) {
                            // 从文件里重新读
                            var text = File.ReadAllText( shaderPath );
                            var m = Reg_EditorData.Match( text );
                            if ( m.Success && m.Groups.Count > 2 ) {
                                source = m.Groups[ 1 ].ToString();
                            }
                        }
                        if ( String.IsNullOrEmpty( source ) ) {
                            break;
                        }
                        raw = JSONObject.Create( source );
                    } catch ( Exception e ) {
                        Debug.LogException( e );
                    }
                    if ( raw == null ) {
                        break;
                    }
                    tree = new EditorDataTree();
                    treeDict.Add( shaderPath, tree );
                    editorData = new EditorData();
                    editorData.raw = raw;
                    editorData.data = raw;
                    editorData.tree = tree;
                    tree.editorData = editorData;
                    tree.shaderPath = shaderPath;
                    tree.source = source;
                    tree.children = new List<EditorDataGroupNode>();
                    tree.children.Add(
                        new EditorDataGroupNode {
                            groupName = DefaultGroupName,
                            shaderPath = shaderPath,
                        }
                    );
                    var curGroupName = DefaultGroupName;
                    var curGroup = tree.children[ 0 ];
                    Dictionary<String, String> defines = null;
                    Action<String> updateGroupFunc = groupName => {
                        if ( !String.IsNullOrEmpty( groupName ) && groupName != curGroupName ) {
                            if ( !groupName.EndsWith( " end", StringComparison.CurrentCultureIgnoreCase ) ) {
                                curGroupName = groupName;
                                curGroup = tree.children.Find( e => e.groupName == curGroupName );
                                if ( curGroup == null ) {
                                    curGroup = new EditorDataGroupNode();
                                    curGroup.groupName = curGroupName;
                                    curGroup.shaderPath = shaderPath;
                                    tree.children.Add( curGroup );
                                }
                            } else {
                                curGroupName = DefaultGroupName;
                                curGroup = tree.children[ 0 ];
                            }
                        }
                    };
                    for ( int i = 0; i < raw.list.Count; ++i ) {
                        var o = raw.list[ i ];
                        if ( o.IsArray && o.Count > 0 ) {
                            var attr = o.list[ 0 ];
                            // 预处理器标记用数组存储
                            if ( attr.IsString ) {
                                // 获取当前编辑器分组信息
                                updateGroupFunc( attr.str );
                            } else if ( attr.IsObject && attr.HasField( Preprocessor_include ) ) {
                                var pathObj = attr.GetField( Preprocessor_include );
                                if ( pathObj.IsString ) {
                                    var path = pathObj.str;
                                    if ( !String.IsNullOrEmpty( path ) ) {
                                        var split = path.LastIndexOf( ':' );
                                        var group = DefaultGroupName;
                                        if ( split > 0 ) {
                                            group = path.Substring( split + 1 ).Trim();
                                            path = path.Substring( 0, split ).Trim();
                                        }
                                        if ( path == Macro_LastIncludeFile && !String.IsNullOrEmpty( lastIncludeShaderName ) ) {
                                            path = lastIncludeShaderName;
                                        } else {
                                            var m = Reg_MacroRefValue.Match( path );
                                            for ( ; ; ) {
                                                if ( m.Success && m.Groups.Count > 1 ) {
                                                    var name = m.Groups[ 1 ].Value;
                                                    String value;
                                                    if ( defines != null && defines.TryGetValue( name, out value ) ) {
                                                        path = value;
                                                    } else {
                                                        Debug.LogErrorFormat( "unrecognized identifier {0}", name );
                                                    }
                                                }
                                                lastIncludeShaderName = path;
                                                break;
                                            }
                                        }
                                        var shader = SearchShader( path );
                                        if ( shader != null ) {
                                            var includeShaderAssetPath = AssetDatabase.GetAssetPath( shader );
                                            Debug.Assert( !String.IsNullOrEmpty( includeShaderAssetPath ) );
                                            if ( String.IsNullOrEmpty( includeShaderAssetPath ) ) {
                                                continue;
                                            }
                                            updateGroupFunc( group );
                                            curGroup.editors = curGroup.editors ?? new List<STuple<JSONObject, EditorGroupRef>>();
                                            curGroup.editors.Add(
                                                STuple.Create<JSONObject, EditorGroupRef>( null,
                                                    new EditorGroupRef {
                                                        shaderAssetPath = includeShaderAssetPath,
                                                        group = group
                                                    }
                                                )
                                            );
                                        }
                                    }
                                }
                            } else if ( attr.IsObject && attr.HasField( Preprocessor_delete ) ) {
                                var list = attr.GetField( Preprocessor_delete );
                                if ( list.IsArray && list.Count > 0 ) {
                                    curGroup.editors = curGroup.editors ?? new List<STuple<JSONObject, EditorGroupRef>>();
                                    curGroup.editors.Add( STuple.Create<JSONObject, EditorGroupRef>( attr, new EditorGroupRef() ) );
                                }
                            } else if ( attr.IsObject && attr.HasField( Preprocessor_define ) ) {
                                String str;
                                if ( attr.GetField( out str, Preprocessor_define, String.Empty ) ) {
                                    var split = str.IndexOfAny( DefineSpliters );
                                    if ( split >= 0 ) {
                                        var value = str.Substring( split + 1 ).Trim();
                                        var name = str.Substring( 0, split ).Trim();
                                        if ( defines != null ) {
                                            if ( !defines.ContainsKey( name ) ) {
                                                defines.Add( name, value );
                                            }
                                        } else {
                                            defines = new Dictionary<String, String>();
                                            defines.Add( name, value );
                                        }
                                    }
                                }
                            } else if ( defines != null && attr.IsObject && attr.HasField( Preprocessor_undef ) ) {
                                String name;
                                if ( attr.GetField( out name, Preprocessor_undef, String.Empty ) ) {
                                    if ( !defines.Remove( name ) ) {
                                        Debug.LogErrorFormat( "unrecognized identifier '{0}' for 'undef' command.", name );
                                    }
                                }
                            }
                        }
                        if ( o.IsObject && o.HasField( Cfg.Key_Editor ) ) {
                            curGroup.editors = curGroup.editors ?? new List<STuple<JSONObject, EditorGroupRef>>();
                            curGroup.editors.Add( STuple.Create( o, new EditorGroupRef() ) );
                        }
                    }
                } else {
                    editorData = tree.editorData;
                }
                if ( tree.editorDataIsReady ) {
                    break;
                }
                // 处理包含文件
                curTree = tree;
                for ( int i = 0; i < tree.children.Count; ++i ) {
                    var group = tree.children[ i ];
                    if ( !String.IsNullOrEmpty( refGroup ) && refGroup != group.groupName ) {
                        continue;
                    }
                    if ( group.editors == null ) {
                        group.editorDataIsReady = true;
                        continue;
                    }
                    if ( group.editors != null && !group.editorDataIsReady ) {
                        for ( int j = 0; j < group.editors.Count; ++j ) {
                            var e = group.editors[ j ];
                            if ( e.Item1 == null && !String.IsNullOrEmpty( e.Item2.shaderAssetPath ) ) {
                                var includePath = e.Item2.shaderAssetPath;
                                var includeGroups = e.Item2.group.Split( GroupSpliters );
                                foreach ( var ig in includeGroups ) {
                                    var includeGroup = ig.Trim();
                                    String stackCheckKey;
                                    if ( includeGroup != DefaultGroupName ) {
                                        stackCheckKey = String.Format( "{0} : {1}", includePath, includeGroup );
                                    } else {
                                        stackCheckKey = includePath;
                                    }
                                    if ( stack.Contains( stackCheckKey ) ) {
                                        // 循环依赖
                                        Debug.LogErrorFormat( "Cat not include itself: {0}", shaderPath );
                                        foreach ( var v in stack ) {
                                            Debug.LogError( v );
                                        }
                                        continue;
                                    }
                                    stack.Push( stackCheckKey );
                                    var ed = GetEditorDataInternal( includePath, null, ref treeDict, includeGroup, stack );
                                    var cur = stack.Pop();
                                    Debug.Assert( cur == stackCheckKey );
                                    if ( ed != null ) {
                                        if ( includeGroup != DefaultGroupName ) {
                                            // 包含指定组
                                            var refEditors = ed.tree.children.Find( g => g.groupName == includeGroup );
                                            if ( refEditors != null ) {
                                                Debug.Assert( refEditors.editorDataIsReady );
                                                group.editors.RemoveAt( j );
                                                group.editors.InsertRange( j, refEditors.editors );
                                                j += refEditors.editors.Count - 1;
                                            } else {
                                                group.editors.RemoveAt( j-- );
                                                Debug.LogErrorFormat( "UnitMaterialEditor include file group not found! {0} : {1}", includePath, includeGroup );
                                            }
                                        } else {
                                            // 包含所有组，包括默认分组
                                            Debug.Assert( ed.tree.editorDataIsReady );
                                            group.editors.RemoveAt( j );
                                            var insertCount = 0;
                                            var insertStartPos = j;
                                            // 为了插入操作保证顺序而使用反向遍历
                                            for ( int g = ed.tree.children.Count - 1; g >= 0; --g ) {
                                                var refEditors = ed.tree.children[ g ];
                                                Debug.Assert( refEditors.editorDataIsReady );
                                                if ( refEditors.editors != null && refEditors.editors.Count > 0 ) {
                                                    var addGroup = refEditors.groupName;
                                                    var addTarget = tree.children.Find( _g => _g.groupName == addGroup );
                                                    if ( addTarget == null ) {
                                                        // 当需要追加的分组不存在，新增一个完整组
                                                        var newGroup = new EditorDataGroupNode();
                                                        // 新增加的分组插入到当前子节点下面，保证优先级顺序
                                                        // 由于采用了插入操作，所以上面采用了反向遍历
                                                        if ( i + 1 < tree.children.Count ) {
                                                            tree.children.Insert( i + 1, newGroup );
                                                        } else {
                                                            tree.children.Add( newGroup );
                                                        }
                                                        newGroup.groupName = addGroup;
                                                        newGroup.editorDataIsReady = true;
                                                        newGroup.shaderPath = shaderPath;
                                                        newGroup.editors = new List<STuple<JSONObject, EditorGroupRef>>( refEditors.editors );
                                                    } else {
                                                        // 分组已经存在，不能新建，把包含编辑器包含进当前分组
                                                        if ( addTarget.editors == null ) {
                                                            addTarget.editors = new List<STuple<JSONObject, EditorGroupRef>>();
                                                        }
                                                        Debug.Assert( insertStartPos <= addTarget.editors.Count );
                                                        addTarget.editors.InsertRange( insertStartPos, refEditors.editors );
                                                        insertCount += refEditors.editors.Count;
                                                        insertStartPos += refEditors.editors.Count;
                                                    }
                                                }
                                            }
                                            j += insertCount - 1;
                                        }
                                    } else {
                                        Debug.LogErrorFormat( "UnitMaterialEditor include file not found! {0} : {1}", includePath );
                                    }
                                }
                            }
                        }
                        if ( group.editors != null ) {
                            // 去重以及排除指定编辑器
                            List<KeyValuePair<String, String>> removeCmds = null;
                            for ( int j = group.editors.Count - 1; j > 0; --j ) {
                                var e = group.editors[ j ].Item1;
                                if ( e.HasField( Preprocessor_delete ) ) {
                                    var list = e.GetField( Preprocessor_delete );
                                    if ( list != null && list.IsArray && list.Count > 0 ) {
                                        for ( int k = 0; k < list.Count; ++k ) {
                                            var kv = list[ k ];
                                            if ( kv.IsArray ) {
                                                removeCmds = removeCmds ?? new List<KeyValuePair<String, String>>();
                                                var removeType = ( kv.Count > 1 && kv[ 1 ].IsString ) ? kv[ 1 ].str : String.Empty;
                                                removeCmds.Add( new KeyValuePair<String, String>( kv[ 0 ].str, removeType ) );
                                            }
                                        }
                                    }
                                    group.editors.RemoveAt( j );
                                    continue;
                                }

                                String type, id;
                                if ( e.GetField( out type, Cfg.Key_Editor, String.Empty ) ) {
                                    // 检查编辑器类定义是否含有允许多个的定义
                                    Type editorType;
                                    if ( s_ShaderEditorTypeLut.TryGetValue( type, out editorType ) ) {
                                        if ( editorType.GetCustomAttributes( typeof( AllowMultipleAttribute ), true ).Length > 0 ) {
                                            continue;
                                        }
                                    }
                                }
                                if ( !e.GetField( out id, Cfg.Key_ID, String.Empty ) ) {
                                    if ( e.HasField( Cfg.Key_Args ) ) {
                                        var args = e.GetField( Cfg.Key_Args );
                                        if ( args != null && args.IsObject ) {
                                            args.GetField( out id, Cfg.Key_Name, String.Empty );
                                        }
                                    }
                                }
                                var firstIndex = group.editors.FindIndex(
                                    item => {
                                        var _e = item.Item1;
                                        String _type, _id;
                                        _e.GetField( out _type, Cfg.Key_Editor, String.Empty );
                                        if ( !_e.GetField( out _id, Cfg.Key_ID, String.Empty ) ) {
                                            if ( _e.HasField( Cfg.Key_Args ) ) {
                                                var _args = _e.GetField( Cfg.Key_Args );
                                                if ( _args != null && _args.IsObject ) {
                                                    _args.GetField( out _id, Cfg.Key_Name, String.Empty );
                                                }
                                            }
                                        }
                                        if ( _id == id && _type == type ) {
                                            return true;
                                        }
                                        return false;
                                    }
                                );
                                Debug.Assert( firstIndex >= 0 );
                                if ( firstIndex != j ) {
                                    // 覆盖
                                    Debug.Assert( j > firstIndex );
                                    group.editors[ firstIndex ] = group.editors[ j ];
                                    group.editors.RemoveAt( j );
                                }
                            }
                            if ( removeCmds != null ) {
                                for ( int j = 0; j < removeCmds.Count; ++j ) {
                                    var id = removeCmds[ j ].Key;
                                    var type = removeCmds[ j ].Value;
                                    var removeCount = group.editors.RemoveAll(
                                        item => {
                                            var _e = item.Item1;
                                            String _type, _id;
                                            _e.GetField( out _type, Cfg.Key_Editor, String.Empty );
                                            if ( !_e.GetField( out _id, Cfg.Key_ID, String.Empty ) ) {
                                                if ( _e.HasField( Cfg.Key_Args ) ) {
                                                    var _args = _e.GetField( Cfg.Key_Args );
                                                    if ( _args != null && _args.IsObject ) {
                                                        _args.GetField( out _id, Cfg.Key_Name, String.Empty );
                                                    }
                                                }
                                            }
                                            if ( _id == id && ( String.IsNullOrEmpty( type ) || _type == type ) ) {
                                                return true;
                                            }
                                            return false;
                                        }
                                    );
                                    if ( removeCount == 0 ) {
                                        Debug.LogErrorFormat( "remove editor[{0}] failed: id = '{1}', type = '{2}'", group.groupName, id, type );
                                    }
                                }
                            }
                        }
                        group.editorDataIsReady = true;
                    }
                }
                var done = true;
                for ( int i = 0; i < tree.children.Count; ++i ) {
                    var group = tree.children[ i ];
                    if ( group.editors == null ) {
                        continue;
                    }
                    if ( !group.editorDataIsReady ) {
                        done = false;
                        break;
                    }
                }
                if ( done ) {
                    tree.editorDataIsReady = done;
                    editorData.data = new JSONObject( JSONObject.Type.ARRAY );
                    for ( int i = 0; i < tree.children.Count; ++i ) {
                        var group = tree.children[ i ];
                        if ( group.editors == null ) {
                            continue;
                        }
                        var groupInfo = new JSONObject( JSONObject.Type.ARRAY );
                        groupInfo.Add( group.groupName );
                        editorData.data.list.Add( groupInfo );
                        Debug.Assert( group.editorDataIsReady );
                        for ( int j = 0; j < group.editors.Count; ++j ) {
                            var e = group.editors[ j ];
                            Debug.Assert( String.IsNullOrEmpty( e.Item2.shaderAssetPath ) );
                            editorData.data.list.Add( e.Item1 );
                        }
                    }
                }
                break;
            }
            return editorData;
        }

        static JSONObject GetEditorData( String shaderPath, ref bool dirty ) {
            if ( !File.Exists( shaderPath ) ) {
                return null;
            }
            var source = String.Empty;
            var lastTime = GetShaderEditorDataLastWriteTime( shaderPath, out source );
            if ( lastTime == 0 ) {
                return null;
            }
            if ( LastEditorData == null ||
                LastShaderPath != shaderPath ||
                LastShaderTime != lastTime ) {
                LastShaderTime = lastTime;
                LastShaderPath = shaderPath;
                dirty = true;
                Dictionary<String, EditorDataTree> treeDict = null;
                var stack = new Stack<String>();
                EditorData editorData = null;
                try {
                    stack.Push( shaderPath );
                    editorData = GetEditorDataInternal( shaderPath, source, ref treeDict, null, stack );
                } finally {
                    var cur = stack.Pop();
                    Debug.Assert( stack.Count == 0 && cur == shaderPath );
                }
                if ( editorData != null && editorData.data != null ) {
                    LastEditorData = editorData.data;
                } else {
                    LastEditorData = new JSONObject();
                }
            }
            return LastEditorData;
        }
        
        internal MaterialProperty FindCachedProperty( String propertyName, MaterialProperty[] properties ) {
            MaterialProperty prop = null;
            try {
                prop = ShaderGUI.FindProperty( propertyName, properties );
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            if ( prop != null ) {
                m_usedPropNames = m_usedPropNames ?? new List<String>();
                if ( !m_usedPropNames.Contains( propertyName ) ) {
                    m_usedPropNames.Add( propertyName );
                }
            }
            return prop;
        }

        internal MaterialProperty FindCachedProperty( String propertyName, MaterialProperty[] properties, bool propertyIsMandatory ) {
            var prop = ShaderGUI.FindProperty( propertyName, properties, propertyIsMandatory );
            if ( prop != null ) {
                m_usedPropNames = m_usedPropNames ?? new List<String>();
                if ( !m_usedPropNames.Contains( propertyName ) ) {
                    m_usedPropNames.Add( propertyName );
                }
            }
            return prop;
        }

        protected static ShaderUtil.ShaderPropertyType? FindShaderPropertyType( Shader shader, String name, ShaderUtil.ShaderPropertyType? type = null ) {
            var c = ShaderUtil.GetPropertyCount( shader );
            for ( int i = 0; i < c; ++i ) {
                var _type = ShaderUtil.GetPropertyType( shader, i );
                if ( !String.IsNullOrEmpty( name ) && name == ShaderUtil.GetPropertyName( shader, i ) &&
                    ( type == null || type.Value == ShaderUtil.GetPropertyType( shader, i ) ) ) {
                    return ShaderUtil.GetPropertyType( shader, i );
                }
            }
            return null;
        }

        protected static int FindShaderPropertyIndex( Shader shader, String name,
            ShaderUtil.ShaderPropertyType? typeA = null,
            ShaderUtil.ShaderPropertyType? typeB = null ) {
            if ( shader != null ) {
                var propCount = ShaderUtil.GetPropertyCount( shader );
                for ( int i = 0; i < propCount; ++i ) {
                    var _name = ShaderUtil.GetPropertyName( shader, i );
                    if ( !String.IsNullOrEmpty( name ) && _name != name ) {
                        continue;
                    }
                    var type = ShaderUtil.GetPropertyType( shader, i );
                    var _typeA = typeA;
                    var _typeB = typeB;
                    if ( _typeA == null ) {
                        _typeA = type;
                    }
                    if ( _typeB == null ) {
                        _typeB = type;
                    }
                    if ( type == _typeA.Value || type == _typeB.Value ) {
                        return i;
                    }
                }
            }
            return -1;
        }

        public static bool RemoveEmptyProps( Material m ) {
            var mod = 0;
            using ( var so = new SerializedObject( m ) ) {
                var envs_array = so.FindProperty( "m_SavedProperties.m_TexEnvs.Array" );
                var envs_size = so.FindProperty( "m_SavedProperties.m_TexEnvs.Array.size" );
                if ( envs_size != null && envs_array != null ) {
                    var size = envs_size.intValue;
                    for ( int i = 0; i < size; ) {
                        var envNamePropPath = String.Format( "data[{0}].first", i );
                        var envNameProp = envs_array.FindPropertyRelative( envNamePropPath );
                        var texValuePropPath = String.Format( "data[{0}].second.m_Texture", i );
                        var texValueProp = envs_array.FindPropertyRelative( texValuePropPath );
                        if ( texValueProp != null && envNameProp != null ) {
                            var envName = envNameProp.stringValue;
                            if ( !m.HasProperty( envName ) ||
                                FindShaderPropertyIndex( m.shader, envName, ShaderUtil.ShaderPropertyType.TexEnv ) == -1 ) {
                                Debug.LogWarningFormat( "{0} = null, will be removed.", envName );
                                envs_array.DeleteArrayElementAtIndex( i );
                                --size;
                                ++mod;
                                continue;
                            }
                        }
                        ++i;
                    }
                }
                var floats_array = so.FindProperty( "m_SavedProperties.m_Floats.Array" );
                var floats_size = so.FindProperty( "m_SavedProperties.m_Floats.Array.size" );
                if ( floats_array != null && floats_size != null ) {
                    var size = floats_size.intValue;
                    for ( int i = 0; i < size; ) {
                        var namePropPath = String.Format( "data[{0}].first", i );
                        var nameProp = floats_array.FindPropertyRelative( namePropPath );
                        var valuePropPath = String.Format( "data[{0}].second", i );
                        var valueProp = floats_array.FindPropertyRelative( valuePropPath );
                        if ( valueProp != null && nameProp != null ) {
                            var name = nameProp.stringValue;
                            if ( !m.HasProperty( name ) ||
                                FindShaderPropertyIndex( m.shader, name,
                                    ShaderUtil.ShaderPropertyType.Float,
                                    ShaderUtil.ShaderPropertyType.Range ) == -1 ) {
                                Debug.LogWarningFormat( "{0} = null, will be removed.", name );
                                floats_array.DeleteArrayElementAtIndex( i );
                                --size;
                                ++mod;
                                continue;
                            }
                        }
                        ++i;
                    }
                }
                var colors_array = so.FindProperty( "m_SavedProperties.m_Colors.Array" );
                var colors_size = so.FindProperty( "m_SavedProperties.m_Colors.Array.size" );
                if ( colors_array != null && colors_size != null ) {
                    var size = colors_size.intValue;
                    for ( int i = 0; i < size; ) {
                        var namePropPath = String.Format( "data[{0}].first", i );
                        var nameProp = colors_array.FindPropertyRelative( namePropPath );
                        var valuePropPath = String.Format( "data[{0}].second", i );
                        var valueProp = colors_array.FindPropertyRelative( valuePropPath );
                        if ( valueProp != null && nameProp != null ) {
                            var name = nameProp.stringValue;
                            if ( !m.HasProperty( name ) ||
                                FindShaderPropertyIndex( m.shader, name,
                                    ShaderUtil.ShaderPropertyType.Color,
                                    ShaderUtil.ShaderPropertyType.Vector ) == -1 ) {
                                Debug.LogWarningFormat( "{0} = null, will be removed.", name );
                                colors_array.DeleteArrayElementAtIndex( i );
                                --size;
                                ++mod;
                                continue;
                            }
                        }
                        ++i;
                    }
                }
                if ( mod > 0 ) {
                    so.ApplyModifiedProperties();
                    EditorUtility.SetDirty( m );
                    return true;
                }
            }
            return false;
        }

        public static object FindPropValueFromMaterial( Material m, String name, MaterialProperty.PropType type ) {
            object retval = null;
            if ( !m.HasProperty( name ) || m.shader == null ) {
                using ( var so = new SerializedObject( m ) ) {
                    if ( type == MaterialProperty.PropType.Texture ) {
                        var envs_array = so.FindProperty( "m_SavedProperties.m_TexEnvs.Array" );
                        var envs_size = so.FindProperty( "m_SavedProperties.m_TexEnvs.Array.size" );
                        if ( envs_size != null && envs_array != null ) {
                            var size = envs_size.intValue;
                            for ( int i = 0; i < size; ) {
                                var envNamePropPath = String.Format( "data[{0}].first", i );
                                var envNameProp = envs_array.FindPropertyRelative( envNamePropPath );
                                var texValuePropPath = String.Format( "data[{0}].second.m_Texture", i );
                                var texValueProp = envs_array.FindPropertyRelative( texValuePropPath );
                                if ( texValueProp != null && envNameProp != null ) {
                                    var envName = envNameProp.stringValue;
                                    if ( envName == name ) {
                                        retval = texValueProp.objectReferenceValue;
                                        break;
                                    }
                                }
                                ++i;
                            }
                        }
                    } else if ( type == MaterialProperty.PropType.Range || type == MaterialProperty.PropType.Float ) {
                        var floats_array = so.FindProperty( "m_SavedProperties.m_Floats.Array" );
                        var floats_size = so.FindProperty( "m_SavedProperties.m_Floats.Array.size" );
                        if ( floats_array != null && floats_size != null ) {
                            var size = floats_size.intValue;
                            for ( int i = 0; i < size; ) {
                                var namePropPath = String.Format( "data[{0}].first", i );
                                var nameProp = floats_array.FindPropertyRelative( namePropPath );
                                if (  nameProp != null ) {
                                    var propName = nameProp.stringValue;
                                    if ( propName == name ) {
                                        var valuePropPath = String.Format( "data[{0}].second", i );
                                        var valueProp = floats_array.FindPropertyRelative( valuePropPath );
                                        if ( valueProp != null ) {
                                            retval = valueProp.floatValue;
                                            break;
                                        }
                                    }
                                }
                                ++i;
                            }
                        }
                    } else if ( type == MaterialProperty.PropType.Color || type == MaterialProperty.PropType.Vector ) {
                        var colors_array = so.FindProperty( "m_SavedProperties.m_Colors.Array" );
                        var colors_size = so.FindProperty( "m_SavedProperties.m_Colors.Array.size" );
                        if ( colors_array != null && colors_size != null ) {
                            var size = colors_size.intValue;
                            for ( int i = 0; i < size; ) {
                                var namePropPath = String.Format( "data[{0}].first", i );
                                var nameProp = colors_array.FindPropertyRelative( namePropPath );
                                if ( nameProp != null ) {
                                    var propName = nameProp.stringValue;
                                    if ( propName == name ) {
                                        var valuePropPath = String.Format( "data[{0}].second", i );
                                        var valueProp = colors_array.FindPropertyRelative( valuePropPath );
                                        if ( valueProp != null ) {
                                            retval = valueProp.colorValue;
                                            break;
                                        }
                                    }
                                }
                                ++i;
                            }
                        }
                    }
                }
            } else {
                var index = FindShaderPropertyIndex( m.shader, name );
                if ( index >= 0 ) {
                    switch ( ShaderUtil.GetPropertyType( m.shader, index ) ) {
                    case ShaderUtil.ShaderPropertyType.Color:
                        retval = m.GetColor( name );
                        break;
                    case ShaderUtil.ShaderPropertyType.Float:
                        retval = m.GetFloat( name );
                        break;
                    case ShaderUtil.ShaderPropertyType.Range:
                        retval = m.GetFloat( name );
                        break;
                    case ShaderUtil.ShaderPropertyType.TexEnv:
                        retval = m.GetTexture( name );
                        break;
                    case ShaderUtil.ShaderPropertyType.Vector:
                        retval = m.GetVector( name );
                        break;
                    }
                }
            }
            return retval;
        }

        public static void AssignNewShader( Material material, Shader oldShader, Shader newShader ) {
            Color tintColor = new Color( 128, 128, 128, 255 );
            Color color = new Color( 255, 255, 255, 255 );
            Color? _TintColor_2_Color = null;
            Color? _Color_2_Color = null;
            if ( material.HasProperty( "_TintColor" ) ) {
                tintColor = material.GetColor( "_TintColor" );
                if ( FindShaderPropertyType( newShader, "_TintColor", ShaderUtil.ShaderPropertyType.Color ) == null ) {
                    var dstIndex = FindShaderPropertyIndex( newShader, "_Color", ShaderUtil.ShaderPropertyType.Color );
                    if ( dstIndex != -1 ) {
                        var desc = ShaderUtil.GetPropertyDescription( newShader, dstIndex );
                        if ( !desc.Equals( "Tint Color" ) ) {
                            // _TintColor => _Color as MainColor
                            _TintColor_2_Color = new Color(
                                tintColor.r * 0.5f,
                                tintColor.g * 0.5f,
                                tintColor.b * 0.5f,
                                tintColor.a
                             );
                        } else {
                            // _TintColor => _Color as TintColor
                            tintColor.a = Mathf.Clamp01( tintColor.a * 2 );
                            _TintColor_2_Color = tintColor;
                        }
                    }
                }
            } else {
                var _Debug_DisableTintColor = Shader.GetGlobalInt( "_Debug_DisableTintColor" );
                var srcPropIndex = FindShaderPropertyIndex( oldShader, "_Color", ShaderUtil.ShaderPropertyType.Color );
                var dstPropIndex = FindShaderPropertyIndex( newShader, "_Color", ShaderUtil.ShaderPropertyType.Color );
                if ( srcPropIndex != -1 && dstPropIndex != -1 ) {
                    var srcDesc = ShaderUtil.GetPropertyDescription( oldShader, srcPropIndex ).Trim();
                    var dstDesc = ShaderUtil.GetPropertyDescription( newShader, dstPropIndex ).Trim();
                    if ( srcDesc != dstDesc && _Debug_DisableTintColor == 0 ) {
                        color = material.GetColor( "_Color" );
                        if ( srcDesc == "Tint Color" && dstDesc == "Color" ) {
                            _Color_2_Color = new Color(
                                Mathf.Clamp01( color.r * 2 ),
                                Mathf.Clamp01( color.g * 2 ),
                                Mathf.Clamp01( color.b * 2 ),
                                color.a
                            );
                        } else if ( srcDesc == "Color" && dstDesc == "Tint Color" ) {
                            _Color_2_Color = new Color(
                                color.r * 0.5f,
                                color.g * 0.5f,
                                color.b * 0.5f,
                                color.a
                            );
                        }
                    }
                }
            }
#if KEEP_RENDERQUEUE
            // 切换Shader会导致渲染队列被重置，需要手动保留
            var renderQueue = material.renderQueue;
            material.shader = newShader;
            material.renderQueue = renderQueue;
#else
            material.shader = newShader;
#endif
            if ( _TintColor_2_Color != null ) {
                material.SetColor( "_Color", _TintColor_2_Color.Value );
            } else if ( _Color_2_Color != null ) {
                material.SetColor( "_Color", _Color_2_Color.Value );
            }
        }

        protected virtual bool OnInitProperties( MaterialProperty[] props ) {
            m_userDefaultEditor = false;
            var material = m_MaterialEditor.target as Material;
            var shader = material.shader;
            var path = shader != null ? AssetDatabase.GetAssetPath( shader ) : String.Empty;
            if ( !IsEmptyShader( shader ) && !String.IsNullOrEmpty( path ) ) {
                try {
                    var json = GetEditorData( path, ref m_editorDirty );
                    if ( m_editorDirty && json != null && json.IsArray ) {
                        m_props.Clear();
                        m_editorDirty = false;
                        var vals = json.list;
                        var curGroupName = DefaultGroupName;
                        s_groupFoldoutState = s_groupFoldoutState ?? new Dictionary<String, bool>();
                        if ( s_groupFoldoutStateForShader != shader ) {
                            s_groupFoldoutStateForShader = shader;
                            s_groupFoldoutState.Clear();
                        }
                        if ( !s_groupFoldoutState.ContainsKey( DefaultGroupName ) ) {
                            s_groupFoldoutState[ DefaultGroupName ] = true;
                        }
                        for ( int i = 0; i < vals.Count; ++i ) {
                            var val = vals[ i ];
                            if ( val != null && val.IsArray && val.Count > 0 ) {
                                if ( val[ 0 ].IsString ) {
                                    var groupName = val[ 0 ].str.Trim();
                                    if ( !String.IsNullOrEmpty( groupName ) ) {
                                        curGroupName = groupName;
                                    } else {
                                        curGroupName = DefaultGroupName;
                                    }
                                    if ( !s_groupFoldoutState.ContainsKey( curGroupName ) ) {
                                        s_groupFoldoutState[ curGroupName ] = true;
                                    }
                                    continue;
                                }
                            }
                            if ( val != null && val.IsObject ) {
                                var editor = String.Empty;
                                if ( !val.GetField( out editor, Cfg.Key_Editor, String.Empty ) ) {
                                    continue;
                                }
                                Func<PropEditorSettings, UnitMaterialEditor> f = null;
                                if ( s_ShaderPropGUIFactory.TryGetValue( editor, out f ) ) {
                                    var propName = String.Empty;
                                    var args = val.GetField( Cfg.Key_Args );
                                    if ( args != null && args.IsObject ) {
                                        args.GetField( out propName, Cfg.Key_Name, String.Empty );
                                    }
                                    var settings = new PropEditorSettings {
                                        name = propName,
                                        parent = this,
                                        props = props
                                    };
                                    var p = f( settings );
                                    if ( p != null ) {
                                        float space_begin;
                                        float space_end;
                                        int indent;
                                        val.GetField( out space_begin, "space", 0 );
                                        val.GetField( out space_end, "endspace", 0 );
                                        val.GetField( out indent, "indent", 0 );
                                        p.m_group = curGroupName;
                                        p.m_indent = indent;
                                        p.m_propIndex = m_props.Count;
                                        p.m_uiSpace = new Vector2( space_begin, space_end );
                                        val.GetField( out p.m_id, Cfg.Key_ID, String.Empty );
                                        p.m_args = args;
                                        p.m_MaterialEditor = m_MaterialEditor;
                                        p.m_parent = this;
                                        try {
                                            if ( p.OnInitProperties( props ) ) {
                                                m_props.Add( p );
                                            }
                                        } catch ( Exception e ) {
                                            Debug.LogException( e );
                                        }
                                    }
                                }
                            }
                        }
                    }
                    for ( int i = 0; i < m_props.Count; ++i ) {
                        m_props[ i ].OnPostInitProperties();
                    }
                    m_userDefaultEditor = m_props.Count == 0;
                } catch ( Exception e ) {
                    Debug.LogException( e );
                    m_userDefaultEditor = true;
                }
            } else {
                m_userDefaultEditor = true;
            }
            return true;
        }

        protected virtual void OnPostInitProperties() { }

        protected void DrawPropertiesGUI( MaterialProperty[] props ) {
            if ( OnInitProperties( props ) ) {
                OnDrawPropertiesGUI( props );
            }
        }

        protected virtual void OnDrawPropertiesGUI( MaterialProperty[] props ) {
        }

        protected virtual void OnMaterialChanged( MaterialProperty[] props ) {
            for ( int i = 0; i < m_props.Count; ++i ) {
                m_props[ i ].OnMaterialChanged( props );
            }
        }

        protected virtual void OnRefreshKeywords() {
            for ( int i = 0; i < m_props.Count; ++i ) {
                m_props[ i ].OnRefreshKeywords();
            }
        }

        void RefreshKeywords() {
            OnRefreshKeywords();
        }

        void FindProperties( MaterialProperty[] props ) {
            OnInitProperties( props );
        }

        static void _FixupEmissiveFlag( Material mat ) {
            if ( mat == null ) {
                throw new ArgumentNullException( "mat" );
            }
            mat.globalIlluminationFlags = _FixupEmissiveFlag( mat.GetColor( "_EmissionColor" ), mat.globalIlluminationFlags );
        }

        static MaterialGlobalIlluminationFlags _FixupEmissiveFlag( Color col, MaterialGlobalIlluminationFlags flags ) {
            if ( ( flags & MaterialGlobalIlluminationFlags.BakedEmissive ) != MaterialGlobalIlluminationFlags.None && col.maxColorComponent == 0f ) {
                flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            } else if ( flags != MaterialGlobalIlluminationFlags.EmissiveIsBlack ) {
                flags &= MaterialGlobalIlluminationFlags.AnyEmissive;
            }
            return flags;
        }

        void MaterialChanged( MaterialProperty[] props ) {
            OnMaterialChanged( props );
            var _EmissionColor = Color.black;
            var materials = targets;
            foreach ( var material in materials ) {
                if ( material.HasProperty( "_EmissionColor" ) ) {
                    _EmissionColor = material.GetColor( "_EmissionColor" );
                    _FixupEmissiveFlag( material );
                }
            }
        }

        static bool Foldout( bool display, string title, out bool shift, KeyValuePair<String, Action>[] menuCallbacks ) {
            shift = false;
            var style = new GUIStyle( "ShurikenModuleTitle" );
            style.font = new GUIStyle( EditorStyles.boldLabel ).font;
            style.border = new RectOffset( 15, 7, 4, 4 );
            style.fixedHeight = 22;
            style.contentOffset = new Vector2( 20f, -2f );
            var rect = GUILayoutUtility.GetRect( 16f, 22f, style );
            GUI.Box( rect, title, style );
            var e = Event.current;
            var toggleRect = new Rect( rect.x + 4f, rect.y + 2f, 13f, 13f );
            if ( e.type == EventType.Repaint ) {
                EditorStyles.foldout.Draw( toggleRect, false, false, display, false );
            }
            if ( e.type == EventType.MouseDown && rect.Contains( e.mousePosition ) ) {
                if ( e.button != 1 ) {
                    shift = e.shift;
                    display = !display;
                } else {
                    if ( menuCallbacks != null && menuCallbacks.Length > 0 ) {
                        var menu = new GenericMenu();
                        for ( int i = 0; i < menuCallbacks.Length; ++i ) {
                            var callback = menuCallbacks[ i ];
                            if ( callback.Value != null && !String.IsNullOrEmpty( callback.Key ) ) {
                                menu.AddItem(
                                    new GUIContent( callback.Key ), false,
                                    () => {
                                        try {
                                            callback.Value();
                                        } catch ( Exception ex ) {
                                            Debug.LogException( ex );
                                        }
                                    }
                                );
                            }
                        }
                        menu.ShowAsContext();
                    }
                }
                e.Use();
            }
            return display;
        }

        static bool FoldoutSubMenu( bool display, string title ) {
            var style = new GUIStyle( "ShurikenModuleTitle" );
            style.font = new GUIStyle( EditorStyles.boldLabel ).font;
            style.border = new RectOffset( 15, 7, 4, 4 );
            style.padding = new RectOffset( 5, 7, 4, 4 );
            style.fixedHeight = 22;
            style.contentOffset = new Vector2( 32f, -2f );
            var rect = GUILayoutUtility.GetRect( 16f, 22f, style );
            GUI.Box( rect, title, style );
            var e = Event.current;
            var toggleRect = new Rect( rect.x + 16f, rect.y + 2f, 13f, 13f );
            if ( e.type == EventType.Repaint ) {
                EditorStyles.foldout.Draw( toggleRect, false, false, display, false );
            }
            if ( e.type == EventType.MouseDown && rect.Contains( e.mousePosition ) ) {
                display = !display;
                e.Use();
            }
            return display;
        }

        void DoEmissionArea() {
            var target = this.target;
            if ( target.HasProperty( "_EmissionColor" ) ) {
                if ( this.m_MaterialEditor.EmissionEnabledProperty() ) {
                    this.m_MaterialEditor.LightmapEmissionFlagsProperty( 0, true );
                }
            }
        }

        void ShaderPropertiesGUI( MaterialProperty[] props ) {
            EditorGUI.BeginChangeCheck();
            var curGroup = String.Empty;
            var show = true;
            var hasPasteSource = false;
            if ( !String.IsNullOrEmpty( EditorGUIUtility.systemCopyBuffer ) &&
                EditorGUIUtility.systemCopyBuffer.Contains( UnitMaterialEditor.Cfg.EditorCopyBufferTag ) ) {
                hasPasteSource = true;
            }
            for ( int i = 0; i < m_props.Count; ++i ) {
                var p = m_props[ i ];
                if ( p.m_group != curGroup ) {
                    var _show = s_groupFoldoutState[ p.m_group ];
                    bool shift;
                    var startIndex = i;
                    Action pasteAction = null;
                    Action copyAction = null;
                    var ignoreTextureProperties = false;
                    if ( hasPasteSource ) {
                        pasteAction = () => {
                            try {
                                var jval = new JSONObject( EditorGUIUtility.systemCopyBuffer );
                                if ( ignoreTextureProperties ) {
                                    List<String> removeList = null;
                                    for ( int k = 0; k < jval.keys.Count; ++k ) {
                                        var key = jval.keys[ k ];
                                        var val = jval.list[ k ];
                                        String type;
                                        if ( val.GetField( out type, "type", String.Empty ) && type == "Texture" ) {
                                            removeList = removeList ?? new List<string>();
                                            removeList.Add( key );
                                        }
                                    }
                                    if ( removeList != null ) {
                                        foreach ( var key in removeList ) {
                                            jval.RemoveField( key );
                                        }
                                    }
                                }
                                var firstProp = p;
                                for ( int j = startIndex; j < m_props.Count; ++j ) {
                                    var _p = m_props[ j ];
                                    if ( _p.m_group == firstProp.m_group ) {
                                        _p.DeserializeFromJSON( jval );
                                    } else {
                                        break;
                                    }
                                }
                            } catch ( Exception e ) {
                                Debug.LogException( e );
                            }
                        };
                    }
                    copyAction = () => {
                        var firstProp = p;
                        var outJval = new JSONObject( JSONObject.Type.OBJECT );
                        outJval.SetField( UnitMaterialEditor.Cfg.EditorCopyBufferTag, true );
                        for ( int j = startIndex; j < m_props.Count; ++j ) {
                            var _p = m_props[ j ];
                            if ( _p.m_group == firstProp.m_group ) {
                                _p.SerializeToJSON( outJval );
                            } else {
                                break;
                            }
                        }
                        var text = outJval.ToString( true );
                        EditorGUIUtility.systemCopyBuffer = text;
                        Debug.LogFormat( "UnitMaterialEditor copy values:\n{0}", text );
                    };
                    show = Foldout( _show, p.m_group, out shift,
                        new KeyValuePair<String, Action>[] {
                            new KeyValuePair<String, Action>(
                                "Copy Properties",
                                copyAction
                            ),
                            new KeyValuePair<String, Action>(
                                "Paste Numbers",
                                () => {
                                    ignoreTextureProperties = true;
                                    pasteAction();
                                }
                            ),
                            new KeyValuePair<String, Action>(
                                "Paste All",
                                pasteAction
                            ),
                            new KeyValuePair<String, Action>(
                                String.IsNullOrEmpty( EditorGUIUtility.systemCopyBuffer ) ? String.Empty : "Clean Clipboard",
                                () => EditorGUIUtility.systemCopyBuffer = String.Empty
                            ),
                            new KeyValuePair<String, Action>(
                                String.IsNullOrEmpty( EditorGUIUtility.systemCopyBuffer ) ? String.Empty : "Dump Clipboard",
                                () => {
                                    Debug.LogFormat( "systemCopyBuffer:\n{0}", EditorGUIUtility.systemCopyBuffer );
                                }
                            )
                        }
                    );
                    if ( _show != show ) {
                        if ( !shift ) {
                            s_groupFoldoutState[ p.m_group ] = show;
                        } else {
                            // 顺延下所有的选项整体控制
                            for ( int _i = i; _i < m_props.Count; ++_i ) {
                                s_groupFoldoutState[ m_props[ _i ].m_group ] = show;
                            }
                        }
                    }
                    curGroup = p.m_group;
                }
                if ( show ) {
                    var indent = p.m_indent + 1;
                    GUILayout.Space( p.m_uiSpace.x );
                    EditorGUI.indentLevel += indent;
                    m_props[ i ].DrawPropertiesGUI( props );
                    EditorGUI.indentLevel -= indent;
                    GUILayout.Space( p.m_uiSpace.y );
                }
            }
            EditorGUILayout.Space();
            var targets = this.targets;
            if ( targets.Length == 1 ) {
                DrawKeywords( targets[ 0 ] );
            }
            if ( EditorGUI.EndChangeCheck() ) {
                MaterialChanged( props );
            }
            EditorGUILayout.Space();
            DoEmissionArea();
            if ( targets.Length == 1 ) {
                RenderQueueField();
            }
        }

        public static void DrawKeywords( Material material ) {
            var _keywords = material.shaderKeywords;
            var keywords = String.Join( "\n", _keywords );
            EditorGUILayout.Separator();
            EditorGUILayout.LabelField( "Compiler keywords:" );
            GUI.enabled = false;
            try {
                var newKeywords = EditorGUILayout.TextArea( keywords );
                if ( newKeywords != keywords ) {
                    var key = newKeywords.Split( ' ', ',', ';', '\n' );
                    for ( int i = 0; i < key.Length; ++i ) {
                        key[ i ] = key[ i ].Trim();
                    }
                    material.shaderKeywords = key;
                }
            } finally {
                GUI.enabled = true;
            }
        }

        public override void AssignNewShaderToMaterial( Material material, Shader oldShader, Shader newShader ) {
            m_FirstTimeApply = true;
            if ( !editorEnabled ) {
                base.AssignNewShaderToMaterial( material, oldShader, newShader );
                return;
            }
            AssignNewShader( material, oldShader, newShader );
        }

        public override void OnClosed( Material material ) {
            if ( !editorEnabled ) {
                return;
            }
            s_curMaterialEditor = null;
            s_curShaderGUI = null;
            s_curMaterial = null;
            if ( m_template != null ) {
                m_template = null;
            }
        }

        public override void OnGUI( MaterialEditor materialEditor, MaterialProperty[] props ) {
            if ( !editorEnabled ) {
                OnGUI( materialEditor, props );
                return;
            }
            s_curMaterialEditor = materialEditor;
            s_curShaderGUI = this;
            s_curMaterial = materialEditor.target as Material;
            if ( m_template == null && s_curMaterial != null && !IsEmptyShader( s_curMaterial.shader ) ) {
                if ( !s_templateCache.TryGetValue( s_curMaterial.shader, out m_template ) || m_template == null ) {
                    m_template = new Material( s_curMaterial.shader );
                    s_templateCache[ s_curMaterial.shader ] = m_template;
                }
            }
            m_MaterialEditor = materialEditor;
            FindProperties( props );
            if ( m_userDefaultEditor ) {
                base.OnGUI( materialEditor, props );
            } else {
                if ( this.m_FirstTimeApply ) {
                    MaterialChanged( props );
                    this.m_FirstTimeApply = false;
                }
                ShaderPropertiesGUI( props );
            }
        }

        public static void SetKeyword( Material m, String keyword, bool state ) {
            if ( state ) {
                m.EnableKeyword( keyword );
            } else {
                m.DisableKeyword( keyword );
            }
        }

        public static void SetKeyword( Material[] m, String keyword, bool state ) {
            foreach ( var mat in m ) {
                if ( state ) {
                    if ( !mat.IsKeywordEnabled( keyword ) ) {
                        mat.EnableKeyword( keyword );
                    }
                } else {
                    if ( mat.IsKeywordEnabled( keyword ) ) {
                        mat.DisableKeyword( keyword );
                    }
                }
            }
        }

        public T FindPropEditor<T>( String id = null ) where T : UnitMaterialEditor {
            var props = m_parent != null ? m_parent.m_props : m_props;
            if ( props != null ) {
                var t = typeof( T );
                for ( int i = 0; i < props.Count; ++i ) {
                    if ( ( id == null || id == props[ i ].m_id ) &&
                        ( t == props[ i ].GetType() || t.IsInstanceOfType( props[ i ] ) ) ) {
                        return props[ i ] as T;
                    }
                }
            }
            return null;
        }

        public List<T> FindPropEditors<T>( List<T> list = null ) where T : UnitMaterialEditor {
            var props = m_parent != null ? m_parent.m_props : m_props;
            if ( list == null ) {
                list = new List<T>();
            } else {
                list.Clear();
            }
            if ( props != null ) {
                var t = typeof( T );
                for ( int i = 0; i < props.Count; ++i ) {
                    if ( props[ i ].GetType() == t || t.IsInstanceOfType( props[ i ] ) ) {
                        list.Add( props[ i ] as T );
                    }
                }
            }
            return list;
        }

        public T GetPrevEditor<T>() where T : UnitMaterialEditor {
            if ( m_parent != null && m_propIndex > 0 ) {
                var t = typeof( T );
                if ( m_parent.m_props[ m_propIndex - 1 ].GetType() == t || t.IsInstanceOfType( m_parent.m_props[ m_propIndex - 1 ] ) ) {
                    return m_parent.m_props[ m_propIndex - 1 ] as T;
                }
            }
            return null;
        }

        public T GetNextEditor<T>() where T : UnitMaterialEditor {
            if ( m_parent != null && m_propIndex < m_parent.m_props.Count - 1 ) {
                var t = typeof( T );
                if ( m_parent.m_props[ m_propIndex + 1 ].GetType() == t || t.IsInstanceOfType( m_parent.m_props[ m_propIndex + 1 ] ) ) {
                    return m_parent.m_props[ m_propIndex + 1 ] as T;
                }
            }
            return null;
        }

        public bool? GetLogicOpResult( MaterialProperty[] props ) {
            String returnValue;
            return GetLogicOpResult( out returnValue, props );
        }

        public virtual bool? GetLogicOpResult( out String returnValue, MaterialProperty[] props ) {
            returnValue = String.Empty;
            return null;
        }

        protected virtual String ComputeReturnValue( MaterialProperty[] props ) {
            return "null";
        }

        public virtual bool GetReturnValue( out String returnValue, MaterialProperty[] props ) {
            returnValue = String.Empty;
            var b = GetLogicOpResult( out returnValue, props );
            return b != null && b.Value;
        }

        public virtual bool SerializeToJSON( JSONObject parent ) {
            return false;
        }

        public virtual bool DeserializeFromJSON( JSONObject parent ) {
            return false;
        }

        public bool? TryGetBoolTestResult( MaterialProperty[] props, String key = null, bool? defaultValue = null ) {
            String _dummy;
            if ( m_args != null && m_args.GetField( out _dummy, key, String.Empty ) ) {
                if ( !String.IsNullOrEmpty( _dummy ) ) {
                    return GetBoolTestResult( props, key );
                }
            }
            if ( defaultValue.HasValue ) {
                return defaultValue.Value;
            } else {
                return null;
            }
        }

        public virtual bool? GetBoolTestResult( MaterialProperty[] props, String key = null ) {
            if ( m_args != null ) {
                String _ref;
                if ( String.IsNullOrEmpty( key ) ) {
                    key = "if";
                }
                m_args.GetField( out _ref, key, String.Empty );
                if ( !String.IsNullOrEmpty( _ref ) ) {
                    var m = Reg_LogicRef.Match( _ref );
                    if ( m.Success && m.Groups.Count > 2 ) {
                        var rev = m.Groups[ 1 ].ToString().Trim() == "!";
                        var id = m.Groups[ 2 ].ToString().Trim();
                        if ( !String.IsNullOrEmpty( id ) ) {
                            var ui = FindPropEditor<UnitMaterialEditor>( id );
                            if ( ui != null ) {
                                var returnValue = String.Empty;
                                var b = ui.GetLogicOpResult( out returnValue, props );
                                if ( b == null ) {
                                    return null;
                                }
                                if ( rev ) {
                                    b = !b;
                                }
                                return b;
                            } else {
                                var result = false;
                                if ( props != null ) {
                                    var prop = ShaderGUI.FindProperty( id, props, false );
                                    if ( prop != null ) {
                                        if ( prop.hasMixedValue ) {
                                            return null;
                                        }
                                        switch ( prop.type ) {
                                        case MaterialProperty.PropType.Color:
                                            result = ShaderGUIHelper.Compare( ">", prop.colorValue, new Color( 0, 0, 0, 0 ) );
                                            break;
                                        case MaterialProperty.PropType.Float:
                                        case MaterialProperty.PropType.Range:
                                            result = prop.floatValue > 0;
                                            break;
                                        case MaterialProperty.PropType.Texture:
                                            result = prop.textureValue != null;
                                            break;
                                        case MaterialProperty.PropType.Vector:
                                            result = ShaderGUIHelper.Compare( ">", prop.vectorValue, new Vector4( 0, 0, 0, 0 ) );
                                            break;
                                        }
                                        if ( rev ) {
                                            result = !result;
                                        }
                                        return result;
                                    }
                                }
                            }
                            return false;
                        }
                    }
                }
            }
            return true;
        }

        private static class Styles {
            static Styles() {
                Styles.queueLabel = EditorGUIUtility.TrTextContent( "Render Queue" );
                Styles.queueNames = new GUIContent[] {
                    EditorGUIUtility.TrTextContent( "From Shader", null ),
                    EditorGUIUtility.TrTextContent( "Geometry", "Queue 2000" ),
                    EditorGUIUtility.TrTextContent( "AlphaTest", "Queue 2450" ),
                    EditorGUIUtility.TrTextContent( "Transparent", "Queue 3000" ),
                    EditorGUIUtility.TrTextContent( "Background", "Queue 1000" ),
                    EditorGUIUtility.TrTextContent( "Overlay", "Queue 4000" ),
                };
                Styles.queueValues = new int[] {
                    -1,
                    2000,
                    2450,
                    3000,
                    1000,
                    4000,
                };
                Styles.customQueueNames = new GUIContent[] {
                    Styles.queueNames[0],
                    Styles.queueNames[1],
                    Styles.queueNames[2],
                    Styles.queueNames[3],
                    Styles.queueNames[4],
                    Styles.queueNames[5],
                    EditorGUIUtility.TrTextContent( "", null )
                };
                int[] array2 = new int[ 7 ];
                array2[ 0 ] = Styles.queueValues[ 0 ];
                array2[ 1 ] = Styles.queueValues[ 1 ];
                array2[ 2 ] = Styles.queueValues[ 2 ];
                array2[ 3 ] = Styles.queueValues[ 3 ];
                array2[ 4 ] = Styles.queueValues[ 4 ];
                array2[ 5 ] = Styles.queueValues[ 5 ];
                Styles.customQueueValues = array2;
            }
            public const int kNewShaderQueueValue = -1;
            public const int kCustomQueueIndex = 4;
            public static readonly GUIContent queueLabel;
            public static readonly GUIContent[] queueNames;
            public static readonly int[] queueValues;
            public static GUIContent[] customQueueNames;
            public static int[] customQueueValues;
            public static KeyValuePair<int, String>[] sortedRenderQueueTypes = new KeyValuePair<int, String>[]{
                new KeyValuePair<int, String>( 1000, "Background" ),
                new KeyValuePair<int, String>( 2000, "Geometry" ),
                new KeyValuePair<int, String>( 2450, "AlphaTest" ),
                new KeyValuePair<int, String>( 3000, "Transparent" ),
                new KeyValuePair<int, String>( 4000, "Overlay" ),
            };
        }

        static int GetMaterialRawRenderQueue( Material m ) {
            var getter = typeof( Material ).GetProperty( "rawRenderQueue",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance );
            if ( getter != null ) {
                var val = getter.GetValue( m, null );
                if ( val != null && val is int ) {
                    return ( int )val;
                }
            }
            return -1;
        }

        private bool HasMultipleMixedQueueValues() {
            int rawRenderQueue = GetMaterialRawRenderQueue( m_MaterialEditor.targets[ 0 ] as Material );
            for ( int i = 1; i < m_MaterialEditor.targets.Length; i++ ) {
                if ( rawRenderQueue != GetMaterialRawRenderQueue( m_MaterialEditor.targets[ i ] as Material ) ) {
                    return true;
                }
            }
            return false;
        }

        static Rect GetControlRectForSingleLine() {
            return EditorGUILayout.GetControlRect( true, 18f, EditorStyles.layerMaskField, new GUILayoutOption[ 0 ] );
        }

        void RenderQueueField() {
            Rect controlRectForSingleLine = GetControlRectForSingleLine();
            this.RenderQueueField( controlRectForSingleLine );
        }

        int CalculateClosestQueueIndexToValue( int requestedValue ) {
            int num = int.MaxValue;
            int result = 1;
            for ( int i = 1; i < Styles.queueValues.Length; i++ ) {
                int num2 = Styles.queueValues[ i ];
                int num3 = Mathf.Abs( num2 - requestedValue );
                if ( num3 < num ) {
                    result = i;
                    num = num3;
                }
            }
            return result;
        }

        void RenderQueueField( Rect r ) {
            bool showMixedValue = this.HasMultipleMixedQueueValues();
            EditorGUI.showMixedValue = showMixedValue;
            Material material = m_MaterialEditor.targets[ 0 ] as Material;
            int rawRenderQueue = GetMaterialRawRenderQueue( material );
            int renderQueue = material.renderQueue;
            bool flag = Array.IndexOf<int>( Styles.queueValues, rawRenderQueue ) < 0;
            GUIContent[] displayedOptions;
            int[] optionValues;
            float num3;
            if ( flag ) {
                bool flag2 = Array.IndexOf( Styles.customQueueNames, rawRenderQueue ) < 0;
                if ( flag2 ) {
                    int num = CalculateClosestQueueIndexToValue( rawRenderQueue );
                    string text = Styles.queueNames[ num ].text;
                    int num2 = rawRenderQueue - Styles.queueValues[ num ];
                    string text2 = string.Format( ( num2 <= 0 ) ? "{0}{1}" : "{0}+{1}", text, num2 );
                    Styles.customQueueNames[ 6 ].text = text2;
                    Styles.customQueueValues[ 6 ] = rawRenderQueue;
                }
                displayedOptions = Styles.customQueueNames;
                optionValues = Styles.customQueueValues;
                num3 = 115f;
            } else {
                displayedOptions = Styles.queueNames;
                optionValues = Styles.queueValues;
                num3 = 100f;
            }
            float labelWidth = EditorGUIUtility.labelWidth;
            float fieldWidth = EditorGUIUtility.fieldWidth;
            m_MaterialEditor.SetDefaultGUIWidths();
            EditorGUIUtility.labelWidth -= num3;
            Rect position = r;
            position.width -= EditorGUIUtility.fieldWidth + 2f;
            Rect position2 = r;
            position2.xMin = position2.xMax - EditorGUIUtility.fieldWidth;
            int num4 = rawRenderQueue;
            int num5 = EditorGUI.IntPopup( position, Styles.queueLabel, rawRenderQueue, displayedOptions, optionValues );
            int num6 = EditorGUI.DelayedIntField( position2, renderQueue );
            if ( num4 != num5 || renderQueue != num6 ) {
                m_MaterialEditor.RegisterPropertyChangeUndo( "Render Queue" );
                int num7 = num6;
                if ( num5 != num4 ) {
                    num7 = num5;
                }
                num7 = Mathf.Clamp( num7, -1, 5000 );
                foreach ( UnityEngine.Object @object in m_MaterialEditor.targets ) {
                    var m = ( ( Material )@object );
                    var renderType = m.GetTag( "RenderType", false );
                    m.renderQueue = num7;
                    if ( m.renderQueue != -1 ) {
                        var setTag = String.IsNullOrEmpty( renderType );
                        if ( !setTag ) {
                            var rm = FindPropEditor<ShaderGUI_RenderMode>();
                            if ( rm != null && rm._Mode != RenderMode.Custom ) {
                                setTag = true;
                            }
                        }
                        if ( setTag ) {
                            var newType = Styles.sortedRenderQueueTypes[ 0 ].Value;
                            for ( int i = 1; i < Styles.sortedRenderQueueTypes.Length; ++i ) {
                                if ( m.renderQueue < Styles.sortedRenderQueueTypes[ i ].Key ) {
                                    break;
                                }
                                newType = Styles.sortedRenderQueueTypes[ i ].Value;
                            }
                            m.SetOverrideTag( "RenderType", newType );
                        }
                    }
                }
            }
            EditorGUIUtility.labelWidth = labelWidth;
            EditorGUIUtility.fieldWidth = fieldWidth;
            EditorGUI.showMixedValue = false;
        }
    }
}
