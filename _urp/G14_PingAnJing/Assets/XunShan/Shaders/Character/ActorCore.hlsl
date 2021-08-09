#ifndef ACTOR_CORE_INCLUDED
#define ACTOR_CORE_INCLUDED

//////////////////////////////////////////////
// ����(��������)
#ifdef _G_DEBUG_ACTOR_ON
//
// ShaderEditor.DebugActor.Mode:  static fields
//
#define DEBUGACTOR_MODE_ALBEDO				(1)
#define DEBUGACTOR_MODE_METALLIC			(DEBUGACTOR_MODE_ALBEDO + 1)
#define DEBUGACTOR_MODE_ROUGHNESS			(DEBUGACTOR_MODE_METALLIC + 1)
#define DEBUGACTOR_MODE_AO					(DEBUGACTOR_MODE_ROUGHNESS + 1)
#define DEBUGACTOR_MODE_SUBSURFACE			(DEBUGACTOR_MODE_AO + 1)
#define DEBUGACTOR_MODE_ANISOTROPY			(DEBUGACTOR_MODE_SUBSURFACE + 1)
#define DEBUGACTOR_MODE_EMISSIVE			(DEBUGACTOR_MODE_ANISOTROPY + 1)
#define DEBUGACTOR_MODE_ANISO_TANGENT		(DEBUGACTOR_MODE_EMISSIVE + 1)
#define DEBUGACTOR_MODE_ANISO_SHIFT			(DEBUGACTOR_MODE_ANISO_TANGENT + 1)
#define DEBUGACTOR_MODE_NORMALMAP			(DEBUGACTOR_MODE_ANISO_SHIFT + 1)
#define DEBUGACTOR_MODE_MODEL_NORMAL_WORLD	(DEBUGACTOR_MODE_NORMALMAP + 1)
#define DEBUGACTOR_MODE_NORMAL_WORLD		(DEBUGACTOR_MODE_MODEL_NORMAL_WORLD + 1)
#define DEBUGACTOR_MODE_ADDITIONAL_LIGHTS	(DEBUGACTOR_MODE_NORMAL_WORLD + 1)
#define DEBUGACTOR_MODE_BAKED_GI			(DEBUGACTOR_MODE_ADDITIONAL_LIGHTS + 1)
#define DEBUGACTOR_MODE_IBL_SPECULAR		(DEBUGACTOR_MODE_BAKED_GI + 1)
#define DEBUGACTOR_MODE_DIRECT_DIRECTIONAL	(DEBUGACTOR_MODE_IBL_SPECULAR + 1)
#define DEBUGACTOR_MODE_GI					(DEBUGACTOR_MODE_DIRECT_DIRECTIONAL + 1)
#define DEBUGACTOR_MODE_BRDF				(DEBUGACTOR_MODE_GI + 1)
#define DEBUGACTOR_MODE_ENV_BRDF			(DEBUGACTOR_MODE_BRDF + 1)
#define DEBUGACTOR_MODE_RADIANCE			(DEBUGACTOR_MODE_ENV_BRDF + 1)
#define DEBUGACTOR_MODE_PBR_DIFFUSE_VALID	(DEBUGACTOR_MODE_RADIANCE + 1)
#define DEBUGACTOR_MODE_PBR_SPECULAR_VALID	(DEBUGACTOR_MODE_PBR_DIFFUSE_VALID + 1)
#define DEBUGACTOR_MODE_HDR_HEATMAP			(DEBUGACTOR_MODE_PBR_SPECULAR_VALID + 1)

#define DEBUG_ON 
#define DEBUG_MODE _G_DebugActorMode
// ��������
uint _G_DebugActorMode;
#endif

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "../Lib/Color.hlsl"
#include "../Lib/BSDF.hlsl"
#include "../Lib/Input.hlsl"
#include "../Lib/Lighting.hlsl"
#include "../Lib/URPLighting.hlsl"
#include "../Lib/Debug.hlsl"

