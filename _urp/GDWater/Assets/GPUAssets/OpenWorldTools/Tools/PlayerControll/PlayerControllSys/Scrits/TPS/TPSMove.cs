using UnityEngine;
using UnityEngine.UI;


public class TPSMove : BaseMove
{
   
    private Text text;
    public TPSMove()
    {

    }
    public TPSMove(GameObject target, GameObject selfObj)
    {
        _target = target;
        _selfobj = selfObj;
    }

    public override void Start()
    {
        base.Start();
        text = GameObject.Find("AnimText").GetComponent<Text>(); 
    }

    public override void OnMove()
    {
#if UNITY_EDITOR ||UNITY_STANDALONE_WIN
        Input_PC();
        if (_animtor)
            text.text = "当前动画控制器：---" + _selfobj.name + " ---" + _animtor.name;
#endif

#if UNITY_ANDROID || UNITY_IPHONE || UNITY_IOS
        Input_JoyStick();
          text.text = "当前动画控制器：---" + _selfobj.name + " ---" + _animtor.name + "---这里是移动设备^_^" +"当前状态="+_currentPlayType+"---上个状态="+_lastPlayType;
#endif
        base.OnMove();
    }
}
