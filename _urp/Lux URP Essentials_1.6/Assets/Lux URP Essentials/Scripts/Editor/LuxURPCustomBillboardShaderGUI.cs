using UnityEngine;
using UnityEditor;
 
public class LuxURPCustomBillboardShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

        var _Surface = ShaderGUI.FindProperty("_Surface", properties);
        int QueueOffset = material.GetInt("_QueueOffset");
    
    //  Alpha Testing
        if(_Surface.floatValue == 0.0f) {
            material.EnableKeyword("_ALPHATEST_ON");
            material.DisableKeyword("_APPLYFOGADDITIVELY");
            if (material.GetInt("_ApplyFog") == 1) {
                material.EnableKeyword("_APPLYFOG");
                material.DisableKeyword("_APPLYFOGADDITIVELY");    
            }

            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest + QueueOffset;
            material.SetOverrideTag("RenderType", "TransparentCutout");
            material.SetInt("_ZWrite", 1);

            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);

            material.SetShaderPassEnabled("ShadowCaster", true);    
        }

    //  Alpha Blending
        else {
            material.DisableKeyword("_ALPHATEST_ON");

            material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent + QueueOffset;
            material.SetOverrideTag("RenderType", "Transparent");
            material.SetInt("_ZWrite", 0);
            if (material.GetInt("_Blend") == 0) {
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.DisableKeyword("_APPLYFOGADDITIVELY");
                if (material.GetInt("_ApplyFog") == 1) {
                    material.EnableKeyword("_APPLYFOG");   
                }
                else {
                    material.DisableKeyword("_APPLYFOG"); 
                }
            }
            else if (material.GetInt("_Blend") == 1)  {
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.DisableKeyword("_APPLYFOG");
                if (material.GetInt("_ApplyFog") == 1) {
                    material.EnableKeyword("_APPLYFOGADDITIVELY");   
                }
                else {
                    material.DisableKeyword("_APPLYFOGADDITIVELY"); 
                }
            }
            else {
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusDstColor);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.DisableKeyword("_APPLYFOG");
                if (material.GetInt("_ApplyFog") == 1) {
                    material.EnableKeyword("_APPLYFOGADDITIVELY");   
                }
                else {
                    material.DisableKeyword("_APPLYFOGADDITIVELY"); 
                }
            }

            material.SetShaderPassEnabled("ShadowCaster", false);
        }


    	if (material.HasProperty("_Culling")) {
	    	var _Culling = ShaderGUI.FindProperty("_Culling", properties);
			if(_Culling.floatValue == 0.0f) {
				if (material.doubleSidedGI == false) {
					Debug.Log ("Double Sided Global Illumination enabled.");
				}
        		material.doubleSidedGI = true;
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
    }
}