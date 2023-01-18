#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using UnityEngine.Video;

namespace KWS
{
    public class VideoTooltipWindow : EditorWindow
    {
        public string VideoClipFileURI;

        GameObject tempGO;
        VideoClip clip;
        VideoPlayer player;
        Texture currentRT;
        Texture2D DefaultTexture;

        void OnGUI()
        {
            Repaint();

            if (clip == null)
            {
                if (player == null)
                {
                    tempGO = new GameObject("WaterVideoWindowHelp");
                    tempGO.hideFlags = HideFlags.DontSave;

                    player = tempGO.AddComponent<VideoPlayer>();

                    player.url = VideoClipFileURI;
                    player.isLooping = true;

                    player.prepareCompleted += PlayerOnprepareCompleted;
                    player.Prepare();
                }

            }

            if (currentRT != null) EditorGUI.DrawPreviewTexture(new Rect(0, 0, position.width, position.height), currentRT);
            else
            {
                if(DefaultTexture == null) DefaultTexture = Resources.Load<Texture2D>("KWS_DefaultVideoLoading");
                currentRT = DefaultTexture;
            }
        }

        private void PlayerOnprepareCompleted(VideoPlayer source)
        {
            player.Play();
            currentRT = source.texture;
        }

        void OnDisable()
        {
            if (tempGO != null) KW_Extensions.SafeDestroy(tempGO);
            if (DefaultTexture != null) Resources.UnloadAsset(DefaultTexture);
        }
    }

}

#endif