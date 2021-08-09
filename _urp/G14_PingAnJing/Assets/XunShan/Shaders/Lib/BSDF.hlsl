#ifndef GSTORE_BSDF_INCLUDED
#define GSTORE_BSDF_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Common.hlsl"
#include "Input.hlsl"


struct GS_BRDFData
{
	// 次表面颜色
	half3 sssColor;
	// 漫反射颜色(散射)
	half3 diffuseColor;
	// 高光颜色
	half3 specularColor;
	// F0 
	half3 fresnel0;
	// 次表面
	half subsurface;
	// roughness in tangent direction
	half roughnessT;
	// roughness in bitangent direction
	half roughnessB;
	// 各向异性Mask
	half anisotropy;
	// 各向异性偏移
	half anisoSpecularShift;

	// 感性粗糙度(美术输入)
	half perceptualRoughness;
	// perceptualRoughness^2
	// Burley 在"Physically Based Shading at Disney"提出的建议，把美术提供的roughness进行平方后使用在NDF
	half roughness;
	// perceptualRoughness^4
	half roughness2;
	// 与金属度近似
	half reflectivity;
	// smoothness + reflectivity
	half grazingTerm;
	


	// We save some light invariant BRDF terms so we don't have to recompute
	// them in the light loop. Take a look at DirectBRDF function for detailed explaination.
	half normalizationTerm;     // roughness * 4.0 + 2.0 符合一个指令MAD
	half roughness2MinusOne;    // roughness^2 - 1.0
};


struct BxDFContext
{
	float NoV;			// -1 to 1
	float NoV_01;		// clamp 0 to 1
	float NoV_abs01;	// abs 0 to 1
	float NoL;			// -1 to 1
	float NoL_01;		// clamp 0 to 1
	float NoL_abs01;	// abs 0 to 1
	float HalfLambert;	// remap 0 to 1
	float VoL;			// -1 to 1
	float NoH;			// clamp 0 to 1
	float VoH;			// clamp 0 to 1
	float LoH;			// clamp 0 to 1
	float3 R;			// normalized
	float3 H;			// half dir
	float fresnelTerm;	// 菲涅而因子(F_Schlick中的 (1.0 - VoH)^5)

	// AnisoBSDF
	float ToH;			// -1 to 1
	float ToL;			// -1 to 1
	float ToV;			// -1 to 1
	float BoH;			// -1 to 1
	float BoL;			// -1 to 1
	float BoV;			// -1 to 1
};


real F_SchlickFactor(real VoH)
{
	real x = 1.0 - VoH;
	real x2 = x * x;
	real x5 = x * x2 * x2;
	return x5;
}


// 备注一些URP的已有实现
/*
###################
URP Lighting.hlsl:

half OneMinusReflectivityMetallic(half metallic)
{
	// We'll need oneMinusReflectivity, so
	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
	// store (1-dielectricSpec) in kDieletricSpec.a, then
	//   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
	//                  = alpha - metallic * alpha
	half oneMinusDielectricSpec = kDieletricSpec.a;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}


##################

###################
CORE CommonMaterial.hlsl:

real PerceptualRoughnessToRoughness(real perceptualRoughness)
{
	return perceptualRoughness * perceptualRoughness;
}

real PerceptualRoughnessToPerceptualSmoothness(real perceptualRoughness)
{
	return (1.0 - perceptualRoughness);
}

###################
*/

