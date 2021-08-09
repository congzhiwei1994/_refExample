using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;


namespace ShaderEditor
{
    public static class PBRGUI
    {
        /// <summary>
        /// 自定义接口
        /// </summary>
        public interface CustomInterface
        {
            GUIContent GetMixMapText();
            GUIContent GetNormalMapText();
            GUIContent GetAOBiasTipText();
            GUIContent GetEmissiveTipText(EmissiveType type);
        }

        /// <summary>
        /// 法线贴图类型
        /// </summary>
        public enum NormalMapType
        {
            /// <summary>
            /// 不使用法线贴图
            /// </summary>
            [InspectorName("不使用")]
            NotUse = 0,
            /// <summary>
            /// 正常使用法线贴图
            /// </summary>
            [InspectorName("使用RGB通道")]
            UseRGB,
            /// <summary>
            /// RG通道
            /// </summary>
            [InspectorName("使用RG通道")]
            UseRG,
        }

        /// <summary>
        /// 粗糙度范围限制
        /// </summary>
        public enum RoughnessRange
        {
            /// <summary>
            /// 不使用
            /// </summary>
            [InspectorName("不使用")]
            NotUse = 0,
            /// <summary>
            /// 使用
            /// </summary>
            [InspectorName("使用")]
            Use,
        }

        /// <summary>
        /// 粗糙度来源
        /// </summary>
        public enum RoughnessSource
        {
            /// <summary>
            /// 来自MixMap的R通道
            /// </summary>
            [InspectorName("MixMap(R通道)")]
            MixMap_R,

            [InspectorName("法线(B通道)")]
            NormalMap_B,
        }

        public enum AOType
        {
            [InspectorName("不使用")]
            NotUse,
            [InspectorName("使用")]
            Use,
        }

        public enum EmissiveType
        {
            [InspectorName("不使用")]
            NotUse,
            [InspectorName("使用")]
            Use,
        }

        public enum IBLDiff
        {
            [InspectorName("URP全局参数")]
            GlobalURP,
            [InspectorName("指定 Sphere Map")]
            LocalSphereMap,
            [InspectorName("指定 Cube Map")]
            LocalCubeMap,
        }

        public enum IBLSpec
        {
            [InspectorName("URP全局参数")]
            GlobalURP,
            [InspectorName("指定 Sphere Map")]
            LocalSphereMap,
            [InspectorName("指定 Cube Map")]
            LocalCubeMap,
        }

        public static class Styles
        {
            public static readonly GUIContent MixMapText = new GUIContent("Mix Map",
                "混合贴图，不同材质每个通道表示意义可能不一样。");
            public static readonly GUIContent MixMapMipmapText = new GUIContent("建议Mix贴图不需要采用Mipmap增加材质表现准确度");

            public static readonly GUIContent RoughnessMinMaxText = new GUIContent("粗糙度范围",
                "可以使粗糙度的范围改变默认0-1。");
            public static readonly GUIContent RoughnessLowText = new GUIContent("粗糙度最小值",
               "粗糙度的最小值限制。");
            public static readonly GUIContent RoughnessHighText = new GUIContent("粗糙度最大值",
               "粗糙度的最大值限制。");

            public static readonly GUIContent NormalMapText =
               new GUIContent("法线贴图", "");
            public static readonly GUIContent NormalMapOptionsText =
               new GUIContent("法线贴图使用", "");

            public static readonly GUIContent AOSourceText =
              new GUIContent("AO来源", "");
            public static readonly GUIContent AOBiasText =
              new GUIContent("AO偏向", "");

            public static readonly GUIContent EmissiveSourceText =
              new GUIContent("自发光来源", "");
            public static readonly GUIContent EmissiveIntensityText =
              new GUIContent("自发光强度", "");

            public static readonly GUIContent RoughnessSourceText =
              new GUIContent("粗糙度来源", "");
            public static readonly GUIContent RoughnessRangeText =
             new GUIContent("粗糙度范围限制", "");

            public static readonly GUIContent IBLDiffText =
              new GUIContent("IBL-Diffuse来源", "");
            public static readonly GUIContent IBLDiffTip1Text =
            new GUIContent("与Renderer中'Light Probes'设置相关", "");
            public static readonly GUIContent IBLDiffTip2Text =
            new GUIContent("Baked Lighting + Environment Lighting", "");

