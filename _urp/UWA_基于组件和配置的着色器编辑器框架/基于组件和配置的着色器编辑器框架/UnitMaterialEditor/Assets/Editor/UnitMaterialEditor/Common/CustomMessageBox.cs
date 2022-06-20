using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace UME {

    public class CustomMessageBox : EditorWindow {

        public delegate void OnWindowClose( int button, int returnValue );
        public String Info = String.Empty;
        public Func<int> OnGUIFunc = null;
        public Action<int>[] OnButtonClicks = null;
        public OnWindowClose OnClose = null;
        public String[] Buttons = null;
        public int ReturnValue = 0;
        int m_closeButton = -1;

        public void OnDestroy() {
            if ( OnClose != null ) {
                try {
                    OnClose( m_closeButton, ReturnValue );
                } catch ( Exception e ) {
                    Debug.LogException( e );
                }
            }
        }

        public void OnGUI() {
            EditorGUILayout.BeginVertical();
            EditorGUILayout.Space();
            if ( !string.IsNullOrEmpty( Info ) ) {
                EditorGUILayout.HelpBox( Info, MessageType.None );
            }
            EditorGUILayout.Space();
            if ( OnGUIFunc != null ) {
                ReturnValue = OnGUIFunc();
            }
            EditorGUILayout.Space();
            EditorGUILayout.BeginHorizontal();
            if ( Buttons != null ) {
                for ( int i = 0; i < Buttons.Length; ++i ) {
                    if ( GUILayout.Button( Buttons[ i ], GUILayout.MinWidth( 80 ) ) ) {
                        m_closeButton = i;
                        if ( OnButtonClicks != null ) {
                            if ( i >= 0 && i <= OnButtonClicks.Length && OnButtonClicks[ i ] != null ) {
                                try {
                                    OnButtonClicks[ i ]( ReturnValue );
                                } catch ( Exception e ) {
                                    Debug.LogException( e );
                                }
                            }
                        }
                        EditorApplication.delayCall += () => {
                            Close();
                        };
                    }
                    GUILayout.Space( 5 );
                }
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();
            EditorGUILayout.EndVertical();
        }
    }
}
//EOF
