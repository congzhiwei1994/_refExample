using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;


public class E3DCombinerEditor : EditorWindow
{
    private static E3DCombinerEditor m_window;

    #region Field and Property 

    #region Common Property
    private string[] m_ToolbarChoices;
    private int m_ToolbarSelection = 0;
    #endregion

    #region Mesh Property

    public GameObject meshRoot;

    public GameObject meshSave;
    //===============================//

    Rect meshSaveRect;
    public int lightmapIndex = -1;

    public bool debug = false;
    //材质分类
    Dictionary<Material, List<GameObject>> materialDirectory = new Dictionary<Material, List<GameObject>>();
    //网格定点分类
    List<GameObject> newBranchList = new List<GameObject>();
    //===============================//
    #endregion

    #region Collider Property

    public GameObject colliderRoot;

    public GameObject materialRoot;

    public GameObject colliderSave;

    #endregion

    #endregion

    #region GUI
    [MenuItem("E3D-EditorTools/Combiner")]
    public static void CombinerWindow()
    {
        m_window = (E3DCombinerEditor)EditorWindow.GetWindow(typeof(E3DCombinerEditor), false, "E3DCombiner");
        m_window.Show();
    }

    private void OnGUI()
    {
        m_ToolbarChoices = new string[] { "Separate Collider", "Sort Materials", "Combine Mesh" };
        m_ToolbarSelection = GUILayout.Toolbar(m_ToolbarSelection, m_ToolbarChoices);
        if (m_ToolbarSelection == 0)
        {
            SeparateColliderGUI();
        }
        else if (m_ToolbarSelection == 1)
        {
            SortMaterialsGUI();
        }
        else if (m_ToolbarSelection == 2)
        {
            CombineMeshGUI();
        }

        newBranchList.Clear();
        materialDirectory.Clear();
    }

    private void SeparateColliderGUI()
    {
        EditorGUILayout.BeginVertical();
        //======================================//
        colliderRoot = (GameObject)EditorGUILayout.ObjectField("Target:", colliderRoot, typeof(GameObject), true);
        //======================================//
        if (GUILayout.Button("Separate"))
        {
            if (colliderRoot is GameObject)
            {
                CombinerCollider();
            }
            else
            {
                this.ShowNotification(new GUIContent("Target is null"));
            }

        }
        //======================================//
        EditorGUILayout.EndVertical();
    }

    private void SortMaterialsGUI()
    {
        EditorGUILayout.BeginVertical();
        //======================================//
        materialRoot = (GameObject)EditorGUILayout.ObjectField("Target:", materialRoot, typeof(GameObject), true);
        //======================================//
        if (GUILayout.Button("Sort"))
        {
            if (materialRoot is GameObject)
            {
                SortMeshByMaterial();
            }
            else
            {
                this.ShowNotification(new GUIContent("Target is null"));
            }
        }
        //======================================//
        EditorGUILayout.EndVertical();
    }

    private void CombineMeshGUI()
    {
        EditorGUILayout.BeginVertical();
        meshRoot = (GameObject)EditorGUILayout.ObjectField("Target:", meshRoot, typeof(GameObject), true);

        if (GUILayout.Button("Combine"))
        {
            if (meshRoot is GameObject)
            {
                CleanUselessMesh();

                if (CheckBranchIsGood(meshRoot))
                {
                    NoGetBranch();
                }
                else
                {
                    GetBranch(meshRoot);
                }

                CreatMeshPrefab();
            }
            else
            {
                this.ShowNotification(new GUIContent("Target is null"));
            }
        }
        EditorGUILayout.EndVertical();
    }


    #endregion

    #region Common Method
    static bool Compare(Material m1, Material m2)
    {
        EditorSettings.serializationMode = SerializationMode.ForceText;
        string m1Path = AssetDatabase.GetAssetPath(m1);
        string m2Path = AssetDatabase.GetAssetPath(m2);


        if (!string.IsNullOrEmpty(m1Path) && !string.IsNullOrEmpty(m2Path))
        {
            string rootPath = Directory.GetCurrentDirectory();
            m1Path = Path.Combine(rootPath, m1Path);
            m2Path = Path.Combine(rootPath, m2Path);

            string text1 = File.ReadAllText(m1Path).Replace(" m_Name: " + m1.name, "");
            string text2 = File.ReadAllText(m2Path).Replace(" m_Name: " + m2.name, "");
            return (text1 == text2);
        }
        return false;
    }

