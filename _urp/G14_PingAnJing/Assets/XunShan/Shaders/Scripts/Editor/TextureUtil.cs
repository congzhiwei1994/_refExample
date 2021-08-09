using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Reflection;

namespace ShaderLib
{
    // Lightmap format of a [[Texture2D|texture]].
    public enum TextureUsageMode
    {
        // Not a lightmap.
        Default = 0,
        // Range [0;2] packed to [0;1] with loss of precision.
        BakedLightmapDoubleLDR = 1,
        // Range [0;kLightmapRGBMMax] packed to [0;1] with multiplier stored in the alpha channel.
        BakedLightmapRGBM = 2,
        // Compressed DXT5 normal map
        NormalmapDXT5nm = 3,
        // Plain RGB normal map
        NormalmapPlain = 4,
        RGBMEncoded = 5,
        // Texture is always padded if NPOT and on low-end hardware
        AlwaysPadded = 6,
        DoubleLDR = 7,
        // Baked lightmap without any encoding
        BakedLightmapFullHDR = 8,
        RealtimeLightmapRGBM = 9,
    }

    public static class TextureUtil
    {
        private static System.Type classType;

        static System.Type TextureUtilClass
        {
            get
            {
                if (classType == null)
                {
                    classType = typeof(EditorGUI).Assembly.GetType("UnityEditor.TextureUtil", false);
                }
                return classType;
            }
        }

        static PropertyInfo s_activeTextureColorSpace;
        public static ColorSpace GetTextureColorSpace(Texture t)
        {
            if(s_activeTextureColorSpace == null)
            {
                var _type = typeof(Texture);
                if (_type != null)
                {
                    s_activeTextureColorSpace = _type.GetProperty("activeTextureColorSpace", BindingFlags.Instance | BindingFlags.NonPublic);
                }
            }
            ColorSpace rt = ColorSpace.Uninitialized;
            if (s_activeTextureColorSpace != null)
            {
                try
                {
                    rt = (ColorSpace)s_activeTextureColorSpace.GetValue(t);
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                }
            }
            return rt;
        }


        static MethodInfo s_GetUsageMode;
        public static TextureUsageMode GetUsageMode(Texture t)
        {
            if(s_GetUsageMode == null)
            {
                var _type = TextureUtilClass;
                if(_type != null)
                {
                    s_GetUsageMode = _type.GetMethod("GetUsageMode", BindingFlags.Static | BindingFlags.Public);
                }
            }
            TextureUsageMode rt = TextureUsageMode.Default;
            if(s_GetUsageMode != null)
            {
                try
                {
                    rt = (TextureUsageMode)s_GetUsageMode.Invoke(null, new object[] { t });
                }
                catch(System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                }
            }

            return rt;
        }

        // public static extern Texture2D GetSourceTexture(Cubemap cubemapRef, CubemapFace face);
        static MethodInfo s_GetSourceTexture;
        public static Texture2D GetSourceTexture(Cubemap cubemapRef, CubemapFace face)
        {
            if (s_GetSourceTexture == null)
            {
                var _type = TextureUtilClass;
                if (_type != null)
                {
                    s_GetSourceTexture = _type.GetMethod("GetSourceTexture", BindingFlags.Static | BindingFlags.Public);
                }
            }
            Texture2D rt = null;
            if (s_GetSourceTexture != null)
            {
                try
                {
                    rt = (Texture2D)s_GetSourceTexture.Invoke(null, new object[] { cubemapRef, face });
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                }
            }

            return rt;
        }
    }
}