Shader "Hidden/PostProcessing/PAJBloom"
{
    HLSLINCLUDE
        
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Sampling.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        TEXTURE2D_SAMPLER2D(_BloomTex, sampler_BloomTex);

		float _Bloom_Intensity;
		float _Blur_Size;
		float _Bloom_Up_Scale;

		float4 _MainTex_TexelSize;
		float4 _BloomTex_TexelSize;


		struct VaryingsPrefilter
		{
			float4 vertex : SV_POSITION;
			float4 texcoord0 : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float2 texcoord2 : TEXCOORD2;

			float2 texcoordStereo : TEXCOORD3;
#if STEREO_INSTANCING_ENABLED
			uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
#endif
		};

		struct VaryingsDownsample
		{
			float4 vertex : SV_POSITION;
			float4 texcoord0 : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			float4 texcoord3 : TEXCOORD3;

			float2 texcoordStereo : TEXCOORD4;
#if STEREO_INSTANCING_ENABLED
			uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
#endif
		};

		struct VaryingsUpsample
		{
			float4 vertex : SV_POSITION;
			float4 texcoord0 : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			float4 texcoord3 : TEXCOORD3;

			float2 texcoordStereo : TEXCOORD4;
#if STEREO_INSTANCING_ENABLED
			uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
#endif
		};

        // ----------------------------------------------------------------------------------------
        // Prefilter

		VaryingsPrefilter VertPrefilter(AttributesDefault v)
		{
			VaryingsPrefilter o;
			o.vertex = float4(v.vertex.xy, 0.0, 1.0);
			float2 uv = TransformTriangleVertexToUV(v.vertex.xy);
#if UNITY_UV_STARTS_AT_TOP
			uv = uv * float2(1.0, -1.0) + float2(0.0, 1.0);
#endif
			o.texcoordStereo = TransformStereoScreenSpaceTex(uv, 1.0);

			float2 texelSize = UnityStereoAdjustedTexelSize(_MainTex_TexelSize).xy;
			o.texcoord0 = uv.xyxy + (texelSize.xyxy * float4(0.0, 0.5, 0.5, 0.0));
			o.texcoord1 = uv.xyxy + (texelSize.xyxy * float4(0.0, -0.5, -0.5, 0.0));
			o.texcoord2 = uv.xy;

			return o;
		}
 
        half4 FragPrefilter(VaryingsPrefilter i) : SV_Target
        {
			half4 orgColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.xy));
			half alpha = orgColor.a;
			alpha += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.xy)).a;
			alpha += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.zw)).a;
			alpha += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.xy)).a;
			alpha += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.zw)).a;
        
			alpha = alpha / 5.0;
			// alpha 0-1 remap 为 0-0.5 值域(曲线)
			alpha = alpha / (1 + alpha);

			half3 color = (orgColor.rgb * orgColor.rgb) * alpha;
			// 1.5转为线性空间
			color *= 1.5 * 1.5;
			// x / (1 + x) * 1.5 * 1.5 
			// x = 1  y = 1.25

			color *= _Bloom_Intensity;
			return half4(color, 1.0);
		}

			


        // ----------------------------------------------------------------------------------------
        // Downsample

		float2 GetBlurOffset(int index)
		{
			float rai = (TWO_PI / 7.0) * (index + 0.2857143);
			return float2(sin(rai), cos(rai));
		}

		VaryingsDownsample VertDownsample(AttributesDefault v)
		{
			VaryingsDownsample o;
			o.vertex = float4(v.vertex.xy, 0.0, 1.0);
			float2 uv = TransformTriangleVertexToUV(v.vertex.xy);
#if UNITY_UV_STARTS_AT_TOP
			uv = uv * float2(1.0, -1.0) + float2(0.0, 1.0);
#endif
			o.texcoordStereo = TransformStereoScreenSpaceTex(uv, 1.0);

			float2 texelSize = UnityStereoAdjustedTexelSize(_MainTex_TexelSize).xy;
			float2 halfTexelSize = texelSize * 0.5;
			float2 blurSize = _Blur_Size * halfTexelSize;

			o.texcoord0 = uv.xyxy + (float4(0.0.xx, GetBlurOffset(0)) * blurSize.xyxy);
			o.texcoord1 = uv.xyxy + (float4(GetBlurOffset(1), GetBlurOffset(2)) * blurSize.xyxy);
			o.texcoord2 = uv.xyxy + (float4(GetBlurOffset(3), GetBlurOffset(4)) * blurSize.xyxy);
			o.texcoord3 = uv.xyxy + (float4(GetBlurOffset(5), GetBlurOffset(6)) * blurSize.xyxy);

			return o;
		}

        half4 FragDownsample(VaryingsDownsample i) : SV_Target
        {
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.zw));
			color *= 0.125;
			return color;
        }

        // ----------------------------------------------------------------------------------------
        // Upsample & combine

		VaryingsUpsample VertUpsample(AttributesDefault v)
		{
			VaryingsUpsample o;
			o.vertex = float4(v.vertex.xy, 0.0, 1.0);
			float2 uv = TransformTriangleVertexToUV(v.vertex.xy);
#if UNITY_UV_STARTS_AT_TOP
			uv = uv * float2(1.0, -1.0) + float2(0.0, 1.0);
#endif
			o.texcoordStereo = TransformStereoScreenSpaceTex(uv, 1.0);

			// 以大图为基准
			float2 texelSize = UnityStereoAdjustedTexelSize(_BloomTex_TexelSize).xy;
			float2 halfTexelSize = texelSize * 0.5;
			float2 blurSize = _Bloom_Up_Scale * halfTexelSize;

			o.texcoord0 = uv.xyxy + (float4(0.0.xx, GetBlurOffset(0)) * blurSize.xyxy);
			o.texcoord1 = uv.xyxy + (float4(GetBlurOffset(1), GetBlurOffset(2)) * blurSize.xyxy);
			o.texcoord2 = uv.xyxy + (float4(GetBlurOffset(3), GetBlurOffset(4)) * blurSize.xyxy);
			o.texcoord3 = uv.xyxy + (float4(GetBlurOffset(5), GetBlurOffset(6)) * blurSize.xyxy);

			return o;
		}

		half4 FragUpsample(VaryingsUpsample i) : SV_Target
		{
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.zw));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.xy));
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.zw));
			color *= 0.125;

			half4 color2 = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.xy));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord0.zw));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.xy));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord1.zw));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.xy));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord2.zw));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.xy));
			color2 += SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, UnityStereoTransformScreenSpaceTex(i.texcoord3.zw));
			color2 *= 0.125;
			return color + color2;
		}

		// ----------------------------------------------------------------------------------------
		// Last

		float4 FragLast(VaryingsDefault i) : SV_Target
		{
			float4 main_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoordStereo);
			float4 bloom_color = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, i.texcoordStereo);

			// 这里平安京不知道是不是有Bug，应该是先*1.5后再平方的
			main_color.rgb = main_color.rgb * main_color.rgb * 1.5;
			bloom_color.rgb = bloom_color.rgb * bloom_color.rgb * 1.5;

			half3 color = main_color.rgb + bloom_color.rgb;

			// 色调映射(HDR到LDR)可以和gamma组合在一起
			// Tone mapper
			// https://docs.unrealengine.com/udk/Three/ColorGrading.html
			// GammaColor = LinearColor / (LinearColor + 0.187) * 1.035;
			color = (color / (color + 0.187)) * 1.035;

			return float4(color,1.0);
		}
    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0: Prefilter
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertPrefilter
                #pragma fragment FragPrefilter

            ENDHLSL
        }
        // 1: Downsample 
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDownsample
                #pragma fragment FragDownsample

            ENDHLSL
        }
        // 2: Upsample
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertUpsample
                #pragma fragment FragUpsample

            ENDHLSL
        }

		// 3 - Fullscreen triangle copy
		Pass
		{
			HLSLPROGRAM

				#pragma vertex VertDefault
				#pragma fragment FragLast

			ENDHLSL
		}
    }
}
