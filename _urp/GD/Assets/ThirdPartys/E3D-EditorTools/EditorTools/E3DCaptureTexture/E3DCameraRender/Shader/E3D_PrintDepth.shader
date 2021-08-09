Shader "E3D/PrintDepth"
{
	SubShader
	{
		ZWrite Off

		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
			};

			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				#if UNITY_UV_STARTS_AT_TOP //处于DX
					if(_MainTex_TexelSize.y < 0)
					o.uv = float2(v.uv.x, 1-v.uv.y);
				#else
					o.uv = v.uv;
				#endif

				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//非投影下的深度
				//float depth = (UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv)) - 0.3)/15;				
				//float linear01Depth = 1-Linear01Depth(depth);
				//return linear01Depth;

				//计算投影下的深度图
				// float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.screenPos));
				// float linearEyeDepth = 1- saturate(LinearEyeDepth(depth) * 1);
				// return linearEyeDepth;

				float depthValue =1- LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r);
				//depthValue = Linear01Depth (depthValue) *10;
				return float4(depthValue, depthValue, depthValue, 1.0f);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
