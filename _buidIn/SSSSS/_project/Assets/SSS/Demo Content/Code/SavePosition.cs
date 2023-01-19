#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

namespace SSS
{
    [ExecuteInEditMode]
    public class SavePosition : MonoBehaviour
    {
        [Header("Frames between savings")]
        public int Frequency = 50;
        [SerializeField] Vector3 position;
        public Vector3 Position
        {
            get
            {
                Vector3 RotVector;
                RotVector.x = EditorPrefs.GetFloat("Position X " + this.GetInstanceID() + " " + name, gameObject.transform.localPosition.x);
                RotVector.y = EditorPrefs.GetFloat("Position Y " + this.GetInstanceID() + " " + name, gameObject.transform.localPosition.y);
                RotVector.z = EditorPrefs.GetFloat("Position Z " + this.GetInstanceID() + " " + name, gameObject.transform.localPosition.z);
                return RotVector;

            }
            set
            {
                EditorPrefs.SetFloat("Position X " + this.GetInstanceID() + " " + name, value.x);
                EditorPrefs.SetFloat("Position Y " + this.GetInstanceID() + " " + name, value.y);
                EditorPrefs.SetFloat("Position Z " + this.GetInstanceID() + " " + name, value.z);
            }
        }

        [SerializeField] Vector3 rotation;
        public Vector3 Rotation
        {
            get
            {
                Vector3 RotVector;
                RotVector.x = EditorPrefs.GetFloat("Rotation X " + this.GetInstanceID() + " " + name, gameObject.transform.localEulerAngles.x);
                RotVector.y = EditorPrefs.GetFloat("Rotation Y " + this.GetInstanceID() + " " + name, gameObject.transform.localEulerAngles.y);
                RotVector.z = EditorPrefs.GetFloat("Rotation Z " + this.GetInstanceID() + " " + name, gameObject.transform.localEulerAngles.z);
                return RotVector;

            }
            set
            {
                EditorPrefs.SetFloat("Rotation X " + this.GetInstanceID() + " " + name, value.x);
                EditorPrefs.SetFloat("Rotation Y " + this.GetInstanceID() + " " + name, value.y);
                EditorPrefs.SetFloat("Rotation Z " + this.GetInstanceID() + " " + name, value.z);
            }
        }


        // Use this for initialization
        void OnEnable()
        {
            //Restore
            rotation = Rotation;
            transform.localEulerAngles = rotation;

            position = Position;
            transform.localPosition = position;
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
        // Update is called once per frame
        void Update()
        {
            if (TimeSnap(Frequency))
            {
                Rotation = transform.localEulerAngles;
                rotation = Rotation;

                Position = transform.localPosition;
                position = Position;
            }
        }
    }
}
#endif
