using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(PlayControll_V1))]
public class PlayControllEditor_V1 : Editor
{
    private string[] _toolbarChoices;
    private int _toolbarSelection = 0;
    private PlayControll_V1 _self;
    private int _enumSelection = 0;
    private BaseControData baseControData;

    private bool _isEditorPlay = false;
    bool allowSceneObjects;

    private TPSData idleTPSData;
    private FPSData idleFPSData;
    private LockCameraData idleLockData;
    private RTSData idleRTSData;
    private void OnEnable()
    {
        _self = (PlayControll_V1)target;

        idleTPSData = AssetDatabase.LoadAssetAtPath<TPSData>(DataStringPath.UniIdleDataPath+DataStringPath.IdleTPSData+DataStringPath.fileExr);
        idleFPSData = AssetDatabase.LoadAssetAtPath<FPSData>(DataStringPath.UniIdleDataPath + DataStringPath.IdleFPSData + DataStringPath.fileExr);
        idleLockData = AssetDatabase.LoadAssetAtPath<LockCameraData>(DataStringPath.UniIdleDataPath + DataStringPath.IdleLockData + DataStringPath.fileExr);
        idleRTSData = AssetDatabase.LoadAssetAtPath<RTSData>(DataStringPath.UniIdleDataPath + DataStringPath.IdleRTSData + DataStringPath.fileExr);
    }

    void OnDisable() 
    {
        EditorUtility.SetDirty(idleTPSData);
        EditorUtility.SetDirty(idleFPSData);
        EditorUtility.SetDirty(idleLockData);
        EditorUtility.SetDirty(idleRTSData);
    }
    public override void OnInspectorGUI()
    {
        if (Application.isEditor && Application.isPlaying)
        {
            _isEditorPlay = true;
        }
        else { _isEditorPlay = false; }
        allowSceneObjects = !EditorUtility.IsPersistent(_self);

        _self.playControllType = (PlayControllType)EditorGUILayout.EnumPopup("操作系统类型：", _self.playControllType, GUILayout.ExpandWidth(true));
        if(_self.playControllType != PlayControllType.RTS )
        _self.isPlayMaker = EditorGUILayout.Toggle("使用PM控制: ", _self.isPlayMaker);

        switch (_self.playControllType)
        {
            case PlayControllType.TPS:
                TPS_Method();
                break;
            case PlayControllType.FPS:
                FPS_Method();
                break;
            case PlayControllType.LockCamera:
                LockCamera_Method();
                break;
            case PlayControllType.RTS:
                RTS_Method();
                break;
            default:
                break;
        }

        if (GUI.changed)
        {
            EditorUtility.SetDirty(_self);
        }

        serializedObject.ApplyModifiedProperties();
        //base.OnInspectorGUI();
    }


    public delegate void Resoult();

    /// <summary>
    /// 重置数据
    /// </summary>
    /// <param name="btnClickResoult"></param>
    /// <param name="infoMessgae"></param>
    private void ResetDataNormal(EditorBtnResoult btnClickResoult, string infoMessgae)
    {
        EditorGUILayout.HelpBox(infoMessgae, MessageType.Info);

        EditorGUILayout.BeginHorizontal();
        GUILayout.Space(10);

        if (GUILayout.Button("保存为默认数据"))
        {
            if (EditorUtility.DisplayDialog("二次确认", "是否保存到到默认数据", "是", "我在想想"))
            {
                btnClickResoult.SaveSuccess();
            }
            else
            {
                btnClickResoult.SaveFailure();
            }
        }

        if (GUILayout.Button("恢复默认数据"))
        {
            if (EditorUtility.DisplayDialog("二次确认", "是否重置到默认数据", "是", "我在想想"))
            {
                btnClickResoult.ResSuccess();
            }
            else
            {
                btnClickResoult.ResFailure();
            }
        }
        EditorGUILayout.EndHorizontal();
    }

    TPSResetResoult tpsReset;
    FPSResetResoult fpsReset ;
    LockCameraResetResoult lockReset;
    RTSResetResoult rtsReset;

