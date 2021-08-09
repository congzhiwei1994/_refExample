using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "EjoyTA/PlayControll_FPS")]
public class FPSData : BaseControData
{
    public Vector3 charctCenter = new Vector3(0, 1, 0);

    public float rotateHoriSpeed = 2;
    public float rotateVertSpeed = 2;

    public float rotateVminAngle = 0;
    public float rotateVmaxAngle = 65;

     public void SetFPSData(float newMoveSpeed, CharacterController newCharac,
                          Animator newAnim, string newIdleAnim, string newRunAnim,
                          string newFsmObj, string newFsm, string newFsmStand, string newFsmRun,
                           Vector3 newCharaCenter,
                         float newRotaHSpeed, float newRotaVSpeed, float newRotaMinAngle, float newRotaMaxAngle)
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
        rotateHoriSpeed = newRotaHSpeed;
        rotateVertSpeed = newRotaVSpeed;

        rotateVminAngle = newRotaMinAngle;
        rotateVmaxAngle = newRotaMaxAngle;    
    }

}
