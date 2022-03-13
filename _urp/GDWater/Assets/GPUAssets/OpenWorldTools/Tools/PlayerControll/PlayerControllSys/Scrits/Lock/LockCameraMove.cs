using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class LockCameraMove : BaseMove
{
    private Text text;
    public override void Start()
    {
        base.Start();
        text = GameObject.Find("AnimText").GetComponent<Text>();
    }

    public override void OnMove()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_WIN
        Input_PC();
#endif

#if UNITY_ANDROID || UNITY_IPHONE || UNITY_IOS
        Input_JoyStick();       
#endif
        base.OnMove();
    }
}
