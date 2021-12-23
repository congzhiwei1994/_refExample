#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
    #include "../Includes/Lux URP Hair Lighting.hlsl"

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)

        float4 _BaseMap_ST;
        
        half4 _BaseColor;
        half4 _SecondaryColor;
        half _Cutoff;

        half _Smoothness;
        half3 _SpecColor;
        
        half _BumpScale;

        half _StrandDir;
        half _SpecularShift;
        half3 _SpecularTint;
        half _SpecularExponent;
        half _SecondarySpecularShift;
        half3 _SecondarySpecularTint;
        half _SecondarySpecularExponent;
        half _RimTransmissionIntensity;
        half _AmbientReflection;
        //half _OcclusionStrength;
        //float2 _DistanceFade;

        #if defined(_RIMLIGHTING)
            half4 _RimColor;
            half _RimPower;
            half _RimMinPower;
            half _RimFrequency;
            half _RimPerPositionFrequency;
        #endif

    //  Needed by URP 10.1. depthnormal
        half _Surface;

    CBUFFER_END

//  Additional textures
    TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
    //TEXTURE2D(_Dither); SAMPLER(sampler_Dither); float4 _Dither_TexelSize;

//  Global Inputs
    //float _FrameIndexMod4;

//  Structs
    struct VertexInput
    {
        float3 positionOS                   : POSITION;
        float3 normalOS                     : NORMAL;
        float4 tangentOS                    : TANGENT;
        float2 texcoord                     : TEXCOORD0;
        float2 lightmapUV                   : TEXCOORD1;
        half4 color                         : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct VertexOutput
    {
        float4 positionCS                   : SV_POSITION;
        float2 uv                           : TEXCOORD0;
        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
            DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS           : TEXCOORD2;
            #endif
        //  Hair lighting always needs tangent and bitangent
            float3 normalWS                 : TEXCOORD3;
            float3 viewDirWS                : TEXCOORD4;
            float4 tangentWS                : TEXCOORD5;
            
            half4 fogFactorAndVertexLight   : TEXCOORD6;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord          : TEXCOORD7;
            #endif
        #endif
        //float4 screenPos : TEXCOORD8;
        half4 color                         : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescription
    {
        half3 albedo;
        half alpha;
        half3 normalTS;
        half3 emission;
        half metallic;
        half3 specular;
        half smoothness;
        half occlusion;
        half shift;
    };

#endif