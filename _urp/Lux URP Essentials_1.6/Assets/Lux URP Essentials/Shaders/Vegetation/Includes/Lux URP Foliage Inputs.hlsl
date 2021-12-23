#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"  
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
    #include "../Includes/Lux URP Translucent Lighting.hlsl"


    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
    CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half _Cutoff;
        half _Smoothness;
        half3 _SpecColor;
        half4 _WindMultiplier;
        float _SampleSize;
        //#ifdef _NORMALMAP
            half _GlossMapScale;
            half _BumpScale;
        //#endif
        float2 _DistanceFade;
        half _TranslucencyPower;
        half _TranslucencyStrength;
        half _ShadowStrength;
        half _MaskByShadowStrength;
        half _Distortion;
        #if defined(DEBUG)
            half _DebugColor;
            half _Brightness;
        #endif
    CBUFFER_END

//  Additional textures
    TEXTURE2D(_BumpSpecMap); SAMPLER(sampler_BumpSpecMap); float4 _BumpSpecMap_TexelSize;
    TEXTURE2D(_LuxLWRPWindRT); SAMPLER(sampler_LuxLWRPWindRT);

//  Global Inputs
    float4 _LuxLWRPWindDirSize;
    float4 _LuxLWRPWindStrengthMultipliers;
    float4 _LuxLWRPSinTime;

    float2 _LuxLWRPGust;

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
        half fade                           : TEXCOORD9;

        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
            float3 normalWS                 : TEXCOORD3;
        #endif

        #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
            DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS           : TEXCOORD2;
            #endif
            float3 viewDirWS                : TEXCOORD4;
            #ifdef _NORMALMAP
                float4 tangentWS            : TEXCOORD5;
            #endif
            half4 fogFactorAndVertexLight   : TEXCOORD6;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord          : TEXCOORD7;
            #endif
        #endif
        #if defined(DEBUG)
            half4 color                     : COLOR;
        #endif

        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescription
    {
        float3 albedo;
        float alpha;
        float3 normalTS;
        float3 emission;
        float metallic;
        float3 specular;
        float smoothness;
        float occlusion;
        float translucency;
    };


    half4 SmoothCurve( half4 x ) {   
    return x * x *( 3.0h - 2.0h * x );   
    }
    half4 TriangleWave( half4 x ) {   
        return abs( frac( x + 0.5h ) * 2.0h - 1.0h );   
    }
    half4 SmoothTriangleWave( half4 x ) {   
        return SmoothCurve( TriangleWave( x ) );   
    }

    half2 SmoothCurve( half2 x ) {   
    return x * x *( 3.0h - 2.0h * x );   
    }
    half2 TriangleWave( half2 x ) {   
        return abs( frac( x + 0.5h ) * 2.0h - 1.0h );   
    }
    half2 SmoothTriangleWave( half2 x ) {   
        return SmoothCurve( TriangleWave( x ) );   
    }

    #define foliageMainWindStrengthFromZone _LuxLWRPWindStrengthMultipliers.y
    #define primaryBending _WindMultiplier.x
    #define secondaryBending _WindMultiplier.y
    #define edgeFlutter _WindMultiplier.z

    void animateVertex(half4 animParams, half3 normalOS, inout float3 positionOS) {

        float origLength = length(positionOS.xyz);
        float3 windDir = mul(UNITY_MATRIX_I_M, float4(_LuxLWRPWindDirSize.xyz, 0)).xyz;

        half fDetailAmp = 0.1h;
        half fBranchAmp = 0.3h;
        
    #if !defined(_WIND_MATH)
        float2 samplePos = TransformObjectToWorld(positionOS.xyz * _SampleSize).xz * _LuxLWRPWindDirSize.ww;
        
        half fVtxPhase = dot( normalize(positionOS.xyz), ((animParams.g + animParams.r) * 0.5).xxx );
        float4 wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, samplePos.xy, _WindMultiplier.w);

    //  Factor in bending params from Material
        animParams.abg *= _WindMultiplier.xyz;
    //  Make math match
        animParams.ab *= 2;

    //  Primary bending
        positionOS.xz += animParams.a   *   windDir.xz * foliageMainWindStrengthFromZone * smoothstep(-1.5h, 1.0h, wind.r * (wind.g * 1.0h - 0.243h));

    //  Second texture sample taking phase into account
        wind = SAMPLE_TEXTURE2D_LOD(_LuxLWRPWindRT, sampler_LuxLWRPWindRT, samplePos.xy - animParams.rr * 0.5, _WindMultiplier.w);
    //  Edge Flutter
        float3 bend = normalOS.xyz * (animParams.g * fDetailAmp * lerp(_LuxLWRPSinTime.y, _LuxLWRPSinTime.z, wind.r));
        bend.y = animParams.b * 0.3h;
    //  Edge Flutter and Secondary Bending
        positionOS.xyz += ( bend + ( animParams.b  *  windDir * wind.r * (wind.g * 2.0h - 0.243h) ) ) * foliageMainWindStrengthFromZone; 
        
    #else
        float3 objectWorldPos = UNITY_MATRIX_M._m03_m13_m23;

    //  Animate incoming wind
        float3 absObjectWorldPos = abs(objectWorldPos.xyz * 0.125h);
        float sinuswave = _SinTime.z;
        half2 vOscillations = SmoothTriangleWave( half2(absObjectWorldPos.x + sinuswave, absObjectWorldPos.z + sinuswave * 0.7h) );
        // x used for main wind bending / y used for tumbling
        half2 fOsc = (vOscillations.xy * vOscillations.xy);
        fOsc = 0.75h + (fOsc + 3.33h) * 0.33h;

        half fObjPhase = dot(objectWorldPos, 1);
        half fBranchPhase = fObjPhase + animParams.r;
        half fVtxPhase = dot(positionOS.xyz, animParams.g + fBranchPhase);

    //  Factor in bending params from Material
        animParams.abg *= _WindMultiplier.xyz;

        // x is used for edges; y is used for branches
        half2 vWavesIn = _Time.yy + half2(fVtxPhase, fBranchPhase);
        // 1.975, 0.793, 0.375, 0.193 are good frequencies
        half4 vWaves = (frac( vWavesIn.xxyy * half4(1.975h, 0.793h, 0.375h, 0.193h) ) * 2.0h - 1.0h);
        vWaves = SmoothTriangleWave( vWaves );
        half2 vWavesSum = vWaves.xz + vWaves.yw;

    //  Primary bending / animated by * fOsc.x
        positionOS.xz += animParams.a   *   windDir.xz * foliageMainWindStrengthFromZone * fOsc.x;

        float3 bend = normalOS.xyz * (animParams.g * fDetailAmp);
        bend.y = animParams.b * fBranchAmp;

        positionOS.xyz += ( (vWavesSum.xyx * bend) + (animParams.b   *   windDir * fOsc.y * vWavesSum.y) ) * foliageMainWindStrengthFromZone;
    #endif
        positionOS.xyz = normalize(positionOS.xyz) * origLength;
    }
#endif