#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace KWS
{
    public static class KWS_EditorUtils
    {
        private static Camera _sceneCamera;
        static Texture2D _buttonTex;
        static Texture2D _editorTabTex;
        static VideoTooltipWindow window;
        static string pathToHelpVideos;

        #region styles
        static GUIStyle _helpBoxStyle;

        public static GUIStyle HelpBoxStyle
        {
            get
            {
                if (_helpBoxStyle == null)
                {
                    _helpBoxStyle = new GUIStyle("button");
                    _helpBoxStyle.alignment = TextAnchor.MiddleCenter;
                    _helpBoxStyle.stretchHeight = false;
                    _helpBoxStyle.stretchWidth = false;
                }

                return _helpBoxStyle;
            }
        }

        static GUIStyle _buttonStyle;

        public static GUIStyle ButtonStyle
        {
            get
            {
                if (_buttonStyle == null)
                {
                    _buttonStyle = new GUIStyle();
                    _buttonStyle.overflow.left = ButtonStyle.overflow.right = 3;
                    _buttonStyle.overflow.top = 2;
                    _buttonStyle.overflow.bottom = 2;
                }

                if (_buttonTex == null)
                {
                    _buttonTex = CreateTex(32, 32, EditorGUIUtility.isProSkin ? new Color(78 / 255f, 79 / 255f, 80 / 255f) : new Color(171 / 255f, 171 / 255f, 171 / 255f));
                    _buttonStyle.normal.background = _buttonTex;
                }
                ;
                return _buttonStyle;
            }
        }

        private static GUIStyle _notesLabelStyleFade;
        public static GUIStyle NotesLabelStyleFade
        {
            get
            {
                if (_notesLabelStyleFade == null)
                {
                    _notesLabelStyleFade = new GUIStyle("label");
                    _notesLabelStyleFade.normal.textColor = EditorGUIUtility.isProSkin ? new Color(0.75f, 0.75f, 0.75f, 0.5f) : new Color(0.1f, 0.1f, 0.1f, 0.3f);
                }

                return _notesLabelStyleFade;
            }
        }
        
        static GUIStyle _notesLabelStyle;
        public static GUIStyle NotesLabelStyle
        {
            get
            {
                if (_notesLabelStyle == null)
                {
                    _notesLabelStyle = new GUIStyle(GUI.skin.label);
                    _notesLabelStyle.normal.textColor = EditorGUIUtility.isProSkin ? new Color(0.85f, 0.25f, 0.25f, 0.95f) : new Color(0.7f, 0.1f, 0.1f, 0.95f);
                }

                return _notesLabelStyle;
            }
        }

        static GUIStyle _tabNameTextStyle;
        public static GUIStyle TabNameTextStyle
        {
            get
            {
                if (_tabNameTextStyle == null)
                {
                    _tabNameTextStyle = new GUIStyle(EditorStyles.foldout);
                    _tabNameTextStyle.fontSize = 13;
                    _tabNameTextStyle.padding = new RectOffset(16, 0, 0, 0);
                    //_tabNameTextStyle.clipping = TextClipping.Overflow;
                    _tabNameTextStyle.fontStyle = FontStyle.Bold;
                }

                return _tabNameTextStyle;
            }
        }

        static GUIStyle _expertButtonStyle;
        public static GUIStyle ExpertButtonStyle
        {
            get
            {
                if (_expertButtonStyle == null)
                {
                    _expertButtonStyle = new GUIStyle(GUI.skin.button);
                    _expertButtonStyle.fontSize = 10;
                    _expertButtonStyle.normal.textColor = new Color(1, 1, 1, 0.5f);
                }

                return _expertButtonStyle;
            }
        }

        static GUIStyle _editorTabStyle;

        public static GUIStyle EditorTabStyle
        {
            get
            {
                if (_editorTabStyle == null)
                {
                    _editorTabStyle = new GUIStyle(GUI.skin.box);
                }
                if (_editorTabTex == null)
                {
                    _editorTabTex = CreateBorderTex(128, 128, new Color(0f, 1f, 0f, 0.6f));
                    _editorTabStyle.normal.background = _editorTabTex;
                }

                return _editorTabStyle;
            }
        }

        static Texture2D CreateTex(int width, int height, Color col)
        {
            var pix = new Color[width * height];
            for (int i = 0; i < pix.Length; i++) pix[i] = col;

            var result = new Texture2D(width, height);
            result.SetPixels(pix);
            result.Apply();

            return result;
        }

        static Texture2D CreateBorderTex(int width, int height, Color col)
        {
            var pix = new Color[width * height];
            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    if (x == 0 || x == width - 1 || y == 0 || y == height - 1) pix[y * height + x] = col;
                }
            }

            var result = new Texture2D(width, height);
            result.SetPixels(pix);
            result.Apply();

            return result;
        }
        #endregion

        #region GUI

        public static string GetPathToHelpVideos()
        {
            //var dirs = Directory.GetDirectories(Application.dataPath, "HelpVideos", SearchOption.AllDirectories);
            //return dirs.Length != 0 ? dirs[0] : string.Empty;
            return @"http://kripto289.com/AssetStore/WaterSystem/VideoHelpers/";
        }

        public static void OpenHelpVideoWindow(string filename)
        {
            if (window != null) window.Close();
            if(window == null) window = (VideoTooltipWindow)EditorWindow.GetWindow(typeof(VideoTooltipWindow));
            if (string.IsNullOrEmpty(pathToHelpVideos)) pathToHelpVideos = GetPathToHelpVideos();
            window.VideoClipFileURI = Path.Combine(pathToHelpVideos, filename + ".mp4");
            window.maxSize = new Vector2(854, 480);
            window.minSize = new Vector2(854, 480);
            window.Show();
        }

        static void HelpWindowButton(string fileName)
        {
            GUILayout.Label("", GUILayout.Width(6));
            if (GUILayout.Button("?", HelpBoxStyle, GUILayout.Width(16), GUILayout.Height(18))) OpenHelpVideoWindow(fileName);
        }

        public static float Slider(string text, string description, float value, float leftValue, float rightValue, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.Slider(new GUIContent(text, description), value, leftValue, rightValue);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static int IntSlider(string text, string description, int value, int leftValue, int rightValue, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.IntSlider(new GUIContent(text, description), value, leftValue, rightValue);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static int IntField(string text, string description, int value, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.IntField(new GUIContent(text, description), value);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static float FloatField(string text, string description, float value, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.FloatField(new GUIContent(text, description), value);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static Vector2 Vector2Field(string text, string description, Vector2 value, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.Vector2Field(new GUIContent(text, description), value);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static Vector3 Vector3Field(string text, string description, Vector3 value, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.Vector3Field(new GUIContent(text, description), value);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static Color ColorField(string text, string description, Color value, bool shoeEyedropper, bool showAlpha, bool hdr, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.ColorField(new GUIContent(text, description), value, shoeEyedropper, showAlpha, hdr);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static Enum EnumPopup(string text, string description, Enum value, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.EnumPopup(new GUIContent(text, description), value);
            HelpWindowButton(helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static int MaskField(string text, string description, int mask, string[] layers, string helpVideoName)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.MaskField(new GUIContent(text, description), mask, layers);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public static bool Toggle(string text, string description, bool value, string helpVideoName, params GUILayoutOption[] options)
        {
            EditorGUILayout.BeginHorizontal();
            var newValue = EditorGUILayout.Toggle(new GUIContent(text, description), value, options);
            HelpWindowButton(helpVideoName == string.Empty ? text : helpVideoName);
            EditorGUILayout.EndHorizontal();
            return newValue;
        }

        public delegate void WaterTabSettings();


        public static void KWS_Tab(WaterSystem water, ref bool isVisibleTab, bool useHelpBox, bool useExpertButton, ref bool isExpertMode, KWS_EditorProfiles.IWaterPerfomanceProfile profileInterface, string tabName, WaterTabSettings settings)
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUILayout.BeginHorizontal(ButtonStyle);
            EditorGUILayout.LabelField("", GUILayout.MaxWidth(9));
            isVisibleTab = EditorGUILayout.Foldout(isVisibleTab, new GUIContent(tabName), true, TabNameTextStyle);
            if (profileInterface != null)
            {
                var newProfile = (WaterSystem.WaterProfileEnum)EditorGUILayout.EnumPopup("", profileInterface.GetProfile(water), GUILayout.Width(75));
                profileInterface.SetProfile(newProfile, water);
                profileInterface.ReadDataFromProfile(water);
            }
            if (useHelpBox) HelpWindowButton(tabName);
            EditorGUILayout.EndHorizontal();
            if (isVisibleTab)
            {
                GUILayout.Space(5);
                EditorGUI.indentLevel++;

                if (useExpertButton) isExpertMode = GUILayout.Toggle(isExpertMode, isExpertMode ? "Additional Settings -" : "Additional Settings +", ExpertButtonStyle, GUILayout.Height(18));
                GUILayout.Space(5);
               
                settings.Invoke();

                EditorGUI.indentLevel--;
                GUILayout.Space(15);
            }

            EditorGUILayout.EndVertical();
            profileInterface?.CheckDataChangesAnsSetCustomProfile(water);
        }

        public static void KWS_Tab(WaterSystem water, bool isWaterActive, ref bool isToogleSelected, ref bool isVisibleTab, bool useExpertButton, ref bool isExpertMode, KWS_EditorProfiles.IWaterPerfomanceProfile profileInterface, string tabName, WaterTabSettings settings)
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUILayout.BeginHorizontal(ButtonStyle);
            isToogleSelected = EditorGUILayout.Toggle(isToogleSelected, GUILayout.MaxWidth(14));

            GUILayout.Space(14);
            isVisibleTab = EditorGUILayout.Foldout(isVisibleTab, new GUIContent(tabName), true, TabNameTextStyle);
            if (profileInterface != null)
            {
                if (isWaterActive) GUI.enabled = isToogleSelected;

                var newProfile = (WaterSystem.WaterProfileEnum)EditorGUILayout.EnumPopup("", profileInterface.GetProfile(water), GUILayout.Width(75));
                profileInterface.SetProfile(newProfile, water);
                profileInterface.ReadDataFromProfile(water);

                if (isWaterActive) GUI.enabled = true;
            }
            HelpWindowButton(tabName);
            EditorGUILayout.EndHorizontal();

            if (isVisibleTab)
            {
                if (isWaterActive) GUI.enabled = isToogleSelected;
                GUILayout.Space(5);
                EditorGUI.indentLevel++;
                
                if (useExpertButton) isExpertMode = GUILayout.Toggle(isExpertMode, isExpertMode ? "Additional Settings -" : "Additional Settings +", ExpertButtonStyle, GUILayout.Height(18));
                GUILayout.Space(5);

                settings.Invoke();

                EditorGUI.indentLevel--;
                GUILayout.Space(15);
                if (isWaterActive) GUI.enabled = true;
            }
            EditorGUILayout.EndVertical();

            profileInterface?.CheckDataChangesAnsSetCustomProfile(water);
        }


        public static void KWS_EditorTab(bool isEditorEnabled, WaterTabSettings settings)
        {
            if (isEditorEnabled)
            {
                GUI.enabled = true;
                using (new EditorGUILayout.VerticalScope(EditorTabStyle))
                {
                    EditorGUI.indentLevel++;
                    settings.Invoke();
                    EditorGUI.indentLevel--;
                }
                GUI.enabled = false;
            }
            else settings.Invoke();
        }

        public static void KWS_EditorMessage(string message, MessageType messageType)
        {
            EditorGUILayout.HelpBox(message, messageType);
        }

        public static bool SaveButton(string txt, bool isActive)
        {
            if (isActive)
            {
                var oldColor = GUI.backgroundColor;
                GUI.backgroundColor = Color.green;
                var state = GUILayout.Button(txt);
                GUI.backgroundColor = oldColor;
                return state;
            }
            else return GUILayout.Button(txt);
        }

        #endregion
        public static Camera GetSceneCamera()
        {
            //if (SceneView.lastActiveSceneView != null) _sceneCamera = SceneView.lastActiveSceneView.camera;
            //else
            //{
            //    var camCurrent                                                                        = Camera.current;
            //    if (camCurrent != null && camCurrent.cameraType == CameraType.SceneView) _sceneCamera = camCurrent;
            //}
            //return _sceneCamera;
            return SceneView.lastActiveSceneView.camera;
        }

        public static Vector3 GetMouseWorldPosProjectedToWater(float height, Event e)
        {
            var mousePos = e.mousePosition;
            var plane = new Plane(Vector3.down, height);
            var ray = HandleUtility.GUIPointToWorldRay(mousePos);
            if (plane.Raycast(ray, out var distanceToPlane))
            {
                return ray.GetPoint(distanceToPlane);
            }

            return Vector3.positiveInfinity;
        }

        public static void Release()
        {
            KW_Extensions.SafeDestroy(_buttonTex, _editorTabTex);
        }

        public static void SetEditorCameraPosition(Vector3 worldPos)
        {
            SceneView.lastActiveSceneView.LookAt(worldPos);
        }

        public static void LockLeftClickSelection(int controlID)
        {
            if (Event.current.type == EventType.MouseDown)
            {
                if (Event.current.button == 0)
                {
                    GUIUtility.hotControl = controlID;
                    Event.current.Use();
                }
            }
        }

        public static bool MouseRaycast(out RaycastHit hit)
        {
            var ray = HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);
            if (Physics.Raycast(ray, out hit))
            {
                return true;
            }

            return false;
        }


        public static void DisplayMessageNotification(string msg, bool useDebugError, float time = 5)
        {
            if (useDebugError) Debug.LogError(msg);

#if UNITY_EDITOR
            foreach (UnityEditor.SceneView sv in UnityEditor.SceneView.sceneViews)
                sv.ShowNotification(new GUIContent(msg), time);
#endif
        }

        static void ReplaceShaderText(string shaderText, string pattern, string newText)
        {
            var result = Regex.Replace(shaderText, pattern, newText);

        }

        public static void SetShaderTextDefine(string shaderPath, string define, bool enabled)
        {
            var pathToShadersFolder    = KW_Extensions.GetPathToWaterShadersFolder();
            var platorfmSpecificShader = Path.Combine(pathToShadersFolder, shaderPath);
            var shaderText                  = File.ReadAllText(platorfmSpecificShader);

            var pattern = @"\/{0,}#define\s{1,}" + define; //pattern for such lines with spaces      ->     //#define   ENVIRO_FOG  //comment
            var newText = enabled ? $"#define {define}" : $"//#define {define}";
            var newShader = Regex.Replace(shaderText, pattern, newText, RegexOptions.Singleline);

            File.WriteAllText(platorfmSpecificShader, newShader);
        }

        public static void SetShaderTextQueue(string shaderPath, int queue)
        {
            var pathToShadersFolder    = KW_Extensions.GetPathToWaterShadersFolder();
            var platorfmSpecificShader = Path.Combine(pathToShadersFolder, shaderPath);
            var shaderText = File.ReadAllText(platorfmSpecificShader);

            var queueText = queue == 3000 ? "" : queue > 3000 ? $"+{queue - 3000}" : $"-{3000 - queue}";
            var newText = $"\"Queue\" = \"Transparent{queueText}\"";

            var pattern = "\"Queue\"\\s{0,}=\\s{0,}\"Transparent.{0,2}\"";
            var newShader = Regex.Replace(shaderText, pattern, newText, RegexOptions.Singleline);

            File.WriteAllText(platorfmSpecificShader, newShader);
        }

        public static void ChangeShaderTextIncludePath(string shaderPath, string shaderDefine, string newPath)
        {
            if (shaderDefine.Length == 0) return;

            var pathToShadersFolder = KW_Extensions.GetPathToWaterShadersFolder();
            var platorfmSpecificShader = Path.Combine(pathToShadersFolder, shaderPath);
            var shaderLines = File.ReadAllLines(platorfmSpecificShader);

            var searchPattern = $"#if defined({shaderDefine})";
            var lineIdx = 0;
            while (lineIdx < shaderLines.Length - 1)
            {
                if (shaderLines[lineIdx].Contains(searchPattern))
                {
                    shaderLines[lineIdx + 1] = $"	#include \"{newPath}\"";
                    break;
                }

                lineIdx++;
            }

            File.WriteAllLines(platorfmSpecificShader, shaderLines);
        }

        public static int GetEnabledDefineIndex(string shaderPath, List<string> defines)
        {
            var pathToShadersFolder    = KW_Extensions.GetPathToWaterShadersFolder();
            var platorfmSpecificShader = Path.Combine(pathToShadersFolder, shaderPath);
            var shaderLines = File.ReadAllLines(platorfmSpecificShader);

            for (var index = 0; index < defines.Count; index++)
            {
                var define  = defines[index];
                if(define.Length == 0) continue;
                var pattern = $"#define {define}";

                for (int lineIndex = 0; lineIndex < shaderLines.Length; lineIndex++)
                {
                    if (shaderLines[lineIndex] == pattern) return index;
                }
            }
            
            return 0;
        }
    }
}
#endif