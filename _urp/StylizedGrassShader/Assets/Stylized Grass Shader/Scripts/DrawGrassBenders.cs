//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
#if URP
    public class DrawGrassBenders : ScriptableRendererFeature
    {
        public DrawGrassBendersPass m_ScriptablePass;
        public static string AssetName = "GrassBendRenderer";

        public class DrawGrassBendersPass : ScriptableRenderPass
        {
            private ProfilingSampler profilerSampler;
            MaterialPropertyBlock props;

            public static RenderTargetIdentifier bendVectorRT;
            private int bendVectorID;
            Bounds renderBounds;
            private Plane[] frustrumPlanes;

            private Material m_MaskMat;
            private const string MASK_SHADER_NAME = "Hidden/Nature/Grass BendRenderer";

            private bool enableEdgeMasking;
            private bool trailEnabled;

            // This method is called before executing the render pass.
            // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
            // When empty this render pass will render to the active camera render target.
            // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
            // The render pipeline will ensure target setup and clearing happens in an performance manner.
            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                //Debug.Log("Configure");
                if (!m_MaskMat) m_MaskMat = new Material(Shader.Find(MASK_SHADER_NAME));

                //Note, Blit is only performed when camera transform changes. Disable in edit mode to avoid jittering
                enableEdgeMasking = false;
                if (StylizedGrassRenderer.Instance)
                {
                    enableEdgeMasking = StylizedGrassRenderer.Instance.maskEdges;
                }

                if (enableEdgeMasking)
                {
                    bendVectorID = Shader.PropertyToID(StylizedGrassRenderer.VECTOR_MAP_PARAM);
                    cmd.GetTemporaryRT(bendVectorID, cameraTextureDescriptor);
                }

                //Note: may conflict with existing property blocks but this is an edge case
                if (props == null) props = new MaterialPropertyBlock();

                profilerSampler = new ProfilingSampler("Draw Grass Benders");
            }

            private MeshRenderer m_MeshRenderer;
            private TrailRenderer m_TrailRenderer;
            private ParticleSystemRenderer m_ParticleRenderer;
            public ParticleSystem.ColorOverLifetimeModule m_ParticleRendererGrad;

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var cmd = CommandBufferPool.Get(profilerSampler.name);

                renderBounds = StylizedGrassRenderer.Instance.bounds;
                frustrumPlanes = GeometryUtility.CalculateFrustumPlanes(StylizedGrassRenderer.Instance.renderCam);

                using (new ProfilingScope(cmd, profilerSampler))
                {
                    foreach (KeyValuePair<int, List<GrassBender>> layer in StylizedGrassRenderer.GrassBenders)
                    {
                        foreach (GrassBender b in layer.Value)
                        {
                            if (b.enabled == false) continue;

                            props.SetVector("_Params", new Vector4(b.strength, b.heightOffset, b.pushStrength, b.scaleMultiplier));

                            if (b.benderType == GrassBenderBase.BenderType.Trail)
                            {
                                if (!b.trailRenderer) continue;

                                if (!b.trailRenderer.emitting) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.trailRenderer.bounds)) continue;

                                m_TrailRenderer = b.trailRenderer;
                                m_TrailRenderer.SetPropertyBlock(props);

                                //Trail
                                m_TrailRenderer.emitting = b.gameObject.activeInHierarchy;
                                m_TrailRenderer.generateLightingData = true;
                                m_TrailRenderer.widthMultiplier = b.trailRadius;
                                m_TrailRenderer.time = b.trailLifetime;
                                m_TrailRenderer.minVertexDistance = b.trailAccuracy;
                                m_TrailRenderer.widthCurve = b.widthOverLifetime;
                                m_TrailRenderer.colorGradient = GrassBenderBase.GetGradient(b.strengthOverLifetime);

                                //If disabled, temporarly enable in order to bake mesh
                                trailEnabled = m_TrailRenderer.enabled ? true : false;
                                if (!trailEnabled) m_TrailRenderer.enabled = true;

                                if (b.bakedMesh == null) b.bakedMesh = new Mesh();
                                m_TrailRenderer.BakeMesh(b.bakedMesh, renderingData.cameraData.camera, false);

                                cmd.DrawMesh(b.bakedMesh, Matrix4x4.identity, GrassBenderBase.TrailMaterial, 0, 0, props);

                                //Note: Faster, but crashed when trails are disabled (Case 1200430)
                                //cmd.DrawRenderer(m_TrailRenderer, GrassBenderBase.TrailMaterial, 0, 0);

                                if (!trailEnabled) m_TrailRenderer.enabled = false;

                                //trailMesh.Clear();
                            }
                            if (b.benderType == GrassBenderBase.BenderType.ParticleSystem)
                            {
                                if (!b.particleSystem) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.particleRenderer.bounds)) continue;

                                m_ParticleRenderer = b.particleRenderer;
                                m_ParticleRenderer.SetPropertyBlock(props);

                                var grad = b.particleSystem.colorOverLifetime;
                                grad.enabled = true;
                                grad.color = GrassBenderBase.GetGradient(b.strengthOverLifetime);
                                bool localSpace = b.particleSystem.main.simulationSpace == ParticleSystemSimulationSpace.Local;

                                //Note: DrawRenderes with particle systems appear to be broken. Only renders to scene cam when it redraws. Bake the mesh down and render it instead.
                                //Todo: Create repo project and file bug report. 
                                //cmd.DrawRenderer(m_ParticleRenderer, m_Material, 0, 0);
                                if (!b.bakedMesh) b.bakedMesh = new Mesh();
                                m_ParticleRenderer.BakeMesh(b.bakedMesh, renderingData.cameraData.camera);

                                cmd.DrawMesh(b.bakedMesh, localSpace ? m_ParticleRenderer.localToWorldMatrix : Matrix4x4.identity, GrassBenderBase.MeshMaterial, 0, b.alphaBlending ? 1 : 0, props);

                                //Also draw particle trails
                                if (b.hasParticleTrails)
                                {
                                    if (!b.particleTrailMesh) b.particleTrailMesh = new Mesh();

                                    m_ParticleRenderer.BakeTrailsMesh(b.particleTrailMesh, renderingData.cameraData.camera);
                                    cmd.DrawMesh(b.particleTrailMesh, m_ParticleRenderer.localToWorldMatrix, GrassBenderBase.TrailMaterial, 1, 0, props);
                                    //cmd.DrawRenderer(m_ParticleRenderer, GrassBenderBase.TrailMaterial, 1, 0);
                                }
                            }
                            if (b.benderType == GrassBenderBase.BenderType.Mesh)
                            {
                                if (!b.meshRenderer) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.meshRenderer.bounds)) continue;

                                m_MeshRenderer = b.meshRenderer;
                                m_MeshRenderer.SetPropertyBlock(props);

                                cmd.DrawRenderer(m_MeshRenderer, GrassBenderBase.MeshMaterial, 0, b.alphaBlending ? 1 : 0);

                            }
                        }
                    }

                    //Mask edges of bend area, avoids streaking at edges
                    if (enableEdgeMasking)
                    {
                        cmd.SetGlobalTexture("_BendMapInput", BuiltinRenderTextureType.CurrentActive);
                        cmd.Blit(BuiltinRenderTextureType.CurrentActive, bendVectorID, m_MaskMat);
                        cmd.SetGlobalTexture(StylizedGrassRenderer.VECTOR_MAP_PARAM, bendVectorID);
                    }
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            /// Cleanup any allocated resources that were created during the execution of this render pass.
#if URP_9_0
            public override void OnCameraCleanup(CommandBuffer cmd)
