using UnityEngine;
using System.Collections;

public class TimeScale : MonoBehaviour
{
    /// <summary>
    /// 变化速率
    /// </summary>
    float speed;

    //什么时候开始运动
    float startTime;

    float _currentScale;


    bool _uSpeed = true;
    bool _aSpeed = false;
    bool _dSpeed = false;

    float _delay;

    #region  参数

    private float _stopValue = 0f;

    private float _value0 = 0.1f;

    private float _value1 = 1f;

    private float _value2 = 2f;

    private float _value3 = 0.3f;


    private float _value4 = 0.4f;


    private float _value5 = 0.5f;


    private float _value6 = 0.6f;


    private float _value7 = 0.7f;


    private float _value8 = 0.8f;


    private float _value9 = 0.9f;
    [Header("本脚本备注：")]
    [SerializeField, TextArea(0, 12)]
    string _message2 = "1=1倍\n2=2倍\n3=0.3倍\n4=0.4倍\n5=0.5倍\n6=0.6倍\n7=0.7倍\n8=0.8倍\n9=0.9倍\n*=0.1倍";
    #endregion
    [SerializeField]
    float _time;
    // [SerializeField]
    // float _timeMax = 0.1f;
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.KeypadMultiply))
        {
            Time.timeScale = _value0;
        }
        if (Input.GetKeyDown(KeyCode.Keypad0))
        {
            Time.timeScale = _stopValue;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad1))
        {
            Time.timeScale = _value1;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad2))
        {
            Time.timeScale = _value2;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad3))
        {
            Time.timeScale = _value3;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad4))
        {
            Time.timeScale = _value4;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad5))
        {
            Time.timeScale = _value5;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad6))
        {
            Time.timeScale = _value6;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad7))
        {
            Time.timeScale = _value7;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.Keypad8))
        {
            Time.timeScale = _value8;
            Debug.Log(Time.timeScale);
        }
        // if (Input.GetKeyDown(KeyCode.Alpha9) || Input.GetKeyDown(KeyCode.Keypad9)) 键盘上2处数字键控制方式
        if (Input.GetKeyDown(KeyCode.Keypad9))
        {
            Time.timeScale = _value9;
            Debug.Log(Time.timeScale);
        }
        if (Input.GetKeyDown(KeyCode.L))
        {
            OnClick();
        }



    }
    int clickCnt;

    public void OnClick()
    {
        clickCnt %= 2;
        switch (clickCnt)
        {
            case 0:
                Time.timeScale = _stopValue;
                break;
            case 1:
                Time.timeScale = _value1;
                break;
        }
        clickCnt++;

    }


    private void LateUpdate()
    {
        if (Time.timeScale != 1)
        {
            if (_uSpeed)
            {
                Time.timeScale = Mathf.Lerp(Time.timeScale, 1f, speed);
                Debug.Log("当前匀速缩放:" + Time.timeScale);
            }
            if (_aSpeed)
            {
                speed += speed * Time.deltaTime;
                Time.timeScale = Mathf.Lerp(Time.timeScale, 1f, (Time.time - startTime) * speed);
                Debug.Log("当前匀加速缩放:" + Time.timeScale);
            }
            if (_dSpeed)
            {
                //speed += speed * Time.deltaTime/3;
                speed = Mathf.Lerp(speed, 0.01f, (Time.time - startTime) * speed);
                //speed += speed * Time.deltaTime;
                //speed = Mathf.Lerp(speed, 0.1f, speed);
                //Debug.Log("当前速度值:"+speed);
                Time.timeScale = Mathf.Lerp(Time.timeScale, 1f, (Time.time - startTime) * speed);
                //Time.timeScale = Mathf.Lerp(Time.timeScale, 1f, speed);
                //Debug.Log("当前匀减速缩放:" + Time.timeScale);
            }

        
        }

    }

    public void SetScale(float currSpeed, float v, bool uSpeed, bool aSpeed, bool dSpeed, float delay)
    {
        if(delay != 0)
        {
            TimeDelay.Delay(delay, a =>
            {
                Time.timeScale = currSpeed;
                startTime = Time.time;
                speed = v;
                _aSpeed = aSpeed;
                _dSpeed = dSpeed;
                _uSpeed = uSpeed;
            });
        }
        else
        {
            Time.timeScale = currSpeed;
            startTime = Time.time;
            speed = v;
            _aSpeed = aSpeed;
            _dSpeed = dSpeed;
            _uSpeed = uSpeed;
            _delay = delay;
        }


    }

}
