/* Configuration: VegetationStudio */

//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

Shader "Universal Render Pipeline/Nature/Stylized Grass"
{
	Properties
	{
		//Lighting
		[MainTexture] _BaseMap("Albedo", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		//[Header(Shading)]
		[MainColor] _BaseColor("Color", Color) = (0.49, 0.89, 0.12, 1.0)
		_HueVariation("Hue Variation (Alpha = Intensity)", Color) = (1, 0.63, 0, 0.15)
		_ColorMapStrength("Colormap Strength", Range(0.0, 1.0)) = 0.0
		_ColorMapHeight("Colormap Height", Range(0.0, 1.0)) = 1.0
		_ScalemapInfluence("Scale influence", vector) = (0,1,0,0)
		_OcclusionStrength("Ambient Occlusion", Range(0.0, 1.0)) = 0.25
		_VertexDarkening("Random Darkening", Range(0, 1)) = 0.1
		_Smoothness("Reflectivity", Range(0.0, 1.0)) = 0.5
		_Translucency("Translucency", Range(0.0, 1.0)) = 0.2
		
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BendPushStrength("Push Strength", Range(0.0, 1.0)) = 1.0
		[MaterialEnum(PerVertex,0,PerObject,1)]_BendMode("Bend Mode", Float) = 0.0
		_BendFlattenStrength("Flatten Strength", Range(0.0, 1.0)) = 1.0
		_PerspectiveCorrection("Perspective Correction", Range(0.0, 1.0)) = 0.0

		//[Header(Wind)]
		_WindAmbientStrength("Ambient Strength", Range(0.0, 1.0)) = 0.2
		_WindSpeed("Speed", Range(0.0, 10.0)) = 3.0
		_WindDirection("Direction", vector) = (1,0,0,0)
		_WindVertexRand("Vertex randomization", Range(0.0, 1.0)) = 0.6
		_WindObjectRand("Object randomization", Range(0.0, 1.0)) = 0.5
		_WindRandStrength("Random per-object strength", Range(0.0, 1.0)) = 0.5
		_WindSwinging("Swinging", Range(0.0, 1.0)) = 0.15
		_WindGustStrength("Gusting strength", Range(0.0, 1.0)) = 0.2
		_WindGustFreq("Gusting frequency", Range(0.0, 10.0)) = 4
		[NoScaleOffset] _WindMap("Wind map", 2D) = "black" {}
		_WindGustTint("Gusting tint", Range(0.0, 1.0)) = 0.066

		//[Header(Rendering)]
		_FadeParams("Fade params (X=Start, Y=End, Z=Toggle", vector) = (50, 100, 0, 0)
		[MaterialEnum(Both,0,Front,1,Back,2)] _Cull("Render faces", Float) = 0
		[Toggle] _AlphaToCoverage("Alpha to coverage", Float) = 0.0
		[Toggle] _AdvancedLighting("Advanced Lighting", Float) = 1.0
		[Toggle] _Scalemap("Scale grass by heightmap", Float) = 0.0
		[Toggle] _ShadowBiasCorrection("Avoid shadow acne", Float) = 0.0
		[ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
		[ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		// Editmode props
		[HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
	}

	SubShader
	{
		Tags{
			"RenderType" = "Opaque" 
			"Queue" = "AlphaTest"
			"RenderPipeline" = "UniversalPipeline" 
			"IgnoreProjector" = "True"
			"NatureRendererInstancing" = "True"
		}
		LOD 300

		// ------------------------------------------------------------------
		//  Forward pass. Shades all light in a single pass. GI + emission + Fog
		Pass
			{
			Name "ForwardLit"
			Tags{ "LightMode" = "UniversalForward" }

			AlphaToMask [_AlphaToCoverage]
			Blend One Zero, One Zero
			Cull [_Cull]
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _ADVANCED_LIGHTING
			#pragma shader_feature_local _SCALEMAP
			#pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local _SHADOWBIAS_CORRECTION

			//Disable features
			#undef _ALPHAPREMULTIPLY_ON
			#undef _EMISSION
			#undef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#undef _OCCLUSIONMAP
			#undef _METALLICSPECGLOSSMAP
			#define _SPECULARHIGHLIGHTS_OFF

			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile_vertex LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile_fog

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			//Constants
			#define _SPECULARHIGHLIGHTS_OFF
			#define _ALPHATEST_ON
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			#include "Libraries/Input.hlsl"
			#include "Libraries/Common.hlsl"
			#include "Libraries/Color.hlsl"
			#include "Libraries/Lighting.hlsl"
			
			/* start VegetationStudio */
			#include "Libraries/VS_InstancedIndirect.cginc"
			#pragma instancing_options assumeuniformscaling renderinglayer procedural:setup
			/* end VegetationStudio */

			/* start NatureRenderer */
//			#pragma instancing_options assumeuniformscaling procedural:SetupNatureRenderer
//			#include "Assets/Visual Design Cafe/Nature Shaders/Common/Nodes/Integrations/Nature Renderer.cginc"
			/* end NatureRenderer */

			#define SHADERPASS_FORWARD

			#pragma vertex LitPassVertex
			#pragma fragment ForwardPassFragment
			#include "LightingPass.hlsl"

			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}

			ZWrite On
			ZTest LEqual
			Cull[_Cull]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_vertex LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE
			#pragma multi_compile_instancing
			#pragma shader_feature_local _SCALEMAP
			#define _ALPHATEST_ON

			#define SHADERPASS_SHADOWCASTER
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			#include "Libraries/Input.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Libraries/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

			/* start VegetationStudio */
			#include "Libraries/VS_InstancedIndirect.cginc"
			#pragma instancing_options assumeuniformscaling renderinglayer procedural:setup
			/* end VegetationStudio */

			/* start NatureRenderer */
//			#pragma instancing_options assumeuniformscaling procedural:SetupNatureRenderer
//			#include "Assets/Visual Design Cafe/Nature Shaders/Common/Nodes/Integrations/Nature Renderer.cginc"
			/* end NatureRenderer */

			#include "ShadowPass.hlsl"

			//#endif
			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}

			ZWrite On
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			#define SHADERPASS_DEPTHONLY
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			// -------------------------------------
			// Material Keywords
			#pragma multi_compile_vertex LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE
			#pragma shader_feature_local _SCALEMAP
			#define _ALPHATEST_ON

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#include "Libraries/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Libraries/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

			/* start VegetationStudio */
			#include "Libraries/VS_InstancedIndirect.cginc"
			#pragma instancing_options assumeuniformscaling renderinglayer procedural:setup
			/* end VegetationStudio */

			/* start NatureRenderer */
//			#pragma instancing_options assumeuniformscaling procedural:SetupNatureRenderer
//			#include "Assets/Visual Design Cafe/Nature Shaders/Common/Nodes/Integrations/Nature Renderer.cginc"
			/* end NatureRenderer */

			#include "DepthPass.hlsl"
			ENDHLSL
		}

		//URP 10.0.0 not yet available
		/*
		// This pass is used when drawing to a _CameraNormalsTexture texture
		Pass
		{
			Name "DepthNormals"
			Tags{"LightMode" = "DepthNormals"}

			ZWrite On
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			#pragma vertex DepthOnlyVertex
			#define SHADERPASS_DEPTH_ONLY
			//Only URP 10.0.0+ this amounts to the actual fragment shader, otherwise a dummy is used
			#pragma fragment DepthNormalsFragment

			// -------------------------------------
			// Material Keywords
			#pragma multi_compile_vertex LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment __ LOD_FADE_CROSSFADE
			#pragma shader_feature_local _SCALEMAP
			#define _ALPHATEST_ON

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Libraries/Input.hlsl"
			#include "Libraries/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#if VERSION_GREATER_EQUAL(10,0)
			#include "Packages/com.unity.render-pipelines.core/Shaders/DepthNormalsPass.hlsl"
			#endif

			//* start VegetationStudio */
			//#include "Libraries/VS_InstancedIndirect.cginc"
			//#pragma instancing_options assumeuniformscaling renderinglayer procedural:setup
			/* end VegetationStudio */

			/* start NatureRenderer */
			//#pragma instancing_options assumeuniformscaling procedural:SetupNatureRenderer
			//#include "Assets/Visual Design Cafe/Nature Shaders/Common/Nodes/Integrations/Nature Renderer.cginc"
			/* end NatureRenderer */

			//#include "DepthPass.hlsl"
			//ENDHLSL
		//}
		//*/
			
		// Used for Baking GI. This pass is stripped from build.
		//Disabled, breaks SRP batcher, shadr doesnt have the exact same properties as the Lit shader
		//UsePass "Universal Render Pipeline/Lit/Meta"
		}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "StylizedGrass.StylizedGrassShaderGUI"
}