            public static readonly GUIContent IBLSpecText =
             new GUIContent("IBL-Specular来源", "");
            public static readonly GUIContent IBLSpecTip1Text =
            new GUIContent("与Renderer中'Reflection Probes'设置相关", "");
            public static readonly GUIContent IBLSpecTip2Text =
            new GUIContent("默认优先级：Reflection Probe -> Environment Reflections", "");

            public static readonly GUIContent IrradianceMap2DText =
              new GUIContent("辐照度贴图(2D)", "");
            public static readonly GUIContent IrradianceMapCubeText =
             new GUIContent("辐照度贴图(Cube)", "");

            public static readonly GUIContent EnvironmentMap2DText =
              new GUIContent("光泽反射贴图(2D)", "");
            public static readonly GUIContent EnvironmentMapCubeText =
             new GUIContent("光泽反射贴图(Cube)", "");
        }

        public static class Keywords
        {
            /// <summary>
            /// 使用法线贴图开关
            /// 这里使用回URP的定义，因为我们有调用到URP里的函数，依赖这个Keyword
            /// </summary>
            public const string _NORMALMAP = "_NORMALMAP";

            /// <summary>
            /// 是否开启粗糙度范围调整
            /// </summary>
            public const string _L_ROUGHNESS_RANGE_ON = "_L_ROUGHNESS_RANGE_ON";

            /// <summary>
            /// 粗糙度来源
            /// </summary>
            public const string _L_ROUGH_SRC_MIX_R = "_L_ROUGH_SRC_MIX_R";
            public const string _L_ROUGH_SRC_NORMMAP_B = "_L_ROUGH_SRC_NORMMAP_B";

            /// <summary>
            /// 是否使用AO
            /// </summary>
            public const string _L_AO_ON = "_L_AO_ON";

            /// <summary>
            /// 是否使用BumpScale
            /// </summary>
            public const string _L_BUMP_SCALE_ON = "_L_BUMP_SCALE_ON";

            /// <summary>
            /// IBL-Diffuse类型
            /// </summary>
            public const string _L_IBL_DIFF_GLOBAL_URP = "_L_IBL_DIFF_GLOBAL_URP";
            public const string _L_IBL_DIFF_LOCAL_SPHERE_MAP = "_L_IBL_DIFF_LOCAL_SPHERE_MAP";
            public const string _L_IBL_DIFF_LOCAL_CUBE_MAP = "_L_IBL_DIFF_LOCAL_CUBE_MAP";

            /// <summary>
            /// IBL-Specular类型
            /// </summary>
            public const string _L_IBL_SPEC_GLOBAL_URP = "_L_IBL_SPEC_GLOBAL_URP";
            public const string _L_IBL_SPEC_LOCAL_SPHERE_MAP = "_L_IBL_SPEC_LOCAL_SPHERE_MAP";
            public const string _L_IBL_SPEC_LOCAL_CUBE_MAP = "_L_IBL_SPEC_LOCAL_CUBE_MAP";

            /// <summary>
            /// 自发光
            /// </summary>
            public const string _L_EMISSIVE_ON = "_L_EMISSIVE_ON";
        }

        public static class PropName
        {
            /// <summary>
            /// 法线贴图类型
            /// 示例:
            /// [HideInInspector] _INTR_NormalMapType("", Int) = 0
            /// </summary>
            public const string _INTR_NormalMapType = "_INTR_NormalMapType";

            /// <summary>
            /// 粗糙来源
            /// 示例:
            /// [HideInInspector] _INTR_RoughSrc("", Int) = 0
            /// </summary>
            public const string _INTR_RoughSrc = "_INTR_RoughSrc";

            /// <summary>
            /// 粗糙范围调整
            /// 示例：
            /// [HideInInspector] _INTR_RoughRange("", Int) = 0
            /// 
            /// 配套Properties：
            /// _RoughnessLow("RoughnessLow", Range(0,1)) = 0.0
            /// _RoughnessHigh("RoughnessHigh", Range(0,1)) = 1.0
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local __ _L_ROUGHNESS_RANGE_ON
            /// </summary>
            public const string _INTR_RoughRange = "_INTR_RoughRange";

