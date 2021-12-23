Shader "Lux URP/Toon Outline"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(68hb5r7b3dnz)]

        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 1

        [Header(Outline)]
        _Color ("Color", Color) = (0,0,0,1)
        _Border ("Width", Float) = 3
        [Toggle(_COMPENSATESCALE)]
        _CompensateScale            ("     Compensate Scale", Float) = 0
        [Toggle(_OUTLINEINSCREENSPACE)]
        _OutlineInScreenSpace       ("     Calculate width in Screen Space", Float) = 0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"= "Geometry+1"
        }
        Pass
        {
            Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha
            Cull[_Cull]
            ZTest [_ZTest]
        //  Make sure we do not get overwritten
            ZWrite On

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature_local _COMPENSATESCALE
            #pragma shader_feature_local _OUTLINEINSCREENSPACE

            // -------------------------------------
            // Lightweight Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5
            
            #pragma vertex vert
            #pragma fragment frag

            // Lighting include is needed because of GI
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _Border;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 position : POSITION;
                half fogCoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            
            //  Extrude
                #if !defined(_OUTLINEINSCREENSPACE)
                    #if defined(_COMPENSATESCALE)
                        float3 scale;
                        scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                        scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));
                        scale.z = length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z));
                    #endif
                    v.vertex.xyz += v.normal * 0.001 * _Border
                    #if defined(_COMPENSATESCALE) 
                        / scale
                    #endif
                    ;
                #endif

                o.position = TransformObjectToHClip(v.vertex.xyz);
                o.fogCoord = ComputeFogFactor(o.position.z);

            //  Extrude
                #if defined(_OUTLINEINSCREENSPACE)
                    if (_Border > 0.0h) {
                        float3 normal = mul(UNITY_MATRIX_MVP, float4(v.normal, 0)).xyz; // to clip space
                        float2 offset = normalize(normal.xy);
                        float2 ndc = _ScreenParams.xy * 0.5;
                        o.position.xy += ((offset * _Border) / ndc * o.position.w);
                    }
                #endif
                return o;
            }

            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                _Color.rgb = MixFog(_Color.rgb, input.fogCoord);
                return half4(_Color);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}