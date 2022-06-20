using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_GetTextureFormat : UnitMaterialEditor {

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
            returnValue = ComputeReturnValue( props );
            return true;
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            m_prop = FindProperty( m_propName, props );
            return m_prop != null;
        }

        protected override String ComputeReturnValue( MaterialProperty[] props ) {
            if ( m_prop != null && m_prop.type == MaterialProperty.PropType.Texture ) {
                var texture = m_prop.textureValue;
                if ( texture != null ) {
                    var type = texture.GetType();
                    var format = "unknown";
                    if ( type == typeof( Texture2D ) ) {
                        format = ( texture as Texture2D ).format.ToString();
                    } else if ( type == typeof( Texture3D ) ) {
                        format = ( texture as Texture3D ).format.ToString();
                    } else if ( type == typeof( Texture2DArray ) ) {
                        format = ( texture as Texture2DArray ).format.ToString();
                    }
                    return format;
                }
            }
            return "null";
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_GetTextureFormat();
            ret.m_propName = s.name;
            return ret;
        }

    }
}
