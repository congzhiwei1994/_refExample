using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "EjoyTA/PlayControll_Lock")]
public class LockCameraData : BaseControData
{
    public Vector3 charctCenter = new Vector3(0, 1, 0);
    public float offsetAngle = 30;

    public float rotateVminAngle = 0;
    public float rotateVmaxAngle = 65;

    public float currentZoomDis = 6;

    public float zoomMinDis = 1;
    public float zoomMaxDis = 20;
 
    public void SetLockCameraData(float newMoveSpeed, CharacterController newCharac,
                          Animator newAnim, string newIdleAnim, string newRunAnim,
                          string newFsmObj, string newFsm, string newFsmStand, string newFsmRun,
                          Vector3 newCharaCenter, float newOffsetAngle,
                        float newRotaMinAngle, float newRotaMaxAngle,
                         float newZoomDis, float newZoomMin, float newZoomMax)
     
    {
        moveSpeed = newMoveSpeed;
        characterController = newCharac;
        animtor = newAnim;
        idleAnimName = newIdleAnim;
        runAnimName = newRunAnim;
        fsmGameObject = newFsmObj;
        fsmName = newFsm;
        fsmEventStand = newFsmStand;
        fsmEventRun = newFsmRun;

        charctCenter = newCharaCenter;
        offsetAngle = newOffsetAngle;

        rotateVminAngle = newRotaMinAngle;
        rotateVmaxAngle = newRotaMaxAngle;

        currentZoomDis = newZoomDis;

        zoomMinDis = newZoomMin;
        zoomMaxDis = newZoomMax;
    }
}
