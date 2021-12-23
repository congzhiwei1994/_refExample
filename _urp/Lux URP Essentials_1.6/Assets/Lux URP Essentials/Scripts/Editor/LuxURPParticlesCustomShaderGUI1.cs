using UnityEngine;
using UnityEditor;
//using UnityEditorInternal;
using System.Linq;
using System.Collections.Generic;
 
public class LuxURPParticlesCustomShaderGUI : ShaderGUI
{
    
    List<ParticleSystemRenderer> m_RenderersUsingThisMaterial = new List<ParticleSystemRenderer>();
    //private static ReorderableList vertexStreamList;
    private bool showVertexSteamArea = false;


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

    	Material material = materialEditor.target as Material;

        var blendMode = material.GetInt("_Blend");

        switch (blendMode) {
            case 0: // Alpha
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.DisableKeyword("_ALPHAMODULATE_ON");
                material.DisableKeyword("_ADDITIVE");
                break;
            case 1: // Premultiply
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                material.DisableKeyword("_ALPHAMODULATE_ON");
                material.DisableKeyword("_ADDITIVE");
                break;
            case 2: // Additive:
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.DisableKeyword("_ALPHAMODULATE_ON");
                material.EnableKeyword("_ADDITIVE");
                break;
            case 3: // Multiply:
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.EnableKeyword("_ALPHAMODULATE_ON");
                material.DisableKeyword("_ADDITIVE");
                break;
        }

        var colorMode = material.GetInt("_ColorMode");
            
        switch (colorMode)
        {
            case 0: //ColorMode.Multiply:
                material.DisableKeyword("_COLOROVERLAY_ON");
                material.DisableKeyword("_COLORCOLOR_ON");
                material.DisableKeyword("_COLORADDSUBDIFF_ON");
                break;
            case 1: //ColorMode.Additive:
                material.DisableKeyword("_COLOROVERLAY_ON");
                material.DisableKeyword("_COLORCOLOR_ON");
                material.EnableKeyword("_COLORADDSUBDIFF_ON");
                material.SetVector("_BaseColorAddSubDiff", new Vector4(1.0f, 0.0f, 0.0f, 0.0f));
                break;
            case 2: //ColorMode.Subtractive:
                material.DisableKeyword("_COLOROVERLAY_ON");
                material.DisableKeyword("_COLORCOLOR_ON");
                material.EnableKeyword("_COLORADDSUBDIFF_ON");
                material.SetVector("_BaseColorAddSubDiff", new Vector4(-1.0f, 0.0f, 0.0f, 0.0f));
                break;
            case 3: //ColorMode.Overlay:
                material.DisableKeyword("_COLORCOLOR_ON");
                material.DisableKeyword("_COLORADDSUBDIFF_ON");
                material.EnableKeyword("_COLOROVERLAY_ON");
                break;
            case 4: //ColorMode.Color:
                material.DisableKeyword("_COLOROVERLAY_ON");
                material.DisableKeyword("_COLORADDSUBDIFF_ON");
                material.EnableKeyword("_COLORCOLOR_ON");
                break;
            case 5: //ColorMode.Difference:
                material.DisableKeyword("_COLOROVERLAY_ON");
                material.DisableKeyword("_COLORCOLOR_ON");
                material.EnableKeyword("_COLORADDSUBDIFF_ON");
                material.SetVector("_BaseColorAddSubDiff", new Vector4(-1.0f, 1.0f, 0.0f, 0.0f));
                break;
        }

    //  Setup Specular
        if(material.GetFloat("_EnableSpecGloss") == 1.0f) {
            material.EnableKeyword("_SPECGLOSSMAP");
            material.DisableKeyword("_SPECULAR_COLOR");
        }
        else {
           material.DisableKeyword("_SPECGLOSSMAP");
           material.EnableKeyword("_SPECULAR_COLOR"); 
        }

    //  Remap Distortion Strength
        material.SetFloat("_DistortionStrengthScaled", material.GetFloat("_DistortionStrength") * 0.1f);

    //  Remap Camera Fade Strength
        var CameraFade = material.GetVector("_CameraFadeParamsRaw");
        // clamp values
        if (CameraFade.x < 0.0f) {
            CameraFade.x = 0.0f;
        }

