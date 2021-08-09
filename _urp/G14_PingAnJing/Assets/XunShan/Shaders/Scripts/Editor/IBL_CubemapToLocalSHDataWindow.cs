using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace ShaderLib
{
    public class IBL_CubemapToLocalSHDataWindow : EditorWindow
    {
        private Cubemap targetCubemap;
        private LocalSHData targetSHData;

        [MenuItem("TA工具/IBL/Cubemap提取LocalSHData")]
        private static void DoMenu()
        {
            GetWindow<IBL_CubemapToLocalSHDataWindow>(true, "Cubemap提取LocalSHData", true);
        }

        private void OnEnable()
        {
            minSize = new Vector2(400f, 300f);
            maxSize = new Vector2(400f, 300f);
        }

        private void OnGUI()
        {
            targetCubemap = EditorGUILayout.ObjectField("原Cubemap", targetCubemap, typeof(Cubemap), false) as Cubemap;
            targetSHData = EditorGUILayout.ObjectField("目标数据", targetSHData, typeof(LocalSHData), false) as LocalSHData;
            if(targetSHData == null)
            {
                if (GUILayout.Button("创建SH数据"))
                {
                    var asset = LocalSHDataEditor.CreateLocalSHDataSelectPath();
                    if (asset != null)
                    {
                        targetSHData = asset;
                    }
                }
            }

            bool valid = false;
            if(targetCubemap != null && targetSHData != null)
            {
                valid = true;
            }


            GUILayout.FlexibleSpace();

            if(!valid)
            {
                EditorGUILayout.HelpBox("请设置好原数据和目标数据!", MessageType.Error);
            }
            EditorGUI.BeginDisabledGroup(!valid);
            if(GUILayout.Button("开始提取"))
            {
                SphericalHarmonicsL2 shData;
                PrefilterSH.PrefilterToSH(targetCubemap, out shData);
                if(targetSHData != null)
                {
                    targetSHData.lightProbe = shData;
                    targetSHData.occlusionProbe = Vector4.one;
                }
            }
            EditorGUI.EndDisabledGroup();
        }
    }
}