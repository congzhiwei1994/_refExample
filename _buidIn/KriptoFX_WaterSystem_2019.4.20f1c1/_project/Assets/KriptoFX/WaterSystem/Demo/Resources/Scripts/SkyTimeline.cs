using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyTimeline : MonoBehaviour
{
    public Material SkyMaterial;
    public AnimationCurve Curve1;
    public float TimeScale1 = 20;
    public string ShaderProperty1;

    private float startValue;

    private float currentTime;

    void OnEnable()
    {
        currentTime = 0;
        startValue = SkyMaterial.GetFloat(ShaderProperty1);
    }

    void OnDisable()
    {
        SkyMaterial.SetFloat(ShaderProperty1, startValue);
    }

    void Update()
    {
        currentTime += Time.deltaTime;
        var param1 = Curve1.Evaluate(currentTime / TimeScale1);
        SkyMaterial.SetFloat(ShaderProperty1, param1);
    }
}
