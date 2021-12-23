using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEditor.Rendering.Universal;

namespace UnityEditor
{
	public class LuxUberShaderGUI : ShaderGUI 
	{
	    public enum SurfaceType {
            Opaque,
            Transparent
        }

        public enum BlendMode {
            Alpha,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
            Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
            Additive,
            Multiply
        }
	    
		public enum WorkflowMode {
	    	Specular = 0,
	    	Metallic = 1
        }

	    public enum RenderFace {
	    	Both = 0,
            Back = 1,
            Front = 2
        }

        public enum SmoothnessMapChannel {
            SpecularMetallicAlpha,
            AlbedoAlpha,
        }

        public static class Styles {
        	public static readonly string[] metallicSmoothnessChannelNames = {"Metallic Alpha", "Albedo Alpha"};
            public static readonly string[] specularSmoothnessChannelNames = {"Specular Alpha", "Albedo Alpha"};
        }

        static string url = "https://docs.google.com/document/d/1ck3hmPzKUdewHfwsvmPYwSPCP8azwtpzN7aOLJHvMqE/edit#heading=h.thxlhugei9is";
		static Texture2D helpIcon = EditorGUIUtility.FindTexture("_Help");
	    static GUIContent helpbuttonGUIContent = new GUIContent(helpIcon, "Open Online Documentation");

		public bool openSurfaceOptions = false;
		public bool openSurfaceInputs = false;
		public bool openAdvancedSurfaceInputs = false;
		public bool openRimLighingInputs = false;
		public bool openStencilOptions = false;
		public bool openAdvancedOptions = false;

		private MaterialProperty surfaceOptionsProps;
		private MaterialProperty surfaceInputsProps;
		private MaterialProperty advancedSurfaceInputsProps;
		private MaterialProperty RimLighingInputsProps;
		private MaterialProperty stencilOptionsProps;
		private MaterialProperty advancedOptionsProps;

		
		private MaterialProperty surfaceTypeProp;
		private MaterialProperty blendModeProp;
		private MaterialProperty workflowmodeProp;
		private MaterialProperty ztestProp;

		private MaterialProperty cullingProp;
		private MaterialProperty alphaClipProp;
		private MaterialProperty alphaCutoffProp;
		private MaterialProperty cameraFadingEnabledProp;
		private MaterialProperty cameraFadeDistProp;
		private MaterialProperty cameraFadeShadowsProp;
		private MaterialProperty cameraShadowFadeDistProp;
		private MaterialProperty receiveShadowsProp;

		private MaterialProperty baseColorProp;
		private MaterialProperty baseMapProp;

		private MaterialProperty specGlossMapProp;
		private MaterialProperty specColorProp;

		private MaterialProperty metallicGlossMapProp;
		private MaterialProperty metallicProp;

		private MaterialProperty smoothnessProp;
		private MaterialProperty smoothnessMapChannelProp;

		private MaterialProperty bumpMapProp;
		private MaterialProperty bumpMapScaleProp;
		private MaterialProperty enableNormalProp;

		private MaterialProperty occlusionStrengthProp;
        private MaterialProperty occlusionMapProp;
        private MaterialProperty enableOcclusionProp;

        private MaterialProperty emissionColorProp;
        private MaterialProperty emissionMapProp;
        private MaterialProperty emissionProp;

        private MaterialProperty heightMapProp;
        private MaterialProperty enableParallaxProp;
        private MaterialProperty parallaxProp;
        private MaterialProperty enableParallaxShadowsProp;

        private MaterialProperty BentNormalMapProp;
        private MaterialProperty EnableBentNormalProp;

        private MaterialProperty HorizonOcclusionProp;

        private MaterialProperty GeometricSpecularAAProp;
        private MaterialProperty ScreenSpaceVarianceProp;
        private MaterialProperty SAAThresholdProp;

        private MaterialProperty AOfromGIProp;
        private MaterialProperty GItoAOProp;
        private MaterialProperty GItoAOBiasProp;

        private MaterialProperty RimProp;
        private MaterialProperty RimColorProp;
        private MaterialProperty RimPowerProp;
        private MaterialProperty RimFrequencyProp;
        private MaterialProperty RimMinPowerProp;
        private MaterialProperty RimPerPositionFrequencyProp;

        private MaterialProperty stencilProp;
        private MaterialProperty readMaskProp;
        private MaterialProperty writeMaskProp;
        private MaterialProperty stencilCompProp;
        private MaterialProperty stencilOpProp;
        private MaterialProperty stencilFailProp;
        private MaterialProperty stenciZfailProp;

        private MaterialProperty SpecularHighlightsProps;
        private MaterialProperty EnvironmentReflectionsProps;


/*
		public virtual void OnOpenGUI(Material material, MaterialEditor materialEditor)
	    {
	    	// Foldout states
	            m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
	            m_SurfaceOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceOptionsFoldout", true);
	            foreach (var obj in  materialEditor.targets)
	                MaterialChanged((Material)obj);
	    }
*/

