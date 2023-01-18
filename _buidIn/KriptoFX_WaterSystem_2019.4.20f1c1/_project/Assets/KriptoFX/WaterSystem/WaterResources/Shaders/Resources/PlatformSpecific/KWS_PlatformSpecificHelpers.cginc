//#define ENVIRO_FOG
//#define AZURE_FOG
//#define WEATHER_MAKER
//#define ATMOSPHERIC_HEIGHT_FOG
//#define VOLUMETRIC_FOG_AND_MIST
//#define COZY_FOG

//ATMOSPHERIC_HEIGHT_FOG also need to change the "Queue" = "Transparent-1"      -> "Queue" = "Transparent+2"
//VOLUMETRIC_FOG_AND_MIST also need to enable "Water->Rendering->DrawToDepth"

#define _FrustumCameraPlanes unity_CameraWorldClipPlanes

//------------------  unity includes   ----------------------------------------------------------------

#ifndef UNITY_CG_INCLUDED
	#include "UnityCG.cginc"
#endif

#ifndef UNITY_LIGHTING_COMMON_INCLUDED
	#include "UnityLightingCommon.cginc"
#endif

//-------------------------------------------------------------------------------------------------------




//------------------  thid party assets  ----------------------------------------------------------------

#if defined(ENVIRO_FOG)
	#include "Assets/Third-party assets/Enviro - Sky and Weather/Core/Resources/Shaders/Core/EnviroFogCore.cginc"
#endif

#if defined(AZURE_FOG)
	#include "Assets/Azure[Sky] Dynamic Skybox/Shaders/Transparent/AzureFogCore.cginc"
#endif

#if defined(WEATHER_MAKER)
	#include "Assets/WeatherMaker/Prefab/Shaders/WeatherMakerFogExternalShaderInclude.cginc"
#endif

#if defined(ATMOSPHERIC_HEIGHT_FOG)
	#include "Assets/Third-party assets/BOXOPHOBIC/Atmospheric Height Fog/Core/Includes/AtmosphericHeightFog.cginc"
#endif

#if defined(VOLUMETRIC_FOG_AND_MIST)
	#include "Assets/Third-party assets/VolumetricFog/Resources/Shaders/VolumetricFogOverlayVF.cginc"
#endif

#if defined(COZY_FOG)
	#include "Assets/Third-party assets/Distant Lands/Cozy Weather/Contents/Materials/Shaders/Includes/StylizedFogIncludes.cginc"
#endif

//-------------------------------------------------------------------------------------------------------


//UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
Texture2D _CameraDepthTexture;
SamplerState sampler_CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;

Texture2D _CameraOpaqueTexture;
SamplerState sampler_CameraOpaqueTexture;
float4 _CameraOpaqueTexture_TexelSize;
float4 _CameraOpaqueTexture_RTHandleScale;

float3 KWS_AmbientColor;

float4x4 KWS_MATRIX_I_VP;



inline float4 ObjectToClipPos(float4 vertex)
{
	return UnityObjectToClipPos(vertex);
}

inline float2 GetTriangleUV(uint vertexID)
{
	#if UNITY_UV_STARTS_AT_TOP
		return float2((vertexID << 1) & 2, 1.0 - (vertexID & 2));
	#else
		return float2((vertexID << 1) & 2, vertexID & 2);
	#endif
}

inline float4 GetTriangleVertexPosition(uint vertexID, float z = UNITY_NEAR_CLIP_VALUE)
{
	float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
	return float4(uv * 2.0 - 1.0, z, 1.0);
}

inline float3 LocalToWorldPos(float3 localPos)
{
	return mul(UNITY_MATRIX_M, float4(localPos, 1));
}

inline float3 WorldToLocalPos(float3 worldPos)
{
	return mul(unity_WorldToObject, float4(worldPos, 1));
}

inline float3 WorldToLocalPosWithoutTranslation(float3 worldPos)
{
	return mul((float3x3)unity_WorldToObject, worldPos);
}

inline float3 GetCameraRelativeWorldPos(float3 worldPos)
{
	return worldPos;
}

inline float3 GetWorldSpaceViewDirNorm(float3 worldPos)
{
	return normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
}

inline float3 GetWorldSpaceNormal(float3 normal)
{
	return normalize(mul((float3x3)unity_ObjectToWorld, normal)).xyz;
}

inline float GetWorldToCameraDistance(float3 worldPos)
{
	return length(_WorldSpaceCameraPos.xyz - worldPos.xyz);
}

