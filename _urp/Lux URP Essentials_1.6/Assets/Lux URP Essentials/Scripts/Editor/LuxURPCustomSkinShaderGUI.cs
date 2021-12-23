using UnityEngine;
using UnityEditor;
 
public class LuxURPCustomSkinShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

    	if (material.HasProperty("_SkinLUT")) {
            if ( material.GetTexture("_SkinLUT") == null) {
                material.SetTexture("_SkinLUT", Resources.Load("DiffuseScatteringOnRing") as Texture2D );
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