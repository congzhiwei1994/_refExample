using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Play_RTS : MonoBehaviour
{
    public RTSCamera rtsCameraScript;

	void Start ()
    {
        rtsCameraScript = transform.GetComponentInChildren<RTSCamera>();
    }
    public void SetValue(float newSpeed, float newZoomSpeed, float newAngle, float newDis, Vector2 newBounds, Vector2 newAngelBound, Vector2 newZoom, Transform newFloor=null)
    {
        if (rtsCameraScript)
        {
            rtsCameraScript.SetValue(newSpeed,newZoomSpeed, newAngle,newDis, newBounds,newAngelBound,newZoom, newFloor);
        }
    }

    public void OnUpdate(ref float value)
    {
        if (rtsCameraScript)
        {
            rtsCameraScript.OnUpdate(ref value);
        }
    }
}