    /// <summary>
    /// RTS模式
    /// </summary>
    private void RTS_Method()
    {
        //string path = "Assets/ThirdParty/EjoyTA/PlayerControllSys/Data/RTS.asset";
        //RTSData rtsData = AssetDatabase.LoadAssetAtPath<RTSData>(path);

        RTSData rtsData = AssetDatabase.LoadAssetAtPath<RTSData>(DataStringPath.RuntimeDataPath + DataStringPath.RuntimeRTSData + DataStringPath.fileExr);

        rtsReset = new RTSResetResoult(rtsData, idleRTSData);

        _self.RTSFloorObj = (Transform)EditorGUILayout.ObjectField("注视地面: ", _self.RTSFloorObj, typeof(Transform), allowSceneObjects);
        _self.RTS = (GameObject)EditorGUILayout.ObjectField("Camera: ", _self.RTS, typeof(GameObject), allowSceneObjects);  
        {
            EditorGUILayout.HelpBox("RTS模式相机已固定，注视地面主要用作相机注视参考面，可自己手动指定\n代码默认使用一个虚拟地面", MessageType.Warning);
        }

        if (rtsData)
        {
            showNotificationIndex = 0;
            _toolbarChoices = new string[] { "Movement", "Rotation", "Zoom" };
            _toolbarSelection = GUILayout.Toolbar(_toolbarSelection, _toolbarChoices);
            EditorGUILayout.ObjectField("数据： ", rtsData, typeof(ScriptableObject), true);

            if (_toolbarSelection == 0)
            {

                rtsData.moveSpeed = EditorGUILayout.Slider("移动速度： ", rtsData.moveSpeed, 1, 20);

                rtsData.boundX = EditorGUILayout.Slider("可移动长度: ", rtsData.boundX, 0, 90);
                rtsData.boundY = EditorGUILayout.Slider("可移动宽度: ", rtsData.boundY, 0, 90);

                rtsData.boundX = Mathf.Round(rtsData.boundX);
                rtsData.boundY = Mathf.Round(rtsData.boundY);

                //if (_self.RTS)   //--可移动范围基于相机所在位置_+指定范围_
                //{
                //    rtsData.boundX = Mathf.Abs(_self.RTS.transform.position.x) + rtsData.boundX;
                //    rtsData.boundY = Mathf.Abs(_self.RTS.transform.position.z) + rtsData.boundY;
                //}


                _self.isMove = EditorGUILayout.Toggle("是否移动： ", _self.isMove);
                EditorGUILayout.HelpBox("当前是移动设置", MessageType.Info);
            }
            else if (_toolbarSelection == 1)
            {
                rtsData.offSetAngle = EditorGUILayout.FloatField("初始角度： ", rtsData.offSetAngle);
                rtsData.rotateVminAngle = EditorGUILayout.Slider("竖直旋转最小: ", rtsData.rotateVminAngle, -90, 90);
                rtsData.rotateVmaxAngle = EditorGUILayout.Slider("竖直旋转最大: ", rtsData.rotateVmaxAngle, -90, 90);

                rtsData.rotateVminAngle = Mathf.Round(rtsData.rotateVminAngle);
                rtsData.rotateVmaxAngle = Mathf.Round(rtsData.rotateVmaxAngle);

                EditorGUILayout.HelpBox("注意！！以上参数只作为编辑器下调节角度作用，实际出包不会有任何旋转功能！！", MessageType.Error);
            }
            else if (_toolbarSelection == 2)
            {
                rtsData.currentZoomDis = EditorGUILayout.FloatField("初始距离： ", rtsData.currentZoomDis);

                rtsData.zoomMin = EditorGUILayout.Slider("缩放最小值: ", rtsData.zoomMin, 0, 90);
                rtsData.zoomMax = EditorGUILayout.Slider("缩放最大值: ", rtsData.zoomMax, 0, 90);

                rtsData.zoomMin = Mathf.Round(rtsData.zoomMin);
                rtsData.zoomMax = Mathf.Round(rtsData.zoomMax);

                EditorGUILayout.HelpBox("注意！！以上参数只作为编辑器下调节距离作用，实际出包不会有任何缩放功能！！", MessageType.Error);
            }
            else if (_toolbarSelection == 3)
            {
                EditorGUILayout.HelpBox("当前是跳跃设置", MessageType.Info);
            }


            EditorUtility.SetDirty(rtsData);

            _self.RTSControData = rtsData;
        }

        ResetDataNormal(rtsReset, "当前是RTS");
    }

