using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UME.UnitShaderGUIAttribute;

namespace UME {

    [AllowMultiple]
    public class ShaderGUI_UpdateKeyword : UnitMaterialEditor {

        /// <summary>
        /// 开启自动检测Keyword有效性检查，从Unity编译文件中获取实际使用的所有Keyword
        /// </summary>
        public static bool EnableKeywordCheck = false;

        String m_propName = String.Empty;
        MaterialProperty m_prop = null;

        public override String ToString() {
            var s = base.ToString();
            if ( !String.IsNullOrEmpty( m_propName ) ) {
                s = String.Format( "{0}->{1}", s, m_propName );
            }
            return s;
        }

        /// <summary>
        /// 强制检查Keyword有效性
        /// </summary>
        bool m_mandatory = true;

        public override bool? GetLogicOpResult( out String returnValue, MaterialProperty[] props ) {
            returnValue = String.Empty;
            var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
            if ( modeMatch == null ) {
                return null;
            }
            if ( m_prop != null ) {
                var opResult = ShaderGUIHelper.ExcuteLogicOp( this, m_prop, props, m_args );
                if ( opResult == -1 ) {
                    return null;
                }
                return modeMatch.Value && opResult == 1;
            } else {
                var boolTest = GetBoolTestResult( props );
                if ( boolTest == null ) {
                    return null;
                }
                return modeMatch.Value && boolTest.Value;
            }
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            if ( !String.IsNullOrEmpty( m_propName ) ) {
                try {
                    m_prop = ShaderGUI.FindProperty( m_propName, props, true );
                } catch ( Exception e ) {
                    Debug.LogException( e );
                }
            }
            if ( m_args != null ) {
                m_args.GetField( out m_mandatory, Cfg.ArgsKey_UpdateKeyword_Mandatory, true );
            }
            return true;
        }

