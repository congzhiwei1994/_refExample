Shader "Hidden/KriptoFX/KWS/MaskDepthNormal" 
{
	Properties{
		srpBatcherFix("srpBatcherFix", Float) = 0
	}

	SubShader{
		Pass // dx11 tesselation
		{
			ZWrite On


			Cull Off

			CGPROGRAM
				
				#include "../Common/KWS_WaterVariables.cginc"
				#include "../Common/KWS_WaterPassHelpers.cginc"
				#include "../Common/KWS_CommonHelpers.cginc"
				#include "KWS_PlatformSpecificHelpers.cginc"
				#include "../Common/KWS_WaterHelpers.cginc"
				#include "../Common/Shoreline/KWS_Shoreline_Common.cginc"
				#include "../Common/KWS_WaterVertPass.cginc"
				#include "../Common/KWS_WaterFragPass.cginc"
				#include "../Common/KWS_Tessellation.cginc"

				#pragma multi_compile _ KW_FLOW_MAP KW_FLOW_MAP_FLUIDS
				#pragma multi_compile _ KW_DYNAMIC_WAVES
				#pragma multi_compile _ USE_MULTIPLE_SIMULATIONS
				#pragma multi_compile _ USE_SHORELINE
				#pragma multi_compile _ USE_FILTERING

				#pragma target 4.6

				#pragma vertex vertHull
				#pragma fragment fragDepth
				#pragma hull HS
				#pragma domain DS_Depth

				ENDCG
			}

			Pass // dx9 without tesselation
			{
				ZWrite On
				Cull Off

				CGPROGRAM

				#include "../Common/KWS_WaterVariables.cginc"
				#include "../Common/KWS_WaterPassHelpers.cginc"
				#include "../Common/KWS_CommonHelpers.cginc"
				#include "KWS_PlatformSpecificHelpers.cginc"
				#include "../Common/KWS_WaterHelpers.cginc"
				#include "../Common/Shoreline/KWS_Shoreline_Common.cginc"
				#include "../Common/KWS_WaterVertPass.cginc"
				#include "../Common/KWS_WaterFragPass.cginc"

				#pragma multi_compile _ KW_FLOW_MAP KW_FLOW_MAP_FLUIDS
				#pragma multi_compile _ KW_DYNAMIC_WAVES
				#pragma multi_compile _ USE_MULTIPLE_SIMULATIONS
				#pragma multi_compile _ USE_SHORELINE
				#pragma multi_compile _ USE_FILTERING

				#pragma vertex vertDepth
				#pragma fragment fragDepth


				ENDCG
			}
		}
}