    /// <summary>
    /// 锁视角模式
    /// </summary>
    private void LockCamera_Method()
    {
        LockCameraData lockCameraData = AssetDatabase.LoadAssetAtPath<LockCameraData>(DataStringPath.RuntimeDataPath + DataStringPath.RuntimeLockData + DataStringPath.fileExr);

        lockReset = new LockCameraResetResoult(lockCameraData, idleLockData);

        _self.playLockObj = (GameObject)EditorGUILayout.ObjectField("Target: ", _self.playLockObj, typeof(GameObject), allowSceneObjects);
        _self.cameraLockObj = (GameObject)EditorGUILayout.ObjectField("Camera: ", _self.cameraLockObj, typeof(GameObject), allowSceneObjects);
        if (_self.playLockObj == null || _self.cameraLockObj == null)
        {
            EditorGUILayout.HelpBox("请指定目标角色对象以及控制相机对象", MessageType.Error);
        }
        if (lockCameraData)
        {
            showNotificationIndex = 0;
            _toolbarChoices = new string[] { "Movement", "Rotation", "Zoom", "Jump" };
            _toolbarSelection = GUILayout.Toolbar(_toolbarSelection, _toolbarChoices);
            EditorGUILayout.ObjectField("数据： ", lockCameraData, typeof(ScriptableObject), true);

            if (_toolbarSelection == 0)
            {
                if (_self.isPlayMaker == true)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.green;

                    lockCameraData.fsmGameObject = EditorGUILayout.TextField("FSM所在对象： ", lockCameraData.fsmGameObject);
                    lockCameraData.fsmName = EditorGUILayout.TextField("FSM节点对象: ", lockCameraData.fsmName);
                    lockCameraData.fsmEventStand = EditorGUILayout.TextField("FSM待机事件: ", lockCameraData.fsmEventStand);
                    lockCameraData.fsmEventRun = EditorGUILayout.TextField("FSM跑步事件: ", lockCameraData.fsmEventRun/*, fontStyle*/);
                    //EditorGUI.indentLevel--;

                    GUI.backgroundColor = restoryGUIBgColor;
                }

                lockCameraData.moveSpeed = EditorGUILayout.Slider("移动速度： ", lockCameraData.moveSpeed, 1, 20);

                lockCameraData.idleAnimName = EditorGUILayout.TextField("待机动作: ", lockCameraData.idleAnimName);
                lockCameraData.runAnimName = EditorGUILayout.TextField("跑步动作： ", lockCameraData.runAnimName);
                lockCameraData.animtor = (Animator)EditorGUILayout.ObjectField("动画类型：", lockCameraData.animtor, typeof(Animator), true);
                lockCameraData.characterController = (CharacterController)EditorGUILayout.ObjectField("移动控制器：", lockCameraData.characterController, typeof(CharacterController), true);
                if (_isEditorPlay)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.red;
                    EditorGUILayout.TextField("运行中无法修改角色控制器的中心，请退出运行在修改！----当前控制器高度  " + lockCameraData.charctCenter.y.ToString());
                    GUI.backgroundColor = restoryGUIBgColor;
                }
                else
                {
                    lockCameraData.charctCenter = EditorGUILayout.Vector3Field("控制器中心点：", lockCameraData.charctCenter);
                }


                _self.isMove = EditorGUILayout.Toggle("是否移动： ", _self.isMove);
                EditorGUILayout.HelpBox("当前是移动设置", MessageType.Info);
            }
            else if (_toolbarSelection == 1)
            {
                lockCameraData.offsetAngle = EditorGUILayout.FloatField("初始角度： ", lockCameraData.offsetAngle);
                lockCameraData.rotateVminAngle = EditorGUILayout.Slider("竖直旋转最小: ", lockCameraData.rotateVminAngle, -90, 90);
                lockCameraData.rotateVmaxAngle = EditorGUILayout.Slider("竖直旋转最大: ", lockCameraData.rotateVmaxAngle, -90, 90);

                lockCameraData.rotateVminAngle = Mathf.Round(lockCameraData.rotateVminAngle);
                lockCameraData.rotateVmaxAngle = Mathf.Round(lockCameraData.rotateVmaxAngle);

                EditorGUILayout.HelpBox("注意！！以上参数只作为编辑器下调节角度作用，实际出包不会有任何旋转功能！！", MessageType.Error);
            }
            else if (_toolbarSelection == 2)
            {
                lockCameraData.currentZoomDis = EditorGUILayout.FloatField("初始距离： ", lockCameraData.currentZoomDis);

                lockCameraData.zoomMinDis = EditorGUILayout.Slider("缩放最小值: ", lockCameraData.zoomMinDis, 0, 90);
                lockCameraData.zoomMaxDis = EditorGUILayout.Slider("缩放最大值: ", lockCameraData.zoomMaxDis, 0, 90);

                lockCameraData.zoomMinDis = Mathf.Round(lockCameraData.zoomMinDis);
                lockCameraData.zoomMaxDis = Mathf.Round(lockCameraData.zoomMaxDis);

                EditorGUILayout.HelpBox("注意！！以上参数只作为编辑器下调节距离作用，实际出包不会有任何缩放功能！！", MessageType.Error);
            }
            else if (_toolbarSelection == 3)
            {
                EditorGUILayout.HelpBox("当前是跳跃设置", MessageType.Info);
            }


