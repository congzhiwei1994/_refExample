using System;
using System.Collections.Generic;
using static KWS.WaterSystem;

namespace KWS
{
    public static class KWS_EditorProfiles
    {
        private const float tolerance = 0.001f;

        public interface IWaterPerfomanceProfile
        {
            WaterProfileEnum GetProfile(WaterSystem water);
            void SetProfile(WaterProfileEnum profile, WaterSystem water);
            void ReadDataFromProfile(WaterSystem water);
            void CheckDataChangesAnsSetCustomProfile(WaterSystem water);
        }

        public static class PerfomanceProfiles
        {
            public struct Reflection : IWaterPerfomanceProfile
            {
                static readonly ReflectionModeEnum ReflectionMode = ReflectionModeEnum.ScreenSpaceReflection;

                static readonly Dictionary<WaterProfileEnum, PlanarReflectionResolutionQualityEnum> PlanarReflectionResolutionQuality = new Dictionary<WaterProfileEnum, PlanarReflectionResolutionQualityEnum>()
                {
                    {WaterProfileEnum.Ultra, PlanarReflectionResolutionQualityEnum.Ultra},
                    {WaterProfileEnum.High, PlanarReflectionResolutionQualityEnum.High},
                    {WaterProfileEnum.Medium,  PlanarReflectionResolutionQualityEnum.Medium},
                    {WaterProfileEnum.Low,  PlanarReflectionResolutionQualityEnum.Low},
                    {WaterProfileEnum.PotatoPC,  PlanarReflectionResolutionQualityEnum.VeryLow},
                };

                static readonly Dictionary<WaterProfileEnum, ScreenSpaceReflectionResolutionQualityEnum> ScreenSpaceReflectionResolutionQuality = new Dictionary<WaterProfileEnum, ScreenSpaceReflectionResolutionQualityEnum>()
                {
                    {WaterProfileEnum.Ultra, ScreenSpaceReflectionResolutionQualityEnum.Ultra},
                    {WaterProfileEnum.High, ScreenSpaceReflectionResolutionQualityEnum.High},
                    {WaterProfileEnum.Medium, ScreenSpaceReflectionResolutionQualityEnum.Medium},
                    {WaterProfileEnum.Low, ScreenSpaceReflectionResolutionQualityEnum.Low},
                    {WaterProfileEnum.PotatoPC, ScreenSpaceReflectionResolutionQualityEnum.VeryLow},
                };

                static readonly Dictionary<WaterProfileEnum, CubemapReflectionResolutionQualityEnum> CubemapReflectionResolutionQuality = new Dictionary<WaterProfileEnum, CubemapReflectionResolutionQualityEnum>()
                {
                    {WaterProfileEnum.Ultra, CubemapReflectionResolutionQualityEnum.High},
                    {WaterProfileEnum.High, CubemapReflectionResolutionQualityEnum.High},
                    {WaterProfileEnum.Medium, CubemapReflectionResolutionQualityEnum.Medium},
                    {WaterProfileEnum.Low, CubemapReflectionResolutionQualityEnum.Low},
                    {WaterProfileEnum.PotatoPC, CubemapReflectionResolutionQualityEnum.Low},
                };

                static readonly Dictionary<WaterProfileEnum, float> CubemapUpdateInterval = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra,  6},
                    {WaterProfileEnum.High,  6},
                    {WaterProfileEnum.Medium,  6},
                    {WaterProfileEnum.Low,   6},
                    {WaterProfileEnum.PotatoPC,  60},
                };