		public virtual void FindProperties(MaterialProperty[] properties)
        {
        	surfaceOptionsProps = FindProperty("_FoldSurfaceOptions", properties);
			surfaceInputsProps = FindProperty("_FoldSurfaceInputs", properties);
			advancedSurfaceInputsProps = FindProperty("_FoldAdvancedSurfaceInputs", properties);
			RimLighingInputsProps = FindProperty("_FoldRimLightingInputs", properties);
			stencilOptionsProps = FindProperty("_FoldStencilOptions", properties);

			advancedOptionsProps = FindProperty("_FoldAdvanced", properties);
			
			surfaceTypeProp = FindProperty("_Surface", properties);
        	blendModeProp = FindProperty("_Blend", properties);
        	workflowmodeProp = FindProperty("_WorkflowMode", properties);
        	ztestProp = FindProperty("_ZTest", properties);

        	cullingProp = FindProperty("_Cull", properties);
        	alphaClipProp = FindProperty("_AlphaClip", properties);
        	alphaCutoffProp = FindProperty("_Cutoff", properties);

			cameraFadingEnabledProp = FindProperty("_CameraFadingEnabled", properties);
			cameraFadeDistProp = FindProperty("_CameraFadeDist", properties);
			cameraFadeShadowsProp = FindProperty("_CameraFadeShadows", properties);
			cameraShadowFadeDistProp = FindProperty("_CameraShadowFadeDist", properties);

        	receiveShadowsProp = FindProperty("_ReceiveShadows", properties, false);


        	baseMapProp = FindProperty("_BaseMap", properties); 
        	baseColorProp = FindProperty("_BaseColor", properties);

        	specGlossMapProp = FindProperty("_SpecGlossMap", properties);
        	specColorProp = FindProperty("_SpecColor", properties);

        	metallicGlossMapProp = FindProperty("_MetallicGlossMap", properties);
			metallicProp = FindProperty("_Metallic", properties);

			smoothnessProp = FindProperty("_Smoothness", properties);
			smoothnessMapChannelProp = FindProperty("_SmoothnessTextureChannel", properties);

        	bumpMapProp = FindProperty("_BumpMap", properties);
			bumpMapScaleProp = FindProperty("_BumpScale", properties);
			enableNormalProp = FindProperty("_EnableNormal", properties);

			occlusionStrengthProp = FindProperty("_OcclusionStrength", properties);
            occlusionMapProp = FindProperty("_OcclusionMap", properties);
            enableOcclusionProp = FindProperty("_EnableOcclusion", properties);

            emissionColorProp = FindProperty("_EmissionColor", properties);
        	emissionMapProp = FindProperty("_EmissionMap", properties);
        	emissionProp = FindProperty("_Emission", properties);

        	//
        	heightMapProp = FindProperty("_HeightMap", properties);
        	parallaxProp = FindProperty("_Parallax", properties);
        	enableParallaxProp = FindProperty("_EnableParallax", properties);
        	enableParallaxShadowsProp = FindProperty("_EnableParallaxShadows", properties);

        	BentNormalMapProp = FindProperty("_BentNormalMap", properties);
        	EnableBentNormalProp = FindProperty("_EnableBentNormal", properties);

        	HorizonOcclusionProp = FindProperty("_HorizonOcclusion", properties);

        	GeometricSpecularAAProp = FindProperty("_GeometricSpecularAA", properties);
        	ScreenSpaceVarianceProp = FindProperty("_ScreenSpaceVariance", properties);
        	SAAThresholdProp = FindProperty("_SAAThreshold", properties);

        	AOfromGIProp = FindProperty("_AOfromGI", properties);
        	GItoAOProp = FindProperty("_GItoAO", properties);
        	GItoAOBiasProp = FindProperty("_GItoAOBias", properties);
        	
        	//
        	RimProp = FindProperty("_Rim", properties);
        	RimColorProp = FindProperty("_RimColor", properties);
        	RimPowerProp = FindProperty("_RimPower", properties);
        	RimFrequencyProp = FindProperty("_RimFrequency", properties);
        	RimMinPowerProp = FindProperty("_RimMinPower", properties);
        	RimPerPositionFrequencyProp = FindProperty("_RimPerPositionFrequency", properties);

        	//
        	stencilProp = FindProperty("_Stencil", properties);
        	readMaskProp = FindProperty("_ReadMask", properties);
        	writeMaskProp = FindProperty("_WriteMask", properties);
        	stencilCompProp = FindProperty("_StencilComp", properties);
        	stencilOpProp = FindProperty("_StencilOp", properties);
        	stencilFailProp = FindProperty("_StencilFail", properties);
        	stenciZfailProp = FindProperty("_StencilZFail", properties);

        	SpecularHighlightsProps = FindProperty("_SpecularHighlights", properties);
        	EnvironmentReflectionsProps = FindProperty("_EnvironmentReflections", properties);
            
        }


