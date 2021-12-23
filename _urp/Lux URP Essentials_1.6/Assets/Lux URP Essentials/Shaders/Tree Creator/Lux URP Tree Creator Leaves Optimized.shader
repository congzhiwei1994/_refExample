// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

// Please note: This shader will never be batched as unity uses Materialpropertyblocks to write per instance properties.

Shader "Lux URP/Nature/Tree Creator Leaves Optimized"
{
    Properties
    {

        [Header(Surface Options)]
        [Space(5)]
        
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0
        [Toggle(_ENABLEDITHERING)]
        _EnableDither               ("Enable Dithering for VR", Float) = 0.0


        [Header(Surface Inputs)]
        [Space(5)]
        [MainColor]
        _Color                      ("Main Color", Color) = (1,1,1,1)
        [MainTexture]
        _MainTex                    ("Base (RGB) Alpha (A)", 2D) = "white" {}
        _Cutoff                     ("Alpha cutoff", Range(0.0, 1.0)) = 0.5

        [NoScaleOffset]
        _BumpSpecMap                ("Normalmap (GA) Spec (R)", 2D) = "bump" {}
        [NoScaleOffset]
        _TranslucencyMap            ("Trans (B) Gloss(A)", 2D) = "white" {}

        [Space(5)]
        _SpecColor                  ("Specular Color", Color) = (0.2, 0.2, 0.2)


        [Header(Transmission)]
        [Space(5)]
        _TranslucencyColor          ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
        _TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
        _ShadowStrength             ("Shadow Strength", Range(0,1)) = 0.8

        [HideInInspector] _ShadowOffsetScale ("Shadow Offset Scale", Float) = 1

        [HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
        [HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
        [HideInInspector] _SquashAmount ("Squash", Float) = 1

    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff

    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "TransparentCutout"
            "IgnoreProjector" = "True"
            "Queue"="AlphaTest"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            // #define _SPECULAR_SETUP 1

            #define _ALPHATEST_ON

            #pragma shader_feature _ENABLEDITHERING
            #pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS

        //  We always have a combined normal map
            // #pragma shader_feature _NORMALMAP
        //  We do not use PBR
            // #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF


            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            // -------------------------------------
            // Unity defined keywords

        //  Trees do not support lightmapping
            // #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Tree Creator Inputs.hlsl"
            #include "Includes/Lux URP Tree Creator Library.hlsl"


            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

        //--------------------------------------
        //  Vertex shader


            VertexOutput LitPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                TreeVertLeaf(input);

                VertexPositionInputs vertexInput; // 
                vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = vertexInput.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                output.positionCS = vertexInput.positionCS;

                output.color = input.color;

                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    output.screenPos = ComputeScreenPos(output.positionCS);
                #endif

                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeSurfaceData(
                float2 uv,
                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    float4 screenPos,
                    half dither,
                #endif
                out SurfaceDescription outSurfaceData)
            {

                half4 albedoAlpha = SampleAlbedoAlpha(uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));

            //  Dither
                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    half coverage = 1.0h;
                    [branch]
                    if (dither < 1.0h) {
                        coverage = ComputeAlphaCoverage(screenPos, dither);
                    }
                    albedoAlpha.a *= coverage;
                #endif
                outSurfaceData.alpha = Alpha(albedoAlpha.a, half4(1,1,1,1), _Cutoff);

                outSurfaceData.albedo = albedoAlpha.rgb; // * _Color.rgb;
            
            //  Normal
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpSpecMap, sampler_BumpSpecMap, uv);
                half3 normal;
                normal.xy = normalSample.ag * 2 - 1;
                normal.xy *= UNITY_ACCESS_INSTANCED_PROP(Props, _SquashAmount);
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                outSurfaceData.normalTS = normal;
                outSurfaceData.specular = normalSample.rrr;
                
                outSurfaceData.occlusion = 1;

            //  Transmission
                half4 maskSample = SAMPLE_TEXTURE2D(_TranslucencyMap, sampler_TranslucencyMap, uv);
                outSurfaceData.translucency = maskSample.b;
                outSurfaceData.gloss = maskSample.a * _Color.a;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif
                
                half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                viewDirWS = SafeNormalize(viewDirWS);
                inputData.viewDirectionWS = viewDirWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                inputData.fogCoord = input.fogFactorAndVertexLight.x;
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
            }

            half4 LitPassFragment(VertexOutput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeSurfaceData(input.uv,
                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    input.screenPos, UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a,
                #endif
                surfaceData);

            //  Apply tree color and occlusion
                surfaceData.albedo *= input.color.rgb;
                surfaceData.occlusion = input.color.a;

            //  Prepare surface data (like bring normal into world space and get missing inputs like gi)
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

            //  Apply lighting
                half4 color = LuxLWRPTreeLeafFragmentPBR (
                    inputData, 
                    surfaceData.albedo,
                    surfaceData.specular, 
                    surfaceData.gloss, 
                    surfaceData.occlusion, 
                    surfaceData.alpha,
                    half2(surfaceData.translucency, _TranslucencyViewDependency),
                    _TranslucencyColor,
                    UNITY_ACCESS_INSTANCED_PROP(Props, _SquashAmount),
                    _ShadowStrength
                );   

            //  Add fog
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }

            ENDHLSL
        }


    //  Shadows -----------------------------------------------------
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON

        //  Usually no shadows during the transition...
            #pragma shader_feature _ENABLEDITHERING
            #pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Tree Creator Inputs.hlsl"
            #include "Includes/Lux URP Tree Creator Library.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                TreeVertLeaf(input);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldDir(input.normalOS);

                #if defined(_ALPHATEST_ON)
                    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                #endif

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

            //  Dither coords - not perfect for shadows but ok.
                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    output.screenPos = ComputeScreenPos(output.positionCS);
                #endif

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

                #if defined(_ALPHATEST_ON)
                    half mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;

                //  Dither
                    #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                        half coverage = 1.0h;
                        half dither = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a; 
                        [branch]
                        if ( dither < 1.0h) {
                            coverage = ComputeAlphaCoverage(input.screenPos, dither );
                        }
                        mask *= coverage;
                    #endif

                    clip (mask - _Cutoff);
                #endif

                return 0;
            }
            ENDHLSL
        }

    //  Depth -----------------------------------------------------

        Pass
        {
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
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
            #define _ALPHATEST_ON

            #pragma shader_feature _ENABLEDITHERING
            #pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5
            
            #define DEPTHONLYPASS
            #include "Includes/Lux URP Tree Creator Inputs.hlsl"
            #include "Includes/Lux URP Tree Creator Library.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                TreeVertLeaf(input);

                #if defined(_ALPHATEST_ON)
                    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                #endif

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    output.screenPos = ComputeScreenPos(output.positionCS);
                #endif

                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
                    half mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;

                //  Dither
                    #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                        half coverage = 1.0h;
                        half dither = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a; 
                        [branch]
                        if ( dither < 1.0h) {
                            coverage = ComputeAlphaCoverage(input.screenPos, dither );
                        }
                        mask *= coverage;
                    #endif

                    clip (mask - _Cutoff);
                #endif

                return 0;
            }

            ENDHLSL
        }

    //  DepthNormal -----------------------------------------------------

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON

            #pragma shader_feature _ENABLEDITHERING
            #pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5
            
            #define DEPTHNORMALONLYPASS
            #include "Includes/Lux URP Tree Creator Inputs.hlsl"
            #include "Includes/Lux URP Tree Creator Library.hlsl"

            VertexOutput DepthNormalsVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                TreeVertLeaf(input);

                #if defined(_ALPHATEST_ON)
                    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                #endif

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                    output.screenPos = ComputeScreenPos(output.positionCS);
                #endif

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, float4(1,1,1,1)); //input.tangentOS);
                output.normalWS.xyz = NormalizeNormalPerVertex(normalInput.normalWS).xyz;

                return output;
            }

            half4 DepthNormalsFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
                    half mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;

                //  Dither
                    #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
                        half coverage = 1.0h;
                        half dither = UNITY_ACCESS_INSTANCED_PROP(Props, _TreeInstanceColor).a; 
                        [branch]
                        if ( dither < 1.0h) {
                            coverage = ComputeAlphaCoverage(input.screenPos, dither );
                        }
                        mask *= coverage;
                    #endif

                    clip (mask - _Cutoff);
                #endif

                float3 normal = input.normalWS;
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(normal, true)), 0.0, 0.0);
            }

            ENDHLSL
        }

    //  End Passes -----------------------------------------------------
    
    }
    FallBack "Hidden/InternalErrorShader"
    Dependency "BillboardShader" = "Hidden/Nature/Lux Tree Creator Leaves Rendertex"
}
