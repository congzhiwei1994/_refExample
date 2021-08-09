#ifndef GSTORE_LIGHTING_INCLUDED
#define GSTORE_LIGHTING_INCLUDED

// ========================= ��̬���ض��� =========================
// ��̬���أ�
// ��Shader��ֱ��ʹ��#define�����ã�������Keyword����ʹ��multi_compile��shader_feature�������ı��岻һ����
// ʹ�ÿ�����Shader�����ϻ������ͬ�ķ�֧��
//
// Ŀ��:
// 1.Ч�����أ��������ɶ��Ч��Shader�����ô��롣
// 2.�Ż����أ��Ż����ؾ����л�һЩ�������ﵽ�Ż�Ŀ�ġ�
//
// ��;��
// 1.�ڲ�ͬ��Shader�У��л�Ч����
// 2.��ͬһShader�У����ֲ�ͬ��LOD��

// ========================= ��̬���ض��� =========================
// ��̬���أ�
// ʹ��multi_compile��shader_feature��������Keyword������Keyword��ϲ������塣
// ʹ�ÿ�����Shader�����ϻ������ͬ�ķ�֧��
//
// Ŀ��:
// 1.Ч�����أ��������ɶ��Ч��Shader�����ô��롣
// 2.�Ż����أ��Ż����ؾ����л�һЩ�������ﵽ�Ż�Ŀ�ġ�
//
// ��;��
// 1.�ڲ�ͬ��Shader�У��л�Ч����


// �����÷�ʽ������:
// 1.��̬���ã�
// 2.��̬���ã���Shader��ʹ��multi_compile��shader_feature������(���ֻ��������)

/*

///////////////////////////////////////////////////////////////
����Unity ��IBL-Diffuse
���ڸ������Ϣ���Բο�Unity�ĵ���"Light Probes: Technical information"��

///////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////
����Unity ��IBL HDR��ʽ

- Reflection Probe�決��
* �決������ͼ��������FilterModeΪTrilinear��
* HDR��ʽ�����ļ�Ϊ��EXR������HDR��ʽ�����ļ�Ϊ��PNG����
* ���ɵ���ͼ������Unity Cubemapˮƽ6��ͼ�Ĺ淶���档
* ���Ǽ�������IBL-Specular�У�����ConvolutionType��������Ϊ��Specular(Glossy Reflection)����
��Androidƽ̨��
* EXR��ʽCubeĬ�ϱ���Ϊ"RGB Compressed ETC UNorm dLDR encoded"
* PNG��ʽCubeĬ�ϱ���Ϊ"RGB Compressed ETC UNorm"
��iOSƽ̨��
* EXR��ʽCubeĬ�ϱ���Ϊ"RGB Compressed PVRTC 4BPP UNorm dLDR encoded"
* PNG��ʽCubeĬ�ϱ���Ϊ"RGB Compressed PVRTC 4BPP UNorm"
�������飬Unity�����ƶ�ƽ̨����ʹ��dLDR������HDR��ͼ������HDR��ͼ��Ҫʹ��DecodeHDREnvironment�����롣

- ��Built-in Shader�����¶��壺
* UNITY_NO_RGBM                - no RGBM support, so doubleLDR
* UNITY_LIGHTMAP_DLDR_ENCODING
* UNITY_LIGHTMAP_RGBM_ENCODING
* UNITY_LIGHTMAP_FULL_HDR

- ����decodeInstructions��
* decodeInstructions.x contains 2.0 when gamma color space is used or pow(2.0, 2.2) = 4.59 when linear color space is used on mobile platforms

- ����Double Low Dynamic Range (dLDR) encoding��
dLDR encoding is used on mobile platforms by simply mapping a range of [0, 2] to [0, 1].
Baked light intensities that are above a value of 2 will be clamped. 
The decoding value is computed by multiplying the value from the lightmap texture by 2 when gamma space is used, or 4.59482(22.2) when linear space is used. 
Some platforms store lightmaps as dLDR because their hardware compression produces poor-looking artifacts when using RGBM.

Note: When encoding is used, the values stored in the lightmaps (GPU texture memory) are always in Gamma Color Space.

���ڸ����HDR��Ϣ���Բο�Unity�ĵ�����Lightmaps-TechnicalInformation����

- URP�н�ѹHDR:
real3 DecodeHDREnvironment(real4 encodedIrradiance, real4 decodeInstructions)
{
	// Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
	real alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);

	// If Linear mode is not supported we can skip exponent part
	return (decodeInstructions.x * PositivePow(alpha, decodeInstructions.y)) * encodedIrradiance.rgb;
}

///////////////////////////////////////////////////////////////
*/


