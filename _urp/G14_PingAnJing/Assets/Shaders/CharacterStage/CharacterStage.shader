Shader "JZPAJ/CharacterStage"
{
    Properties
    {
		_BaseMap("Albedo (RGB)", 2D) = "white" {}
		_MixMap("Mix Map", 2D) = "black" {}

		_AlphaMtl("AlphaMtl", float) = 1.0

		_ShadowShakeFrequency("Shadow Shake Frequency", Vector) = (2.00, 2.50, 2.30, 1.50)
		_ShadowShakeAmplitude("Shadow Shake Amplitude", Vector) = (0.007, 0.004, -0.006, 1.00)
		_ShadowShineFrequency("Shadow Shine Frequency", float) = 2.3
		_GlowFactor("Glow Factor", Vector) = (0.50, 1.00, 0.5, 0)

		_ShadowAlpha("Shadow Alpha", Range(0, 1)) = 0.82
		_ShadowPosFactor01("Shadow Pos Factor01", Vector) = (0.015, 0.02, 0.20, -0.05)
		_ShadowClination("Shadow Clination", Vector) = (0.003, -0.003, 0.0, 0.0)
		_ShadowColorTrans("Shadow Color Trans", Vector) = (0.01, 1.80, 0.0, 0.0)
		_ShadowColor1("Shadow Color 1", Color) = (0.28, 0.38, 0.71, 1.00)
		_ShadowColor2("Shadow Color 2", Color) = (1.00, 0.00, 0.40, 1.00)
		_ShadowDensity("Shadow Density", Range(0, 1)) = 0.53

		_GlowColor("Glow Color", Color) = (1.00, 0.8314, 0.3765, 1.00)
		_GlowDiffFactor("Glow Diff Factor", Vector) = (0.35, 0.60, 0.0, 0.0)
		_GlowPosBias("Glow Pos Bias", Vector) = (0.00, -0.20, 0.0, 0.0)
		_GlowPosFactor01("Glow Pos Factor01", Vector) = (0.008, 0.015, 0.25, 1.10)
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
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

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
				float3 uv : TEXCOORD0;						// xy: uv, z: glow intensity
				float4 positionWSAndFogFactor : TEXCOORD1;	// xyz: 世界坐标, w: vertex fog factor
				half4 shakeAmount : TEXCOORD2;
				half4 shakeAndShineAmount : TEXCOORD3;
#ifdef _MAIN_LIGHT_SHADOWS
				float4 shadowCoord : TEXCOORD4;
#endif
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_MixMap);
			SAMPLER(sampler_MixMap);

			CBUFFER_START(UnityPerMaterial)
				half _AlphaMtl;
				half4 _ShadowShakeFrequency;
				half4 _ShadowShakeAmplitude;
				half _ShadowShineFrequency;
				half4 _GlowFactor;
				half _ShadowAlpha;
				half4 _ShadowPosFactor01;
				half4 _ShadowClination;
				half4 _ShadowColorTrans;
				half4 _ShadowColor1;
				half4 _ShadowColor2;
				half _ShadowDensity;
				half4 _GlowColor;
				half4 _GlowDiffFactor;
				half4 _GlowPosBias;
				half4 _GlowPosFactor01;
			CBUFFER_END

			Varyings LitPassVertex(Attributes input)
			{
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				float3 positionWS = vertexInput.positionWS;

				half4 shakeAmount;
				float frequency = _Time.y * _ShadowShakeFrequency.x;
				shakeAmount.x = sin(frequency) + 0.37 * sin(0.31999999 + 1.7 * frequency);
				shakeAmount.y = -1.3 * sin(0.67000002 + frequency) + 0.56999999 * sin(1.0700001 + 1.37 * frequency);
				shakeAmount.xy *= _ShadowShakeAmplitude.x;

				frequency = _Time.y * _ShadowShakeFrequency.y;
				shakeAmount.z = sin(frequency) + 0.67000002 * sin(0.31999999 + 2.7 * frequency);
				shakeAmount.w = -0.76999998 * sin(0.76999998 + frequency) + 0.47 * sin(1.17 + 2.3699999 * frequency);
				shakeAmount.zw *= _ShadowShakeAmplitude.y;

				half4 shakeAndShineAmount;
				frequency = _Time.y * _ShadowShakeFrequency.z;
				shakeAndShineAmount.x = 0.63999999 * sin(frequency) + 0.56999999 * sin(1.3200001 + 2.3 * frequency);
				shakeAndShineAmount.y = 1.1 * sin(0.47 + frequency) + 0.76999998 * sin(1.77 + 1.87 * frequency);
				shakeAndShineAmount.xy *= _ShadowShakeAmplitude.z;

				frequency = _Time.y * _ShadowShineFrequency;
				shakeAndShineAmount.z = sin(frequency);
				shakeAndShineAmount.w = sin(0.93000001 + 0.75999999 * frequency);
				shakeAndShineAmount.zw = 0.5 * (1.0 + shakeAndShineAmount.zw);

				float t = 0.5 + 0.5 * sin(_Time.y * _GlowFactor.z);
				float glowIntensity = lerp(_GlowFactor.x, _GlowFactor.y, t);

				Varyings output;
				output.positionCS = vertexInput.positionCS;
				output.uv = float3(input.uv, glowIntensity);
				output.positionWSAndFogFactor = float4(positionWS, ComputeFogFactor(vertexInput.positionCS.z));
				output.shakeAmount = shakeAmount;
				output.shakeAndShineAmount = shakeAndShineAmount;
#ifdef _MAIN_LIGHT_SHADOWS
				output.shadowCoord = GetShadowCoord(vertexInput);
#endif
				return output;
			}

			half4 LitPassFragment(Varyings input) : SV_Target
			{
				half3 ConstPos = half3(-0.70999998, 4.6999998, -45.529999);
				half3 AmbientColor = half3(1.00, 1.00, 1.00);
				half3 GreyValue = half3(0.30000001, 0.58999997, 0.11);	// 灰度值

				half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
				half3 positionWS = input.positionWSAndFogFactor.xyz;
				half2 distanceXZ = positionWS.xz - ConstPos.xz;

#ifdef _MAIN_LIGHT_SHADOWS
				Light shadowLight = GetMainLight(input.shadowCoord);
				half inShadow = 1 - shadowLight.shadowAttenuation;
#else
				half inShadow = 0.0;
#endif

				half2 tempValue = 0.5 + distanceXZ * _ShadowPosFactor01.xy + _ShadowPosFactor01.zw;
				tempValue += _ShadowClination.xy * (positionWS.y - ConstPos.y);
				half2 uv = input.shakeAmount.xy + tempValue.xy;
				half temp0 = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv).r;
				half temp1 = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv + input.shakeAmount.zw).g;
				half temp2 = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv + input.shakeAndShineAmount.xy).g;
				temp1 = lerp(temp1, 1.0, input.shakeAndShineAmount.z);
				temp2 = lerp(temp2, 1.0, input.shakeAndShineAmount.w);
				inShadow = min(temp2, min(temp1, min(inShadow, temp0)));

				tempValue = 0.5 * distanceXZ * _GlowPosFactor01.xy + _GlowPosBias.xy;
				tempValue += _ShadowClination.xy * (positionWS.y - ConstPos.y);
				uv = input.shakeAmount.xy + input.shakeAmount.zw + input.shakeAndShineAmount.xy;
				uv = tempValue + _GlowPosFactor01.z * uv;
				temp0 = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv).b;

				half grey = dot(baseColor.rgb, GreyValue);
				half glow = smoothstep(_GlowDiffFactor.x, _GlowDiffFactor.y, grey);
				glow *= saturate(2.0 * temp0 - 1.0) * inShadow;

				inShadow = min(inShadow, saturate(2.0 * temp0));
				half3 finalColor = baseColor.rgb * AmbientColor;
				half shadowAlpha = lerp(_ShadowAlpha, 1.0, inShadow);
				half shadowTrans = smoothstep(_ShadowColorTrans.x, _ShadowColorTrans.y, inShadow);
				half3 shadowColor = lerp(_ShadowColor1.rgb, _ShadowColor2.rgb, shadowTrans);
				shadowColor = AmbientColor * shadowAlpha * lerp(finalColor, shadowColor, _ShadowDensity);
				finalColor = lerp(finalColor, shadowColor, inShadow);

				half3 tempColor = 2.0 * (1.0 - finalColor);
				half3 glowColor = _GlowColor.rgb;
				glowColor = 1.0 - (1.0 - glowColor) * tempColor;
				glowColor *= _GlowPosFactor01.w;
				half glowIntensity = input.uv.z * glow;
				finalColor = lerp(finalColor, glowColor, glowIntensity);

				// 处理雾
				float fogFactor = input.positionWSAndFogFactor.w;
				finalColor = MixFog(finalColor, fogFactor);

				half finalAlpha = baseColor.a * _AlphaMtl;
				return half4(finalColor, finalAlpha);
			}

			ENDHLSL
        }
    }
}
