// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "Lux URP/Vegetation/Foliage Debug"
{
    Properties
    {
        
        //[IntRange] _DebugColor ("Debug Vertex Color", Range(0, 4)) = 0
        [Enum(None,0,Red,1,Green,2,Blue,3,Alpha,4)] _DebugColor ("Debug Vertex Color", Float) = 0
        _Brightness ("Brightness", Float) = 1

        [Header(Surface Options)]
        [Space(5)]
        [Toggle(_ALPHATEST_ON)]
        _AlphaClip                  ("Alpha Clipping", Float) = 1.0
        _Cutoff                     ("     Threshold", Range(0.0, 1.0)) = 0.5
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0

        [Header(Surface Inputs)]
        [Space(5)]
        [NoScaleOffset][MainTexture]
        _BaseMap                    ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        [HideInInspector][MainColor]
        _BaseColor                  ("Color", Color) = (1,1,1,1)

        [Space(5)]
        _Smoothness                 ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecColor                  ("Specular", Color) = (0.2, 0.2, 0.2)

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                ("Enable Normal Smoothness Trans Map", Float) = 0.0
        [NoScaleOffset] _BumpSpecMap
                                    ("     Normal (AG) Smoothness (B) Trans (R)", 2D) = "white" {}
        _GlossMapScale              ("     Smoothness Scale", Range(0.0, 1.0)) = 1.0

        [Header(Transmission)]
        [Space(5)]
        _TranslucencyPower          ("Power", Range(0.0, 10.0)) = 7.0
        _TranslucencyStrength       ("Strength", Range(0.0, 1.0)) = 1.0
        _ShadowStrength             ("Shadow Strength", Range(0.0, 1.0)) = 0.7
        _Distortion                 ("Distortion", Range(0.0, 0.1)) = 0.01

        [Header(Wind)]
        [Space(5)]
        [KeywordEnum(Texture, Math)]
        _Wind                       ("Wind Input", Float) = 0
        [LuxURPWindFoliageDrawer]
        _WindMultiplier             ("Wind Strength (X) Secondary Strength (Y) Edge Flutter (Z) Lod Level (W)", Vector) = (1, 2, 1, 0)
        _SampleSize                 ("Sample Size", Range(0.0, 1.0)) = 0.5

        [Header(Distance Fading)]
        [Space(5)]
        [LuxLWRPDistanceFadeDrawer]
        _DistanceFade               ("Distance Fade Params", Vector) = (2500, 0.001, 0, 0)

        [Header(Advanced)]
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
            "RenderType" = "TransparentCutout"
            "IgnoreProjector" = "True"
            "Queue"="AlphaTest"
        }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite On
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #define _SPECULAR_SETUP 1
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            #pragma shader_feature_local _WIND_MATH

            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #define DEBUG

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Foliage Inputs.hlsl"

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
                float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                float dist = dot(diff, diff);
                output.fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );

            //  Wind in ObjectSpace -------------------------------


// WEE NEED 2 samples because of offset (by phase variation)

                VertexPositionInputs vertexInput; // = GetVertexPositionInputs(input.positionOS.xyz);

