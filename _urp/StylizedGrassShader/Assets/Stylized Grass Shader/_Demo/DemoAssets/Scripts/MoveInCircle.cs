using UnityEngine;

namespace StylizedGrassDemo
{
    public class MoveInCircle : MonoBehaviour
    {
        public float radius = 1f;
        public float speed = 1f;
        public Vector3 offset;

        private void Update()
        {
            Move();
        }

        void Move()
        {
            float x = Mathf.Sin(Time.realtimeSinceStartup * speed) * radius + offset.x;
            float y = this.transform.position.y + offset.y;
            float z = Mathf.Cos(Time.realtimeSinceStartup * speed) * radius + offset.z;
            transform.localPosition = new Vector3(x, y, z);
        }
    }
}