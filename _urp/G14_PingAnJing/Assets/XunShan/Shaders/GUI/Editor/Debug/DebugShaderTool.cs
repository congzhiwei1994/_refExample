using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.EditorTools;

namespace ShaderEditor
{
    public abstract class DebugShaderTool : EditorTool
    {
        public static class PropName
        {
            /// <summary>
            /// float
            /// </summary>
            public const string _G_Debug_HeatMaxValue = "_G_Debug_HeatMaxValue";

            public const string _G_Debug_EnableHeat = "_G_Debug_EnableHeat";
        }

        static class Styles
        {
            private static GUIStyle s_background;
            public static GUIStyle Background
            {
                get
                {
                    if (s_background == null)
                    {
                        //var _style = new GUIStyle("AnimationEventTooltip");
                        var _style = new GUIStyle("IN BigTitle inner");
                        //var _style = new GUIStyle("WindowBackground");
                        //var _style = new GUIStyle("SceneViewOverlayTransparentBackground");
                        //var _style = new GUIStyle("NotificationBackground");
                        //var _style = new GUIStyle("Box");
                        //var _overflow = _style.overflow;
                        //_overflow.right = 0;
                        //_style.overflow = _overflow;
                        _style.stretchWidth = true;
                        _style.stretchHeight = true;
                        s_background = _style;
                    }
                    return s_background;
                }
            }

            private static GUIStyle s_MenuItem;
            public static GUIStyle MenuItem
            {
                get
                {
                    if (s_MenuItem == null)
                    {
                        var _style = new GUIStyle("MenuItem");
                        s_MenuItem = _style;
                    }
                    return s_MenuItem;
                }
            }
        }

        #region DrawState

        protected class DrawState
        {
            private class State
            {
                public UnityEngine.Color m_GUIColor;
                public UnityEngine.Color m_GUIContentColor;
                public UnityEngine.Color m_GUIBackgroundColor;

                // 构造
                public State()
                {
                    m_GUIColor = UnityEngine.Color.clear;
                    m_GUIContentColor = UnityEngine.Color.clear;
                    m_GUIBackgroundColor = UnityEngine.Color.clear;
                }

                public void PushState()
                {
                    m_GUIColor = UnityEngine.GUI.color;
                    m_GUIContentColor = UnityEngine.GUI.contentColor;
                    m_GUIBackgroundColor = UnityEngine.GUI.backgroundColor;
                }

                public void PopState()
                {
                    UnityEngine.GUI.color = m_GUIColor;
                    UnityEngine.GUI.contentColor = m_GUIContentColor;
                    UnityEngine.GUI.backgroundColor = m_GUIBackgroundColor;
                }
            }

            // 最大支持状态栈
            private const int MAX_STATE = 20;

            private static State[] m_DrawState;
            private static int m_CurState;


            // 构造
            static DrawState()
            {
                m_DrawState = new State[MAX_STATE];
                for (int i = 0; i < MAX_STATE; ++i)
                {
                    m_DrawState[i] = new State();
                }
                m_CurState = -1;
            }


            // 压入状态
            public static void PushState()
            {
                ++m_CurState;
                if (m_CurState >= 0 && m_CurState < MAX_STATE)
                {
                    m_DrawState[m_CurState].PushState();
                }
                else
                {
                    UnityEngine.Debug.LogError("DrawState push is out of stack");
                }
            }

            // 弹出状态
            public static void PopState()
            {
                if (m_CurState >= 0)
                {
                    if (m_CurState < MAX_STATE)
                    {
                        m_DrawState[m_CurState].PopState();
                    }
                    --m_CurState;
                }
                else
                {
                    UnityEngine.Debug.LogError("PushState and PopState not match pair!!!");
                }
            }

            public static void RestoreState()
            {
                if (m_CurState >= 0)
                {
                    if (m_CurState < MAX_STATE)
                    {
                        m_DrawState[m_CurState].PopState();
                    }
                }
                else
                {
                    UnityEngine.Debug.LogError("PushState and PopState not match pair!!!");
                }
            }


            public static void SetAllColor(UnityEngine.Color col)
            {
                UnityEngine.GUI.color = col;
                UnityEngine.GUI.contentColor = col;
                UnityEngine.GUI.backgroundColor = col;
            }

            public static void ApplyColor(UnityEngine.Color _col)
            {
                UnityEngine.GUI.color *= _col;
            }

            public static void SetContentColor(UnityEngine.Color col)
            {
                UnityEngine.GUI.contentColor = col;
            }

            public static void SetBackgroundColor(UnityEngine.Color col)
            {
                UnityEngine.GUI.backgroundColor = col;
            }