//////////////////////////////////////////////////////
// 根据表面输入参数计算BRDF参数
GS_BRDFData GetBRDFData(GS_SurfaceData surfaceData)
{
	GS_BRDFData outBRDFData;
	half3 albedo = surfaceData.albedo;
	half metallic = surfaceData.metallic;
	half roughness = surfaceData.roughness;

	// 计算反射率
	half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
	half reflectivity = 1.0 - oneMinusReflectivity;

	// 计算漫反射与高光颜色
	//outBRDFData.diffuseColor = albedo * oneMinusReflectivity;
	outBRDFData.diffuseColor = ComputeDiffuseColor(albedo, metallic);
	outBRDFData.fresnel0 = lerp(kDieletricSpec.rgb, albedo, metallic);
	outBRDFData.specularColor = outBRDFData.fresnel0;

	// 次表面颜色
	outBRDFData.sssColor = saturate(albedo.rgb - max(Max3(albedo.r, albedo.g, albedo.b) - 0.39, 0.1)) * surfaceData.subsurface;
	outBRDFData.subsurface = surfaceData.subsurface;

	// 各向异性相关
	outBRDFData.anisotropy = surfaceData.anisotropy;
	outBRDFData.anisoSpecularShift = surfaceData.anisoSpecularShift;

	half smoothness = PerceptualRoughnessToPerceptualSmoothness(roughness);
	outBRDFData.reflectivity = reflectivity;
	outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
	outBRDFData.perceptualRoughness = roughness;
	outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
	outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

	outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
	outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;


	// Use the parametrization of Sony Imageworks.
	// Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
	// roughnessT and roughnessB are clamped, and are meant to be used with punctual and directional lights.
	// perceptualRoughness is not clamped, and is meant to be used for IBL.
	ConvertAnisotropyToRoughness(outBRDFData.perceptualRoughness, outBRDFData.anisotropy, outBRDFData.roughnessT, outBRDFData.roughnessB);

	return outBRDFData;
}







// 规范：点乘标记为“XoY”
// 全为世界空间
BxDFContext GetBxDFContext(half3 N, half3 V, half3 L, half3 Tangent, half3 Bitangent)
{
	BxDFContext Context;

	Context.NoV = dot(N, V);
	Context.NoV_01 = max(Context.NoV, 0.0001); // Approximately 0.0057 degree bias
	Context.NoV_abs01 = saturate(abs(Context.NoV) + 1e-5);

	Context.NoL = dot(N, L);
	Context.NoL_01 = saturate(Context.NoL);
	Context.NoL_abs01 = abs(Context.NoL);
	Context.HalfLambert = 0.5 * (1.0 + Context.NoL);
	
	Context.VoL = dot(V, L);
	// invLenLV = rsqrt(max(2.0 * LdotV + 2.0, FLT_EPS));    // invLenLV = rcp(length(L + V)), clamp to avoid rsqrt(0) = inf, inf * 0 = NaN
	float InvLenH = rsqrt(2.0 + 2.0 * Context.VoL);
	Context.NoH = saturate((Context.NoL + Context.NoV) * InvLenH);	// (NoL + NoV) * InvLenH
	Context.VoH = saturate(InvLenH + InvLenH * Context.VoL);		// (VoV + VoL) * InvLenH
	Context.LoH = Context.VoH;
	// Unity的做法
	/*float3 H = SafeNormalize(float3(L) + float3(V));
	Context.NoH = saturate(dot(N, H));
	Context.VoH = saturate(dot(V, H));
	Context.LoH = Context.VoH;*/

	Context.R = reflect(-V, N);
	Context.H = (L + V) * InvLenH;

	Context.fresnelTerm = F_SchlickFactor(Context.VoH);

	Context.ToL = dot(Tangent, L);
	Context.ToV = dot(Tangent, V);
	Context.ToH = (Context.ToV + Context.ToL) * InvLenH;			// (ToV + ToL) * InvLenH
	
	Context.BoL = dot(Bitangent, L);
	Context.BoV = dot(Bitangent, V);
	Context.BoH = (Context.BoV + Context.BoL) * InvLenH;			// (BoV + BoL) * InvLenH


	// Unity的做法 在core CommonLighting.hlsl
	// Ref: "Crafting a Next-Gen Material Pipeline for The Order: 1886".
	//real ClampNdotV(real NdotV)
	//{
	//	return max(NdotV, 0.0001); // Approximately 0.0057 degree bias
	//}

	
	// TODO: 把unreal和Unity做一个ALU对比

	// Unity做法
	// float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));
	// float NoH = saturate(dot(normalWS, halfDir));
	// half LoH = saturate(dot(lightDirectionWS, halfDir));

	// Unity 在core CommonLighting.hlsl中有类似的做法
	// Helper function to return a set of common angle used when evaluating BSDF
	// NdotL and NdotV are unclamped
	//void GetBSDFAngle(real3 V, real3 L, real NdotL, real NdotV,
	//	out real LdotV, out real NdotH, out real LdotH, out real invLenLV)
	//{
	//	// Optimized math. Ref: PBR Diffuse Lighting for GGX + Smith Microsurfaces (slide 114).
	//	LdotV = dot(L, V);
	//	invLenLV = rsqrt(max(2.0 * LdotV + 2.0, FLT_EPS));    // invLenLV = rcp(length(L + V)), clamp to avoid rsqrt(0) = inf, inf * 0 = NaN
	//	NdotH = saturate((NdotL + NdotV) * invLenLV);
	//	LdotH = saturate(invLenLV * LdotV + invLenLV);
	//}

	return Context;
}
BxDFContext GetBxDFContext(GS_InputData urpInput, Light light)
{
	return GetBxDFContext(urpInput.normalWS, urpInput.viewDirectionWS, light.direction, urpInput.tangentWS, urpInput.bitangentWS);
}

