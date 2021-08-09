Shader "XunShan/VFX/Additive" {
Properties {
    [HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	[Toggle(_WithoutAlpha)] _WithoutAlpha("是否RBG贴图",Float) = 0
	_MainTex ("Particle Texture", 2D) = "white" {}
    [Toggle] _UseUvTrail("======UV条带======", Float) = 0
    [Toggle] _UseUvAni("======UV滚动======", Float) = 0
    _SpeedU("SpeedU", Float) = 0
    _SpeedV("SpeedV", Float) = 0
    [Toggle] _UseUvDistortion("======UV扰乱======", Float) = 0
    _UVNoiseTex("NoiseTex", 2D) = "bump" {}
    _Distortion ("Distortion", Float) = 0
    _NoiseScroll ("NoiseScroll", Vector) = (0,0,1,1)
    [Toggle] _UseMask("======Mask======", Float) = 0
    _Mask("Mask ( R Channel )", 2D) = "white" {}
    [Toggle] _UseDissolve("======溶解======", Float) = 0
    _DissolveTex ("DissolveTex( R Channel )", 2D) = "white" {}
    _Dissolve ("Dissolve", Range(0, 1.01)) = 0
    _DissolveWidth ("DissolveWidth", Range(0, 1)) = 0
	[Toggle] _UseDissolveColor("使用溶解区域颜色", Float) = 0
	_DissolveStartColor("Dissolve Start Color", Color) = (1, 1, 0, 1)
	_DissolveEndColor("Dissolve End Color", Color) = (1, 0, 0, 1)
	_DissolveCutAlphaWidth("Dissolve Cut Alpha", Range(0, 1)) = 0
    [Toggle] _UseUIMaskClip("======UI裁切======", Float) = 0
    _ClipRect ("Clip Rect", Vector) = (-32767, -32767, 32767, 32767)

	_BloomFactor("Bloom强度", Range(0, 10)) = 0.0
	_BloomEnhance("RGB贴图 Bloom增强",Range(1,2)) = 1
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"  "RenderPipeline" = "UniversalPipeline"}
    Blend One One, SrcAlpha OneMinusSrcAlpha
	
    Cull Off Lighting Off ZWrite Off

    SubShader 
	{
        Pass 
		{
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			#pragma vertex vert
			#pragma fragment frag

            #pragma shader_feature _USEMASK_ON
            #pragma shader_feature _USEUVTRAIL_ON
            #pragma shader_feature _USEUVANI_ON
            #pragma shader_feature _USEUVDISTORTION_ON
			#pragma shader_feature _USEDISSOLVE_ON
			#pragma shader_feature _USEDISSOLVECOLOR_ON
            #pragma shader_feature _USEUIMASKCLIP_ON
			#pragma shader_feature _WithoutAlpha

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			TEXTURE2D(_Mask);
			SAMPLER(sampler_Mask);

			TEXTURE2D(_UVNoiseTex);
			SAMPLER(sampler_UVNoiseTex);

			TEXTURE2D(_DissolveTex);
			SAMPLER(sampler_DissolveTex);

			CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
			half4 _TintColor;
			half _BloomFactor;

			#if _WithoutAlpha
			half _BloomEnhance;
			#endif

            //#if _USEMASK_ON
			float4 _Mask_ST;
            //#endif

            //#if _USEUVANI_ON
			half _SpeedU;
			half _SpeedV;
            //#endif

            //#if _USEUVDISTORTION_ON
			float4 _UVNoiseTex_ST;
			half _Distortion;
			half4 _NoiseScroll;
            //#endif

            //#if _USEDISSOLVE_ON || _USEDISSOLVECOLOR_ON
			float4 _DissolveTex_ST;
			half _Dissolve;
			half _DissolveWidth;
			half3 _DissolveStartColor;
			half3 _DissolveEndColor;
			half _DissolveCutAlphaWidth;
            //#endif

            //#if _USEUIMASKCLIP_ON
			half4 _ClipRect;
            //#endif

			CBUFFER_END

			struct AttributesParticle
			{
				half4 color : COLOR;
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                half2 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct VaryingsParticle
			{
                float4 clipPos : SV_POSITION;
				half4 color : COLOR;
                float4 texcoord : TEXCOORD0;
                half2 texcoord1 : TEXCOORD1;

                #if _USEMASK_ON
				half2 texcoordMask : TEXCOORD2;
                #endif

                #if _USEUVDISTORTION_ON
				half2 texcoordNoise : TEXCOORD3;
                #endif

                #if _USEDISSOLVE_ON
				half2 texcoordDissolve: TEXCOORD4;
                #endif

                #if _USEUIMASKCLIP_ON
				half4 positionWS : TEXCOORD5;
                #endif

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };


#ifdef UNITY_COLORSPACE_GAMMA
#define unity_ColorSpaceLuminance half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
#else 
#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
#endif
			inline half Luminance(half3 rgb)
			{
				return dot(rgb, unity_ColorSpaceLuminance.rgb);
			}

			VaryingsParticle vert(AttributesParticle input)
            {
				VaryingsParticle output = (VaryingsParticle)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);

                #if _USEUIMASKCLIP_ON
                o.positionWS = vertexInput.positionWS;
                #endif

				output.color = input.color * _TintColor;
				output.texcoord.xy = TRANSFORM_TEX(input.texcoord.xy, _MainTex);
				output.texcoord.zw = input.texcoord.zw;
				output.texcoord1 = input.texcoord1;

                #if _USEMASK_ON
				output.texcoordMask = TRANSFORM_TEX(input.texcoord, _Mask);
                #endif

                #if _USEUVDISTORTION_ON
				output.texcoordNoise = TRANSFORM_TEX(input.texcoord, _UVNoiseTex);
                #endif

                #if _USEDISSOLVE_ON
				output.texcoordDissolve = TRANSFORM_TEX(input.texcoord, _DissolveTex);
                #endif

				output.clipPos = vertexInput.positionCS;
                return output;
            }


			half4 frag(VaryingsParticle input) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if _USEUVTRAIL_ON
					input.texcoord.xy = saturate(input.texcoord.xy + input.texcoord1);
                #else
                    #if _USEUVANI_ON
						input.texcoord.xy += _Time.y * float2(_SpeedU, _SpeedV);
                    #endif
                #endif

                #if _USEUVDISTORTION_ON
					input.texcoordNoise += float2(_Time.y * _NoiseScroll.xy);
					input.texcoord.xy += UnpackNormal(SAMPLE_TEXTURE2D(_UVNoiseTex, sampler_UVNoiseTex, input.texcoordNoise)).xy * _Distortion * _NoiseScroll.zw;
                #endif

                half4 col = 2.0f * input.color * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoord.xy);				//Opaque贴图A为1	

#if _WithoutAlpha
				col.a = Luminance(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoord.xy).rgb) * _BloomEnhance;
#endif

                col.a = saturate(col.a);

                #if _USEMASK_ON
                    col.a = saturate(col.a * SAMPLE_TEXTURE2D(_Mask, sampler_Mask, input.texcoordMask).r);
                #endif

                #if _USEDISSOLVE_ON
					half DissolveWithParticle = (_Dissolve * (1 - input.texcoord.z) * (1 + _DissolveWidth) - _DissolveWidth);
					half dissolveAlpha = saturate(smoothstep( DissolveWithParticle, (DissolveWithParticle + _DissolveWidth), SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, input.texcoordDissolve).r));
					#if _USEDISSOLVECOLOR_ON
					half3 dissColor = lerp(_DissolveStartColor, _DissolveEndColor, dissolveAlpha);
					col.rgb = lerp(dissColor.rgb, col.rgb, smoothstep(0.9, 1.0, dissolveAlpha));
					#endif

					#if _USEDISSOLVECOLOR_ON
					dissolveAlpha = Smootherstep(0, 1 - _DissolveCutAlphaWidth, dissolveAlpha);
					#endif
					col.a *= dissolveAlpha;
                #endif

                #if _USEUIMASKCLIP_ON
                    col.a *= UnityGet2DClipping(input.positionWS.xy, _ClipRect);
                #endif

#if _WithoutAlpha
				col.rgb = col.rgb * 1;
#else
					// 要预乘
				col.rgb = col.rgb * col.a;				//SrcColor * a + DstColor * One
#endif	
														
														// 写Bloom
				col.a = col.a * _BloomFactor;
                return col;
            }
			ENDHLSL
        }
    }
}
}