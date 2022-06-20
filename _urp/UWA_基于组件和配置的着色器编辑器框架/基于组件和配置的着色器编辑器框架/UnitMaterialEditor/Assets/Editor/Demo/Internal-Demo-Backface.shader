Shader "Custom/Internal/Demo-Backface" {

    Properties {
        // #define BASE = Custom/Demo

        // #region Textures
        // #include $(BASE) : Textures
        _MainTex( "Main Texture", 2D ) = "white" {}
        [NoScaleOffset] _MainTex_Alpha( "Base Alpha (R)", 2D ) = "white" {}
        // #endregion Textures

        // #region Colors
        _Color2( "Backface Color", Color ) = ( 1, 1, 1, 1 )
        _Cutoff( "Alpha Cutoff", Range( 0, 1 ) ) = 0
        _ColorKey( "Color Key (RGB) Epsilon (A)", Color ) = ( 1.0, 0, 1.0, 0.004 )
        [Toggle] _DoubleColorTint( "Double Color Tint", Float ) = 0.0
        [ToggleOff] _VertexColorTint( "Vertex Color Tint", Float ) = 0.0
        // #endregion Colors

        // #region RenderMode
        // #include $(BASE) : RenderMode
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
        // #include $(BASE) : StencilSettings
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
        _Backface_CullMode( "Backface Cull Mode", Float ) = 1
        [Toggle] _AlphaPremultiply( "Premultiply Alpha", Float ) = 0
        _Fog_DensityBalance( "Fog Density Balance", Range( -1, 1 ) ) = 0
        // #endregion Misc

        // #region Effect
        // #include $(BASE) : Effect
        [HideInInspector] _RimLightColor( "Rim Light Color", Color ) = ( 0, 0, 0, 0 )
        [HideInInspector] _RimLightPower( "Rim Light Power", Range( 1, 8 ) ) = 4
        // #endregion Effect

        //// AUTO GENERATED. DO NOT MODIFY!
        //// DEPENDENCIES:
        //// Assets/Editor/Demo/Internal-Demo-Backface.shader
        //// Assets/Editor/Demo/Demo.shader
        //// END DEPENDENCIES

    }

    /*
    #BEGINEDITOR
    [
        [ { "#define" : "BASE = Custom/Demo" } ],

        [ { "#include" : "$(BASE) : Textures" } ],

        [ "Colors" ],
        { "editor" : "SingleProp", "args" : { "name" : "_Color2", "label" : "Backface Color" } },
        [ { "#include" : "$(BASE) : Colors" } ],
        [ { "#delete" : [ [ "_Color", "" ] ] } ],

        [ "Misc" ],
        { "editor" : "CullMode", "args" : { "name" : "_Backface_CullMode", "keep" : "front" } },
        [ { "#include" : "$(BASE) : Misc" } ],
        [ { "#delete" : [ [ "_CullMode", "" ] ] } ],

        [ { "#include" : "$(BASE) : Effect" } ],
        [ { "#include" : "$(BASE) : Shader Feature List" } ],
        [ { "#include" : "$(BASE) : Generic" } ],

    ]
    #ENDEDITOR
    */

    CustomEditor "UME.UnitMaterialEditor"

    SubShader {
        Pass {
            Name "MASTER-BACKFACE" 
            Tags { "LightMode" = "ForwardBase" }
            Blend [_SrcBlend][_DstBlend], [_SrcAlphaBlend][_DstAlphaBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_Backface_CullMode]
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

            // 背面模式选择另外一个颜色值属性
            #define _CURRENT_COLOR_INDEX 2
            // 开启背面渲染用于反向法线
            #define _BACKFACE_RENDERING_ON
            #include "__main.cginc"
            ENDCG
        }
    }
}

