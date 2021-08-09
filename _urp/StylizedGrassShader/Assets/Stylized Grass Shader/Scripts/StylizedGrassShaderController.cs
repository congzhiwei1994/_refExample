#if VEGETATION_STUDIO_PRO
using AwesomeTechnologies.VegetationSystem;
using UnityEngine;

namespace AwesomeTechnologies.Shaders
{
    public class StylizedGrassShaderController : IShaderController
    {
        public bool MatchShader(string shaderName)
        {
            if (string.IsNullOrEmpty(shaderName)) return false;

            return (shaderName == "Universal Render Pipeline/Nature/Stylized Grass") ? true : false;
        }

        public bool MatchBillboardShader(Material[] materials)
        {
            return false;
        }

        private Vector4 fadeParams;

        public ShaderControllerSettings Settings { get; set; }
        public void CreateDefaultSettings(Material[] materials)
        {
            Settings = new ShaderControllerSettings
            {
                Heading = "Stylized Grass",
                Description = "Description text",
                LODFadePercentage = true,
                LODFadeCrossfade = false,
                UpdateWind = true,
                SampleWind = true,
                DynamicHUE = true,
                SupportsInstantIndirect = true
            };

            fadeParams = ShaderControllerSettings.GetVector4FromMaterials(materials, "_FadeParams");
            Settings.AddBooleanProperty("enableDistFade", "Distance fading", "", fadeParams.z == 1f ? true : false);
            Settings.AddFloatProperty("fadeStartDist", "Fade start", "", fadeParams.x, 0, 100);
            Settings.AddFloatProperty("fadeEndDist", "Fade end", "", fadeParams.y, 0, 500);

            Settings.AddLabelProperty(" ");

            Settings.AddLabelProperty("Color");
            Settings.AddColorProperty("_BaseColor", "Base color", "", ShaderControllerSettings.GetColorFromMaterials(materials, "_BaseColor"));
            Settings.AddColorProperty("_HueVariation", "Hue variation", "", ShaderControllerSettings.GetColorFromMaterials(materials, "_HueVariation"));
            Settings.AddFloatProperty("_ColorMapStrength", "Colormap strength", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_ColorMapStrength"), 0, 1);
            if (Shader.GetGlobalVector("_ColorMapUV").w == 0f) Settings.AddLabelProperty("No color map is currently active");
            Settings.AddFloatProperty("_ColorMapHeight", "Colormap height", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_ColorMapHeight"), 0, 1);
            
            //No support for vectors!
            //Settings.add("_HeightmapScaleInfluence", "Heightmap scale influence", "", ShaderControllerSettings.GetVector4FromMaterials(materials, "_HeightmapScaleInfluence"), 0, 1);

            Settings.AddFloatProperty("_OcclusionStrength", "Ambient Occlusion", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_OcclusionStrength"), 0, 1);
            Settings.AddFloatProperty("_VertexDarkening", "Random darkening", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_VertexDarkening"), 0, 1);
            Settings.AddFloatProperty("_Translucency", "Translucency", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_Translucency"), 0, 1);

            Settings.AddLabelProperty(" ");

            Settings.AddLabelProperty("Bending");
            Settings.AddBooleanProperty("_BendMode", "Per-vertex", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_BendMode") == 0 ? true : false);
            Settings.AddFloatProperty("_BendPushStrength", "Pushing", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_BendPushStrength"), 0, 1);
            Settings.AddFloatProperty("_BendFlattenStrength", "Flattening", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_BendFlattenStrength"), 0, 1);
            Settings.AddFloatProperty("_PerspectiveCorrection", "Perspective Correction", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_PerspectiveCorrection"), 0, 1);

            Settings.AddLabelProperty(" ");

            Settings.AddLabelProperty("Wind");
            Settings.AddFloatProperty("_WindAmbientStrength", "Ambient Strength", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindAmbientStrength"), 0, 1);
            Settings.AddFloatProperty("_WindSpeed", "Speed", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindSpeed"), 0, 10);
            Settings.AddFloatProperty("_WindVertexRand", "Vertex randomization", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindVertexRand"), 0, 1);
            Settings.AddFloatProperty("_WindObjectRand", "Object randomization", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindObjectRand"), 0, 1);
            Settings.AddFloatProperty("_WindRandStrength", "Random strength", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindRandStrength"), 0, 1);
            Settings.AddFloatProperty("_WindSwinging", "Swinging", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindSwinging"), 0, 1);
            Settings.AddFloatProperty("_WindGustStrength", "Gust Strength", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindGustStrength"), 0, 1);
            Settings.AddFloatProperty("_WindGustFreq", "Gust Frequency", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindGustFreq"), 0, 10);
            Settings.AddFloatProperty("_WindGustTint", "Gust Tint", "", ShaderControllerSettings.GetFloatFromMaterials(materials, "_WindGustTint"), 0, 1);
        }

        public void UpdateMaterial(Material material, EnvironmentSettings environmentSettings)
        {
            if (Settings == null) return;

            material.SetVector("_FadeParams", new Vector4(
                Settings.GetFloatPropertyValue("fadeStartDist"),
                Settings.GetFloatPropertyValue("fadeEndDist"),
                Settings.GetBooleanPropertyValue("enableDistFade") ? 1f : 0f,
                0f));

            material.SetColor("_BaseColor", Settings.GetColorPropertyValue("_BaseColor"));
            material.SetColor("_HueVariation", Settings.GetColorPropertyValue("_HueVariation"));

            material.SetFloat("_ColorMapStrength", Settings.GetFloatPropertyValue("_ColorMapStrength"));
            material.SetFloat("_ColorMapHeight", Settings.GetFloatPropertyValue("_ColorMapHeight"));
            material.SetFloat("_OcclusionStrength", Settings.GetFloatPropertyValue("_OcclusionStrength"));
            material.SetFloat("_VertexDarkening", Settings.GetFloatPropertyValue("_VertexDarkening"));
            material.SetFloat("_Translucency", Settings.GetFloatPropertyValue("_Translucency"));

            material.SetFloat("_BendMode", Settings.GetBooleanPropertyValue("_BendMode") ? 0f : 1f);
            material.SetFloat("_BendPushStrength", Settings.GetFloatPropertyValue("_BendPushStrength"));
            material.SetFloat("_BendFlattenStrength", Settings.GetFloatPropertyValue("_BendFlattenStrength"));
            material.SetFloat("_PerspectiveCorrection", Settings.GetFloatPropertyValue("_PerspectiveCorrection"));

            material.SetFloat("_WindAmbientStrength", Settings.GetFloatPropertyValue("_WindAmbientStrength"));
            material.SetFloat("_WindSpeed", Settings.GetFloatPropertyValue("_WindSpeed"));
            material.SetFloat("_WindVertexRand", Settings.GetFloatPropertyValue("_WindVertexRand"));
            material.SetFloat("_WindObjectRand", Settings.GetFloatPropertyValue("_WindObjectRand"));
            material.SetFloat("_WindRandStrength", Settings.GetFloatPropertyValue("_WindRandStrength"));
            material.SetFloat("_WindSwinging", Settings.GetFloatPropertyValue("_WindSwinging"));
            material.SetFloat("_WindGustStrength", Settings.GetFloatPropertyValue("_WindGustStrength"));
            material.SetFloat("_WindGustFreq", Settings.GetFloatPropertyValue("_WindGustFreq"));
            material.SetFloat("_WindGustTint", Settings.GetFloatPropertyValue("_WindGustTint"));
        }

        public void UpdateWind(Material material, WindSettings windSettings)
        {
            material.SetVector("_WindDirection", windSettings.Direction);
        }
    }
}
#endif