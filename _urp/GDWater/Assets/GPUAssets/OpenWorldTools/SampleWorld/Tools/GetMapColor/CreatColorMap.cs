using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using System.IO;
public class CreatColorMap : MonoBehaviour
{
    public enum ColorMapSize
    {
        _64 = 0,
        _128,
        _256,
        _512,
        _1024,
        _2048
    }
    public ColorMapSize colorMapSize;

    public enum CreatType
    {
        Terrain = 0,
        Mesh
    }
    public CreatType creatType = CreatType.Terrain;

    public Terrain terrain;
    public float terrainHeight = 0;
    public Vector3 terrainSize;
    public Vector3 terrainCenter;
    public Vector3 terrainPos;
    public Vector4 terrainScaleOffset;

    public int intColorMapSize = 0;
    public Texture2D colorMap;

    public string savePath;

    private Vector3 oldTerrainPos;
    private TerrainData terrainData;
    private string shaderUnlit = "Cl/Terrain/Unlit";
    private Material oldMat;
    void Start()
    {

    }


    void Update()
    {

    }
    /// <summary>
    /// 根据ColorMap枚举获取目标尺寸
    /// </summary>
    /// <returns></returns>
    public int GetIntColorMapSize()
    {
        int result = 1024;
        switch (colorMapSize)
        {
            case ColorMapSize._64:
                result = 64;
                break;
            case ColorMapSize._128:
                result = 128;
                break;
            case ColorMapSize._256:
                result = 256;
                break;
            case ColorMapSize._512:
                result = 512;
                break;
            case ColorMapSize._1024:
                result = 1024;
                break;
            case ColorMapSize._2048:
                result = 2048;
                break;
            default:
                break;
        }

        return result;
    }
    public void OnInit()
    {
        savePath = null;
        terrain = this.gameObject.GetComponent<Terrain>();
        GetTerrainInfo();
    }

    public void GetTerrainInfo()
    {
        if (terrain == null) return;

        terrainData = terrain.terrainData;
        if (!CheckSize(terrainData.size.x, terrainData.size.z))
        {
            Debug.LogError("当前地形宽高比不均匀！无法生成");
        }

        if (terrainData.bounds.size.y > terrainHeight)
        {
            terrainHeight = terrainData.bounds.size.y;
        }
        terrainSize = terrainData.size;
        terrainPos = terrain.transform.position;
        terrainCenter = terrainPos + (terrainSize / 2f);

        terrainScaleOffset = new Vector4(terrainSize.x, terrainSize.z,
                                        Mathf.Abs(terrainPos.x), Mathf.Abs(terrainPos.z));
    }

    Light[] lights;
    AmbientMode ambientmode;
    Color ambientColor;
    bool enableFog;
    Light renderLight;
    public bool enableRenderLight = true;
    [Range(0,1)]
    public float renderLightIntensity = 0.25f;
    
    public void SetLight() 
    {
        lights = FindObjectsOfType<Light>();
        if (lights == null) return;
        //关闭所有方向光
        foreach (var item in lights)
        {
            if (item.type == LightType.Directional)
                item.gameObject.SetActive(false);
        }

        //保存当前环境配置
        ambientmode = RenderSettings.ambientMode;
        ambientColor = RenderSettings.ambientLight;
        enableFog = RenderSettings.fog;

        //设置RT渲染环境
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = Color.white;
        RenderSettings.fog = false;

        //设置RT渲染灯光
        if (enableRenderLight) 
        {
            if (renderLight == null) renderLight = new GameObject().AddComponent<Light>();

            renderLight.name = "OnlyRenderLight";
            renderLight.type = LightType.Directional;
            renderLight.transform.localEulerAngles = new Vector3(90, 0, 0);
            renderLight.intensity = renderLightIntensity;
        }
    }


