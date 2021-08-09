using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class AEMSetting : MonoBehaviour
{
    public string DataFile;
    public static AEMSetting Instance = null;
    public bool loadFinish;

    string fileName;
    public string ID;
    public UnityEngine.Object PrefabRoot;
    Dictionary<string, GameObject> PrefabDic = new Dictionary<string, GameObject>();
    public float UnitHeight = 1f;
    public float UnitSize = 1f;

    public string EAB_Name;
    public UnityEngine.Object Data;
    public bool RemoveUnderUnit = true;

    public UnityEngine.Object ColliderRoot;
    public Dictionary<string, GameObject> ColliderPrefabObjectDic = new Dictionary<string, GameObject>();

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        //====20200805====//
        //LoadDataEntrance();
        //LoadPrefabEntrance();
        //====20200805====//
    }

    public void LoadDataEntrance()
    {
        DataFile = AssetDatabase.GetAssetPath(Data);
        //Debug.Log("路径：" + DataFile);
        fileName = Path.GetFileNameWithoutExtension(DataFile);
        //Debug.Log("文件名：" + fileName);
        string path = DataFile;
        int start = path.IndexOf("Resources") + 10;
        string retPath = path.Substring(start, path.Length - start);
        int ext = retPath.IndexOf('.');
        if (ext != -1)
            retPath = retPath.Substring(0, ext);
        //Debug.Log("文件路径：" + retPath);
        AEMDataMgr.Instance.Initialize(retPath, "GameObject");
        loadFinish = AEMDataMgr.Instance.finish;
    }

    public void LoadPrefabEntrance()
    {
        ReadAllMeshPrefab();
        ReadAllColliderPrefab();//=====20200805=====//
        CreateGameObjectEntrance();
    }

    void CreateGameObjectEntrance()
    {
        if (RemoveUnderUnit)
        {
            CreateGameObjectByPrefabRemove();
        }
        else
        {
            CreateGameObjectByPrefabNoRemove();
        }
    }

    Dictionary<int, string> RemoveUnderUnitDic = new Dictionary<int, string>();

    Dictionary<string, Dictionary<float, RemoveUnderUnitInfo>> RemoveUnderUnitInfoDic = new Dictionary<string, Dictionary<float, RemoveUnderUnitInfo>>();
    public struct RemoveUnderUnitInfo
    {
        public int index;
        public float layer;
        public string info;
    }

    void CreateGameObjectByPrefabRemove()
    {
        RemoveUnderUnitDic.Clear();
        RemoveUnderUnitInfoDic.Clear();
        //========================================================================//
        GameObject meshParent = new GameObject();
        meshParent.name = fileName;
        //========================================//
        GameObject colliderParent = new GameObject();
        colliderParent.name = "Collider" + fileName;
        //========================================================================//
        List<string> newPosStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "");
        List<string> meshStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Mesh");
        List<string> posStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Position");
        List<string> rotStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Rotation");
        //========================================================================//
        int length = newPosStr.Count;
        for (int i = 0; i < length; i++)
        {
            string str = newPosStr[i];
            int index = str.LastIndexOf(",");
            string zeroStr = str.Substring(0, index + 1);
            string oneStr = str.Substring(index + 1);
            float layer = float.Parse(oneStr);
            //Debug.Log("============================");
            if (!RemoveUnderUnitInfoDic.ContainsKey(zeroStr))
            {
                Dictionary<float, RemoveUnderUnitInfo> infoDic = new Dictionary<float, RemoveUnderUnitInfo>();

                RemoveUnderUnitInfo info = new RemoveUnderUnitInfo();
                info.index = i;
                info.layer = layer;
                info.info = str;

                infoDic.Add(layer, info);
                RemoveUnderUnitInfoDic.Add(zeroStr, infoDic);
            }
            else
            {
                RemoveUnderUnitInfo info = new RemoveUnderUnitInfo();
                info.index = i;
                info.layer = layer;
                info.info = str;
                if (RemoveUnderUnitInfoDic[zeroStr].ContainsKey(layer))
                {
                    continue;
                }
                else
                {
                    RemoveUnderUnitInfoDic[zeroStr].Add(layer, info);
                }

            }

        }
        //Debug.Log("============================");
        foreach (var a in RemoveUnderUnitInfoDic)
        {
            if (a.Value.Count > 1)
            {
                //多层结构
                float max = 1f;//第一层
                foreach (var b in a.Value)
                {
                    if (b.Key > max)
                    {
                        max = b.Key;
                    }
                }
                //Debug.Log(a.Key+ " Max Index:"+max);
                foreach (var c in a.Value)
                {
                    if (c.Key - max < 0)
                    {
                        //Debug.Log("==============" + c.Value.info + " Max Index:" + max);
                        RemoveUnderUnitDic.Add(c.Value.index, c.Value.info);
                    }
                }
            }
            else
            {
                continue;
            }
        }
        //Debug.Log("============================");
        for (int i = 0; i < length; i++)
        {
            if (RemoveUnderUnitDic.ContainsKey(i)) continue;

            string mesh = meshStr[i];

            Vector3 pos = Vector3.zero;
            Vector3 rot = Vector3.zero;
            string[] tempPos = posStr[i].Split(',');
            string[] tempRot = rotStr[i].Split(',');

            Vector3 newPos = Vector3.zero;
            string str = newPosStr[i];

            int index = str.LastIndexOf(" ");
            string newStr = str.Substring(index + 1);
            string[] tempNewPos = newStr.Split(',');

            //====================================//
            if (tempPos.Length > 3 || tempRot.Length > 3)
            {
                Debug.LogError("位置、角度数据异常");
            }
            else
            {
                if (tempPos.Length == 3)
                {
                    if (UnitSize != 0)
                        pos = ((UnitHeight - 1) * Vector3.up + new Vector3(float.Parse(tempNewPos[0]), 0f, float.Parse(tempNewPos[1]))) * UnitSize;
                    else
                        pos = (UnitHeight - 1) * Vector3.up + new Vector3(float.Parse(tempNewPos[0]), 0f, float.Parse(tempNewPos[1]));
                    //rot = new Vector3(float.Parse(tempRot[0]), float.Parse(tempRot[1]), float.Parse(tempRot[2]));
                    //rot = new Vector3(-90, -90, 0);
                    //pos += Vector3.up * (float.Parse(tempNewPos[2]) - 1) * 1.374f;
                    pos += Vector3.up * (float.Parse(tempNewPos[2]) - 1);
                    string[] header = mesh.Split('-');
                    if (header[0] != EAB_Name)
                    {
                        mesh = EAB_Name + "-" + header[1] + "-" + header[2] + "-" + header[3] + "-" + header[4];
                    }
                    CreateGameObjectByPrefab(mesh, pos, rot, Vector3.one * UnitSize, meshParent.transform);
                    //CreateColliderByPrefab(mesh, pos, rot, Vector3.one * UnitSize, colliderParent.transform);
                    CreateColliderByPrefabExtension(mesh, pos, rot, Vector3.one * UnitSize, colliderParent.transform);
                }
            }
        }
    }

    void CreateGameObjectByPrefabNoRemove()
    {
        GameObject parent = new GameObject();
        parent.name = fileName;
        //========================================//
        GameObject colliderParent = new GameObject();
        colliderParent.name = "Collider" + fileName;
        //========================================================================//
        List<string> newPosStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "");
        List<string> meshStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Mesh");
        List<string> posStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Position");
        List<string> rotStr = AEMDataMgr.Instance.GetExcelListData(DataFile, "Rotation");
        //========================================================================//
        int length = newPosStr.Count;
        for (int i = 0; i < length; i++)
        {
            string mesh = meshStr[i];

            Vector3 pos = Vector3.zero;
            Vector3 rot = Vector3.zero;
            string[] tempPos = posStr[i].Split(',');
            string[] tempRot = rotStr[i].Split(',');

            Vector3 newPos = Vector3.zero;
            string str = newPosStr[i];

            int index = str.LastIndexOf(" ");
            string newStr = str.Substring(index + 1);
            string[] tempNewPos = newStr.Split(',');

            //====================================//
            if (tempPos.Length > 3 || tempRot.Length > 3)
            {
                Debug.LogError("位置、角度数据异常");
            }
            else
            {
                if (tempPos.Length == 3)
                {
                    if (UnitSize != 0)
                        pos = ((UnitHeight - 1) * Vector3.up + new Vector3(float.Parse(tempNewPos[0]), 0f, float.Parse(tempNewPos[1]))) * UnitSize;
                    else
                        pos = (UnitHeight - 1) * Vector3.up + new Vector3(float.Parse(tempNewPos[0]), 0f, float.Parse(tempNewPos[1]));
                    //rot = new Vector3(float.Parse(tempRot[0]), float.Parse(tempRot[1]), float.Parse(tempRot[2]));
                    //rot = new Vector3(-90, -90, 0);

                    //pos += Vector3.up * (float.Parse(tempNewPos[2]) - 1) * 1.374f;
                    pos += Vector3.up * (float.Parse(tempNewPos[2]) - 1);
                    string[] header = mesh.Split('-');
                    if (header[0] != EAB_Name)
                    {
                        mesh = EAB_Name + "-" + header[1] + "-" + header[2] + "-" + header[3] + "-" + header[4];
                    }
                    CreateGameObjectByPrefab(mesh, pos, rot, Vector3.one * UnitSize, parent.transform);
                    //CreateColliderByPrefab(mesh, pos, rot, Vector3.one * UnitSize, colliderParent.transform);
                    CreateColliderByPrefabExtension(mesh, pos, rot, Vector3.one * UnitSize, colliderParent.transform);
                }
            }
        }
    }

    void CreateGameObjectByPrefab(string mesh, Vector3 pos, Vector3 angle, Vector3 scale, Transform parent = null)
    {
        GameObject temp = GetObject(mesh) as GameObject;

        if (temp != null)
        {
            Vector3 newPos = temp.transform.position;
            newPos.x = 0;
            newPos.z = 0;
            GameObject tt = Instantiate(temp);
            tt = PrefabUtility.ConnectGameObjectToPrefab(tt, temp);
            tt.transform.SetParent(parent);
            tt.transform.position = pos + newPos;
            //tt.transform.eulerAngles = angle;
            tt.transform.localScale = scale;
        }
        else
        {
            Debug.LogError("网格：" + mesh + "预置不存在");
            GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cube.name = mesh;
            Material mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            mat.SetColor("_BaseColor", Color.red);
            cube.GetComponent<Renderer>().sharedMaterial = mat;
            cube.transform.SetParent(parent);
            cube.transform.position = pos + Vector3.up * 0.874f;
            //cube.transform.eulerAngles = angle;
            cube.transform.localScale = scale;
        }
    }

    void CreateColliderByPrefab(string collider, Vector3 pos, Vector3 angle, Vector3 scale, Transform parent = null)
    {
        string col = collider;
        int index = col.IndexOf("-");
        string tempCol = col.Substring(index);
        //string newCol = "COLH" + (pos.y + 1f) + tempCol;
        string newCol = "COLH1" + tempCol;
        //Debug.Log(newCol);
        if (ColliderPrefabObjectDic.ContainsKey(newCol))
        {
            GameObject temp = ColliderPrefabObjectDic[newCol];
            if (temp != null)
            {
                Vector3 newPos = temp.transform.position;
                newPos.x = 0;
                newPos.z = 0;
                GameObject tt = Instantiate(temp);
                tt.transform.SetParent(parent);
                tt.name = newCol;
                tt.transform.position = pos + newPos;
                //tt.transform.eulerAngles = angle;
                tt.transform.localScale = scale;
            }
        }
        else
        {
            Debug.LogError("碰撞：" + newCol + "预置不存在");
        }
    }

    void CreateColliderByPrefabExtension(string collider, Vector3 pos, Vector3 angle, Vector3 scale, Transform parent = null)
    {
        string col = collider;
        int index = col.IndexOf("-");
        string tempCol = col.Substring(index);
        //string newCol = "COLH" + (pos.y + 1f) + tempCol;
        string newCol = GetCollider("COLH1" + tempCol);
        //Debug.Log(newCol);
        if (newCol != "" && ColliderPrefabObjectDic.ContainsKey(newCol))
        {
            GameObject temp = ColliderPrefabObjectDic[newCol];
            if (temp != null)
            {
                Vector3 newPos = temp.transform.position;
                newPos.x = 0;
                newPos.z = 0;
                GameObject tt = Instantiate(temp);
                tt.transform.SetParent(parent);
                tt.name = newCol;
                tt.transform.position = pos + newPos;
                //tt.transform.eulerAngles = angle;
                tt.transform.localScale = scale;
            }
        }
        else
        {
            Debug.LogError("碰撞：" + newCol + "预置不存在");
        }
    }

    void ReadAllMeshPrefab()
    {
        PrefabDic.Clear();
        //=====================================//
        if (PrefabRoot != null && ID != null && ID != "")
        {
            string folderPath = AssetDatabase.GetAssetPath(PrefabRoot);
            if (folderPath.Contains("Resources"))
            {
                int index = folderPath.IndexOf("Resources") + 10;
                folderPath = folderPath.Substring(index);

                var y = Resources.LoadAll<GameObject>(folderPath);
                if (y.Length > 0)
                {
                    foreach (var item in y)
                    {
                        if (!PrefabDic.ContainsKey(item.name))
                        {
                            PrefabDic.Add(item.name, item);
                        }
                    }
                }
            }
        }
        else
        {
            Debug.LogError("检查数据设置面板参数设置");
        }
        //=====================================//
    }

    void ReadAllColliderPrefab()
    {
        string colPrefabFolderPath = AssetDatabase.GetAssetPath(ColliderRoot);
        if (colPrefabFolderPath.Contains("Resources"))
        {
            int index = colPrefabFolderPath.IndexOf("Resources") + 10;
            colPrefabFolderPath = colPrefabFolderPath.Substring(index);
            colPrefabFolderPath += "/";
            var ColliderPrefabObjs = Resources.LoadAll<GameObject>(colPrefabFolderPath);
            if (ColliderPrefabObjs.Length > 0)
            {
                //Debug.Log("Get Resource Collider Objects Finish");
                foreach (var item in ColliderPrefabObjs)
                {
                    if (!ColliderPrefabObjectDic.ContainsKey(item.name))
                    {
                        ColliderPrefabObjectDic.Add(item.name, item);
                    }
                }
            }
        }
    }

    GameObject GetObject(string mesh)
    {
        string[] split = mesh.Split('-');


        if (PrefabDic.ContainsKey(mesh))
        {
            return PrefabDic[mesh];
        }
        else
        {
            string temp = split[0] + "-" + split[1] + "-" + split[2] + "-";//第二层
            if (split[3] != "A")
            {
                if (split[4] != "1")
                {
                    temp = temp + "A" + "-" + split[4];
                    if (PrefabDic.ContainsKey(temp))
                    {
                        return PrefabDic[temp];
                    }
                    else
                    {
                        temp = temp + "A-1";
                        return PrefabDic[temp];
                    }
                }
                else
                {
                    temp = temp + "A-1";
                    return PrefabDic[temp];
                }
            }
            else
            {
                if (split[4] != "1")
                {
                    temp = temp + split[3] + "-" + 1;
                    if (PrefabDic.ContainsKey(temp))
                    {
                        return PrefabDic[temp];
                    }
                    else
                    {
                        return null;
                    }
                }
                else
                {
                    temp = temp + "A-1";
                    if (PrefabDic.ContainsKey(temp))
                    {
                        return PrefabDic[temp];
                    }
                    else
                    {
                        return null;
                    }
                }
            }
        }
    }

    string GetCollider(string collider)
    {
        string[] split = collider.Split('-');

        if (ColliderPrefabObjectDic.ContainsKey(collider))
        {
            return collider;
        }
        else
        {
            string temp = split[0] + "-" + split[1] + "-" + split[2] + "-";//第二层
            if (split[3] != "A")
            {
                if (split[4] != "1")
                {
                    temp = temp + "A" + "-" + split[4];
                    if (ColliderPrefabObjectDic.ContainsKey(temp))
                    {
                        return temp;
                    }
                    else
                    {
                        temp = temp + "A-1";
                        return temp;
                    }
                }
                else
                {
                    temp = temp + "A-1";
                    return temp;
                }
            }
            else
            {
                if (split[4] != "1")
                {
                    temp = temp + split[3] + "-" + 1;
                    if (ColliderPrefabObjectDic.ContainsKey(temp))
                    {
                        return temp;
                    }
                    else
                    {
                        return "";
                    }
                }
                else
                {
                    temp = temp + "A-1";
                    if (ColliderPrefabObjectDic.ContainsKey(temp))
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
    }
}
