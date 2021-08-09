using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEditorInternal;
using UnityEngine;

namespace StylizedGrass
{
    [CustomEditor(typeof(GrassColorMapRenderer))]
    public class GrassColorMapRendererInspector : Editor
    {
        GrassColorMapRenderer script;
        SerializedProperty colorMap;
        SerializedProperty resIdx;
        SerializedProperty resolution;
        SerializedProperty renderLayer;
        SerializedProperty useLayers;
        SerializedProperty terrainObjects;

        private GUIContent[] layerNames;
        private int terrainLayerCount;

        private void OnEnable()
        {
            script = (GrassColorMapRenderer)target;

            colorMap = serializedObject.FindProperty("colorMap");
            resIdx = serializedObject.FindProperty("resIdx");
            resolution = serializedObject.FindProperty("resolution");
            renderLayer = serializedObject.FindProperty("renderLayer");
            useLayers = serializedObject.FindProperty("useLayers");
            terrainObjects = serializedObject.FindProperty("terrainObjects");

            if (!script.colorMap) script.colorMap = ColorMapEditor.NewColorMap();

            RefreshLayerNames();
        }

        bool editingCollider
        {
            get { return EditMode.editMode == EditMode.SceneViewEditMode.Collider && EditMode.IsOwner(this); }
        }

        static Color s_HandleColor = new Color(127f, 214f, 244f, 100f) / 255;
        static Color s_HandleColorSelected = new Color(127f, 214f, 244f, 210f) / 255;
        static Color s_HandleColorDisabled = new Color(127f * 0.75f, 214f * 0.75f, 244f * 0.75f, 100f) / 255;
        BoxBoundsHandle m_BoundsHandle = new BoxBoundsHandle();

        Bounds GetBounds()
        {
            return script.colorMap.bounds;
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUI.BeginChangeCheck();

            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.PropertyField(colorMap);

                if (colorMap.objectReferenceValue)
                {
                    /*
                    if (GUILayout.Button(new GUIContent(" Edit", EditorGUIUtility.IconContent(EditorGUIUtility.isProSkin ? "d_editicon.sml" : "editicon.sml").image), GUILayout.MaxWidth(70f)))
                    {
                        Selection.activeObject = colorMap.objectReferenceValue;
                    }
                    */
                    if (GUILayout.Button(new GUIContent(" New", EditorGUIUtility.IconContent(EditorGUIUtility.isProSkin ? "d_editicon.sml" : "editicon.sml").image), GUILayout.MaxWidth(70f)))
                    {
                        colorMap.objectReferenceValue = ColorMapEditor.NewColorMap();
                    }
                }
            }

            if (!colorMap.objectReferenceValue)
            {
                EditorGUILayout.HelpBox("No color map assigned", MessageType.Error);
                return;
            }

            if (colorMap.objectReferenceValue)
            {
                //EditorGUILayout.LabelField(string.Format("Area size: {0}x{1}", script.colorMap.bounds.size.x, script.colorMap.bounds.size.z));

                if (EditorUtility.IsPersistent(script.colorMap) == false)
                {
                    Action saveColorMap = new Action(SaveColorMap);
                    StylizedGrassGUI.DrawActionBox("  The color map asset has not been saved to a file\n  and can only be used in this scene", "Save", MessageType.Warning, saveColorMap);
                }

                if (script.colorMap.overrideTexture)
                {
                    EditorGUILayout.HelpBox("The assigned color map uses a texture override. Rendering a new/updated color map will revert this.", MessageType.Warning);
                }
            }

            EditorGUILayout.Space();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Render area"));

