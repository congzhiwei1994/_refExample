using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
public class BaseCameClip : MonoBehaviour {

    public Transform m_Cam;
    public Transform m_Pivot;
    public float m_MoveVelocity;
    public float m_ClipMoveTime = 0.05f;
    public float m_ReturnTime = 0.4f;
    [Range(0, 0.2f)]
    public float m_CamePosLerpValue = 0.15f;
    public float m_SphereCasyRadius = 0.1f;
    public float m_ClosestDistance = 0.5f;
    public string m_DontClipTag = "Player";
    public string m_DontClipTagWall = "Wall";
    public int m_LayerMask;
    public float m_OriginaDist = 6f;
    public float m_CurrentDist = 0f;
    public float m_TargetDist = 0f;

    public float m_minDist = 1.0f;
    public float m_maxDist = 15f;

    public bool m_isSmooth = true;
    public bool m_isRay = true;
    public bool m_currentRay = true;
    public bool m_isZoom =true;
    private Ray m_Ray = new Ray();
    private RaycastHit[] m_Hits;
    private RayHitCompere m_RayHitComparer;

    private void Start()
    {
        m_Cam = GetComponentInChildren<Camera>().transform;
        m_Pivot = m_Cam.parent;

        m_OriginaDist = m_Cam.localPosition.magnitude;
        m_CurrentDist = m_OriginaDist;

        m_RayHitComparer = new RayHitCompere();
    }
    void OnDrawGizmos()
    {
        //绘制角色头上的球形范围
        Gizmos.DrawSphere(m_Ray.origin, m_SphereCasyRadius);
    }


    public void SetPointRayTrue()
    {
        if (m_isRay != true)
            m_isRay = true;
    }

    public void SetPoinRayFalse()
    {
        if (m_isRay != false)
            m_isRay = false;
    }

    
    /// <summary>
    /// 设置m_isRay 状态
    /// </summary>
    /// <param name="value"></param>
    public void SetCurrentRay(bool value)
    {
        m_currentRay = value;
        if (m_currentRay != m_isRay)
        {
            m_isRay = m_currentRay;
            Debug.Log("设置状态_" + m_isRay);
        }
        else
        {
            return;
        }
    }
    private void Update()
    {
        //CameraClip();
    }


    public void SetZoomValue(float currentDis,float disMin,float disMax,bool newState, bool isZoom)
    {
        m_OriginaDist = currentDis;
        m_minDist = disMin;
        m_maxDist = disMax;
        m_isSmooth = newState;
        m_isZoom = isZoom;
    }
    public void SetZoomValue(float currentDis, float disMin, float disMax)
    {
        m_OriginaDist = currentDis;
        m_minDist = disMin;
        m_maxDist = disMax;
    }
    /// <summary>
    /// 设置距离
    /// </summary>
    /// <param name="newDis"></param>
    public void SetOriDis(float newDis)
    {
        if (newDis>m_maxDist)
        {
            newDis = m_maxDist;
        }else if (newDis <= m_minDist)
        {
            newDis = m_minDist;
        }
        m_OriginaDist = newDis;

        CameraClip();
    }
    public void RuntimeUpdate(ref float currentDis)
    {
        //Debug.Log("相机裁剪旋转Update外部调用");
        if (m_isZoom)
        {
            ScrollWheelDis(ref currentDis);
            CameraClip();
        }
    }

    private void CameraClip()
    {       

        if (m_isRay)
        {
            CameClip();
        }
        else
        {
            m_OriginaDist = m_CurrentDist;
            m_TargetDist = 0;
            m_TargetDist = m_OriginaDist;

            m_CurrentDist = m_TargetDist;
            m_CurrentDist = Mathf.Clamp(m_CurrentDist, m_minDist, m_maxDist);

            if (m_isSmooth)
            {
                m_Cam.localPosition = Vector3.Lerp(m_Cam.localPosition, Vector3.forward * m_CurrentDist * -1, m_CamePosLerpValue);
            }
            else
            {
                m_Cam.localPosition = Vector3.forward * m_CurrentDist * -1;
            }
        }
    }

    public void SetOriginaDist(float newValue)
    {
        m_OriginaDist = newValue;
        m_CurrentDist = newValue;
    }
    /// <summary>
    /// 滚轮控制距离
    /// </summary>
    public void ScrollWheelDis( ref float currenDis)
    {
#if UNITY_STANDALONE_WIN || UNITY_EDITOR
        if (Input.GetAxis("Mouse ScrollWheel") > 0)
        {
            //if (m_OriginaDist > m_minDist)
            //{
            //    m_OriginaDist -= 1;
            //}

            if (currenDis > m_minDist)
            {
                currenDis -= 1;
            }
        }

        else if (Input.GetAxis("Mouse ScrollWheel") < 0)
        {
            //if (m_OriginaDist < m_maxDist)
            //{
            //    m_OriginaDist += 1;
            //}
            if (currenDis < m_maxDist)
            {
                currenDis += 1;
            }
        }
#endif
    }

