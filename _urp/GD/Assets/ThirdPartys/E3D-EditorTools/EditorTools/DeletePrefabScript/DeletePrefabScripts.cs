using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;


public class DeletePrefabScripts
{
    static void DeleteScriptsExtension(bool miss)
    {
        string[] filePaths = Directory.GetFiles(Application.dataPath, "*.prefab", SearchOption.AllDirectories);
        int sum = 0;
        for (int i = 0; i < filePaths.Length; i++)
        {
            string path = filePaths[i].Replace(Application.dataPath, "Assets");
            GameObject objPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            GameObject obj = PrefabUtility.InstantiatePrefab(objPrefab) as GameObject;
            //判断是否存在于Hierarchy面板上
            if (obj.hideFlags == HideFlags.None && obj.scene.path != null)
            {
                var components = obj.GetComponents<Component>();
                SerializedObject so = new SerializedObject(obj);
                var soProperties = so.FindProperty("m_Component");
                int r = 0;
                for (int j = 0; j < components.Length; j++)
                {
                    if (components[j] == null)
                    {
                        soProperties.DeleteArrayElementAtIndex(j - r);
                        Debug.LogError("清除了物体：" + obj.name + " 的一个missing脚本");
                        r++;
                    }
                }
                if (r > 0)
                {
                    so.ApplyModifiedProperties();
                    //PrefabUtility.SaveAsPrefabAssetAndConnect(obj, path, InteractionMode.AutomatedAction);
                    PrefabUtility.ReplacePrefab(obj, objPrefab);
                    AssetDatabase.Refresh();
                }
                sum += r;
                UnityEngine.Object.DestroyImmediate(obj);
            }

        }
        Debug.LogError("清除完成,清理个数：" + sum);
    }

    [MenuItem("E3D-EditorTools/Scripts/Delete Select Scripts")]
    public static void DeleteSelectScripts()
    {
        //获取选中的gameobject对象
        GameObject[] selectedsGameobject = Selection.gameObjects;

        for (int i = 0; i < selectedsGameobject.Length; i++)
        {
            GameObject obj = selectedsGameobject[i];

            UnityEngine.Object newsPref = PrefabUtility.GetPrefabObject(obj);

            //判断选择的物体，是否为预设
            if (PrefabUtility.GetPrefabType(obj) == PrefabType.PrefabInstance)
            {
                UnityEngine.Object parentObject = PrefabUtility.GetPrefabParent(obj);
                //==========================================================================//
                //获取路径
                string path = AssetDatabase.GetAssetPath(parentObject);
                Debug.Log("Path:" + path);
                Transform[] trans = obj.GetComponentsInChildren<Transform>();
                for (int j = 0; j < trans.Length; j++)
                {
                    Debug.Log("Tran:" + trans[j]);
                    GameObject item = trans[j].gameObject;
                    var components = item.GetComponents<MonoBehaviour>();
                    foreach (var c in components)
                    {
                        Debug.Log("Mono:" + c);
                        GameObject.DestroyImmediate(c);
                    }
                }
            }
        }
    }

    [MenuItem("E3D-EditorTools/Scripts/Cleanup Missing Scripts")]
    public static void RemoveAllMissingScript()
    {
        var gos = GameObject.FindObjectsOfType<GameObject>();
        foreach (var item in gos)
        {
            Debug.Log(item.name);
            SerializedObject so = new SerializedObject(item);
            var soProperties = so.FindProperty("m_Component");
            var components = item.GetComponents<Component>();
            int propertyIndex = 0;
            foreach (var c in components)
            {
                if (c == null)
                {
                    soProperties.DeleteArrayElementAtIndex(propertyIndex);
                }
                ++propertyIndex;
            }
            so.ApplyModifiedProperties();
        }
        AssetDatabase.Refresh();

        Debug.Log("清理无效完成!");
    }

    [MenuItem("E3D-EditorTools/Scripts/Delete Select Scripts(Update Preafab)")]
    public static void DeleteSelectScriptsUpdatePefab()
    {
        //获取选中的gameobject对象
        GameObject[] selectedsGameobject = Selection.gameObjects;
        GameObject prefab = PrefabUtility.FindPrefabRoot(selectedsGameobject[0]);

        for (int i = 0; i < selectedsGameobject.Length; i++)
        {
            GameObject obj = selectedsGameobject[i];

            UnityEngine.Object newsPref = PrefabUtility.GetPrefabObject(obj);

            //判断选择的物体，是否为预设
            if (PrefabUtility.GetPrefabType(obj) == PrefabType.PrefabInstance)
            {
                UnityEngine.Object parentObject = PrefabUtility.GetPrefabParent(obj);
                //==========================================================================//
                //获取路径
                string path = AssetDatabase.GetAssetPath(parentObject);
                Debug.Log("Path:" + path);
                Transform[] trans = obj.GetComponentsInChildren<Transform>();
                for (int j = 0; j < trans.Length; j++)
                {
                    Debug.Log("Tran:" + trans[j]);
                    GameObject item = trans[j].gameObject;
                    var components = item.GetComponents<MonoBehaviour>();
                    foreach (var c in components)
                    {
                        Debug.Log("Mono:" + c);
                        GameObject.DestroyImmediate(c);
                    }
                }
                //==========================================================================//
                //替换预设
                PrefabUtility.ReplacePrefab(obj, parentObject, ReplacePrefabOptions.ConnectToPrefab);
                //刷新
                AssetDatabase.Refresh();
            }
        }
    }

}
