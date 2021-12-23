#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)
        half4   _BaseColor;
        half    _Cutoff;

        float4  _BaseMap_ST;

        half4   _OutlineColor;
        half    _Border;
        float4  _BaseMap_TexelSize;       
    CBUFFER_END

//  Additional textures

//  Global Inputs

//  Structs
    struct VertexInputSimple
    {
        float3 positionOS                   : POSITION;
        float2 texcoord                     : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct VertexOutputSimple
    {
        float4 positionCS               : SV_POSITION;
        float2 uv                       : TEXCOORD0;
        #if defined(_APPLYFOG)
            half fogFactor              : TEXCOORD1;
        #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescriptionSimple
    {
        half alpha;
    };

//  Helper
    inline float2 shufflefast (float2 offset, float2 shift) {
        return offset * shift;
    }

#endif