using UnityEngine;
public abstract class PivotBasedCameraRig : AbstractTargetFollower
{
    /// <summary>
    /// 相机
    /// </summary>
    protected Transform m_Cam;
    /// <summary>
    /// 相机注视点
    /// </summary>
    protected Transform m_Pivot;
    protected override void Awake() 
    {
        base.Awake();

        try
        {
            m_Cam = GetComponentInChildren<Camera>().transform;
            m_Pivot = m_Cam.parent;
        }
        catch (System.Exception e)
        {
            Debug.Log(e);
        }
    }
}
