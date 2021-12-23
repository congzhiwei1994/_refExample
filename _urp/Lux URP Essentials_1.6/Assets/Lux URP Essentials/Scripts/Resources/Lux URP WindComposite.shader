// http://www.iquilezles.org/www/articles/dynclouds/dynclouds.htm
Shader "Hidden/Lux URP WindComposite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "LightweightPipeline" }

        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //  Global Inputs
            float3 _LuxLWRPWindDir;
            float2 _LuxLWRPWindUVs;
            float2 _LuxLWRPWindUVs1;
            float2 _LuxLWRPWindUVs2;
            float2 _LuxLWRPWindUVs3;
            float2 _LuxLWRPGust;
            half3 _GustMixLayer;

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_ST;

            #pragma vertex vert
            #pragma fragment frag

            struct VertexInput
            {
                float4 positionOS   : POSITION;
                half2 texcoord      : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };


            VertexOutput vert( VertexInput v )
            {
                VertexOutput output;
                output.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                output.uv = v.texcoord;
                return output;
            }

            half4 frag(VertexOutput i) : SV_Target {

                half4 n1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _LuxLWRPWindUVs);
                half4 n2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _LuxLWRPWindUVs1);
                half4 n3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _LuxLWRPWindUVs2);
                half4 n4 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv * _LuxLWRPGust.x + _LuxLWRPWindUVs3);

                half4 sum = half4(n1.r, n1.g + n2.g, n1.b + n2.b + n3.b, n1.a + n2.a + n3.a + n4.a);
                const half4 weights = half4(0.5000, 0.2500 , 0.1250 , 0.0625 );
                
                half2 WindStrengthGustNoise;
            //  WindStrength
                WindStrengthGustNoise.x = dot(sum, weights);
            //  GrassGustNoise / _LuxLWRPGust.y comes in as 0.5 - 1.5                                 
                WindStrengthGustNoise.y = lerp(1.0h, (n4.a + dot(half3(n1.a, n2.a, n3.a), _GustMixLayer)) * 0.85h, _LuxLWRPGust.y - 0.5h);
            //  Sharpen WindStrengthGustNoise according to turbulence
                WindStrengthGustNoise = (WindStrengthGustNoise - half2(0.5h, 0.5h)) * _LuxLWRPGust.yy + half2(0.5h, 0.5h);

                return half4(
                    WindStrengthGustNoise,
                    //n4.a,
                    //0
                    (n3.a + abs(WindStrengthGustNoise.y)) * 0.5h + n2.a * 0.0h,
                    0
                );
            }
            ENDHLSL
        }
    }
}
