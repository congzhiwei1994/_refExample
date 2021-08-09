Shader "JZPAJ/SceneObject/TreeLeaf"
{
	Properties
	{
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_AlphaMap("Alpha Tex", 2D) = "white" {}
		_FOWMap("迷雾mask图", 2D) = "black" {}
		_AlphaRef("Alpha Cutoff", Range(0.0, 1.0)) = 0.39216
		_PickColor("Pick Color", Color) = (1.00, 1.00, 1.00, 1.00)
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True" }
		LOD 200
		cull off

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

			#include "SceneObjectCore.hlsl"

			struct Varyings
			{
				float4 positionCS	: SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 fovInfo : TEXCOORD1;			// xy: 战场迷雾贴图UV z: 顶点与场景的相对高度
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_AlphaMap);
			SAMPLER(sampler_AlphaMap);

			CBUFFER_START(UnityPerMaterial)
				half _AlphaRef;
				half4 _PickColor;
			CBUFFER_END

			Varyings LitPassVertex(Attributes input)
			{
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

				Varyings output;
				output.positionCS = vertexInput.positionCS + float4(0.0, 0.0, 0.001, 0.0);
				output.uv = input.uv;
				output.fovInfo = CalcFogOfWarInfo(vertexInput.positionWS);
				return output;
			}

			half4 LitPassFragment(Varyings input) : SV_Target
			{
				// cutoff
				half4 alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, input.uv.xy);
				clip(alpha.a - _AlphaRef);

				// 颜色值
				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
				half3 finalColor = MultFogColor(baseColor.rgb);
				finalColor = MixFogOfWarColor(finalColor, input.fovInfo);
				finalColor = MultSceneIllum(finalColor);

				// 透明度
				half finalAlpha = MultAlpha(alpha.a);

				return half4(finalColor, finalAlpha) * _PickColor;
			}
			ENDHLSL
		}
	}
}
