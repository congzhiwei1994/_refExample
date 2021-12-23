#ifndef INPUT_BASETOPDOWN_INCLUDED
#define INPUT_BASETOPDOWN_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
    #include "../Includes/Lux URP Simple Fuzz Lighting.hlsl"

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


    CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;

        half4 _BaseColor;

        half3 _SpecColor;
        half _BumpScale;

        half _GlossMapScale;
        half _GlossMapScaleDyn;

        half3 _EmissionColor;
        half _Occlusion;

        half _BumpScaleDyn;

        half _NormalFactor;
        half _NormalLimit;
        half _TopDownTiling;
        float3 _TerrainPosition;
        half _LowerNormalMinStrength;
        half _LowerNormalInfluence;

        half _HeightBlendSharpness;

    //  Simple Fuzz
        half    _FuzzStrength;
        half    _FuzzAmbient;
        half    _FuzzWrap;
        half    _FuzzPower;        
        half    _FuzzBias;

        half    _Cutoff;    //HDRP 10.1. DepthNormal pass

    CBUFFER_END



    struct VertexInput
    {
        float4 positionOS   : POSITION;
        float3 normalOS     : NORMAL;
        float4 tangentOS    : TANGENT;
        float2 texcoord     : TEXCOORD0;
        float2 lightmapUV   : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };


    struct VertexOutput {
        
        float4 positionCS               : SV_POSITION;
        //#ifdef _ADDITIONAL_LIGHTS
        float3 positionWS               : TEXCOORD0;
        //#endif
        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS) && !defined(DEPTHNORMALONLYPASS)
            float4 uv                   : TEXCOORD1;
            #if !defined(CUSTOMMETAPASS)
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 2);
                float3 normalWS                  : TEXCOORD3;
                #ifdef _NORMALMAP
                    float4 tangentWS             : TEXCOORD4;    // xyz: tangent, w: tangent sign
                #endif
                float3 viewDirWS                 : TEXCOORD5;
                
                float4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord          : TEXCOORD7;
                #endif
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
        half fuzzMask;
    };



#endif