using UnityEngine;
using System.Collections;
namespace SSS
{
    public class ExplorationCamera : MonoBehaviour
    {
        //Turn
        [Range(1f, 50)]
        public float sensitivity = 30;
        [Range(.1f, 50)]
        public float smoothing = 5f;
        Camera cam;
        //Movement
        private float speedZ;
        private float speedX;
        private float speedY;
        [Range(.0f, 10)]
        public float Speed = .1f;
        [HideInInspector]
        public float InitialSpeed = .1f;
        [HideInInspector]
        public float FOV;
        private float initialFOV;
        Vector2 initialLook;
        Vector2 Look;
        private Vector3 MovementDirection;
        public float MaxAcceleration = 4;
        [Range(1f, 10)]
        public float AccelerationSmoothing = 10, SpeedSmooth = 1;
        Vector2 _smoothMouse;
        public bool HideCursor = false;
        float focalLength = 0, focalSize = 1;
        public bool ConstantMove = false;
        [HideInInspector]
        public float tilt;

        //public bool LeeKeyStyle = true;
        void Start()
        {
            try
            {
                //gamepad
                Input.GetAxis("LookHorizontal");
            }
            catch
            {
                //print("Import the custom input to support gamepad in this camera script\n http://davidmiranda.me/files/FogVolume3/InputManager.asset");
            }

            cam = gameObject.GetComponent<Camera>();
            //if (this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>())
            //{
            //    focalLength = this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>().focalLength;
            //    focalSize = this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>().focalSize;
            //}
        }
        Vector2 lastPos;

        void OnGUI()
        {
            //ratón
            if (Event.current.type == EventType.MouseDown)
            {
                if (Input.GetMouseButton(1))
                    lastPos = Event.current.mousePosition;
            }
            else if (Event.current.type == EventType.MouseDrag || Event.current.type == EventType.MouseMove)
            {
                if (Input.GetMouseButton(1))
                {
                    Vector3 diff = Event.current.mousePosition - lastPos;
                    Look += new Vector2(diff.x * sensitivity / 50, -diff.y * sensitivity / 50);
                    lastPos = Event.current.mousePosition;
                }
            }
        }
        public float tiltSmoothing = 50, FOVTransitionSpeed = .1f;
        public float inclination = 13;
        public bool ApplyGravity;
        [Range(0f, 1)]
        public float gravityAccelerationScale = .1f;
        void OnDestroy()
        { Cursor.visible = true; }
        void FixedUpdate()
        {
            //       if (Input.GetKey(KeyCode.Escape)) Application.Quit();



            try
            {
                //gamepad
                if (Mathf.Abs(Input.GetAxis("LookHorizontal")) > 0.017f || Mathf.Abs(Input.GetAxis("LookVertical")) > 0.017f)
                {
                    Look += new Vector2(Input.GetAxis("LookHorizontal"), -Input.GetAxis("LookVertical")) * sensitivity;

                    if (Input.GetAxis("LookHorizontal") > 0)
                        tilt = Mathf.Lerp(tilt, -inclination * Mathf.Abs(Input.GetAxis("LookHorizontal")) * sensitivity, 1f / tiltSmoothing);
                    else
                        tilt = Mathf.Lerp(tilt, inclination * Mathf.Abs(Input.GetAxis("LookHorizontal")) * sensitivity, 1f / tiltSmoothing);


                }
            }
            catch
            {
                //
            }
            tilt = Mathf.Lerp(tilt, 0, 1f / tiltSmoothing);
            //DOF
            if (Input.GetKey(KeyCode.PageDown))
                focalLength -= .05f;
            if (Input.GetKey(KeyCode.PageUp))
                focalLength += .05f;

            if (Input.GetKey(KeyCode.End))
                focalSize -= .05f;
            if (Input.GetKey(KeyCode.Home))
                focalSize += .05f;
            //if (this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>())
            //{
            //    this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>().focalLength = focalLength;
            //    this.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>().focalSize = focalSize;
            //}
            //Turn interpolation
            _smoothMouse.x = Mathf.Lerp(_smoothMouse.x, Look.x, 1f / smoothing);
            _smoothMouse.y = Mathf.Lerp(_smoothMouse.y, Look.y, 1f / smoothing);

            //Aplica giro suave
            transform.localEulerAngles = new Vector3(-_smoothMouse.y, _smoothMouse.x, tilt);


            //Traslación:
            if (Input.GetKey(KeyCode.W) || Input.GetAxis("Vertical") > 0 || ConstantMove)
            {
                MovementDirection = new Vector3(0, 0, 1);
                speedZ = Mathf.Lerp(speedZ, Speed, 1f / smoothing);
            }



            if (Input.GetKey(KeyCode.S) || Input.GetAxis("Vertical") < 0)
            {
                MovementDirection = new Vector3(0, 0, -1);
                speedZ = Mathf.Lerp(speedZ, -Speed, 1f / smoothing);
            }



            if (Input.GetKey(KeyCode.A) || Input.GetAxis("Horizontal") < 0)
            {
                MovementDirection = new Vector3(-1, 0, 0);
                speedX = Mathf.Lerp(speedX, -Speed, 1f / smoothing);

            }

            if (Input.GetKey(KeyCode.D) || Input.GetAxis("Horizontal") > 0)
            {
                MovementDirection = new Vector3(1, 0, 0);
                speedX = Mathf.Lerp(speedX, Speed, 1f / smoothing);

            }


            if (Input.GetKey(KeyCode.Q) || Input.GetKey(KeyCode.JoystickButton4) /*|| Input.GetKey(KeyCode.Space)*/)
            {
                MovementDirection = new Vector3(0, -1, 0);
                speedY = Mathf.Lerp(speedY, -Speed, 1f / smoothing);
            }
            if (Input.GetKey(KeyCode.E) || Input.GetKey(KeyCode.JoystickButton5))
            {
                MovementDirection = new Vector3(0, 1, 0);
                speedY = Mathf.Lerp(speedY, Speed, 1f / smoothing);
            }

            //desaceleración
            speedZ = Mathf.Lerp(speedZ, 0, 1f / smoothing);
            MovementDirection.z = speedZ;
            speedY = Mathf.Lerp(speedY, 0, 1f / smoothing);
            MovementDirection.y = speedY;
            speedX = Mathf.Lerp(speedX, 0, 1f / smoothing);
            MovementDirection = new Vector3(speedX, speedY, speedZ);
            if (ApplyGravity)
            {
                MovementDirection += Physics.gravity * gravityAccelerationScale;
            }
            transform.Translate(MovementDirection);
            // transform.Rotate(Vector3.forward, tilt * 150);
            //Speed Ratón
            Speed = Mathf.Clamp(Speed, .0001f, 100f);
            if (Input.GetMouseButton(1))
            {
                InitialSpeed += Input.GetAxis("Mouse ScrollWheel") * .05f;
                InitialSpeed = Mathf.Max(.001f, InitialSpeed);
            }
            //FOV
            if (Input.GetMouseButton(1) & Input.GetKey(KeyCode.C) & FOV > 5)
            {
                FOV -= 1;
            }
            if (Input.GetMouseButton(1) & Input.GetKey(KeyCode.Z) & FOV < 120)
            {
                FOV += 1;
            }

            //Al soltar la tecla:
            if (Input.GetMouseButton(1) == false)
            {
                FOV = Mathf.Lerp(FOV, initialFOV, FOVTransitionSpeed);//El último valor sería la velocidad a la que vuelve al fov original
                                                                      //Rueda:
                                                                      // speedZ += Input.GetAxis("Mouse ScrollWheel");
            }
            //Aplicar
            //
            //
            if (cam.stereoEnabled == false)
                cam.fieldOfView = FOV;


        }
        float TriggerValue = 0;

