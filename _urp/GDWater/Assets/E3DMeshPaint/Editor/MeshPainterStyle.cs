using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections;
using System.Collections.Generic;

[CustomEditor(typeof(E3DMeshPainter))]
[CanEditMultipleObjects]
public class MeshPainterStyle : Editor
{
    private E3DMeshPainter _target;
    private UnityEngine.Object monoScript;

    private MeshShaderType ShaderNames;
    private MeshShaderType idleShaderNames;

    private Tool LastTool = Tool.None;

    public enum MeshPaintTexNumber
    {
        Three,
        Four,
    }
    string contolTexName = "";

    bool isPaint;
    bool isDebug = false;
    float brushSize = 16f;
    float brushStronger = 0.5f;

    Texture[] brushTex;
    Texture[] texLayer;

    int selBrush = 0;
    int selTex = 0;

    //private MeshPaintTexNumber meshPaintTexNumber = MeshPaintTexNumber.Three;
    bool hasFourProperty = false;
    int brushSizeInPourcent;
    Texture2D MaskTex;

    bool isNoneFourTexture = false;

    private List<string> shadernames = new List<string>();
    private List<string> useLayers = new List<string>();
    void OnSceneGUI()
    {
        if (isPaint)
        {
            Painter();
            //强制每一帧绘制
            SceneView.RepaintAll();
        }
    }


    private void OnEnable()
    {
        _target = (E3DMeshPainter)target;
        this.monoScript = MonoScript.FromMonoBehaviour(this.target as MonoBehaviour);

        Transform Select = _target.transform;
        //Transform Select = Selection.activeTransform;

        //LastTool = Tools.current;
        //Tools.current = Tool.Move;//===========2020-11-05========//
        
        #region 数据检索
        string controlTexFolder = MeshPainterStringUtility.contolTexFolder;
        if (!MeshPainterStringUtility.Exists(controlTexFolder))
        {
            string r = MeshPainterStringUtility.RelativePath(MeshPainterStringUtility.FindPath(Application.dataPath, "Controler") + "/");
            MeshPainterStringUtility.contolTexFolder = r;
            Debug.Log("modify folder path:" + r);

        }

        string meshPaintEditorFolder = MeshPainterStringUtility.meshPaintEditorFolder;
        if (!MeshPainterStringUtility.Exists(meshPaintEditorFolder))
        {
            //Debug.Log("相对路径"+ Application.dataPath);
            string temp = MeshPainterStringUtility.FindPath(Application.dataPath, "Brushes");
            //Debug.Log("修正文件夹路径:"+   Directory.GetParent(temp));
            string t = Directory.GetParent(temp).ToString();
            string r = MeshPainterStringUtility.RelativePath(t + "/");
            Debug.Log("modify folder path:" + r);
            MeshPainterStringUtility.meshPaintEditorFolder = r;
        }
        //===================================================================================================//
        string[] findDatas;
        string result = "";
        if (File.Exists(MeshPainterStringUtility.shaderNameDatas + MeshPainterStringUtility.fileExr))
        {
            ShaderNames = AssetDatabase.LoadAssetAtPath<MeshShaderType>(MeshPainterStringUtility.shaderNameDatas + MeshPainterStringUtility.fileExr);
        }
        else
        {
            findDatas = AssetDatabase.FindAssets("MeshPaintShaderDatas");
            foreach (var item in findDatas)
            {
                if (result == "") result = AssetDatabase.GUIDToAssetPath(item).ToString();
            }
            //Debug.Log(result);
            ShaderNames = AssetDatabase.LoadAssetAtPath<MeshShaderType>(result);
        }
        if (File.Exists(MeshPainterStringUtility.idleShaderNameDatas + MeshPainterStringUtility.fileExr))
        {
            idleShaderNames = AssetDatabase.LoadAssetAtPath<MeshShaderType>(MeshPainterStringUtility.idleShaderNameDatas + MeshPainterStringUtility.fileExr);
        }
        else
        {
            findDatas = AssetDatabase.FindAssets("DefaultShaderDatas");
            foreach (var item in findDatas)
            {
                result = AssetDatabase.GUIDToAssetPath(item).ToString();
            }
            //Debug.Log(result);
            idleShaderNames = AssetDatabase.LoadAssetAtPath<MeshShaderType>(result);
        }
        #endregion

        if (ShaderNames != null && ShaderNames.shaders.Count > 0)
        {
            string tempName = "";

            for (int i = 0; i < ShaderNames.shaders.Count; i++)
            {
                tempName = ShaderNames.shaders[i].shaderName;
                if (!shadernames.Contains(tempName))
                {
                    shadernames.Add(tempName);
                }
            }
            string layerName = "";
            for (int i = 0; i < ShaderNames.layers.Count; i++)
            {
                layerName = ShaderNames.layers[i];
                if (!useLayers.Contains(layerName))
                {
                    useLayers.Add(layerName);
                }
            }
        }
        else
        {
            Debug.Log("<color=red>" + "See the current shader data file path does not exist：" + "Assets/ThirdPartys/MeshPaint/ScriptsData/MeshPaintShaderDatas" + "</color>");
        }

        if (Select)
            CheakLayer(Select);
    }

