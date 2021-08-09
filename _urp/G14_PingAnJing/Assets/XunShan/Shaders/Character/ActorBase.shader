Shader "XunShan/Actor/ActorBase"
{
    Properties
    {
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_MixMap("Mix Map", 2D) = "white" {}
		[NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
		//_EnvShadowColor("Env Shadow Color", Color) = (0.667, 0.545, 0.761, 1)
		//_EnvBrightness("Env Brightness", Range(0,2)) = 1
		// _L_ANISO_ON
		[NoScaleOffset]_AnisotropicMap("Anisotropic Map", 2D) = "bump" {}
		_AnisoShiftOffset("Aniso Shift Offset", Float) = 0.0
		_AnisoShiftScale("Aniso Shift Scale", Float) = 0.5
		// _L_ROUGHNESS_RANGE_ON
		_RoughnessLow("RoughnessLow", Range(0,1)) = 0.0
		_RoughnessHigh ("RoughnessHigh", Range(0,1)) = 1.0
		// _L_SSS_ON
		_SSS_Factor("SSS Factor", Range(0,1)) = 1
		// _L_IBL_DIFF_XXXX
		[NoScaleOffset]_IrradianceMap_2D("Irradiance Texture 2D", 2D) = "black" {}
		[NoScaleOffset]_IrradianceMap_Cube("Irradiance Texture Cube", Cube) = "Cube" {}
		// _L_IBL_SPEC_XXXX
		[NoScaleOffset]_EnvironmentMap_2D("Environment Texture 2D", 2D) = "black" {}
		[NoScaleOffset]_EnvironmentMap_Cube("Environment Texture Cube", Cube) = "Cube" {}
		// _L_AO_ON
		_AO_Bias("AO Bias", Range(0,1)) = 1
		// _L_EMISSIVE_ON
		_EmissiveIntensity("Emissive Intensity", Range(0,5)) = 1

		// Blending state
		[HideInInspector] _Surface("__surface", Float) = 0.0
		[HideInInspector] _Blend("__blend", Float) = 0.0
		[HideInInspector] _AlphaClip("__clip", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
		[HideInInspector] _Cull("__cull", Float) = 2.0
		// Shader类型标识
		[HideInInspector] _ObjectType_Actor("", Int) = 0
		// Internal
		[HideInInspector] _INTR_AnisoType("", Int) = 0
		[HideInInspector] _INTR_SSSType("", Int) = 0
		[HideInInspector] _INTR_RoughRange("", Int) = 0
		[HideInInspector] _INTR_IBLDiff("", Int) = 0
		[HideInInspector] _INTR_IBLSpec("", Int) = 0
		[HideInInspector] _INTR_AO("", Int) = 0
		[HideInInspector] _INTR_EM("", Int) = 0
    }
    SubShader
    {
		Tags{"ObjectType" = "Actor" "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True" }
        LOD 100

		Pass
		{
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]
			Cull[_Cull]

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			//#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			//#pragma multi_compile _ _SHADOWS_SOFT
			//#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// -------------------------------------
			// Unity defined keywords
			//#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			//#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile_fog

			// -------------------------------------
			// 自定义 Local keywords
			#pragma multi_compile_local __ _NORMALMAP
			#pragma multi_compile_local _L_IBL_DIFF_GLOBAL_URP _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
			#pragma multi_compile_local _L_IBL_SPEC_GLOBAL_URP _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP
			#pragma multi_compile_local __ _L_AO_ON
			#pragma multi_compile_local __ _L_ROUGHNESS_RANGE_ON
			#pragma multi_compile_local __ _L_ANISO_ON
			#pragma multi_compile_local __ _L_SSS_ON
			#pragma multi_compile_local __ _L_EMISSIVE_ON
			// -------------------------------------
			// 自定义 Global keywords
			#pragma multi_compile __ _G_DEBUG_ACTOR_ON


			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#include "ActorCore.hlsl"
			ENDHLSL
		}

		// Used for rendering shadowmaps
		//UsePass "Universal Render Pipeline/Lit/ShadowCaster"

		// Used for depth prepass
		// If shadows cascade are enabled we need to perform a depth prepass. 
		// We also need to use a depth prepass in some cases camera require depth texture
		// (e.g, MSAA is enabled and we can't resolve with Texture2DMS
		//UsePass "Universal Render Pipeline/Lit/DepthOnly"

		// Used for Baking GI. This pass is stripped from build.
		//UsePass "Universal Render Pipeline/Lit/Meta"

		
    }

	//FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "ShaderEditor.ActorShaderGUI"
}
