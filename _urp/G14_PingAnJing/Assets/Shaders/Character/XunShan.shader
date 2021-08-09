Shader "CzwTest/Character/XunaShan"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] _WorkflowMode("WorkflowMode", Float) = 1.0
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BaseMapScale("_BaseMap Scale", Float) = 1.0

        [Space(20)]
        [Header(Normal)]
        _BumpScale("Normal Scale", Float) = 1.0
        _BumpMap("Normal Map(RG) AO(B)", 2D) = "bump" {}

        [Space(30)]
        _AnisotropicTex("Anisotropic texture",2D) = "white"{}
        _AniShift("AniShift",float) = 1
        _NoiseOffset("Noise Offset", Float) = 1.0

        [Space(30)]
        _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        _MixMap("Metallic(R) AniMask(G) Smoothness(B)", 2D) = "white" {}
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        _lightDirScale("Main lightDir(灯光方向)",float) = 1
        _EmissionColor("Color", Color) = (0,0,0)
        _ShadowColor("Shadow Color" ,color) = (0.5,0.5,0.5)
        _SubsurfaceFactor("Subsurface Factor",float) = 0.5
        _EnvironmentBrightness("EnvironmentBrightness",float) = 1

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        _ReceiveShadows("Receive Shadows", Float) = 1.0
        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0
    }

    SubShader
    {
        
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        
        Pass
        {
            
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            ColorMask RGB

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _OCCLUSIONMAP

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
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

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "XunShanCharacterLighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"          
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _SpecColor;
            half4 _EmissionColor;
            half _Cutoff;
            half _Smoothness;
            half _Metallic;
            half _BumpScale;
            half4 _AnisotropicTex_ST;
            float _lightDirScale;
            float _AniShift;
            float _NoiseOffset;
            half _BaseMapScale;
            half4 _ShadowColor;
            half _SubsurfaceFactor;
            half _EnvironmentBrightness;
            CBUFFER_END

            TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_MixMap);             SAMPLER(sampler_MixMap);
            TEXTURE2D(_AnisotropicTex);     SAMPLER(sampler_AnisotropicTex);


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                half3 positionWS          :TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;
                
                float3 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
                half3 bitangentWS                     :TEXCOORD8;
                float3 viewDirWS                : TEXCOORD5;

                half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord              : TEXCOORD7;
                #endif

                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            
            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            Varyings LitPassVertex(Attributes v)
            {
                Varyings o = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.uv = v.texcoord;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);

                o.normalWS  = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                real sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(v.normalOS, v.tangentOS)* sign;

                o.viewDirWS = _WorldSpaceCameraPos-  o.positionWS;
                half3 vertexLight = VertexLighting( o.positionWS, o.normalWS);
                half fogFactor = ComputeFogFactor(o.positionCS.z);

                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);

                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    o.shadowCoord = TransformWorldToShadowCoord( o.positionWS);
                #endif

                return o;
            }



            half4 LitPassFragment(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half4 albedo = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));    
                half4 AnisTex = SAMPLE_TEXTURE2D(_AnisotropicTex,sampler_AnisotropicTex, i.uv); 
                half4 mixMap = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, i.uv.xy);
                half4 uv_normalMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy);
                half3 normalMapTS = UnpackNormalRG_Custom(uv_normalMap.rg, 1.0);// 将normal.b 赋值为 1，因为面部法线的z取1时正好可以去除面部的自投影。
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half3 normalMapWS = TransformTangentToWorld(normalMapTS, tbn);

                // HairInputData hairInput;
                // ZERO_INITIALIZE(HairInputData, hairInput);
                // hairInput.aniMap = AnisTex;
                // half3 aniNormalTS = UnpackNormalRG_Custom(AnisTex.rg, 0);
                // hairInput.aniNormalWS = normalize(TransformTangentToWorld_Scale(aniNormalTS,1.0,tbn));
                // hairInput.normalScale = _AniShift + ((AnisTex.b - 0.5) * _NoiseOffset); // aniMap.b (-0.5 ~ 0.5)
                // hairInput.aniNormalWS = normalize((normalMapWS * normalScale) + hairInput.aniNormalWS);	  // 头发法线合并到整体法线纹理             

                
                //--------------------------------------------------------------------------------------
                // SurfaceData
                //--------------------------------------------------------------------------------------           
                SurfaceData surfaceData;
                ZERO_INITIALIZE(SurfaceData, surfaceData);
                surfaceData.alpha = Alpha(albedo.a, _BaseColor, _Cutoff); 
                surfaceData.albedo = albedo.rgb * _BaseColor.rgb * _BaseMapScale;
                surfaceData.metallic = saturate(mixMap.r + _Metallic);
                surfaceData.specular = 0;
                surfaceData.smoothness = saturate((1-mixMap.b) + _Smoothness);
                surfaceData.normalTS = normalMapTS;
                surfaceData.occlusion = uv_normalMap.b;
                surfaceData.emission = 0;

                //--------------------------------------------------------------------------------------
                // InputData
                //--------------------------------------------------------------------------------------
                InputData inputData;
                ZERO_INITIALIZE(InputData, inputData);
                inputData.positionWS = i.positionWS;
                inputData.normalWS = NormalizeNormalPerPixel(normalMapWS);
                inputData.viewDirectionWS = SafeNormalize(i.viewDirWS);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                inputData.fogCoord = i.fogFactorAndVertexLight.x;
                inputData.vertexLighting = i.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);



                // --------------------------------------------------------------------------------------
                // XunShanInputData
                // --------------------------------------------------------------------------------------
                SubsurfaceInputDate  subsurfaceInput;
                ZERO_INITIALIZE(SubsurfaceInputDate, subsurfaceInput);
                subsurfaceInput.sssMask = saturate((mixMap.g * 2) - 1); // remap -1到1 但去掉-1到0的值（即去掉原图0-0.5的值，取0.5-1）
                subsurfaceInput.sssFactor = saturate(subsurfaceInput.sssMask * _SubsurfaceFactor);
                //  RGB值小于0.35的恒定(baseMap.rgb - 0.1)，越大于0.35，得到值越暗
                subsurfaceInput.sssColor = saturate(surfaceData.albedo.rgb - max(max(max(surfaceData.albedo.r, surfaceData.albedo.g), surfaceData.albedo.b) - 0.39, 0.1));
                subsurfaceInput.shadowColor = lerp(_ShadowColor.xyz, 1.0, subsurfaceInput.sssFactor); // 控制暗部颜色	
                subsurfaceInput.environmentBrightness = _EnvironmentBrightness;
                

                
                //--------------------------------------------------------------------------------------
                half4 color = UniversalFragmentPBR1(
                subsurfaceInput,
                inputData, 
                surfaceData.albedo, 
                surfaceData.metallic,
                surfaceData.specular, 
                surfaceData.smoothness, 
                surfaceData.occlusion, 
                surfaceData.emission, 
                surfaceData.alpha);
                
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                // color.a = OutputAlpha(color.a);

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
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }



        
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    // CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
