using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEditor.ProjectWindowCallback;


namespace ShaderLib
{
    [CustomEditor(typeof(LocalSHData))]
    public class LocalSHDataEditor : Editor
    {
        private readonly static SphericalHarmonicsL2[] s_TempLightProbeArray = new SphericalHarmonicsL2[1];
        private readonly static Vector4[] s_TempOcclusionProbeArray = new Vector4[1];

        private MaterialPropertyBlock m_PropertyBlock;
        private Material m_SHMaterial;

        private PreviewRenderUtility m_PreviewUtility;
        public Vector2 m_PreviewDir = new Vector2(0, 0);
        private Mesh m_Mesh;

        internal static Mesh GetPreviewSphere()
        {
            return Resources.GetBuiltinResource(typeof(Mesh), "New-Sphere.fbx") as Mesh;
        }

        private Material shMaterial
        {
            get
            {
                if (m_SHMaterial == null)
                {
                    m_SHMaterial = new Material(Shader.Find("Hidden/ShaderLib/ShowSH"));
                    m_SHMaterial.hideFlags = HideFlags.HideAndDontSave;
                }
                return m_SHMaterial;
            }
        }

        void OnEnable()
        {
            
        }

        private void OnDisable()
        {
            if (m_PreviewUtility != null)
            {
                m_PreviewUtility.Cleanup();
                m_PreviewUtility = null;
            }

            DestroyImmediate(m_SHMaterial);
            if (m_PropertyBlock != null)
            {
                m_PropertyBlock.Clear();
            }
        }

       

        void InitPreview()
        {
            // Initialized?
            if (m_PreviewUtility != null)
                return;

            m_PreviewUtility = new PreviewRenderUtility();
            m_PreviewUtility.camera.fieldOfView = 15f;
            m_Mesh = GetPreviewSphere();
        }

        public override bool HasPreviewGUI()
        {
            return true;
        }

        public override void OnPreviewGUI(Rect position, GUIStyle style)
        {
            LocalSHData data = target as LocalSHData;
            if (data != null && targets.Length == 1)
            {
                m_PreviewDir = PreviewGUI.Drag2D(m_PreviewDir, position);

                if (Event.current.type != EventType.Repaint)
                {
                    return;
                }
                if(shMaterial == null)
                {
                    return;
                }
                InitPreview();
                m_PreviewUtility.BeginPreview(position, style);

                if (m_PropertyBlock == null)
                {
                    m_PropertyBlock = new MaterialPropertyBlock();
                }
                m_PropertyBlock.Clear();
                s_TempLightProbeArray[0] = data.lightProbe;
                s_TempOcclusionProbeArray[0] = data.occlusionProbe;
                m_PropertyBlock.CopySHCoefficientArraysFrom(s_TempLightProbeArray);
                m_PropertyBlock.CopyProbeOcclusionArrayFrom(s_TempOcclusionProbeArray);


                var rotation = Quaternion.Euler(-m_PreviewDir.y, 0, 0) * Quaternion.Euler(0, -m_PreviewDir.x, 0);
                var forward = rotation * Vector3.forward;

                m_PreviewUtility.camera.transform.position = -forward * 5.3f;
                m_PreviewUtility.camera.transform.rotation = rotation;

                m_PreviewUtility.DrawMesh(m_Mesh, Vector3.zero, Quaternion.identity, shMaterial, 0, m_PropertyBlock);
                m_PreviewUtility.Render();

                Texture renderedTexture = m_PreviewUtility.EndPreview();
                GUI.DrawTexture(position, renderedTexture, ScaleMode.StretchToFill, false);
            }
        }

        #region Create

        public static LocalSHData CreateLocalSHDataAtPath(string path)
        {
            var data = ScriptableObject.CreateInstance<LocalSHData>();
            data.name = System.IO.Path.GetFileName(path);
            AssetDatabase.CreateAsset(data, path);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            return data;
        }

        public static LocalSHData CreateLocalSHDataSelectPath()
        {
            var path = EditorUtility.SaveFilePanelInProject("创建LocalSHData", "New LocalSH.asset", "asset", "请选择创建的位置");
            if (!string.IsNullOrEmpty(path))
            {
                return CreateLocalSHDataAtPath(path);
            }
            return null;
        }


        [MenuItem("Assets/Create/LightProbe局部数据")]
        static void CreateLocalSHData()
        {
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
                0,
                ScriptableObject.CreateInstance<DoCreateLocalSHData>(),
                "New LocalSH.asset",
                null,
                null
                );
        }

