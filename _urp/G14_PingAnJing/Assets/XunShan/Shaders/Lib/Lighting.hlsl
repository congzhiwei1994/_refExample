#ifndef GSTORE_LIGHTING_INCLUDED
#define GSTORE_LIGHTING_INCLUDED

// ========================= 静态开关定义 =========================
// 静态开关：
// 在Shader里直接使用#define来设置，不产生Keyword，与使用multi_compile或shader_feature来声明的变体不一样。
// 使用开关在Shader代码上会产生不同的分支。
//
// 目的:
// 1.效果开关，方便生成多个效果Shader，重用代码。
// 2.优化开关，优化开关就是切换一些代码来达到优化目的。
//
// 用途：
// 1.在不同的Shader中，切换效果。
// 2.在同一Shader中，区分不同的LOD。

// ========================= 动态开关定义 =========================
// 动态开关：
// 使用multi_compile或shader_feature来声明的Keyword。根据Keyword组合产生变体。
// 使用开关在Shader代码上会产生不同的分支。
//
// 目的:
// 1.效果开关，方便生成多个效果Shader，重用代码。
// 2.优化开关，优化开关就是切换一些代码来达到优化目的。
//
// 用途：
// 1.在不同的Shader中，切换效果。


// 按设置方式分两类:
// 1.静态设置，
// 2.动态设置，在Shader里使用multi_compile或shader_feature来设置(这种会产生变体)

