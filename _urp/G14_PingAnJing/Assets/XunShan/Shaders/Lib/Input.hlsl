#ifndef GSTORE_INPUT_INCLUDED
#define GSTORE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

// Ŀ�ģ�
// �Ա�������������д���

#define GS_DEFAULT_TANGENT real3(1.0, 0.0, 0.0)
#define GS_DEFAULT_BITANGENT real3(0.0, 1.0, 0.0)


// ���ڻ�ȡUnity URP����Ĳ���
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

// ����ʵ�ֺ���
// GS_InputData GetGSInputData(Varyings vertexOutput, GS_SurfaceData surfaceData)

// ���ڻ�ȡ����Environment����Ĳ���
struct GS_EnvData
{
	half3   envIrradiance;		// �������ն�(IBL-Diffuse)
	half3	envReflection;		// ��������(IBL-Specular)
	half3	envShadowColor;
	half	envBrightness;
};

// ����ʵ�ֺ���
// GS_EnvData GetGSEnvData(Varyings vertexOutput, Light light, GS_InputData inputData, GS_BRDFData brdfData, BxDFContext bxdfContext)

// ���ʱ����������
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

// ����ʵ�ֺ���
// GS_SurfaceData GetGSSurfaceData(float2 uv)

half GetSurfaceAlpha(half albedoAlpha, half cutoff)
{
	half alpha = albedoAlpha;

#if defined(_ALPHATEST_ON)
	clip(alpha - cutoff);
#endif

	return alpha;
}


// δnormalize
real3 UnpackNormalRG(real2 packedNormal, real z)
{
	real3 normal;
	normal.xy = packedNormal.rg * 2.0 - 1.0;
	normal.z = z;
	// ����Z��
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