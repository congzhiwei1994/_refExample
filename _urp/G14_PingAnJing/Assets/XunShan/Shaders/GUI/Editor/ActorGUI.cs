using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;


namespace ShaderEditor
{
    public static class ActorGUI
    {
        /// <summary>
        /// 自定义接口
        /// </summary>
        public interface CustomInterface
        {
            void OnSelectMaterialType(MaterialType type);
        }

        /// <summary>
        /// 材质类型
        /// </summary>
        public enum MaterialType
        {
            [InspectorName("请选择类型")]
            Unselect = 0,
            [InspectorName("通用混合类型")]
            Universal,
            [InspectorName("眼睛")]
            Eye
        }

        public enum AnisoType
        {
            [InspectorName("不使用")]
            NotUse,
            [InspectorName("使用")]
            Use,
        }

        public enum SSSType
        {
            [InspectorName("不使用")]
            NotUse,
            [InspectorName("使用")]
            Use,
        }

        public static class Keywords
        {
            public const string _G_DEBUG_ACTOR_ON = "_G_DEBUG_ACTOR_ON";

            public const string _L_ANISO_ON = "_L_ANISO_ON";
            public const string _L_SSS_ON = "_L_SSS_ON";
        }

        public static class PropName
        {
            /// <summary>
            /// 调试类型
            /// uint 类型
            /// </summary>
            public const string _G_DebugActorMode = "_G_DebugActorMode";

            /// <summary>
            /// 各向异性类型
            /// 示例:
            /// [HideInInspector] _INTR_AnisoType("", Int) = 0
            /// 
            /// 配套Properties：
            /// _AnisoShiftOffset("Aniso Shift Offset", Float) = 0.0
            /// _AnisoShiftScale("Aniso Shift Scale", Float) = 0.5
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local __ _L_ANISO_ON
            /// </summary>
            public const string _INTR_AnisoType = "_INTR_AnisoType";

            /// <summary>
            /// SSS类型
            /// 示例:
            /// [HideInInspector] _INTR_SSSType("", Int) = 0
            /// 
            /// 配套Properties：
            /// _SSS_Factor("SSS Factor", Range(0,1)) = 1
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local __ _L_SSS_ON
            /// </summary>
            public const string _INTR_SSSType = "_INTR_SSSType";

            public const string _AnisotropicMap = "_AnisotropicMap";
            public const string _AnisoShiftOffset = "_AnisoShiftOffset";
            public const string _AnisoShiftScale = "_AnisoShiftScale";

            public const string _SSS_Factor = "_SSS_Factor";

            public const string _EnvShadowColor = "_EnvShadowColor";
            public const string _EnvBrightness = "_EnvBrightness";
            
        }

        public static class Styles
        {
            public static GUIContent MaterialTypeText =
                new GUIContent("材质推荐设置", "");

            public static GUIContent AnisoTypeText =
               new GUIContent("各向异性材质", "");

            public static GUIContent AnisotropicMapText =
               new GUIContent("各向异性贴图", "");

            public static GUIContent AnisoShiftOffsetText =
              new GUIContent("各向异性切线偏移", "");

            public static GUIContent AnisoShiftScaleText =
             new GUIContent("各向异性切线缩放", "");

            public static GUIContent SSSTypeText =
                new GUIContent("SSS材质", "");

            public static readonly GUIContent SSS_FactorText =
                new GUIContent("SSS强度调整",
                "");

            public static readonly GUIContent EnvShadowColorText =
                new GUIContent("环境光照阴影颜色",
                "");
            public static readonly GUIContent EnvBrightnessText =
                new GUIContent("环境光照强度调整",
                "一般不用调整，默认为1");
        }

        public struct Properties : IProperties
        {
            public MaterialProperty _INTR_AnisoType;
            public MaterialProperty _INTR_SSSType;

            public MaterialProperty _AnisotropicMap;
            public MaterialProperty _AnisoNormalOffset;
            public MaterialProperty _AnisoNoiseOffset;
            public MaterialProperty _SSS_Factor;
            public MaterialProperty _EnvShadowColor;
            public MaterialProperty _EnvBrightness;


