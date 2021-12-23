Shader "Lux URP/Vegetation/Wind Visualize"
{
    Properties
    {
        [Header(Select Mode)]
        [KeywordEnum(Combined Wind, Wind Strength, Wind Gust)]
        _Visualize ("Visualize", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}


//Blend One One
Blend SrcAlpha OneMinusSrcAlpha

            Cull Back
            ZTest LEqual
            ZWrite Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0

            // -------------------------------------
            // Unity defined keywords

            //--------------------------------------
            // GPU Instancing
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Visualize;
            CBUFFER_END

            TEXTURE2D(_LuxLWRPWindRT); SAMPLER(sampler_LuxLWRPWindRT); float4 _LuxLWRPWindRT_TexelSize;
            float4 _LuxLWRPWindDirSize;

            
            struct VertexInput
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.positionWS = mul(UNITY_MATRIX_M,v.vertex).xyz;
                return o;
            }

            half3 getResult(half4 sample) {
                half full = sample.r * (sample.g * 2.0h - 0.243h); // - 0.24376f /* not a "real" normal as we want to keep the base direction */ );
                half neg = saturate(-full);
                switch(_Visualize) {
                    case 0:
                        half3 result = (neg == 0) ? full.xxx : half3(neg, full.xx); 
                        return result;
                    case 1:
                        return sample.rrr;
                    case 2:
                        return sample.ggg;
                    default:
                        return sample.rgb;
                }  
            }

            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 sample = SAMPLE_TEXTURE2D(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, input.positionWS.xz * _LuxLWRPWindDirSize.w);
                half3 finalCol = getResult(sample);

                return half4(finalCol, .5);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}