            // 设置alpha
            public static void SetAllAlpha(float alpha)
            {
                UnityEngine.Color tempCol = UnityEngine.GUI.color;
                tempCol.a = alpha;
                UnityEngine.GUI.color = tempCol;

                tempCol = UnityEngine.GUI.contentColor;
                tempCol.a = alpha;
                UnityEngine.GUI.contentColor = tempCol;

                tempCol = UnityEngine.GUI.backgroundColor;
                tempCol.a = alpha;
                UnityEngine.GUI.backgroundColor = tempCol;
            }
            public static void ApplyAllAlpha(float alpha)
            {
                UnityEngine.Color tempCol = UnityEngine.GUI.color;
                tempCol.a *= alpha;
                UnityEngine.GUI.color = tempCol;

                tempCol = UnityEngine.GUI.contentColor;
                tempCol.a *= alpha;
                UnityEngine.GUI.contentColor = tempCol;

                tempCol = UnityEngine.GUI.backgroundColor;
                tempCol.a *= alpha;
                UnityEngine.GUI.backgroundColor = tempCol;
            }
            public static float GetColorAlpha()
            {
                return UnityEngine.GUI.color.a;
            }
        }

        #endregion // DrawState

        protected const float k_WindowWidth = 100f;

        private const float k_MaxHeat = 10f;


        protected GUIContent m_IconContent;

        Rect m_WindowRect;

        private System.Reflection.PropertyInfo m_SceneViewToolbarHeight;

        [System.NonSerialized]
        string[] s_ModeNames;
        [System.NonSerialized]
        string[] s_ModeTooltip;
        [System.NonSerialized]
        bool s_ModeNamesIsGet = false;
        [System.NonSerialized]
        int[] s_ModeValues;

        protected virtual Texture GetToolIcon()
        {
            return null;
        }

        protected virtual string GetToolText()
        {
            return string.Empty;
        }

        protected virtual string GetToolTip()
        {
            return string.Empty;
        }

        protected virtual float GetToolWindowWidth()
        {
            return k_WindowWidth;
        }

        protected virtual void OnToolInit()
        {
            
        }

        protected virtual void OnToolExit()
        {

        }

        protected virtual void OnToolUpdate(float _deltaTime)
        {
            
        }

        protected virtual void OnToolDrawBottom()
        {

        }

        protected abstract System.Type GetModeEnumType();
        protected abstract int GetCurrentMode();
        protected abstract void OnToolSelectMode(int _mode);

        public override GUIContent toolbarIcon
        {
            get { return m_IconContent; }
        }

