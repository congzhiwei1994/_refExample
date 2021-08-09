//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA
//#define DEFAULT_GUI

using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
    public class StylizedGrassShaderGUI : ShaderGUI
    {
#if URP
        private ShaderConfigurator.Configuration thirdPartyConfig;

        Material targetMat;
        string[] keyWords;

        private Vector4 windParams;
        private Vector4 natureRendererParams;

        private MaterialProperty baseMap;
        private MaterialProperty bumpMap;
        private MaterialProperty alphaCutoffProp;
        private MaterialProperty alphaToCoverage;
        private MaterialProperty color;

        private MaterialProperty hueColor;
        private MaterialProperty colorMapStrength;
        private MaterialProperty colorMapHeight;
        private MaterialProperty scalemapInfluence;
        private MaterialProperty ambientOcclusion;
        private MaterialProperty vertexDarkening;
        private MaterialProperty smoothness;
        private MaterialProperty translucency;

        private MaterialProperty bendMode;
        private MaterialProperty bendPushStrength;
        private MaterialProperty bendFlattenStrength;
        private MaterialProperty perspCorrection;

        private MaterialProperty windAmbientStrength;
        private MaterialProperty windSpeed;
        private MaterialProperty windDirection;
        private MaterialProperty windVertexRand;
        private MaterialProperty windObjectRand;
        private MaterialProperty windRandStrength;
        private MaterialProperty windSwinging;
        private MaterialProperty windGustTex;
        private MaterialProperty windGustStrength;
        private MaterialProperty windGustFreq;
        private MaterialProperty windGustTint;

        private bool enableDistFade;
        private float fadeStartDist;
        private float fadeEndDist;
        private Vector4 fadeParams;

        private MaterialProperty culling;
        public enum CullingMode
        {
            Both, Front, Back
        }

        private bool m_SurfaceOptionsFoldout
        {
            get { return SessionState.GetBool("m_SurfaceOptionsFoldout", true); }
            set { SessionState.SetBool("m_SurfaceOptionsFoldout", value); }
        }
        private bool m_ColorOptionsFoldout
        {
            get { return SessionState.GetBool("m_ColorOptionsFoldout", true); }
            set { SessionState.SetBool("m_ColorOptionsFoldout", value); }
        }
        private bool m_ShadingOptionsFoldout
        {
            get { return SessionState.GetBool("sgs_ShadingOptionsFoldout", true); }
            set { SessionState.SetBool("sgs_ShadingOptionsFoldout", value); }
        }
        private bool m_RenderingOptionsFoldout
        {
            get { return SessionState.GetBool("sgs_RenderingOptionsFoldout", true); }
            set { SessionState.SetBool("sgs_RenderingOptionsFoldout", value); }
        }
        private bool m_WindOptionsFoldout
        {
            get { return SessionState.GetBool("sgs_WindOptionsFoldout", true); }
            set { SessionState.SetBool("sgs_WindOptionsFoldout", value); }
        }
        private bool m_BendOptionsFoldout
        {
            get { return SessionState.GetBool("sgs_BendOptionsFoldout", true); }
            set { SessionState.SetBool("sgs_BendOptionsFoldout", value); }
        }

        private MaterialEditor materialEditor;
        private MaterialProperty disableShadows;
        private MaterialProperty advancedLighting;
        private MaterialProperty castShadows;
        private MaterialProperty environmentReflections;
        private MaterialProperty scaleMap;
        private MaterialProperty shadowBiasCorrection;

        private GUIContent simpleLightingContent;
        private GUIContent advancedLightingContent;

        private bool initliazed;

        public void FindProperties(MaterialProperty[] props)
        {
            thirdPartyConfig = ShaderConfigurator.GetConfiguration((materialEditor.target as Material).shader);

            culling = FindProperty("_Cull", props);
            windParams = Shader.GetGlobalVector("_GlobalWindParams");
            natureRendererParams = Shader.GetGlobalVector("GlobalWindDirectionAndStrength");

            baseMap = FindProperty("_BaseMap", props);
            alphaCutoffProp = FindProperty("_Cutoff", props);
            alphaToCoverage = FindProperty("_AlphaToCoverage", props);
            bumpMap = FindProperty("_BumpMap", props);
            color = FindProperty("_BaseColor", props);
            hueColor = FindProperty("_HueVariation", props);

            colorMapStrength = FindProperty("_ColorMapStrength", props);
            colorMapHeight = FindProperty("_ColorMapHeight", props);
            scalemapInfluence = FindProperty("_ScalemapInfluence", props);

            ambientOcclusion = FindProperty("_OcclusionStrength", props);
            vertexDarkening = FindProperty("_VertexDarkening", props);
            smoothness = FindProperty("_Smoothness", props);
            translucency = FindProperty("_Translucency", props);

            windAmbientStrength = FindProperty("_WindAmbientStrength", props);
            windSpeed = FindProperty("_WindSpeed", props);
            windDirection = FindProperty("_WindDirection", props);
            windVertexRand = FindProperty("_WindVertexRand", props);
            windObjectRand = FindProperty("_WindObjectRand", props);
            windRandStrength = FindProperty("_WindRandStrength", props);
            windSwinging = FindProperty("_WindSwinging", props);

            bendMode = FindProperty("_BendMode", props);
            bendPushStrength = FindProperty("_BendPushStrength", props);
            bendFlattenStrength = FindProperty("_BendFlattenStrength", props);
            perspCorrection = FindProperty("_PerspectiveCorrection", props);

            windGustTex = FindProperty("_WindMap", props);
            windGustStrength = FindProperty("_WindGustStrength", props);
            windGustFreq = FindProperty("_WindGustFreq", props);
            windGustTint = FindProperty("_WindGustTint", props);

            fadeParams = targetMat.GetVector("_FadeParams");
            enableDistFade = fadeParams.z == 1f;
            fadeStartDist = fadeParams.x;
            fadeEndDist = fadeParams.y;

            advancedLighting = FindProperty("_AdvancedLighting", props);
            disableShadows = FindProperty("_ReceiveShadows", props);
            castShadows = FindProperty("_ReceiveShadows", props);
            environmentReflections = FindProperty("_EnvironmentReflections", props);
            scaleMap = FindProperty("_Scalemap", props);
            shadowBiasCorrection = FindProperty("_ShadowBiasCorrection", props);

            simpleLightingContent = new GUIContent("Simple", "" +
               "Diffuse shading\n\n" +
               "" +
               "Per pixel color map\n" +
               "Lightmaps\n" +
               "Point and spot lights (per object)");

            advancedLightingContent = new GUIContent("Advanced",
                "Physically-based shading\n\n" +
                "" +
                "Per pixel color map\n" +
                "Lightmaps\n" +
                "Point and spot lights (per pixel/vertex)\n" +

                "Global Illumination\n" +
                "Environment reflections\n" +
                "Light Probes\n");

            initliazed = true;
        }

        //https://github.com/Unity-Technologies/ScriptableRenderPipeline/blob/648184ec8405115e2fcf4ad3023d8b16a191c4c7/com.unity.render-pipelines.universal/Editor/ShaderGUI/BaseShaderGUI.cs
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            this.materialEditor = materialEditor;

            materialEditor.SetDefaultGUIWidths();
            materialEditor.UseDefaultMargins();
            EditorGUIUtility.labelWidth = 0f;

            targetMat = materialEditor.target as Material;
            keyWords = targetMat.shaderKeywords;

            if (!initliazed)
            {
                FindProperties(props);
            }

#if DEFAULT_GUI
            base.OnGUI(materialEditor, props);
            return;
#endif

            EditorGUILayout.LabelField(AssetInfo.ASSET_NAME + " " + AssetInfo.INSTALLED_VERSION, EditorStyles.centeredGreyMiniLabel);
            EditorGUILayout.Space();

            EditorGUI.BeginChangeCheck();

            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField("Lighting", GUILayout.Width(EditorGUIUtility.labelWidth));
                advancedLighting.floatValue = (float)GUILayout.Toolbar((int)advancedLighting.floatValue,
                    new GUIContent[] { simpleLightingContent, advancedLightingContent }
                    );
            }
            EditorGUILayout.Space();

            DrawRendering();
            EditorGUILayout.Space();
            DrawMaps();
            EditorGUILayout.Space();
            DrawColor();
            EditorGUILayout.Space();
            DrawShading();
            EditorGUILayout.Space();
            DrawVertices();
            EditorGUILayout.Space();
            DrawWind();

            EditorGUILayout.Space();

            materialEditor.EnableInstancingField();
            if (!materialEditor.IsInstancingEnabled()) EditorGUILayout.HelpBox("GPU Instancing is highly recommended for optimal performance", MessageType.Warning);
            materialEditor.RenderQueueField();
            materialEditor.DoubleSidedGIField();

            if (EditorGUI.EndChangeCheck())
            {
                ApplyChanges();
            }

            EditorGUILayout.Space();

            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField("Third party shader configuration:", EditorStyles.boldLabel, GUILayout.MaxWidth(200f));
                EditorGUILayout.LabelField(thirdPartyConfig.ToString(), GUILayout.MaxWidth(150f));
                if (GUILayout.Button("Change"))
                {
                    GenericMenu menu = new GenericMenu();
                    if (thirdPartyConfig == ShaderConfigurator.Configuration.VegetationStudio)
                    {
                        menu.AddDisabledItem(new GUIContent("Switch to Vegetation Studio integration"));
                    }
                    else
                    {
                        menu.AddItem(new GUIContent("Switch to Vegetation Studio integration"), false, ShaderConfigurator.ConfigureForVegetationStudio);
                    }
                    if (thirdPartyConfig == ShaderConfigurator.Configuration.NatureRenderer)
                    {
                        menu.AddDisabledItem(new GUIContent("Switch to Nature Renderer integration"));
                    }
                    else
                    {
                        menu.AddItem(new GUIContent("Switch to Nature Renderer integration"), false, ShaderConfigurator.ConfigureForNatureRenderer);
                    }

                    menu.ShowAsContext();
                }
            }

            EditorGUILayout.Space();
            EditorGUILayout.LabelField("- Staggart Creations -", EditorStyles.centeredGreyMiniLabel);

        }

        private void ApplyChanges()
        {
#if URP
            targetMat.mainTexture = baseMap.textureValue;
            targetMat.SetTexture("_WindMap", windGustTex.textureValue);
            targetMat.SetTexture("_BumpMap", bumpMap.textureValue);

            //Keywords
            if (bumpMap.textureValue) CoreUtils.SetKeyword(targetMat, "_NORMALMAP", bumpMap.textureValue);
            if (targetMat.HasProperty("_AdvancedLighting")) CoreUtils.SetKeyword(targetMat, "_ADVANCED_LIGHTING", targetMat.GetFloat("_AdvancedLighting") == 1.0f);
            if (targetMat.HasProperty("_ReceiveShadows")) CoreUtils.SetKeyword(targetMat, "_RECEIVE_SHADOWS_OFF", targetMat.GetFloat("_ReceiveShadows") == 0.0f);
            if (targetMat.HasProperty("_EnvironmentReflections")) CoreUtils.SetKeyword(targetMat, "_ENVIRONMENTREFLECTIONS_OFF", targetMat.GetFloat("_EnvironmentReflections") == 1.0f);
            if (targetMat.HasProperty("_Scalemap")) CoreUtils.SetKeyword(targetMat, "_SCALEMAP", targetMat.GetFloat("_Scalemap") == 1.0f);
            if (targetMat.HasProperty("_ShadowBiasCorrection")) CoreUtils.SetKeyword(targetMat, "_SHADOWBIAS_CORRECTION", targetMat.GetFloat("_ShadowBiasCorrection") == 1.0f);

            //Packed vectors
            targetMat.SetVector("_FadeParams", new Vector4(fadeStartDist, fadeEndDist, enableDistFade ? 1f : 0f, 0f));

            EditorUtility.SetDirty(targetMat);
#endif
        }

        private void DrawMinMaxSlider(string label, ref float min, ref float max)
        {
            float minVal = min;
            float maxVal = max;

            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField(label, GUILayout.MaxWidth(EditorGUIUtility.labelWidth - 30));
                EditorGUILayout.LabelField(Math.Round(minVal, 2).ToString(), GUILayout.Width(75f));
                EditorGUILayout.MinMaxSlider(ref minVal, ref maxVal, 0f, 500f);
                EditorGUILayout.LabelField(Math.Round(maxVal, 2).ToString(), GUILayout.Width(75f));
            }

            min = minVal;
            max = maxVal;
        }

        private static void DrawSlider(MaterialProperty prop, string tooltip = null)
        {
            prop.floatValue = EditorGUILayout.Slider(new GUIContent(prop.displayName, null, tooltip), prop.floatValue, prop.rangeLimits.x, prop.rangeLimits.y);
        }

        private static void DrawSlider(MaterialProperty prop, string name, string tooltip = null)
        {
            prop.floatValue = EditorGUILayout.Slider(new GUIContent(name, null, tooltip), prop.floatValue, prop.rangeLimits.x, prop.rangeLimits.y);
        }

        private static void Toggle(MaterialProperty prop, string tooltip = null)
        {
            prop.floatValue = EditorGUILayout.Toggle(new GUIContent(prop.displayName, null, tooltip), prop.floatValue == 0f ? true : false) ? 0f : 1f;
        }

        private static void DrawColorField(MaterialProperty prop, string name, string tooltip = null)
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.PrefixLabel(new GUIContent(name, tooltip));
                GUILayout.Space(-15f);
                prop.colorValue = EditorGUILayout.ColorField(new GUIContent("", null, tooltip), prop.colorValue, true, true, false, GUILayout.MaxWidth(75f));
                //GUILayout.FlexibleSpace();
            }
        }

        private static void DrawVector3(MaterialProperty prop, string name, string tooltip = null)
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.PrefixLabel(new GUIContent(name, tooltip));
                GUILayout.Space(-15f);
                prop.vectorValue = EditorGUILayout.Vector3Field(new GUIContent("", null, tooltip), prop.vectorValue);
            }
        }

        private void DrawRendering()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);
                m_RenderingOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_RenderingOptionsFoldout, new GUIContent("Rendering"));
                if (m_RenderingOptionsFoldout)
                {
                    EditorGUI.indentLevel++;
                    var cullingMode = (int)culling.floatValue;

                    cullingMode = EditorGUILayout.Popup("Culling", cullingMode, new string[] { "Double-sided", "Front-faces", "Back-faces" });

                    culling.floatValue = cullingMode;
                    materialEditor.ShaderProperty(disableShadows, "Receive Shadows");
                    if (disableShadows.floatValue == 1)
                    {
                        EditorGUI.indentLevel++;
                        materialEditor.ShaderProperty(shadowBiasCorrection, new GUIContent("Shadow banding correction", "Offsets the shadows received by the grass a tiny bit. This avoids unwanted self-shadowing (aka shadow acne)\n\nHas the added benefit of creating fake contact shadows."));
                        EditorGUI.indentLevel--;
                    }
                    materialEditor.ShaderProperty(alphaToCoverage, new GUIContent("Alpha to coverage", "Reduces aliasing when using MSAA"));
                    if (alphaToCoverage.floatValue > 0 && UniversalRenderPipeline.asset.msaaSampleCount == 1) EditorGUILayout.HelpBox("MSAA is disabled, alpha to coverage will have no effect", MessageType.None);

                    enableDistFade = EditorGUILayout.Toggle(new GUIContent("Distance fading", "Reduces the alpha clipping based on camera distance." +
                        "\n\nNote that this does not improve performance, only pixels are being hidden, meshes are still being rendered, " +
                        "best to match these settings to your maximum grass draw distance"), enableDistFade);
                    if (enableDistFade)
                    {
                        EditorGUI.indentLevel++;
                        DrawMinMaxSlider("Start/End", ref fadeStartDist, ref fadeEndDist);
                        EditorGUI.indentLevel--;
                    }

                    EditorGUI.indentLevel--;
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawMaps()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);
                m_SurfaceOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceOptionsFoldout, new GUIContent("Main Maps"));
                if (m_SurfaceOptionsFoldout)
                {
                    EditorGUI.indentLevel++;
                    //materialEditor.TexturePropertySingleLine(new GUIContent("Texture (A=Alpha)"), baseMap, color);
                    materialEditor.TextureProperty(baseMap, "Texture (A=Alpha)");
                    //materialEditor.ShaderProperty(baseMap, new GUIContent("Texture (A=Alpha)"));
                    materialEditor.ShaderProperty(alphaCutoffProp, "Alpha clipping");
                    materialEditor.TextureProperty(bumpMap, "Normal map");
                    EditorGUI.indentLevel--;
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawColor()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);
                m_ColorOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_ColorOptionsFoldout, new GUIContent("Color"));
                if (m_ColorOptionsFoldout)
                {
                    EditorGUI.indentLevel++;

                    DrawColorField(color, color.displayName, "This color is multiplied with the texture. Use a white texture to color the grass by this value entirely.");
                    DrawColorField(hueColor, hueColor.displayName, "Every object will receive a random color between this color, and the main color. The alpha channel controls the intensity");

                    DrawSlider(colorMapStrength, "Controls the much the color map influences the material. Overrides any other colors");
                    if (!GrassColorMap.Active) EditorGUILayout.HelpBox("No color map is currently active", MessageType.None);
                    DrawSlider(colorMapHeight, "Controls which part of the mesh is affected, from bottom to top");

                    DrawSlider(ambientOcclusion, "Darkens the mesh based on the red vertex color painted into the mesh");
                    DrawSlider(vertexDarkening, "Gives each vertex a random darker tint. Use in moderation to slightly break up visual repetition");

                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawShading()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);

                m_ShadingOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_ShadingOptionsFoldout, new GUIContent("Shading"));
                if (m_ShadingOptionsFoldout)
                {
                    EditorGUI.indentLevel++;

                    if (advancedLighting.floatValue == 1f)
                    {
                        //materialEditor.ShaderProperty(environmentReflections, environmentReflections.displayName);
                        Toggle(environmentReflections, "Enables reflections from skybox and reflection probes");
                        if (environmentReflections.floatValue == 0f && RenderSettings.defaultReflectionMode != DefaultReflectionMode.Skybox && RenderSettings.customReflection == null)
                        {
                            EditorGUILayout.HelpBox("Environment reflection source is set to \"Custom\" but no cubemap is assigned", MessageType.Warning);

                        }
                        DrawSlider(smoothness, "Controls how strongly the skybox and reflection probes affect the material (similar to PBR smoothness)");
                        if (smoothness.floatValue > 0f && RenderSettings.defaultReflectionMode == DefaultReflectionMode.Custom && RenderSettings.customReflection == null)
                        {
                            EditorGUILayout.HelpBox("Environment reflections source is set to \"Custom\" without a cubemap assigned. No reflections will be visible", MessageType.Warning);

                        }

                    }
                    DrawSlider(translucency, "Simulates sun light passing through the grass. Most noticeable at glancing or low sun angles");

                    EditorGUI.indentLevel--;

                    EditorGUILayout.Space();
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawVertices()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);
                m_BendOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BendOptionsFoldout, new GUIContent("Vertices"));
                if (m_BendOptionsFoldout)
                {
                    EditorGUI.indentLevel++;

                    DrawSlider(perspCorrection, "The amount by which the grass is gradually bent away from the camera as it looks down. Useful for better coverage in top-down perspectives");

                    using (new EditorGUILayout.HorizontalScope())
                    {
                        EditorGUILayout.LabelField("Bend Mode", GUILayout.Width(EditorGUIUtility.labelWidth));
                        bendMode.floatValue = (float)GUILayout.Toolbar((int)bendMode.floatValue,
                            new GUIContent[] { new GUIContent("Per-vertex", "Bending is applied on a per-vertex basis"), new GUIContent("Whole object", "Applied to all vertices at once, use this for plants/flowers to avoid distorting the mesh") }
                            );
                    }
                    DrawSlider(bendPushStrength, "The amount of pushing the material should receive by Grass Benders");
                    DrawSlider(bendFlattenStrength, "A multiplier for how much the material is flattened by Grass Benders");

                    if (GrassColorMap.Active && GrassColorMap.Active.hasScalemap == false) EditorGUILayout.HelpBox("Active color map has no scale information", MessageType.None);
                    if (!GrassColorMap.Active) EditorGUILayout.HelpBox("No color map is currently active", MessageType.None);
                    materialEditor.ShaderProperty(scaleMap, new GUIContent("Apply scale map", "Enable scaling through terrain-layer heightmap"));
                    if (scaleMap.floatValue == 1)
                    {
                        EditorGUI.indentLevel++;
                        DrawVector3(scalemapInfluence, "Scale influence", "Controls the scale strength of the heightmap per axis");
                        EditorGUI.indentLevel--;
                    }


                    EditorGUILayout.Space();
                    EditorGUI.indentLevel--;
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        private void DrawWind()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(-5f);
                m_WindOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_WindOptionsFoldout, new GUIContent("Wind"));
                if (m_WindOptionsFoldout)
                {
                    EditorGUI.indentLevel++;

                    EditorGUILayout.LabelField("Wind", EditorStyles.boldLabel);
                    if (windParams.x > 0f) EditorGUILayout.HelpBox("Wind strength is mutliplied by " + Shader.GetGlobalFloat("_WindStrength").ToString() + " (Set by external script)", MessageType.Info);
                    if (natureRendererParams.w > 0f) EditorGUILayout.HelpBox("Nature Renderer wind strength and speed are added to these values", MessageType.Info);

                    DrawSlider(windAmbientStrength, "The amount of wind that is applied without gusting");
                    DrawSlider(windSpeed, "The speed the wind and gusting moves at");
                    DrawVector3(windDirection, windDirection.displayName, null);
                    DrawSlider(windSwinging, "Controls the amount the grass is able to spring back against the wind direction");

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Randomization", EditorStyles.boldLabel);

                    DrawSlider(windObjectRand, "Per-object", "Adds a per-object offset, making each object move randomly rather than in unison");
                    DrawSlider(windVertexRand, "Per-vertex", "Adds a per-vertex offset");
                    DrawSlider(windRandStrength, "Gives each object a random wind strength. This is useful for breaking up repetition and gives the impression of turbulence");

                    EditorGUILayout.Space();

                    EditorGUILayout.LabelField("Gusting", EditorStyles.boldLabel);
                    materialEditor.TexturePropertySingleLine(new GUIContent("Gust texture (Grayscale)"), windGustTex);

                    DrawSlider(windGustStrength, "Strength", "Gusting add wind strength based on the gust texture, which moves over the grass");
                    DrawSlider(windGustFreq, "Frequency", "Controls the tiling of the gusting texture, essentially setting the size of the gusting waves");
                    DrawSlider(windGustTint, "Color tint", "Uses the gusting texture to add a brighter tint based on the gusting strength");

                    EditorGUILayout.Space();
                    EditorGUI.indentLevel--;

                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }
#else
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            EditorGUILayout.HelpBox("The Universal Render Pipeline v" + AssetInfo.MIN_URP_VERSION + " is not installed", MessageType.Error);
        }
#endif
    }
}