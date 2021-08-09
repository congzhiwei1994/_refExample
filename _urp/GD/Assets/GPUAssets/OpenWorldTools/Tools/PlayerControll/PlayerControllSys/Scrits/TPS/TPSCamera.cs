using System;
using UnityEngine;
public class TPSCamera : BaseCame
{
    /// <summary> 触摸缩放系数 </summary>
    public float _ZoomSpeed = 0.03f;
    public bool _isMouseScroll = false;

    private Vector3 offset;
    private BaseCameClip _proCame;
    protected override void Start()
    {
        base.Start();
        offset = m_Pivot.localPosition;
        _proCame = transform.GetComponent<BaseCameClip>();
    }
    public  void SetValue(Transform newTarget, Vector2 xySpeed, Vector2 tiltRange, Vector3 newOffset, bool rotateState)
    {
        if (newTarget == null) { Debug.Log("newTarger -- 新对象为空"); return; }

        m_Target = newTarget;
        _horiSpeed = xySpeed.x;
        _vertSpeed = xySpeed.y;

        _TiltMin = tiltRange.x;
        _TiltMax = tiltRange.y;
        offset = newOffset;
        _isRotate = rotateState;
    }
    public void RuntimUpdate()
    {
        //Debug.Log("相机旋转Update外部调用");

        GetPCState();

        #region ----编辑器下滚轮按下控制offset
        //if (Input.GetMouseButtonDown(2))
        //{
        //    _isMouseScroll = true;
        //}
        //if (Input.GetMouseButtonUp(2))
        //{
        //    _isMouseScroll = false;
        //}
        #endregion

        if (Input.GetAxis("Mouse ScrollWheel") > 0)
        {
            if (_proCame && _proCame.m_OriginaDist > _proCame.m_minDist)
            {
                _proCame.m_OriginaDist -= 1;
            }
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0)
        {
            if (_proCame && _proCame.m_OriginaDist < _proCame.m_maxDist)
            {
                _proCame.m_OriginaDist += 1;
            }
        }
        if (_isMouseScroll)
        {
            #region ----滚轮按下控制注视点
            //float _y = (-1) * Input.GetAxis("Mouse Y");
            //if (_y > 0.1f || _y < -0.1f)
            //{
            //    if (m_Pivot)
            //    {
            //        m_Pivot.Translate(new Vector3(0, _y * Time.deltaTime * _posY, 0));
            //        offset = m_Pivot.localPosition;
            //    }
            //}
            #endregion
        }
        else
        {
            if (m_Pivot)
            {
                m_Pivot.localPosition = offset;
            }
        }

    }
    public void RuntimLateUpdate()
    {
        //Debug.Log("相机旋转LateUpdate外部调用");
#if UNITY_EDITOR||UNITY_STANDALONE_WIN 
        CameraRotate();
#elif UNITY_ANDROID || UNITY_IPHONE
        GetMobileState();
#endif
    }
    protected override void MobileTouch()
    {
        if (Input.touchCount <= 0)
        {
            return;
        }
        else
        {
            //单个手指在--摇杆区域外--触摸
            if (Input.touchCount == 1 && _joyMove.IsOnDrag == false)
            {
                SingleTouchMove(0);
            }
            else if (Input.touchCount > 1)
            {
                //两手指都不在摇杆获取游戏对象(UI)，进行缩放
                if (_joyMove.IsOnDrag)
                {
                    TwoTouchPlayerMoveAndCameraCtr();
                    return;
                }
                else if (Utility.IsPointerOverUIObject() == false)
                {
                    TwoTouchScale(_proCame,_ZoomSpeed);
                }
            }
        }
    }
}
