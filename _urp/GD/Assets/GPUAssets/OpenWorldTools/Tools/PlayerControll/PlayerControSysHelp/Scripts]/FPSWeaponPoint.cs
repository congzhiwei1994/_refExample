/*
 * 本脚本主要应对Animator 挂在在相机下面不播放响应动作
 * 需要在运行时动态吧对象挂载在目标节点下
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FPSWeaponPoint : MonoBehaviour
{
    [Header("目标节点")]
    public Transform parent;
	// Use this for initialization
	void Start ()
    {
        //Invoke("SetParent",1);
        StartCoroutine("SetParent");
    }

    IEnumerator SetParent()
    {
        yield return null;
        if (parent)
        {
            this.transform.SetParent(parent, true);
            this.transform.localPosition = Vector3.zero;
        }
    }
	// Update is called once per frame
	void Update () {
		
	}
}