//////////////////////////////////////////////
//Shader�е�Propertiesʾ��
/*
Properties
{
	[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
	[NoScaleOffset]_MixMap("Mix Map", 2D) = "white" {}
	[NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
	_EnvShadowColor("Env Shadow Color", Color) = (0.667, 0.545, 0.761, 1)
	_EnvBrightness("Env Brightness", Range(0,2)) = 1
	// _L_ANISO_ON
	[NoScaleOffset]_AnisotropicMap("Anisotropic Map", 2D) = "bump" {}
	_AnisoShiftOffset("Aniso Shift Offset", Float) = 0.0
	_AnisoShiftScale("Aniso Shift Scale", Float) = 0.5
	// _L_ROUGHNESS_RANGE_ON
	_RoughnessLow("RoughnessLow", Range(0,1)) = 0.2
	_RoughnessHigh ("RoughnessHigh", Range(0,1)) = 1.0
	// _L_SSS_ON
	_SSS_Factor("SSS Factor", Range(0,1)) = 1
	// Blending state
	[HideInInspector] _Surface("__surface", Float) = 0.0
	[HideInInspector] _Blend("__blend", Float) = 0.0
	[HideInInspector] _AlphaClip("__clip", Float) = 0.0
	[HideInInspector] _SrcBlend("__src", Float) = 1.0
	[HideInInspector] _DstBlend("__dst", Float) = 0.0
	[HideInInspector] _ZWrite("__zw", Float) = 1.0
	[HideInInspector] _Cull("__cull", Float) = 2.0
	// Internal
	[HideInInspector] _INTR_AnisoType("", Int) = 0
	[HideInInspector] _INTR_SSSType("", Int) = 0
	[HideInInspector] _INTR_RoughRange("", Int) = 0
	[HideInInspector] _INTR_MatType("", Int) = 0
}
*/

//////////////////////////////////////////////
// ֧�ֵı���
/*
�ֲ���
_NORMALMAP
_L_IBL_DIFF_GLOBAL_URP _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
_L_IBL_SPEC_GLOBAL_URP _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP
_L_ROUGHNESS_RANGE_ON
_L_SSS_ON
_L_ANISO_ON
_L_AO_ON
_L_EMISSIVE_ON

ȫ�֣�
_G_DEBUG_ACTOR_ON
*/


//////////////////////////////////////////////
// �ֲ��궨��
#if defined(_NORMALMAP) || defined(_L_ANISO_ON)
#define NEED_TBN 
#endif

