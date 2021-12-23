#ifndef INPUT_BASE_INCLUDED
#define INPUT_BASE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"


	CBUFFER_START(UnityPerMaterial)
	        
	    float4 _BaseMap_ST;
	    half4 _BaseColor;
	    half _Cutoff;
	    
	    half3 _SpecColor;
	    half _Smoothness;
	    half _BumpScale;

	    half _Shrink;
	    half _ShadowOffset;
	    
	CBUFFER_END

#endif