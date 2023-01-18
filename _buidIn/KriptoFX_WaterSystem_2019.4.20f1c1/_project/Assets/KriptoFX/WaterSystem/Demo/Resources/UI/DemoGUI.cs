using KWS;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;
#if UNITY_POST_PROCESSING_STACK_V2
using UnityEngine.Rendering.PostProcessing;
#endif
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class DemoGUI: MonoBehaviour
{
    public GameObject button;
    public GameObject slider;

    public Camera cam;
    public Light sun;
    public GameObject environment;
    public WaterSystem water;
#if UNITY_POST_PROCESSING_STACK_V2
    public PostProcessLayer posteffects;
#endif
    public GameObject terrain;
    public Terrain terrainDetails;
    // public SEGI segiPostFX;
    public VolumetricLightRenderer volumeLightRend;
    public VolumetricLight volumeLight;
    public PlayableDirector timeline;

    int buttonOffset = 35;
    int sliderOffset = 25;
    Vector2 currentElementOffset;

    List<GameObject> waterUIElements = new List<GameObject>();

    GameObject CreateButton(string text, Action action, bool currentActive, bool isWaterElement, params string[] prefixStatus)
    {
        var instance = Instantiate(button, transform);
        if (isWaterElement) waterUIElements.Add(instance);
        var uiElement = instance.GetComponent<KWS_DemoUIElement>();
        uiElement.Initialize(text, action, currentActive, prefixStatus);
       
        uiElement.Rect.anchoredPosition = currentElementOffset;
        currentElementOffset.y -= buttonOffset;
        return instance;
    }

    GameObject CreateSlider(string text, Action<float> action, bool isWaterElement = false)
    {
        var instance = Instantiate(slider, transform);
        if (isWaterElement) waterUIElements.Add(instance);
        var uiElement = instance.GetComponent<KWS_DemoUIElement>();
        uiElement.Initialize(text, action);
        uiElement.Rect.anchoredPosition = currentElementOffset;
        currentElementOffset.y -= sliderOffset;
        return instance;
    }

    void Start () 
    {
//#if KWS_DEBUG
//        var notes = GetComponentInChildren<Text>();
//        if(notes != null) notes.enabled = false;
//#endif

        currentElementOffset = new Vector2(10, -10);

        CreateButton("Next Scene", () =>
        {
            var currentSceneID = SceneManager.GetActiveScene().buildIndex;
            if (currentSceneID < SceneManager.sceneCountInBuildSettings - 1) currentSceneID++;
            else currentSceneID = 0;
            SceneManager.LoadScene(currentSceneID);
        }, currentActive: true, false);

        CreateButton("Previous Scene", () =>
         {
             var currentSceneID = SceneManager.GetActiveScene().buildIndex;
             if (currentSceneID > 0) currentSceneID--;
             else currentSceneID = 0;
             SceneManager.LoadScene(currentSceneID);
         },
            currentActive: true, false);

        if (sun != null)
        {
            CreateButton("Shadows", () =>
            {
                sun.shadows = (sun.shadows == LightShadows.None) ? sun.shadows = LightShadows.Soft : LightShadows.None;
            }, 
            currentActive: true, false, "On", "Off");
        }

        if(environment != null)
        {
            CreateButton("Environment", () =>
            {
                environment.gameObject.SetActive(!environment.gameObject.activeSelf);
            },
           currentActive: true, false, "On", "Off");
        }

        if (terrain != null)
        {
            CreateButton("Terrain", () =>
            {
                terrain.SetActive(!terrain.activeSelf);
            },
           currentActive: true, false, "On", "Off");
        }

        if (terrainDetails != null)
        {
            CreateButton("Terrain details", () =>
            {
                terrainDetails.drawTreesAndFoliage = !terrainDetails.drawTreesAndFoliage;
            },
            currentActive: true, false, "On", "Off");
        }

#if UNITY_POST_PROCESSING_STACK_V2
        if (posteffects != null)
        {
            CreateButton("Post processing", () =>
            {
                posteffects.enabled = !posteffects.enabled;
                if (volumeLightRend != null) volumeLightRend.enabled = posteffects.enabled;
                if (volumeLight != null && volumeLight.enabled && !posteffects.enabled) 
                {
                    volumeLight.GetComponent<Light>().RemoveAllCommandBuffers(); 
                    volumeLight.enabled = posteffects.enabled; 
                }
                
            },
           currentActive: true, false, "On", "Off");
        }
#endif

        if (water != null)
        {
            CreateButton("Water", () =>
            {
                water.gameObject.SetActive(!water.gameObject.activeSelf);
                SetWaterUIElementsActiveStatus(water.gameObject.activeSelf);
            },
           currentActive: true, false, "On", "Off");
        }

        InitializeWaterUI();

        CreateButton("Quit", () =>
        {
            Application.Quit();
        }, currentActive: true, false);
    }

    void SetWaterUIElementsActiveStatus(bool isActive)
    {
        foreach(var element in waterUIElements)
        {
            element.SetActive(isActive);
        }
    }
    int shorelineQuality = 1;
    void InitializeWaterUI()
    {
        currentElementOffset.y -= 50;
        CreateSlider("Transparent", (sliderVal) =>
        {
            water.Transparent = Mathf.Lerp(0.1f, 20f, sliderVal);
        }, true);

        CreateButton("Reflection mode", () =>
        {
            if (water.ReflectionMode == WaterSystem.ReflectionModeEnum.CubemapReflection) water.ReflectionMode = WaterSystem.ReflectionModeEnum.ScreenSpaceReflection;
            else if (water.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection) water.ReflectionMode = WaterSystem.ReflectionModeEnum.PlanarReflection;
            else water.ReflectionMode = WaterSystem.ReflectionModeEnum.CubemapReflection;
        },
        currentActive: true, true, "SSR", "Planar", "Sky");

        CreateButton("Flowing", () =>
        {
            water.UseFlowMap = !water.UseFlowMap;
        },
        currentActive: water.UseFlowMap, true, "On", "Off");

        CreateButton("Dynamic waves", () =>
        {
            water.UseDynamicWaves = !water.UseDynamicWaves;
        },
        currentActive: water.UseDynamicWaves, true, "On", "Off");

        CreateButton("Shoreline", () =>
        {
            water.UseShorelineRendering = !water.UseShorelineRendering;
        },
        currentActive: water.UseShorelineRendering, true, "On", "Off");
        CreateButton("Foam Quality", () =>
        {
            shorelineQuality++;
            if (shorelineQuality == 3) shorelineQuality = 0;

            if (shorelineQuality == 0)
            {
                water.FoamLodQuality = WaterSystem.QualityEnum.Low;
                water.FoamCastShadows = false;
                water.FoamReceiveShadows = false;
            }
            else if (shorelineQuality == 1)
            {
                water.FoamLodQuality = WaterSystem.QualityEnum.Medium;
                water.FoamCastShadows = true;
                water.FoamReceiveShadows = true;
            }
            else if (shorelineQuality == 2)
            {
                water.FoamLodQuality = WaterSystem.QualityEnum.High;
                water.FoamCastShadows = true;
                water.FoamReceiveShadows = true;
            }
        },
        currentActive: water.UseShorelineRendering, true, "Medium", "High", "Low");

        CreateButton("Volumetric Lighting", () =>
        {
            water.UseVolumetricLight = !water.UseVolumetricLight;
        },
        currentActive: water.UseVolumetricLight, true, "On", "Off");

        CreateButton("Caustic Effect", () =>
        {
            water.UseCausticEffect = !water.UseCausticEffect;
        },
        currentActive: water.UseCausticEffect, true, "On", "Off");

        CreateButton("Underwater Effect", () =>
        {
            water.UseUnderwaterEffect = !water.UseUnderwaterEffect;
        },
        currentActive: water.UseUnderwaterEffect, true, "On", "Off");

        CreateButton("Draw to Depth", () =>
                     {
                         water.DrawToPosteffectsDepth = !water.DrawToPosteffectsDepth;
                     },
                     currentActive: water.DrawToPosteffectsDepth, true, "On", "Off");

        CreateButton("Use Tesselation", () =>
        {
            water.UseTesselation = !water.UseTesselation;
            water.InitializeWaterMaterial(water.UseTesselation);
        },
         currentActive: water.UseTesselation, true, "On", "Off");
    }

}
