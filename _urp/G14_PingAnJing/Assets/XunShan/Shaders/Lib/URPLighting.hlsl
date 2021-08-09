#ifndef URP_LIGHTING_INCLUDED
#define URP_LIGHTING_INCLUDED

#include "BSDF.hlsl"


// 目的：
// 把URP中的Lighting计算使用我们的数据结构，算法不变。


half3 URP_EnvironmentBRDF(GS_BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
	half3 c = indirectDiffuse * brdfData.diffuseColor;
	float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
	c += surfaceReduction * indirectSpecular * lerp(brdfData.fresnel0, brdfData.grazingTerm, fresnelTerm);
	return c;
}


half3 URP_GlobalIllumination(GS_BRDFData brdfData, BxDFContext bxdfContext, half3 bakedGI, half occlusion)
{
	half3 reflectVector = bxdfContext.R;
	half fresnelTerm = Pow4(1.0 - bxdfContext.NoV_abs01);

	half3 indirectDiffuse = bakedGI * occlusion;
	half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

	return URP_EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}



//备注: GlossyEnvironmentReflection函数
//half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
//{
//#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
//	half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
//	half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);
//
//#if !defined(UNITY_USE_NATIVE_HDR)
//	half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
//#else
//	half3 irradiance = encodedIrradiance.rbg;
//#endif
//
//	return irradiance * occlusion;
//#endif // GLOSSY_REFLECTIONS
//
//	return _GlossyEnvironmentColor.rgb * occlusion;
//}



// Based on Minimalist CookTorrance BRDF
// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
//
// * NDF [Modified] GGX
// * Modified Kelemen and Szirmay-Kalos for Visibility term
// * Fresnel approximated with 1/LdotH
half3 URP_DirectBRDF(GS_BRDFData brdfData, BxDFContext bxdfContext)
{
	float NoH = bxdfContext.NoH;
	half LoH = bxdfContext.LoH;

	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// BRDFspec = (D * V * F) / 4.0
	// D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
	// V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155

	// Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
	// We further optimize a few light invariant terms
	// brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
	float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

	half LoH2 = LoH * LoH;
	half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

	// On platforms where half actually means something, the denominator has a risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
	specularTerm = specularTerm - HALF_MIN;
	specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

	half3 color = specularTerm * brdfData.specularColor + brdfData.diffuseColor;
	return color;
}



half3 URP_SubtractDirectMainLightFromLightmap(Light mainLight, BxDFContext bxdfContext, half3 bakedGI)
{
	// Let's try to make realtime shadows work on a surface, which already contains
	// baked lighting and shadowing from the main sun light.
	// Summary:
	// 1) Calculate possible value in the shadow by subtracting estimated light contribution from the places occluded by realtime shadow:
	//      a) preserves other baked lights and light bounces
	//      b) eliminates shadows on the geometry facing away from the light
	// 2) Clamp against user defined ShadowColor.
	// 3) Pick original lightmap value, if it is the darkest one.


	// 1) Gives good estimate of illumination as if light would've been shadowed during the bake.
	// We only subtract the main direction light. This is accounted in the contribution term below.
	half shadowStrength = GetMainLightShadowStrength();
	half contributionTerm = bxdfContext.NoL_01;
	half3 lambert = mainLight.color * contributionTerm;
	half3 estimatedLightContributionMaskedByInverseOfShadow = lambert * (1.0 - mainLight.shadowAttenuation);
	half3 subtractedLightmap = bakedGI - estimatedLightContributionMaskedByInverseOfShadow;

	// 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
	half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
	realtimeShadow = lerp(bakedGI, realtimeShadow, shadowStrength);

	// 3) Pick darkest color
	return min(bakedGI, realtimeShadow);
}

void URP_MixRealtimeAndBakedGI(Light light, BxDFContext bxdfContext, inout half3 bakedGI)
{
#if defined(_MIXED_LIGHTING_SUBTRACTIVE) && defined(LIGHTMAP_ON)
	bakedGI = URP_SubtractDirectMainLightFromLightmap(light, bxdfContext, bakedGI);
#endif
}

#endif