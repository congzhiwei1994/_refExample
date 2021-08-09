Shader "JZPAJ/SceneObject/Base"
{
	Properties
	{
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_FOWMap("迷雾mask图", 2D) = "black" {}

		_SigX("Sig X", float) = -70.0
		_SigZ("Sig Z", float) = -70.0
		_AdjustMulti("Adjust Multi", float) = 1.51
		_AdjustArea("Adjust Area", float) = -0.03
		_AdjustAlpha("Adjust Alpha", float) = 1.0
		_ChangedColor("Changed Color", Color) = (0.858, 0.686, 0.6627, 1.00)

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
				float3 uv : TEXCOORD0;				// xy: 模型uv坐标 z: 是否敌方（如果是需要调整颜色）
				float3 fovInfo : TEXCOORD1;			// xy: 战场迷雾贴图UV z: 顶点与场景的相对高度
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			CBUFFER_START(UnityPerMaterial)
				half _SigX;
				half _SigZ;
				half _AdjustMulti;
				half _AdjustArea;
				half _AdjustAlpha;
				half4 _ChangedColor;
				half4 _PickColor;
			CBUFFER_END

			Varyings LitPassVertex(Attributes input)
			{
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

				// 根据世界坐标判断阵营
				float3 positionWS = vertexInput.positionWS;
				float sig = step(0.0, positionWS.x + positionWS.z + _SigX + _SigZ);

				Varyings output;
				output.positionCS = vertexInput.positionCS + float4(0.0, 0.0, 0.001, 0.0);
				output.uv = float3(input.uv.xy, sig);
				output.fovInfo = CalcFogOfWarInfo(positionWS);
				return output;
			}

			half4 LitPassFragment(Varyings input) : SV_Target
			{
				// 主贴图颜色
				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);

				// 阵营颜色
				half temp = 2.0 * baseColor.g - baseColor.r - baseColor.b + _AdjustArea;
				temp = 2.0 * saturate(temp * _AdjustAlpha);
				temp *= input.uv.z;
				half3 adjustColor = baseColor.rgb * _ChangedColor.rgb * _AdjustMulti;

				// 颜色值
				half3 finalColor = lerp(baseColor.rgb, adjustColor, temp);
				finalColor = MultFogColor(finalColor);
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
