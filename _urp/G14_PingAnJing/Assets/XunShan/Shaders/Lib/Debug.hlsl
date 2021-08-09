#ifndef GSTORE_DEBUG_INCLUDED
#define GSTORE_DEBUG_INCLUDED

#include "PBRValidator.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

#ifdef DEBUG_ON

// 调试颜色输出
half4 _G_DebugOutputColor;
half _G_Debug_EnableHeat;
half _G_Debug_HeatMaxValue;

#ifndef DEBUG_MODE
#error must be define DEBUG_MODE varian
#endif

// Displays the luminance of the HDR color with a 'false color' set of colored bands.
// This is like a heatmap to better visualize the wide range of HDR values.
float3 FasleColorRemap(float lum, float4 thresholds)
{
	//Gradient from 0 to 240 deg of HUE gradient
	const float l = DegToRad(240) / TWO_PI;

	float t = lerp(0.0, l / 3, RangeRemap(thresholds.x, thresholds.y, lum))
		+ lerp(0.0, l / 3, RangeRemap(thresholds.y, thresholds.z, lum))
		+ lerp(0.0, l / 3, RangeRemap(thresholds.z, thresholds.w, lum));

	return HsvToRgb(float3(l - t, 1, 1));
}
float3 FasleColorRemap(float lum, float maxValue)
{
	//Gradient from 0 to 240 deg of HUE gradient
	const float l = DegToRad(240) / TWO_PI;
	float t = lerp(0.0, l, RangeRemap(0, maxValue, lum));

	return HsvToRgb(float3(l - t, 1, 1));
}
float3 FasleColorRemap(float3 color, float maxValue)
{
	//float part = maxValue / 3;
	//return FasleColorRemap(Luminance(color.rgb), float4(0, part, maxValue - part, maxValue));
	return FasleColorRemap(Luminance(color.rgb), maxValue);
}
float3 FasleColorRemapHeat(float3 color)
{
	return FasleColorRemap(color, _G_Debug_HeatMaxValue);
}


real4 CorrectColor(real4 output)
{
	// 输入参数为线性值

#if defined(UNITY_COLORSPACE_GAMMA)
	// 在Gamma需要把线性数据转为Gamma
	return LinearToSRGB(output);
#else
	// 如果在线性空间Unity会帮我们转为Gamma
	return output;
#endif
}

// 注意：默认传入的颜色值已经是线性的
real4 GetDebugOutput(real c)
{
	return CorrectColor(real4(c.xxx, 1));
}
real4 GetDebugOutput(real2 c)
{
	return CorrectColor(real4(c.xy, 1, 1));
}
real4 GetDebugOutput(real3 c)
{
	return CorrectColor(real4(c.xyz, 1));
}
real4 GetDebugOutput(real4 c)
{
	return CorrectColor(c);
}

// 注意：默认传入的颜色值已经是线性的
//#define DEBUG(mode, c) if (HasFlag(DEBUG_MODE, mode)) { _G_DebugOutputColor = GetDebugOutput(c); }
#define DEBUG(mode, c) if (DEBUG_MODE == mode) { _G_DebugOutputColor = GetDebugOutput(c); }
#define DEBUG_HEAT(mode, c) if (DEBUG_MODE == mode) { _G_DebugOutputColor = GetDebugOutput((_G_Debug_EnableHeat == 0)?c:FasleColorRemapHeat(c)); }
#define DEBUG_HEAT01(mode, c) if (DEBUG_MODE == mode) { _G_DebugOutputColor = GetDebugOutput((_G_Debug_EnableHeat == 0)?c:FasleColorRemap(c, 1.0)); }
#define OUTPUT(c) _G_DebugOutputColor

#else

#define DEBUG(mode, c) 
#define DEBUG_HEAT(mode, c) 
#define DEBUG_HEAT01(mode, c) 
#define OUTPUT(c) c


#endif



#endif