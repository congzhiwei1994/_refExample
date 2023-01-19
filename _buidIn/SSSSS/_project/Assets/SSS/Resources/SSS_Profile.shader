Shader "Hidden/SSS_Profile"
{	
	//Properties
	//{
	//	_Cutoff("Mask Clip Value", Float) = 0.5
	//}
	SubShader
	{
		//Tags { "RenderType"="SSS" }
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			half _Cutoff;
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "SSS_Common.hlsl"
			#pragma multi_compile _ ENABLE_ALPHA_TEST
			#pragma multi_compile _ ENABLE_PARALLAX
			#pragma multi_compile _ PUPIL_DILATION


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv_MainTex : TEXCOORD0;
				float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
			};

			struct v2f
			{
				float2 uv_MainTex : TEXCOORD0;
				float3 viewDir  : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};	

			float4 _MainTex_ST;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv_MainTex = TRANSFORM_TEX(v.uv_MainTex, _MainTex);
				TANGENT_SPACE_ROTATION; 
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				return o;
			}
			
			fixed4 frag (v2f IN) : SV_Target
			{
				// sample the texture
				half2 uv = IN.uv_MainTex;

				#ifdef ENABLE_PARALLAX
				COMPUTE_PARALLAX
				#endif

				#ifdef PUPIL_DILATION		
				COMPUTE_EYE_DILATION
				#endif

				fixed4 col = tex2D(_ProfileTex, uv) * _ProfileColor;
				fixed alpha = tex2D(_MainTex, uv).a;

				#ifdef ENABLE_ALPHA_TEST
				clip(alpha - _Cutoff);
				#endif

				return col;
			}
			ENDCG
		}
	}
		//Don't render anything else
		//Fallback "Legacy Shaders/VertexLit"
}
