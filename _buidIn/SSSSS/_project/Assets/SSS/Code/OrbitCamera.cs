using UnityEngine;
using System.Collections;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace SSS_Demo
{
    [ExecuteInEditMode]
    public class OrbitCamera : MonoBehaviour
    {
        [Header("Frames between savings")]
        public int Frequency = 50;
        public Transform target;
        /*[HideInInspector] */
        public float distance = 5.0f;
        public float Distance
        {
            get { return PlayerPrefs.GetFloat("Camera Distance " + this.GetInstanceID().ToString(), distance); }
            set { PlayerPrefs.SetFloat("Camera Distance " + this.GetInstanceID().ToString(), value); }
        }

        float idistance;
        public float RotationSpeed = 120.0f;
        bool CursorOnScreen;
        [Range(.1f, 1)]
        public float ZoomSpeed = 1;
        //Vector3 VirtualPivot = Vector3.zero;
        //[SerializeField]
        /*[HideInInspector] */
        public Vector3 virtualPivot;
        public Vector3 VirtualPivot
        {
            get
            {
                Vector3 _Vector;
                _Vector.x = PlayerPrefs.GetFloat("Camera VirtualPivot X " + this.GetInstanceID(), virtualPivot.x);
                _Vector.y = PlayerPrefs.GetFloat("Camera VirtualPivot Y " + this.GetInstanceID(), virtualPivot.y);
                _Vector.z = PlayerPrefs.GetFloat("Camera VirtualPivot Z " + this.GetInstanceID(), virtualPivot.z);
                return _Vector;

            }
            set
            {
                PlayerPrefs.SetFloat("Camera VirtualPivot X " + this.GetInstanceID(), value.x);
                PlayerPrefs.SetFloat("Camera VirtualPivot Y " + this.GetInstanceID(), value.y);
                PlayerPrefs.SetFloat("Camera VirtualPivot Z " + this.GetInstanceID(), value.z);
            }
        }

        [Range(0, .1f)]
        public float PanSpeed = .1f;
        float x = 0, ix = 0.0f;
        float y = 0, iy = 0.0f;

        //[SerializeField]
        [HideInInspector] public Vector3 rotation;
        public Vector3 Rotation
        {
            get
            {
                Vector3 RotVector;
                RotVector.x = PlayerPrefs.GetFloat("Camera Rotation X " + this.GetInstanceID(), gameObject.transform.eulerAngles.x);
                RotVector.y = PlayerPrefs.GetFloat("Camera Rotation Y " + this.GetInstanceID(), gameObject.transform.eulerAngles.y);
                RotVector.z = PlayerPrefs.GetFloat("Camera Rotation Z " + this.GetInstanceID(), gameObject.transform.eulerAngles.z);
                return RotVector;

            }
            set
            {
                PlayerPrefs.SetFloat("Camera Rotation X " + this.GetInstanceID(), value.x);
                PlayerPrefs.SetFloat("Camera Rotation Y " + this.GetInstanceID(), value.y);
                PlayerPrefs.SetFloat("Camera Rotation Z " + this.GetInstanceID(), value.z);
            }
        }

        //[SerializeField]
        [HideInInspector] public Vector3 position;
        public Vector3 Position
        {
            get
            {
                Vector3 _Vector;
                _Vector.x = PlayerPrefs.GetFloat("Camera Position X " + this.GetInstanceID(), gameObject.transform.position.x);
                _Vector.y = PlayerPrefs.GetFloat("Camera Position Y " + this.GetInstanceID(), gameObject.transform.position.y);
                _Vector.z = PlayerPrefs.GetFloat("Camera Position Z " + this.GetInstanceID(), gameObject.transform.position.z);
                return _Vector;

            }
            set
            {
                PlayerPrefs.SetFloat("Camera Position X " + this.GetInstanceID(), value.x);
                PlayerPrefs.SetFloat("Camera Position Y " + this.GetInstanceID(), value.y);
                PlayerPrefs.SetFloat("Camera Position Z " + this.GetInstanceID(), value.z);
            }
        }

        void Start()
        {
            Vector3 angles = transform.eulerAngles;
            x = angles.y;
            y = angles.x;
            ix = x;
            iy = y;
            idistance = distance;
        }

        bool TimeSnap(int Frames)
        {
            bool refresh = true;
            if (Application.isPlaying)
            {
                refresh = Time.frameCount <= 3 || (Time.frameCount % (1 + Frames)) == 0;

                return refresh;
            }
            else
                return true;


        }

        void Update()
        {
            bool LMB = Input.GetMouseButton(0);
            bool RMB = Input.GetMouseButton(1);
            bool MMB = Input.GetMouseButton(2);



            if (target && Application.isPlaying)
            {
                if (/*Input.GetKey(KeyCode.LeftAlt) && */LMB)
                {
                    x += Input.GetAxis("Mouse X") * RotationSpeed * 0.02f;
                    y -= Input.GetAxis("Mouse Y") * RotationSpeed * 0.02f;

                }
                Quaternion Qrotation = Quaternion.Euler(y, x, 0);

                //zoom draggin'
                if (/*Input.GetKey(KeyCode.LeftAlt) && */RMB)
                {
                    //drag mouse to add and sub distance
                    distance += Input.GetAxis("Mouse Y") * ZoomSpeed * 0.15f;
                }

                //zoom mouse wheel
                if (MouseScreenCheck())
                    distance -= Input.GetAxis("Mouse ScrollWheel") * ZoomSpeed;

                //Vector3 RotationPivot = target.position;
                //pan
                if (/*Input.GetKey(KeyCode.LeftAlt) && */MMB)
                {
                    // VirtualPivot.x += Input.GetAxis("Mouse X") * PanSpeed;
                    // VirtualPivot.y -= Input.GetAxis("Mouse Y") * PanSpeed;
                    virtualPivot -= Qrotation * new Vector3(Input.GetAxis("Mouse X") * PanSpeed, Input.GetAxis("Mouse Y") * PanSpeed, 0);
                }

                /*Vector3*/
                position = Qrotation * new Vector3(0.0f, 0.0f, -distance) + target.position + virtualPivot;

                transform.rotation = Qrotation;
                transform.position = position;




                if (TimeSnap(Frequency))
                {
                    VirtualPivot = virtualPivot;

                    Rotation = transform.eulerAngles;
                    rotation = Rotation;

                    Position = transform.position;
                    position = Position;

                    Distance = distance;

                }
            }
            if (target == null)
                print("Set a target in the orbit camera");
            // print( Event.current.keyCode);


            if (/*Input.GetKey(KeyCode.F) ||*/ Input.GetKey(KeyCode.R)) ResetCam();



        }
        void ResetCam()
        {
            //  print("Control");
            // if (Input.GetKey(KeyCode.F) || Input.GetKey(KeyCode.R))
            {
                //   print("F");
                VirtualPivot = Vector3.zero;
                virtualPivot = Vector3.zero;
                x = ix;
                y = iy;
                distance = idistance;
            }
        }

        void OnEnable()
        {
            //ResetCam();
            rotation = Rotation;
            transform.eulerAngles = rotation;

            position = Position;
            transform.position = Position;

            distance = Distance;

            virtualPivot = VirtualPivot;
        }

        public bool MouseScreenCheck()
        {
            var view = GetComponent<Camera>().ScreenToViewportPoint(Input.mousePosition);
            var isOutside = view.x < 0 || view.x > 1 || view.y < 0 || view.y > 1;

            return !isOutside;
        }

    }
}
