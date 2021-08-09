Shader "JZPAJ/CharacterLow"
{
    Properties
    {
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
	

		_AlphaMtl("_AlphaMtl", Float) = 1.0
		_Hero_Alpha_Random("_Hero_Alpha_Random", Float) = 1.0
		_Support_Hero_Alpha("_Support_Hero_Alpha", Float) = 1.0
		_Change_Color("_Change_Color", Color) = (1.0,1.0,1.0,1.0)
		_DiscardAmount("_DiscardAmount", Float) = 0
		_PickColor("_PickColor", Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 100

		Pass
		{
			//Name "StandardLit"
			//Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// 自定义 keywords


			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment


			#include "CharacterLowCore.hlsl"

			ENDHLSL

		}

    }
}
