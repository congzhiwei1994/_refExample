// @https://www.zhihu.com/search?q=%E5%B1%8F%E5%B9%95%E7%A9%BA%E9%97%B4%E7%9A%84%E5%8F%8D%E5%B0%84&utm_content=search_history&type=content
Shader "Unlit/SSRShader"
{
	Properties
	{
		_Noise ("NoiseTex", 2D) = "white" {}
		_SkyBoxCubeMap("SkyBox", Cube) = ""{}
	}
	SubShader
	{
		//Geometry  Transparent
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }
		ZWrite Off
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma enable_d3d11_debug_symbols

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#define MAX_TRACE_DIS 500
			#define MAX_IT_COUNT 200         
			#define EPSION 0.1

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float4 positionOS : TEXCOORD2;
				float4 positionCS : TEXCOORD3;
				float4 vsRay	  : TEXCOORD4;
				float4 vertex : SV_POSITION;
			};

			TEXTURE2D(_Noise);
			SAMPLER(sampler_Noise);

			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURECUBE(_SkyBoxCubeMap);
			SAMPLER(sampler_SkyBoxCubeMap);

			float4x4 _InverseProjectionMatrix;
			float4x4 _InverseViewMatrix;
			float4x4 _Camera_INV_VP;

			float3 GetReflectRay(float3 inputRayDir, float3 planeDir)
			{
				float3 ret = -(2 * dot(inputRayDir, planeDir) * planeDir - inputRayDir);
				return normalize(ret);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv = v.uv;

				o.positionWS = TransformObjectToWorld(v.vertex).xyz;
				o.positionOS = v.vertex.xyzw;

				float4 screenPos = TransformObjectToHClip(v.vertex);
				//透视除法 转换到NDC下坐标，值域(-1,1)
				screenPos.xyz /= screenPos.w;
				//映射到(0,1)
				screenPos.xy = screenPos.xy * 0.5 + 0.5;

				o.positionCS = screenPos;

				//翻转y值
				#if UNITY_UV_STARTS_AT_TOP
					o.positionCS.y = 1 - o.positionCS.y;
				#endif

				//远裁剪面
				float zFar = _ProjectionParams.z;
				half2 CS = o.positionCS.xy * 2.0 - 1.0;
				// 构建一个位于远平面的向量坐标，是为了配合之后在片元着色器取出的深度区间百分比后，直接对向量进行缩放计算，可以快速得到当前射线和反射平面的相交点坐标
				float4 vsRay = float4(float3(CS, 1) * zFar, zFar);

				vsRay = mul(unity_CameraInvProjection, vsRay);

				o.vsRay = vsRay;
				return o;
			}



			float2 ViewPosToCS(float3 vpos)
			{
				float4 proj_pos = mul(unity_CameraProjection, float4(vpos, 1));
				float3 screenPos = proj_pos.xyz / proj_pos.w;
				return float2(screenPos.x, screenPos.y) * 0.5 + 0.5;
			}

			float compareWithDepth(float3 vpos)
			{
				float2 uv = ViewPosToCS(vpos);
				float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
				depth = LinearEyeDepth(depth, _ZBufferParams);
				int isInside = uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1;
				return lerp(0, vpos.z + depth, isInside);
			}

			bool rayMarching(float3 o, float3 r, out float2 hitUV)
			{
				float3 end = o;
				float stepSize = 0.5;
				float thinkness = 0.1;
				float triveled = 0;
				int max_marching = 256;
				float max_distance = 500;

				UNITY_LOOP
				for (int i = 1; i <= max_marching; ++i)
				{
					end += r * stepSize;
					triveled += stepSize;

					if (triveled > max_distance)
					return false;

					float collied = compareWithDepth(end);
					if (collied < 0)
					{
						if (abs(collied) < thinkness)
						{
							hitUV = ViewPosToCS(end);
							return true;
						}

						//回到当前起点
						end -= r * stepSize;
						triveled -= stepSize;
						//步进减半
						stepSize *= 0.5;
					}
				}
				return false;
			}

			float4 frag (v2f i) : SV_Target
			{
				
				float4 screenPos = i.positionCS;
				/*	float4 screenPos = TransformObjectToHClip(i.positionOS);
				screenPos.xyz /= screenPos.w;
				screenPos.xy = screenPos.xy * 0.5 + 0.5;
				screenPos.y = 1 - screenPos.y;
				
				float4 cameraRay = float4(screenPos.xy * 2.0 - 1.0, 1, 1.0);
				cameraRay = mul(unity_CameraInvProjection, cameraRay);
				i.vsRay = cameraRay / cameraRay.w;*/

				//世界空间射线
				/*float3 normalWS = TransformObjectToWorldDir(float3(0, 1, 0));
				

				float3 viewDir = normalize(i.positionWS - _WorldSpaceCameraPos);
				float3 reflectDir = reflect(viewDir, normalWS);
				float3 reflectPos = i.positionWS;

				float3 col = RayTracePixel(reflectPos, reflectDir);*/

				// NDC 空间下的z值，值域是（-1~1）
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos.xy);
				// (0~1)
				depth = Linear01Depth(depth, _ZBufferParams);
				
				float2 noiseTex = (SAMPLE_TEXTURE2D(_Noise, sampler_Noise, (i.uv * 5) + _Time.x).xy * 2 - 1) * 0.1;

				float3 wsNormal = normalize(float3(noiseTex.x, 1, noiseTex.y));    //世界坐标系下的法线
				float3 vsNormal = (TransformWorldToViewDir(wsNormal));    //将转换到view space
				// 直接进行缩放可以得到和反射平面的相交位置
				float3 vsRayOrigin = (i.vsRay) * depth;
				float3 reflectionDir = normalize(reflect(vsRayOrigin, vsNormal));

				float2 hitUV = 0;
				float3 col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenPos.xy).xyz;
				if (rayMarching(vsRayOrigin, reflectionDir, hitUV))
				{
					float3 hitCol = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, hitUV).xyz;
					col += hitCol;
				}
				else {
					float3 viewPosToWorld = normalize(i.positionWS.xyz - _WorldSpaceCameraPos.xyz);
					float3 reflectDir = reflect(viewPosToWorld, wsNormal);
					col = SAMPLE_TEXTURECUBE(_SkyBoxCubeMap, sampler_SkyBoxCubeMap, reflectDir);
				}

				return float4(col, 1);
			}
			ENDHLSL
		}
	}
}
