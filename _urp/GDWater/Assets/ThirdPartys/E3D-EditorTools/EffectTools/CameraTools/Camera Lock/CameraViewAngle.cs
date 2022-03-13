using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraViewAngle : MonoBehaviour {

    public GameObject player;
    public float xAngle = 0f;
    public float yAngle = 0f; 
    public float zAngle = 0f;

    /// <summary>
    /// 向前距离
    /// </summary>
    public float forwardDis = 5;



    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

            //相机锁定
            Quaternion rotation = Quaternion.Euler(xAngle, yAngle, zAngle);
            transform.position = player.transform.position - (rotation * new Vector3(0f, 0f, forwardDis));
            transform.LookAt(player.transform);
            return;
#if UNITY_EDITOR
        Debug.Log("UNITY_EDITOR");
#endif

    }

    public void LockCameraMethod()
    {
        Quaternion rotation = Quaternion.Euler(xAngle, yAngle, zAngle);
        transform.position = player.transform.position - (rotation * new Vector3(0f, 0f, forwardDis));
        transform.LookAt(player.transform);
    }
}
