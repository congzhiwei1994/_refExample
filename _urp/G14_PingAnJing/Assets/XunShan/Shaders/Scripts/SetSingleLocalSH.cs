using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderLib
{
    [RequireComponent(typeof(Renderer))]
    public class SetSingleLocalSH : MonoBehaviour
    {
        private static MaterialPropertyBlock s_MPB;
        private readonly static SphericalHarmonicsL2[] s_TempLightProbeArray = new SphericalHarmonicsL2[1];
        private readonly static Vector4[] s_TempOcclusionProbeArray = new Vector4[1];

        public enum WhenSet
        {
            [InspectorName("手动")]
            Manual,

            [InspectorName("Start调用时")]
            Start,

            [InspectorName("每帧(性能消耗)")]
            EveryFrame,
        }

        [SerializeField]
        public Renderer m_TargetRenderer;
        [SerializeField]
        public LocalSHData m_TargetData;
        [SerializeField]
        public WhenSet m_WhenSet;


        private void Start()
        {
            if (m_WhenSet == WhenSet.Start)
            {
                Apply();
            }
        }

        private void Update()
        {
            if (m_WhenSet == WhenSet.EveryFrame)
            {
                Apply();
            }
        }

        public void Apply()
        {
            if (m_TargetRenderer != null && m_TargetData != null)
            {
                ApplySHToRenderer(m_TargetRenderer, m_TargetData);
            }
        }

        public void Clear()
        {
            if (m_TargetRenderer != null)
            {
                ClearSHToRenderer(m_TargetRenderer);
            }
        }

        public static void ClearSHToRenderer(Renderer targetRenderer)
        {
            if (targetRenderer == null)
            {
                return;
            }

            if (s_MPB == null)
            {
                s_MPB = new MaterialPropertyBlock();
            }
            s_MPB.Clear();
            //if (targetRenderer.HasPropertyBlock())
            //{
            //    targetRenderer.GetPropertyBlock(s_MPB);
            //}
            //s_TempLightProbeArray[0] = new SphericalHarmonicsL2();
            //s_TempOcclusionProbeArray[0] = Vector4.zero;
            //s_MPB.CopySHCoefficientArraysFrom(s_TempLightProbeArray);
            //s_MPB.CopyProbeOcclusionArrayFrom(s_TempOcclusionProbeArray);
            targetRenderer.SetPropertyBlock(s_MPB);
            s_MPB.Clear();
        }

        /// <summary>
        /// 应用数据
        /// </summary>
        /// <param name="targetRenderer"></param>
        /// <param name="targetData"></param>
        public static void ApplySHToRenderer(Renderer targetRenderer, LocalSHData targetData)
        {
            if(targetRenderer == null)
            {
                return;
            }
            if(targetData == null)
            {
                return;
            }
            if(s_MPB == null)
            {
                s_MPB = new MaterialPropertyBlock();
            }
            s_MPB.Clear();
            if (targetRenderer.HasPropertyBlock())
            {
                targetRenderer.GetPropertyBlock(s_MPB);
            }
            s_TempLightProbeArray[0] = targetData.lightProbe;
            s_TempOcclusionProbeArray[0] = targetData.occlusionProbe;
            s_MPB.CopySHCoefficientArraysFrom(s_TempLightProbeArray);
            s_MPB.CopyProbeOcclusionArrayFrom(s_TempOcclusionProbeArray);
            targetRenderer.SetPropertyBlock(s_MPB);
            s_MPB.Clear();
        }
    }
}
