using UnityEngine;
using UnityEditor;
 
public class LuxURPCustomShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

		MaterialProperty _Emission = ShaderGUI.FindProperty("_Emission", properties);
		if (_Emission.floatValue == 1.0f) {
			material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
		}
		else {
			material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
			material.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
		}

	//  Needed to make the Selection Outline work
        if (material.HasProperty("_MainTex") && material.HasProperty("_BaseMap") ) {
            if (material.GetTexture("_BaseMap") != null) {
                material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
            }
        }
        
    }
}