//////////////////////////////////////////////////////////////////////////////////
// Diffuse

// GPU Gems1 - 16 次表面散射的实时近似（Real-Time Approximations to Subsurface Scattering）
// Wrap Shading 
// http://www.cim.mcgill.ca/~derek/files/jgt_wrap.pdf
half GreenWrap_Simple(half NoL, half wrap)
{
	return max(0.0, (NoL + wrap)) / (1.0 + wrap);
}

// 来源: UE 4.25 => Diffuse_Burley
// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley_NoPI(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5(1 - NoV);
	float FdL = 1 + (FD90 - 1) * Pow5(1 - NoL);
	return DiffuseColor * (FdV * FdL);
}

// 来源: UE 4.25 => Diffuse_OrenNayar
// [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
float3 Diffuse_OrenNayar_NoPI(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float a = Roughness * Roughness;
	float s = a;// / ( 1.29 + 0.5 * a );
	float s2 = s * s;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
	float C1 = 1 - 0.5 * s2 / (s2 + 0.33);
	float C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * (Cosri >= 0 ? rcp(max(NoL, NoV)) : 1);
	return DiffuseColor / (C1 + C2) * (1 + Roughness * 0.5);
}

// 来源: UE 4.25 => Diffuse_Gotanda
// [Gotanda 2014, "Designing Reflectance Models for New Consoles"]
float3 Diffuse_Gotanda_NoPI(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float F0 = 0.04;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
#if 1
	float a2_13 = a2 + 1.36053;
	float Fr = (1 - (0.542026*a2 + 0.303573*a) / a2_13) * (1 - pow(1 - NoV, 5 - 4 * a2) / a2_13) * ((-0.733996*a2*a + 1.50912*a2 - 1.16402*a) * pow(1 - NoV, 1 + rcp(39 * a2*a2 + 1)) + 1);
	//float Fr = ( 1 - 0.36 * a ) * ( 1 - pow( 1 - NoV, 5 - 4*a2 ) / a2_13 ) * ( -2.5 * Roughness * ( 1 - NoV ) + 1 );
	float Lm = (max(1 - 2 * a, 0) * (1 - Pow5(1 - NoL)) + min(2 * a, 1)) * (1 - 0.5*a * (NoL - 1)) * NoL;
	float Vd = (a2 / ((a2 + 0.09) * (1.31072 + 0.995584 * NoV))) * (1 - pow(1 - NoL, (1 - 0.3726732 * NoV * NoV) / (0.188566 + 0.38841 * NoV)));
	float Bp = Cosri < 0 ? 1.4 * NoV * NoL * Cosri : Cosri;
	float Lr = (21.0 / 20.0) * (1 - F0) * (Fr * Lm + Vd + Bp);
	return DiffuseColor / PI * Lr;
#else
	float a2_13 = a2 + 1.36053;
	float Fr = (1 - (0.542026*a2 + 0.303573*a) / a2_13) * (1 - pow(1 - NoV, 5 - 4 * a2) / a2_13) * ((-0.733996*a2*a + 1.50912*a2 - 1.16402*a) * pow(1 - NoV, 1 + rcp(39 * a2*a2 + 1)) + 1);
	float Lm = (max(1 - 2 * a, 0) * (1 - Pow5(1 - NoL)) + min(2 * a, 1)) * (1 - 0.5*a + 0.5*a * NoL);
	float Vd = (a2 / ((a2 + 0.09) * (1.31072 + 0.995584 * NoV))) * (1 - pow(1 - NoL, (1 - 0.3726732 * NoV * NoV) / (0.188566 + 0.38841 * NoV)));
	float Bp = Cosri < 0 ? 1.4 * NoV * Cosri : Cosri / max(NoL, 1e-8);
	float Lr = (21.0 / 20.0) * (1 - F0) * (Fr * Lm + Vd + Bp);
	return DiffuseColor / Lr;
#endif
}