    private void CameClip()
    {
        //初始到目标距离
        m_TargetDist = 0;
        m_TargetDist = m_OriginaDist;
        //射线起始位置
        m_Ray.origin = m_Pivot.position + m_Pivot.forward * m_SphereCasyRadius;
        m_Ray.direction = -m_Pivot.forward;

        //position  3D相交球的球心
        //radius    3D相交球的球半径
        //layerMask 在某个Layer层上进行碰撞体检索，例如当前选中Player层，则只会返回周围半径内               
        //          Layer标示为Player的GameObject的碰撞体集合
        var cols = Physics.OverlapSphere(m_Ray.origin, m_SphereCasyRadius);//-------------角色头顶Pivot点所在的球形范围

        //Pivot是否和对象相交
        bool initiaIntersect = false;
        //是否碰撞到东西
        bool hitSomething = false;

        for (int i = 0; i < cols.Length; i++)
        {
            if (cols[i] != null && (!cols[i].isTrigger) &&
                  (!cols[i].gameObject.tag.Equals(m_DontClipTag) && !cols[i].gameObject.tag.Equals(m_DontClipTagWall)))
            {
                initiaIntersect = true;
                break;
            }
        }
        //如果相交对象时Collision
        if (initiaIntersect)
        {
            m_Ray.origin += m_Pivot.forward * m_SphereCasyRadius;
            //发射一条射线,并返回所有可碰撞的对象
            //注意：如果从一个球型体的内部到外部用光线投射，返回错误。
            m_Hits = Physics.RaycastAll(m_Ray, m_OriginaDist - m_SphereCasyRadius);//获取射线碰到的所有对象
        }
        else
        {
            //返回球形范围(射线扫描范围)碰撞到的所有对象信息
            m_Hits = Physics.SphereCastAll(m_Ray, m_SphereCasyRadius, m_OriginaDist + m_SphereCasyRadius);
        }

        //对所有射线碰到对象的距离进行排序
        Array.Sort(m_Hits, m_RayHitComparer);
        //最近的距离--初始是正无穷大
        float nearest = Mathf.Infinity;

        //得到最近的那个距离
        for (int i = 0; i < m_Hits.Length; i++)
        {
            if (m_Hits[i].distance < nearest && (!m_Hits[i].collider.isTrigger) &&
                   (!m_Hits[i].collider.gameObject.tag.Equals(m_DontClipTag) && !m_Hits[i].collider.gameObject.tag.Equals(m_DontClipTagWall)))
            {
                nearest = m_Hits[i].distance;
                m_TargetDist = -m_Pivot.InverseTransformPoint(m_Hits[i].point).z;
                hitSomething = true;
            }
        }

        if (hitSomething)
        {
            Debug.DrawRay(m_Ray.origin, m_Pivot.forward * (m_TargetDist + m_SphereCasyRadius) * -1, Color.red);
        }

        if (m_isSmooth)
        {
            m_CurrentDist = Mathf.SmoothDamp(m_CurrentDist, m_TargetDist,
                                ref m_MoveVelocity,
                                 m_CurrentDist > m_TargetDist ? m_ClipMoveTime : m_ReturnTime);
        }
        else
        {
            m_CurrentDist = m_TargetDist;
        }

        m_CurrentDist = Mathf.Clamp(m_CurrentDist, m_minDist, m_maxDist);
        if (m_isSmooth)
        {
            m_Cam.localPosition = Vector3.Lerp(m_Cam.localPosition, Vector3.forward * m_CurrentDist * -1, m_CamePosLerpValue);
        }
        else
        {
            m_Cam.localPosition = Vector3.forward * m_CurrentDist * -1;
        }

    }

    /// <summary>
    /// 比较两条射线的距离
    /// </summary>
    public class RayHitCompere : IComparer
    {
        public int Compare(object x1, object x2)
        {
            return ((RaycastHit)x1).distance.CompareTo(((RaycastHit)x2).distance);
        }
    }

    /// <summary>
    /// 开启平滑
    /// </summary>
    public void CameraSmoothOn()
    {
    }

    /// <summary>
    /// 关闭平滑
    /// </summary>
    public void CameraSmoothOff()
    {
    }
}


/*
Optimize your game with the profile analyzer(Unite Copenhagen 2019)
Tales from the optimization trenches(Unite Copenhagen 2019)
Squeezing Unity:Tips for raising performance(Unite Europe 2017)
Unity is evolving best practices(Unite Berlin 2018)
*/