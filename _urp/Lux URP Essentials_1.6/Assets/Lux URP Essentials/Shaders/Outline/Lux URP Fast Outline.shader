Shader "Lux URP/Fast Outline"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(gpukpasbzt01)]
        
        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 2

        [Space(5)]
        [IntRange] _StencilRef ("Stencil Reference", Range (0, 255)) = 0
        [IntRange] _ReadMask ("     Read Mask", Range (0, 255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompare ("Stencil Comparison", Int) = 6


        [Header(Outline)]
        [Space(8)]
        _Color ("Color", Color) = (1,1,1,1)
        _Border ("Width", Float) = 3

        [Space(5)]
        [Toggle(_APPLYFOG)] _ApplyFog("Enable Fog", Float) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"= "Transparent+59" // +59 smalltest to get drawn on top of transparents
        }
        Pass
        {
            Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}

            Stencil {
                Ref      [_StencilRef]
                ReadMask [_ReadMask]
                Comp     [_StencilCompare]
                Pass     Keep
            }

            Blend SrcAlpha OneMinusSrcAlpha

        //  We only use backfaces here – so we do not need a stencil test. Well - now we use stencil. so only front faces.
        //  Cull Back
            Cull [_Cull]
            ZTest [_ZTest]
        //  Make sure we do not get overwritten
            ZWrite On

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature_local_fragment _APPLYFOG

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"

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

                #if defined(_APPLYFOG)
                    half fogCoord : TEXCOORD0;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.position = TransformObjectToHClip(v.vertex.xyz);
                #if defined(_APPLYFOG)
                    o.fogCoord = ComputeFogFactor(o.position.z);
                #endif
            //  Extrude
                if (_Border > 0.0h) {
                    float3 normal = mul(UNITY_MATRIX_MVP, float4(v.normal, 0)).xyz; // to clip space
                    //float3 normal = mul(GetWorldToHClipMatrix(), mul(GetObjectToWorldMatrix(), float4(v.normal, 0.0)));
                    float2 offset = normalize(normal.xy);
                    float2 ndc = _ScreenParams.xy * 0.5;
                    o.position.xy += ((offset * _Border) / ndc * o.position.w);
                }
                return o;
            }

            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_APPLYFOG)
                    _Color.rgb = MixFog(_Color.rgb, input.fogCoord);
                #endif

                return half4(_Color);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}

