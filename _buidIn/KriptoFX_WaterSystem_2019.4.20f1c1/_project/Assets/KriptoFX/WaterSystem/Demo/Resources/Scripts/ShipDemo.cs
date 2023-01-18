using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShipDemo : MonoBehaviour
{
    public Rigidbody RigidBody;
    public bool UseAutoPilot = true;

    public float ForwardSpeed = 15;
    public float BackSpeed = 5;
    public float LeftRightSpeed = 0.2f;

    public GameObject Steering;
    public float StreeringSpeed = 0.2f;

    float wheelRotationSpeed;
    Vector3 lastWheelRotation;

    float currentRotationSpeed;
    float currentForwardSpeed;
    float currentBackSpeed;

    public void Update()
    {
        if (Input.GetKeyUp(KeyCode.A) || Input.GetKeyUp(KeyCode.D))
        {
            currentRotationSpeed = 0;
        }
    }

    public void FixedUpdate()
    {

        if (Input.GetKey(KeyCode.W) || UseAutoPilot)
        {
            currentForwardSpeed += Time.deltaTime * 0.4f * ForwardSpeed;
            currentForwardSpeed = Mathf.Clamp(currentForwardSpeed, -ForwardSpeed, ForwardSpeed);
           
        }
        else if (Input.GetKey(KeyCode.S))
        {
            currentForwardSpeed -= Time.deltaTime * 0.4f * BackSpeed;
            currentForwardSpeed = Mathf.Clamp(currentForwardSpeed, -BackSpeed, BackSpeed);
        }
        else
        {
            currentForwardSpeed *= 0.991f;
        }

        if (Input.GetKey(KeyCode.A))
        {
            currentRotationSpeed -= Time.deltaTime * 0.25f;
            currentRotationSpeed = Mathf.Clamp(currentRotationSpeed, -1, 1);

            wheelRotationSpeed -= StreeringSpeed * Time.deltaTime;
            wheelRotationSpeed = Mathf.Clamp01(wheelRotationSpeed);
            
            lastWheelRotation = new Vector3(0, 0, Mathf.SmoothStep(-500, 500, wheelRotationSpeed));
            Steering.transform.localRotation = Quaternion.Euler(lastWheelRotation);
        }
        else if (Input.GetKey(KeyCode.D))
        {
            currentRotationSpeed += Time.deltaTime * 0.25f;
            currentRotationSpeed = Mathf.Clamp(currentRotationSpeed, -1, 1);

            wheelRotationSpeed += StreeringSpeed * Time.deltaTime;
            wheelRotationSpeed = Mathf.Clamp01(wheelRotationSpeed);
            lastWheelRotation = new Vector3(0, 0, Mathf.SmoothStep(-500, 500, wheelRotationSpeed));
            Steering.transform.localRotation = Quaternion.Euler(lastWheelRotation);
        }
        else
        {
            wheelRotationSpeed *= 0.991f;
        }
       // Debug.Log("currentForwardSpeed " + currentForwardSpeed + "    currentRotationSpeed " + currentRotationSpeed);
        RigidBody.AddRelativeForce(-Vector3.forward * currentForwardSpeed, ForceMode.Acceleration);
        RigidBody.AddTorque(Vector3.up * currentRotationSpeed * LeftRightSpeed, ForceMode.Acceleration);
    }
}
