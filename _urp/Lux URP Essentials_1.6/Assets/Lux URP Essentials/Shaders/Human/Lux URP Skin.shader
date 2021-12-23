// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "Lux URP/Human/Skin"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(snoamqpqhtdl)]
        
        [Header(Surface Options)]
        [Space(8)]
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0
        _SkinShadowBias             ("     Shadow Caster Bias", Range(.1, 1.0)) = 1.0
        _SkinShadowSamplingBias     ("     Shadow Sampling Bias", Range(0, 0.05)) = 0
        
        [Header(Surface Inputs)]
        [Space(8)]
        [NoScaleOffset] [MainTexture]
        _BaseMap                    ("Albedo (RGB) Smoothness (A)", 2D) = "white" {}
        [MainColor]
        _BaseColor                  ("Color", Color) = (1,1,1,1)
        
        [Space(5)]
        _Smoothness                 ("Smoothness", Range(0.0, 1.0)) = 0.5
    //  For some reason android did not like _SpecColor!?
        _SpecularColor              ("Specular", Color) = (0.2, 0.2, 0.2)

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                ("Enable Normal Map", Float) = 0.0
        [NoScaleOffset]
        _BumpMap                    ("     Normal Map", 2D) = "bump" {}
        _BumpScale                  ("     Normal Scale", Float) = 1.0
        [Toggle(_NORMALMAPDIFFUSE)]
        _ApplyNormalDiffuse         ("     Enable Diffuse Normal Sample", Float) = 0.0
        _Bias                       ("     Bias", Range(0.0, 8.0)) = 3.0
        [Toggle]_VertexNormal       ("          Use Vertex Normal for Diffuse", Float) = 1

        [Header(Skin Lighting)]
        [Space(8)]
        [NoScaleOffset] _SSSAOMap   ("Skin Mask (R) Thickness (G) Curvature (B) Occlusion (A)", 2D) = "white" {}
        
        _OcclusionStrength          ("Occlusion Strength", Range(0.0, 1.0)) = 1.0

        [Toggle]
        _SampleCurvature            ("Sample Curvature", Float) = 0
        _Curvature                  ("Curvature", Range(0.0, 1.0)) = 0.5

        _SubsurfaceColor            ("Subsurface Color", Color) = (1.0, 0.4, 0.25, 1.0)
        _TranslucencyPower          ("Transmission Power", Range(0.0, 10.0)) = 7.0
        _TranslucencyStrength       ("Transmission Strength", Range(0.0, 1.0)) = 1.0
        _ShadowStrength             ("Shadow Strength", Range(0.0, 1.0)) = 0.7
        _MaskByShadowStrength       ("Mask by incoming Shadow Strength", Range(0.0, 1.0)) = 1.0
        _Distortion                 ("Transmission Distortion", Range(0.0, 0.1)) = 0.01

        [Space(5)]
        [Toggle(_BACKSCATTER)]
        _EnableBackscatter          ("Enable Ambient Back Scattering", Float) = 0
        _Backscatter                ("Ambient Back Scattering", Range(0.0, 8.0)) = 1

        [Space(5)]
        _AmbientReflectionStrength  ("Ambient Reflection Strength", Range(0.0, 1)) = 1

        [Space(5)]
        [NoScaleOffset] _SkinLUT    ("Skin LUT", 2D) = "white" {}

        [Header(Distance Fading)]
        [Space(8)]
        [Toggle(_DISTANCEFADE)]
        _EnableDistanceFade         ("Enable Distance Fade", Float) = 0.0
        [LuxURPDistanceFadeDrawer]
        _DistanceFade               ("Distance Fade Params", Vector) = (2500, 0.001, 0, 0)


        [Header(Rim Lighting)]
        [Space(8)]
        [Toggle(_RIMLIGHTING)]
        _Rim                        ("Enable Rim Lighting", Float) = 0
        [HDR] _RimColor             ("Rim Color", Color) = (0.5,0.5,0.5,1)
        _RimPower                   ("Rim Power", Float) = 2
        _RimFrequency               ("Rim Frequency", Float) = 0
        _RimMinPower                ("     Rim Min Power", Float) = 1
        _RimPerPositionFrequency    ("     Rim Per Position Frequency", Range(0.0, 1.0)) = 1

        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights         ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections     ("Environment Reflections", Float) = 1.0


        [Header(Stencil)]
        [Space(8)]
        [IntRange] _Stencil         ("Stencil Reference", Range (0, 255)) = 0
        [IntRange] _ReadMask        ("     Read Mask", Range (0, 255)) = 255
        [IntRange] _WriteMask       ("     Write Mask", Range (0, 255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _StencilComp                ("Stencil Comparison", Int) = 8     // always 
        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilOp                  ("Stencil Operation", Int) = 0      // 0 = keep, 2 = replace
        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilFail                ("Stencil Fail Op", Int) = 0        // 0 = keep
        [Enum(UnityEngine.Rendering.StencilOp)] 
        _StencilZFail               ("Stencil ZFail Op", Int) = 0       // 0 = keep

    //  Needed by the inspector
        [HideInInspector] _Culling  ("Culling", Float) = 0.0

    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _MainTex  ("Albedo", 2D) = "white" {}
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
        [HideInInspector] _Cutoff   ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0

    //  URP 10.1. needs this for the depthnormal pass 
        [HideInInspector] _Cutoff   ("     Threshold", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Surface("__surface", Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Stencil {
                Ref   [_Stencil]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
                Comp  [_StencilComp]
                Pass  [_StencilOp]
                Fail  [_StencilFail]
                ZFail [_StencilZFail]
            }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_SETUP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _NORMALMAPDIFFUSE
            #pragma shader_feature_local_fragment _DISTANCEFADE
            #pragma shader_feature_local_fragment _RIMLIGHTING
            #pragma shader_feature_local_fragment _BACKSCATTER

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
            #include "Includes/Lux URP Skin Inputs.hlsl"

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

            //  Set distance fade value
                #if defined(_DISTANCEFADE)
                    float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                    float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                    float dist = dot(diff, diff);
                    output.fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                #else
                    output.fade = 1.0h;
                #endif

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv.xy = input.texcoord;

                output.normalWS = normalInput.normalWS; //NormalizeNormalPerVertex(normalInput.normalWS);
                output.viewDirWS = viewDirWS;

                #ifdef _NORMALMAP
                    float sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                #endif

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = vertexInput.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                //  tweak the sampling position
                    vertexInput.positionWS += output.normalWS.xyz * _SkinShadowSamplingBias;
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                output.positionCS = vertexInput.positionCS;

                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeSkinLitSurfaceData(float2 uv, half fade, out SurfaceDescription outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor;

                outSurfaceData.alpha = 1;
                
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecularColor;
            
            //  Normal Map
                #if defined (_NORMALMAP)
                    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                    #if defined(_NORMALMAPDIFFUSE)
                        half4 sampleNormalDiffuse = SAMPLE_TEXTURE2D_BIAS(_BumpMap, sampler_BumpMap, uv, _Bias);
                    //  Do not manually unpack the normal map as it might use RGB.
                        outSurfaceData.diffuseNormalTS = UnpackNormal(sampleNormalDiffuse);
                    #else
                        outSurfaceData.diffuseNormalTS = half3(0,0,1);
                    #endif
                #else
                    outSurfaceData.normalTS = half3(0,0,1);
                    outSurfaceData.diffuseNormalTS = half3(0,0,1);
                #endif

                half4 SSSAOSample = SAMPLE_TEXTURE2D(_SSSAOMap, sampler_SSSAOMap, uv);
                outSurfaceData.translucency = SSSAOSample.g;
                outSurfaceData.skinMask = SSSAOSample.r;
                outSurfaceData.occlusion = lerp(1.0h, SSSAOSample.a, _OcclusionStrength);
                outSurfaceData.curvature = SSSAOSample.b;

                outSurfaceData.smoothness = albedoAlpha.a * _Smoothness;
                outSurfaceData.emission = 0;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, half3 diffuseNormalTS, out InputData inputData
                #ifdef _NORMALMAP
                    , inout float3 bitangent
                #endif
                , inout half3 diffuseNormalWS
                )
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif
                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                
                #ifdef _NORMALMAP
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 ToW = half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, ToW);
                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                    #ifdef _NORMALMAPDIFFUSE
                        diffuseNormalWS = TransformTangentToWorld(diffuseNormalTS, ToW);
                        diffuseNormalWS = NormalizeNormalPerPixel(diffuseNormalWS);
                    #else
                    //  Here we let the user decide to use the per vertex or the specular normal.
                        diffuseNormalWS = (_VertexNormal) ? NormalizeNormalPerPixel(input.normalWS.xyz) : inputData.normalWS;
                    #endif
                #else
                    inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
                    diffuseNormalWS = inputData.normalWS;
                #endif

                inputData.viewDirectionWS = viewDirWS;
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS + input.normalWS * _SkinShadowSamplingBias);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                inputData.fogCoord = input.fogFactorAndVertexLight.x;
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, diffuseNormalWS); //inputData.normalWS);

                //inputData.normalizedScreenSpaceUV = input.positionCS.xy;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
            }

            half4 LitPassFragment(VertexOutput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeSkinLitSurfaceData(input.uv.xy, input.fade, surfaceData);

            //  Prepare surface data (like bring normal into world space and get missing inputs like gi
                half3 diffuseNormalWS;
                InputData inputData;
                #ifdef _NORMALMAP
                    float3 bitangent;
                #endif
                InitializeInputData(input, surfaceData.normalTS, surfaceData.diffuseNormalTS, inputData
                    #ifdef _NORMALMAP
                        , bitangent
                    #endif
                    , diffuseNormalWS
                );

                #if defined(_RIMLIGHTING)
                    half rim = saturate(1.0h - saturate( dot(inputData.normalWS, inputData.viewDirectionWS) ) );
                    half power = _RimPower;
                    UNITY_BRANCH if(_RimFrequency > 0 ) {
                        half perPosition = lerp(0.0h, 1.0h, dot(1.0h, frac(UNITY_MATRIX_M._m03_m13_m23) * 2.0h - 1.0h ) * _RimPerPositionFrequency ) * 3.1416h;
                        power = lerp(power, _RimMinPower, (1.0h + sin(_Time.y * _RimFrequency + perPosition) ) * 0.5h );
                    }
                    surfaceData.emission += pow(rim, power) * _RimColor.rgb * _RimColor.a;
                #endif

            //  Apply lighting
                half4 color = LuxLWRPSkinFragmentPBR(
                    inputData, 
                    surfaceData.albedo, 
                    surfaceData.metallic, 
                    surfaceData.specular, 
                    surfaceData.smoothness, 
                    surfaceData.occlusion, 
                    surfaceData.emission, 
                    surfaceData.alpha,
                //  Subsurface Scattering
                    half4(_TranslucencyStrength * surfaceData.translucency, _TranslucencyPower, _ShadowStrength, _Distortion),
                //  AmbientReflection Strength
                    _AmbientReflectionStrength,
                //  Diffuse Normal
                    // #if defined(_NORMALMAP) && defined(_NORMALMAPDIFFUSE)
                    //     NormalizeNormalPerPixel( TransformTangentToWorld(surfaceData.diffuseNormalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz)) )
                    // #else
                    //     input.normalWS
                    // #endif
                    diffuseNormalWS,
                    _SubsurfaceColor,
                    (_SampleCurvature) ? surfaceData.curvature * _Curvature : lerp(surfaceData.translucency, 1, _Curvature),
                //  Lerp lighting towards standard according the distance fade
                    surfaceData.skinMask * input.fade,
                    _MaskByShadowStrength,
                    _Backscatter
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


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Skin Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldDir(input.normalOS);

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS * _SkinShadowBias, _LightDirection));
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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #define DEPTHONLYPASS
            #include "Includes/Lux URP Skin Inputs.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return 0;
            }

            ENDHLSL
        }

    //  Depth Normals --------------------------------------------
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Includes/Lux URP Skin Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        } 


    //  Meta -----------------------------------------------------
        
        Pass
        {
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #define _SPECULAR_SETUP

        //  First include all our custom stuff
            #include "Includes/Lux URP Skin Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.alpha = 1;
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecularColor;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = half3(0,0,1);
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0;

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 0;
            }

        //  Finally include the meta pass related stuff  
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

    //  End Passes -----------------------------------------------------
    
    }
    CustomEditor "LuxURPCustomSkinShaderGUI"
    FallBack "Hidden/InternalErrorShader"
}
