using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.LWRP;

namespace LuxLWRPEssentials.Demo {
	public class CheckSettings : MonoBehaviour
	{
	    // Start is called before the first frame update
	    void Start()
	    {
	        UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset lwrp = GraphicsSettings.renderPipelineAsset as UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset;

	        if (lwrp.supportsCameraDepthTexture == true) {
	        	Debug.Log("CameraDepthTexture supported.");
	        }
	        else {
	        	Debug.Log("CameraDepthTexture not supported.");
	        }

	        if (lwrp.supportsCameraOpaqueTexture == true) {
	        	Debug.Log("CameraOpaqueTexture supported.");
	        }
	        else {
	        	Debug.Log("CameraOpaqueTexture not supported.");
	        }

	    }

	    // Update is called once per frame
	    void Update()
	    {
	        
	    }
	}
}