    static void DeleteSameMaterial()
    {
        Dictionary<string, string> dicMaterial = new Dictionary<string, string>();
        MeshRenderer[] meshRenderers = Resources.FindObjectsOfTypeAll<MeshRenderer>();
        string rootPath = Directory.GetCurrentDirectory();
        for (int i = 0; i < meshRenderers.Length; i++)
        {
            MeshRenderer meshRender = meshRenderers[i];
            Material[] newMaterials = new Material[meshRender.sharedMaterials.Length];
            for (int j = 0; j < meshRender.sharedMaterials.Length; j++)
            {
                Material m = meshRender.sharedMaterials[j];

                string mPath = AssetDatabase.GetAssetPath(m);
                if (!string.IsNullOrEmpty(mPath) && mPath.Contains("Assets/"))
                {
                    string fullPath = Path.Combine(rootPath, mPath);
                    string text = File.ReadAllText(fullPath).Replace(" m_Name: " + m.name, "");

                    string change;
                    if (!dicMaterial.TryGetValue(text, out change))
                    {
                        dicMaterial[text] = mPath;
                        change = mPath;
                    }
                    newMaterials[j] = AssetDatabase.LoadAssetAtPath<Material>(change);
                }
            }
            meshRender.sharedMaterials = newMaterials;
        }
    }

    static Vector3 GetCenter(Component[] components)
    {
        if (components != null && components.Length > 0)
        {
            Vector3 min = components[0].transform.position;
            Vector3 max = min;
            foreach (var comp in components)
            {
                min = Vector3.Min(min, comp.transform.position);
                max = Vector3.Max(max, comp.transform.position);
            }
            return min + ((max - min) / 2);
        }
        return Vector3.zero;
    }

    //================去除所有的预制的关联==================//
    static GameObject HandleColliderPrefabToGameObject(GameObject gameObject)
    {
        GameObject root = GameObject.Instantiate(gameObject);
        root.name = gameObject.name;
        var colliders = root.GetComponentsInChildren<Collider>();
        foreach (var col in colliders)
        {
#if UNITY_5 || UNITY_5_0 || UNITY_2017
            if (col.gameObject.scene.IsValid())
            {
                PrefabUtility.DisconnectPrefabInstance(col);
            }

#else   //UNITY_2018_3_OR_NEWER
    if (PrefabUtility.IsPartOfAnyPrefab(col))
    {
        PrefabUtility.DisconnectPrefabInstance(col);
    }   
#endif
        }
        return root;
    }

    static GameObject HandleMeshPrefabToGameObject(GameObject gameObject)
    {
        GameObject root = GameObject.Instantiate(gameObject);
        root.name = gameObject.name;
        var meshFilters = root.GetComponentsInChildren<MeshFilter>();
        foreach (var mesh in meshFilters)
        {
#if UNITY_5 || UNITY_5_0 || UNITY_2017
            if (mesh.gameObject.scene.IsValid())
            {
                PrefabUtility.DisconnectPrefabInstance(mesh);
            }

#else   //UNITY_2018_3_OR_NEWER
            if (PrefabUtility.IsPartOfAnyPrefab(mesh))
            {
                PrefabUtility.DisconnectPrefabInstance(mesh);
            } 
#endif
        }
        //============================ClearUselessMesh==================================//
        meshFilters = root.GetComponentsInChildren<MeshFilter>();//refresh
        for (int i = 0; i < meshFilters.Length; i++)
        {
            var obj = meshFilters[i].gameObject;
            var mr = obj.GetComponent<MeshRenderer>();
            if (mr == null || mr.enabled == false || meshFilters[i].sharedMesh == null)
            {
                var col = obj.GetComponent<Collider>();
                if (col) DestroyImmediate(col);
                DestroyImmediate(meshFilters[i]);
                if (mr) DestroyImmediate(mr);
            }
        }
        //============================ClearUselessMesh==================================//
        return root;
    }


    //======================================================//

    static void CreatePrefab(GameObject obj, string localPath)
    {
        Object prefab = EditorUtility.CreateEmptyPrefab(localPath);
        EditorUtility.ReplacePrefab(obj, prefab);
        AssetDatabase.Refresh();

        DestroyImmediate(obj);
        GameObject clone = EditorUtility.InstantiatePrefab(prefab) as GameObject;
    }

