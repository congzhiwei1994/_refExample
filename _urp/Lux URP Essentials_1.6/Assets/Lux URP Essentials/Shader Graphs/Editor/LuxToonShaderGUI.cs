using UnityEngine;
using UnityEditor;
using System;

public class LuxToonShaderGUI : ShaderGUI 
{

    public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI (materialEditor, properties);

        Material targetMat = materialEditor.target as Material;

    //	Steps - implement our custom int slider
        if (targetMat.HasProperty("_Steps")) {
	        float steps = targetMat.GetFloat("_Steps");
	        targetMat.SetFloat("_Steps", Mathf.Round(steps));
	    }

	//	Ramp
	    if (targetMat.HasProperty("_EnableRamp")) {
	    	float ramp = targetMat.GetFloat("_EnableRamp");
	    	if(ramp == 1.0f) {
	        	targetMat.EnableKeyword("GRADIENT_ON");
	        	if (targetMat.HasProperty("_RampSmoothSampling")) {
	        		float smoothRamp = targetMat.GetFloat("_RampSmoothSampling");
	    			if(smoothRamp == 1.0f) {
	    				targetMat.EnableKeyword("SMOOTHGRADIENT_ON");
	    			}
	    			else {
	    				targetMat.DisableKeyword("SMOOTHGRADIENT_ON");
	    			}
	    		}
	        }
	        else {
	        	targetMat.DisableKeyword("GRADIENT_ON");
	        	targetMat.DisableKeyword("SMOOTHGRADIENT_ON");
	        }
	    }

    //	Normal
        if (targetMat.HasProperty("_EnableNormalMap")) {
	        float normal = targetMat.GetFloat("_EnableNormalMap");
	        if(normal == 1.0f) {
	        	targetMat.EnableKeyword("NORMAL_ON");
	        }
	        else {
	        	targetMat.DisableKeyword("NORMAL_ON");
	        }
	    }

    //	Specular
        if (targetMat.HasProperty("_EnableSpecular")) {
	        float specular = targetMat.GetFloat("_EnableSpecular");
	        if(specular == 1.0f) {
	        	targetMat.EnableKeyword("SPECULAR_ON");
	        }
	        else {
	        	targetMat.DisableKeyword("SPECULAR_ON");
	        }
	    }

    //	Rim
	    if (targetMat.HasProperty("_EnableToonRim")) {
	        float rim = targetMat.GetFloat("_EnableToonRim");
	        if(rim == 1.0f) {
	        	targetMat.EnableKeyword("RIM_ON");
	        }
	        else {
	        	targetMat.DisableKeyword("RIM_ON");
	        }
	    }

	//	Shadows - we have to reverse the logic here?!
        bool shadows = Array.IndexOf(targetMat.shaderKeywords, "_RECEIVE_SHADOWS_OFF") != -1;
        EditorGUI.BeginChangeCheck();
        shadows = EditorGUILayout.Toggle("Receive Shadows", !shadows);
        if (EditorGUI.EndChangeCheck())
        {
            if (!shadows)
                targetMat.EnableKeyword("_RECEIVE_SHADOWS_OFF");
            else
                targetMat.DisableKeyword("_RECEIVE_SHADOWS_OFF");
        }
    }
}