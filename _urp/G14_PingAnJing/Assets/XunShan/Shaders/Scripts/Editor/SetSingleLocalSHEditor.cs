using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor.Rendering;
using UnityEditor;
using UnityEngine.Rendering;

namespace ShaderLib
{
    [CustomEditor(typeof(SetSingleLocalSH))]
    public class SetSingleLocalSHEditor : Editor
    {
        //SerializedProperty m_TargetRenderer;
        //SerializedProperty m_TargetData;


        void OnEnable()
        {
            //var o = new PropertyFetcher<SetSingleLocalSH>(serializedObject);
            //m_TargetRenderer = o.Find(x => x.m_TargetRenderer);
            //m_TargetData = o.Find(x => x.m_TargetData);

            var data = target as SetSingleLocalSH;
            if (data != null)
            {
                data.m_TargetRenderer = data.gameObject.GetComponent<Renderer>();
            }
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            var data = target as SetSingleLocalSH;
            if (data == null)
            {
                return;
            }
            //var renderer = data.m_TargetRenderer;
            //if(renderer != null)
            //{
            //    if(renderer.lightProbeUsage != LightProbeUsage.CustomProvided)
            //    {
            //        EditorGUILayout.HelpBox("LightProbe未设置为：CustomProvided", MessageType.Warning);
            //        if(GUILayout.Button("设置CustomProvided"))
            //        {
            //            renderer.lightProbeUsage = LightProbeUsage.CustomProvided;
            //        }
            //    }
            //}

            GUILayout.Space(10f);

            if (GUILayout.Button("立即应用到Renderer Property"))
            {
                data.Apply();
            }
            if (GUILayout.Button("清空Renderer Property"))
            {
                data.Clear();
            }
        }
    }
}