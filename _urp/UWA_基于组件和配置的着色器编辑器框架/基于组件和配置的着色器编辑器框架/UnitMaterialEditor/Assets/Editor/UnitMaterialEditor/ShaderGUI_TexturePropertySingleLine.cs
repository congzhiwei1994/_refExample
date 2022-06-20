using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    [Obsolete]
    public class ShaderGUI_TexturePropertySingleLine : ShaderGUI_SingleProp {

        protected String m_propName2 = String.Empty;
        protected MaterialProperty m_prop2 = null;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            var ret = base.OnInitProperties( props );
            if ( !ret ) {
                return false;
            }
            if ( m_prop == null || m_prop.type != MaterialProperty.PropType.Texture ) {
                Debug.LogErrorFormat( "Invalid GUI for '{0}'", m_propName );
                return false;
            }
            if ( m_args != null ) {
                m_propName2 = String.Empty;
                if ( m_args.GetField( out m_propName2, "name2", String.Empty ) ) {
                    m_prop2 = FindProperty( m_propName2, props, false );
                }
            }
            return true;
        }

        protected override void OnResetToDefaultValue( Material template ) {
            base.OnResetToDefaultValue( template );
            ResetToDefaultValue( template, m_prop2 );
        }

        protected override void OnDrawGUI() {
            var label = m_label ?? m_prop.displayName;
            float h = m_MaterialEditor.GetPropertyHeight( m_prop2, label );
            Rect r = EditorGUILayout.GetControlRect( true, h, EditorStyles.layerMaskField );
            for (; ; ) {
                m_MaterialEditor.TexturePropertySingleLine( new GUIContent( label ), m_prop, m_prop2 );
                if ( m_precision >= 0 ) {
                    FixPropertyPrecision( m_prop2 );
                }
                break;
            }
        }

        public new static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_TexturePropertySingleLine();
            ret.m_propName = s.name;
            return ret;
        }
    }
}
//EOF
