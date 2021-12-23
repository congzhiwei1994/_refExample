// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "Lux URP/Vegetation/Grass"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(iwibq8un2c3h)]
        
        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                       ("Culling", Float) = 0
        [Toggle(_ALPHATEST_ON)]
        _AlphaClip                  ("Alpha Clipping", Float) = 1.0
        _Cutoff                     ("     Threshold", Range(0.0, 1.0)) = 0.5
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0
        

        [Header(Surface Inputs)]
        [Space(8)]
        [NoScaleOffset] [MainTexture]
        _BaseMap                    ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        [HideInInspector] [MainColor]
        _BaseColor                  ("Color", Color) = (1,1,1,1)

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _EnableNormal               ("Enable Normal Map", Float) = 0
        [NoScaleOffset] _BumpMap    ("     Normal Map", 2D) = "bump" {}
        _BumpScale                  ("     Normal Scale", Float) = 1.0

        [Space(5)]
        _Smoothness                 ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecColor                  ("Specular", Color) = (0.2, 0.2, 0.2)
        _Occlusion                  ("Occlusion", Range(0.0, 1.0)) = 1.0

        [Header(Wind)]
        [Space(5)]
        [KeywordEnum(Blue, Alpha)]
        _BendingMode                ("Main Bending", Float) = 0
        [Space(5)]
        [LuxURPWindGrassDrawer]
        _WindMultiplier             ("Wind Strength (X) Normal Strength (Y) Sample Size (Z) Lod Level (W)", Vector) = (1, 2, 1, 0)

        [Header(Distance Fading)]
        [Space(8)]
        [LuxLWRPDistanceFadeDrawer]
        _DistanceFade               ("Distance Fade Params", Vector) = (900, 0.005, 0, 0)

        [Header(Advanced)]
        [Space(8)]
        [Toggle(_BLINNPHONG)]
        _BlinnPhong                 ("Enable Blinn Phong Lighting", Float) = 0.0
        [Space(5)]
        [ToggleOff]
        _SpecularHighlights         ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections     ("Environment Reflections", Float) = 1.0

    //  Needed by the inspector
        [HideInInspector] _Culling  ("Culling", Float) = 0.0

    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _MainTex  ("Albedo", 2D) = "white" {}
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"                     //"RenderType" = "TransparentCutout"
            "IgnoreProjector" = "True"
            "Queue"="Geometry"
            "ShaderModel"="4.5"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            ZWrite On
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_SETUP 1

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma shader_feature_local_fragment _BLINNPHONG
            #pragma shader_feature_local _BENDINGMODE_ALPHA

        //  Needed to make BlinnPhong work
            #define _SPECULAR_COLOR

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
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Grass Inputs.hlsl"

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

            //  VSPro like vertex colors
                #if defined (_BENDINGMODE_ALPHA)
                    #define bendAmount input.color.a
                #else
                    #define bendAmount input.color.b
                #endif
                #define phase input.color.gg
                #define vocclusion input.color.r

                #if !defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    output.fadeOcclusion.x = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                //  Shrinken mesh if alpha testing is disabled
                    input.positionOS.xyz *= output.fadeOcclusion.x;
                #endif

            //  Wind in WorldSpace -------------------------------
                VertexPositionInputs vertexInput; // = GetVertexPositionInputs(input.positionOS.xyz);
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);
            
            //  Do the texture lookup as soon as possible    
                half4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, vertexInput.positionWS.xz * _LuxLWRPWindDirSize.w + phase * _WindMultiplier.z, _WindMultiplier.w);
            
            //  Do as much as possible unrelated to the final position afterwards to hide latency
                    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                    half windStrength = bendAmount * _LuxLWRPWindStrengthMultipliers.x * _WindMultiplier.x;
                    half3 windDir = _LuxLWRPWindDirSize.xyz;
                    half2 normalWindDir = windDir.xz * _WindMultiplier.y;

            //  Set distance fade value
                    #if defined(_ALPHATEST_ON)
                        float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                        float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                        float dist = dot(diff, diff);
                        output.fadeOcclusion.x = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                    #endif

            //  Do other stuff here
                    output.uv.xy = input.texcoord;
                    output.fadeOcclusion.y = lerp(1.0h, vocclusion, _Occlusion);
                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);

            //  From now on we rely on the texture sample being available
                wind.r = wind.r  *  (wind.g * 2.0h - 0.243h  /* not a "real" normal as we want to keep the base direction */ );
                windStrength *= wind.r;
                vertexInput.positionWS.xz += windDir.xz * windStrength; 
            
            //  Do something to the normal as well
                normalInput.normalWS.xz += normalWindDir * windStrength;
                #ifdef _NORMALMAP
                    normalInput.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
                #endif

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
                vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                float4 ndc = vertexInput.positionCS * 0.5f;
                vertexInput.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                vertexInput.positionNDC.zw = vertexInput.positionCS.zw;
            
            //  End Wind -------------------------------

                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.normalWS = normalInput.normalWS;
                output.viewDirWS = viewDirWS;
                #ifdef _NORMALMAP
                    float sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                #endif
                
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = vertexInput.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                output.positionCS = vertexInput.positionCS;

                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            //inline void InitializeGrassLitSurfaceData(float2 uv, half2 fadeOcclusion, out SurfaceDescription outSurfaceData)
            inline void InitializeGrassLitSurfaceData(float2 uv, half2 fadeOcclusion, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
            //  Add fade
                albedoAlpha.a *= fadeOcclusion.x;
            //  Early out
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
            //  Normal Map
                #if defined (_NORMALMAP)
                    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
                    half4 sampleNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
                    outSurfaceData.normalTS = UnpackNormalScale(sampleNormal, _BumpScale);
                #else
                    outSurfaceData.normalTS = float3(0, 0, 1);
                #endif
                
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.occlusion = fadeOcclusion.y;
                outSurfaceData.emission = 0;

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 0;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif
                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                #ifdef _NORMALMAP
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                #else
                    inputData.normalWS = input.normalWS;
                #endif

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
                //SurfaceDescription surfaceData;
                SurfaceData surfaceData;
                InitializeGrassLitSurfaceData(input.uv.xy, input.fadeOcclusion, surfaceData);

            //  Prepare surface data (like bring normal into world space) and get missing inputs like gi
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

            //  Apply lighting
                #if defined(_BLINNPHONG)
                    surfaceData.smoothness = max(0.01, surfaceData.smoothness);
                    //half4 color = LightweightFragmentBlinnPhong(inputData, surfaceData.albedo, half4(surfaceData.specular, surfaceData.smoothness), surfaceData.smoothness, surfaceData.emission, surfaceData.alpha);
                //#else
                    //half4 color = LightweightFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
                #endif

                half4 color = UniversalFragmentPBR(inputData, surfaceData);

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
            Cull[_Cull]

            HLSLPROGRAM
             // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON              // Not per fragment!
            #pragma shader_feature_local _BENDINGMODE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Grass Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

            //  VSPro like vertex colors
                #if defined (_BENDINGMODE_ALPHA)
                    #define bendAmount input.color.a
                #else
                    #define bendAmount input.color.b
                #endif
                #define phase input.color.gg
                #define vocclusion input.color.r

            //  Shrink mesh if alpha testing is disabled
                #if !defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    half fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                //  Shrink mesh
                    input.positionOS.xyz *= fade;
                #endif

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

            //  Wind in WorldSpace -------------------------------
            //  Do the texture lookup as soon as possible 
                half4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, positionWS.xz * _LuxLWRPWindDirSize.w + phase * _WindMultiplier.z, _WindMultiplier.w);
            //  Do as much as possible unrelated to the final position afterwards to hide latency

            //  Calculate world space normal
                    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);    
                
            //  Set distance fade value
                    #if defined(_ALPHATEST_ON)
                        float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                        float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                        float dist = dot(diff, diff);
                        output.fadeOcclusion.x = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                    #endif

            //  Do other stuff here
                    #if defined(_ALPHATEST_ON)
                        output.uv = input.texcoord;
                    #endif

                    half3 windDir = _LuxLWRPWindDirSize.xyz;
                    half windStrength = bendAmount * _LuxLWRPWindStrengthMultipliers.x * _WindMultiplier.x;
            //  From now on we rely on the texture sample being available
                wind.r = wind.r   *   (wind.g * 2.0h - 0.243h  /* not a "real" normal as we want to keep the base direction */ );
                windStrength *= wind.r;
                positionWS.xz += windDir.xz * windStrength;

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
            //  End Wind -------------------------------  

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
                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * input.fadeOcclusion.x, /*_BaseColor*/ half4(1,1,1,1), _Cutoff);
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
            Cull [_Cull]

            HLSLPROGRAM
             // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON          // not per fragment!
            #pragma shader_feature_local _BENDINGMODE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5
            
            #define DEPTHONLYPASS
            #include "Includes/Lux URP Grass Inputs.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  VSPro like vertex colors
                #if defined (_BENDINGMODE_ALPHA)
                    #define bendAmount input.color.a
                #else
                    #define bendAmount input.color.b
                #endif
                #define phase input.color.gg
                #define vocclusion input.color.r

            //  Shrink mesh if alpha testing is disabled
                #if !defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    half fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                //  Shrink mesh
                    input.positionOS.xyz *= fade;
                #endif

            //  Wind in WorldSpace -------------------------------
                VertexPositionInputs vertexInput; // = GetVertexPositionInputs(input.positionOS.xyz);
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);
            //  Do the texture lookup as soon as possible   
                half4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, vertexInput.positionWS.xz * _LuxLWRPWindDirSize.w + phase * _WindMultiplier.z, _WindMultiplier.w);
            //  Do as much as possible unrelated to the final position afterwards to hide latency
                
            //  Calculate fade
                #if defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    output.fadeOcclusion.x = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                #endif

                half windStrength = bendAmount * _LuxLWRPWindStrengthMultipliers.x * _WindMultiplier.x;
                half3 windDir = _LuxLWRPWindDirSize.xyz;

                #if defined(_ALPHATEST_ON)
                    output.uv.xy = input.texcoord;
                #endif

            //  From now on we rely on the texture sample being available
                wind.r = wind.r   *   (wind.g * 2.0h - 0.243h  /* not a "real" normal as we want to keep the base direction */ );
                windStrength *= wind.r;
                vertexInput.positionWS.xz += windDir.xz * windStrength;
            //  End Wind -------------------------------

            //  We have to recalculate ClipPos!
                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * input.fadeOcclusion.x, /*_BaseColor*/ half4(1,1,1,1), _Cutoff);
                #endif
                return 0;
            }

            ENDHLSL
        }

    //  DepthNormals -----------------------------------------------------

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull [_Cull]

            HLSLPROGRAM
             // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON              // not per fragment!
            #pragma shader_feature_local _BENDINGMODE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5
            
            #define DEPTHNORMALPASS
            #include "Includes/Lux URP Grass Inputs.hlsl"

            VertexOutput DepthNormalsVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  VSPro like vertex colors
                #if defined (_BENDINGMODE_ALPHA)
                    #define bendAmount input.color.a
                #else
                    #define bendAmount input.color.b
                #endif
                #define phase input.color.gg
                #define vocclusion input.color.r

            //  Shrink mesh if alpha testing is disabled
                #if !defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    half fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                //  Shrink mesh
                    input.positionOS.xyz *= fade;
                #endif

            //  Wind in WorldSpace -------------------------------
                VertexPositionInputs vertexInput; // = GetVertexPositionInputs(input.positionOS.xyz);
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);
            //  Do the texture lookup as soon as possible   
                half4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, vertexInput.positionWS.xz * _LuxLWRPWindDirSize.w + phase * _WindMultiplier.z, _WindMultiplier.w);
            //  Do as much as possible unrelated to the final position afterwards to hide latency
                
            //  Calculate fade
                #if defined(_ALPHATEST_ON)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    output.fadeOcclusion.x = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                #endif

                half windStrength = bendAmount * _LuxLWRPWindStrengthMultipliers.x * _WindMultiplier.x;
                half3 windDir = _LuxLWRPWindDirSize.xyz;
                half2 normalWindDir = windDir.xz * _WindMultiplier.y;

                #if defined(_ALPHATEST_ON)
                    output.uv.xy = input.texcoord;
                #endif

            //  From now on we rely on the texture sample being available
                wind.r = wind.r   *   (wind.g * 2.0h - 0.243h  /* not a "real" normal as we want to keep the base direction */ );
                windStrength *= wind.r;
                vertexInput.positionWS.xz += windDir.xz * windStrength;
            
            //  Do something to the normal as well
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, float4(1,1,1,1)); //input.tangentOS);
                normalInput.normalWS.xz += normalWindDir * windStrength;
                #ifdef _NORMALMAP
                    normalInput.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
                #endif
                output.normalWS = normalInput.normalWS;


            //  End Wind -------------------------------

            //  We have to recalculate ClipPos!
                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                return output;
            }

            half4 DepthNormalsFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * input.fadeOcclusion.x, /*_BaseColor*/ half4(1,1,1,1), _Cutoff);
                #endif
                float3 normal = input.normalWS;
                normal = TransformWorldToViewDir(normal, true);
            //  Make the normal face the camera!
                normal.z = abs(normal.z);
                return float4(PackNormalOctRectEncode(normal), 0.0, 0.0);
            }

            ENDHLSL
        }

    //  Meta -----------------------------------------------------
        
        Pass
        {
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #define _SPECULAR_SETUP 1
            #pragma shader_feature_local _ALPHATEST_ON
            // 1

        //  First include all our custom stuff
            #include "Includes/Lux URP Grass Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions - usually defined in LitInput.hlsl

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.alpha = Alpha(albedoAlpha.a, half4(1.0h, 1.0h, 1.0h, 1.0h), _Cutoff);
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 1.0h; // crazy?
                outSurfaceData.specular = _SpecColor;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = half3(0,0,1);
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0.5h;

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 0;
            }

        //  Finally include the meta pass related stuff  
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

    //  End Passes -----------------------------------------------------
    
    }
    FallBack "Hidden/InternalErrorShader"
    CustomEditor "LuxURPCustomSingleSidedShaderGUI"
}