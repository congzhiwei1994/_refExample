using UnityEngine;

/// <summary>
/// 目标跟随抽象基类
/// </summary>
public abstract class AbstractTargetFollower : MonoBehaviour
{
    /// <summary>
    /// 更新方式
    /// </summary>
    public enum UpdateType 
    {
        FixedUpdate,
        LateUpdate,
        Update,
        ManuaUpdate,
    }

    /// <summary>/// 更随目标/// </summary>
    [SerializeField]
    protected Transform m_Target;

    /// <summary> /// 自动寻找目标/// </summary>
    [SerializeField]
    protected bool m_AutoTargetRole = true;

    /// <summary>/// 更新方式/// </summary>
    [SerializeField]
    protected UpdateType m_UpdateType = UpdateType.Update;

    /// <summary>/// 目标刚体 /// </summary>
    protected Rigidbody m_TargetRigidbody;

    protected virtual void Awake() 
    {
        if (m_AutoTargetRole)
        {
            FindAndTargetPlayer();
        }
        if (m_Target == null)
        {
            Debug.LogFormat("m_Target=={0}为空!!!", m_Target);
            return;
        }
    }
    protected virtual void Start() 
    {
        //if (m_AutoTargetRole) 
        //{
        //    FindAndTargetPlayer();
        //}
        //if (m_Target == null) 
        //{
        //    Debug.LogFormat("m_Target=={0}为空!!!",m_Target);
        //    return; 
        //}
        m_TargetRigidbody = m_Target.GetComponent<Rigidbody>();
    }
    protected abstract void FollowTarget(float deltaTime);

    private void FixedUpdate() 
    {
        if(m_AutoTargetRole&&(m_Target==null)||!m_Target.gameObject.activeSelf)
        {
            FindAndTargetPlayer();
        }
        if (m_UpdateType == UpdateType.FixedUpdate) 
        {
            FollowTarget(Time.deltaTime);
        }
    }

    private void LateUpdate() 
    {
        if (m_AutoTargetRole && (m_Target == null) || !m_Target.gameObject.activeSelf) 
        {
            FindAndTargetPlayer();
        }
        if(m_UpdateType==UpdateType.LateUpdate)
        {
            FollowTarget(Time.deltaTime);
        }
    }

    private void Update()
    {
        if (m_AutoTargetRole && (m_Target == null) || !m_Target.gameObject.activeSelf)
        {
            FindAndTargetPlayer();
        }
        if (m_UpdateType == UpdateType.Update)
        {
            FollowTarget(Time.deltaTime);
        }
    }
    public void ManualUpdate()
    {

        if (m_AutoTargetRole && (m_Target == null || !m_Target.gameObject.activeSelf))
        {
            FindAndTargetPlayer();
        }
        if (m_UpdateType == UpdateType.ManuaUpdate)
        {
            FollowTarget(Time.deltaTime);
        }
    }

    /// <summary>
    /// 寻找目标
    /// </summary>
    public void FindAndTargetPlayer() 
    {
        var targetObj = GameObject.FindGameObjectWithTag("Player");
        if (targetObj) 
        {
            SetTarget(targetObj.transform);
        }
    }

    /// <summary>
    /// 更换目标
    /// </summary>
    /// <param name="newTransform"></param>
    public virtual void SetTarget(Transform newTransform) 
    {
        m_Target = newTransform;
    }

    /// <summary>
    /// 获取目标
    /// </summary>
    public Transform Target 
    {
        get { return m_Target; }
    }
}
