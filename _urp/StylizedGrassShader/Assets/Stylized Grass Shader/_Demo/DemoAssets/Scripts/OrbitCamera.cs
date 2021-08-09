using UnityEngine;
using System.Collections;

namespace StylizedGrassDemo
{
    public class OrbitCamera : MonoBehaviour
    {
        [Space]
        public Transform pivot;

        [Space]
        public bool enableMouse = true;
        public float idleRotationSpeed = 0.05f;
        public float lookSmoothSpeed = 5;
        public float moveSmoothSpeed = 5;
        public float scrollSmoothSpeed = 5;

        private Transform cam;
        private float cameraRotSide;
        private float cameraRotUp;
        private float cameraRotSideCur;
        private float cameraRotUpCur;
        private float distance;

        void Start()
        {
            cam = Camera.main.transform;

            cameraRotSide = transform.eulerAngles.y;
            cameraRotSideCur = transform.eulerAngles.y;
            cameraRotUp = transform.eulerAngles.x;
            cameraRotUpCur = transform.eulerAngles.x;
            distance = -cam.localPosition.z;
        }

        void LateUpdate()
        {

            Cursor.visible = false;
            if (!pivot) return;

            if (Input.GetMouseButton(0) && enableMouse)
            {
                cameraRotSide += Input.GetAxis("Mouse X") * 5;
                cameraRotUp -= Input.GetAxis("Mouse Y") * 5;
            }
            else
            {
                cameraRotSide += idleRotationSpeed;
            }
            cameraRotSideCur = Mathf.LerpAngle(cameraRotSideCur, cameraRotSide, Time.deltaTime * lookSmoothSpeed);
            cameraRotUpCur = Mathf.Lerp(cameraRotUpCur, cameraRotUp, Time.deltaTime * lookSmoothSpeed);

            if (Input.GetMouseButton(1) && enableMouse)
            {
                distance *= (1 - 0.1f * Input.GetAxis("Mouse Y"));
            }

            if(enableMouse) distance *= (1 - 1 * Input.GetAxis("Mouse ScrollWheel"));

            Vector3 targetPoint = pivot.position;
            transform.position = Vector3.Lerp(transform.position, targetPoint, Time.deltaTime * moveSmoothSpeed);
            transform.rotation = Quaternion.Euler(cameraRotUpCur, cameraRotSideCur, 0);

            float dist = Mathf.Lerp(-cam.transform.localPosition.z, distance, Time.deltaTime * scrollSmoothSpeed);
            cam.localPosition = -Vector3.forward * dist;
        }
    }
}