            EditorUtility.SetDirty(lockCameraData);

            _self.LockCameraControData = lockCameraData;
        }
        ResetDataNormal(lockReset, "当前是锁视角");
    }

    /// <summary>
    /// FPS模式
    /// </summary>
    private void FPS_Method()
    {

        FPSData fps = AssetDatabase.LoadAssetAtPath<FPSData>(DataStringPath.RuntimeDataPath + DataStringPath.RuntimeFPSData + DataStringPath.fileExr);

        fpsReset = new FPSResetResoult(fps, idleFPSData);

        _self.playFPSObj = (GameObject)EditorGUILayout.ObjectField("Target: ", _self.playFPSObj, typeof(GameObject), allowSceneObjects);
        _self.cameraFPSObj = (GameObject)EditorGUILayout.ObjectField("Camera: ", _self.cameraFPSObj, typeof(GameObject), allowSceneObjects);

        if (_self.playFPSObj == null || _self.cameraFPSObj == null)
        {
            EditorGUILayout.HelpBox("请指定目标角色对象以及控制相机对象", MessageType.Error);
        }

        if (fps)
        {
            showNotificationIndex = 0;
            _toolbarChoices = new string[] { "Movement", "Rotation", "Jump" };
            _toolbarSelection = GUILayout.Toolbar(_toolbarSelection, _toolbarChoices);
            EditorGUILayout.ObjectField("数据： ", fps, typeof(ScriptableObject), true);

            if (_toolbarSelection == 0)
            {
                if (_self.isPlayMaker == true)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.green;

                    fps.fsmGameObject = EditorGUILayout.TextField("FSM所在对象： ", fps.fsmGameObject);
                    fps.fsmName = EditorGUILayout.TextField("FSM节点对象: ", fps.fsmName);
                    fps.fsmEventStand = EditorGUILayout.TextField("FSM待机事件: ", fps.fsmEventStand);
                    fps.fsmEventRun = EditorGUILayout.TextField("FSM跑步事件: ", fps.fsmEventRun/*, fontStyle*/);
                    //EditorGUI.indentLevel--;

                    GUI.backgroundColor = restoryGUIBgColor;
                }

                fps.moveSpeed = EditorGUILayout.Slider("移动速度： ", fps.moveSpeed, 1, 20);

                fps.idleAnimName = EditorGUILayout.TextField("待机动作: ", fps.idleAnimName);
                fps.runAnimName = EditorGUILayout.TextField("跑步动作： ", fps.runAnimName);
                fps.animtor = (Animator)EditorGUILayout.ObjectField("动画类型：", fps.animtor, typeof(Animator), true);
                fps.characterController = (CharacterController)EditorGUILayout.ObjectField("移动控制器：", fps.characterController, typeof(CharacterController), true);
                if (_isEditorPlay)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.red;
                    EditorGUILayout.TextField("运行中无法修改角色控制器的中心，请退出运行在修改！----当前控制器高度  " + fps.charctCenter.y.ToString());
                    GUI.backgroundColor = restoryGUIBgColor;
                }
                else
                {
                    fps.charctCenter = EditorGUILayout.Vector3Field("控制器中心点：", fps.charctCenter);
                }


                _self.isMove = EditorGUILayout.Toggle("是否移动： ", _self.isMove);
                EditorGUILayout.HelpBox("当前是移动设置", MessageType.Info);
            }
            else if (_toolbarSelection == 1)
            {
                fps.rotateHoriSpeed = EditorGUILayout.Slider("水平旋转速度： ", fps.rotateHoriSpeed, 1, 20);
                fps.rotateVertSpeed = EditorGUILayout.Slider("竖直旋转速度： ", fps.rotateVertSpeed, 1, 20);


                //tps.currentRotate = EditorGUILayout.Vector2Field("当前XY旋转： ", tps.currentRotate);

                fps.rotateVminAngle = EditorGUILayout.Slider("竖直旋转最小: ", fps.rotateVminAngle, -90, 90);
                fps.rotateVmaxAngle = EditorGUILayout.Slider("竖直旋转最大: ", fps.rotateVmaxAngle, -90, 90);

                fps.rotateVminAngle = Mathf.Round(fps.rotateVminAngle);
                fps.rotateVmaxAngle = Mathf.Round(fps.rotateVmaxAngle);

                _self.isRotate = EditorGUILayout.Toggle("是否旋转： ", _self.isRotate);

                EditorGUILayout.HelpBox("当前是旋转设置", MessageType.Info);
            }
            else if (_toolbarSelection == 2)
            {
                EditorGUILayout.HelpBox("当前是跳跃设置", MessageType.Info);
            }


            EditorUtility.SetDirty(fps);

            _self.FPSControData = fps;
        }

        ResetDataNormal(fpsReset, "当前是第一人称视角");
    }

    private int animSelection = 0;

    int showNotificationIndex = 0;
    /// <summary>
    /// TPS模式
    /// </summary>
    private void TPS_Method()
    {
        //string path = "Assets/ThirdParty/EjoyTA/PlayerControllSys/Data/TPS.asset";
        TPSData tps = AssetDatabase.LoadAssetAtPath<TPSData>(DataStringPath.RuntimeDataPath+DataStringPath.RuntimeTPSData+DataStringPath.fileExr);

        tpsReset = new TPSResetResoult(tps,idleTPSData);

        _self.playTPSObj = (GameObject)EditorGUILayout.ObjectField("Target: ", _self.playTPSObj, typeof(GameObject), allowSceneObjects);
        _self.cameraTPSObj = (GameObject)EditorGUILayout.ObjectField("Camera: ", _self.cameraTPSObj, typeof(GameObject), allowSceneObjects);
        if (_self.playTPSObj == null || _self.cameraTPSObj == null)
        {
            EditorGUILayout.HelpBox("请指定目标角色对象以及控制相机对象", MessageType.Error);
        }

        if (tps)
        {
            showNotificationIndex = 0;
            _toolbarChoices = new string[] { "Movement", "Rotation", "Zoom", "Jump" };
            _toolbarSelection = GUILayout.Toolbar(_toolbarSelection, _toolbarChoices);

            EditorGUILayout.ObjectField("数据： ", tps, typeof(ScriptableObject), true);

            if (_toolbarSelection == 0)
            {
                if (_self.isPlayMaker == true)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.green;
                    //GUIStyle fontStyle = new GUIStyle();
                    //fontStyle.normal.background = null;
                    //fontStyle.normal.textColor = Color.red;

                    //EditorGUI.indentLevel++; //--缩进
                    tps.fsmGameObject = EditorGUILayout.TextField("FSM所在对象： ", tps.fsmGameObject);
                    tps.fsmName = EditorGUILayout.TextField("FSM节点对象: ", tps.fsmName);
                    tps.fsmEventStand = EditorGUILayout.TextField("FSM待机事件: ", tps.fsmEventStand);
                    tps.fsmEventRun = EditorGUILayout.TextField("FSM跑步事件: ", tps.fsmEventRun/*, fontStyle*/);
                    //EditorGUI.indentLevel--;

                    GUI.backgroundColor = restoryGUIBgColor;
                }

                tps.moveSpeed = EditorGUILayout.Slider("移动速度： ", tps.moveSpeed, 1, 20);

                tps.idleAnimName = EditorGUILayout.TextField("待机动作: ", tps.idleAnimName);
                tps.runAnimName = EditorGUILayout.TextField("跑步动作： ", tps.runAnimName);
                tps.animtor = (Animator)EditorGUILayout.ObjectField("动画类型：", tps.animtor, typeof(Animator), true);
                tps.characterController = (CharacterController)EditorGUILayout.ObjectField("移动控制器：", tps.characterController, typeof(CharacterController), true);
                if (_isEditorPlay)
                {
                    Color restoryGUIBgColor = GUI.backgroundColor;

                    GUI.backgroundColor = Color.red;
                    EditorGUILayout.TextField("运行中无法修改角色控制器的中心，请退出运行在修改！----当前控制器高度  " + tps.charctCenter.y.ToString());
                    GUI.backgroundColor = restoryGUIBgColor;
                }
                else
                {
                    tps.charctCenter = EditorGUILayout.Vector3Field("控制器中心点：", tps.charctCenter);
                }


                _self.isMove = EditorGUILayout.Toggle("是否移动： ", _self.isMove);
                EditorGUILayout.HelpBox("当前是移动设置", MessageType.Info);
            }
            else if (_toolbarSelection == 1)
            {
                tps.rotateHoriSpeed = EditorGUILayout.Slider("水平旋转速度： ", tps.rotateHoriSpeed, 1, 20);
                tps.rotateVertSpeed = EditorGUILayout.Slider("竖直旋转速度： ", tps.rotateVertSpeed, 1, 20);


                //tps.currentRotate = EditorGUILayout.Vector2Field("当前XY旋转： ", tps.currentRotate);

                tps.rotateVminAngle = EditorGUILayout.Slider("竖直旋转最小: ", tps.rotateVminAngle, -90, 90);
                tps.rotateVmaxAngle = EditorGUILayout.Slider("竖直旋转最大: ", tps.rotateVmaxAngle, -90, 90);

                tps.rotateVminAngle = Mathf.Round(tps.rotateVminAngle);
                tps.rotateVmaxAngle = Mathf.Round(tps.rotateVmaxAngle);

                tps.pointOffset = EditorGUILayout.Vector3Field("注视偏移：", tps.pointOffset);

                _self.isRotate = EditorGUILayout.Toggle("是否旋转： ", _self.isRotate);

                EditorGUILayout.HelpBox("当前是旋转设置", MessageType.Info);
            }
            else if (_toolbarSelection == 2)
            {
                tps.currentZoomDis = EditorGUILayout.FloatField("初始距离： ", tps.currentZoomDis);

                tps.zoomMinDis = EditorGUILayout.Slider("缩放最小值: ", tps.zoomMinDis, 0, 90);
                tps.zoomMaxDis = EditorGUILayout.Slider("缩放最大值: ", tps.zoomMaxDis, 0, 90);

                tps.zoomMinDis = Mathf.Round(tps.zoomMinDis);
                tps.zoomMaxDis = Mathf.Round(tps.zoomMaxDis);
                tps.zoomIsSmooth = EditorGUILayout.Toggle("是否差值： ", tps.zoomIsSmooth);

                _self.isZoom = EditorGUILayout.Toggle("是否缩放： ", _self.isZoom);

                EditorGUILayout.HelpBox("当前是缩放设置", MessageType.Info);
            }
            else if (_toolbarSelection == 3)
            {
                EditorGUILayout.HelpBox("当前是跳跃设置", MessageType.Info);
            }


            EditorUtility.SetDirty(tps);

            _self.TPSControData = tps;

            ResetDataNormal(tpsReset, "当前是第三人称视角");
        }
        else
        {
            EditorGUILayout.HelpBox("TPS 数据文件不存在,请创建文件,并放在指定目录\n --Assets/ThirdParty/EjoyTA/PlayerControllSys/Data/", MessageType.Error);

            //if (showNotificationIndex<=0)
            //{
            //    EditorWindow editorWindow = new EditorWindow();
            //    editorWindow.ShowNotification(new GUIContent("弹窗消息提示样式!!!"));
            //    showNotificationIndex++;
            //}
        }
    }

}

