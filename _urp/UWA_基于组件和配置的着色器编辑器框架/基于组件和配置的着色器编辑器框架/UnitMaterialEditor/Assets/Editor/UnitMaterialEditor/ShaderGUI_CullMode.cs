using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_CullMode : UnitMaterialEditor {

        String m_propName = String.Empty;
        String m_label = String.Empty;
        MaterialProperty m_prop = null;
        MaterialProperty m_invertProp = null;
        object m_keep = null;

        public String propName {
            get {
                return m_propName ?? String.Empty;
            }
        }

        void DrawGUI( MaterialProperty[] props ) {
            var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
            if ( modeMatch != null && modeMatch.Value == false ) {
                return;
            }
            var boolTest = GetBoolTestResult( props );
            if ( boolTest != null && boolTest.Value == false ) {
                return;
            }
            var gui_enabled = GUI.enabled;
            var showMixedValue = EditorGUI.showMixedValue;
            try {
                // 没有初始值固定，也没有反转源，才可以编辑
                GUI.enabled = m_keep == null && m_invertProp == null;
                if ( !GUI.enabled && ( m_prop.flags & MaterialProperty.PropFlags.HideInInspector ) != 0 ) {
                    return;
                }
                m_MaterialEditor.SetDefaultGUIWidths();
                var label = m_label ?? m_prop.displayName;
                float h = m_MaterialEditor.GetPropertyHeight( m_prop, label );
                Rect r = EditorGUILayout.GetControlRect( true, h, EditorStyles.layerMaskField );
                if ( m_invertProp != null && !m_invertProp.hasMixedValue ) {
                    // 反转源不能有混合值才可以应用反转赋值
                    var mode = ( CullMode )( int )m_invertProp.floatValue;
                    switch ( mode ) {
                    case CullMode.Off:
                        if ( m_prop.floatValue != ( float )CullMode.Off ) {
                            m_prop.floatValue = ( float )CullMode.Off;
                        }
                        break;
                    case CullMode.Front:
                        if ( m_prop.floatValue != ( float )CullMode.Back ) {
                            m_prop.floatValue = ( float )CullMode.Back;
                        }
                        break;
                    case CullMode.Back:
                        if ( m_prop.floatValue != ( float )CullMode.Front ) {
                            m_prop.floatValue = ( float )CullMode.Front;
                        }
                        break;
                    }
                }
                EditorGUI.showMixedValue = m_prop.hasMixedValue;
                m_MaterialEditor.ShaderProperty( r, m_prop, label );
            } finally {
                GUI.enabled = gui_enabled;
                EditorGUI.showMixedValue = showMixedValue;
            }
            m_MaterialEditor.SetDefaultGUIWidths();
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            DrawGUI( props );
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            m_prop = FindCachedProperty( m_propName, props );
            m_keep = null;
            m_label = null;
            if ( m_args != null ) {
                ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_GUILabel, out m_label );
            }
            m_label = String.IsNullOrEmpty( m_label ) ? null : m_label;
            if ( m_prop != null && m_args != null && m_prop.type == MaterialProperty.PropType.Float ) {
                if ( m_args.HasField( Cfg.Key_FixedValue ) ) {
                    // 初始值固定都来源于编辑器，可以应用于多选目标材质
                    switch ( m_prop.type ) {
                    case MaterialProperty.PropType.Float: {
                            String s;
                            try {
                                ShaderGUIHelper.EnableParseErrorChecking = false;
                                if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out s ) ) {
                                    s = s.ToLower();
                                    switch ( s ) {
                                    case "none":
                                    case Cfg.Value_CullMode_Off:
                                        m_keep = CullMode.Off;
                                        break;
                                    case Cfg.Value_CullMode_Front:
                                        m_keep = CullMode.Front;
                                        break;
                                    case Cfg.Value_CullMode_Back:
                                        m_keep = CullMode.Back;
                                        break;
                                    default:
                                        m_keep = CullMode.Back;
                                        break;
                                    }
                                    if ( m_prop.floatValue != ( float )( CullMode )m_keep ) {
                                        m_prop.floatValue = ( float )( CullMode )m_keep;
                                    }
                                    break;
                                }
                            } finally {
                                ShaderGUIHelper.EnableParseErrorChecking = true;
                            }
                            float val;
                            if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out val ) ) {
                                int ival = ( int )val;
                                switch ( ival ) {
                                case 0:
                                    m_keep = CullMode.Off;
                                    break;
                                case 1:
                                    m_keep = CullMode.Front;
                                    break;
                                case 2:
                                    m_keep = CullMode.Back;
                                    break;
                                default:
                                    m_keep = CullMode.Back;
                                    break;
                                }
                                if ( m_prop.floatValue != ( float )( CullMode )m_keep ) {
                                    m_prop.floatValue = ( float )( CullMode )m_keep;
                                }
                            }
                        }
                        break;
                    }
                } else if ( m_args.HasField( Cfg.Command_Value_Invert ) ) {
                    // 值来源与另外一个编辑器反转，需要注意源属性不能有多个不同的值
                    String val;
                    if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Command_Value_Invert, out val ) &&
                        !String.IsNullOrEmpty( val ) && val != m_propName ) {
                        var invertProp = FindCachedProperty( val, props, false );
                        if ( invertProp != null && invertProp.type == MaterialProperty.PropType.Float ) {
                            m_invertProp = invertProp;
                        }
                    }
                }
            }
            if ( m_prop == null ) {
                var mat = this.materialEditor.target as Material;
                if ( mat != null && mat.shader != null ) {
                    Debug.LogErrorFormat( "Find Shader Property failed: {0}.{1}. \n{2}",
                        mat.shader.name, m_propName, AssetDatabase.GetAssetPath( mat ) );
                }
            }
            return m_prop != null;
        }

        public override bool SerializeToJSON( JSONObject parent ) {
            return ShaderGUIHelper.SerializeToJSON( parent, m_prop ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_invertProp );
        }

        public override bool DeserializeFromJSON( JSONObject parent ) {
            return ShaderGUIHelper.DeserializeFromJSON( parent, m_prop ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_invertProp );
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_CullMode();
            ret.m_propName = s.name;
            return ret;
        }
    }
}
