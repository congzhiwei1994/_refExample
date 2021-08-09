using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(SameView), true)]
public class SameViewEditor : SameViewBaseEditor
{
    private SameView _self;
    void OnEnable()
    {
        base.OnEnable();
        _self = (SameView)target;
        //EditorApplication.update += SameViewCore;//20200810
    }

    public override void OnInspectorGUI()
    {
        //================================================================//
        this.DrawMonoScript();
        serializedObject.Update();
        _self.SameViewOn = EditorGUILayout.Toggle("Same View：", _self.SameViewOn);
        //================================================================//
        if (_self.SameViewOn)
        {
            EditorApplication.update += SameViewCore;
        }
        else
        {
            EditorApplication.update -= SameViewCore;
        }
        //================================================================//
    }

    public void OnDisable()
    {
        //EditorApplication.update -= SameViewCore;//20200810
    }

    public void OnDestroy()
    {
        //EditorApplication.update -= SameViewCore;//20200810
    }

    void SameViewCore()
    {
        if(_self.SameViewOn)
        {
            Camera.main.transform.position = SceneView.lastActiveSceneView.camera.transform.position;
            Camera.main.transform.rotation = SceneView.lastActiveSceneView.camera.transform.rotation;
            //Debug.Log("尺寸:"+SceneView.currentDrawingSceneView.size);
        }
    }
}
public class SameViewBaseEditor : Editor
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