// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "Lux URP/Fast Outline AlphaTested"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(uj834ddvqvmq)]

        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest                      ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                       ("Culling", Float) = 2
        [Enum(Off,0,On,1)]
        _Coverage                   ("Alpha To Coverage", Float) = 0

        [Space(5)]
        [IntRange] _StencilRef      ("Stencil Reference", Range (0, 255)) = 0
        [IntRange] _ReadMask        ("     Read Mask", Range (0, 255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _StencilCompare             ("Stencil Comparison", Int) = 6

        [Header(Outline)]
        [Space(8)]
        _OutlineColor               ("Color", Color) = (1,1,1,1)
        _Border                     ("Width", Float) = 3

        [Space(5)]
        [Toggle(_APPLYFOG)]
        _ApplyFog                   ("Enable Fog", Float) = 0.0      

        [Header(Surface Inputs)]
        [Space(8)]
        [MainColor]
        _BaseColor                  ("Color", Color) = (1,1,1,1)
        [MainTexture]
        _BaseMap                    ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        _Cutoff                     ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _MainTex  ("Albedo", 2D) = "white" {}
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Transparent+59" // +59 smalltest to get drawn on top of transparents
        }
        LOD 100

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

            ZWrite On
            ZTest [_ZTest]
            Cull [_Cull]

            AlphaToMask [_Coverage]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
        //  Shader target needs to be 3.0 due to tex2Dlod in the vertex shader and VFACE
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON
            #pragma shader_feature_local_fragment _APPLYFOG

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Fast Outlines AlphaTested Inputs.hlsl"

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

        //--------------------------------------
        //  Vertex shader

            VertexOutputSimple LitPassVertex(VertexInputSimple input)
            {
                VertexOutputSimple output = (VertexOutputSimple)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput;
                vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                #if defined(_APPLYFOG)
                    output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                #endif
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = vertexInput.positionCS;
                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeSurfaceData(
                float2 uv,
                out SurfaceDescriptionSimple outSurfaceData)
            {
                half innerAlpha = SampleAlbedoAlpha(uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a;

            //  Outline

                float2 offset = float2(1,1);
                float2 shift = fwidth(uv) * _Border * 0.5f;

                float2 sampleCoord = uv + shufflefast(offset, shift); 
                half shuffleAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, sampleCoord).a;

                offset = float2(-1,1);
                sampleCoord = uv + shufflefast(offset, shift);
                shuffleAlpha += SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, sampleCoord).a;

                offset = float2(1,-1);
                sampleCoord = uv + shufflefast(offset, shift);
                shuffleAlpha += SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, sampleCoord).a;

                offset = float2(-1,-1);
                sampleCoord = uv + shufflefast(offset, shift);
                shuffleAlpha += SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, sampleCoord).a;
            //  Mask inner parts - which is not really needed when using the stencil buffer. Let's do it anyway, just in case.
                shuffleAlpha = lerp(shuffleAlpha, 0, step(_Cutoff, innerAlpha) );
            //  Apply clip
                outSurfaceData.alpha = Alpha(shuffleAlpha, 1, _Cutoff);
            }

            void InitializeInputData(VertexOutputSimple input, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(_APPLYFOG)
                    inputData.fogCoord = input.fogFactor;
                #endif
            }

            half4 LitPassFragment(VertexOutputSimple input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescriptionSimple surfaceData;
                InitializeSurfaceData(input.uv, surfaceData);

            //  Prepare surface data (like bring normal into world space and get missing inputs like gi). Super simple here.
                InputData inputData;
                InitializeInputData(input, inputData);

            //  Apply color – as we do not have any lighting.
                half4 color = half4(_OutlineColor.rgb, surfaceData.alpha);    
            //  Add fog
                #if defined(_APPLYFOG)
                    color.rgb = MixFog(color.rgb, inputData.fogCoord);
                #endif

                return color;
            }

            ENDHLSL
        }


    //  End Passes -----------------------------------------------------
    
    }
    FallBack "Hidden/InternalErrorShader"
}