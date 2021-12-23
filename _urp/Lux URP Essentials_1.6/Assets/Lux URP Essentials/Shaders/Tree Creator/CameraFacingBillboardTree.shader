// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/CameraFacingBillboardTree" {
    Properties{
        _MainTex("Base (RGB) Alpha (A)", 2D) = "white" {}
        _NormalTex("Base (RGB) Alpha (A)", 2D) = "white" {}
        _TranslucencyViewDependency("View dependency", Range(0,1)) = 0.7
        _TranslucencyColor("Translucency Color", Color) = (0.73,0.85,0.41,1)
        _AlphaToMask("AlphaToMask", Float) = 1.0 // On
    }
        SubShader{
            Tags {
                "IgnoreProjector" = "True" "RenderType" = "TreeBillboard" }

            Pass {
                ColorMask rgb
                ZWrite On Cull Off
//              AlphaToMask [_AlphaToMask]

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fog
                #include "UnityCG.cginc"
                #include "UnityBuiltin3xTreeLibrary.cginc"
#if SHADER_API_D3D11 || SHADER_API_GLCORE
#define ALBEDO_NORMAL_LIGHTING 1
#endif
                struct v2f {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR0;
                    float3 uv : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    UNITY_VERTEX_OUTPUT_STEREO
                    float4 screenPos : TEXCOORD2;
#if defined(ALBEDO_NORMAL_LIGHTING)
                    float3 viewDir : TEXCOORD3;
#endif
                };

#if defined(ALBEDO_NORMAL_LIGHTING)
                CBUFFER_START(UnityTerrainImposter)
                    float3 _TerrainTreeLightDirections[4];
                    float4 _TerrainTreeLightColors[4];
                CBUFFER_END
#endif
        void CameraFacingBillboardVert(inout float4 pos, float2 offset, float offsetz)
        {
            float3 vertViewVector = pos.xyz - _TreeBillboardCameraPos.xyz;
            float treeDistanceSqr = dot(vertViewVector, vertViewVector);
            float distance = sqrt(treeDistanceSqr);
            if (treeDistanceSqr > _TreeBillboardDistances.x)
                offset.xy = offsetz = 0.0;
            // Create LookAt matrix
            float3 up = float3(0, 1, 0);
            float3 zaxis = vertViewVector / distance; // distance won't be 0 since billboard would already be clipped by near plane
            float3 xaxis = normalize(cross(up, zaxis)); // direct top down view of billboard won't be visible due its orientation about yaxis
            float vertexCameraDistance = distance - _TreeBillboardDistances.z;
            float fadeAmount = saturate(vertexCameraDistance / _TreeBillboardDistances.w);
            pos.w = fadeAmount;
            if (vertexCameraDistance > _TreeBillboardDistances.w)
                pos.w = 1.0;

            // positioning of billboard vertices horizontally
            pos.xyz += xaxis * offset.x;
            float radius = offset.y;
            // positioning of billboard vertices veritally
            pos.xyz += up * radius;
        }

                v2f vert(appdata_tree_billboard v) {
                    v2f o;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    CameraFacingBillboardVert(v.vertex, v.texcoord1.xy, v.texcoord.y);
                    o.uv.z = v.vertex.w;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv.x = v.texcoord.x;
                    o.uv.y = v.texcoord.y > 0;
#if defined(ALBEDO_NORMAL_LIGHTING)
                    o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
#endif
                    o.color = v.color;
                    o.screenPos = ComputeScreenPos(o.pos);
                    UNITY_TRANSFER_FOG(o,o.pos);
                    return o;
                }



float LuxScreenDitherToAlpha(float x, float y, float c0)
{
#if (SHADER_TARGET > 30) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3)
    //dither matrix reference: https://en.wikipedia.org/wiki/Ordered_dithering
    const float dither[64] = {
        0, 32, 8, 40, 2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26 ,
        12, 44, 4, 36, 14, 46, 6, 38 ,
        60, 28, 52, 20, 62, 30, 54, 22,
        3, 35, 11, 43, 1, 33, 9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47, 7, 39, 13, 45, 5, 37,
        63, 31, 55, 23, 61, 29, 53, 21 };

    int xMat = int(x) & 7;
    int yMat = int(y) & 7;
    float limit = (dither[yMat * 8 + xMat] + 11) / 64.0;
    return saturate( c0 * (1 + c0) - limit);
#else
    return 1.0;
#endif
}

float LuxComputeAlphaCoverage(float4 screenPos, float fadeAmount)
{
#if (SHADER_TARGET > 30) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3)
    float2 pixelPosition = screenPos.xy / (screenPos.w + 0.00001);
    pixelPosition *= _ScreenParams;
    float coverage = LuxScreenDitherToAlpha(pixelPosition.x, pixelPosition.y, fadeAmount);
    return coverage;
#else
    return 1.0;
#endif
}



                half3 CalcTreeLighting(half3 viewDir, half3 lightColor, half3 lightDir, half3 albedo, half3 normal, half backContribScale)
                {
                    half backContrib = saturate(dot(viewDir, -lightDir));
                    half ndotl = dot(lightDir, normal);
                    backContrib = lerp(saturate(-ndotl), backContrib, _TranslucencyViewDependency) * backContribScale;
                    half3 translucencyColor = backContrib * _TranslucencyColor;
                    const half diffuseWrap = 0.8;
                    ndotl = saturate(ndotl * diffuseWrap + (1 - diffuseWrap));
                    return albedo * (translucencyColor + ndotl) * lightColor;
                }

                sampler2D _MainTex;
                sampler2D _NormalTex;

                fixed4 frag(v2f input) : SV_Target
                {
                    fixed4 col = tex2D(_MainTex, input.uv.xy);
                    col.rgb *= input.color.rgb;
#if defined(ALBEDO_NORMAL_LIGHTING)
                    half3 normal = tex2D(_NormalTex, input.uv.xy).xyz;
                    normal = normalize(normal);
                    half3 albedo = col.rgb;
// half3 light = UNITY_LIGHTMODEL_AMBIENT * albedo;
half3 light = ShadeSH9(half4 (normal, 1)) * albedo;
                    const half backContribScale = 0.2;

                    light += CalcTreeLighting(input.viewDir, _TerrainTreeLightColors[0].rgb, _TerrainTreeLightDirections[0], albedo, normal, backContribScale);
                    light += CalcTreeLighting(input.viewDir, _TerrainTreeLightColors[1].rgb, _TerrainTreeLightDirections[1], albedo, normal, backContribScale);
                    light += CalcTreeLighting(input.viewDir, _TerrainTreeLightColors[2].rgb, _TerrainTreeLightDirections[2], albedo, normal, backContribScale);
                    col.rgb = light;
#endif
//col.rgb = half3(1,0,0);
                    float coverage = LuxComputeAlphaCoverage(input.screenPos, input.uv.z);
                    col.a *= coverage;
                    clip(col.a - _TreeBillboardCameraFront.w );
                    UNITY_APPLY_FOG(input.fogCoord, col);
                    return col;
                }
                ENDCG
            }
    }

        Fallback Off
}
