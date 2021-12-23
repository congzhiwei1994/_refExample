using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEditor.Rendering.Universal;
 
public class LuxURPUniversalCustomShaderGUI : ShaderGUI
{

    public enum SurfaceType {
        Opaque,
        Transparent
    }

    public enum BlendMode {
        Alpha,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
        Additive,
        Multiply
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;
        float surface = 0.0f;
        float surfaceOld = 0.0f;

        if (material.HasProperty("_LuxSurface")) {
            surface = surfaceOld = material.GetFloat("_LuxSurface");
            //surface = (SurfaceType)EditorGUILayout.EnumPopup("Surface Type", surface);
        } 

        base.OnGUI(materialEditor, properties);

    //  Double sided
        if (material.HasProperty("_Cull")) {
            var _Culling = ShaderGUI.FindProperty("_Cull", properties);
            if(_Culling.floatValue == 0.0f) {
                if (material.doubleSidedGI == false) {
                    Debug.Log ("Material " + material.name + ": Double Sided Global Illumination enabled.", (Object)material);
                }
                material.doubleSidedGI = true;
            }
            else {
                if (material.doubleSidedGI == true) {
                    Debug.Log ("Material " + material.name + ": Double Sided Global Illumination disabled.", (Object)material);
                }
                material.doubleSidedGI = false;
            }
        }

    //  Emission
        if ( material.HasProperty("_Emission")) {
            if ( material.GetFloat("_Emission") == 1.0f) {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
            }
            else {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
                material.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }

    //  Get RenderQueue Offset - if any
        int QueueOffset = 0;
        if ( material.HasProperty("_QueueOffset") ) {
            QueueOffset = material.GetInt("_QueueOffset");
        }

    //  Alpha Testing
        bool enableAlphaTesting = false;
    //  Check old custom property
        if ( material.HasProperty("_EnableAlphaTesting")) {
            if ( material.GetFloat("_EnableAlphaTesting") == 1.0f ) {
                if( material.HasProperty("_AlphaFromMaskMap") && material.HasProperty("_MaskMap") ) {
                    if (material.GetFloat("_AlphaFromMaskMap") == 1.0f && material.GetFloat("_EnableMaskMap") == 1.0f) {
                        enableAlphaTesting = true;
                    }
                }
                else {
                    enableAlphaTesting = true;
                }
            }

            if(enableAlphaTesting) {
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest + QueueOffset;
                material.SetOverrideTag("RenderType", "TransparentCutout");
            }
            else {
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry + QueueOffset;
                material.SetOverrideTag("RenderType", "Opaque");
            }
        }
    
    //  We also check for the "standard" property
        if ( material.HasProperty("_AlphaClip")) {

            bool isTransparent = false;
            if (material.HasProperty("_LuxSurface")) {
                if (material.GetFloat("_LuxSurface") == 1.0f) {
                    isTransparent = true;    
                }
            }

            if ( material.GetFloat("_AlphaClip") == 1.0f ) {
                if( material.HasProperty("_AlphaFromMaskMap") && material.HasProperty("_MaskMap") ) {
                    if (material.GetFloat("_AlphaFromMaskMap") == 1.0f && material.GetFloat("_EnableMaskMap") == 1.0f) {
                        enableAlphaTesting = true;
                    }
                }
                else {
                    enableAlphaTesting = true;
                }
            }
            if(enableAlphaTesting) {
                if (isTransparent) {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent + QueueOffset;
                    material.SetOverrideTag("RenderType", "Transparent");   
                }
                else {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest + QueueOffset;
                    material.SetOverrideTag("RenderType", "TransparentCutout");   
                }
                
            }
            else {
                if (isTransparent) {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent + QueueOffset;
                    material.SetOverrideTag("RenderType", "Transparent");   
                }
                else {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry + QueueOffset;
                    material.SetOverrideTag("RenderType", "Opaque"); 
                }
            }
        }

    //  Surface
        if (material.HasProperty("_LuxSurface")) {
            surface = material.GetFloat("_LuxSurface");
            if(surface != surfaceOld) {
                if (surface == 0) {
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    if ( !material.HasProperty("_AlphaClip")) {
                        material.SetOverrideTag("RenderType", "Opaque");
                        material.renderQueue = (int)RenderQueue.Geometry + QueueOffset;
                    }
                    material.SetShaderPassEnabled("ShadowCaster", true);
                }
                else {
                    //else {
                    //    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    //    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);   
                    //}
                    material.SetInt("_ZWrite", 0);
                    if ( !material.HasProperty("_AlphaClip")) {
                        material.SetOverrideTag("RenderType", "Transparent");
                        material.renderQueue = (int)RenderQueue.Transparent + QueueOffset;
                    }
                    material.SetShaderPassEnabled("ShadowCaster", false);
                }
            }
            if (surface == 1.0) {
                if(material.HasProperty("_LuxBlend")){
                    var blendMode = (BlendMode) material.GetFloat("_LuxBlend");
                    switch (blendMode)
                    {
                        case BlendMode.Alpha:
                            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                            material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                            break;
                        case BlendMode.Premultiply:
                            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                            material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                            break;
                        case BlendMode.Additive:
                            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.One);
                            material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                            break;
                        case BlendMode.Multiply:
                            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.DstColor);
                            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                            material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                            material.EnableKeyword("_ALPHAMODULATE_ON");
                            break;
                    }
                }
            }
        }
        else if(material.renderQueue == (int)RenderQueue.Geometry + QueueOffset) {
            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
            material.SetInt("_ZWrite", 1);    
        }

    //  ColorMask - this is currently only used by the toon & outline shader
    //  So if detected base geometry only writes to depth. In order to prevent it from occluding the skybox
    //  we set the render queue to Transparent +
        if ( material.HasProperty("_ColorMask") ) {
            if (material.GetFloat("_ColorMask") == 0) {
                material.renderQueue = (int)RenderQueue.Transparent + QueueOffset;    
            }
        }

    //  Get rid of the normal map issue
        if ( material.HasProperty("_BumpMap") ) {
            if (material.HasProperty("_ApplyNormal") ) {
                if ( material.GetFloat("_ApplyNormal") == 0.0f && material.GetTexture("_BumpMap") == null ) {
                    //material.SetTexture("_BumpMap", Texture2D.normalTexture); // Is not linear?!
                    material.SetTexture("_BumpMap", Resources.Load("LuxURPdefaultBump") as Texture2D );
                }
            }
        }

    //  Needed to make the Selection Outline work
        if (material.HasProperty("_MainTex") && material.HasProperty("_BaseMap") ) {

        //  Alpha might be stored in the Mask Map
            bool copyMaskMap = false;
            if(material.HasProperty("_AlphaFromMaskMap") && material.HasProperty("_MaskMap")) {
                if (material.GetFloat("_AlphaFromMaskMap") == 1.0) {
                    copyMaskMap = true;
                }
            }
            if (copyMaskMap) {
                if (material.GetTexture("_MaskMap") != null) {
                    material.SetTexture("_MainTex", material.GetTexture("_MaskMap"));
                } 
            }
            else {
                if (material.GetTexture("_BaseMap") != null) {
                    material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
                }
            }
        }

    }
}