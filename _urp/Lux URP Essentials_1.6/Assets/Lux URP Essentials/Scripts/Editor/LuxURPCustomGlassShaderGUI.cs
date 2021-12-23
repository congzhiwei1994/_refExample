using UnityEngine;
using UnityEditor;
 
public class LuxURPCustomGlassShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

    //  Blending
        int blendMode = (int)material.GetFloat("_Blend");
    //  None
        if (blendMode == 0) {
            material.SetFloat("_SrcBlend", 1.0f);
            material.SetFloat("_DstBlend", 0.0f);
            material.DisableKeyword("_FINALALPHA");
            material.DisableKeyword("_ADDITIVE");
        }
    //  Alpha blending
        else if (blendMode == 1) {
            material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
            material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            material.EnableKeyword("_FINALALPHA");
            material.DisableKeyword("_ADDITIVE");
        }
    //  Additive
        else {
            material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
            material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One);
            material.EnableKeyword("_FINALALPHA");
            material.EnableKeyword("_ADDITIVE");
        }


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

    //  Get RenderQueue Offset - if any
        int QueueOffset = 0;
        if ( material.HasProperty("_QueueOffset") ) {
            QueueOffset = material.GetInt("_QueueOffset");
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