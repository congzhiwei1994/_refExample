using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Play_Lock : MonoBehaviour
{
    public LockCameraMove _lockCameMoveScript;
    public LockCamera _lockCameraScript;
    public BaseCameClip _cameClipScript;
    void Start()
    {
        _lockCameMoveScript = transform.GetComponentInChildren<LockCameraMove>();
        _lockCameraScript = transform.GetComponentInChildren<LockCamera>();
        _cameClipScript = transform.GetComponentInChildren<BaseCameClip>();
    }

    /// <summary>
    /// 设置移动参数
    /// </summary>
    /// <param name="cameraObj"></param>
    /// <param name="playObj"></param>
    /// <param name="moveSpeed"></param>
    /// <param name="isMove"></param>
    /// <param name="clipIdle"></param>
    /// <param name="clipRun"></param>
    /// <param name="animtor"></param>
    /// <param name="chrc"></param>
    /// <param name="charCeneter"></param>
    public void SetMoveValue(GameObject cameraObj, GameObject playObj, float moveSpeed, bool isMove, string clipIdle, string clipRun, Animator animtor, CharacterController chrc, Vector3 charCeneter)
    {
        //Debug.Log("锁视角移动数据赋值！！！");
        if (cameraObj == null || playObj == null) { Debug.Log(cameraObj.name + "--为空 ||--" + playObj.name); return; }
        if (_lockCameMoveScript)
            _lockCameMoveScript.SetValue(cameraObj, playObj, moveSpeed, isMove, clipIdle, clipRun, animtor, chrc, charCeneter);
        else
            Debug.Log("_fpsMoveScript 不存在");
    }

    /// <summary>
    /// 设置旋转参数
    /// </summary>
    /// <param name="newTarget"></param>
    /// <param name="newAngle"></param>
    /// <param name="angleClimp"></param>
    public void SetAngle(Transform newTarget, float newAngle,Vector2 angleClimp)
    {
        //Debug.Log("锁视角旋转数据赋值！！！");

        if (_lockCameraScript)
            _lockCameraScript.SetValue(newTarget,newAngle, angleClimp);
        else
            Debug.Log("_lockCameMoveScript 不存在");
    }

    /// <summary>
    /// 设置缩放参数
    /// </summary>
    /// <param name="currentDis"></param>
    /// <param name="disMin"></param>
    /// <param name="disMax"></param>
    public void SetZoomValue(float currentDis, float disMin, float disMax)
    {
        //Debug.Log("锁视角缩放数据赋值！！！");
        if (_cameClipScript)
            _cameClipScript.SetZoomValue(currentDis,disMin,disMax);
        else
            Debug.Log("_cameClipScript 不存在");
    }

    public void OnUpdate(float currentDis)
    {
        if (_lockCameMoveScript)
        {
            _lockCameMoveScript.RuntimeUpdate();
        }

        if (_lockCameraScript)
        {
            _lockCameraScript.RuntimUpdate();   
        }

        if (_cameClipScript)
        {
            _cameClipScript.SetOriDis(currentDis);
        }
    }
    public void OnLateUpdate()
    {
        if (_lockCameMoveScript)
        {

        }

        if (_lockCameraScript)
        {
            _lockCameraScript.RuntimLateUpdate();
        }
    }
}