//////////////////////////////////////////////
// ��ͼ����
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_MixMap);
SAMPLER(sampler_MixMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

#ifdef _L_ANISO_ON
TEXTURE2D(_AnisotropicMap);
SAMPLER(sampler_AnisotropicMap);
#endif

//////////////////////////////////////////////
// ��������
CBUFFER_START(UnityPerMaterial)
// _L_SSS_ON
half _SSS_Factor;
// _L_ANISO_ON
half _AnisoShiftOffset;
half _AnisoShiftScale;
// _L_ROUGHNESS_RANGE_ON
half _RoughnessLow;
half _RoughnessHigh;
// _L_AO_ON
half _AO_Bias;
// _L_EMISSIVE_ON
half _EmissiveIntensity;
// _L_IBL_SPEC_LOCAL_SPHERE_MAP
// _L_IBL_SPEC_LOCAL_CUBE_MAP
DECLARE_IBL_SPEC_HDR;
// ����
//half3 _EnvShadowColor;
//half _EnvBrightness;


CBUFFER_END

//////////////////////////////////////////////
// ȫ������



//////////////////////////////////////////////
// ������������
struct Attributes
{
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
#ifdef NEED_TBN
	float4 tangentOS	: TANGENT;
#endif
	float2 uv           : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//////////////////////////////////////////////
// ƬԪ��������
struct Varyings
{
	float4 positionCS               : SV_POSITION;
	float2 uv                       : TEXCOORD0;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	float3 positionWS               : TEXCOORD2;
#endif

#ifdef NEED_TBN
	float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
	float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
	float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
	float3 normalWS                 : TEXCOORD3;
	float3 viewDirWS                : TEXCOORD4;
#endif
	half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	float4 shadowCoord              : TEXCOORD7;
#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};


//////////////////////////////////////////////
// ��ƬԪ�л�ȡSurface����
GS_SurfaceData GetGSSurfaceData(float2 uv)
{
	GS_SurfaceData outSurfaceData = (GS_SurfaceData)0;

	half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
	half4 albedoAndAlpha = G2L(baseColor);
	outSurfaceData.albedo = albedoAndAlpha.rgb;
#if _L_EMISSIVE_ON
	// �����Է���ĵط�͸����һ��Ϊ1����ʾ�Է��ⲻ�����ڰ�͸���ĵط�
	// Alphaͨ��ֻȡ0-0.5֮���ֵӳ��Ϊ0-1��ֵ
	half alpha = saturate(albedoAndAlpha.a * 2.0);
	outSurfaceData.alpha = GetSurfaceAlpha(alpha, 0.5);
#else
	outSurfaceData.alpha = GetSurfaceAlpha(albedoAndAlpha.a, 0.5);
#endif

	half3 mixColor = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv).rgb;
#ifdef _L_ROUGHNESS_RANGE_ON
	outSurfaceData.roughness = lerp(_RoughnessLow, _RoughnessHigh, mixColor.b);
#else
	outSurfaceData.roughness = mixColor.b;
#endif
	outSurfaceData.metallic = mixColor.r;

#ifdef _L_SSS_ON
	// remap -1��1 ��ȥ��-1��0��ֵ����ȥ��ԭͼ0-0.5��ֵ��ȡ0.5-1ӳ�䵽0-1��
	outSurfaceData.subsurface = saturate((mixColor.g * 2) - 1) * _SSS_Factor;
#else
	outSurfaceData.subsurface = 0.0;
#endif

	half3 anisotropicColor = 0;
#ifdef _L_ANISO_ON
	half anisotropicMask = step(mixColor.g, 0.25);
	outSurfaceData.anisotropy = anisotropicMask;
	anisotropicColor = SAMPLE_TEXTURE2D(_AnisotropicMap, sampler_AnisotropicMap, uv).rgb;
	outSurfaceData.anisotropicTS = UnpackNormalRG(anisotropicColor.rg, 0);
	// anisotropicColor.b - 0.5 ��˼�Ǵ�0-1 remap�� -0.5 �� 0.5
	outSurfaceData.anisoSpecularShift = _AnisoShiftOffset + ((anisotropicColor.b - 0.5) * _AnisoShiftScale);
#else
	outSurfaceData.anisotropy = 0.0;
#endif

	// ��ɫ�����з���
	half4 normalColor = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
	outSurfaceData.normalTS = UnpackNormalRG(normalColor.rg);

	// AO
#ifdef _L_AO_ON
	outSurfaceData.occlusion = normalColor.b;
#else
	outSurfaceData.occlusion = 1;
#endif

	// �Է���
#ifdef _L_EMISSIVE_ON
	// Alphaͨ��ֻȡ0.5-1֮���ֵӳ��Ϊ0-1��ֵ
	half emissiveMask = saturate(albedoAndAlpha.a - 0.5) * 2.0;
	outSurfaceData.emission = emissiveMask * _EmissiveIntensity * albedoAndAlpha.rgb;
#else
	outSurfaceData.emission = 0;
#endif

	// ����
	DEBUG(DEBUGACTOR_MODE_ALBEDO, outSurfaceData.albedo);
	DEBUG_HEAT01(DEBUGACTOR_MODE_METALLIC, outSurfaceData.metallic);
	DEBUG_HEAT01(DEBUGACTOR_MODE_ROUGHNESS, outSurfaceData.roughness);
	DEBUG_HEAT01(DEBUGACTOR_MODE_AO, outSurfaceData.occlusion);
	DEBUG_HEAT(DEBUGACTOR_MODE_EMISSIVE, outSurfaceData.emission);
	DEBUG_HEAT01(DEBUGACTOR_MODE_SUBSURFACE, outSurfaceData.subsurface);
	DEBUG_HEAT01(DEBUGACTOR_MODE_ANISOTROPY, outSurfaceData.anisotropy);
	DEBUG(DEBUGACTOR_MODE_NORMALMAP, outSurfaceData.normalTS * 0.5 + 0.5);
	DEBUG(DEBUGACTOR_MODE_ANISO_TANGENT, outSurfaceData.anisotropicTS * 0.5 + 0.5);
	DEBUG(DEBUGACTOR_MODE_ANISO_SHIFT, anisotropicColor.b);
	DEBUG(DEBUGACTOR_MODE_PBR_DIFFUSE_VALID, PBR_DiffuseColorValidate(outSurfaceData));
	DEBUG(DEBUGACTOR_MODE_PBR_SPECULAR_VALID, PBR_SpecularColorValidate(outSurfaceData));
	return outSurfaceData;
}

//////////////////////////////////////////////
// ��ƬԪ�л�ȡURP����
GS_InputData GetGSInputData(Varyings vertexOutput, GS_SurfaceData surfaceData)
{
	GS_InputData outInputData = (GS_InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	outInputData.positionWS = vertexOutput.positionWS;
#endif

#ifdef NEED_TBN
	half3x3 TBN_Matrix = half3x3(vertexOutput.tangentWS.xyz, vertexOutput.bitangentWS.xyz, vertexOutput.normalWS.xyz);
	half3 viewDirWS = half3(vertexOutput.normalWS.w, vertexOutput.tangentWS.w, vertexOutput.bitangentWS.w);
#else
	half3 viewDirWS = vertexOutput.viewDirWS;
#endif
	// ��һ��
	viewDirWS = SafeNormalize(viewDirWS);
	outInputData.viewDirectionWS = viewDirWS;

#ifdef _NORMALMAP
	outInputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, TBN_Matrix);
#else
	outInputData.normalWS = vertexOutput.normalWS;
#endif
	// ��һ��
	outInputData.normalWS = NormalizeNormalPerPixel(outInputData.normalWS);
#ifdef _NORMALMAP
	outInputData.tangentWS = Orthonormalize(vertexOutput.tangentWS.xyz, outInputData.normalWS);
	outInputData.bitangentWS = cross(outInputData.tangentWS, outInputData.normalWS);
#else
	outInputData.tangentWS = GS_DEFAULT_TANGENT;
	outInputData.bitangentWS = GS_DEFAULT_BITANGENT;
#endif

#ifdef _L_ANISO_ON
	outInputData.anisotropicWS = TransformTangentToWorld(surfaceData.anisotropicTS, TBN_Matrix);
	outInputData.anisotropicWS = normalize(outInputData.anisotropicWS);
#endif


#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	outInputData.shadowCoord = vertexOutput.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
	outInputData.shadowCoord = TransformWorldToShadowCoord(outInputData.positionWS);
#else
	outInputData.shadowCoord = float4(0, 0, 0, 0);
#endif

	outInputData.fogCoord = vertexOutput.fogFactorAndVertexLight.x;
	outInputData.vertexLighting = vertexOutput.fogFactorAndVertexLight.yzw;

	// ����
	DEBUG(DEBUGACTOR_MODE_MODEL_NORMAL_WORLD, normalize(vertexOutput.normalWS.xyz) * 0.5 + 0.5);
	DEBUG(DEBUGACTOR_MODE_NORMAL_WORLD, outInputData.normalWS.xyz * 0.5 + 0.5);
	return outInputData;
}

//////////////////////////////////////////////
// ��ƬԪ�л�ȡEnvironment����

GS_EnvData GetGSEnvData(Varyings vertexOutput, Light light, GS_InputData inputData, GS_BRDFData brdfData, BxDFContext bxdfContext)
{
	GS_EnvData outEnvData = (GS_EnvData)0;

	outEnvData.envIrradiance = CALC_DIFFUSE_IRRADIANCE(vertexOutput.lightmapUV, vertexOutput.vertexSH, inputData.normalWS);
	// ���Unity GI
	URP_MixRealtimeAndBakedGI(light, bxdfContext, outEnvData.envIrradiance);

	outEnvData.envReflection = CalcGlossyEnvironmentReflection(bxdfContext.R, brdfData.perceptualRoughness);
	//outEnvData.envShadowColor = _EnvShadowColor;
	//outEnvData.envBrightness = _EnvBrightness;
	outEnvData.envBrightness = 1;

	// ����
	DEBUG_HEAT(DEBUGACTOR_MODE_BAKED_GI, outEnvData.envIrradiance);
	DEBUG_HEAT(DEBUGACTOR_MODE_IBL_SPECULAR, outEnvData.envReflection);
	return outEnvData;
}

//////////////////////////////////////////////
// ��ɫ����
struct ActorData
{
	half skin;
};

//////////////////////////////////////////////
// ��ý�ɫ����
ActorData GetActorData(Varyings vertexOutput)
{
	ActorData actorData = (ActorData)0;
	return actorData;
}

//////////////////////////////////////////////
// ֱ�ӹ���ɫ���� 
half3 CalcDirectLighting(GS_BRDFData brdfData, BxDFContext bxdfContext, Light light, ActorData actorData)
{
	// ԭPBRʵ�� 
	half3 radiance = CalcDirectRadiance(brdfData, bxdfContext, light);
	half3 brdf = CalcDirectBRDF(brdfData, bxdfContext);

	// ����
	DEBUG_HEAT(DEBUGACTOR_MODE_BRDF, brdf);
	DEBUG_HEAT(DEBUGACTOR_MODE_RADIANCE, radiance);
	return brdf * radiance;
}

//////////////////////////////////////////////
// Ӧ��AOƫ��
void ApplyAOBias(inout half ao, half ao_bias, half NoV)
{
	// ���������ߵĵط�AOԽ������
	half ao_new = lerp(1.0, ao, NoV);
	// (2 * saturate(0.5 - AO)) * ao_bias
	// �ֶκ�����
	// AO(0.5��1) ��ԶΪ0
	// AO(0��0.5) AO_slider��0���Ա仯
	half k = (2.0 * saturate(0.5 - ao)) * ao_bias;
	// Խ�ڵĵط����û�ԭ���ĺڶȣ���ǳ�ĵط�����������߼���AO��Խ��grazing�Ƕ�Խǳ
	ao = lerp(ao_new, ao, k);
}

//////////////////////////////////////////////
// ���㺯��
Varyings LitPassVertex(Attributes input)
{
	Varyings output = (Varyings)0;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
#ifdef NEED_TBN
	VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
#else
	VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
#endif
	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	// Ĭ��ʵ����Lambert����
	half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
	half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

	output.uv = input.uv;

#ifdef NEED_TBN
	output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
	output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
	output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
	output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
	output.viewDirWS = viewDirWS;
#endif

	OUTPUT_DIFFUSE_IRRADIANCE(output.normalWS.xyz, output.vertexSH);

	output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	// ǰ��_ADDITIONAL_LIGHTS �� _MAIN_LIGHT_SHADOWS_CASCADE
	output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	output.shadowCoord = GetShadowCoord(vertexInput);
#endif
	output.positionCS = vertexInput.positionCS;
	return output;
}



//////////////////////////////////////////////
// ƬԪ����
half4 LitPassFragment(Varyings vertexOutput) : SV_Target
{
	// ׼������
	GS_SurfaceData surfaceData = GetGSSurfaceData(vertexOutput.uv);
	GS_BRDFData brdfData = GetBRDFData(surfaceData);
	GS_InputData inputData = GetGSInputData(vertexOutput, surfaceData);
	Light mainLight = GetMainLight(inputData.shadowCoord);
	BxDFContext bxdfContext = GetBxDFContext(inputData, mainLight);
	ActorData actorData = GetActorData(vertexOutput);
	FillMaterialSSS(brdfData, bxdfContext);
	FillMaterialAnisotropy(brdfData, bxdfContext, inputData.normalWS, inputData.anisotropicWS);
	GS_EnvData envData = GetGSEnvData(vertexOutput, mainLight, inputData, brdfData, bxdfContext);
	ApplyAOBias(surfaceData.occlusion, _AO_Bias, bxdfContext.NoV);

	half3 color = 0;
	// �ռ����м�ӹ�
	half3 gi = CalcGlobalIllumination(envData, brdfData, bxdfContext, surfaceData.occlusion);
	// ����
	DEBUG_HEAT(DEBUGACTOR_MODE_GI, gi);
	DEBUG_HEAT(DEBUGACTOR_MODE_ENV_BRDF, DEBUG_GetEnvBRDF);
	color += gi;

	// һ��Ҫ�����ڼ���Env֮��ֱ���֮ǰ
	ClampRoughnessByDefault(brdfData);

	// ֱ�ӹ�
	half3 directDirectional = CalcDirectLighting(brdfData, bxdfContext, mainLight, actorData);
	// ����
	DEBUG_HEAT(DEBUGACTOR_MODE_DIRECT_DIRECTIONAL, directDirectional);
	color += directDirectional;


	// ��̬���Դ
	half3 additionalLights = 0;
#ifdef _ADDITIONAL_LIGHTS
	uint pixelLightCount = GetAdditionalLightsCount();
	for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
	{
		Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
		BxDFContext additionalBxDFContext = GetBxDFContext(inputData, light);
		additionalLights += CalcDirectLighting(brdfData, additionalBxDFContext, light, actorData);
	}
#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
	additionalLights = inputData.vertexLighting * brdfData.diffuse;
#endif
	// ����
	DEBUG_HEAT(DEBUGACTOR_MODE_ADDITIONAL_LIGHTS, additionalLights);
	color += additionalLights;

	// Ӧ���Է���
	color = MixEmission(color, surfaceData);

	// Ӧ����ɫ
	color = MixFog(color, inputData.fogCoord);

	color = L2G(color);

	half alpha = surfaceData.alpha;

	DEBUG(DEBUGACTOR_MODE_HDR_HEATMAP, FasleColorRemapHeat(color.rgb));
	return OUTPUT(half4(color.rgb, alpha));
}



#endif