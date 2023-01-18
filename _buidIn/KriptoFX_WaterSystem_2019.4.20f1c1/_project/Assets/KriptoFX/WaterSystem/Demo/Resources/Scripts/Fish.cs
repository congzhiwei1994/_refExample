using UnityEngine;
using System.Collections;

public class Fish : MonoBehaviour
{
    public GlobalFlock GlobalFlock;
	public Transform fishZone;
    public Vector2 MinMaxSpeed = new Vector2(0.1f, 0.5f);
    public float ObstacleSensingDistance = 3;
    public Vector3 tankSize;


	public float speed;
	public float turnSpeed = 1.0f;
	Vector3 averageHeading;
	Vector3 averagePosition;
	float neighborDistance = 5;

    private Vector3 lastPos;

	bool turning = false;

	// Use this for initialization
	void Start () {
		speed = Random.Range (MinMaxSpeed.x, MinMaxSpeed.y);
	}

    void UpdateBoundary()
    {

    }
	// Update is called once per frame
	void Update () {
		ApplyTankBoundary ();

		if(turning) {
			Vector3 direction = fishZone.position - transform.position;
			transform.rotation = Quaternion.Slerp (transform.rotation,
				Quaternion.LookRotation (direction),
				TurnSpeed () * Time.deltaTime);
			speed = Random.Range(MinMaxSpeed.x, MinMaxSpeed.y);
		} else {
			if (Random.Range (0, 5) < 1)
				ApplyRules ();
		}

		transform.Translate (0, 0, Time.deltaTime * speed);
	}

    void ApplyTankBoundary()
    {
        if (Mathf.Abs(transform.position.x - fishZone.position.x) >= tankSize.x ||
            Mathf.Abs(transform.position.y - fishZone.position.y) >= tankSize.y ||
            Mathf.Abs(transform.position.z - fishZone.position.z) >= tankSize.z)
        {
            turning = true;
        }
        else
        {
            turning = false;
        }
    }

    void ApplyRules() {

		var gos = GlobalFlock.allFish;

		Vector3 vCenter = Vector3.zero;
		Vector3 vAvoid = Vector3.zero;
		float gSpeed = 0.1f;

		Vector3 goalPos = GlobalFlock.goalPos;

		float dist;
		int groupSize = 0;

		foreach (GameObject go in gos) {
			if (go != this.gameObject) {
				dist = Vector3.Distance (go.transform.position, this.transform.position);
				if (dist <= neighborDistance) {
					vCenter += go.transform.position;
					groupSize++;

					if(dist < 0.75f) {
						vAvoid = vAvoid + (this.transform.position - go.transform.position);
					}

					Fish anotherFish = go.GetComponent<Fish> ();
					gSpeed += anotherFish.speed;
				}

			}
		}

		if (groupSize > 0) {
			vCenter = vCenter / groupSize + (goalPos - this.transform.position);
			speed = gSpeed / groupSize;

			Vector3 direction = (vCenter + vAvoid) - transform.position;
			if (direction != Vector3.zero) {
				transform.rotation = Quaternion.Slerp (transform.rotation,
					Quaternion.LookRotation (direction),
					TurnSpeed () * Time.deltaTime);
			}
		}

 	}


	float TurnSpeed() {
		return Random.Range (0.2f, 0.6f) * turnSpeed;
	}
 }