            /// <summary>
            /// AO来源
            /// 示例:
            /// _AO_Bias("AO Bias", Range(0,1)) = 1
            /// [HideInInspector] _INTR_AO("", Int) = 0
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local __ _L_AO_ON
            /// </summary>
            public const string _INTR_AO = "_INTR_AO";

            /// <summary>
            /// 自发光类型
            /// 示例:
            /// _EmissiveIntensity("Emissive Intensity", Range(0,5)) = 1
            /// [HideInInspector] _INTR_EM("", Int) = 0
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local __ _L_EMISSIVE_ON
            /// </summary>
            public const string _INTR_EM = "_INTR_EM";

            /// <summary>
            /// IBL-Diffuse类型
            /// 示例:
            /// [HideInInspector] _INTR_IBLDiff("", Int) = 0
            /// 
            /// 配套Properties：
            /// [NoScaleOffset]_IrradianceMap_2D("Irradiance Texture 2D", 2D) = "black" {}
            /// [NoScaleOffset]_IrradianceMap_Cube("Irradiance Texture Cube", Cube) = "Cube" {}
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local _L_IBL_DIFF_GLOBAL_URP _L_IBL_DIFF_LOCAL_SPHERE_MAP _L_IBL_DIFF_LOCAL_CUBE_MAP
            /// </summary>
            public const string _INTR_IBLDiff = "_INTR_IBLDiff";

            /// <summary>
            /// IBL-Specular类型
            /// 示例:
            /// [HideInInspector] _INTR_IBLSpec("", Int) = 0
            /// 
            /// 配套Properties：
            /// [NoScaleOffset]_EnvironmentMap_2D("Environment Texture 2D", 2D) = "black" {}
            /// [NoScaleOffset]_EnvironmentMap_Cube("Environment Texture Cube", Cube) = "Cube" {}
            /// 
            /// 配套Keyword：
            /// #pragma multi_compile_local _L_IBL_SPEC_GLOBAL_URP _L_IBL_SPEC_LOCAL_SPHERE_MAP _L_IBL_SPEC_LOCAL_CUBE_MAP
            /// </summary>
            public const string _INTR_IBLSpec = "_INTR_IBLSpec";

            



            public const string _MixMap = "_MixMap";
            public const string _BumpMap = "_BumpMap";
            public const string _NormalMap = "_NormalMap";
            public const string _BumpScale = "_BumpScale";
            public const string _RoughnessLow = "_RoughnessLow";
            public const string _RoughnessHigh = "_RoughnessHigh";
            public const string _IrradianceMap_2D = "_IrradianceMap_2D";
            public const string _IrradianceMap_Cube = "_IrradianceMap_Cube";
            public const string _EnvironmentMap_2D = "_EnvironmentMap_2D";
            public const string _EnvironmentMap_Cube = "_EnvironmentMap_Cube";

            // _L_AO_ON
            public const string _AO_Bias = "_AO_Bias";

            public const string _EmissiveIntensity = "_EmissiveIntensity";

        }

        public struct Properties : IProperties
        {
            public MaterialProperty _INTR_NormalMapType;
            public MaterialProperty _INTR_RoughSrc;
            public MaterialProperty _INTR_RoughRange;
            public MaterialProperty _INTR_AO;
            public MaterialProperty _INTR_EM;
            public MaterialProperty _INTR_IBLDiff;
            public MaterialProperty _INTR_IBLSpec;


            /// <summary>
            /// 因为"_BumpMap"会被Unity特殊处理，混合法线图会被经常提示转为法线图，所以使用另一个名字处理
            /// </summary>
            public MaterialProperty _NormalMap;
            public MaterialProperty _BumpMap;
            public MaterialProperty _BumpScale;
           
            public MaterialProperty _MixMap;
            public MaterialProperty _RoughnessLow;
            public MaterialProperty _RoughnessHigh;

            public MaterialProperty _IrradianceMap_2D;
            public MaterialProperty _IrradianceMap_Cube;
            public MaterialProperty _EnvironmentMap_2D;
            public MaterialProperty _EnvironmentMap_Cube;

            public MaterialProperty _AO_Bias;

            public MaterialProperty _EmissiveIntensity;

