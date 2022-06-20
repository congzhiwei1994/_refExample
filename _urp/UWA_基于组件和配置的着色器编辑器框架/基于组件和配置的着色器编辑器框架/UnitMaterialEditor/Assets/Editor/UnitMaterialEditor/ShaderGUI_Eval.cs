using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UME.UnitShaderGUIAttribute;

namespace UME {

    [AllowMultiple]
    public class ShaderGUI_Eval : UnitMaterialEditor {

        String m_propName = String.Empty;
        MaterialProperty m_prop = null;

        public override String ToString() {
            var s = base.ToString();
            if ( !String.IsNullOrEmpty( m_propName ) ) {
                s = String.Format( "{0}->{1}", s, m_propName );
            }
            return s;
        }

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
            m_prop = ShaderGUI.FindProperty( m_propName, props, false );
            return true;
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_Eval();
            ret.m_propName = s.name;
            return ret;
        }
    }
}
