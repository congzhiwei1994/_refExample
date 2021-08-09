using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

namespace StylizedGrass
{
    [ExecuteInEditMode]
    [AddComponentMenu("Stylized Grass/Bender")]
    public class GrassBender : MonoBehaviour
    {
        public GrassBenderBase.BenderType benderType = GrassBenderBase.BenderType.Mesh;
        [Tooltip("Higher layers are always drawn over lower layers. Use this to override other benders on a lower layer.")]
        [Range(0, 4)]
        public int layer = 0;
        public int sortingLayer = 0;
        [NonSerialized]
        public Mesh bakedMesh;
        [NonSerialized]
        public Mesh particleTrailMesh;

        //Common
        [Range(-1, 1f)]
        public float heightOffset = 0f;
        [Range(0f, 3f)]
        public float strength = 1f;
        [Range(0, 3f)]
        public float pushStrength = 1f;
        [Range(0f, 3f)]
        public float scaleMultiplier = 1f;
        public AnimationCurve strengthOverLifetime = AnimationCurve.Linear(0f, 1f, 1f, 0f);
        public Gradient strengthGradient;
        [Tooltip("When enabled, overlapping benders of the same type will blend together")]
        public bool alphaBlending = false;

        //Mesh
        public MeshFilter meshFilter;
        public Mesh mesh;
        public MeshRenderer meshRenderer;

        //Trail
        [FormerlySerializedAs("trail")]
        public TrailRenderer trailRenderer;
        [Range(0.25f, 1f)]
        public float trailAccuracy = 0.33f;
        public float trailLifetime = 2f;
        [UnityEngine.Min(1f)]
        public float trailRadius = 3;
        public AnimationCurve widthOverLifetime = AnimationCurve.Constant(0f, 1f, 1f);

        //Particle system
        public new ParticleSystem particleSystem;
        public ParticleSystemRenderer particleRenderer;
        public bool hasParticleTrails;
        public ParticleSystem.ColorOverLifetimeModule psGrad;

        private void OnEnable()
        {
            StylizedGrassRenderer.RegisterBender(this);

            if (trailRenderer)
            {
                //Hide from cameras
                trailRenderer.forceRenderingOff = true;
                trailRenderer.emitting = true;
            }
        }

        private void OnDisable()
        {
            StylizedGrassRenderer.UnRegisterBender(this);

            if (trailRenderer)
            {
                trailRenderer.emitting = false;
            }
        }

        public void SwitchLayer(int layerNum)
        {
            //No point in switching to the same layer
            if (layerNum == this.sortingLayer) return;

            //Debug.Log("Switching layer " + layer + ">" + i);

            //Unregister with current layer
            StylizedGrassRenderer.UnRegisterBender(this);

            //Set layer
            this.sortingLayer = layerNum;

            //Register with new layer
            StylizedGrassRenderer.RegisterBender(this);
        }

        public void SwitchBenderType(GrassBenderBase.BenderType type)
        {
            benderType = type;

            if (trailRenderer && type != GrassBenderBase.BenderType.Trail)
            {
                //DestroyImmediate(trail);
                trailRenderer = null;
            }
            //if (!trail && type == GrassBenderBase.BenderType.Trail) GrassBenderBase.UpdateTrail(this);

            if (meshRenderer && type != GrassBenderBase.BenderType.Mesh)
            {
                meshFilter = null;
                meshRenderer = null;
            }
            if (meshRenderer && type == GrassBenderBase.BenderType.Mesh)
            {
                meshFilter = meshRenderer.gameObject.GetComponent<MeshFilter>();
            }

            if (particleSystem && type != GrassBenderBase.BenderType.ParticleSystem)
            {
                particleSystem = null;
            }
            if (particleSystem && type == GrassBenderBase.BenderType.ParticleSystem)
            {
                particleRenderer = particleSystem.gameObject.GetComponent<ParticleSystemRenderer>();
                psGrad = particleSystem.GetComponent<ParticleSystem.ColorOverLifetimeModule>();
            }

            //StylizedGrassRenderer.UnRegisterBender(this);
            //StylizedGrassRenderer.RegisterBender(this);
        }

        private void OnDrawGizmos()
        {
            if (meshFilter)
            {
                if (benderType == GrassBenderBase.BenderType.Mesh && meshFilter.sharedMesh)
                {
                    Gizmos.color = new Color(0.5f, 0.75f, 1, 0.5f);
                    Gizmos.DrawWireMesh(meshFilter.sharedMesh, 0, meshFilter.transform.position - new Vector3(0f, heightOffset, 0f), meshFilter.transform.rotation, meshFilter.transform.lossyScale * scaleMultiplier);
                    Gizmos.color = new Color(0.5f, 0.75f, 1, 0.3f);
                    Gizmos.DrawMesh(meshFilter.sharedMesh, 0, meshFilter.transform.position - new Vector3(0f, heightOffset, 0f), meshFilter.transform.rotation, meshFilter.transform.lossyScale * scaleMultiplier);
                }
            }
        }
    }
}