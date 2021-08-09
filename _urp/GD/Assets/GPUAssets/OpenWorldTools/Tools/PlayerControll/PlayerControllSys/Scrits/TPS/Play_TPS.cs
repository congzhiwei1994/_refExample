using UnityEngine;

public class Play_TPS : MonoBehaviour
{
    public TPSMove _tpsMoveScript;
    public TPSCamera _tpsCameraScript;
    public BaseCameClip _baseCameraClip;
    void Start ()
    {
        _tpsCameraScript = transform.GetComponentInChildren<TPSCamera>();
        _baseCameraClip = transform.GetComponentInChildren<BaseCameClip>();
        _tpsMoveScript = transform.GetComponentInChildren<TPSMove>();
    }


    public void OnUpdate(ref float currentDis)
    {
        if (_tpsMoveScript)                            //player move
        {
            _tpsMoveScript.RuntimeUpdate();
        }

        if (_tpsCameraScript)                            //camera move
        {
            _tpsCameraScript.RuntimUpdate();
        }

        if (_baseCameraClip)                            //cameraclip 
        {
            _baseCameraClip.RuntimeUpdate(ref currentDis);
        }
    }

    public void OnLateUpdate()
    {
        if (_tpsCameraScript)
        {
            _tpsCameraScript.RuntimLateUpdate();
        }
    }

    public void SetMoveValue(GameObject cameraObj,GameObject playObj,float moveSpeed,bool isMove)
    {
        if (cameraObj ==null || playObj ==null) { Debug.Log(cameraObj.name +"--为空 ||--"+ playObj.name ); return; }

        _tpsMoveScript.SetValue(cameraObj, playObj, moveSpeed, isMove);
    }

    /// <summary>
    /// 移动相关参数赋值
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
    public void SetMoveValue(GameObject cameraObj, GameObject playObj, float moveSpeed, bool isMove,string clipIdle,string clipRun,Animator animtor,CharacterController chrc,Vector3 charCeneter)
    {
        if (cameraObj == null || playObj == null) { Debug.Log(cameraObj.name + "--为空 ||--" + playObj.name); return; }

        _tpsMoveScript.SetValue(cameraObj, playObj, moveSpeed, isMove, clipIdle, clipRun, animtor, chrc,charCeneter);
    }

    /// <summary>
    /// 旋转相关参数赋值
    /// </summary>
    /// <param name="newTarget"></param>
    /// <param name="xySpeed"></param>
    /// <param name="tiltRange"></param>
    /// <param name="offset"></param>
    /// <param name="rotateState"></param>
    public void SetRotateValue(Transform newTarget,Vector2 xySpeed,Vector2 tiltRange,Vector3 offset, bool rotateState)
    {
        _tpsCameraScript.SetValue(newTarget,xySpeed,tiltRange,offset,rotateState);
    }

    /// <summary>
    /// 缩放相关参数赋值
    /// </summary>
    /// <param name="currentDis"></param>
    /// <param name="disMin"></param>
    /// <param name="disMax"></param>
    /// <param name="newState"></param>
    /// <param name="isZoom"></param>
    public void SetZoomValue(float currentDis,float disMin,float disMax,bool newState,bool isZoom)
    {
        _baseCameraClip.SetZoomValue(currentDis,disMin,disMax,newState, isZoom);
    }
}
