Shader "XunShan/Actor/WaterBase"
{
    Properties
    {
		_Albedo("Albedo", Color) = (0,0,0,0)
		[NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
		_Tiling_Offset("Tiling&Offset",Vector) = (1,1,0,0)

		_Smoothness("Smoothness", Range(0,1)) = 0.0
		_Density("Density",Float) = 1
		_AbsorbColor("AbsorbColor",Color) = (1,1,1,1)
		_DeepWaterColor("DeepWaterColor",Color) = (1,1,1,1)

		_CausticColor("CausticColor", Color) = (1,1,1,1)
		_CausticScale("CausticScale",Float) = 1
		_CausticMap1("CausticMap1",2D) = "black" {}
		_CausticMap2("CausticMap2",2D) = "black" {}

		_CubeMap("CubeMap",CUBE) = "white" {}
		_WaterReflection("WaterReflection",Range(0,0.15)) = 0

		//FOAM
		_FoamMap("FoamMap",2D) = "black" {}
		_PerlinNoiseMap("NoiseMap",2D) = "black"{}
		_FoamStrength("FoamStrength",Range(0,1)) = 0.2
		
		//Bloom Factor
		_BloomFactor("BloomFactor(Bloom强度)",Float) = 0

		//////////////////////////////////////////////
		// 内部变量
		// Blending state
		[HideInInspector] _Surface("", Float) = 0.0
		[HideInInspector] _Blend("", Float) = 0.0
		[HideInInspector] _SrcBlend("", Float) = 1.0
		[HideInInspector] _DstBlend("", Float) = 0.0
		[HideInInspector] _ZWrite("", Float) = 1.0
		[HideInInspector] _Cull("", Float) = 2.0
		// Shader类型标识
		[HideInInspector] _ObjectType_Actor("", Int) = 0
		// Internal
		[HideInInspector] _INTR_AnisoType("", Int) = 0
		[HideInInspector] _INTR_SSSType("", Int) = 0
		[HideInInspector] _INTR_IBLDiff("", Int) = 0
		[HideInInspector] _INTR_IBLSpec("", Int) = 0
		[HideInInspector] _INTR_IBLSpecLight("", Int) = 0
		///////////////////////////////////////////////
    }
    SubShader
    {
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

		Pass
		{
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			//Blend[_SrcBlend][_DstBlend]
			Blend One Zero, One Zero
			ZWrite	Off
			Cull Back

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
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// -------------------------------------
			// Unity defined keywords
			//#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			//#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile_fog

			// -------------------------------------
			// 自定义 Local keywords
			#define _NORMALMAP 
			#define _L_AO_ON
			#define _L_MIX_ON
			#pragma shader_feature_local _ _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
			#pragma shader_feature_local _ _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP _L_IBL_SPEC_URP_LIGHT _L_IBL_SPEC_LOCAL_SPHERE_MAP_LIGHT _L_IBL_SPEC_LOCAL_CUBE_MAP_LIGHT
			#pragma shader_feature_local _ _L_ANISO_ON
			#pragma shader_feature_local _ _L_SSS_ON

			// -------------------------------------
			// 自定义 Global keywords
			#pragma shader_feature _ _G_DEBUG_ACTOR_ON
			#pragma shader_feature _ _ALPHATEST_ON
			#pragma shader_feature _ _RECEIVE_SHADOWS_OFF

			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#include "WaterBaseInput.hlsl"
			#include "WaterCore.hlsl"
			ENDHLSL
		}


		// Used for depth prepass
		// If shadows cascade are enabled we need to perform a depth prepass. 
		// We also need to use a depth prepass in some cases camera require depth texture
		// (e.g, MSAA is enabled and we can't resolve with Texture2DMS
		//Pass
  //      {
  //          Name "DepthOnly"
  //          Tags{"LightMode" = "DepthOnly"}

  //          ZWrite On
  //          ColorMask 0
  //          Cull[_Cull]

  //          HLSLPROGRAM
  //          // Required to compile gles 2.0 with standard srp library
  //          #pragma prefer_hlslcc gles
  //          #pragma exclude_renderers d3d11_9x
  //          #pragma target 2.0

  //          #pragma vertex DepthOnlyVertex
  //          #pragma fragment DepthOnlyFragment

  //          // -------------------------------------
  //          // Material Keywords
  //          #pragma shader_feature _ALPHATEST_ON

  //          //--------------------------------------
  //          // GPU Instancing
  //          #pragma multi_compile_instancing

		//	#include "ActorDebug.hlsl"
		//	#include "HeroBaseInput.hlsl"
  //          #include "ActorBaseDepthOnlyPass.hlsl"
  //          ENDHLSL
  //      }

		// Used for Baking GI. This pass is stripped from build.
		//UsePass "Universal Render Pipeline/Lit/Meta"

    }

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	//CustomEditor "Rendering.ShaderEditor.ActorShaderGUI"
}
