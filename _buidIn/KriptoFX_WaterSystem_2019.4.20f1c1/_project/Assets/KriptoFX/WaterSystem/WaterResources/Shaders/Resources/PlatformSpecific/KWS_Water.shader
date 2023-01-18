Shader "KriptoFX/KWS/Water"
{
    Properties
    {
        srpBatcherFix ("srpBatcherFix", Float) = 0
    }

    SubShader
    {

        Tags { "Queue" = "Transparent-1" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "true" }
        
        Blend SrcAlpha OneMinusSrcAlpha

        Stencil
        {
            Ref 230
            Comp Greater
            Pass keep
        }
        Pass
        {
            ZWrite On

            Cull Back
            CGPROGRAM

            #include "../Common/KWS_WaterVariables.cginc"
            #include "KWS_PlatformSpecificHelpers.cginc"
            #include "../Common/KWS_WaterPassHelpers.cginc"
            #include "../Common/KWS_CommonHelpers.cginc"
            #include "../Common/Shoreline/KWS_Shoreline_Common.cginc"
            #include "../Common/KWS_WaterHelpers.cginc"
            #include "../Common/KWS_WaterVertPass.cginc"
            #include "../Common/KWS_WaterFragPass.cginc"
            #include "../Common/KWS_Tessellation.cginc"


            #pragma shader_feature  KW_FLOW_MAP_EDIT_MODE
            #pragma multi_compile _ KW_FLOW_MAP KW_FLOW_MAP_FLUIDS
            #pragma multi_compile _ KW_DYNAMIC_WAVES
            #pragma multi_compile _ USE_MULTIPLE_SIMULATIONS
            #pragma multi_compile _ PLANAR_REFLECTION SSPR_REFLECTION
            #pragma multi_compile _ USE_REFRACTION_IOR
            #pragma multi_compile _ USE_REFRACTION_DISPERSION
            #pragma multi_compile _ USE_SHORELINE
            #pragma multi_compile _ REFLECT_SUN
            #pragma multi_compile _ USE_VOLUMETRIC_LIGHT
            #pragma multi_compile _ USE_FILTERING
            #pragma multi_compile_fog

            #pragma vertex vert
            #pragma fragment frag

            ENDCG
        }
    }
}
