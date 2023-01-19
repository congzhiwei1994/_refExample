using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SSS
{
    [ExecuteInEditMode]
    public class WaterFog : MonoBehaviour
    {
        //[SerializeField]
        Material FogMaterial;
        [SerializeField]
        Shader FogShader = null;
        Color _FogColor;
        float _Density;
        Material WaterMaterial;
        public GameObject FogMesh;
        Renderer FogRenderer;

        void CreateMaterial()
        {
            if (FogShader && FogMesh)
            {
                FogMaterial = new Material(FogShader);
                FogMaterial.name = "Fog material";
                FogMesh.GetComponent<Renderer>().sharedMaterial = FogMaterial;
            }
        }

        void OnEnable()
        {
            FogRenderer = GetComponent<Renderer>();
          

        }

        // Update is called once per frame
        void Update()
        {
            WaterMaterial = FogRenderer.sharedMaterial;

            if (FogMaterial)
            {
                _FogColor = WaterMaterial.GetColor("_FogColor");
                _Density = WaterMaterial.GetFloat("_Density");

                FogMaterial.SetColor("_Color", _FogColor);
                FogMaterial.SetFloat("_Density", _Density);
            }
            else
            {// Debug.Log("No Fog Material");
                CreateMaterial();
            }
        }

        private void OnDisable()
        {
            DestroyImmediate(FogMaterial);
        }
    }
}