using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_WaterLights
    {
        #region public variables

        public const int MaxShadowPointLights = 4;
        public const int MaxShadowSpotLights = 4;

        public static Camera            CachedCamera;
        public static Plane[]           CachedCameraFrustumPlanes;
        public static List<VolumeLight> Lights = new List<VolumeLight>();

        public static readonly Dictionary<LightType, Dictionary<int, LightShadowmapPropertyID>> LightShadowmapID = new Dictionary<LightType, Dictionary<int, LightShadowmapPropertyID>>
        {
            { 
                LightType.Directional, new Dictionary<int, LightShadowmapPropertyID>() 
                {
                    { 0, new LightShadowmapPropertyID("KWS_DirLightShadowMap0") }, 
                } 
            },

            { 
                LightType.Point,  new Dictionary<int, LightShadowmapPropertyID>()
                {
                    { 0, new LightShadowmapPropertyID("KWS_PointLightShadowMap0")},
                    { 1, new LightShadowmapPropertyID("KWS_PointLightShadowMap1")},
                    { 2, new LightShadowmapPropertyID("KWS_PointLightShadowMap2")},
                    { 3, new LightShadowmapPropertyID("KWS_PointLightShadowMap3")},
                }
            },

            {
                LightType.Spot, new Dictionary<int, LightShadowmapPropertyID>()
                {
                    { 0, new LightShadowmapPropertyID("KWS_SpotLightShadowMap0")},
                    { 1, new LightShadowmapPropertyID("KWS_SpotLightShadowMap1")},
                    { 2, new LightShadowmapPropertyID("KWS_SpotLightShadowMap2")},
                    { 3, new LightShadowmapPropertyID("KWS_SpotLightShadowMap3")},
                }
            },
        };

        public class LightShadowmapPropertyID
        {
            public string ShadowmapName;
            public int ShadowmapNameID;
            
            public LightShadowmapPropertyID(string name)
            {
                ShadowmapName = name;
                ShadowmapNameID = Shader.PropertyToID(name);
            }
        }

        public static readonly Dictionary<LightType, float> LightShadowMapSizeMultiplier = new Dictionary<LightType, float> //target size for spot/points[128-512] and dir[512-2048]
        {
            { LightType.Spot, 0.25f},
            { LightType.Directional, 1f},
            { LightType.Point, 0.125f}
        };

        public static readonly Dictionary<LightType, LightEvent> LightShadowsEvents = new Dictionary<LightType, LightEvent>
        {
            { LightType.Spot, LightEvent.AfterShadowMap},
            { LightType.Directional, LightEvent.AfterShadowMap},
            { LightType.Point, LightEvent.AfterShadowMapPass}
        };


        public static readonly Dictionary<LightType, TextureDimension> LightShadowsDimension = new Dictionary<LightType, TextureDimension>
        {
            { LightType.Spot, TextureDimension.Tex2D},
            { LightType.Directional, TextureDimension.Tex2D},
            { LightType.Point, TextureDimension.Cube}
        };

        public static readonly Dictionary<LightType, Stack<int>> FreeShadowIndexes = new Dictionary<LightType, Stack<int>>
        {
              { LightType.Spot, new Stack<int>(new[] { 3, 2, 1, 0 })},
              { LightType.Directional, new Stack<int>(new[] { 0 })},
              { LightType.Point, new Stack<int>(new[] { 3, 2, 1, 0 })},
              { LightType.Area, new Stack<int>()},
        };

        public class VolumeLight
        {
            public Light Light;
            public Transform LightTransform;
            public int ShadowIndex = -1;
            public bool IsVisible;
            public bool UseVolumetricShadows;
            public float SqrDistanceToCamera = float.MaxValue;
            public Action<Vector3> LightUpdate;
            public Action ReleaseLight;
        }

        public struct LightData
        {
            public Vector4 color;
            public float range;

            public Vector3 forward;
            public Vector3 position;
            public Vector4 attenuation;
        }

        public struct ShadowLightData
        {
            public Vector4 color;
            public float range;

            public Vector3 forward;
            public Vector3 position;
            public Vector4 attenuation;

            public int shadowIndex;
            public Matrix4x4 worldToShadow;
            public Vector4 projectionParams;
            public float shadowStrength;
        }

        public enum VolumeLightRenderMode
        {
            LightOnly,
            ShadowAndLight
        }

        public enum ShadowDownsampleEnum
        {
             None = 1,
            _2x = 2,
            _4x = 4
        }

        public readonly static Dictionary<int, int> VolumetricPointLightShadowResolutionSize = new Dictionary<int, int>
        {
              { 4, 32},
              { 3, 64},
              { 2, 128},
              { 1, 256},
              { 0, 512}
        };

        public readonly static Dictionary<LightShadowResolution, int> StandardDirLightShadowResolutionSize = new Dictionary<LightShadowResolution, int>
        {
            { LightShadowResolution.FromQualitySettings, -1},
            { LightShadowResolution.Low, 1024},
            { LightShadowResolution.Medium, 2048},
            { LightShadowResolution.High, 4096},
            { LightShadowResolution.VeryHigh, 4096}
        };

        public readonly static Dictionary<LightShadowResolution, int> StandardPointLightShadowResolutionSize = new Dictionary<LightShadowResolution, int>
        {
            { LightShadowResolution.FromQualitySettings, -1},
            { LightShadowResolution.Low, 256},
            { LightShadowResolution.Medium, 512},
            { LightShadowResolution.High, 1024},
            { LightShadowResolution.VeryHigh, 1024}
        };

        public readonly static Dictionary<LightShadowResolution, int> StandardSpotLightShadowResolutionSize = new Dictionary<LightShadowResolution, int>
        {
            { LightShadowResolution.FromQualitySettings, -1},
            { LightShadowResolution.Low, 512},
            { LightShadowResolution.Medium, 1024},
            { LightShadowResolution.High, 2048},
            { LightShadowResolution.VeryHigh, 2048}
        };

        #endregion
    }
}
