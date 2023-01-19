Shader "SSS/RT viewers/SSS_ProfileTex"
{
	Properties
	{
		_MainTex("Overlay", 2D) = "" {}
        [Toggle(RightEye)] _RightEye ("Right Eye?", Float) = 0
        [Toggle(Alpha)] _Alpha ("Alpha", Float) = 0
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
			#pragma multi_compile _ Alpha
			#include "UnityCG.cginc"
			sampler2D _MainTex;
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

			sampler2D SSS_ProfileTex, SSS_ProfileTexR;		

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 col = 0;
				#ifdef RightEye
                col = tex2D(SSS_ProfileTexR, i.uv);
                #else
                col = tex2D(SSS_ProfileTex, i.uv);
                #endif 
				float4 overlay = tex2D(_MainTex, i.uv);
				col = lerp(col, overlay, overlay.a);

				#ifdef Alpha
				col.rgb = col.a;
				#endif

				return col;
			}
			ENDCG
		}
	}
}