                static readonly Dictionary<WaterProfileEnum, bool> UseAnisotropicReflections = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, true},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                static readonly Dictionary<WaterProfileEnum, bool> AnisotropicReflectionsHighQuality = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, false},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                static readonly Dictionary<WaterProfileEnum, float> AnisotropicReflectionsScale = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra,  0.85f},
                    {WaterProfileEnum.High,  0.55f},
                    {WaterProfileEnum.Medium,   0.4f},
                    {WaterProfileEnum.Low,   0.4f},
                    {WaterProfileEnum.PotatoPC,  0.4f},
                };

                static readonly Dictionary<WaterProfileEnum, float> ReflectionClipPlaneOffset = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra,  0.01f},
                    {WaterProfileEnum.High,  0.0085f},
                    {WaterProfileEnum.Medium,   0.0065f},
                    {WaterProfileEnum.Low,   0.0065f},
                    {WaterProfileEnum.PotatoPC,  0.0065f},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.ReflectionProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.ReflectionProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.ReflectionProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.ReflectionMode                         = ReflectionMode;
                        water.PlanarReflectionResolutionQuality      = PlanarReflectionResolutionQuality[currentProfile];
                        water.ScreenSpaceReflectionResolutionQuality = ScreenSpaceReflectionResolutionQuality[currentProfile];
                        water.CubemapReflectionResolutionQuality     = CubemapReflectionResolutionQuality[currentProfile];
                        water.CubemapUpdateInterval                  = CubemapUpdateInterval[currentProfile];
                        water.UseAnisotropicReflections              = UseAnisotropicReflections[currentProfile];
                        water.AnisotropicReflectionsHighQuality      = AnisotropicReflectionsHighQuality[currentProfile];
                        water.AnisotropicReflectionsScale            = AnisotropicReflectionsScale[currentProfile];
                        water.ReflectionClipPlaneOffset              = ReflectionClipPlaneOffset[currentProfile];
                    }
                }


                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.ReflectionProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.ReflectionMode                                                                           != ReflectionMode) isChanged                                         = true;
                        else if (water.PlanarReflectionResolutionQuality                                                   != PlanarReflectionResolutionQuality[currentProfile]) isChanged      = true;
                        else if (water.ScreenSpaceReflectionResolutionQuality                                              != ScreenSpaceReflectionResolutionQuality[currentProfile]) isChanged = true;
                        else if (water.CubemapReflectionResolutionQuality                                                  != CubemapReflectionResolutionQuality[currentProfile]) isChanged     = true;
                        else if (Math.Abs(water.CubemapUpdateInterval - CubemapUpdateInterval[currentProfile])             > tolerance) isChanged                                               = true;
                        else if (water.UseAnisotropicReflections                                                           != UseAnisotropicReflections[currentProfile]) isChanged              = true;
                        else if (water.AnisotropicReflectionsHighQuality                                                   != AnisotropicReflectionsHighQuality[currentProfile]) isChanged      = true;
                        else if (Math.Abs(water.AnisotropicReflectionsScale - AnisotropicReflectionsScale[currentProfile]) > tolerance) isChanged                                               = true;
                        else if (Math.Abs(water.ReflectionClipPlaneOffset   - ReflectionClipPlaneOffset[currentProfile])   > tolerance) isChanged                                               = true;

                        if (isChanged) water.ReflectionProfile = WaterProfileEnum.Custom;
                    }
                }

            }

            public struct ColorRerfraction : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, RefractionModeEnum> RefractionMode = new Dictionary<WaterProfileEnum, RefractionModeEnum>
                {
                    {WaterProfileEnum.Ultra, RefractionModeEnum.PhysicalAproximationIOR},
                    {WaterProfileEnum.High, RefractionModeEnum.PhysicalAproximationIOR},
                    {WaterProfileEnum.Medium, RefractionModeEnum.PhysicalAproximationIOR},
                    {WaterProfileEnum.Low, RefractionModeEnum.Simple},
                    {WaterProfileEnum.PotatoPC, RefractionModeEnum.Simple}
                };

                public static readonly Dictionary<WaterProfileEnum, bool> UseRefractionDispersion = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.RefractionProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.RefractionProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.RefractionProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.RefractionMode          = RefractionMode[currentProfile];
                        water.UseRefractionDispersion = UseRefractionDispersion[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.RefractionProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.RefractionMode               != RefractionMode[currentProfile]) isChanged          = true;
                        else if (water.UseRefractionDispersion != UseRefractionDispersion[currentProfile]) isChanged = true;

                        if (isChanged) water.RefractionProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct Flowing : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, FlowmapTextureResolutionEnum> FlowMapTextureResolution = new Dictionary<WaterProfileEnum, FlowmapTextureResolutionEnum>()
                {
                    {WaterProfileEnum.Ultra, FlowmapTextureResolutionEnum._4096},
                    {WaterProfileEnum.High, FlowmapTextureResolutionEnum._4096},
                    {WaterProfileEnum.Medium, FlowmapTextureResolutionEnum._2048},
                    {WaterProfileEnum.Low, FlowmapTextureResolutionEnum._1024},
                    {WaterProfileEnum.PotatoPC, FlowmapTextureResolutionEnum._512},
                };

                public static readonly Dictionary<WaterProfileEnum, int> FluidsSimulationIterrations = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 3},
                    {WaterProfileEnum.High, 2},
                    {WaterProfileEnum.Medium, 2},
                    {WaterProfileEnum.Low, 2},
                    {WaterProfileEnum.PotatoPC, 2},
                };

                public static readonly Dictionary<WaterProfileEnum, int> FluidsTextureSize = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 2048},
                    {WaterProfileEnum.High, 1536},
                    {WaterProfileEnum.Medium, 1024},
                    {WaterProfileEnum.Low, 768},
                    {WaterProfileEnum.PotatoPC, 512},
                };

                public static readonly Dictionary<WaterProfileEnum, int> FluidsAreaSize = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 45},
                    {WaterProfileEnum.High, 35},
                    {WaterProfileEnum.Medium, 25},
                    {WaterProfileEnum.Low, 20},
                    {WaterProfileEnum.PotatoPC, 15},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.FlowmapProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.FlowmapProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.FlowmapProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.FlowMapTextureResolution    = FlowMapTextureResolution[currentProfile];
                        water.FluidsSimulationIterrations = FluidsSimulationIterrations[currentProfile];
                        water.FluidsTextureSize           = FluidsTextureSize[currentProfile];
                        water.FluidsAreaSize              = FluidsAreaSize[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.FlowmapProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.FlowMapTextureResolution         != FlowMapTextureResolution[currentProfile]) isChanged    = true;
                        else if (water.FluidsSimulationIterrations != FluidsSimulationIterrations[currentProfile]) isChanged = true;
                        else if (water.FluidsTextureSize           != FluidsTextureSize[currentProfile]) isChanged           = true;
                        else if (water.FluidsAreaSize              != FluidsAreaSize[currentProfile]) isChanged              = true;

                        if (isChanged) water.FlowmapProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct DynamicWaves : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, int> DynamicWavesAreaSize = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 60},
                    {WaterProfileEnum.High, 50},
                    {WaterProfileEnum.Medium, 40},
                    {WaterProfileEnum.Low, 30},
                    {WaterProfileEnum.PotatoPC, 20},
                };

                public static readonly Dictionary<WaterProfileEnum, int> DynamicWavesResolutionPerMeter = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 34},
                    {WaterProfileEnum.High, 34},
                    {WaterProfileEnum.Medium, 34},
                    {WaterProfileEnum.Low, 25},
                    {WaterProfileEnum.PotatoPC, 20},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.DynamicWavesProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.DynamicWavesProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.DynamicWavesProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.DynamicWavesAreaSize           = DynamicWavesAreaSize[currentProfile];
                        water.DynamicWavesResolutionPerMeter = DynamicWavesResolutionPerMeter[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.DynamicWavesProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.DynamicWavesAreaSize                != DynamicWavesAreaSize[currentProfile]) isChanged           = true;
                        else if (water.DynamicWavesResolutionPerMeter != DynamicWavesResolutionPerMeter[currentProfile]) isChanged = true;

                        if (isChanged) water.DynamicWavesProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct Shoreline : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, QualityEnum> FoamLodQuality = new Dictionary<WaterProfileEnum, QualityEnum>()
                {
                    {WaterProfileEnum.Ultra, QualityEnum.High},
                    {WaterProfileEnum.High, QualityEnum.Medium},
                    {WaterProfileEnum.Medium, QualityEnum.Medium},
                    {WaterProfileEnum.Low, QualityEnum.Low},
                    {WaterProfileEnum.PotatoPC, QualityEnum.Low},
                };

                public static readonly Dictionary<WaterProfileEnum, bool> FoamCastShadows = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, true},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public static readonly Dictionary<WaterProfileEnum, bool> FoamReceiveShadows = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.ShorelineProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.ShorelineProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.ShorelineProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.FoamLodQuality     = FoamLodQuality[currentProfile];
                        water.FoamCastShadows    = FoamCastShadows[currentProfile];
                        water.FoamReceiveShadows = FoamReceiveShadows[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.ShorelineProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.FoamLodQuality          != FoamLodQuality[currentProfile]) isChanged     = true;
                        else if (water.FoamCastShadows    != FoamCastShadows[currentProfile]) isChanged    = true;
                        else if (water.FoamReceiveShadows != FoamReceiveShadows[currentProfile]) isChanged = true;

                        if (isChanged) water.ShorelineProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct VolumetricLight : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, VolumetricLightResolutionQualityEnum> VolumetricLightResolutionQuality = new Dictionary<WaterProfileEnum, VolumetricLightResolutionQualityEnum>()
                {
                    {WaterProfileEnum.Ultra, VolumetricLightResolutionQualityEnum.Ultra},
                    {WaterProfileEnum.High, VolumetricLightResolutionQualityEnum.High},
                    {WaterProfileEnum.Medium, VolumetricLightResolutionQualityEnum.Medium},
                    {WaterProfileEnum.Low, VolumetricLightResolutionQualityEnum.Low},
                    {WaterProfileEnum.PotatoPC, VolumetricLightResolutionQualityEnum.VeryLow},
                };

                public static readonly Dictionary<WaterProfileEnum, int> VolumetricLightIteration = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 8},
                    {WaterProfileEnum.High, 6},
                    {WaterProfileEnum.Medium, 4},
                    {WaterProfileEnum.Low, 3},
                    {WaterProfileEnum.PotatoPC, 2},
                };

                public static readonly Dictionary<WaterProfileEnum, VolumetricLightFilterEnum> VolumetricLightFilter = new Dictionary<WaterProfileEnum, VolumetricLightFilterEnum>()
                {
                    {WaterProfileEnum.Ultra, VolumetricLightFilterEnum.Bilateral},
                    {WaterProfileEnum.High, VolumetricLightFilterEnum.Bilateral},
                    {WaterProfileEnum.Medium, VolumetricLightFilterEnum.Bilateral},
                    {WaterProfileEnum.Low, VolumetricLightFilterEnum.Gaussian},
                    {WaterProfileEnum.PotatoPC, VolumetricLightFilterEnum.Gaussian},
                };

                public static readonly Dictionary<WaterProfileEnum, float> VolumetricLightBlurRadius = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra, 1f},
                    {WaterProfileEnum.High, 1f},
                    {WaterProfileEnum.Medium, 1f},
                    {WaterProfileEnum.Low, 2.5f},
                    {WaterProfileEnum.PotatoPC, 3.5f},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.VolumetricLightProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.VolumetricLightProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.VolumetricLightProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.VolumetricLightResolutionQuality = VolumetricLightResolutionQuality[currentProfile];
                        water.VolumetricLightIteration         = VolumetricLightIteration[currentProfile];
                        water.VolumetricLightFilter            = VolumetricLightFilter[currentProfile];
                        water.VolumetricLightBlurRadius        = VolumetricLightBlurRadius[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.VolumetricLightProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.VolumetricLightResolutionQuality                                                     != VolumetricLightResolutionQuality[currentProfile]) isChanged = true;
                        else if (water.VolumetricLightIteration                                                        != VolumetricLightIteration[currentProfile]) isChanged         = true;
                        else if (water.VolumetricLightFilter                                                           != VolumetricLightFilter[currentProfile]) isChanged            = true;
                        else if (Math.Abs(water.VolumetricLightBlurRadius - VolumetricLightBlurRadius[currentProfile]) > tolerance) isChanged                                         = true;

                        if (isChanged) water.VolumetricLightProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct Caustic : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, bool> UseCausticBicubicInterpolation = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, false},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public static readonly Dictionary<WaterProfileEnum, bool> UseCausticDispersion = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public static readonly Dictionary<WaterProfileEnum, int> CausticTextureSize = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 1024},
                    {WaterProfileEnum.High, 768},
                    {WaterProfileEnum.Medium, 512},
                    {WaterProfileEnum.Low, 384},
                    {WaterProfileEnum.PotatoPC, 256},
                };

                public static readonly Dictionary<WaterProfileEnum, int> CausticMeshResolution = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 384},
                    {WaterProfileEnum.High, 320},
                    {WaterProfileEnum.Medium, 256},
                    {WaterProfileEnum.Low, 192},
                    {WaterProfileEnum.PotatoPC, 128},
                };

                public static readonly Dictionary<WaterProfileEnum, int> CausticActiveLods = new Dictionary<WaterProfileEnum, int>()
                {
                    {WaterProfileEnum.Ultra, 4},
                    {WaterProfileEnum.High, 4},
                    {WaterProfileEnum.Medium, 3},
                    {WaterProfileEnum.Low, 2},
                    {WaterProfileEnum.PotatoPC, 1},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.CausticProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.CausticProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.CausticProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.UseCausticBicubicInterpolation = UseCausticBicubicInterpolation[currentProfile];
                        water.UseCausticDispersion           = UseCausticDispersion[currentProfile];
                        water.CausticTextureSize             = CausticTextureSize[currentProfile];
                        water.CausticMeshResolution          = CausticMeshResolution[currentProfile];
                        water.CausticActiveLods              = CausticActiveLods[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.CausticProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.UseCausticBicubicInterpolation != UseCausticBicubicInterpolation[currentProfile]) isChanged = true;
                        else if (water.UseCausticDispersion      != UseCausticDispersion[currentProfile]) isChanged           = true;
                        else if (water.CausticTextureSize        != CausticTextureSize[currentProfile]) isChanged             = true;
                        else if (water.CausticMeshResolution     != CausticMeshResolution[currentProfile]) isChanged          = true;
                        else if (water.CausticActiveLods         != CausticActiveLods[currentProfile]) isChanged              = true;

                        if (isChanged) water.CausticProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct Mesh : IWaterPerfomanceProfile
            {
                public static readonly bool UseTesselation = true;

                public static readonly Dictionary<WaterProfileEnum, float> TesselationFactor = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra, 1.0f},
                    {WaterProfileEnum.High, 0.75f},
                    {WaterProfileEnum.Medium, 0.5f},
                    {WaterProfileEnum.Low, 0.25f},
                    {WaterProfileEnum.PotatoPC, 0.15f},
                };

                public static readonly Dictionary<WaterProfileEnum, float> TesselationInfiniteMeshMaxDistance = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra, 2000},
                    {WaterProfileEnum.High, 1000},
                    {WaterProfileEnum.Medium, 500},
                    {WaterProfileEnum.Low, 200},
                    {WaterProfileEnum.PotatoPC, 100},
                };

                public static readonly Dictionary<WaterProfileEnum, float> TesselationOtherMeshMaxDistance = new Dictionary<WaterProfileEnum, float>()
                {
                    {WaterProfileEnum.Ultra, 150},
                    {WaterProfileEnum.High, 100},
                    {WaterProfileEnum.Medium, 50},
                    {WaterProfileEnum.Low, 25},
                    {WaterProfileEnum.PotatoPC, 10},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.MeshProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.MeshProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.MeshProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.UseTesselation                     = UseTesselation;
                        water.TesselationFactor                  = TesselationFactor[currentProfile];
                        water.TesselationInfiniteMeshMaxDistance = TesselationInfiniteMeshMaxDistance[currentProfile];
                        water.TesselationOtherMeshMaxDistance    = TesselationOtherMeshMaxDistance[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.MeshProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.UseTesselation                                                                                         != UseTesselation) isChanged = true;
                        else if (Math.Abs(water.TesselationFactor                  - TesselationFactor[currentProfile])                  > tolerance) isChanged       = true;
                        else if (Math.Abs(water.TesselationInfiniteMeshMaxDistance - TesselationInfiniteMeshMaxDistance[currentProfile]) > tolerance) isChanged       = true;
                        else if (Math.Abs(water.TesselationOtherMeshMaxDistance    - TesselationOtherMeshMaxDistance[currentProfile])    > tolerance) isChanged       = true;

                        if (isChanged) water.MeshProfile = WaterProfileEnum.Custom;
                    }
                }
            }

            public struct Rendering : IWaterPerfomanceProfile
            {
                public static readonly Dictionary<WaterProfileEnum, bool> UseFiltering = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, true},
                    {WaterProfileEnum.Medium, true},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public static readonly Dictionary<WaterProfileEnum, bool> UseAnisotropicFiltering = new Dictionary<WaterProfileEnum, bool>()
                {
                    {WaterProfileEnum.Ultra, true},
                    {WaterProfileEnum.High, false},
                    {WaterProfileEnum.Medium, false},
                    {WaterProfileEnum.Low, false},
                    {WaterProfileEnum.PotatoPC, false},
                };

                public WaterProfileEnum GetProfile(WaterSystem water)
                {
                    return water.RenderingProfile;
                }

                public void SetProfile(WaterProfileEnum profile, WaterSystem water)
                {
                    water.RenderingProfile = profile;
                }

                public void ReadDataFromProfile(WaterSystem water)
                {
                    var currentProfile = water.RenderingProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        water.UseFiltering            = UseFiltering[currentProfile];
                        water.UseAnisotropicFiltering = UseAnisotropicFiltering[currentProfile];
                    }
                }

                public void CheckDataChangesAnsSetCustomProfile(WaterSystem water)
                {
                    var currentProfile = water.RenderingProfile;
                    if (currentProfile != WaterProfileEnum.Custom)
                    {
                        var isChanged = false;

                        if (water.UseFiltering                 != UseFiltering[currentProfile]) isChanged            = true;
                        else if (water.UseAnisotropicFiltering != UseAnisotropicFiltering[currentProfile]) isChanged = true;

                        if (isChanged) water.RenderingProfile = WaterProfileEnum.Custom;
                    }
                }
            }
        }
    }
}