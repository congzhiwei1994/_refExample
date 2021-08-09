using UnityEngine.Rendering.PostProcessing;

namespace UnityEditor.Rendering.PostProcessing
{
    [PostProcessEditor(typeof(PAJBloom))]
    internal sealed class PAJBloomEditor : PostProcessEffectEditor<PAJBloom>
    {
        SerializedParameterOverride m_Intensity;
        SerializedParameterOverride m_BlurSize;
        SerializedParameterOverride m_BloomUpScale;
        SerializedParameterOverride m_AnamorphicRatio;


        public override void OnEnable()
        {
            m_Intensity = FindParameterOverride(x => x.intensity);
            m_BlurSize = FindParameterOverride(x => x.blurSize);
            m_BloomUpScale = FindParameterOverride(x => x.bloomUpScale);
            m_AnamorphicRatio = FindParameterOverride(x => x.anamorphicRatio);

        }

        public override void OnInspectorGUI()
        {
            EditorUtilities.DrawHeaderLabel("PAJBloom");

            PropertyField(m_Intensity);
            PropertyField(m_BlurSize);
            PropertyField(m_BloomUpScale);
            PropertyField(m_AnamorphicRatio);
        }
    }
}