float3 GetWorldSpacePositionFromDepth(float2 uv, float deviceDepth)
{
	float4 positionCS = float4(uv * 2.0 - 1.0, deviceDepth, 1.0);
	#if UNITY_UV_STARTS_AT_TOP
		positionCS.y = -positionCS.y;
	#endif
	float4 hpositionWS = mul(KWS_MATRIX_I_VP, positionCS);
	return hpositionWS.xyz / hpositionWS.w;
}

inline float GetSceneDepth(float2 uv)
{
	return _CameraDepthTexture.SampleLevel(sampler_CameraDepthTexture, uv, 0);
}

inline float4 GetSceneDepthGather(float2 uv)
{
	return _CameraDepthTexture.Gather(sampler_CameraDepthTexture, uv);
}

inline float3 GetAmbientColor()
{
	return KWS_AmbientColor;
}

inline float2 GetSceneColorNormalizedUV(float2 uv)
{
	return clamp(uv, 0.001, 0.999) * _CameraOpaqueTexture_RTHandleScale.xy;
}

inline float3 GetSceneColor(float2 uv)
{
	return _CameraOpaqueTexture.SampleLevel(sampler_CameraOpaqueTexture, GetSceneColorNormalizedUV(uv), 0).xyz;
}

inline half3 GetSceneColorWithDispersion(float2 uv, float dispersionStrength)
{
	half3 refraction;
	refraction.r = GetSceneColor(uv - _CameraOpaqueTexture_TexelSize.xy * dispersionStrength).r;
	refraction.g = GetSceneColor(uv).g;
	refraction.b = GetSceneColor(uv + _CameraOpaqueTexture_TexelSize.xy * dispersionStrength).b;
	return refraction;
}

inline float3 GetMainLightDir()
{
	return _WorldSpaceLightPos0.xyz;
}

inline float3 GetMainLightColor()
{
	return _LightColor0.xyz;
}

inline void GetInternalFogVariables(float4 pos, float3 viewDir, float surfaceDepthZ, float screenPosZ, out half3 fogColor, out half3 fogOpacity)
{
	#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
		UNITY_CALC_FOG_FACTOR_RAW(surfaceDepthZ);
		fogOpacity = 1 - saturate(unityFogFactor);
		fogColor = unity_FogColor;
	#else
		fogOpacity = half3(0.0, 0.0, 0.0);
		fogColor = half3(0.0, 0.0, 0.0);
	#endif
}


inline half3 ComputeInternalFog(half3 sourceColor, half3 fogColor, half3 fogOpacity)
{
	#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
		return lerp(sourceColor, fogColor, fogOpacity);
	#else
		return sourceColor;
	#endif
}

inline half3 ComputeThirdPartyFog(half3 sourceColor, float3 worldPos, float2 screenUV, float screenPosZ)
{
	#if defined(ENVIRO_FOG)
		sourceColor = TransparentFog(half4(sourceColor, 1.0), worldPos.xyz, screenUV, Linear01Depth(screenPosZ));
	#elif defined(AZURE_FOG)
		sourceColor = ApplyAzureFog(half4(sourceColor, 1.0), worldPos.xyz).xyz;
	#elif defined(WEATHER_MAKER)
		_DirectionalLightMultiplier = 1;
		_PointSpotLightMultiplier = 1;
		_AmbientLightMultiplier = 1;
		sourceColor = ComputeWeatherMakerFog(half4(sourceColor, 1.0), worldPos, true);
	#elif defined(ATMOSPHERIC_HEIGHT_FOG)
		float4 fogParams = GetAtmosphericHeightFog(worldPos);
		fogParams.a = saturate(fogParams.a * 1.35f); //by some reason max value < 0.75;
		sourceColor = ApplyAtmosphericHeightFog(half4(sourceColor, 1.0), fogParams).xyz;
	#elif defined(VOLUMETRIC_FOG_AND_MIST)
		sourceColor = overlayFog(worldPos, float4(screenUV, screenPosZ, 1), half4(sourceColor, 1.0)).xyz;
	#elif defined(COZY_FOG)
		sourceColor = BlendStylizedFog(worldPos, half4(sourceColor.xyz, 1));
	#endif

	return max(0, sourceColor);
}

inline float GetExposure()
{
	return 1;
}

float GetSurfaceDepth(float screenPosZ)
{
	return UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPosZ);
}
