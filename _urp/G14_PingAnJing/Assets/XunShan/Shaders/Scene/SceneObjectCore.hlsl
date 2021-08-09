#ifndef SCENE_OBJECT_INCLUDED
#define SCENE_OBJECT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "../Lib/Color.hlsl"
#include "../Lib/BSDF.hlsl"
#include "../Lib/Input.hlsl"
#include "../Lib/URPLighting.hlsl"

//////////////////////////////////////////////
//Shader中的Properties示例
/*
Properties
{
	[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}

}
*/


//////////////////////////////////////////////
// 支持的变体
/*
局部：
_NORMALMAP


全局：

*/



//////////////////////////////////////////////
// 贴图输入
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_MixMap);
SAMPLER(sampler_MixMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

//////////////////////////////////////////////
// 材质输入
CBUFFER_START(UnityPerMaterial)

CBUFFER_END

//////////////////////////////////////////////
// 全局输入





//////////////////////////////////////////////
// 顶点输入数据
struct Attributes
{
	half4 color			: COLOR;
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
	float4 tangentOS    : TANGENT;
	float2 uv           : TEXCOORD0;
	float2 lightmapUV   : TEXCOORD1;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//////////////////////////////////////////////
// 片元输入数据
struct Varyings
{
	float4 positionCS               : SV_POSITION;
	half4 color                     : COLOR;
	float2 uv                       : TEXCOORD0;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	float3 positionWS               : TEXCOORD2;
#endif

#if _NORMALMAP
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
// 在片元中获取Surface输入
GS_SurfaceData GetGSSurfaceData(float2 uv)
{
	half smoothness = 0;

	GS_SurfaceData outSurfaceData = (GS_SurfaceData)0;

	half4 albedoAndAlpha = G2L(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv));
	outSurfaceData.albedo = albedoAndAlpha.rgb;
	outSurfaceData.alpha = GetSurfaceAlpha(albedoAndAlpha.a, 0.5);

	half4 mixColor = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, uv);
	outSurfaceData.roughness = mixColor.g;
	outSurfaceData.metallic = mixColor.r;

	half4 normalColor = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
	outSurfaceData.occlusion = normalColor.b;
	outSurfaceData.normalTS = UnpackNormalRG(normalColor.rg);

	outSurfaceData.emission = 0;

	return outSurfaceData;
}

//////////////////////////////////////////////
// 在片元中获取URP输入
GS_InputData GetGSInputData(Varyings vertexOutput, GS_SurfaceData surfaceData)
{
	GS_InputData inputData = (GS_InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	inputData.positionWS = vertexOutput.positionWS;
#endif

#ifdef _NORMALMAP
	half3 viewDirWS = half3(vertexOutput.normalWS.w, vertexOutput.tangentWS.w, vertexOutput.bitangentWS.w);
	half3x3 TBN_Matrix = half3x3(vertexOutput.tangentWS.xyz, vertexOutput.bitangentWS.xyz, vertexOutput.normalWS.xyz);
	inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, TBN_Matrix);
#else
	half3 viewDirWS = vertexOutput.viewDirWS;
	inputData.normalWS = vertexOutput.normalWS;
#endif
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

	viewDirWS = SafeNormalize(viewDirWS);
	inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	inputData.shadowCoord = vertexOutput.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
	// bug? inputData.positionWS 为 0
	inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
	inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

	inputData.fogCoord = vertexOutput.fogFactorAndVertexLight.x;
	inputData.vertexLighting = vertexOutput.fogFactorAndVertexLight.yzw;
	return inputData;
}

//////////////////////////////////////////////
// 在片元中获取Environment输入
GS_EnvData GetGSEnvData(Varyings vertexOutput, GS_InputData inputData, GS_BRDFData brdfData, BxDFContext bxdfContext)
{
	GS_EnvData outEnvData = (GS_EnvData)0;

	outEnvData.envIrradiance = SAMPLE_GI(vertexOutput.lightmapUV, vertexOutput.vertexSH, inputData.normalWS);
	//outEnvData.envReflection = CalcGlossyEnvironmentReflection(bxdfContext.R, brdfData.perceptualRoughness);
	//outEnvData.envBrightness = 1.0;

	return outEnvData;
}

//////////////////////////////////////////////
// 直接光着色函数 
half3 CalcDirectLighting(GS_BRDFData brdfData, BxDFContext bxdfContext, Light light)
{
	half3 lightColor = light.color;
	half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

	half3 radiance = lightColor * (lightAttenuation * bxdfContext.NoL_01);
	return URP_DirectBRDF(brdfData, bxdfContext) * radiance;
}



//////////////////////////////////////////////
// 顶点函数
Varyings LitPassVertex(Attributes input)
{
	Varyings output = (Varyings)0;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
	VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	// 默认实现是Lambert光照
	half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
	half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

	output.uv = input.uv;

#if _NORMALMAP
	output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
	output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
	output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
	output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
	output.viewDirWS = viewDirWS;
#endif

	OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
	OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

	output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	output.shadowCoord = GetShadowCoord(vertexInput);
#endif

	output.positionCS = vertexInput.positionCS;

	return output;
}

//////////////////////////////////////////////
// 片元函数
half4 LitPassFragment(Varyings vertexOutput) : SV_Target
{
	// 准备数据
	GS_SurfaceData surfaceData = GetGSSurfaceData(vertexOutput.uv);
	GS_InputData inputData = GetGSInputData(vertexOutput, surfaceData);
	Light mainLight = GetMainLight(inputData.shadowCoord);
	GS_BRDFData brdfData = GetBRDFData(surfaceData);
	BxDFContext bxdfContext = GetBxDFContext(inputData.normalWS, inputData.viewDirectionWS, mainLight.direction, half3(1, 0, 0), half3(0, 1, 0));
	GS_EnvData envData = GetGSEnvData(vertexOutput, inputData, brdfData, bxdfContext);

	// 混合Unity GI
	URP_MixRealtimeAndBakedGI(mainLight, bxdfContext, envData.envIrradiance);

	// 收集所有间接光
	half3 color = URP_GlobalIllumination(brdfData, bxdfContext, envData.envIrradiance, surfaceData.occlusion);
	
	// 直接光
	color += (CalcDirectLighting(brdfData, bxdfContext, mainLight));
	//return half4(inputData.normalWS, 1);

	// 动态点光源
	half3 additionalLights = 0;
#ifdef _ADDITIONAL_LIGHTS
	uint pixelLightCount = GetAdditionalLightsCount();
	for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
	{
		Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
		BxDFContext additionalBxDFContext = GetBxDFContext(inputData, light);
		additionalLights += CalcDirectLighting(brdfData, additionalBxDFContext, light);
	}
#endif
	color += additionalLights;

	// 动态点光源
#ifdef _ADDITIONAL_LIGHTS_VERTEX
	color += inputData.vertexLighting * brdfData.diffuse;
#endif

	// 应用雾色
	color = MixFog(color, inputData.fogCoord);

	color = L2G(color);

	half alpha = surfaceData.alpha;
	return half4(color.rgb, alpha);
}

#endif