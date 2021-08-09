Shader "JZPAJ/SceneObject/Lampstand"
{
	Properties
	{
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_ProZBias("Pro Z Bias", float) = 0.0
		_DiscardAmount("Discard Amount", Range(0.0, 1.0)) = 0.0
		_AlphaMtl("AlphaMtl", float) = 1.0
		_SupportHeroAlpha("Support Hero Alpha", float) = 0.0
		_HeroAlphaRandom("Hero Alpha Random", float) = 1.0
		_ChangeColor("Change Color", Color) = (1.00, 0.96078, 0.9098, 1.00)
		_PickColor("Pick Color", Color) = (1.00, 1.00, 1.00, 1.00)
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True" }
		LOD 200

		Pass
		{
			Name "StandardLit"
			Tags{ "LightMode" = "UniversalForward" }

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fog

			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			CBUFFER_START(UnityPerMaterial)
				half _ProZBias;
				half _DiscardAmount;
				half _AlphaMtl;
				half _SupportHeroAlpha;
				half _HeroAlphaRandom;
				half4 _ChangeColor;
				half4 _PickColor;
			CBUFFER_END

			Varyings LitPassVertex(Attributes input)
			{
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				Varyings output;
				output.positionCS = vertexInput.positionCS + float4(0.0, 0.0, _ProZBias, 0.0);
				output.uv = input.uv;
				return output;
			}

			half4 LitPassFragment(Varyings input) : SV_Target
			{
				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
				clip(baseColor.a - _DiscardAmount);

				half3 finalColor = baseColor.rgb * _ChangeColor.rgb;
				half finalAlpha = baseColor.a * _AlphaMtl;
				half temp = lerp(step(1.0, finalAlpha), step(1.0, _AlphaMtl), _SupportHeroAlpha);
				finalAlpha = lerp(finalAlpha, _HeroAlphaRandom, temp);
				return half4(finalColor, finalAlpha) * _PickColor;
			}
			ENDHLSL
		}
	}
}
