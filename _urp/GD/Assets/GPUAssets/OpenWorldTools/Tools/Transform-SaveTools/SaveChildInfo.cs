using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SaveChildInfo : MonoBehaviour
{ 
    private PCGDetailInfo _currentPCGDetailInfo;
    public PCGDetailInfo CurrentPCGDetailInfo
    {
        get{return _currentPCGDetailInfo;}
        set{_currentPCGDetailInfo = value;}
    }

    private Object _dataSaveDir;
    public Object DataSaveDir
    {
        get{return  _dataSaveDir;}
        set{_dataSaveDir =value;}
    }
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    public List<DetailSingleType>  GetChildInfo()
    {
        List<DetailSingleType> result = new List<DetailSingleType>();

        foreach (Transform item in this.transform)
        {

            DetailSingleType detailSingleType = new DetailSingleType();
            foreach (Transform v in item.transform)
            {
                DetailSingleInfo detailSingleInfo = new DetailSingleInfo(v.position,
                    v.rotation,v.localScale);

                detailSingleType.singleType.Add(detailSingleInfo);
            }

            result.Add(detailSingleType);
        }
        return result;
    }
}
