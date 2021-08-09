Shader "JZPAJ/Character_AO_SSS_Cartoon"
{
    Properties
    {
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_MixMap("Mix (R:金属度 G:混合(SSS+各向异性) B:粗糙度)", 2D) = "white" {}
		[NoScaleOffset]_NormalMap("混合Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_EnvTex("Env Texture", 2D) = "black" {}

		_CartoonFactor("_CartoonFactor(Vector4)", Vector) = (0.3, 0, 0, 0)

		_SSS_Factor("_SSS_Factor", Float) = 1.0

		_AO_Slider("_AO_Slider", Float) = 1.0

		_Min_GGX_Roughness("_Min_GGX_Roughness", Range(0,1)) = 0.04
		_Max_GGX_Roughness("_Max_GGX_Roughness", Range(0,1)) = 1.0
		_Metal_Multi("_Metal_Multi", Float) = 0.0
		_Rough_Multi("_Rough_Multi", Float) = 0.0
		_Diffuse_Intensity("_Diffuse_Intensity", Float) = 1.0
		_U_Light_Scale("_U_Light_Scale", Float) = 1.0
		_Shadow_Bias_Factor("_Shadow_Bias_Factor(Vector2)", Vector) = (0.004, 0.001, 1, 1)
		_Env_Shadow_Factor("_Env_Shadow_Factor", Color) = (0.667, 0.545, 0.761, 1)
		_Envir_Brightness("_Envir_Brightness", Float) = 1.0
		_Max_Brightness("_Max_Brightness", Float) = 130.0
		_Envir_Fresnel_Brightness("_Envir_Fresnel_Brightness", Float) = 0.35
		_Rim_Power("_Rim_Power", Float) = 2.80
		_U_Rim_Start("_U_Rim_Start", Float) = 0.0
		_U_Rim_End("_U_Rim_End", Float) = 1.0
		_Rim_Color("_Rim_Color", Color) = (0,0.3804,1,0)
		_Rim_Multi("_Rim_Multi", Float) = 0.0
		_Force_Pixel_Color("_Force_Pixel_Color(Vector3)", Color) = (0.0, 0.0, 0.0, 0.0)
		_Adjust_Inner("_Adjust_Inner(Vector3)", Color) = (1.0, 1.0, 1.0, 1.0)
		_Inner_Alpha("_Inner_Alpha", Float) = 1.0
		_AlphaMtl("_AlphaMtl", Float) = 1.0
		_U_Tonemapping_Factor("_U_Tonemapping_Factor", Float) = 0.0
		_Bloom_Range("_Bloom_Range", Float) = 0.4
		_Illum_Multi("_Illum_Multi", Float) = 1.0
		_Emissive_Bloom("_Emissive_Bloom", Float) = 1.0
    }
    SubShader
    {
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 100

		Pass
		{
			Name "StandardLit"
			Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fog

			// -------------------------------------
			// 自定义 keywords


			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#define USE_CARTOON 
			#define USE_SSS 
			#define USE_AO 

			#include "CharacterCore.hlsl"

			ENDHLSL

		}

		// Used for rendering shadowmaps
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}
