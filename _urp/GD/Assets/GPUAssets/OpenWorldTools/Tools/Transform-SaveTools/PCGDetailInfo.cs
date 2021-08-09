using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class PCGDetailInfo : ScriptableObject
{
    public List<DetailSingleType> detailList = new List<DetailSingleType>();
}



[System.Serializable]
public class DetailSingleInfo
{
    public Vector3 position;
    public Quaternion rotation;
    public Vector3 localScale;

    public DetailSingleInfo() { }

    public DetailSingleInfo(Vector3 pos,
                            Quaternion rota,
                            Vector3 scale)
    {
        this.position = pos;
        this.rotation = rota;
        this.localScale = scale;
    }
}

[System.Serializable]
public class DetailSingleType
{
    public List<DetailSingleInfo> singleType;

    public DetailSingleType()
    {
        singleType = new List<DetailSingleInfo>();
    }
}