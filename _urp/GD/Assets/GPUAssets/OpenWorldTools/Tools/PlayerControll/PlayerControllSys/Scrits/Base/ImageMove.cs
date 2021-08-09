using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
public class ImageMove : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IDragHandler
{
    public enum RadiusBase { Width, Height, UserDefined };
    public RadiusBase radiusBase;
    public Image _onDrgImage;
    public Image _onDrgBgImgae;
    public float radiusBaseValue = 60;
    public Vector2 axisValue = Vector2.zero;
    [SerializeField]
    private bool isOnDrag = false;
    [SerializeField]
    private bool isTouch = false;
    private RectTransform cachedRectTransform;
    private RectTransform cachedBgRectTransform;
    private Vector3 zeroVector3 = Vector3.zero;
    Vector2 tmp = Vector2.zero;
    float x = 0;
    float y = 0;
    public int _fingerId;
    public bool IsOnDrag
    {
        get { return isOnDrag; }
    }

    void Start()
    {
        if (_onDrgImage)
        {
            cachedRectTransform = _onDrgImage.GetComponent<RectTransform>();
        }
        if (_onDrgBgImgae)
        {
            cachedBgRectTransform = _onDrgBgImgae.GetComponent<RectTransform>();
        }
    }

    void Update()
    {
        if (!isTouch && cachedRectTransform)
        {
            x = Input.GetAxis("Horizontal");
            y = Input.GetAxis("Vertical");

            isOnDrag = false;

            if (x != 0 || y != 0)
            {
                isOnDrag = true;
                //归一化水平和竖直的输入
                tmp = new Vector2(x, y).normalized;
                cachedRectTransform.anchoredPosition = tmp * GetRadius();
            }
            else
            {
                isTouch = false;
                isOnDrag = false;
                cachedRectTransform.anchoredPosition = zeroVector3;
            }
        }
    }

    public float GetRadius()
    {
        float radius = 0;
        switch (radiusBase)
        {
            case RadiusBase.Width:
                radius = cachedBgRectTransform.sizeDelta.x * 0.5f;
                break;
            case RadiusBase.Height:
                radius = cachedBgRectTransform.sizeDelta.y * 0.5f;
                break;
            case RadiusBase.UserDefined:
                radius = radiusBaseValue;
                break;
        }
        return radius;
    }


    public void OnPointerDown(PointerEventData eventData)
    {
        OnDrag(eventData);
    }

    public void OnDrag(PointerEventData eventData)
    {
        _fingerId = eventData.pointerId;
        //Debug.Log("_joyMove._fingerId:  " + _fingerId);
        isOnDrag = true;
        isTouch = true;
        Vector2 pos;
        if (RectTransformUtility.ScreenPointToLocalPointInRectangle
            (_onDrgBgImgae.rectTransform,
            eventData.position,
            eventData.pressEventCamera,
            out pos))
        {
            pos.x = (pos.x / _onDrgBgImgae.rectTransform.sizeDelta.x);
            pos.y = (pos.y / _onDrgBgImgae.rectTransform.sizeDelta.y);

            Vector3 inputVector = new Vector3(pos.x * 2 + 1, 0, pos.y * 2 - 1);
            inputVector = (inputVector.magnitude > 1.0f) ? inputVector.normalized : inputVector;


            _onDrgImage.rectTransform.anchoredPosition = new Vector3
                (inputVector.x * (_onDrgBgImgae.rectTransform.sizeDelta.x / 2)
                , inputVector.z * (_onDrgBgImgae.rectTransform.sizeDelta.y / 2));

            axisValue = new Vector2(inputVector.x, inputVector.z);
        }
       
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        isTouch = false;
        isOnDrag = false;
        _onDrgImage.rectTransform.anchoredPosition = zeroVector3;
        axisValue = Vector2.zero;
    }


}
