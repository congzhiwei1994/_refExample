#if UNITY_EDITOR
using UnityEditor;
using System.Linq;
using UnityEngine;

namespace KWS
{
    public partial class KWS_Editor
    {
        void CheckPlatformSpecificMessages()
        {
            CheckPlatformSpecificMessages_VolumeLight();
            CheckPlatformSpecificMessages_Reflection();
        }

        void CheckPlatformSpecificMessages_VolumeLight()
        {
            if (_waterSystem.UseVolumetricLight && KWS_WaterLights.Lights.Count == 0) EditorGUILayout.HelpBox("Water->'Volumetric lighting' doesn't work because no lights has been added for water rendering! Add the script 'AddLightToWaterRendering' to your light.", MessageType.Error);
        }

        void CheckPlatformSpecificMessages_Reflection()
        {
            if (_waterSystem.ReflectSun)
            {
                if (KWS_WaterLights.Lights.Count == 0 || KWS_WaterLights.Lights.Count(l => l.Light.type == LightType.Directional) == 0)
                {
                    EditorGUILayout.HelpBox("'Water->Reflection->Reflect Sunlight' doesn't work because no directional light has been added for water rendering! Add the script 'AddLightToWaterRendering' to your directional light!", MessageType.Error);
                }
            }

        }
    }

}
#endif