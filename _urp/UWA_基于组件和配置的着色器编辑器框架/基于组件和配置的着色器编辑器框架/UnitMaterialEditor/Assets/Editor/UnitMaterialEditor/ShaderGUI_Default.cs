using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_Default : UnitMaterialEditor {

        List<MaterialProperty> m_props = null;

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            if ( m_props != null ) {
                for ( int i = 0; i < m_props.Count; ++i ) {
                    var item = m_props[ i ];
                    var defaultProp = item;
                    if ( ( defaultProp.flags & ( MaterialProperty.PropFlags.HideInInspector | MaterialProperty.PropFlags.PerRendererData ) ) == MaterialProperty.PropFlags.None ) {
                        m_MaterialEditor.SetDefaultGUIWidths();
                        float h = m_MaterialEditor.GetPropertyHeight( defaultProp, defaultProp.displayName );
                        Rect r = EditorGUILayout.GetControlRect( true, h, EditorStyles.layerMaskField );
                        var showMixedValue = EditorGUI.showMixedValue;
                        try {
                            EditorGUI.showMixedValue = defaultProp.hasMixedValue;
                            m_MaterialEditor.ShaderProperty( r, defaultProp, defaultProp.displayName );
                        } finally {
                            m_MaterialEditor.SetDefaultGUIWidths();
                            EditorGUI.showMixedValue = showMixedValue;
                        }
                    }
                }
            }
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            if ( m_props == null ) {
                m_props = new List<MaterialProperty>( props.Length );
            } else {
                m_props.Clear();
            }
            var excludes = FindPropEditors<UnitMaterialEditor>();
            for ( int i = 0; i < props.Length; ++i ) {
                var name = props[ i ].name;
                var used = false;
                for ( int j = 0; j < excludes.Count; ++j ) {
                    var usedProps = excludes[ j ].usedPropNames;
                    if ( usedProps != null ) {
                        if ( usedProps.IndexOf( name ) >= 0 ) {
                            used = true;
                            break;
                        }
                    }
                }
                if ( !used ) {
                    m_props.Add( props[ i ] );
                }
            }
            return true;
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_Default();
            return ret;
        }
    }
}
