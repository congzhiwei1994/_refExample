Shader "SSS/RT viewers/NormalTex"
{
	Properties
	{
		[hideininspector]_MainTex("Base", 2D) = "" {}		
		[Toggle(RightEye)] _RightEye ("Right Eye?", Float) = 0	
	
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ RightEye
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
			};

			sampler2D SSSDepthTex, SSSDepthTexBlurred, _MainTex;
			sampler2D SSSDepthTexR, SSSDepthTexBlurredR;
			float4 SSSDepthTex_ST, _MainTex_TexelSize, _MainTex_ST;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 depthSample = 0;
                #ifdef RightEye
                depthSample = tex2D(SSSDepthTexR, i.uv);
                #else
                depthSample = tex2D(SSSDepthTex, i.uv);
                #endif
                float3 normal;
		        float depth;
		        DecodeDepthNormal(depthSample, depth, normal);
				//half3 normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, input.uv.xy));
				
				return float4(normal, 1);
			}
			ENDCG
		}
	}
}
