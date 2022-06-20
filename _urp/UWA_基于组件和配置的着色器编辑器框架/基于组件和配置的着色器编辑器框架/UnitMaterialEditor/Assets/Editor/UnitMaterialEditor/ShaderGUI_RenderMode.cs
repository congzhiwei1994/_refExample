using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public class ShaderGUI_RenderMode : UnitMaterialEditor {

        protected MaterialProperty m_prop_Mode = null;
        protected MaterialProperty m_prop_BlendOp = null;
        protected MaterialProperty m_prop_SrcBlend = null;
        protected MaterialProperty m_prop_DstBlend = null;
        protected MaterialProperty m_prop_ZWrite = null;
        protected MaterialProperty m_prop_ZTest = null;
        protected MaterialProperty m_prop_AlphaPremultiply = null;
        protected MaterialProperty m_prop_AutoRenderQueue = null;

        protected MaterialProperty m_prop_MainTex_Alpha = null;
        protected MaterialProperty m_prop_Cutoff = null;
        protected MaterialProperty m_prop_ColorKey = null;
        protected MaterialProperty m_prop_FogColorSelector = null;

        protected String[] m_optionNames = null;
        protected int[] m_optionValues = null;
        protected RenderMode? m_keep = null;
        protected RenderMode? m_shotcutForCustomMode = null;

        protected static bool _showDetail = false;

        public String[] options {
            get {
                return m_optionNames;
            }
        }

        public int[] optionValues {
            get {
                return m_optionValues;
            }
        }

        public RenderMode? fixedMode {
            get {
                if ( m_keep != null ) {
                    return m_keep.Value;
                }
                return null;
            }
        }

        public RenderMode _Mode {
            get {
                if ( m_prop_Mode != null && m_prop_Mode.type == MaterialProperty.PropType.Float ) {
                    return ( RenderMode )m_prop_Mode.floatValue;
                }
                return RenderMode.Opaque;
            }
            set {
                if ( m_prop_Mode != null && m_prop_Mode.type == MaterialProperty.PropType.Float ) {
                    m_prop_Mode.floatValue = ( float )value;
                }
            }
        }

        public MaterialProperty _PropMode {
            get {
                return m_prop_Mode;
            }
        }

        public bool _AutoRenderQueue {
            get {
                if ( m_prop_AutoRenderQueue != null && m_prop_AutoRenderQueue.type == MaterialProperty.PropType.Float ) {
                    return m_prop_AutoRenderQueue.floatValue != 0;
                }
                return false;
            }
            set {
                if ( m_prop_AutoRenderQueue != null && m_prop_AutoRenderQueue.type == MaterialProperty.PropType.Float ) {
                    m_prop_AutoRenderQueue.floatValue = value ? 1 : 0;
                }
            }
        }

        public bool _AlphaPremultiply {
            get {
                if ( m_prop_AlphaPremultiply != null && m_prop_AlphaPremultiply.type == MaterialProperty.PropType.Float ) {
                    return m_prop_AlphaPremultiply.floatValue != 0;
                }
                return false;
            }
            set {
                if ( m_prop_AlphaPremultiply != null && m_prop_AlphaPremultiply.type == MaterialProperty.PropType.Float ) {
                    m_prop_AlphaPremultiply.floatValue = value ? 1 : 0;
                }
            }
        }

        public float _FogColorSelector {
            get {
                if ( m_prop_FogColorSelector != null ) {
                    return m_prop_FogColorSelector.floatValue > 0 ? 1 : 0;
                }
                return 0;
            }
            set {
                if ( m_prop_FogColorSelector != null ) {
                    m_prop_FogColorSelector.floatValue = value > 0 ? 1 : 0;
                }
            }
        }

        public BlendOp _BlendOp {
            get {
                if ( m_prop_BlendOp != null && m_prop_BlendOp.type == MaterialProperty.PropType.Float ) {
                    return ( BlendOp )m_prop_BlendOp.floatValue;
                }
                return BlendOp.Add;
            }
            set {
                if ( m_prop_BlendOp != null && m_prop_BlendOp.type == MaterialProperty.PropType.Float ) {
                    m_prop_BlendOp.floatValue = ( float )value;
                }
            }
        }

        public BlendMode _SrcBlend {
            get {
                if ( m_prop_SrcBlend != null && m_prop_SrcBlend.type == MaterialProperty.PropType.Float ) {
                    return ( BlendMode )m_prop_SrcBlend.floatValue;
                }
                return BlendMode.One;
            }
            set {
                if ( m_prop_SrcBlend != null && m_prop_SrcBlend.type == MaterialProperty.PropType.Float ) {
                    m_prop_SrcBlend.floatValue = ( float )value;
                }
            }
        }

        public BlendMode _DstBlend {
            get {
                if ( m_prop_DstBlend != null && m_prop_DstBlend.type == MaterialProperty.PropType.Float ) {
                    return ( BlendMode )m_prop_DstBlend.floatValue;
                }
                return BlendMode.Zero;
            }
            set {
                if ( m_prop_DstBlend != null && m_prop_DstBlend.type == MaterialProperty.PropType.Float ) {
                    m_prop_DstBlend.floatValue = ( float )value;
                }
            }
        }

        public float _Cutoff {
            get {
                if ( m_prop_Cutoff != null && ( m_prop_Cutoff.type == MaterialProperty.PropType.Float || m_prop_Cutoff.type == MaterialProperty.PropType.Range ) ) {
                    return m_prop_Cutoff.floatValue;
                }
                return 0;
            }
            set {
                if ( m_prop_Cutoff != null && ( m_prop_Cutoff.type == MaterialProperty.PropType.Float || m_prop_Cutoff.type == MaterialProperty.PropType.Range ) ) {
                    m_prop_Cutoff.floatValue = Mathf.Clamp01( value );
                }
            }
        }

        public Color _ColorKey {
            get {
                if ( m_prop_ColorKey != null && ( m_prop_ColorKey.type == MaterialProperty.PropType.Color ) ) {
                    return m_prop_ColorKey.colorValue;
                }
                return Color.black;
            }
            set {
                if ( m_prop_ColorKey != null && ( m_prop_ColorKey.type == MaterialProperty.PropType.Color ) ) {
                    m_prop_ColorKey.colorValue = value;
                }
            }
        }

        public bool _ZWrite {
            get {
                if ( m_prop_ZWrite != null && m_prop_ZWrite.type == MaterialProperty.PropType.Float ) {
                    return m_prop_ZWrite.floatValue != 0;
                }
                return true;
            }
            set {
                if ( m_prop_ZWrite != null && m_prop_ZWrite.type == MaterialProperty.PropType.Float ) {
                    m_prop_ZWrite.floatValue = value ? 1 : 0;
                }
            }
        }

        public bool _ZTest {
            get {
                if ( m_prop_ZTest != null && m_prop_ZTest.type == MaterialProperty.PropType.Float ) {
                    return m_prop_ZTest.floatValue != 0;
                }
                return true;
            }
            set {
                if ( m_prop_ZTest != null && m_prop_ZTest.type == MaterialProperty.PropType.Float ) {
                    m_prop_ZTest.floatValue = value ? 1 : 0;
                }
            }
        }

        public bool useAlpha {
            get {
                return RenderModeNeedsAlpha( _Mode );
            }
        }

        protected override bool OnInitProperties( MaterialProperty[] props ) {
            var _prop_Mode = FindCachedProperty( "_Mode", props, false );
            if ( _prop_Mode == null ) {
                _prop_Mode = FindCachedProperty( "_RenderMode", props );
            }
            if ( _prop_Mode != null ) {
                if ( m_shotcutForCustomMode == null ) {
                    m_shotcutForCustomMode = _Mode;
                }
                var _prop_BlendOp = FindCachedProperty( "_BlendOp", props );
                var _prop_SrcBlend = FindCachedProperty( "_SrcBlend", props );
                var _prop_DstBlend = FindCachedProperty( "_DstBlend", props );
                var _prop_ZWrite = FindCachedProperty( "_ZWrite", props );
                var _prop_ZTest = FindCachedProperty( "_ZTest", props );
                if ( _prop_SrcBlend != null && _prop_DstBlend != null && _prop_ZWrite != null && _prop_ZTest != null ) {
                    m_prop_Mode = _prop_Mode;
                    m_prop_BlendOp = _prop_BlendOp;
                    m_prop_SrcBlend = _prop_SrcBlend;
                    m_prop_DstBlend = _prop_DstBlend;
                    m_prop_ZWrite = _prop_ZWrite;
                    m_prop_ZTest = _prop_ZTest;
                    m_prop_AlphaPremultiply = FindCachedProperty( "_AlphaPremultiply", props, false );
                    m_prop_AutoRenderQueue = FindCachedProperty( "_AutoRenderQueue", props, false );
                    m_prop_FogColorSelector = FindCachedProperty( "_FogColorSelector", props, false );

                    m_prop_Cutoff = FindCachedProperty( "_Cutoff", props, false );
                    m_prop_ColorKey = FindCachedProperty( "_ColorKey", props, false );
                    m_prop_MainTex_Alpha = FindCachedProperty( "_MainTex_Alpha", props, false );

                    ParseOptions();
                    if ( m_shotcutForCustomMode == null && !m_prop_Mode.hasMixedValue ) {
                        if ( m_keep.HasValue && m_keep.Value != RenderMode.Custom ) {
                            m_shotcutForCustomMode = m_keep.Value;
                        } else {
                            m_shotcutForCustomMode = _Mode;
                        }
                    }
                    return true;
                }
            }
            return false;
        }

        protected void ParseOptions() {
            var enames = Enum.GetNames( typeof( RenderMode ) );
            var evals = Enum.GetValues( typeof( RenderMode ) );
            var options = new List<KeyValuePair<String, int>>();
            if ( m_args != null ) {
                var _options = m_args.GetField( Cfg.ArgsKey_Options );
                if ( _options != null && _options.IsString && !String.IsNullOrEmpty( _options.str ) ) {
                    var seps = _options.str.Split( ',', ';', '|' );
                    for ( int i = 0; i < seps.Length; ++i ) {
                        var key = seps[ i ].Trim();
                        var index = Array.IndexOf( enames, key );
                        if ( index >= 0 ) {
                            options.Add( new KeyValuePair<String, int>( enames[ index ], ( int )evals.GetValue( index ) ) );
                        }
                    }
                }
            }
            if ( options.Count > 0 ) {
                if ( options.FindIndex( e => e.Value == ( int )RenderMode.Custom ) < 0 ) {
                    options.Add( new KeyValuePair<String, int>( RenderMode.Custom.ToString(), ( int )RenderMode.Custom ) );
                }
                m_optionNames = new string[ options.Count ];
                m_optionValues = new int[ options.Count ];
                for ( int i = 0; i < options.Count; ++i ) {
                    m_optionNames[ i ] = options[ i ].Key;
                    m_optionValues[ i ] = options[ i ].Value;
                }
            } else {
                m_optionNames = enames;
                m_optionValues = new int[ m_optionNames.Length ];
                for ( int i = 0; i < m_optionNames.Length; ++i ) {
                    m_optionValues[ i ] = ( int )evals.GetValue( i );
                }
            }
            for (; !m_prop_Mode.hasMixedValue; ) {
                if ( m_args != null ) {
                    // 固定选项
                    String keepOption;
                    if ( ShaderGUIHelper.ParseValue( this, m_args, Cfg.Key_FixedValue, out keepOption ) ) {
                        var index = Array.IndexOf( m_optionNames, keepOption );
                        if ( index >= 0 ) {
                            m_keep = ( RenderMode )m_optionValues[ index ];
                            if ( _Mode == RenderMode.Custom ) {
                                break;
                            }
                            _Mode = m_keep.Value;
                            foreach ( var mat in this.m_MaterialEditor.targets ) {
                                SetupMaterialWithRenderingMode( mat as Material, true, false );
                            }
                            break;
                        }
                    }
                }
                if ( Array.IndexOf( m_optionValues, ( int )_Mode ) < 0 ) {
                    // 修正选项
                    _Mode = ( RenderMode )m_optionValues[ 0 ];
                }
                // 修正渲染模式参数
                foreach ( var mat in this.m_MaterialEditor.targets ) {
                    SetupMaterialWithRenderingMode( mat as Material, true, false );
                }
                break;
            }
        }

        static bool RenderModeNeedsAlpha( RenderMode mode ) {
            return mode == RenderMode.Cutout ||
                    mode == RenderMode.Transparent;
        }

        static bool IsTransparentMode( RenderMode mode ) {
            return mode == RenderMode.Additive ||
                mode == RenderMode.Transparent;
        }

        bool SetMaterialKeywords() {
            if ( m_prop_Mode == null || m_prop_Mode.hasMixedValue ) {
                return false;
            }
            var ret = true;
            var mode = _Mode;
            var cutoff = false;
            var materials = targets;
            switch ( mode ) {
            case RenderMode.Cutout: {
                    var alphaTest = m_prop_Cutoff != null;
                    if ( m_prop_Cutoff != null && m_prop_Cutoff.floatValue == 0 ) {
                        if ( m_prop_Cutoff.type == MaterialProperty.PropType.Range ) {
                            if ( m_prop_Cutoff.floatValue != m_prop_Cutoff.rangeLimits.x ) {
                                m_prop_Cutoff.floatValue = m_prop_Cutoff.rangeLimits.x;
                            }
                        }
                    }
                    cutoff = alphaTest;
                    if ( alphaTest ) {
                        SetKeyword( materials, "_ALPHATEST_ON", true );
                    } else {
                        SetKeyword( materials, "_ALPHATEST_ON", false );
                    }
                    SetKeyword( materials, "_ALPHATEST_COLOR_KEY_ON", false );
                    SetKeyword( materials, "_ALPHABLEND_ON", false );
                }
                break;
            case RenderMode.ColorKey: {
                    cutoff = m_prop_ColorKey != null;
                    SetKeyword( materials, "_ALPHATEST_COLOR_KEY_ON", cutoff );
                    SetKeyword( materials, "_ALPHATEST_ON", false );
                    SetKeyword( materials, "_ALPHABLEND_ON", false );
                }
                break;
            case RenderMode.Additive:
                SetKeyword( materials, "_ALPHABLEND_ON", false );
                break;
            case RenderMode.Transparent:
                SetKeyword( materials, "_ALPHABLEND_ON", true );
                break;
            case RenderMode.Custom:
                break;
            default:
                cutoff = false;
                SetKeyword( materials, "_ALPHATEST_COLOR_KEY_ON", false );
                SetKeyword( materials, "_ALPHATEST_ON", false );
                SetKeyword( materials, "_ALPHABLEND_ON", false );
                break;
            }
            if ( !cutoff && ( mode == RenderMode.Cutout || mode == RenderMode.ColorKey ) ) {
                _Mode = RenderMode.Opaque;
                SetKeyword( materials, "_ALPHATEST_COLOR_KEY_ON", false );
                SetKeyword( materials, "_ALPHATEST_ON", false );
                SetKeyword( materials, "_ALPHABLEND_ON", false );
                ret = false;
            }
            var hasAlphaTex = useAlpha && m_prop_MainTex_Alpha != null ? m_prop_MainTex_Alpha.textureValue : null;
            SetKeyword( materials, "_USE_EXTERNAL_ALPHA", hasAlphaTex != null );
            if ( hasAlphaTex == null && m_prop_MainTex_Alpha != null ) {
                m_prop_MainTex_Alpha.textureValue = null;
            }
            SetKeyword( materials, "_MODE_OPAQUE", _Mode == RenderMode.Opaque );
            SetKeyword( materials, "_MODE_COLORKEY", _Mode == RenderMode.ColorKey );
            SetKeyword( materials, "_MODE_CUSTOM", _Mode == RenderMode.Custom );
            SetKeyword( materials, "_MODE_CUTOUT", _Mode == RenderMode.Cutout );
            SetKeyword( materials, "_MODE_TRANSPARENT", _Mode == RenderMode.Transparent );
            SetKeyword( materials, "_MODE_ADDITIVE", _Mode == RenderMode.Additive );
            SetKeyword( materials, "_MODE_SOFTADDITIVE", _Mode == RenderMode.SoftAdditive );
            if ( _Mode == RenderMode.SoftAdditive || _Mode == RenderMode.Additive ) {
                SetKeyword( materials, "_BLEND_ADDITIVE_SERIES", true );
                // 颜色叠加模式，注意去掉目标雾的颜色，避免两次叠加
                _FogColorSelector = 0;
            } else {
                SetKeyword( materials, "_BLEND_ADDITIVE_SERIES", false );
                _FogColorSelector = 1;
            }
            return ret;
        }

        protected static RenderQueue? ConvertToRenderQueueFromSortValue( int renderQueue ) {
            var values = UnitMaterialEditor.RenderQueueValues;
            for ( int i = values.Length - 1; i >= 0; --i ) {
                if ( renderQueue >= values[ i ] ) {
                    return ( RenderQueue )values[ i ];
                }
            }
            return null;
        }

        protected static Vector2Int GetRenderQueueRange( RenderQueue queue ) {
            var values = UnitMaterialEditor.RenderQueueValues;
            var index = Array.IndexOf( values, queue );
            Debug.Assert( index >= 0 );
            const int QueueRangeSize = 1000;
            int lowerBound = index > 0 ? ( ( values[ index ] + values[ index - 1 ] ) / 2 ) : values[ 0 ] - QueueRangeSize;
            int upperBound = index < values.Length - 1 ? ( ( values[ index ] + values[ index + 1 ] ) / 2 ) : values[ values.Length - 1 ] + QueueRangeSize;
            return new Vector2Int( lowerBound, upperBound );
        }

        /// <summary>
        /// 找到距离给定渲染排序值最近的枚举值
        /// </summary>
        /// <param name="renderQueue"></param>
        /// <returns></returns>
        protected static RenderQueue FindNearestRenderQueueFromSortValue( int renderQueue ) {
            var curIndex = -1;
            var curDistance = int.MaxValue;
            var values = UnitMaterialEditor.RenderQueueValues;
            for ( int i = values.Length - 1; i >= 0; --i ) {
                var dis = Mathf.Abs( renderQueue - values[ i ] );
                if ( dis == 0 ) {
                    // 完全匹配
                    return ( RenderQueue )values[ i ];
                } else {
                    if ( dis < curDistance ) {
                        curIndex = i;
                        curDistance = dis;
                    }
                }
            }
            Debug.Assert( curIndex != -1 );
            return ( RenderQueue )values[ curIndex ];
        }

        protected static void SetAutoRenderQueue( Material material, RenderMode renderingMode, bool fixRenderQueueStrict ) {
            if ( fixRenderQueueStrict ) {
                switch ( renderingMode ) {
                case RenderMode.Opaque:
                    material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Geometry;
                    break;
                case RenderMode.Cutout:
                case RenderMode.ColorKey:
                    material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case RenderMode.Transparent:
                case RenderMode.SoftAdditive:
                case RenderMode.Additive:
                    material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                }
            } else {
                if ( material.renderQueue < 0 ) {
                    // 根据当前渲染混合模式初始化正确的排序值
                    SetAutoRenderQueue( material, renderingMode, true );
                }
                Debug.Assert( material.renderQueue >= 0 );
                var nearstRenderQueue = FindNearestRenderQueueFromSortValue( material.renderQueue );
                if ( nearstRenderQueue == RenderQueue.Overlay || nearstRenderQueue == RenderQueue.Background ) {
                    // 用户通过面板设置了不在当前支持的混合模式的排序区间
                    return;
                }
                // 当前所属的渲染队列和当先混合模式不匹配，需要重置
                var queueMatched = true;
                switch ( nearstRenderQueue ) {
                case RenderQueue.Geometry:
                case RenderQueue.GeometryLast:
                    queueMatched = renderingMode == RenderMode.Opaque;
                    break;
                case RenderQueue.AlphaTest:
                    queueMatched = renderingMode == RenderMode.ColorKey || renderingMode == RenderMode.Cutout;
                    break;
                case RenderQueue.Transparent:
                    queueMatched = renderingMode == RenderMode.Transparent || renderingMode == RenderMode.SoftAdditive || renderingMode == RenderMode.Additive;
                    break;
                }
                var range = GetRenderQueueRange( nearstRenderQueue );
                if ( !queueMatched || material.renderQueue < range.x || material.renderQueue > range.y ) {
                    // 超界，重置渲染排序队列值
                    var oldQueue = material.renderQueue;
                    SetAutoRenderQueue( material, renderingMode, true );
                    Debug.LogWarningFormat( "Fix RenderQueue {0}:{1} => {2}, RenderMode = {3}", nearstRenderQueue, oldQueue, material.renderQueue, renderingMode );
                }
            }
        }

        struct RenderingModeOptions {
            internal RenderMode mode;
            internal BlendOp blendOp;
            internal BlendMode srcBlend;
            internal BlendMode dstBlend;
            internal bool zwrite;
            internal int renderQueue;
            internal static RenderingModeOptions GetPreset( RenderMode mode, ShaderGUI_RenderMode editor ) {
                switch ( mode ) {
                case RenderMode.Opaque:
                    return new RenderingModeOptions {
                        mode = RenderMode.Opaque,
                        blendOp = BlendOp.Add,
                        srcBlend = BlendMode.One,
                        dstBlend = BlendMode.Zero,
                        zwrite = true,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Geometry
                    };
                case RenderMode.Cutout:
                    return new RenderingModeOptions {
                        mode = RenderMode.Cutout,
                        blendOp = BlendOp.Add,
                        srcBlend = BlendMode.One,
                        dstBlend = BlendMode.Zero,
                        zwrite = true,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.AlphaTest
                    };
                case RenderMode.ColorKey:
                    return new RenderingModeOptions {
                        mode = RenderMode.ColorKey,
                        blendOp = BlendOp.Add,
                        srcBlend = BlendMode.One,
                        dstBlend = BlendMode.Zero,
                        zwrite = true,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.AlphaTest
                    };
                case RenderMode.Transparent:
                    return new RenderingModeOptions {
                        mode = RenderMode.Transparent,
                        blendOp = BlendOp.Add,
                        srcBlend = editor._AlphaPremultiply ? BlendMode.One : BlendMode.SrcAlpha,
                        dstBlend = BlendMode.OneMinusSrcAlpha,
                        zwrite = false,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent
                };
                case RenderMode.Additive:
                    return new RenderingModeOptions {
                        mode = RenderMode.Additive,
                        blendOp = BlendOp.Add,
                        srcBlend = editor._AlphaPremultiply ? BlendMode.One : BlendMode.SrcAlpha,
                        dstBlend = BlendMode.One,
                        zwrite = false,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent
                    };
                case RenderMode.SoftAdditive:
                    return new RenderingModeOptions {
                        mode = RenderMode.SoftAdditive,
                        blendOp = BlendOp.Add,
                        srcBlend = BlendMode.OneMinusDstColor,
                        dstBlend = BlendMode.One,
                        zwrite = false,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent
                    };
                default:
                    return new RenderingModeOptions {
                        mode = RenderMode.Custom,
                        blendOp = BlendOp.Add,
                        srcBlend = BlendMode.One,
                        dstBlend = BlendMode.Zero,
                        zwrite = true,
                        renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Geometry
                    };
                }
            }
        }

        protected virtual void SetupMaterialWithRenderingMode( Material material, bool modeChanged = true, bool fixRenderQueueStrict = true ) {
            var ok = false;
            while ( !ok ) {
                switch ( _Mode ) {
                case RenderMode.Opaque:
                    material.SetOverrideTag( "RenderType", "Opaque" );
                    _Mode = RenderMode.Opaque;
                    _BlendOp = BlendOp.Add;
                    _SrcBlend = BlendMode.One;
                    _DstBlend = BlendMode.Zero;
                    _ZWrite = true;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = -1;
                    }
                    SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.Cutout:
                    material.SetOverrideTag( "RenderType", "TransparentCutout" );
                    _Mode = RenderMode.Cutout;
                    _BlendOp = BlendOp.Add;
                    _SrcBlend = BlendMode.One;
                    _DstBlend = BlendMode.Zero;
                    _ZWrite = true;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.AlphaTest;
                    }
                    SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.ColorKey:
                    material.SetOverrideTag( "RenderType", "TransparentCutout" );
                    _Mode = RenderMode.ColorKey;
                    _BlendOp = BlendOp.Add;
                    _SrcBlend = BlendMode.One;
                    _DstBlend = BlendMode.Zero;
                    _ZWrite = true;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.AlphaTest;
                    }
                    SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.Transparent:
                    _Mode = RenderMode.Transparent;
                    material.SetOverrideTag( "RenderType", "Transparent" );
                    _BlendOp = BlendOp.Add;
                    if ( _AlphaPremultiply ) {
                        _SrcBlend = BlendMode.One;
                        SetKeyword( material, "_ALPHAPREMULTIPLY_ON", true );
                    } else {
                        _SrcBlend = BlendMode.SrcAlpha;
                        SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    }
                    _DstBlend = BlendMode.OneMinusSrcAlpha;
                    _ZWrite = false;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent;
                    }
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.Additive:
                    _Mode = RenderMode.Additive;
                    material.SetOverrideTag( "RenderType", "Transparent" );
                    _BlendOp = BlendOp.Add;
                    if ( _AlphaPremultiply ) {
                        _SrcBlend = BlendMode.One;
                        SetKeyword( material, "_ALPHAPREMULTIPLY_ON", true );
                    } else {
                        _SrcBlend = BlendMode.SrcAlpha;
                        SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    }
                    _DstBlend = BlendMode.One;
                    _ZWrite = false;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent;
                    }
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.SoftAdditive:
                    material.SetOverrideTag( "RenderType", "Transparent" );
                    _Mode = RenderMode.SoftAdditive;
                    _BlendOp = BlendOp.Add;
                    _SrcBlend = BlendMode.OneMinusDstColor;
                    _DstBlend = BlendMode.One;
                    _ZWrite = false;
                    if ( _AutoRenderQueue ) {
                        material.renderQueue = ( int )UnityEngine.Rendering.RenderQueue.Transparent;
                    }
                    SetKeyword( material, "_ALPHAPREMULTIPLY_ON", false );
                    ok = SetMaterialKeywords();
                    break;
                case RenderMode.Custom:
                    if ( modeChanged ) {
                        _AutoRenderQueue = false;
                    }
                    _Mode = RenderMode.Custom;
                    SetMaterialKeywords();
                    ok = true;
                    break;
                default:
                    ok = true;
                    break;
                }
            }
            if ( modeChanged && _Mode != RenderMode.Custom ) {
                _AutoRenderQueue = true;
                SetAutoRenderQueue( material, _Mode, fixRenderQueueStrict );
            }
        }

        protected override void OnDrawPropertiesGUI( MaterialProperty[] props ) {
            if ( m_prop_Mode != null ) {
                var material = m_parent.materialEditor.target as Material;
                EditorGUI.showMixedValue = m_prop_Mode.hasMixedValue;
                var oldMode = ( RenderMode )m_prop_Mode.floatValue;
                var renderingMode = ( RenderMode )EditorGUILayout.IntPopup( "Render Mode", ( int )oldMode, m_optionNames, m_optionValues, GUILayout.MinWidth( 200 ) );
                if ( renderingMode != oldMode ) {
                    if ( renderingMode != RenderMode.Custom && m_keep.HasValue && m_keep.Value != renderingMode ) {
                        // 除自定义模式，其他选项被禁止
                        renderingMode = oldMode;
                    }
                }
                EditorGUI.BeginChangeCheck();
                EditorGUI.indentLevel++;
                if ( m_prop_AutoRenderQueue != null ) {
                    m_MaterialEditor.ShaderProperty( m_prop_AutoRenderQueue, m_prop_AutoRenderQueue.displayName );
                }
                if ( m_prop_AlphaPremultiply != null && IsTransparentMode( _Mode ) ) {
                    m_MaterialEditor.ShaderProperty( m_prop_AlphaPremultiply, m_prop_AlphaPremultiply.displayName );
                }
                if ( _Mode == RenderMode.Custom ) {
                    var guiColor = GUI.color;
                    RenderingModeOptions? defaultOptions = null;
                    if ( m_shotcutForCustomMode.HasValue ) {
                        defaultOptions = RenderingModeOptions.GetPreset( m_shotcutForCustomMode.Value, this );
                    }
                    GUI.enabled = false;
                    GUI.color = ( defaultOptions != null && defaultOptions.Value.renderQueue != material.renderQueue ) ? Color.yellow : guiColor;
                    EditorGUILayout.IntField( "RenderQueue", material.renderQueue );
                    GUI.enabled = true;
                    if ( m_prop_BlendOp != null ) {
                        GUI.color = ( defaultOptions != null && defaultOptions.Value.blendOp != _BlendOp ) ? Color.yellow : guiColor;
                        var a = ( BlendOp )EditorGUILayout.EnumPopup( m_prop_BlendOp.displayName, ( BlendOp )m_prop_BlendOp.floatValue );
                        m_prop_BlendOp.floatValue = ( float )a;
                    }
                    if ( m_prop_SrcBlend != null ) {
                        GUI.color = ( defaultOptions != null && defaultOptions.Value.srcBlend != _SrcBlend ) ? Color.yellow : guiColor;
                        var a = ( BlendMode )EditorGUILayout.EnumPopup( m_prop_SrcBlend.displayName, ( BlendMode )m_prop_SrcBlend.floatValue );
                        m_prop_SrcBlend.floatValue = ( float )a;
                    }
                    if ( m_prop_DstBlend != null ) {
                        GUI.color = ( defaultOptions != null && defaultOptions.Value.dstBlend != _DstBlend ) ? Color.yellow : guiColor;
                        var a = ( BlendMode )EditorGUILayout.EnumPopup( m_prop_DstBlend.displayName, ( BlendMode )m_prop_DstBlend.floatValue );
                        m_prop_DstBlend.floatValue = ( float )a;
                    }
                    if ( m_prop_ZWrite != null ) {
                        GUI.color = ( defaultOptions != null && defaultOptions.Value.zwrite != _ZWrite ) ? Color.yellow : guiColor;
                        m_prop_ZWrite.floatValue = EditorGUILayout.Toggle( m_prop_ZWrite.displayName, m_prop_ZWrite.floatValue > 0 ) ? 1 : 0;
                    }
                    if ( m_prop_ZTest != null ) {
                        GUI.color = ( _ZTest == false ) ? Color.yellow : guiColor;
                        var a = ( ZTest )EditorGUILayout.EnumPopup( m_prop_ZTest.displayName, ( ZTest )m_prop_ZTest.floatValue );
                        m_prop_ZTest.floatValue = ( float )a;
                    }
                    GUI.color = guiColor;
                }
                if ( EditorGUI.EndChangeCheck() || renderingMode != oldMode ) {
                    this.m_MaterialEditor.RegisterPropertyChangeUndo( m_prop_Mode.name );
                    this.m_prop_Mode.floatValue = ( float )renderingMode;
                    if ( _Mode != RenderMode.Custom ) {
                        this.m_shotcutForCustomMode = _Mode;
                    }
                    SetupMaterialWithRenderingMode( material, oldMode != renderingMode );
                }
                if ( _Mode == RenderMode.Custom && m_shotcutForCustomMode.HasValue ) {
                    EditorGUI.BeginChangeCheck();
                    var shotcutForCustomMode = ( RenderMode )EditorGUILayout.EnumPopup( "Preset", m_shotcutForCustomMode.Value );
                    if ( EditorGUI.EndChangeCheck() && shotcutForCustomMode != RenderMode.Custom ) {
                        m_shotcutForCustomMode = shotcutForCustomMode;
                        UnityEditor.EditorApplication.delayCall += () => {
                            if ( m_shotcutForCustomMode.HasValue ) {
                                _Mode = m_shotcutForCustomMode.Value;
                                SetupMaterialWithRenderingMode( this.m_MaterialEditor.target as Material, true, false );
                                _Mode = RenderMode.Custom;
                            }
                        };
                    }
                }
                EditorGUI.indentLevel--;
                EditorGUI.showMixedValue = false;
            }
        }

        protected override void OnRefreshKeywords() {
            SetMaterialKeywords();
        }

        protected override void OnMaterialChanged( MaterialProperty[] props ) {
            SetMaterialKeywords();
        }

        public override bool SerializeToJSON( JSONObject parent ) {
            return ShaderGUIHelper.SerializeToJSON( parent, m_prop_Mode ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_BlendOp ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_SrcBlend ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_DstBlend ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_ZWrite ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_ZTest ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_AlphaPremultiply ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_AutoRenderQueue ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_MainTex_Alpha ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_Cutoff ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_ColorKey ) &&
                ShaderGUIHelper.SerializeToJSON( parent, m_prop_FogColorSelector );
        }

        public override bool DeserializeFromJSON( JSONObject parent ) {
            return ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_Mode ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_BlendOp ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_SrcBlend ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_DstBlend ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_ZWrite ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_ZTest ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_AlphaPremultiply ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_AutoRenderQueue ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_MainTex_Alpha ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_Cutoff ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_ColorKey ) &&
                ShaderGUIHelper.DeserializeFromJSON( parent, m_prop_FogColorSelector );
        }

        public static UnitMaterialEditor Create( UnitMaterialEditor.PropEditorSettings s ) {
            return new ShaderGUI_RenderMode();
        }
    }
}