    //======================================================//
    #region Mesh
    static bool CheckBranchIsGood(GameObject obj)
    {
        int vertexCount = 0;
        var meshFilters = obj.GetComponentsInChildren<MeshFilter>();
        for (int i = 0; i < meshFilters.Length; ++i)
        {
            if (meshFilters[i].GetComponent<MeshFilter>())
                vertexCount += meshFilters[i].sharedMesh.vertexCount;
        }
        if (vertexCount < 65535)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    void GetBranch(GameObject root)
    {
        var branchCount = root.transform.childCount;
        //Debug.Log("分支:" + branchCount);

        for (int i = 0; i < branchCount; i++)
        {
            var childObj = root.transform.GetChild(i).gameObject;
            if (CheckBranchIsGood(childObj))
            {
                CombineMesh(childObj, meshSave);
            }
            else
            {
                GetBranch(childObj);
            }
        }
    }

    void NoGetBranch()
    {
        if (debug)
        {
            CombineMesh(meshRoot, meshSave);
        }
        else
        {
            var branchCount = meshRoot.transform.childCount;
            for (int i = 0; i < branchCount; i++)
            {
                var childObj = meshRoot.transform.GetChild(i).gameObject;
                CombineMesh(childObj, meshSave);
            }
        }
    }

    #region Branch
    void SetSameLevel()
    {
        materialDirectory.Clear();//20200615
        //===========================2020-12-1============================//
        var root = HandleMeshPrefabToGameObject(materialRoot);//root   materialRoot
        //===========================2020-12-1============================//
        var meshFilters = root.GetComponentsInChildren<MeshFilter>();
        //===========================================================//
        meshSave = new GameObject();
        meshSave.name = root.name + "_Material";
        meshSave.transform.position = root.transform.position;
        meshSave.transform.rotation = root.transform.rotation;
        meshSave.transform.localScale = root.transform.localScale;
        //===========================================================//
        for (int i = 0; i < meshFilters.Length; i++)
        {
            var obj = meshFilters[i].gameObject;
            var render = obj.GetComponent<Renderer>();
            var mat = render.sharedMaterial;
            //========================================//
            Transform parent = obj.transform.parent;
            obj.transform.SetParent(null);
            //========================================//
            GameObject node = new GameObject();

            //========================================//
            node.name = meshFilters[i].name;
            node.transform.SetParent(meshSave.transform, true);
            node.transform.position = obj.transform.position;
            node.transform.rotation = obj.transform.rotation;
            node.transform.localScale = obj.transform.localScale;
            UnityEditorInternal.ComponentUtility.CopyComponent(meshFilters[i]);
            UnityEditorInternal.ComponentUtility.PasteComponentAsNew(node);
            UnityEditorInternal.ComponentUtility.CopyComponent(render);
            UnityEditorInternal.ComponentUtility.PasteComponentAsNew(node);
            obj.transform.SetParent(parent);
            //================================================//
            if (mat == null) continue;
            if (!materialDirectory.ContainsKey(mat))
            {
                List<GameObject> list = new List<GameObject>();
                list.Add(node);
                materialDirectory.Add(mat, list);
            }
            else
            {
                if (!materialDirectory[mat].Contains(node))
                    materialDirectory[mat].Add(node);
            }
            //================================================//
        }
        //===========================2020-12-1============================//
        DestroyImmediate(root);
        //===========================2020-12-1============================//
    }

    void ClearNewUselessMesh()
    {
        var meshFilters = meshSave.GetComponentsInChildren<MeshFilter>();
        for (int i = 0; i < meshFilters.Length; i++)
        {
            var obj = meshFilters[i].gameObject;
            var mr = obj.GetComponent<MeshRenderer>();
            if (mr == null || mr.enabled == false || meshFilters[i].sharedMesh == null)
            {
                var col = obj.GetComponent<Collider>();
                if (col) DestroyImmediate(col);
                DestroyImmediate(meshFilters[i]);
                if (mr) DestroyImmediate(mr);
            }
        }
    }

    void SortLevelByMaterial()
    {
        foreach (var kv in materialDirectory)
        {
            GameObject obj = new GameObject();
            obj.name = kv.Key.name;//材质名

            foreach (var value in kv.Value)
            {
                value.transform.SetParent(obj.transform, true);
            }
            obj.transform.SetParent(meshSave.transform, true);
        }
    }

    void GetBadLevelBranch()
    {
        var branchCount = meshSave.transform.childCount;

        for (int i = 0; i < branchCount; i++)
        {
            var childObj = meshSave.transform.GetChild(i).gameObject;
            if (!CheckBranchIsGood(childObj))
            {
                Debug.LogError(childObj + "执行分支");
                if (!newBranchList.Contains(childObj))
                    newBranchList.Add(childObj);
            }
        }
    }

    void SetNewLevelBranchExtension()
    {
        if (newBranchList.Count > 0)
        {
            for (int i = 0; i < newBranchList.Count; i++)
            {
                var obj = newBranchList[i];
                var tempMeshFilters = obj.GetComponentsInChildren<MeshFilter>();
                int vertexCount = 0;
                int nextIndex = 0;

                GameObject nextObj = null;

                for (int j = 0; j < tempMeshFilters.Length; j++)
                {
                    var tf = tempMeshFilters[j];
                    var childObj = tf.gameObject;
                    vertexCount += tf.sharedMesh.vertexCount;

                    if (vertexCount < 65535)
                    {
                        if (nextObj == null)
                        {
                            nextObj = new GameObject();
                            nextObj.name = obj.name + "(" + nextIndex + ")";
                            nextObj.transform.SetParent(obj.transform, true);
                            childObj.name = childObj.name + "" + j;
                            childObj.transform.SetParent(nextObj.transform, true);
                        }
                        else
                        {
                            childObj.name = childObj.name + "" + j;
                            childObj.transform.SetParent(nextObj.transform, true);
                        }
                    }
                    else
                    {
                        nextIndex++;
                        vertexCount = tf.sharedMesh.vertexCount;
                        nextObj = new GameObject();
                        nextObj.name = obj.name + "(" + nextIndex + ")";
                        nextObj.transform.SetParent(obj.transform, true);
                        childObj.name = childObj.name + j;
                        childObj.transform.SetParent(nextObj.transform, true);
                    }
                }
            }
        }
    }
    #endregion

    #endregion

    #endregion

    #region Private Method

    #region Collider
    void CombinerCollider()
    {
        //===========================2020-12-1============================//
        var root = HandleColliderPrefabToGameObject(colliderRoot);//root   colliderRoot
        //===========================2020-12-1============================//
        var colliders = root.GetComponentsInChildren<Collider>();
        //===========================2020-12-1============================//
        colliderSave = new GameObject();
        colliderSave.name = root.name + "_Collider";
        colliderSave.transform.position = root.transform.position;
        colliderSave.transform.rotation = root.transform.rotation;
        colliderSave.transform.localScale = root.transform.localScale;
        //================================================================//
        for (int i = 0; i < colliders.Length; i++)
        {
            var obj = colliders[i].gameObject;
            Transform parent = obj.transform.parent;
            obj.transform.SetParent(null);//2020-11-30//   obj.transform.SetParent(obj.transform.root);   //2020-11-30//
            GameObject node = new GameObject();
            node.name = colliders[i].name;
            node.transform.SetParent(colliderSave.transform, true);
            node.transform.position = obj.transform.position;
            node.transform.rotation = obj.transform.rotation;
            node.transform.localScale = obj.transform.localScale;
            UnityEditorInternal.ComponentUtility.CopyComponent(colliders[i]);
            UnityEditorInternal.ComponentUtility.PasteComponentAsNew(node);
            obj.transform.SetParent(parent);
        }
        //===========================2020-12-1============================//
        DestroyImmediate(root);
        //===========================2020-12-1============================//
    }
    #endregion

    #region Material

    void SortMeshByMaterial()
    {
        EditorUtility.DisplayProgressBar("Set Same Level", "Set Mesh Same Level in Hierarchy", 0.2f);
        SetSameLevel();
        //ClearNewUselessMesh();
        EditorUtility.DisplayProgressBar("Sort Level By Material", "Sort Mesh  Level By Material in Hierarchy", 0.4f);
        SortLevelByMaterial();
        EditorUtility.DisplayProgressBar("Get Bad Level Branch", "Get Mesh Branch Level On Hierarchy", 0.6f);
        GetBadLevelBranch();
        EditorUtility.DisplayProgressBar("Get New Level Branch", "Get Mesh Branch Level On Hierarchy", 0.8f);
        SetNewLevelBranchExtension();
        EditorUtility.DisplayProgressBar("Finish", "Finish Mesh Branch Level On Hierarchy", 1f);
        EditorUtility.ClearProgressBar();
    }

    #endregion

    #region Mesh
    void CleanUselessMesh()
    {
        var meshFilters = meshRoot.GetComponentsInChildren<MeshFilter>();

        meshSave = new GameObject();
        meshSave.name = meshRoot.name + "_Mesh";
        meshSave.transform.position = meshRoot.transform.position;
        meshSave.transform.rotation = meshRoot.transform.rotation;
        meshSave.transform.localScale = meshRoot.transform.localScale;

        for (int i = 0; i < meshFilters.Length; i++)
        {
            var obj = meshFilters[i].gameObject;
            var mr = obj.GetComponent<MeshRenderer>();
            if (mr == null || mr.enabled == false || meshFilters[i].sharedMesh == null)
            {
                var col = obj.GetComponent<Collider>();
                if (col) DestroyImmediate(col);
                DestroyImmediate(meshFilters[i]);
                if (mr) DestroyImmediate(mr);
            }
        }
    }

    void CombineMesh(GameObject obj, GameObject parent)
    {
        MeshFilter[] meshFilters = obj.GetComponentsInChildren<MeshFilter>();
        //计算父节点的中心点
        Vector3 centerPos = GetCenter(meshFilters);
        CombineInstance[] combine = new CombineInstance[meshFilters.Length];
        Material material = null;
        int lightmap = -1;
        int i = 0;
        while (i < meshFilters.Length)
        {
            var meshRender = meshFilters[i].GetComponent<MeshRenderer>();
            if (meshRender)
            {
                if (material == null)
                    material = meshRender.sharedMaterial;
                if (material != meshRender.sharedMaterial)
                {
                    Debug.LogError("存在不同材质不予合并");
                    Debug.LogError(material.name + "===============" + meshRender.sharedMaterial);
                    return;
                }
                if (lightmap == -1)
                    lightmap = meshRender.lightmapIndex;
                if (lightmap != meshRender.lightmapIndex)
                {
                    Debug.LogError("存在不同烘焙贴图不予合并");
                    return;
                }
                combine[i].mesh = meshFilters[i].sharedMesh;
                //记录参与合批的lightmapOffset
                combine[i].lightmapScaleOffset = meshRender.lightmapScaleOffset;
                //每个参与合批mesh的矩阵与中心点进行偏移计算
                Matrix4x4 matrix4X4 = meshFilters[i].transform.localToWorldMatrix;
                matrix4X4.m03 -= centerPos.x;
                matrix4X4.m13 -= centerPos.y;
                matrix4X4.m23 -= centerPos.z;
                combine[i].transform = matrix4X4;
                i++;
            }
        }
        var newObj = new GameObject(obj.name, typeof(MeshFilter), typeof(MeshRenderer));
        newObj.transform.position = centerPos;

        if (lightmapIndex >= 0)
        {
            var newRenderer = newObj.transform.GetComponent<MeshRenderer>();
            if (newRenderer)
            {
                newRenderer.lightmapIndex = lightmap;
            }
        }

        var newMesh = new Mesh();
        newMesh.CombineMeshes(combine, true, true, true);
        //合拼会自动生成UV3，但是我们并不需要，可以这样删除
        newMesh.uv3 = null;
        //=================================================//
        AssetDatabase.CreateAsset(newMesh, "Assets/" + newObj.name + ".asset");
        newObj.GetComponent<MeshFilter>().sharedMesh = newMesh;
        newObj.GetComponent<MeshRenderer>().sharedMaterial = material;
        AssetDatabase.Refresh();
        //=================================================//
        newObj.transform.SetParent(parent.transform, true);
    }

    void CreatMeshPrefab()
    {
        //===2020-11-27:22:00===//
        if (meshSave != null)
        {
            string prefabPath = "Assets/" + meshSave.name + ".prefab";
            if (AssetDatabase.LoadAssetAtPath(prefabPath, typeof(GameObject)))
            {
                if (EditorUtility.DisplayDialog("Are you sure?", "The prefab already exists. Do you want to overwrite it?", "Yes", "No"))
                {
                    CreatePrefab(meshSave, prefabPath);
                }
            }
            else
            {
                CreatePrefab(meshSave, prefabPath);
            }
        }
        //===2020-11-27:22:00===//
    }
    #endregion

    #endregion
}
