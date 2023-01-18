using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using static KWS.KWS_CoreUtils;

namespace KWS
{
    public static class KW_WaterOrthoDepth
    {
        private const int WaterLayer = (1 << 4);

        [System.Serializable]
        public class OrthoDepthParams
        {
            [SerializeField] public int OtrhograpicSize;
            [SerializeField] public float PositionX;
            [SerializeField] public float PositionY;
            [SerializeField] public float PositionZ;
            public void SetData(int orthoSize, Vector3 pos)
            {
                OtrhograpicSize = orthoSize;
                PositionX = pos.x;
                PositionY = pos.y;
                PositionZ = pos.z;
            }
        }

        //public static void ReinitializeDepthTexture(TemporaryRenderTexture depth_rt, int size)
        //{
        //    depth_rt.RTAllocDepth("depthRT", size, size);
        //}

        public static Camera InitializeDepthCamera(float nearPlane, float farPlane, Transform parent)
        {

            var cameraGO = new GameObject("TopViewDepthCamera");
            cameraGO.transform.parent = parent;
            var depthCam = cameraGO.AddComponent<Camera>();

            depthCam.cameraType = CameraType.Reflection;
            depthCam.renderingPath = RenderingPath.Forward;
            depthCam.orthographic = true;
            depthCam.allowMSAA = false;
            depthCam.allowHDR = false;
            depthCam.nearClipPlane = nearPlane;
            depthCam.farClipPlane = farPlane;
            depthCam.transform.rotation = Quaternion.Euler(90, 0, 0);
            depthCam.enabled = false;

            return depthCam;
        }

        public static void RenderDepth(Camera cam, TemporaryRenderTexture depthRT, Vector3 position, int depthAreaSize, int depthTextureSize)
        {
            depthRT.AllocDepth("depthRT", depthTextureSize, depthTextureSize);

            cam.orthographicSize = depthAreaSize * 0.5f;
            cam.transform.position = position;
            cam.cullingMask = ~WaterLayer;
            cam.targetTexture = depthRT.rt;
            cam.Render();
            cam.targetTexture = null;
        }

        public static void SaveDepthTextureToFile(TemporaryRenderTexture depthRT, string path)
        {
            if (depthRT.rt == null)
            {
                Debug.LogError("Can't save ortho depth");
                return;
            }

          
            var tempRT = new RenderTexture(depthRT.rt.width, depthRT.rt.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            var activeRT = RenderTexture.active;
            Graphics.Blit(depthRT.rt, tempRT);
            tempRT.SaveRenderTextureToFile(path, TextureFormat.RFloat);
            RenderTexture.active = activeRT;
            tempRT.Release();
        }

        public static void SaveDepthDataToFile(OrthoDepthParams depthParams, string path)
        {
            KW_Extensions.SerializeToFile(path, depthParams);
        }

        public static void RenderAndSaveDepth(Transform parent, Vector3 position, int areaSize, int textureSize, float nearPlane, float farPlane, string pathToTexture, string pathToData)
        {
            var cam = InitializeDepthCamera(nearPlane, farPlane, parent);
            var depthRT = new TemporaryRenderTexture();
            depthRT.AllocDepth("depthRT", textureSize, textureSize);
            RenderDepth(cam, depthRT, position, areaSize, textureSize);

            var depthParams = new OrthoDepthParams();
            depthParams.SetData(areaSize, position);
            SaveDepthTextureToFile(depthRT, pathToTexture);
            SaveDepthDataToFile(depthParams, pathToData);
            KW_Extensions.SafeDestroy(cam.gameObject);
            depthRT.Release(true);
        }

        static Vector3?[,] GetSurfacePositions(WaterSystem waterSystem, Vector3 position, int textureSize, float areaSize)
        {
            var meshCollider = waterSystem.WaterMeshTransform.gameObject.AddComponent<MeshCollider>();
            meshCollider.sharedMesh = waterSystem.WaterMesh;

            areaSize /= 2;

            int halfTexSize             = textureSize / 2;
            var pixelsPetMeter        = halfTexSize / areaSize;
            var meshColliderMaxHeight = waterSystem.WorldSpaceBounds.max.y + 100;
           
            var surfacePositions = new Vector3?[textureSize, textureSize];
            var worldRay   = new Ray(Vector3.zero, Vector3.down);

            for (int y = 0; y < textureSize; y++)
            {
                for (int x = 0; x < textureSize; x++)
                {
                    worldRay.origin = new Vector3(position.x + (x - halfTexSize) / pixelsPetMeter, meshColliderMaxHeight, position.z + (y - halfTexSize) / pixelsPetMeter);
                    if (meshCollider.Raycast(worldRay, out var surfaceHit, 10000))
                    {
                        surfacePositions[x, y] = surfaceHit.point;
                    }
                }
            }
            KW_Extensions.SafeDestroy(meshCollider);
            return surfacePositions;
        }


        public static void RenderAndSaveDepthUsingRaycast(WaterSystem waterSystem, Vector3 position, int areaSize, int textureSize, float nearPlane, float farPlane, string pathToTexture, string pathToData)
        {
#if UNITY_EDITOR
            var currentHitBackfaces = Physics.queriesHitBackfaces;
            Physics.queriesHitBackfaces = true;

            var maxDepth = KWS_Settings.SurfaceDepth.MaxSurfaceDepthMeters;
            var colors = new Color[textureSize * textureSize];
            var surfacePositions = GetSurfacePositions(waterSystem, position, textureSize, areaSize);
            var maxRayDistanceAbove = 1.0f;

            for (int y = 0; y < textureSize; y++)
            {
                for (int x = 0; x < textureSize; x++)
                {
                    var depth                = 0f;
                    var surfacePointNullable = surfacePositions[x, y];
                    if (surfacePointNullable != null)
                    {
                        var surfacePoint = (Vector3) surfacePointNullable;

                        if (Physics.Raycast(surfacePoint, Vector3.down, out var hitDepth, maxDepth))
                        {
                            depth = hitDepth.distance;
                        }

                        if (Physics.Raycast(new Vector3(surfacePoint.x, surfacePoint.y + maxRayDistanceAbove, surfacePoint.z), Vector3.down, maxRayDistanceAbove))
                        {
                            depth = 0;
                        }

                        if (Physics.CheckSphere(surfacePoint, 0.1f))
                        {
                            depth = 0;
                        }
                    }

                    colors[y * textureSize + x] = new Color(depth * 0.1f, 0, 0, 1);
                }
            }

            var tempTex = new Texture2D(textureSize, textureSize, GraphicsFormat.R16_SFloat, TextureCreationFlags.None);
            tempTex.SetPixels(colors);
            tempTex.Apply();
            UnityEditor.EditorUtility.CompressTexture(tempTex, TextureFormat.BC4, UnityEditor.TextureCompressionQuality.Normal);

            var depthParams = new OrthoDepthParams();
            depthParams.SetData(areaSize, position);

            tempTex.SaveTextureToFile(pathToTexture);
            SaveDepthDataToFile(depthParams, pathToData);

            KW_Extensions.SafeDestroy(tempTex);
            Physics.queriesHitBackfaces = currentHitBackfaces;
#endif
        }
    }
}