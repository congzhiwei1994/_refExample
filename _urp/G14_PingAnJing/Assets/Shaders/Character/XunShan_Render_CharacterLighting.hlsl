#ifndef XUNSHAN_RENDER_CHARACTER_INCLUDED
	#define XUNSHAN_RENDER_CHARACTER_INCLUDED

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

	real3 NormalRG_Custom(real2 packedNormal, real z)
	{
		real3 normal;
		normal.xy = packedNormal.rg * 2.0 - 1.0;
		normal.z = z;
		return normal;
	}

	
	real3 TransformTangentToWorld_Scale(real3 dirTS, real scale, real3x3 tangentToWorld)
	{
		// Note matrix is in row major convention with left multiplication as it is build on the fly
		dirTS.xy *= scale;
		return TransformTangentToWorld(dirTS, tangentToWorld);
	}

	// GPU Gems1 - 16 次表面散射的实时近似（Real-Time Approximations to Subsurface Scattering）
	half WrapDiffuse(half NoL, half wrap)
	{
		// 原实现:
		return max(0.0, (NoL + wrap) / (1 + wrap));
		//return max(0.0, NoL + wrap) / (1 + wrap);
	}

	// GGX / Trowbridge-Reitz
	// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
	float My_D_GGX(float a, float NDotH)
	{
		float a2 = a * a;
		float d = (NDotH * a2 - NDotH) * NDotH + 1;	// 2 mad
		return min(a2 / (d*d), 10000.0);					// 4 mul, 1 rcp
	}

	// Tuned to match behavior of Vis_Smith
	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	float My_Vis_Schlick(float a, float NDotV, float NoL)
	{
		//float k = sqrt(a2) * 0.5;
		float k = a;

		float Vis_SchlickV = NDotV * (1 - k) + k;
		float Vis_SchlickL = NoL * (1 - k) + k;
		return 0.25 / (Vis_SchlickV * Vis_SchlickL);
	}


	
	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	real3 My_F_Schlick(real3 f0, real f90, real u)
	{
		real x = 1.0 - u;
		real x2 = x * x;
		real x5 = x * x2 * x2;

		return f0 * (1.0 - x5) + (f90 * x5);        // sub mul mul mul sub mul mad*3
	}
	
	real3 My_F_Schlick(real3 f0, real u)
	{
		return My_F_Schlick(f0, 1.0, u);               // sub mul mul mul sub mad*3
	}

	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	float3 EnvironmentBRDFApprox(float roughness, float NDotV, float3 f0 ,half envirFresnel )
	{
		float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
		float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);

		float4 r = roughness * c0 + c1;
		float a004 = min(r.x * r.x, exp2(-9.28 * NDotV)) * r.x + r.y;
		float2 AB = float2(-1.04, 1.04) * a004 + r.zw;

		return f0 * AB.x + AB.y * envirFresnel;
	}

	float GetSpecularOcclusion(float NDotV, float AoFactor, float ao)
	{
		// 直视  NDotV = 1，a = 1
		// 斜视  NDotV = 0,a = ao
		// 否则   ao < a < 1
		half a = lerp(1.0, ao, NDotV);

		// ao(0.5~1)  k = 0
		// ao = 0,  b= 1, k = AoFactor
		// ao = 0.5, b= 0, k = 0
		half b = (2 * saturate(0.5 - ao));
		float k =  b * AoFactor;

		// 越黑的地方就用回原来的黑度，较浅的地方，会根据视线减弱AO，越是grazing角度越浅
		// k = 0, c = a, ao = 0.5,
		// k = 1, c = ao, ao = 0
		half c = lerp(a, ao, k);
		return c;
	}


	half3 ShiftTangent ( half3 T, half3 N, float shift)
	{
		half3 shiftedT = T+ shift * N;
		return normalize( shiftedT);
	}
	
	float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
	{
		half3 H = normalize ( L + V );
		float dotTH = dot ( T, H );
		float sinTH = sqrt ( 1 - dotTH * dotTH);
		float dirAtten = smoothstep( -1, 0, dotTH );
		return dirAtten * pow(sinTH, exponent);
	}


	#if _RIMENABLE_ON
		half3 CalcRim(half NDotV,half RimStart,half RimEnd ,half RimSize, half3 RimColor,half RimFactor)
		{
			half rim = smoothstep(RimStart, RimEnd, pow(1 - NDotV, RimSize));
			half rimMulti = RimFactor;
			return rim * RimColor.rgb * rimMulti;
		}
	#endif 



#endif