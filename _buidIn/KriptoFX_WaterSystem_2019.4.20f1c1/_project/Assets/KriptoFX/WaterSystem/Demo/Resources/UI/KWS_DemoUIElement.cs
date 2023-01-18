using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class KWS_DemoUIElement : MonoBehaviour
{
    public Text TextLabel;
    public RectTransform Rect;
    public Slider Slider;
    public Button Button;
    Action currentButtonAction;
    Action<float> currentSliderAction;
    string initializedText;

    Color enabledColor = new Color(0.9f, 1f, 0.9f);
    Color disabledColor = new Color(0.75f, 0.75f, 0.75f);
    bool isActive;
    int currentClickCount;
    string[] buttonPrefixStatus;

    public void Initialize(string text, Action buttonAction, bool currentActive, params string[] prefixStatus)
    {
        initializedText = text;
        TextLabel.text = initializedText + (prefixStatus.Length > 0 ? prefixStatus[0] : string.Empty);
        currentButtonAction = buttonAction;
        isActive = currentActive;
        this.buttonPrefixStatus = prefixStatus;
        UpdateButtonStatus(prefixStatus);
    }

    public void Initialize(string text, Action<float> sliderAction)
    {
        TextLabel.text = text;
        currentSliderAction = sliderAction;
      
    }

    void UpdateButtonStatus(params string[] prefixStatus)
    {
        if (prefixStatus.Length == 2)
        {
            GetComponent<Image>().color = isActive ? enabledColor : disabledColor;
            TextLabel.text = initializedText + " " + (isActive ? prefixStatus[0] : prefixStatus[1]);
        }

        if (prefixStatus.Length == 3)
        {
            GetComponent<Image>().color = enabledColor;
            var currentStatus = prefixStatus[currentClickCount % prefixStatus.Length];
            TextLabel.text = initializedText + " " + currentStatus;
        }
    }

    public void OnButtonClick()
    {
        if (currentButtonAction == null) return;

        currentClickCount++;
        isActive = !isActive;
        UpdateButtonStatus(buttonPrefixStatus);
        currentButtonAction();
       
    }

    public void OnSliderValueChanged()
    {
        if (currentSliderAction == null) return;

        currentSliderAction(Slider.value);
    }
}
