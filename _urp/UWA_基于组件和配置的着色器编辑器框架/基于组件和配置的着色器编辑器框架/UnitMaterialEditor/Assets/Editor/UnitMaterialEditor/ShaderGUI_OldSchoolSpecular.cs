using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    [Obsolete]
    public class ShaderGUI_OldSchoolSpecular : UnitMaterialEditor {

        MaterialProperty m_prop_MainTex = null;
        MaterialProperty m_prop_MainTex_Alpha = null;
        MaterialProperty m_prop_Color = null;
        MaterialProperty m_prop_Cutoff = null;
        MaterialProperty m_prop_ColorKey = null;
        MaterialProperty m_prop_BumpScale = null;
        MaterialProperty m_prop_BumpMap = null;
        MaterialProperty m_prop_SpecGlossMap = null;
        MaterialProperty m_prop_SpecColor = null;
        MaterialProperty m_prop_Shininess = null;

        static bool _Replace_BumpMapTextureNeedsFixing = false;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            m_prop_MainTex = FindCachedProperty( "_MainTex", props );
            m_prop_MainTex_Alpha = FindCachedProperty( "_MainTex_Alpha", props, false );
            m_prop_Color = FindCachedProperty( "_Color", props );
            m_prop_Cutoff = FindCachedProperty( "_Cutoff", props );
            m_prop_ColorKey = FindCachedProperty( "_ColorKey", props );
            m_prop_BumpScale = FindCachedProperty( "_BumpScale", props, false );
            m_prop_BumpMap = FindCachedProperty( "_BumpMap", props, false );
            m_prop_SpecGlossMap = FindCachedProperty( "_SpecGlossMap", props, false );
            m_prop_SpecColor = FindCachedProperty( "_SpecColor", props, false );
            m_prop_Shininess = FindCachedProperty( "_Shininess", props );
            return true;
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_OldSchoolSpecular();
        }
        
        protected override void OnRefreshKeywords() {
            var materials = targets;
            if ( !m_prop_BumpMap.hasMixedValue ) {
                SetKeyword( materials, "_NORMALMAP", m_prop_BumpMap != null && m_prop_BumpMap.textureValue != null );
            }
            if ( !m_prop_SpecGlossMap.hasMixedValue ) {
                SetKeyword( materials, "_SPECGLOSSMAP", m_prop_SpecGlossMap != null && m_prop_SpecGlossMap.textureValue != null );
            }
        }

        [MethodImpl( MethodImplOptions.NoInlining )]
        static bool BumpMapTextureNeedsFixing( MaterialProperty prop ) {
            if ( _Replace_BumpMapTextureNeedsFixing ) {
                return _BumpMapTextureNeedsFixing( prop );
            } else {
                return BumpMapTextureNeedsFixing_Proxy( prop );
            }
        }

        [MethodImpl( MethodImplOptions.NoInlining )]
        static bool BumpMapTextureNeedsFixing_Proxy( MaterialProperty prop ) {
            Debug.Log( "This is will be the original method after hook installed." );
            return false;
        }

        internal static bool _BumpMapTextureNeedsFixing( MaterialProperty prop ) {
            bool result;
            if ( prop.type != MaterialProperty.PropType.Texture ) {
                result = false;
            } else {
                bool flaggedAsNormal = ( prop.flags & MaterialProperty.PropFlags.Normal ) != MaterialProperty.PropFlags.None;
                UnityEngine.Object[] targets = prop.targets;
                for ( int i = 0; i < targets.Length; i++ ) {
                    Material material = ( Material )targets[ i ];
                    if ( material.IsKeywordEnabled( "_SPECULAR_TEXTURE_NORMAL_CHANNEL_A" ) ) {
                        continue;
                    }
                    if ( UnityEditorInternal.InternalEditorUtility.BumpMapTextureNeedsFixingInternal( material, prop.name, flaggedAsNormal ) ) {
                        result = true;
                        return result;
                    }
                }
                result = false;
            }
            return result;
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            var gui = FindPropEditor<ShaderGUI_RenderMode>();
            var mode = gui != null ? gui._Mode : RenderMode.Opaque;
            var useAlpha = gui != null ? gui.useAlpha : false;
            if ( m_prop_MainTex != null &&
                ( m_prop_MainTex.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.TexturePropertySingleLine(
                    new GUIContent( m_prop_MainTex.displayName ),
                    m_prop_MainTex, m_prop_Color );
                EditorGUI.indentLevel++;
                m_MaterialEditor.TextureScaleOffsetProperty( m_prop_MainTex );
                EditorGUI.indentLevel--;
            }
            if ( useAlpha && m_prop_MainTex_Alpha != null &&
                ( m_prop_MainTex_Alpha.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.TexturePropertySingleLine(
                    new GUIContent( m_prop_MainTex_Alpha.displayName ),
                    m_prop_MainTex_Alpha );
            }
            if ( m_prop_BumpMap != null &&
                ( m_prop_BumpMap.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                try {
                    _Replace_BumpMapTextureNeedsFixing = true;
                    m_MaterialEditor.TexturePropertySingleLine(
                        new GUIContent( m_prop_BumpMap.displayName ),
                        m_prop_BumpMap,
                        m_prop_BumpMap.textureValue != null ?
                            m_prop_BumpScale : null
                    );
                } finally {
                    _Replace_BumpMapTextureNeedsFixing = false;
                }
            }
            if ( m_prop_SpecGlossMap != null &&
                ( m_prop_SpecGlossMap.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.TexturePropertySingleLine(
                    new GUIContent( m_prop_SpecGlossMap.displayName ),
                    m_prop_SpecGlossMap,
                    m_prop_SpecColor
                );
            } else if ( m_prop_SpecColor != null &&
                ( m_prop_SpecColor.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.ShaderProperty( m_prop_SpecColor, m_prop_SpecColor.displayName );
            }
            if ( m_prop_Shininess != null &&
                ( m_prop_Shininess.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.ShaderProperty( m_prop_Shininess, m_prop_Shininess.displayName );
            }
            if ( mode == RenderMode.Cutout && m_prop_Cutoff != null &&
                ( m_prop_Cutoff.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.ShaderProperty( m_prop_Cutoff, m_prop_Cutoff.displayName );
            } else if ( mode == RenderMode.ColorKey &&
                ( m_prop_ColorKey.flags & MaterialProperty.PropFlags.HideInInspector ) == 0 ) {
                m_MaterialEditor.ShaderProperty( m_prop_ColorKey, m_prop_ColorKey.displayName );
            }
        }
    }
}
