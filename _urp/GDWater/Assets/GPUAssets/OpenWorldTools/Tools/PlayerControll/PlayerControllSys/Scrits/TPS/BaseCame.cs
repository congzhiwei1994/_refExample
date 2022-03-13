using UnityEngine;
using System;
public class BaseCame : PivotBasedCameraRig
{
    /// <summary> 相机跟随目标点速度 </summary>
    [Range(1, 20)]
    public float _followSpeed = 5;
    /// <summary> 相机水平旋转速度 </summary>
    [Range(1, 20)]
    public float _horiSpeed = 5;
    /// <summary> 相机竖直旋转速度 </summary>
    [Range(1, 20)]
    public float _vertSpeed = 5;
    /// <summary> 绕x轴旋转最大 </summary>
    public  float _TiltMax = 75f;
    /// <summary> 绕x轴旋转最小 </summary>
    public float _TiltMin = -45f;

    /// <summary> 触摸缩放系数 </summary>
    //public float _ZoomSpeed = 0.03f;

    /// <summary> 触摸水平系数 </summary>
    public float _MobileHSpeed = 2.5f;

    public bool _isRotate = true;
    public bool _isMouseDown = false;
    public bool _isCameCtr = false;
    public Vector2 screenScale;
   // public bool _isMouseScroll = false;

    private float x = 0;
    private float y = 0;

    private float _LookAngleY;      //绕y轴旋转角
    private float _LookAngleX;      //绕x轴旋转角

    private Quaternion _PivotTargetRot;
    private Quaternion _TransformTargetRot;

    //private Vector3 offset;

    private bool _isKeyDown = false;

    private bool _isSmooth = false;      //相机旋转是否差值

    private float _smoothSpeed = 10;     //相机差值固定速率   
    
    private float _followSpeed_ = 30;
    private float _rotateSpeed_ = 20;   //相机旋转固定速率   

    //private BaseCameClip _proCame;
    protected ImageMove _joyMove;
    //private float _posY = 10;

    protected new virtual void Awake()
    {
        base.Awake();

        _LookAngleY = transform.localEulerAngles.y;
       // offset = m_Pivot.localPosition;

        _PivotTargetRot = m_Pivot.transform.localRotation;
        _TransformTargetRot = transform.localRotation;

        //_proCame = transform.GetComponent<BaseCameClip>();
        _joyMove = FindObjectOfType<ImageMove>();
        screenScale = new Vector2(Screen.width, Screen.height);
    }
    /// <summary>
    /// 跟随目标
    /// </summary>
    /// <param name="deltaTime"></param>
    protected override void FollowTarget(float deltaTime)
    {
        if (m_Target == null) return;
        transform.position = Vector3.Lerp(transform.position, m_Target.position, deltaTime * _followSpeed * _followSpeed_);
    }
    public virtual void SetValue(Transform newTarget, Vector2 xySpeed, Vector2 tiltRange, /*Vector3 newOffset,*/ bool rotateState)
    {
        if (newTarget == null) { Debug.Log("newTarger -- 新对象为空"); return; }

        m_Target = newTarget;
        _horiSpeed = xySpeed.x;
        _vertSpeed = xySpeed.y;

        _TiltMin = tiltRange.x;
        _TiltMax = tiltRange.y;
        //offset = newOffset;
        _isRotate = rotateState;
    }


    #region ----编辑器下控制
    /// <summary>
    /// 编辑器下按键检测
    /// </summary>
    public void GetPCState()
    {
        FollowTarget(Time.deltaTime);

        if (Input.GetMouseButton(0))
        {
            _isMouseDown = true;
        }
        else if (Input.GetMouseButtonUp(0))
        {
            _isMouseDown = false;
        }    
    }
    /// <summary>
    /// 相机旋转
    /// </summary>
    /// <param name="isSmooth">是否开启差值 </param>
    public void CameraRotateXY(bool isSmooth = true)
    {
        CameraCtrH();
        CameraCtrV();

        if (isSmooth)
        {
            m_Pivot.localRotation = Quaternion.Slerp(m_Pivot.localRotation, _PivotTargetRot, Time.deltaTime * _smoothSpeed);
            transform.localRotation = Quaternion.Slerp(transform.localRotation, _TransformTargetRot, Time.deltaTime * _smoothSpeed);
        }
        else
        {
            m_Pivot.localRotation = _PivotTargetRot;
            transform.localRotation = _TransformTargetRot;
        }

    }
    void HandleRotationMovment()
    {
        x = Input.GetAxis("Mouse X");
        y = Input.GetAxis("Mouse Y");

        _isKeyDown = Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.W);