#region ----重置数据实现

/// <summary>
/// 重置数据回调
/// </summary>
public interface EditorBtnResoult
{
    /// <summary>
    /// 恢复默认成功
    /// </summary>
    void ResSuccess();
    /// <summary>
    /// 恢复默认失败
    /// </summary>
    void ResFailure();

    /// <summary>
    /// 保存成功
    /// </summary>
    void SaveSuccess();
    /// <summary>
    /// 保存失败
    /// </summary>
    void SaveFailure();
}


public class TPSResetResoult : EditorBtnResoult
{
    TPSData runtimData;
    TPSData idleData;
    public TPSResetResoult() { }
    public TPSResetResoult(TPSData newRunData,TPSData newIdleData) 
    {
        if (newRunData == null || newIdleData == null)
        {
            Debug.LogError("实时数据和默认数据文件不存在_！！请检查");
            return;
        }
        else 
        {
            runtimData = newRunData;
            idleData = newIdleData;
        }
    }
    public void ResFailure()
    {
        Debug.Log("TPSResetResoult_  " + "重置数据取消");
    }

    public void ResSuccess()
    {
        
        runtimData.SetTPSData(idleData.moveSpeed,idleData.characterController,idleData.animtor,idleData.idleAnimName,idleData.runAnimName,
                                idleData.fsmGameObject,idleData.fsmName,idleData.fsmEventStand,idleData.fsmEventRun,
                                idleData.pointOffset,idleData.charctCenter,idleData.rotateHoriSpeed,idleData.rotateVertSpeed,
                                idleData.rotateVminAngle,idleData.rotateVmaxAngle,idleData.currentZoomDis,idleData.zoomMinDis,idleData.zoomMaxDis,
                                idleData.zoomIsSmooth);
        Debug.Log("TPSResetResoult_  " + "重置数据成功");
    }
    public void SaveSuccess()
    {
       
        idleData.SetTPSData(runtimData.moveSpeed, runtimData.characterController, runtimData.animtor, runtimData.idleAnimName, runtimData.runAnimName,
                             runtimData.fsmGameObject, runtimData.fsmName, runtimData.fsmEventStand, runtimData.fsmEventRun,
                             runtimData.pointOffset, runtimData.charctCenter, runtimData.rotateHoriSpeed, runtimData.rotateVertSpeed,
                             runtimData.rotateVminAngle, runtimData.rotateVmaxAngle, runtimData.currentZoomDis, runtimData.zoomMinDis, runtimData.zoomMaxDis,
                             runtimData.zoomIsSmooth);

        Debug.Log("TPSResetResoult_  " + "保存数据成功");
    }
    public void SaveFailure()
    {
        Debug.Log("TPSResetResoult_  " + "保存数据失败");
    }
}


