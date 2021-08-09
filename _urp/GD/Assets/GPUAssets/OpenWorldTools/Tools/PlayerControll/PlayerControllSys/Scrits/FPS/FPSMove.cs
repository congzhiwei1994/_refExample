using UnityEngine;
using UnityEngine.UI;
public class FPSMove : BaseMove
{
    private Text text;
    public override void Start()
    {
        base.Start();
        text = GameObject.Find("AnimText").GetComponent<Text>();
    }


    public override void OnUpdate(float x, float y)
    {
        Vector3 movement = new Vector3(x*_speed, 0, y*_speed);
        movement = Vector3.ClampMagnitude(movement, _speed);

        movement.y = _gravity;

        movement *= Time.deltaTime;
        movement = transform.TransformDirection(movement);
        _charController.Move(movement);
    }

    public override void OnMove()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_WIN    
        Input_PC();
#endif

#if UNITY_ANDROID || UNITY_IPHONE || UNITY_IOS
        Input_JoyStick();       
#endif
        OnUpdate(_horInput,_vertInput);

        ChangePlayType();
    }
}
