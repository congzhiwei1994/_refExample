Shader "JZPAJ/SceneObject/Water"
{
    Properties
    {
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_ReflectionMap("Reflection Map", 2D) = "white" {}
		[NoScaleOffset]_FOWMap("迷雾mask图", 2D) = "black" {}

		_BaseMapTiling("Base Map Tiling", float) = 10.0
		_UVTiling("UV Tiling", Vector) = (10.0, 10.0, 12.0, 12.0)

		_WaterColor("水的颜色", Color) = (0.2784, 0.7333, 1.00, 1.00)
		_WaterAlpha("水的透明度", float) = 0.5

		_WaveSpeed("Wave Speed", Vector) = (0.03, 0.05, -0.08, 0.04)
		_NormalFactor("Normal Factor", float) = 0.25
		_WaveFactor("Wave Factor", float) = 0.28
		_ReflectFactor("Reflect Factor", float) = 0.3
		_NOVFactor1("NOV Factor 1", float) = 0.28
		_NOVFactor2("NOV Factor 2", float) = 0.79

		_GradientColor("Gradient Color", Color) = (0.395, 0.598, 0.748, 1.00)
		_FogOfWarColor("迷雾颜色", Color) = (0.00, 0.168, 0.298, 0.619)
		_FogColor("雾颜色", Color) = (1.00, 0.96078, 0.9098, 1.00)
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
				float4 uv : TEXCOORD0;				// xy:顶点uv zw:战场迷雾贴图uv
				float4 bumpUV : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				half3 normalWS : TEXCOORD3;
				half3 tangentWS : TEXCOORD4;
				half3 bitangentWS : TEXCOORD5;
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_BumpMap);
			SAMPLER(sampler_BumpMap);

			TEXTURE2D(_ReflectionMap);
			SAMPLER(sampler_ReflectionMap);

			TEXTURE2D(_FOWMap);
			SAMPLER(sampler_FOWMap);

			CBUFFER_START(UnityPerMaterial)
				half _BaseMapTiling;
				half4 _WaterColor;
				half _WaterAlpha;
				half4 _UVTiling;
				half4 _WaveSpeed;
				half _NormalFactor;
				half _WaveFactor;
				half _ReflectFactor;
				half _NOVFactor1;
				half _NOVFactor2;
				half4 _GradientColor;
				half4 _FogOfWarColor;
				half4 _FogColor;
			CBUFFER_END

			Varyings LitPassVertex(Attributes input)
			{
				float2 SceneSize = float2(1280.0, 1280.0);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(float3(0.0, 1.0, 0.0), float4(0.0, 0.0, 1.0, 1.0));
				float3 positionWS = vertexInput.positionWS;

				float4 bumpUV;
				bumpUV.xy = 0.01 * positionWS.xz * _UVTiling.xy + _Time.y * _WaveSpeed.xy;
				bumpUV.zw = 0.01 * positionWS.xz * _UVTiling.zw + _Time.y * _WaveSpeed.zw;

				// 顶点与场景的相对坐标与高度
				float dx = 0.5 + (positionWS.x / SceneSize.x);
				float dz = 0.5 + (positionWS.z / SceneSize.y);

				Varyings output;
				output.positionCS = vertexInput.positionCS;
				output.uv = float4(input.uv, dx, dz);
				output.bumpUV = bumpUV;
				output.positionWS = positionWS;
				output.normalWS = normalInput.normalWS;
				output.tangentWS = normalInput.tangentWS;
				output.bitangentWS = normalInput.bitangentWS;
				return output;
			}

			half4 LitPassFragment(Varyings input) : SV_Target
			{
				half3 camPos = half3(193.60892, 184.00002, -35.54847);

				half3 wave0 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.bumpUV.xy).xyz;
				wave0 = half3((2.0 * wave0.xy - 1.0) * _NormalFactor, 1.0);
				wave0 = normalize(TransformTangentToWorld(wave0, half3x3(input.tangentWS, input.bitangentWS, input.normalWS)));
				half3 wave1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.bumpUV.zw).xyz;
				wave1 = half3((2.0 * wave1.xy - 1.0) * _NormalFactor, 1.0);
				wave1 = normalize(TransformTangentToWorld(wave1, half3x3(input.tangentWS, input.bitangentWS, input.normalWS)));
				half3 wave = lerp(wave0, wave1, 0.5);
				half3 normalWS = lerp(input.normalWS, wave, _WaveFactor);

				//half3 viewDirection = SafeNormalize(GetCameraPositionWS() - input.positionWS);
				half3 viewDirection = SafeNormalize(camPos - input.positionWS);
				half specular = saturate(dot(normalWS, viewDirection));
				specular = 1.0 - smoothstep(_NOVFactor1, _NOVFactor2, specular);

				half3 reflectionMapUV = 0.5 * (1.0 + wave + viewDirection);
				half3 reflectionColor = SAMPLE_TEXTURE2D(_ReflectionMap, sampler_ReflectionMap, reflectionMapUV.xy).rgb;

				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy * _BaseMapTiling);
				half3 finalColor = baseColor.rgb * _FogColor.rgb;
				finalColor = lerp(finalColor, _WaterColor, specular * _WaterAlpha);
				reflectionColor = 0.5 * reflectionColor * (_ReflectFactor + specular);
				finalColor += reflectionColor;

				// 迷雾mask值
				half4 fowMask = SAMPLE_TEXTURE2D(_FOWMap, sampler_FOWMap, input.uv.zw);
				half mask = smoothstep(0.23100001, 0.76899999, 1.0 - fowMask.r);
				mask *= _FogOfWarColor.w;

				// 迷雾颜色（水没有高度）
				half3 tempColor = half3(0.0, 0.168, 0.29800001);
				//half temp = 0.0;//input.sceneUV.z
				//tempColor = lerp(tempColor, _GradientColor.rgb, temp);

				// 根据迷雾mask计算出像素颜色
				//finalColor = lerp(finalColor, tempColor, mask);

				return half4(finalColor, 1);
			}
			ENDHLSL
        }
    }
}
