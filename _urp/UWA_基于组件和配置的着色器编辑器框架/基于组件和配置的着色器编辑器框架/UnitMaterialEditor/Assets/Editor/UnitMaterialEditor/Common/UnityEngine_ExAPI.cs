using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace UME {

    public static class UnityEngine_ExAPI {

        const String PropName_MainTexture = "_MainTex";
        const String PropName_Color = "_Color";

        [NonSerialized]
        static int PropId_MainTexture = 0;
        [NonSerialized]
        static int PropId_Color = 0;

        static UnityEngine_ExAPI() {
            PropId_MainTexture = Shader.PropertyToID( PropName_MainTexture );
            PropId_Color = Shader.PropertyToID( PropName_Color );
        }

        public static Texture GetMainTexture( this Material _this ) {
            return _this.GetTexture( PropId_MainTexture );
        }

        public static Vector4 GetMainTextureScaleOffset( this Material _this ) {
            var curST_S = _this.GetTextureScale( PropId_MainTexture );
            var curST_T = _this.GetTextureOffset( PropId_MainTexture );
            return new Vector4( curST_S.x, curST_S.y, curST_T.x, curST_T.y );
        }

        public static Vector4 GetTextureScaleOffset( this Material _this, String name ) {
            var id = Shader.PropertyToID( name );
            var curST_S = _this.GetTextureScale( id );
            var curST_T = _this.GetTextureOffset( id );
            return new Vector4( curST_S.x, curST_S.y, curST_T.x, curST_T.y );
        }

        public static void SetTextureScaleOffset( this Material _this, String name, Vector4 st ) {
            var id = Shader.PropertyToID( name );
            _this.SetTextureScale( id, new Vector2( st.x, st.y ) );
            _this.SetTextureOffset( id, new Vector2( st.z, st.w ) );
        }

        public static void SetMainTextureScaleOffset( this Material _this, Vector4 st ) {
            _this.SetTextureScale( PropId_MainTexture, new Vector2( st.x, st.y ) );
            _this.SetTextureOffset( PropId_MainTexture, new Vector2( st.z, st.w ) );
        }

        public static Color GetColor( this Material _this ) {
            return _this.GetColor( PropId_Color );
        }

        public static void SetMainTexture( this Material _this, Texture texture ) {
            _this.SetTexture( PropId_MainTexture, texture );
        }

        public static void SetColor( this Material _this, ref Color color ) {
            _this.SetColor( PropId_Color, color );
        }

        public static void SetColor( this Material _this, Color color ) {
            _this.SetColor( PropId_Color, color );
        }

        public static bool IsAllKeywordsEnabled( this Material _this, params String[] keywords ) {
            if ( _this != null && keywords.Length > 0 ) {
                for ( int i = 0; i < keywords.Length; ++i ) {
                    if ( !_this.IsKeywordEnabled( keywords[ i ] ) ) {
                        return false;
                    }
                }
                return true;
            }
            return false;
        }

        public static bool IsAnyOfKeywordEnabled( this Material _this, params String[] keywords ) {
            if ( _this != null && keywords.Length > 0 ) {
                for ( int i = 0; i < keywords.Length; ++i ) {
                    if ( _this.IsKeywordEnabled( keywords[ i ] ) ) {
                        return true;
                    }
                }
            }
            return false;
        }
    }
}
//EOF
