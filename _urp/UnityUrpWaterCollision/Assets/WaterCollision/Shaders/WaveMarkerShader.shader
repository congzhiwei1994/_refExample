Shader "Unlit/WaveMarkerShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			inline float2 EncodeFloatRG( float v )
			{
				float2 kEncodeMul = float2(1.0, 255.0);
				float kEncodeBit = 1.0/255.0;
				float2 enc = kEncodeMul * v;
				enc = frac (enc);
				enc.x -= enc.y * kEncodeBit;
				return enc;
			}

			inline float DecodeFloatRG( float2 enc )
{
				float2 kDecodeDot = float2(1.0, 1/255.0);
				return dot( enc, kDecodeDot );
			}
			
			float4 EncodeHeight(float height) {
				float2 rg = EncodeFloatRG(height > 0 ? height : 0);
				float2 ba = EncodeFloatRG(height <= 0 ? -height : 0);

				return float4(rg, ba);
			}

			float DecodeHeight(float4 rgba) {
				float h1 = DecodeFloatRG(rgba.rg);
				float h2 = DecodeFloatRG(rgba.ba);

				int c = step(h2, h1);
				return lerp(h2, h1, c);
			}
   
			inline float4 EncodeFloatRGBA( float v )
			{
				float4 kEncodeMul = float4(1.0, 255.0, 65025.0, 160581375.0);
				float kEncodeBit = 1.0/255.0;
				float4 enc = kEncodeMul * v;
				enc = frac (enc);
				enc -= enc.yzww * kEncodeBit;
				return enc;
			}

			inline float DecodeFloatRGBA( float4 enc )
			{
				float4 kDecodeDot = float4(1.0, 1/255.0, 1/65025.0, 1/160581375.0);
				return dot( enc, kDecodeDot );
			}
			
			float3 UnityWorldSpaceViewDir(float3 worldPos){
				
				return _WorldSpaceCameraPos.xyz - worldPos;
			}
			
			float4 UnityObjectToClipPos(float4 vertex){
				
				return mul(UNITY_MATRIX_MVP, vertex);
			}

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

			float4 _WaveMarkParams;
			sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				float dx = i.uv.x - _WaveMarkParams.x;
				float dy = i.uv.y - _WaveMarkParams.y;

				float disSqr = dx * dx + dy * dy;

				int hasCol = step(0, _WaveMarkParams.z - disSqr);

				float waveValue = DecodeHeight(tex2D(_MainTex, i.uv));

				if (hasCol == 1) {
					waveValue = _WaveMarkParams.w;
				}
				
                return EncodeHeight(waveValue);
            }
            ENDHLSL
        }
	}
}
