Shader "JZPAJ/SceneObject/Enemy"
{
    Properties
    {
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_FOWMap("迷雾mask图", 2D) = "black" {}
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

			#include "SceneObjectCore.hlsl"

			struct Varyings
			{
				float4 positionCS	: SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 fovInfo : TEXCOORD1;			// xy: 战场迷雾贴图UV z: 顶点与场景的相对高度
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			CBUFFER_START(UnityPerMaterial)
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
				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);

				// 颜色值
				half3 finalColor = MultFogColor(baseColor.rgb);
				finalColor = MixFogOfWarColor(finalColor, input.fovInfo);
				finalColor = MultSceneIllum(finalColor);

				// 透明度
				half finalAlpha = MultAlpha(baseColor.a);

				return half4(finalColor, finalAlpha) * _PickColor;
			}
			ENDHLSL
		}
    }
}
