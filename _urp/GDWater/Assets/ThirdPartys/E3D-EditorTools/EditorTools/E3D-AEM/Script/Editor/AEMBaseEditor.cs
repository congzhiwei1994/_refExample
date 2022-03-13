using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class AEMBaseEditor : Editor
{
    protected SerializedObject serializedTarget;
    protected UnityEngine.Object monoScript;
    protected virtual void OnEnable()
    {
        this.serializedTarget = new SerializedObject(this.target);
        this.monoScript = MonoScript.FromMonoBehaviour(this.target as MonoBehaviour);
    }
    protected void DrawMonoScript()
    {
        EditorGUI.BeginDisabledGroup(true);
        EditorGUILayout.ObjectField("Script", this.monoScript, typeof(MonoScript), false);
        EditorGUI.EndDisabledGroup();
    }
}
