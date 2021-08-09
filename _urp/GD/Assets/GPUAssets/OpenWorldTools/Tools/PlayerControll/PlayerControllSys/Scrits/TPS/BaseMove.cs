using UnityEngine;
public enum PlayCtrlType
{
    Idle,
    Run
}
public class BaseMove : MonoBehaviour
{
    public GameObject _target;
    public GameObject _selfobj;
    public CharacterController _charController;
    public Animator _animtor;

    public string _idle = "Idle";
    public string _run = "Run";

    public float _speed = 10;
    public float _rotaSpeed = 10;
    public Vector3 _charactCenter = new Vector3(0, 1, 0);

    public float _horInput = 0.0f;
    public float _vertInput = 0.0f;
    public Vector3 _movement = Vector3.zero;


    public float _vertSpeed = -1f;
    public float _gravity = -9.8f;
    public float terminalVelocity = -20.0f;

    public bool _isMove = true;
    public bool _isPM = false;
    public bool _isInputNormalize = false;

    public PlayCtrlType _currentPlayType = PlayCtrlType.Idle;
    public PlayCtrlType _lastPlayType = PlayCtrlType.Idle;


    private ControllerColliderHit _contact;
    private ImageMove _joyMove;
    private bool _isKeyDown = false;
    private bool _lastKeyDown = false;
    private bool _isFaceRotate = true;
    private bool _isWorldAxis = true;
    private TPSCamera tpsCamera;
    public BaseMove() { }

    public BaseMove(GameObject target, GameObject selfObj)
    {
        _target = target;
        _selfobj = selfObj;
    }

    /// <summary>
    /// 设置新值
    /// </summary>
    /// <param name="cameraObj"></param>
    /// <param name="playObj"></param>
    /// <param name="moveSpeed"></param>
    /// <param name="isMove"></param>
    public void SetValue(GameObject cameraObj, GameObject playObj, float moveSpeed, bool isMove)
    {
        _target = cameraObj;
        _selfobj = playObj;
        _speed = moveSpeed;
        SetMoveState(isMove);
    }

    public void SetValue(GameObject cameraObj, GameObject playObj,
                        float moveSpeed, bool isMove,
                        string animClipIdle, string animClipRun, Animator animtor,
                        CharacterController charc, Vector3 charcCenter)
    {
        if (_target != cameraObj) _target = cameraObj;
        if (_selfobj != cameraObj) _selfobj = playObj;

        _speed = moveSpeed;
        SetMoveState(isMove);

        _idle = animClipIdle;
        _run = animClipRun;

        if (animtor && _animtor != animtor) _animtor = animtor;

        if (charc && _charController != charc) _charController = charc;
        _charactCenter = charcCenter;

    }
    public virtual void Start()
    {
        _joyMove = FindObjectOfType<ImageMove>();
        tpsCamera = FindObjectOfType<TPSCamera>();
    }

    public void OnInit()
    {
        _joyMove = FindObjectOfType<ImageMove>();
        if (_selfobj)
        {
            _charController = _selfobj.GetComponent<CharacterController>();

            if (_charController == null)
            {
                _charController = _selfobj.AddComponent<CharacterController>();
                _charController.center = _charactCenter;
            }

            _animtor = _selfobj.GetComponent<Animator>();
            if (_animtor == null)
            {
                _animtor = _selfobj.GetComponentInChildren<Animator>();
                if (_animtor == null)
                {
                    Debug.LogError(_selfobj.name + "--对象动画控制器不存在_!");
                }
            }
        }
        else
        {
            Debug.Log("当前对象不存在_");
            return;
        }
    }

    /// <summary>
    /// 实时更新数据
    /// </summary>
    public void RuntimeUpdate()
    {
        OnMove();
    }

    /// <summary>
    /// 默认状态
    /// </summary>
    public void InputIdle()
    {
        _horInput = 0;
        _vertInput = 0;
        _currentPlayType = PlayCtrlType.Idle;
    }

