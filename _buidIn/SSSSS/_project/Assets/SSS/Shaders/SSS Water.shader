Shader "SSS/Water" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_FogColor ("Color", Color) = (1,1,1,1)
		_Density("Density", Range( 0 , 20)) = 1
		
		//[NoScaleOffset]_MainTex ("Albedo (RGB)", 2D) = "white" {}

		//_AlbedoTile("Tile", Range(1, 20)) = 1
		[hideininspector][NoScaleOffset]_ProfileTex ("Profile", 2D) = "white" {}
		_ProfileColor("Profile Color", Color) = (1.0,1.0,1.0)
      
        _SpecColor("Specular Color", Color) = (0.2,0.2,0.2)
		//[NoScaleOffset] _SpecGlossMap("Specular", 2D) = "white" {}
		//[NoScaleOffset] _CavityMap("Cavity Map", 2D) = "white" {}
        //_CavityStrength("Cavity", Range(0, 1)) = 1
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
        //_FresnelIntensity("Fresnel", Range(0,1)) = 1
		//_SubsurfaceColor("_SubsurfaceColor", Color) =  (1,1,1,1)
		[Toggle(DEBUG_NORMALS)] DEBUG_NORMALS("Debug", Float) = 0
		[NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}
        _OcclusionColor("Occlusion Color", Color) = (1.0,1.0,1.0)
		[Normal]_FlowMap("Flow Map", 2D) = "bump" {}
		_FlowTile("Tiling", Range(0, 5)) = 1
		_FlowSpeed("Flow Speed", Range(0, 50)) = .5
		_FlowIntensity("Intensity", Range(0, 5)) = .5
		//_Pan("Pan",  Color) = (0.2,0.0,0.0)
		_PanU("Pan U", Range(-1, 1)) = 0
		_PanV("Pan V", Range(-1, 1)) = 0

		/*[NoScaleOffset]*/_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Scale", Range(0,1)) = 1.0
		_BumpTile("Tile", Range(0, 5)) = 1
		//_AnimationSpeed("Animation Speed", Range(0, 1)) = .5

		//_ScaleMask("Dilation Mask", 2D) = "black" {}
		 [hideininspector][Toggle(SSS_TRANSPARENCY)] SSS_TRANSPARENCY("SSS_TRANSPARENCY", Float) = 1
		TransparencyDistortion("Distortion", Range(0, 5)) = 0		
		//_TintTexture("Tint Texture", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1, 1, 1, 1)
		_TintFade("Tint Fade", Range(0, 1)) = .01

		_ChromaticAberration("Chromatic Aberration", Range(0, 1)) = 0.5
		 //[Toggle(SSS_Water)] SSS_Water("SSS_Water", Float) = 0
		_FadeDistance("Fade Distance", Range(0, 1)) = .1
		_FadeContrast("Fade contrast", Range(1, 20)) = 1
        [hideininspector]SSS_shader("", float)=1
        [hideininspector]IsWater("", float)=1
	}
	SubShader {

		Tags { "RenderType"="Opaque"}
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular fullforwardshadows 
		#pragma multi_compile _ SCENE_VIEW
		//#pragma shader_feature SUBSURFACE_ALBEDO
        #include "../../SSS/Resources/SSS_Common.hlsl"
		//#pragma shader_feature TRANSMISSION
		//#pragma shader_feature ENABLE_DETAIL_NORMALMAP
		//#pragma shader_feature ENABLE_ALPHA_TEST
		//#pragma shader_feature ENABLE_PARALLAX
		#pragma shader_feature DEBUG_NORMALS
		#define SSS_TRANSPARENCY 1
		//#define DEBUG_NORMALS 1
		//#pragma shader_feature SSS_Water

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		
		sampler2D LightingTex;
		sampler2D LightingTexR;
		sampler2D _FlowMap;
		half _FadeDistance;
		half _FadeContrast;
		//half _AnimationSpeed;
		half _FlowSpeed;
		half _FlowIntensity;
		half _FlowTile;
		#define blue float3(0, 0, 1)
		half4 _Pan;
		half _PanU;
		half _PanV;
		half _TintFade;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_FlowMap;
			float2 uv_BumpMap;
			float4 screenPos;
			float3 viewDir;
			INTERNAL_DATA
		};

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) 
		{
			half2 uv = IN.uv_MainTex;

			fixed4 Albedo = 1;//tex2D(_MainTex, uv/* * _AlbedoTile*/);

			//the easy way
			/*
            o.Normal = normalize(
			BumpMap(uv + _Time.x * _AnimationSpeed) + 
			BumpMap(uv * 0.8 - _Time.x * _AnimationSpeed) + 
			BumpMap(uv * 0.5 + _Time.x * _AnimationSpeed * -0.5)
			);*/
			float3 flowDir = UnpackNormal(tex2D(_FlowMap, IN.uv_FlowMap * _FlowTile));
			flowDir = lerp(0, flowDir, _FlowIntensity);
			half FlowIntensity = dot(flowDir.xyz - blue, float3( 0.299, 0.587, 0.114 ));
			float phase0 = frac(_Time[0] * _FlowSpeed + 0.5f);
			float phase1 = frac(_Time[0] * _FlowSpeed);
			float flowLerp0 = abs((0.5f - phase0) * 2);
			float flowLerp1 = abs((0.5f - phase1) * 2);
			float4 BumpUV = IN.uv_BumpMap.xyxy * _BumpTile;
			_Pan.xy = float2(_PanU, _PanV);
			BumpUV.xy += flowDir.xy * phase0 + _Pan.xy * _Time[0] * 1.5;
			BumpUV.zw += flowDir.xy * phase1 + _Pan.xy * _Time[0];
			
			float3 Normal_A = normalize(UnpackNormal(tex2D(_BumpMap, BumpUV.xy)));		
			Normal_A = lerp(blue, Normal_A, _BumpScale * FlowIntensity);

			float3 Normal_B = normalize(UnpackNormal(tex2D(_BumpMap, BumpUV.zw)));
			Normal_B = lerp(blue, Normal_B, _BumpScale * FlowIntensity);

            o.Normal = lerp(Normal_A, Normal_B, flowLerp0);

			o.Occlusion = 1;

			#ifdef SCENE_VIEW
			o.Albedo.rgb = Albedo * _Color;           
            #endif
			

            float4 Specular = float4(_SpecColor.rgb, _Glossiness)/* * tex2D(_SpecGlossMap, uv)*/;

			o.Specular = Specular.rgb;
			o.Smoothness = Specular.a;
			float3 Emission = 0;
			//Convolved buffer
            #if !defined(SCENE_VIEW)
				half3 LightingPass = 0;
				float4 coords = 0;
				coords = UNITY_PROJ_COORD(IN.screenPos);
				coords.w += .0001;
				float2 screenUV = coords.xy / coords.w;
            
				#ifdef UNITY_SINGLE_PASS_STEREO
					float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
					screenUV = (screenUV - scaleOffset.zw) / scaleOffset.xy;
				#endif
				
				if (unity_StereoEyeIndex == 0)
					LightingPass = tex2D(LightingTexBlurred, screenUV).rgb;
				else
					LightingPass = tex2D(LightingTexBlurredR, screenUV).rgb;

				Emission += Albedo * LightingPass;

				#ifdef SSS_TRANSPARENCY
				
					half3 SceneColor = 0, dR=0, dG=0, dB=0;
					half DepthDifference = 0;
					half EdgeBlend = 0;
					half DepthDifferenceDistorted = 0;
					half LightingPassDepth, TransparencyDepth;
					
					//Thickness
					if (unity_StereoEyeIndex == 0)
						{
							LightingPassDepth = LinearEyeDepth(tex2D(LightingTex, screenUV).a);
							TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV).a);
						}
						else
						{
							LightingPassDepth = LinearEyeDepth(tex2D(LightingTexR, screenUV).a);
							TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV).a);
						}
		
						DepthDifference = TransparencyDepth - LightingPassDepth;
						DepthDifference = 1.0 - exp2(-DepthDifference);
						EdgeBlend = pow(saturate(DepthDifference / _FadeDistance), _FadeContrast);

					UNITY_BRANCH
					if(TransparencyDistortion == 0)
					{
						if (unity_StereoEyeIndex == 0)
							SceneColor = tex2D(SSS_TransparencyTexBlurred, screenUV).rgb;
						else
							SceneColor = tex2D(SSS_TransparencyTexBlurredR, screenUV).rgb;

						_TintColor.rgb = lerp(1, _TintColor.rgb, saturate(DepthDifference / _TintFade));

					}
					else
					{
						//Distorted Thickness
						TransparencyDistortion *= DepthDifference;
						TransparencyDistortion *= 1.0 / LightingPassDepth;

						if (unity_StereoEyeIndex == 0)
						{
														
							dR = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV + o.Normal * TransparencyDistortion).a));
							dG = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration)).a));
							dB = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration)).a));

							SceneColor.r = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * dR).r;
							SceneColor.g = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration) * dG).g;
							SceneColor.b = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration) * dB).b;

							LightingPassDepth = LinearEyeDepth(tex2D(LightingTex, screenUV + o.Normal * TransparencyDistortion * dR).a);
							TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV + o.Normal * TransparencyDistortion * dR).a);
						}
						else
						{
							dR = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV + o.Normal * TransparencyDistortion).a));
							dG = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration)).a));
							dB = 1.0 - saturate(TransparencyDepth - LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration)).a));

							SceneColor.r = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * dR).r;
							SceneColor.g = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration) * dG).g;
							SceneColor.b = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration) * dB).b;

							LightingPassDepth = LinearEyeDepth(tex2D(LightingTexR, screenUV + o.Normal * TransparencyDistortion * dR).a);
							TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV + o.Normal * TransparencyDistortion * dR).a);
						}
						DepthDifferenceDistorted = TransparencyDepth - LightingPassDepth;
						DepthDifferenceDistorted = 1.0 - exp2(-DepthDifferenceDistorted);
						_TintColor.rgb = lerp(1, _TintColor.rgb, saturate(DepthDifferenceDistorted / _TintFade));
					
					}

					//SceneColor *= tex2D(_TintTexture, uv).rgb * _TintColor.rgb;
					
					SceneColor *= lerp(1, /*tex2D(_TintTexture, uv).rgb **/ _TintColor.rgb, EdgeBlend);
					o.Alpha = Albedo.a * EdgeBlend;

					#ifndef DEBUG_NORMALS
						Emission = lerp(SceneColor, Emission, saturate(o.Alpha * _Color.a));
					#else
						Emission = saturate(lerp(half3(0.5, 0.5, 0.5), o.Normal * 0.5 + 0.5, 100)) * half3(1, 1, 0);
						o.Albedo = 0;
						o.Specular = 0;
						o.Smoothness = 0;
					#endif

				#endif

            #endif


            o.Emission = Emission;
		}
		ENDCG
	}
	FallBack "Diffuse"
	CustomEditor "SSS_Water_MaterialEditor"

}