public class FPSResetResoult : EditorBtnResoult
{
    FPSData runtimData;
    FPSData idleData;
    public FPSResetResoult() { }
    public FPSResetResoult(FPSData newRunData, FPSData newIdleData) 
    {
        if (newRunData == null || newIdleData == null)
        {
            Debug.LogError("实时数据和默认数据文件不存在_！！请检查");
            return;
        }
        else 
        {
            runtimData = newRunData;
            idleData = newIdleData;
        }
    }

    public void ResFailure()
    {
        Debug.Log("FPSResetResoult_  " + "重置数据取消");
    }

    public void ResSuccess()
    {
       
        runtimData.SetFPSData(idleData.moveSpeed, idleData.characterController, idleData.animtor, idleData.idleAnimName, idleData.runAnimName,
                            idleData.fsmGameObject, idleData.fsmName, idleData.fsmEventStand, idleData.fsmEventRun,
                            idleData.charctCenter, idleData.rotateHoriSpeed, idleData.rotateVertSpeed,
                            idleData.rotateVminAngle, idleData.rotateVmaxAngle);
        Debug.Log("FPSResetResoult_  " + "重置数据成功");
    }

    public void SaveSuccess()
    {
      
        idleData.SetFPSData(runtimData.moveSpeed, runtimData.characterController, runtimData.animtor, runtimData.idleAnimName, runtimData.runAnimName,
                           runtimData.fsmGameObject, runtimData.fsmName, runtimData.fsmEventStand, runtimData.fsmEventRun,
                           runtimData.charctCenter, runtimData.rotateHoriSpeed, runtimData.rotateVertSpeed,
                           runtimData.rotateVminAngle, runtimData.rotateVmaxAngle);
        Debug.Log("FPSResetResoult_  " + "保存数据成功");
    }
    public void SaveFailure()
    {
        Debug.Log("FPSResetResoult_  " + "保存数据失败");
    }
}