	    public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
	    {
	        
	    	Material material = materialEditor.target as Material;

	    	FindProperties(properties);
	    	
	    //	Always needed vars
	    	bool surfaceModeChanged = false;
	    	var workflow = (WorkflowMode)workflowmodeProp.floatValue;
	    	var surface = (SurfaceType)surfaceTypeProp.floatValue;
	    	bool alphaclipChanged = false;
	    	var alphaclip = (alphaClipProp.floatValue == 1)? true : false;


//	-----------------------
//	Help
	    	var txt = new GUIContent("Help");
	    	var position = GUILayoutUtility.GetRect(txt, GUIStyle.none);
	    	var headerPos = new Rect(position.x + 1, position.y, position.width - 20, 20);
			var btnPos = new Rect(position.x + headerPos.width, position.y, 20, 20);
	    	
	    	GUI.Label(headerPos, new GUIContent("Help"), EditorStyles.boldLabel);
	    	if (GUI.Button(btnPos, helpbuttonGUIContent, EditorStyles.boldLabel)) {
				Help.BrowseURL(url);
			}
			GUILayout.Space(10);

//	-----------------------
//	Surface Options

	    	openSurfaceOptions = (surfaceOptionsProps.floatValue == 1.0f) ? true : false;
	    	EditorGUI.BeginChangeCheck();
	    	openSurfaceOptions = EditorGUILayout.BeginFoldoutHeaderGroup(openSurfaceOptions, "Surface Options");
	    	if (EditorGUI.EndChangeCheck()) {
	    		surfaceOptionsProps.floatValue = openSurfaceOptions? 1.0f : 0.0f;
	    	}
	        
	        if(openSurfaceOptions){

	        //	Workflow
	        	EditorGUI.BeginChangeCheck();
	            //var workflow = (WorkflowMode)workflowmodeProp.floatValue;
            	workflow = (WorkflowMode)EditorGUILayout.EnumPopup("Workflow Mode", workflow);
	            if (EditorGUI.EndChangeCheck()) {
	                materialEditor.RegisterPropertyChangeUndo("Workflow Mode");
	                workflowmodeProp.floatValue = (float)workflow;
	                if((float)workflow == 0.0f) {
	                	material.EnableKeyword("_SPECULAR_SETUP");
	                }
	                else {
	                	material.DisableKeyword("_SPECULAR_SETUP");
	                }
	            }

	        //	Surface
	        	EditorGUI.BeginChangeCheck();
	        	//var surface = (SurfaceType)surfaceTypeProp.floatValue;
	        	surface = (SurfaceType)EditorGUILayout.EnumPopup("Surface Type", surface);
	        	if (EditorGUI.EndChangeCheck()) {
	        		materialEditor.RegisterPropertyChangeUndo("Surface Type");
	        		surfaceModeChanged = true;
	        		surfaceTypeProp.floatValue = (float)surface;
	        		if (surface == SurfaceType.Opaque) {
	        			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                		material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                		material.SetInt("_ZWrite", 1);
	        			material.SetOverrideTag("RenderType", "Opaque");
	        			material.renderQueue = (int)RenderQueue.Geometry;
	        			material.SetShaderPassEnabled("ShadowCaster", true);
	        		}
	        		else {
	        			material.SetOverrideTag("RenderType", "Transparent");
	        			material.SetInt("_ZWrite", 0);
	        			material.renderQueue = (int)RenderQueue.Transparent;
	        			material.SetShaderPassEnabled("ShadowCaster", false);
	        		}
	        	}

	        //	Culling
	        	EditorGUI.BeginChangeCheck();
	            var culling = (RenderFace)cullingProp.floatValue;
            	culling = (RenderFace)EditorGUILayout.EnumPopup("Render Face", culling);
	            if (EditorGUI.EndChangeCheck())
	            {
	                materialEditor.RegisterPropertyChangeUndo("Cull");
	                cullingProp.floatValue = (float)culling;
	                material.doubleSidedGI = (RenderFace)cullingProp.floatValue != RenderFace.Front;
	            }
	        
	        //	Alpha Clipping
//	Allow alpha clipping for transparents as well	            
//	        	if (surface == SurfaceType.Opaque) { 
	        		EditorGUI.BeginChangeCheck();
	        		alphaclip = EditorGUILayout.Toggle(new GUIContent("Alpha Clipping"), alphaClipProp.floatValue == 1);
	        	//	Make sure we set alpha clip if surface type has changed only as well
	        		if (EditorGUI.EndChangeCheck() || surfaceModeChanged) {
	        			alphaclipChanged = true;
	        			if (alphaclip) {
	        				alphaClipProp.floatValue = 1;
	        				material.EnableKeyword("_ALPHATEST_ON");
	        				if (surface == SurfaceType.Opaque) {
	        					material.renderQueue = (int)RenderQueue.AlphaTest;
                    			material.SetOverrideTag("RenderType", "TransparentCutout");
                    		}

                    	//	We may have to re eanble camera fading
                    		if(cameraFadingEnabledProp.floatValue == 1) {
	        					material.EnableKeyword("_FADING_ON");
		        				if(cameraFadeShadowsProp.floatValue == 1) {
		        					material.EnableKeyword("_FADING_SHADOWS_ON");
		        				}
		        				else {
		        					material.DisableKeyword("_FADING_SHADOWS_ON");
		        				}
		        			}
		        			else {
		        				material.DisableKeyword("_FADING_ON");
		        				material.DisableKeyword("_FADING_SHADOWS_ON");
		        			}

	        			}
	        			else {
	        				alphaClipProp.floatValue = 0;
	        				material.DisableKeyword("_ALPHATEST_ON");
	        				if (surface == SurfaceType.Opaque) {
	        					material.renderQueue = (int)RenderQueue.Geometry;
                    			material.SetOverrideTag("RenderType", "Opaque");
	        					material.DisableKeyword("_FADING_ON");
	        					material.DisableKeyword("_FADING_SHADOWS_ON");
	        				}
	        			}
	        		}
	        		if (alphaclip) {
	        			materialEditor.ShaderProperty(alphaCutoffProp, "Threshold", 1);
	        		}
//	        	}

	        //	Camera Fading
	        	if (alphaclip) {
	        		EditorGUI.BeginChangeCheck();
	        		materialEditor.ShaderProperty(cameraFadingEnabledProp, "Camera Fading", 1);
	        		materialEditor.ShaderProperty(cameraFadeDistProp, "Fade Distance", 2);
	        		materialEditor.ShaderProperty(cameraFadeShadowsProp, "Fade Shadows", 2);
	        		materialEditor.ShaderProperty(cameraShadowFadeDistProp, "Shadow Fade Dist", 2);

	        		if (EditorGUI.EndChangeCheck()) {
	        			if(cameraFadingEnabledProp.floatValue == 1) {
	        				material.EnableKeyword("_FADING_ON");
	        				if(cameraFadeShadowsProp.floatValue == 1) {
	        					material.EnableKeyword("_FADING_SHADOWS_ON");
	        				}
	        				else {
	        					material.DisableKeyword("_FADING_SHADOWS_ON");
	        				}
	        			}
	        			else {
	        				material.DisableKeyword("_FADING_ON");
	        				material.DisableKeyword("_FADING_SHADOWS_ON");
	        			}
	        		}
	        	}
	        	else {
	        		material.DisableKeyword("_FADING_ON");
	        		material.DisableKeyword("_FADING_SHADOWS_ON");
	        	}

	        //	Shadows
	        	EditorGUI.BeginChangeCheck();
                var receiveShadows = EditorGUILayout.Toggle(new GUIContent("Receive Shadows"), receiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck()) {
                    receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
                    if(receiveShadows) {
                    	material.DisableKeyword("_RECEIVE_SHADOWS_OFF");
                    }
                    else {
                    	material.EnableKeyword("_RECEIVE_SHADOWS_OFF");
                    }
                }


	        //	Transparency
	        	if (surface == SurfaceType.Transparent) {
	    			EditorGUI.BeginChangeCheck();
	    			//DoPopup(Styles.blendingMode, blendModeProp, Enum.GetNames(typeof(BlendMode)));
	    			var blendMode = (BlendMode)blendModeProp.floatValue;
	    			blendMode = (BlendMode)EditorGUILayout.EnumPopup("Blend Mode", blendMode);
	    		//	Make sure we set blend mode if surface type has changed only as well
	    			if (EditorGUI.EndChangeCheck() || surfaceModeChanged) {
	    				blendModeProp.floatValue = (float)blendMode;

	    				material.DisableKeyword("_ALPHATEST_ON");

	    				switch (blendMode) {
		                    case BlendMode.Alpha:
		                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
		                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
		                        material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
		                        break;
		                    case BlendMode.Premultiply:
		                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
		                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
		                        material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
		                        break;
		                    case BlendMode.Additive:
		                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
		                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
		                        material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
		                        break;
		                    case BlendMode.Multiply:
		                        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
		                        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
		                        material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
		                        material.EnableKeyword("_ALPHAMODULATE_ON");
		                        break;
		                }
	    			}
	    		}

	    	//	ZTesting
	        	EditorGUI.BeginChangeCheck();
	            var ztest = (UnityEngine.Rendering.CompareFunction)ztestProp.floatValue;
            	ztest = (UnityEngine.Rendering.CompareFunction)EditorGUILayout.EnumPopup("ZTest", ztest);
	            if (EditorGUI.EndChangeCheck())
	            {
	                materialEditor.RegisterPropertyChangeUndo("ZTest");
	                ztestProp.floatValue = (float)ztest;
	            }

	        //	Spacing
	            EditorGUILayout.Space();
	        }
	        EditorGUILayout.EndFoldoutHeaderGroup();

//	-----------------------
//	Surface Inputs

			openSurfaceInputs = (surfaceInputsProps.floatValue == 1.0f) ? true : false;
	        EditorGUI.BeginChangeCheck();
	        openSurfaceInputs = EditorGUILayout.BeginFoldoutHeaderGroup(openSurfaceInputs, "Surface Inputs");
	        if (EditorGUI.EndChangeCheck()) {
	    		surfaceInputsProps.floatValue = openSurfaceInputs? 1.0f : 0.0f;
	    	}
	        if(openSurfaceInputs){
	        	EditorGUILayout.Space();
	        	
	        //	Basemap / Color
	        	materialEditor.TexturePropertySingleLine(new GUIContent("Base Map"), baseMapProp, baseColorProp);

	        //	Metallic
	        	string[] smoothnessChannelNames;
	            bool hasGlossMap = false;
	            if ((WorkflowMode)workflowmodeProp.floatValue == WorkflowMode.Metallic) {
	                hasGlossMap = metallicGlossMapProp.textureValue != null;
	                smoothnessChannelNames = Styles.metallicSmoothnessChannelNames;
	                EditorGUI.BeginChangeCheck();
	                materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map"), metallicGlossMapProp, hasGlossMap ? null : metallicProp);
	            	if (EditorGUI.EndChangeCheck()) {
	                	if(metallicGlossMapProp.textureValue != null) {
	                		material.EnableKeyword("_METALLICSPECGLOSSMAP");
	                	}
	                	else {
	                		material.DisableKeyword("_METALLICSPECGLOSSMAP");
	                	}
	                }
	            }

	        //	Specular
	            else {
	                hasGlossMap = specGlossMapProp.textureValue != null;
	                smoothnessChannelNames = Styles.specularSmoothnessChannelNames;
	                EditorGUI.BeginChangeCheck();
	                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map"), specGlossMapProp, hasGlossMap ? null : specColorProp);
	                if (EditorGUI.EndChangeCheck()) {
	                	if(specGlossMapProp.textureValue != null) {
	                		material.EnableKeyword("_METALLICSPECGLOSSMAP");
	                	}
	                	else {
	                		material.DisableKeyword("_METALLICSPECGLOSSMAP");
	                	}
	                }
	            }

	        //	Smoothness
	            EditorGUI.indentLevel++;
	            	EditorGUI.indentLevel++;
			            EditorGUI.BeginChangeCheck();
			            EditorGUI.showMixedValue = smoothnessProp.hasMixedValue;
			            var smoothness = EditorGUILayout.Slider("Smoothness", smoothnessProp.floatValue, 0f, 1f);
			            if (EditorGUI.EndChangeCheck())
			                smoothnessProp.floatValue = smoothness;
			            EditorGUI.showMixedValue = false;
			        EditorGUI.indentLevel--;
			    //	Chose Smoothness Cannel in case we have any GlossMap
		            //if (hasGlossMap) {
		                EditorGUI.indentLevel++;

						EditorGUI.BeginDisabledGroup(surface != SurfaceType.Opaque);
		                EditorGUI.BeginChangeCheck();
		                EditorGUI.showMixedValue = smoothnessMapChannelProp.hasMixedValue;
		                var smoothnessSource = (int) smoothnessMapChannelProp.floatValue;
		            //	This is correct, but it does not allow fading
		                if (surface == SurfaceType.Opaque && !alphaclip) {
		                	smoothnessSource = EditorGUILayout.Popup(new GUIContent("Source"), smoothnessSource, smoothnessChannelNames);
		                }
		                else {
		                	GUI.enabled = false;
		                    	EditorGUILayout.Popup(new GUIContent("Source"), 0, smoothnessChannelNames);
		                    	material.DisableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
		                    GUI.enabled = true;
		                }
		            //	Make sure we set the proper keyword even if only alphaclip has changed as well
		                if (EditorGUI.EndChangeCheck() || alphaclipChanged ) {
		                    smoothnessMapChannelProp.floatValue = smoothnessSource;
		                    if (smoothnessSource == 1) {
		                    	material.EnableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
		                    }
		                    else {
		                    	material.DisableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
		                    }
		                }
		                EditorGUI.showMixedValue = false;
		            	EditorGUI.EndDisabledGroup();
		                EditorGUI.indentLevel--;
		            //}
		        //	We may still sample from Albedo alpha
/*		        	else {
		        	//	We can not sample smoothness from albedo alpha of the shader is transparent
		        		if (surface == SurfaceType.Opaque && !alphaclip) {
		        			EditorGUI.indentLevel++;
		        				EditorGUI.BeginChangeCheck();
				        		var smoothnessFromAlbedoAlpha = EditorGUILayout.Toggle(new GUIContent("Source Albedo Alpha"), smoothnessMapChannelProp.floatValue == 1);
				        		if (EditorGUI.EndChangeCheck()) {
				        			if (smoothnessFromAlbedoAlpha) {
				        				smoothnessMapChannelProp.floatValue = 1;
				        				material.EnableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
				        			}
				        			else {
				        				smoothnessMapChannelProp.floatValue = 0;
				        				material.DisableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
				        			}
				        		}
				        	EditorGUI.indentLevel--;
			        	}
			        	else {
			        		smoothnessMapChannelProp.floatValue = 0;
				        	material.DisableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
			        	}
		        	}
		*/        	
	            EditorGUI.indentLevel--;

	        //	Normal
	        //	NOTE: _NORMALMAP is needed by Bent normal as well: see sh lighting.
	        	EditorGUI.BeginChangeCheck();
	        	materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), bumpMapProp, bumpMapScaleProp);
	        	if (EditorGUI.EndChangeCheck() || bumpMapProp.textureValue == null ) {
	        		if(bumpMapProp.textureValue != null && bumpMapScaleProp.floatValue != 0.0f) {
	        			material.EnableKeyword("_NORMALMAP");
	        			material.EnableKeyword("_SAMPLENORMAL");
	        			enableNormalProp.floatValue = 1.0f;
	        		}
	        		else {
	        			if (BentNormalMapProp.textureValue == null) {
	        				material.DisableKeyword("_NORMALMAP");
	        			}
	        			material.DisableKeyword("_SAMPLENORMAL");
	        			enableNormalProp.floatValue = 0.0f;
	        		}
	            }

