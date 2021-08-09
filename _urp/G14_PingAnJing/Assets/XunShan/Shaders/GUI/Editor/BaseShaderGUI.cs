using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;


namespace ShaderEditor
{
    public abstract class BaseShaderGUI : ShaderGUI
    {
        #region EnumsAndClasses

        public enum SurfaceType
        {
            [InspectorName("不透明")]
            Opaque,
            [InspectorName("透明")]
            Transparent
        }

        public enum BlendMode
        {
            Alpha,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
            Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
            Additive,
            Multiply
        }

        public enum RenderFace
        {
            [InspectorName("正面")]
            Front = 2,
            [InspectorName("背面")]
            Back = 1,
            [InspectorName("双面")]
            Both = 0
        }

        public static class Keywords
        {
            public const string _ALPHATEST_ON = "_ALPHATEST_ON";
            public const string _ALPHAPREMULTIPLY_ON = "_ALPHAPREMULTIPLY_ON";
        }
            

        private class Styles
        {
            // Catergories
            public static readonly GUIContent MaterialEditorOptions =
                new GUIContent("材质面板选项", "");

            public static readonly GUIContent SurfaceOptions =
                new GUIContent("表面选项", "");

            public static readonly GUIContent SurfaceInputs = 
                new GUIContent("表面输入",
                "这些选项用来描述物体的表面特性。");

            public static readonly GUIContent AdvancedLabel = 
                new GUIContent("Advanced",
                "These settings affect behind-the-scenes rendering and underlying calculations.");

            public static readonly GUIContent SurfaceType = 
                new GUIContent("表面类型",
                "选择物体表面类型。");

            public static readonly GUIContent blendingMode = 
                new GUIContent("半透明混合模式",
                "控制半透明表面颜色与背景颜色如何混合。");

            public static readonly GUIContent cullingText = 
                new GUIContent("渲染Face",
                "指定渲染的三角面方向，不渲染的面会被剔除。");

            public static readonly GUIContent alphaClipText = 
                new GUIContent("Alpha剪裁",
                "使材质有Cutout效果。使用这个创建全透-不透明效果，不会有渲染排序穿帮问题。");

            public static readonly GUIContent alphaClipThresholdText = 
                new GUIContent("Threshold",
                "Sets where the Alpha Clipping starts. The higher the value is, the brighter the  effect is when clipping starts.");

            public static readonly GUIContent receiveShadowText = 
                new GUIContent("Receive Shadows",
                "When enabled, other GameObjects can cast shadows onto this GameObject.");

            public static readonly GUIContent baseMap = 
                new GUIContent("Base Map",
                "指定表面的基本材质和/或颜色。如果你在表面选项下选择了透明或者Alpha剪裁，你的材质使用纹理的Alpha通道或者颜色。");

            public static readonly GUIContent emissionMap = 
                new GUIContent("Emission Map",
                "Sets a Texture map to use for emission. You can also select a color with the color picker. Colors are multiplied over the Texture.");

           

           

            public static readonly GUIContent queueSlider = new GUIContent("Priority",
                "Determines the chronological rendering order for a Material. High values are rendered first.");
        }

        #endregion

        #region Variables

        public static class PropName
        {
            public const string _BaseMap = "_BaseMap";
            public const string _Cutoff = "_Cutoff";
            public const string _Surface = "_Surface";
        }

        public struct Properties : IProperties
        {
            public MaterialProperty _BaseMap;
            public MaterialProperty _Cutoff;
            public MaterialProperty _Surface;


            public Properties(MaterialProperty[] properties)
            {
                _BaseMap = FindProperty(PropName._BaseMap, properties, false);
                _Cutoff = FindProperty(PropName._Cutoff, properties, false);
                _Surface = FindProperty(PropName._Surface, properties, false);
            }
        }

        protected Properties m_Properties;


        protected MaterialEditor materialEditor { get; set; }
        public MaterialEditor MaterialEditor { get { return materialEditor; } }

