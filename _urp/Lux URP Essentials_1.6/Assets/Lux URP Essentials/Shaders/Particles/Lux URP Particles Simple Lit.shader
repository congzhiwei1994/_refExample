Shader "Lux URP/Particles/Simple Lit"
{
// ------------------------------------------
// All lights are supported for lit particles
// Per pixel or per vertex shadows

    Properties
    {
        [HeaderHelpLuxURP_URL(hgrc26wf1x5s)]
        
        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest                                  ("ZTest", Float) = 4 // "LessEqual"
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                                   ("Cull", Float) = 2.0
        [HideInInspector]
        [Enum(Off,0,On,1)]_ZWrite               ("ZWrite", Float) = 0.0
        
        [Space(5)]
        [Enum(Alpha,0,Premultiply,1,Additive,2,Multiply,3)]
        _Blend                                  ("Blending Mode", Float) = 0
        [Enum(Multiply,0,Additive,1,Subtractive,2,Overlay,3,Color,4,Difference,5)]
        _ColorMode                              ("Color Mode", Float) = 0.0

        [Space(5)]
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows                         ("Receive Shadows", Float) = 0.0
        [Toggle(_ADDITIONALLIGHT_SHADOWS)]
        _AdditionalLightShadows                 ("Additional Light Shadows", Float) = 1.0
        [Toggle(_PERVERTEX_SHADOWS)]
        _PerVertexShadows                       ("     Per Vertex Shadows", Float) = 0.0
        _SampleOffset                           ("     Sample Offset", Range(0, 2)) = 0.1


        [Header(Surface Inputs)]
        [Space(8)]
        _BaseColor                              ("Base Color", Color) = (1,1,1,1)
        _BaseMap                                ("Base Map", 2D) = "white" {}

        [Space(5)]
        [ToggleOff] _SpecularHighlights         ("Specular Highlights", Float) = 1.0
        [Toggle]
        _EnableSpecGloss                        ("     Enable Spec Gloss Map", Float) = 0.0
        [NoScaleOffset] _SpecGlossMap           ("          Spec Gloss Map", 2D) = "white" {}
        _SpecColor                              ("          Specular (RGB) Smoothness(A)", Color) = (1.0, 1.0, 1.0, .5)
        //_Smoothness                           ("    Smoothness", Range(0.0, 1.0)) = 0.5

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                            ("Enable Normal Map", Float) = 0.0
        [NoScaleOffset] _BumpMap                ("     Normal Map", 2D) = "bump" {}
        //_BumpScale                            ("     Scale", Float) = 1.0

        [Space(5)]
        [Toggle(_EMISSION)]
        _EnableEmission                         ("Enable Emission", Float) = 0.0
        [NoScaleOffset] _EmissionMap            ("     Emission Map", 2D) = "white" {}
        [HDR]_EmissionColor                     ("     Color", Color) = (1,1,1)

        [Space(5)]
        [Toggle(_TRANSMISSION)]
        _EnableTransmission                     ("Enable Transmission", Float) = 0.0
        _Transmission                           ("     Transmission", Range(0.0, 1.0)) = 0.5
        _TransmissionDistortion                 ("     Distortion", Range(0.01, 0.5)) = 0.01

        
        // Hidden properties - Generic
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0

        
        // Particle specific
        [Header(Particle Options)]
        [Space(8)] 
        [Toggle(_FLIPBOOKBLENDING_ON)]
        _FlipbookBlending                       ("Enable Flipbook Blending", Float) = 0.0

        [Space(5)]      
        [Toggle(_DISTORTION_ON)]
        _DistortionEnabled                      ("Enable Distortion", Float) = 0.0
        _DistortionStrength                     ("     Strength", Float) = 1.0
        _DistortionBlend                        ("     Blend", Range(0.0, 1.0)) = 0.5
        [HideInInspector]
        _DistortionStrengthScaled               ("     Distortion Strength Scaled", Float) = 0.1

        [Space(5)] 
        [Toggle(_SOFTPARTICLES_ON)]
        _SoftParticlesEnabled                   ("Enable Soft Particles", Float) = 0.0
        [LuxURPVectorTwoDrawer]
        _SoftParticleFadeParams                 ("     Near (X) Far (Y)", Vector) = (0,1,0,0)
        
        [Space(5)] 
        [Toggle(_FADING_ON)]
        _CameraFadingEnabled                    ("Enable Camera Fading", Float) = 0.0
        [LuxURPVectorTwoDrawer]
        _CameraFadeParamsRaw                    ("     Near (X) Far (Y)", Vector) = (1,2,0,0)
        [HideInInspector]_CameraFadeParams      ("     Near (X) Far (Y)", Vector) = (1,1,0,0)
        

        // Hidden props
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)]  _SrcBlend("__src", Float) = 1.0
        [HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)]  _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _BaseColorAddSubDiff  ("_ColorMode", Vector) = (0,0,0,0)
        
        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        
        // ObsoleteProperties
        [HideInInspector] _FlipbookMode("flipbook", Float) = 0
        [HideInInspector] _Glossiness("gloss", Float) = 0
        [HideInInspector] _Mode("mode", Float) = 0
        [HideInInspector] _Color("color", Color) = (1,1,1,1)

    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _MainTex  ("Albedo", 2D) = "white" {}
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
        [HideInInspector] _Cutoff   ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
            "PerformanceChecks" = "False"
            "RenderPipeline" = "UniversalPipeline"
        }

        // ------------------------------------------------------------------
        //  Forward pass.
        Pass
        {
            // Lightmode matches the ShaderPassName set in LightweightRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Lightweight Render Pipeline
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}
            
            BlendOp[_BlendOp]
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION

            //#pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF _SPECGLOSSMAP _SPECULAR_COLOR

            // _RECEIVE_SHADOWS_OFF drives AdditionalLightRealtimeShadow() in shadows.hlsl. Without it being set no sampling will happen
            // shadows.hlsl differs in LWRP and URP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _PERVERTEX_SHADOWS
            #pragma shader_feature_local _PERVERTEX_SAMPLEOFFSET
            #pragma shader_feature_local _ADDITIONALLIGHT_SHADOWS

            #pragma shader_feature_local_fragment _TRANSMISSION

            // -------------------------------------
            // Particle Keywords
            #pragma shader_feature _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON _ADDITIVE
            //#pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ _COLOROVERLAY_ON _COLORCOLOR_ON _COLORADDSUBDIFF_ON
            #pragma shader_feature _FLIPBOOKBLENDING_ON
            #pragma shader_feature _SOFTPARTICLES_ON
            #pragma shader_feature _FADING_ON
            #pragma shader_feature _DISTORTION_ON
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #if defined(_SHADOWS_SOFT) && defined(_PERVERTEX_SHADOWS)
                #undef _SHADOWS_SOFT
            #endif

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON // needs shader target 4.5

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            
            #pragma vertex ParticlesLitVertex
            #pragma fragment ParticlesLitFragment
            
            #define BUMP_SCALE_NOT_SUPPORTED 1
            
            #include "Includes/Lux URP Particles Simple Lit Inputs.hlsl"
            #include "Includes/Lux URP Particles Simple Lit Forward Pass.hlsl"
            ENDHLSL
        }
    }

    Fallback "Lightweight Render Pipeline/Particles/Unlit"
    CustomEditor "LuxURPParticlesCustomShaderGUI"
}