using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
#if UNITY_EDITOR
using UnityEditor;


#endif
namespace SSS
{
    [ExecuteInEditMode]
    public class MaterialSelector : MonoBehaviour
    {
        public Material[] Materials;
        public Renderer FogMesh;
        int InitialItem;

        private void OnEnable()
        {
#if UNITY_EDITOR
            InitialItem = EditorPrefs.GetInt("InitialItem " + this.GetInstanceID() + " " + name, InitialItem);
            //Debug.Log("Loaded material :" + InitialItem);

            FogMesh.sharedMaterial = Materials[InitialItem];
#endif
        }
        // Start is called before the first frame update
        void Start()
        {
            Dropdown dd = GetComponent<Dropdown>();
            dd.options.Clear();

            foreach (Material m in Materials)
                dd.options.Add(new Dropdown.OptionData() { text = m.name });

            for (int i = 0; i < Materials.Length; i++)
            {
                if (Materials[i].name == FogMesh.sharedMaterial.name)
                {
                    //Debug.Log("initial Material is " + Materials[i].name);
                    FogMesh.sharedMaterial = Materials[i];
                    dd.value = i;
                    
                    break;
                }
            }
        }

        public void HandleInputData(int val)
        {
            FogMesh.sharedMaterial = Materials[val];
#if UNITY_EDITOR
            EditorPrefs.SetInt("InitialItem " + this.GetInstanceID() + " " + name, val);
            //Debug.Log("Saved item: " + val);
            InitialItem = val;
#endif
        }
        // Update is called once per frame
        void Update()
        {

        }

        private void OnDisable()
        {
           
        }
    }
}