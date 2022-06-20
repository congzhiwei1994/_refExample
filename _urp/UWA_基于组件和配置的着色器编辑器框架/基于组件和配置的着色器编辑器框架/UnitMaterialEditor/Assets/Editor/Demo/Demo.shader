Shader "Custom/Demo" {

    Properties {
        // #region Textures
        _MainTex( "Main Texture (Changed)", 2D ) = "white" {}
        [NoScaleOffset] _MainTex_Alpha( "Base Alpha (R)", 2D ) = "white" {}
        // #endregion Textures

        // #region Colors
        [HDR]_Color( "Color", Color ) = ( 1, 1, 1, 1 )
        _Cutoff( "Alpha Cutoff", Range( 0, 1 ) ) = 0
        _ColorKey( "Color Key (RGB) Epsilon (A)", Color ) = ( 1.0, 0, 1.0, 0.004 )
        [Toggle] _DoubleColorTint( "Double Color Tint", Float ) = 0.0
        [ToggleOff] _VertexColorTint( "Vertex Color Tint", Float ) = 0.0
        // #endregion Colors

        // #region RenderMode
        [KeywordEnum( Opaque, Cutout, ColorKey, Transparent, Additive, SoftAdditive )]
        [HideInInspector] _Mode( "Mode", Float ) = 0.0
        [HideInInspector] _BlendOp( "Blend OP", Float ) = 0.0
        [HideInInspector] _SrcBlend( "Src Color Blend", Float ) = 1.0
        [HideInInspector] _DstBlend( "Dst Color Blend", Float ) = 0.0
        [HideInInspector] _SrcAlphaBlend( "Src Alpha Blend", Float ) = 1.0
        [HideInInspector] _DstAlphaBlend( "Dst Alpha Blend", Float ) = 0.0
        [HideInInspector] _OutputBloomFactorAlphaSelector( "Output BloomFactor / Alpha Selector", Range( 0, 1 ) ) = 0
        [HideInInspector] _OutputAlphaPreMultiplySelector( "Output Alpha PreMultiply Selector", Range( 0, 1 ) ) = 0
        [HideInInspector] _FogColorSelector( "Fog Selector", Range( 0, 1 ) ) = 1
        [HideInInspector] _ZWrite( "ZWrite", Float ) = 1.0
        [HideInInspector] _ZTest( "ZTest", Float ) = 4 // LEqual
        // #endregion RenderMode

        // #region StencilSettings
        [Enum( UnityEngine.Rendering.CompareFunction )]
        _StencilComp( "Stencil Comparison", Float ) = 8 // always
        _Stencil( "Stencil ID", Float ) = 0
        _StencilWriteMask( "Stencil Write Mask", Float ) = 255
        _StencilReadMask( "Stencil Read Mask", Float ) = 255
        [Enum( UnityEngine.Rendering.StencilOp )]
        _StencilPass( "Stencil Pass", Float ) = 0 // keep
        [Enum( UnityEngine.Rendering.StencilOp )]
        _StencilFail( "Stencil Fail", Float ) = 0 // keep
        [Enum( UnityEngine.Rendering.StencilOp )]
        _StencilZFail( "Stencil ZFail", Float ) = 0 // keep
        // #endregion StencilSettings

        // #region Misc
        [Enum( UnityEngine.Rendering.CullMode )]
        _CullMode( "Cull Mode", Float ) = 2
        [Toggle] _AlphaPremultiply( "Premultiply Alpha", Float ) = 0
        _Fog_DensityBalance( "Fog Density Balance", Range( -1, 1 ) ) = 0
        // #endregion Misc

        // #region Eval Logic
        _ValueA( "Value A", Float ) = 0
        _ValueB( "Value B", Float ) = 0
        _ValueC( "Value C", Range( 0, 1 ) ) = 0
        // #endregion Eval Logic

        // #region Effect
        [HideInInspector] _RimLightColor( "Rim Light Color", Color ) = ( 0, 0, 0, 0 )
        [HideInInspector] _RimLightPower( "Rim Light Power", Range( 1, 8 ) ) = 4
        [HideInInspector] _RimLightScale( "Rim Light Scale", Range( -2, 2 ) ) = 1
        // #endregion Effect

    }

    /*
    #BEGINEDITOR
    [
        [ "Textures" ],
        { "editor" : "SingleProp", "args" : { "name" : "_MainTex" } },
        { "editor" : "GetTextureFormat", "id" : "_MainTex_Format", "args" : { "name" : "_MainTex" } },
        { "editor" : "GetTextureAssetPath", "id" : "_MainTex_AssetPath", "args" : { "name" : "_MainTex" } },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "none",
                "params" : [ "_MainTex_Format", "_MainTex_AssetPath" ],
                "text" :
"
当前MainTex贴图信息：
格式：<color=green><b>{0}</b></color>
路径：<b>{1}</b>
"
            }
        },

        { "editor" : "SingleProp", "args" : { "name" : "_MainTex_Alpha", "mode" : "Transparent | Cutout" } },
        { "editor" : "GetTextureFormat", "id" : "_MainTex_Alpha_Format", "args" : { "name" : "_MainTex_Alpha" } },
        { "editor" : "GetTextureAssetPath", "id" : "_MainTex_Alpha_AssetPath", "args" : { "name" : "_MainTex_Alpha" } },
        { "editor" : "UpdateKeyword", "id" : "_USE_EXTERNAL_ALPHA", "args" : { "name" : "_MainTex_Alpha", "mode" : "Transparent | Cutout", "keyword" : "_USE_EXTERNAL_ALPHA" } },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "none",
                "if" : "[_USE_EXTERNAL_ALPHA]",
                "mode" : "Cutout | Transparent",
                "params" : [ "_MainTex_Alpha_Format", "_MainTex_Alpha_AssetPath" ],
                "text" :
"
当前_MainTex_Alpha贴图信息：
格式：<color=green><b>{0}</b></color>
路径：<b>{1}</b>
"
            }
        },

        [ "Colors" ],
        { "editor" : "SingleProp", "args" : { "name" : "_Color" } },
        { "editor" : "SingleProp", "args" : { "name" : "_DoubleColorTint" } },
        { "editor" : "HelpBox", "args" : { "type" : "info", "if" : "[_DoubleColorTint]", "text" : "双倍Color调色开启" } },

        { "editor" : "SingleProp", "args" : { "name" : "_Cutoff", "mode" : "Cutout", "precision" : 64 } },
        { "editor" : "UpdateKeyword", "id" : "_ALPHATEST_ON", "args" : { "name" : "_Cutoff", "mode" : "Cutout", "op" : ">", "ref" : 0, "keyword" : "_ALPHATEST_ON" } },
        { "editor" : "SingleProp", "args" : { "name" : "_ColorKey", "mode" : "ColorKey" } },
        { "editor" : "SingleProp", "args" : { "name" : "_VertexColorTint" } },
        { "editor" : "UpdateKeyword", "id" : "_VERTEXCOLORTINT_OFF", "args" : { "name" : "_VertexColorTint", "op" : "==", "ref" : 0, "keyword" : "_VERTEXCOLORTINT_OFF" } },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "info",
                "if" : "[_VertexColorTint]",
                "text" : "开启并使用顶点颜色控制漫反射颜色（Albedo），可实现顶点Alpha的透明度控制"
            }
        },
        
        [ "Misc" ],
        { "editor" : "CullMode", "args" : { "name" : "_CullMode", } },
        { "editor" : "RenderMode_Bloom" },
        { "editor" : "StencilSettings", "args" : { "name" : "StencilSettings" } },
        { "editor" : "SingleProp", "args" : { "name" : "_Fog_DensityBalance", "precision" : "low", "map_range" : [-100, 100] } },
        { "editor" : "UpdateKeyword", "id" : "_FOG_DENSITY_BALANCE_ON", "args" : { "name" : "_Fog_DensityBalance", "op" : "!=", "ref" : 0, "keyword" : "_FOG_DENSITY_BALANCE_ON" } },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "info",
                "if" : "[_FOG_DENSITY_BALANCE_ON]",
                "text" :
"
Fog Density Balance 雾效浓度平衡调节：[-1, 1]
< 0, 雾效果减淡
= 0, 关闭浓度调节（默认）
> 0, 雾效浓度加强
"
            }
        },

        [ "Eval Logic" ],
        { "editor" : "SingleProp", "args" : { "name" : "_ValueA", } },
        { "editor" : "SingleProp", "args" : { "name" : "_ValueB", } },
		{ "editor" : "SingleProp", "args" : { "name" : "_ValueC", "map_range" : [ -180, 180 ], "grade" : 360 } },
        { "editor" : "SingleProp", "id" : "_Color_A", "args" : { "label" : "Color Alpha", "name" : "_Color", "gui" : "color_a", "range" : [ 0, 10 ], "grade" : 128 } },
        
        { "editor" : "Eval", "id" : "_HAS_A_", "args" : { "name" : "_ValueA", "op" : ">", "ref" : 0 } },
        { "editor" : "Eval", "id" : "_HAS_B_", "args" : { "name" : "_ValueB", "op" : ">", "ref" : 0 } },
        { "editor" : "Logic", "id" : "_A_OR_B", "args" : {  "op" : "||", "arg0" : "[_HAS_A_]", "arg1" : "[_HAS_B_]" } },
        { "editor" : "Logic", "id" : "_A_AND_B", "args" : {  "op" : "&&", "arg0" : "[_HAS_A_]", "arg1" : "[_HAS_B_]" } },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "none",
                "if" : "[_A_OR_B]",
                "text" : "( A > 0 || B > 0 ) == true"
            }
        },
        {
            "editor" : "HelpBox",
            "args" : {
                "type" : "none",
                "if" : "[_A_AND_B]",
                "text" : "( A > 0 && B > 0 ) == true"
            }
        },

        [ "Effect" ],
        { "editor" : "SingleProp", "args" : { "name" : "_RimLightColor" } },
        { "editor" : "SingleProp", "args" : { "name" : "_RimLightPower", "if" : "[UseRimLight]" } },
        { "editor" : "SingleProp", "args" : { "name" : "_RimLightScale", "if" : "[UseRimLight]", "range" : [-4,4] } },
        { "editor" : "UpdateKeyword", "id" : "UseRimLight", "args" : { "keyword" : "_RIMLIGHT_ON", "name" : "_RimLightColor", "op" : "!=", "ref" : [0,0,0] } },

        [ "Shader Feature List" ],
        {
            "editor" : "Initializer",
            "args" : {
                "shader_feature_list" : [
                    "_ALPHABLEND_ON",
                    "_ALPHATEST_ON",
                    "_ALPHATEST_COLOR_KEY_ON",
                    "_ALPHAPREMULTIPLY_ON",
                    "_DOUBLECOLORTINT_ON",
                    "_VERTEXCOLORTINT_OFF",
                    "_FOG_DENSITY_BALANCE_ON",
                    "_RIMLIGHT_ON",
                    "_USE_EXTERNAL_ALPHA"
                ],
            }
        },

        [ "Generic" ],
        { "editor" : "SourceHelper" },
        {
            "editor" : "CustomTag",
            "args" : {
                "tags" : [
                    { "type" : "PreviewType", "values" : [ "Mesh", "Plane", "Skybox" ] },
                    { "type" : "CastShadow", "values" : [ "No", "Yes" ] },
                    { "type" : "Usage", "values" : [ "None", "Role" ] },
                    { "type" : "ShadowCaster", "values" : [ "No", "Yes" ], "upgrade_to" : "CastShadow" },
                    { "type" : "ShaderSet", "values" : [ "None", "Role" ], "upgrade_to" : "Usage" },
                ],
            }
        },
    ]
    #ENDEDITOR
    */

    CustomEditor "UME.UnitMaterialEditor"

    SubShader {
        Pass {
            Name "MASTER" 
            Tags { "LightMode" = "ForwardBase" }
            Blend [_SrcBlend][_DstBlend], [_SrcAlphaBlend][_DstAlphaBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_CullMode]
            BlendOp [_BlendOp]
            Stencil
            {
                Comp [_StencilComp]
                Ref [_Stencil]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Pass [_StencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma shader_feature _ALPHATEST_ON _ALPHATEST_COLOR_KEY_ON
            #pragma shader_feature _USE_EXTERNAL_ALPHA
            #pragma shader_feature _DOUBLECOLORTINT_ON
            #pragma shader_feature _VERTEXCOLORTINT_OFF

            // 雾效平衡功能
            #pragma shader_feature _FOG_DENSITY_BALANCE_ON

            // 边缘光开关
            #pragma shader_feature _RIMLIGHT_ON

            // 多pass模式下可以选择使用不同的颜色属性
            #define _CURRENT_COLOR_INDEX 1
            #include "__main.cginc"
            ENDCG
        }
    }
}

