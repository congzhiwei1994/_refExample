Shader "Lux URP/Billboard"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(miywznst4xsx)]

        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest                      ("ZTest", Int) = 4
        [Enum(Tested,0,Blended,1)]
        _Surface                    ("Alpha", Float) = 0.0
        _Cutoff                     ("    Threshold", Range(0.0, 1.0)) = 0.5
        [Enum(Transparent,0,Additive,1,SoftAdditive,2)]
        _Blend                      ("    Blending", Float) = 0.0
        [Space(5)]
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0
        _ShadowOffset               ("Billboard Shadow Offset", Float) = 1.0


        [Header(Billboard Options)]
        [Space(8)]
        [Toggle(_UPRIGHT)]
        _Upright                    ("Enable upright oriented Billboard", Float) = 0.0
        [Toggle(_PIVOTTOBOTTOM)]
        _Pivot                      ("Set Pivot to Bottom", Float) = 0.0
        
        _Shrink                     ("Expand X", Range(0.0, 1.0)) = 1.0


        [Header(Surface Inputs)]
        [MainColor]
        [HDR]_BaseColor             ("Base Color", Color) = (1,1,1,1)
        [NoScaleOffset] [MainTexture]
        _BaseMap                    ("Albedo (RGB) Alpha (A)", 2D) = "white" {}


        [Header(Lighting)]
        [Space(8)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                ("Enable Lighting", Float) = 0.0
        [Space(5)]
        [NoScaleOffset]
        _BumpMap                    ("    Normal Map", 2D) = "bump" {}
        _BumpScale                  ("    Normal Scale", Float) = 1.0

        _Smoothness                 ("    Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecColor                  ("    Specular", Color) = (0.2, 0.2, 0.2)


        [Header(Fog)]
        [Space(8)]
        //[Toggle(_APPLYFOG)] _ApplyFog("Enable Fog", Float) = 1.0
        [Toggle] _ApplyFog          ("Enable Fog", Float) = 1.0

        [Header(Render Queue)]
        [Space(8)]
        [IntRange] _QueueOffset     ("Queue Offset", Range(-50, 50)) = 0

        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights         ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections     ("Environment Reflections", Float) = 1.0

        [HideInInspector] _ZWrite   ("__zw", Float) = 1.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0

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
            "Queue" = "Transparent"
            "DisableBatching" = "True" // Has nor effet on static batching?!
            "PreviewType" = "Plane"
        }
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            Cull Back
            ZTest [_ZTest]
            ZWrite[_ZWrite]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_SETUP 1
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON

            #pragma shader_feature_local _UPRIGHT
            #pragma shader_feature_local _PIVOTTOBOTTOM
            #pragma shader_feature_local _APPLYFOG _APPLYFOGADDITIVELY

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

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
            
            #include "Includes/Lux URP Billboard Inputs.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS : POSITION;
                float2 uv : TEXCOORD0;

                float3 positionWS : TEXCOORD1;
                
                #if defined(_APPLYFOG) || defined (_APPLYFOGADDITIVELY)
                    half fogCoord : TEXCOORD2;
                #endif

                #ifdef _NORMALMAP
                    half4 normalWS : TEXCOORD3;
                    half4 tangentWS : TEXCOORD4;
                    half4 bitangentWS : TEXCOORD5;
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        float4 shadowCoord : TEXCOORD6;
                    #endif
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert (VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  Instance world position
                float3 positionWS = float3(UNITY_MATRIX_M[0].w, UNITY_MATRIX_M[1].w, UNITY_MATRIX_M[2].w);
                half3 viewDirWS = normalize(GetCameraPositionWS() - positionWS);

                #if !defined(_UPRIGHT)
                    input.positionOS.xyz = 0;
                    #if defined(_PIVOTTOBOTTOM)
                        input.positionOS.xy = input.texcoord.xy - float2(0.5f, 0.0f);
                    #else
                        input.positionOS.xy = input.texcoord.xy - 0.5;
                    #endif
                    input.positionOS.x *= _Shrink;

                    float2 scale;
                //  Using unity_ObjectToWorld may break. So we use the official function.
                    scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                    scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));

                    float4 positionVS = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1.0));
                    positionVS.xyz += input.positionOS.xyz * float3(scale.xy, 1.0);
                    output.positionCS = mul(UNITY_MATRIX_P, positionVS);
                    output.positionWS = mul(UNITY_MATRIX_I_V, positionVS).xyz;

                //  we have to make the normal point towards the cam
                    half3 billboardTangentWS = normalize(float3(-viewDirWS.z, 0, viewDirWS.x));
                    half3 billboardNormalWS = viewDirWS; //float3(billboardTangentWS.z, 0, -billboardTangentWS.x);
                //  Sign!
                    half3 billboardBitangentWS = -cross(billboardNormalWS, billboardTangentWS);
                    
                #else
                    half3 billboardTangentWS = normalize(float3(-viewDirWS.z, 0, viewDirWS.x));
                    half3 billboardNormalWS = float3(billboardTangentWS.z, 0, -billboardTangentWS.x);
                //  Sign!
                    half3 billboardBitangentWS = -cross(billboardNormalWS, billboardTangentWS);
                    
                //  Expand Billboard
                    float2 percent = input.texcoord.xy;
                    float3 billboardPos = (percent.x - 0.5) * _Shrink * billboardTangentWS;
                    #if defined(_PIVOTTOBOTTOM)
                        billboardPos.y += percent.y;
                    #else
                        billboardPos.y += percent.y - 0.5;
                    #endif

                    output.positionWS = TransformObjectToWorld(billboardPos).xyz;
                    output.positionCS = TransformWorldToHClip(output.positionWS);
                #endif

                output.uv = input.texcoord.xy;
                output.uv.x = (output.uv.x - 0.5) * _Shrink + 0.5;

                #ifdef _NORMALMAP
                //  Recalulate viewDirWS
                    viewDirWS = normalize(GetCameraPositionWS() - output.positionWS);
                    output.normalWS = half4(billboardNormalWS, viewDirWS.x);
                    output.tangentWS = half4(billboardTangentWS, viewDirWS.y);
                    output.bitangentWS = half4(billboardBitangentWS, viewDirWS.z);
                
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                    #endif

                #endif

                //half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                //half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                //output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                #if defined(_APPLYFOG) || defined(_APPLYFOGADDITIVELY)
                    output.fogCoord = ComputeFogFactor(output.positionCS.z);
                #endif

                return output;
            }

            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

                albedoAlpha.rgb *= _BaseColor.rgb;

                #ifdef _NORMALMAP
                    half3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                    half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));

                    //col.rgb = normalize(normalWS) * 0.5 + 0.5;

                    InputData inputData = (InputData)0;
                    inputData.positionWS = input.positionWS;
                    inputData.normalWS = NormalizeNormalPerPixel(normalWS);
                    inputData.viewDirectionWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
                    //inputData.fogCoord = 0;
                    //inputData.vertexLighting = 0;
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = input.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif
                //  We have to sample SH per pixel
                    inputData.bakedGI = SampleSH(inputData.normalWS);

                    half4 color = UniversalFragmentPBR(
                        inputData,
                        albedoAlpha.rgb,    // albedo
                        0,                  // metallic,
                        _SpecColor,         // specular
                        _Smoothness,        // smoothness,
                        1.0h,               // occlusion,
                        0,                  // emission,
                        alpha               // alpha
                    );
                #else
                    half4 color = albedoAlpha;
                #endif

                           
                #if defined(_APPLYFOGADDITIVELY)
                    color.rgb = MixFogColor(color.rgb, half3(0,0,0), input.fogCoord);
                #endif
                #if defined(_APPLYFOG) 
                    color.rgb = MixFog(color.rgb, input.fogCoord);
                #endif

                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0 


            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON 1

            #pragma shader_feature_local _UPRIGHT
            #pragma shader_feature_local _PIVOTTOBOTTOM

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Includes/Lux URP Billboard Inputs.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if !defined(_UPRIGHT)

                    input.positionOS.xyz = 0;
                    #if defined(_PIVOTTOBOTTOM)
                        input.positionOS.xy = input.texcoord.xy - float2(0.5f, 0.0f);
                    #else
                        input.positionOS.xy = input.texcoord.xy - 0.5;
                    #endif
                    input.positionOS.x *= _Shrink;

                    float2 scale;
                    scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                    scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));

                    float4 positionVS = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1.0));
                    positionVS.xyz += input.positionOS.xyz * float3(scale.xy, 1.0);
                    float3 positionWS = mul(UNITY_MATRIX_I_V, positionVS).xyz;
                    positionWS -= _LightDirection * _ShadowOffset;
                #else
                    half3 viewDirWS = _LightDirection;
                    half3 billboardTangentWS = normalize(float3(-viewDirWS.z, 0, viewDirWS.x));
                //  Expand Billboard
                    float2 percent = input.texcoord.xy;
                    float3 billboardPos = (percent.x - 0.5) * billboardTangentWS;
                    #if defined(_PIVOTTOBOTTOM)
                        billboardPos.y += percent.y;
                    #else
                        billboardPos.y += percent.y - 0.5;
                    #endif
                    float3 positionWS = TransformObjectToWorld(float4(billboardPos, 1)).xyz;
                    positionWS -= _LightDirection * _ShadowOffset;
                #endif

                half3 normalWS = -_LightDirection;
                output.uv = input.texcoord;

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                return output;
            }

            half4 ShadowPassFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                return 0;
            }
            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ZTest [_ZTest]
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0 

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON 1

            #pragma shader_feature_local _UPRIGHT
            #pragma shader_feature_local _PIVOTTOBOTTOM

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #include "Includes/Lux URP Billboard Inputs.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                #if !defined(_UPRIGHT)
                    input.positionOS.xyz = 0;
                    #if defined(_PIVOTTOBOTTOM)
                        input.positionOS.xy = input.texcoord.xy - float2(0.5f, 0.0f);
                    #else
                        input.positionOS.xy = input.texcoord.xy - 0.5;
                    #endif
                    input.positionOS.x *= _Shrink;

                    float2 scale;
                    scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                    scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));

                    float4 positionVS = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1.0));
                    positionVS.xyz += input.positionOS.xyz * float3(scale.xy, 1.0);
                    output.positionCS = mul(UNITY_MATRIX_P, positionVS);
                #else
                //  Instance world position
                    float3 positionWS = float3(UNITY_MATRIX_M[0].w, UNITY_MATRIX_M[1].w, UNITY_MATRIX_M[2].w);
                    half3 viewDirWS = normalize(GetCameraPositionWS() - positionWS);
                    half3 billboardTangentWS = normalize(float3(-viewDirWS.z, 0, viewDirWS.x));
                //  Expand Billboard
                    float2 percent = input.texcoord.xy;
                    float3 billboardPos = (percent.x - 0.5) * billboardTangentWS;
                    #if defined(_PIVOTTOBOTTOM)
                        billboardPos.y += percent.y;
                    #else
                        billboardPos.y += percent.y - 0.5;
                    #endif
                    output.positionCS = TransformObjectToHClip(billboardPos);
                #endif

                output.uv = input.texcoord;

                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a , _BaseColor, _Cutoff);
                return 0;
            }
            ENDHLSL
        }

    }
    FallBack "Hidden/InternalErrorShader"
    CustomEditor "LuxURPCustomBillboardShaderGUI"
}