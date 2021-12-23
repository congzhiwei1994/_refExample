#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED



    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    #include "../Includes/Lux URP Blend Lighting.hlsl"
 
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)

        float3  _TerrainPos;
        float3  _TerrainSize;
        float4  _TerrainHeightNormal_TexelSize;

        float   _Shift;

        half    _AlphaShift;
        half    _AlphaWidth;
        float   _ShadowShiftThreshold;
        float   _ShadowShift;
        float   _ShadowShiftView;
        half    _NormalShift;
        half    _NormalWidth;
        half    _NormalThreshold;
        half    _BumpScale;

        half4   _BaseColor;
        half    _Cutoff;
        float4  _BaseMap_ST;
        half    _Smoothness;
        half3   _SpecColor;
        //half    _OcclusionStrength;
        
    CBUFFER_END

//  Additional textures
    //TEXTURE2D(_TopDownBaseMap); SAMPLER(sampler_TopDownBaseMap);
    //TEXTURE2D(_TopDownNormalMap); SAMPLER(sampler_TopDownNormalMap);
    TEXTURE2D(_TerrainHeightNormal); SAMPLER(sampler_TerrainHeightNormal);


//  Global Inputs

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
            //#ifdef _ADDITIONAL_LIGHTS
                float3 positionWS           : TEXCOORD2;
            //#endif
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
        half alpha;
        half3 normalTS;
        half3 emission;
        half metallic;
        half3 specular;
        half smoothness;
        half occlusion;
    };

#endif