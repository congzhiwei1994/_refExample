using UnityEngine;
using System.Collections;
[ExecuteInEditMode]
public class MaterialSwitch : MonoBehaviour
{

    public Material[] MaterialList;
    int CurrentMaterial = 1;
    public GameObject[] ObjectList;
    string MaterialName = "";
    public bool ShowGUI = false;
    public float HorizontalMargin = 25;

    void OnEnable()
    {

        if (ObjectList.Length == 0) return;

        if (ObjectList.Length > 0)
            MaterialName = ObjectList[0].GetComponent<Renderer>().sharedMaterial.name;

      
        MaterialName = MaterialList[CurrentMaterial].name;
    }

    void SwitchMaterialNow()
    {

        if (CurrentMaterial > MaterialList.Length)
            CurrentMaterial = 1;

        if (CurrentMaterial < 1)
            CurrentMaterial = MaterialList.Length;

        for (int i = 0; i < ObjectList.Length; i++)
        {
            ObjectList[i].GetComponent<Renderer>().material = MaterialList[CurrentMaterial - 1];
        }
        MaterialName = MaterialList[CurrentMaterial - 1].name;

    }

    void Update()
    {
        if (ObjectList.Length == 0) return;

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            CurrentMaterial++;
            SwitchMaterialNow();
        }
        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            CurrentMaterial--;

            SwitchMaterialNow();
        }
     
    }

    void OnGUI()
    {
        if (ShowGUI)
        {
            GUI.Label(new Rect(HorizontalMargin, 10, 500, 20),"Use arrows to switch between materials");

            GUI.Label(new Rect(HorizontalMargin, 25, 500, 20), "Material: " + MaterialName);
        }
    }
}