        if (CameraFade.y < 0.0f) {
            CameraFade.y = 0.0f;
        }
        material.SetVector("_CameraFadeParamsRaw", CameraFade);
        material.SetVector("_CameraFadeParams", new Vector2(CameraFade.x, 1.0f / (CameraFade.y - CameraFade.x) ));

    //  Set _PERVERTEX_SAMPLEOFFSET Keyword if needed
        if( material.GetFloat("_SampleOffset") > 0.0f && material.GetFloat("_PerVertexShadows") == 1.0f  ) {
            material.EnableKeyword("_PERVERTEX_SAMPLEOFFSET");
        }
        else {
            material.DisableKeyword("_PERVERTEX_SAMPLEOFFSET");
        }


        //if (GUILayout.Button("Check Vertex Streams"))
        //{
            CheckVertexStreams(material, materialEditor);
        //}


	//  Needed to make the Selection Outline work
        if (material.HasProperty("_MainTex") && material.HasProperty("_BaseMap") ) {

        //  Alpha might be stored in the Mask Map
            bool copyMaskMap = false;
            if(material.HasProperty("_AlphaFromMaskMap") && material.HasProperty("_MaskMap")) {
                if (material.GetFloat("_AlphaFromMaskMap") == 1.0) {
                    copyMaskMap = true;
                }
            }
            if (copyMaskMap) {
                if (material.GetTexture("_MaskMap") != null) {
                    material.SetTexture("_MainTex", material.GetTexture("_MaskMap"));
                } 
            }
            else {
                if (material.GetTexture("_BaseMap") != null) {
                    material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
                }
            }
        }
    }


    public void CheckVertexStreams (Material material, MaterialEditor materialEditor) {

        if (GUILayout.Button("Check Vertex Streams")) {
            showVertexSteamArea = true;
        }
        
        if(showVertexSteamArea) {
            m_RenderersUsingThisMaterial.Clear();
            ParticleSystemRenderer[] renderers = UnityEngine.Object.FindObjectsOfType(typeof(ParticleSystemRenderer)) as ParticleSystemRenderer[];
            foreach (ParticleSystemRenderer renderer in renderers) {
                if (renderer.sharedMaterial == material)
                    m_RenderersUsingThisMaterial.Add(renderer);
            }

        //  Build the list of expected vertex streams
            List<ParticleSystemVertexStream> streams = new List<ParticleSystemVertexStream>();

            streams.Add(ParticleSystemVertexStream.Position);
        //  Lit shader!
            streams.Add(ParticleSystemVertexStream.Normal);
            streams.Add(ParticleSystemVertexStream.Color);
            streams.Add(ParticleSystemVertexStream.UV);

            if( material.GetFloat("_ApplyNormal") == 1.0f)
                streams.Add(ParticleSystemVertexStream.Tangent);

            if( material.GetFloat("_FlipbookBlending") == 1.0f) {
                streams.Add(ParticleSystemVertexStream.UV2);
                streams.Add(ParticleSystemVertexStream.AnimBlend);
            }
        //  In case we use per vertex shadows and _SampleOffset > 0 we need velocity
            if( material.GetFloat("_SampleOffset") > 0.0f && material.GetFloat("_PerVertexShadows") == 1.0f  ) {
                streams.Add(ParticleSystemVertexStream.Velocity);
            }

        //  Display a warning if any renderers have incorrect vertex streams
            string Warnings = "";
            List<ParticleSystemVertexStream> rendererStreams = new List<ParticleSystemVertexStream>();
            foreach (ParticleSystemRenderer renderer in renderers) {
                renderer.GetActiveVertexStreams(rendererStreams);
                if (!rendererStreams.SequenceEqual(streams))
                    Warnings += "- " + renderer.name + "\n";
            }

            if (!string.IsNullOrEmpty(Warnings)) {
                EditorGUILayout.HelpBox("The following Particle System Renderers are using this material with incorrect Vertex Streams:\n" + Warnings, MessageType.Error, true);
            //  Set the streams on all systems using this material
                if (GUILayout.Button("Fix Vertex Streams")) {
                    Undo.RecordObjects(renderers.Where(r => r != null).ToArray(), "Fix Vertex Streams");
                    foreach (ParticleSystemRenderer renderer in renderers) {
                        renderer.SetActiveVertexStreams(streams);
                    }
                    showVertexSteamArea = false;
                }
            }
            else {
               Debug.Log("All renderers have proper vertex streams.");
               showVertexSteamArea = false;
            }
        }
        EditorGUILayout.Space();
    }
}