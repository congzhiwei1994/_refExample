using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ShaderLOD : MonoBehaviour
{
    public enum Quality
    {
        High,Medium,Low
    }
    public Quality theQuality = Quality.High;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        switch(theQuality)
        {
            case Quality.High:
            Shader.globalMaximumLOD=600;
            break;
            case Quality.Medium:
            Shader.globalMaximumLOD=400;
            break;
            case Quality.Low:
            Shader.globalMaximumLOD=200;
            break;
        }
    }
}