animateVertex(input.color, input.normalOS.xyz, input.positionOS.xyz);
/*
#if !defined(_WIND_MATH)


                float2 samplePos = TransformObjectToWorld(input.positionOS.xyz * _SampleSize).xz; 
            //  Bring wind into object space
                _LuxLWRPWindDirSize.xyz = mul(UNITY_MATRIX_I_M, float4(_LuxLWRPWindDirSize.xyz, 0)).xyz;


                float fVtxPhase = dot( normalize(input.positionOS.xyz), ((input.color.g + input.color.r) * 0.5).xxx );

              
                half4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, samplePos.xy * _LuxLWRPWindDirSize.w - _LuxLWRPWindDirSize.xz * input.color.rr * 0, 0);


                float origLength = length(input.positionOS.xyz);

                wind.r = wind.r  * wind.g;
                wind.r = wind.g;                
                half3 windDir = _LuxLWRPWindDirSize.xyz;
                
                float windStrength = input.color.a * wind.r * _LuxLWRPWindStrengthMultipliers.y * _WindMultiplier.x;
            
            //  Primary bending
                input.positionOS.xz += windDir.xz * windStrength ; 


                // here we cant rotate...
                // now we can
                wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, samplePos.xy * _LuxLWRPWindDirSize.w - input.color.rr * 3 , 0);


// pos.xyz += ((vWavesSum.xyx * bend) + (_Wind.xyz * vWavesSum.y * animParams.w)) * _Wind.w;

float3 bend = input.color.g * input.normalOS.xyz * windDir *  _WindMultiplier.z * lerp(_LuxLWRPSinTime.y, _LuxLWRPSinTime.z, wind.r); //saturate(wind.b * fVtxPhase)); // saturate(wind.b + input.positionOS.x + input.positionOS.z ));
bend.y = 0; //input.color.b * 0.3; // * fBranchAmp;


                input.positionOS.xyz += bend + ((windDir * input.color.b  ))  *  ( wind.r  *   (wind.g )) * _LuxLWRPWindStrengthMultipliers.y * _WindMultiplier.y ; 


                input.positionOS.xyz = normalize(input.positionOS.xyz) * origLength;

#endif
*/


                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);


            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
                vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                float4 ndc = vertexInput.positionCS * 0.5f;
                vertexInput.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                vertexInput.positionNDC.zw = vertexInput.positionCS.zw;
            //  End Wind -------------------------------

                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv.xy = input.texcoord;
                output.normalWS = normalInput.normalWS;
                output.viewDirWS = viewDirWS;

                #ifdef _NORMALMAP
                    half sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = half4(normalInput.tangentWS, sign);
                #endif

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                
                #if defined(_NORMALMAP)
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                #else
            //  When no normal map is applied we have to lookup SH fully per pixel
                    output.vertexSH = 0;
                #endif
                
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = vertexInput.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                output.positionCS = vertexInput.positionCS;

                output.color = input.color;

                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeFoliageLitSurfaceData(float2 uv, half fade, out SurfaceDescription outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
            //  Add fade
                albedoAlpha.a *= fade;
            //  Early out
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
            
            //  Normal Map
                #if defined (_NORMALMAP)
                    float4 sampleNormal = SAMPLE_TEXTURE2D(_BumpSpecMap, sampler_BumpSpecMap, uv);
                    float3 tangentNormal;
                    tangentNormal.xy = sampleNormal.ag * 2 - 1;
                    tangentNormal.z = sqrt(1.0 - dot(tangentNormal.xy, tangentNormal.xy));  
                    outSurfaceData.normalTS = tangentNormal;
                    outSurfaceData.smoothness = sampleNormal.b * _GlossMapScale;
                    outSurfaceData.translucency = sampleNormal.r;
                #else
                    outSurfaceData.normalTS = float3(0, 0, 1);
                    outSurfaceData.smoothness = _Smoothness;
                    outSurfaceData.translucency = 1;
                #endif
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, half facing, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif
                half3 viewDirWS = input.viewDirWS;
                #ifdef _NORMALMAP
                    normalTS.z *= facing;
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                #else
                    inputData.normalWS = input.normalWS * facing;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                viewDirWS = SafeNormalize(viewDirWS);

                inputData.viewDirectionWS = viewDirWS;
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCDDDDDDDDDDDDDDDDDDDoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                inputData.fogCoord = input.fogFactorAndVertexLight.x;
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                
            //  
                #if defined(_NORMALMAP) 
                    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                #endif

            //  Using VFACE and vertex normals – so we should sample SH fully per pixel
                #if !defined(_NORMALMAP) && !defined(LIGHTMAP_ON)
                    inputData.bakedGI = SampleSH(inputData.normalWS);
                #endif
            }

            half4 LitPassFragment(VertexOutput input, half facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeFoliageLitSurfaceData(input.uv.xy, input.fade, surfaceData);


            //  Prepare surface data (like bring normal into world space (incl. VFACE)) and get missing inputs like gi
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, facing, inputData);

            //  Apply lighting
                half4 color = half4(surfaceData.albedo,1);
                if(_DebugColor != 0)
                    color = half4(0,0,0,1);

                if(_DebugColor == 1)
                    color.r = input.color.r * _Brightness;
                if(_DebugColor == 2)
                    color.g = input.color.g * _Brightness;
                if(_DebugColor == 3)
                    color.b = input.color.b * _Brightness;
                if(_DebugColor == 4)
                    color.rgb = input.color.aaa * _Brightness;

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
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON 1

            #pragma shader_feature_local _WIND_MATH


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Include base inputs and all other needed "base" includes
            #include "Includes/Lux URP Foliage Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                float dist = dot(diff, diff);
                output.fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );
                
                output.uv = input.texcoord;

            //  Wind in Object Space -------------------------------
                animateVertex(input.color, input.normalOS.xyz, input.positionOS.xyz);
            //  End Wind -------------------------------

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldDir(input.normalOS);

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
                half alpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a;
            //  Works in scene view but not in GameView?
                alpha *= input.fade;
                clip(alpha - _Cutoff);
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
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #define _ALPHATEST_ON 1

            #pragma shader_feature_local _WIND_MATH

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #define DEPTHONLYPASS
            #include "Includes/Lux URP Foliage Inputs.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 worldInstancePos = UNITY_MATRIX_M._m03_m13_m23;
                float3 diff = (_WorldSpaceCameraPos - worldInstancePos);
                float dist = dot(diff, diff);
                output.fade = saturate( (_DistanceFade.x - dist) * _DistanceFade.y );

                
            //  Wind in Object Space -------------------------------
                animateVertex(input.color, input.normalOS.xyz, input.positionOS.xyz);
            //  End Wind -------------------------------

                VertexPositionInputs vertexInput;
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
                vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                float4 ndc = vertexInput.positionCS * 0.5f;
                vertexInput.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                vertexInput.positionNDC.zw = vertexInput.positionCS.zw;
            //  End Wind -------------------------------                

                output.uv.xy = input.texcoord;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half alpha = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a;
                alpha *= input.fade;
                clip(alpha - _Cutoff);
                return 0;
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
            #define _ALPHATEST_ON 1

        //  First include all our custom stuff
            #include "Includes/Lux URP Grass Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = half3(0,0,1); //SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
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
    CustomEditor "LuxURPCustomSingleSidedShaderGUI"
}