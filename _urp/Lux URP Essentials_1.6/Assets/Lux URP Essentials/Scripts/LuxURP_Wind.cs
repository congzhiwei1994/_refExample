using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
	using UnityEditor;
#endif

namespace LuxURPEssentials
{

	[System.Serializable]
    public enum RTSize {
    	_128 = 128,
        _256 = 256,
        _512 = 512
    }

    [System.Serializable]
    public enum RTFormat {
    	ARGB32 = 0,
        ARGBHalf = 1
    }

    [System.Serializable]
    public enum GustMixLayer {
    	Layer_0 = 0,
        Layer_1 = 1,
        Layer_2 = 2
    }

	[ExecuteInEditMode]
	//[ExecuteAlways]
	[RequireComponent(typeof(WindZone))]
	//[HelpURL("https://docs.google.com/document/d/1ck3hmPzKUdewHfwsvmPYwSPCP8azwtpzN7aOLJHvMqE/edit#heading=h.wnnhm4pxp610")]
	public class LuxURP_Wind : MonoBehaviour {
	//	using order to fix header/button issue
		[Space(5)]
		[LuxURP_HelpBtn("h.wnnhm4pxp610")]
		[Space(-5)]

		public bool UpdateInEditMode = false;
		
		[Header("Render Texture Settings")]

		public RTSize Resolution = RTSize._256;
		public RTFormat Format = RTFormat.ARGB32;
		public Texture WindBaseTex;
		public Shader WindCompositeShader;
		
		[Header("Wind Multipliers")]
		public float Grass = 1.0f;
		public float Foliage = 1.0f; 

		[Header("Wind Speed and Size")]
		[Tooltip("Base Wind Speed in km/h at Main = 1 (WindZone)")]
        public float BaseWindSpeed = 15;
        [Tooltip("Size of the Wind RenderTexture in World Space")]
        public float SizeInWorldSpace = 50;
		[Space(5)]
		public float speedLayer0 = 1.0f;
		public float speedLayer1 = 1.137f;
		public float speedLayer2 = 1.376f;

		[Header("Noise")]
		public int GrassGustTiling = 4;
		public float GrassGustSpeed = 0.278f;
		public GustMixLayer LayerToMixWith = GustMixLayer.Layer_1; 
		
		[Header("Jitter")]
		public float JitterFrequency = 3.127f;
		public float JitterHighFrequency = 21.0f;

	
		private RenderTexture WindRenderTexture;
		private Material m_material;

		private Vector2 uvs = new Vector2(0,0);
		private Vector2 uvs1 = new Vector2(0,0);
		private Vector2 uvs2 = new Vector2(0,0);
		private Vector2 uvs3 = new Vector2(0,0);

		private int WindRTPID;

		private Transform trans;
		private WindZone windZone;
		private float mainWind;
		private float turbulence;

		private int LuxLWRPWindDirSizePID;
		private int LuxLWRPWindStrengthMultipliersPID;
		private int LuxLWRPSinTimePID;
		private int LuxLWRPGustPID;
		private int LuxLWRPGustMixLayerPID;

		private int LuxLWRPWindUVsPID;
		private int LuxLWRPWindUVs1PID;
		private int LuxLWRPWindUVs2PID;
		private int LuxLWRPWindUVs3PID;

		private int previousRTSize;
		private int previousRTFormat;

		private Vector4 WindDirectionSize = Vector4.zero;

		private static Vector3[] MixLayers = new [] { new Vector3(1f,0f,0f), new Vector3(0f,1f,0f), new Vector3(0f,0f,1f)  };

		#if UNITY_EDITOR
			private double lastTimeStamp = 0.0;
		#endif

		void OnEnable () {
			if(WindCompositeShader == null) {
				WindCompositeShader = Shader.Find("Hidden/Lux URP WindComposite");
			}
			if (WindBaseTex == null ) {
				WindBaseTex = Resources.Load("Lux URP default wind base texture") as Texture;
			}
			SetupRT();
			GetPIDs();
			trans = this.transform;
			windZone = trans.GetComponent<WindZone>();

			previousRTSize = (int)Resolution;
			previousRTFormat = (int)Format;

			#if UNITY_EDITOR
				EditorApplication.update += OnEditorUpdate;
			#endif
		}


		void OnDisable () {
			if (WindRenderTexture != null) {
				WindRenderTexture.Release();
				UnityEngine.Object.DestroyImmediate(WindRenderTexture);
			}
			if (m_material != null) {
				UnityEngine.Object.DestroyImmediate(m_material);
				m_material = null;
			}
			if (WindBaseTex != null) {
				WindBaseTex = null;
			}

			#if UNITY_EDITOR
				EditorApplication.update -= OnEditorUpdate;
			#endif
		}

		#if UNITY_EDITOR
			void OnEditorUpdate() {
				if(!Application.isPlaying && UpdateInEditMode) {
					Update();
				//	Unity 2019.1.10 on macOS using Metal also needs this
					SceneView.RepaintAll(); 
				}
			}
		#endif

		void SetupRT () {
			if (WindRenderTexture == null || m_material == null)
	        {
	        	var rtf = ((int)Format == 0) ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGBHalf;
	            WindRenderTexture = new RenderTexture((int)Resolution, (int)Resolution, 0, rtf, RenderTextureReadWrite.Linear );
	            WindRenderTexture.useMipMap = true;
	            WindRenderTexture.wrapMode = TextureWrapMode.Repeat;
	            m_material = new Material(WindCompositeShader);
	        }
		}

