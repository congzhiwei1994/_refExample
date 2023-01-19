using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SSS
{
    public class QualitySwitch : MonoBehaviour
    {
        SSS _SSS;
        Dropdown _Dropdown;
        public GameObject[] _Fuzz;
        public GameObject HeadLow, HeadHigh;
        float[] DownscaleFactor;
        float initRadius, initIterations, initShaderIterations;
        public Light MainLight;
        public GameObject[] SecondaryLights;
        //int initTextureSize;
        // Start is called before the first frame update
        void OnEnable()
        {
            DownscaleFactor = new float[3] { 1, 1.5f, 2 };
            _Dropdown = GetComponent<Dropdown>();
            //initTextureSize = QualitySettings.masterTextureLimit;
            _SSS = FindObjectOfType<SSS>();
            initRadius = _SSS.ScatteringRadius;
            initIterations = _SSS.ScatteringIterations;
            initShaderIterations = _SSS.ShaderIterations;
            _Dropdown.onValueChanged.AddListener(delegate
            {
                DropdownValueChanged(_Dropdown);
            });

            //Initialise the Text to say the first value of the Dropdown
            //m_Text.text = "First Value : " + m_Dropdown.value;
        }

        void SetActive(GameObject[] obj, bool b)
        {
            foreach (GameObject i in obj)
                i.SetActive(b);
        }
        //Ouput the new value of the Dropdown into Text
        void DropdownValueChanged(Dropdown level)
        {
            _SSS.Downsampling = DownscaleFactor[level.value];
            switch (level.value)
            {
                case 0:
                    SetActive(_Fuzz, true);
                    _SSS.ScatteringRadius = initRadius;
                    _SSS.ScatteringIterations = (int)initIterations;
                    _SSS.ShaderIterations = (int)initShaderIterations;
                    HeadLow.SetActive(false);
                    HeadHigh.SetActive(true);
                    MainLight.shadowCustomResolution = 8192;
                    SetActive(SecondaryLights, true);
                    QualitySettings.masterTextureLimit = 0;
                    QualitySettings.antiAliasing = 8;
                    Camera.main.allowMSAA = true;
                    break;
                case 1:
                    SetActive(_Fuzz, true);
                    _SSS.ScatteringRadius = initRadius * 2;
                    _SSS.ScatteringIterations = (int)initIterations - 1;
                    _SSS.ShaderIterations = (int)initShaderIterations - 2;
                    HeadLow.SetActive(false);
                    HeadHigh.SetActive(true);
                    MainLight.shadowResolution = UnityEngine.Rendering.LightShadowResolution.VeryHigh;
                    MainLight.shadowCustomResolution = -1;
                    SetActive(SecondaryLights, true);
                    QualitySettings.masterTextureLimit = 1;
                    QualitySettings.antiAliasing = 2;
                    Camera.main.allowMSAA = true;
                    break;
                case 2:
                    SetActive(_Fuzz, false);
                    _SSS.ScatteringRadius = initRadius * 3;
                    _SSS.ScatteringIterations = (int)initIterations - 1;
                    _SSS.ShaderIterations = (int)initShaderIterations - 3;
                    HeadLow.SetActive(true);
                    HeadHigh.SetActive(false);
                    MainLight.shadowResolution = UnityEngine.Rendering.LightShadowResolution.Medium;
                    MainLight.shadowCustomResolution = -1;
                    SetActive(SecondaryLights, false);
                    QualitySettings.masterTextureLimit = 2;
                    QualitySettings.antiAliasing = 0;
                    Camera.main.allowMSAA = false;
                    break;
            }

        }
    }
}
