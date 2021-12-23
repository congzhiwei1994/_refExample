Shader "Lux URP/Terrain/Mesh Terrain"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(v7hplahjb13)]

        [Header(Surface Options)]
        [Space(8)]
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows             ("Receive Shadows", Float) = 1.0

        [Header(Surface Inputs)]
        [Space(8)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                ("Enable Normal Maps", Float) = 1.0
        [Toggle(_TOPDOWNPROJECTION)]
        _ApplyTopDownProjection     ("Enable Top Down Projection", Float) = 0.0
        _TopDownTiling              ("     Tiling in World Space", Float) = 1.0

        [Space(5)]
        [NoScaleOffset] _DetailA0   ("Detail 0  Albedo (RGB) Smoothness (A)", 2D) = "gray" {}
        [NoScaleOffset] _Normal0    ("     Normal 0", 2D) = "bump" {}
        [NoScaleOffset] _DetailA1   ("Detail 1  Albedo (RGB) Smoothness (A)", 2D) = "gray" {}
        [NoScaleOffset] _Normal1    ("     Normal 1", 2D) = "bump" {}
        [NoScaleOffset] _DetailA2   ("Detail 2  Albedo (RGB) Smoothness (A)", 2D) = "gray" {}
        [NoScaleOffset] _Normal2    ("     Normal 2", 2D) = "bump" {}
        [NoScaleOffset] _DetailA3   ("Detail 3  Albedo (RGB) Smoothness (A)", 2D) = "gray" {}
        [NoScaleOffset] _Normal3    ("     Normal 3", 2D) = "bump" {}
        
        [Space(5)]
        [Toggle(_USEVERTEXCOLORS)] 
        _VertexColors               ("Use Vertex Colors", Float) = 0.0
        [NoScaleOffset] _SplatMap   ("Splat Map (RGB)", 2D) = "red" {}

        [Space(5)]
        [LuxURPVectorTwoDrawer] _SplatTiling("Detail Tiling (UV)", Vector) = (1,1,0,0)
        _Specular("Specular", Color) = (0.2,0.2,0.2,0)
        _Occlusion("Occlusion", Range(0, 1)) = 0

        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights         ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections     ("Environment Reflections", Float) = 1.0
    }


    // HLSLINCLUDE
    //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // ENDHLSL


    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry-100"
        }
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend One Zero
            Cull Back
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

        //  Tell Polybrush that this shader supports 4 texture channels
            #define Z_TEXTURE_CHANNELS 4
            #define Z_MESH_ATTRIBUTES COLOR

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_SETUP 1

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _TOPDOWNPROJECTION
            #pragma shader_feature_local_fragment _USEVERTEXCOLORS

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
    //  Does this make sense here? Well: maybe
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex vert
            #pragma fragment frag

            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float2 _SplatTiling;
                float4 _Specular;
                float _Occlusion;
                half _TopDownTiling;
            CBUFFER_END

            TEXTURE2D(_DetailA0);   SAMPLER(sampler_DetailA0);  float4 _DetailA0_TexelSize;
            TEXTURE2D(_Normal0);    SAMPLER(sampler_Normal0);   float4 _Normal0_TexelSize;
            TEXTURE2D(_DetailA1);   float4 _DetailA1_TexelSize;
            TEXTURE2D(_Normal1);    float4 _Normal1_TexelSize;
            TEXTURE2D(_DetailA2);   float4 _DetailA2_TexelSize;
            TEXTURE2D(_Normal2);    float4 _Normal2_TexelSize;
            TEXTURE2D(_DetailA3);   float4 _DetailA3_TexelSize;
            TEXTURE2D(_Normal3);    float4 _Normal3_TexelSize;
            TEXTURE2D(_SplatMap);   SAMPLER(sampler_SplatMap); float4 _SplatMap_TexelSize;


            struct VertexInput
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;

                #if defined(_USEVERTEXCOLORS)
                    half4 color     : COLOR;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS                : SV_POSITION;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 0);
                half4 fogFactorAndVertexLight : TEXCOORD1; // x: fogFactor, yzw: vertex light
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord            : TEXCOORD2;
                #endif

                float3 normalWS                 : TEXCOORD3;
                float3 viewDirWS                : TEXCOORD4;
                #ifdef _NORMALMAP
                    float4 tangentWS            : TEXCOORD5;    
                #endif
                float3 positionWS : TEXCOORD6;
                float2 uv0 : TEXCOORD7;
                #if defined(_USEVERTEXCOLORS)
                    half4 color     : COLOR;
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

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv0 = input.texcoord; //TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionWS = vertexInput.positionWS;

            //  Already normalized from normal transform to WS.
                output.normalWS = normalInput.normalWS;
                output.viewDirWS = viewDirWS;
                #ifdef _NORMALMAP
                    float sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                #endif
                
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                output.positionCS = vertexInput.positionCS;

                #if defined(_USEVERTEXCOLORS)
                    output.color = input.color;
                #endif
                
                return output;
            }

        //  Surface function which has full access to all vertex interpolators
            inline void InitializeStandardLitSurfaceData(VertexOutput input, out SurfaceData outSurfaceData, out half3 topdownNormal)
            {
                
                topdownNormal = 0;

                float2 detailUV = input.uv0 * _SplatTiling;
                half4 splatControl = 0;

                #if defined(_USEVERTEXCOLORS)
                    splatControl = input.color;
                #else
                    splatControl.rgb = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, input.uv0.xy).rgb;
                #endif
                splatControl.a = 1.0h - splatControl.r - splatControl.g - splatControl.b;
                
                #if defined(_TOPDOWNPROJECTION)
                    float2 uvWS = input.positionWS.xz * _TopDownTiling;
                    half4 albedoAlpha = SAMPLE_TEXTURE2D(_DetailA0, sampler_DetailA0, uvWS) * splatControl.r;
                #else
                    half4 albedoAlpha = SAMPLE_TEXTURE2D(_DetailA0, sampler_DetailA0, detailUV) * splatControl.r;
                #endif
                
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA1, sampler_DetailA0, detailUV) * splatControl.g;
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA2, sampler_DetailA0, detailUV) * splatControl.b;
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA3, sampler_DetailA0, detailUV) * splatControl.a;

                half3 normalTS = 0;
                #if defined(_NORMALMAP)
                    half4 nrm = 0.0h;
                    #if defined(_TOPDOWNPROJECTION)
                        topdownNormal = UnpackNormal (SAMPLE_TEXTURE2D(_Normal0, sampler_Normal0, uvWS));
                    //  Without safe normalization of gba normals are off withing the blend range.
                        splatControl.gba /= dot( max(splatControl.gba, half3(0.0001h, 0.0001h, 0.0001h)), half3(1.0h,1.0h,1.0h));
                    #else
                        nrm = SAMPLE_TEXTURE2D(_Normal0, sampler_Normal0, detailUV) * splatControl.r;
                    #endif
                    nrm += SAMPLE_TEXTURE2D(_Normal1, sampler_Normal0, detailUV) * splatControl.g;
                    nrm += SAMPLE_TEXTURE2D(_Normal2, sampler_Normal0, detailUV) * splatControl.b;
                    nrm += SAMPLE_TEXTURE2D(_Normal3, sampler_Normal0, detailUV) * splatControl.a;
                    normalTS = UnpackNormal(nrm);
                #endif

                #if defined(_TOPDOWNPROJECTION) && defined(_NORMALMAP)
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    normalTS = normalize(TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz)));
                //  We use Reoriented Normal Mapping to bring the the top down normal into world space
                    half3 n1 = /*normalize*/(input.normalWS.xzy);
                    half3 n2 = topdownNormal.xyz;
                    n1.z += 1.0h;
                    n2.xy *= -1.0h;
                    half3 topDownNormalWS = n1 * dot(n1, n2) / n1.z - n2;
                    topDownNormalWS = topDownNormalWS.xzy;
                //  Finally we blend both normals in world space 
                    normalTS = normalize(normalTS * (1.0h - splatControl.r) + topDownNormalWS * splatControl.r);
                #endif

                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.smoothness = albedoAlpha.a; 
                outSurfaceData.normalTS = normalTS;
                outSurfaceData.emission = 0;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _Specular.rgb;
                outSurfaceData.occlusion = 1.0h - _Occlusion;
                outSurfaceData.alpha = 1;

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 0;
            }


            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                SurfaceData surfaceData;
                half3 topdownNormal;
                half topnormalstrength;
            
            //  Get the surface description
                InitializeStandardLitSurfaceData(input, surfaceData, topdownNormal);

            //  Transfer all to world space 
                InputData inputData;
                inputData.positionWS = input.positionWS;

                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                #ifdef _NORMALMAP
                    #if !defined(_TOPDOWNPROJECTION)
                        float sgn = input.tangentWS.w;      // should be either +1 or -1
                        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                    #else
                        inputData.normalWS = surfaceData.normalTS;
                    #endif
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

                half4 color = UniversalFragmentPBR(
                    inputData, 
                    surfaceData.albedo, 
                    surfaceData.metallic, 
                    surfaceData.specular, 
                    surfaceData.smoothness, 
                    surfaceData.occlusion, 
                    surfaceData.emission, 
                    surfaceData.alpha);

            //  Computes fog factor per-vertex
                color.rgb = MixFog(color.rgb, input.fogFactorAndVertexLight.x);
                #if _AlphaClip
                    clip(Alpha - AlphaClipThreshold);
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
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            //#define _NORMALMAP 1
            #define _SPECULAR_SETUP 1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float2 _SplatTiling;
                float4 _Specular;
                float _Occlusion;
                half _TopDownTiling;
            CBUFFER_END


            struct VertexInput
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            //  Needs Shadows.hlsl
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowPassFragment(VertexOutput input ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return 0;
            }

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float2 _SplatTiling;
                float4 _Specular;
                float _Occlusion;
                half _TopDownTiling;
            CBUFFER_END

            struct VertexInput
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 positionCS      : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 frag(VertexOutput input ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
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
            Cull Back

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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float2 _SplatTiling;
                float4 _Specular;
                float _Occlusion;
                half _TopDownTiling;
            CBUFFER_END

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float3 normal     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 positionCS      : SV_POSITION;
                float3 normalWS        : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput DepthNormalsVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, float4(1,1,1,1));
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
                
                return output;
            }

            half4 DepthNormalsFragment(VertexOutput input ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
            }

            ENDHLSL
        }

    //  Meta -----------------------------------------------------

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM

        //  Tell Polybrush that this shader supports 4 texture channels
            #define Z_TEXTURE_CHANNELS 4
            #define Z_MESH_ATTRIBUTES COLOR

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            //#define _NORMALMAP 1
            #define _SPECULAR_SETUP 1

            #pragma shader_feature_local_fragment _TOPDOWNPROJECTION
            #pragma shader_feature_local_fragment _USEVERTEXCOLORS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float2 _SplatTiling;
                float4 _Specular;
                float _Occlusion;
                half _TopDownTiling;
            CBUFFER_END

            TEXTURE2D(_DetailA0);   SAMPLER(sampler_DetailA0);  float4 _DetailA0_TexelSize;
            TEXTURE2D(_DetailA1);   float4 _DetailA1_TexelSize;
            TEXTURE2D(_DetailA2);   float4 _DetailA2_TexelSize;
            TEXTURE2D(_DetailA3);   float4 _DetailA3_TexelSize;
            TEXTURE2D(_SplatMap);   SAMPLER(sampler_SplatMap); float4 _SplatMap_TexelSize;

            struct VertexInput
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;

                #if defined(_USEVERTEXCOLORS)
                    half4 color     : COLOR;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS   : SV_POSITION;
                float2 uv0          : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;

                #if defined(_USEVERTEXCOLORS)
                    half4 color     : COLOR;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionWS = mul(UNITY_MATRIX_M, input.positionOS).xyz;
                output.uv0 = input.texcoord;
                output.uv1 = input.lightmapUV;
                output.positionCS = MetaVertexPosition(input.positionOS, input.lightmapUV, input.lightmapUV, unity_LightmapST, unity_DynamicLightmapST);

                #if defined(_USEVERTEXCOLORS)
                    output.color = input.color;
                #endif

                return output;
            }

            half4 frag(VertexOutput input ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 detailUV = input.uv0 * _SplatTiling;
                half4 splatControl = 0;
                #if defined(_USEVERTEXCOLORS)
                    splatControl = input.color;
                    splatControl.a = 1.0h - splatControl.r - splatControl.g - splatControl.b;
                #else
                    splatControl.rgb = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, input.uv0).rgb;
                    splatControl.a = 1.0h - splatControl.r - splatControl.g - splatControl.b;
                #endif
                
                
                #if defined(_TOPDOWNPROJECTION)
                    float2 uvWS = input.positionWS.xz * _TopDownTiling;
                    half4 albedoAlpha = SAMPLE_TEXTURE2D(_DetailA0, sampler_DetailA0, uvWS) * splatControl.r;
                #else
                    half4 albedoAlpha = SAMPLE_TEXTURE2D(_DetailA0, sampler_DetailA0, detailUV) * splatControl.r;
                #endif
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA1, sampler_DetailA0, detailUV) * splatControl.g;
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA2, sampler_DetailA0, detailUV) * splatControl.b;
                albedoAlpha += SAMPLE_TEXTURE2D(_DetailA3, sampler_DetailA0, detailUV) * splatControl.a;

                #if _AlphaClip
                //    clip(Alpha - AlphaClipThreshold);
                #endif

                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = albedoAlpha.rgb;
                metaInput.Emission = 0;
                
                return MetaFragment(metaInput);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}