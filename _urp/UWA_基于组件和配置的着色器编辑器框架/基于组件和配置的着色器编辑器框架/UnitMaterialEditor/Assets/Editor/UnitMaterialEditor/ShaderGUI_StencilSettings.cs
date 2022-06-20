using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_StencilSettings : UnitMaterialEditor {

        const String DefaultTitle = "Stencil Settings";

        protected MaterialProperty m_prop_StencilComp = null;
        protected MaterialProperty m_prop_Stencil = null;
        protected MaterialProperty m_prop_StencilWriteMask = null;
        protected MaterialProperty m_prop_StencilReadMask = null;
        protected MaterialProperty m_prop_StencilPass = null;
        protected MaterialProperty m_prop_StencilFail = null;
        protected MaterialProperty m_prop_StencilZFail = null;

        protected bool m_prop_StencilComp_Enabled = true;
        protected bool m_prop_Stencil_Enabled = true;
        protected bool m_prop_StencilWriteMask_Enabled = true;
        protected bool m_prop_StencilReadMask_Enabled = true;
        protected bool m_prop_StencilPass_Enabled = true;
        protected bool m_prop_StencilFail_Enabled = true;
        protected bool m_prop_StencilZFail_Enabled = true;

        bool m_showStencilSettings = false;

        String m_title = DefaultTitle;
        String m_prefix = String.Empty;
        String m_preset = String.Empty;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            var prefix = String.Empty;
            var preset = String.Empty;
            if ( m_args != null ) {
                if ( m_args.GetField( out prefix, Cfg.ArgsKey_PropPrefix, String.Empty ) && !String.IsNullOrEmpty( prefix ) ) {
                    m_prefix = prefix;
                    m_title = m_prefix + " " + DefaultTitle;
                    prefix = "_" + prefix;
                }
                if ( m_args.GetField( out preset, Cfg.ArgsKey_Preset, String.Empty ) && !String.IsNullOrEmpty( preset ) ) {
                    m_preset = preset.Trim().ToLower();
                }
            }
            m_prop_StencilComp = FindCachedProperty( prefix + "_StencilComp", props, false );
            m_prop_Stencil = FindCachedProperty( prefix + "_Stencil", props, false );
            m_prop_StencilWriteMask = FindCachedProperty( prefix + "_StencilWriteMask", props, false );
            m_prop_StencilReadMask = FindCachedProperty( prefix + "_StencilReadMask", props, false );
            m_prop_StencilPass = FindCachedProperty( prefix + "_StencilPass", props, false );
            m_prop_StencilFail = FindCachedProperty( prefix + "_StencilFail", props, false );
            m_prop_StencilZFail = FindCachedProperty( prefix + "_StencilZFail", props, false );
            if ( m_prop_StencilComp != null && m_prop_Stencil != null && m_prop_StencilPass != null ) {
                switch ( m_preset ) {
                case "mask":
                case "maskout": {
                        m_prop_StencilComp_Enabled = false;
                        m_prop_Stencil_Enabled = true;
                        m_prop_StencilWriteMask_Enabled = false;
                        m_prop_StencilReadMask_Enabled = false;
                        m_prop_StencilPass_Enabled = false;
                        m_prop_StencilFail_Enabled = false;
                        m_prop_StencilZFail_Enabled = false;
                        if ( m_prop_Stencil.floatValue == 0 ) {
                            m_prop_Stencil.floatValue = 1;
                        }
                        var op_keep = ( float )UnityEngine.Rendering.StencilOp.Keep;
                        if ( m_preset == "mask" ) {
                            var comp_always = ( float )UnityEngine.Rendering.CompareFunction.Always;
                            if ( m_prop_StencilComp.floatValue != comp_always ) {
                                m_prop_StencilComp.floatValue = comp_always;
                            }
                            var op_replace = ( float )UnityEngine.Rendering.StencilOp.Replace;
                            if ( m_prop_StencilPass.floatValue != op_replace ) {
                                m_prop_StencilPass.floatValue = op_replace;
                            }
                        } else {
                            // maskout
                            var comp_greater = ( float )UnityEngine.Rendering.CompareFunction.Greater;
                            if ( m_prop_StencilComp.floatValue != comp_greater ) {
                                m_prop_StencilComp.floatValue = comp_greater;
                            }
                            if ( m_prop_StencilPass.floatValue != op_keep ) {
                                m_prop_StencilPass.floatValue = op_keep;
                            }
                        }
                        if ( m_prop_StencilWriteMask != null && m_prop_StencilWriteMask.floatValue != 255 ) {
                            m_prop_StencilWriteMask.floatValue = 255;
                        }
                        if ( m_prop_StencilReadMask != null && m_prop_StencilReadMask.floatValue != 255 ) {
                            m_prop_StencilReadMask.floatValue = 255;
                        }
                        if ( m_prop_StencilFail != null && m_prop_StencilFail.floatValue != op_keep ) {
                            m_prop_StencilWriteMask.floatValue = op_keep;
                        }
                        if ( m_prop_StencilZFail != null && m_prop_StencilZFail.floatValue != op_keep ) {
                            m_prop_StencilReadMask.floatValue = op_keep;
                        }
                    }
                    break;
                default:
                    break;
                }
                return true;
            }
            return false;
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            var _showStencilSettings = EditorGUILayout.Foldout( m_showStencilSettings, m_title );
            if ( m_showStencilSettings ) {
                var comp = CompareFunction.Always;
                var pass_op = StencilOp.Keep;
                var fail_op = StencilOp.Keep;
                var zfail_op = StencilOp.Keep;
                var sref = 0;
                var swmask = 255;
                var srmask = 255;
                var showMixedValue = EditorGUI.showMixedValue;
                EditorGUI.BeginChangeCheck();
                try {
                    EditorGUI.indentLevel++;

                    if ( m_prop_StencilComp != null ) {
                        GUI.enabled = m_prop_StencilComp_Enabled;
                        var _comp = ( CompareFunction )m_prop_StencilComp.floatValue;
                        EditorGUI.showMixedValue = m_prop_StencilComp.hasMixedValue;
                        comp = ( CompareFunction )EditorGUILayout.EnumPopup( m_prop_StencilComp.displayName, _comp );
                    }
                    if ( m_prop_Stencil != null ) {
                        GUI.enabled = m_prop_Stencil_Enabled;
                        EditorGUI.showMixedValue = m_prop_Stencil.hasMixedValue;
                        sref = EditorGUILayout.IntField( m_prop_Stencil.displayName, ( int )m_prop_Stencil.floatValue );
                        sref = Mathf.Clamp( sref, 0, 255 );
                    }
                    if ( m_prop_StencilWriteMask != null ) {
                        GUI.enabled = m_prop_StencilWriteMask_Enabled;
                        EditorGUI.showMixedValue = m_prop_StencilWriteMask.hasMixedValue;
                        swmask = EditorGUILayout.IntField( m_prop_StencilWriteMask.displayName, ( int )m_prop_StencilWriteMask.floatValue );
                        swmask = Mathf.Clamp( swmask, 0, 255 );
                    }
                    if ( m_prop_StencilReadMask != null ) {
                        GUI.enabled = m_prop_StencilReadMask_Enabled;
                        EditorGUI.showMixedValue = m_prop_StencilReadMask.hasMixedValue;
                        srmask = EditorGUILayout.IntField( m_prop_StencilReadMask.displayName, ( int )m_prop_StencilReadMask.floatValue );
                        srmask = Mathf.Clamp( srmask, 0, 255 );
                    }
                    if ( m_prop_StencilPass != null ) {
                        GUI.enabled = m_prop_StencilPass_Enabled;
                        var _op = ( StencilOp )m_prop_StencilPass.floatValue;
                        EditorGUI.showMixedValue = m_prop_StencilPass.hasMixedValue;
                        pass_op = ( StencilOp )EditorGUILayout.EnumPopup( m_prop_StencilPass.displayName, _op );
                    }
                    if ( m_prop_StencilFail != null ) {
                        GUI.enabled = m_prop_StencilFail_Enabled;
                        var _op = ( StencilOp )m_prop_StencilFail.floatValue;
                        EditorGUI.showMixedValue = m_prop_StencilFail.hasMixedValue;
                        fail_op = ( StencilOp )EditorGUILayout.EnumPopup( m_prop_StencilFail.displayName, _op );
                    }
                    if ( m_prop_StencilZFail != null ) {
                        GUI.enabled = m_prop_StencilZFail_Enabled;
                        var _op = ( StencilOp )m_prop_StencilZFail.floatValue;
                        EditorGUI.showMixedValue = m_prop_StencilZFail.hasMixedValue;
                        zfail_op = ( StencilOp )EditorGUILayout.EnumPopup( m_prop_StencilZFail.displayName, _op );
                    }
                } finally {
                    GUI.enabled = true;
                    EditorGUI.indentLevel--;
                    if ( EditorGUI.EndChangeCheck() ) {
                        if ( m_prop_StencilComp != null ) {
                            m_prop_StencilComp.floatValue = ( float )comp;
                        }
                        if ( m_prop_Stencil != null ) {
                            m_prop_Stencil.floatValue = ( float )sref;
                        }
                        if ( m_prop_StencilWriteMask != null ) {
                            m_prop_StencilWriteMask.floatValue = ( float )swmask;
                        }
                        if ( m_prop_StencilReadMask != null ) {
                            m_prop_StencilReadMask.floatValue = ( float )srmask;
                        }
                        if ( m_prop_StencilPass != null ) {
                            m_prop_StencilPass.floatValue = ( float )pass_op;
                        }
                        if ( m_prop_StencilFail != null ) {
                            m_prop_StencilFail.floatValue = ( float )fail_op;
                        }
                        if ( m_prop_StencilZFail != null ) {
                            m_prop_StencilZFail.floatValue = ( float )zfail_op;
                        }
                    }
                    EditorGUI.showMixedValue = showMixedValue;
                }
            }
            m_showStencilSettings = _showStencilSettings;
        }

        public override bool SerializeToJSON( JSONObject parent ) {
            return ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilComp ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_Stencil ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilWriteMask ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilReadMask ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilPass ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilFail ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_StencilZFail );
        }

        public override bool DeserializeFromJSON( JSONObject parent ) {
            return ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilComp ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_Stencil ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilWriteMask ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilReadMask ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilPass ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilFail ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_StencilZFail );
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_StencilSettings();
            return ret;
        }
    }
}
