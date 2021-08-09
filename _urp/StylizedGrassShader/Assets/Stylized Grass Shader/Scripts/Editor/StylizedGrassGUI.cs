using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Assertions;

namespace StylizedGrass
{
    public class StylizedGrassGUI : Editor
    {
        private static GUIStyle _Header;
        public static GUIStyle Header
        {
            get
            {
                if (_Header == null)
                {
                    _Header = new GUIStyle(GUI.skin.label)
                    {
                        richText = true,
                        alignment = TextAnchor.MiddleCenter,
                        wordWrap = true,
                        fontSize = 18,
                        fontStyle = FontStyle.Normal
                    };
                }

                return _Header;
            }
        }

        private static GUIStyle _Tab;
        public static GUIStyle Tab
        {
            get
            {
                if (_Tab == null)
                {
                    _Tab = new GUIStyle(EditorStyles.miniButtonMid)
                    {
                        alignment = TextAnchor.MiddleCenter,
                        stretchWidth = true,
                        richText = true,
                        wordWrap = true,
                        fontSize = 12,
                        fixedHeight = 27.5f,
                        fontStyle = FontStyle.Bold,
                        padding = new RectOffset()
                        {
                            left = 14,
                            right = 14,
                            top = 8,
                            bottom = 8
                        }
                    };
                }

                return _Tab;
            }
        }

        private static GUIStyle _Button;
        public static GUIStyle Button
        {
            get
            {
                if (_Button == null)
                {
                    _Button = new GUIStyle(UnityEngine.GUI.skin.button)
                    {
                        alignment = TextAnchor.MiddleLeft,
                        stretchWidth = true,
                        richText = true,
                        wordWrap = true,
                        padding = new RectOffset()
                        {
                            left = 14,
                            right = 14,
                            top = 8,
                            bottom = 8
                        }
                    };
                }

                return _Button;
            }
        }

        public static void DrawActionBox(string text, string label, MessageType messageType, Action action)
        {
            Assert.IsNotNull(action);

            EditorGUILayout.HelpBox(text, messageType);

            GUILayout.Space(-32);
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.FlexibleSpace();

                if (GUILayout.Button(label, GUILayout.Width(60)))
                    action();

                GUILayout.Space(8);
            }
            GUILayout.Space(11);
        }

        public class ParameterGroup
        {
            static ParameterGroup()
            {
                Section = new GUIStyle(EditorStyles.helpBox)
                {
                    margin = new RectOffset(0, 0, -10, 10),
                    padding = new RectOffset(10, 10, 10, 10),
                    clipping = TextClipping.Clip,
                };

                headerLabel = new GUIStyle(EditorStyles.miniLabel);
                headerBackgroundDark = new Color(0.1f, 0.1f, 0.1f, 0.2f);
                headerBackgroundLight = new Color(1f, 1f, 1f, 0.2f);
                paneOptionsIconDark = (Texture2D)EditorGUIUtility.Load("Builtin Skins/DarkSkin/Images/pane options.png");
                paneOptionsIconLight = (Texture2D)EditorGUIUtility.Load("Builtin Skins/LightSkin/Images/pane options.png");
                splitterDark = new Color(0.12f, 0.12f, 0.12f, 1.333f);
                splitterLight = new Color(0.6f, 0.6f, 0.6f, 1.333f);
            }

            public static readonly GUIStyle headerLabel;
            public static GUIStyle Section;
            static readonly Texture2D paneOptionsIconDark;
            static readonly Texture2D paneOptionsIconLight;
            public static Texture2D paneOptionsIcon { get { return EditorGUIUtility.isProSkin ? paneOptionsIconDark : paneOptionsIconLight; } }
            static readonly Color headerBackgroundDark;
            static readonly Color headerBackgroundLight;
            public static Color headerBackground { get { return EditorGUIUtility.isProSkin ? headerBackgroundDark : headerBackgroundLight; } }

            static readonly Color splitterDark;
            static readonly Color splitterLight;
            public static Color splitter { get { return EditorGUIUtility.isProSkin ? splitterDark : splitterLight; } }

            public static void DrawHeader(GUIContent content)
            {
                //DrawSplitter();
                Rect backgroundRect = GUILayoutUtility.GetRect(1f, 20f);

                if (content.image)
                {
                    content.text = " " + content.text;
                }

                Rect labelRect = backgroundRect;
                labelRect.y += 0f;
                labelRect.xMin += 5f;
                labelRect.xMax -= 20f;

                // Background rect should be full-width
                backgroundRect.xMin = 10f;
                //backgroundRect.width -= 10f;

                // Background
                EditorGUI.DrawRect(backgroundRect, headerBackground);

                // Title
                EditorGUI.LabelField(labelRect, content, EditorStyles.boldLabel);

                DrawSplitter();
            }

            public static void DrawSplitter()
            {
                var rect = GUILayoutUtility.GetRect(1f, 1f);

                // Splitter rect should be full-width
                rect.xMin = 10f;
                //rect.width -= 10f;

                if (Event.current.type != EventType.Repaint)
                    return;

                EditorGUI.DrawRect(rect, splitter);
            }


        }

    }
}