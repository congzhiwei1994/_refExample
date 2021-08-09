#ifndef GSTORE_INPUT_INCLUDED
#define GSTORE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

// 目的：
// 对表面输入参数进行处理

#define GS_DEFAULT_TANGENT real3(1.0, 0.0, 0.0)
#define GS_DEFAULT_BITANGENT real3(0.0, 1.0, 0.0)


// 用于获取Unity URP输入的参数
struct GS_InputData
{
	float3  positionWS;
	half3   normalWS;
	half3	tangentWS;
	half3	bitangentWS;
	half3   viewDirectionWS;
	half3   anisotropicWS;
	float4  shadowCoord;
	half    fogCoord;
	half3   vertexLighting;
};

// 必需实现函数
// GS_InputData GetGSInputData(Varyings vertexOutput, GS_SurfaceData surfaceData)

// 用于获取环境Environment输入的参数
struct GS_EnvData
{
	half3   envIrradiance;		// 环境辐照度(IBL-Diffuse)
	half3	envReflection;		// 环境反射(IBL-Specular)
	half3	envShadowColor;
	half	envBrightness;
};

// 必需实现函数
// GS_EnvData GetGSEnvData(Varyings vertexOutput, Light light, GS_InputData inputData, GS_BRDFData brdfData, BxDFContext bxdfContext)

// 材质表面输入参数
struct GS_SurfaceData
{
	half3 albedo;
	half  metallic;
	half  roughness;
	half  subsurface;
	// anisotropic ratio(0->no isotropic; 1->full anisotropy in tangent direction, -1->full anisotropy in bitangent direction)
	half  anisotropy;
	half3 anisotropicTS;
	half  anisoSpecularShift;
	half3 normalTS;
	half3 emission;
	half  occlusion;
	half  alpha;
};

// 必需实现函数
// GS_SurfaceData GetGSSurfaceData(float2 uv)

half GetSurfaceAlpha(half albedoAlpha, half cutoff)
{
	half alpha = albedoAlpha;

#if defined(_ALPHATEST_ON)
	clip(alpha - cutoff);
#endif

	return alpha;
}


// 未normalize
real3 UnpackNormalRG(real2 packedNormal, real z)
{
	real3 normal;
	normal.xy = packedNormal.rg * 2.0 - 1.0;
	normal.z = z;
	// 正常Z求法
	//  normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normal;
}
real3 UnpackNormalRG(real2 packedNormal)
{
	return UnpackNormalRG(packedNormal, 1.0);
}

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
#ifdef _NORMALMAP
	half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
#if _L_BUMP_SCALE_ON
	return UnpackNormalScale(n, scale);
#else
	return UnpackNormal(n);
#endif
#else
	return half3(0.0h, 0.0h, 1.0h);
#endif
}





#endif