// 来源: SRP-Core => DiffuseGGXNoPI
// Ref: Diffuse Lighting for GGX + Smith Microsurfaces, p. 113.
real3 Diffuse_GGX_NoPI(real3 albedo, real NdotV, real NdotL, real NdotH, real LdotV, real roughness)
{
	real facing = 0.5 + 0.5 * LdotV;              // (LdotH)^2
	real rough = facing * (0.9 - 0.4 * facing) * (0.5 / NdotH + 1);
	real transmitL = F_Transm_Schlick(0, NdotL);
	real transmitV = F_Transm_Schlick(0, NdotV);
	real smooth = transmitL * transmitV * 1.05;   // Normalize F_t over the hemisphere
	real single = lerp(smooth, rough, roughness); // Rescaled by PI
	real multiple = roughness * (0.1159 * PI);      // Rescaled by PI

	return single + albedo * multiple;
}

//////////////////////////////////////////////////////////////////////////////////
// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F



//////////////////////////////////////////////////////////////
// BRDF Visibility Term
// Vis = G / (4 * NoL * NoV)
// Note: V = G / (4 * NdotL * NdotV)


// no visibility term
// l = n and v = n
real V_Implicit()
{
	return 0.25;
}

// 来源: UE 4.25 => Vis_Neumann
// [Neumann et al. 1999, "Compact metallic reflectance models"]
float V_Neumann(float NoV, float NoL)
{
	return 1 / (4 * max(NoL, NoV));
}

// 来源: UE 4.25 => Vis_Kelemen
// 对Cook-Torrance的一个近似
// [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
float V_Kelemen(float VoH)
{
	// constant to prevent NaN
	return rcp(4 * VoH * VoH + 1e-5);
}

// 来源: UE 4.25 => Vis_Smith
// Smith term for GGX
// [Smith 1967, "Geometrical shadowing of a random rough surface"]
float V_Smith(float a2, float NoV, float NoL)
{
	float Vis_SmithV = NoV + sqrt(NoV * (NoV - NoV * a2) + a2);
	float Vis_SmithL = NoL + sqrt(NoL * (NoL - NoL * a2) + a2);
	return rcp(Vis_SmithV * Vis_SmithL);
}

// 来源: UE 4.25 => Vis_Schlick
// Tuned to match behavior of Vis_Smith
// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
real V_Schlick(real a2, real NoV, real NoL)
{
	real k = sqrt(a2) * 0.5;
	real Vis_SchlickV = NoV * (1 - k) + k;
	real Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / (Vis_SchlickV * Vis_SchlickL);
}

// 来源: 平安京
// 平安京中的做法，roughness按Disney的建议，但函数是用了Schlick
real V_PAJ_Schlick(real roughness, real NoV, real NoL)
{
	real k = Sq(0.5 * roughness + 0.5);

	real Vis_SchlickV = NoV * (1 - k) + k;
	real Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / (Vis_SchlickV * Vis_SchlickL);
}

// [Burley 2012, "Physically-Based Shading at Disney"]
real V_Burley_SmithG_GGXAniso(real NdotV, real TdotV, real BdotV,
	real NdotL, real TdotL, real BdotL,
	real roughnessT, real roughnessB)
{
	return 0.25 / ((NdotV + length(real3(TdotV * roughnessT, BdotV * roughnessB, NdotV))) * (NdotL + length(real3(TdotL * roughnessT, BdotL * roughnessB, NdotL))));
}

// 下面的与SRP Core中的V_SmithJointGGXAniso相同
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
//float V_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL)
//{
//	float Vis_SmithV = NoL * length(float3(ax * XoV, ay * YoV, NoV));
//	float Vis_SmithL = NoV * length(float3(ax * XoL, ay * YoL, NoL));
//	return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
//}

//////////////////////////////////////////////////////////////
// BRDF Fresnel term

real3 F_None(real3 f0)
{
	return f0;
}

