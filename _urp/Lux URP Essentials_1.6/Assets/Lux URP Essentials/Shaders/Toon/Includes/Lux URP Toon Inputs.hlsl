#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED



    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 



    #include "../Includes/Lux URP Toon Lighting.hlsl"

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)

        half4   _BaseColor;
        half    _Cutoff;
        float4  _BaseMap_ST;
        half    _Smoothness;
        half3   _SpecColor;

    //  Toon
        half3   _ShadedBaseColor;
        half    _Steps;
        half    _DiffuseStep;
        half    _DiffuseFallOff;
        half    _EnergyConservation;
        half    _SpecularStep;
        half    _SpecularFallOff;
        half    _ColorizedShadowsMain;
        half    _ColorizedShadowsAdd;
        half    _LightColorContribution;
        half    _AddLightFallOff;
        half    _ShadowFallOff;
        half    _ShadoBiasDirectional;
        half    _ShadowBiasAdditional;
        half3   _SpecColor2nd;

        half3   _ToonRimColor;
        half    _ToonRimPower;
        half    _ToonRimFallOff;
        half    _ToonRimAttenuation;

        half3   _EmissionColor;

    //  Simple
        half    _BumpScale;
        float4  _MaskMap_ST;
        half    _OcclusionStrength;

        half    _ShadowOffset;

        half4   _RimColor;
        half    _RimPower;
        half    _RimMinPower;
        half    _RimFrequency;
        half    _RimPerPositionFrequency;
    CBUFFER_END

//  Additional textures
//  Toon
    #if defined(_TEXMODE_TWO)
        TEXTURE2D(_ShadedBaseMap);
    #endif
    #if defined(_MASKMAP)
        TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
    #endif


//  Global Inputs

//  Structs
    struct VertexInput
    {
        float3 positionOS                   : POSITION;
        float3 normalOS                     : NORMAL;
        #if defined(_NORMALMAP)
            float4 tangentOS                : TANGENT;
        #endif
        #if defined(_TEXMODE_ONE) || defined(_TEXMODE_TWO) || defined(_NORMALMAP) || defined(_MASKMAP)
            float2 texcoord                 : TEXCOORD0;
        #endif
        #if defined(LIGHTMAP_ON)
            float2 lightmapUV               : TEXCOORD1;
        #endif
        //half4 color                       : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct VertexOutput
    {
        float4 positionCS                   : SV_POSITION;
        #if defined(_TEXMODE_ONE) || defined(_TEXMODE_TWO) || defined(_TEXMODE_TWO) || defined(_NORMALMAP) || defined(_MASKMAP)
            float2 uv                       : TEXCOORD0;
        #endif

        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
            DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS           : TEXCOORD2;
            #endif
            float3 normalWS                 : TEXCOORD3;
            float3 viewDirWS                : TEXCOORD4;
            #if defined(_NORMALMAP)
                float4 tangentWS            : TEXCOORD5;
            #endif
            half4 fogFactorAndVertexLight   : TEXCOORD6;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord          : TEXCOORD7;
            #endif
        #endif

        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescription
    {
        half3 albedo;
        half3 albedoShaded;
        half alpha;
        half3 normalTS;
        half3 emission;
        half metallic;
        half3 specular;
        half smoothness;
        half occlusion;
    };

#endif