        protected MaterialProperty blendModeProp { get; set; }

        protected MaterialProperty cullingProp { get; set; }

        protected MaterialProperty alphaClipProp { get; set; }


        protected MaterialProperty receiveShadowsProp { get; set; }

        // Common Surface Input properties


        protected MaterialProperty baseColorProp { get; set; }

        protected MaterialProperty emissionMapProp { get; set; }

        protected MaterialProperty emissionColorProp { get; set; }

        protected MaterialProperty queueOffsetProp { get; set; }

        public bool m_FirstTimeApply = true;

        private static readonly string k_KeyPrefix = PlayerSettings.productName + "ShaderEditor:Material:UI_State:";

        protected string m_HeaderStateKey = null;

        // Header foldout states

        SavedBool m_SurfaceOptionsFoldout;

        SavedBool m_SurfaceInputsFoldout;

        SavedBool m_AdvancedFoldout;

        SavedBool m_SettingFoldout;

        SavedBool m_ShowTextureInfo;

        #endregion

        private const int queueOffsetRange = 50;

        #region 子类定制重写

        protected virtual bool IsFixedRenderFace()
        {
            return false;
        }

        protected virtual RenderFace GetFixedRenderFace()
        {
            return RenderFace.Front;
        }

        #endregion

        ////////////////////////////////////
        // General Functions              //
        ////////////////////////////////////
        #region GeneralFunctions

        protected abstract void MaterialChanged(Material material);

        protected virtual void InitProperties(MaterialProperty[] properties)
        {
            m_Properties = new Properties(properties);
            blendModeProp = FindProperty("_Blend", properties, false);
            cullingProp = FindProperty("_Cull", properties, false);
            alphaClipProp = FindProperty("_AlphaClip", properties, false);
            receiveShadowsProp = FindProperty("_ReceiveShadows", properties, false);
            baseColorProp = FindProperty("_BaseColor", properties, false);
            emissionMapProp = FindProperty("_EmissionMap", properties, false);
            emissionColorProp = FindProperty("_EmissionColor", properties, false);
            queueOffsetProp = FindProperty("_QueueOffset", properties, false);
        }

        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {
            if (materialEditorIn == null)
            {
                throw new ArgumentNullException("materialEditorIn");
            }

            InitProperties(properties); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            materialEditor = materialEditorIn;
            Material material = materialEditor.target as Material;

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a universal shader.
            if (m_FirstTimeApply)
            {
                DoOpenGUI(material, materialEditorIn);
                m_FirstTimeApply = false;
            }

            ShaderPropertiesGUI(material, properties);
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            MaterialChanged(material);
        }

        private void DoOpenGUI(Material material, MaterialEditor materialEditor)
        {
            m_SettingFoldout = new SavedBool($"{k_KeyPrefix}.SettingFoldout", false);
            m_ShowTextureInfo = new SavedBool($"{k_KeyPrefix}.ShowTextureInfo", true);

            // Foldout states
            m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
            m_SurfaceOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceOptionsFoldout", true);
            m_SurfaceInputsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceInputsFoldout", true);
            m_AdvancedFoldout = new SavedBool($"{m_HeaderStateKey}.AdvancedFoldout", false);

            OnOpenGUI(material, materialEditor);

            foreach (var obj in materialEditor.targets)
            {
                MaterialChanged((Material)obj);
            }
        }

        /// <summary>
        /// 子类重写 - 第一次显示GUI
        /// 用于读取配置信息
        /// </summary>
        /// <param name="material"></param>
        /// <param name="materialEditor"></param>
        protected virtual void OnOpenGUI(Material material, MaterialEditor materialEditor)
        {

        }

        private void ShaderPropertiesGUI(Material material, MaterialProperty[] properties)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }

            EditorGUI.BeginChangeCheck();

