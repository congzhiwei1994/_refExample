Shader "Hidden/CopyDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

          

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            sampler2D _MainTex, _CameraDepthTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                #if UNITY_SINGLE_PASS_STEREO
			        float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
			        uv = (uv - scaleOffset.zw) / scaleOffset.xy;

                #endif

                fixed4 col = tex2D(_MainTex, uv);
                col.a = tex2D(_CameraDepthTexture, uv).r;
               
                return col;
               
            }
            ENDCG
        }
    }
}
