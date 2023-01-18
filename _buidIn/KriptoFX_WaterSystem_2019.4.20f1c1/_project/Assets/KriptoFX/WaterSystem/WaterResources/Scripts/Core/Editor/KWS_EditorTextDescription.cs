using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace KWS
{
    public class KWS_EditorTextDescription
    {
        public static class Color
        {
            public static readonly string Transparent    = "Opacity in meters";
            public static readonly string WaterColor     = "This is the solution color of clean water without impurities";
            public static readonly string TurbidityColor = "Color of suspended particles, such as algae or dirt";
            public static readonly string Turbidity      = "Total suspended solids in water, water purity";
        }

        public static class Waves
        {
            public static readonly string FFT_SimulationSize = "Higher detailing mean the better waves quality, but the worse the performance.";

            public static readonly string WindSpeed = "Wind speed in meters. Wind force of more than 1 meter per second requires additional stimulation " +
                                                      "and therefore performance is slightly slower";

            public static readonly string WindRotation   = "Wind rotation in degrees";
            public static readonly string WindTurbulence = "Wind turbulence creates chaotic wave fluctuations.";
            public static readonly string TimeScale      = "Time speed multiplier of wave simulation";
        }

        public static class Reflection
        {
            public static readonly string ReflectionMode = "Cubemap(reflection probe) : Often used only for sky rendering and almost performance free because you can update it for example once per minute." +
                                                          Environment.NewLine                                                                                                                               +
                                                          Environment.NewLine                                                                                                                               +
                                                          "Screen space reflection: the fastest method of rendering reflections in real time(it's faster then other SSR methods), use it if possible. "      +
                                                          "It's also the only way to render the correct fog"                                                                                                + Environment.NewLine +
                                                          "SSR can reflect only visible screen pixels (for example, you will not see what is under the skirt in the reflection of a puddle xD). "               + Environment.NewLine +
                                                          "Also, reflections may have some artifacts (holes, information lost, leaking incorrect pixels, etc)"                                              +
                                                          Environment.NewLine                                                                                                                               +
                                                          Environment.NewLine                                                                                                                               +
                                                          "Planar reflection: expensive because it render a scene twice, but can reflect accurate reflections with transparent geometry";

            public static readonly string PlanarReflectionResolutionQuality = "Higher resolution means better reflection quality, but worse performance.";
            public static readonly string ScreenSpaceReflectionResolutionQuality = PlanarReflectionResolutionQuality;
            public static readonly string CubemapReflectionResolutionQuality = PlanarReflectionResolutionQuality;
            public static readonly string ReflectionClipPlaneOffset = "Use this option to hide artifacts near the water's edge";
            public static readonly string ReflectioDepthHolesFillDistance = "Used to fill holes in the screen space reflection.";
            public static readonly string CubemapCullingMask = "Best practice is to leave only the sky rendering (layers=nothing), since the rendering of other layers looks wrong when the camera is moved.";

            public static readonly string CubemapUpdateInterval = "Cubemap rendering in real time requires rendering the scene 6(!) times for each side. " +
                                                                  "Therefore, it is strongly recommended to update the cube as rarely as possible, for example once a minute.";

            public static readonly string UsePlanarCubemapReflection = "Sometimes, for example when you are in a dark cave, the reflection of the water can reflect the bright sky." + Environment.NewLine +
                                                                "Uncheck this toggle, and select all layers (CubemapCullingMask) for baking correct indoor reflection";

            public static readonly string UseAnisotropicReflections = "Approximation of more realistic blur on the far distance";
            public static readonly string AnisotropicReflectionsScale = "Anisotropic (vertical) blur scale on the far distance";
            public static readonly string AnisotropicReflectionsHighQuality = "Higher detailing mean the better blur reflection (less noise), but the worse the performance.";
            public static readonly string ReflectSun = "Reflect first directional light source";
            public static readonly string ReflectedSunCloudinessStrength = "By default the sun is reflected from a clear sky. In some cases (for example when cloudy) the reflection will be incorrect.";
            public static readonly string ReflectedSunStrength = "Sun reflection intensity";

        }

        public static class Refraction
        {
            public static readonly string RefractionMode = "When light travels from air into water, it slows down, causing it to change direction slightly. This change of direction is called refraction. " + Environment.NewLine + Environment.NewLine +
                                                           "'Physical Aproximation IOR' : Ii looks more realistic, but has some distortion artifacts (since this is a screen space technique), and slower than simple refraction." + Environment.NewLine + Environment.NewLine +
                                                           "'Simple refraction': uses water normals for distortion, this is a very fast method and does not have some artifacts, but it looks less realistic.";

            public static readonly string RefractionAproximatedDepth = "The approximation uses the average water depth in meters, so the greater depth value -> the higher distortion and refraction.";

            public static readonly string RefractionSimpleStrength = "Distortion strength relative to the water normals";

            public static readonly string UseRefractionDispersion = "Light waves will bend varying amounts upon passage through a water. The separation of light into its different colors is known as dispersion. " + Environment.NewLine +
                                                                    "Sometimes it can be seen as a rainbow on the edges of objects with strong distortion";

            public static readonly string RefractionDispersionStrength = "The higher the value, the more noticeable the rainbow effect on the edges of objects";
        }

        public static class Flowing
        {
            public static readonly string FlowingNotInitialized = @"'Flowing' is activated, but the 'flowmap texture' hasn't been initialized yet. Use 'FlowMap Painter' and save the result.";
            public static readonly string FlowingDescription = "A 'flow map' stores water flow directional information in a texture. " +
                                                               "When drawing with a brush, you will draw the direction of the water flow (for example, a river) to texture";

            public static readonly string FlowingEditorUsage = "\"Left Mouse Click\" for painting "  + Environment.NewLine +
                                                               "Hold \"Ctrl Button\" for erase mode" + Environment.NewLine +
                                                               "Use \"Mouse Wheel\" for brush size";

            public static readonly string LoadLatestSaved = "Are you sure you want to RELOAD latest flowmap texture?" + Environment.NewLine +
                                                            "All new changes will be deleted and the last saved texture will be loaded.";

            public static readonly string DeleteAll = "Are you sure you want to DELETE flowmap texture?" + Environment.NewLine +
                                                      "All changes and flowmap texture will be deleted";

            public static readonly string FlowMapAreaPosition = "Drawing area position (in world space)";
            public static readonly string FlowMapAreaSize = "Drawing area size in meters. Less area -> better flow detailing";
            public static readonly string FlowMapTextureResolution = "The higher resolution -> better flow detailing";
            public static readonly string FlowMapSpeed = "Velocity(speed) multiplier of all flow map";
            public static readonly string FlowMapBrushStrength = "The higher the value, the faster flow speed that you draw";
            
            public static readonly string UseFluidsSimulation = "Used to simulate dynamic flow of river and foam";

            public static readonly string FluidSimulationUsage = "Fluids simulation calculate dynamic flow around static objects."              + Environment.NewLine +
                                                                 "Step 1: draw the flow direction on the current flowmap (use flowmap painter)" + Environment.NewLine +
                                                                 "Step 2: save flowmap"                                                         + Environment.NewLine +
                                                                 "Step 3: press the button 'Bake Fluids Obstacles'";

            public static readonly string FluidsSimulationIterrations = "The more iterations, the faster the animation of the fluids simulation. " + Environment.NewLine +
                                                                        "But it affects performance! 4 iterations are 4 times slower than 1 iteration!";

            public static readonly string FluidsTextureSize = "Higher detailing means better waves quality, but worse performance.";
            public static readonly string FluidsAreaSize = "The simulation area in meters around the camera.";
            public static readonly string FluidsSpeed = "Velocity of flow";
            public static readonly string FluidsFoamStrength = "The foam strength relative to the flow velocity";
        }

        public static class DynamicWaves
        {
            public static readonly string Usage = "You must add the script 'KW_InteractWithWater' to your moving objects";
            public static readonly string DynamicWavesAreaSize = "The simulation area size in meters around the camera.";
            public static readonly string DynamicWavesResolutionPerMeter = "Higher detailing means better waves quality, but worse performance.";
            public static readonly string DynamicWavesPropagationSpeed = "Velocity of waves";
            public static readonly string UseDynamicWavesRainEffect = "Use rain simulation in the dynamic waves area size";
            public static readonly string DynamicWavesRainStrength = "The higher value-> more raindrops";
        }

        public static class Shoreline
        {
            public static readonly string Usage = "Enable volumetric lighting to receive foam shadows!";
            public static readonly string FoamLodQuality = "Foam particles count";
            public static readonly string FoamCastShadows = "Cast shadows";
            public static readonly string FoamReceiveShadows = "Receive Shadows (a very expensive for performance)";
            public static readonly string FoamShadowsRequiredVolumetric = "Enable volumetric lighting to receive foam shadows!";
            public static readonly string FoamShadowsUsageWarning = "Foam shadows receiving DRASTICALLY reduces FPS! It is not recommended to use this setting without a high-end GPU!";

            public static readonly string ShorelineEditorUsage = "You must add shoreline waves only in the drawing area." + Environment.NewLine +
                                                                 "Avoid crossing boxes of the same color."                + Environment.NewLine +
                                                                 "Use Insert/Delete buttons for Add/Delete waves at the current mouse position.";

            public static readonly string ShorelineAreaPosition = "Shoreline area position (in world space). "               +
                                                                  "You must add shoreline waves only in this drawing area. " +
                                                                  "Outside of this area, waves will not be displayed correctly.";

            public static readonly string ShorelineAreaSize = "Area size in meters for baked waves. Less area -> less memory usage";
            public static readonly string ShorelineCurvedSurfacesQuality = "Quality of rendering foam around curved obstacles, for example rocks";
            public static readonly string DeleteAll = "Are you sure you want to DELETE shoreline waves?";
        }

        public static class VolumetricLight
        {
            public static readonly string ResolutionQuality = "The resolution of the volumetric lighting texture. Higher resolutions mean better quality, but worse performance.";
            public static readonly string Iterations        = "Higher iteration count mean the more detailed shadows/light and less noise, but worse performance.";

            public static readonly string Filter = $"Bilateral filter preserves sharp edges but it is a bit more expensive then other filters.{Environment.NewLine}" +
                                                   $"Gaussian filter is faster, but also creates halo artifacts around objects";

            public static readonly string BlurRadius = "A high blur radius reduces noise artifacts, but greatly blurs the boundaries of shadows/light";
        }

        public static class Caustic
        {
            public static readonly string UseCausticDispersion = "Light waves will bend varying amounts upon passage through a water. The separation of light into its different colors is known as dispersion. " + Environment.NewLine +
                                                                 "Sometimes it can be seen as a rainbow on the edges of caustic";

            public static readonly string UseCausticBicubicInterpolation = "Improves the quality of caustic detailing (more smoothed) by averaging the adjacent pixels.";
            public static readonly string CausticTextureSize             = "Higher detailing means better caustic quality, but worse performance.";
            public static readonly string CausticMeshResolution          = "Higher detailing means better caustic quality, but worse performance.";
            public static readonly string CausticActiveLods              = "The greater the number of cascades, the further the caustic rendering distance";
            public static readonly string CausticStrength                = "Caustic light intensity";
            public static readonly string CausticDepthScale         = "Caustic size/strength multiplier";

            public static readonly string CausticOrthoDepthPosition = "World space area position";
            public static readonly string CausticOrthoDepthAreaSize = "World space area size where the caustic depth will be saved";
            public static readonly string CausticOrthoDepthTextureResolution = "Higher detailing means better waves quality, but requires more memory.";
            public static readonly string UseDepthCausticScale = "In the real world, the caustic strength and size depend on the depth. More depth -> stronger caustic light";
        }

        public static class Underwater
        {
            public static readonly string UseUnderwaterBlur = "Underwater blur helps to hide low-resolution quality, so it's faster for rendering. It is recommended to use it with low-resolution to improve performance!";
            public static readonly string UnderwaterBlurRadius = "The strength of the blur. The higher value -> the worse performance";
        }

        public static class Mesh
        {
            public static readonly string WaterMeshType = "'InfiniteOcean : A mesh with the size relative to 'camera.farDistance', which is tied to the position of the current camera."          + Environment.NewLine + Environment.NewLine +
                                                          "'FiniteBox' A cube mesh with the custom size"                                                                                          + Environment.NewLine + Environment.NewLine +
                                                          "'River' In this mode, a river mesh is generated using splines (control points). "                                                      + Environment.NewLine +
                                                          "Some functions that require a constant water height do not work in this mode (because rivers have different heights at each vertex). " + Environment.NewLine +
                                                          "Will not work: planar reflections, ssr reflections, dynamic waves, shoreline waves"                                                    + Environment.NewLine + Environment.NewLine +
                                                          "'CustomMesh' You can assign any mesh, but volumetric lighting, caustics, underwater effect will only work if you use a volumetric mesh (for example, box instead of plane)";

            public static readonly string MeshQuality = "Water mesh detailing. It's recommended to use tessellation instead, since with tessellation all invisible vertices is discarded and performance may be higher.";

            public static readonly string UseTesselation = "Tessellation dynamically increases the mesh detail (triangles count) depending on the distance. " + Environment.NewLine +
                                                           "A huge number of triangles greatly affects performance! Choose as little detail as possible!";
            public static readonly string TesselationFactor = "Higher tesselation factor means better mesh detailing, but worse performance.";
            public static readonly string TesselationMaxDistance = "Higher tesselation distance means better mesh detailing at distance, but worse performance.";

            public static readonly string RiverUsage = "In this mode, a river mesh is generated using splines (control points)." + Environment.NewLine +
                                                       "Step 1:  Press the button 'Add River' " + Environment.NewLine +
                                                       "Step 2:  Left click on the ground and set the starting point of your river" + Environment.NewLine +
                                                       "Step 3:  Press SHIFT + LEFT click to add a new point." + Environment.NewLine +
                                                       "Ctrl + Left click deletes the selected point." + Environment.NewLine +
                                                       "Use 'scale tool' (or R button) to change the river width" + Environment.NewLine +
                                                       "Step 4:  A minimum of 3 points is required to create a river. Place the points approximately at the same distance and avoid strong curvature of the mesh (otherwise you will see red intersections and artifacts)" + Environment.NewLine +
                                                       "Step 5:  Press 'Save Changes'";

            public static readonly string RiverSplineNormalOffset = "Height offset(relative to the ground level) when setting a new point";
            public static readonly string RiverSplineVertexCountBetweenPoints = "Grid detailing between two points. Higher value means better mesh detailing, but worse performance.";
            public static readonly string RiverDeleteAll = "Are you sure you want to DELETE selected river?";
        }

        public static class Rendering
        {
            public static readonly string ThirdPartyFogWarnign = "You use a third-party fog in the water->rendering tab. Water will not work correctly if a third-party package is not installed, or it's not used in the scene!";

            public static readonly string UseFiltering = "Improves the quality of normal detailing by averaging the adjacent pixels. Allows you to overcome the effects of aliasing and adds smoothing normals.";
            public static readonly string UseAnisotropicFiltering = "Anisotropic filtering makes distant normals look more detailed. Almost no effect on performance";
            public static readonly string DrawToPosteffectsDepth = "Write water depth to the scene depth buffer after transparent geometry." + Environment.NewLine +
                                                                   "Required for correct rendering of \"Depth Of Field\" post effect";
        }
    }
}

