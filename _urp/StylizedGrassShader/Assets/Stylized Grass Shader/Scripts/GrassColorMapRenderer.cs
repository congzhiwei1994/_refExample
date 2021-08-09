using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif
using UnityEngine;
using UnityEngine.Rendering;

namespace StylizedGrass
{
    [AddComponentMenu("Stylized Grass/Colormap Renderer")]
    [ExecuteInEditMode]
    public class GrassColorMapRenderer : MonoBehaviour
    {
        public static GrassColorMapRenderer Instance;

        public GrassColorMap colorMap;
        [Tooltip("These objects can be Unity Terrains or custom Mesh Terrains. Their size can be used to automatically fit the render area")]
        public List<GameObject> terrainObjects = new List<GameObject>();
        public int resIdx = 4;
        public int resolution = 1024;
        [Tooltip("Objects set to this layer will be included in the render")]
        public LayerMask renderLayer;
        [Tooltip("Render objects on specific layers into the color map. When disabled, the terrain(s) are temporarily moved up 1000 units")]
        public bool useLayers = false;
        public Camera renderCam;
        [NonSerialized]
        public bool showBounds = true;

        [Serializable]
        public class LayerScaleSettings
        {
            public int layerID;
            [Range(0f, 1f)]
            public float strength = 1f;
        }
        public List<LayerScaleSettings> layerScaleSettings;

        private void OnEnable()
        {
            Instance = this;
            AssignColorMap();

#if UNITY_EDITOR
            if (this.gameObject.name == "GameObject") this.gameObject.name = "Grass Colormap renderer";

            EditorSceneManager.sceneSaved += OnSceneSave;
#endif
        }

        private void OnDisable()
        {
            Instance = null;
            //Disable sampling of color map
            GrassColorMap.DisableGlobally();

#if UNITY_EDITOR
            EditorSceneManager.sceneSaved -= OnSceneSave;
#endif
        }

        private void OnDrawGizmosSelected()
        {
            if (!colorMap || !showBounds) return;

            Color32 color = new Color(0f, 0.66f, 1f, 0.25f);
            Gizmos.color = color;
            Gizmos.DrawCube(colorMap.bounds.center, colorMap.bounds.size);

            color = new Color(0f, 0.66f, 1f, 1f);
            Gizmos.color = color;
            Gizmos.DrawWireCube(colorMap.bounds.center, colorMap.bounds.size);
        }

        public void AssignColorMap()
        {
            if (!colorMap) return;

            colorMap.SetActive();
        }

#if UNITY_EDITOR
        private void OnSceneSave(UnityEngine.SceneManagement.Scene scene)
        {
            AssignColorMap();
        }
#endif
    }
}