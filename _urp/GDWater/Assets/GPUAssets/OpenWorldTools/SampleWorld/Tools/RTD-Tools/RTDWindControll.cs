//******************************************************
//
//	文件名 (File Name) 	: 		RTDWindControll.cs
//	
//	脚本创建者(Author) 	:		Ejoy_小林
	
//	创建时间 (CreatTime):		#CreateTime#
//******************************************************


using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RTDWindControll : MonoBehaviour
{
    public Camera rtCamera;
    public string shaderPropertyRTCameraPos = "RTCameraPosition";
    public string shaderPropertyRTCameraSize = "RTCameraSize";
  
    void Start () 
	{
		
	}
	
	void Update () 
	{
        if (rtCamera != null)
        {
           // Debug.Log("设置shader属性");
            Shader.SetGlobalVector(shaderPropertyRTCameraPos, rtCamera.transform.position);
            Shader.SetGlobalFloat(shaderPropertyRTCameraSize, rtCamera.orthographicSize);
        }
	}
}
