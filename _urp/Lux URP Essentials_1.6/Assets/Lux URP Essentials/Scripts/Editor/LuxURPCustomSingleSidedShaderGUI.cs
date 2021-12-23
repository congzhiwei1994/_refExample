using UnityEngine;
using UnityEditor;
 
public class LuxURPCustomSingleSidedShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

    //  Old signature
    	if (material.HasProperty("_Culling")) {
	    	var _Culling = ShaderGUI.FindProperty("_Culling", properties);
			if(_Culling.floatValue == 0.0f) {
				if (material.doubleSidedGI == false) {
					Debug.Log ("Double Sided Global Illumination enabled.");
				}
        		material.doubleSidedGI = true;
        	}
	    }
    //  Handle both cases
        if (material.HasProperty("_Cull")) {
            var _Cull = ShaderGUI.FindProperty("_Cull", properties);
            if(_Cull.floatValue == 0.0f) {
                if (material.doubleSidedGI == false) {
                    Debug.Log ("Double Sided Global Illumination enabled.");
                }
                material.doubleSidedGI = true;
            }
        }

        if (material.HasProperty("_AlphaClip")) {
            var _AlphaClip = ShaderGUI.FindProperty("_AlphaClip", properties);
            if(_AlphaClip.floatValue == 1.0f) {
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                material.SetOverrideTag("RenderType", "TransparentCutout");
            }
            else {
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                material.SetOverrideTag("RenderType", "Opaque");
            }
        }

        //material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
        //material.SetOverrideTag("RenderType", "TransparentCutout");

    //  Needed to make the Selection Outline work
        if (material.HasProperty("_MainTex") && material.HasProperty("_BaseMap") ) {
            if (material.GetTexture("_BaseMap") != null) {
                material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
            }
        }
    }
}