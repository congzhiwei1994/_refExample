using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanarReflectionManager : MonoBehaviour {

    Camera m_ReflectionCamere;
    Camera m_MainCamera;

    public GameObject m_ReflectionPlane;
    [Range(0.0f, 1.0f)]
    public float _Alpha = 0.5f;
    Material ssrMaterial;

    RenderTexture m_RenderTarget;

    void Start()
    {
        GameObject reflectionCameraGo = new GameObject("ReflectionCamera");
        m_ReflectionCamere = reflectionCameraGo.AddComponent<Camera>();
        m_ReflectionCamere.enabled = false;

        m_MainCamera = GetComponent<Camera>();
        m_RenderTarget = new RenderTexture(Screen.width, Screen.height, 24);
        //m_DepthTexture = new RenderTexture(Screen.width, Screen.height, 0);
        if (m_ReflectionPlane != null)
        {
            ssrMaterial = m_ReflectionPlane.GetComponent<MeshRenderer>().sharedMaterial;
        }
    }


    //private void OnPostRender()
    //{
    //    if (m_ReflectionPlane == null) return;
    //    RenderReflection();
    //    //Blur();
    //    //DrawQuad();
    //}

    private void LateUpdate()
    {
        if (m_ReflectionPlane == null) return;
        RenderReflection();
    }

    void RenderReflection()
    {
        m_ReflectionCamere.CopyFrom(m_MainCamera);

        Vector3 cameraDirectionWorldSpace = m_MainCamera.transform.forward;
        Vector3 cameraUpWorldSpace = m_MainCamera.transform.up;
        Vector3 cameraPositionWorldSpace = m_MainCamera.transform.position;

        Vector3 cameraDirectionPlaneSpace = m_ReflectionPlane.transform.InverseTransformDirection(cameraDirectionWorldSpace);
        Vector3 cameraUpPlaneSpace = m_ReflectionPlane.transform.InverseTransformDirection(cameraUpWorldSpace);
        Vector3 cameraPositonPlaneSpace = m_ReflectionPlane.transform.InverseTransformPoint(cameraPositionWorldSpace);

        cameraDirectionPlaneSpace.y *= -1.0f;
        cameraUpPlaneSpace.y *= -1.0f;
        cameraPositonPlaneSpace.y *= -1.0f;

        cameraDirectionWorldSpace = m_ReflectionPlane.transform.TransformDirection(cameraDirectionPlaneSpace);
        cameraUpWorldSpace = m_ReflectionPlane.transform.TransformDirection(cameraUpPlaneSpace);
        cameraPositionWorldSpace = m_ReflectionPlane.transform.TransformPoint(cameraPositonPlaneSpace);

        m_ReflectionCamere.transform.position = cameraPositionWorldSpace;
        m_ReflectionCamere.transform.LookAt(cameraPositionWorldSpace + cameraDirectionWorldSpace, cameraUpWorldSpace);

        m_ReflectionCamere.targetTexture = m_RenderTarget;

        //Shader.SetGlobalFloat("_WaterPlaneHeight", m_ReflectionPlane.transform.position.y);

        m_ReflectionCamere.Render();
        ssrMaterial.SetTexture("_Reflection", m_RenderTarget);
        ssrMaterial.SetFloat("_Alpha", _Alpha);
    }

    private void OnDisable()
    {
        m_RenderTarget.Release();
    }

}