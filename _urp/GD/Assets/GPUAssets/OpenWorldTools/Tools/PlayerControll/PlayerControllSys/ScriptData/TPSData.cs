using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "EjoyTA/PlayControll_TPS")]
public class TPSData : BaseControData
{

    public Vector3 pointOffset = Vector3.zero;
    public Vector3 charctCenter = new Vector3(0, 1, 0);

    //public Vector2 currentRotate;

    public float rotateHoriSpeed = 2;
    public float rotateVertSpeed = 2;

    public float rotateVminAngle = 0;
    public float rotateVmaxAngle = 65;

    public float currentZoomDis = 6;

    public float zoomMinDis = 1;
    public float zoomMaxDis = 20;

    public bool zoomIsSmooth = true;
    public  void  SetTPSData(float newMoveSpeed, CharacterController newCharac,
                          Animator newAnim, string newIdleAnim, string newRunAnim,
                          string newFsmObj, string newFsm, string newFsmStand, string newFsmRun,
                          Vector3 newPointOffset, Vector3 newCharaCenter,
                         float newRotaHSpeed, float newRotaVSpeed, float newRotaMinAngle, float newRotaMaxAngle,
                         float newZoomDis, float newZoomMin, float newZoomMax, bool newZoomisSmooth)
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

        pointOffset = newPointOffset;
        charctCenter = newCharaCenter;
        rotateHoriSpeed = newRotaHSpeed;
        rotateVertSpeed = newRotaVSpeed;

        rotateVminAngle = newRotaMinAngle;
        rotateVmaxAngle = newRotaMaxAngle;

        currentZoomDis = newZoomDis;

        zoomMinDis = newZoomMin;
        zoomMaxDis = newZoomMax;

        zoomIsSmooth = newZoomisSmooth;
    }
}