    private void OnDisable()
    {
        //Tools.current = LastTool;
        isPaint = false;
        brushOrthValue = 2;
        isUseLayer = false;
        isTargerLayer = false;
        lastLayer = "";
        seletMeshrender = null;

        //切换目标时保存数据
        if (ShaderNames)
            EditorUtility.SetDirty(ShaderNames);

        if (idleShaderNames)
            EditorUtility.SetDirty(idleShaderNames);
    }
    int brushOrthValue = 2;

    private bool isCheak = false;

    /// <summary>
    /// 检测对象层级
    /// </summary>
    /// <param name="Select"></param>
    private void CheakLayer(Transform Select)
    {
        if (Select == null) return;
        string tempLayer = LayerMask.LayerToName(Select.gameObject.layer);

        if (lastLayer != tempLayer)
        {
            isUseLayer = false;
            lastLayer = tempLayer;
        }
        if (ShaderNames && useLayers.Count > 0)
        {
            for (int i = 0; i < useLayers.Count; i++)
            {
                if (useLayers[i] == tempLayer)
                {
                    if (isUseLayer != true)
                        isUseLayer = true;
                    return;
                }
            }
        }
    }

    public override void OnInspectorGUI()
    {
        EditorGUI.BeginDisabledGroup(true);
        EditorGUILayout.ObjectField("Script", this.monoScript, typeof(MonoScript), false);
        EditorGUI.EndDisabledGroup();

        Repaint();

        //Transform Select = Selection.activeTransform;
        Transform Select = _target.transform;

        CheakLayer(Select);
        if (isUseLayer == false)
        {
            EditorGUILayout.HelpBox("Layer the current model does error！，Replace！", MessageType.Error);
            return;
        }

        isCheak = Cheak();

        if (isCheak == true && isUseLayer == true && ShaderNames != null)
        {
            //=================================================Switch Drawing==========================================================================
            // GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            GUIStyle boolBtnOn = new GUIStyle(GUI.skin.GetStyle("Button"));//Get Button Style

            isPaint = GUILayout.Toggle(isPaint, EditorGUIUtility.IconContent("EditCollider"), boolBtnOn, GUILayout.Width(35), GUILayout.Height(25));//编辑模式开关       
            if (isPaint == true)
            {
                Tools.hidden = true;
                LastTool = Tools.current;
                Tools.current = Tool.Move;
            }
            else
            {
                Tools.hidden = false;
                //Tools.current = Tool.Move;//2020-11-4--->锁定Move-Tool
            }

            GUILayout.FlexibleSpace();
            GUILayout.EndHorizontal();

            //=================================================Brush attributes==========================================================================
            //meshPaintTexNumber = (MeshPaintTexNumber)EditorGUILayout.EnumPopup("MeshPaintTexNumber:", meshPaintTexNumber);//meshPaintTexNumber

            brushSize = (int)EditorGUILayout.Slider("Brush Size", brushSize, 1, 50);//Brush size
            brushStronger = EditorGUILayout.Slider("Brush Stronger", brushStronger, 0, 1f);//Brush Strength
            brushOrthValue = (int)EditorGUILayout.Slider("Brush OrthographicSize", brushOrthValue, 2, 10);

            isDebug = EditorGUILayout.Toggle("Show UV", isDebug);
            EditorGUILayout.ObjectField("Drawable Shader Data： ", ShaderNames, typeof(MeshShaderType), true);

            //=================================================Get maps Brush======================================================================

            GetBrush();
            GetMaterialTexture();

            //=================================================Mapping list==========================================================================

            GUILayout.BeginHorizontal();

            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal("box", GUILayout.Width(270));
            //=======================2020-11-21=======================//
            int texCount = 3;
            int gridWidth = 270;
            if (hasFourProperty)
            {
                texCount = 4;
                gridWidth = 360;
            }
            //=======================2020-11-21=======================//
            selTex = GUILayout.SelectionGrid(selTex, texLayer, texCount, "gridlist", GUILayout.Width(gridWidth), GUILayout.Height(90));//2020-11-21//
            GUILayout.EndHorizontal();
            GUILayout.FlexibleSpace();

            GUILayout.EndHorizontal();

            //=================================================Brush List==========================================================================

            GUILayout.BeginHorizontal();

            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal("box", GUILayout.Width(318));
            selBrush = GUILayout.SelectionGrid(selBrush, brushTex, 9, "gridlist", GUILayout.Width(340), GUILayout.Height(70));
            GUILayout.EndHorizontal();
            GUILayout.FlexibleSpace();

            GUILayout.EndHorizontal();

            //=================================================Data Save==========================================================================
            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();

            if (GUILayout.Button("Save as default data"))
            {
                if (EditorUtility.DisplayDialog("Secondary confirmation", "Whether to save the data to default", "Yes", "No,I think"))
                {
                    if (idleShaderNames && ShaderNames)
                    {
                        idleShaderNames.UpdateLayers(ShaderNames.layers);
                        idleShaderNames.UpdateShaders(ShaderNames.shaders);
                    }
                }
                else
                {

                }
            }
            if (GUILayout.Button("Set as default data"))
            {
                if (EditorUtility.DisplayDialog("Secondary confirmation", "Whether to reset to the default data", "Yes", "No,I think"))
                {
                    if (idleShaderNames && ShaderNames)
                    {
                        ShaderNames.UpdateLayers(idleShaderNames.layers);
                        ShaderNames.UpdateShaders(idleShaderNames.shaders);
                    }
                }
                else
                {

                }
            }
            GUILayout.EndHorizontal();
        }
        serializedObject.ApplyModifiedProperties();
    }

