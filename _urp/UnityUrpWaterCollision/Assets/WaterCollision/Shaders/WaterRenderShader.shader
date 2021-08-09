// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/WaterRenderShader"
{
    Properties
    {
        _Color ("Color", color) = (1,1,1,1)
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		_WaveScale("WaveScale", Range(0,10)) = 0.1
		
		[HideInInspector] _SrcBlend ("__src", float) = 1.0
		[HideInInspector] _DstBlend ("__dst", float) = 0.0
		[HideInInspector] _ZWrite ("__zwrite", float) = 1.0
		[HideInInspector] _ZTest ("__ztest", float) = 4.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

		ZWrite [_ZWrite]
		ZTest [_ZTest] 
		Cull Off //Front Back
		Blend [_SrcBlend] [_DstBlend]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 worldSpaceReflect : TEXCOORD1;
            };
			
			CBUFFER_START(UnityPerMaterial)

				float4 _Color;
				float _WaveScale;
				sampler2D _WaveResult;
				samplerCUBE _SkyboxTex;
				
			CBUFFER_END
			
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            v2f vert (appdata v)
            {
                v2f o;

				float4 localPos = v.vertex;
				float4 waveTransmit = tex2Dlod(_WaveResult, float4(v.uv, 0, 0));
				float waveHeight = DecodeFloatRGBA(waveTransmit);

				localPos.y += waveHeight * _WaveScale;

				float3 worldPos = mul(unity_ObjectToWorld, localPos);
				float3 worldSpaceNormal = mul(unity_ObjectToWorld, v.normal);
				float3 worldSpaceViewDir = UnityWorldSpaceViewDir(worldPos);

                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				o.uv = v.uv;
				o.worldSpaceReflect = reflect(-worldSpaceViewDir, worldSpaceNormal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                half4 noiseColor = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv);

				noiseColor *= _Color;

				float4 waveTransmit = tex2Dlod(_WaveResult, float4(i.uv, 0, 0));
				float waveHeight = DecodeFloatRGBA(waveTransmit) * _WaveScale;

				float3 reflect = normalize(i.worldSpaceReflect);
				noiseColor = lerp(noiseColor, _Color, waveHeight);
                return half4(noiseColor.rgb, _Color.a);
            }
            ENDHLSL
        }
    }
}