#include "BSDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// ע�⣺���ﲻҪ����GS_InputData��GS_SurfaceData!!!!!!

// Use the parametrization of Sony Imageworks.
// Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
void ClampRoughness(inout GS_BRDFData brdfData, real minRoughness)
{
	brdfData.roughnessT = max(minRoughness, brdfData.roughnessT);
	brdfData.roughnessB = max(minRoughness, brdfData.roughnessB);
	//brdfData.coatRoughness = max(minRoughness, brdfData.coatRoughness);
}
void ClampRoughnessByDefault(inout GS_BRDFData brdfData)
{
	ClampRoughness(brdfData, 0.001);
}


// SSS ���յ���
void FillMaterialSSS(GS_BRDFData brdfData, inout BxDFContext bxdfContext)
{
	real NoL_01_wrap = Sq(GreenWrap_Simple(bxdfContext.NoL, 0.45));
	bxdfContext.NoL_01 = lerp(bxdfContext.NoL_01, NoL_01_wrap, brdfData.subsurface);
}

// Anisotropic ��������
void FillMaterialAnisotropy(GS_BRDFData brdfData, inout BxDFContext bxdfContext, real3 normalWS, real3 anisotropicWS)
{
	// ���ŷ��߷������Tangent����
	float3 T = ShiftTangent(anisotropicWS, normalWS, brdfData.anisoSpecularShift);
	real ToH = saturate(dot(T, bxdfContext.H));
	real aniso = max(0.0, sin(ToH * PI));
	bxdfContext.NoH = lerp(bxdfContext.NoH, aniso, brdfData.anisotropy);
}


// ����ֱ�ӹ�ķ���
real3 CalcDirectRadiance(GS_BRDFData brdfData, BxDFContext bxdfContext, Light light)
{
	real3 lightColor = light.color;
	// TODO: ʲô����?
	real lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

	// ԭPBRʵ�� 
	//half3 radiance = lightColor * (lightAttenuation * bxdfContext.NoL_01);
	
	// SSSʵ��
	real unknowSSS_1 = smoothstep(0.51, 0.0, bxdfContext.NoL_01 * 0.5);
	real sssNoL = 1 - lerp(saturate(bxdfContext.NoL), saturate(-bxdfContext.NoL), 0.61);
	real sssNoL_01_wrap = GreenWrap_Simple(sssNoL, -0.47);
	real3 sssResult = sssNoL_01_wrap * unknowSSS_1 * brdfData.sssColor * 0.705;

	real3 radiance = lightColor * lightAttenuation * (bxdfContext.NoL_01 + sssResult);
	return radiance;
}