    /// <summary>
    /// Get Material ball texture
    /// </summary>
    void GetMaterialTexture()
    {
        //Transform Select = Selection.activeTransform;
        Transform Select = _target.transform;

        if (Select)
        {
            seletMeshrender = Select.GetComponent<MeshRenderer>();
            //=======================2020-11-23=======================//
            hasFourProperty = seletMeshrender.sharedMaterial.HasProperty(MeshPainterStringUtility.tex_4) && seletMeshrender.sharedMaterial.HasProperty("_Color" + MeshPainterStringUtility.tex_4);    //2020-11-23
            //=======================2020-11-23=======================//                                                                                                                                                                                            //=======================2020-11-23=======================//
            if (hasFourProperty)        //===2020-11-23 has FourProperty===//
            {
                texLayer = new Texture[4];
            }
            else
            {
                texLayer = new Texture[3];
            }

            if (seletMeshrender)
            {
                try
                {
                    Texture2D tex_1 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_1));
                    Texture2D tex_2 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_2));
                    Texture2D tex_3 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_3));
             

                    Color col_1 = seletMeshrender.sharedMaterial.GetColor("_Color" + MeshPainterStringUtility.tex_1);
                    Color col_2 = seletMeshrender.sharedMaterial.GetColor("_Color" + MeshPainterStringUtility.tex_2);
                    Color col_3 = seletMeshrender.sharedMaterial.GetColor("_Color" + MeshPainterStringUtility.tex_3);

                    texLayer[0] = MergeTexture(tex_1, col_1) as Texture;
                    texLayer[1] = MergeTexture(tex_2, col_2) as Texture;
                    texLayer[2] = MergeTexture(tex_3, col_3) as Texture;

                    //==============================================//
                    if (hasFourProperty)    //===2020-11-23===hasFourProperty===//
                    {
                        Texture2D tex_4 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_4));
                        Color col_4 = seletMeshrender.sharedMaterial.GetColor("_Color" + MeshPainterStringUtility.tex_4);
                        texLayer[3] = MergeTexture(tex_4, col_4) as Texture;
                    }
                    //==============================================//

                    //============================================================2020-11-06=====================================================================//
                }
                catch (System.Exception e)
                {
                    if (isDebug)
                    {
                        Debug.Log(e + "shader：Map not found");
                    }
                }
            }
        }
    }

    public static Texture2D MergeTexture(Texture2D a, Color b)
    {
        var newTexture = new Texture2D(a.width, a.height);
        newTexture.filterMode = FilterMode.Point;

        for (int i = 0; i < newTexture.width; i++)
        {
            for (int j = 0; j < newTexture.height; j++)
            {
                var color = a.GetPixel(i, j);
                color.r = color.r * b.r;
                color.g = color.g * b.g;
                color.b = color.b * b.b;
                newTexture.SetPixel(i, j, color);
            }
        }

        newTexture.Apply();
        return newTexture;
    }

    /// <summary>
    /// 获取笔刷
    /// </summary>    
    void GetBrush()
    {
        string MeshPaintEditorFolder = MeshPainterStringUtility.meshPaintEditorFolder;
        ArrayList BrushList = new ArrayList();
        Texture BrushesTL;
        int BrushNum = 0;
        do
        {
            BrushesTL = (Texture)AssetDatabase.LoadAssetAtPath(MeshPaintEditorFolder + "Brushes/Brush" + BrushNum + ".png", typeof(Texture));

            if (BrushesTL)
            {
                BrushList.Add(BrushesTL);
            }
            BrushNum++;
        } while (BrushesTL);
        brushTex = BrushList.ToArray(typeof(Texture)) as Texture[];
    }

    Shader currentShader;         
    Shader lastShader;

    bool isUseLayer = false;
    string lastLayer = "";
    MeshRenderer seletMeshrender;
    /// <summary>
    /// Check for compliance with the rendering conditions
    /// </summary>
    /// <returns></returns>
    bool Cheak()
    {
        bool Cheak = false;
        bool isHaveShader = false;
        //Transform Select = Selection.activeTransform;
        Transform Select = _target.transform;
        if (Select)
            seletMeshrender = Select.GetComponent<MeshRenderer>();
        if (seletMeshrender)
        {
            Texture ControlTex = seletMeshrender.sharedMaterial.GetTexture("_Control");
            currentShader = seletMeshrender.sharedMaterial.shader;

            if (currentShader != null)
            {
                if (ShaderNames && shadernames.Count > 0)
                {
                    for (int i = 0; i < shadernames.Count; i++)
                    {
                        if (currentShader == Shader.Find(shadernames[i].ToString()))
                        {
                            isHaveShader = true;
                            break;
                        }
                    }
                }

                if (lastShader != currentShader)
                {
                    Debug.Log("<color=#FF9900>" + "current shader:    " + "</color>" + currentShader.name);
                    Debug.Log("<color=#29A7FF>" + "Is it inconsistent with the last drawing shader----->>>>>" + "</color>" + isHaveShader);
                    lastShader = currentShader;
                }
            }
            else
            {
                if (ControlTex != null)
                    Cheak = true;
                else
                    Cheak = false;

                return Cheak;
            }

            if (isHaveShader == true)
            {
                if (ControlTex == null)
                {
                    EditorGUILayout.HelpBox("Control map not found in current model shader, drawing function is not available！", MessageType.Error);
                    if (GUILayout.Button("Create Control Texture"))
                    {
                        creatContolTex();
                    }
                }
                else
                {
                    Cheak = true;
                }
            }
            else
            {
                EditorGUILayout.HelpBox("current shader error！Replace！", MessageType.Error);
                Cheak = false;
            }
        }

        return Cheak;
    }

    /// <summary>
    /// Create Contol Texture
    /// </summary>
    void creatContolTex()
    {
        string ContolTexFolder = MeshPainterStringUtility.contolTexFolder;
        Texture2D newMaskTex = new Texture2D(512, 512, TextureFormat.ARGB32, true);
        Color[] colorBase = new Color[512 * 512];
        for (int t = 0; t < colorBase.Length; t++)
        {
            colorBase[t] = new Color(1, 0, 0, 0);
        }
        newMaskTex.SetPixels(colorBase);

        //判断是否重名
        bool exporNameSuccess = true;
        for (int num = 1; exporNameSuccess; num++)
        {
            Transform Select = _target.transform;
            //Transform Select = Selection.activeTransform;

            string Next = Select.name + "_" + num;
            if (!File.Exists(ContolTexFolder + Select.name + ".png"))
            {
                contolTexName = Select.name;
                exporNameSuccess = false;
            }
            else if (!File.Exists(ContolTexFolder + Next + ".png"))
            {
                contolTexName = Next;
                exporNameSuccess = false;
            }
        }

        string path = ContolTexFolder + contolTexName + ".png";
        byte[] bytes = newMaskTex.EncodeToPNG();
        File.WriteAllBytes(path, bytes);//Save

        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);//Import Resources
        //Contol Map import settings
        TextureImporter textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
        textureIm.isReadable = true;
        textureIm.anisoLevel = 9;
        textureIm.mipmapEnabled = false;
        textureIm.wrapMode = TextureWrapMode.Repeat;

        //Map import settings