        class DoCreateLocalSHData : EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var profile = CreateLocalSHDataAtPath(pathName);
                ProjectWindowUtil.ShowCreatedAsset(profile);
            }
        }

        #endregion

        class PreviewGUI
        {
            static int sliderHash = "Slider".GetHashCode();
            static Rect s_ViewRect, s_Position;
            static Vector2 s_ScrollPos;

            internal static void BeginScrollView(Rect position, Vector2 scrollPosition, Rect viewRect, GUIStyle horizontalScrollbar, GUIStyle verticalScrollbar)
            {
                s_ScrollPos = scrollPosition;
                s_ViewRect = viewRect;
                s_Position = position;
                GUI.BeginClip(position, new Vector2(Mathf.Round(-scrollPosition.x - viewRect.x - (viewRect.width - position.width) * .5f), Mathf.Round(-scrollPosition.y - viewRect.y - (viewRect.height - position.height) * .5f)), Vector2.zero, false);
            }

            internal class Styles
            {
                public static GUIStyle preButton;
                public static void Init()
                {
                    preButton = "preButton";
                }
            }

            public static Vector2 EndScrollView()
            {
                GUI.EndClip();

                Rect clipRect = s_Position, position = s_Position, viewRect = s_ViewRect;

                Vector2 scrollPosition = s_ScrollPos;
                switch (Event.current.type)
                {
                    case EventType.Layout:
                        GUIUtility.GetControlID(sliderHash, FocusType.Passive);
                        GUIUtility.GetControlID(sliderHash, FocusType.Passive);
                        break;
                    case EventType.Used:
                        break;
                    default:
                        bool needsVerticalScrollbar = ((int)viewRect.width > (int)clipRect.width);
                        bool needsHorizontalScrollbar = ((int)viewRect.height > (int)clipRect.height);
                        int id = GUIUtility.GetControlID(sliderHash, FocusType.Passive);

                        if (needsHorizontalScrollbar)
                        {
                            GUIStyle horizontalScrollbar = "PreHorizontalScrollbar";
                            GUIStyle horizontalScrollbarThumb = "PreHorizontalScrollbarThumb";
                            float offset = (viewRect.width - clipRect.width) * .5f;
                            scrollPosition.x = GUI.Slider(new Rect(position.x, position.yMax - horizontalScrollbar.fixedHeight, clipRect.width - (needsVerticalScrollbar ? horizontalScrollbar.fixedHeight : 0), horizontalScrollbar.fixedHeight),
                                scrollPosition.x, clipRect.width + offset, -offset, viewRect.width,
                                horizontalScrollbar, horizontalScrollbarThumb, true, id);
                        }
                        else
                        {
                            // Get the same number of Control IDs so the ID generation for children don't depend on number of things above
                            scrollPosition.x = 0;
                        }

                        id = GUIUtility.GetControlID(sliderHash, FocusType.Passive);

                        if (needsVerticalScrollbar)
                        {
                            GUIStyle verticalScrollbar = "PreVerticalScrollbar";
                            GUIStyle verticalScrollbarThumb = "PreVerticalScrollbarThumb";
                            float offset = (viewRect.height - clipRect.height) * .5f;
                            scrollPosition.y = GUI.Slider(new Rect(clipRect.xMax - verticalScrollbar.fixedWidth, clipRect.y, verticalScrollbar.fixedWidth, clipRect.height),
                                scrollPosition.y, clipRect.height + offset, -offset, viewRect.height,
                                verticalScrollbar, verticalScrollbarThumb, false, id);
                        }
                        else
                        {
                            scrollPosition.y = 0;
                        }
                        break;
                }

                return scrollPosition;
            }

            public static Vector2 Drag2D(Vector2 scrollPosition, Rect position)
            {
                int id = GUIUtility.GetControlID(sliderHash, FocusType.Passive);
                Event evt = Event.current;
                switch (evt.GetTypeForControl(id))
                {
                    case EventType.MouseDown:
                        if (position.Contains(evt.mousePosition) && position.width > 50)
                        {
                            GUIUtility.hotControl = id;
                            evt.Use();
                            EditorGUIUtility.SetWantsMouseJumping(1);
                        }
                        break;
                    case EventType.MouseDrag:
                        if (GUIUtility.hotControl == id)
                        {
                            scrollPosition -= evt.delta * (evt.shift ? 3 : 1) / Mathf.Min(position.width, position.height) * 140.0f;
                            scrollPosition.y = Mathf.Clamp(scrollPosition.y, -90, 90);
                            evt.Use();
                            GUI.changed = true;
                        }
                        break;
                    case EventType.MouseUp:
                        if (GUIUtility.hotControl == id)
                            GUIUtility.hotControl = 0;
                        EditorGUIUtility.SetWantsMouseJumping(0);
                        break;
                }
                return scrollPosition;
            }
        }
    }
}