        void Update()
        {


            //Extra velocidad:
            try
            {
                TriggerValue = Mathf.Pow(Input.GetAxis("FasterCamera") * 1 / AccelerationSmoothing + 1, 2);
            }
            catch { }
            //print(Speed);
            if (Input.GetKeyDown(KeyCode.LeftShift))
            {

                Speed *= MaxAcceleration;

            }

            try
            {
                if (Input.GetAxis("FasterCamera") > 0 && Speed < InitialSpeed * MaxAcceleration)
                {
                    Speed *= TriggerValue;

                }
                else
                    if (!Input.GetKey(KeyCode.LeftShift))
                    Speed = Mathf.Lerp(Speed, InitialSpeed, 1 / AccelerationSmoothing);
            }
            catch
            {
                if (!Input.GetKey(KeyCode.LeftShift))
                    Speed = Mathf.Lerp(Speed, InitialSpeed, 1 / AccelerationSmoothing);
            }
            //  print(Speed);
            if (Input.GetKeyUp(KeyCode.LeftShift))
            {
                Speed /= MaxAcceleration;
            }
        }


        void OnEnable()
        {
            InitialSpeed = Speed;
            if (HideCursor)
                Cursor.visible = false;


            FOV = this.gameObject.GetComponent<Camera>().fieldOfView;
            initialFOV = FOV;
            initialLook = new Vector2(transform.eulerAngles.y, transform.eulerAngles.x * -1);
            //	Debug.Log (transform.eulerAngles);
            Look = initialLook;
            _smoothMouse = initialLook;
        }
    }
}