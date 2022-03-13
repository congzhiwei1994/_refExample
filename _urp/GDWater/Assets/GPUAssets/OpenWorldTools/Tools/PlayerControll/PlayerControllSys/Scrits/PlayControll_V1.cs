using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 操作控制类型
/// </summary>
public enum PlayControllType
{
    /// <summary>
    /// 第三人称
    /// </summary>
    TPS=0,
    /// <summary>
    /// 第一人称
    /// </summary>
    FPS,
    /// <summary>
    /// 锁视角
    /// </summary>
    LockCamera,
    /// <summary>
    /// RTS
    /// </summary>
    RTS,
}
public class PlayControll_V1 : MonoBehaviour
{
    [HideInInspector]
    public PlayControllType playControllType = PlayControllType.TPS;
    private PlayControllType lastPlayControllType = PlayControllType.TPS;
    public PlayControllType LastPType
    {
        get { return lastPlayControllType; }
    }
    [HideInInspector]
    public bool isPlayMaker = false;

   
    public GameObject joystickObj;
    public bool isMove = true;
    public bool isRotate = true;
    public bool isZoom = true;

    #region ----TPS 
    [HideInInspector]
    public GameObject playTPSObj;
    [HideInInspector]
    public GameObject cameraTPSObj;
    [HideInInspector]
    public TPSData TPSControData;

    public GameObject TPS;
    public Play_TPS playTpsScript;
    #endregion

    #region ----FPS
    [HideInInspector]
    public GameObject playFPSObj;
    [HideInInspector]
    public GameObject cameraFPSObj;
    [HideInInspector]
    public FPSData FPSControData;
    public GameObject FPS;
    public Play_FPS playFpsScript;

    #endregion

    #region ----LockCamera

    [HideInInspector]
    public GameObject playLockObj;
    [HideInInspector]
    public GameObject cameraLockObj;

    public GameObject LockCamera;
    public Play_Lock playLockCameraScript;
    [HideInInspector]
    public LockCameraData LockCameraControData;
    #endregion

    #region ----RTS
    public Transform RTSFloorObj;
    public GameObject RTS;
    public Play_RTS playRtsScript;
    [HideInInspector]
    public RTSData RTSControData;
    #endregion

    private void Awake()
    {
#if UNITY_EDITOR
        Application.runInBackground = true;
#endif

        #region ----TPS
        if (TPS == null)
            TPS = transform.Find("TPS").gameObject;

        if (playTPSObj && TPSControData)
        {
            TPSControData.animtor = playTPSObj.GetComponentInChildren<Animator>();

            TPSControData.characterController = playTPSObj.GetComponent<CharacterController>();

            if (TPSControData.characterController == null)
            {
                TPSControData.characterController = playTPSObj.AddComponent<CharacterController>();
                TPSControData.characterController.center = TPSControData.charctCenter;
            }
        }

        if (playTpsScript == null)
            playTpsScript = transform.GetComponentInChildren<Play_TPS>();
        #endregion

        #region ----FPS
        if (FPS == null)
            FPS = transform.Find("FPS").gameObject;

        if (playFPSObj && FPSControData)
        {
            FPSControData.animtor = playFPSObj.GetComponentInChildren<Animator>();

            FPSControData.characterController = playFPSObj.GetComponent<CharacterController>();

            if (FPSControData.characterController == null)
            {
                FPSControData.characterController = playFPSObj.AddComponent<CharacterController>();
                FPSControData.characterController.center = FPSControData.charctCenter;
            }
        }
        if (playFpsScript == null)
            playFpsScript = transform.GetComponentInChildren<Play_FPS>();

        #endregion

        #region ----LockCamera   
        try
        {
            if (LockCamera == null)
                LockCamera = transform.Find("LockCamera").gameObject;

            if (playLockObj && LockCameraControData)
            {
                LockCameraControData.animtor = playLockObj.GetComponentInChildren<Animator>();

                LockCameraControData.characterController = playLockObj.GetComponent<CharacterController>();

                if (LockCameraControData.characterController == null)
                {
                    LockCameraControData.characterController = playLockObj.AddComponent<CharacterController>();
                    LockCameraControData.characterController.center = LockCameraControData.charctCenter;
                }
            }

            if (playLockCameraScript == null)
                playLockCameraScript = transform.GetComponentInChildren<Play_Lock>();
        }
        catch (System.Exception e)
        {
            Debug.Log(e);
        }
        #endregion

        #region ----RTS
        try
        {
            if (RTS == null)
                RTS = transform.Find("RTS").gameObject;

            if (playRtsScript == null)
                playRtsScript = transform.GetComponentInChildren<Play_RTS>();
        }
        catch (System.Exception e)
        {
            Debug.Log(e);
        }
        #endregion

        joystickObj = GameObject.Find("JoyControll");
    }
    void Start()
    {
        OnInit();

        RTSDateUpdateMethod();
        LockDataUpdateMethod();
        FPSDateUpdateMethod();
        TPSDateUpdateMethod();
    }

