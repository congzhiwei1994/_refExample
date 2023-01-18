using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class GlobalFlock : MonoBehaviour {

	public GameObject AttachedCameraFollow;
	public GameObject AttachedCameraTarget;
	public Vector3 CameraFollowOffset = new Vector3(0, 1, 0);
	public GameObject[] fishPrefabs;
	public GameObject fishArea;
	public Vector3 tankSize = new Vector3(7, 3, 7);
	public Vector2 MinMaxSpeed = new Vector2(5.1f, 5.5f);
    public float TurnSpeed = 1;
	public Vector2 MinMaxScale = new Vector2(0.5f, 2f);

	public int numFish = 30;
	public List<GameObject> allFish;
	public Vector3 goalPos = Vector3.zero;

	// Use this for initialization
	void Start () {
		for (int i = 0; i < numFish; i++) {
			Vector3 pos = new Vector3 (
				Random.Range(-tankSize.x, tankSize.x),
				Random.Range(-tankSize.y, tankSize.y),
				Random.Range(-tankSize.z, tankSize.z)
			);
			var fish = (GameObject)Instantiate (fishPrefabs[Random.Range (0, fishPrefabs.Length)]);
			fish.transform.parent = fishArea.transform;
            fish.transform.localPosition = pos;
            fish.transform.localScale = Vector3.one * Random.Range(MinMaxScale.x, MinMaxScale.y);
		    allFish.Add(fish);
            var fishSettings = fish.AddComponent<Fish>();

            fishSettings.fishZone = fishArea.transform;
            fishSettings.GlobalFlock = this;
            fishSettings.MinMaxSpeed = MinMaxSpeed;
            fishSettings.turnSpeed = TurnSpeed;
            fishSettings.tankSize = tankSize * Random.Range(MinMaxScale.x, MinMaxScale.y);

			if(i == 0 && AttachedCameraFollow != null)
            {
				AttachedCameraFollow.transform.parent = fish.transform;
				AttachedCameraFollow.transform.localPosition = CameraFollowOffset;

				AttachedCameraTarget.transform.parent = fish.transform;
				AttachedCameraTarget.transform.localPosition = Vector3.zero;
			}
        }
	}

	// Update is called once per frame
	void Update () {
		HandleGoalPos ();
	}

	void HandleGoalPos() {
		if (Random.Range(1, 10000) < 50) {
			goalPos = new Vector3 (
                Random.Range(-tankSize.x, tankSize.x),
                Random.Range(-tankSize.y, tankSize.y),
                Random.Range(-tankSize.z, tankSize.z)
			);
		}
	}

    void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(transform.position, tankSize * 2);
	}
}
