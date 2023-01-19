using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
namespace SSS_utilities
{
    public static class Rendering
    {

        public static void RenderToTarget(Camera dest, RenderTexture targetTexture, Shader CameraShader)
        {
            dest.targetTexture = targetTexture;
            if (CameraShader != null)
                dest.RenderWithShader(CameraShader, "RenderType");
            else

                dest.Render();

        }
        

    }
    public static class Utilities
    {
#if UNITY_EDITOR
        public static void CreateLayer(string LayerName)
        {
            //  https://forum.unity3d.com/threads/adding-layer-by-script.41970/reply?quote=2274824
            SerializedObject tagManager = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
            SerializedProperty layers = tagManager.FindProperty("layers");
            bool ExistLayer = false;
            //print(ExistLayer);
            for (int i = 8; i < layers.arraySize; i++)
            {
                SerializedProperty layerSP = layers.GetArrayElementAtIndex(i);

                //print(layerSP.stringValue);
                if (layerSP.stringValue == LayerName)
                {
                    ExistLayer = true;
                    break;
                }

            }
            for (int j = 8; j < layers.arraySize; j++)
            {
                SerializedProperty layerSP = layers.GetArrayElementAtIndex(j);
                if (layerSP.stringValue == "" && !ExistLayer)
                {
                    layerSP.stringValue = LayerName;
                    tagManager.ApplyModifiedProperties();

                    break;
                }
            }

            // print(layers.arraySize);
        }
#endif
    }
}