	        //	Occlusion
	        	EditorGUI.BeginChangeCheck();
	        	materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map"), occlusionMapProp, occlusionMapProp.textureValue != null ? occlusionStrengthProp : null);
                if (EditorGUI.EndChangeCheck()) {
                	if (occlusionMapProp.textureValue != null && occlusionStrengthProp.floatValue > 0 ) {
                		material.EnableKeyword("_OCCLUSIONMAP");
                		enableOcclusionProp.floatValue = 1;
                	}
                	else {
                		material.DisableKeyword("_OCCLUSIONMAP");
                		enableOcclusionProp.floatValue = 0;
                	}
                }
            
	        //	Emission
	        	EditorGUI.BeginChangeCheck();
	        	var emission = EditorGUILayout.Toggle(new GUIContent("Emission"), (emissionProp.floatValue == 1)? true : false );
	        	if (EditorGUI.EndChangeCheck()) {
	        		if (emission) {
	        			material.EnableKeyword("_EMISSION");
	        			emissionProp.floatValue = 1;
	        		}
	        		else {
	        			material.DisableKeyword("_EMISSION");
	        			emissionProp.floatValue = 0;
	        		}
	        	}
	        	if (emission) {
	        		EditorGUI.BeginChangeCheck();
	        		materialEditor.TexturePropertyWithHDRColor(new GUIContent("Emission Map"), emissionMapProp, emissionColorProp, false);
	        		if (EditorGUI.EndChangeCheck()) {
	        			var brightness = emissionColorProp.colorValue.maxColorComponent;
	        			material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
	        			if (brightness <= 0f) {
                    		material.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                    	}
	        		}
	        	}

