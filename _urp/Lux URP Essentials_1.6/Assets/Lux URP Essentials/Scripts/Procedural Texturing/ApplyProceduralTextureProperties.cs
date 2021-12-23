using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyProceduralTextureProperties : MonoBehaviour
{
    [Space(5)]
    public Material m_Material;
    [Space(5)]
    public ProceduralTexture2D proceduralTexAssetAlbedo;
    public ProceduralTexture2D proceduralTexAssetNormal;
    public ProceduralTexture2D proceduralTexAssetMask;

    public void SyncMatWithProceduralTextureAsset() {

    	if(m_Material == null) {
    		return;
    	}

        if(proceduralTexAssetAlbedo != null) {
        	m_Material.SetTexture	("_Tinput_Albedo", proceduralTexAssetAlbedo.Tinput);
        	m_Material.SetTexture	("_invT_Albedo", proceduralTexAssetAlbedo.invT);
        	
        	m_Material.SetVector 	("_InputSize_Albedo", new Vector3(proceduralTexAssetAlbedo.Tinput.width, proceduralTexAssetAlbedo.Tinput.height, 1.0f / proceduralTexAssetAlbedo.invT.height));
            m_Material.SetVector    ("_CompressionScalars_Albedo",proceduralTexAssetAlbedo.compressionScalers);

        	m_Material.SetVector 	("_ColorSpaceOrigin_Albedo",proceduralTexAssetAlbedo.colorSpaceOrigin);
        	m_Material.SetVector 	("_ColorSpaceVector1_Albedo",proceduralTexAssetAlbedo.colorSpaceVector1);
        	m_Material.SetVector 	("_ColorSpaceVector2_Albedo",proceduralTexAssetAlbedo.colorSpaceVector2);
        	m_Material.SetVector 	("_ColorSpaceVector3_Albedo",proceduralTexAssetAlbedo.colorSpaceVector3);
        }

        if(proceduralTexAssetNormal != null) {
            m_Material.SetTexture   ("_Tinput_Normal", proceduralTexAssetNormal.Tinput);
            m_Material.SetTexture   ("_invT_Normal", proceduralTexAssetNormal.invT);

            m_Material.SetVector    ("_InputSize_Normal", new Vector3(proceduralTexAssetNormal.Tinput.width, proceduralTexAssetNormal.Tinput.height, 1.0f / proceduralTexAssetNormal.invT.height));
            m_Material.SetVector    ("_CompressionScalars_Normal",proceduralTexAssetNormal.compressionScalers);
        }

        if(proceduralTexAssetMask != null) {
            m_Material.SetTexture   ("_Tinput_Mask", proceduralTexAssetMask.Tinput);
            m_Material.SetTexture   ("_invT_Mask", proceduralTexAssetMask.invT);
            
            m_Material.SetVector    ("_InputSize_Mask", new Vector3(proceduralTexAssetMask.Tinput.width, proceduralTexAssetMask.Tinput.height, 1.0f / proceduralTexAssetMask.invT.height));
            m_Material.SetVector    ("_CompressionScalars_Mask",proceduralTexAssetMask.compressionScalers);

            m_Material.SetVector    ("_ColorSpaceOrigin_Mask",proceduralTexAssetMask.colorSpaceOrigin);
            m_Material.SetVector    ("_ColorSpaceVector1_Mask",proceduralTexAssetMask.colorSpaceVector1);
            m_Material.SetVector    ("_ColorSpaceVector2_Mask",proceduralTexAssetMask.colorSpaceVector2);
            m_Material.SetVector    ("_ColorSpaceVector3_Mask",proceduralTexAssetMask.colorSpaceVector3);
        }
    }
}