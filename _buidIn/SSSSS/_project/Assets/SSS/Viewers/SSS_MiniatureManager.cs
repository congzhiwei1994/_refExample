using UnityEngine;
using System.Collections;
using UnityEngine.UI;
[ExecuteInEditMode]
public class SSS_MiniatureManager : MonoBehaviour
{

    public Transform[] Miniatures;
    [SerializeField]
    float margin = 10;
    [Range(0, 1)] public float imageSize = .1f;
    public float VerticalPosition = 10;
    public bool vertical = false;
    void Start()
    {
        //ImageScale(0.1792f);
    }

    // Update is called once per frame
    void Update()
    {
        ImageScale(imageSize);
    }
    public void SetSize(float SliderSize)
    {

        ImageScale(SliderSize);
        // print(SliderSize);
    }
    void ImageScale(float PreviewSize)
    {
        int i = 0;
        Camera cam = Camera.main;
        if (cam == null) return;
        Vector2 size;
        if (cam.stereoEnabled)
            size = new Vector2(UnityEngine.XR.XRSettings.eyeTextureWidth, UnityEngine.XR.XRSettings.eyeTextureWidth) * PreviewSize;
        else
        size = new Vector2(Screen.width, Screen.height) * PreviewSize;

        if (Miniatures != null)
            if (Miniatures.Length > 0)
                foreach (Transform Target in Miniatures)
                {
                    try
                    {
                        if (Target.GetComponent<RawImage>().enabled)
                        {
                            Vector2 Position = Target.GetComponent<RectTransform>().position;
                            Target.transform.localScale = new Vector3(size.x, size.y, 1);
                            Position = new Vector2(size.x * i + margin * i + margin, VerticalPosition + margin);
                            if (vertical)
                                Position = new Vector2(margin, size.y * i + margin * i + VerticalPosition);
                            Target.GetComponent<RectTransform>().position = Position;
                            i++;
                        }
                        
                    }
                    catch { print("Missing Element in UI"); }
                }

    }
}
