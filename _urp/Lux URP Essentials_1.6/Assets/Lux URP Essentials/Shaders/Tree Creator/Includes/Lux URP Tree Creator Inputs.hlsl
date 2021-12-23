#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED



    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
    #include "../Includes/Lux URP Tree Creator Lighting.hlsl"


    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)

        half4   _Color;
        half    _Smoothness;
        half    _Metallic;
        half3   _SpecColor;

        half    _Cutoff;
        float4  _MainTex_ST;

    //  needed by meta pass
        float4  _BaseMap_ST;
        
        float4  _BumpMap_ST;

        half3   _TranslucencyColor;
        half    _TranslucencyViewDependency;

        half    _ShadowStrength;

        #if defined (DUMMYSHADER)
            half    _Shininess;
        #endif

    CBUFFER_END

//  These can't be per material...

    UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_DEFINE_INSTANCED_PROP(half, _SquashAmount)
        UNITY_DEFINE_INSTANCED_PROP(half4, _TreeInstanceColor)
        UNITY_DEFINE_INSTANCED_PROP(half4, _TreeInstanceScale)
        UNITY_DEFINE_INSTANCED_PROP(half4, _SquashPlaneNormal)
        UNITY_DEFINE_INSTANCED_PROP(half4, _Wind)
    UNITY_INSTANCING_BUFFER_END(Props)
    

    TEXTURE2D (_MainTex); SAMPLER(sampler_MainTex);
    TEXTURE2D (_BumpSpecMap ); SAMPLER(sampler_BumpSpecMap);
    TEXTURE2D (_TranslucencyMap); SAMPLER(sampler_TranslucencyMap);

    #if defined (DUMMYSHADER)
        //TEXTURE2D (_BumpMap); SAMPLER(sampler_BumpMap); // already defined
        TEXTURE2D (_GlossMap); SAMPLER(sampler_GlossMap);
        // TEXTURE2D (_TranslucencyMap); SAMPLER(sampler_TranslucencyMap); // already defined
    #endif

//  Additional textures

//  Global Inputs

//  Structs
    struct VertexInput
    {
        float3 positionOS                   : POSITION;
        float3 normalOS                     : NORMAL;
        float4 tangentOS                    : TANGENT;
        float2 texcoord                     : TEXCOORD0;
        float2 texcoord1                    : TEXCOORD1;
        half4 color                         : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct VertexOutput
    {
        float4 positionCS                   : SV_POSITION;

        #if defined(_MASKMAP)
            float4 uv                       : TEXCOORD0;
        #else
            float2 uv                       : TEXCOORD0;
        #endif

        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
            DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS           : TEXCOORD2;
            #endif
                
            half4 normalWS                  : TEXCOORD3;
            half4 tangentWS                 : TEXCOORD4;
            half4 bitangentWS               : TEXCOORD5;

            half4 fogFactorAndVertexLight   : TEXCOORD6;
            
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord          : TEXCOORD7;
            #endif
        #endif

        #if defined(BILLBOARD_FACE_CAMERA_POS) && defined(_ENABLEDITHERING)
            float4 screenPos                : TEXCOORD8;
        #endif

        half4 color                         : COLOR;

        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescription
    {
        half3 albedo;
        half alpha;
        half3 normalTS;
        half3 specular;
        half gloss;
        half occlusion;
        half translucency;
    };

#endif