// 来源: UE 4.25 => F_Schlick
// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
real3 F_UE_Schlick(real3 f0, real VoH)
{
	real x = 1.0 - VoH;
	real x2 = x * x;
	real x5 = x * x2 * x2;
	//return x5 + (1.0 - x5) * f0;        // sub mul mul mul sub mul mad*3

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate(50.0 * f0.g) * x5 + (1.0 - x5) * f0;
}
// F_UE_Schlick的因子版本
real3 F_UE_SchlickByFactor(real3 f0, real factor)
{
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate(50.0 * f0.g) * factor + (1.0 - factor) * f0;
}

// F_Schlick的因子版本
real3 F_SchlickByFactor(real3 f0, real f90, real factor)
{
	return f0 * (1.0 - factor) + (f90 * factor);        // sub mul mul mul sub mul mad*3
}
// F_Schlick的因子版本
real3 F_SchlickByFactor(real3 f0, real factor)
{
	return F_SchlickByFactor(f0, 1.0, factor);               // sub mul mul mul sub mad*3
}

// 来源: Unreal Engine 4.25 
real3 F_Fresnel(real3 f0, float VoH)
{
	real3 SpecularColorSqrt = sqrt(clamp(float3(0, 0, 0), float3(0.99, 0.99, 0.99), f0));
	real3 n = (1 + SpecularColorSqrt) / (1 - SpecularColorSqrt);
	real3 g = sqrt(n*n + VoH * VoH - 1);
	return 0.5 * Sq((g - VoH) / (g + VoH)) * (1 + Sq(((g + VoH)*VoH - 1) / ((g - VoH)*VoH + 1)));
}


//////////////////////////////////////////////////////////////
// BRDF NDF Term

/*
总结：
引用"siggraph2013-Background - Physics and Math of Shading"中的总结。
考虑到Beckmann与Phong的明显相似性以及较高的计算成本，这似乎也是一条死胡同。
通常，在任何给定的点上，空间感的变化比精确的高亮形状更重要。
在这些情况下，使用Phong NDF可能是最简单的，它在计算上简单并且具有合理的表达能力。
如果需要更真实的高亮形状，那么Trowbridge-Reitz可能是一个很好的适合;它的“草帽”形状可能比高斯Phong lobe更适合真实世界的材料。
Trowbridge-Reitz的另一个优势是成功地应用于电影和游戏制作。
如果需要一个更有表现力的NDF，那么在这里讨论的双参数的isotropic NDFs (ABC、SGD和GTR)之外，我建议使用GTR分布。
它比其他两种更简单，也被用于电影制作。
然而，这种NDFs的空间变异对于艺术家来说很难管理。
一种可以帮助降低参数空间的维数的方法是通过定义一个一维的线(基于艺术品味或物质测量)空间，并将该线的参数化暴露给艺术家。
另一种方法是通过纹理绘制只公开空间变化的一个参数(可能是remgtr)，只允许另一个(很可能是remgtr)设置为每材质常量。
在这种情况下，重新参数化可能是为了在“平滑”和“形状”之间创建一个干净的分离。一种可能的方法是使用概率分布的统计度量，如方差和峰度(这可能在某种程度上对应于视觉上的“平滑”和“尖锐”)。
*/

/**
 * Use this function to compute the pow() in the specular computation.
 * This allows to change the implementation depending on platform or it easily can be replaced by some approxmation.
 */
real PhongShadingPow(real x, real y)
{
	// The following clamping is done to prevent NaN being the result of the specular power computation.
	// Clamping has a minor performance cost.

	// In HLSL pow(a, b) is implemented as exp2(log2(a) * b).

	// For a=0 this becomes exp2(-inf * 0) = exp2(NaN) = NaN.

	// As seen in #TTP 160394 "QA Regression: PS3: Some maps have black pixelated artifacting."
	// this can cause severe image artifacts (problem was caused by specular power of 0, lightshafts propagated this to other pixels).
	// The problem appeared on PlayStation 3 but can also happen on similar PC NVidia hardware.

	// In order to avoid platform differences and rarely occuring image atrifacts we clamp the base.

	// Note: Clamping the exponent seemed to fix the issue mentioned TTP but we decided to fix the root and accept the
	// minor performance cost.

	return ClampedPow(x, y);
}

