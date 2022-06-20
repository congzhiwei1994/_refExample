Shader "Custom/Demo-AlphaBlend-DoubleSide" {

    Properties {
        // #define BASE = Custom/Demo

        // #region Textures
        // #include $(BASE) : Textures
        _MainTex( "Main Texture", 2D ) = "white" {}
        [NoScaleOffset] _MainTex_Alpha( "Base Alpha (R)", 2D ) = "white" {}
        // #endregion Textures

        // #region Colors
        _Color2( "Backface Color", Color ) = ( 1, 1, 1, 1 )
        _Color( "Color", Color ) = ( 1, 1, 1, 1 )
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
        _CullMode( "Cull Mode", Float ) = 2
        [Enum( UnityEngine.Rendering.CullMode )]
        _Backface_CullMode( "Backface Cull Mode", Float ) = 1
        [Toggle] _AlphaPremultiply( "Premultiply Alpha", Float ) = 0
        _Fog_DensityBalance( "Fog Density Balance", Range( -1, 1 ) ) = 0
        // #endregion Misc

        // #region Effect
        // #include $(BASE) : Effect
        [HideInInspector] _RimLightColor( "Rim Light Color", Color ) = ( 0, 0, 0, 0 )
        [HideInInspector] _RimLightPower( "Rim Light Power", Range( 1, 8 ) ) = 4
        [HideInInspector] _RimLightScale( "Rim Light Scale", Range( -2, 2 ) ) = 1
        // #endregion Effect

        //// AUTO GENERATED. DO NOT MODIFY!
        //// DEPENDENCIES:
        //// Assets/Editor/Demo/Demo-AlphaBlend-DoubleSide.shader
        //// Assets/Editor/Demo/Demo.shader
        //// END DEPENDENCIES

    }

    /*
    #BEGINEDITOR
    [
        [ { "#define" : "BASE = Custom/Demo" } ],
        [ { "#define" : "BACK = Custom/Internal/Demo-Backface" } ],

        [ { "#include" : "$(BASE) : Textures" } ],

        [ "Colors" ],
        { "editor" : "SingleProp", "args" : { "name" : "_Color2", "label" : "Backface Color" } },
        [ { "#include" : "$(BASE) : Colors" } ],

        [ "Misc" ],
        { "editor" : "CullMode", "args" : { "name" : "_Backface_CullMode", "invert" : "_CullMode" } },
        [ { "#include" : "$(BASE) : Misc" } ],
        { "editor" : "CullMode", "args" : { "name" : "_CullMode" } },
        { "editor" : "RenderMode_Bloom", "args" : { "options" : "Transparent", "keep" : "Transparent" } },

        [ { "#include" : "$(BASE) : Effect" } ],
        [ { "#include" : "$(BASE) : Shader Feature List" } ],
        [ { "#include" : "$(BACK) : Shader Feature List" } ],
        [ { "#include" : "$(BASE) : Generic" } ],

    ]
    #ENDEDITOR
    */

    CustomEditor "UME.UnitMaterialEditor"

    SubShader {
        UsePass "Custom/Internal/Demo-Backface/MASTER-BACKFACE"
        UsePass "Custom/Demo/MASTER"
    }
}

