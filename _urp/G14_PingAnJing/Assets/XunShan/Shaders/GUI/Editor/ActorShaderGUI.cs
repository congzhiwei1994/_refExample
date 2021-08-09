using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace ShaderEditor
{
    internal class ActorShaderGUI : BaseShaderGUI, PBRGUI.CustomInterface, ActorGUI.CustomInterface
    {
        private class Styles
        {
            public static readonly GUIContent ActorOptionsText =
              new GUIContent("Actor选项", "");

            public static readonly GUIContent MixMapText =
             new GUIContent($"{PBRGUI.Styles.MixMapText.text} (R:金属度 B:粗糙度)", PBRGUI.Styles.MixMapText.tooltip);

            public static readonly GUIContent NormalMapText =
              new GUIContent($"{PBRGUI.Styles.NormalMapText.text} (RG:法线 B:AO)", PBRGUI.Styles.NormalMapText.tooltip);

            public static readonly GUIContent AOBiasTipText =
             new GUIContent("AO偏移说明 0=在掠角处减弱AO 1=正常AO");

            public static readonly GUIContent EmissiveTipText =
             new GUIContent("BaseMap的Alph通道 50-100%灰度值为自发光值");
        }

      
        SavedBool m_ActorOptionsFoldout;

        // Properties
        private PBRGUI.Properties m_PBRProperties;
        private ActorGUI.Properties m_ActorProperties;


        #region 子类定制重写

        protected override bool IsFixedRenderFace()
        {
            return true;
        }

        protected override RenderFace GetFixedRenderFace()
        {
            return RenderFace.Front;
        }

        #endregion


        // collect properties from the material properties
        protected override void InitProperties(MaterialProperty[] properties)
        {
            base.InitProperties(properties);
            m_ActorProperties = new ActorGUI.Properties(properties);
            m_PBRProperties = new PBRGUI.Properties(properties);
        }

        protected override void OnOpenGUI(Material material, MaterialEditor materialEditor)
        {
            base.OnOpenGUI(material, materialEditor);

            m_ActorOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.ActorOptionsFoldout", true);

        }

        // material changed check
        protected override void MaterialChanged(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            DoCheckMaterial();

            BaseShaderGUI.SetMaterialKeywords(material,
                PBRGUI.SetMaterialKeywords,
                ActorGUI.SetMaterialKeywords);
        }

        /// <summary>
        /// 在SurfaceOptions之前的界面
        /// </summary>
        /// <param name="material"></param>
        protected override void DrawBeforeSurfaceOptions(Material material)
        {
            m_ActorOptionsFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_ActorOptionsFoldout.value, Styles.ActorOptionsText);
            if (m_ActorOptionsFoldout.value)
            {
                ActorGUI.DrawActorOptions(m_ActorProperties, materialEditor, material, this);
                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        

        // material main surface inputs
        protected override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);

            PBRGUI.DrawInputs(this, m_PBRProperties, material, this);
            ActorGUI.DrawInputs(this, m_ActorProperties, material);
            DrawEmissionProperties(material, true);
        }

        /// <summary>
        /// 做一些检查
        /// </summary>
        protected void DoCheckMaterial()
        {
        }

        #region ActorGUI.CustomInterface

        void ActorGUI.CustomInterface.OnSelectMaterialType(ActorGUI.MaterialType type)
        {
            switch (type)
            {
                case ActorGUI.MaterialType.Universal:
                    BaseShaderGUI.SetMaterialPropertyEnum(m_ActorProperties._INTR_AnisoType, ActorGUI.SSSType.Use);
                    BaseShaderGUI.SetMaterialPropertyEnum(m_ActorProperties._INTR_SSSType, ActorGUI.SSSType.Use);
                    BaseShaderGUI.SetMaterialPropertyEnum(m_PBRProperties._INTR_AO, PBRGUI.AOType.Use);
                    break;
                case ActorGUI.MaterialType.Eye:
                    BaseShaderGUI.SetMaterialPropertyEnum(m_ActorProperties._INTR_AnisoType, ActorGUI.SSSType.NotUse);
                    BaseShaderGUI.SetMaterialPropertyEnum(m_ActorProperties._INTR_SSSType, ActorGUI.SSSType.NotUse);
                    BaseShaderGUI.SetMaterialPropertyEnum(m_PBRProperties._INTR_AO, PBRGUI.AOType.NotUse);
                    break;
            }

        }

        #endregion

        #region PBRGUI.CustomInterface

        GUIContent PBRGUI.CustomInterface.GetMixMapText()
        {
            return Styles.MixMapText;
        }

        GUIContent PBRGUI.CustomInterface.GetNormalMapText()
        {
            return Styles.NormalMapText;
        }

        GUIContent PBRGUI.CustomInterface.GetAOBiasTipText()
        {
            return Styles.AOBiasTipText;
        }

        GUIContent PBRGUI.CustomInterface.GetEmissiveTipText(PBRGUI.EmissiveType type)
        {
            if(type == PBRGUI.EmissiveType.NotUse)
            {
                return null;
            }
            return Styles.EmissiveTipText;
        }

        #endregion
    }
}