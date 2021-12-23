#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED



    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    #include "../Includes/Lux URP Transparent Lighting.hlsl"
 
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)

        half    _FinalAlpha;
        //half3   _GlassTint;
        //float   _RayLength;
        float   _IOR;
        half    _BumpRefraction;
        float   _IsThinShell;
        //float   _PixelDepth;

        half4   _BaseColor;
        half    _Smoothness;
        //half    _Metallic;
        half3   _SpecColor;

        float   _ScreenEdgeFade;

    //  None glass
        half    _SmoothnessBase;
        half3   _SpecColorBase;    
        //half    _Cutoff;
        //half    _ShadowOffset;

    //  Needed by LitMetaPass
        float4  _BaseMap_ST;
        float4  _BumpMap_ST;
        half    _BumpScale;
        float4  _MaskMap_ST;

        //half    _Occlusion;
        //half    _TranslucencyPower;
        //half    _TranslucencyStrength;
        //half    _ShadowStrength;
        //half    _Distortion;

        half4   _RimColor;
        half    _RimPower;
        half    _RimMinPower;
        half    _RimFrequency;
        half    _RimPerPositionFrequency;
            
    CBUFFER_END

//  Additional textures

    TEXTURE2D_X(_CameraOpaqueTexture); SAMPLER(sampler_LinearClamp);
    float4 _CameraOpaqueTexture_TexelSize;
    SamplerState my_linear_clamp_sampler;

    #if defined(SHADER_API_GLES)
        TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    #else
        TEXTURE2D_X(_CameraDepthTexture); //SAMPLER(sampler_PointClamp);
    #endif
    float4 _CameraDepthTexture_TexelSize;
    
    #if defined(_MASKMAP)
        TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
    #endif
    #if defined(_TINTMAP)
        TEXTURE2D(_TintMap); SAMPLER(sampler_TintMap);
    #endif


//  Global Inputs

//  Structs
    struct VertexInput
    {
        float3 positionOS                   : POSITION;
        float3 normalOS                     : NORMAL;
        float4 tangentOS                    : TANGENT;
        float2 texcoord                     : TEXCOORD0;
        float2 lightmapUV                   : TEXCOORD1;
   //   half4 color                         : COLOR;
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
            float4 projectionCoord          : TEXCOORD8;
            float  scale                    : TEXCOORD9;

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