    /// <summary>
    /// 激死四个模式对象
    /// </summary>
    void SetActiveFalse()
    {
        if (TPS && FPS && LockCamera && RTS)
        {
            if (TPS.activeInHierarchy != false)
            {
                TPS.SetActive(false);
            }
            if (FPS.activeInHierarchy != false)
            {
                FPS.SetActive(false);
            }
            if (LockCamera.activeInHierarchy != false)
            {
                LockCamera.SetActive(false);
            }
            if (RTS.activeInHierarchy != false)
            {
                RTS.SetActive(false);
            }
        }
        else
        {
            Debug.Log("TPS || FPS || LockCamera || RTS 为空");
        }
    }
    /// <summary>
    /// 设置对象激死激活
    /// </summary>
    /// <param name="tempObj"></param>
    /// <param name="tempState"></param>
    void SetObjState(GameObject tempObj, bool tempState)
    {
        if (tempObj == null)
        {
            Debug.Log("tempobj 不存在!!_");
            return;
        }
        if (tempObj.activeInHierarchy != tempState)
            tempObj.SetActive(tempState);
    }
    void OnInit()
    {
        if (playControllType == PlayControllType.TPS)
        {
            SetActiveFalse();
            //if (TPS.activeInHierarchy != true)
            //{
            //    TPS.SetActive(true);
            //}
            SetObjState(TPS, true);
            SetObjState(joystickObj, true);
        }
        else if (playControllType == PlayControllType.FPS)
        {
            SetActiveFalse();
            SetObjState(FPS, true);
            SetObjState(joystickObj, true);
        }
        else if (playControllType == PlayControllType.LockCamera)
        {
            SetActiveFalse();
            SetObjState(LockCamera, true);
            SetObjState(joystickObj, true);
        }
        else if (playControllType == PlayControllType.RTS)
        {
            SetActiveFalse();
            SetObjState(RTS, true);
            SetObjState(joystickObj, false);
        }
    }

    void Update()
    {
        #region ----新旧状态
        if (lastPlayControllType != playControllType)  //重新赋值
        {
            lastPlayControllType = playControllType;
            OnInit();

            //switch (lastPlayControllType)
            //{
            //    case PlayControllType.TPS:
            //        TPSDateUpdateMethod();
            //        break;
            //    case PlayControllType.FPS:
            //        FPSDateUpdateMethod();
            //        break;
            //    case PlayControllType.LockCamera:
            //        LockDataUpdateMethod();
            //        break;
            //    case PlayControllType.RTS:

            //        break;
            //    default:
            //        break;
            //}
            Debug.Log("更换模式");
        }
        #endregion 

        switch (playControllType)
        {
            case PlayControllType.TPS:
                TPSUpdateMethod();
                break;
            case PlayControllType.FPS:
                FPSUpdateMethod();
                break;
            case PlayControllType.LockCamera:
                LockCameraMethod();
                break;
            case PlayControllType.RTS:
                RTSUpdateMethod();
                break;
            default:
                break;
        }
    }

    #region ----RTS视角数据更新
    private void RTSDateUpdateMethod()
    {
        if (RTS && RTS.activeInHierarchy == true && playRtsScript&& RTSControData)
        {
            //float selfX = Mathf.Abs( playRtsScript.gameObject.transform.position.x);
            //float selfZ = Mathf.Abs(playRtsScript.gameObject.transform.position.z);
            if (RTSFloorObj)
            {
                playRtsScript.SetValue(RTSControData.moveSpeed, RTSControData.zoomSpeed,
              RTSControData.offSetAngle, RTSControData.currentZoomDis, new Vector2(RTSControData.boundX , RTSControData.boundY),
              new Vector2(RTSControData.rotateVminAngle, RTSControData.rotateVmaxAngle), new Vector2(RTSControData.zoomMin, RTSControData.zoomMax), RTSFloorObj.transform);
            }
            else
            {
                playRtsScript.SetValue(RTSControData.moveSpeed, RTSControData.zoomSpeed,
              RTSControData.offSetAngle, RTSControData.currentZoomDis, new Vector2(RTSControData.boundX, RTSControData.boundY),
              new Vector2(RTSControData.rotateVminAngle, RTSControData.rotateVmaxAngle), new Vector2(RTSControData.zoomMin, RTSControData.zoomMax));
            }     
        }
    }
    private void RTSUpdateMethod()
    {
        if (RTS && RTS.activeInHierarchy == true && playRtsScript)
        {
            RTSDateUpdateMethod();

            playRtsScript.OnUpdate(ref RTSControData.currentZoomDis);
        }
    }
    #endregion 

