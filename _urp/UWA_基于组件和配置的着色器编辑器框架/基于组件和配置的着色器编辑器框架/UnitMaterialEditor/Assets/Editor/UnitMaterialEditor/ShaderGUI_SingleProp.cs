using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_SingleProp : UnitMaterialEditor {

        protected enum Precision {
            Default = 0,
            Low = 8,
            Half = 16,
            High = 32,
        }

        protected enum HideReset {
            None = 0,
            Auto,
            Conditional,
        }

        const int DefaultPrecision_Color = 256;

        protected String m_propName = String.Empty;
        protected String m_label = String.Empty;
        protected String m_guiType = String.Empty;
        protected HideReset m_hideReset = HideReset.Auto;
        protected bool? m_dirty = null;
        protected MaterialProperty m_prop = null;
        protected object m_keep = null;
        protected int m_precision = 0;
        protected Vector2? m_mapRange = null;
        protected Vector2? m_exRange = null;

        static List<KeyValuePair<String, String>> s_upgradeList = new List<KeyValuePair<String, String>>();

        /// <summary>
        /// 在这里增加想要强制升级的属性：key: to -> value: from
        /// 随着项目推进，有些Shader属性需要升级或者迁移，这时候用这个功能来自动升级迁移原有属性值到新定义属性上
        /// </summary>
        static KeyValuePair<String, String>[] s_autoUpgradeList = new KeyValuePair<string, string>[] {
            STuple.Pair( "_OutlineNormalSource", "_OutlineUseTangentAsNormal" ),
        };

        public String propName {
            get {
                return m_propName ?? String.Empty;
            }
        }

        public override String ToString() {
            var s = base.ToString();
            if ( !String.IsNullOrEmpty( m_propName ) ) {
                s = String.Format( "{0}->{1}", s, m_propName );
            }
            return s;
        }

        static float DrawRangeProperty( Rect position, MaterialProperty prop, float value, String label, float left, float right, int precision = 0, float? defaultVal = null ) {
            EditorGUI.showMixedValue = prop.hasMixedValue;
            float labelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 0f;
            float floatValue = EditorGUI.Slider( position, label, value, left, right );
            floatValue = _RoundRange( floatValue, new Vector3( defaultVal != null ? defaultVal.Value : 0, left, right ), precision );
            EditorGUI.showMixedValue = false;
            EditorGUIUtility.labelWidth = labelWidth;
            return floatValue;
        }

        /// <summary>
        /// 获取Float/Range类型属性默认值与取值范围
        /// </summary>
        /// <param name="shader"></param>
        /// <param name="name"></param>
        /// <returns></returns>
        static Vector3? GetDefaultRange( Shader shader, String name ) {
            var index = ShaderUtils.FindPropertyIndex( shader, name, ShaderUtil.ShaderPropertyType.Range );
            if ( index >= 0 ) {
                return new Vector3(
                    ShaderUtil.GetRangeLimits( shader, index, 0 ),
                    ShaderUtil.GetRangeLimits( shader, index, 1 ),
                    ShaderUtil.GetRangeLimits( shader, index, 2 ) );
            } else {
                index = ShaderUtils.FindPropertyIndex( shader, name, ShaderUtil.ShaderPropertyType.Float );
                if ( index >= 0 ) {
                    return new Vector3( ShaderUtil.GetRangeLimits( shader, index, 0 ), float.MinValue, float.MaxValue );
                }
            }
            return null;
        }

        /// <summary>
        /// 读取指定属性默认值（Unity只提供了Float, 和Range类型的默认值获取，其他类型属性从模板材质中读取）
        /// </summary>
        /// <param name="template"></param>
        /// <param name="propName"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        protected static object GetDefaultValue( Material template, String propName, ShaderUtil.ShaderPropertyType type ) {
            if ( template != null && !IsEmptyShader( template.shader ) && template.HasProperty( propName ) ) {
                var propType = FindShaderPropertyType( template.shader, propName );
                if ( propType != null ) {
                    switch ( propType ) {
                    case ShaderUtil.ShaderPropertyType.Float:
                    case ShaderUtil.ShaderPropertyType.Range: {
                            var v = GetDefaultRange( template.shader, propName );
                            if ( v.HasValue ) {
                                return v.Value.x;
                            }
                        }
                        break;
                    case ShaderUtil.ShaderPropertyType.TexEnv:
                        return template.GetTexture( propName );
                    case ShaderUtil.ShaderPropertyType.Vector:
                        return template.GetVector( propName );
                    case ShaderUtil.ShaderPropertyType.Color:
                        return template.GetColor( propName );
                    }
                }
            }
            return null;
        }

        internal static int ColorGUITypeToComponentIndex( String guiType ) {
            if ( !String.IsNullOrEmpty( guiType ) && guiType.StartsWith( Cfg.Value_PropGUIType_ColorPrefix ) ) {
                var cindex = 0;
                switch ( guiType ) {
                case Cfg.Value_PropGUIType_ColorR:
                    cindex = 0;
                    break;
                case Cfg.Value_PropGUIType_ColorG:
                    cindex = 1;
                    break;
                case Cfg.Value_PropGUIType_ColorB:
                    cindex = 2;
                    break;
                case Cfg.Value_PropGUIType_ColorA:
                    cindex = 3;
                    break;
                }
                return cindex;
            }
            return -1;
        }

        /// <summary>
        /// 重置指定材质属性回归默认值
        /// </summary>
        /// <param name="template"></param>
        /// <param name="prop"></param>
        protected void ResetToDefaultValue( Material template, MaterialProperty prop ) {
            if ( prop != null && !prop.hasMixedValue && template != null && !IsEmptyShader( template.shader ) && template.HasProperty( prop.name ) ) {
                var propType = FindShaderPropertyType( template.shader, prop.name );
                if ( propType == null ) {
                    return;
                }
                switch ( propType.Value ) {
                case ShaderUtil.ShaderPropertyType.Range:
                case ShaderUtil.ShaderPropertyType.Float:
                    var _defalueVal = GetDefaultRange( template.shader, prop.name );
                    if ( _defalueVal != null ) {
                        if ( m_exRange != null ) {
                            _defalueVal = new Vector3( _defalueVal.Value.x, m_exRange.Value.x, m_exRange.Value.y );
                        }
                        if ( propType.Value == ShaderUtil.ShaderPropertyType.Float && m_exRange == null ) {
                            prop.floatValue = _RoundFloat( _defalueVal.Value.x, _defalueVal.Value.x );
                        } else {
                            Debug.Assert( propType.Value == ShaderUtil.ShaderPropertyType.Range );
                            prop.floatValue = _RoundRange( _defalueVal.Value.x, _defalueVal.Value );
                        }
                        Debug.AssertFormat( prop.floatValue == _defalueVal.Value.x,
                            "{0} = {1}/[{2}]", prop.name, prop.floatValue, _defalueVal.Value.x );
                    }
                    break;
                case ShaderUtil.ShaderPropertyType.Color: {
                        var srcValue = template.GetColor( prop.name );
                        var dstValue = prop.colorValue;
                        if ( !String.IsNullOrEmpty( m_guiType ) && m_guiType.StartsWith( Cfg.Value_PropGUIType_ColorPrefix ) ) {
                            // 用户设置了编辑器类型覆盖
                            var cindex = ColorGUITypeToComponentIndex( m_guiType );
                            if ( cindex >= 0 ) {
                                // 只重置编辑器使用的分量
                                var curValue = srcValue[ cindex ];
                                if ( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0 && m_exRange != null ) {
                                    dstValue[ cindex ] = _RoundColor( true, srcValue[ cindex ], new Vector3( srcValue[ cindex ], m_exRange.Value.x, m_exRange.Value.y ), m_precision );
                                } else {
                                    dstValue[ cindex ] = _RoundColor( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0, srcValue[ cindex ], new Vector3( srcValue[ cindex ], 0, 1 ), m_precision );
                                }
                                Debug.AssertFormat( dstValue[ cindex ] == srcValue[ cindex ], "{0}.{1} = {2}/[{3}]", prop.name, m_guiType, dstValue, srcValue );
                            }
                        } else {
                            if ( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0 && m_exRange != null ) {
                                // HDR有更大的值域范围，如果定义了范围，则可以进行区域限定
                                for ( int i = 0; i < 4; ++i ) {
                                    dstValue[ i ] = _RoundColor( true, srcValue[ i ], new Vector3( srcValue[ i ], m_exRange.Value.x, m_exRange.Value.y ), m_precision );
                                }
                            } else {
                                // 如果是HDR，但是没有限定范围，只进行精度约束
                                for ( int i = 0; i < 4; ++i ) {
                                    dstValue[ i ] = _RoundColor( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0, srcValue[ i ], new Vector3( srcValue[ i ], 0, 1 ), m_precision );
                                }
                            }
                            Debug.AssertFormat( dstValue == srcValue, "{0} = {1}/[{2}]", prop.name, dstValue, srcValue );
                        }
                        prop.colorValue = dstValue;
                    }
                    break;
                case ShaderUtil.ShaderPropertyType.Vector: {
                        var srcValue = template.GetVector( prop.name );
                        var dstValue = prop.vectorValue;
                        if ( String.IsNullOrEmpty( m_guiType ) ) {
                            for ( int i = 0; i < 4; ++i ) {
                                dstValue[ i ] = _RoundFloat( srcValue[ i ], m_precision );
                            }
                        } else {
                            // 特殊编辑器覆盖类型，暂时不进行精度矫正
                            dstValue = srcValue;
                        }
                        Debug.AssertFormat( dstValue == srcValue, "{0} = {1}/[{2}]", prop.name, dstValue, srcValue );
                        prop.vectorValue = dstValue;
                    }
                    break;
                case ShaderUtil.ShaderPropertyType.TexEnv:
                    if ( prop.type == MaterialProperty.PropType.Texture ) {
                        prop.textureValue = template.GetTexture( prop.name );
                        prop.textureScaleAndOffset = template.GetTextureScaleOffset( prop.name );
                    }
                    break;
                }
            }
        }

        protected virtual void OnResetToDefaultValue( Material template ) {
            ResetToDefaultValue( template, m_prop );
        }

        protected bool FixPropertyPrecision( MaterialProperty prop, float? newFloatValue = null, Color? newColorValue = null, Vector4? newVectorValue = null ) {
            if ( prop == null || prop.hasMixedValue ) {
                return false;
            }
            var materials = targets;
            if ( materials == null || materials.Length == 0 ) {
                return false;
            }
            var shader = materials[ 0 ].shader;
            var range = new Vector3( 0, float.MinValue, float.MaxValue );
            if ( prop.type == MaterialProperty.PropType.Float ) {
                var index = ShaderUtils.FindPropertyIndex( shader, prop.name, ShaderUtil.ShaderPropertyType.Float );
                if ( index >= 0 ) {
                    range.x = ShaderUtil.GetRangeLimits( shader, index, 0 );
                }
                var prop_floatValue = _RoundFloat( newFloatValue != null ? newFloatValue.Value : prop.floatValue, range.x );
                if ( prop_floatValue != prop.floatValue ) {
                    prop.floatValue = prop_floatValue;
                    return true;
                }
            } else if ( prop.type == MaterialProperty.PropType.Range ) {
                range.y = prop.rangeLimits.x;
                range.z = prop.rangeLimits.y;
                if ( m_exRange != null ) {
                    range.y = m_exRange.Value.x;
                    range.z = m_exRange.Value.y;
                }
                var index = ShaderUtils.FindPropertyIndex( shader, prop.name, ShaderUtil.ShaderPropertyType.Range );
                if ( index >= 0 ) {
                    range.x = ShaderUtil.GetRangeLimits( shader, index, 0 );
                }
                var prop_floatValue = _RoundRange( newFloatValue != null ? newFloatValue.Value : prop.floatValue, range );
                if ( prop_floatValue != prop.floatValue ) {
                    prop.floatValue = prop_floatValue;
                    return true;
                }
            } else if ( prop.type == MaterialProperty.PropType.Color && m_parent.template != null ) {
                var _type = FindShaderPropertyType( m_parent.template.shader, prop.name );
                if ( _type != null && _type.Value == ShaderUtil.ShaderPropertyType.Color ) {
                    var defaultColor = m_parent.template.GetColor( prop.name );
                    var c = newColorValue != null ? newColorValue.Value : prop.colorValue;
                    var cindex = ColorGUITypeToComponentIndex( m_guiType );
                    if ( cindex >= 0 ) {
                        var curValue = prop.colorValue;
                        if ( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0 && m_exRange != null ) {
                            for ( int i = 0; i < 4; ++i ) {
                                // 只处理编辑器使用分量，其余分量保持不变
                                if ( i == cindex ) {
                                    c[ i ] = _RoundColor( true, c[ i ], new Vector3( defaultColor[ i ], m_exRange.Value.x, m_exRange.Value.y ), m_precision );
                                } else {
                                    c[ i ] = curValue[ i ];
                                }
                            }
                        } else {
                            for ( int i = 0; i < 4; ++i ) {
                                // 只处理编辑器使用分量，其余分量保持不变
                                if ( i == cindex ) {
                                    c[ i ] = _RoundColor( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0, c[ i ], new Vector3( defaultColor[ i ], 0, 1 ), m_precision );
                                } else {
                                    c[ i ] = curValue[ i ];
                                }
                            }
                        }
                    } else {
                        if ( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0 && m_exRange != null ) {
                            // HDR有更大的值域范围，如果定义了范围，则可以进行区域限定
                            for ( int i = 0; i < 4; ++i ) {
                                c[ i ] = _RoundColor( true, c[ i ], new Vector3( defaultColor[ i ], m_exRange.Value.x, m_exRange.Value.y ), m_precision );
                            }
                        } else {
                            // 如果是HDR，但是没有限定范围，只进行精度约束
                            for ( int i = 0; i < 4; ++i ) {
                                c[ i ] = _RoundColor( ( prop.flags & MaterialProperty.PropFlags.HDR ) != 0, c[ i ], new Vector3( defaultColor[ i ], 0, 1 ), m_precision );
                            }
                        }
                    }
                    if ( prop.colorValue != c ) {
                        prop.colorValue = c;
                        return true;
                    }
                }
            } else if ( prop.type == MaterialProperty.PropType.Vector && m_parent.template != null ) {
                var _type = FindShaderPropertyType( m_parent.template.shader, prop.name );
                if ( _type != null && _type.Value == ShaderUtil.ShaderPropertyType.Vector ) {
                    var defaultVector = m_parent.template.GetVector( prop.name );
                    var v = newVectorValue != null ? newVectorValue.Value : prop.vectorValue;
                    v.x = _RoundFloat( v.x, defaultVector.x );
                    v.y = _RoundFloat( v.y, defaultVector.y );
                    v.z = _RoundFloat( v.z, defaultVector.z );
                    v.w = _RoundFloat( v.w, defaultVector.w );
                    if ( prop.vectorValue != v ) {
                        prop.vectorValue = v;
                        return true;
                    }
                }
            }
            return false;
        }

        protected virtual void OnDrawGUI() {
            var label = m_label ?? m_prop.displayName;
            float h = m_MaterialEditor.GetPropertyHeight( m_prop, label );
            Rect r = EditorGUILayout.GetControlRect( true, h, EditorStyles.layerMaskField );
            for (; ; ) {
                if ( m_guiType == Cfg.Value_PropGUIType_Toggle && ( m_prop.type == MaterialProperty.PropType.Float || m_prop.type == MaterialProperty.PropType.Range ) ) {
                    var _floatValue = EditorGUI.Toggle( r, label, m_prop.floatValue > 0 ) ? 1 : 0;
                    if ( _floatValue != m_prop.floatValue ) {
                        m_prop.floatValue = _floatValue;
                    }
                    break;
                }
                if ( m_guiType == Cfg.Value_PropGUIType_Rect && ( m_prop.type == MaterialProperty.PropType.Vector ) ) {
                    var v = m_prop.vectorValue;
                    var bounds = new Rect();
                    bounds.xMin = v.x;
                    bounds.xMax = v.y;
                    bounds.yMin = v.z;
                    bounds.yMax = v.w;
                    EditorGUI.LabelField( r, m_prop.displayName );
                    EditorGUI.indentLevel++;
                    bounds = EditorGUILayout.RectField( bounds );
                    EditorGUI.indentLevel--;
                    var _vectorValue = new Vector4( bounds.xMin, bounds.xMax, bounds.yMin, bounds.yMax );
                    if ( m_prop.vectorValue != _vectorValue ) {
                        m_prop.vectorValue = _vectorValue;
                    }
                    break;
                }
                if ( m_prop.type == MaterialProperty.PropType.Color ) {
                    var cindex = ColorGUITypeToComponentIndex( m_guiType );
                    if ( cindex >= 0 ) {
                        var precision = m_precision;
                        if ( precision <= 0 ) {
                            precision = DefaultPrecision_Color;
                        }
                        var c = m_prop.colorValue;
                        var defaultColorValue = m_parent.template.GetColor( m_prop.name );
                        var rangeLimits = new Vector2( 0, 1 );
                        if ( m_exRange != null && ( m_prop.flags & MaterialProperty.PropFlags.HDR ) != 0 ) {
                            rangeLimits = m_exRange.Value;
                        }
                        if ( m_mapRange != null ) {
                            double srcRange = rangeLimits.y - rangeLimits.x;
                            double dstRange = m_mapRange.Value.y - m_mapRange.Value.x;
                            double cur = ( m_prop.colorValue[ cindex ] - rangeLimits.x ) / srcRange;
                            cur = _Clamp01( cur );
                            cur = m_mapRange.Value.x + cur * dstRange;
                            double value = DrawRangeProperty( r, m_prop, ( float )cur, label, m_mapRange.Value.x, m_mapRange.Value.y, precision, defaultColorValue[ cindex ] );
                            cur = ( value - m_mapRange.Value.x ) / dstRange;
                            cur = _Clamp01( cur );
                            c[ cindex ] = ( float )( rangeLimits.x + cur * srcRange );
                        } else {
                            c[ cindex ] = DrawRangeProperty( r, m_prop, m_prop.colorValue[ cindex ], label, rangeLimits.x, rangeLimits.y, precision, defaultColorValue[ cindex ] );
                        }
                        if ( c != m_prop.colorValue ) {
                            m_prop.colorValue = c;
                        }
                        break;
                    }
                }
                // 使用默认编辑器
                var showMixedValue = EditorGUI.showMixedValue;
                EditorGUI.showMixedValue = true;
                try {
                    if ( ( m_prop.type == MaterialProperty.PropType.Range || m_prop.type == MaterialProperty.PropType.Float && m_exRange != null ) && m_mapRange != null ) {
                        float rangeLimitsMin = 0;
                        float rangeLimitsMax = 0;
                        if ( m_prop.type == MaterialProperty.PropType.Range ) {
                            rangeLimitsMin = m_prop.rangeLimits.x;
                            rangeLimitsMax = m_prop.rangeLimits.y;
                        }
                        if ( m_exRange != null ) {
                            rangeLimitsMin = m_exRange.Value.x;
                            rangeLimitsMax = m_exRange.Value.y;
                        }
                        double srcRange = rangeLimitsMax - rangeLimitsMin;
                        double dstRange = m_mapRange.Value.y - m_mapRange.Value.x;
                        double cur = ( m_prop.floatValue - rangeLimitsMin ) / srcRange;
                        cur = _Clamp01( cur );
                        cur = m_mapRange.Value.x + cur * dstRange;
                        double value = DrawRangeProperty( r, m_prop, ( float )cur, label, m_mapRange.Value.x, m_mapRange.Value.y, m_precision );
                        cur = ( value - m_mapRange.Value.x ) / dstRange;
                        cur = _Clamp01( cur );
                        var _cur = ( float )( rangeLimitsMin + cur * srcRange );
                        if ( m_prop.floatValue != _cur ) {
                            m_prop.floatValue = _cur;
                        }
                    } else if ( ( m_prop.type == MaterialProperty.PropType.Float || m_prop.type == MaterialProperty.PropType.Range ) && m_exRange != null ) {
                        var value = DrawRangeProperty( r, m_prop, m_prop.floatValue, label, m_exRange.Value.x, m_exRange.Value.y, m_precision );
                        if ( m_prop.floatValue != value ) {
                            m_prop.floatValue = value;
                        }
                    } else {
                        m_MaterialEditor.ShaderProperty( r, m_prop, label );
                    }
                } finally {
                    EditorGUI.showMixedValue = showMixedValue;
                }
                if ( m_precision >= 0 && m_prop.hasMixedValue == false ) {
                    var material = m_parent.materialEditor.target as Material;
                    FixPropertyPrecision( m_prop );
                }
                break;
            }
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            var modeMatch = ShaderGUIHelper.IsModeMatched( this, m_args );
            var boolTest = GetBoolTestResult( props );
            if ( ( modeMatch != null && modeMatch.Value == false ) || ( boolTest != null && boolTest.Value == false ) ) {
                // 至少有一个求值成功，判断是否需要重置属性
                if ( m_parent.template != null ) {
                    if ( m_hideReset != HideReset.None ) {
                        if ( m_dirty == null || m_dirty.Value == true ) {
                            m_dirty = false;
                            if ( m_hideReset == HideReset.Conditional ) {
                                var resetIf = TryGetBoolTestResult( props, Cfg.Key_ConditionalResetIf, true );
                                if ( resetIf == null || resetIf != null && resetIf.Value == false ) {
                                    // 跳过重置
                                    return;
                                }
                            }
                            OnResetToDefaultValue( m_parent.template );
                        }
                    }
                }
                return;
            }
            if ( modeMatch == null || boolTest == null || modeMatch.Value == false || boolTest.Value == false ) {
                return;
            }
            m_dirty = true;
            var gui_enabled = GUI.enabled;
            try {
                GUI.enabled = m_keep == null;
                if ( !GUI.enabled && ( m_prop.flags & MaterialProperty.PropFlags.HideInInspector ) != 0 ) {
                    return;
                }
                m_MaterialEditor.SetDefaultGUIWidths();
                OnDrawGUI();
            } finally {
                GUI.enabled = gui_enabled;
            }
            m_MaterialEditor.SetDefaultGUIWidths();
        }

        public override bool SerializeToJSON( JSONObject parent ) {
            return ShaderGUIHelper.SerializeToJSON( parent, m_prop, m_guiType );
        }

        public override bool DeserializeFromJSON( JSONObject parent ) {
            return ShaderGUIHelper.DeserializeFromJSON( parent, m_prop, m_guiType );
        }

        protected static double _Clamp01( double value ) {
            if ( value < 0 ) {
                return value;
            } else if ( value > 1 ) {
                return value;
            }
            return value;
        }

        protected static float _Clamp01( float value ) {
            if ( value < 0 ) {
                return value;
            } else if ( value > 1 ) {
                return value;
            }
            return value;
        }

        protected float _RoundFloat( float value, float defaultValue ) {
            return _RoundFloat( value, defaultValue, m_precision );
        }

        protected float _RoundRange( float value, Vector3 defaultRange ) {
            return _RoundRange( value, defaultRange, m_precision );
        }

        protected static float _RoundFloat( float value, float defaultValue, int precision ) {
            // 单值浮点，无取值取值范围设定，精度表示小数部分精度如：
            // precision = 2, 小数部分取值0.0, 0.5
            // precision = 4, 小数部分取值0.0, 0.25, 0.5, 0.75
            // 余下类推...
            return precision > 0 ? ( float )( Math.Round( ( value - defaultValue ) * precision ) ) / precision + defaultValue : value;
        }

        protected static float _RoundRange( float value, Vector3 defaultRange, int precision ) {
            if ( value <= defaultRange.y ) {
                return defaultRange.y;
            } else if ( value >= defaultRange.z ) {
                return defaultRange.z;
            }
            if ( precision > 0 ) {
                // 单位化范围，把取值范围规范到[0,1]
                // 精度值表示取值范围均分指定次数
                // 比如：当range = [0, 1], precision = 4, 有效取值为：0.0, 0.25, 0.5, 0.75, 1.0
                // 比如：当range = [0, 2], precision = 2, 有效取值为：0.0, 1.0, 2.0
                var scale = defaultRange.z - defaultRange.y;
                var _value = value / scale;
                var _defaultValue = defaultRange.x / scale;
                value = ( float )( Math.Round( ( _value - _defaultValue ) * precision ) ) / precision + _defaultValue;
                value *= scale;
                value = Mathf.Clamp( value, defaultRange.y, defaultRange.z );
            }
            return value;
        }

        protected static float _RoundRange01( float value, int precision ) {
            if ( value <= 0 ) { return 0; } else if ( value >= 1 ) { return 1; }
            return precision > 0 ? Mathf.Clamp01( ( float )( Math.Round( value * precision ) ) / precision ) : value;
        }

        protected static float _RoundColor( bool hdr, float value, Vector3 defaultRange, int precision ) {
            if ( !hdr ) {
                if ( value <= 0 ) {
                    return 0;
                } else if ( value >= 1 ) {
                    return 1;
                }
                if ( precision > 0 ) {
                    // 颜色值范围默认[0, 1]，不需要规范化处理
                    value = ( float )( Math.Round( ( value - defaultRange.x ) * precision ) ) / precision + defaultRange.x;
                    value = Mathf.Clamp( value, defaultRange.y, defaultRange.z );
                }
            } else {
                value = _RoundFloat( value, defaultRange.x, precision );
            }
            return value;
        }

        protected static float _RoundColor( float value, int precision = DefaultPrecision_Color ) {
            if ( value <= 0 ) { return 0; } else if ( value >= 1 ) { return 1; }
            return precision > 0 ? Mathf.Clamp01( ( float )( Math.Round( value * precision ) ) / precision ) : value;
        }

        static bool SetMaterialPropertyValue( MaterialProperty prop, object value ) {
            try {
                switch ( prop.type ) {
                case MaterialProperty.PropType.Color:
                    if ( value.GetType() == typeof( Color ) ) {
                        prop.colorValue = ( Color )value;
                    }  else if ( value.GetType() == typeof( Vector4 ) ) {
                        prop.colorValue = ( Vector4 )value;
                    }
                    break;
                case MaterialProperty.PropType.Float:
                case MaterialProperty.PropType.Range:
                    prop.floatValue = ( float )value;
                    break;
                case MaterialProperty.PropType.Texture:
                    prop.textureValue = ( Texture )value;
                    break;
                case MaterialProperty.PropType.Vector:
                    if ( value.GetType() == typeof( Color ) ) {
                        prop.vectorValue = ( Color )value;
                    } else if ( value.GetType() == typeof( Vector4 ) ) {
                        prop.vectorValue = ( Vector4 )value;
                    }
                    break;
                }
                return true;
            } catch ( Exception e ) {
                Debug.LogException( e );
            }
            return false;
        }

        public static bool CopyMaterialPropertyValue( MaterialProperty from, MaterialProperty to ) {
            if ( from != null && to != null && from != to && from.type == to.type ) {
                switch ( to.type ) {
                case MaterialProperty.PropType.Color:
                    to.colorValue = from.colorValue;
                    break;
                case MaterialProperty.PropType.Float:
                case MaterialProperty.PropType.Range:
                    to.floatValue = from.floatValue;
                    break;
                case MaterialProperty.PropType.Texture:
                    to.textureValue = from.textureValue;
                    to.textureScaleAndOffset = from.textureScaleAndOffset;
                    break;
                case MaterialProperty.PropType.Vector:
                    to.vectorValue = from.vectorValue;
                    break;
                }
                return true;
            }
            return false;
        }

        void ParsePrecision() {
            var forceNP2 = true;
            var _precision = m_args.GetField( Cfg.Key_Precision );
            if ( _precision == null ) {
                _precision = m_args.GetField( "grade" );
                forceNP2 = false;
            }
            if ( _precision != null ) {
                if ( _precision.IsNumber ) {
                    m_precision = ( int )_precision.i;
                } else if ( _precision.IsString ) {
                    switch ( _precision.str.ToLower() ) {
                    case Cfg.Value_Precision_Low:
                        m_precision = ( int )Precision.Low;
                        break;
                    case Cfg.Value_Precision_Half:
                        m_precision = ( int )Precision.Half;
                        break;
                    case Cfg.Value_Precision_High:
                        m_precision = ( int )Precision.High;
                        break;
                    }
                }
            }
            CheckPrecisionLevel( forceNP2 );
        }

        void CheckPrecisionLevel( bool forceNP2 = true ) {
            if ( m_prop == null ) {
                return;
            }
            var _precision = m_precision;
            if ( m_precision > 0 && forceNP2 ) {
                m_precision = Mathf.NextPowerOfTwo( m_precision );
            }
            var precision = m_precision;
            if ( m_prop.type == MaterialProperty.PropType.Color && m_mapRange == null && ( m_prop.flags & MaterialProperty.PropFlags.HDR ) == 0 ) {
                if ( precision > 0 ) {
                    precision = Mathf.Clamp( precision, 1, DefaultPrecision_Color );
                } else {
                    precision = DefaultPrecision_Color;
                }
                _precision = precision;
                m_precision = precision;
                if ( forceNP2 ) {
                    Debug.Assert( Mathf.IsPowerOfTwo( m_precision ) );
                }
            }
            if ( m_precision != _precision ) {
                Debug.LogWarningFormat( "fix {0}'s precision {1} -> {2}", m_prop.name, _precision, m_precision );
            }
        }

        void UpgradeProperty( MaterialProperty[] props ) {
            s_upgradeList.Clear();
            var curUpgradeSrcPropName = String.Empty;
            if ( m_args.HasField( Cfg.Key_UpgradeFrom ) ) {
                String upgradeSrcPropName;
                if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_UpgradeFrom, out upgradeSrcPropName ) &&
                    !String.IsNullOrEmpty( upgradeSrcPropName ) ) {
                    curUpgradeSrcPropName = upgradeSrcPropName;
                    s_upgradeList.Add( new KeyValuePair<String, String>( m_propName, upgradeSrcPropName ) );
                }
            }
            if ( s_autoUpgradeList != null ) {
                for ( int i = 0; i < s_autoUpgradeList.Length; ++i ) {
                    s_upgradeList.Add( s_autoUpgradeList[ i ] );
                }
            }
            for ( int i = 0; i < s_upgradeList.Count; ++i ) {
                if ( s_upgradeList[ i ].Key != m_propName ) {
                    continue;
                }
                var upgradeSrcPropName = s_upgradeList[ i ].Value;
                var upgradeSrcProp = FindProperty( upgradeSrcPropName, props, false );
                if ( upgradeSrcProp != null && upgradeSrcProp.type == m_prop.type ) {
                    CopyMaterialPropertyValue( upgradeSrcProp, m_prop );
                } else {
                    var srcOldValue = FindPropValueFromMaterial( this.materialEditor.target as Material, upgradeSrcPropName, m_prop.type );
                    if ( srcOldValue != null ) {
                        if ( SetMaterialPropertyValue( m_prop, srcOldValue ) ) {
                            Debug.LogWarningFormat( "Upgrade material property: '{0}' -> '{1}', value = {2} : {3}\nYou could 'Tidy' material asset to remove useless properties after all the upgrades are done.",
                                upgradeSrcPropName, m_prop.name, srcOldValue, m_prop.type );
                        }
                    } else {
                        if ( upgradeSrcPropName == curUpgradeSrcPropName ) {
                            // 当前编辑器定义了升级目标，但是没有找到需要报错警告
                            Debug.LogErrorFormat( "Upgrade source property '{0}' not found, type: ({1})", upgradeSrcPropName, m_prop.type );
                        }
                    }
                }
            }
        }

        void DoHeavyChecking() {
            if ( m_args != null && m_prop != null ) {
                if ( m_prop.type == MaterialProperty.PropType.Texture ) {
                    bool? isLinearTexture = null;
                    bool? isReadable = null;
                    TextureWrapMode? wrapMode = null;
                    if ( m_args.HasField( Cfg.ArgsKey_SingleProp_Texture_Linear ) ) {
                        bool value;
                        if ( m_args.GetField( out value, Cfg.ArgsKey_SingleProp_Texture_Linear, false ) ) {
                            isLinearTexture = value;
                        }
                    }
                    if ( m_args.HasField( Cfg.ArgsKey_SingleProp_Texture_WrapMode ) ) {
                        String value;
                        if ( m_args.GetField( out value, Cfg.ArgsKey_SingleProp_Texture_WrapMode, String.Empty ) && !String.IsNullOrEmpty( value ) ) {
                            TextureWrapMode mode;
                            if ( Enum.TryParse<TextureWrapMode>( value, true, out mode ) ) {
                                wrapMode = mode;
                            }
                        }
                    }
                    if ( m_args.HasField( Cfg.ArgsKey_SingleProp_Texture_Readable ) ) {
                        bool value;
                        if ( m_args.GetField( out value, Cfg.ArgsKey_SingleProp_Texture_Readable, false ) ) {
                            isReadable = value;
                        }
                    }
                    foreach ( var target in m_MaterialEditor.targets ) {
                        var m = target as Material;
                        if ( m != null ) {
                            var texture = m.GetTexture( m_prop.name );
                            if ( texture != null ) {
                                var assetPath = AssetDatabase.GetAssetPath( texture );
                                if ( !String.IsNullOrEmpty( assetPath ) ) {
                                    if ( ShaderGUIHelper.IsUnityDefaultResource( assetPath ) ) {
                                        Debug.LogErrorFormat( "Please do not use unity's builtin resource: {0}", texture.name );
                                    } else {
                                        if ( isLinearTexture != null || wrapMode != null ) {
                                            var ti = AssetImporter.GetAtPath( assetPath ) as TextureImporter;
                                            if ( ti != null ) {
                                                System.Text.StringBuilder sb = null;
                                                if ( isLinearTexture != null ) {
                                                    var _sRGBTexture = isLinearTexture.Value ? false : true;
                                                    if ( _sRGBTexture != ti.sRGBTexture ) {
                                                        ti.sRGBTexture = _sRGBTexture;
                                                        sb = sb ?? new System.Text.StringBuilder();
                                                        sb.AppendFormat( "sRGBTexture = {0}", ti.sRGBTexture ).AppendLine();
                                                    }
                                                }
                                                if ( wrapMode != null ) {
                                                    if ( ti.wrapMode != wrapMode.Value ) {
                                                        ti.wrapMode = wrapMode.Value;
                                                        sb = sb ?? new System.Text.StringBuilder();
                                                        sb.AppendFormat( "wrapMode = {0}", ti.wrapMode ).AppendLine();
                                                    }
                                                }
                                                if ( isReadable != null ) {
                                                    if ( ti.isReadable != isReadable.Value ) {
                                                        ti.isReadable = isReadable.Value;
                                                        sb = sb ?? new System.Text.StringBuilder();
                                                        sb.AppendFormat( "isReadable = {0}", ti.isReadable ).AppendLine();
                                                    }
                                                } else if ( ti.isReadable ) {
                                                    Debug.LogErrorFormat( "Can't use read/write texture: {0}", texture.name );
                                                    ti.isReadable = false;
                                                    sb.AppendFormat( "isReadable = {0}", ti.isReadable ).AppendLine();
                                                }
                                                if ( sb != null ) {
                                                    ti.SaveAndReimport();
                                                    Debug.LogErrorFormat( "Fixing texture import settings: {0}\n{1}", texture.name, sb.ToString() );
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            var _oldProp = m_prop;
            m_prop = FindCachedProperty( m_propName, props );
            m_keep = null;
            if ( m_prop != null && m_args != null ) {
                ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_GUILabel, out m_label );
                m_label = String.IsNullOrEmpty( m_label ) ? null : m_label;
                if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_PropGUIType, out m_guiType ) ) {
                    m_guiType = m_guiType.ToLower();
                }
                if ( m_args.HasField( Cfg.Key_ConditionalResetIf ) ) {
                    m_hideReset = HideReset.Conditional;
                } else {
                    bool autoReset;
                    if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_AutoReset, out autoReset ) ) {
                        m_hideReset = autoReset ? HideReset.Auto : HideReset.None;
                    } else {
                        m_hideReset = HideReset.Auto;
                    }
                }
                if ( m_args.HasField( Cfg.Key_MapRange ) ) {
                    Vector4 mapRange;
                    int mask;
                    if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_MapRange, out mapRange, out mask ) && mask == 3 ) {
                        var min = Math.Min( mapRange.x, mapRange.y );
                        var max = Math.Max( mapRange.x, mapRange.y );
                        if ( Math.Abs( max - min ) > 0.0001f ) {
                            m_mapRange = new Vector2( min, max );
                        } else {
                            Debug.LogWarningFormat( "remap '{0}' to [{1},{2}] is too small!", m_propName, min, max );
                        }
                    }
                }
                if ( m_args.HasField( Cfg.Key_Range ) ) {
                    Vector4 exRange;
                    int mask;
                    if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_Range, out exRange, out mask ) && mask == 3 ) {
                        var min = Math.Min( exRange.x, exRange.y );
                        var max = Math.Max( exRange.x, exRange.y );
                        if ( Math.Abs( max - min ) > 0.0001f ) {
                            m_exRange = new Vector2( min, max );
                        } else {
                            Debug.LogWarningFormat( "range '{0}' to [{1},{2}] is too small!", m_propName, min, max );
                        }
                    }
                }
                ParsePrecision();
                if ( _oldProp == null ) {
                    // 第一次初始化才进行属性升级操作，没必要每次都进行升级检查
                    try {
                        UpgradeProperty( props );
                        DoHeavyChecking();
                    } catch ( Exception e ) {
                        Debug.LogException( e );
                    }
                }
                while ( m_args.HasField( Cfg.Key_FixedValue ) ) {
                    // 初始固定值处理，可以支持多选
                    var material = this.materialEditor.target as Material;
                    var enable_if = TryGetBoolTestResult( props, Cfg.Key_FixedIf, true );
                    if ( enable_if == null || enable_if != null && enable_if.Value == false ) {
                        break;
                    }
                    // 设置为一个无用非空但无法编辑的标志
                    m_keep = this;
                    // 用户设置了固定值，读取默认值和取值范围，精度矫正
                    switch ( m_prop.type ) {
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range: {
                            float val;
                            if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out val ) ) {
                                if ( FixPropertyPrecision( m_prop, newFloatValue: val ) ) {
                                    // 如果用户设置的固定值经过精度矫正后，如果出现了偏差，提示用户重新选择新值
                                    Debug.AssertFormat( m_prop.floatValue == val, "{0} = {1}/[{2}]", m_prop.name, m_prop.floatValue, val );
                                    m_keep = m_prop.floatValue;
                                }
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Color: {
                            Vector4 _val;
                            int mask;
                            // 读取用户设置的向量值，只设置有效分量
                            if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out _val, out mask ) ) {
                                var val = m_prop.colorValue;
                                ShaderGUIHelper.MixColorValue( ref val, ( Color )_val, mask );
                                if ( FixPropertyPrecision( m_prop, newColorValue: val ) ) {
                                    Debug.AssertFormat( m_prop.colorValue == val, "{0} = {1}/[{2}]", m_prop.name, m_prop.colorValue, val );
                                    m_keep = m_prop.colorValue;
                                }
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Vector: {
                            Vector4 _val;
                            int mask;
                            if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out _val, out mask ) ) {
                                var val = m_prop.vectorValue;
                                ShaderGUIHelper.MixVectorValue( ref val, _val, mask );
                                if ( FixPropertyPrecision( m_prop, newVectorValue: val ) ) {
                                    Debug.AssertFormat( m_prop.vectorValue == val, "{0} = {1}/[{2}]", m_prop.name, m_prop.vectorValue, val );
                                    m_keep = m_prop.vectorValue;
                                }
                            }
                        }
                        break;
                    case MaterialProperty.PropType.Texture: {
                            String val;
                            if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out val ) ) {
                                if ( !m_prop.hasMixedValue ) {
                                    var tex = AssetDatabase.LoadAssetAtPath<Texture>( val );
                                    if ( tex != null ) {
                                        m_prop.textureValue = tex;
                                        m_keep = tex;
                                    } else {
                                        m_prop.textureValue = null;
                                    }
                                }
                            }
                        }
                        break;
                    default:
                        m_keep = null;
                        break;
                    }
                    break;
                }
            }
            if ( m_prop == null ) {
                var mat = this.materialEditor.target as Material;
                if ( mat != null && mat.shader != null ) {
                    Debug.LogErrorFormat( "Find Shader Property failed: {0}.{1}. \n{2}",
                        mat.shader.name, m_propName, AssetDatabase.GetAssetPath( mat ) );
                }
            }
            return m_prop != null;
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            var ret = new ShaderGUI_SingleProp();
            ret.m_propName = s.name;
            return ret;
        }
    }
}
