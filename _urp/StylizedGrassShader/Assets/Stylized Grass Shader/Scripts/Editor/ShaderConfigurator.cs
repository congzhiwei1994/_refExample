//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace StylizedGrass
{
    public class ShaderConfigurator
    {
        public enum Configuration
        {
            VegetationStudio,
            NatureRenderer
        }

        private const string ShaderGUID = "d7dd1c3f4cba1d441a7d295a168bac0d";
        private static string ShaderFilePath;
        private struct CodeBlock
        {
            public int startLine;
            public int endLine;
        }

        private static void RefreshShaderFilePath()
        {
            ShaderFilePath = AssetDatabase.GUIDToAssetPath(ShaderGUID);
        }

#if SGS_DEV
        [MenuItem("SGS/Installation/ConfigureForVegetationStudio")]
#endif
        public static void ConfigureForVegetationStudio()
        {
            RefreshShaderFilePath();

            EditorUtility.DisplayProgressBar("Stylized Grass Shader", "Modifying shader...", 0f);
            {
                ToggleCodeBlock(ShaderFilePath, "NatureRenderer", false);
                ToggleCodeBlock(ShaderFilePath, "VegetationStudio", true);
            }
            EditorUtility.ClearProgressBar();

            Debug.Log("Shader file modified to use Vegetation Studio integration");

        }

#if SGS_DEV
        [MenuItem("SGS/Installation/ConfigureForURP")]
#endif
        public static void ConfigureForNatureRenderer()
        {
            RefreshShaderFilePath();

            EditorUtility.DisplayProgressBar("Stylized Grass Shader", "Modifying shader...", 0f);
            {
                ToggleCodeBlock(ShaderFilePath, "VegetationStudio", false);
                ToggleCodeBlock(ShaderFilePath, "NatureRenderer", true);
            }
            EditorUtility.ClearProgressBar();

            Debug.Log("Shader file modified to use Nature Renderer integration");
        }

        public static void ToggleCodeBlock(string filePath, string id, bool enable)
        {
            string[] lines = File.ReadAllLines(filePath);

            List<CodeBlock> codeBlocks = new List<CodeBlock>();

            //Find start and end line indices
            for (int i = 0; i < lines.Length; i++)
            {
                bool blockEndReached = false;

                if (lines[i].Contains("/* Configuration: ") && enable)
                {
                    lines[i] = lines[i].Replace(lines[i], "/* Configuration: " + id + " */");
                }

                if (lines[i].Contains("start " + id))
                {
                    CodeBlock codeBlock = new CodeBlock();

                    codeBlock.startLine = i;

                    //Find related end point
                    for (int l = codeBlock.startLine; l < lines.Length; l++)
                    {
                        if (blockEndReached == false)
                        {
                            if (lines[l].Contains("end " + id))
                            {
                                codeBlock.endLine = l;

                                blockEndReached = true;
                            }
                        }
                    }

                    codeBlocks.Add(codeBlock);
                    blockEndReached = false;
                }

            }

            if (codeBlocks.Count == 0)
            {
                //Debug.Log("No code blocks with the marker \"" + id + "\" were found in file");

                return;
            }

            foreach (CodeBlock codeBlock in codeBlocks)
            {
                if (codeBlock.startLine == codeBlock.endLine) continue;

                //Debug.Log((enable ? "Enabled" : "Disabled") + " \"" + id + "\" code block. Lines " + (codeBlock.startLine + 1) + " through " + (codeBlock.endLine + 1));

                for (int i = codeBlock.startLine + 1; i < codeBlock.endLine; i++)
                {
                    //Uncomment lines
                    if (enable == true)
                    {
                        if (lines[i].StartsWith("//") == true) lines[i] = lines[i].Remove(0, 2);
                    }
                    //Comment out lines
                    else
                    {
                        if (lines[i].StartsWith("//") == false) lines[i] = "//" + lines[i];
                    }
                }
            }

            File.WriteAllLines(filePath, lines);

            AssetDatabase.ImportAsset(filePath);
        }

        public static Configuration GetConfiguration(Shader shader)
        {
            string filePath = AssetDatabase.GetAssetPath(shader);

            string[] lines = File.ReadAllLines(filePath);

            string configStr = lines[0].Replace("/* Configuration: ", string.Empty);
            configStr = configStr.Replace(" */", string.Empty);

            Configuration config = Configuration.VegetationStudio;

            if (configStr == "NatureRenderer") config = Configuration.NatureRenderer;

            return config;
        }
    }
}