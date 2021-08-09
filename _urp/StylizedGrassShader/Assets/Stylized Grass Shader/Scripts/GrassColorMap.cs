using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace StylizedGrass
{
    public class GrassColorMap : ScriptableObject
    {
        public int resolution = 1024;
        public Bounds bounds;
        public Vector4 uv;
        public Texture2D texture;
        public Texture2D customTex;
        [Tooltip("When enabled, a custom color map texture can be used")]
        public bool overrideTexture;
        public bool hasScalemap = false;

        public static GrassColorMap Active;

        public void SetActive()
        {
            if (!texture || (overrideTexture && !customTex))
            {
                Debug.LogWarning("Tried to activate grass color map with null texture", this);
                return;
            }

            Shader.SetGlobalTexture("_ColorMap", overrideTexture? customTex : texture);

            //Enables sampling of color map in shader
            uv.w = 1f;

            Shader.SetGlobalVector("_ColorMapUV", uv);

            Active = this;
        }

        /// <summary>
        /// Disables sampling of a color map in the grass shader. This must be called when a color map was used, but the current game context no longer as one active
        /// </summary>
        public static void DisableGlobally()
        {
            Shader.SetGlobalTexture("_ColorMap", null);
            Shader.SetGlobalVector("_ColorMapUV", Vector4.zero);

            Active = null;
        }
    }
}