/*

///////////////////////////////////////////////////////////////
关于Unity 的IBL-Diffuse
关于更多的信息可以参考Unity文档："Light Probes: Technical information"。

///////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////
关于Unity 的IBL HDR格式

- Reflection Probe烘焙：
* 烘焙出来的图导入设置FilterMode为Trilinear。
* HDR格式保存文件为“EXR”，非HDR格式保存文件为“PNG”。
* 生成的贴图都是以Unity Cubemap水平6张图的规范保存。
* 都是假设用于IBL-Specular中，所以ConvolutionType都是设置为“Specular(Glossy Reflection)”。
在Android平台：
* EXR格式Cube默认编码为"RGB Compressed ETC UNorm dLDR encoded"
* PNG格式Cube默认编码为"RGB Compressed ETC UNorm"
在iOS平台：
* EXR格式Cube默认编码为"RGB Compressed PVRTC 4BPP UNorm dLDR encoded"
* PNG格式Cube默认编码为"RGB Compressed PVRTC 4BPP UNorm"
经过试验，Unity对于移动平台都是使用dLDR来编码HDR贴图。对于HDR贴图需要使用DecodeHDREnvironment来解码。

- 在Built-in Shader中如下定义：
* UNITY_NO_RGBM                - no RGBM support, so doubleLDR
* UNITY_LIGHTMAP_DLDR_ENCODING
* UNITY_LIGHTMAP_RGBM_ENCODING
* UNITY_LIGHTMAP_FULL_HDR

- 关于decodeInstructions：
* decodeInstructions.x contains 2.0 when gamma color space is used or pow(2.0, 2.2) = 4.59 when linear color space is used on mobile platforms

- 关于Double Low Dynamic Range (dLDR) encoding：
dLDR encoding is used on mobile platforms by simply mapping a range of [0, 2] to [0, 1].
Baked light intensities that are above a value of 2 will be clamped. 
The decoding value is computed by multiplying the value from the lightmap texture by 2 when gamma space is used, or 4.59482(22.2) when linear space is used. 
Some platforms store lightmaps as dLDR because their hardware compression produces poor-looking artifacts when using RGBM.

Note: When encoding is used, the values stored in the lightmaps (GPU texture memory) are always in Gamma Color Space.

关于更多的HDR信息可以参考Unity文档：“Lightmaps-TechnicalInformation”。

- URP中解压HDR:
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

// 注意：这里不要引入GS_InputData或GS_SurfaceData!!!!!!

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


// SSS 光照调整
void FillMaterialSSS(GS_BRDFData brdfData, inout BxDFContext bxdfContext)
{
	real NoL_01_wrap = Sq(GreenWrap_Simple(bxdfContext.NoL, 0.45));
	bxdfContext.NoL_01 = lerp(bxdfContext.NoL_01, NoL_01_wrap, brdfData.subsurface);
}

// Anisotropic 各向异性
void FillMaterialAnisotropy(GS_BRDFData brdfData, inout BxDFContext bxdfContext, real3 normalWS, real3 anisotropicWS)
{
	// 沿着法线方向调整Tangent方向
	float3 T = ShiftTangent(anisotropicWS, normalWS, brdfData.anisoSpecularShift);
	real ToH = saturate(dot(T, bxdfContext.H));
	real aniso = max(0.0, sin(ToH * PI));
	bxdfContext.NoH = lerp(bxdfContext.NoH, aniso, brdfData.anisotropy);
}


// 计算直接光的辐射
real3 CalcDirectRadiance(GS_BRDFData brdfData, BxDFContext bxdfContext, Light light)
{
	real3 lightColor = light.color;
	// TODO: 什么意义?
	real lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

	// 原PBR实现 
	//half3 radiance = lightColor * (lightAttenuation * bxdfContext.NoL_01);
	
	// SSS实现
	real unknowSSS_1 = smoothstep(0.51, 0.0, bxdfContext.NoL_01 * 0.5);
	real sssNoL = 1 - lerp(saturate(bxdfContext.NoL), saturate(-bxdfContext.NoL), 0.61);
	real sssNoL_01_wrap = GreenWrap_Simple(sssNoL, -0.47);
	real3 sssResult = sssNoL_01_wrap * unknowSSS_1 * brdfData.sssColor * 0.705;

	real3 radiance = lightColor * lightAttenuation * (bxdfContext.NoL_01 + sssResult);
	return radiance;
}


// 计算光照公式中BRDF部分
real3 CalcDirectBRDF(GS_BRDFData brdfData, BxDFContext bxdfContext)
{
	// 公式:
	// f(l,v) = diffuse + D(h)*F(d)*G(v,l) / 4*cos(l)*cos(v)


	// Diffuse部分
#if 0
	// 基于Disney原则的BRDF
	// ref: https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf

	// 只是增加在掠角时的效果，几乎留意不到
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
	

	// Specular部分
#if 0
#elif 0
	// 超高端版本
	real Vis = V_SmithJointGGX(bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real D = D_GGX_Visible_NoPI(bxdfContext.NoH, bxdfContext.NoV_abs01, bxdfContext.VoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// 高端版本
	// 相对平安京，在掠角表现表丰富，相对平安京亮一点
	// SmithJointGGX
	real D_Vis = DV_SmithJointGGX_NoPI(bxdfContext.NoH, bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D_Vis * F;
#elif 1
	// 中端版本
	// 相对平安京，在掠角表现表丰富
	real Vis = V_SmithJointGGXApprox(bxdfContext.NoL_abs01, bxdfContext.NoV_01, brdfData.roughness);
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// 简化版本
	// 相对平安京暗一点
	real Vis = V_Implicit();
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#elif 0
	// 试验向：各向异性版本
	real D_Vis = DV_SmithJointGGXAniso_NoPI(bxdfContext.ToH, bxdfContext.BoH, bxdfContext.NoH,
		bxdfContext.ToV, bxdfContext.BoV, bxdfContext.NoV_abs01,
		bxdfContext.ToL, bxdfContext.BoL, bxdfContext.NoL_abs01,
		brdfData.roughnessT, brdfData.roughnessB);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D_Vis * F;
#elif 0
	// 基于Disney原则的BRDF
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
	// 平安京
	real Vis = V_PAJ_Schlick(brdfData.perceptualRoughness, bxdfContext.NoV_01, bxdfContext.NoL_01);
	real D = D_GGXNoPI(bxdfContext.NoH, brdfData.roughness);
	real3 F = F_SchlickByFactor(brdfData.fresnel0, bxdfContext.fresnelTerm);
	real3 specularTerm = D * Vis * F;
#else
	// Unity URP实现
	// 相对比平安京的会亮一点，位置基本一致(准确性比平安京低)
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
// 因为保存的是低频光照，所以不需要HDR
// 输入的贴图应该是Linear空间下的

// 处理：
// #pragma multi_compile_local _L_IBL_DIFF_GLOBAL_URP _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
#if defined(_L_IBL_DIFF_LOCAL_SPHERE_MAP)
TEXTURE2D(_IrradianceMap_2D);
SAMPLER(sampler_IrradianceMap_2D);
#elif defined(_L_IBL_DIFF_LOCAL_CUBE_MAP)
TEXTURECUBE(_IrradianceMap_Cube);
SAMPLER(sampler_IrradianceMap_Cube);
#endif

// Shader中放在UnityPerMaterial中的变量(为了兼容SRP Batcher)
//#define DECLARE_IBL_DIFF_HDR  real4 _IrradianceMap_2D_HDR; real4 _IrradianceMap_Cube_HDR
// 声明函数时参数
//#define	PARAM_IBL_DIFF_HDR(irr2D_HDR, irrCube_HDR) real4 irr2D_HDR, real4 irrCube_HDR
// 调用时传入参数
//#define ARGS_IBL_DIFF_HDR _IrradianceMap_2D_HDR, _IrradianceMap_Cube_HDR

// 在顶点函数中调用
#if defined(_L_IBL_DIFF_GLOBAL_URP)
#define OUTPUT_DIFFUSE_IRRADIANCE(normalWS, OUT) OUTPUT_SH(normalWS, OUT)
#else
#define OUTPUT_DIFFUSE_IRRADIANCE(normalWS, OUT)
#endif

// 在片元函数中调用
#if defined(_L_IBL_DIFF_GLOBAL_URP)
#define CALC_DIFFUSE_IRRADIANCE(lmName, shName, normalWSName) SAMPLE_GI(lmName, shName, normalWSName)
#else
#define CALC_DIFFUSE_IRRADIANCE(lmName, shName, normalWSName) CalcDiffuseEnvironmentIrradiance(normalWSName)
#endif

// 对Mirrored Ball (Spheremap)进行采样
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

// 输出一定是线性空间的颜色
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
// 因为含有高频光照信息，所以需要处理HDR
// 输入的贴图应该是Linear空间下的

// 处理：
// #pragma multi_compile_local _L_IBL_SPEC_GLOBAL_URP _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP
#if defined(_L_IBL_SPEC_LOCAL_SPHERE_MAP)
TEXTURE2D(_EnvironmentMap_2D);
SAMPLER(sampler_EnvironmentMap_2D);
#elif defined(_L_IBL_SPEC_LOCAL_CUBE_MAP)
TEXTURECUBE(_EnvironmentMap_Cube);
SAMPLER(sampler_EnvironmentMap_Cube);
#endif

// Shader中放在UnityPerMaterial中的变量(为了兼容SRP Batcher)
#define DECLARE_IBL_SPEC_HDR  real4 _EnvironmentMap_2D_HDR; real4 _EnvironmentMap_Cube_HDR
// 声明函数时参数
#define	PARAM_IBL_SPEC_HDR(env2D_HDR, envCube_HDR) real4 env2D_HDR, real4 envCube_HDR
// 调用时传入参数
#define ARGS_IBL_SPEC_HDR _EnvironmentMap_2D_HDR, _EnvironmentMap_Cube_HDR

// 对Mirrored Ball (Spheremap)进行采样
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
	// 平安京的做法
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

// 来源: URP
// Unity URP标准处理
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

// 调试
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
	// Diffuse部分
#if 0
	// Unity URP 实现
	half3 indirectDiffuseTerm = envData.envIrradiance;
#else
	// SSS 间接光
	half3 sssIndirectTerm = (2.0 - bxdfContext.NoV_01) * brdfData.sssColor;
	// 调整间接Diffuse的暗部颜色
	half3 indirectDiffuseTerm = (envData.envIrradiance + sssIndirectTerm);
#endif

	// Specular部分
	half3 brdf = 0;
#if 1
	// 平安京 实现
	brdf = EnvBRDFApprox(brdfData.fresnel0, brdfData.perceptualRoughness, bxdfContext.NoV_abs01);
	real3 specularTerm = envData.envReflection * brdf;
#else
	// Unity URP 实现
	brdf = EnvBRDF_URP(brdfData.fresnel0, brdfData.roughness2, brdfData.grazingTerm, bxdfContext.fresnelTerm);
	real3 specularTerm = envData.envReflection * brdf;
#endif

	// 背光补偿 backlight compensation
	/*half3 BLC = lerp(envShadowColor.rgb, 1.0, bxdfContext.HalfLambert);
	half3 compensation = (indirectDiffuseTerm + specularTerm) * BLC;*/

	// 调试
	DEBUG_SetEnvBRDF(brdf);
	return ((brdfData.diffuseColor * indirectDiffuseTerm) + specularTerm) * occlusion * envData.envBrightness;
}




/////////////////////////////////////////////////////////////////////////
// 自发光 部分

half3 MixEmission(real3 fragColor, GS_SurfaceData surfaceData)
{
	return fragColor + surfaceData.emission;
}

/////////////////////////////////////////////////////////////////////////
// AO 部分

float specularOcclusionCorrection(float diffuseOcclusion, float metallic, float roughness)
{
	return lerp(diffuseOcclusion, 1.0, metallic * (1.0 - roughness) * (1.0 - roughness));
}



#endif