		void GetPIDs () {
			WindRTPID = Shader.PropertyToID("_LuxLWRPWindRT");
			LuxLWRPWindDirSizePID = Shader.PropertyToID("_LuxLWRPWindDirSize");
			LuxLWRPWindStrengthMultipliersPID = Shader.PropertyToID("_LuxLWRPWindStrengthMultipliers");
			LuxLWRPSinTimePID = Shader.PropertyToID("_LuxLWRPSinTime");
			LuxLWRPGustPID = Shader.PropertyToID("_LuxLWRPGust");
			LuxLWRPWindUVsPID = Shader.PropertyToID("_LuxLWRPWindUVs");
			LuxLWRPWindUVs1PID = Shader.PropertyToID("_LuxLWRPWindUVs1");
			LuxLWRPWindUVs2PID = Shader.PropertyToID("_LuxLWRPWindUVs2");
			LuxLWRPWindUVs3PID = Shader.PropertyToID("_LuxLWRPWindUVs3");
			LuxLWRPGustMixLayerPID = Shader.PropertyToID("_GustMixLayer");
		}

		void OnValidate () {
			if(WindCompositeShader == null) {
				WindCompositeShader = Shader.Find("Hidden/Lux LWRP WindComposite");
			}
			if (WindBaseTex == null ) {
				WindBaseTex = Resources.Load("Default wind base texture") as Texture;
			}
			if ( (previousRTSize != (int)Resolution ) || ( previousRTFormat != (int)Format ) ) {
				var rtf = ((int)Format == 0) ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGBHalf;
				WindRenderTexture = new RenderTexture((int)Resolution, (int)Resolution, 0, rtf, RenderTextureReadWrite.Linear );
	            WindRenderTexture.useMipMap = true;
	            WindRenderTexture.wrapMode = TextureWrapMode.Repeat;
			}
		}
		
		void Update () {

		//	Get wind settings from WindZone
			mainWind = windZone.windMain;
			turbulence = windZone.windTurbulence;
			
			float delta = Time.deltaTime;

			#if UNITY_EDITOR
				if(!Application.isPlaying) {
					delta = (float)(EditorApplication.timeSinceStartup - lastTimeStamp);
					lastTimeStamp = EditorApplication.timeSinceStartup;
				}
			#endif

			WindDirectionSize.x = trans.forward.x;
			WindDirectionSize.y = trans.forward.y;
			WindDirectionSize.z = trans.forward.z;
			WindDirectionSize.w = 1.0f / SizeInWorldSpace;

			var windVec = new Vector2(WindDirectionSize.x, WindDirectionSize.z ) * delta * (BaseWindSpeed * 0.2777f * WindDirectionSize.w); // * mainWind);

			uvs -= windVec * speedLayer0;
			uvs.x = uvs.x - (int)uvs.x;
			uvs.y = uvs.y - (int)uvs.y;

			uvs1 -= windVec * speedLayer1;
			uvs1.x = uvs1.x - (int)uvs1.x;
			uvs1.y = uvs1.y - (int)uvs1.y;

			uvs2 -= windVec * speedLayer2;
			uvs2.x = uvs2.x - (int)uvs2.x;
			uvs2.y = uvs2.y - (int)uvs2.y;

			uvs3 -= windVec * GrassGustSpeed 			* turbulence;
			uvs3.x = uvs3.x - (int)uvs3.x;
			uvs3.y = uvs3.y - (int)uvs3.y;

		//	Set global shader variables for grass and foliage shaders
			Shader.SetGlobalVector(LuxLWRPWindDirSizePID, WindDirectionSize);

			Vector2 tempWindstrengths;
			tempWindstrengths.x = Grass * mainWind;
			tempWindstrengths.y = Foliage * mainWind;
			Shader.SetGlobalVector(LuxLWRPWindStrengthMultipliersPID, tempWindstrengths );
		//	Use clamped turbulence as otherwise wind direction might get "reversed"
			Shader.SetGlobalVector(LuxLWRPGustPID, new Vector2(GrassGustTiling, Mathf.Clamp( turbulence + 0.5f, 0.0f, 1.5f))  );	
		//	Jitter frequncies and strength
			Shader.SetGlobalVector(LuxLWRPSinTimePID, new Vector4(
				(float)Math.Sin(Time.time * JitterFrequency),
				(float)Math.Sin(Time.time * JitterFrequency * 0.2317f + 2.0f * Mathf.PI),
				(float)Math.Sin(Time.time * JitterHighFrequency),
				turbulence * 0.1f
			));
		

		//	Set UVs
			Shader.SetGlobalVector(LuxLWRPWindUVsPID, uvs);
			Shader.SetGlobalVector(LuxLWRPWindUVs1PID, uvs1);
			Shader.SetGlobalVector(LuxLWRPWindUVs2PID, uvs2);
			Shader.SetGlobalVector(LuxLWRPWindUVs3PID, uvs3);

		//	Set Mix Layer
			Shader.SetGlobalVector(LuxLWRPGustMixLayerPID, MixLayers[(int)LayerToMixWith]);

		#if UNITY_EDITOR
			if (m_material != null && WindRenderTexture != null ) {
		#endif
				Graphics.Blit(WindBaseTex, WindRenderTexture, m_material);
				WindRenderTexture.SetGlobalShaderProperty("_LuxLWRPWindRT"); // only accepts strings...
		#if UNITY_EDITOR
			}
		#endif
			
		}

	#if UNITY_EDITOR
		void OnRenderObject() {
			//Update();
		}
	#endif
	}
}