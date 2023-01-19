using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace SSS
{
    [ExecuteInEditMode]
    public class SSS_Buffers_Miniature : MonoBehaviour, IPointerDownHandler
    {
        GameObject GameCamera;

        SSS sss;

        public SSS.ToggleTexture toggleTexture = SSS.ToggleTexture.LightingTex;
        bool Active = false;
        SSS_Buffers_Miniature[] sss_Buffers_Miniature;
        private void OnEnable()
        {
            if (FindObjectOfType<SSS>())
            {
                GameCamera = FindObjectOfType<SSS>().gameObject;

                sss_Buffers_Miniature = FindObjectsOfType<SSS_Buffers_Miniature>();

                if (sss == null)
                    sss = GameCamera.GetComponent<SSS>();

                sss.toggleTexture = SSS.ToggleTexture.None;
            }
        }
        private void Update()
        {
            if (toggleTexture == SSS.ToggleTexture.ProfileTex)
                if (Shader.IsKeywordEnabled("SSS_PROFILES"))
                {
                    gameObject.GetComponent<RawImage>().enabled = true;
                }
                else
                {
                    gameObject.GetComponent<RawImage>().enabled = false;
                }

            //enabled = true;
        }
        public void OnPointerDown(PointerEventData pointerEventData)
        {
            if (FindObjectOfType<SSS>())
            {
                Active = !Active;

                if (Active && Application.isPlaying)
                {
                    switch (toggleTexture)
                    {
                        case SSS.ToggleTexture.LightingTex:
                            sss.toggleTexture = SSS.ToggleTexture.LightingTex;
                            break;
                        case SSS.ToggleTexture.LightingTexBlurred:
                            sss.toggleTexture = SSS.ToggleTexture.LightingTexBlurred;
                            break;
                        case SSS.ToggleTexture.ProfileTex:
                            sss.toggleTexture = SSS.ToggleTexture.ProfileTex;
                            break;
                    }
                }
                else
                {
                    sss.toggleTexture = SSS.ToggleTexture.None;


                }
                //Disable the other ones
                foreach (SSS_Buffers_Miniature brother in sss_Buffers_Miniature)
                {
                    if (brother.name != name)
                        brother.Active = false;
                }
            }
        }

    }
}