        public override void OnToolGUI(EditorWindow window)
        {
            Handles.BeginGUI();
            {
                float _toolbarHeight = 0.0f;
                var _sceneView = window as SceneView;
                if (_sceneView != null)
                {
                    if (m_SceneViewToolbarHeight == null)
                    {
                        m_SceneViewToolbarHeight = _sceneView.GetType().GetProperty("toolbarHeight", System.Reflection.BindingFlags.GetProperty | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                    }
                    if (m_SceneViewToolbarHeight != null)
                    {
                        _toolbarHeight = (float)m_SceneViewToolbarHeight.GetValue(_sceneView);
                    }
                }

                var _desWidth = GetToolWindowWidth();
                var _working_layout_rect = Rect.zero;
                _working_layout_rect.width = _desWidth;
                _working_layout_rect.y += _toolbarHeight;
                m_WindowRect = GUILayout.Window(this.GetType().GetHashCode(), _working_layout_rect, WindowLayout, GUIContent.none, GUIStyle.none, GUILayout.MinWidth(_desWidth), GUILayout.ExpandHeight(true));
            }
            Handles.EndGUI();
        }

        private void WindowLayout(int id)
        {
            var _current_event = Event.current;
            var _event_type = _current_event.GetTypeForControl(id);

            var _mouse_rect = m_WindowRect;
            _mouse_rect.y = 0;
            _mouse_rect.x = 0;
            var _mouse_pos = _current_event.mousePosition;
            var _cur_mouse_on = _mouse_rect.Contains(_mouse_pos);
            
            DrawState.PushState();
            DrawState.SetAllAlpha(_cur_mouse_on ? 1f : 0.6f);
            EditorGUILayout.BeginVertical(Styles.Background);

            GUILayout.Label(GetToolText(), EditorStyles.miniLabel);

            var _currentMode = GetCurrentMode();
            for (int _i = 0; _i < s_ModeNames.Length; ++_i)
            {
                //bool _toggle = (s_ModeValues[_i] != 0) ? ((_currentMode & s_ModeValues[_i]) != 0) : (_currentMode == 0);
                bool _toggle = s_ModeValues[_i] == _currentMode;
                bool _newToggle = GUILayout.Toggle(_toggle, EditorGUIUtility.TrTextContent(s_ModeNames[_i], (s_ModeTooltip != null)?s_ModeTooltip[_i]:string.Empty), Styles.MenuItem);
                if (_newToggle != _toggle)
                {
                    OnToolSelectMode(s_ModeValues[_i]);
                }
            }

            OnToolDrawBottom();

            EditorGUILayout.EndVertical();

            DrawState.PopState();

        }

        private void OnEnable()
        {
            if (s_ModeValues == null)
            {
                s_ModeValues = System.Enum.GetValues(GetModeEnumType()) as int[];
            }
            if (s_ModeNames == null)
            {
                s_ModeNames = System.Enum.GetNames(GetModeEnumType());
            }
            if (!s_ModeNamesIsGet)
            {
                System.Type _typeFor = null;
                var _type_EnumDataUtility = typeof(EditorGUI).Assembly.GetType("UnityEditor.EnumDataUtility", false);
                if (_type_EnumDataUtility != null)
                {
                    _typeFor = _type_EnumDataUtility;
                }
                else
                {
                    // 旧2019
                    _typeFor = typeof(EditorGUI);
                }
                if (_typeFor != null)
                {
                    var _method_GetCachedEnumData = _typeFor.GetMethod("GetCachedEnumData", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic);
                    if (_method_GetCachedEnumData != null)
                    {
                        var _enumData = _method_GetCachedEnumData.Invoke(null, new object[] { GetModeEnumType(), true });
                        if (_enumData != null)
                        {
                            var _field_displayNames = _enumData.GetType().GetField("displayNames", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
                            if (_field_displayNames != null)
                            {
                                var _displayNames = _field_displayNames.GetValue(_enumData) as string[];
                                if (_displayNames != null)
                                {
                                    s_ModeNames = _displayNames;
                                }
                            }
                            var _field_tooltip = _enumData.GetType().GetField("tooltip", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
                            if (_field_tooltip != null)
                            {
                                var _tooltip = _field_tooltip.GetValue(_enumData) as string[];
                                if (_tooltip != null)
                                {
                                    s_ModeTooltip = _tooltip;
                                }
                            }
                            
                        }
                    }
                }
                s_ModeNamesIsGet = true;
            }

            m_IconContent = new GUIContent()
            {
                image = GetToolIcon(),
                text = GetToolText(),
                tooltip = GetToolTip()
            };

            Internal_RegisterEditorUpdate();

            OnToolInit();

        }

        private void OnDisable()
        {
            Internal_UnRegisterEditorUpdate();

            OnToolExit();
        }


        private void WindowUpdate(float _deltaTime)
        {
            Shader.SetGlobalFloat(PropName._G_Debug_HeatMaxValue, DebugShader.HeatMaxValue);
            
            OnToolUpdate(_deltaTime);
        }

        protected void DrawHDRHeatmapGUI()
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("热力峰值");
            DebugShader.HeatMaxValue = EditorGUILayout.Slider(DebugShader.HeatMaxValue, 0.0f, k_MaxHeat);
            EditorGUILayout.EndHorizontal();
        }

        [UnityEditor.ShortcutManagement.ClutchShortcut("DebugShader/显示热力模式", null, KeyCode.Space)]
        private static void Callback_ShortcutShowHeat(UnityEditor.ShortcutManagement.ShortcutArguments args)
        {
            if (args.stage == UnityEditor.ShortcutManagement.ShortcutStage.Begin)
            {
                Shader.SetGlobalInt(PropName._G_Debug_EnableHeat, 1);
            }
            else
            {
                Shader.SetGlobalInt(PropName._G_Debug_EnableHeat, 0);
            }
        }


        #region Update

        /// <summary>
        /// 上一次Update的时间戳
        /// </summary>
        private double last_update_time;

        /// <summary>
        /// 注册Update
        /// </summary>
        private void Internal_RegisterEditorUpdate()
        {
            last_update_time = UnityEditor.EditorApplication.timeSinceStartup;

            EditorApplication.update += this.Callback_Internal_EditorUpdate;
        }

        private void Internal_UnRegisterEditorUpdate()
        {
            EditorApplication.update -= this.Callback_Internal_EditorUpdate;
        }

        private void Callback_Internal_EditorUpdate()
        {
            double _time = UnityEditor.EditorApplication.timeSinceStartup;
            double _cur_delta_time = _time - last_update_time;
            last_update_time = _time;
            float _delta_time = System.Convert.ToSingle(_cur_delta_time);

            WindowUpdate(_delta_time);

        }

        #endregion // Update
    }
}