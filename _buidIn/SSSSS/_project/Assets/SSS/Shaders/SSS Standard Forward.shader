Shader "SSS/Standard (Forward)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset]_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[Toggle(ENABLE_ALPHA_TEST)] ENABLE_ALPHA_TEST("Enable alpha test", Float) = 0
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
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
		DynamicPassTransmission("Dynamic Pass", Range(0,5)) = 1
		BasePassTransmission("Base Pass", Range(0,5)) = 1
		_Depth("Depth", range(0, .1)) = 0.01
		_DepthCenter("Depth Center", Range(-.1, .1)) = -0.01
		_DepthTile("Depth Tiling", Range(1, 20)) = 1
		_ParallaxMap("Depth Map", 2D) = "white" {}
        [Toggle(ENABLE_PARALLAX)] ENABLE_PARALLAX("Enable Parallax", Float) = 0
        [Toggle(WRAPPED_LIGHTING)] WRAPPED_LIGHTING("Wrapped Lighting", Float) = 0
		_Wrap("Range", Range(0,1)) = 0.5
        [Toggle(PUPIL_DILATION)] PUPIL_DILATION("Pupil dilation", Float) = 0
		_Dilation("Pupil Dilation", Range(0, 10)) = 0

		_ScaleMask("Dilation Mask", 2D) = "black" {}
		
        [Toggle(SSS_TRANSPARENCY)] SSS_TRANSPARENCY("Enable", Float) = 0
		TransparencyDistortion("Distortion", Range(0, .1)) = 0		
		_TintTexture("Tint Texture", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1, 1, 1, 1)
		_ChromaticAberration("Chromatic Aberration", Range(0, 1)) = 0.5
		SSS_shader("", float) = 1
	}
	SubShader{
			
		//Tags { "RenderType" = "SSS" }
	Tags { "RenderType" = "Opaque" }
	LOD 200
	
	CGPROGRAM
	// Physically based Standard lighting model, and enable shadows on all light types
	//alphatest:_Cutoff
	#pragma surface surf SSS_Basic nofog addshadow nometa fullforwardshadows nodynlightmap nodirlightmap  
	#pragma multi_compile _ SCENE_VIEW
	#pragma shader_feature SUBSURFACE_ALBEDO

	//#pragma multi_compile __ STEREO_RENDER
	// Use shader model 3.0 target, to get nicer looking lighting
	#pragma target 3.0
	#include "../Resources/SSS_Common.hlsl"
	#pragma shader_feature TRANSMISSION
	#pragma shader_feature ENABLE_DETAIL_NORMALMAP
	#pragma shader_feature ENABLE_PARALLAX
	#pragma shader_feature WRAPPED_LIGHTING
	#pragma shader_feature PUPIL_DILATION
	#pragma shader_feature SSS_TRANSPARENCY
	//#pragma multi_compile _ SSS_TRANSPARENCY_MATERIAL
	#pragma shader_feature ENABLE_ALPHA_TEST

	half _Cutoff;

	struct Input
	{
		float2 uv_MainTex;
		float4 screenPos;
		float3 worldPos;
		float3 viewDir;
		float3 worldRefl;
		float3 worldNormal;
		INTERNAL_DATA
	};

	struct DataStructure
	{
		fixed3 Albedo;  // diffuse color
		fixed3 Normal;  // tangent space normal, if written
		fixed3 Emission;
		fixed Alpha;
		fixed3 Occlusion;
		fixed Glossiness;
		fixed4 Specular;
		//fixed3 Fresnel;
		fixed3 Transmission;
		fixed Cavity;
	};

	//Specular only
	half4 LightingSSS_Basic(DataStructure s, half3 lightDir, half3 viewDir, half atten)
	{
		#if defined (__INTELLISENSE__)
		#define SCENE_VIEW
		#define TRANSMISSION
		#define UNITY_SINGLE_PASS_STEREO
		#endif

		float3 N = s.Normal;
		float3 L = lightDir;
		//float3 Lr = Snell(L, N, 1.0 / refractiveIndex);
		float3 E = normalize(viewDir);
		float3 h = (E + L);
		float3 H = Unity_SafeNormalize(h);
		half NdotL = max(0, dot(N, lightDir));
		
		float VdotH = saturate(dot(E, H));
		float NdotH = saturate(dot(N, H));
		float NdotV = saturate(dot(N, E));
		half3 Light = atten * _LightColor0.rgb;

		float perceptualRoughness = SmoothnessToPerceptualRoughness(s.Specular.a);
		float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
		roughness = max(roughness, 0.002);
		half D = GGXTerm(NdotH, roughness);
		half3 F = FresnelTerm(s.Specular.rgb * s.Cavity, saturate(dot(L, h)));
		half V = SmithJointGGXVisibilityTerm(NdotL, NdotV, roughness);
		half3 Highlight = V * D * F * NdotL;
		// To provide true Lambert lighting, we need to be able to kill specular completely.
		Highlight *= any(s.Specular.rgb) ? 1.0 : 0.0;
		half4 FinalLighting = 0;
		half3 Diffuse = DiffuseLightingModel(NdotL) * s.Albedo.rgb * Light;
		FinalLighting.rgb = Highlight;
		FinalLighting.rgb *= s.Occlusion.r;
		FinalLighting.rgb *= Light * UNITY_PI;
		//FinalLighting.rgb += pow(saturate(dot(N, -Lr)), 1) * s.Albedo * _LightColor0.rgb * _IrisCaustics;
		#if defined(SCENE_VIEW)
		//Light stuff
			#ifdef TRANSMISSION
			Diffuse += ADDITIVE_PASS_TRANSMISSION_SCENE
			#endif
		//Diffuse *= s.Albedo.rgb;

			return float4(Diffuse + FinalLighting.rgb, 1);
		#else	
			return float4(FinalLighting.rgb, 1);
		#endif
    }

   void surf(Input IN, inout DataStructure o)
	{
		#if defined (__INTELLISENSE__)
		#define TRANSMISSION
		#endif

		half2 uv = IN.uv_MainTex;

		#ifdef ENABLE_PARALLAX
		half d = tex2D(_ParallaxMap, IN.uv_MainTex).r;
		//uv = lerp(SurfaceParallaxMap(normalize(IN.viewDir), uv), uv, d);
		COMPUTE_PARALLAX
		#endif

		#ifdef PUPIL_DILATION	
		COMPUTE_EYE_DILATION
		#endif

		float3 Normal = BumpMap(uv);
		o.Normal = Normal;

		SSS_OCCLUSION

		float4 Albedo = tex2D(_MainTex, uv * _AlbedoTile);

		#ifdef ENABLE_ALPHA_TEST
		ALPHA_TEST
		#endif

		#ifdef SCENE_VIEW
		o.Albedo = Albedo.rgb * o.Occlusion.rgb * _Color.rgb;
		#else

		o.Albedo = 0;
		#endif

		float4 Specular = float4(_SpecColor.rgb, _Glossiness) * tex2D(_SpecGlossMap, uv);

		o.Alpha = Albedo.a;
		o.Specular = Specular;
		float3 V = (IN.viewDir);
		half NdotV = max(0, dot(Normal, V));
		float3 R = WorldReflectionVector(IN, Normal);
		//float3 R = IN.worldRefl;

		half Cavity = lerp(1.0, tex2D(_CavityMap, uv).r, _CavityStrength);
		o.Cavity = Cavity;


		//half3 F = FresnelTerm(Specular.rgb * Cavity, NdotV);
		half oneMinusReflectivity = 1 - SpecularStrength(Specular.rgb);
		half grazingTerm = saturate(Specular.a + (1 - oneMinusReflectivity));
		//half3 F = FresnelLerpFast (Specular.rgb * Cavity, grazingTerm, NdotV);
		//F = lerp(Specular.rgb * Cavity, F, _FresnelIntensity);
		//o.Fresnel = F;
		float perceptualRoughness = SmoothnessToPerceptualRoughness(Specular.a);
		float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
		// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
		half surfaceReduction;
		#ifdef UNITY_COLORSPACE_GAMMA
			surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
		#else
			surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
		#endif
		half SpecularOcclusion = Jimenez_SpecularOcclusion(NdotV, Occlusion.r);
		float3 EnvironmentReflections = /*_Exposure **/ Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),
		unity_SpecCube0_HDR, R, perceptualRoughness) * SpecularOcclusion * FresnelLerp(Specular.rgb * Cavity, grazingTerm, lerp(1.0, NdotV, _FresnelIntensity))
		* surfaceReduction;// *F;
		float3 Emission = 0;
		//Convolved buffer
		#if !defined(SCENE_VIEW)
		{
			#ifdef SUBSURFACE_ALBEDO
			Albedo.rgb = lerp(1.0, Albedo.rgb, _AlbedoOpacity);
			Albedo.rgb = lerp(Luminance(Albedo.rgb) * 6, Albedo.rgb, _SubsurfaceAlbedoSaturation);
			#endif
			half3 LightingPass = 0;
			float4 coords = 0;

			coords = UNITY_PROJ_COORD(IN.screenPos);
			coords.w += 1e-9f;
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
				{	if (unity_StereoEyeIndex == 0)
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

			Emission += EnvironmentReflections;
		}
		#endif

		#if defined(TRANSMISSION) && defined(SCENE_VIEW)
		BASE_TRANSMISSION_SCENE

		#endif

		

		o.Emission = Emission;
		//o.Emission = ShadeSH9(float4(WorldNormalVector (IN, -o.Normal), 1.0));


		   }
		   ENDCG
	   }
		
	   Fallback "Legacy Shaders/Diffuse"
	CustomEditor "SSS_MaterialEditor"
}