    /// <summary>
    /// WSAD 输入
    /// </summary>
    public void Input_PC()
    {
        if (_isMove)
        {
            _isKeyDown = Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.W);
            if (_isKeyDown)
            {
                _horInput = Input.GetAxis("Horizontal");
                _vertInput = Input.GetAxis("Vertical");

                _currentPlayType = PlayCtrlType.Run;
            }
            else
            {
                if (_joyMove && _joyMove.IsOnDrag)
                {
                    _horInput = _joyMove.axisValue.x;
                    _vertInput = _joyMove.axisValue.y;

                    _currentPlayType = PlayCtrlType.Run;
                }
                else
                {
                    InputIdle();
                }
            }
        }
    }

    /// <summary>
    /// 摇杆输入
    /// </summary>
    public void Input_JoyStick()
    {
        if (_isMove && _joyMove)
        {
            if (_joyMove.axisValue.x != 0 || _joyMove.axisValue.y != 0)
            {
                _horInput = _joyMove.axisValue.x;
                _vertInput = _joyMove.axisValue.y;

                _currentPlayType = PlayCtrlType.Run;
            }
            else
            {
                if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.W))
                {
                    _horInput = Input.GetAxis("Horizontal");
                    _vertInput = Input.GetAxis("Vertical");
                    _currentPlayType = PlayCtrlType.Run;
                }
                else
                {
                    InputIdle();
                }
            }
        }
    }
    Vector2 tempNormalize = Vector2.zero;
    public virtual void OnMove()
    {
        if (_isInputNormalize)
        {
            tempNormalize = new Vector2(_horInput, _vertInput).normalized;
            OnUpdate(tempNormalize.x, tempNormalize.y);
        }
        else
        {
            OnUpdate(_horInput, _vertInput);
        }

        ChangePlayType();
    }

    protected void ChangePlayType()
    {
        if (_lastPlayType != _currentPlayType)
        {
            //Debug.Log("移动外部调用");

            switch (_currentPlayType)
            {
                case PlayCtrlType.Idle:
                    if (_isPM)
                    {
                        //发送pm事件
                    }
                    else
                    {
                        if (_animtor)
                        {
                            PlayAnim(_idle);
                        }
                    }
                    break;
                case PlayCtrlType.Run:
                    if (_isPM)
                    {
                        //发送pm事件
                    }
                    else
                    {
                        if (_animtor)
                        {
                            PlayAnim(_run);
                        }
                    }
                    break;
                default:
                    break;
            }
            _lastPlayType = _currentPlayType;
        }
    }


    /// <summary>
    /// 播放动画
    /// </summary>
    /// <param name="animName"></param>
    public void PlayAnim(string animName)
    {
        if (!string.IsNullOrEmpty(animName))
        {
            _animtor.Play(animName);
        }
    }

    /// <summary>
    /// 设置移动权限_
    /// </summary>
    /// <param name="newState">新权限</param>
    public void SetMoveState(bool newState)
    {
        if (_isMove != newState)
        {
            _isMove = newState;
        }
        else
        {
            return;
        }
    }
    /// <summary>
    /// 移动
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    public virtual void OnUpdate(float x, float y )
    {
        if (_isMove && _selfobj && _target && _charController)
        {
            _movement = Vector3.zero;

            if (x != 0 || y != 0)
            {
                _movement.x = x * _speed;
                _movement.z = y * _speed;
                _movement = Vector3.ClampMagnitude(_movement, _speed);

                if (_isWorldAxis)
                {
                    Quaternion tempQuaterion = _target.transform.rotation;
                    _target.transform.eulerAngles = new Vector3(0, _target.transform.eulerAngles.y, 0);
                    _movement = _target.transform.TransformDirection(_movement);
                    _target.transform.rotation = tempQuaterion;
                }
                else
                {                  
                   // _movement = _selfobj.transform.TransformDirection(_movement);                  
                }


                Quaternion direction = Quaternion.LookRotation(_movement);

                if (_isFaceRotate)
                {
                    if (tpsCamera && tpsCamera._isCameCtr)
                    {
                        _selfobj.transform.rotation = direction;
                    }
                    else
                    {
                        _selfobj.transform.rotation = Quaternion.Lerp(_selfobj.transform.rotation,
                           direction, _rotaSpeed * Time.deltaTime);
                    }
                }
               

                bool hitGround = false;
                RaycastHit hit;
                if (_vertSpeed < 0 && Physics.Raycast(_selfobj.transform.position, Vector3.down, out hit))
                {
                    float check = (_charController.height + _charController.radius) * 0.49f;

                    hitGround = hit.distance <= check;
                }
                if (hitGround)
                {
                    //Jump();
                }
                else
                {
                    _vertSpeed += _gravity * 5 * Time.deltaTime;
                    if (_vertSpeed < terminalVelocity)
                    {
                        _vertSpeed = terminalVelocity;
                    }

                    if (_charController != null && _charController.isGrounded && _movement != null && _contact != null)
                    {
                        if (Vector3.Dot(_movement, _contact.normal) < 0)
                            _movement = _contact.normal * _speed;
                        else
                            _movement += _contact.normal * _speed;
                    }

                }
            }
            _movement.y = _vertSpeed;
            _movement *= Time.deltaTime * 2;
            _charController.Move(_movement);
        }
    }
    void OnControllerColliderHit(ControllerColliderHit hit)
    {
        _contact = hit;
    }
}
