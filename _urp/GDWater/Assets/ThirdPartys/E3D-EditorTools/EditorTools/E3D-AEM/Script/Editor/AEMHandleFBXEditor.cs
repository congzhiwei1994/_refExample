using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;

public class AEMHandleFBXEditor : EditorWindow
{
    private static AEMHandleFBXEditor m_window;

    [Tooltip("Root of FBX")]
    public UnityEngine.Object FBX;

    [Tooltip("Material Folder")]
    public UnityEngine.Object MaterialFolder;
    public Material[] matObjs;
    public UnityEngine.GameObject[] prefabObjs;
    public Dictionary<string, Material> matDic = new Dictionary<string, Material>();

    [Tooltip("Output Prefab Folder")]
    public UnityEngine.Object PrefabFolder;
    [Tooltip("Input Prefab Folder")]
    public UnityEngine.Object NewPrefabFolder;
    private string prefabSavePath;

    private string[] m_ToolbarChoices;
    private int m_ToolbarSelection = 0;


    [MenuItem("E3D-EditorTools/AEMHandleFBX")]
    public static void CombinerWindow()
    {
        m_window = (AEMHandleFBXEditor)EditorWindow.GetWindow(typeof(AEMHandleFBXEditor), false, "AEMHandleFBX");
        m_window.Show();
    }

    private void OnGUI()
    {
        m_ToolbarChoices = new string[] { "Prefab", "Material" };
        m_ToolbarSelection = GUILayout.Toolbar(m_ToolbarSelection, m_ToolbarChoices);
        if (m_ToolbarSelection == 0)
        {
            ExportPrefab();
        }
        else if (m_ToolbarSelection == 1)
        {
            ConnectMaterial();
        }
    }

    void ExportPrefab()
    {
        EditorGUILayout.BeginVertical();
        //======================================//
        FBX = EditorGUILayout.ObjectField("FBX:", FBX, typeof(UnityEngine.Object), true);
        PrefabFolder = EditorGUILayout.ObjectField("Prefab Folder:", PrefabFolder, typeof(UnityEngine.Object), true);
        //获得一个长500的框  
        //======================================//

        if (GUILayout.Button("Export"))
        {
            //===================================================//
            prefabSavePath = AssetDatabase.GetAssetPath(PrefabFolder);
            Debug.Log(prefabSavePath);
            if (FBX == null || prefabSavePath == "")
            {
                Debug.LogError("请检查输入内容是否完整");
                return;
            }
            //===================================================//
            float process = 0;
            int allLenth = 0;
            //===================================================//
            GameObject temp = FBX as GameObject;
            if (temp != null)
            {
                GameObject tt = Instantiate(temp) as GameObject;
                MeshRenderer[] ttRenderGroup = tt.transform.GetComponentsInChildren<MeshRenderer>();
                allLenth = ttRenderGroup.Length;
                //===============================================================//
                foreach (var item in ttRenderGroup)
                {
                    string jindu = string.Format("正在生成，请耐心等待，当前进度:{0}%", ((process / allLenth) * 100).ToString("0.00"));
                    string genPrefabFullName = string.Concat(prefabSavePath, "/", item.name, ".prefab");
                    Object prefabObj = PrefabUtility.CreateEmptyPrefab(genPrefabFullName);
                    GameObject prefab = PrefabUtility.ReplacePrefab(item.gameObject, prefabObj);
                    EditorUtility.DisplayCancelableProgressBar("生成进度条", jindu, process / allLenth);
                    process++;
                }
                EditorUtility.ClearProgressBar();
                GameObject.DestroyImmediate(tt);
            }

            AssetDatabase.Refresh();
        }
        //======================================//
        EditorGUILayout.EndVertical();
    }

    void ConnectMaterial()
    {
        EditorGUILayout.BeginVertical();
        //======================================//
        NewPrefabFolder = EditorGUILayout.ObjectField("Prefab Folder:", NewPrefabFolder, typeof(UnityEngine.Object), true);
        MaterialFolder = EditorGUILayout.ObjectField("Material Folder:", MaterialFolder, typeof(UnityEngine.Object), true);
        //获得一个长500的框  
        //======================================//
        if (GUILayout.Button("Connect"))
        {
            //===================================================//
            matDic.Clear();
            prefabSavePath = AssetDatabase.GetAssetPath(NewPrefabFolder);
            Debug.Log(prefabSavePath);
            if (prefabSavePath == "")
            {
                Debug.LogError("请检查输入内容是否完整");
                return;
            }
            //===============================================================//
            string matFolderPath;
            Material firstMat = null;//第一个材质
            if (MaterialFolder == null)
            {
                matFolderPath = prefabSavePath + "/Materials";
            }
            else
            {
                matFolderPath = AssetDatabase.GetAssetPath(MaterialFolder);
            }
            Debug.Log(matFolderPath);
            //===============================================================//
            if (matFolderPath.Contains("Resources"))
            {
                int matIndex = matFolderPath.IndexOf("Resources") + 10;
                matFolderPath = matFolderPath.Substring(matIndex);
                matFolderPath += "/";

                matObjs = Resources.LoadAll<Material>(matFolderPath);
                if (matObjs.Length > 0)
                {
                    //Debug.Log("Get Resource Objects Finish");
                    foreach (var item in matObjs)
                    {
                        if (!matDic.ContainsKey(item.name))
                        {
                            if (firstMat == null) firstMat = item;
                            matDic.Add(item.name, item);
                        }
                    }
                }
            }
            //===============================================================//
            string prefabFolderPath = AssetDatabase.GetAssetPath(NewPrefabFolder);
            if (prefabFolderPath.Contains("Resources"))
            {
                int index = prefabFolderPath.IndexOf("Resources") + 10;
                prefabFolderPath = prefabFolderPath.Substring(index);
                prefabFolderPath += "/";
                prefabObjs = Resources.LoadAll<GameObject>(prefabFolderPath);
            }
            //===============================================================//
            foreach (var item in prefabObjs)
            {
                if (matDic.Count > 0)
                {
                    var trans = item.transform.GetComponentsInChildren<Transform>();

                    if (matDic.ContainsKey(item.name))
                    {
                        Material newMat = matDic[item.name] as Material;
                        item.GetComponent<Renderer>().sharedMaterial = newMat;
                    }
                    else
                    {
                        item.GetComponent<Renderer>().sharedMaterial = firstMat as Material;
                    }

                    if (trans.Length > 0)
                    {
                        foreach (var tran in trans)
                        {
                            string childMatName = GetChildMat(tran.name);
                            if (childMatName != "")
                            {
                                Material newMat = matDic[childMatName] as Material;
                                tran.GetComponent<Renderer>().sharedMaterial = newMat;
                            }
                        }
                    }
                }
            }
        }
        EditorGUILayout.EndVertical();
    }



    string GetChildMat(string mat)
    {
        string[] split = mat.Split('-');

        if (matDic.ContainsKey(mat))
        {
            return mat;
        }
        else
        {
            string temp = split[0];//第二层
            temp = temp + "-" + 1;
            if (matDic.ContainsKey(temp))
            {
                return temp;
            }
            else
            {
                return "";
            }
        }
    }

}
