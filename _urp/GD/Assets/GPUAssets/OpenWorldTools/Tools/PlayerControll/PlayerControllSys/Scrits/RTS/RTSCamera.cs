using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class RTSCamera : MonoBehaviour
{
    public enum RTSZoomType
    {
        /// <summary>
        /// Y轴上下拉近
        /// </summary>
        VerticalY,
        /// <summary>
        /// 相机本地正向拉近
        /// </summary>
        ForwardZ,
    }
    public Transform floor;
    public float zoomMin = 1;
    public float zoomMax = 20;
    /// <summary>
    /// 滚轮减少的差值
    /// </summary>
    public float zoomLerp = 1.0f;
    public float zoomSpeed = 5.0f;
    public float forwardDis = 5;

    /// <summary>
    /// 移动速度
    /// </summary>
    public float panSpeed = 10.0f;
    /// <summary>
    /// 距离屏幕边缘大小--鼠标移动检测
    /// </summary>
    public float panScreenBounder = 20.0f;
    public float panelY = 0.0f;
    public float angle = 70.0f;
    public Vector2 angleBound = new Vector2(0, 90);
    public Vector3 lookPosition;
    public Vector2 panBounder = new Vector2(20, 30);
    public Plane rayFloorPanel;
    public RTSZoomType zoomType = RTSZoomType.ForwardZ;
    public bool isMouseDown = false;
    public bool isMove = true;
    void Start()
    {
        if (floor)
        {
            rayFloorPanel = new Plane(Vector3.up, new Vector3(0, floor.position.y, 0));

            var lookRay = new Ray(transform.position, transform.forward);

            float dist;
            if (rayFloorPanel.Raycast(lookRay, out dist))
            {
                lookPosition = lookRay.GetPoint(dist);
            }

            if (isMouseDown == false)
            {
                zoomMin = floor.position.y + zoomMin;
                zoomMax = floor.position.y + zoomMax;
            }
        }
        else
        {
            rayFloorPanel = new Plane(Vector3.up, new Vector3(0, panelY, 0));

            var lookRay = new Ray(transform.position, transform.forward);

            float dist;
            if (rayFloorPanel.Raycast(lookRay, out dist))
            {
                lookPosition = lookRay.GetPoint(dist);
                GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.transform.position = lookPosition;
            }
        }

        //初始化。获取射线与虚拟平面的焦点位置，和相机位置 求出两者距离
        forwardDis = (lookPosition - transform.position).magnitude;
        //更新最大距离为初始距离+原始距离
        zoomMax += forwardDis;
    }

    public void SetValue(float newSpeed, float newZoomSpeed, float newAngle, float newDis, Vector2 newBounds, Vector2 newAngelBound, Vector2 newZoom, Transform newFloor = null)
    {
        floor = newFloor;
        panSpeed = newSpeed;
        zoomSpeed = newZoomSpeed;
        panBounder = newBounds;
        angle = newAngle;
        angleBound = newAngelBound;

#if UNITY_EDITOR
        forwardDis = newDis;
#endif
        zoomMin = newZoom.x;
        zoomMax = newZoom.y;
    }

    Vector3 pos;
    void Update()
    {

    }
    public void OnUpdate(ref float value)
    {
        pos = transform.position;
        if (isMove)
        {
#if UNITY_EDITOR
            PCControllMethod();
            PCZoomMethod(ref value);
#endif
#if UNITY_ANDROID || UNITY_IOS || UNITY_IPHONE
            MobileTouch();        
#endif
        }
    }
    private void MobileTouch()
    {
        if (Input.touchCount <= 0)
        {
            return;
        }
        else
        {
            //单个手指在--摇杆区域外--触摸
            if (Input.touchCount == 1)
            {
                SingleTouchMove(0);

                transform.position = pos;
            }
            else if (Input.touchCount > 1)
            {
                TwoTouchScale(zoomSpeed);
            }
        }
    }
    #region ----Mobile
    float x, y;
    //===========================================================触屏和摇杆处理=======================//
    // 记录手指触屏的位置
    Vector2 touchStartPos = new Vector2();
    Vector2 touchEndPos = new Vector2();
    /// <summary>
    ///哪个手指开始触摸
    /// </summary>
    private int beginId;
    /// <summary>
    /// 哪个手指手指id滑动
    /// </summary>
    private int id;

    public float mobileSpeed = 6.5f;
    /// <summary>
    /// 公用的单指触摸
    /// </summary>
    /// <param name="i"></param>
    protected void SingleTouchMove(int i)
    {
        //touchStartPos = Vector2.zero;
        //touchEndPos = Vector2.zero;

        if (Input.touches[i].phase == TouchPhase.Began)
        {
            touchStartPos = Input.touches[i].position;
        }
        else if (TouchPhase.Moved == Input.touches[i].phase)
        {
            x = Input.touches[i].deltaPosition.x * Time.deltaTime * mobileSpeed;
            y = Input.touches[i].deltaPosition.y * Time.deltaTime * mobileSpeed;

            Vector3 toucpos = new Vector3(x, 0, y);
            pos += toucpos;
            pos.x = Mathf.Clamp(pos.x, -panBounder.x, panBounder.x);
            pos.z = Mathf.Clamp(pos.z, -panBounder.y, panBounder.y);
        }
    }

    /// <summary>
    /// 双指缩放
    /// </summary>
    /// <param name="procame">相机脚本</param>
    /// <param name="zoomSpeed">缩放速度</param>
    protected void TwoTouchScale(float zoomSpeed)
    {
        Touch touchZero = Input.GetTouch(0);
        Touch touchOne = Input.GetTouch(1);

        Vector2 touchZeroPrevPos = touchZero.position - touchZero.deltaPosition;
        Vector2 touchOnePrevPos = touchOne.position - touchOne.deltaPosition;

        float prevTouchDeltaMag = (touchZeroPrevPos - touchOnePrevPos).magnitude;
        float touchDeltaMag = (touchZero.position - touchOne.position).magnitude;

        float deltaMagnitudeDiff = prevTouchDeltaMag - touchDeltaMag;

        ZoomMethod(deltaMagnitudeDiff * Time.deltaTime * zoomSpeed);
    }


    private float _Speed = 5;
    private float _touchSpeedL = 5;
    private void CameCtrMobile()
    {
        CameraCtrH();
        CameraCtrV();
    }

    /// <summary>
    /// 相机水平旋转
    /// </summary>
    private void CameraCtrH()
    {
        //y轴
        pos.x += x * Time.deltaTime * _Speed * _touchSpeedL;
        pos.x = Mathf.Clamp(pos.x, -panBounder.x, panBounder.x);
    }

    /// <summary>
    /// 相机竖直旋转
    /// </summary>
    private void CameraCtrV()
    {
        //x轴
        pos.z -= y * Time.deltaTime * _Speed * _touchSpeedL;
        pos.z = Mathf.Clamp(pos.z, -panBounder.y, panBounder.y);
    }

    #endregion



    /// <summary>
    /// 编辑器模式下操作
    /// </summary>
    private void PCControllMethod()
    {
        if (isMouseDown)
        {
            if (Input.GetMouseButton(0))
            {
                PCCameraPosChangeMethod();
            }
        }
        else
        {
            if (Input.anyKey == false)
            {
                PCCameraPosChangeMethod();
            }
        }

        if (Input.GetKey("w"))
        {
            pos.z += panSpeed * Time.deltaTime;
        }
        if (Input.GetKey("s"))
        {
            pos.z -= panSpeed * Time.deltaTime;
        }
        if (Input.GetKey("d"))
        {
            pos.x += panSpeed * Time.deltaTime;
        }
        if (Input.GetKey("a"))
        {
            pos.x -= panSpeed * Time.deltaTime;
        }
        pos.x = Mathf.Clamp(pos.x, -panBounder.x, panBounder.x);
        pos.z = Mathf.Clamp(pos.z, -panBounder.y, panBounder.y);
        transform.position = pos;

        angle = Mathf.Clamp(angle, angleBound.x, angleBound.y);

        transform.eulerAngles = new Vector3(angle, 0.0f, 0.0f);
    }

    private void PCZoomMethod(ref float value)
    {
        if (zoomType == RTSZoomType.ForwardZ)
        {
            ZoomMethod(ref value);
        }
        else if (zoomType == RTSZoomType.VerticalY)
        {
            if (Input.GetAxis("Mouse ScrollWheel") > 0)
            {

                if (pos.y > zoomMin)
                {
                    pos.y -= zoomLerp;
                }
            }
            else if (Input.GetAxis("Mouse ScrollWheel") < 0)
            {
                if (pos.y < zoomMax)
                {
                    pos.y += zoomLerp;
                }
            }
            transform.position = pos;
        }

        if (Input.anyKey == false)
        {
            forwardDis = Mathf.Clamp(forwardDis, zoomMin, zoomMax);
            var lookRay = new Ray(transform.position, transform.forward);

            float dist;
            if (rayFloorPanel.Raycast(lookRay, out dist))
            {
                lookPosition = lookRay.GetPoint(dist);
            }

            pos = this.transform.rotation * new Vector3(0.0f, 0.0f, -forwardDis) + lookPosition;
            transform.position = pos;
        }
    }

    private void ZoomMethod(ref float value)
    {
        var lookRay = new Ray(transform.position, transform.forward);

        float dist;
        if (rayFloorPanel.Raycast(lookRay, out dist))
        {
            lookPosition = lookRay.GetPoint(dist);
        }
        if (Input.GetAxis("Mouse ScrollWheel") > 0)
        {
            value -= 1;
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0)
        {
            value += 1;
        }
        forwardDis = value;
        value = Mathf.Clamp(value, zoomMin, zoomMax);
        forwardDis = Mathf.Clamp(forwardDis, zoomMin, zoomMax);
        pos = transform.rotation * new Vector3(0.0f, 0.0f, -forwardDis) + lookPosition;
        transform.position = pos;
    }

    private void ZoomMethod(float value)
    {
        var lookRay = new Ray(transform.position, transform.forward);

        float dist;
        if (rayFloorPanel.Raycast(lookRay, out dist))
        {
            lookPosition = lookRay.GetPoint(dist);
        }

        forwardDis -= value;
        forwardDis = Mathf.Clamp(forwardDis, zoomMin, zoomMax);
        pos = transform.rotation * new Vector3(0.0f, 0.0f, -forwardDis) + lookPosition;
        transform.position = pos;
    }

    private void PCCameraPosChangeMethod()
    {
        if (Input.mousePosition.y >= Screen.height - panScreenBounder)
        {
            pos.z += panSpeed * Time.deltaTime;
        }
        if (Input.mousePosition.y <= panScreenBounder)
        {
            pos.z -= panSpeed * Time.deltaTime;
        }
        if (Input.mousePosition.x >= Screen.width - panScreenBounder)
        {
            pos.x += panSpeed * Time.deltaTime;
        }
        if (Input.mousePosition.x <= panScreenBounder)
        {
            pos.x -= panSpeed * Time.deltaTime;
        }
    }
}
