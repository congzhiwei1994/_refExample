Shader "JZPAJ/SceneObject/Grass"
{
    Properties
    {
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_AlphaMap("Alpha Tex", 2D) = "white" {}
		_FOWMap("迷雾mask图", 2D) = "black" {}
		_WindFactor("风力", float) = 0.000005
		_MaxDistFactor("离玩家最远距离", float) = 20.0
		_ActFactor("摇摆强度", float) = 0.0015
		_AlphaRef("Alpha Cutoff", Range(0.0, 1.0)) = 0.39216
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

			TEXTURE2D(_AlphaMap);
			SAMPLER(sampler_AlphaMap);

			CBUFFER_START(UnityPerMaterial)
				half _WindFactor;
				half _MaxDistFactor;
				half _ActFactor;
				half _AlphaRef;
				half4 _PickColor;
			CBUFFER_END

			float3 CalcGrassVertex(in float3 positionWS, half wind, half maxDist, half act)
			{
				// xy: 玩家角色的xz坐标 zw:摆动值
				float4 WindInfo = float4(-528.79565, 47.05514, 0.00, 0.00);

				// 风力
				float curWind = -wind * sin(2.0 * _Time.y);

				// 玩家移动到草时的摆动
				float2 toPlayerDist = length(positionWS.xz - WindInfo.xy);
				float t = clamp((maxDist - toPlayerDist) / maxDist, 0.0, 1.0);
				float swing = act * t;

				// 偏移值 = 风力 + 摇摆 (备注：y轴越大，偏移最大)
				float yPow2 = positionWS.y * positionWS.y;
				float yPow4 = yPow2 * yPow2;
				float2 offsetXZ = yPow4 * (swing * WindInfo.zw + curWind.xx);

				// 根据xy的偏移值计算出y的偏移值
				float offsetY = sqrt(yPow2 - offsetXZ.x - offsetXZ.y);
				offsetY *= sign(positionWS.y);

				return positionWS + float3(offsetXZ.x, offsetY, offsetXZ.y);
			}

			Varyings LitPassVertex(Attributes input)
			{
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				float3 positionWS = CalcGrassVertex(vertexInput.positionWS, _WindFactor, _MaxDistFactor, _ActFactor);

				Varyings output;
				output.positionCS = TransformWorldToHClip(positionWS) + float4(0.0, 0.0, 0.001, 0.0);
				output.uv = input.uv;
				output.fovInfo = CalcFogOfWarInfo(positionWS);
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