            public Properties(MaterialProperty[] properties)
            {
                _INTR_NormalMapType = BaseShaderGUI.FindProperty(PropName._INTR_NormalMapType, properties, false);
                _INTR_RoughSrc = BaseShaderGUI.FindProperty(PropName._INTR_RoughSrc, properties, false);
                _INTR_RoughRange = BaseShaderGUI.FindProperty(PropName._INTR_RoughRange, properties, false);
                _INTR_AO = BaseShaderGUI.FindProperty(PropName._INTR_AO, properties, false);
                _INTR_EM = BaseShaderGUI.FindProperty(PropName._INTR_EM, properties, false);
                _INTR_IBLDiff = BaseShaderGUI.FindProperty(PropName._INTR_IBLDiff, properties, false);
                _INTR_IBLSpec = BaseShaderGUI.FindProperty(PropName._INTR_IBLSpec, properties, false);

                _MixMap = BaseShaderGUI.FindProperty(PropName._MixMap, properties, false);

                _NormalMap = BaseShaderGUI.FindProperty(PropName._NormalMap, properties, false);
                _BumpMap = BaseShaderGUI.FindProperty(PropName._BumpMap, properties, false);
                _BumpScale = BaseShaderGUI.FindProperty(PropName._BumpScale, properties, false);

                _RoughnessLow = BaseShaderGUI.FindProperty(PropName._RoughnessLow, properties, false);
                _RoughnessHigh = BaseShaderGUI.FindProperty(PropName._RoughnessHigh, properties, false);

                _IrradianceMap_2D = BaseShaderGUI.FindProperty(PropName._IrradianceMap_2D, properties, false);
                _IrradianceMap_Cube = BaseShaderGUI.FindProperty(PropName._IrradianceMap_Cube, properties, false);
                _EnvironmentMap_2D = BaseShaderGUI.FindProperty(PropName._EnvironmentMap_2D, properties, false);
                _EnvironmentMap_Cube = BaseShaderGUI.FindProperty(PropName._EnvironmentMap_Cube, properties, false);

                _AO_Bias = BaseShaderGUI.FindProperty(PropName._AO_Bias, properties, false);

                _EmissiveIntensity = BaseShaderGUI.FindProperty(PropName._EmissiveIntensity, properties, false);
            }
        }

        

        public static void DrawInputs(BaseShaderGUI shaderGUI, Properties properties, Material material, CustomInterface customInterface)
        {
            DoMixArea(shaderGUI, properties, customInterface);
            DoNormalArea(shaderGUI, properties, customInterface);
            DoBumpArea(shaderGUI, properties);
            DoRoughnessArea(shaderGUI, properties, customInterface);
            DoAOArea(shaderGUI, properties, customInterface);
            DoEmissiveArea(shaderGUI, properties, customInterface);
            DoIBLDiffuseArea(shaderGUI, properties, customInterface);
            DoIBLSpecularArea(shaderGUI, properties, customInterface);
        }

        #region Mix Map

        public static void DoMixArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            if (properties._MixMap == null)
            {
                return;
            }

            GUIContent text = (customInterface?.GetMixMapText()) ?? Styles.MixMapText;


            shaderGUI.MaterialEditor.TexturePropertySingleLine(text, properties._MixMap);

            var texture = properties._MixMap.textureValue;
            if(texture != null)
            {
                if(texture.mipmapCount > 1)
                {

                    if (BaseShaderGUI.HelpBoxWithButton(Styles.MixMapMipmapText, EditorGUIUtility.TrTempContent("去掉Mipmap"), MessageType.Warning))
                    {
                        BaseShaderGUI.RemoveTextureMipmap(texture);
                    }
                }
            }

            shaderGUI.DrawTextureInfo(properties._MixMap.textureValue);
        }

        #endregion

        #region Normal Map

        public static void DoNormalArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            MaterialProperty normalMap = properties._NormalMap;
            MaterialProperty bumpMapScale = properties._BumpScale;
            if (normalMap == null)
            {
                return;
            }

            MaterialProperty normalMapType = properties._INTR_NormalMapType;
            if (normalMapType != null)
            {
                // 选择
                BaseShaderGUI.DoEnumPopup<NormalMapType>(Styles.NormalMapOptionsText, normalMapType, shaderGUI.MaterialEditor);
                var type = BaseShaderGUI.MaterialPropertyToEnum<NormalMapType>(normalMapType, NormalMapType.NotUse);
                if (type == NormalMapType.NotUse)
                {
                    return;
                }
            }

