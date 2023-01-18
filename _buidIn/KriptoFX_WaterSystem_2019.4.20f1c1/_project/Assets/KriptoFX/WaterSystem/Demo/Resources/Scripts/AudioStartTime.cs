using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class AudioStartTime : MonoBehaviour
{
    public float StartTime = 2;

    void OnEnable()
    {
        GetComponent<AudioSource>().time = StartTime;
    }

}