#if UNITY_5
        textureIm.textureFormat = TextureImporterFormat.ARGB32;
#endif
#if UNITY_2017||UNITY_2017_OR_NEWER
        TextureImporterPlatformSettings settings = textureIm.GetDefaultPlatformTextureSettings();
        settings.overridden = true;
        settings.format = TextureImporterFormat.ARGB32;

        textureIm.SetPlatformTextureSettings(settings);
#endif
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);//Reflash
        setContolTex(path);//Set Contol Map
    }

    //Set Contol Map
    void setContolTex(string peth)
    {
        Texture2D ControlTex = (Texture2D)AssetDatabase.LoadAssetAtPath(peth, typeof(Texture2D));
        Transform Select = _target.transform;
        //Transform Select = Selection.activeTransform;
        Select.gameObject.GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_Control", ControlTex);
    }

    bool isTargerLayer = false;

    /// <summary>
    /// Core drawing
    /// </summary>
    void Painter()
    {
        //Transform Select = Selection.activeTransform; 
        if (_target == null) return;//2020-11-09
        Transform CurrentSelect = _target.transform;
        
        MeshFilter temp = null;
        if (CurrentSelect)
        {
            temp = CurrentSelect.GetComponent<MeshFilter>();
        }
        else
        {
            if (isDebug) Debug.Log("The current object is empty");
            return;
        }

        float orthographicSize = (brushSize * CurrentSelect.localScale.x) * (temp.sharedMesh.bounds.size.x / (brushOrthValue * 100));//The orthogonal size of the brush on the model
        MaskTex = (Texture2D)CurrentSelect.gameObject.GetComponent<MeshRenderer>().sharedMaterial.GetTexture(MeshPainterStringUtility.shaderControlTexName);//Get the Control map from the shader

        brushSizeInPourcent = (int)Mathf.Round((brushSize * MaskTex.width) / (brushOrthValue * 0.5f * 100));//The size of the brush on the model
        bool ToggleF = false;
        Event e = Event.current;//Detection input
        HandleUtility.AddDefaultControl(0);
        RaycastHit raycastHit = new RaycastHit();
        Ray terrain = HandleUtility.GUIPointToWorldRay(e.mousePosition);//Emitting a ray from the mouse position

        if (ShaderNames && useLayers.Count > 0)
        {
            for (int i = 0; i < useLayers.Count; i++)
            {
                if (Physics.Raycast(terrain, out raycastHit, Mathf.Infinity, 1 << LayerMask.NameToLayer(useLayers[i])))
                {
                    isTargerLayer = true;
                    break;
                }
            }
        }
        else
        {
            return;
        }

        if (isTargerLayer == true)
        {
            Handles.color = new Color(1f, 1f, 0f, 1f);
            Handles.DrawWireDisc(raycastHit.point, raycastHit.normal, orthographicSize);//Display a circle at the mouse position according to the brush size

            Handles.color = new Color(1f, 0f, 0f, 1f);
            Handles.DrawLine(raycastHit.point, raycastHit.point + raycastHit.normal);//Displays the normal direction at the mouse position according to the brush size

            //Mouse click or press and drag to draw
            if ((e.type == EventType.MouseDrag && e.alt == false && e.control == false && e.shift == false && e.button == 0) || (e.type == EventType.MouseDown && e.shift == false && e.alt == false && e.control == false && e.button == 0 && ToggleF == false))
            {
                //Select the channel to draw
                Color targetColor = new Color(1f, 0f, 0f, 0f);
                switch (selTex)
                {
                    case 0:
                        targetColor = new Color(1f, 0f, 0f, 0f);
                        break;
                    case 1:
                        targetColor = new Color(0f, 1f, 0f, 0f);
                        break;
                    case 2:
                        targetColor = new Color(0f, 0f, 1f, 0f);
                        break;
                    case 3:
                        targetColor = new Color(0f, 0f, 0f, 1f);
                        break;
                }

                Vector2 pixelUV = raycastHit.textureCoord;
                #region ----Determine if UV is over-framed
                float changX = 0;
                float changY = 0;
                if (Mathf.Abs(pixelUV.x) > 1 || Mathf.Abs(pixelUV.y) > 1)
                {
                    if (isDebug)
                        Debug.LogError("UV superframe original value:" + pixelUV);
                    if (pixelUV.x > 1)
                    {
                        changX = pixelUV.x % 1;
                    }
                    else if (pixelUV.x < -1)
                    {
                        changX = 1 - Mathf.Abs(pixelUV.x % (-1));
                        if (isDebug)
                            Debug.Log((pixelUV.x % (-1)));
                    }
                    else
                    {
                        changX = pixelUV.x;
                    }


                    if (pixelUV.y > 1)
                    {
                        changY = pixelUV.y % 1;
                    }
                    else if (pixelUV.y < -1)
                    {
                        changY = 1 - Mathf.Abs(pixelUV.y % (-1));
                    }
                    else
                    {
                        changY = pixelUV.y;
                    }

                    pixelUV = new Vector2(changX, changY);
                    if (isDebug)
                        Debug.Log("UV Superframe:" + pixelUV + "    X:" + changX + "    Y:" + changY);
                }

                if ((pixelUV.y < 0 && pixelUV.y >= -1) || (pixelUV.x < 0 && pixelUV.x >= -1))
                {
                    if (isDebug)
                        Debug.LogError("UV Negative original value:" + pixelUV);
                    if (pixelUV.x < 0 && pixelUV.x >= -1)
                    {
                        changX = 1 - Mathf.Abs(pixelUV.x);
                    }
                    else
                    {
                        changX = pixelUV.x;
                    }

                    if (pixelUV.y < 0 && pixelUV.y >= -1)
                    {
                        changY = 1 - Mathf.Abs(pixelUV.y);
                    }
                    else { changY = pixelUV.y; }
                    pixelUV = new Vector2(changX, changY);
                    if (isDebug)
                        Debug.Log("UV Negative:" + pixelUV + "    X:" + changX + "    Y:" + changY);
                }

                if ((pixelUV.y >= 0 && pixelUV.y <= 1) && (pixelUV.x >= 0 && pixelUV.x <= 1))
                {
                    if (isDebug)
                        Debug.Log("UV in the box:" + pixelUV);
                }
                #endregion
                //Calculate the area covered by the brush
                int PuX = Mathf.FloorToInt(pixelUV.x * MaskTex.width);
                int PuY = Mathf.FloorToInt(pixelUV.y * MaskTex.height);
                int x = Mathf.Clamp(PuX - brushSizeInPourcent / 2, 0, MaskTex.width - 1);
                int y = Mathf.Clamp(PuY - brushSizeInPourcent / 2, 0, MaskTex.height - 1);
                int width = Mathf.Clamp((PuX + brushSizeInPourcent / 2), 0, MaskTex.width) - x;
                int height = Mathf.Clamp((PuY + brushSizeInPourcent / 2), 0, MaskTex.height) - y;

                Color[] terrainBay = MaskTex.GetPixels(x, y, width, height, 0);//Get the color of the area that the Control map is covered by the brush

                Texture2D TBrush = brushTex[selBrush] as Texture2D;//Get brush trait map
                float[] brushAlpha = new float[brushSizeInPourcent * brushSizeInPourcent];//Brush transparency

                //Calculate the transparency of the brush based on the brush map
                for (int i = 0; i < brushSizeInPourcent; i++)
                {
                    for (int j = 0; j < brushSizeInPourcent; j++)
                    {
                        brushAlpha[j * brushSizeInPourcent + i] = TBrush.GetPixelBilinear(((float)i) / brushSizeInPourcent, ((float)j) / brushSizeInPourcent).a;
                    }
                }

                //Calculate the color after drawing
                for (int i = 0; i < height; i++)
                {
                    for (int j = 0; j < width; j++)
                    {
                        int index = (i * width) + j;
                        float Stronger = brushAlpha[Mathf.Clamp((y + i) - (PuY - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1) * brushSizeInPourcent + Mathf.Clamp((x + j) - (PuX - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1)] * brushStronger;

                        terrainBay[index] = Color.Lerp(terrainBay[index], targetColor, Stronger);
                    }
                }
                Undo.RegisterCompleteObjectUndo(MaskTex, "meshPaint");//Save history for revocation

                MaskTex.SetPixels(x, y, width, height, terrainBay, 0);//Save the drawn Control texture
                MaskTex.Apply();
                ToggleF = true;
            }

            if (e.type == EventType.MouseUp && e.alt == false && e.button == 0)// && ToggleF == true)
            {

                SaveTexture();//Draw to save the Control texture
                ToggleF = false;
            }
        }
    }
    public void SaveTexture()
    {
        var path = AssetDatabase.GetAssetPath(MaskTex);
        var bytes = MaskTex.EncodeToPNG();
        Debug.Log("SaveTexture " + path);
        File.WriteAllBytes(path, bytes);
    }
}