        void _SetKeywordEx( Material[] m, String keyword, bool state, MaterialProperty[] props ) {
            UnitMaterialEditor.SetKeyword( m, keyword, state );
            if ( m_args == null ) {
                return;
            }
            String propertyName;
            var shader = target.shader;
            var updatePropertyData = m_args.GetField( Cfg.ArgsKey_UpdateKeywordProperty );
            if ( updatePropertyData != null && updatePropertyData.GetField( out propertyName, Cfg.Key_Name, String.Empty ) && !String.IsNullOrEmpty( propertyName ) ) {
                var prop = FindCachedProperty( propertyName, props, false );
                if ( prop != null ) {
                    switch ( prop.type ) {
                    case MaterialProperty.PropType.Texture: {
                            String assetPath;
                            if ( updatePropertyData.GetField( out assetPath, state ? "true" : "false", String.Empty ) ) {
                                var texture = AssetDatabase.LoadAssetAtPath<Texture>( assetPath );
                                if ( texture != null && prop.textureValue != texture ) {
                                    prop.textureValue = texture;
                                }
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Color: {
                            var srcVal = ( Vector4 )prop.colorValue;
                            var dstVal = srcVal;
                            int comp;
                            ShaderGUIHelper.TryParseVector4( this, updatePropertyData, state ? "true" : "false", ref dstVal, out comp );
                            if ( comp > 0 && srcVal != dstVal ) {
                                prop.colorValue = ( Color )dstVal;
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Float: {
                            int comp;
                            var dstVal = Vector4.zero;
                            dstVal.x = prop.floatValue;
                            ShaderGUIHelper.TryParseVector4( this, updatePropertyData, state ? "true" : "false", ref dstVal, out comp );
                            if ( comp > 0 && dstVal.x != prop.floatValue ) {
                                prop.floatValue = dstVal.x;
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Range: {
                            int comp;
                            var dstVal = Vector4.zero;
                            dstVal.x = prop.floatValue;
                            ShaderGUIHelper.TryParseVector4( this, updatePropertyData, state ? "true" : "false", ref dstVal, out comp );
                            dstVal.x = Mathf.Clamp( dstVal.x, prop.rangeLimits.x, prop.rangeLimits.y );
                            if ( comp > 0 && dstVal.x != prop.floatValue ) {
                                prop.floatValue = dstVal.x;
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Vector: {
                            var srcVal = prop.vectorValue;
                            var dstVal = srcVal;
                            int comp;
                            ShaderGUIHelper.TryParseVector4( this, updatePropertyData, state ? "true" : "false", ref dstVal, out comp );
                            if ( comp > 0 && srcVal != dstVal ) {
                                prop.vectorValue = dstVal;
                            }
                        }
                        break;
                    }
                }
            }
        }

        protected override void OnMaterialChanged( MaterialProperty[] props ) {
            var keyword = String.Empty;
            if ( m_args != null && m_args.GetField( out keyword, Cfg.ArgsKey_UpdateKeyword, String.Empty ) ) {
                var material = target;
                var shader = material.shader;
                if ( m_mandatory && EnableKeywordCheck && shader != null ) {
                    // 从当期Shader和它的依赖项的编译文件中获取真实的有效Keyword信息，从而判断Keyword的有效性
                    var curShader = material.shader;
                    var shaderPath = AssetDatabase.GetAssetPath( curShader );
                    var keywordValid = false;
                    var deps = AssetDatabase.GetDependencies( shaderPath );
                    for ( int i = 0; i < deps.Length; ++i ) {
                        Shader depShader = null;
                        if ( deps[ i ] == shaderPath ) {
                            depShader = curShader;
                        } else {
                            if ( deps[ i ].EndsWith( ".shader", StringComparison.OrdinalIgnoreCase ) ) {
                                depShader = AssetDatabase.LoadAssetAtPath<Shader>( deps[ i ] );
                                if ( depShader == null ) {
                                    Debug.LogErrorFormat( "Load shader '{0}' failed.", deps[ i ] );
                                }
                            }
                        }
                        if ( depShader != null ) {
                            var result = ShaderUtils.ParseShaderCombinations( depShader, true );
                            if ( result != null ) {
                                if ( result.IsValidKeyword( keyword ) ) {
                                    keywordValid = true;
                                    break;
                                }
                            }
                        }
                    }
                    if ( !keywordValid ) {
                        Debug.LogErrorFormat( "<color=#ff0000ff>{0}</color>: keyword '<color=#ff0000ff><b>{1}</b></color>' is invalid", material.shader.name, keyword );
                    }
                }
                if ( keyword.Equals( "none", StringComparison.OrdinalIgnoreCase ) ) {
                    return;
                }
                var enable_if = TryGetBoolTestResult( props, Cfg.Key_EnableIf, true );
                if ( enable_if == null || enable_if != null && enable_if.Value == false ) {
                    return;
                }
                var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
                var boolTest = GetBoolTestResult( props );
                if ( modeMatch != null && modeMatch.Value && boolTest != null && boolTest.Value ) {
                    if ( m_prop != null ) {
                        var cmp = ShaderGUIHelper.ExcuteLogicOp( this, m_prop, props, m_args );
                        if ( cmp != -1 ) {
                            if ( !keyword.Equals( "none", StringComparison.OrdinalIgnoreCase ) ) {
                                var materials = targets;
                                _SetKeywordEx( materials, keyword, cmp == 1, props );
                            }
                            return;
                        }
                    } else {
                        var _op = String.Empty;
                        var materials = targets;
                        m_args.GetField( out _op, UnitMaterialEditor.Cfg.ArgsKey_OP, String.Empty );
                        if ( String.IsNullOrEmpty( _op ) || String.IsNullOrEmpty( m_propName ) ) {
                            _SetKeywordEx( materials, keyword, true, props );
                        } else {
                            _SetKeywordEx( materials, keyword, false, props );
                        }
                        return;
                    }
                }
                if ( !keyword.Equals( "none", StringComparison.OrdinalIgnoreCase ) ) {
                    // disable keyword for default
                    var materials = targets;
                    _SetKeywordEx( materials, keyword, false, props );
                }
            }
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_UpdateKeyword();
            ret.m_propName = s.name;
            return ret;
        }

    }
}
