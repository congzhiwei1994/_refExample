#ifndef GSTORE_COMMON_INCLUDED
#define GSTORE_COMMON_INCLUDED


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"


// Ŀ�ģ�
// ����Unity����û�еĺ���

/////////////////////////////////////////////////
// ����

#define TEXTURE2D_HDR_PARAM(textureName, samplerName, decodeName) TEXTURE2D_PARAM(textureName, samplerName), real4 decodeName
#define TEXTURECUBE_HDR_PARAM(textureName, samplerName, decodeName) TEXTURECUBE_PARAM(textureName, samplerName), real4 decodeName


/////////////////////////////////////////////////



/////////////////////////////////////////////////
//converts an input 1d to 2d position. Useful for locating z frames that have been laid out in a 2d grid like a flipbook.
real2 Tile1Dto2D(real xsize, real idx)
{
	real2 xyidx = 0;
	xyidx.y = floor(idx / xsize);
	xyidx.x = idx - xsize * xyidx.y;

	return xyidx;
}

/////////////////////////////////////////////////
// ƽ������
//real Square(real x)
//{
//	return x * x;
//}
//real2 Square(real2 x)
//{
//	return x * x;
//}
//real3 Square(real3 x)
//{
//	return x * x;
//}
//real4 Square(real4 x)
//{
//	return x * x;
//}

// ע��Core������"Sq"

/////////////////////////////////////////////////


/////////////////////////////////////////////////
// ƽ������
// Clamp the base, so it's never <= 0.0f (INF/NaN).
TEMPLATE_2_REAL(ClampedPow, x, y, return pow(max(abs(x), 0.000001f), y);)
//real ClampedPow(real X, real Y)
//{
//	return pow(max(abs(X), 0.000001f), Y);
//}
//real2 ClampedPow(real2 X, real2 Y)
//{
//	return pow(max(abs(X), MaterialFloat2(0.000001f, 0.000001f)), Y);
//}
//MaterialFloat3 ClampedPow(MaterialFloat3 X, MaterialFloat3 Y)
//{
//	return pow(max(abs(X), MaterialFloat3(0.000001f, 0.000001f, 0.000001f)), Y);
//}
//MaterialFloat4 ClampedPow(MaterialFloat4 X, MaterialFloat4 Y)
//{
//	return pow(max(abs(X), MaterialFloat4(0.000001f, 0.000001f, 0.000001f, 0.000001f)), Y);
//}
/////////////////////////////////////////////////


real Pow5(real x)
{
	real x2 = x * x;
	real x5 = x * x2 * x2;
	return x5;
}


/////////////////////////////////////////////////
// �ӷ��䷽����ShpereMap�Ĳ�������
#if 0

#elif 0
// ��ȷ��ʵ��
float2 GetShpericalCoord(float3 reflect)
{
	float2 sphericalCoord = float2(atan2(reflect.x, reflect.z), asin(reflect.y));
	sphericalCoord *= float2(INV_TWO_PI, INV_PI);
	sphericalCoord.xy += 0.5;

	return sphericalCoord;
}
#elif 1
// ��ȷ��ʵ��
// https://learnopengl.com/PBR/IBL/Diffuse-irradiance
float2 GetShpericalCoord(float3 reflect)
{
	float2 sphericalCoord = float2(atan2(reflect.z, reflect.x), acos(reflect.y));
	sphericalCoord *= float2(INV_TWO_PI, INV_PI);
	sphericalCoord.x += 0.5;
	sphericalCoord.y = 1 - sphericalCoord.y;

	return sphericalCoord;
}

#elif 0
// ��ȷ��ʵ�֣���Y��Ϊ��ת
float2 GetShpericalCoord(float3 reflect)
{
	float2 sphericalCoord = float2(atan2(reflect.z, reflect.x), acos(reflect.y));
	sphericalCoord *= float2(INV_TWO_PI, INV_PI);
	sphericalCoord.x += 0.5;

	return sphericalCoord;
}
#elif 0
// ��ȷ��ʵ�֣���Y��Ϊ��ת
float2 GetShpericalCoord(float3 reflect)
{
	float2 sphericalCoord = float2(atan2(reflect.x, reflect.z), -asin(reflect.y));
	sphericalCoord *= float2(INV_TWO_PI, INV_PI);
	sphericalCoord.xy += 0.5;

	return sphericalCoord;
}

#endif

float2 GetShpericalCoordApprox_1(float3 reflect)
{
	float p = sqrt(8.0 * (reflect.z + 1.0));
	return (reflect.xy / p) + 0.5;
}

float2 GetShpericalCoordApprox_2(float3 v)
{
	float ang = max(dot(v, float3(0.0, 0.0, -1.0)), 0.0);
	float hackValue = lerp(1.0, 1.008, ang);
	float p = sqrt(8.0 * (v.z + hackValue));
	return (v.xy / p) + 0.5;
}

float2 GetShpericalCoordApprox_3(float3 v)
{
	float3 p = float3(v.x, v.y, v.z + 1.0);
	float m = 2.0 * sqrt(dot(p, p));
	return v.xy / m + 0.5;
}

float2 GetShpericalCoordApprox_4(float3 r)
{
	// �����ŶԹ�������m��ģ����������r+���������(0,0,1)Ϊ��������m��
	float m = sqrt(r.x * r.x + r.y * r.y + (r.z + 1.0) * (r.z + 1.0));
	// ���������m�ĵ�λ����
	float3 n = float3(r.x / m, r.y / m, r.z / m);
	// ����ֵ��Ϊ[-1,1],תΪUV��ֵ��[0,1]
	// �ڱ�Ե��UV��ϢҲ�Ǹ�����ͼƬ���棬���γɾ���ˮ�����Ч����
	return float2(0.5 * n.x + 0.5, 0.5 * n.y + 0.5);

}

/////////////////////////////////////////////////

#endif