            public Properties(MaterialProperty[] properties)
            {
                _INTR_AnisoType = BaseShaderGUI.FindProperty(PropName._INTR_AnisoType, properties, false);
                _INTR_SSSType = BaseShaderGUI.FindProperty(PropName._INTR_SSSType, properties, false);

                _AnisotropicMap = BaseShaderGUI.FindProperty(PropName._AnisotropicMap, properties, false);
                _AnisoNormalOffset = BaseShaderGUI.FindProperty(PropName._AnisoShiftOffset, properties, false);
                _AnisoNoiseOffset = BaseShaderGUI.FindProperty(PropName._AnisoShiftScale, properties, false);
                _SSS_Factor = BaseShaderGUI.FindProperty(PropName._SSS_Factor, properties, false);
                _EnvShadowColor = BaseShaderGUI.FindProperty(PropName._EnvShadowColor, properties, false);
                _EnvBrightness = BaseShaderGUI.FindProperty(PropName._EnvBrightness, properties, false);
            }
        }

        /// <summary>
        /// Actor选项
        /// </summary>
        /// <param name="material"></param>
        public static void DrawActorOptions(Properties properties, MaterialEditor materialEditor, Material material, CustomInterface customInterface)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            var select = (MaterialType)EditorGUILayout.EnumPopup(Styles.MaterialTypeText, MaterialType.Unselect);
            if(select != MaterialType.Unselect)
            {
                if(customInterface != null)
                {
                    customInterface.OnSelectMaterialType(select);
                }
            }
        }

        public static void DrawInputs(BaseShaderGUI shaderGUI, Properties properties, Material material)
        {
            DoAnisotropicArea(shaderGUI, properties, material);
            DoSSSArea(shaderGUI, properties, material);
            DoEnvArea(shaderGUI, properties, material);
        }

        private static void DoAnisotropicArea(BaseShaderGUI shaderGUI, Properties properties, Material material)
        {
            if (properties._INTR_AnisoType == null)
            {
                return;
            }
            BaseShaderGUI.DoEnumPopup<AnisoType>(Styles.AnisoTypeText, properties._INTR_AnisoType, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<AnisoType>(material, PropName._INTR_AnisoType, AnisoType.NotUse);
            if (type == AnisoType.NotUse)
            {
                return;
            }

            if (properties._AnisotropicMap != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.AnisotropicMapText, properties._AnisotropicMap);

                shaderGUI.DrawTextureInfo(properties._AnisotropicMap.textureValue);
            }
            if (properties._AnisoNormalOffset != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._AnisoNormalOffset, Styles.AnisoShiftOffsetText);
            }
            if (properties._AnisoNoiseOffset != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._AnisoNoiseOffset, Styles.AnisoShiftScaleText);
            }
        }

        private static void DoSSSArea(BaseShaderGUI shaderGUI, Properties properties, Material material)
        {
            if(properties._INTR_SSSType == null)
            {
                return;
            }
            BaseShaderGUI.DoEnumPopup<SSSType>(Styles.SSSTypeText, properties._INTR_SSSType, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<SSSType>(material, PropName._INTR_SSSType, SSSType.NotUse);
            if(type == SSSType.NotUse)
            {
                return;
            }
            if (properties._SSS_Factor != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._SSS_Factor, Styles.SSS_FactorText);
            }
        }

        private static void DoEnvArea(BaseShaderGUI shaderGUI, Properties properties, Material material)
        {
            if (properties._EnvShadowColor != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._EnvShadowColor, Styles.EnvShadowColorText);
            }
            if (properties._EnvBrightness != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._EnvBrightness, Styles.EnvBrightnessText);
            }
        }



        public static void SetMaterialKeywords(Material material)
        {
            // Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
            // (MaterialProperty value might come from renderer material property block)
  
            // 开启Aniso
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_ANISO_ON, false);

                if (material.HasProperty(PropName._INTR_AnisoType))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum<AnisoType>(material, PropName._INTR_AnisoType, AnisoType.NotUse);
                    if (type == AnisoType.Use)
                    {
                        CoreUtils.SetKeyword(material, Keywords._L_ANISO_ON, true);
                    }
                }
            }

            // 开启SSS
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_SSS_ON, false);

                if (material.HasProperty(PropName._INTR_SSSType))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum<SSSType>(material, PropName._INTR_SSSType, SSSType.NotUse);
                    if (type == SSSType.Use)
                    {
                        CoreUtils.SetKeyword(material, Keywords._L_SSS_ON, true);
                    }
                }
            }
            
        }
    }
}