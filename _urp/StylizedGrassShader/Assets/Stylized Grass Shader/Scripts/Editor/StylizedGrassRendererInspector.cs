using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace StylizedGrass
{
    [CustomEditor(typeof(StylizedGrassRenderer))]
    public class StylizedGrassRendererInspector : Editor
    {
        StylizedGrassRenderer script;
        SerializedProperty renderExtends;
        SerializedProperty followSceneCamera;
        SerializedProperty followTarget;
        SerializedProperty renderLayer;
        SerializedProperty maskEdges;
        SerializedProperty colorMap;
        SerializedProperty listenToWindZone;
        SerializedProperty windZone;

        private Vector2 benderScrollPos;

        private Texture benderIcon;

        private Vector4 windParams;

        private string[] layerStr;

        private void OnEnable()
        {
            script = (StylizedGrassRenderer)target;
#if URP
            if (script.bendRenderer == null)
            {
                DrawGrassBenders.ValidatePipelineRenderers();

                script.bendRenderer = StylizedGrassEditor.GetGrassBendRendererInProject();
                script.OnEnable();
                script.OnDisable();
            }
#endif

            renderExtends = serializedObject.FindProperty("renderExtends");
            followSceneCamera = serializedObject.FindProperty("followSceneCamera");
            followTarget = serializedObject.FindProperty("followTarget");
            renderLayer = serializedObject.FindProperty("renderLayer");
            maskEdges = serializedObject.FindProperty("maskEdges");
            colorMap = serializedObject.FindProperty("colorMap");
            listenToWindZone = serializedObject.FindProperty("listenToWindZone");
            windZone = serializedObject.FindProperty("windZone");

            layerStr = UnityEditorInternal.InternalEditorUtility.layers;

        }

        public override void OnInspectorGUI()
        {
            this.Repaint();

#if !URP
            EditorGUILayout.HelpBox("The Universal Render Pipeline v" + AssetInfo.MIN_URP_VERSION + " is not installed", MessageType.Error);
#else

            serializedObject.Update();
            windParams = Shader.GetGlobalVector("_GlobalWindParams");

            EditorGUI.BeginChangeCheck();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Settings"));

            using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
            {
                EditorGUILayout.PropertyField(renderExtends);
                EditorGUILayout.HelpBox("Resolution: " + StylizedGrassRenderer.CalculateResolution(renderExtends.floatValue).ToString() + "px (" + StylizedGrassRenderer.TexelsPerMeter + " texels/m)", MessageType.None);
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PropertyField(maskEdges);
                    if (!Application.isPlaying) EditorGUILayout.HelpBox("Only takes effect in Play mode", MessageType.None);
                }
                EditorGUILayout.PropertyField(followSceneCamera);
                EditorGUILayout.PropertyField(followTarget);
                EditorGUILayout.Space();

                //renderLayer.intValue = EditorGUILayout.Popup("Render layer", renderLayer.intValue, layerStr);
                EditorGUILayout.PropertyField(colorMap);
                EditorGUILayout.PropertyField(listenToWindZone);
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (listenToWindZone.boolValue)
                    {
                        EditorGUILayout.PropertyField(windZone);

                        if (!windZone.objectReferenceValue)
                        {
                            if (GUILayout.Button("Create", GUILayout.MaxWidth(75f)))
                            {
                                GameObject obj = new GameObject();
                                obj.name = "Wind Zone";
                                WindZone wz = obj.AddComponent<WindZone>();

                                windZone.objectReferenceValue = wz;
                            }
                        }

                    }
                }
            }

            EditorGUILayout.Space();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Grass benders (" + StylizedGrassRenderer.benderCount + ")"));

            benderScrollPos = EditorGUILayout.BeginScrollView(benderScrollPos, StylizedGrassGUI.ParameterGroup.Section, GUILayout.MaxHeight(150f));
            {
                var prevColor = GUI.color;
                var prevBgColor = GUI.backgroundColor;
                //var rect = EditorGUILayout.BeginHorizontal();

                int i = 0;

                foreach (KeyValuePair<int, List<GrassBender>> layer in StylizedGrassRenderer.GrassBenders)
                {
                    if(StylizedGrassRenderer.GrassBenders.Count > 1) EditorGUILayout.LabelField("Layer " + layer.Key, EditorStyles.boldLabel);
                    foreach (GrassBender bender in layer.Value)
                    {
                        var rect = EditorGUILayout.BeginHorizontal();
                        GUI.color = i % 2 == 0 ? Color.white * 0.66f : Color.grey * (EditorGUIUtility.isProSkin ? 1.1f : 1.5f);

                        if (rect.Contains(Event.current.mousePosition)) GUI.color = Color.white * 0.75f;
                        if (Selection.activeGameObject == bender.gameObject) GUI.color = Color.white * 0.8f;

                        EditorGUI.DrawRect(rect, GUI.color);

                        //GUILayout.Space(5);
                        GUI.color = prevColor;
                        GUI.backgroundColor = prevBgColor;

                        if (bender.benderType == GrassBenderBase.BenderType.Mesh) benderIcon = EditorGUIUtility.IconContent("MeshRenderer Icon").image;
                        if (bender.benderType == GrassBenderBase.BenderType.Trail) benderIcon = EditorGUIUtility.IconContent("TrailRenderer Icon").image;
                        if (bender.benderType == GrassBenderBase.BenderType.ParticleSystem) benderIcon = EditorGUIUtility.IconContent("ParticleSystem Icon").image;

                        if (GUILayout.Button(new GUIContent(" " + bender.name, benderIcon), EditorStyles.miniLabel, GUILayout.MaxHeight(20f)))
                        {
                            Selection.activeGameObject = bender.gameObject;
                        }

                        EditorGUILayout.EndHorizontal();

                        i++;

                    }
                }
            }
            EditorGUILayout.EndScrollView();

            if (EditorGUI.EndChangeCheck())
            {
                serializedObject.ApplyModifiedProperties();
                if (colorMap.objectReferenceValue) script.colorMap.SetActive();
            }

            EditorGUILayout.LabelField("- Staggart Creations -", EditorStyles.centeredGreyMiniLabel);
#endif
        }

        public override bool HasPreviewGUI()
        {
            return script.vectorRT;
        }

        public override void OnPreviewGUI(Rect r, GUIStyle background)
        {
            if (!script.vectorRT) return;

            GUI.DrawTexture(r, script.vectorRT, ScaleMode.ScaleToFit);

            Rect btnRect = r;
            btnRect.x += 5f;
            btnRect.y += 5f;
            btnRect.width = 150f;
            btnRect.height = 20f;
            script.debug = GUI.Toggle(btnRect, script.debug, new GUIContent(" Pin to viewport"));

            GUI.Label(new Rect(r.width * 0.5f - (175 * 0.5f), r.height - 5, 175, 25), string.Format("{0} texel(s) per meter", ColorMapEditor.GetTexelSize(script.vectorRT.height, script.resolution)), EditorStyles.toolbarButton);

        }
    }
}
