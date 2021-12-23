// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "Lux URP/Glass"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(3fte1chjgh54)]

        [Header(Surface Options)]
        [Space(8)]
        [Enum(Off,0,On,1)]_ZWrite   ("ZWrite", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                       ("Culling", Float) = 2
        [Enum(None,0,Transparent,1,Additive,2)]
        _Blend                      ("Blending", Float) = 0.0
        _FinalAlpha                 ("     Final Alpha", Range(0.0, 1.0)) = 0.5
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0


        [Header(Surface Inputs)]
        [Space(8)]
        [MainColor]
        _BaseColor                  ("Color (RGB) Alpha (A)", Color) = (1,1,1,0)
        [Toggle(_BASEMAP)]
        _EnableBaseMap              ("Enable Base Map", Float) = 0.0
        [MainTexture]
        _BaseMap                    ("     Albedo (RGB) Alpha (A)", 2D) = "white" {}

        [Space(5)]
        _Smoothness                 ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SmoothnessBase             ("     Smoothness Opaque", Range(0.0, 1.0)) = 0.5
        _SpecColor                  ("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecColorBase              ("     Specular Opaque", Color) = (0.2, 0.2, 0.2)

        [Space(5)]
        [Toggle(_MASKMAP)]
        _EnableMaskMap              ("Enable Mask Map", Float) = 0.0
        [NoScaleOffset] _MaskMap    ("     Thickness Mask (R) Smoothness (A)", 2D) = "white" {}

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                ("Enable Normal Map", Float) = 0.0
        [NoScaleOffset] _BumpMap    ("     Normal Map", 2D) = "bump" {}
        _BumpScale                  ("     Normal Scale", Float) = 1.0


        [Header(Refrection)]
        [Space(8)]
        [Toggle(_GEOREFRACTIONS)]
        _EnableGeoRefr              ("Enable geometric Refractions", Float) = 1.0
        _IOR                        ("     Index of Refraction", Float) = 1.33
        _IsThinShell                ("     Thin Shell", Range(0.0, 0.98)) = 0

        [Space(5)] 
        [Toggle(_SCREENEDGEFADE)]
        _EnableScreenEdgeFade       ("Enable Screen Edge Fade", Float) = 0.0
        _ScreenEdgeFade             ("     Fade Width", Range(8.0, 32.0)) = 8

        [Space(5)]     
        _BumpRefraction             ("Bump Distortion", Range(0.0, 1.0)) = 0.1

        [Space(5)] 
        [Toggle(_EXCLUDEFOREGROUND)]
        _ExcludeForeground          ("Exclude Foreground", Float) = 0.0

        
        [Header(Rim Lighting)]
        [Space(8)]
        [Toggle(_RIMLIGHTING)]
        _Rim                        ("Enable Rim Lighting", Float) = 0
        [HDR] _RimColor             ("Rim Color", Color) = (0.5,0.5,0.5,1)
        _RimPower                   ("Rim Power", Float) = 2
        _RimFrequency               ("Rim Frequency", Float) = 0
        _RimMinPower                ("     Rim Min Power", Float) = 1
        _RimPerPositionFrequency    ("     Rim Per Position Frequency", Range(0.0, 1.0)) = 1


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


        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights         ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections     ("Environment Reflections", Float) = 1.0
        [Space(5)]

        [HideInInspector] _SrcBlend ("SrcBlend", Float) = 1.0
        [HideInInspector] _DstBlend ("_DstBlend", Float) = 0.0
        
    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _MainTex  ("Albedo", 2D) = "white" {}
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
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
            
            ZWrite [_ZWrite]
            Cull [_Cull]
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_SETUP 1

            // #pragma shader_feature _ALPHATEST_ON

            #define _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local _NORMALMAP

            #pragma shader_feature_local_fragment _GEOREFRACTIONS
            #pragma shader_feature_local_fragment _SCREENEDGEFADE

            #pragma shader_feature_local_fragment _FINALALPHA
            #pragma shader_feature_local_fragment _ADDITIVE
            #pragma shader_feature_local_fragment _BASEMAP
            #pragma shader_feature_local_fragment _MASKMAP
            #pragma shader_feature_local_fragment _EXCLUDEFOREGROUND
            #pragma shader_feature_local_fragment _RIMLIGHTING

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING

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
            #include "Includes/Lux URP Glass Inputs.hlsl"

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

                VertexPositionInputs vertexInput; // 
                vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);

                output.normalWS = normalInput.normalWS; //NormalizeNormalPerVertex(normalInput.normalWS);
                output.viewDirWS = viewDirWS;
                
                #ifdef _NORMALMAP
                    float sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                #endif

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                //#ifdef _ADDITIONAL_LIGHTS
                    output.positionWS = vertexInput.positionWS;
                //#endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                output.positionCS = vertexInput.positionCS;

                output.projectionCoord = vertexInput.positionNDC;
            //  Store Eye Depth
                output.projectionCoord.z = LinearEyeDepth(output.projectionCoord.z / output.projectionCoord.w, _ZBufferParams);

                float3 scale;
                scale.x = length(float3(UNITY_MATRIX_MV[0].x, UNITY_MATRIX_MV[1].x, UNITY_MATRIX_MV[2].x));
                scale.y = length(float3(UNITY_MATRIX_MV[0].y, UNITY_MATRIX_MV[1].y, UNITY_MATRIX_MV[2].y));
                scale.z = length(float3(UNITY_MATRIX_MV[0].z, UNITY_MATRIX_MV[1].z, UNITY_MATRIX_MV[2].z));
                output.scale = max(scale.x, max(scale.y, scale.z));

                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeSurfaceData(
                float2 uv,
                float4 projectionCoord,
                half3 normalWS,
                half3 viewDirWS,
                float3 positionWS,
                float scale,
                half facing,
                out SurfaceDescription outSurfaceData)
            {

                #if defined(_BASEMAP)
                    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, 0.0h);
                    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                #else
                    outSurfaceData.alpha = _BaseColor.a;
                    outSurfaceData.albedo = _BaseColor.rgb;
                #endif

            //  Normal Map
                #if defined (_NORMALMAP)
                    outSurfaceData.normalTS = SampleNormal(uv.xy, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                #else
                    outSurfaceData.normalTS = half3(0,0,1);
                #endif

            //  Mask Map (Glass)
                #if defined(_MASKMAP)
                    half4 maskSample = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv.xy);
                #else
                    half4 maskSample = half4(0,1,1,1);
                #endif

            //  ///////////////////////////////////////
            //  Refraction

            //  Handle VFACE separatly for refractions
                normalWS *= facing;
                float NdotV = saturate(dot(normalWS, viewDirWS));

                #if defined(_GEOREFRACTIONS)
                    half isThinShell = _IsThinShell
                        #if defined(_MASKMAP)
                            * maskSample.r
                        #endif
                    ;
                
                //  Tweak ior to handle solid and thin shell refractions
                    half myior = lerp(_IOR * 2.0h /* as we skip the 2nd, outgoing refraction*/, 1.0h, isThinShell);
                    half3 refractWS = refract(-viewDirWS, normalWS, rcp(myior) );
                    half rayLength = -dot(normalWS, refractWS);
                    float3 rayOriginWS = positionWS + (refractWS * rayLength);
                    float3 refractedPointWS = rayOriginWS + (refractWS * scale);

                //  Calculate the sample UVs
                //  Transform world space coordinates to clip space
                    float4 screenUV = TransformWorldToHClip(refractedPointWS);      // Clip space
                //  Transform from clip space to NDC
                    #if UNITY_UV_STARTS_AT_TOP
                        screenUV.y = -screenUV.y;
                    #endif
                    screenUV *= rcp(screenUV.w);                                    // Perspective
                //  Final sample UVs
                    screenUV.xy = screenUV.xy * 0.5f + 0.5f;                        // NDC
                
                #else
                    float2 screenUV = projectionCoord.xy * rcp(projectionCoord.w);
                #endif
                    
                #if defined(_NORMALMAP)
                    screenUV.xy +=  (outSurfaceData.normalTS.xy * _BumpRefraction) * rcp(projectionCoord.w);
                #endif

            //  Clamp at screen edges
                #if defined(_SCREENEDGEFADE)
                    float2 coordCS = screenUV.xy * 2 - 1;
                    float fadeRcpLength = _ScreenEdgeFade;
                    float2 t = Remap10(abs(coordCS), fadeRcpLength, fadeRcpLength);
                    float weight = Smoothstep01(t.x) * Smoothstep01(t.y);
                    screenUV.xy = lerp(projectionCoord.xy/projectionCoord.w, screenUV.xy, weight);
                #endif

            //  Fix screenUV for Single Pass Stereo Rendering
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    //screenUV.x = screenUV.x * 0.5f + (float)unity_StereoEyeIndex * 0.5f;
                    screenUV.xy = UnityStereoTransformScreenSpaceTex(screenUV.xy);
                #endif

            //  Check depth
                #if defined(_EXCLUDEFOREGROUND)
                    #if defined(SHADER_API_GLES)
                        float refractedSceneDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV.xy, 0);
                    #else
                        //float refractedSceneDepth = LOAD_TEXTURE2D_X_LOD(_CameraDepthTexture, _CameraDepthTexture_TexelSize.zw * screenUV.xy, 0).x;
                        float refractedSceneDepth = LOAD_TEXTURE2D_X(_CameraDepthTexture, _CameraDepthTexture_TexelSize.zw * saturate(screenUV.xy)).x;
                    #endif
                //  TODO: add ortho support
                    refractedSceneDepth = LinearEyeDepth(refractedSceneDepth, _ZBufferParams);
                    float refractionOffsetMultiplier = saturate(refractedSceneDepth - projectionCoord.z);
                    screenUV.xy = lerp( 
                    #if defined(UNITY_SINGLE_PASS_STEREO)
                        UnityStereoTransformScreenSpaceTex(projectionCoord.xy/projectionCoord.w),
                    #else
                        projectionCoord.xy/projectionCoord.w,
                    #endif
                        screenUV.xy, refractionOffsetMultiplier);
                #endif

            //  Just like separate texture + sampler syntax, inline sampler states are not supported on some platforms.
            //  Currently they are implemented on Direct3D 11/12, PS4, XboxOne and Metal.
                #if defined(_EXCLUDEFOREGROUND)
                    //half3 RefractionSample = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV ).rgb;
                    half3 RefractionSample = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_LinearClamp, screenUV.xy).rgb;
                #else
                    #if defined(SHADER_API_D3D11) || defined(SHADER_API_PS4) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_METAL)
                        //half3 RefractionSample = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, my_linear_clamp_sampler, screenUV).rgb;
                        half3 RefractionSample = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_LinearClamp, screenUV.xy).rgb;
                    #else
                        //half3 RefractionSample = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV ).rgb;
                        half3 RefractionSample = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_LinearClamp, screenUV.xy).rgb;
                    #endif
                #endif
            
            //  Tint glass
                half3 glassTint = outSurfaceData.albedo;
                outSurfaceData.emission = RefractionSample * glassTint * max(0.5h, 1.0h - F_Schlick(_SpecColor, NdotV)) * (1.0h - outSurfaceData.alpha);

                //outSurfaceData.emission = weight;

            //  ///////////////////////////////////////

                #if defined(_MASKMAP)
                    outSurfaceData.smoothness = _Smoothness * maskSample.a;
                #else
                    outSurfaceData.smoothness = _Smoothness;
                #endif

            //  Lerp between glass and opaque properties
                outSurfaceData.smoothness = lerp(outSurfaceData.smoothness, _SmoothnessBase, outSurfaceData.alpha);
                outSurfaceData.specular = lerp(_SpecColor, _SpecColorBase, outSurfaceData.alpha);

                outSurfaceData.metallic = 0;
                outSurfaceData.occlusion = 1;

            }

            void InitializeInputData(VertexOutput input, half3 normalTS, half3 viewDirWS, half facing, out InputData inputData)
            {
                
            //  NOTE: inputData.normalWS and viewDirWS are already normalized

                inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                
                #if defined(_NORMALMAP)
                    //half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                    normalTS.z *= facing;
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                #else
                    //half3 viewDirWS = input.viewDirWS;
                    inputData.normalWS = input.normalWS * facing;
                #endif

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
            }

            half4 LitPassFragment(VertexOutput input, half facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  We need viewDirWS and normalWS already in the surface function, so we get them up front
                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                input.normalWS.xyz = NormalizeNormalPerPixel(input.normalWS.xyz);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeSurfaceData(input.uv, input.projectionCoord, input.normalWS.xyz, viewDirWS, input.positionWS, input.scale, facing, surfaceData);

            //  Prepare surface data (like bring normal into world space and get missing inputs like gi)
            //  NOTE: viewDirWS and normalWS are already (almost) set up
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, viewDirWS, facing, inputData);

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
                half4 color = LuxLWRPTransparentFragmentPBR (
                    inputData, 
                    surfaceData.albedo,
                    surfaceData.metallic, 
                    surfaceData.specular, 
                    surfaceData.smoothness, 
                    surfaceData.occlusion, 
                    surfaceData.emission, 
                    surfaceData.alpha
                );    
            
                #if defined(_FINALALPHA)
                    color.a = max(_FinalAlpha, surfaceData.alpha);
                #endif
                #if defined (_ADDITIVE)
                //  Add fog
                    color.rgb = MixFogColor(color.rgb, half3(0,0,0), inputData.fogCoord);
                #else
                //  Add fog
                    color.rgb = MixFog(color.rgb, inputData.fogCoord);
                #endif

                return color;
            }

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
            #include "Includes/Lux URP Glass Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                //half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.alpha = 1;
                outSurfaceData.albedo = _BaseColor.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
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
    FallBack "Hidden/InternalErrorShader"
    CustomEditor "LuxURPCustomGlassShaderGUI"
}