            using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
            {

                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(terrainObjects);
                EditorGUI.indentLevel--;

                using (new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.FlexibleSpace();
#if VEGETATION_STUDIO_PRO
                    if (GUILayout.Button("Add VSP mesh terrains"))
                    {
                        AwesomeTechnologies.MeshTerrains.MeshTerrain[] terrains = GameObject.FindObjectsOfType<AwesomeTechnologies.MeshTerrains.MeshTerrain>();

                        for (int i = 0; i < terrains.Length; i++)
                        {
                            if (script.terrainObjects.Contains(terrains[i].gameObject) == false) script.terrainObjects.Add(terrains[i].gameObject);
                        }
                    }
#endif
                    if (GUILayout.Button("Add active terrains"))
                    {
                        Terrain[] terrains = Terrain.activeTerrains;

                        for (int i = 0; i < terrains.Length; i++)
                        {
                            if (script.terrainObjects.Contains(terrains[i].gameObject) == false) script.terrainObjects.Add(terrains[i].gameObject);
                        }

                        RefreshLayerNames();
                    }
                    if (GUILayout.Button("Add child meshes"))
                    {
                        //All childs, recursive
                        MeshRenderer[] children = script.gameObject.GetComponentsInChildren<MeshRenderer>();

                        for (int i = 0; i < children.Length; i++)
                        {
                            if (script.terrainObjects.Contains(children[i].gameObject) == false) script.terrainObjects.Add(children[i].gameObject);
                        }
                    }
                    if (GUILayout.Button("Clear"))
                    {
                        terrainObjects.ClearArray();
                    }
                }

                EditorGUILayout.Space();

                EditMode.DoEditModeInspectorModeButton(EditMode.SceneViewEditMode.Collider, "Edit Volume", EditorGUIUtility.IconContent("EditCollider"), GetBounds, this);
                script.colorMap.bounds.size = EditorGUILayout.Vector3Field("Size", script.colorMap.bounds.size);
                script.colorMap.bounds.center = EditorGUILayout.Vector3Field("Center", script.colorMap.bounds.center);

                if (script.colorMap.bounds.size == Vector3.zero && terrainObjects.arraySize == 0) EditorGUILayout.HelpBox("The render area cannot be zero", MessageType.Error);
                if (script.colorMap.bounds.size == Vector3.zero && terrainObjects.arraySize > 0) EditorGUILayout.HelpBox("The render area will be automatically calculate based on terrain size", MessageType.Info);

                using (new EditorGUI.DisabledGroupScope(script.terrainObjects.Count == 0))
                {
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        GUILayout.FlexibleSpace();
                        if (GUILayout.Button("Calculate from terrain(s)"))
                        {
                            ColorMapEditor.ApplyUVFromTerrainBounds(colorMap.objectReferenceValue as GrassColorMap, script);
                            SceneView.RepaintAll();
                        }
                    }
                }
            }

            EditorGUILayout.Space();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Layer-based grass scale (experimental)"));
            using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
            {
                DrawLayerHeightSettings();
            }

            EditorGUILayout.Space();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Rendering"));
            using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
            {

                EditorGUILayout.PropertyField(useLayers);

                if (useLayers.boolValue)
                {
                    EditorGUILayout.PropertyField(renderLayer);

                    if (renderLayer.intValue == 0) EditorGUILayout.HelpBox("The render layer is set to \"Nothing\", no objects will be rendered into the color map", MessageType.Error);
                }

                using (new EditorGUILayout.HorizontalScope())
                {
                    resIdx.intValue = EditorGUILayout.Popup("Resolution", resIdx.intValue, ColorMapEditor.reslist, new GUILayoutOption[0]);
                    if (GUILayout.Button("Render"))
                    {
                        ColorMapEditor.RenderColorMap((GrassColorMapRenderer)target);
                    }
                }

            }

            if (EditorGUI.EndChangeCheck())
            {
                resolution.intValue = ColorMapEditor.IndexToResolution(resIdx.intValue);
                serializedObject.ApplyModifiedProperties();
            }