	        //	Tiling
	        	EditorGUILayout.Space();
	        	materialEditor.TextureScaleOffsetProperty(baseMapProp);

		    //	Spacing
		        EditorGUILayout.Space();
	        }
	        EditorGUILayout.EndFoldoutHeaderGroup();

//	-----------------------
//	Advanced Surface Inputs

GUIContent labeltooltip;

			openAdvancedSurfaceInputs = (advancedSurfaceInputsProps.floatValue == 1.0f) ? true : false;
	        EditorGUI.BeginChangeCheck();	       
	        openAdvancedSurfaceInputs = EditorGUILayout.BeginFoldoutHeaderGroup(openAdvancedSurfaceInputs, "Advanced Surface Inputs");
	        if (EditorGUI.EndChangeCheck()) {
	    		advancedSurfaceInputsProps.floatValue = openAdvancedSurfaceInputs? 1.0f : 0.0f;
	    	}
	        if (openAdvancedSurfaceInputs) {
	        	EditorGUILayout.Space();
	        	
	        //	Parallax
	        	EditorGUI.BeginChangeCheck();
labeltooltip = new GUIContent("Height Map (G)", "RGB texture which stores height in the green color channel used by parallax extrusion.");
	        	materialEditor.TexturePropertySingleLine(new GUIContent("Height Map (G)"), heightMapProp, heightMapProp.textureValue != null ? parallaxProp : null);
                if (EditorGUI.EndChangeCheck()) {
                	if ( (heightMapProp.textureValue != null) && (parallaxProp.floatValue > 0) ) {
                		material.EnableKeyword("_PARALLAX");
                		enableParallaxProp.floatValue = 1;
                	}
                	else {
                		material.DisableKeyword("_PARALLAX");
                		enableParallaxProp.floatValue = 0;
                	}
                }
                if ( alphaclip && (heightMapProp.textureValue != null) && (parallaxProp.floatValue > 0) ) {
	                EditorGUI.BeginChangeCheck();
labeltooltip = new GUIContent("Parallax Shadows", "If checked the shader will apply parallax mapping even in the shadow caster pass. This is somehow correct for directional shadows where we can derive the view direction from the (shadow) camera’s forward vector but not in case we render spot lights. Furthermore even parallax directional shadow casters are quite unstable if you rotate the camera. So check if you really need this..."); 
	        		var pShadows = EditorGUILayout.Toggle(labeltooltip, enableParallaxShadowsProp.floatValue == 1);
	        		if (EditorGUI.EndChangeCheck() || surfaceModeChanged) {
	        			if (pShadows) {
	        				enableParallaxShadowsProp.floatValue = 1;
	        				material.EnableKeyword("_PARALLAXSHADOWS");
	        			}
	        			else {
	        				enableParallaxShadowsProp.floatValue = 0;
	        				material.DisableKeyword("_PARALLAXSHADOWS");
	        			}
	        		}
	        		EditorGUILayout.Space();
	        	}
	        	else {
	        		enableParallaxShadowsProp.floatValue = 0;
	        		material.DisableKeyword("_PARALLAXSHADOWS");
	        	}




	        //	Bent Normals
	        	EditorGUI.BeginChangeCheck();
labeltooltip = new GUIContent("Bent Normal Map", "Cosine weighted Bent Normal Map in tangent space. If assigned the shader will tweak ambient diffuse lighting and ambient specular reflections.");
	        	materialEditor.TexturePropertySingleLine(labeltooltip, BentNormalMapProp);
                if (EditorGUI.EndChangeCheck()) {
	        		if (BentNormalMapProp.textureValue != null) {
        				EnableBentNormalProp.floatValue = 1;
        				material.EnableKeyword("_BENTNORMAL");
        				material.EnableKeyword("_NORMALMAP");	
           			}
        			else {
        				EnableBentNormalProp.floatValue = 0;
        				material.DisableKeyword("_BENTNORMAL");
        				if(bumpMapProp.textureValue == null) {
        					material.DisableKeyword("_NORMALMAP");	
        				}
        			}
	        	}

	        //	Horizon Occlusion
labeltooltip = new GUIContent("Horizon Occlusion", "Terminates light leaking caused by normal mapped ambient specular reflections where the reflection vector might end up pointing behind the surface being rendered.");
	        	materialEditor.ShaderProperty(HorizonOcclusionProp, labeltooltip, 0);
	        	

	        //	Specular AA
	        	EditorGUI.BeginChangeCheck();

labeltooltip = new GUIContent("Geometric Specular AA", "When enabled the shader reduces specular aliasing on high density meshes by reducing smoothness at grazing angles.");
	        	var specAA = EditorGUILayout.Toggle(labeltooltip, GeometricSpecularAAProp.floatValue == 1);
	        	if (EditorGUI.EndChangeCheck()) {
	        		if (specAA) {
        				GeometricSpecularAAProp.floatValue = 1;
        				material.EnableKeyword("_ENABLE_GEOMETRIC_SPECULAR_AA");
        			}
        			else {
        				GeometricSpecularAAProp.floatValue = 0;
        				material.DisableKeyword("_ENABLE_GEOMETRIC_SPECULAR_AA");
        			}
	        	}
	        	if (specAA) {
labeltooltip = new GUIContent("Screen Space Variance", "Controls the amount of Specular AA. Higher values give a more blurry result.");
	        		materialEditor.ShaderProperty(ScreenSpaceVarianceProp, labeltooltip, 1);
labeltooltip = new GUIContent("Threshold", "Controls the amount of Specular AA. Higher values allow higher reduction.");
	        		materialEditor.ShaderProperty(SAAThresholdProp, labeltooltip, 1);
	        	}

	        //	GI TO AO
        		EditorGUI.BeginChangeCheck();
labeltooltip = new GUIContent("GI to Specular Occlusion", "In case you use lightmaps you may activate this feature to derive some kind of specular occlusion just from the lightmap and its baked ambient occlusion.");        		
	        	var GIAO = EditorGUILayout.Toggle(labeltooltip, AOfromGIProp.floatValue == 1);
	        	if (EditorGUI.EndChangeCheck()) {
	        		if (GIAO) {
        				AOfromGIProp.floatValue = 1;
        				material.EnableKeyword("_ENABLE_AO_FROM_GI");
        			}
        			else {
        				AOfromGIProp.floatValue = 0;
        				material.DisableKeyword("_ENABLE_AO_FROM_GI");
        			}
	        	}
	        	if (GIAO) {
labeltooltip = new GUIContent("GI to AO Factor", "Controls the amount of specular occlusion. It acts as a factor to brighten the value sampled from the lightmap.");
	        		materialEditor.ShaderProperty(GItoAOProp, labeltooltip, 1);
labeltooltip = new GUIContent("Bias", "Adds a constant value to brighten the value sampled from the lightmap.");	        		
	        		materialEditor.ShaderProperty(GItoAOBiasProp, labeltooltip, 1);
	        	}


        	//	Spacing
	        	EditorGUILayout.Space();
			}
			EditorGUILayout.EndFoldoutHeaderGroup();

//	-----------------------
//	Rim Lighting
			openRimLighingInputs = (RimLighingInputsProps.floatValue == 1.0f) ? true : false;
	        EditorGUI.BeginChangeCheck();
	        openRimLighingInputs = EditorGUILayout.BeginFoldoutHeaderGroup(openRimLighingInputs, "Rim Lighting");
	        if (EditorGUI.EndChangeCheck()) {
	    		RimLighingInputsProps.floatValue = openRimLighingInputs? 1.0f : 0.0f;
	    	}
	        if(openRimLighingInputs){
	        	
	        //	Rim
	        	EditorGUI.BeginChangeCheck();
	        	materialEditor.ShaderProperty(RimProp, "Enable Rim Lighting", 0);
	        	materialEditor.ShaderProperty(RimColorProp, "Rim Color", 0);
	        	materialEditor.ShaderProperty(RimPowerProp, "Rim Power", 0);
	        	materialEditor.ShaderProperty(RimFrequencyProp, "Rim Frequency", 0);
	        	materialEditor.ShaderProperty(RimMinPowerProp, "Rim Min Power", 1);
	        	materialEditor.ShaderProperty(RimPerPositionFrequencyProp, "Rim Per Position Frequency", 1);
	        	if (EditorGUI.EndChangeCheck()) {
	        		if(RimProp.floatValue == 1) {
	        			material.EnableKeyword("_RIMLIGHTING");
	        		}
	        		else {
	        			material.DisableKeyword("_RIMLIGHTING");
	        		}
	        	}

	        	EditorGUILayout.Space();
			}


