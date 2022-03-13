using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 屏幕位置
/// </summary>
public enum ScreenPos
{
    FullScreen=0,
    LeftScreen,
    RightScreen,
}
public class FPSCamera : BaseCame
{
    public ScreenPos screenPos = ScreenPos.RightScreen;
    public void RuntimUpdate()
    {
        //Debug.Log("相机旋转Update外部调用");

        GetPCState();
    }

    public void RuntimLateUpdate()
    {
        //Debug.Log("相机旋转LateUpdate外部调用");
#if UNITY_EDITOR
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
                SingleTouchMove(0, (int)screenPos);
            }
            else if (Input.touchCount > 1)
            {
                if (_joyMove.IsOnDrag)
                {
                    TwoTouchPlayerMoveAndCameraCtr((int)screenPos);
                    return;
                }
            }
        }
    }
}
