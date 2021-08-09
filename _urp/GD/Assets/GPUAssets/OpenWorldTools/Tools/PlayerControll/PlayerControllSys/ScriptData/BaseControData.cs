using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaseControData : ScriptableObject
{
    public float moveSpeed          = 10;
    public CharacterController characterController;
    public Animator animtor;
    public string idleAnimName      = "Idle";
    public string runAnimName       = "Run";


    public string fsmGameObject     = "FSM所在对象";
    public string fsmName           = "FSM节点对象";
    public string fsmEventStand     = "FSM待机事件";
    public string fsmEventRun       = "FSM跑步事件";
}