            m_SettingFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_SettingFoldout.value, Styles.MaterialEditorOptions);
            if (m_SettingFoldout.value)
            {
                DrawMaterialEditorOptions(material);
                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            DrawBeforeSurfaceOptions(material);

            m_SurfaceOptionsFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceOptionsFoldout.value, Styles.SurfaceOptions);
            if (m_SurfaceOptionsFoldout.value)
            {
                DrawSurfaceOptions(material);
                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            m_SurfaceInputsFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceInputsFoldout.value, Styles.SurfaceInputs);
            if (m_SurfaceInputsFoldout.value)
            {
                DrawSurfaceInputs(material);
                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            m_AdvancedFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout.value, Styles.AdvancedLabel);
            if (m_AdvancedFoldout.value)
            {
                DrawAdvancedOptions(material);
                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            DrawAdditionalFoldouts(material);


            PropertyHelper.DrawUncatchMaterialProperty(this, materialEditor, properties);

            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in materialEditor.targets)
                {
                    MaterialChanged((Material)obj);
                }
            }
        }

        #endregion
        ////////////////////////////////////
        // Drawing Functions              //
        ////////////////////////////////////
        #region DrawingFunctions

        /// <summary>
        /// 在SurfaceOptions之前的界面
        /// </summary>
        /// <param name="material"></param>
        protected virtual void DrawBeforeSurfaceOptions(Material material)
        {

        }

        protected virtual void DrawMaterialEditorOptions(Material material)
        {
            m_ShowTextureInfo.value = EditorGUILayout.Toggle("显示贴图详细信息", m_ShowTextureInfo.value);
        }

        protected virtual void DrawSurfaceOptions(Material material)
        {
            DoEnumPopup<SurfaceType>(Styles.SurfaceType, m_Properties._Surface);
            var surfaceType = MaterialPropertyToEnum<SurfaceType>(material, PropName._Surface, SurfaceType.Opaque);
            if (surfaceType == SurfaceType.Transparent)
            {
                DoEnumPopup<BlendMode>(Styles.blendingMode, blendModeProp);
            }

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = cullingProp.hasMixedValue;
            var culling = (RenderFace)cullingProp.floatValue;
            var isFixedCulling = IsFixedRenderFace();
            if (isFixedCulling)
            {
                var fixedCulling = GetFixedRenderFace();
                if(fixedCulling != culling)
                {
                    cullingProp.floatValue = (float)fixedCulling;
                    culling = fixedCulling;
                    GUI.changed = true;
                }
            }
            EditorGUI.BeginDisabledGroup(isFixedCulling);
            culling = (RenderFace)EditorGUILayout.EnumPopup(Styles.cullingText, culling);
            EditorGUI.EndDisabledGroup();
            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(Styles.cullingText.text);
                cullingProp.floatValue = (float)culling;
                material.doubleSidedGI = (RenderFace)cullingProp.floatValue != RenderFace.Front;
            }

            EditorGUI.showMixedValue = false;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = alphaClipProp.hasMixedValue;
            var alphaClipEnabled = EditorGUILayout.Toggle(Styles.alphaClipText, alphaClipProp.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
            }

            EditorGUI.showMixedValue = false;

            if (alphaClipProp.floatValue == 1)
            {
                if (m_Properties._Cutoff != null)
                {
                    materialEditor.ShaderProperty(m_Properties._Cutoff, Styles.alphaClipThresholdText, 1);
                }
            }

            if (receiveShadowsProp != null)
            {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = receiveShadowsProp.hasMixedValue;
                var receiveShadows =
                    EditorGUILayout.Toggle(Styles.receiveShadowText, receiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck())
                {
                    receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
                }

                EditorGUI.showMixedValue = false;
            }
        }

        protected virtual void DrawSurfaceInputs(Material material)
        {
            DrawBaseProperties(material);
        }

        protected virtual void DrawAdvancedOptions(Material material)
        {
            materialEditor.EnableInstancingField();

            if (queueOffsetProp != null)
            {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = queueOffsetProp.hasMixedValue;
                var queue = EditorGUILayout.IntSlider(Styles.queueSlider, (int)queueOffsetProp.floatValue, -queueOffsetRange, queueOffsetRange);
                if (EditorGUI.EndChangeCheck())
                {
                    queueOffsetProp.floatValue = queue;
                }

                EditorGUI.showMixedValue = false;
            }
        }

        protected virtual void DrawAdditionalFoldouts(Material material) { }


        protected virtual void DrawBaseProperties(Material material)
        {
            if (m_Properties._BaseMap != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                if (baseColorProp != null)
                {
                    materialEditor.TexturePropertySingleLine(Styles.baseMap, m_Properties._BaseMap, baseColorProp);
                }
                else
                {
                    materialEditor.TexturePropertySingleLine(Styles.baseMap, m_Properties._BaseMap);
                }
                DrawTextureInfo(m_Properties._BaseMap.textureValue);

                bool scaleOffset = ((m_Properties._BaseMap.flags & MaterialProperty.PropFlags.NoScaleOffset) == 0);
                if (scaleOffset)
                {
                    DrawTileOffset(materialEditor, m_Properties._BaseMap);
                }
            }
        }

        protected virtual void DrawEmissionProperties(Material material, bool keyword)
        {
            if (emissionMapProp == null)
            {
                return;
            }

            var emissive = true;
            var hadEmissionTexture = emissionMapProp.textureValue != null;

            if (!keyword)
            {
                materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, emissionMapProp, emissionColorProp, false);
            }
            else
            {
                // Emission for GI?
                emissive = materialEditor.EmissionEnabledProperty();

                EditorGUI.BeginDisabledGroup(!emissive);
                {
                    // Texture and HDR color controls
                    materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, emissionMapProp,
                        emissionColorProp,
                        false);
                }
                EditorGUI.EndDisabledGroup();
            }

            // If texture was assigned and color was black set color to white
            var brightness = emissionColorProp.colorValue.maxColorComponent;
            if (emissionMapProp.textureValue != null && !hadEmissionTexture && brightness <= 0f)
            {
                emissionColorProp.colorValue = Color.white;
            }

            // UniversalRP does not support RealtimeEmissive. We set it to bake emissive and handle the emissive is black right.
            if (emissive)
            {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
                if (brightness <= 0f)
                {
                    material.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                }
            }
        }

       

        protected static void DrawTileOffset(MaterialEditor materialEditor, MaterialProperty textureProp)
        {
            materialEditor.TextureScaleOffsetProperty(textureProp);
        }

        #endregion
        ////////////////////////////////////
        // Material Data Functions        //
        ////////////////////////////////////
        #region MaterialDataFunctions

        /// <summary>
        /// 根据当前材质属性自动设置Keyword
        /// </summary>
        /// <param name="material"></param>
        /// <param name="shadingModelFunc"></param>
        /// <param name="shaderFunc"></param>
        public static void SetMaterialKeywords(Material material, params Action<Material>[] shadingModelFunc)
        {
            // Clear all keywords for fresh start
            material.shaderKeywords = null;
            // Setup blending - consistent across all Universal RP shaders
            SetupMaterialBlendMode(material);
            // Receive Shadows
            if (material.HasProperty("_ReceiveShadows"))
            {
                CoreUtils.SetKeyword(material, "_RECEIVE_SHADOWS_OFF", material.GetFloat("_ReceiveShadows") == 0.0f);
            }
            // Emission
            if (material.HasProperty("_EmissionColor"))
            {
                MaterialEditor.FixupEmissiveFlag(material);
            }

            bool shouldEmissionBeEnabled =
                (material.globalIlluminationFlags & MaterialGlobalIlluminationFlags.EmissiveIsBlack) == 0;
            if (material.HasProperty("_EmissionEnabled") && !shouldEmissionBeEnabled)
            {
                shouldEmissionBeEnabled = material.GetFloat("_EmissionEnabled") >= 0.5f;
            }

            CoreUtils.SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);
            // Normal Map
            //if (material.HasProperty("_BumpMap"))
            //{
            //    CoreUtils.SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap"));
            //}
            // Shader specific keyword functions

            if (shadingModelFunc != null)
            {
                for(int _i = 0; _i < shadingModelFunc.Length; ++_i)
                {
                    shadingModelFunc[_i]?.Invoke(material);
                }
            }
        }

        public static void SetupMaterialBlendMode(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }

            bool alphaClip = material.GetFloat("_AlphaClip") == 1;
            if (alphaClip)
            {
                material.EnableKeyword(Keywords._ALPHATEST_ON);
            }
            else
            {
                material.DisableKeyword(Keywords._ALPHATEST_ON);
            }

            var queueOffset = 0; // queueOffsetRange;
            if (material.HasProperty("_QueueOffset"))
            {
                queueOffset = queueOffsetRange - (int)material.GetFloat("_QueueOffset");
            }

            SurfaceType surfaceType = (SurfaceType)material.GetFloat("_Surface");
            if (surfaceType == SurfaceType.Opaque)
            {
                if (alphaClip)
                {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                }
                else
                {
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                    material.SetOverrideTag("RenderType", "Opaque");
                }
                material.renderQueue += queueOffset;
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword(Keywords._ALPHAPREMULTIPLY_ON);
                material.SetShaderPassEnabled("ShadowCaster", true);
            }
            else
            {
                BlendMode blendMode = (BlendMode)material.GetFloat("_Blend");
                var queue = (int)UnityEngine.Rendering.RenderQueue.Transparent;

                // Specific Transparent Mode Settings
                switch (blendMode)
                {
                    case BlendMode.Alpha:
                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        material.DisableKeyword(Keywords._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Premultiply:
                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        material.EnableKeyword(Keywords._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Additive:
                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                        material.DisableKeyword(Keywords._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Multiply:
                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                        material.DisableKeyword(Keywords._ALPHAPREMULTIPLY_ON);
                        material.EnableKeyword("_ALPHAMODULATE_ON");
                        break;
                }
                // General Transparent Material Settings
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_ZWrite", 0);
                material.renderQueue = queue + queueOffset;
                material.SetShaderPassEnabled("ShadowCaster", false);
            }
        }

        #endregion
        ////////////////////////////////////
        // Helper Functions               //
        ////////////////////////////////////
        #region HelperFunctions


        public static void RemoveTextureMipmap(Texture texture)
        {
            if (texture == null)
            {
                return;
            }

            var path = AssetDatabase.GetAssetPath(texture);
            if (string.IsNullOrEmpty(path))
            {
                return;
            }
            var importer = TextureImporter.GetAtPath(path) as TextureImporter;
            if(importer == null)
            {
                return;
            }
            importer.mipmapEnabled = false;

            importer.SaveAndReimport();
        }

        /// <summary>
        /// 材质属性转Enum
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="material"></param>
        /// <param name="_name"></param>
        /// <param name="defaultVal"></param>
        /// <returns></returns>
        public static T MaterialPropertyToEnum<T>(Material material, string _name, T defaultVal = default(T)) where T : System.Enum
        {
            if (material.HasProperty(_name))
            {
                var val = material.GetFloat(_name);
                try
                {
                    T enumVal = (T)System.Enum.ToObject(typeof(T), System.Convert.ToInt32(val));
                    return enumVal;
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                    return defaultVal;
                }
            }
            return defaultVal;
        }
        public static T MaterialPropertyToEnum<T>(MaterialProperty materialProp, T defaultVal = default(T)) where T : System.Enum
        {
            if (materialProp != null)
            {
                var val = materialProp.floatValue;
                try
                {
                    T enumVal = (T)System.Enum.ToObject(typeof(T), System.Convert.ToInt32(val));
                    return enumVal;
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                    return defaultVal;
                }
            }
            return defaultVal;
        }
        public static void SetMaterialPropertyEnum<T>(MaterialProperty materialProp, T val) where T : System.Enum
        {
            if (materialProp != null)
            {
                try
                {
                    materialProp.floatValue = System.Convert.ToSingle(val);
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                }
                
            }
        }

        public static bool HelpBoxWithButton(GUIContent messageContent, GUIContent buttonContent, MessageType msgType)
        {
            EditorGUILayout.HelpBox(messageContent.text, msgType);

            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            bool click = GUILayout.Button(buttonContent, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            return click;
        }

        public static void TwoFloatSingleLine(GUIContent title, MaterialProperty prop1, GUIContent prop1Label,
            MaterialProperty prop2, GUIContent prop2Label, MaterialEditor materialEditor, float labelWidth = 30f)
        {
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop1.hasMixedValue || prop2.hasMixedValue;
            Rect rect = EditorGUILayout.GetControlRect();
            EditorGUI.PrefixLabel(rect, title);
            var indent = EditorGUI.indentLevel;
            var preLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUI.indentLevel = 0;
            EditorGUIUtility.labelWidth = labelWidth;
            Rect propRect1 = new Rect(rect.x + preLabelWidth, rect.y,
                (rect.width - preLabelWidth) * 0.5f, EditorGUIUtility.singleLineHeight);
            var prop1val = EditorGUI.FloatField(propRect1, prop1Label, prop1.floatValue);

            Rect propRect2 = new Rect(propRect1.x + propRect1.width, rect.y,
                propRect1.width, EditorGUIUtility.singleLineHeight);
            var prop2val = EditorGUI.FloatField(propRect2, prop2Label, prop2.floatValue);

            EditorGUI.indentLevel = indent;
            EditorGUIUtility.labelWidth = preLabelWidth;

            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(title.text);
                prop1.floatValue = prop1val;
                prop2.floatValue = prop2val;
            }

            EditorGUI.showMixedValue = false;
        }

        //public void DoPopup(GUIContent label, MaterialProperty property, string[] options)
        //{
        //    DoPopup(label, property, options, materialEditor);
        //}

        //public static void DoPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
        //{
        //    if (property == null)
        //        throw new ArgumentNullException("property");

        //    EditorGUI.showMixedValue = property.hasMixedValue;

        //    var mode = property.floatValue;
        //    EditorGUI.BeginChangeCheck();
        //    mode = EditorGUILayout.Popup(label, (int)mode, options);
        //    if (EditorGUI.EndChangeCheck())
        //    {
        //        materialEditor.RegisterPropertyChangeUndo(label.text);
        //        property.floatValue = mode;
        //    }

        //    EditorGUI.showMixedValue = false;
        //}

        public void DoEnumPopup<T>(GUIContent label, MaterialProperty property) where T : System.Enum
        {
            DoEnumPopup<T>(label, property, materialEditor);
        }

        public static void DoEnumPopup<T>(GUIContent label, MaterialProperty property, MaterialEditor materialEditor) where T : System.Enum
        {
            if (property == null)
            {
                throw new ArgumentNullException("property");
            }

            EditorGUI.showMixedValue = property.hasMixedValue;

            T mode = (T)System.Enum.ToObject(typeof(T), (int)property.floatValue);
            EditorGUI.BeginChangeCheck();
            mode = (T)EditorGUILayout.EnumPopup(label, mode);
            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(label.text);
                property.floatValue = System.Convert.ToSingle(mode);
            }

            EditorGUI.showMixedValue = false;
        }

        // Helper to show texture and color properties
        public static Rect TextureColorProps(MaterialEditor materialEditor, GUIContent label, MaterialProperty textureProp, MaterialProperty colorProp, bool hdr = false)
        {
            Rect rect = EditorGUILayout.GetControlRect();
            EditorGUI.showMixedValue = textureProp.hasMixedValue;
            materialEditor.TexturePropertyMiniThumbnail(rect, textureProp, label.text, label.tooltip);
            EditorGUI.showMixedValue = false;

            if (colorProp != null)
            {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = colorProp.hasMixedValue;
                int indentLevel = EditorGUI.indentLevel;
                EditorGUI.indentLevel = 0;
                Rect rectAfterLabel = new Rect(rect.x + EditorGUIUtility.labelWidth, rect.y,
                    EditorGUIUtility.fieldWidth, EditorGUIUtility.singleLineHeight);
                var col = EditorGUI.ColorField(rectAfterLabel, GUIContent.none, colorProp.colorValue, true,
                    false, hdr);
                EditorGUI.indentLevel = indentLevel;
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo(colorProp.displayName);
                    colorProp.colorValue = col;
                }
                EditorGUI.showMixedValue = false;
            }

            return rect;
        }

        // Copied from shaderGUI as it is a protected function in an abstract class, unavailable to others

        public new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties)
        {
            return ShaderGUI.FindProperty(propertyName, properties);
        }

        // Copied from shaderGUI as it is a protected function in an abstract class, unavailable to others

        public new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties, bool propertyIsMandatory)
        {
            //for (int index = 0; index < properties.Length; ++index)
            //{
            //    if (properties[index] != null && properties[index].name == propertyName)
            //        return properties[index];
            //}
            //if (propertyIsMandatory)
            //    throw new ArgumentException("Could not find MaterialProperty: '" + propertyName + "', Num properties: " + (object)properties.Length);
            return ShaderGUI.FindProperty(propertyName, properties, propertyIsMandatory);
        }

        #endregion


        #region Texture Info

        readonly static System.Text.StringBuilder s_TextureInfo = new System.Text.StringBuilder();

        /// <summary>
        /// 显示贴图信息
        /// </summary>
        /// <param name="texture"></param>
        public void DrawTextureInfo(Texture texture)
        {
            if(!m_ShowTextureInfo.value)
            {
                return;
            }
            if (texture != null)
            {
                TextureImporter importer = null;
                var path = AssetDatabase.GetAssetPath(texture);
                if (!string.IsNullOrEmpty(path))
                {
                    importer = TextureImporter.GetAtPath(path) as TextureImporter;
                }

                s_TextureInfo.Length = 0;
                EditorGUI.indentLevel++;
                EditorGUILayout.BeginVertical();

                if (importer != null)
                {
                    switch (importer.textureShape)
                    {
                        case TextureImporterShape.Texture2D:
                            s_TextureInfo.Append("2D ");
                            break;
                        case TextureImporterShape.TextureCube:
                            s_TextureInfo.Append("Cube ");
                            s_TextureInfo.Append(importer.generateCubemap);
                            s_TextureInfo.Append(" ");
                            break;
                    }
                }
                else
                {
                    s_TextureInfo.Append(texture.dimension);
                    s_TextureInfo.Append(" ");
                }

                s_TextureInfo.Append(texture.width);
                s_TextureInfo.Append('×');
                s_TextureInfo.Append(texture.height);

                if (importer != null)
                {
                    bool hasAlpha = false;
                    if (importer.alphaSource != TextureImporterAlphaSource.None)
                    {
                        if ((importer.alphaSource == TextureImporterAlphaSource.FromGrayScale) ||
                            (importer.alphaSource == TextureImporterAlphaSource.FromInput && importer.DoesSourceTextureHaveAlpha()))
                        {
                            hasAlpha = true;
                        }
                    }
                    s_TextureInfo.Append(" Alpha通道[");
                    s_TextureInfo.Append(hasAlpha ? "✔" : "✖");
                    s_TextureInfo.Append("]");
                }

                s_TextureInfo.Append(" mip[");
                s_TextureInfo.Append(texture.mipmapCount);
                s_TextureInfo.Append("]");


                EditorGUILayout.LabelField(s_TextureInfo.ToString(), EditorStyles.miniLabel);

                EditorGUILayout.EndVertical();
                EditorGUI.indentLevel--;

            }
      
        }

        #endregion
    }
}