public class RTSResetResoult : EditorBtnResoult
{
    RTSData runtimData;
    RTSData idleData;
    public RTSResetResoult() { }
    public RTSResetResoult(RTSData newRunData, RTSData newIdleData) 
    {
        if (newRunData == null || newIdleData == null)
        {
            Debug.LogError("实时数据和默认数据文件不存在_！！请检查");
            return;
        }
        else 
        {
            runtimData = newRunData;
            idleData = newIdleData;
        }
    }


    public void ResFailure()
    {
        Debug.Log("RTSResetResoult_  " + "重置数据取消");
    }

    public void ResSuccess()
    {
        runtimData.SetRTSData(idleData.moveSpeed,idleData.offSetAngle,
                           idleData.rotateVminAngle, idleData.rotateVmaxAngle, idleData.panelYValue,idleData.currentZoomDis,idleData.zoomSpeed,idleData.zoomMin,idleData.zoomMax,idleData.boundX,idleData.boundY);

        Debug.Log("RTSResetResoult_  " + "重置数据成功");
    }

    public void SaveSuccess()
    {
        idleData.SetRTSData(runtimData.moveSpeed, runtimData.offSetAngle,
                          runtimData.rotateVminAngle, runtimData.rotateVmaxAngle, runtimData.panelYValue, runtimData.currentZoomDis, runtimData.zoomSpeed, runtimData.zoomMin, runtimData.zoomMax, runtimData.boundX, runtimData.boundY);
        Debug.Log("RTSResetResoult_  " + "保存数据成功");
    }
    public void SaveFailure()
    {
        Debug.Log("RTSResetResoult_  " + "保存数据失败");
    }
}


