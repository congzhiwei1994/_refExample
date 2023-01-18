using System.Collections.Generic;
using UnityEngine;
using static KWS.WaterSystem;

namespace KWS
{
    public static class KWS_Settings
    {
        public static class Water
        {
            public static readonly int DefaultWaterQueue = 2999;
            public static readonly int WaterLayer = 4; //water layer bit mask
            public static readonly float UpdatePositionEveryMeters = 5.0f;
            public static readonly int MaxNormalsAnisoLevel = 4;
            public static readonly int MaxRefractionDispersion = 5;
            public static readonly int DefaultCubemapCullingMask = 32;
            public static readonly float DomainSize = 20f;
            public static readonly float DomainSize_LOD1 = 40f;
            public static readonly float DomainSize_LOD2 = 160f;

            public static readonly float MeshChunkSize = 40;
            public static readonly float TesselationMeshChunkSize = 10;
            public static readonly int SplineRiverMinVertexCount = 5;
            public static readonly int SplineRiverMaxVertexCount = 25;

            public static readonly float MaxTesselationFactorInfinite = 15;
            public static readonly float MaxTesselationFactorFiniteMin = 5;
            public static readonly float MaxTesselationFactorFiniteMax = 25;
            public static readonly float MaxTesselationFactorRiver = 5;
            public static readonly float MaxTesselationFactorOther = 15;

            public static readonly int TesselationInfiniteMeshQuality = 5;
            public static readonly int TesselationFiniteMeshQualityMin = 10;
            public static readonly int TesselationFiniteMeshQualityMax = 40;
            public static readonly float TesselationFiniteMeshQualityRange = 1000;
        }

        public static class DataPaths
        {
            public static readonly string CausticFolder = "CausticMaps";
            public static readonly string CausticDepthTexture = "KW_CausticDepthTexture";
            public static readonly string CausticDepthData = "KW_CausticDepthData";

            public static readonly string FlowmapFolder = "FlowMaps";
            public static readonly string FlowmapTexture = "FlowMapTexture";
            public static readonly string FlowmapData = "FlowMapData";

            public static readonly string SplineFolder = "Splines";
            public static readonly string SplineData = "SplineData";
        }

        public static class ShaderPaths
        {
            public static readonly string KWS_PlatformSpecificHelpers = @"Resources/PlatformSpecific/KWS_PlatformSpecificHelpers.cginc";
            public static readonly string KWS_WaterTesselated = @"Resources/PlatformSpecific/KWS_WaterTesselated.shader";
            public static readonly string KWS_Water = @"Resources/PlatformSpecific/KWS_Water.shader";
            public static readonly string KWS_FoamParticles = @"Resources/PlatformSpecific/KWS_FoamParticles.shader";
        }

        public static class Caustic
        {
            public static readonly int CausticCameraDepth_Near = -1;
            public static readonly int CausticCameraDepth_Far = 50;
        }

        public static class SurfaceDepth
        {
            public static readonly float MaxSurfaceDepthMeters = 50;
        }

        public static class Shoreline
        {
            public static readonly int ShadowParticlesDivider = 4;
        }

        public static class VolumetricLighting
        {
            public static readonly bool UseFastBilateralMode = false;
        }

        public static class Reflection
        {
            public static readonly float MaxSunStrength = 3;
        }

        public static class DynamicWaves
        {
            public static readonly int MaxDynamicWavesTexSize = 2048;
        }
    }
}