            EditorGUILayout.LabelField("- Staggart Creations -", EditorStyles.centeredGreyMiniLabel);
        }

        private void DrawLayerHeightSettings()
        {
            if (layerNames == null)
            {
                EditorGUILayout.HelpBox("This feature only works with Unity terrains (The first item in the Terrain Objects list isn't a terrain)", MessageType.Info);
                return;
            }

            if (script.layerScaleSettings.Count > 0)
            {
                EditorGUILayout.HelpBox("Currently ALL terrain layers have to be configured", MessageType.Info);

                using (new EditorGUILayout.VerticalScope())
                {
                    EditorGUI.BeginChangeCheck();

                    for (int i = 0; i < script.layerScaleSettings.Count; i++)
                    {
                        GrassColorMapRenderer.LayerScaleSettings s = script.layerScaleSettings[i];

                        using (new EditorGUILayout.HorizontalScope())
                        {
                            /*
                            if (GUILayout.Button("▲"))
                            {
                                script.layerHeightSettings.RemoveAt(i);
                                script.layerHeightSettings.Insert(i - 1, s);
                            }
                            if (GUILayout.Button("▼"))
                            {
                                script.layerHeightSettings.RemoveAt(i);
                                script.layerHeightSettings.Insert(i + 1, s);
                            }
                            */
                            s.layerID = EditorGUILayout.Popup(s.layerID, layerNames, GUILayout.MaxWidth(150f));
                            float strength = s.strength * 100f;
                            strength = EditorGUILayout.Slider(strength, 1f, 100f);
                            s.strength = strength * 0.01f;
                            EditorGUILayout.LabelField("%", GUILayout.MaxWidth(20f));

                            if (GUILayout.Button(new GUIContent("", EditorGUIUtility.IconContent("d_TreeEditor.Trash").image, "Delete item")))
                            {
                                script.layerScaleSettings.RemoveAt(i);
                            }

                        }
                    }

                    if (EditorGUI.EndChangeCheck())
                    {
                        ColorMapEditor.RenderColorMap((GrassColorMapRenderer)target);
                    }
                }
            }
            else
            {
                EditorGUILayout.LabelField("No height settings for terrain layers, grass will stay a uniform scale");
            }

            using (new EditorGUI.DisabledScope(script.layerScaleSettings.Count == terrainLayerCount))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.FlexibleSpace();
                    if (GUILayout.Button(new GUIContent("Add layer setting", EditorGUIUtility.IconContent(EditorGUIUtility.isProSkin ? "d_Toolbar Plus" : "Toolbar Plus").image)))
                    {
                        GrassColorMapRenderer.LayerScaleSettings s = new GrassColorMapRenderer.LayerScaleSettings();
                        s.layerID = script.layerScaleSettings.Count;

                        script.layerScaleSettings.Add(s);

                        ColorMapEditor.RenderColorMap((GrassColorMapRenderer)target);
                    }
                }
            }

        }

        private void RefreshLayerNames()
        {
            if (script.terrainObjects.Count == 0)
            {
                layerNames = null;
                return;
            }

            Terrain t = script.terrainObjects[0].GetComponent<Terrain>();

            if (t == null)
            {
                layerNames = null;
                return;
            }

            terrainLayerCount = t.terrainData.alphamapLayers;
            layerNames = new GUIContent[terrainLayerCount];
            for (int i = 0; i < layerNames.Length; i++)
            {
                layerNames[i] = new GUIContent(t.terrainData.terrainLayers[i].name);
            }
        }

        public override bool HasPreviewGUI()
        {
            if (script.colorMap == null) return false;
            if (script.colorMap.texture == null) return false;

            return script.colorMap.texture == true;
        }

        public override GUIContent GetPreviewTitle()
        {
            return new GUIContent("Color/scale map");
        }

        public override void OnPreviewSettings()
        {
            if (script.colorMap.texture == false) return;

            GUILayout.Label(string.Format("Output ({0}x{0})", script.colorMap.texture.height));
        }

        private bool previewColor = true;
        public override void OnPreviewGUI(Rect r, GUIStyle background)
        {
            if (script.colorMap.texture == null) return;

            if (previewColor)
            {
                GUI.DrawTexture(r, script.colorMap.texture, ScaleMode.ScaleToFit, false);
            }
            else
            {
                EditorGUI.DrawTextureAlpha(r, script.colorMap.texture, ScaleMode.ScaleToFit);
            }

            Rect btnRect = r;
            btnRect.x += 10f;
            btnRect.y += 10f;
            btnRect.width = 50f;
            btnRect.height = 20f;

            previewColor = GUI.Toggle(btnRect, previewColor, new GUIContent("Color"), "Button");
            btnRect.x += 49f;
            previewColor = !GUI.Toggle(btnRect, !previewColor, new GUIContent("Scale"), "Button");
            
            GUI.Label(new Rect(r.width * 0.5f - (175 * 0.5f), r.height - 5, 175, 25), string.Format("{0} texel(s) per meter", ColorMapEditor.GetTexelSize(script.colorMap.texture.height, script.colorMap.bounds.size.x)), EditorStyles.toolbarButton);
        }

        private void SaveColorMap()
        {
            ColorMapEditor.SaveColorMapToAsset(colorMap.objectReferenceValue as GrassColorMap);
        }

        void OnSceneGUI()
        {

            if (!editingCollider || script.colorMap == null)
                return;

            Bounds bounds = script.colorMap.bounds;
            Color color = script.enabled ? s_HandleColor : s_HandleColorDisabled;
            using (new Handles.DrawingScope(color, Matrix4x4.identity))
            {
                m_BoundsHandle.center = bounds.center;
                m_BoundsHandle.size = bounds.size;

                EditorGUI.BeginChangeCheck();
                m_BoundsHandle.DrawHandle();
                //m_BoundsHandle.axes = PrimitiveBoundsHandle.Axes.X | PrimitiveBoundsHandle.Axes.Z;

                if (EditorGUI.EndChangeCheck())
                {
                    Undo.RecordObject(script.colorMap, "Modified Grass color map bounds");
                    Vector3 center = m_BoundsHandle.center;
                    Vector3 size = m_BoundsHandle.size;

                    script.colorMap.bounds.center = center;
                    script.colorMap.bounds.size = size;
                    EditorUtility.SetDirty(target);
                }
            }
        }
    }
}