    Camera renderCam;
    const int HEIGHTOFFSET = 1000;
    const int CLIP_PADDING = 10;
    public void SetCamera() 
    {
        if (renderCam == null) renderCam = new GameObject().AddComponent<Camera>();
        renderCam.name = this.name + "--OnlyRenderCamera";
       
        intColorMapSize = GetIntColorMapSize();
      
        float rectWidth = 1024;
        rectWidth /= Screen.width;
        renderCam.rect = new Rect(0, 0, rectWidth, 1);
        renderCam.orthographic = true;
        renderCam.orthographicSize = terrainSize.x / 2;
        renderCam.farClipPlane = 2000f;
        renderCam.useOcclusionCulling = false;
        
        renderCam.renderingPath = (enableRenderLight) ? RenderingPath.Forward : RenderingPath.VertexLit;
     
        Vector3 tempCameraPos = new Vector3();
        tempCameraPos.x = terrainCenter.x;
        tempCameraPos.y = terrainPos.y + terrainSize.y + HEIGHTOFFSET + CLIP_PADDING;
        tempCameraPos.z = terrainCenter.z;
        renderCam.transform.position = tempCameraPos;
        renderCam.transform.localEulerAngles = new Vector3(90, 0, 0);

        //设置地形材质
        oldMat = terrain.materialTemplate;
        terrain.materialTemplate = new Material(Shader.Find(shaderUnlit));

        //关闭地形树木绘制
        terrain.drawTreesAndFoliage = false;
        terrain.transform.position = new Vector3(terrain.transform.position.x, HEIGHTOFFSET, terrain.transform.position.z);      
    }
#if UNITY_EDITOR
    public void GetCameraRenderTexture() 
    {
        if (renderCam == null) return;
        colorMap = null;
        intColorMapSize = GetIntColorMapSize();
        RenderTexture rt = new RenderTexture(intColorMapSize, intColorMapSize, 24);
        renderCam.targetTexture = rt;
        savePath = SetTextureSavePath();

        UnityEditor.EditorUtility.DisplayProgressBar("ColorMap创建", "Rendering Texture", 1);
        Texture2D render = new Texture2D(intColorMapSize, intColorMapSize, TextureFormat.ARGB32, false);
        renderCam.Render();
        RenderTexture.active = rt;
        render.ReadPixels(new Rect(0, 0, intColorMapSize, intColorMapSize), 0, 0);

        byte[] bytes = render.EncodeToPNG();
        UnityEditor.EditorUtility.DisplayProgressBar("ColorMap", "Save Texture...", 1);
        File.WriteAllBytes(savePath, bytes);
        UnityEditor.AssetDatabase.Refresh();
        UnityEditor.EditorUtility.ClearProgressBar();
    }   
#endif
    void CleanUp() 
    {
        if (renderLight) DestroyImmediate(renderLight.gameObject);
        renderLight = null;

        if (renderCam) DestroyImmediate(renderCam.gameObject);
        renderCam = null;
    }
    public void Reset() 
    {
        foreach (var item in lights)
        {
          if (item.type == LightType.Directional)
                item.gameObject.SetActive(true);
        }

        RenderSettings.ambientMode = ambientmode;
        RenderSettings.ambientLight = ambientColor;
        RenderSettings.fog = enableFog;

        terrain.materialTemplate = oldMat;

        terrain.drawTreesAndFoliage = true;

        terrain.transform.position = terrainPos;

        CleanUp();
    }
    
#if UNITY_EDITOR
    public string  SetTextureSavePath() 
    {
        string result = "";
        result = UnityEditor.AssetDatabase.GetAssetPath(terrain.terrainData);
        result = result.Substring(0, result.LastIndexOf('/'));
        result = result+"/TerrainColorMap-"+".png";
        return result;
    }
#endif
    
    /// <summary>
    /// 粗略检测两个浮点数是否相等
    /// </summary>
    /// <param name="x"></param>
    /// <param name="z"></param>
    /// <returns></returns>
    public bool CheckSize(float x, float z)
    {
        return Mathf.Abs(x - z) < 0.01f;
    }
}
