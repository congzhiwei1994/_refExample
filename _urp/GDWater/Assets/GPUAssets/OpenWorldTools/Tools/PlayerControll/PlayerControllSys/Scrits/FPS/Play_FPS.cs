using UnityEngine;

public class Play_FPS : MonoBehaviour
{
    public FPSCamera _fpsCameraScript;
    public FPSMove _fpsMoveScript;

	void Start ()
    {
        _fpsCameraScript = transform.GetComponentInChildren<FPSCamera>();
        _fpsMoveScript = transform.GetComponentInChildren<FPSMove>();
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
    public void SetMoveValue(GameObject cameraObj, GameObject playObj, float moveSpeed, bool isMove, string clipIdle, string clipRun, Animator animtor, CharacterController chrc, Vector3 charCeneter)
    {
        if (cameraObj == null || playObj == null) { Debug.Log(cameraObj.name + "--为空 ||--" + playObj.name); return; }
        if (_fpsMoveScript)
            _fpsMoveScript.SetValue(cameraObj, playObj, moveSpeed, isMove, clipIdle, clipRun, animtor, chrc, charCeneter);
        else
            Debug.Log("_fpsMoveScript 不存在");
    }


    /// <summary>
    /// 旋转相关参数赋值
    /// </summary>
    /// <param name="newTarget"></param>
    /// <param name="xySpeed"></param>
    /// <param name="tiltRange"></param>
    /// <param name="offset"></param>
    /// <param name="rotateState"></param>
    public void SetRotateValue(Transform newTarget, Vector2 xySpeed, Vector2 tiltRange, bool rotateState)
    {
        _fpsCameraScript.SetValue(newTarget, xySpeed, tiltRange, rotateState);
    }

    public void OnUpdate()
    {
        if (_fpsMoveScript)
        {
            _fpsMoveScript.RuntimeUpdate();
        }

        if (_fpsCameraScript)
        {
            _fpsCameraScript.RuntimUpdate();
        }
    }
    public void OnLateUpdate()
    {    
        if (_fpsCameraScript)
        {

        }
        if (_fpsCameraScript)
        {
            _fpsCameraScript.RuntimLateUpdate();
        }
    }
}
