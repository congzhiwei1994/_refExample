using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using GPUInstancer;
public class HoudiniDetailCreater : MonoBehaviour
{
	//目标种类
	public List<GPUInstancerPrefab> gpuPrefabObjList = new List<GPUInstancerPrefab>();
	public GPUInstancerPrefabManager gpuPrefabManager;

	public PCGDetailInfo detailInfo;
	private GameObject detailParent;
	
	//存储创建出来的对象
	List<GPUInstancerPrefab> gpuPrefabList = new List<GPUInstancerPrefab>();
	private GPUInstancerPrefab tempPrefab;
	void Awake()
	{
		detailParent = new GameObject("Houdini植被根节点");
		detailParent.transform.position = Vector3.zero;
		detailParent.transform.parent = this.transform;	

		gpuPrefabList = InstantiatePrefab(detailInfo);
	}
	// Use this for initialization
	void Start () 
	{
		if(gpuPrefabManager!=null
		&&gpuPrefabManager.gameObject.activeSelf
		&&gpuPrefabManager.enabled)	
		{
			GPUInstancerAPI.RegisterPrefabInstanceList(gpuPrefabManager,gpuPrefabList);
			GPUInstancerAPI.InitializeGPUInstancer(gpuPrefabManager);          
		}
	}
	

	private List<GPUInstancerPrefab> InstantiatePrefab( PCGDetailInfo info)
	{
		if(info==null) return null;
		List<GPUInstancerPrefab> result = new List<GPUInstancerPrefab>();
		int typyCount = Mathf.Min(gpuPrefabObjList.Count, info.detailList.Count);
		for(int i =0;i<info.detailList.Count;i++)
		{
			DetailSingleType tempType = info.detailList[i];
			for(int c=0;c<tempType.singleType.Count;c++)
			{
				tempPrefab = Instantiate(gpuPrefabObjList[i],tempType.singleType[c].position,
				tempType.singleType[c].rotation);
				tempPrefab.transform.localScale=tempType.singleType[c].localScale;
				tempPrefab.transform.parent =detailParent.transform;
				result.Add(tempPrefab);
			}
		}
		return result;
	}
}
