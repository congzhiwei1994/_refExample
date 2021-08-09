Shader "Unlit/WaveTransmitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            sampler2D _MainTex;
			sampler2D _PrevWaveMarkTex;
			float4 _WaveTransmitParams;
			float _WaveAtten;

			static const float2 WAVE_DIR[4] = { float2(1, 0), float2(0, 1), float2(-1, 0), float2(0, -1) };
			
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

			float4 UnityObjectToClipPos(float4 vertex){
				
				return mul(UNITY_MATRIX_MVP, vertex);
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				/*波传递公式
				 (4 - 8 * c^2 * t^2 / d^2) / (u * t + 2) + (u * t - 2) / (u * t + 2) * z(x,y,z, t - dt) + (2 * c^2 * t^2 / d ^2) / (u * t + 2)
				 * (z(x + dx,y,t) + z(x - dx, y, t) + z(x,y + dy, t) + z(x, y - dy, t);*/

				float dx = _WaveTransmitParams.w;

				float avgWaveHeight = 0;
				for (int s = 0; s < 4; s++)
				{
					avgWaveHeight += DecodeHeight(tex2D(_MainTex, i.uv + WAVE_DIR[s] * dx));
				}

				//(2 * c^2 * t^2 / d ^2) / (u * t + 2)*(z(x + dx, y, t) + z(x - dx, y, t) + z(x, y + dy, t) + z(x, y - dy, t);
				float agWave = _WaveTransmitParams.z * avgWaveHeight;
				
				// (4 - 8 * c^2 * t^2 / d^2) / (u * t + 2)
				float curWave = _WaveTransmitParams.x *  DecodeHeight(tex2D(_MainTex, i.uv));
				// (u * t - 2) / (u * t + 2) * z(x,y,z, t - dt) 上一次波浪值 t - dt
				float prevWave = _WaveTransmitParams.y * DecodeHeight(tex2D(_PrevWaveMarkTex, i.uv));

				//波衰减
				float waveValue = (curWave + prevWave + agWave) * _WaveAtten;

                return EncodeHeight(waveValue);
            }
            ENDHLSL
        }
    }
}
