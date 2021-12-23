// Shader might write to emission, so it needs a custom inspector

Shader "Lux URP/Projection/Top Down"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(80kxmwjj8akf)]

        [Header(Surface Options)]
        [Space(8)]
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows                 ("Receive Shadows", Float) = 1.0


        [Header(Surface Inputs)]
        [Space(8)]
        _BaseMap                        ("Albedo (RGB) Smoothness (A)", 2D) = "white" {}
        [MainColor] _BaseColor          ("Base Color", Color) = (1,1,1,1)
        [Toggle(_DYNSCALE)]
        _ApplyDynScale                  ("Enable dynamic tiling", Float) = 0.0
        
        [Space(5)]
        _GlossMapScale                  ("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        _SpecColor                      ("Specular", Color) = (0.2, 0.2, 0.2)
        
        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                    ("Enable Normal Map", Float) = 1.0
        [NoScaleOffset] _BumpMap        ("     Normal Map", 2D) = "bump" {}
        _BumpScale                      ("     Normal Scale", Float) = 1.0
        
        [Header(Mask Map)]
        [Space(8)]
        [Toggle(_COMBINEDTEXTURE)]
        _CombinedTexture                ("Enable Mask Map", Float) = 0.0
        [NoScaleOffset] _MaskMap        ("     Metallness (R) Occlusion (G) Height (B) Emission (A) ", 2D) = "bump" {}
    
        [HDR] _EmissionColor            ("     Emission Color", Color) = (0,0,0)
        [Toggle(_EMISSION)]
        _Emission                       ("     Bake Emission", Float) = 0.0
        _Occlusion                      ("     Occlusion", Range(0.0, 1.0)) = 1.0
        
        [Header(Top Down Projection)]
        [Space(8)]
        [Toggle(_TOPDOWNPROJECTION)]
        _ApplyTopDownProjection         ("Enable top down Projection", Float) = 1.0
        [NoScaleOffset]_TopDownBaseMap  ("     Albedo (RGB) Smoothness (A)", 2D) = "white" {}
        _GlossMapScaleDyn               ("     Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Space(5)]
        [Toggle(_MASKFROMNORMAL)]
        _MaskFromNormal                 ("     Get Mask from Normal", Float) = 0.0
        [NoScaleOffset]_TopDownNormalMap("     Normal (RGB) or Normal (AG) Mask (B)", 2D) = "bump" {}
        _BumpScaleDyn                   ("     Normal Scale", Float) = 1.0
        [Space(5)]
        _TopDownTiling                  ("     Tiling", Float) = 1.0
        [LuxURPVectorThreeDrawer]
        _TerrainPosition                ("     Terrain Position (XYZ)", Vector) = (0,0,0,0)

        [Header(Blending)]
        [Space(8)]
        _NormalLimit                    ("Angle Limit", Range(0.05,1)) = 0.5
        _NormalFactor                   ("Strength", Range(0.0,2)) = 1
        [Space(5)]
        _LowerNormalInfluence           ("Base Normal Influence", Range(0,1)) = 1
        _LowerNormalMinStrength         ("Base Normal Strength", Range(0,1)) = 0.2
        [Space(5)]
        _HeightBlendSharpness           ("Height Influence", Range(0.0, 1.0)) = 1.0

        [Header(Fuzz Lighting)]
        [Space(8)]
        [Toggle(_SIMPLEFUZZ)]
        _EnableFuzzyLighting            ("Enable Fuzzy Lighting", Float) = 0
        _FuzzWrap                       ("     Diffuse Wrap", Range(0, 1)) = 0.5 
        _FuzzStrength                   ("     Fuzz Strength", Range(0, 8)) = 1 
        _FuzzPower                      ("     Fuzz Power", Range(1, 16)) = 4        
        _FuzzBias                       ("     Fuzz Bias", Range(0, 1)) = 0
        _FuzzAmbient                    ("     Ambient Strength", Range(0, 1)) = 1 

        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights             ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections         ("Environment Reflections", Float) = 1.0

        // DepthNormal compatibility
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue"="Geometry"
            "DisableBatching" = "LODFading"
        }


//  Base -----------------------------------------------------
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite On
            Cull Back
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #define _SPECULAR_SETUP 1

            #pragma shader_feature_local _TOPDOWNPROJECTION
            #pragma shader_feature_local _DYNSCALE
            #pragma shader_feature_local_fragment _COMBINEDTEXTURE
            #pragma shader_feature_local_fragment _MASKFROMNORMAL

            #pragma shader_feature_local_fragment _SIMPLEFUZZ

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

            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #include "Includes/Top Down URP Inputs.hlsl"

            #if defined(_COMBINEDTEXTURE)
                TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
            #endif
            TEXTURE2D(_TopDownBaseMap); SAMPLER(sampler_TopDownBaseMap);
            TEXTURE2D(_TopDownNormalMap); SAMPLER(sampler_TopDownNormalMap);

			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment


            void InitializeInputData(VertexOutput input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
                inputData.positionWS = input.positionWS;

                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                #ifdef _NORMALMAP
                //  Here normalTS is already normalWS
                //  inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                    inputData.normalWS = normalTS;
                #else
                    inputData.normalWS = input.normalWS;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
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

			VertexOutput LitPassVertex(VertexInput input)
			{
				VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.uv.zw = vertexInput.positionWS.xz * _TopDownTiling + _TerrainPosition.xz;

                #if defined (_DYNSCALE)
                    float scale = length( TransformObjectToWorld( float3(1,0,0) ) - UNITY_MATRIX_M._m03_m13_m23 );
                    output.uv.xy *= scale;
                #endif

            //  Already normalized from normal transform to WS!
                output.normalWS = normalInput.normalWS;
                
                #ifdef _NORMALMAP
                    float sign = input.tangentOS.w * GetOddNegativeScale();
    				output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                #endif
                output.viewDirWS = viewDirWS;

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

            //  #ifdef _ADDITIONAL_LIGHTS
                    output.positionWS = vertexInput.positionWS;
            //  #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                output.positionCS = vertexInput.positionCS;
				return output;
			}


            #define oneMinusDielectricSpecConst half(1.0 - 0.04)
            // derived from #define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

        //  Surface function which has full access to all vertex interpolators
            inline void InitializeStandardLitSurfaceData(VertexOutput input, out SurfaceDescription outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor;
                albedoAlpha.a *= _GlossMapScale;

                outSurfaceData.alpha = 1;
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.emission = 0;
                outSurfaceData.occlusion = 1;

                outSurfaceData.fuzzMask = 0;

                #if defined(_SPECULAR_SETUP)
                    outSurfaceData.specular = _SpecColor;
                #else
                    outSurfaceData.specular = 0;
                #endif

                #if defined(_COMBINEDTEXTURE)
                    half4 combinedTextureSample = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv.xy);
                    outSurfaceData.specular = lerp(_SpecColor, albedoAlpha.rgb, combinedTextureSample.rrr);
                //  Remap albedo
                    albedoAlpha.rgb *= oneMinusDielectricSpecConst - combinedTextureSample.rrr * oneMinusDielectricSpecConst;
                    outSurfaceData.emission = _EmissionColor * combinedTextureSample.a;
                    outSurfaceData.occlusion = lerp(1.0h, combinedTextureSample.g, _Occlusion);
                #endif
                
                outSurfaceData.smoothness = albedoAlpha.a * _GlossMapScale;
                outSurfaceData.normalTS = SampleNormal(input.uv.xy, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

                #ifdef _NORMALMAP
                    #if defined (_MASKFROMNORMAL)
                        half4 packedNormal = SAMPLE_TEXTURE2D(_TopDownNormalMap, sampler_TopDownNormalMap, input.uv.zw);
                        #if BUMP_SCALE_NOT_SUPPORTED
                            half3 topDownNormal = UnpackNormalmapRGorAG(packedNormal, 1.0);
                        #else
                            half3 topDownNormal = UnpackNormalmapRGorAG(packedNormal, _BumpScaleDyn);
                        #endif
                    #else
                        half3 topDownNormal = SampleNormal(input.uv.zw, TEXTURE2D_ARGS(_TopDownNormalMap, sampler_TopDownNormalMap), _BumpScaleDyn);
                    #endif
                #endif

            //  Please note: outSurfaceData.normalTS will actually contain a normal in world space!
                #if defined(_TOPDOWNPROJECTION)
                    float blendFactor = 0;
                    #ifdef _NORMALMAP
                    //  Get per pixel worldspace normal (needed by blending)
                    	float sgn = input.tangentWS.w;      // should be either +1 or -1
    					float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        float3 normalWS = TransformTangentToWorld(outSurfaceData.normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                        blendFactor = lerp(input.normalWS.y, normalWS.y, _LowerNormalInfluence);
                    #else
                        blendFactor = input.normalWS.y;
                    #endif
                //  Prevent projected texture from gettings stretched by masking out steep faces
                    //blendFactor = saturate( blendFactor - (1 - saturate ( (blendFactor - _NormalLimit) * 4 ) ) );
                    blendFactor = lerp(-_NormalLimit, 1, saturate(blendFactor));
                //  Widen blendfactor
                    blendFactor = blendFactor * _NormalFactor;
                    #if defined(_COMBINEDTEXTURE) || defined (_NORMALMAP) && defined (_MASKFROMNORMAL)
                        #if defined (_NORMALMAP) && defined (_MASKFROMNORMAL)
                            float mask = saturate(packedNormal.b * _HeightBlendSharpness);
                        #else
                        //  Mask is height and we want less on high levels. So it is some kind of inverted.
                            float mask = saturate(combinedTextureSample.b * _HeightBlendSharpness);   
                        #endif
                        blendFactor = smoothstep(mask, 1, blendFactor); 
                    #else
                    //  Somehow compensate missing height sample, smoothstep is not compensated? Nope. Just saturate.
                        blendFactor = saturate(blendFactor); // * (1 + _HeightBlendSharpness));
                    #endif
                    float normalBlendFactor = blendFactor;
                    blendFactor *= blendFactor * blendFactor * blendFactor;

                    outSurfaceData.fuzzMask = blendFactor;

                //  Get top down projected Texture(s)
                    //float2 topDownUV = input.positionWS.xz * _TopDownTiling + _TerrainPosition.xz;
                    half4 topDownSample = SAMPLE_TEXTURE2D(_TopDownBaseMap, sampler_TopDownBaseMap, input.uv.zw);
                    topDownSample.a *= _GlossMapScaleDyn;
                    albedoAlpha = lerp(albedoAlpha, topDownSample, blendFactor.xxxx);

                    outSurfaceData.emission = lerp(outSurfaceData.emission, half3(0.0h, 0.0h, 0.0h), blendFactor.xxx);
                    outSurfaceData.occlusion = lerp(outSurfaceData.occlusion, 1, blendFactor);

                    #ifdef _NORMALMAP
                    //  1. Normal is not sampled in tangent space   
                        outSurfaceData.normalTS = normalWS;
                    //  2. So we use Reoriented Normal Mapping to bring the top down normal into world space
                    //  See e.g.: https://medium.com/@bgolus/normal-mapping-for-a-triplanar-shader-10bf39dca05a
                    //  We must apply some crazy swizzling here: Swizzle world space to tangent space
                        half3 n1 = input.normalWS.xzy;
                        half3 n2 = topDownNormal.xyz;
                        n1.z += 1.0h;
                        n2.xy *= -1.0h;
                        topDownNormal = n1 * dot(n1, n2) / n1.z - n2;
                    //  Swizzle tangent space to world space
                        topDownNormal = topDownNormal.xzy;
                    //  3. Finally we blend both normals in world space 
                        outSurfaceData.normalTS = lerp(outSurfaceData.normalTS, topDownNormal, saturate(normalBlendFactor.xxx - _LowerNormalMinStrength) );
                    #endif
                #else
                    #ifdef _NORMALMAP
                    	float sgn = input.tangentWS.w;      // should be either +1 or -1
    					float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        outSurfaceData.normalTS = TransformTangentToWorld(outSurfaceData.normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                    #else
                        outSurfaceData.normalTS = input.normalWS.xyz;
                    #endif
                #endif

                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.smoothness = albedoAlpha.a;
            }


            half4 LitPassFragment(VertexOutput input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(LOD_FADE_CROSSFADE) && !defined(SHADER_API_GLES)
                    LODDitheringTransition(input.positionCS.xyz, unity_LODFade.x);
                #endif

                SurfaceDescription surfaceData;
            //  Get the surface description
                InitializeStandardLitSurfaceData(input, surfaceData);

            //  Transfer all to world space
            //  Please note: surfaceData.normalTS already contains the world space normal! 
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

            //  Apply lighting
                //half4 color = LightweightFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
            
            //  Apply lighting
                half4 color = LuxURPSimpleFuzzFragmentPBR(
                    inputData, 
                    surfaceData.albedo,
                    surfaceData.metallic, 
                    surfaceData.specular, 
                    surfaceData.smoothness, 
                    surfaceData.occlusion, 
                    surfaceData.emission, 
                    surfaceData.alpha,

                    #if defined(_SCATTERING)
                        half4(surfaceData.translucency * _TranslucencyStrength, _TranslucencyPower, _ShadowStrength, _Distortion),
                    #else
                        half4(0,0,0,0),
                    #endif

                    surfaceData.fuzzMask, // Fuzzmask
                    _FuzzPower,
                    _FuzzBias,
                    _FuzzWrap,
                    _FuzzStrength * PI,
                    _FuzzAmbient
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
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Needed functions usually included in LitInput.hlsl
            half LerpWhiteTo(half b, half t)
            {
                half oneMinusT = 1.0 - t;
                return oneMinusT + b * t;
            }

            half3 LerpWhiteTo(half3 b, half t)
            {
                half oneMinusT = 1.0 - t;
                return half3(oneMinusT, oneMinusT, oneMinusT) + b * t;
            }

            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #include "Includes/Top Down URP Inputs.hlsl"

            float3 _LightDirection;


            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
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
                #if defined(LOD_FADE_CROSSFADE) && !defined(SHADER_API_GLES)
                    LODDitheringTransition(input.positionCS.xyz, unity_LODFade.x);
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
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define DEPTHONLYPASS
            #include "Includes/Top Down URP Inputs.hlsl"

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

                #if defined(LOD_FADE_CROSSFADE) && !defined(SHADER_API_GLES) // enable dithering LOD transition if user select CrossFade transition in LOD group
                    LODDitheringTransition(input.positionCS.xyz, unity_LODFade.x);
                #endif
                return 0;
            }

            ENDHLSL
        }

//  Depth Normal ---------------------------------------------
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
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
            #pragma shader_feature_local _NORMALMAP
            //#pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #define DEPTHNORMALONLYPASS
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Includes/Top Down URP Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

//  Meta -----------------------------------------------------
        Pass
        {
            Tags{"LightMode" = "Meta"}

            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex UniversalVertexMetaCustom
            //UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaCustom

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #define _SPECULAR_SETUP 1

            #pragma shader_feature _SPECGLOSSMAP
            // #pragma shader_feature _EMISSION // Not needed as we do our own emission

            #pragma shader_feature_local _TOPDOWNPROJECTION
            #pragma shader_feature_local _DYNSCALE
            #pragma shader_feature_local _COMBINEDTEXTURE
            #pragma shader_feature_local _MASKFROMNORMAL

            #define CUSTOMMETAPASS

            // This breaks all
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            #include "Includes/Top Down URP Inputs.hlsl"

            #if defined(_COMBINEDTEXTURE)
                TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
            #endif
            #if defined (_NORMALMAP) || defined (_MASKFROMNORMAL)
                TEXTURE2D(_TopDownNormalMap); SAMPLER(sampler_TopDownNormalMap);
            #endif
            TEXTURE2D(_TopDownBaseMap); SAMPLER(sampler_TopDownBaseMap);

            #define oneMinusDielectricSpecConst half(1.0 - 0.04)
            // derived from #define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

            inline void InitializeStandardLitSurfaceData(float4 uv, float3 positionWS, float3 normalWS, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                albedoAlpha.a *= _GlossMapScale;
                outSurfaceData.alpha = 1;

                #if _SPECULAR_SETUP
                    outSurfaceData.metallic = 1.0h;
                    outSurfaceData.specular = _SpecColor;
                #else
                    outSurfaceData.metallic = specGloss.r;
                    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
                #endif

                #if defined(_COMBINEDTEXTURE)
                    half4 combinedTextureSample = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv.xy);
                    outSurfaceData.specular = lerp(_SpecColor, albedoAlpha.rgb, combinedTextureSample.rrr);
                //  Remap albedo
                    albedoAlpha.rgb *= oneMinusDielectricSpecConst - combinedTextureSample.rrr * oneMinusDielectricSpecConst;
                    outSurfaceData.emission = _EmissionColor * combinedTextureSample.a;
                    outSurfaceData.occlusion = lerp(1.0h, combinedTextureSample.g, _Occlusion);
                #else
                    outSurfaceData.emission = 0;
                    outSurfaceData.occlusion = 1; 
                #endif

                #ifdef _NORMALMAP
                    #if defined (_MASKFROMNORMAL)
                        half4 packedNormal = SAMPLE_TEXTURE2D(_TopDownNormalMap, sampler_TopDownNormalMap, uv.zw);
                        #if BUMP_SCALE_NOT_SUPPORTED
                            half3 topDownNormal = UnpackNormalmapRGorAG(packedNormal, 1.0);
                        #else
                            half3 topDownNormal = UnpackNormalmapRGorAG(packedNormal, _BumpScaleDyn);
                        #endif
                    #else
                        half3 topDownNormal = SampleNormal(uv.zw, TEXTURE2D_ARGS(_TopDownNormalMap, sampler_TopDownNormalMap), _BumpScaleDyn);
                    #endif
                #endif

                #if defined(_TOPDOWNPROJECTION)
                    float blendFactor = normalWS.y;
                //  Prevent projected texture from gettings stretched by masking out steep faces
                    //blendFactor = saturate( blendFactor - (1 - saturate ( (blendFactor - _NormalLimit) * 4 ) ) );
                    blendFactor = lerp(-_NormalLimit, 1, saturate(blendFactor));             
                //  Widen blendfactor
                    blendFactor = blendFactor * _NormalFactor;
                    #if defined(_COMBINEDTEXTURE) || defined (_NORMALMAP) && defined (_MASKFROMNORMAL)
                        #if defined (_NORMALMAP) && defined (_MASKFROMNORMAL)
                            float mask = saturate(packedNormal.b * _HeightBlendSharpness);
                        #else
                        //  Mask is height and we want less on high levels. So it is some kind of inverted.
                            float mask = saturate(combinedTextureSample.b * _HeightBlendSharpness);   
                        #endif
                        blendFactor = smoothstep(mask, 1, blendFactor); 
                    #else
                    //  Somehow compensate missing height sample, smoothstep is not compensated
                        blendFactor = saturate(blendFactor); // * (1 + _HeightBlendSharpness));
                    #endif
                    blendFactor *= blendFactor * blendFactor * blendFactor;

                    // float2 topDownUV = positionWS.xz * _TopDownTiling + _TerrainPosition.xz;
                    half4 topDownSample = SAMPLE_TEXTURE2D(_TopDownBaseMap, sampler_TopDownBaseMap, uv.zw);
                    topDownSample.a *= _GlossMapScaleDyn;
                    albedoAlpha = lerp(albedoAlpha, topDownSample, blendFactor.xxxx);
                    outSurfaceData.emission = lerp(outSurfaceData.emission, 0, blendFactor);
                #endif

                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.smoothness = albedoAlpha.a;

                outSurfaceData.normalTS = half3(0,0,1);

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 0;
            }

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

//  Needed by URP
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv0          : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float2 uv2          : TEXCOORD2;
            #ifdef _TANGENT_TO_WORLD
                float4 tangentOS     : TANGENT;
            #endif
            };

            struct VertexOutputMeta {
                float4 positionCS   : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                half3 normalWS      : TEXCOORD2;
            };

            VertexOutputMeta UniversalVertexMetaCustom(Attributes input)
            {
                VertexOutputMeta output;
                output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
                    unity_LightmapST, unity_DynamicLightmapST);
                
                output.uv.xy = TRANSFORM_TEX(input.uv0, _BaseMap);

                #if defined (_DYNSCALE)
                    float scale = length( TransformObjectToWorld( float3(1,0,0) ) - UNITY_MATRIX_M._m03_m13_m23 );
                    output.uv.xy *= scale;
                #endif

                output.positionWS = mul(UNITY_MATRIX_M, input.positionOS).xyz;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);

                output.uv.zw = output.normalWS.xz * _TopDownTiling + _TerrainPosition.xz;

                return output;
            }

            half4 UniversalFragmentMetaCustom(VertexOutputMeta input) : SV_Target
            {
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, input.positionWS, input.normalWS, surfaceData);

                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

                MetaInput metaInput;
                metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
                metaInput.SpecularColor = surfaceData.specular;
                metaInput.Emission = surfaceData.emission;

                return MetaFragment(metaInput);
            }
            
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
    CustomEditor "LuxURPCustomShaderGUI"
}