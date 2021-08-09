using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestGetChildCount : MonoBehaviour
{
    public GameObject[] list;
    // Use this for initialization
    void Start()
    {
        foreach (var item in list)
        {
            Debug.Log(item.name + "-----" + item.transform.childCount);
        }
    }
}
