using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LockCamera : BaseCame
{
    private float angle = 30;
    protected override void Start()
    {
        base.Start();      
    }

    public void SetValue(Transform newTarget,float newAngle,Vector2 tilt)
    {
        if (newTarget == null) { Debug.Log("newTarger -- 新对象为空"); return; }
        m_Target = newTarget;
        angle = newAngle;
        _TiltMin = tilt.x;
        _TiltMax = tilt.y;
    }
    public void RuntimUpdate()
    {
        //Debug.Log("相机旋转Update外部调用");

        FollowTarget(Time.deltaTime);

    }

    public void RuntimLateUpdate()
    {
        //Debug.Log("相机旋转LateUpdate外部调用");

        angle = Mathf.Clamp(angle,_TiltMin,_TiltMax);
        m_Pivot.rotation = Quaternion.Euler(angle, 0, 0);
    }

    protected override void MobileTouch()
    {
       
    }
}