    #region ----锁视角数据更新

    /// <summary>
    /// 锁视角数据更新
    /// </summary>
    private void LockDataUpdateMethod()
    {
        if (LockCamera && LockCamera.activeInHierarchy == true && playLockCameraScript)
        {
            playLockCameraScript.SetMoveValue(cameraLockObj, playLockObj, LockCameraControData.moveSpeed, isMove,
                        LockCameraControData.idleAnimName, LockCameraControData.runAnimName, LockCameraControData.animtor,
                        LockCameraControData.characterController, LockCameraControData.charctCenter);

            Vector2 angleRange = new Vector2(LockCameraControData.rotateVminAngle, LockCameraControData.rotateVmaxAngle);
            playLockCameraScript.SetAngle(playLockObj.transform, LockCameraControData.offsetAngle, angleRange);

            playLockCameraScript.SetZoomValue(LockCameraControData.currentZoomDis, LockCameraControData.zoomMinDis, LockCameraControData.zoomMaxDis);
        }
    }
    private void LockCameraMethod()
    {
        if (LockCamera && LockCamera.activeInHierarchy == true && playLockCameraScript)
        {
            LockDataUpdateMethod();
            playLockCameraScript.OnUpdate(LockCameraControData.currentZoomDis);
        }
    }
    #endregion

    #region ----FPS视角数据更新
    private void FPSDateUpdateMethod()
    {
        if (FPS && FPS.activeInHierarchy == true && playFpsScript)
        {
            playFpsScript.SetMoveValue(cameraFPSObj, playFPSObj, FPSControData.moveSpeed, isMove,
                                        FPSControData.idleAnimName, FPSControData.runAnimName, FPSControData.animtor,
                                        FPSControData.characterController, FPSControData.charctCenter);

            Vector2 speed = new Vector2(FPSControData.rotateHoriSpeed, FPSControData.rotateVertSpeed);
            Vector2 angleRange = new Vector2(FPSControData.rotateVminAngle, FPSControData.rotateVmaxAngle);

            playFpsScript.SetRotateValue(playFPSObj.transform, speed, angleRange, isRotate);
        }
    }
    private void FPSUpdateMethod()
    {
        if (FPS && FPS.activeInHierarchy == true && playFpsScript)
        {
            FPSDateUpdateMethod();
            playFpsScript.OnUpdate();
        }
    }

    #endregion

    #region ----TPS数据更新

    private void TPSDateUpdateMethod()
    {
        if (TPS && TPS.activeInHierarchy == true && playTpsScript)
        {
            playTpsScript.SetMoveValue(cameraTPSObj, playTPSObj, TPSControData.moveSpeed, isMove,
                    TPSControData.idleAnimName, TPSControData.runAnimName, TPSControData.animtor,
                    TPSControData.characterController, TPSControData.charctCenter);

            Vector2 speed = new Vector2(TPSControData.rotateHoriSpeed, TPSControData.rotateVertSpeed);
            Vector2 angleRange = new Vector2(TPSControData.rotateVminAngle, TPSControData.rotateVmaxAngle);
            playTpsScript.SetRotateValue(playTPSObj.transform, speed, angleRange, TPSControData.pointOffset, isRotate);

#if UNITY_EDITOR
            playTpsScript.SetZoomValue(TPSControData.currentZoomDis, TPSControData.zoomMinDis, TPSControData.zoomMaxDis, TPSControData.zoomIsSmooth, isZoom);
#endif
#if UNITY_IPHONE || UNITY_ANDROID

                    //playTpsScript.SetZoomValue(TPSControData.currentZoomDis, TPSControData.zoomMinDis, TPSControData.zoomMaxDis, TPSControData.zoomIsSmooth, isZoom);
#endif    
        }
    }
    private void TPSUpdateMethod()
    {
        if (TPS && TPS.activeInHierarchy == true && playTpsScript)
        {
            TPSDateUpdateMethod();
            playTpsScript.OnUpdate(ref TPSControData.currentZoomDis);
        }
    }

    #endregion


    private void LateUpdate()
    {
        switch (playControllType)
        {
            case PlayControllType.TPS:
                if (TPS && TPS.activeInHierarchy == true && playTpsScript)
                {
                    playTpsScript.OnLateUpdate();
                }
                break;
            case PlayControllType.FPS:
                if (FPS && FPS.activeInHierarchy == true && playFpsScript)
                {
                    playFpsScript.OnLateUpdate();
                }
                break;
            case PlayControllType.LockCamera:
                if (LockCamera && LockCamera.activeInHierarchy == true && playLockCameraScript)
                {
                    playLockCameraScript.OnLateUpdate();
                }
                break;
            case PlayControllType.RTS:

                break;
            default:
                break;
        }
    }
}
