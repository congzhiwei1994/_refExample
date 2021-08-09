using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace ShaderEditor
{
    [System.Serializable]
    public sealed class DebugActor : DebugData<DebugActor>
    {
        public enum Mode
        {
            [InspectorName("正常")]
            None = 0,

            [InspectorName("Albedo 固有色")]
            Albedo,

            [InspectorName("Metallic 金属度")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Metallic,

            [InspectorName("Roughness 粗糙度")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Roughness,

            [InspectorName("AO")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            AO,

            [InspectorName("Subsurface 次表面")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Subsurface,

            [InspectorName("Anisotropy 各向异性")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Anisotropy,

            [InspectorName("Emissive 自发光")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Emissive,

            [InspectorName("各向异性切线图")]
            AnisoTangent,

            [InspectorName("各向异性抖动图")]
            AnisoShift,

            [InspectorName("法线贴图")]
            NormalMap,

            [InspectorName("模型法线(世界空间)")]
            ModelNormalWorld,

            [InspectorName("最终法线(世界空间)")]
            NormalWorld,

            [InspectorName("直接额外光源结果")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            AdditionalLights,

            [InspectorName("IBL-Diffuse 环境漫反射BakedGI(间接光)")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            BakedGI,

            [InspectorName("IBL-Specular 环境高光反射(间接光)")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            IBL_Specular,

            [InspectorName("直接直射光照结果")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            DirectDirectional,

            [InspectorName("间接直射光照结果(GI)")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            GI,

            [InspectorName("BRDF 双向反射分布")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            BRDF,

            [InspectorName("EnvBRDF 环境双向反射分布")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            EnvBRDF,

            [InspectorName("Radiance 直射光辐射率(直接光)")]
            [Tooltip("按空格键(默认)可以显示对应热力值")]
            Radiance,

            [InspectorName("检查PBR Diffuse合法范围")]
            [Tooltip("红色区域表示超过参考值，蓝色区域表示低于参考值")]
            PBR_DiffuseValidate,

            [InspectorName("检查PBR Specular合法范围")]
            [Tooltip("红色区域表示超过参考值，蓝色区域表示低于参考值")]
            PBR_SpecularValidate,

            [InspectorName("HDR亮度热力图")]
            [Tooltip("越红表示越接近峰值")]
            HDR_Heatmap,
        }

        [SerializeField]
        private Mode s_CurrentMode;
        public static Mode CurrentMode
        {
            get { return get.s_CurrentMode; }
            set
            {
                get.s_CurrentMode = value;
            }
        }
    }
}