        if (x != 0 || y != 0)
        {
            _isCameCtr = true;

            if (_isKeyDown)
            {
                CameraRotateXY(true);
            }
            else
            {
                if (_joyMove != null && _joyMove.IsOnDrag == false)
                {
                    CameraRotateXY();
                }
            }
        }
    }
    /// <summary>
    /// 编辑器下TPS控制相机
    /// </summary>
    public void CameraRotate()
    {
        if (_isMouseDown && _isRotate)
        {
            HandleRotationMovment();
        }
        else
        {
            _isCameCtr = false;
        }
    }
    #endregion


    #region ----移动平台控制
    public  void GetMobileState()
    {
        if (!Utility.IsPointerOverUIObject())
        {
            MobileTouch();
        }
        else
        {
            _isCameCtr = false;
        }
    }

    protected virtual void MobileTouch()
    {
        #region ----实现版本
        //if (Input.touchCount <= 0)
        //{
        //    return;
        //}
        //else
        //{
        //    //单个手指在--摇杆区域外--触摸
        //    if (Input.touchCount == 1 && _joyMove.IsOnDrag == false)
        //    {
        //        SingleTouchMove(0);
        //    }
        //    else if (Input.touchCount > 1)
        //    {
        //        //两手指都不在摇杆获取游戏对象(UI)，进行缩放
        //        if (_joyMove.IsOnDrag)
        //        {
        //            TwoTouchPlayerMoveAndCameraCtr();
        //            return;
        //        }
        //        else if (Utility.IsPointerOverUIObject() == false)
        //        {
        //           //
        //        }
        //    }
        //}
        #endregion 
    }

    /// <summary>
    /// ----两指触摸-边遥感边旋转相机
    /// </summary>
    protected void TwoTouchPlayerMoveAndCameraCtr()
    {
        _isCameCtr = false;
        int id = Mathf.Abs(_joyMove._fingerId - 1);
        if (_joyMove._fingerId == 2)
        {
            return;
        }
        SingleTouchMove(id);
        return;
    }
    /// <summary>
    ///  ----两指触摸-边遥感边旋转相机--限制旋转触摸位置
    /// </summary>
    /// <param name="type">0--表示全屏  1--表示右半屏幕  2--表示左半屏幕</param>
    protected void TwoTouchPlayerMoveAndCameraCtr(int type)
    {
        _isCameCtr = false;
        int id = Mathf.Abs(_joyMove._fingerId - 1);
        if (_joyMove._fingerId == 2)
        {
            return;
        }
        SingleTouchMove(id, type);
        return;
    }
    /// <summary>
    /// 双指缩放
    /// </summary>
    /// <param name="procame">相机脚本</param>
    /// <param name="zoomSpeed">缩放速度</param>
    protected void TwoTouchScale(BaseCameClip procame,float zoomSpeed)
    {
        Touch touchZero = Input.GetTouch(0);
        Touch touchOne = Input.GetTouch(1);

        Vector2 touchZeroPrevPos = touchZero.position - touchZero.deltaPosition;
        Vector2 touchOnePrevPos = touchOne.position - touchOne.deltaPosition;

        float prevTouchDeltaMag = (touchZeroPrevPos - touchOnePrevPos).magnitude;
        float touchDeltaMag = (touchZero.position - touchOne.position).magnitude;

        float deltaMagnitudeDiff = prevTouchDeltaMag - touchDeltaMag;
        {
            if (procame)
            {
                procame.m_OriginaDist += deltaMagnitudeDiff * zoomSpeed;
                procame.m_OriginaDist = Mathf.Clamp(procame.m_OriginaDist, procame.m_minDist, procame.m_maxDist);
            }
        }
    }

    /// <summary>
    /// 更新触摸xy值
    /// </summary>
    private void CameCtrMobile()
    {
        CameraRotateXY();
    }

    //===========================================================触屏和摇杆处理=======================//
    // 记录手指触屏的位置
    Vector2 m_screenpos = new Vector2();
    /// <summary>
    ///哪个手指开始触摸
    /// </summary>
    private int beginId;
    /// <summary>
    /// 哪个手指手指id滑动
    /// </summary>
    private int id;
    /// <summary>
    /// 公用的单指触摸
    /// </summary>
    /// <param name="i"></param>
    protected void SingleTouchMove(int i)
    {
        if (Input.touches[i].phase == TouchPhase.Began)
        {
            m_screenpos = Input.touches[i].position;
        }
        else if (TouchPhase.Moved == Input.touches[i].phase)
        {
            x = Input.touches[i].deltaPosition.x * Time.deltaTime * _MobileHSpeed;
            y = Input.touches[i].deltaPosition.y * Time.deltaTime;

            if (x != 0 || y != 0)
            {
                _isCameCtr = true;
            }
            CameCtrMobile();
            return;
        }
    }
    /// <summary>
    /// 限制屏幕
    /// </summary>
    /// <param name="i">触摸手指ID</param>
    /// <param name="type">0--表示全屏  1--表示右半屏幕  2--表示左半屏幕</param>
    protected void SingleTouchMove(int i,int type =0)
    {
        if (Input.touches[i].phase == TouchPhase.Began)
        {
            m_screenpos = Input.touches[i].position;
            if (type == 0)
            {

            }
            else if (type == 1)
            {
                if (m_screenpos.x - ((screenScale.x) * 0.5f) > 0)
                {
                    //在右半屏幕
                }
                else
                {
                    return;
                }
            }
            else if(type ==2)
            {
                if (m_screenpos.x - ((screenScale.x) * 0.5f) < 0)
                {
                    //在左半屏幕
                }
                else
                {
                    return;
                }
            }
        }
        else if (TouchPhase.Moved == Input.touches[i].phase)
        {
            x = Input.touches[i].deltaPosition.x * Time.deltaTime * _MobileHSpeed;
            y = Input.touches[i].deltaPosition.y * Time.deltaTime;

            if (x != 0 || y != 0)
            {
                _isCameCtr = true;
            }
            CameCtrMobile();
            return;
        }
    }

    #endregion

    #region ----公用方法
    /// <summary>
    /// 相机水平旋转
    /// </summary>
    private void CameraCtrH()
    {
        //y轴
        _LookAngleY += x *Time.deltaTime * _horiSpeed *_rotateSpeed_;
        //赋值
        _TransformTargetRot = Quaternion.Euler(0f, _LookAngleY, 0f);
    }

    /// <summary>
    /// 相机竖直旋转
    /// </summary>
    private void CameraCtrV()
    {
        //x轴
        _LookAngleX -= y * Time.deltaTime * _vertSpeed * _rotateSpeed_;
        _LookAngleX = Mathf.Clamp(_LookAngleX, _TiltMin, _TiltMax);

       //赋值
       _PivotTargetRot = Quaternion.Euler(_LookAngleX, 0, 0);
    }

    #endregion
}