public class LockCameraResetResoult : EditorBtnResoult
{

    LockCameraData runtimData;
    LockCameraData idleData;
    public LockCameraResetResoult() { }
    public LockCameraResetResoult(LockCameraData newRunData, LockCameraData newIdleData) 
    {
        if (newRunData == null || newIdleData == null)
        {
            Debug.LogError("实时数据和默认数据文件不存在_！！请检查");
            return;
        }
        else 
        {
            runtimData = newRunData;
            idleData = newIdleData;
        }
    }
    public void ResFailure()
    {
        Debug.Log("LockCameraResetResoult_  " + "重置数据成功");
    }

    public void ResSuccess()
    {
        runtimData.SetLockCameraData(idleData.moveSpeed,idleData.characterController,idleData.animtor,idleData.idleAnimName,idleData.runAnimName,
            idleData.fsmGameObject,idleData.fsmName,idleData.fsmEventStand,idleData.fsmEventRun,
            idleData.charctCenter,idleData.offsetAngle, idleData.rotateVminAngle,idleData.rotateVmaxAngle, 
            idleData.currentZoomDis, runtimData.zoomMinDis, runtimData.zoomMaxDis);

        Debug.Log("LockCameraResetResoult_  " + "重置数据成功");
    }

    public void SaveSuccess()
    {
        idleData.SetLockCameraData(runtimData.moveSpeed, runtimData.characterController, runtimData.animtor, runtimData.idleAnimName, runtimData.runAnimName,
                   runtimData.fsmGameObject, runtimData.fsmName, runtimData.fsmEventStand, runtimData.fsmEventRun,
                   runtimData.charctCenter,runtimData.offsetAngle,
                   runtimData.rotateVminAngle, runtimData.rotateVmaxAngle, runtimData.currentZoomDis, runtimData.zoomMinDis, runtimData.zoomMaxDis);

        Debug.Log("LockCameraResetResoult_  " + "保存数据成功");
    }
    public void SaveFailure()
    {
        Debug.Log("LockCameraResetResoult_  " + "保存数据失败");
    }
}
#endregion