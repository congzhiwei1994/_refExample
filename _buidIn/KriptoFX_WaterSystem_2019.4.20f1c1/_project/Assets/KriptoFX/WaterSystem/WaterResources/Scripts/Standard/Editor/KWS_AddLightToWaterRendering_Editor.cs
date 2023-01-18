#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace KWS
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(KWS_AddLightToWaterRendering))]
    public class KWS_AddLightToWaterRendering_Editor : Editor
    {
        public override void OnInspectorGUI()
        {
            EditorGUILayout.Space();

            var s = (KWS_AddLightToWaterRendering)target;
            s.VolumetricLightRenderingMode = (KWS_WaterLights.VolumeLightRenderMode)EditorGUILayout.EnumPopup("Volumetric Mode", s.VolumetricLightRenderingMode);

            if (s.VolumetricLightRenderingMode == KWS_WaterLights.VolumeLightRenderMode.ShadowAndLight
                && s.currentLight != null && (s.currentLight.type == LightType.Directional || s.currentLight.type == LightType.Spot))
            {
                s.ShadowDownsample = (KWS_WaterLights.ShadowDownsampleEnum)EditorGUILayout.EnumPopup("Water Shadow Downasample", s.ShadowDownsample);
            }

            foreach (var obj in targets)
            {
                var selectedScript = (KWS_AddLightToWaterRendering)obj;
                selectedScript.VolumetricLightRenderingMode = s.VolumetricLightRenderingMode;
                selectedScript.ShadowDownsample = s.ShadowDownsample;
            }
        }
    }
}
#endif