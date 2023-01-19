Shader "SSS/Standard (Deferred)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset]_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		[Toggle(ENABLE_ALPHA_TEST)] ENABLE_ALPHA_TEST("Enable alpha test", Float) = 0
		 [Toggle(SUBSURFACE_ALBEDO)] SUBSURFACE_ALBEDO ("Subsurface albedo", Float) = 0
		_SubSurfaceParallax ("SubSurface Parallax", Range(-.002,0)) = -0.000363
		 [Toggle(SUBSURFACE_PARALLAX)] SUBSURFACE_PARALLAX ("Parallax", Float) = 0

        _AlbedoOpacity("Opacity", Range(0, 1)) = 1

		[NoScaleOffset]_SubsurfaceAlbedo ("Subsurface Albedo", 2D) = "white" {}
        _SubsurfaceAlbedoOpacity("Opacity", Range(0, 1)) = 1
        _SubsurfaceAlbedoSaturation("Saturation", Range(0, 1)) = 1

		_AlbedoTile("Tile", Range(1, 20)) = 1
		[NoScaleOffset]_ProfileTex ("Profile", 2D) = "white" {}
		_ProfileColor("Profile Color", Color) = (1.0,1.0,1.0)
        [NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}
        [NoScaleOffset] _OcclusionStrength("_OcclusionStrength", Range(0,1)) = 1

        _OcclusionColor("Occlusion Color", Color) = (0.0,0.0,0.0)
        _SpecColor("Specular Color", Color) = (0.2,0.2,0.2)
		[NoScaleOffset] _SpecGlossMap("Specular", 2D) = "white" {}
		[NoScaleOffset] _CavityMap("Cavity Map", 2D) = "white" {}
        _CavityStrength("Cavity", Range(0, 1)) = 1
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
        _FresnelIntensity("Fresnel", Range(0,1)) = 1
		//_SubsurfaceColor("_SubsurfaceColor", Color) =  (1,1,1,1)
		[NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Scale", Range(0,1)) = 1.0
		_BumpTile("Tile", Range(1, 20)) = 1
		_DetailNormalMapScale("Scale", Range(0,1)) = 1.0
		_DetailNormalMapTile("Tile", float) = 1.0
		[NoScaleOffset]_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
        [Toggle(ENABLE_DETAIL_NORMALMAP)] _DetailNormal("Detail normal", Float) = 0
        [Toggle(TRANSMISSION)] _Transmission ("Transmission", Float) = 0
		[NoScaleOffset]_TransmissionMap("Mask", 2D) = "white" {}
        _TransmissionColor("Color", Color) = (0.2,0.2,0.2)
        TransmissionOcc("Occlusion", Range(0,1)) = 1
        TransmissionShadows("Shadows", Range(0,1)) = 1
        TransmissionRange("Range", Range(0,5)) = 0.5
        DynamicPassTransmission ("Dynamic Pass", Range(0,5)) = 1
        BasePassTransmission ("Base Pass", Range(0,5)) = 1
		_DepthTile("Depth Tiling", Range(1, 20)) = 1
		_Depth("Depth", range(0, .1)) = 0.01
		_DepthCenter("Depth Center", Range(-.1, .1)) = -0.01
		_ParallaxMap("Depth Mask", 2D) = "white" {}
        [Toggle(ENABLE_PARALLAX)] ENABLE_PARALLAX("Enable Parallax", Float) = 0
        [Toggle(WRAPPED_LIGHTING)] WRAPPED_LIGHTING("Enable WrappedLighting", Float) = 0
		_Wrap("Range", Range(0,1)) = 0.5
		[Toggle(PUPIL_DILATION)] PUPIL_DILATION("Pupil dilation", Float) = 0
		_Dilation("Pupil Dilation", Range(0, 10)) = 0

		_ScaleMask("Dilation Mask", 2D) = "black" {}
		 [Toggle(SSS_TRANSPARENCY)] SSS_TRANSPARENCY("Enable", Float) = 0
		TransparencyDistortion("Distortion", Range(0, .1)) = 0		
		_TintTexture("Tint Texture", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1, 1, 1, 1)
		_ChromaticAberration("Chromatic Aberration", Range(0, 1)) = 0.5

        SSS_shader("", float)=1
	}
	SubShader {
		//Tags { "RenderType"="SSS"}
		Tags { "RenderType"="Opaque"}
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular fullforwardshadows 
		#pragma multi_compile _ SCENE_VIEW
		#pragma shader_feature SUBSURFACE_ALBEDO
        #include "../Resources/SSS_Common.hlsl"
		#pragma shader_feature TRANSMISSION
		#pragma shader_feature ENABLE_DETAIL_NORMALMAP
		#pragma shader_feature ENABLE_ALPHA_TEST
		#pragma shader_feature ENABLE_PARALLAX
		#pragma shader_feature PUPIL_DILATION
		#pragma shader_feature SSS_TRANSPARENCY

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		half _OcclusionFade;
		half _Cutoff;

		struct Input 
		{
			float2 uv_MainTex;
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

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			half2 uv = IN.uv_MainTex;
			
			#ifdef ENABLE_PARALLAX
			COMPUTE_PARALLAX
			#endif			

			#ifdef PUPIL_DILATION		
			COMPUTE_EYE_DILATION
			#endif

			fixed4 Albedo = tex2D(_MainTex, uv * _AlbedoTile);
			
			#ifdef ENABLE_ALPHA_TEST
			ALPHA_TEST
			#endif

            o.Normal = BumpMap(uv);
			SSS_OCCLUSION
			o.Occlusion = lerp(1.0, tex2D(_OcclusionMap, uv).r, _OcclusionStrength);

			#ifdef SCENE_VIEW
			o.Albedo.rgb = Albedo * _Color;
            #else
				#ifdef SUBSURFACE_ALBEDO
				Albedo.rgb = lerp(1.0, Albedo.rgb, _AlbedoOpacity);
				Albedo.rgb = lerp(Luminance(Albedo.rgb) * 6, Albedo.rgb, _SubsurfaceAlbedoSaturation);
				#endif
            #endif
			

            float4 Specular = float4(_SpecColor.rgb, _Glossiness) * tex2D(_SpecGlossMap, uv);

			o.Specular = Specular.rgb;
			o.Smoothness = Specular.a;
			o.Alpha = Albedo.a;
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
			
					half3 SceneColor = 0;

					UNITY_BRANCH
					if(TransparencyDistortion == 0)
					{
						if (unity_StereoEyeIndex == 0)
							SceneColor = tex2D(SSS_TransparencyTexBlurred, screenUV).rgb;
						else
							SceneColor = tex2D(SSS_TransparencyTexBlurredR, screenUV).rgb;

					}
					else
					{
						if (unity_StereoEyeIndex == 0)
						{
							half d = 1.0 - saturate(LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV).a) - LinearEyeDepth(tex2D(SSS_TransparencyTex, screenUV + o.Normal * TransparencyDistortion).a));

							SceneColor.r = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * d).r;
							SceneColor.g = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration) * d).g;
							SceneColor.b = tex2D(SSS_TransparencyTexBlurred, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration) * d).b;
						}
						else
						{
							half d = 1.0 - saturate(LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV).a) - LinearEyeDepth(tex2D(SSS_TransparencyTexR, screenUV + o.Normal * TransparencyDistortion).a));

							SceneColor.r = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * d).r;
							SceneColor.g = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 1.5, _ChromaticAberration) * d).g;
							SceneColor.b = tex2D(SSS_TransparencyTexBlurredR, screenUV + o.Normal * TransparencyDistortion * lerp(1, 2, _ChromaticAberration) * d).b;
						}
					
					}

					SceneColor *= tex2D(_TintTexture, uv).rgb * _TintColor.rgb;
					Emission = lerp(SceneColor, Emission, saturate(o.Alpha * _Color.a /*+ TransparencyAlphaTweak*/));

				#endif

            #endif

			#if defined(TRANSMISSION) && defined(SCENE_VIEW)
			BASE_TRANSMISSION_DEFERRED
            #endif

			

            o.Emission = Emission;
		}
		ENDCG
	}
	FallBack "Diffuse"
		CustomEditor "SSS_MaterialEditor"

}