#else
            public override void FrameCleanup(CommandBuffer cmd)
#endif
            {
                cmd.ReleaseTemporaryRT(bendVectorID);
            }
        }

        /// <summary>
        /// Checks if the GrassBendRenderer feature is present in the pipeline asset. List is internal, so reflection is required
        /// </summary>
        public static void ValidatePipelineRenderers()
        {
            BindingFlags bindings = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;

            ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField("m_RendererDataList", bindings).GetValue(UniversalRenderPipeline.asset);
            bool isPresent = false;

            ScriptableRendererData pass = StylizedGrassRenderer.Instance.bendRenderer;

            if (pass == null)
            {
                Debug.LogError("The " + AssetName + " ScriptableRendererFeature was not assigned to the StylizedGrassRenderer");
                return;
            }
            for (int i = 0; i < m_rendererDataList.Length; i++)
            {
                if (m_rendererDataList[i] == pass) isPresent = true;
            }

            if (!isPresent)
            {
                AddRendererToPipeline(pass);
            }
            else
            {
                //Debug.Log("The " + AssetName + " ScriptableRendererFeature is assigned to the pipeline asset");
            }
        }

        private static void AddRendererToPipeline(ScriptableRendererData pass)
        {
            if (pass == null) return;

            BindingFlags bindings = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;

            ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField("m_RendererDataList", bindings).GetValue(UniversalRenderPipeline.asset);
            List<ScriptableRendererData> rendererDataList = new List<ScriptableRendererData>();

            for (int i = 0; i < m_rendererDataList.Length; i++)
            {
                rendererDataList.Add(m_rendererDataList[i]);
            }
            rendererDataList.Add(pass);

            typeof(UniversalRenderPipelineAsset).GetField("m_RendererDataList", bindings).SetValue(UniversalRenderPipeline.asset, rendererDataList.ToArray());

            Debug.Log("The <i>" + DrawGrassBenders.AssetName + "</i> renderer is required and was automatically added to the \"" + UniversalRenderPipeline.asset.name + "\" pipeline asset");
        }

        public override void Create()
        {
            m_ScriptablePass = new DrawGrassBendersPass();

            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRendering;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
#endif
        }