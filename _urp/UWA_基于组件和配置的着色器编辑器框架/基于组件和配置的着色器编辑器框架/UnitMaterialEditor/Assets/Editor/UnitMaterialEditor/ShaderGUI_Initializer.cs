using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using System.Text.RegularExpressions;
using System.Text;
using UME.UnitShaderGUIAttribute;

namespace UME {

    [AllowMultiple]
    public class ShaderGUI_Initializer : UnitMaterialEditor {

        static List<ShaderGUI_Initializer> s_allInitializers = new List<ShaderGUI_Initializer>();
        static HashSet<String> s_shaderFeaturesTable = new HashSet<String>();
        static StringBuilder s_shaderFeaturesHashBuilder = new StringBuilder();
        static int s_shaderFeaturesHash = 0;
        static List<KeyValuePair<String, int>> s_allShaderFeatures = new List<KeyValuePair<String, int>>();
        static String s_allShaderFeaturesText = String.Empty;

        List<String> m_featureList = null;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            if ( m_args != null && props.Length > 0 ) {
                var material = this.m_MaterialEditor.target as Material;
                var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
                var boolTest = GetBoolTestResult( props );
                if ( modeMatch != null && modeMatch.Value && boolTest != null && boolTest.Value ) {
                    var values = m_args.GetField( "values" );
                    if ( values != null && values.type == JSONObject.Type.OBJECT ) {
                        for ( int i = 0; i < values.keys.Count; ++i ) {
                            var key = values.keys[ i ];
                            var value = values.GetField( key );
                            var prop = ShaderGUI.FindProperty( key, props );
                            if ( prop != null && !String.IsNullOrEmpty( key ) && value != null ) {
                                switch ( prop.type ) {
                                case MaterialProperty.PropType.Float: {
                                        float f;
                                        if ( ShaderGUIHelper.ParseValue( this, values, key, out f ) ) {
                                            if ( prop.floatValue != f ) {
                                                prop.floatValue = f;
                                            }
                                        }
                                    }
                                    break;
                                case MaterialProperty.PropType.Range: {
                                        float f;
                                        if ( ShaderGUIHelper.ParseValue( this, values, key, out f ) ) {
                                            f = Mathf.Clamp( f, prop.rangeLimits.x, prop.rangeLimits.y );
                                            if ( prop.floatValue != f ) {
                                                prop.floatValue = f;
                                            }
                                        }
                                    }
                                    break;
                                case MaterialProperty.PropType.Color: {
                                        Vector4 c = prop.colorValue;
                                        int comp;
                                        if ( ShaderGUIHelper.TryParseVector4( this, values, key, ref c, out comp ) ) {
                                            if ( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0 ) {
                                                c.x = Mathf.Clamp01( c.x );
                                                c.y = Mathf.Clamp01( c.y );
                                                c.z = Mathf.Clamp01( c.z );
                                                c.w = Mathf.Clamp01( c.w );
                                            }
                                            var _c = new Color( c.x, c.y, c.z, c.w );
                                            if ( prop.colorValue != _c ) {
                                                prop.colorValue = c;
                                            }
                                        }
                                    }
                                    break;
                                case MaterialProperty.PropType.Vector: {
                                        Vector4 v = prop.colorValue;
                                        int comp;
                                        if ( ShaderGUIHelper.TryParseVector4( this, values, key, ref v, out comp ) ) {
                                            if ( prop.vectorValue != v ) {
                                                prop.vectorValue = v;
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
                var features = m_args.GetField( "shader_feature_list" );
                if ( features != null && features.type == JSONObject.Type.ARRAY ) {
                    var features_list = new List<String>( features.list.Count );
                    for ( int i = 0; i < features.list.Count; ++i ) {
                        var o = features.list[ i ];
                        if ( o != null && o.type == JSONObject.Type.STRING &&
                            !String.IsNullOrEmpty( o.str ) ) {
                            features_list.Add( o.str );
                        }
                    }
                    if ( FindShaderPropertyType( material.shader, "_Mode", ShaderUtil.ShaderPropertyType.Float ) != null ) {
                        var renderModeEditor = this.FindPropEditor<ShaderGUI_RenderMode>();
                        if ( renderModeEditor.options != null ) {
                            for ( int i = 0; i < renderModeEditor.options.Length; ++i ) {
                                features_list.Add( "_MODE_" + renderModeEditor.options[ i ].ToUpper() );
                            }
                            if ( Array.IndexOf( renderModeEditor.optionValues, ( int )RenderMode.Additive ) >= 0 ||
                                Array.IndexOf( renderModeEditor.optionValues, ( int )RenderMode.SoftAdditive ) >= 0 ) {
                                features_list.Add( "_BLEND_ADDITIVE_SERIES" );
                            }
                        }
                        features_list.Add( "_ALPHAPREMULTIPLY_ON" );
                    }

                    m_featureList = features_list.Distinct().ToList();
                }
            }
            return true;
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            if ( s_allInitializers[ 0 ] != this ) {
                return;
            }
            if ( !String.IsNullOrEmpty( s_allShaderFeaturesText ) ) {
                m_MaterialEditor.SetDefaultGUIWidths();
                EditorGUILayout.BeginVertical();
                var style = GUI.skin.GetStyle( "HelpBox" );
                var _richText = style.richText;
                style.richText = true;
                EditorGUILayout.HelpBox( s_allShaderFeaturesText, MessageType.None );
                if ( Event.current.type == EventType.MouseDown &&
                    GUILayoutUtility.GetLastRect().Contains( Event.current.mousePosition ) ) {
                    if ( Event.current.button == 1 ) {
                        var menu = new GenericMenu();
                        menu.AddItem(
                            new GUIContent( "ClearCurrentShaderVariantCollection" ), false,
                            () => {
                                Utils.RflxStaticCall(
                                    "UnityEditor.ShaderUtil",
                                    "ClearCurrentShaderVariantCollection",
                                    null, "UnityEditor" );
                            }
                        );
                        menu.AddItem(
                            new GUIContent( "Report Current Collection" ), false,
                            () => {
                                Debug.developerConsoleVisible = true;
                                UnityEditor.EditorApplication.ExecuteMenuItem( "Window/General/Console" );
                                var shaderCount = Utils.RflxStaticCall(
                                    "UnityEditor.ShaderUtil",
                                    "GetCurrentShaderVariantCollectionShaderCount",
                                    null, "UnityEditor" );
                                var shaderVariantCount = Utils.RflxStaticCall(
                                    "UnityEditor.ShaderUtil",
                                    "GetCurrentShaderVariantCollectionVariantCount",
                                    null, "UnityEditor" );
                                Debug.LogFormat( "Currently tracked: {0} shaders {1} total variants.",
                                    shaderCount, shaderVariantCount );
                            }
                        );
                        if ( menu.GetItemCount() > 0 ) {
                            Event.current.Use();
                            menu.ShowAsContext();
                        }
                    }
                }
                style.richText = _richText;
                EditorGUILayout.EndVertical();
                m_MaterialEditor.SetDefaultGUIWidths();
            }
        }

        protected override void OnPostInitProperties() {
            s_allInitializers.Clear();
            // 整合所有的初始化器，合并ShaderFeatures
            FindPropEditors<ShaderGUI_Initializer>( s_allInitializers );
            if ( this != s_allInitializers[ 0 ] ) {
                // 只在第一个初始化器中处理
                return;
            }
            s_shaderFeaturesHashBuilder.Length = 0;
            s_shaderFeaturesTable.Clear();
            s_allShaderFeatures.Clear();
            // 整合所有支持的ShaderFeature
            var targets = this.targets;
            for ( int i = 0; i < s_allInitializers.Count; ++i ) {
                var list = s_allInitializers[ i ].m_featureList;
                if ( list != null ) {
                    for ( int j = 0; j < list.Count; ++j ) {
                        if ( s_shaderFeaturesTable.Add( list[ j ] ) ) {
                            var key = list[ j ];
                            var count = 0;
                            foreach ( var m in targets ) {
                                if ( m.IsKeywordEnabled( key ) ) {
                                    ++count;
                                }
                            }
                            s_allShaderFeatures.Add( new KeyValuePair<String, int>( key, count ) );
                            s_shaderFeaturesHashBuilder.Append( key ).Append( count );
                        }
                    }
                }
            }
            var hash = s_shaderFeaturesHashBuilder.ToString().GetHashCode();
            if ( hash != s_shaderFeaturesHash ) {
                s_shaderFeaturesHash = hash;
                s_allShaderFeatures.Sort( ( l, r ) => l.Key.CompareTo( r.Key ) );
                var sb = s_shaderFeaturesHashBuilder;
                sb.Length = 0;
                for ( int i = 0; i < s_allShaderFeatures.Count; ++i ) {
                    var state = s_allShaderFeatures[ i ];
                    if ( sb.Length > 0 ) {
                        sb.AppendLine();
                    }
                    if ( state.Value > 0 ) {
                        if ( state.Value == targets.Length ) {
                            sb.AppendFormat( "<b><color=green>{0}</color></b>", state.Key );
                        } else {
                            sb.AppendFormat( "<b><i><color=yellow>{0}</color></i></b>", state.Key );
                        }
                    } else {
                        sb.Append( state.Key );
                    }
                }
                if ( sb.Length == 0 ) {
                    sb.Append( "--" );
                }
                s_allShaderFeaturesText = sb.ToString();
                var allShaderFeatures = s_allShaderFeatures;
                if ( allShaderFeatures.Count > 0 ) {
                    using ( var keywords = GlobalBuffer<String>.Get() ) {
                        using ( var dirtyList = GlobalBuffer<String>.Get() ) {
                            for ( int n = 0; n < targets.Length; ++n ) {
                                var material = targets[ n ];
                                dirtyList.Clear();
                                keywords.Clear();
                                keywords.AddRange( material.shaderKeywords );
                                for ( int i = keywords.Count - 1; i >= 0; --i ) {
                                    var keyword = keywords[ i ];
                                    var keywordIndex = -1;
                                    if ( ( keywordIndex = allShaderFeatures.FindIndex( keyword, ( e, k ) => e.Key == k ) ) < 0 ) {
                                        dirtyList.Add( keywords[ i ] );
                                        keywords.RemoveAt( i );
                                    }
                                }
                                if ( dirtyList.Count > 0 ) {
                                    Debug.LogErrorFormat(
                                        "[{0}]{1}: Remove useless keywords: {2}",
                                        AssetDatabase.GetAssetPath( material ),
                                        material.shader.name,
                                        String.Join( ";", dirtyList )
                                    );
                                    material.shaderKeywords = keywords.ToArray();
                                    EditorUtility.SetDirty( material );
                                }
                            }
                        }
                    }
                }
            }
        }

        protected override void OnMaterialChanged( MaterialProperty[] props ) {
            s_shaderFeaturesHash = 0;
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_Initializer();
        }
    }
}