            GUIContent text = (customInterface?.GetNormalMapText()) ?? Styles.NormalMapText;
            if (bumpMapScale != null)
            {
                shaderGUI.MaterialEditor.TexturePropertySingleLine(text, normalMap, bumpMapScale);
            }
            else
            {
                shaderGUI.MaterialEditor.TexturePropertySingleLine(text, normalMap);
            }

            shaderGUI.DrawTextureInfo(normalMap.textureValue);
        }

        public static void DoBumpArea(BaseShaderGUI shaderGUI, Properties properties)
        {
            MaterialProperty bumpMap = properties._BumpMap;
            MaterialProperty bumpMapScale = properties._BumpScale;
            if (bumpMap == null)
            {
                return;
            }

            if (bumpMapScale != null)
            {
                shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.NormalMapText, bumpMap, bumpMapScale);
            }
            else
            {
                shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.NormalMapText, bumpMap);
            }

            shaderGUI.DrawTextureInfo(bumpMap.textureValue);
        }

        /// <summary>
        /// 返回是否具有法线贴图属性
        /// </summary>
        /// <param name="properties"></param>
        /// <returns></returns>
        private static bool HasNormalMapOrBumpMap(Properties properties)
        {
            if(properties._BumpMap != null)
            {
                // 声明BumpMap表示普通需求
                return true;
            }
            if (properties._NormalMap != null)
            {
                // 声明NormalMap表示有怪异需求
                if(properties._INTR_NormalMapType != null)
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(properties._INTR_NormalMapType, NormalMapType.NotUse);
                    if(type != NormalMapType.NotUse)
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        public static void SetNormalMapType(Properties properties, NormalMapType new_type)
        {
            MaterialProperty normalMapType = properties._INTR_NormalMapType;
            if (normalMapType == null)
            {
                return;
            }
            var type = BaseShaderGUI.MaterialPropertyToEnum(normalMapType, NormalMapType.NotUse);
            if (type == new_type)
            {
                return;
            }
            BaseShaderGUI.SetMaterialPropertyEnum(normalMapType, new_type);
        }

        #endregion

        #region Roughness

        public static void DoRoughnessArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            if(properties._INTR_RoughSrc != null)
            {
                // 选择
                BaseShaderGUI.DoEnumPopup<RoughnessSource>(Styles.RoughnessSourceText, properties._INTR_RoughSrc, shaderGUI.MaterialEditor);
                var type = BaseShaderGUI.MaterialPropertyToEnum<RoughnessSource>(properties._INTR_RoughSrc);
                switch(type)
                {
                    case RoughnessSource.MixMap_R:
                        {
                            if(properties._MixMap == null)
                            {
                                EditorGUILayout.HelpBox($"材质不具备{PropName._MixMap}属性", MessageType.Error);
                                break;
                            }
                        }
                        break;
                    case RoughnessSource.NormalMap_B:
                        {
                            if(!HasNormalMapOrBumpMap(properties))
                            {
                                EditorGUILayout.HelpBox($"材质不具备法线贴图属性", MessageType.Error);
                                break;
                            }
                        }
                        break;
                }
            }

            if(properties._INTR_RoughRange != null)
            {
                BaseShaderGUI.DoEnumPopup<RoughnessRange>(Styles.RoughnessRangeText, properties._INTR_RoughRange, shaderGUI.MaterialEditor);
                var type = BaseShaderGUI.MaterialPropertyToEnum<RoughnessRange>(properties._INTR_RoughRange);
                if(type == RoughnessRange.Use)
                {
                    DoRoughnessLowHigh(properties);
                }
            }
        }

        private static void DoRoughnessLowHigh(Properties properties)
        {
            var propLow = properties._RoughnessLow;
            var propHigh = properties._RoughnessHigh;
            if (propLow == null || propHigh == null)
            {
                return;
            }
            var low = properties._RoughnessLow.floatValue;
            var high = properties._RoughnessHigh.floatValue;
            EditorGUILayout.MinMaxSlider(Styles.RoughnessMinMaxText, ref low, ref high, 0.0f, 1.0f);
            low = EditorGUILayout.Slider(Styles.RoughnessLowText, low, 0.0f, 1.0f);
            high = EditorGUILayout.Slider(Styles.RoughnessHighText, high, 0.0f, 1.0f);
            low = Mathf.Clamp01(low);
            high = Mathf.Clamp01(high);
            properties._RoughnessLow.floatValue = low;
            properties._RoughnessHigh.floatValue = high;
        }

        #endregion

        #region IBL

        public static void DoIBLDiffuseArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            MaterialProperty iblType = properties._INTR_IBLDiff;
            if(iblType == null)
            {
                return;
            }

            BaseShaderGUI.DoEnumPopup<IBLDiff>(Styles.IBLDiffText, iblType, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<IBLDiff>(iblType, IBLDiff.GlobalURP);
            switch(type)
            {
                case IBLDiff.GlobalURP:
                    {
                        // nothing
                        EditorGUI.indentLevel++;
                        EditorGUILayout.LabelField(Styles.IBLDiffTip1Text, EditorStyles.miniLabel);
                        EditorGUILayout.LabelField(Styles.IBLDiffTip2Text, EditorStyles.miniLabel);
                        EditorGUI.indentLevel--;
                    }
                    break;
                case IBLDiff.LocalSphereMap:
                    {
                        if (properties._IrradianceMap_2D == null)
                        {
                            EditorGUILayout.HelpBox($"缺少属性:{PropName._IrradianceMap_2D}", MessageType.Error);
                        }
                        else
                        {
                            shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.IrradianceMap2DText, properties._IrradianceMap_2D);
                            shaderGUI.DrawTextureInfo(properties._IrradianceMap_2D.textureValue);
                        }
                    }
                    break;
                case IBLDiff.LocalCubeMap:
                    {
                        if (properties._IrradianceMap_Cube == null)
                        {
                            EditorGUILayout.HelpBox($"缺少属性:{PropName._IrradianceMap_Cube}", MessageType.Error);
                        }
                        else
                        {
                            shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.IrradianceMapCubeText, properties._IrradianceMap_Cube);
                            shaderGUI.DrawTextureInfo(properties._IrradianceMap_Cube.textureValue);
                        }
                    }
                    break;
            }
        }

        public static void DoIBLSpecularArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            MaterialProperty iblType = properties._INTR_IBLSpec;
            if (iblType == null)
            {
                return;
            }

            BaseShaderGUI.DoEnumPopup<IBLSpec>(Styles.IBLSpecText, iblType, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<IBLSpec>(iblType, IBLSpec.GlobalURP);
            switch (type)
            {
                case IBLSpec.GlobalURP:
                    {
                        // nothing
                        //var _texture = ReflectionProbe.defaultTexture;
                        //EditorGUILayout.ObjectField(_texture, typeof(Texture), false);
                        EditorGUI.indentLevel++;
                        EditorGUILayout.LabelField(Styles.IBLSpecTip1Text, EditorStyles.miniLabel);
                        EditorGUILayout.LabelField(Styles.IBLSpecTip2Text, EditorStyles.miniLabel);
                        EditorGUI.indentLevel--;
                    }
                    break;
                case IBLSpec.LocalSphereMap:
                    {
                        if (properties._EnvironmentMap_2D == null)
                        {
                            EditorGUILayout.HelpBox($"缺少属性:{PropName._EnvironmentMap_2D}", MessageType.Error);
                        }
                        else
                        {
                            shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.EnvironmentMap2DText, properties._EnvironmentMap_2D);
                            shaderGUI.DrawTextureInfo(properties._EnvironmentMap_2D.textureValue);
                        }
                    }
                    break;
                case IBLSpec.LocalCubeMap:
                    {
                        if (properties._EnvironmentMap_Cube == null)
                        {
                            EditorGUILayout.HelpBox($"缺少属性:{PropName._EnvironmentMap_Cube}", MessageType.Error);
                        }
                        else
                        {
                            shaderGUI.MaterialEditor.TexturePropertySingleLine(Styles.EnvironmentMapCubeText, properties._EnvironmentMap_Cube);
                            shaderGUI.DrawTextureInfo(properties._EnvironmentMap_Cube.textureValue);
                        }
                    }
                    break;
            }
        }

        #endregion

        #region AO

        public static void DoAOArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            MaterialProperty aoType = properties._INTR_AO;
            if (aoType == null)
            {
                return;
            }

            BaseShaderGUI.DoEnumPopup<AOType>(Styles.AOSourceText, properties._INTR_AO, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<AOType>(properties._INTR_AO);
            if(type == AOType.NotUse)
            {
                return;
            }

            if (properties._AO_Bias != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._AO_Bias, Styles.AOBiasText);
                if(customInterface != null)
                {
                    var _tips = customInterface.GetAOBiasTipText();
                    if(_tips != null)
                    {
                        EditorGUI.indentLevel++;
                        EditorGUILayout.LabelField(_tips, EditorStyles.miniLabel);
                        EditorGUI.indentLevel--;
                    }
                }
            }
        }

        #endregion

        #region Emissive

        public static void DoEmissiveArea(BaseShaderGUI shaderGUI, Properties properties, CustomInterface customInterface)
        {
            MaterialProperty emType = properties._INTR_EM;
            if (emType == null)
            {
                return;
            }
            BaseShaderGUI.DoEnumPopup<EmissiveType>(Styles.EmissiveSourceText, properties._INTR_EM, shaderGUI.MaterialEditor);
            var type = BaseShaderGUI.MaterialPropertyToEnum<EmissiveType>(properties._INTR_EM);
            if (type == EmissiveType.NotUse)
            {
                return;
            }
            if (customInterface != null)
            {
                var _tips = customInterface.GetEmissiveTipText(type);
                if (_tips != null)
                {
                    EditorGUI.indentLevel++;
                    EditorGUILayout.LabelField(_tips, EditorStyles.miniLabel);
                    EditorGUI.indentLevel--;
                }
            }

            if (properties._EmissiveIntensity != null)
            {
                shaderGUI.MaterialEditor.ShaderProperty(properties._EmissiveIntensity, Styles.EmissiveIntensityText);
            }
        }

        #endregion

        public static void SetMaterialKeywords(Material material)
        {
            // Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
            // (MaterialProperty value might come from renderer material property block)

            // 法线Keyword
            {
                bool useNormalMap = false;
                if (material.HasProperty(PropName._NormalMap))
                {
                    if (material.HasProperty(PropName._INTR_NormalMapType))
                    {
                        // 有选择
                        var type = BaseShaderGUI.MaterialPropertyToEnum<NormalMapType>(material, PropName._INTR_NormalMapType, NormalMapType.NotUse);
                        if (type != NormalMapType.NotUse)
                        {
                            useNormalMap = true;
                        }
                    }
                    else
                    {
                        // 固定一定使用
                        useNormalMap = true;
                    }
                }
                if (material.HasProperty(PropName._BumpMap))
                {
                    // 只要有_BumpMap就使用
                    useNormalMap = true;
                }
                // 设置法线Keyword
                CoreUtils.SetKeyword(material, Keywords._NORMALMAP, useNormalMap);
                // 清空不必要的贴图引用
                if (!useNormalMap)
                {
                    if (material.HasProperty(PropName._NormalMap))
                    {
                        material.SetTexture(PropName._NormalMap, null);
                    }
                    if (material.HasProperty(PropName._BumpMap))
                    {
                        material.SetTexture(PropName._BumpMap, null);
                    }
                }

                bool useBumpScale = false;
                if(material.HasProperty(PropName._BumpScale))
                {
                    useBumpScale = true;
                }
                // 设置Keyword
                CoreUtils.SetKeyword(material, Keywords._L_BUMP_SCALE_ON, useBumpScale);
            }

            // 粗糙度范围
            {
                bool useRoughnessRange = false;
                if (material.HasProperty(PropName._INTR_RoughRange))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum<RoughnessRange>(material, PropName._INTR_RoughRange, RoughnessRange.NotUse);
                    if (type != RoughnessRange.NotUse)
                    {
                        useRoughnessRange = true;
                    }
                }
                // 设置Keyword
                CoreUtils.SetKeyword(material, Keywords._L_ROUGHNESS_RANGE_ON, useRoughnessRange);
            }

            // 粗糙度来源
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_ROUGH_SRC_MIX_R, false);
                CoreUtils.SetKeyword(material, Keywords._L_ROUGH_SRC_NORMMAP_B, false);

                if (material.HasProperty(PropName._INTR_RoughSrc))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(material, PropName._INTR_RoughRange, RoughnessSource.MixMap_R);
                    switch(type)
                    {
                        case RoughnessSource.MixMap_R: CoreUtils.SetKeyword(material, Keywords._L_ROUGH_SRC_MIX_R, true); break;
                        case RoughnessSource.NormalMap_B: CoreUtils.SetKeyword(material, Keywords._L_ROUGH_SRC_NORMMAP_B, true); break;
                    }
                }
            }

            // AO
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_AO_ON, false);

                if (material.HasProperty(PropName._INTR_AO))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(material, PropName._INTR_AO, AOType.NotUse);
                    if(type == AOType.Use)
                    {
                        CoreUtils.SetKeyword(material, Keywords._L_AO_ON, true);
                    }
                }
            }

            // Emissive
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_EMISSIVE_ON, false);

                if (material.HasProperty(PropName._INTR_EM))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(material, PropName._INTR_EM, EmissiveType.NotUse);
                    if (type == EmissiveType.Use)
                    {
                        CoreUtils.SetKeyword(material, Keywords._L_EMISSIVE_ON, true);
                    }
                }
            }

            // IBL-Diffuse来源
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_GLOBAL_URP, false);
                CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_LOCAL_SPHERE_MAP, false);
                CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_LOCAL_CUBE_MAP, false);

                bool useIrradianceMap_2D = false;
                bool useIrradianceMap_Cube = false;
                if (material.HasProperty(PropName._INTR_IBLDiff))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(material, PropName._INTR_IBLDiff, IBLDiff.GlobalURP);
                    switch (type)
                    {
                        case IBLDiff.GlobalURP: CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_GLOBAL_URP, true); break;
                        case IBLDiff.LocalSphereMap: useIrradianceMap_2D = true; CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_LOCAL_SPHERE_MAP, true); break;
                        case IBLDiff.LocalCubeMap: useIrradianceMap_Cube = true; CoreUtils.SetKeyword(material, Keywords._L_IBL_DIFF_LOCAL_CUBE_MAP, true); break;
                    }
                }

                // 清空不必要的贴图引用
                if (!useIrradianceMap_2D)
                {
                    if (material.HasProperty(PropName._IrradianceMap_2D))
                    {
                        material.SetTexture(PropName._IrradianceMap_2D, null);
                    }
                }
                if (!useIrradianceMap_Cube)
                {
                    if (material.HasProperty(PropName._IrradianceMap_Cube))
                    {
                        material.SetTexture(PropName._IrradianceMap_Cube, null);
                    }
                }
            }

            // IBL-Specular来源
            {
                // 先清空所有
                CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_GLOBAL_URP, false);
                CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_LOCAL_SPHERE_MAP, false);
                CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_LOCAL_CUBE_MAP, false);

                bool useEnvironmentMap_2D = false;
                bool useEnvironmentMap_Cube = false;
                if (material.HasProperty(PropName._INTR_IBLSpec))
                {
                    var type = BaseShaderGUI.MaterialPropertyToEnum(material, PropName._INTR_IBLSpec, IBLSpec.GlobalURP);
                    switch (type)
                    {
                        case IBLSpec.GlobalURP: CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_GLOBAL_URP, true); break;
                        case IBLSpec.LocalSphereMap: useEnvironmentMap_2D = true; CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_LOCAL_SPHERE_MAP, true); break;
                        case IBLSpec.LocalCubeMap: useEnvironmentMap_Cube = true; CoreUtils.SetKeyword(material, Keywords._L_IBL_SPEC_LOCAL_CUBE_MAP, true); break;
                    }
                }

                // 清空不必要的贴图引用
                if (!useEnvironmentMap_2D)
                {
                    if (material.HasProperty(PropName._EnvironmentMap_2D))
                    {
                        material.SetTexture(PropName._EnvironmentMap_2D, null);
                    }
                }
                if (!useEnvironmentMap_Cube)
                {
                    if (material.HasProperty(PropName._EnvironmentMap_Cube))
                    {
                        material.SetTexture(PropName._EnvironmentMap_Cube, null);
                    }
                }
            }
        }
    }
}