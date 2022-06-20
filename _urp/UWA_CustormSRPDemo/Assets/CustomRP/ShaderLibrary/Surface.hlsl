#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface {
	//表面位置坐标
	float3 position;
	float3 normal;
	float3 color;
	float alpha;
	float metallic;
	float smoothness;
	float3 viewDirection;
	//表面深度
	float depth;
	//抖动
	float dither;
};

#endif