// ������չ�ʽ��BRDF����
real3 CalcDirectBRDF(GS_BRDFData brdfData, BxDFContext bxdfContext)
{
	// ��ʽ:
	// f(l,v) = diffuse + D(h)*F(d)*G(v,l) / 4*cos(l)*cos(v)


	// Diffuse����
#if 0
	// ����Disneyԭ���BRDF
	// ref: https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf

	// ֻ���������ӽ�ʱ��Ч�����������ⲻ��
	real diffTerm = DisneyDiffuseNoPI(bxdfContext.NoV_abs01, bxdfContext.NoL_01, bxdfContext.VoL, brdfData.perceptualRoughness);

	// Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
	// 1.25 scale is used to (roughly) preserve albedo
	// Fss90 used to "flatten" retroreflection based on roughness
	real Fss90 = bxdfContext.LoH * bxdfContext.LoH * brdfData.perceptualRoughness;
	real Fss = F_Schlick(1.0, Fss90, bxdfContext.NoL_01) * F_Schlick(1.0, Fss90, bxdfContext.NoV_01);
	real ss = 1.25 * (Fss * (1 / (bxdfContext.NoL_01 + bxdfContext.NoV_01) - 0.5) + 0.5);
	
	diffTerm = lerp(diffTerm, ss, brdfData.subsurface);
#else
	real diffTerm = LambertNoPI();
#endif
	

	// Specular����
#if 0
#elif 0
	// ���߶˰汾
	real Vis = V_SmithJointGGX(bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real D = D_GGX_Visible_NoPI(bxdfContext.NoH, bxdfContext.NoV_abs01, bxdfContext.VoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// �߶˰汾
	// ���ƽ���������ӽǱ��ֱ�ḻ�����ƽ������һ��
	// SmithJointGGX
	real D_Vis = DV_SmithJointGGX_NoPI(bxdfContext.NoH, bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D_Vis * F;
#elif 1
	// �ж˰汾
	// ���ƽ���������ӽǱ��ֱ�ḻ
	real Vis = V_SmithJointGGXApprox(bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// �򻯰汾
	// ���ƽ������һ��
	real Vis = V_Implicit();
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// �����򣺸������԰汾
	real D_Vis = DV_SmithJointGGXAniso_NoPI(bxdfContext.ToH, bxdfContext.BoH, bxdfContext.NoH,
		bxdfContext.ToV, bxdfContext.BoV, bxdfContext.NoV_abs01,
		bxdfContext.ToL, bxdfContext.BoL, bxdfContext.NoL_abs01,
		brdfData.roughnessT, brdfData.roughnessB);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D_Vis * F;
#elif 0
	// ����Disneyԭ���BRDF
	// ref: https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf

	// anisotropic 0 to 1
	// (0 <= anisotropy <= 1), therefore (0 <= anisoAspect <= 1)
	// The 0.9 factor limits the aspect ratio to 10:1.
	real anisoAspect = sqrt(1.0 - 0.9 * brdfData.anisotropy);
	real roughnessT = brdfData.perceptualRoughness / anisoAspect; // Distort along tangent (rougher)
	real roughnessB = brdfData.perceptualRoughness * anisoAspect; // Straighten along bitangent (smoother)

	// D: GTR2_aniso
	// G: smithG_GGX_aniso
	real D = D_Burley_GGXAniso_NoPI(bxdfContext.NoH, bxdfContext.ToH, bxdfContext.BoH, roughnessT, roughnessB);
	real Vis = V_Burley_SmithG_GGXAniso(bxdfContext.NoV_01, bxdfContext.ToV, bxdfContext.BoV,
		bxdfContext.NoL_01, bxdfContext.ToL, bxdfContext.BoL,
		roughnessT, roughnessB);
;	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// ƽ����
	real Vis = V_PAJ_Schlick(brdfData.perceptualRoughness, bxdfContext.NoV_01, bxdfContext.NoL_01);
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#else
	// Unity URPʵ��
	// ��Ա�ƽ�����Ļ���һ�㣬λ�û���һ��(׼ȷ�Ա�ƽ������)
	float NoH = bxdfContext.NoH;
	real LoH = bxdfContext.LoH;
	float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
	real LoH2 = LoH * LoH;
	real specularFactor = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
	real3 specularTerm = brdfData.specularColor * specularFactor;
#endif
	
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
	specularTerm = specularTerm - HALF_MIN;
	specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif
	
	return (brdfData.diffuseColor * diffTerm) + specularTerm;
}



/////////////////////////////////////////////////////
// Diffuse Environment Irradiance
// ��Ϊ������ǵ�Ƶ���գ����Բ���ҪHDR
// �������ͼӦ����Linear�ռ��µ�

// ����
// #pragma multi_compile_local _L_IBL_DIFF_GLOBAL_URP _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
#if defined(_L_IBL_DIFF_LOCAL_SPHERE_MAP)
TEXTURE2D(_IrradianceMap_2D);
SAMPLER(sampler_IrradianceMap_2D);
#elif defined(_L_IBL_DIFF_LOCAL_CUBE_MAP)
TEXTURECUBE(_IrradianceMap_Cube);
SAMPLER(sampler_IrradianceMap_Cube);
#endif

// Shader�з���UnityPerMaterial�еı���(Ϊ�˼���SRP Batcher)
//#define DECLARE_IBL_DIFF_HDR  real4 _IrradianceMap_2D_HDR; real4 _IrradianceMap_Cube_HDR
// ��������ʱ����
//#define	PARAM_IBL_DIFF_HDR(irr2D_HDR, irrCube_HDR) real4 irr2D_HDR, real4 irrCube_HDR
// ����ʱ�������
//#define ARGS_IBL_DIFF_HDR _IrradianceMap_2D_HDR, _IrradianceMap_Cube_HDR

// �ڶ��㺯���е���
#if defined(_L_IBL_DIFF_GLOBAL_URP)
#define OUTPUT_DIFFUSE_IRRADIANCE(normalWS, OUT) OUTPUT_SH(normalWS, OUT)
#else
#define OUTPUT_DIFFUSE_IRRADIANCE(normalWS, OUT)
#endif

// ��ƬԪ�����е���
#if defined(_L_IBL_DIFF_GLOBAL_URP)
#define CALC_DIFFUSE_IRRADIANCE(lmName, shName, normalWSName) SAMPLE_GI(lmName, shName, normalWSName)
#else
#define CALC_DIFFUSE_IRRADIANCE(lmName, shName, normalWSName) CalcDiffuseEnvironmentIrradiance(normalWSName)
#endif

// ��Mirrored Ball (Spheremap)���в���
half3 CalcDiffuseEnvironmentIrradiance_2D(TEXTURE2D_PARAM(irradianceMap_2D, sampler_irradianceMap_2D), half3 normalWS)
{
	float2 uv = GetShpericalCoord(normalWS);
	half4 encodedIrradiance = SAMPLE_TEXTURE2D(irradianceMap_2D, sampler_irradianceMap_2D, uv);
//#if !defined(UNITY_USE_NATIVE_HDR)
//	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, decode_irradianceMap_2D);
//#else
//	half3 irradiance = encodedIrradiance.rgb;
//#endif
	half3 irradiance = encodedIrradiance.rgb;
	return irradiance;
}

half3 CalcDiffuseEnvironmentIrradiance_CUBE(TEXTURECUBE_PARAM(irradianceMap_Cube, sampler_irradianceMap_Cube), half3 normalWS)
{
	half4 encodedIrradiance = SAMPLE_TEXTURECUBE(irradianceMap_Cube, sampler_irradianceMap_Cube, normalWS);
//#if !defined(UNITY_USE_NATIVE_HDR)
//	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, decode_irradianceMap_Cube);
//#else
//	half3 irradiance = encodedIrradiance.rgb;
//#endif
	half3 irradiance = encodedIrradiance.rgb;
	return irradiance;
}

// ���һ�������Կռ����ɫ
//#define CalcDiffuseEnvironmentIrradiance(normalWS) CalcDiffuseEnvironmentIrradiance_All(normalWS, ARGS_IBL_DIFF_HDR)
half3 CalcDiffuseEnvironmentIrradiance(half3 normalWS)
{
#if defined(_L_IBL_DIFF_LOCAL_SPHERE_MAP)
	half3 irradiance = CalcDiffuseEnvironmentIrradiance_2D(_IrradianceMap_2D, sampler_IrradianceMap_2D, normalWS);
#elif defined(_L_IBL_DIFF_LOCAL_CUBE_MAP)
	half3 irradiance = CalcDiffuseEnvironmentIrradiance_CUBE(_IrradianceMap_Cube, sampler_IrradianceMap_Cube, normalWS);
#else
	half3 irradiance = 0;
#endif
	return irradiance;
}



/////////////////////////////////////////////////////
// Glossy Environment Reflection
// ��Ϊ���и�Ƶ������Ϣ��������Ҫ����HDR
// �������ͼӦ����Linear�ռ��µ�

// ����
// #pragma multi_compile_local _L_IBL_SPEC_GLOBAL_URP _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP
#if defined(_L_IBL_SPEC_LOCAL_SPHERE_MAP)
TEXTURE2D(_EnvironmentMap_2D);
SAMPLER(sampler_EnvironmentMap_2D);
#elif defined(_L_IBL_SPEC_LOCAL_CUBE_MAP)
TEXTURECUBE(_EnvironmentMap_Cube);
SAMPLER(sampler_EnvironmentMap_Cube);
#endif

// Shader�з���UnityPerMaterial�еı���(Ϊ�˼���SRP Batcher)
#define DECLARE_IBL_SPEC_HDR  real4 _EnvironmentMap_2D_HDR; real4 _EnvironmentMap_Cube_HDR
// ��������ʱ����
#define	PARAM_IBL_SPEC_HDR(env2D_HDR, envCube_HDR) real4 env2D_HDR, real4 envCube_HDR
// ����ʱ�������
#define ARGS_IBL_SPEC_HDR _EnvironmentMap_2D_HDR, _EnvironmentMap_Cube_HDR

// ��Mirrored Ball (Spheremap)���в���
half3 CalcGlossyEnvironmentReflection_2D(TEXTURE2D_HDR_PARAM(environmentMap_2D, sampler_environmentMap_2D, decode_environmentMap_2D), half3 reflectVector, half perceptualRoughness)
{
#if 0
	half mip = 0;
#elif 1
	half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
#elif 0
	// 0-7
	half mip = perceptualRoughness / 0.14;
#endif
	float2 uv = GetShpericalCoord(reflectVector);
	half4 encodedIrradiance = SAMPLE_TEXTURE2D_LOD(environmentMap_2D, sampler_environmentMap_2D, uv, mip);
#if !defined(UNITY_USE_NATIVE_HDR)
	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, decode_environmentMap_2D);
#else
	half3 irradiance = encodedIrradiance.rgb;
#endif
	// ƽ����������
	//half3 irradiance = encodedIrradiance.rgb * encodedIrradiance.a * 130;
	return irradiance;
}

half3 CalcGlossyEnvironmentReflection_CUBE(TEXTURECUBE_HDR_PARAM(environmentMap_Cube, sampler_environmentMap_Cube, decode_environmentMap_Cube), half3 reflectVector, half perceptualRoughness)
{
	half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
	half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(environmentMap_Cube, sampler_environmentMap_Cube, reflectVector, mip);
#if !defined(UNITY_USE_NATIVE_HDR)
	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, decode_environmentMap_Cube);
#else
	half3 irradiance = encodedIrradiance.rgb;
#endif
	return irradiance;
}

// ��Դ: URP
// Unity URP��׼����
half3 CalcGlossyEnvironmentReflection_Unity(half3 reflectVector, half perceptualRoughness)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
	half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
	half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

#if !defined(UNITY_USE_NATIVE_HDR)
	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#else
	half3 irradiance = encodedIrradiance.rgb;
#endif

	return irradiance;
#endif // GLOSSY_REFLECTIONS

	return _GlossyEnvironmentColor.rgb;
}


#define CalcGlossyEnvironmentReflection(reflectVector, perceptualRoughness) CalcGlossyEnvironmentReflection_All(reflectVector, perceptualRoughness, ARGS_IBL_SPEC_HDR)
half3 CalcGlossyEnvironmentReflection_All(half3 reflectVector, half perceptualRoughness, PARAM_IBL_SPEC_HDR(env2D_HDR, envCube_HDR))
{
#if defined(_L_IBL_SPEC_GLOBAL_URP)
	half3 irradiance = CalcGlossyEnvironmentReflection_Unity(reflectVector, perceptualRoughness);
#elif defined(_L_IBL_SPEC_LOCAL_SPHERE_MAP)
	half3 irradiance = CalcGlossyEnvironmentReflection_2D(_EnvironmentMap_2D, sampler_EnvironmentMap_2D, env2D_HDR, reflectVector, perceptualRoughness);
#elif defined(_L_IBL_SPEC_LOCAL_CUBE_MAP)
	half3 irradiance = CalcGlossyEnvironmentReflection_CUBE(_EnvironmentMap_Cube, sampler_EnvironmentMap_Cube, envCube_HDR, reflectVector, perceptualRoughness);
#else 
	half3 irradiance = 0;
#endif
	return irradiance;
}

// ����
#ifdef DEBUG_ON
half3 _G_DebugEnvBRDF;

#define DEBUG_SetEnvBRDF(c) _G_DebugEnvBRDF = c
#define DEBUG_GetEnvBRDF _G_DebugEnvBRDF
#else
#define DEBUG_SetEnvBRDF(c) 
#define DEBUG_GetEnvBRDF 0
#endif

half3 CalcGlobalIllumination(GS_EnvData envData, GS_BRDFData brdfData, BxDFContext bxdfContext, half occlusion)
{
	// Diffuse����
#if 0
	// Unity URP ʵ��
	half3 indirectDiffuseTerm = envData.envIrradiance;
#else
	// SSS ��ӹ�
	half3 sssIndirectTerm = (2.0 - bxdfContext.NoV_01) * brdfData.sssColor;
	// �������Diffuse�İ�����ɫ
	half3 indirectDiffuseTerm = (envData.envIrradiance + sssIndirectTerm);
#endif

	// Specular����
	half3 brdf = 0;
#if 1
	// ƽ���� ʵ��
	brdf = EnvBRDFApprox(brdfData.fresnel0, brdfData.perceptualRoughness, bxdfContext.NoV_abs01);
	real3 specularTerm = envData.envReflection * brdf;
#else
	// Unity URP ʵ��
	brdf = EnvBRDF_URP(brdfData.fresnel0, brdfData.roughness2, brdfData.grazingTerm, bxdfContext.fresnelTerm);
	real3 specularTerm = envData.envReflection * brdf;
#endif

	// ���ⲹ�� backlight compensation
	/*half3 BLC = lerp(envShadowColor.rgb, 1.0, bxdfContext.HalfLambert);
	half3 compensation = (indirectDiffuseTerm + specularTerm) * BLC;*/

	// ����
	DEBUG_SetEnvBRDF(brdf);
	return ((brdfData.diffuseColor * indirectDiffuseTerm) + specularTerm) * occlusion * envData.envBrightness;
}




/////////////////////////////////////////////////////////////////////////
// �Է��� ����

half3 MixEmission(real3 fragColor, GS_SurfaceData surfaceData)
{
	return fragColor + surfaceData.emission;
}

/////////////////////////////////////////////////////////////////////////
// AO ����

float specularOcclusionCorrection(float diffuseOcclusion, float metallic, float roughness)
{
	return lerp(diffuseOcclusion, 1.0, metallic * (1.0 - roughness) * (1.0 - roughness));
}



#endif