using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[CustomEditor(typeof(CreatColorMap))]
public class CreatColorMapEditor : Editor
{
    private CreatColorMap _target;
    private Texture2D _resultColorMap;
    void OnEnable()
    {
        _target = (CreatColorMap)target;
        _target.OnInit();
    }
    public override void OnInspectorGUI()
    {
        //base.OnInspectorGUI();
        _target.creatType = (CreatColorMap.CreatType)EditorGUILayout.EnumPopup("类型：", _target.creatType);
        _target.colorMapSize = (CreatColorMap.ColorMapSize)EditorGUILayout.EnumPopup("尺寸：", _target.colorMapSize);
        if (GUILayout.Button("创建ColorMap"))
        {
            _target.SetLight();
            _target.SetCamera();
            _target.GetCameraRenderTexture();
            _target.Reset();
            _resultColorMap = AssetDatabase.LoadAssetAtPath<Texture2D>(_target.savePath);
        }
        if (_resultColorMap)
        {
            _resultColorMap = EditorGUILayout.ObjectField(_resultColorMap, typeof(Texture2D), false, GUILayout.Width(150), GUILayout.Height(150))as Texture2D;
        }
    }
}