			EditorGUILayout.EndFoldoutHeaderGroup();


//	-----------------------
//	Stencil Inputs
			openStencilOptions = (stencilOptionsProps.floatValue == 1.0f) ? true : false;
	        EditorGUI.BeginChangeCheck();
	        openStencilOptions = EditorGUILayout.BeginFoldoutHeaderGroup(openStencilOptions, "Stencil Options");
	        if (EditorGUI.EndChangeCheck()) {
	    		stencilOptionsProps.floatValue = openStencilOptions? 1.0f : 0.0f;
	    	}
	        if(openStencilOptions){
	        	
	        //	Stencil
	        	materialEditor.ShaderProperty(stencilProp, "Stencil Reference", 0);
	        	materialEditor.ShaderProperty(readMaskProp, "Read Mask", 0);
	        	materialEditor.ShaderProperty(writeMaskProp, "Write Mask", 0);
	        	materialEditor.ShaderProperty(stencilCompProp, "Stencil Comparison", 0);
	        	materialEditor.ShaderProperty(stencilOpProp, "Stencil Operation", 0);
	        	materialEditor.ShaderProperty(stencilFailProp, "Stencil Fail Op", 0);
	        	materialEditor.ShaderProperty(stenciZfailProp, "Stencil ZFail Op", 0);

	        	EditorGUILayout.Space();
			}


