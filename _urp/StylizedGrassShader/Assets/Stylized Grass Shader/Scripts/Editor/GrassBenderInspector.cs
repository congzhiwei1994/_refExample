using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace StylizedGrass
{
    [CustomEditor(typeof(GrassBender))]
    public class GrassBenderInspector : Editor
    {
        GrassBender bender;
        private Vector3[] points;
        private Vector3[] circlePoints;

        SerializedProperty benderType;
        private int m_benderType;
        SerializedProperty strength;
        SerializedProperty heightOffset;
        SerializedProperty scaleMultiplier;
        SerializedProperty pushStrength;
        SerializedProperty alphaBlending;

        //Mesh
        SerializedProperty meshFilter;
        SerializedProperty meshRenderer;
        SerializedProperty trailRenderer;

        //Trail
        SerializedProperty particleSystem;
        SerializedProperty trailLifetime;
        SerializedProperty trailRadius;
        SerializedProperty strengthOverLifetime;
        SerializedProperty widthOverLifetime;
        private int m_layer;

        private void OnEnable()
        {
            bender = (GrassBender)target;

            benderType = serializedObject.FindProperty("benderType");
            m_benderType = benderType.intValue;
            strength = serializedObject.FindProperty("strength");
            heightOffset = serializedObject.FindProperty("heightOffset");
            scaleMultiplier = serializedObject.FindProperty("scaleMultiplier");
            pushStrength = serializedObject.FindProperty("pushStrength");
            alphaBlending = serializedObject.FindProperty("alphaBlending");

            meshFilter = serializedObject.FindProperty("meshFilter");
            meshRenderer = serializedObject.FindProperty("meshRenderer");
            trailRenderer = serializedObject.FindProperty("trailRenderer");

            particleSystem = serializedObject.FindProperty("particleSystem");
            trailLifetime = serializedObject.FindProperty("trailLifetime");
            trailRadius = serializedObject.FindProperty("trailRadius");
            strengthOverLifetime = serializedObject.FindProperty("strengthOverLifetime");
            widthOverLifetime = serializedObject.FindProperty("widthOverLifetime");
        }

        public override void OnInspectorGUI()
        {
            if (StylizedGrassRenderer.Instance == null)
            {
                EditorGUILayout.HelpBox("No Stylized Grass Renderer is active in the scene", MessageType.Warning);
            }

            serializedObject.Update();

            EditorGUI.BeginChangeCheck();

            EditorGUILayout.PropertyField(benderType);

            if (benderType.intValue == (int)GrassBenderBase.BenderType.Mesh)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PropertyField(meshRenderer);

                    using (new EditorGUI.DisabledGroupScope(bender.meshRenderer ? bender.meshRenderer.gameObject == bender.gameObject : false))
                    {
                        if (GUILayout.Button("This", EditorStyles.miniButton, GUILayout.MaxWidth(75f)))
                        {
                            MeshRenderer meshRend = bender.GetComponent<MeshRenderer>();
                            if (meshRend) meshRenderer.objectReferenceValue = meshRend;
                            MeshFilter mf = bender.GetComponent<MeshFilter>();
                            if (mf) bender.meshFilter = mf;
                        }
                    }

                }

                EditorGUILayout.Space();

                StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Mesh"));
                using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
                {
                    EditorGUILayout.PropertyField(alphaBlending);
                    EditorGUILayout.PropertyField(scaleMultiplier);
                }
            }

            if (benderType.intValue == (int)GrassBenderBase.BenderType.Trail)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PropertyField(trailRenderer);

                    using (new EditorGUI.DisabledGroupScope(bender.trailRenderer ? bender.trailRenderer.gameObject == bender.gameObject : false))
                    {
                        if (GUILayout.Button("This", EditorStyles.miniButton, GUILayout.MaxWidth(75f)))
                        {
                            TrailRenderer trailRend = bender.GetComponent<TrailRenderer>();
                            if (trailRend) trailRenderer.objectReferenceValue = trailRend;
                        }
                    }
                }

                EditorGUILayout.Space();

                StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Trail"));
                using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
                {
                    EditorGUILayout.PropertyField(trailLifetime);
                    EditorGUILayout.PropertyField(trailRadius);

                    EditorGUI.BeginChangeCheck();
                    EditorGUILayout.PropertyField(strengthOverLifetime);
                    if (EditorGUI.EndChangeCheck())
                    {
                        bender.strengthGradient = GrassBenderBase.GetGradient(bender.strengthOverLifetime);
                    }
                    EditorGUILayout.PropertyField(widthOverLifetime);
                }
            }

            if (benderType.intValue == (int)GrassBenderBase.BenderType.ParticleSystem)
            {
                GrassBenderBase.ValidateParticleSystem(bender);

                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PropertyField(particleSystem);

                    using (new EditorGUI.DisabledGroupScope(bender.particleSystem ? bender.particleSystem.gameObject == bender.gameObject : false))
                    {
                        if (GUILayout.Button("This", EditorStyles.miniButton, GUILayout.MaxWidth(75f)))
                        {
                            ParticleSystem ps = bender.GetComponent<ParticleSystem>();
                            if (ps) particleSystem.objectReferenceValue = ps;
                        }
                    }

                }

                EditorGUILayout.Space();

                StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Particle System"));
                using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
                {
                    EditorGUILayout.PropertyField(alphaBlending);
                    EditorGUI.BeginChangeCheck();
                    EditorGUILayout.PropertyField(strengthOverLifetime);
                    if (EditorGUI.EndChangeCheck())
                    {
                        bender.strengthGradient = GrassBenderBase.GetGradient(bender.strengthOverLifetime);
                    }
                }
            }

            EditorGUILayout.Space();

            StylizedGrassGUI.ParameterGroup.DrawHeader(new GUIContent("Settings"));
            using (new EditorGUILayout.VerticalScope(StylizedGrassGUI.ParameterGroup.Section))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PrefixLabel(new GUIContent("Sorting layer", "Higher sorting layers are drawn on top of lower layers. Use this to control which benders draw over others"));
                    EditorGUI.BeginChangeCheck();
                    m_layer = GUILayout.Toolbar(m_layer, new string[] { "0", "1", "2", "3" }, GUILayout.Height(20f));
                    if (EditorGUI.EndChangeCheck())
                    {
                        bender.SwitchLayer(m_layer);
                    }
                    m_layer = bender.sortingLayer;
                }
                EditorGUILayout.PropertyField(heightOffset);
                EditorGUILayout.PropertyField(strength);
                EditorGUILayout.PropertyField(pushStrength);
            }

            if (EditorGUI.EndChangeCheck())
            {
                if (benderType.intValue != m_benderType) bender.SwitchBenderType((GrassBenderBase.BenderType)benderType.intValue);
                m_benderType = benderType.intValue;

                //bender.UpdateTrail();
                //bender.UpdateMesh();

                serializedObject.ApplyModifiedProperties();
            }

            //base.OnInspectorGUI();
        }


        private void OnSceneGUI()
        {
            if (bender.benderType != GrassBenderBase.BenderType.Trail || bender.trailRenderer == null) return;

            points = new Vector3[bender.trailRenderer.positionCount];
            bender.trailRenderer.GetPositions(points);
            Handles.color = Color.white;

            circlePoints = new Vector3[16];
            for (int i = 0; i < 16; i++)
            {
                float angle = i * Mathf.PI * 2 / 15;
                circlePoints[i] = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle)) * bender.trailRadius * 0.5f;
                circlePoints[i] += bender.transform.position;
            }
            Handles.color = new Color(1, 1, 1, 0.5f);
            UnityEditor.Handles.DrawAAPolyLine(Texture2D.whiteTexture, 2.5f, circlePoints);

            Handles.color = new Color(1, 1, 1, 0.1f);
            Handles.DrawSolidDisc(bender.transform.position, Vector3.up, bender.trailRadius * 0.5f);

            DrawDottedLines(points, 5f);
        }

        public void DrawDottedLines(Vector3[] lineSegments, float screenSpaceSize)
        {
            //UnityEditor.Handles.BeginGUI();
            var dashSize = screenSpaceSize * UnityEditor.EditorGUIUtility.pixelsPerPoint;
            for (int i = 0; i < lineSegments.Length - 1; i += 2)
            {
                var p1 = lineSegments[i + 0];
                var p2 = lineSegments[i + 1];

                if (p1 == null || p2 == null) continue;

                Handles.color = new Color(1, 1, 1, 1f - bender.strengthOverLifetime.Evaluate((float)i / (float)lineSegments.Length));
                UnityEditor.Handles.DrawAAPolyLine(Texture2D.whiteTexture, dashSize, new Vector3[] { p1, p2 });
            }
            //UnityEditor.Handles.EndGUI();

        }

    }
}
