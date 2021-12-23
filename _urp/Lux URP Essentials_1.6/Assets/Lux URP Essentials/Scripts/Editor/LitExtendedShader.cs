using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor.Rendering.Universal;

namespace UnityEditor.Rendering.URP.ShaderGUI
{
    internal class LitExtendedShader : BaseShaderGUI
    {
        // Properties
        private UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.LitProperties litProperties;
        
        // collect properties from the material properties
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            litProperties = new UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.LitProperties(properties);
        }

        // material changed check
        public override void MaterialChanged(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");
            
            SetMaterialKeywords(material, UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.SetMaterialKeywords);
        }
        
        // material main surface options
        public override void DrawSurfaceOptions(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            if (litProperties.workflowMode != null)
            {
                DoPopup(UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.Styles.workflowModeText, litProperties.workflowMode, Enum.GetNames(typeof(UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.WorkflowMode)));
            }
            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in blendModeProp.targets)
                    MaterialChanged((Material)obj);
            }

        //  The missing piece here
            EditorGUI.BeginChangeCheck();

            base.DrawSurfaceOptions(material);

        //  The missing piece here... otherwise changes made above would not be applied?!
            if (EditorGUI.EndChangeCheck()) {
                MaterialChanged(material);
            }

        //  Lux URP Essentials add ons
            GUILayout.Space(10);
            EditorGUILayout.LabelField("Advanced Options", EditorStyles.boldLabel);
            EditorGUI.BeginChangeCheck();

            var zTest = (CompareFunction)material.GetInt("_ZTest");
            zTest = (UnityEngine.Rendering.CompareFunction) EditorGUILayout.EnumPopup("ZTest", zTest);


            var stencil = material.GetInt("_Stencil");
            stencil = EditorGUILayout.IntSlider("Stencil Reference", stencil, 0, 255);

            var readMask = material.GetInt("_ReadMask");
            readMask = EditorGUILayout.IntSlider("    Read Mask", readMask, 0, 255);

            var writeMask = material.GetInt("_WriteMask");
            writeMask = EditorGUILayout.IntSlider("    Write Mask", writeMask, 0, 255);

            UnityEngine.Rendering.CompareFunction stencilComp = (CompareFunction)material.GetFloat("_StencilComp");
            stencilComp = (UnityEngine.Rendering.CompareFunction) EditorGUILayout.EnumPopup("Stencil Comparison", stencilComp);

            UnityEngine.Rendering.StencilOp stencilOp = (UnityEngine.Rendering.StencilOp)material.GetFloat("_StencilOp");
            stencilOp = (UnityEngine.Rendering.StencilOp)EditorGUILayout.EnumPopup("Stencil Pass Op", stencilOp);

            UnityEngine.Rendering.StencilOp stencilFail = (UnityEngine.Rendering.StencilOp)material.GetFloat("_StencilFail");
            stencilFail = (UnityEngine.Rendering.StencilOp)EditorGUILayout.EnumPopup("Stencil Fail Op", stencilFail);

            UnityEngine.Rendering.StencilOp stencilZFail = (UnityEngine.Rendering.StencilOp)material.GetFloat("_StencilZFail");
            stencilZFail = (UnityEngine.Rendering.StencilOp)EditorGUILayout.EnumPopup("Stencil Z Fail Op", stencilZFail);

            if (EditorGUI.EndChangeCheck()) {
                material.SetInt("_ZTest", (int)zTest);
                material.SetInt("_Stencil", stencil);
                material.SetInt("_ReadMask", readMask);
                material.SetInt("_WriteMask", writeMask);
                material.SetInt("_StencilComp", (int)stencilComp);
                material.SetInt("_StencilOp", (int)stencilOp);
                material.SetInt("_StencilFail", (int)stencilFail);
                material.SetInt("_StencilZFail", (int)stencilZFail);
            }
        }

        // material main surface inputs
        public override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);
            UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.Inputs(litProperties, materialEditor, material);
            DrawEmissionProperties(material, true);
            DrawTileOffset(materialEditor, baseMapProp);

        //  Lux URP Add Ons
            GUILayout.Space(10);
            EditorGUILayout.LabelField("Advanced Options", EditorStyles.boldLabel);
            EditorGUI.BeginChangeCheck();

            var enableRim = material.GetFloat("_Rim");
            var b_enableRim = (enableRim == 0.0) ? false : true;
            b_enableRim = EditorGUILayout.Toggle("Enable Rim Lighting", b_enableRim);

            var rimColor = material.GetColor("_RimColor");
            rimColor = EditorGUILayout.ColorField("Rim Color", rimColor);

            var rimPower = material.GetFloat("_RimPower");
            rimPower = EditorGUILayout.FloatField("Rim Power", rimPower);

            var rimFrequency = material.GetFloat("_RimFrequency");
            rimFrequency = EditorGUILayout.Slider("Rim Frequency", rimFrequency, 0.0f, 20.0f);

            var rimMinPower = material.GetFloat("_RimMinPower");
            rimMinPower = EditorGUILayout.FloatField("    Rim Min Power", rimMinPower);

            var rimPerPositionFrequency = material.GetFloat("_RimPerPositionFrequency");
            rimPerPositionFrequency = EditorGUILayout.Slider("    Rim Per Position Frequency", rimPerPositionFrequency, 0.0f, 1.0f);

            if (EditorGUI.EndChangeCheck()) {
               if(b_enableRim) {
                    material.SetFloat("_Rim", 1.0f);
               }
               else {
                    material.SetFloat("_Rim", 0.0f);
               }

               material.SetColor("_RimColor", rimColor);
               material.SetFloat("_RimPower", rimPower);
               material.SetFloat("_RimMinPower", rimMinPower);
               material.SetFloat("_RimFrequency", rimFrequency);
               material.SetFloat("_RimPerPositionFrequency", rimPerPositionFrequency); 
            }
            CoreUtils.SetKeyword(material, "_RIMLIGHTING", b_enableRim);
        }

        // material main advanced options
        public override void DrawAdvancedOptions(Material material)
        {
            if (litProperties.reflections != null && litProperties.highlights != null)
            {
                EditorGUI.BeginChangeCheck();
                {
                    materialEditor.ShaderProperty(litProperties.highlights, UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.Styles.highlightsText);
                    materialEditor.ShaderProperty(litProperties.reflections, UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.Styles.reflectionsText);
                    EditorGUI.BeginChangeCheck();
                }
            }

            base.DrawAdvancedOptions(material);
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            // _Emission property is lost after assigning Standard shader to the material
            // thus transfer it before assigning the new shader
            if (material.HasProperty("_Emission"))
            {
                material.SetColor("_EmissionColor", material.GetColor("_Emission"));
            }

            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
            {
                SetupMaterialBlendMode(material);
                return;
            }

            SurfaceType surfaceType = SurfaceType.Opaque;
            BlendMode blendMode = BlendMode.Alpha;
            if (oldShader.name.Contains("/Transparent/Cutout/"))
            {
                surfaceType = SurfaceType.Opaque;
                material.SetFloat("_AlphaClip", 1);
            }
            else if (oldShader.name.Contains("/Transparent/"))
            {
                // NOTE: legacy shaders did not provide physically based transparency
                // therefore Fade mode
                surfaceType = SurfaceType.Transparent;
                blendMode = BlendMode.Alpha;
            }
            material.SetFloat("_Surface", (float)surfaceType);
            material.SetFloat("_Blend", (float)blendMode);

            if (oldShader.name.Equals("Standard (Specular setup)"))
            {
                material.SetFloat("_WorkflowMode", (float)UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.WorkflowMode.Specular);
                Texture texture = material.GetTexture("_SpecGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }
            else
            {
                material.SetFloat("_WorkflowMode", (float)UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.WorkflowMode.Metallic);
                Texture texture = material.GetTexture("_MetallicGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }

            MaterialChanged(material);
        }
    }
}
