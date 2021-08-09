using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(E3DBatchCapture), true)]
public class E3DBatchCaptureEditor : E3DBatchCaptureBaseEditor
{
    private E3DBatchCapture _self;
    private void OnEnable()
    {
        base.OnEnable();
        _self = (E3DBatchCapture)target;
    }

    public override void OnInspectorGUI()
    {
        this.DrawMonoScript();
        serializedObject.Update();

        _self.InputFolder = EditorGUILayout.ObjectField("Input-Folder:", _self.InputFolder, typeof(UnityEngine.Object), true);
        _self.property = EditorGUILayout.TextField("Property：", _self.property);
        _self.OutputFolder = EditorGUILayout.ObjectField("Output-Folder：", _self.OutputFolder, typeof(UnityEngine.Object), true);

        if (GUILayout.Button("Build"))
        {
            _self.InputEntrance();
            _self.OutputEntrance();
        }

        serializedObject.ApplyModifiedProperties();
    }
}
public class E3DBatchCaptureBaseEditor : Editor
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