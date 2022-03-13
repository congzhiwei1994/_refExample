using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(SaveChildInfo))]
public class SaveChildInfoEditor : Editor
{
    private PCGDetailInfo pCGDetailInfo;
    private SaveChildInfo _target;
    private string dataPath;
    private List<DetailSingleType> tempData;
    private void OnEnable()
    {
        _target = (SaveChildInfo)target;
        tempData = new List<DetailSingleType>();
    }
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        EditorGUILayout.HelpBox("仅生产孙节点的数据！！",MessageType.Info);
        _target.DataSaveDir = EditorGUILayout.ObjectField("配置数据存放路径", _target.DataSaveDir, typeof(Object), true);
        if (GUILayout.Button("生成配置数据"))
        {
            tempData = _target.GetChildInfo();
            pCGDetailInfo = CreateInstance<PCGDetailInfo>();
            pCGDetailInfo.detailList = tempData;
            if (_target.DataSaveDir != null)
            {
                dataPath = AssetDatabase.GetAssetPath(_target.DataSaveDir)+"/";
                Debug.Log("数据存储路径：" + dataPath);
            }
            else
            {
                dataPath = "Assets/";
            }
            AssetDatabase.CreateAsset(pCGDetailInfo, dataPath + _target.DataSaveDir.name + "_PCGDetailInfo.asset");
            AssetDatabase.Refresh();
        }
        // if (pCGDetailInfo)
        // {
        //     EditorGUILayout.ObjectField("配置数据：", pCGDetailInfo, typeof(PCGDetailInfo), true);
        // }
        if(pCGDetailInfo)
        _target.CurrentPCGDetailInfo = EditorGUILayout.ObjectField("配置数据：", pCGDetailInfo, typeof(PCGDetailInfo), true) as PCGDetailInfo;
    }
}