// 来源: UE 4.25 => D_Blinn
// [Blinn 1977, "Models of light reflection for computer synthesized pictures"]
// a2 = roughness^2
real D_Blinn(real a2, real NoH)
{
	real n = 2 / a2 - 2;
	return (n + 2) / (2 * PI) * PhongShadingPow(NoH, n);		// 1 mad, 1 exp, 1 mul, 1 log
}
real D_Blinn_NoPI(real a2, real NoH)
{
	real n = 2 / a2 - 2;
	return (n + 2) / PI * PhongShadingPow(NoH, n);		// 1 mad, 1 exp, 1 mul, 1 log
}

// 来源: UE 4.25 => D_Beckmann
// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
// a2 = roughness^2
real D_Beckmann(real a2, real NoH)
{
	real NoH2 = NoH * NoH;
	return exp((NoH2 - 1) / (a2 * NoH2)) / (PI * a2 * NoH2 * NoH2);
}
real D_Beckmann_NoPI(real a2, real NoH)
{
	real NoH2 = NoH * NoH;
	return exp((NoH2 - 1) / (a2 * NoH2)) / (a2 * NoH2 * NoH2);
}

// Trowbridge-Reitz NDF
// Burley建议roughness参数使用roughness^2
real D_GGX_NoPI(real NdotH, real roughness)
{
	real a2 = Sq(roughness);
	real s = (NdotH * a2 - NdotH) * NdotH + 1.0;

	// If roughness is 0, returns (NdotH == 1 ? 1 : 0).
	// That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
	return SafeDiv(a2, s * s);
}
#if 0
// 来源: UE 4.25 => D_GGX
// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float D_GGX_NoPI(float a2, float NoH)
{
	float d = (NoH * a2 - NoH) * NoH + 1;	// 2 mad
	return a2 / (d*d);					// 4 mul, 1 rcp
}
#endif

// 来源: SRP-Core => D_GGX_Visible
// GGX / Trowbridge-Reitz
// Ref: Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs, p. 12.
real D_GGX_Visible_NoPI(real NdotH, real NdotV, real VdotH, real roughness)
{
	// D_GGXNoPI - Core中定义
	// G_MaskingSmithGGX - Core中定义
	return D_GGXNoPI(NdotH, roughness) * G_MaskingSmithGGX(NdotV, roughness) * VdotH / NdotV;
}

// 来源: UE 4.25 => D_GGXaniso
// 与SRP-Core里的D_GGXAnisoNoPI算法有点不一样
// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
// 等于原文章的GTR2_aniso
float D_Burley_GGXAniso_NoPI(real NdotH, real TdotH, real BdotH, real roughnessT, real roughnessB)
{
	// The two formulations are mathematically equivalent
#if 1
	real a2 = roughnessT * roughnessB;
	real3 V = real3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
	real S = dot(V, V);

	return a2 * Sq(a2 / S);
#else
	real d = TdotH * TdotH / (roughnessT*roughnessT) + BdotH * BdotH / (roughnessB*roughnessB) + NdotH * NdotH;
	return 1.0 / (roughnessT * roughnessB * d*d);
#endif

	
}


//////////////////////////////////////////////////////////////
// 组合BRDF项

// 来源: SRP-Core => DV_SmithJointGGX
// Ref: Understanding the Masking-Shadowing Functionin Microfacet-Based BRDFs
// Inline D_GGX() * V_SmithJointGGX() together for better code generation.
// 参考HDRP传入参数 NdotL = abs01	NdotV = clamped01
real DV_SmithJointGGX_NoPI(real NdotH, real NdotL, real NdotV, real roughness, real partLambdaV)
{
	real a2 = Sq(roughness);
	real s = (NdotH * a2 - NdotH) * NdotH + 1.0;

	real lambdaV = NdotL * partLambdaV;
	real lambdaL = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

	real2 D = real2(a2, s * s);            // Fraction without the multiplier (1/Pi)
	real2 G = real2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

	// This function is only used for direct lighting.
	// If roughness is 0, the probability of hitting a punctual or directional light is also 0.
	// Therefore, we return 0. The most efficient way to do it is with a max().
	return 0.5 * (D.x * G.x) / max(D.y * G.y, REAL_MIN);
}
real DV_SmithJointGGX_NoPI(real NdotH, real NdotL, real NdotV, real roughness)
{
	real partLambdaV = GetSmithJointGGXPartLambdaV(NdotV, roughness);
	return DV_SmithJointGGX_NoPI(NdotH, NdotL, NdotV, roughness, partLambdaV);
}

