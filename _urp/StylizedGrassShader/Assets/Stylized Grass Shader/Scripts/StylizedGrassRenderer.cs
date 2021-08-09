//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
    [ExecuteInEditMode]
    [AddComponentMenu("Stylized Grass/Stylized Grass Renderer")]
    public class StylizedGrassRenderer : MonoBehaviour
    {
        public static StylizedGrassRenderer Instance;
#if URP
        public ScriptableRendererData bendRenderer;
#endif

        public const int TexelsPerMeter = 16;

        public bool debug = false;
        [Tooltip("When not in play-mode, the renderer will follow the scene-view camera position.")]
        public bool followSceneCamera;
        [Tooltip("Controls how large the render area is. Small is better, since a large area thins out the rendering resolution")]
        [Range(8, 512)]
        public float renderExtends = 32f;
        [Tooltip("The renderer will follow this Transform's position. Ideally set to the player's transform.")]
        public Transform followTarget;
        public RenderTexture vectorRT;
        public Camera renderCam;
        [Tooltip("When enabled, the bend strength decreases smoothly at the edges of the render area. If disabled, benders crossing the edge will cause streaking lines of flat grass." +
            "\n\nBest enabled when using a small render area and a first-person perspective. For top-down games, using a large render area beyond the camera field of view also works.")]
        public bool maskEdges;

        public int resolution = 1024;
        private int m_resolution;
        private Vector4 uv = new Vector4();

        [Tooltip("When a color map is assigned, this will be set as the active color map.\n\nHaving the Color Map Renderer component present would not longer be required.")]
        public GrassColorMap colorMap;
        [Tooltip("When enabled the grass Ambient and Gust strength values are multiplied by the WindZone's Main value")]
        public bool listenToWindZone;
        public WindZone windZone;

        //GrassBender will register itself to this list
        public static SortedDictionary<int, List<GrassBender>> GrassBenders = new SortedDictionary<int, List<GrassBender>>();
        private static List<GrassBender> BenderLayer;
        public static int benderCount;

        public Transform actualFollowTarget;
        public Vector3 lastPos;
        public Bounds bounds;

        public static void RegisterBender(GrassBender gb)
        {
            if (GrassBenders.ContainsKey(gb.sortingLayer))
            {
                GrassBenders.TryGetValue(gb.sortingLayer, out BenderLayer);

                if (BenderLayer.Contains(gb) == false)
                {
                    BenderLayer.Add(gb);
                    GrassBenders[gb.sortingLayer] = BenderLayer;
                    benderCount++;
                }
            }
            //Create new layer
            else
            {
                BenderLayer = new List<GrassBender>();
                BenderLayer.Add(gb);

                GrassBenders.Add(gb.sortingLayer, BenderLayer);
                benderCount++;
            }
        }

        public static void UnRegisterBender(GrassBender gb)
        {
            if (GrassBenders.ContainsKey(gb.sortingLayer))
            {
                GrassBenders.TryGetValue(gb.sortingLayer, out BenderLayer);

                BenderLayer.Remove(gb);
                benderCount--;

                //If layer is now empty, remove it
                if (GrassBenders[gb.sortingLayer].Count == 0) GrassBenders.Remove(gb.sortingLayer);
            }
        }

        public static string VECTOR_MAP_PARAM = "_BendMap";
        public static string VECTOR_UV_PARAM = "_BendMapUV";
        public static string WIND_MAP_PARAM = "_WindMap";

        private static Color neutralVector = new Color(0.5f, 0f, 0.5f, 0f);

        public void OnEnable()
        {
            Instance = this;

            Init();

            if (colorMap)
            {
                colorMap.SetActive();
            }
            else
            {
                if (!GrassColorMapRenderer.Instance) GrassColorMap.DisableGlobally();
            }

#if UNITY_EDITOR
            UnityEditor.SceneView.duringSceneGui += OnSceneGUI;
#endif
        }

        public void OnDisable()
        {
            Instance = null;

            //Shader needs to disable texture reading, since default global textures are gray
            uv.w = 0;
            Shader.SetGlobalVector("_BendMapUV", uv);

#if UNITY_EDITOR
            UnityEditor.SceneView.duringSceneGui -= OnSceneGUI;
#endif

            if (renderCam)
            {
                DestroyImmediate(renderCam.gameObject);
                DestroyImmediate(vectorRT);
                renderCam = null;
            }

            Shader.SetGlobalVector("_GlobalWindParams", new Vector4(0f, 0f, 0f, 0f));
        }

        public static void SetPosition(Vector3 position)
        {
            if (!Instance)
            {
                Debug.LogWarning("[Stylized Grass Renderer] Tried to set  follow target, but no instance is present");
                return;
            }
            if (Instance.followTarget)
            {
                Debug.LogWarning("[Stylized Grass Renderer] Tried to set position, but it is following " + Instance.followTarget.name, Instance.followTarget);
                return;
            }

            Instance.transform.position = position;
        }

        public static void SetFollowTarget(Transform transform)
        {
            if (!Instance)
            {
                Debug.LogWarning("[Stylized Grass Renderer] Tried to set follow target, but no instance is present");
                return;
            }

            Instance.followTarget = transform;
        }

        public static void SetWindZone(WindZone windZone)
        {
            if (!Instance)
            {
                Debug.LogWarning("Tried to set Stylized Grass Renderer wind zone, but no instance is present");
                return;
            }

            Instance.windZone = windZone;
        }

        private void Init()
        {
            m_resolution = resolution;

            CreateVectorMap();

            if (!followTarget)
            {
                GameObject targetObj = GameObject.FindGameObjectWithTag("MainCamera");
                if (targetObj) actualFollowTarget = targetObj.transform;
            }
        }

        private void Update()
        {
            actualFollowTarget = followTarget ?? this.transform;

            if (renderCam)
            {
                UpdateCamera();
            }
            else
            {
                renderCam = CreateCamera();
            }

            //Assign to all shaders
            if (vectorRT && !maskEdges)
            {
                Shader.SetGlobalTexture(VECTOR_MAP_PARAM, vectorRT);
            }

            if (listenToWindZone)
            {
                if (windZone) Shader.SetGlobalVector("_GlobalWindParams", new Vector4(windZone.windMain, 0f, 0f, 1f));
            }
            else
            {
                Shader.SetGlobalVector("_GlobalWindParams", new Vector4(0f, 0f, 0f, 0f));
            }

            Shader.SetGlobalVector(VECTOR_UV_PARAM, uv);
            Shader.SetGlobalVector("_BendRenderParams", new Vector4(this.transform.position.y, renderExtends, 0f, 0f));
        }

        private Camera CreateCamera()
        {
            Camera cam = new GameObject().AddComponent<Camera>();
            cam.gameObject.name = "GrassBendCamera " + GetInstanceID();
            cam.transform.localEulerAngles = new Vector3(90f, 0f, 0f);
            cam.gameObject.hideFlags = HideFlags.HideAndDontSave;
            if (actualFollowTarget) cam.gameObject.transform.position = new Vector3(actualFollowTarget.transform.position.x, actualFollowTarget.transform.position.y + renderExtends, actualFollowTarget.transform.position.z);

            cam.orthographic = true;
            cam.depth = -100f;
            cam.allowHDR = false;
            cam.allowMSAA = false;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.cullingMask = 0;
            //Neutral bend direction and zero strength/mask
            cam.backgroundColor = neutralVector;

            cam.useOcclusionCulling = false;
            cam.allowHDR = true;
            cam.allowMSAA = false;
            cam.forceIntoRenderTexture = true;

#if URP
            UniversalAdditionalCameraData camData = cam.gameObject.AddComponent<UniversalAdditionalCameraData>();
            camData.renderShadows = false;
            camData.renderPostProcessing = false;
            camData.antialiasing = AntialiasingMode.None;
            camData.requiresColorOption = CameraOverrideOption.Off;
            camData.requiresDepthOption = CameraOverrideOption.Off;
            camData.requiresColorTexture = false;
            camData.requiresDepthTexture = false;

            if (UniversalRenderPipeline.asset)
            {
#if UNITY_EDITOR
                //Only runs in editor, but will be referenced in instance from there on
                if (!bendRenderer) bendRenderer = GetGrassBendRenderer();
                DrawGrassBenders.ValidatePipelineRenderers();
#endif

                if (bendRenderer)
                {
                    //Assign DrawGrassBenders renderer (list is internal, so perform reflection workaround)
                    ScriptableRendererData[] rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField("m_RendererDataList", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(UniversalRenderPipeline.asset);

                    for (int i = 0; i < rendererDataList.Length; i++)
                    {
                        if (rendererDataList[i] == bendRenderer) camData.SetRenderer(i);
                    }
                }
                else
                {
                    this.enabled = false;
                }
            }
            else
            {
                Debug.LogError("[StylizedGrassRenderer] No Universal Render Pipeline is currently active.");
            }
#endif

            return cam;
        }

        public static int CalculateResolution(float size)
        {
            int res = Mathf.RoundToInt(size * TexelsPerMeter);
            res = Mathf.NextPowerOfTwo(res);
            res = Mathf.Clamp(res, 256, 2048);
            return res;
        }

        //Create the influence map for the shaders
        private void CreateVectorMap()
        {
            if (vectorRT != null)
            {
                if (renderCam) renderCam.targetTexture = null;
                DestroyImmediate(vectorRT);
            }

            RenderTextureDescriptor rtDsc = new RenderTextureDescriptor();
            rtDsc.width = resolution;
            rtDsc.height = resolution;
            rtDsc.depthBufferBits = 0;

            rtDsc.graphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.R16G16B16A16_SFloat;

            rtDsc.enableRandomWrite = false; //Not supported on OpenGL
            rtDsc.autoGenerateMips = false;
            rtDsc.useMipMap = false;
            rtDsc.volumeDepth = 1;
            rtDsc.msaaSamples = 1;
            rtDsc.dimension = TextureDimension.Tex2D;
            rtDsc.sRGB = false;
            rtDsc.vrUsage = VRTextureUsage.None;
            rtDsc.bindMS = false;
            rtDsc.memoryless = RenderTextureMemoryless.None;
            rtDsc.shadowSamplingMode = ShadowSamplingMode.None;

            //vectorRT = new RenderTexture(rtDsc)
            vectorRT = new RenderTexture(rtDsc)
            {
                useMipMap = false,
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                anisoLevel = 0,

                name = "BendMap" + GetInstanceID(),
                isPowerOfTwo = true,
                hideFlags = HideFlags.DontSave
            };
        }

        private void UpdateCamera()
        {
            if (!renderCam) return;

            //renderCam.cullingMask = 1 << renderLayer;
            renderCam.targetTexture = vectorRT;
            renderCam.orthographicSize = renderExtends;
            renderCam.farClipPlane = renderExtends * 2f;

            if (actualFollowTarget)
            {
                /// Move the renderer once the follow target has moved a distance equal to 10% of the render extends size
                if (((actualFollowTarget.transform.position - lastPos).sqrMagnitude > renderExtends * 0.1f) || lastPos == Vector3.zero)
                {
                    renderCam.transform.position = new Vector3(actualFollowTarget.transform.position.x, actualFollowTarget.transform.position.y + renderExtends, actualFollowTarget.transform.position.z);
                    lastPos = actualFollowTarget.transform.position;
                }
            }
            else
            {
                renderCam.transform.position = new Vector3(transform.position.x, transform.position.y + renderExtends, transform.position.z);
            }

            bounds = new Bounds(new Vector3(renderCam.transform.position.x, renderCam.transform.position.y - renderExtends, renderCam.transform.position.z), Vector3.one * renderExtends * 2);

            //When changing resolution
            if (m_resolution != resolution) CreateVectorMap();
            m_resolution = resolution;

            uv.x = 1 - renderCam.transform.position.x - 1 + renderExtends;
            uv.y = 1 - renderCam.transform.position.z - 1 + renderExtends;
            uv.z = renderExtends * 2;
            uv.w = 1f; //Enable bend map sampling in shader
        }

#if UNITY_EDITOR
#if URP
        public static ForwardRendererData GetGrassBendRenderer()
        {
            string[] GUIDs = AssetDatabase.FindAssets(DrawGrassBenders.AssetName + " t:ForwardRendererData");

            if (GUIDs.Length == 0)
            {
                Debug.LogError("The <i>" + DrawGrassBenders.AssetName + "</i> asset could not be found in the project. Was it renamed or not imported?");
                return null;
            }

            string assetPath = AssetDatabase.GUIDToAssetPath(GUIDs[0]);

            ForwardRendererData data = (ForwardRendererData)AssetDatabase.LoadAssetAtPath(assetPath, typeof(ForwardRendererData));

            return data;
        }
#endif

        private void OnDrawGizmos()
        {
            if (!renderCam) return;

            Gizmos.color = new Color(1, 1, 1, 1f);
            Gizmos.DrawWireCube(bounds.center, bounds.size);
        }

        private void OnGUI() //Gameview
        {
            DrawDebugGUI(false);
        }

        private void OnSceneGUI(SceneView sceneView)
        {
            DrawDebugGUI(true);

            if (followSceneCamera)
            {
                actualFollowTarget = sceneView.camera.transform;
                UpdateCamera();
            }
        }

        void DrawDebugGUI(bool sceneView)
        {
            if (vectorRT == null) return;

            Rect imgRect = new Rect(5, 5, 256, 256);
            //Set to UI debug image
            if (debug && !sceneView)
            {
                GUI.DrawTexture(imgRect, vectorRT);
            }
            if (debug && sceneView)
            {
                Handles.BeginGUI();

                GUILayout.BeginArea(imgRect);

                EditorGUI.DrawTextureTransparent(imgRect, vectorRT);
                GUILayout.EndArea();
                Handles.EndGUI();
            }
        }
#endif
    }
}