using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor.Rendering;
using UnityEditor;
using UnityEngine.Rendering;

namespace ShaderLib
{
    [CustomEditor(typeof(SetChildrenLocalSH))]
    public class SetChildrenLocalSHEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            var data = target as SetChildrenLocalSH;
            if (data == null)
            {
                return;
            }
           
            GUILayout.Space(10f);

            if (GUILayout.Button("立即应用到Renderer Property"))
            {
                data.ApplyAll();
            }
            if (GUILayout.Button("清空Renderer Property"))
            {
                data.ClearAll();
            }
        }
    }
}