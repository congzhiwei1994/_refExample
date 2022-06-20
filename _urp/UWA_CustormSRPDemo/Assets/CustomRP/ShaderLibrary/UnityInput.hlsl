//unity标准输入库
#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED
CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
float4 unity_LODFade;
//相机位置
float3 _WorldSpaceCameraPos;
//这个矩阵包含一些在这里我们不需要的转换信息
real4 unity_WorldTransformParams;
CBUFFER_END

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;
#endif
