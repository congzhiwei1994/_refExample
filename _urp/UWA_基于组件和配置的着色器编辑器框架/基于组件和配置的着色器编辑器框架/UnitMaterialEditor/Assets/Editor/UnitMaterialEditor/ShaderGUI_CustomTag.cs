using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    class ShaderGUI_CustomTag : UnitMaterialEditor {

        static readonly String[] BuiltinTags = new String[]{
            "RenderType"
        };

        enum UpgradeOPType {
            None = 0,
            Cut,
            Copy,
        }

        class TagDefine {
            internal String typename;
            internal String[] values;
            internal bool readOnly;
            internal String keep;
            internal String upgradeTypename;
            /// <summary>
            /// 别名，从另外的tag升级过来
            /// </summary>
            internal HashSet<String> alias;
            /// <summary>
            /// shader中自定义的Tag是删除不掉的，只有通过在其关联材质上设置一个表示空含义的值覆盖
            /// </summary>
            internal bool removeAble = true;
            internal bool builtin = false;
            internal UpgradeOPType upgradeOPType = UpgradeOPType.None;
            internal Dictionary<Material, UpgradeOPType> upgradeState = null;
            public override string ToString() {
                if ( String.IsNullOrEmpty( upgradeTypename ) ) {
                    return typename;
                } else {
                    return String.Format( "{0} ={1}=> {2}", typename, upgradeOPType, upgradeTypename );
                }
            }
        }

        List<TagDefine> m_tags = null;
        bool m_show = true;

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            if ( m_tags != null ) {
                return true;
            }
            m_show = true;
            m_tags = new List<TagDefine>();
            // 从编辑器数据中获取用户自定义Tag
            var tags = m_args.GetField( Cfg.ArgsKey_CustomTag_Tags );
            if ( tags != null && tags.IsArray && tags.list.Count > 0 ) {
                for ( int i = 0; i < tags.list.Count; ++i ) {
                    var tagDef = tags.list[ i ];
                    if ( tagDef.IsObject ) {
                        String type;
                        if ( tagDef.GetField( out type, Cfg.ArgsKey_CustomTag_Type, String.Empty ) ) {
                            type = type.Trim();
                            var values = tagDef.GetField( Cfg.ArgsKey_CustomTag_Values );
                            if ( values != null && values.IsArray && values.Count > 0 ) {
                                if ( m_tags.Find( item => item.typename == type ) != null ) {
                                    Debug.LogErrorFormat( "Tag {0} already exists.", type );
                                    continue;
                                }
                                var tagdef = new TagDefine();
                                tagdef.typename = type;
                                tagDef.GetField( out tagdef.readOnly, Cfg.ArgsKey_CustomTag_Readonly, false );
                                var _values = new List<String>( values.Count );
                                for ( int n = 0; n < values.Count; ++n ) {
                                    var v = values[ n ];
                                    var value = String.Empty;
                                    if ( v.IsString && !String.IsNullOrEmpty( v.str ) &&
                                        !_values.Contains( value = v.str.Trim() ) ) {
                                        _values.Add( value );
                                    }
                                }
                                // 一个定义需要升级到另外一个Tag
                                var op = UpgradeOPType.None;
                                var target = String.Empty;
                                if ( tagDef.GetField( out target, Cfg.ArgsKey_CustomTag_UpgradeTo, String.Empty ) ) {
                                    op = UpgradeOPType.Cut;
                                } else if ( tagDef.GetField( out target, Cfg.ArgsKey_CustomTag_CopyTo, String.Empty ) ) {
                                    op = UpgradeOPType.Copy;
                                }
                                target = target.Trim();
                                if ( !String.IsNullOrEmpty( target ) ) {
                                    tagdef.upgradeOPType = op;
                                    tagdef.upgradeTypename = target;
                                    // 找到升级目标Tag定义
                                    var targetTypeDef = m_tags.Find( item => item.typename == tagdef.upgradeTypename );
                                    if ( targetTypeDef != null ) {
                                        // 保存别名
                                        targetTypeDef.alias = targetTypeDef.alias ?? new HashSet<String>();
                                        targetTypeDef.alias.Add( tagdef.upgradeTypename );
                                        if ( targetTypeDef.values != null ) {
                                            // 把选项合并
                                            _values.AddRange( targetTypeDef.values );
                                        }
                                    } else {
                                        Debug.LogErrorFormat( "upgrade type from '{0}' to '{1}' not found.", type, tagdef.upgradeTypename );
                                    }
                                    // 测试需要升级的当前tag是否可以被删除
                                    var material = m_MaterialEditor.target as Material;
                                    if ( material != null ) {
                                        var removeAble = ShaderGUIHelper.IsTagRemoveable( material, type );
                                        if ( removeAble != null ) {
                                            tagdef.removeAble = removeAble.Value;
                                        }
                                    }
                                }
                                if ( _values.Count > 0 ) {
                                    var keepValue = tagDef.GetField( Cfg.Key_FixedValue );
                                    if ( keepValue != null && keepValue.IsString ) {
                                        tagdef.keep = keepValue.str.Trim();
                                        if ( !String.IsNullOrEmpty( tagdef.keep ) ) {
                                            if ( !_values.Contains( tagdef.keep ) ) {
                                                Debug.LogErrorFormat( "Tag value '{0}' is not defined.", tagdef.keep );
                                            } else {
                                                tagdef.readOnly = true;
                                            }
                                        }
                                    }
                                    // 去重后转换为数组
                                    tagdef.values = _values.Distinct().ToArray();
                                    m_tags = m_tags ?? new List<TagDefine>();
                                    m_tags.Add( tagdef );
                                }
                            }
                        }
                    }
                }
            }
            // 从当前材质中获取已有的系统Tag
            var materials = m_MaterialEditor.targets.Where( e => e is Material ).Cast<Material>().ToArray();
            for ( int m = 0; m < materials.Length; ++m ) {
                var mat = materials[ m ];
                if ( mat == null ) {
                    continue;
                }
                for ( int i = 0; i < BuiltinTags.Length; ++i ) {
                    var typename = BuiltinTags[ i ];
                    var value = mat.GetTag( typename, true );
                    if ( !String.IsNullOrEmpty( value ) ) {
                        m_tags = m_tags ?? new List<TagDefine>();
                        var defIndex = m_tags.FindIndex( item => item.typename == typename );
                        TagDefine def;
                        if ( defIndex >= 0 ) {
                            def = m_tags[ defIndex ];
                            // 定义了系统Tag，把系统tag当前值追加进选项
                            if ( def.values != null ) {
                                var _values = new List<String>( def.values );
                                if ( !_values.Contains( value ) ) {
                                    _values.Add( value );
                                    def.values = _values.ToArray();
                                }
                            } else {
                                // 编辑器中没有定义选项，此选项只读，唯一选项
                                def.values = new String[] { value };
                                def.readOnly = true;
                            }
                            if ( defIndex > 0 ) {
                                // 交换到前面去
                                var t = m_tags[ 0 ];
                                m_tags[ 0 ] = def;
                                m_tags[ defIndex ] = t;
                            }
                        } else {
                            // 编辑器没有定义，只读唯一选项
                            def = new TagDefine();
                            def.typename = typename;
                            def.readOnly = true;
                            def.values = new String[] { value };
                            m_tags.Insert( 0, def );
                        }
                        def.builtin = true;
                    }
                }
            }
            // 设置固定不变值
            for ( int i = 0; i < m_tags.Count; ++i ) {
                var tagdef = m_tags[ i ];
                if ( !String.IsNullOrEmpty( tagdef.keep ) ) {
                    if ( tagdef.values != null ) {
                        if ( Array.IndexOf( tagdef.values, tagdef.keep ) >= 0 ) {
                            for ( int j = 0; j < materials.Length; ++j ) {
                                _SetOverrideTag( materials[ j ], tagdef.typename, tagdef.keep, true );
                            }
                        }
                    }
                }
            }
            DoUpgrade();
            return true;
        }

        void SetOverrideTag( String name, String newValue, bool report = false, bool overwrite = false ) {
            var target = m_MaterialEditor.target as Material;
            _SetOverrideTag( target, name, newValue, report, overwrite );
        }

        bool _SetOverrideTag( Material target, String name, String newValue, bool report = false, bool overwrite = false ) {
            if ( !overwrite ) {
                newValue = IsNullTagValue( newValue ) ? String.Empty : newValue;
            }
            var m = target as Material;
            if ( m != null ) {
                var oldValue = m.GetTag( name, true );
                if ( oldValue != newValue ) {
                    m.SetOverrideTag( name, newValue );
                    if ( report ) {
                        Debug.LogFormat( "SetOverrideTag: {0}.{1}, '{2}' => '{3}'",
                            m.name, name, oldValue, newValue );
                    }
                    EditorUtility.SetDirty( m );
                    return true;
                }
            }
            return false;
        }

        bool? RemoveOverrideTag( String name, out String oldValue ) {
            return _RemoveOverrideTag( m_MaterialEditor.target as Material, name, out oldValue );
        }

        bool? _RemoveOverrideTag( Material m, String name, out String oldValue ) {
            bool? ret = null;
            if ( m != null ) {
                var tag = m.GetTag( name, true );
                oldValue = tag;
                if ( !String.IsNullOrEmpty( tag ) ) {
                    if ( ret == null ) {
                        ret = true;
                    }
                    m.SetOverrideTag( name, String.Empty );
                    if ( !String.IsNullOrEmpty( m.GetTag( name, true ) ) ) {
                        // 删除不掉，说明Shader定义了固定tag
                        ret = false;
                    }
                    EditorUtility.SetDirty( m );
                }
            } else {
                oldValue = String.Empty;
            }
            return ret;
        }

        static bool IsNullTagValue( String value ) {
            return String.IsNullOrEmpty( value ) || IsOptionNone( value );
        }

        static bool IsOptionNone( String value ) {
            return value.Equals( "None", StringComparison.OrdinalIgnoreCase ) ||
                value.Equals( "Nil", StringComparison.OrdinalIgnoreCase ) ||
                value.Equals( "Null", StringComparison.OrdinalIgnoreCase );
        }

        void UpgradeTag( Material mat, TagDefine tagdef, TagDefine upgradeType ) {
            if ( tagdef.upgradeOPType == UpgradeOPType.None ) {
                return;
            }
            tagdef.upgradeState = tagdef.upgradeState ?? new Dictionary<Material, UpgradeOPType>();
            UpgradeOPType state;
            if ( tagdef.upgradeState.TryGetValue( mat, out state ) && state == UpgradeOPType.None ) {
                return;
            }
            var typename = tagdef.typename;
            String oldVal;
            if ( tagdef.upgradeOPType == UpgradeOPType.Cut ) {
                var r = _RemoveOverrideTag( mat, typename, out oldVal );
                if ( r != null && r.Value == false ) {
                    // shader自定义的tag删除不掉，只有通过设置一个表示None的有效字段覆盖
                    tagdef.removeAble = false;
                    // 搜索升级类型选项
                    if ( upgradeType.values != null ) {
                        // 选择一个表示空的选项，用于覆盖Shader默认Tag
                        var newValue = "None";
                        var noneIndex = Array.FindIndex(
                            upgradeType.values, s => s.Equals( "None", StringComparison.OrdinalIgnoreCase ) );
                        if ( noneIndex >= 0 ) {
                            newValue = upgradeType.values[ noneIndex ];
                        } else {
                            // 追加表示空的选项，用于覆盖默认值
                            var temp = new List<String>();
                            temp.Add( newValue );
                            if ( upgradeType.values != null ) {
                                temp.AddRange( upgradeType.values );
                            }
                            upgradeType.values = temp.ToArray();
                        }
                        if ( _SetOverrideTag( mat, typename, upgradeType.values[ 0 ], false, true ) ) {
                            Debug.LogFormat( "Upgrade tag '{0}' -> '{1}', cmd = {2}",
                                typename, tagdef.upgradeTypename, tagdef.upgradeOPType );
                        }
                    }
                }
            } else {
                if ( mat != null ) {
                    oldVal = mat.GetTag( typename, true );
                } else {
                    oldVal = String.Empty;
                }
            }
            if ( !String.IsNullOrEmpty( oldVal ) && upgradeType.values != null &&
                !oldVal.Equals( "None", StringComparison.OrdinalIgnoreCase ) ) {
                // 把原有值写入升级后的类型中去
                if ( IsOptionNone( oldVal ) ) {
                    // 找到目标选项中对应的空值
                    var noneIndex = Array.FindIndex( upgradeType.values, item => IsOptionNone( item ) );
                    if ( noneIndex >= 0 ) {
                        // 修正空值，保证选项中包含
                        oldVal = upgradeType.values[ noneIndex ];
                    }
                }
                if ( Array.IndexOf( upgradeType.values, oldVal ) >= 0 ) {
                    // 把旧值存到新Tag类型中去
                    if ( _SetOverrideTag( mat, upgradeType.typename, oldVal, true, false ) ) {
                        Debug.LogFormat( "Upgrade tag '{0}' -> '{1}', cmd = {2}",
                            typename, tagdef.upgradeTypename, tagdef.upgradeOPType );
                    }
                }
            }
            tagdef.upgradeState[ mat ] = UpgradeOPType.None;
        }

        void DoUpgrade() {
            var targets = m_MaterialEditor.targets.Where( e => e is Material ).Cast<Material>().ToArray();
            for ( int i = 0; m_tags != null && i < m_tags.Count; ++i ) {
                var tagdef = m_tags[ i ];
                if ( !String.IsNullOrEmpty( tagdef.upgradeTypename ) ) {
                    var typename = tagdef.typename;
                    tagdef.upgradeState = tagdef.upgradeState ?? new Dictionary<Material, UpgradeOPType>();
                    var opState = tagdef.upgradeState;
                    for ( int mi = 0; mi < targets.Length; ++mi ) {
                        var mat = targets[ mi ];
                        UpgradeOPType curOp;
                        if ( opState.TryGetValue( mat, out curOp ) && curOp == UpgradeOPType.None ) {
                            // 已经处理过了
                            continue;
                        }
                        var value = mat.GetTag( typename, true );
                        if ( tagdef.upgradeOPType != UpgradeOPType.None ) {
                            if ( tagdef.upgradeOPType == UpgradeOPType.Cut && tagdef.removeAble == false && IsOptionNone( value ) ) {
                                // 剪切模式下，要升级的类型值已经用空值覆盖，跳过处理
                                // 这会导致一个问题就是：如果一个没有升级的Tag，但是其值原本就是空，
                                // 这样会导致这个状态不会被拷贝到需要升级的目标中去
                                opState[ mat ] = UpgradeOPType.None;
                                continue;
                            }
                            var upgradeTypename = tagdef.upgradeTypename;
                            var upgradeType = m_tags.Find( item => item.typename == upgradeTypename );
                            if ( !String.IsNullOrEmpty( value ) && upgradeType != null ) {
                                UpgradeTag( mat, tagdef, upgradeType );
                            }
                            continue;
                        }
                        // value 可能为空字符串，也可能是表示空的有效字符串如'None'
                        var index = Array.IndexOf( tagdef.values, value );
                        var newIndex = index;
                        var fixTag = false;
                        if ( index == -1 ) {
                            if ( tagdef.builtin ) {
                                // 系统tag，如果当前tag值没在选项中，追加
                                if ( !String.IsNullOrEmpty( value ) ) {
                                    Array.Resize( ref tagdef.values, tagdef.values.Length + 1 );
                                    tagdef.values[ tagdef.values.Length - 1 ] = value;
                                    newIndex = tagdef.values.Length - 1;
                                }
                            } else {
                                newIndex = 0;
                                if ( !IsNullTagValue( value ) ) {
                                    // 非空值，没有在选项中找到，当作一次修复操作，需要提示用户
                                    fixTag = true;
                                }
                            }
                        }
                        if ( newIndex >= 0 && newIndex != index ) {
                            if ( !tagdef.readOnly ) {
                                _SetOverrideTag( mat, typename, tagdef.values[ newIndex ], fixTag );
                            }
                        }
                    }
                }
            }
            // tag清理
            var tagMap = new Dictionary<String, String>();
            for ( int i = 0; i < targets.Length; ++i ) {
                var target = targets[ i ];
                if ( ShaderGUIHelper.GetMaterialOverrideTags( target, ref tagMap ) ) {
                    foreach ( var tag in tagMap ) {
                        var def = m_tags.Find( e => e.typename == tag.Key );
                        if ( def == null && Array.IndexOf( BuiltinTags, tag.Key ) < 0 ) {
                            // 材质中有编辑器未定义的tag
                            var removeAble = ShaderGUIHelper.IsTagRemoveable( target, tag.Key );
                            if ( removeAble != null && removeAble.Value ) {
                                target.SetOverrideTag( tag.Key, String.Empty );
                                Debug.LogFormat( "Remove Override Tag: {0}", tag.Key );
                                EditorUtility.SetDirty( target );
                            }
                        }
                    }
                }
            }
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            var targets = m_MaterialEditor.targets;
            var target = targets[ 0 ] as Material;
            m_show = EditorGUILayout.Foldout( m_show, "Custom Tag Editor" );
            if ( m_show && targets.Length == 1 && target != null && m_tags != null ) {
                try {
                    m_MaterialEditor.SetDefaultGUIWidths();
                    EditorGUI.indentLevel++;
                    EditorGUILayout.BeginVertical();
                    for ( int i = 0; i < m_tags.Count; ++i ) {
                        var tagdef = m_tags[ i ];
                        if ( tagdef.values != null && tagdef.values.Length > 0 &&
                            String.IsNullOrEmpty( tagdef.upgradeTypename ) ) {
                            var typename = tagdef.typename;
                            var value = target.GetTag( typename, true );
                            // value 可能为空字符串，也可能是表示空的有效字符串如'None'
                            if ( String.IsNullOrEmpty( value ) ) {
                                // 非升级类型，修正选项为表示空或者否定词
                                var _index = Array.FindIndex(
                                    tagdef.values,
                                    e => {
                                        return IsOptionNone( e ) ||
                                            e.Equals( "Off", StringComparison.OrdinalIgnoreCase ) ||
                                            e.Equals( "Empty", StringComparison.OrdinalIgnoreCase ) ||
                                            e.Equals( "No", StringComparison.OrdinalIgnoreCase ) ||
                                            e.Equals( "Not", StringComparison.OrdinalIgnoreCase );
                                    }
                                );
                                if ( _index >= 0 ) {
                                    value = tagdef.values[ _index ];
                                } else {
                                    value = tagdef.values[ 0 ];
                                }
                            }
                            var index = Array.IndexOf( tagdef.values, value );
                            if ( index < 0 && !String.IsNullOrEmpty( value ) ) {
                                // 追加选项
                                var last = tagdef.values.Length;
                                Array.Resize( ref tagdef.values, last + 1 );
                                tagdef.values[ last ] = value;
                                index = last;
                            }
                            if ( index >= 0 ) {
                                using ( new GUISetEnabled( !tagdef.readOnly ) ) {
                                    var fixTag = false;
                                    var newIndex = EditorGUILayout.Popup( typename, index, tagdef.values );
                                    if ( ( newIndex != index || fixTag ) && !tagdef.readOnly ) {
                                        _SetOverrideTag( target, typename, tagdef.values[ newIndex ], false );
                                    }
                                }
                            }
                        }
                    }
                    using ( new GUISetEnabled( false ) ) {
                        for ( int i = 0; i < m_tags.Count; ++i ) {
                            var tagdef = m_tags[ i ];
                            if ( !String.IsNullOrEmpty( tagdef.upgradeTypename ) ) {
                                var value = target.GetTag( tagdef.typename, true );
                                var title = tagdef.typename;
                                if ( tagdef.upgradeOPType == UpgradeOPType.Cut ) {
                                    title += " [removed]";
                                } else if ( tagdef.upgradeOPType == UpgradeOPType.Copy ) {
                                    title += String.Format( " [copy to {0}]", tagdef.upgradeTypename );
                                }
                                if ( !tagdef.removeAble ) {
                                    title += " [covered]";
                                }
                                if ( String.IsNullOrEmpty( value ) ) {
                                    var _index = Array.FindIndex(
                                        tagdef.values,
                                        e => {
                                            return IsOptionNone( e ) ||
                                                e.Equals( "Off", StringComparison.OrdinalIgnoreCase ) ||
                                                e.Equals( "Empty", StringComparison.OrdinalIgnoreCase ) ||
                                                e.Equals( "No", StringComparison.OrdinalIgnoreCase ) ||
                                                e.Equals( "Not", StringComparison.OrdinalIgnoreCase );
                                        }
                                    );
                                    if ( _index >= 0 ) {
                                        value = tagdef.values[ _index ];
                                    }
                                }
                                while ( !String.IsNullOrEmpty( value ) ) {
                                    if ( tagdef.values != null ) {
                                        var index = Array.IndexOf( tagdef.values, value );
                                        if ( index >= 0 ) {
                                            EditorGUILayout.Popup( title, index, tagdef.values );
                                        } else {
                                            index = tagdef.values.Length;
                                            Array.Resize( ref tagdef.values, tagdef.values.Length + 1 );
                                            tagdef.values[ index ] = value;
                                            EditorGUILayout.Popup( title, index, tagdef.values );
                                        }
                                        break;
                                    }
                                    EditorGUILayout.Popup( title, 0, new String[] { value } );
                                    break;
                                }
                            }
                        }
                    }
                } finally {
                    EditorGUILayout.EndVertical();
                    m_MaterialEditor.SetDefaultGUIWidths();
                    EditorGUI.indentLevel--;
                }
            }
            if ( targets.Length > 1 ) {
                EditorGUILayout.HelpBox( "Custom Tag Editor does not support multi-selection materials.", MessageType.Warning );
            }
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_CustomTag();
        }
    }
}