			EditorGUILayout.EndFoldoutHeaderGroup();

//	-----------------------
//	Advanced Settings
			openAdvancedOptions = (advancedOptionsProps.floatValue == 1.0f) ? true : false;
	        EditorGUI.BeginChangeCheck();
	        openAdvancedOptions = EditorGUILayout.BeginFoldoutHeaderGroup(openAdvancedOptions, "Advanced");
	        if (EditorGUI.EndChangeCheck()) {
	    		advancedOptionsProps.floatValue = openAdvancedOptions? 1.0f : 0.0f;
	    	}
	    	if (openAdvancedOptions) {
	    		EditorGUI.BeginChangeCheck();
	    		materialEditor.ShaderProperty(SpecularHighlightsProps, "Specular Highlights", 0);
	    		materialEditor.ShaderProperty(EnvironmentReflectionsProps, "Environment Reflections", 0);
	    		materialEditor.EnableInstancingField();
	    		materialEditor.RenderQueueField();
	    		if (EditorGUI.EndChangeCheck()) {
	    			if(SpecularHighlightsProps.floatValue == 1) {
	    				material.DisableKeyword("_SPECULARHIGHLIGHTS_OFF");
	    			}
	    			else {
	    				material.EnableKeyword("_SPECULARHIGHLIGHTS_OFF");
	    			}
	    			if(EnvironmentReflectionsProps.floatValue == 1) {
	    				material.DisableKeyword("_ENVIRONMENTREFLECTIONS_OFF");
	    			}
	    			else {
	    				material.EnableKeyword("_ENVIRONMENTREFLECTIONS_OFF");
	    			}
	    		}
	    		EditorGUILayout.Space();
	    	}

	    	EditorGUILayout.EndFoldoutHeaderGroup();

	    //	Fix all the missing stuff

	    //  Needed to make the Selection Outline work
	    //	Lightmapper needs it for alpha testing?!
	    	if (material.HasProperty("_MainTex") && material.HasProperty("_BaseMap") ) {
	            if (material.GetTexture("_BaseMap") != null) {
	                material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
	            }
        	}		
	    }
	}
}