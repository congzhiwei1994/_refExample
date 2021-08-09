using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor.Rendering;
using UnityEditor;
using UnityEngine.Rendering;


namespace ShaderLib
{
    [CustomEditor(typeof(LightProbePicker))]
    public class LightProbePickerEditor : Editor
    {
        SerializedProperty m_Data;

        private static Mesh s_SphereMesh;
        private Material m_SHMaterial;
        private MaterialPropertyBlock m_PropertyBlock;

        private LocalSHDataEditor m_Editor = null;


        private readonly static Vector3[] s_TempPosArray = new Vector3[1];
        private readonly static SphericalHarmonicsL2[] s_TempLightProbeArray = new SphericalHarmonicsL2[1];
        private readonly static Vector4[] s_TempOcclusionProbeArray = new Vector4[1];

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

        private static Mesh sphereMesh
        {
            get { return s_SphereMesh ?? (s_SphereMesh = Resources.GetBuiltinResource(typeof(Mesh), "New-Sphere.fbx") as Mesh); }
        }

        // Start is called before the first frame update
        void OnEnable()
        {
            var o = new PropertyFetcher<LightProbePicker>(serializedObject);
            m_Data = o.Find(x => x.targetData);

            SceneView.beforeSceneGui += OnPreSceneGUICallback;

            var picker = target as LightProbePicker;
            if(picker != null)
            {
                picker.gameObject.tag = "EditorOnly";
            }
        }

        private void OnDisable()
        {
            SceneView.beforeSceneGui -= OnPreSceneGUICallback;

           
            DestroyImmediate(m_SHMaterial);
            DestroyImmediate(m_Editor);

            if (m_PropertyBlock != null)
            {
                m_PropertyBlock.Clear();
            }
        }

        // Draw Reflection probe preview sphere
        private void OnPreSceneGUICallback(SceneView sceneView)
        {
            if (Event.current.type != EventType.Repaint)
                return;

            foreach (var t in targets)
            {
                var p = (LightProbePicker)t;
                if (!shMaterial)
                    return;

                if (!UnityEditor.SceneManagement.StageUtility.IsGameObjectRenderedByCamera(p.gameObject, Camera.current))
                    return;


                Matrix4x4 m = new Matrix4x4();

                // @TODO: use MaterialPropertyBlock instead - once it actually works!
                // Tried to use MaterialPropertyBlock in 5.4.0b2, but would get incorrectly set parameters when using with Graphics.DrawMesh
                if(m_PropertyBlock == null)
                {
                    m_PropertyBlock = new MaterialPropertyBlock();
                }

                var currentPos = p.transform.position;
                s_TempPosArray[0] = currentPos;
                LightProbes.CalculateInterpolatedLightAndOcclusionProbes(s_TempPosArray, s_TempLightProbeArray, s_TempOcclusionProbeArray);

                m_PropertyBlock.Clear();
                m_PropertyBlock.CopySHCoefficientArraysFrom(s_TempLightProbeArray);
                m_PropertyBlock.CopyProbeOcclusionArrayFrom(s_TempOcclusionProbeArray);

                // draw a preview sphere that scales with overall GO scale, but always uniformly
                var scale = p.transform.lossyScale.magnitude * 0.5f;
                m.SetTRS(p.transform.position, Quaternion.identity, new Vector3(scale, scale, scale));
                Graphics.DrawMesh(sphereMesh, m, shMaterial, 0, SceneView.currentDrawingSceneView.camera, 0, m_PropertyBlock);
                
            }
        }


        bool ValidPreviewSetup()
        {
            LightProbePicker p = (LightProbePicker)target;
            return (p != null && p.targetData != null);
        }

        public override bool HasPreviewGUI()
        {
            if(ValidPreviewSetup())
            {
                Editor editor = m_Editor;
                Editor.CreateCachedEditor(((LightProbePicker)target).targetData, null, ref editor);
                m_Editor = editor as LocalSHDataEditor;
            }
           
            return true;
        }
        public override void OnPreviewSettings()
        {
            if (!ValidPreviewSetup())
                return;

            m_Editor.OnPreviewSettings();
        }

        public override void OnPreviewGUI(Rect position, GUIStyle style)
        {
            if(!ValidPreviewSetup())
            {
                return;
            }
            LightProbePicker p = target as LightProbePicker;
            if (p != null && p.targetData != null && targets.Length == 1)
            {
                Editor editor = m_Editor;
                Editor.CreateCachedEditor(p.targetData, null, ref editor);
                m_Editor = editor as LocalSHDataEditor;

                if (m_Editor != null)
                {
                    m_Editor.OnPreviewGUI(position, style);
                }
            }
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.PropertyField(m_Data, EditorGUIUtility.TrTempContent("目标数据"));
            if (GUILayout.Button(EditorGUIUtility.TrTextContent("创建", "创建一个新数据"), EditorStyles.miniButton))
            {
                var asset = LocalSHDataEditor.CreateLocalSHDataSelectPath();
                if (asset != null)
                {
                    m_Data.objectReferenceValue = asset;
                }
            }
            if (m_Data.objectReferenceValue != null)
            {
                GUILayout.Space(10f);
                if (GUILayout.Button(EditorGUIUtility.TrTextContent("应用", "把数据保存在目标里"), EditorStyles.miniButton))
                {
                    var asset = m_Data.objectReferenceValue as LocalSHData;
                    if (asset != null)
                    {
                        LightProbePicker p = target as LightProbePicker;
                        if (p != null)
                        {
                            var currentPos = p.transform.position;
                            s_TempPosArray[0] = currentPos;
                            LightProbes.CalculateInterpolatedLightAndOcclusionProbes(s_TempPosArray, s_TempLightProbeArray, s_TempOcclusionProbeArray);
                            Undo.RecordObject(asset, "应用LightProbe数据");
                            asset.lightProbe = s_TempLightProbeArray[0];
                            asset.occlusionProbe = s_TempOcclusionProbeArray[0];
                            EditorUtility.SetDirty(asset);
                        }
                    }
                }
            }

            GUILayout.Space(10f);

            if (GUILayout.Button("结束并删除吸取器"))
            {
                LightProbePicker p = target as LightProbePicker;
                if (p != null)
                {
                    DestroyImmediate(p.gameObject);
                    GUIUtility.ExitGUI();
                }
            }
            serializedObject.ApplyModifiedProperties();
        }
    }

}