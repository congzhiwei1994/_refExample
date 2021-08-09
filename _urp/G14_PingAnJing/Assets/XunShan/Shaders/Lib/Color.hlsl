#ifndef GSTORE_COLOR_INCLUDED
#define GSTORE_COLOR_INCLUDED


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"



#if defined(SHADER_QUALITY_HIGH)
#define G2L_LEVEL_3
#elif defined(SHADER_QUALITY_MEDIUM)
#define G2L_LEVEL_2
#else
#define G2L_LEVEL_1
#endif

real3 G2L(real3 c)
{
#if !defined(UNITY_COLORSPACE_GAMMA)
	return c;
#elif defined(G2L_LEVEL_1)
	return Gamma20ToLinear(c);
#elif defined(G2L_LEVEL_2)
	return Gamma22ToLinear(c);
#elif defined(G2L_LEVEL_3)
	return FastSRGBToLinear(c);
#elif defined(G2L_LEVEL_4)
	return SRGBToLinear(c);
#else
#error "need to define G2L_LEVEL"
#endif
}

real4 G2L(real4 c)
{
#if !defined(UNITY_COLORSPACE_GAMMA)
	return c;
#elif defined(G2L_LEVEL_1)
	return Gamma20ToLinear(c);
#elif defined(G2L_LEVEL_2)
	return Gamma22ToLinear(c);
#elif defined(G2L_LEVEL_3)
	return FastSRGBToLinear(c);
#elif defined(G2L_LEVEL_4)
	return SRGBToLinear(c);
#else
#error "need to define G2L_LEVEL"
#endif
}




real3 L2G(real3 c)
{
#if !defined(UNITY_COLORSPACE_GAMMA)
	return c;
#elif defined(G2L_LEVEL_1)
	return LinearToGamma20(c);
#elif defined(G2L_LEVEL_2)
	return LinearToGamma22(c);
#elif defined(G2L_LEVEL_3)
	return FastLinearToSRGB(c);
#elif defined(G2L_LEVEL_4)
	return LinearToSRGB(c);
#else
#error "need to define G2L_LEVEL"
#endif
}

real4 L2G(real4 c)
{
#if !defined(UNITY_COLORSPACE_GAMMA)
	return c;
#elif defined(G2L_LEVEL_1)
	return LinearToGamma20(c);
#elif defined(G2L_LEVEL_2)
	return LinearToGamma22(c);
#elif defined(G2L_LEVEL_3)
	return FastLinearToSRGB(c);
#elif defined(G2L_LEVEL_4)
	return LinearToSRGB(c);
#else
#error "need to define G2L_LEVEL"
#endif
}





#endif