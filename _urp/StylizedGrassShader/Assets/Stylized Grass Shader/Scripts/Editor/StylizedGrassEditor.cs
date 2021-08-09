using UnityEditor;
using UnityEngine;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
    public class StylizedGrassEditor : Editor
    {
        [MenuItem("GameObject/Effects/Grass Bender")]
        public static void CreateGrassBender()
        {
            GrassBender gb = new GameObject().AddComponent<GrassBender>();
            gb.gameObject.name = "Grass Bender";

            Selection.activeGameObject = gb.gameObject;
            EditorApplication.ExecuteMenuItem("GameObject/Move To View");
        }

#if URP
        public static ForwardRendererData GetGrassBendRendererInProject()
        {
            string GUID = "6646d2562bb9379498d38addaba2d66d";
            string assetPath = AssetDatabase.GUIDToAssetPath(GUID);

            if (assetPath == string.Empty)
            {
                Debug.LogError("The <i>" + DrawGrassBenders.AssetName + "</i> asset could not be found in the project. GUID should match " + GUID);
                return null;
            }
            ForwardRendererData data = (ForwardRendererData)AssetDatabase.LoadAssetAtPath(assetPath, typeof(ForwardRendererData));

            return data;
        }
#endif

        #region Context menus
        [MenuItem("CONTEXT/MeshFilter/Attach grass bender")]
        public static void ConvertMeshToBender(MenuCommand cmd)
        {
            MeshFilter mf = (MeshFilter)cmd.context;
            MeshRenderer mr = mf.gameObject.GetComponent<MeshRenderer>();

            if (!mf.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = mf.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.Mesh;
                bender.meshFilter = mf;
                bender.meshRenderer = mr;

            }
        }

        [MenuItem("CONTEXT/TrailRenderer/Attach grass bender")]
        public static void ConvertTrailToBender(MenuCommand cmd)
        {
            TrailRenderer t = (TrailRenderer)cmd.context;

            if (!t.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = t.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.Trail;
                bender.trailRenderer = t;
            }
        }

        [MenuItem("CONTEXT/ParticleSystem/Attach grass bender")]
        public static void ConvertParticleToBender(MenuCommand cmd)
        {
            ParticleSystem ps = (ParticleSystem)cmd.context;

            if (!ps.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = ps.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.ParticleSystem;
                bender.particleSystem = ps.GetComponent<ParticleSystem>();

                GrassBenderBase.ValidateParticleSystem(bender);
            }

        }
        #endregion
    }
}