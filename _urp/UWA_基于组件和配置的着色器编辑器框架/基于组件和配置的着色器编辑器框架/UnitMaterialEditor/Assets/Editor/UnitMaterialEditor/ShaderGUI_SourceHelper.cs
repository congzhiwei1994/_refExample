#define SAVE_SOURCECHECKHASH_TO_META
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace UME {

    public class ShaderGUI_SourceHelper : UnitMaterialEditor {

        static Regex Reg_PropHeader = new Regex( @"\[\s*Header\s*\(\s*((\w+\s*)*(\w+))\s*\)\]" );
        new static Regex Reg_Command = new Regex( @"//\s*#(\w+)(\s+(.+))?" );

        static readonly Char[] LineSpaceChar = new Char[] { ' ', '\t' };

        String m_shaderFilePath = String.Empty;
        String m_info = String.Empty;
        long m_timestamp = 0;
        uint m_dependenceHash = 0u;
        bool m_dependenceChanged = false;
        List<KeyValuePair<String, String>> m_dependenceFiles = null;

        static String s_NotePadPlusPlusPath = null;

        struct PropGroupRef {
            /// <summary>
            /// 解析后的完整资源路径
            /// </summary>
            internal String shaderAssetPath;
            /// <summary>
            /// 源文件中引用命令内容
            /// </summary>
            internal String sourceShaderRef;
            internal String group;
        }

        class PropDataGroupNode {
            public override string ToString() {
                if ( String.IsNullOrEmpty( groupName ) ) {
                    return groupName;
                }
                return base.ToString();
            }
            internal String groupName = null;
            internal String shaderPath = null;
            /// <summary>
            /// 组内容中每一行都被展开准备好
            /// </summary>
            internal bool editorDataIsReady = false;
            /// <summary>
            /// 分组内容，可能是行源文本，也可以是解析后的引用路径
            /// </summary>
            internal List<STuple<String, PropGroupRef>> editors = null;
        }

        class PropDataTree {
            internal String shaderPath = null;
            /// <summary>
            /// 完整文件文本内容
            /// </summary>
            internal String text = null;
            /// <summary>
            /// 编辑器属性块插入区间起始
            /// </summary>
            internal int sourceStart = -1;
            /// <summary>
            /// 编辑器属性快插入区间结束位置，开区间
            /// </summary>
            internal int sourceEnd = -1;
            /// <summary>
            /// 完整的属性块源文本
            /// </summary>
            internal String source = null;
            /// <summary>
            /// 展开后用于替换源文本的内容
            /// </summary>
            internal String newSource = null;
            /// <summary>
            /// 标记所有的分组都已经完全展开引用，准备好了
            /// </summary>
            internal bool editorDataIsReady = false;
            /// <summary>
            /// 分组节点列表
            /// </summary>
            internal List<PropDataGroupNode> children = null;
        }

        protected class ShaderPropDataSource {
            internal String path;
            /// <summary>
            /// 源码文件全文本
            /// </summary>
            internal String text;
            /// <summary>
            /// 源码文件属性块区间文本
            /// </summary>
            internal String sourcePropText;
            internal int insertStart = -1;
            internal int insertEnd = -1;
            internal uint recordDependenceHash = 0u;
            internal uint dependenceHash = 0xffffffff;
            /// <summary>
            /// 记录文件以及依赖文件中最后近一次修改时间
            /// </summary>
            internal long lastWriteTime;
            /// <summary>
            /// 当前文件最后一次修改时间
            /// </summary>
            internal long lastSelfWriteTime;
            /// <summary>
            /// 从源码分析出来的完整shader依赖，一定都存在，包含自己
            /// </summary>
            internal List<String> allIncludeShaderNames = new List<String>();
            /// <summary>
            /// 自身文件shader依赖，不一定都存在
            /// </summary>
            internal List<String> selfIncludeShaderNames;
        }

        static Dictionary<String, ShaderPropDataSource> s_ShaderPropSourceCache = new Dictionary<String, ShaderPropDataSource>();

        static ShaderPropDataSource _GetIncludeFiles( String shaderPath, out String propSourceText, HashSet<String> record ) {
            propSourceText = String.Empty;
            if ( String.IsNullOrEmpty( shaderPath ) ) {
                return null;
            }
            if ( !record.Add( shaderPath ) ) {
                return null;
            }
            if ( !File.Exists( shaderPath ) ) {
                return null;
            }
            var ownerShader = AssetDatabase.LoadAssetAtPath<Shader>( shaderPath );
            if ( ownerShader == null ) {
                return null;
            }
            var fileTime = File.GetLastWriteTime( shaderPath ).ToFileTime();
            ShaderPropDataSource dataSource;
            if ( s_ShaderPropSourceCache.TryGetValue( shaderPath, out dataSource ) ) {
                if ( fileTime != dataSource.lastSelfWriteTime ) {
                    // 只要文件自身发生变化，从新计算
                    s_ShaderPropSourceCache.Remove( shaderPath );
                } else {
                    // 需要更新最后修改时间戳
                    dataSource.lastWriteTime = fileTime;
                    dataSource.allIncludeShaderNames.Clear();
                    propSourceText = dataSource.sourcePropText;
                    if ( dataSource.selfIncludeShaderNames != null ) {
                        // 每次都需要根据自身包含文件计算新的全包含文件
                        for ( int i = 0; i < dataSource.selfIncludeShaderNames.Count; ++i ) {
                            var include = dataSource.selfIncludeShaderNames[ i ];
                            var shader = SearchShader( include );
                            if ( shader != null ) {
                                var includeShaderPath = AssetDatabase.GetAssetPath( shader );
                                if ( !String.IsNullOrEmpty( includeShaderPath ) ) {
                                    String _editorData;
                                    var includeData = _GetIncludeFiles( includeShaderPath, out _editorData, record );
                                    if ( null != includeData ) {
                                        for ( int j = 0; j < includeData.allIncludeShaderNames.Count; ++j ) {
                                            var includeShaderName = includeData.allIncludeShaderNames[ j ];
                                            var subShader = SearchShader( includeShaderName );
                                            if ( subShader != null ) {
                                                // 更新时间戳，并且加入到父节点中来
                                                var subShaderAssetPath = AssetDatabase.GetAssetPath( subShader );
                                                var includeFileTime = File.GetLastWriteTime( subShaderAssetPath ).ToFileTime();
                                                if ( includeFileTime > dataSource.lastWriteTime ) {
                                                    dataSource.lastWriteTime = includeFileTime;
                                                }
                                                if ( !dataSource.allIncludeShaderNames.Contains( subShader.name ) ) {
                                                    dataSource.allIncludeShaderNames.Add( subShader.name );
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    dataSource.allIncludeShaderNames.Remove( ownerShader.name );
                    dataSource.allIncludeShaderNames.Sort();
                    dataSource.allIncludeShaderNames.Insert( 0, ownerShader.name );
                    return dataSource;
                }
            }
            dataSource = new ShaderPropDataSource();
            dataSource.path = shaderPath;
            dataSource.lastWriteTime = fileTime;
            dataSource.lastSelfWriteTime = fileTime;
            s_ShaderPropSourceCache.Add( shaderPath, dataSource );
            Dictionary<String, String> defines = null;
            var text = File.ReadAllText( shaderPath );
            try {
                var tagStart = text.IndexOf( "Properties" );
                // 解析属性插入区间区间[start, end)
                var insertStart = -1;
                var insertEnd = -1;
                var content = String.Empty;
                if ( tagStart >= 0 ) {
                    var begin = tagStart + "Properties".Length;
                    var openIndex = text.IndexOf( '{', begin );
                    if ( openIndex >= 0 ) {
                        // 括号后面第一个字符
                        ++openIndex;
                        var brackets = 1;
                        var i = openIndex;
                        for ( ; i < text.Length; ) {
                            var c = text[ i ];
                            if ( c == '/' && i < text.Length - 1 ) {
                                if ( text[ i + 1 ] == '/' ) {
                                    // 跳过单行注释
                                    i += 2;
                                    do { } while ( text[ i++ ] != '\n' );
                                    continue;
                                } else if ( text[ i + 1 ] == '*' ) {
                                    // 跳过多行注释
                                    i += 2;
                                    var end = text.IndexOf( "*/", i );
                                    if ( end >= 0 ) {
                                        i += 2;
                                        continue;
                                    } else {
                                        // 没有找到注释结尾，错误
                                        break;
                                    }
                                }
                            }
                            if ( c == '{' ) {
                                ++brackets;
                            } else if ( c == '}' ) {
                                --brackets;
                            }
                            if ( brackets == 0 ) {
                                break;
                            }
                            ++i;
                        }
                        if ( brackets == 0 ) {
                            var endIndex = i;
                            // 括号内所有字符包含在内，需要往两头搜索最近有效的换行，并保留
                            Debug.Assert( text[ openIndex - 1 ] == '{' && openIndex > 0 );
                            Debug.Assert( text[ endIndex ] == '}' );
                            while ( openIndex < text.Length ) {
                                if ( !Char.IsWhiteSpace( text[ openIndex ] ) || text[ openIndex++ ] == '\n' ) {
                                    // 遇到非空字符停止跳过，使用当前字符位置为插入点
                                    // 跳过换行，插入点在换行之后
                                    break;
                                }
                            }
                            while ( endIndex > 0 ) {
                                if ( !Char.IsWhiteSpace( text[ endIndex - 1 ] ) ) {
                                    // 上一个字符有效，保留换行
                                    break;
                                }
                                if ( text[ endIndex - 1 ] == '\n' ) {
                                    if ( endIndex > 2 && text[ endIndex - 2 ] == '\r' ) {
                                        --endIndex;
                                    }
                                    --endIndex;
                                    break;
                                }
                                --endIndex;
                            }
                            Debug.Assert( endIndex > openIndex );
                            insertStart = openIndex;
                            insertEnd = endIndex;
                            content = text.Substring( insertStart, insertEnd - insertStart );
                        }
                    }
                }
                if ( !String.IsNullOrEmpty( content ) ) {
                    dataSource.text = text;
                    dataSource.sourcePropText = content;
                    dataSource.insertStart = insertStart;
                    dataSource.insertEnd = insertEnd;
                    text = content;
                    var lastIncludeShaderName = String.Empty;
                    var startIndex = 0;
                    var end = -1;
                    while ( startIndex < text.Length ) {
                        // 解析单行内容
                        end = text.IndexOf( '\n', startIndex );
                        if ( end < 0 ) {
                            // 到头了，注意截断
                            end = text.Length;
                            startIndex = text.Length;
                        }
                        if ( end > startIndex ) {
                            // 我们所有的预处理标记都是单行注释形式
                            var tagIndex = text.IndexOf( "//", startIndex, end - startIndex );
                            if ( tagIndex >= 0 ) {
                                // 截取完整行内容
                                var line = text.Substring( startIndex, end - startIndex );
                                // 匹配预处理命令
                                var cmdMatch = Reg_Command.Match( line );
                                if ( cmdMatch.Success && cmdMatch.Groups.Count > 1 ) {
                                    var cmd = cmdMatch.Groups[ 1 ].Value;
                                    var value = String.Empty;
                                    if ( cmdMatch.Groups.Count > 3 ) {
                                        value = cmdMatch.Groups[ 3 ].Value;
                                    }
                                    switch ( cmd ) {
                                    case "include": {
                                            if ( String.IsNullOrEmpty( value ) ) {
                                                break;
                                            }
                                            var path = value;
                                            var split = path.LastIndexOf( ':' );
                                            if ( split > 0 ) {
                                                path = path.Substring( 0, split ).Trim();
                                            }
                                            var shaderRefPath = path;
                                            if ( path == Macro_LastIncludeFile && !String.IsNullOrEmpty( lastIncludeShaderName ) ) {
                                                path = lastIncludeShaderName;
                                            } else {
                                                var m = Reg_MacroRefValue.Match( path );
                                                for (; ; ) {
                                                    if ( m.Success && m.Groups.Count > 1 ) {
                                                        var name = m.Groups[ 1 ].Value;
                                                        String _value;
                                                        if ( defines != null && defines.TryGetValue( name, out _value ) ) {
                                                            path = _value;
                                                        } else {
                                                            Debug.LogErrorFormat( "unrecognized identifier '{0}'", name );
                                                        }
                                                    }
                                                    lastIncludeShaderName = path;
                                                    break;
                                                }
                                            }
                                            // 无论包含文件是否能加载出来都做记录
                                            dataSource.selfIncludeShaderNames = dataSource.selfIncludeShaderNames ?? new List<String>();
                                            if ( !dataSource.selfIncludeShaderNames.Contains( path ) ) {
                                                dataSource.selfIncludeShaderNames.Add( path );
                                            }
                                            var shader = SearchShader( path );
                                            if ( shader != null ) {
                                                var includeShaderPath = AssetDatabase.GetAssetPath( shader );
                                                if ( !String.IsNullOrEmpty( includeShaderPath ) ) {
                                                    String _editorData;
                                                    var includeData = _GetIncludeFiles( includeShaderPath, out _editorData, record );
                                                    if ( null != includeData ) {
                                                        for ( int j = 0; j < includeData.allIncludeShaderNames.Count; ++j ) {
                                                            var includeShaderName = includeData.allIncludeShaderNames[ j ];
                                                            var subShader = SearchShader( includeShaderName );
                                                            if ( subShader != null ) {
                                                                // 更新时间戳，并且加入到父节点中来
                                                                var subShaderAssetPath = AssetDatabase.GetAssetPath( subShader );
                                                                var includeFileTime = File.GetLastWriteTime( subShaderAssetPath ).ToFileTime();
                                                                if ( includeFileTime > dataSource.lastWriteTime ) {
                                                                    dataSource.lastWriteTime = includeFileTime;
                                                                }
                                                                if ( !dataSource.allIncludeShaderNames.Contains( subShader.name ) ) {
                                                                    dataSource.allIncludeShaderNames.Add( subShader.name );
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                Debug.LogErrorFormat( "Shader not found: '{0}'." );
                                            }
                                        }
                                        break;
                                    case "define": {
                                            var split = value.IndexOfAny( DefineSpliters );
                                            if ( split >= 0 ) {
                                                var v = value.Substring( split + 1 ).Trim();
                                                var name = value.Substring( 0, split ).Trim();
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
                                        if ( defines != null && !String.IsNullOrEmpty( value ) &&
                                            !defines.Remove( value ) ) {
                                            Debug.LogErrorFormat( "unrecognized identifier '{0}' for 'undef' command.", value );
                                        }
                                        break;
                                    case "checkhash":
                                        if ( !String.IsNullOrEmpty( value ) ) {
                                            Debug.Assert( dataSource.recordDependenceHash == 0 );
#if !SAVE_SOURCECHECKHASH_TO_META
                                            uint.TryParse( value,
                                                System.Globalization.NumberStyles.HexNumber,
                                                null, out dataSource.recordDependenceHash );
#endif
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                        startIndex = end + 1;
                    }
                    // 把自身文件的依赖始终放到列表首位置，注意去重
                    dataSource.allIncludeShaderNames.Remove( ownerShader.name );
                    dataSource.allIncludeShaderNames.Sort();
                    dataSource.allIncludeShaderNames.Insert( 0, ownerShader.name );
#if SAVE_SOURCECHECKHASH_TO_META
                    var shaderImporter = AssetImporter.GetAtPath( shaderPath ) as ShaderImporter;
                    Debug.Assert( shaderImporter != null );
                    if ( shaderImporter != null ) {
                        JSONObject userData = null;
                        if ( !String.IsNullOrEmpty( shaderImporter.userData ) ) {
                            try {
                                userData = JSONObject.Create( shaderImporter.userData );
                                if ( userData != null && userData.IsObject ) {
                                    String checkhash;
                                    if ( userData.GetField( out checkhash, "checkhash", String.Empty ) && !String.IsNullOrEmpty( checkhash ) ) {
                                        uint.TryParse( checkhash,
                                            System.Globalization.NumberStyles.HexNumber,
                                            null, out dataSource.recordDependenceHash );
                                    }
                                }
                            } catch ( Exception e ) {
                                Debug.LogException( e );
                            }
                        }
                    }
#endif
                    return dataSource;
                }
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            return null;
        }
        
        protected static ShaderPropDataSource GetIncludeFiles( String shaderPath ) {
            String propSourceText;
            var record = new HashSet<String>();
            return _GetIncludeFiles( shaderPath, out propSourceText, record );
        }

        protected static long GetShaderEditorDataLastWriteTime( String shaderAssetPath, out String editorData, out ShaderPropDataSource dataSource, out List<String> includeFiles ) {
            editorData = null;
            includeFiles = null;
            dataSource = null;
            long last = 0;
            try {
                var data = GetIncludeFiles( shaderAssetPath );
                dataSource = data;
                if ( data == null ) {
                    return 0;
                }
                var shaderNames = data.allIncludeShaderNames;
                if ( shaderNames != null ) {
                    long lastWriteTime = 0;
                    for ( int i = 0; i < shaderNames.Count; ++i ) {
                        var subShader = SearchShader( shaderNames[ i ] );
                        if ( subShader != null ) {
                            var includeShaderAssetPath = AssetDatabase.GetAssetPath( subShader );
                            includeFiles = includeFiles ?? new List<String>();
                            if ( !includeFiles.Contains( includeShaderAssetPath ) ) {
                                includeFiles.Add( includeShaderAssetPath );
                            }
                            if ( includeShaderAssetPath != shaderAssetPath ) {
                                // 不包含自身
                                // 使用最后修改时间作为更新提示依据
                                var subFileTime = File.GetLastWriteTime( includeShaderAssetPath ).ToFileTime();
                                if ( subFileTime > lastWriteTime ) {
                                    lastWriteTime = subFileTime;
                                }
                            }
                        }
                    }
                    dataSource.dependenceHash = ( uint )lastWriteTime.GetHashCode();
                }
                last = data.lastWriteTime;
                editorData = data.sourcePropText;
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            return last;
        }

        static String _UpdateInfo( String shaderAssetPath, ref long timestamp, ref uint dependenceHash, out ShaderPropDataSource dataSource, out List<String> outIncludeFiles ) {
            String editorData;
            List<String> includeFiles;
            var newTimestamp = GetShaderEditorDataLastWriteTime( shaderAssetPath, out editorData, out dataSource, out includeFiles );
            outIncludeFiles = includeFiles;
            dependenceHash = dataSource.dependenceHash;
            if ( newTimestamp == timestamp ) {
                // 最后修改的时间没变
                return String.Empty;
            }
            timestamp = newTimestamp;
            includeFiles = includeFiles ?? new List<String>();
            var info = String.Empty;
            for ( int n = 0; n < includeFiles.Count; ++n ) {
                // 获取缩略文件名
                var segs = includeFiles[ n ].Split( '/' );
                var totalLen = 0;
                var s = new List<String>();
                s.Add( segs[ segs.Length - 1 ] );
                totalLen += segs[ segs.Length - 1 ].Length;
                for ( int i = segs.Length - 2; i >= 1; --i ) {
                    var c = segs[ i ];
                    if ( totalLen + c.Length < 15 ) {
                        s.Insert( 0, segs[ i ] );
                        totalLen += segs[ i ].Length;
                    } else {
                        s.Insert( 0, "..." );
                        break;
                    }
                }
                if ( segs.Length > 1 ) {
                    s.Insert( 0, segs[ 0 ] );
                }
                if ( n == 0 ) {
                    info = "<b>" + String.Join( "/", s.ToArray() ) + "</b>\n";
                } else {
                    info += String.Join( "/", s.ToArray() ) + "\n";
                }
            }
            if ( timestamp != 0 ) {
                var time = DateTime.FromFileTime( timestamp );
                info += String.Format( "Timestamp: {1}", info, time );
            }
            return info;
        }

        void Reset() {
            m_timestamp = 0;
            m_info = String.Empty;
            m_dependenceHash = 0u;
            m_dependenceChanged = false;
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            var material = m_MaterialEditor.target as Material;
            if ( material != null && m_MaterialEditor.targets.Length == 1 ) {
                var shader = material.shader;
                if ( !IsEmptyShader( shader ) ) {
                    m_shaderFilePath = AssetDatabase.GetAssetPath( shader );
                    if ( !String.IsNullOrEmpty( m_shaderFilePath ) ) {
                        var hash = 0u;
                        ShaderPropDataSource dataSource;
                        List<String> includeFiles;
                        var info = _UpdateInfo( m_shaderFilePath, ref m_timestamp, ref hash, out dataSource, out includeFiles );
                        if ( !String.IsNullOrEmpty( info ) ) {
                            if ( !ShaderUtils.HasCodeSnippets( shader ) ) {
                                info = info.Insert( 0, "<color=yellow>No code snippets</color>\n" );
                            }
                            if ( hash != 0u ) {
                                info += "\nDependence Hash: " + hash.ToString( "X8" );
                            }
                            m_dependenceHash = hash;
                            m_info = info;
                            m_dependenceChanged = m_dependenceHash != dataSource.recordDependenceHash;
                            if ( includeFiles != null && includeFiles.Count > 1 ) {
                                m_dependenceFiles = m_dependenceFiles ?? new List<KeyValuePair<String, String>>();
                                m_dependenceFiles.Clear();
                                for ( int i = 1; i < includeFiles.Count; ++i ) {
                                    m_dependenceFiles.Add( new KeyValuePair<String, String>(
                                        System.IO.Path.GetFileNameWithoutExtension( includeFiles[ i ] ), includeFiles[ i ] ) );
                                }
                            }
                        }
                    }
                }
            }
            return true;
        }

#if SAVE_SOURCECHECKHASH_TO_META
        static bool _SaveDependenceHashToMeta( String shaderPath, uint dependenceHash ) {
            var shaderImporter = AssetImporter.GetAtPath( shaderPath ) as ShaderImporter;
            Debug.Assert( shaderImporter != null );
            if ( shaderImporter == null ) {
                return false;
            }
            JSONObject userData = null;
            if ( !String.IsNullOrEmpty( shaderImporter.userData ) ) {
                try {
                    userData = JSONObject.Create( shaderImporter.userData );
                } catch ( Exception e ) {
                    Debug.LogException( e );
                }
            }
            userData = userData ?? JSONObject.Create( JSONObject.Type.OBJECT );
            userData.SetField( "checkhash", String.Format( "{0:X8}", dependenceHash ) );
            var oldUserData = shaderImporter.userData ?? String.Empty;
            var newUserData = userData.Print();
            if ( oldUserData != newUserData ) {
                shaderImporter.userData = newUserData;
                EditorUtility.SetDirty( shaderImporter );
            }
            return true;
        }
#endif

        static PropDataTree UpdateShaderFileInternal( String shaderPath, ref Dictionary<String, PropDataTree> treeDict, String refGroup = null, Stack<String> stack = null ) {
            if ( !File.Exists( shaderPath ) ) {
                return null;
            }
            if ( String.IsNullOrEmpty( refGroup ) ) {
                // 如果外部请求分组为空，改为请求全部分组
                refGroup = AllGroupName;
            }
            var shaderPropData = GetIncludeFiles( shaderPath );
            if ( shaderPropData == null || String.IsNullOrEmpty( shaderPropData.sourcePropText ) ) {
                return null;
            }
            PropDataTree tree;
            Dictionary<String, String> defines = null;
            List<String> define_sources = null;
            treeDict = treeDict ?? new Dictionary<String, PropDataTree>();
            if ( !treeDict.TryGetValue( shaderPath, out tree ) ) {
                // 分析静态分组内容
                tree = new PropDataTree();
                tree.shaderPath = shaderPath;
                tree.source = shaderPropData.sourcePropText;
                tree.newSource = null;
                tree.text = shaderPropData.text;
                tree.sourceStart = shaderPropData.insertStart;
                tree.sourceEnd = shaderPropData.insertEnd;
                tree.children = new List<PropDataGroupNode>();
                tree.children.Add(
                    new PropDataGroupNode {
                        groupName = DefaultGroupName,
                        shaderPath = shaderPath,
                    }
                );
                var lastIncludeShaderName = String.Empty;
                var lines = tree.source.Split( '\n' );
                var curGroupName = DefaultGroupName;
                var curGroup = tree.children[ 0 ];
                Func<String, bool> updateGroupFunc = groupName => {
                    if ( !String.IsNullOrEmpty( groupName ) && groupName != curGroupName && groupName != AllGroupName ) {
                        if ( !groupName.EndsWith( " end", StringComparison.CurrentCultureIgnoreCase ) ) {
                            curGroupName = groupName;
                            curGroup = tree.children.Find( e => e.groupName == curGroupName );
                            if ( curGroup == null ) {
                                curGroup = new PropDataGroupNode();
                                curGroup.groupName = curGroupName;
                                curGroup.shaderPath = shaderPath;
                                tree.children.Add( curGroup );
                            }
                        } else {
                            curGroupName = DefaultGroupName;
                            curGroup = tree.children[ 0 ];
                        }
                        return true;
                    }
                    return false;
                };
                for ( int i = 0; i < lines.Length; ++i ) {
                    var processed = false;
                    var line = lines[ i ].Trim();
                    if ( String.IsNullOrEmpty( line ) ) {
                        continue;
                    }
                    // 解析分组头
                    var headerMatch = Reg_PropHeader.Match( line );
                    if ( headerMatch.Success ) {
                        if ( headerMatch.Groups.Count > 1 ) {
                            var groupName = headerMatch.Groups[ 1 ].Value;
                            if ( !String.IsNullOrEmpty( groupName ) ) {
                                updateGroupFunc( groupName );
                                curGroup.editors = curGroup.editors ?? new List<STuple<String, PropGroupRef>>();
                                curGroup.editors.Add( STuple.Create( lines[ i ], new PropGroupRef { group = groupName } ) );
                                processed = true;
                            }
                        }
                    } else if ( line.StartsWith( "//" ) ) {
                        // 解析预编译命令
                        var cmdProcessed = false;
                        var cmdMatch = Reg_Command.Match( line );
                        if ( cmdMatch.Success && cmdMatch.Groups.Count > 1 ) {
                            var cmd = cmdMatch.Groups[ 1 ].Value;
                            var value = String.Empty;
                            cmdProcessed = true;
                            if ( cmdMatch.Groups.Count > 3 ) {
                                value = cmdMatch.Groups[ 3 ].Value;
                            }
                            switch ( cmd ) {
                            case "region":
                                updateGroupFunc( value );
                                break;
                            case "endregion": {
                                    if ( String.IsNullOrEmpty( value ) ) {
                                        curGroupName = DefaultGroupName;
                                        curGroup = tree.children[ 0 ];
                                    } else {
                                        if ( curGroupName == value ) {
                                            updateGroupFunc( value + " end" );
                                        } else {
                                            Debug.LogErrorFormat( "endregion '{0}' failed, current is '{1}'.", value, curGroupName );
                                        }
                                    }
                                }
                                break;
                            case "include": {
                                    if ( String.IsNullOrEmpty( value ) ) {
                                        break;
                                    }
                                    var path = value;
                                    if ( !String.IsNullOrEmpty( path ) ) {
                                        var split = path.LastIndexOf( ':' );
                                        var group = AllGroupName;
                                        if ( split > 0 ) {
                                            group = path.Substring( split + 1 ).Trim();
                                            path = path.Substring( 0, split ).Trim();
                                        }
                                        var shaderRefPath = path;
                                        if ( path == Macro_LastIncludeFile && !String.IsNullOrEmpty( lastIncludeShaderName ) ) {
                                            path = lastIncludeShaderName;
                                        } else {
                                            var m = Reg_MacroRefValue.Match( path );
                                            for (; ; ) {
                                                if ( m.Success && m.Groups.Count > 1 ) {
                                                    var name = m.Groups[ 1 ].Value;
                                                    String _value;
                                                    if ( defines != null && defines.TryGetValue( name, out _value ) ) {
                                                        path = _value;
                                                    } else {
                                                        Debug.LogErrorFormat( "unrecognized identifier '{0}'", name );
                                                    }
                                                }
                                                lastIncludeShaderName = path;
                                                break;
                                            }
                                        }
                                        var shader = SearchShader( path );
                                        if ( shader != null ) {
                                            var includeShaderPath = AssetDatabase.GetAssetPath( shader );
                                            if ( String.IsNullOrEmpty( includeShaderPath ) ) {
                                                continue;
                                            }
                                            updateGroupFunc( group );
                                            curGroup.editors = curGroup.editors ?? new List<STuple<String, PropGroupRef>>();
                                            curGroup.editors.Add(
                                                STuple.Create<String, PropGroupRef>( null,
                                                    new PropGroupRef {
                                                        shaderAssetPath = includeShaderPath,
                                                        sourceShaderRef = shaderRefPath,
                                                        group = group
                                                    }
                                                )
                                            );
                                        }
                                    }
                                }
                                break;
                            case "define": {
                                    var split = value.IndexOfAny( DefineSpliters );
                                    if ( split >= 0 ) {
                                        var v = value.Substring( split + 1 ).Trim();
                                        var name = value.Substring( 0, split ).Trim();
                                        if ( defines != null ) {
                                            if ( !defines.ContainsKey( name ) ) {
                                                defines.Add( name, v );
                                            }
                                        } else {
                                            defines = new Dictionary<String, String>();
                                            defines.Add( name, v );
                                        }
                                        define_sources = define_sources ?? new List<String>();
                                        define_sources.Add( lines[ i ].TrimEnd() );
                                    }
                                }
                                break;
                            case "undef":
                                if ( defines != null && !String.IsNullOrEmpty( value ) &&
                                    !defines.Remove( value ) ) {
                                    Debug.LogErrorFormat( "unrecognized identifier '{0}' for 'undef' command.", value );
                                } else {
                                    define_sources = define_sources ?? new List<String>();
                                    define_sources.Add( lines[ i ].TrimEnd() );
                                }
                                break;
                            case "checkhash":
                                break;
                            default:
                                cmdProcessed = false;
                                break;
                            }
                        }
                        processed |= cmdProcessed;
                    }
                    if ( !processed ) {
                        // 保留原始行内容，不包括4个斜杠后内容
                        if ( !line.StartsWith( "////" ) ) {
                            curGroup.editors = curGroup.editors ?? new List<STuple<String, PropGroupRef>>();
                            curGroup.editors.Add( STuple.Create( lines[ i ], new PropGroupRef() ) );
                        }
                    }
                }
            }
            if ( !tree.editorDataIsReady ) {
                var fullIncludeMode = false;
                // 处理包含文件
                for ( int i = 0; i < tree.children.Count; ++i ) {
                    var group = tree.children[ i ];
                    if ( !String.IsNullOrEmpty( refGroup ) &&
                        refGroup != group.groupName &&
                        refGroup != AllGroupName ) {
                        // 如果外部请求指定分组，跳过非指定分组以提高效率
                        continue;
                    }
                    if ( group.editors == null ) {
                        // 如果当前组没有编辑器信息，标记解析完成
                        group.editorDataIsReady = true;
                        continue;
                    }
                    if ( group.editors != null && !group.editorDataIsReady ) {
                        for ( int j = 0; j < group.editors.Count; ++j ) {
                            var e = group.editors[ j ];
                            if ( e.Item1 == null && !String.IsNullOrEmpty( e.Item2.shaderAssetPath ) ) {
                                // 找到每个分组里面的引用关联, 只处理其中一个
                                var includePath = e.Item2.shaderAssetPath;
                                var includeGroup = e.Item2.group;
                                String stackCheckKey;
                                if ( !String.IsNullOrEmpty( includeGroup ) ) {
                                    stackCheckKey = String.Format( "{0} : {1}", includePath, includeGroup );
                                } else {
                                    stackCheckKey = includePath;
                                }
                                if ( stack.Contains( stackCheckKey ) ) {
                                    // 循环依赖
                                    Debug.LogErrorFormat( "Can not include itself: {0}", shaderPath );
                                    foreach ( var v in stack ) {
                                        Debug.LogError( v );
                                    }
                                    continue;
                                }
                                stack.Push( stackCheckKey );
                                var ed = UpdateShaderFileInternal( includePath, ref treeDict, includeGroup, stack );
                                var cur = stack.Pop();
                                Debug.Assert( cur == stackCheckKey );
                                if ( ed != null ) {
                                    if ( !String.IsNullOrEmpty( includeGroup ) && includeGroup != AllGroupName ) {
                                        // 替换当前组
                                        var refEditors = ed.children.Find( g => g.groupName == includeGroup );
                                        if ( refEditors != null ) {
                                            Debug.Assert( refEditors.editorDataIsReady );
                                            group.editors.Clear();
                                            // 保留组包含源信息
                                            group.editors.Add( e );
                                            // 包含引用内容，排除引用项
                                            if ( refEditors.editors != null ) {
                                                group.editors.AddRange(
                                                    refEditors.editors.Where(
                                                        item => {
                                                            return !String.IsNullOrEmpty( item.Item1 );
                                                        }
                                                    ).ToList()
                                                );
                                            }
                                        } else {
                                            Debug.LogErrorFormat( "UnitMaterialEditor include file group not found! {0} : {1}", includePath, includeGroup );
                                        }
                                    } else {
                                        // 包含所有组，包括默认分组
                                        Debug.Assert( ed.editorDataIsReady );
                                        group.editors.Clear();
                                        group.editors.Add( e );

                                        var useOriginalGroup = false;
                                        if ( tree.children[ 0 ] == group &&
                                            group.groupName == DefaultGroupName && j == 0 &&
                                            tree.children[ 0 ].editors.Count > 0 &&
                                            tree.children[ 0 ].editors[ 0 ].Item2.group == AllGroupName ) {
                                            // 当前只有一个默认分组，全包含模式会使用原始分组
                                            useOriginalGroup = true;
                                            fullIncludeMode = true;
                                            tree.children.Resize( 1 );
                                        }

                                        for ( int g = 0; g < ed.children.Count; ++g ) {
                                            var refEditors = ed.children[ g ];
                                            Debug.Assert( refEditors.editorDataIsReady );
                                            if ( refEditors.editors != null ) {
                                                var targetGroup = group;
                                                if ( useOriginalGroup ) {
                                                    // 全包含模式，保留分组信息
                                                    targetGroup = tree.children.Find( _g => _g.groupName == refEditors.groupName );
                                                    if ( targetGroup == null ) {
                                                        targetGroup = new PropDataGroupNode();
                                                        targetGroup.groupName = refEditors.groupName;
                                                        targetGroup.shaderPath = shaderPath;
                                                        targetGroup.editorDataIsReady = true;
                                                        tree.children.Add( targetGroup );
                                                    }
                                                }
                                                foreach ( var editor in refEditors.editors ) {
                                                    if ( String.IsNullOrEmpty( editor.Item1 ) ) {
                                                        // 跳过非编辑器内容，排除引用标记，统一使用当前同一个包含引用信息e
                                                        Debug.Assert( !String.IsNullOrEmpty( editor.Item2.shaderAssetPath ) );
                                                        continue;
                                                    }
                                                    if ( String.IsNullOrEmpty( editor.Item2.shaderAssetPath ) &&
                                                        !String.IsNullOrEmpty( editor.Item2.group ) ) {
                                                        // 丢弃Header分组源信息
                                                        Debug.Assert( !String.IsNullOrEmpty( editor.Item1 ) );
                                                        continue;
                                                    }
                                                    targetGroup.editors = targetGroup.editors ?? new List<STuple<String, PropGroupRef>>();
                                                    targetGroup.editors.Add( editor );
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Debug.LogErrorFormat( "UnitMaterialEditor include file not found! {0} : {1}", includePath );
                                }
                                break;
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
                    var newLines = new List<String>();
                    var defineLineOffset = 0;

                    if ( define_sources != null ) {
                        // 定义变量头
                        var defCount = define_sources.Count;
                        for ( int d = 0; d < defCount; ++d ) {
                            var def = define_sources[ d ];
                            if ( d < defCount - 1 ) {
                                newLines.Add( def );
                            } else {
                                newLines.Add( def + Environment.NewLine );
                            }
                            ++defineLineOffset;
                        }
                    }
                    // 跳过默认组，最后处理
                    for ( int i = 1; i <= tree.children.Count; ++i ) {
                        var group = tree.children[ i % tree.children.Count ];
                        if ( group.editors == null ) {
                            continue;
                        }
                        String firstLineInGroup = null;
                        var groupStartIndex = newLines.Count;
                        var refIndex = -1;
                        for ( int j = 0; j < group.editors.Count; ++j ) {
                            var e = group.editors[ j ];
                            if ( !String.IsNullOrEmpty( e.Item1 ) ) {
                                newLines.Add( e.Item1.TrimEnd() );
                                if ( firstLineInGroup == null ) {
                                    // 记录一组编辑器中第一行字符串，后面用于提取行起始间距
                                    firstLineInGroup = e.Item1;
                                }
                            } else {
                                refIndex = newLines.Count;
                                var refShaderPath = e.Item2.shaderAssetPath;
                                var shader = AssetDatabase.LoadAssetAtPath<Shader>( refShaderPath );
                                if ( shader != null ) {
                                    // 改写shader名字
                                    refShaderPath = shader.name;
                                } else {
                                    Debug.LogErrorFormat( "shader not found: {0}.", refShaderPath );
                                }
                                // 如果使用了宏的话，反向解析一次看能否对应的上
                                refShaderPath = e.Item2.sourceShaderRef;
                                if ( refShaderPath != Macro_LastIncludeFile ) {
                                    var m = Reg_MacroRefValue.Match( refShaderPath );
                                    for (; ; ) {
                                        // 如果关联信息使用宏，测试是否在当前文件定义，否则会被展开
                                        if ( m.Success && m.Groups.Count > 1 ) {
                                            var name = m.Groups[ 1 ].Value;
                                            String _value;
                                            if ( defines != null && defines.TryGetValue( name, out _value ) ) {
                                                if ( SearchShader( _value ) == shader ) {
                                                    // 匹配，可以继续使用宏定义
                                                    break;
                                                }
                                            }
                                        }
                                        // 没有定义，或者不匹配，展开宏
                                        refShaderPath = MakeShaderSearchKey( shader );
                                        break;
                                    }
                                }
                                // 重新整合包含头信息，注意这里没有行间距
                                if ( !String.IsNullOrEmpty( e.Item2.group ) && e.Item2.group != AllGroupName ) {
                                    newLines.Add( String.Format( "// #include {0} : {1}", refShaderPath, e.Item2.group ) );
                                } else {
                                    newLines.Add( String.Format( "// #include {0}", refShaderPath ) );
                                }
                            }
                        }
                        if ( firstLineInGroup != null ) {
                            var leading = String.Empty;
                            var trim = firstLineInGroup.TrimStart();
                            if ( trim.Length < firstLineInGroup.Length ) {
                                leading = firstLineInGroup.Substring( 0, firstLineInGroup.Length - trim.Length );
                            }
                            if ( refIndex >= 0 && leading.Length > 0 ) {
                                // 追加行间距
                                newLines[ refIndex ] = leading + newLines[ refIndex ];
                            }
                            if ( String.IsNullOrEmpty( group.groupName ) ) {
                                group.groupName = DefaultGroupName;
                                Debug.Assert( i == tree.children.Count );
                            }
                            newLines.Insert( groupStartIndex, String.Format( "{0}// #region {1}", leading, group.groupName ) );
                            newLines.Add( String.Format( "{0}// #endregion {1}{2}", leading, group.groupName, System.Environment.NewLine ) );
                        }
                    }
                    if ( fullIncludeMode ) {
                        var c = tree.children[ 0 ];
                        var e = tree.children[ 0 ].editors[ 0 ];
                        Debug.Assert( c.groupName == DefaultGroupName || c.groupName == AllGroupName );
                        Debug.Assert( tree.children[ 0 ].editors.Count == 1 );
                        Debug.Assert( !String.IsNullOrEmpty( e.Item2.shaderAssetPath ) && e.Item1 == null );
                        var lastLineIndex = newLines.Count - 1;
                        if ( lastLineIndex - 1 >= 0 ) {
                            // 取最后一行包含命令上一行的行间距
                            var preLastLine = newLines[ lastLineIndex - 1 ];
                            var trim = preLastLine.TrimStart();
                            if ( trim.Length < preLastLine.Length ) {
                                // 追加行间距
                                var leading = preLastLine.Substring( 0, preLastLine.Length - trim.Length );
                                newLines[ lastLineIndex ] = leading + newLines[ lastLineIndex ];
                            }
                        }
                        // 把最后一行包含命令交换到编辑器定义之前，宏定义之后
                        if ( lastLineIndex > 0 ) {
                            var lastLine = newLines[ lastLineIndex ];
                            newLines.RemoveAt( lastLineIndex );
                            newLines.Insert( defineLineOffset, lastLine );
                        }
                    }
                    if ( shaderPropData.allIncludeShaderNames != null && shaderPropData.allIncludeShaderNames.Count > 1 ) {
                        var leading = "\t\t//// ";
                        var count = shaderPropData.allIncludeShaderNames.Count;
                        newLines.Add( leading + "AUTO GENERATED. DO NOT MODIFY!" );
                        newLines.Add( leading + "DEPENDENCIES:" );
#if !SAVE_SOURCECHECKHASH_TO_META
                        newLines.Add( String.Format( "{0}#checkhash {1:X8}", leading, shaderPropData.dependenceHash ) );
#else
                        _SaveDependenceHashToMeta( shaderPath, shaderPropData.dependenceHash );
#endif
                        for ( int i = 0; i < count; ++i ) {
                            var shaderName = shaderPropData.allIncludeShaderNames[ i ];
                            var shader = Shader.Find( shaderName );
                            if ( shader != null ) {
                                var shaderAssetPath = AssetDatabase.GetAssetPath( shader );
                                newLines.Add( String.Format( "{0}{1}", leading, shaderAssetPath ) );
                            }
                        }
                        newLines.Add( leading + "END DEPENDENCIES" + Environment.NewLine );
                    }
                    tree.newSource = String.Join( System.Environment.NewLine, newLines.ToArray() );
                    tree.newSource = tree.newSource.Replace( "\t", "    " );
                }
            }
            return tree;
        }

        static bool UpdateShader_SaveAll = false;
        static bool UpdateShader( String shaderPath, Action onFinish = null, bool batchMode = false, bool withSaveAll = false, params KeyValuePair<String, Action<int>>[] extraButtons ) {
            var ret = false;
            var stack = new Stack<String>();
            if ( !withSaveAll ) {
                UpdateShader_SaveAll = false;
            }
            try {
                stack.Push( shaderPath );
                Dictionary<String, PropDataTree> treeDict = null;
                var data = UpdateShaderFileInternal( shaderPath, ref treeDict, null, stack );
                while ( data != null && data.sourceStart >= 0 ) {
                    if ( data.newSource == data.source ) {
                        ShaderPropDataSource dataSource;
                        s_ShaderPropSourceCache.TryGetValue( shaderPath, out dataSource );
                        Debug.Assert( dataSource != null );
                        if ( dataSource != null ) {
                            var info = dataSource.dependenceHash == dataSource.recordDependenceHash ?
                                String.Format( "{0} file is up-to-date.", shaderPath ) :
                                String.Format( "{0} file's dependenceHash has been updated. {1:X8} -> {2:X8}",
                                    shaderPath, dataSource.recordDependenceHash, dataSource.dependenceHash );
                            if ( batchMode ) {
                                Debug.Log( String.Format( "<color=#40ff00ff><b>{0}</b></color>", info ) );
                            } else {
                                EditorUtility.DisplayDialog( "UnitShaderGUI", info, "OK" );
                            }
#if SAVE_SOURCECHECKHASH_TO_META
                            // 强制更新依赖hash到meta
                            _SaveDependenceHashToMeta( shaderPath, dataSource.dependenceHash );
#endif
                            // 从缓存中删除，下次获取时再重新计算
                            s_ShaderPropSourceCache.Remove( shaderPath );
                        }
                        break;
                    }
                    var _left = data.text;
                    // 替换为新内容
                    data.text = data.text.Remove( data.sourceStart, data.sourceEnd - data.sourceStart );
                    data.text = data.text.Insert( data.sourceStart, data.newSource );
                    var _right = data.text;
                    var window = EditorWindow.GetWindow( typeof( CustomMessageBox ), true, "Shader Comparer: " + shaderPath ) as CustomMessageBox;
                    var pos = Vector2.zero;
                    if ( window != null ) {
                        window.Info = "";
                        window.minSize = new Vector2( 1000, 800 );
                        window.Show();
                        // 把每一行字符串，映射为一个单一字符，然后两个文件每一行对比，变成两个字符串逐字符对比
                        // Char这里是UInt16，对于一般规模的文件大小是够用的
                        var _StringLines = new List<String>();
                        var _String2Char = new Dictionary<String, int>();
                        var _Char2String = new Dictionary<int, String>();
                        var _leftLines = _left.Split( '\n' );
                        var _rightLines = _right.Split( '\n' );
                        Func<String, int> str2Char = s => {
                            int c;
                            if ( !_String2Char.TryGetValue( s, out c ) ) {
                                c = _StringLines.Count;
                                _String2Char.Add( s, c );
                                _StringLines.Add( s );
                            }
                            Debug.Assert( c <= Char.MaxValue );
                            return c;
                        };
                        Action<int> doSave = null;
                        var _leftSB = new StringBuilder();
                        var _rightSB = new StringBuilder();
                        Array.ForEach( _leftLines, s => _leftSB.Append( ( Char )str2Char( s ) ) );
                        Array.ForEach( _rightLines, s => _rightSB.Append( ( Char )str2Char( s ) ) );
                        var dmp = new DiffMatchPatch.diff_match_patch();
                        var diffs = dmp.diff_lineMode( _leftSB.ToString(), _rightSB.ToString(), DateTime.MaxValue );
                        var result = new List<STuple<String, DiffMatchPatch.Operation>>();
                        for ( int i = 0; i < diffs.Count; ++i ) {
                            var chars = diffs[ i ].text;
                            for ( int j = 0; j < chars.Length; ++j ) {
                                // 把字符转换为行字符串，并且保留操作类型
                                result.Add( STuple.Create( _StringLines[ chars[ j ] ], diffs[ i ].operation ) );
                            }
                        }
                        window.OnClose = null;
                        window.OnGUIFunc = () => {
                            EditorGUILayout.BeginVertical();
                            pos = EditorGUILayout.BeginScrollView( pos );
                            var diff = 0;
                            for ( int i = 0; i < result.Count; ++i ) {
                                var d = result[ i ];
                                if ( d.Item2 != DiffMatchPatch.Operation.EQUAL ) {
                                    ++diff;
                                    var color = Color.red;
                                    switch ( d.Item2 ) {
                                    case DiffMatchPatch.Operation.DELETE:
                                        color = Color.red;
                                        break;
                                    case DiffMatchPatch.Operation.INSERT:
                                        color = Color.green;
                                        break;
                                    default:
                                        color = Color.yellow;
                                        break;
                                    }
                                    using ( new GUISetColor( color ) ) {
                                        EditorGUILayout.LabelField( d.Item1 );
                                        var rt = GUILayoutUtility.GetLastRect();
                                        EditorGUI.DrawRect( rt, new Color( color.r, color.g, color.b, 0.25f ) );
                                    }
                                } else {
                                    EditorGUILayout.LabelField( d.Item1 );
                                }
                            }
                            EditorGUILayout.EndScrollView();
                            EditorGUILayout.EndVertical();
                            window.ReturnValue = diff;
                            if ( diff > 0 && UpdateShader_SaveAll ) {
                                try {
                                    if ( doSave != null ) {
                                        doSave( window.ReturnValue );
                                    }
                                } finally {
                                    EditorApplication.delayCall += () => window.Close();
                                }
                            }
                            return window.ReturnValue;
                        };
                        window.Buttons = new String[] { "Save", "Cancel" };
                        window.OnButtonClicks = new Action<int>[] {
                            retVal => {
                                if ( retVal > 0 ) {
                                    try {
                                        File.WriteAllText( shaderPath, data.text );
                                    } catch ( Exception e ) {
                                        Debug.LogException( e );
                                    }
                                    var info = String.Format( "Save {0} ok.", shaderPath );
                                    if ( batchMode ) {
                                        Debug.Log( String.Format( "<color=#40ff00ff><b>{0}</b></color>", info ) );
                                    } else {
                                        EditorUtility.DisplayDialog( "UnitShaderGUI", info, "OK" );
                                    }
                                } else {
                                    var info = String.Format( "{0} file is up-to-date.", shaderPath );
                                    if ( batchMode ) {
                                        Debug.Log( String.Format( "<color=#40ff00ff><b>{0}</b></color>", info ) );
                                    } else {
                                        EditorUtility.DisplayDialog( "UnitShaderGUI", info, "OK" );
                                    }
                                }
                            },
                            retVal => { },
                        };
                        if ( withSaveAll && batchMode ) {
                            doSave = window.OnButtonClicks[ 0 ];
                            Array.Resize( ref window.Buttons, window.Buttons.Length + 1 );
                            Array.Resize( ref window.OnButtonClicks, window.OnButtonClicks.Length + 1 );
                            window.Buttons[ 2 ] = window.Buttons[ 1 ];
                            window.OnButtonClicks[ 2 ] = window.OnButtonClicks[ 1 ];
                            window.Buttons[ 1 ] = "Save All";
                            window.OnButtonClicks[ 1 ] = retVal => {
                                UpdateShader_SaveAll = true;
                                doSave( retVal );
                            };
                        }
                        if ( extraButtons != null && extraButtons.Length > 0 ) {
                            var offset = window.Buttons.Length;
                            Array.Resize( ref window.Buttons, window.Buttons.Length + extraButtons.Length );
                            Array.Resize( ref window.OnButtonClicks, window.OnButtonClicks.Length + extraButtons.Length );
                            for ( int i = 0; i < extraButtons.Length; ++i ) {
                                window.Buttons[ offset + i ] = extraButtons[ i ].Key;
                                window.OnButtonClicks[ offset + i ] = extraButtons[ i ].Value;
                            }
                        }
                        if ( onFinish != null ) {
                            window.OnClose = ( button, returnValue ) => onFinish();
                        }
                        ret = true;
                    }
                    break;
                }
            } finally {
                var cur = stack.Pop();
                Debug.Assert( stack.Count == 0 && cur == shaderPath );
            }
            if ( !ret && onFinish != null ) {
                // 不需要更新，通知外部调用者完毕
                try {
                    onFinish();
                } catch ( Exception e ) {
                    Debug.LogException( e );
                }
            }
            return ret;
        }

        static void OpenTextWindow( String title, String content ) {
            var window = EditorWindow.GetWindow( typeof( CustomMessageBox ), true, "Shader Comparer" ) as CustomMessageBox;
            var pos = Vector2.zero;
            if ( window != null ) {
                window.Info = title;
                window.minSize = new Vector2( 1000, 800 );
                window.Show();
                window.OnGUIFunc = () => {
                    EditorGUILayout.BeginVertical();
                    pos = EditorGUILayout.BeginScrollView( pos );
                    EditorGUILayout.TextArea( content );
                    EditorGUILayout.EndScrollView();
                    EditorGUILayout.EndVertical();
                    return 0;
                };
                window.Buttons = new String[] { "OK" };
            }
        }

        static void RunCommand( String exec, String arg ) {
            var info = new System.Diagnostics.ProcessStartInfo();
            info.FileName = exec;
            info.Arguments = arg;
            info.UseShellExecute = false;
            var proc = new System.Diagnostics.Process();
            proc.StartInfo = info;
            proc.Start();
        }

        static void OpenShaderEditor( String shaderFilePath ) {
            if ( s_NotePadPlusPlusPath == null ) {
                if ( Application.platform == RuntimePlatform.WindowsEditor ) {
                    var disks = new String[] { "C:\\", "D:\\", "E:\\", "F:\\", "G:\\", "H:\\" };
                    for ( int i = 0; i < disks.Length; ++i ) {
                        var path = disks[ i ] + "Program Files\\Notepad++\\notepad++.exe";
                        if ( System.IO.File.Exists( path ) ) {
                            s_NotePadPlusPlusPath = path;
                        }
                    }
                }
            }
            if ( String.IsNullOrEmpty( s_NotePadPlusPlusPath ) ) {
                EditorUtility.OpenWithDefaultApp( shaderFilePath );
            } else {
                RunCommand( s_NotePadPlusPlusPath, shaderFilePath );
            }
        }

        private static String FormatCount( ulong count ) {
            string result;
            if ( count > 1000000000UL ) {
                result = ( count / 1000000000.0 ).ToString( "f2" ) + "B";
            } else if ( count > 1000000UL ) {
                result = ( count / 1000000.0 ).ToString( "f2" ) + "M";
            } else if ( count > 1000UL ) {
                result = ( count / 1000.0 ).ToString( "f2" ) + "k";
            } else {
                result = count.ToString();
            }
            return result;
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            m_MaterialEditor.SetDefaultGUIWidths();
            if ( !String.IsNullOrEmpty( m_shaderFilePath ) ) {
                EditorGUILayout.BeginVertical();
                EditorGUILayout.Separator();
                EditorGUILayout.BeginHorizontal();
                using ( new GUISetColor( m_dependenceChanged ? Color.red : Color.white ) ) {
                    if ( GUILayout.Button( "Update Shader" ) ) {
                        UpdateShader( m_shaderFilePath, () => Reset() );
                    }
                }
                var material = m_parent.materialEditor.target as Material;
                if ( GUILayout.Button( "Dump", GUILayout.Width( 60 ) ) ) {
                    var content = ShaderGUIHelper.DumpMaterial( material );
                    OpenTextWindow( "Dump Material", content );
                }
                if ( GUILayout.Button( "Tidy", GUILayout.Width( 60 ) ) ) {
                    RemoveEmptyProps( material );
                }
                if ( GUILayout.Button( "Open", GUILayout.Width( 60 ) ) ) {
                    Debug.LogFormat( "Open {0}", m_shaderFilePath );
                    OpenShaderEditor( m_shaderFilePath );
                }
                if ( GUILayout.Button( "Ping", GUILayout.Width( 60 ) ) ) {
                    EditorGUIUtility.PingObject( material.shader );
                }
                EditorGUILayout.EndHorizontal();

                var style = GUI.skin.GetStyle( "HelpBox" );
                var _richText = style.richText;
                style.richText = true;
                EditorGUILayout.HelpBox( m_info, MessageType.None );
                style.richText = _richText;

                if ( Event.current.type == EventType.MouseDown &&
                    GUILayoutUtility.GetLastRect().Contains( Event.current.mousePosition ) ) {
                    if ( Event.current.button == 1 ) {
                        var menu = new GenericMenu();
                        menu.AddItem(
                            new GUIContent( "Ping" ), false,
                            () => {
                                UnityEditor.EditorGUIUtility.PingObject( material.shader );
                            }
                        );
                        if ( m_dependenceFiles != null ) {
                            for ( int i = 0; i < m_dependenceFiles.Count; ++i ) {
                                menu.AddItem(
                                    new GUIContent( "Open: " + m_dependenceFiles[ i ].Key ), false,
                                    ( ud ) => {
                                        OpenShaderEditor( ud as String );
                                    },
                                    m_dependenceFiles[ i ].Value
                                );
                            }
                        }
                        if ( ShaderUtils.HasCodeSnippets( material.shader ) ) {
                            menu.AddItem(
                                new GUIContent( "Dump Actived Variants" ), false,
                                () => {
                                    var result = ShaderUtils.ParseShaderCombinations( material.shader, true );
                                    if ( result != null ) {
                                        result.Dump();
                                        var used = ShaderUtils.GetVariantCount( material.shader, true );
                                        var total = ShaderUtils.GetVariantCount( material.shader, false );
                                        Debug.LogFormat( "Shader '{0}' variant count: {1}/{2}", material.shader.name, FormatCount( used ), FormatCount( total ) );
                                    } else {
                                        Debug.LogWarningFormat( "Shader '{0}' has no ShaderCombinations.", material.shader.name );
                                    }
                                }
                            );
                            menu.AddItem(
                                new GUIContent( "Report Variant Count" ), false,
                                () => {
                                    var used = ShaderUtils.GetVariantCount( material.shader, true );
                                    var total = ShaderUtils.GetVariantCount( material.shader, false );
                                    Debug.LogFormat( "Shader '{0}' variant count: {1}/{2}", material.shader.name, FormatCount( used ), FormatCount( total ) );
                                }
                            );
                        } else {
                            menu.AddItem( new GUIContent( "Dump Passes" ), false, () => Debug.Log( ShaderUtils.DumpShaderPasses( material.shader ) ) );
                        }
                        if ( menu.GetItemCount() > 0 ) {
                            Event.current.Use();
                            menu.ShowAsContext();
                        }
                    }
                }
                
                EditorGUILayout.Separator();
                EditorGUILayout.EndVertical();
            }
            m_MaterialEditor.SetDefaultGUIWidths();
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_SourceHelper();
        }

        static bool s_UpdateAllShadersInProgress = false;

        [MenuItem( "Tools/UnitMaterialEditor/UpdateAllShaders" )]
        public static void UpdateAllShaders() {
            Debug.ClearDeveloperConsole();
            if ( s_UpdateAllShadersInProgress ) {
                Debug.LogError( "UnitMaterialEditor: UpdateAllShaders is processing." );
                return;
            }
            var allShaderInfo = ShaderUtil.GetAllShaderInfo();
            var updateList = new List<Shader>();
            for ( int i = 0; i < allShaderInfo.Length; ++i ) {
                var shader = Shader.Find( allShaderInfo[ i ].name );
                var shaderAssetPath = AssetDatabase.GetAssetPath( shader );
                if ( String.IsNullOrEmpty( shaderAssetPath ) || ShaderGUIHelper.IsUnityDefaultResource( shaderAssetPath ) ) {
                    continue;
                }
                updateList.Add( shader );
            }
            if ( updateList != null ) {
                int index = 0;
                int totalCount = updateList.Count;
                var updateShaderList = updateList;
                var totalFrame = 0;
                var waitForFrame = 0;
                var state = 0;
                var waitForUpdateWindow = false;
                var enableKeywordCheck = ShaderGUI_UpdateKeyword.EnableKeywordCheck;
                var sb = new StringBuilder();
                UpdateShader_SaveAll = false;
                Material workingMaterial = null;
                EditorApplication.CallbackFunction updateProcess = null;
                updateProcess = () => {
                    if ( index < 0 || index >= totalCount ) {
                        UpdateShader_SaveAll = false;
                        s_UpdateAllShadersInProgress = false;
                        EditorApplication.update -= updateProcess;
                        ShaderGUI_UpdateKeyword.EnableKeywordCheck = enableKeywordCheck;
                        if ( workingMaterial != null ) {
                            UnityEngine.Object.DestroyImmediate( workingMaterial );
                            workingMaterial = null;
                        }
                        EditorUtility.ClearProgressBar();
                        EditorUtility.DisplayDialog( "UnitMaterialEditor", "UpdateAllShaders done.", "OK" );
                        return;
                    }
                    try {
                        var shader = updateShaderList[ index ];
                        var shaderAssetPath = AssetDatabase.GetAssetPath( shader );
                        var progressInfo = String.Format( "[{0}%]Update Shader: {1}{2}",
                            index * 100 / totalCount, shaderAssetPath, new String( '.', totalFrame % 4 ) );
                        if ( EditorUtility.DisplayCancelableProgressBar( "UnitMaterialEditor", progressInfo, ( float )index / totalCount ) ) {
                            index = -1;
                            return;
                        }
                        ++totalFrame;
                        if ( waitForFrame > 0 || waitForUpdateWindow ) {
                            --waitForFrame;
                            return;
                        }
                        switch ( state ) {
                        case 0: {
                                if ( workingMaterial != null ) {
                                    UnityEngine.Object.DestroyImmediate( workingMaterial );
                                    workingMaterial = null;
                                }
                                Debug.LogFormat( "<color=#ff8000ff>Init ShaderGUI for shader: '{0}'</color>", shader.name );
                                ShaderGUI_UpdateKeyword.EnableKeywordCheck = true;
                                workingMaterial = new Material( shader );
                                Selection.activeObject = workingMaterial;
                                waitForFrame = 1;
                                ++state;
                            }
                            break;
                        case 1: {
                                if ( UnitMaterialEditor.curMaterialEditor == null || UnitMaterialEditor.curShaderGUI == null ) {
                                    goto NEXT;
                                }
                                var _workingMaterial = workingMaterial;
                                var material = UnitMaterialEditor.curMaterialEditor.target as Material;
                                var helper = UnitMaterialEditor.curShaderGUI.FindPropEditor<ShaderGUI_SourceHelper>();
                                if ( material != _workingMaterial || helper == null ) {
                                    goto NEXT;
                                }
                                String editorData;
                                List<String> includeFiles;
                                ShaderPropDataSource dataSource;
                                var newTimestamp = GetShaderEditorDataLastWriteTime( shaderAssetPath, out editorData, out dataSource, out includeFiles );
                                Debug.Assert( includeFiles != null );
                                sb.Length = 0;
                                if ( includeFiles != null ) {
                                    sb.AppendFormat( "Update shader source: '{0}'", shader.name ).AppendLine();
                                    for ( int i = 0; i < includeFiles.Count; ++i ) {
                                        sb.Append( "<color=#00ff00ff>" ).Append( includeFiles[ i ] ).Append( "</color>" ).AppendLine();
                                    }
                                    Debug.Log( sb.ToString() );
                                    if ( dataSource != null && dataSource.dependenceHash != dataSource.recordDependenceHash ) {
                                        waitForUpdateWindow = UpdateShader(
                                            shaderAssetPath,
                                            () => {
                                                waitForUpdateWindow = false;
                                                helper.Reset();
                                            },
                                            true, true,
                                            new KeyValuePair<String, Action<int>>( "Abort", button => index = -1 )
                                        );
                                    }
                                }
                                goto NEXT;
                            }
                        }
                        return;
                    NEXT:
                        state = 0;
                        ++index;
                    } catch ( Exception e ) {
                        index = -1;
                        Debug.LogException( e );
                    }
                };
                s_UpdateAllShadersInProgress = true;
                EditorApplication.update += updateProcess;
            }
        }
    }
}