// 来源: SRP-Core => DV_SmithJointGGXAniso
// Inline D_GGXAniso() * V_SmithJointGGXAniso() together for better code generation.
real DV_SmithJointGGXAniso_NoPI(real TdotH, real BdotH, real NdotH, real NdotV,
	real TdotL, real BdotL, real NdotL,
	real roughnessT, real roughnessB, real partLambdaV)
{
	real a2 = roughnessT * roughnessB;
	real3 v = real3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
	real  s = dot(v, v);

	real lambdaV = NdotL * partLambdaV;
	real lambdaL = NdotV * length(real3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

	real2 D = real2(a2 * a2 * a2, s * s);  // Fraction without the multiplier (1/Pi)
	real2 G = real2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

	// This function is only used for direct lighting.
	// If roughness is 0, the probability of hitting a punctual or directional light is also 0.
	// Therefore, we return 0. The most efficient way to do it is with a max().
	return 0.5 * (D.x * G.x) / max(D.y * G.y, REAL_MIN);
}
real DV_SmithJointGGXAniso_NoPI(real TdotH, real BdotH, real NdotH,
	real TdotV, real BdotV, real NdotV,
	real TdotL, real BdotL, real NdotL,
	real roughnessT, real roughnessB)
{
	real partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
	return DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, NdotV,
		TdotL, BdotL, NdotL,
		roughnessT, roughnessB, partLambdaV);
}

//////////////////////////////////////////////////////////////
// EnvBRDF

// 来源: URP => EnvironmentBRDF
// URP的实现
real3 EnvBRDF_URP(real3 f0, real roughness2, real grazingTerm, real fresnelTerm)
{
	float surfaceReduction = 1.0 / (roughness2 + 1.0);
	return surfaceReduction * F_SchlickByFactor(f0, grazingTerm, fresnelTerm);
}
//real3 EnvBRDF_URP(real3 f0, real roughness, real metallic, real NoV)
//{
//	real fresnelTerm = Pow4(1.0 - NoV);
//
//	half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
//	half reflectivity = 1.0 - oneMinusReflectivity;
//	half smoothness = PerceptualRoughnessToPerceptualSmoothness(roughness);
//	half grazingTerm = saturate(smoothness + reflectivity);
//
//	return EnvBRDF_URP(f0, Sq(roughness), grazingTerm, fresnelTerm)
//}

// 来源: UE 4.25 => EnvBRDFApprox
real3 EnvBRDFApprox(real3 SpecularColor, real Roughness, real NoV)
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const real4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const real4 c1 = { 1, 0.0425, 1.04, -0.04 };
	real4 r = Roughness * c0 + c1;
	real a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
	real2 AB = real2(-1.04, 1.04) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate(50.0 * SpecularColor.g);

	return SpecularColor * AB.x + AB.y;
}

// 来源: UE 4.25 => EnvBRDFApprox
// 非金属版本
real EnvBRDFApproxNonmetal(real Roughness, real NoV)
{
	// Same as EnvBRDFApprox( 0.04, Roughness, NoV )
	const real2 c0 = { -1, -0.0275 };
	const real2 c1 = { 1, 0.0425 };
	real2 r = Roughness * c0 + c1;
	return min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
}

// 来源: UE 4.25 => EnvBRDFApproxFullyRough
void EnvBRDFApproxFullyRough(inout half3 DiffuseColor, inout half3 SpecularColor)
{
	// Factors derived from EnvBRDFApprox( SpecularColor, 1, 1 ) == SpecularColor * 0.4524 - 0.0024
	DiffuseColor += SpecularColor * 0.45;
	SpecularColor = 0;
	// We do not modify Roughness here as this is done differently at different places.
}
void EnvBRDFApproxFullyRough(inout half3 DiffuseColor, inout half SpecularColor)
{
	DiffuseColor += SpecularColor * 0.45;
	SpecularColor = 0;
}

#endif