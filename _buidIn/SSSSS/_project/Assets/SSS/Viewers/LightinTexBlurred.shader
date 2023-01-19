Shader "SSS/RT viewers/LightingTexBlurred"
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

			sampler2D LightingTexBlurred, _MainTex;
			sampler2D LightingTexBlurredR;
			float4 LightingTexBlurred_ST, _MainTex_TexelSize, _MainTex_ST;
		

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                #ifdef RightEye
				return tex2D(LightingTexBlurredR, i.uv);
				#else
				return tex2D(LightingTexBlurred, i.uv);
                #endif
				
			
			}
			ENDCG
		}
	}
}
