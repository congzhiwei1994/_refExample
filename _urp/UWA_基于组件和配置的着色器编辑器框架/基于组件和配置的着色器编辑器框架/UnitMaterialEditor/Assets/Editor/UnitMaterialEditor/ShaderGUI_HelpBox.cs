using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using System.Text.RegularExpressions;
using UME.UnitShaderGUIAttribute;

namespace UME {

    [AllowMultiple]
    public class ShaderGUI_HelpBox : UnitMaterialEditor {

        GUIStyle m_style = null;
        MessageType m_type = MessageType.None;
        int m_fontSize = 0;
        String m_text = String.Empty;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            if ( m_style == null ) {
                m_style = GUI.skin.GetStyle( "HelpBox" );
            }
            if ( m_args != null ) {
                m_args.GetField( out m_text, Cfg.Key_Text, String.Empty );
                String type;
                if ( m_args.GetField( out type, "type", "none" ) && !String.IsNullOrEmpty( type ) ) {
                    try {
                        m_type = ( MessageType )Enum.Parse( typeof( MessageType ), type, true );
                    } catch ( Exception e ) {
                        Debug.LogException( e );
                    }
                }
                return !String.IsNullOrEmpty( m_text );
            }
            return false;
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
            if ( modeMatch == null || modeMatch != null && !modeMatch.Value ) {
                return;
            }
            var boolTest = GetBoolTestResult( props );
            if ( boolTest == null || boolTest != null && boolTest.Value == false ) {
                return;
            }
            var showText = String.Empty;
            if ( !String.IsNullOrEmpty( m_text ) ) {
                var jo = m_args.GetField( "params" );
                m_args.GetField( out m_fontSize, "fontsize", 0 );
                List<object> pars = null;
                if ( jo != null ) {
                    if ( jo.IsArray ) {
                        for ( int i = 0; i < jo.Count; ++i ) {
                            var o = jo[ i ];
                            if ( o != null && !o.isContainer ) {
                                pars = pars ?? new List<object>();
                                pars.Add( ShaderGUIHelper.JSONValueToString( o ) );
                            }
                        }
                    } else if ( jo.IsObject == false ) {
                        pars = pars ?? new List<object>();
                        pars.Add( ShaderGUIHelper.JSONValueToString( jo ) );
                    }
                }
                for ( ; ; ) {
                    showText = m_text;
                    var m = Regex.Matches( m_text, @"\{(\d+)\}" );
                    if ( m.Count > 0 ) {
                        var maxIndex = 0;
                        for ( int i = 0; i < m.Count; ++i ) {
                            var groups = m[ i ].Groups;
                            if ( groups.Count == 2 ) {
                                var index = -1;
                                if ( int.TryParse( groups[ 1 ].ToString(), out index ) ) {
                                    if ( index > maxIndex && index >= 0 ) {
                                        maxIndex = index;
                                    }
                                }
                            }
                        }
                        if ( maxIndex >= 0 ) {
                            pars = pars ?? new List<object>();
                            if ( pars.Count < maxIndex + 1 ) {
                                pars.Resize( maxIndex + 1 );
                            }
                            for ( int i = 0; i < pars.Count; ++i ) {
                                var ref_id = pars[ i ] as String;
                                if ( !String.IsNullOrEmpty( ref_id ) ) {
                                    var prop = FindPropEditor<UnitMaterialEditor>( ref_id );
                                    if ( prop != null ) {
                                        String v;
                                        var b = prop.GetReturnValue( out v, props );
                                        if ( !b || String.IsNullOrEmpty( v ) ) {
                                            v = "null";
                                        }
                                        pars[ i ] = v;
                                    }
                                }
                            }
                            showText = String.Format( m_text, pars.ToArray() );
                        }
                    }
                    break;
                }
            }
            if ( m_style != null ) {
                var _richText = m_style.richText;
                var _fontSize = m_style.fontSize;
                m_style.richText = true;
                if ( m_fontSize > 0 ) {
                    m_style.fontSize = m_fontSize;
                }
                EditorGUILayout.HelpBox( showText, m_type );
                m_style.richText = _richText;
                m_style.fontSize = _fontSize;
            }
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_HelpBox();
        }

    }
}
//EOF
