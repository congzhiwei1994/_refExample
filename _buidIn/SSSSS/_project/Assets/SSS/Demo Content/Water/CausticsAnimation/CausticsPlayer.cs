using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SSS
{
    [ExecuteInEditMode]
    public class CausticsPlayer : MonoBehaviour
    {
        [SerializeField]
        Material PoolMaterial;
        [SerializeField] Object[] Frames;       

        int ticks;
        [Range(0, .1f)]
        public float delay = 0.5f;

        void Start() 
        { 
            StartCoroutine(Timer()); 
        }

        IEnumerator Timer()
        {
            yield return new WaitForSeconds(delay);
            ticks++;
            if (ticks > Frames.Length)
                ticks = 1;

            if (Frames.Length > 0)
                PoolMaterial.SetTexture("_CausticsFrame", (Texture2D)Frames[ticks-1]);

            //Debug.Log(ticks);
            StartCoroutine(Timer());
        }

        void OnEnable()
        {
            PoolMaterial = GetComponent<Renderer>().sharedMaterial;
            Frames = Resources.LoadAll("CausticsFrames", typeof(Texture2D));
        }

        // Update is called once per frame
        void Update()
        {

        }
    }
}