using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(AEMSetting), true)]
public class AEMSettingEditor : AEMBaseEditor
{
    private AEMSetting _self;
    private void OnEnable()
    {
        base.OnEnable();
        _self = (AEMSetting)target;
    }

    public override void OnInspectorGUI()
    {
        this.DrawMonoScript();
        serializedObject.Update();

        _self.Data = EditorGUILayout.ObjectField("ESD-File:", _self.Data, typeof(UnityEngine.Object), true);
        _self.EAB_Name = EditorGUILayout.TextField("EAB-Name：", _self.EAB_Name);
        _self.UnitSize = EditorGUILayout.FloatField("UnitSize：", _self.UnitSize);
        _self.UnitHeight = EditorGUILayout.FloatField("UnitHeight：", _self.UnitHeight);
        _self.RemoveUnderUnit = EditorGUILayout.Toggle("RemoveUnderUnit：", _self.RemoveUnderUnit);
        _self.PrefabRoot = EditorGUILayout.ObjectField("PrefabRoot：", _self.PrefabRoot, typeof(UnityEngine.Object), true);
        _self.ColliderRoot = EditorGUILayout.ObjectField("ColliderRoot：", _self.ColliderRoot, typeof(UnityEngine.Object), true);

        if (GUILayout.Button("Build"))
        {
            _self.LoadDataEntrance();
            _self.LoadPrefabEntrance();
        }
        serializedObject.ApplyModifiedProperties();
    }
}
