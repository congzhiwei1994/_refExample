using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public static class ShaderGUIHelper {

        public static bool Compare( String op, int a, int b ) {
            switch ( op ) {
            case "==":
                return a == b;
            case "!=":
                return a != b;
            case "<":
                return a < b;
            case "<=":
                return a <= b;
            case ">":
                return a > b;
            case ">=":
                return a >= b;
            case "&&":
                return a == 1 && b == 1;
            case "||":
                return a == 1 || b == 1;
            }
            return false;
        }

        public static bool Compare( String op, float a, float b ) {
            switch ( op ) {
            case "==":
                return a == b;
            case "!=":
                return a != b;
            case "<":
                return a < b;
            case "<=":
                return a <= b;
            case ">":
                return a > b;
            case ">=":
                return a >= b;
            }
            return false;
        }

        public static bool Compare( String op, String a, String b ) {
            switch ( op ) {
            case "==":
                return a == b;
            case "!=":
                return a != b;
            case "<":
                return a.CompareTo( b ) < 0;
            case "<=":
                return a.CompareTo( b ) <= 0;
            case ">":
                return a.CompareTo( b ) > 0;
            case ">=":
                return a.CompareTo( b ) >= 0;
            }
            return false;
        }

        public static bool Compare( String op, Vector4 a, Vector4 b, int mask = 0xff ) {
            if ( mask == 0 ) {
                return false;
            }
            if ( op == "!=" ) {
                for ( int i = 0; i < 4; ++i ) {
                    if ( ( mask & ( 1 << i ) ) != 0 ) {
                        if ( a[ i ] != b[ i ] ) {
                            return true;
                        }
                    }
                }
                return false;
            } else {
                for ( int i = 0; i < 4; ++i ) {
                    if ( ( mask & ( 1 << i ) ) != 0 ) {
                        switch ( op ) {
                        case "==":
                            if ( a[ i ] != b[ i ] ) {
                                return false;
                            }
                            break;
                        case "<":
                            if ( a[ i ] >= b[ i ] ) {
                                return false;
                            }
                            break;
                        case "<=":
                            if ( a[ i ] > b[ i ] ) {
                                return false;
                            }
                            break;
                        case ">":
                            if ( a[ i ] <= b[ i ] ) {
                                return false;
                            }
                            break;
                        case ">=":
                            if ( a[ i ] < b[ i ] ) {
                                return false;
                            }
                            break;
                        }
                    }
                }
            }
            return true;
        }

        public static bool EnableParseErrorChecking = true;

        static void ParseErrorCheck( UnitMaterialEditor gui, String fieldName, JSONObject value ) {
            if ( value != null && EnableParseErrorChecking ) {
                Debug.LogErrorFormat( "{0}: parse '{1}' failed.", gui.ToString(), fieldName );
            }
        }

        public static bool ParseValue( UnitMaterialEditor gui, JSONObject obj, String fieldName, out String value ) {
            var v = obj.GetField( fieldName );
            if ( v != null && v.type == JSONObject.Type.STRING ) {
                value = v.str;
                return true;
            }
            value = String.Empty;
            return false;
        }

        public static bool ParseValue( UnitMaterialEditor gui, JSONObject obj, String fieldName, out int value ) {
            var v = obj.GetField( fieldName );
            if ( v != null && v.IsNumber ) {
                value = ( int )v.i;
                return true;
            }
            ParseErrorCheck( gui, fieldName, v );
            value = 0;
            return false;
        }

        public static bool ParseValue( UnitMaterialEditor gui, JSONObject obj, String fieldName, out bool value ) {
            var v = obj.GetField( fieldName );
            if ( v != null && v.IsBool ) {
                value = v.b;
                return true;
            }
            ParseErrorCheck( gui, fieldName, v );
            value = false;
            return false;
        }

        public static bool ParseValue( UnitMaterialEditor gui, JSONObject obj, String fieldName, out float value ) {
            var v = obj.GetField( fieldName );
            if ( v != null && v.IsNumber ) {
                value = v.n;
                return true;
            }
            ParseErrorCheck( gui, fieldName, v );
            value = 0;
            return false;
        }

        public static bool ParseValue( UnitMaterialEditor gui, JSONObject obj, String fieldName, out Vector4 value, out int mask ) {
            var v = obj.GetField( fieldName );
            mask = 0;
            if ( v != null && v.IsArray ) {
                var ret = new Vector4();
                for ( int i = 0; i < v.Count && i < 4; ++i ) {
                    if ( v[ i ].IsNumber ) {
                        mask |= 1 << i;
                        ret[ i ] = v[ i ].n;
                    }
                }
                if ( mask != 0 ) {
                    value = ret;
                    return true;
                }
            }
            ParseErrorCheck( gui, fieldName, v );
            value = Vector4.zero;
            return false;
        }

        public static int MixColorValue( ref Color a, Color b, int mask ) {
            if ( mask > 0 ) {
                var count = 0;
                for ( int i = 0; i < 4; ++i ) {
                    if ( ( mask & ( 1 << i ) ) != 0 ) {
                        a[ i ] = b[ i ];
                        ++count;
                    }
                }
                return count;
            }
            return 0;
        }

        public static int MixVectorValue( ref Vector4 a, Vector4 b, int mask ) {
            if ( mask > 0 ) {
                var count = 0;
                for ( int i = 0; i < 4; ++i ) {
                    if ( ( mask & ( 1 << i ) ) != 0 ) {
                        a[ i ] = b[ i ];
                        ++count;
                    }
                }
                return count;
            }
            return 0;
        }

        public static bool TryParseVector4( UnitMaterialEditor gui, JSONObject obj, String fieldName, ref Vector4 value, out int comp ) {
            var v = obj.GetField( fieldName );
            comp = 0;
            if ( v != null ) {
                if ( v.IsArray ) {
                    for ( int i = 0; i < v.Count; ++i ) {
                        if ( v[ i ].IsNumber ) {
                            value[ i ] = v[ i ].n;
                            ++comp;
                        } else {
                            break;
                        }
                    }
                    if ( comp > 0 ) {
                        return true;
                    }
                } else if ( v.IsNumber ) {
                    value[ 0 ] = v.f;
                    comp = 1;
                    return true;
                } else if ( v.IsBool ) {
                    value[ 0 ] = v.b ? 1 : 0;
                    comp = 1;
                    return true;
                }
            }
            return false;
        }

        public static int ExcuteLogicOp( UnitMaterialEditor gui, MaterialProperty prop, MaterialProperty[] props, JSONObject args ) {
            var _op = String.Empty;
            args.GetField( out _op, UnitMaterialEditor.Cfg.ArgsKey_OP, "==" );
            if ( prop == null ) {
                var ret = -1;
                String _id0, _id1;
                if ( args.GetField( out _id0, UnitMaterialEditor.Cfg.ArgsKey_OP_Arg0, String.Empty ) ) {
                    String ret0;
                    var _0 = EvalLogicOpArg( gui, _id0, props, out ret0 );
                    var argIndex = 1;
                    while ( args.GetField( out _id1, UnitMaterialEditor.Cfg.ArgsKey_OP_ArgPrefix + argIndex.ToString(), String.Empty ) ) {
                        String ret1;
                        var _1 = EvalLogicOpArg( gui, _id1, props, out ret1 );
                        if ( _0 != -1 && _1 != -1 ) {
                            ret = Compare( _op, _0, _1 ) ? 1 : 0;
                        } else {
                            if ( ret0 != null && ret1 != null ) {
                                ret = Compare( _op, ret0, ret1 ) ? 1 : 0;
                            }
                        }
                        if ( _op != "&&" && _op != "||" ) {
                            break;
                        } else {
                            if ( _op == "&&" ) {
                                if ( ret != 1 ) {
                                    break;
                                }
                            } else if ( _op == "||" ) {
                                if ( ret == 1 ) {
                                    break;
                                }
                            }
                        }
                        ++argIndex;
                        _0 = _1;
                        ret0 = ret1;
                    }
                }
                return ret;
            }
            if ( !prop.hasMixedValue ) {
                switch ( prop.type ) {
                case MaterialProperty.PropType.Texture: {
                        var lh = prop.textureValue != null ? 1 : 0;
                        int rh;
                        if ( !ShaderGUIHelper.ParseValue( gui, args, UnitMaterialEditor.Cfg.ArgsKey_OP_Ref, out rh ) ) {
                            rh = 1;
                        }
                        return ShaderGUIHelper.Compare( _op, lh, rh ) ? 1 : 0;
                    }
                case MaterialProperty.PropType.Vector: {
                        Vector4 rh;
                        int mask;
                        if ( ShaderGUIHelper.ParseValue( gui, args, UnitMaterialEditor.Cfg.ArgsKey_OP_Ref, out rh, out mask ) ) {
                            return ShaderGUIHelper.Compare( _op, prop.vectorValue, rh, mask ) ? 1 : 0;
                        }
                    }
                    break;
                case MaterialProperty.PropType.Color: {
                        Vector4 rh;
                        int mask;
                        if ( ShaderGUIHelper.ParseValue( gui, args, UnitMaterialEditor.Cfg.ArgsKey_OP_Ref, out rh, out mask ) ) {
                            return ShaderGUIHelper.Compare( _op, prop.colorValue, rh, mask ) ? 1 : 0;
                        }
                    }
                    break;
                case MaterialProperty.PropType.Range:
                case MaterialProperty.PropType.Float: {
                        float rh = 0;
                        ShaderGUIHelper.ParseValue( gui, args, UnitMaterialEditor.Cfg.ArgsKey_OP_Ref, out rh );
                        return ShaderGUIHelper.Compare( _op, prop.floatValue, rh ) ? 1 : 0;
                    }
                }
            }
            return -1;
        }

        public static bool? IsModeMatched( UnitMaterialEditor gui, JSONObject args ) {
            String mode;
            var modeMatched = true;
            if ( args != null && args.GetField( out mode, UnitMaterialEditor.Cfg.ArgsKey_Mode, String.Empty ) ) {
                var renderMode = gui.FindPropEditor<ShaderGUI_RenderMode>();
                if ( renderMode != null && !String.IsNullOrEmpty( mode ) ) {
                    var names = mode.Split( '|' );
                    modeMatched = false;
                    for ( int i = 0; i < names.Length; ++i ) {
                        if ( renderMode._PropMode.hasMixedValue ) {
                            return null;
                        }
                        var name = names[ i ].Trim();
                        if ( name.Equals( renderMode._Mode.ToString(), StringComparison.OrdinalIgnoreCase ) ) {
                            modeMatched = true;
                            break;
                        }
                    }
                }
            }
            return modeMatched;
        }

        public static int EvalLogicOpArg( UnitMaterialEditor gui, String express, MaterialProperty[] props ) {
            String returnValue;
            return EvalLogicOpArg( gui, express, props, out returnValue );
        }

        public static int EvalLogicOpArg( UnitMaterialEditor gui, String express, MaterialProperty[] props, out String returnValue ) {
            returnValue = null;
            if ( !String.IsNullOrEmpty( express ) ) {
                var m = UnitMaterialEditor.Reg_LogicRef.Match( express );
                if ( m.Success && m.Groups.Count > 2 ) {
                    var rev = m.Groups[ 1 ].ToString().Trim() == "!";
                    var id = m.Groups[ 2 ].ToString().Trim();
                    if ( !String.IsNullOrEmpty( id ) ) {
                        var ui = gui.FindPropEditor<UnitMaterialEditor>( id );
                        if ( ui != null ) {
                            var _b = ui.GetLogicOpResult( out returnValue, props );
                            if ( _b == null ) {
                                return -1;
                            }
                            var b = _b.Value;
                            if ( rev ) {
                                b = !b;
                            }
                            return b ? 1 : 0;
                        } else {
                            var result = false;
                            var material = gui.materialEditor.target as Material;
                            if ( material != null && material.shader != null ) {
                                var shader = material.shader;
                                for ( int i = 0; i < ShaderUtil.GetPropertyCount( shader ); ++i ) {
                                    var name = ShaderUtil.GetPropertyName( shader, i );
                                    if ( name == id ) {
                                        var mprop = gui.FindCachedProperty( name, props, false );
                                        if ( mprop != null && mprop.hasMixedValue ) {
                                            return -1;
                                        }
                                        switch ( ShaderUtil.GetPropertyType( shader, i ) ) {
                                        case ShaderUtil.ShaderPropertyType.Color:
                                            result = ShaderGUIHelper.Compare( ">", material.GetColor( name ), new Color( 0, 0, 0, 0 ) );
                                            break;
                                        case ShaderUtil.ShaderPropertyType.Float:
                                        case ShaderUtil.ShaderPropertyType.Range:
                                            result = material.GetFloat( name ) > 0;
                                            break;
                                        case ShaderUtil.ShaderPropertyType.TexEnv:
                                            result = material.GetTexture( name ) != null;
                                            break;
                                        case ShaderUtil.ShaderPropertyType.Vector:
                                            result = ShaderGUIHelper.Compare( ">", material.GetVector( name ), new Vector4( 0, 0, 0, 0 ) );
                                            break;
                                        }
                                        if ( rev ) {
                                            result = !result;
                                        }
                                        return result ? 1 : 0;
                                    }
                                }
                            }
                        }
                        return 0;
                    }
                } else {
                    returnValue = express;
                }
            }
            return -1;
        }

        public static String JSONValueToString( JSONObject jo ) {
            switch ( jo.type ) {
            case JSONObject.Type.BOOL:
                return jo.b.ToString();
            case JSONObject.Type.NUMBER:
                return jo.n.ToString();
            case JSONObject.Type.STRING:
                return jo.str;
            }
            return String.Empty;
        }

        public static bool? IsTagRemoveable( Material mat, String name ) {
            if ( mat != null && name != null ) {
                if ( String.IsNullOrEmpty( name ) ) {
                    return true;
                }
                var tagMap = new Dictionary<String, String>();
                GetMaterialOverrideTags( mat, ref tagMap );
                // 获取的tag可能是从材质中来，也可以是shader定义中来
                var value = mat.GetTag( name, true );
                if ( !String.IsNullOrEmpty( value ) ) {
                    try {
                        // 设置覆盖Tag，如果Shader中声明了Tag，此次覆盖操作只能保证从
                        // 材质中去除，
                        mat.SetOverrideTag( name, String.Empty );
                        var _value = mat.GetTag( name, true );
                        if ( !String.IsNullOrEmpty( _value ) ) {
                            // 表明此tag是不能被删除的
                            return false;
                        }
                        return true;
                    } finally {
                        // 如何还原？
                        // 如果测试的tag在材质中定义，说明我们之前获取的值从tagMap中来
                        if ( tagMap.ContainsKey( name ) ) {
                            // 设置原始值回去
                            mat.SetOverrideTag( name, value );
                        } else {
                            // 如果测试的tag，在材质中没有定义，
                            // 说明此tag从shader中来，无需处理
                        }
                    }
                } else {
                    // 说明测试的tag既不在tagMap也不再Shader中，可认为可删除
                    return true;
                }
            }
            return null;
        }

        public static bool GetMaterialOverrideTags( Material mat, ref Dictionary<String, String> tags ) {
            if ( mat == null ) {
                return false;
            }
            if ( tags != null ) {
                tags.Clear();
            } else {
                tags = new Dictionary<String, String>();
            }
            using ( var so = new SerializedObject( mat ) ) {
                var tagMap = so.FindProperty( "stringTagMap" );
                if ( tagMap != null && tagMap.isArray ) {
                    var arraySize = tagMap.arraySize;
                    for ( int i = 0; i < arraySize; ++i ) {
                        var key = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].first", i ) );
                        var value = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].second", i ) );
                        if ( key != null && value != null &&
                            key.propertyType == SerializedPropertyType.String &&
                            value.propertyType == SerializedPropertyType.String ) {
                            tags = tags ?? new Dictionary<String, String>();
                            tags.Add( key.stringValue, value.stringValue );
                            Debug.Assert( !String.IsNullOrEmpty( key.stringValue ) );
                            Debug.Assert( !String.IsNullOrEmpty( value.stringValue ) );
                        }
                    }
                }
            }
            return tags != null;
        }

        public static bool IsUnityDefaultResource( String path ) {
            return String.IsNullOrEmpty( path ) == false &&
                ( path == "Resources/unity_builtin_extra" ||
                path == "Library/unity default resources" );
        }

        public static String GetAssetGUID( UnityEngine.Object o ) {
            if ( o != null ) {
                var path = AssetDatabase.GetAssetPath( o );
                if ( !String.IsNullOrEmpty( path ) ) {
                    if ( !IsUnityDefaultResource( path ) ) {
                        return AssetDatabase.AssetPathToGUID( path );
                    } else {
                        return o.name;
                    }
                } else {
                    return o.GetInstanceID().ToString();
                }
            }
            return "null";
        }

        static String Vector_ToString( Vector2 v ) {
            return String.Format( "({0:F3}, {1:F3})", v.x, v.y );
        }

        static String Vector_ToString( Vector3 v ) {
            return String.Format( "({0:F3}, {1:F3}, {2:F3})", v.x, v.y, v.z );
        }

        static String Vector_ToString( Vector4 v ) {
            return String.Format( "({0:F3}, {1:F3}, {2:F3}, {3:F3})", v.x, v.y, v.z, v.w );
        }

        public class SerializedMaterial {
            public struct TexEnv : IEquatable<TexEnv> {
                public KeyValuePair<String, Texture> m_Texture;
                public Vector2 m_Scale;
                public Vector2 m_Offset;
                public bool Equals( TexEnv other ) {
                    return String.Equals( m_Texture.Key, other.m_Texture.Key ) &&
                        String.Equals( m_Texture.Value != null ? m_Texture.Value.name : null,
                            other.m_Texture.Value != null ? other.m_Texture.Value.name : null ) &&
                        m_Scale == other.m_Scale &&
                        m_Offset == other.m_Offset;
                }
                public override string ToString() {
                    return String.Format( "m_Texture = {0}, ST = {1}, {2}", m_Texture, m_Scale, m_Offset );
                }
            }

            public struct Properties : IEquatable<Properties> {
                public KeyValuePair<String, TexEnv>[] m_TexEnvs;
                public KeyValuePair<String, float>[] m_Floats;
                public KeyValuePair<String, Vector4>[] m_Colors;
                public bool Equals( Properties other ) {
                    var m_TexEnvs_Count = m_TexEnvs != null ? m_TexEnvs.Length : 0;
                    var other_TexEnvs_Count = other.m_TexEnvs != null ? other.m_TexEnvs.Length : 0;
                    if ( m_TexEnvs_Count != other_TexEnvs_Count ) {
                        return false;
                    } else if ( m_TexEnvs_Count > 0 ) {
                        for ( int i = 0; i < m_TexEnvs_Count; ++i ) {
                            if ( !String.Equals( m_TexEnvs[ i ].Key, other.m_TexEnvs[ i ].Key ) ) {
                                return false;
                            }
                            if ( !m_TexEnvs[ i ].Value.Equals( other.m_TexEnvs[ i ].Value ) ) {
                                return false;
                            }
                        }
                    }
                    var m_Floats_Count = m_Floats != null ? m_Floats.Length : 0;
                    var other_Floats_Count = other.m_Floats != null ? other.m_Floats.Length : 0;
                    if ( m_Floats_Count != other_Floats_Count ) {
                        return false;
                    } else if ( m_Floats_Count > 0 ) {
                        for ( int i = 0; i < m_Floats_Count; ++i ) {
                            if ( !String.Equals( m_Floats[ i ].Key, other.m_Floats[ i ].Key ) ) {
                                return false;
                            }
                            if ( !m_Floats[ i ].Value.Equals( other.m_Floats[ i ].Value ) ) {
                                return false;
                            }
                        }
                    }
                    var m_Colors_Count = m_Colors != null ? m_Colors.Length : 0;
                    var other_Colors_Count = other.m_Colors != null ? other.m_Colors.Length : 0;
                    if ( m_Colors_Count != other_Colors_Count ) {
                        return false;
                    } else if ( m_Colors_Count > 0 ) {
                        for ( int i = 0; i < m_Colors_Count; ++i ) {
                            if ( !String.Equals( m_Colors[ i ].Key, other.m_Colors[ i ].Key ) ) {
                                return false;
                            }
                            if ( !m_Colors[ i ].Value.Equals( other.m_Colors[ i ].Value ) ) {
                                return false;
                            }
                        }
                    }
                    return true;
                }
            }

            public int m_ObjectHideFlags = 0;
            public String m_CorrespondingSourceObject;
            public String m_PrefabInstance;
            public String m_PrefabAsset;
            public String m_Name;
            public KeyValuePair<String, Shader> m_Shader;
            public String[] m_ShaderKeywords;
            public int m_LightmapFlags = 4;
            public int m_EnableInstancingVariants = 0;
            public int m_DoubleSidedGI = 0;
            public int m_CustomRenderQueue = -1;
            public KeyValuePair<String, String>[] stringTagMap;
            public String[] disabledShaderPasses;
            public Properties m_SavedProperties;
        }

        public static SerializedMaterial DeserializeMaterial( Material m ) {
            if ( m == null ) {
                return null;
            }
            var sm = new SerializedMaterial();
            sm.m_Name = m.name;
            sm.m_ObjectHideFlags = ( int )m.hideFlags;
            sm.m_EnableInstancingVariants = m.enableInstancing ? 1 : 0;
            sm.m_DoubleSidedGI = m.doubleSidedGI ? 1 : 0;
            sm.m_LightmapFlags = ( int )m.globalIlluminationFlags;
            sm.m_ShaderKeywords = m.shaderKeywords;
            Array.Sort( sm.m_ShaderKeywords );

            sm.m_Shader = new KeyValuePair<String, Shader>( GetAssetGUID( m.shader ), m.shader );

            using ( var so = new SerializedObject( m ) ) {
                var _m_CorrespondingSourceObject = so.FindProperty( "m_CorrespondingSourceObject" );
                var _m_PrefabInstance = so.FindProperty( "m_PrefabInstance" );
                var _m_PrefabAsset = so.FindProperty( "m_PrefabAsset" );
                if ( _m_CorrespondingSourceObject != null && _m_CorrespondingSourceObject.propertyType == SerializedPropertyType.ObjectReference ) {
                    sm.m_CorrespondingSourceObject = GetAssetGUID( _m_CorrespondingSourceObject.objectReferenceValue );
                }
                if ( _m_PrefabInstance != null && _m_PrefabInstance.propertyType == SerializedPropertyType.ObjectReference ) {
                    sm.m_PrefabInstance = GetAssetGUID( _m_PrefabInstance.objectReferenceValue );
                }
                if ( _m_PrefabAsset != null && _m_PrefabAsset.propertyType == SerializedPropertyType.ObjectReference ) {
                    sm.m_PrefabAsset = GetAssetGUID( _m_PrefabAsset.objectReferenceValue );
                }
                using ( var kv = GlobalBuffer<KeyValuePair<string, string>>.Get() ) {
                    var tagMap = so.FindProperty( "stringTagMap" );
                    if ( tagMap != null && tagMap.isArray ) {
                        var arraySize = tagMap.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var key = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].first", i ) );
                            var value = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].second", i ) );
                            if ( key != null && value != null &&
                                key.propertyType == SerializedPropertyType.String &&
                                value.propertyType == SerializedPropertyType.String ) {
                                kv.Add( new KeyValuePair<String, String>( key.stringValue, value.stringValue ) );
                            }
                        }
                    }
                    kv.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                    sm.stringTagMap = kv.ToArray();
                }
                using ( var buff = GlobalBuffer<String>.Get() ) {
                    var _disabledShaderPasses = so.FindProperty( "disabledShaderPasses" );
                    if ( _disabledShaderPasses != null && _disabledShaderPasses.isArray ) {
                        var arraySize = _disabledShaderPasses.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var value = _disabledShaderPasses.GetArrayElementAtIndex( i );
                            if ( value != null && value.propertyType == SerializedPropertyType.String ) {
                                buff.Add( value.stringValue );
                            }
                        }
                    }
                    buff.Sort();
                    sm.disabledShaderPasses = buff.ToArray();
                }
                using ( var buff = GlobalBuffer<KeyValuePair<String, SerializedMaterial.TexEnv>>.Get() ) {
                    var _m_TexEnvs = so.FindProperty( "m_SavedProperties.m_TexEnvs" );
                    if ( _m_TexEnvs != null && _m_TexEnvs.isArray ) {
                        var arraySize = _m_TexEnvs.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var e = _m_TexEnvs.GetArrayElementAtIndex( i );
                            if ( e != null ) {
                                var key = e.FindPropertyRelative( "first" );
                                var value = e.FindPropertyRelative( "second" );
                                var _m_Texture = e.FindPropertyRelative( "second.m_Texture" );
                                var _m_Scale = e.FindPropertyRelative( "second.m_Scale" );
                                var _m_Offset = e.FindPropertyRelative( "second.m_Offset" );
                                if ( key != null && value != null && _m_Texture != null && _m_Scale != null && _m_Offset != null &&
                                    key.propertyType == SerializedPropertyType.String ) {
                                    buff.Add(
                                        new KeyValuePair<string, SerializedMaterial.TexEnv>(
                                            key.stringValue, new SerializedMaterial.TexEnv {
                                                m_Texture = new KeyValuePair<String, Texture>(
                                                    GetAssetGUID( _m_Texture.objectReferenceValue ),
                                                    _m_Texture.objectReferenceValue as Texture
                                                ),
                                                m_Scale = _m_Scale.vector2Value,
                                                m_Offset = _m_Offset.vector2Value
                                            }
                                        )
                                    );
                                }
                            }
                        }
                    }
                    buff.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                    sm.m_SavedProperties.m_TexEnvs = buff.ToArray();
                }
                using ( var buff = GlobalBuffer<KeyValuePair<String, float>>.Get() ) {
                    var _m_Floats = so.FindProperty( "m_SavedProperties.m_Floats" );
                    if ( _m_Floats != null && _m_Floats.isArray ) {
                        var arraySize = _m_Floats.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var e = _m_Floats.GetArrayElementAtIndex( i );
                            if ( e != null ) {
                                var key = e.FindPropertyRelative( "first" );
                                var value = e.FindPropertyRelative( "second" );
                                if ( key != null && value != null &&
                                    key.propertyType == SerializedPropertyType.String &&
                                    value.propertyType == SerializedPropertyType.Float ) {
                                    buff.Add( new KeyValuePair<String, float>( key.stringValue, value.floatValue ) );
                                }
                            }
                        }
                    }
                    buff.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                    sm.m_SavedProperties.m_Floats = buff.ToArray();
                }
                using ( var buff = GlobalBuffer<KeyValuePair<String, Vector4>>.Get() ) {
                    var _m_Colors = so.FindProperty( "m_SavedProperties.m_Colors" );
                    if ( _m_Colors != null && _m_Colors.isArray ) {
                        var arraySize = _m_Colors.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var e = _m_Colors.GetArrayElementAtIndex( i );
                            if ( e != null ) {
                                var key = e.FindPropertyRelative( "first" );
                                var value = e.FindPropertyRelative( "second" );
                                if ( key != null && value != null &&
                                    key.propertyType == SerializedPropertyType.String &&
                                    ( value.propertyType == SerializedPropertyType.Color ||
                                    value.propertyType == SerializedPropertyType.Vector4 ) ) {
                                    if ( value.propertyType == SerializedPropertyType.Vector4 ) {
                                        buff.Add( new KeyValuePair<String, Vector4>( key.stringValue, value.vector4Value ) );
                                    } else {
                                        buff.Add( new KeyValuePair<String, Vector4>( key.stringValue, value.colorValue ) );
                                    }
                                }
                            }
                        }
                    }
                    buff.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                    sm.m_SavedProperties.m_Colors = buff.ToArray();
                }
            }
            return sm;
        }

        public static String DumpMaterial( Material m ) {
            var sb = new StringBuilder();
            if ( m != null ) {
                var shader = m.shader;
                sb.AppendFormat( "shader: {0}\n", GetAssetGUID( shader ) );
                sb.AppendLine();

                sb.AppendFormat( "enableInstancing: {0}\n", m.enableInstancing );
                sb.AppendFormat( "doubleSidedGI: {0}\n", m.doubleSidedGI );
                sb.AppendFormat( "globalIlluminationFlags: {0}\n", m.globalIlluminationFlags );
                sb.AppendFormat( "renderQueue: {0}\n", m.renderQueue );
                sb.AppendLine();

                sb.AppendFormat( "passCount: {0}\n", m.passCount );
                for ( int i = 0; i < m.passCount; ++i ) {
                    var passName = m.GetPassName( i );
                    var enabled = m.GetShaderPassEnabled( passName );
                    sb.AppendFormat( "pass: {0} enabled = {1}\n", passName, enabled );
                }
                sb.AppendLine();

                List<KeyValuePair<String, Texture>> texEnvs = null;
                using ( var so = new SerializedObject( m ) ) {
                    List<KeyValuePair<String, String>> kv = null;
                    var tagMap = so.FindProperty( "stringTagMap" );
                    if ( tagMap != null && tagMap.isArray ) {
                        var arraySize = tagMap.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var key = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].first", i ) );
                            var value = so.FindProperty( String.Format( "stringTagMap.Array.data[{0}].second", i ) );
                            if ( key != null && value != null &&
                                key.propertyType == SerializedPropertyType.String &&
                                value.propertyType == SerializedPropertyType.String ) {
                                kv = kv ?? new List<KeyValuePair<String, String>>();
                                kv.Add( new KeyValuePair<String, String>( key.stringValue, value.stringValue ) );
                            }
                        }
                    }
                    if ( kv != null ) {
                        kv.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                        for ( int i = 0; i < kv.Count; ++i ) {
                            sb.AppendFormat( "stringTagMap[{0}]: {1} = {2}\n", i, kv[ i ].Key, kv[ i ].Value );
                        }
                    }
                    var envs_array = so.FindProperty( "m_SavedProperties.m_TexEnvs.Array" );
                    if ( envs_array != null && envs_array.isArray ) {
                        var arraySize = envs_array.arraySize;
                        for ( int i = 0; i < arraySize; ++i ) {
                            var envNamePropPath = String.Format( "data[{0}].first", i );
                            var envNameProp = envs_array.FindPropertyRelative( envNamePropPath );
                            var texValuePropPath = String.Format( "data[{0}].second.m_Texture", i );
                            var texValueProp = envs_array.FindPropertyRelative( texValuePropPath );
                            if ( texValueProp != null && envNameProp != null ) {
                                var envName = envNameProp.stringValue;
                                if ( texValueProp.propertyType == SerializedPropertyType.ObjectReference ) {
                                    if ( texValueProp.objectReferenceValue != null ) {
                                        texEnvs = texEnvs ?? new List<KeyValuePair<String, Texture>>();
                                        texEnvs.Add( new KeyValuePair<String, Texture>(
                                            envName, texValueProp.objectReferenceValue as Texture ) );
                                    }
                                }
                            }
                        }
                    }
                }
                sb.AppendLine();

                if ( shader != null ) {
                    var count = ShaderUtil.GetPropertyCount( shader );
                    for ( int i = 0; i < count; ++i ) {
                        var name = ShaderUtil.GetPropertyName( shader, i );
                        var type = ShaderUtil.GetPropertyType( shader, i );
                        switch ( type ) {
                        case ShaderUtil.ShaderPropertyType.Color:
                            sb.AppendFormat( "{0} {1} = {2}\n", type, name, m.GetColor( name ).ToString() );
                            break;
                        case ShaderUtil.ShaderPropertyType.Float:
                        case ShaderUtil.ShaderPropertyType.Range:
                            sb.AppendFormat( "{0} {1} = {2}\n", type, name, m.GetFloat( name ).ToString() );
                            break;
                        case ShaderUtil.ShaderPropertyType.Vector:
                            sb.AppendFormat( "{0} {1} = {2}\n", type, name, Vector_ToString( m.GetVector( name ) ) );
                            break;
                        case ShaderUtil.ShaderPropertyType.TexEnv:
                            var t = m.GetTexture( name );
                            sb.AppendFormat( "{0} {1} = {2}\n", ShaderUtil.GetTexDim( shader, i ), name, ShaderGUIHelper.GetAssetGUID( t ) );
                            sb.AppendFormat( "float4 {0}_ST, {1}, {2}\n", name, Vector_ToString( m.GetTextureScale( name ) ), Vector_ToString( m.GetTextureOffset( name ) ) );
                            if ( t != null && texEnvs != null ) {
                                var _name = name;
                                var ttIndex = texEnvs.FindIndex( kv => kv.Key == _name );
                                Debug.Assert( ttIndex >= 0 && texEnvs[ ttIndex ].Value == t );
                            }
                            break;
                        }
                    }
                }
                sb.AppendLine();

                var shaderKeywords = m.shaderKeywords;
                if ( shaderKeywords.Length > 0 ) {
                    Array.Sort( shaderKeywords );
                    sb.Append( '\n' );
                    for ( int i = 0; i < shaderKeywords.Length; ++i ) {
                        sb.Append( shaderKeywords[ i ] ).Append( ";\n" );
                    }
                }
                sb.AppendLine();
            }
            return sb.ToString();
        }

        public static bool DeserializeFromJSON( JSONObject parent, MaterialProperty m_prop, String guiType = null ) {
            if ( m_prop != null && parent.HasField( m_prop.name ) && parent != null ) {
                var jprop = parent.GetField( m_prop.name );
                String type;
                jprop.GetField( out type, "type", String.Empty );
                if ( type == m_prop.type.ToString() && jprop.HasField( "value" ) ) {
                    switch ( type ) {
                    case "Color": {
                            var c = JSONTemplates.ToColor( jprop.GetField( "value" ) );
                            var index = ShaderGUI_SingleProp.ColorGUITypeToComponentIndex( guiType );
                            if ( index == -1 ) {
                                m_prop.colorValue = c;
                            } else {
                                var _c = m_prop.colorValue;
                                _c[ index ] = c[ index ];
                                m_prop.colorValue = _c;
                            }
                        }
                        break;
                    case "Float":
                    case "Range": {
                            float f;
                            if ( jprop.GetField( out f, "value", 0.0f ) ) {
                                m_prop.floatValue = f;
                            }
                        }
                        break;
                    case "Vector":
                        m_prop.vectorValue = JSONTemplates.ToVector4( jprop.GetField( "value" ) );
                        break;
                    case "Texture": {
                            var val = jprop.GetField( "value" );
                            String guid;
                            if ( val.GetField( out guid, "GUID", String.Empty ) ) {
                                if ( String.IsNullOrEmpty( guid ) ) {
                                    m_prop.textureValue = null;
                                } else {
                                    var assetPath = AssetDatabase.GUIDToAssetPath( guid );
                                    if ( !String.IsNullOrEmpty( assetPath ) ) {
                                        var texture = AssetDatabase.LoadAssetAtPath<Texture>( assetPath );
                                        m_prop.textureValue = texture;
                                    }
                                    m_prop.textureScaleAndOffset = JSONTemplates.ToVector4( val.GetField( "scaleOffset" ) );
                                }
                            }
                        }
                        break;
                    }
                    return true;
                }
            }
            return false;
        }

        public static bool SerializeToJSON( JSONObject parent, MaterialProperty m_prop, String guiType = null ) {
            if ( m_prop != null && !parent.HasField( m_prop.name ) && parent != null ) {
                var jprop = new JSONObject( JSONObject.Type.OBJECT );
                switch ( m_prop.type ) {
                case MaterialProperty.PropType.Color:
                    jprop.SetField( "value", JSONTemplates.FromColor( m_prop.colorValue ) );
                    break;
                case MaterialProperty.PropType.Float:
                case MaterialProperty.PropType.Range:
                    jprop.SetField( "value", m_prop.floatValue );
                    break;
                case MaterialProperty.PropType.Vector:
                    jprop.SetField( "value", JSONTemplates.FromVector4( m_prop.vectorValue ) );
                    break;
                case MaterialProperty.PropType.Texture: {
                        if ( m_prop.textureValue != null ) {
                            var assetPath = AssetDatabase.GetAssetPath( m_prop.textureValue );
                            if ( !String.IsNullOrEmpty( assetPath ) ) {
                                var jval = new JSONObject( JSONObject.Type.OBJECT );
                                jval.SetField( "GUID", AssetDatabase.AssetPathToGUID( assetPath ) );
                                jval.SetField( "assetPath", assetPath );
                                jval.SetField( "scaleOffset", JSONTemplates.FromVector4( m_prop.textureScaleAndOffset ) );
                                jprop.SetField( "value", jval );
                            }
                        } else {
                            var jval = new JSONObject( JSONObject.Type.OBJECT );
                            jval.SetField( "GUID", String.Empty );
                            jprop.SetField( "value", jval );
                        }
                    }
                    break;
                }
                if ( jprop.HasField( "value" ) ) {
                    jprop.SetField( "type", m_prop.type.ToString() );
                    if ( !String.IsNullOrEmpty( guiType ) ) {
                        jprop.SetField( UnitMaterialEditor.Cfg.Key_PropGUIType, guiType );
                    }
                    parent.SetField( m_prop.name, jprop );
                }
                return true;
            }
            return false;
        }
    }
}
