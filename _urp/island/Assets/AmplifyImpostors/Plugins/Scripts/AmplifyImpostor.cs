// Amplify Impostors
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>

//#define AI_DEBUG_MODE

using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
using System.Text.RegularExpressions;
#endif

namespace AmplifyImpostors
{
	public enum LODReplacement
	{
		DoNothing = 0,
		ReplaceCulled = 1,
		ReplaceLast = 2,
		ReplaceAllExceptFirst = 3,
		ReplaceSpecific = 4,
		ReplaceAfterSpecific = 5,
		InsertAfter = 6
	}

	public enum CutMode
	{
		Automatic = 0,
		Manual = 1
	}

	public enum FolderMode
	{
		RelativeToPrefab = 0,
		Global = 1
	}

	public enum RenderPipelineInUse
	{
		None = 0,
		LW = 1,
		HD = 2,
		Custom = 3
	}

#if UNITY_EDITOR
	[Serializable]
	public class DataHolder
	{
		public bool SRGB = true;
		public bool Alpha = true;
		public TextureCompression Compression = TextureCompression.Normal;
		public int MaxSize = -1;
		public DataHolder() { }

		public DataHolder( bool sRGB, TextureCompression compression, bool alpha, int maxSize )
		{
			SRGB = sRGB;
			Compression = compression;
			Alpha = alpha;
			MaxSize = maxSize;
		}
	}

	public class AmplifyTextureImporter : AssetPostprocessor
	{
		public static bool Activated = false;
		public static Dictionary<string, DataHolder> ImportData = new Dictionary<string, DataHolder>();
		void OnPreprocessTexture()
		{
			if( Activated )
			{
				DataHolder data = new DataHolder();
				if( ImportData.TryGetValue( assetPath, out data ) )
				{
					TextureImporter textureImporter = (TextureImporter)assetImporter;
					textureImporter.sRGBTexture = data.SRGB;
					textureImporter.alphaSource = data.Alpha ? TextureImporterAlphaSource.FromInput : TextureImporterAlphaSource.None;
					textureImporter.textureCompression = (TextureImporterCompression)data.Compression;
					if( data.MaxSize > -1 )
						textureImporter.maxTextureSize = data.MaxSize;
				}
			}
		}
	}
#endif
	public class AmplifyImpostor : MonoBehaviour
	{
		private const string ShaderGUID = "e82933f4c0eb9ba42aab0739f48efe21";
		private const string DilateGUID = "57c23892d43bc9f458360024c5985405";
		private const string PackerGUID = "31bd3cd74692f384a916d9d7ea87710d";
		private const string ShaderOctaGUID = "572f9be5706148142b8da6e9de53acdb";
		private const string StandardPreset = "e4786beb7716da54dbb02a632681cc37";

		private const string LWPreset = "089f3a2f6b5f48348a48c755f8d9a7a2";
		private const string LWShaderOctaGUID = "94e2ddcdfb3257a43872042f97e2fb01";
		private const string LWShaderGUID = "990451a2073f6994ebf9fd6f90a842b3";

		private const string HDPreset = "47b6b3dcefe0eaf4997acf89caf8c75e";
		private const string HDShaderOctaGUID = "56236dc63ad9b7949b63a27f0ad180b3";
		private const string HDShaderGUID = "175c951fec709c44fa2f26b8ab78b8dd";

		[SerializeField]
		private AmplifyImpostorAsset m_data;
		public AmplifyImpostorAsset Data { get { return m_data; } set { m_data = value; } }

		[SerializeField]
		private Transform m_rootTransform;
		public Transform RootTransform { get { return m_rootTransform; } set { m_rootTransform = value; } }

		[SerializeField]
		private LODGroup m_lodGroup;
		public LODGroup LodGroup { get { return m_lodGroup; } set { m_lodGroup = value; } }

		[SerializeField]
		private Renderer[] m_renderers;
		public Renderer[] Renderers { get { return m_renderers; } set { m_renderers = value; } }

		public LODReplacement m_lodReplacement = LODReplacement.ReplaceLast;

		[SerializeField]
		public RenderPipelineInUse m_renderPipelineInUse = RenderPipelineInUse.None;

		public int m_insertIndex = 1;

		[SerializeField]
		public GameObject m_lastImpostor;

		[SerializeField]
		public string m_folderPath;

		[NonSerialized]
		public string m_impostorName = string.Empty;

		[SerializeField]
		public CutMode m_cutMode = CutMode.Automatic;

		[NonSerialized]
		private const float StartXRotation = -90;
		[NonSerialized]
		private const float StartYRotation = 90;
		[NonSerialized]
		private const int MinAlphaResolution = 256;
		[NonSerialized]
		private RenderTexture[] m_rtGBuffers;
		[NonSerialized]
		private RenderTexture[] m_alphaGBuffers;
		[NonSerialized]
		private RenderTexture m_trueDepth;
		[NonSerialized]
		public Texture2D m_alphaTex;
		[NonSerialized]
		private float m_xyFitSize = 0;
		[NonSerialized]
		private float m_depthFitSize = 0;
		[NonSerialized]
		private Vector2 m_pixelOffset = Vector2.zero;

		[NonSerialized]
		private Bounds m_originalBound = new Bounds();

		[NonSerialized]
		private Vector3 m_oriPos = Vector3.zero;

		[NonSerialized]
		private Quaternion m_oriRot = Quaternion.identity;

		[NonSerialized]
		private Vector3 m_oriSca = Vector3.one;

		[NonSerialized]
		private const int BlockSize = 65536;
#if UNITY_EDITOR
		[NonSerialized]
		private readonly string[] m_propertyNames = { "_Albedo", "_Specular", "_Normals", "_Emission" };

		[NonSerialized]
		private string[] m_standardFileNames = { string.Empty, string.Empty, string.Empty, string.Empty };

		[NonSerialized]
		private string[] m_fileNames = { string.Empty, string.Empty, string.Empty, string.Empty };
#endif

#if AI_DEBUG_MODE
		[SerializeField]
		private string m_renderInfo = string.Empty;
		public string RenderInfo { get { return m_renderInfo; } set { m_renderInfo = value; } }
		public bool m_createGameobject = true;
		public bool m_generateQuad = true;
#endif

		private void GenerateTextures( List<TextureOutput> outputList )
		{
			m_rtGBuffers = new RenderTexture[ outputList.Count ];
			for( int i = 0; i < m_rtGBuffers.Length; i++ )
			{
				m_rtGBuffers[ i ] = new RenderTexture( (int)m_data.TexSize.x, (int)m_data.TexSize.y, 16, outputList[ i ].SRGB ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGBHalf );
				m_rtGBuffers[ i ].Create();
			}

			m_trueDepth = new RenderTexture( (int)m_data.TexSize.x, (int)m_data.TexSize.y, 16, RenderTextureFormat.Depth );
			m_trueDepth.Create();
		}

		private void GenerateAlphaTextures( List<TextureOutput> outputList )
		{
			m_alphaGBuffers = new RenderTexture[ outputList.Count ];

			for( int i = 0; i < m_alphaGBuffers.Length; ++i )
			{
				m_alphaGBuffers[ i ] = new RenderTexture( MinAlphaResolution, MinAlphaResolution, 16, outputList[ i ].SRGB ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGBHalf );
				m_alphaGBuffers[ i ].Create();
			}
		}

		private void ClearBuffers()
		{
			RenderTexture.active = null;
			foreach( var rt in m_rtGBuffers )
			{
				rt.Release();
			}
			m_rtGBuffers = null;
		}

		private void ClearAlphaBuffers( )
		{
			RenderTexture.active = null;
			foreach( var rt in m_alphaGBuffers )
			{
				rt.Release();
			}
			m_alphaGBuffers = null;
		}

#if UNITY_EDITOR
		private const string ImpostorsGCincGUID = "b88b76e7061d41545aaf145c34304b89";

		public enum AISRPVersions
		{
			AI_SRP_4_9_0 = 040900,
			AI_SRP_4_10_0 = 041000,
			AI_SRP_5_7_2 = 050702,
			AI_SRP_5_8_2 = 050802,
			AI_SRP_5_9_0 = 050900,
			AI_SRP_5_10_0 = 051000,
			AI_SRP_5_13_0 = 051300,
			AI_SRP_5_16_1 = 051601,
			AI_SRP_6_9_0 = 060900,
			AI_SRP_6_9_1 = 060901
		}

#if UNITY_2018_3_OR_NEWER
		private static Dictionary<string, AISRPVersions> m_srpVersionConverter = new Dictionary<string, AISRPVersions>()
		{
			{"4.9.0-preview",   AISRPVersions.AI_SRP_4_9_0},
			{"4.10.0-preview",  AISRPVersions.AI_SRP_4_10_0},
			{"5.7.2-preview",   AISRPVersions.AI_SRP_5_7_2},
			{"5.7.2",           AISRPVersions.AI_SRP_5_7_2},
			{"5.8.2-preview",   AISRPVersions.AI_SRP_5_8_2},
			{"5.8.2",           AISRPVersions.AI_SRP_5_8_2},
			{"5.9.0-preview",   AISRPVersions.AI_SRP_5_9_0},
			{"5.9.0",           AISRPVersions.AI_SRP_5_9_0},
			{"5.10.0-preview",  AISRPVersions.AI_SRP_5_10_0},
			{"5.10.0",          AISRPVersions.AI_SRP_5_10_0},
			{"5.13.0-preview",  AISRPVersions.AI_SRP_5_13_0},
			{"5.13.0",          AISRPVersions.AI_SRP_5_13_0},
			{"5.16.1-preview",  AISRPVersions.AI_SRP_5_16_1},
			{"5.16.1",          AISRPVersions.AI_SRP_5_16_1},
			{"6.9.0",           AISRPVersions.AI_SRP_6_9_0},
			{"6.9.0-preview",   AISRPVersions.AI_SRP_6_9_0},
			{"6.9.1",           AISRPVersions.AI_SRP_6_9_1},
			{"6.9.1-preview",   AISRPVersions.AI_SRP_6_9_1},
		};

		UnityEditor.PackageManager.Requests.ListRequest m_packageListRequest;
#endif
		public void CheckSRPVerionAndApply()
		{
#if UNITY_2018_3_OR_NEWER
			m_packageListRequest = UnityEditor.PackageManager.Client.List( true );
#endif
			EditorApplication.delayCall += ApplySRP;
		}

		private AISRPVersions GetLowestVersion( string version )
		{
			version = version.Replace( ".", "0" );
			version = version.Replace( "-preview", "" );
			int versionInt = int.Parse( version );

			Array all = Enum.GetValues( typeof( AISRPVersions ) );
			for( int i = 0; i < all.Length; i++ )
			{
				if( (int)all.GetValue( i ) > versionInt && i > 0 )
				{
					return (AISRPVersions)all.GetValue( i - 1 );
				}
			}
			return AISRPVersions.AI_SRP_6_9_1;
		}

		public void ApplySRP()
		{
#if UNITY_2018_3_OR_NEWER
			if( !( m_packageListRequest != null && m_packageListRequest.IsCompleted ) )
			{
				EditorApplication.delayCall += ApplySRP;
				return;
			}
#endif

			AISRPVersions LWversion = AISRPVersions.AI_SRP_6_9_1;
			AISRPVersions HDversion = AISRPVersions.AI_SRP_6_9_1;

#if UNITY_2018_3_OR_NEWER
			foreach( UnityEditor.PackageManager.PackageInfo pi in m_packageListRequest.Result )
			{
				if( pi.name.Equals( "com.unity.render-pipelines.lightweight" ) )
				{
					if( m_srpVersionConverter.ContainsKey( pi.version ) )
					{
						LWversion = m_srpVersionConverter[ pi.version ];
					}
					else
					{
						LWversion = GetLowestVersion( pi.version );
					}
				}

				if( pi.name.Equals( "com.unity.render-pipelines.high-definition" ) )
				{
					if( m_srpVersionConverter.ContainsKey( pi.version ) )
					{
						HDversion = m_srpVersionConverter[ pi.version ];
					}
					else
					{
						HDversion = GetLowestVersion( pi.version );
					}
				}
			}
#endif
			string impostorCGincPath = AssetDatabase.GUIDToAssetPath( ImpostorsGCincGUID );
			if( string.IsNullOrEmpty( impostorCGincPath ) )
				return;

			string cginc = string.Empty;
			if( !string.IsNullOrEmpty( impostorCGincPath ) && File.Exists( impostorCGincPath ) )
			{
				StreamReader fileReader = null;
				try
				{
					fileReader = new StreamReader( impostorCGincPath );
					cginc = fileReader.ReadToEnd();
				}
				catch( Exception e )
				{
					Debug.LogException( e );
				}
				finally
				{
					if( fileReader != null )
						fileReader.Close();
				}
			}

			bool saveAndRefresh = false;

			Match cgincMatch = Regex.Match( cginc, @"#define AI_HDRP_VERSION (\d*)", RegexOptions.Multiline );
			if( cgincMatch.Success )
			{
				string cgincSRPversion = cgincMatch.Groups[ 1 ].Value;
				if( cgincSRPversion != ((int)HDversion).ToString() )
				{
					cginc = cginc.Replace( cgincMatch.Groups[ 0 ].Value, "#define AI_HDRP_VERSION "+ ( (int)HDversion ).ToString() );
					saveAndRefresh = true;
				}
			}

			cgincMatch = Regex.Match( cginc, @"#define AI_LWRP_VERSION (\d*)", RegexOptions.Multiline );
			if( cgincMatch.Success )
			{
				string cgincSRPversion = cgincMatch.Groups[ 1 ].Value;
				if( cgincSRPversion != ( (int)LWversion ).ToString() )
				{
					cginc = cginc.Replace( cgincMatch.Groups[ 0 ].Value, "#define AI_LWRP_VERSION " + ( (int)LWversion ).ToString() );
					saveAndRefresh = true;
				}
			}

			if( saveAndRefresh )
				SaveCginc( cginc, impostorCGincPath );
		}

		private void SaveCginc( string file, string path )
		{
			StreamWriter fileWriter = new StreamWriter( path );
			try
			{
				fileWriter.Write( file );
			}
			catch( Exception e )
			{
				Debug.LogException( e );
			}
			finally
			{
				fileWriter.Close();
			}
			AssetDatabase.Refresh();
		}

		public void RenderToTexture( ref RenderTexture tex, string path, ImageFormat imageFormat, int resizeScale, TextureChannels channels )
		{
			Texture2D outfile = AssetDatabase.LoadAssetAtPath<Texture2D>( path );
			outfile = new Texture2D( (int)m_data.TexSize.x / resizeScale, (int)m_data.TexSize.y / resizeScale, channels == TextureChannels.RGB ? TextureFormat.RGB24 : TextureFormat.RGBA32, true );
			outfile.name = Path.GetFileNameWithoutExtension( path );
			RenderTexture temp = RenderTexture.active;
			RenderTexture.active = tex;
			outfile.ReadPixels( new Rect( 0, 0, (int)m_data.TexSize.x / resizeScale, (int)m_data.TexSize.y / resizeScale ), 0, 0 );
			RenderTexture.active = temp;
			outfile.Apply();
			byte[] bytes;
			switch( imageFormat )
			{
				case ImageFormat.PNG:
				bytes = outfile.EncodeToPNG();
				break;
				default:
				case ImageFormat.TGA:
				bytes = outfile.EncodeToTGA( channels == TextureChannels.RGBA );
				break;
			}

			int BytesToWrite, BufIndex;
			int bytesLength = bytes.Length;
			FileStream FSFile = new FileStream( path, FileMode.Create, FileAccess.Write, FileShare.None, BlockSize, false );
			BufIndex = 0;
			do
			{
				BytesToWrite = Math.Min( BlockSize, bytesLength - BufIndex );
				FSFile.Write( bytes, BufIndex, BytesToWrite );
				BufIndex += BytesToWrite;
			} while( BufIndex < bytesLength );
			FSFile.Close();
			FSFile.Dispose();
			EditorUtility.SetDirty( outfile );
		}

		public void ChangeTextureImporter( ref RenderTexture tex, string path, bool sRGB = true, bool changeResolution = false, TextureCompression compression = TextureCompression.Normal, bool alpha = true )
		{
			Texture2D outfile = AssetDatabase.LoadAssetAtPath<Texture2D>( path );
			TextureImporter tImporter = AssetImporter.GetAtPath( path ) as TextureImporter;
			if( tImporter != null )
			{
				if( (tImporter.alphaSource == TextureImporterAlphaSource.FromInput && !alpha) || ( tImporter.textureCompression != (TextureImporterCompression)compression ) || tImporter.sRGBTexture != sRGB || ( changeResolution && tImporter.maxTextureSize != (int)m_data.TexSize.x ) )
				{
					tImporter.sRGBTexture = sRGB;
					tImporter.alphaSource = alpha ? TextureImporterAlphaSource.FromInput : TextureImporterAlphaSource.None;
					tImporter.textureCompression = (TextureImporterCompression)compression;
					if( changeResolution )
						tImporter.maxTextureSize = (int)m_data.TexSize.x;

					EditorUtility.SetDirty( tImporter );
					EditorUtility.SetDirty( outfile );
					tImporter.SaveAndReimport();
				}
			}
		}
		public void CalculateSheetBounds( ImpostorType impostorType )
		{
			m_xyFitSize = 0;
			m_depthFitSize = 0;

			int hframes = m_data.HorizontalFrames;
			int vframes = m_data.HorizontalFrames;
			if( impostorType == ImpostorType.Spherical )
			{
				vframes = m_data.HorizontalFrames - 1;
				if( m_data.DecoupleAxisFrames )
					vframes = m_data.VerticalFrames - 1;
			}

			for( int x = 0; x < hframes; x++ )
			{
				for( int y = 0; y <= vframes; y++ )
				{
					Bounds frameBounds = new Bounds();
					Matrix4x4 camMatrixRot = GetCameraRotationMatrix( impostorType, hframes, vframes, x, y );

					for( int i = 0; i < Renderers.Length; i++ )
					{
						if( Renderers[ i ] == null || !Renderers[ i ].enabled || Renderers[ i ].shadowCastingMode == ShadowCastingMode.ShadowsOnly )
							continue;

						MeshFilter mf = Renderers[ i ].GetComponent<MeshFilter>();
						if( mf == null || mf.sharedMesh == null )
							continue;

						if( frameBounds.size == Vector3.zero )
							frameBounds = mf.sharedMesh.bounds.Transform( m_rootTransform.worldToLocalMatrix * Renderers[ i ].localToWorldMatrix );
						else
							frameBounds.Encapsulate( mf.sharedMesh.bounds.Transform( m_rootTransform.worldToLocalMatrix * Renderers[ i ].localToWorldMatrix ) );
					}

					if( x == 0 && y == 0 )
						m_originalBound = frameBounds;//.Transform( m_rootTransform.worldToLocalMatrix );
					
					frameBounds = frameBounds.Transform( camMatrixRot /** m_rootTransform.worldToLocalMatrix*/ );
					m_xyFitSize = Mathf.Max( m_xyFitSize, frameBounds.size.x, frameBounds.size.y );
					m_depthFitSize = Mathf.Max( m_depthFitSize, frameBounds.size.z );
				}
			}

#if AI_DEBUG_MODE
			m_renderInfo = "";
			m_renderInfo += "\nXY fit:\t" + m_trueFitsize;
			m_renderInfo += "\nDepth:\t" + m_depthFitsize;
#endif
		}

		public void DilateRenderTextureUsingMask( ref RenderTexture mainTex, ref RenderTexture maskTex, int pixelBleed, bool alpha, Material dilateMat = null )
		{
			if( pixelBleed == 0 )
				return;

			bool destroyMaterial = false;
			if( dilateMat == null )
			{
				destroyMaterial = true;
				Shader dilateShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( DilateGUID ) );
				dilateMat = new Material( dilateShader );
			}

			RenderTexture tempTex = RenderTexture.GetTemporary( mainTex.width, mainTex.height, mainTex.depth, mainTex.format );
			RenderTexture tempMask = RenderTexture.GetTemporary( maskTex.width, maskTex.height, maskTex.depth, maskTex.format );
			RenderTexture dilatedMask = RenderTexture.GetTemporary( maskTex.width, maskTex.height, maskTex.depth, maskTex.format );

			Graphics.Blit( maskTex, dilatedMask );

			for( int i = 0; i < pixelBleed; i++ )
			{
				dilateMat.SetTexture( "_MaskTex", dilatedMask );

				Graphics.Blit( mainTex, tempTex, dilateMat, alpha ? 1 : 0 );
				Graphics.Blit( tempTex, mainTex );

				Graphics.Blit( dilatedMask, tempMask, dilateMat, 1 );
				Graphics.Blit( tempMask, dilatedMask );
			}

			RenderTexture.ReleaseTemporary( tempTex );
			RenderTexture.ReleaseTemporary( tempMask );
			RenderTexture.ReleaseTemporary( dilatedMask );

			if( destroyMaterial )
			{
				DestroyImmediate( dilateMat );
				dilateMat = null;
			}
		}

		public void PackingRemapping( ref RenderTexture src, ref RenderTexture dst, int passIndex, Material packerMat = null, Texture extraTex = null )
		{
			bool destroyMaterial = false;
			if( packerMat == null )
			{
				destroyMaterial = true;
				Shader packerShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( PackerGUID ) );
				packerMat = new Material( packerShader );
			}

			if( extraTex != null )
				packerMat.SetTexture( "_A", extraTex );

			if( src == dst )
			{
				int width = src.width;
				int height = src.height;
				int depth = src.depth;
				RenderTextureFormat format = src.format;

				RenderTexture tempTex = RenderTexture.GetTemporary( width, height, depth, format );
				Graphics.Blit( src, tempTex, packerMat, passIndex );
				Graphics.Blit( tempTex, dst );
				RenderTexture.ReleaseTemporary( tempTex );
			}
			else
			{
				Graphics.Blit( src, dst, packerMat, passIndex );
			}

			if( destroyMaterial )
			{
				DestroyImmediate( packerMat );
				packerMat = null;
			}
		}

		private void CopyTransform()
		{
			m_oriPos = RootTransform.position;
			m_oriRot = RootTransform.rotation;
			m_oriSca = RootTransform.localScale;
			RootTransform.position = Vector3.zero;
			RootTransform.rotation = Quaternion.identity;
			RootTransform.localScale = Vector3.one;
		}

		private void PasteTransform()
		{
			RootTransform.position = m_oriPos;
			RootTransform.rotation = m_oriRot;
			RootTransform.localScale = m_oriSca;
		}

		public void CalculatePixelBounds( int targetAmount )
		{
			bool sRGBcache = GL.sRGBWrite;

			CalculateSheetBounds( m_data.ImpostorType );
			GenerateAlphaTextures( m_data.Preset.Output );

			GL.sRGBWrite = true;

			m_pixelOffset = Vector2.zero;

			// TODO: remove this temporary solution
			CopyTransform();
			try
			{
				RenderImpostor( m_data.ImpostorType, m_data.Preset.Output.Count, false, true, true, m_data.Preset.BakeShader );
				PasteTransform();
			}
			catch( Exception e )
			{
				PasteTransform();
				EditorUtility.ClearProgressBar();
				throw e;
			}

			GL.sRGBWrite = sRGBcache;

			int alphaIndex = m_data.Preset.BakeShader == null ? 2 : m_data.Preset.AlphaIndex;
			
			// Render just alpha
			RenderTexture combinedAlphaTexture = RenderTexture.GetTemporary( MinAlphaResolution, MinAlphaResolution, m_alphaGBuffers[ alphaIndex ].depth, m_alphaGBuffers[ alphaIndex ].format );
			PackingRemapping( ref m_alphaGBuffers[ alphaIndex ], ref combinedAlphaTexture, 8 );

			ClearAlphaBuffers();

			RenderTexture.active = combinedAlphaTexture;
			Texture2D tempTex = new Texture2D( combinedAlphaTexture.width, combinedAlphaTexture.height, TextureFormat.RGBAFloat, false );
			tempTex.ReadPixels( new Rect( 0, 0, combinedAlphaTexture.width, combinedAlphaTexture.height ), 0, 0 );
			tempTex.Apply();
			RenderTexture.active = null;

			RenderTexture.ReleaseTemporary( combinedAlphaTexture );

			Rect testRect = new Rect( 0, 0, tempTex.width, tempTex.height );
			Vector2[][] paths;
			SpriteUtilityEx.GenerateOutline( tempTex, testRect, 0.2f, 0, false, out paths );
			int sum = 0;
			for( int i = 0; i < paths.Length; i++ )
			{
				sum += paths[ i ].Length;
			}

			Vector2[] minMaxPoints = new Vector2[ sum ];
			int index = 0;
			for( int i = 0; i < paths.Length; i++ )
			{
				for( int j = 0; j < paths[ i ].Length; j++ )
				{
					minMaxPoints[ index ] = (Vector2)( paths[ i ][ j ] ) + ( new Vector2( tempTex.width * 0.5f, tempTex.height * 0.5f ) );
					minMaxPoints[ index ] = Vector2.Scale( minMaxPoints[ index ], new Vector2( 1.0f / tempTex.width, 1.0f / tempTex.height ) );
					index++;
				}
			}

			Vector2 mins = Vector2.one;
			Vector2 maxs = Vector2.zero;

			for( int i = 0; i < minMaxPoints.Length; i++ )
			{
				mins.x = Mathf.Min( minMaxPoints[ i ].x, mins.x );
				mins.y = Mathf.Min( minMaxPoints[ i ].y, mins.y );
				maxs.x = Mathf.Max( minMaxPoints[ i ].x, maxs.x );
				maxs.y = Mathf.Max( minMaxPoints[ i ].y, maxs.y );
			}

			Vector2 height = ( maxs - mins );
			float maxBound = Mathf.Max( height.x, height.y );
			Vector2 center = mins + ( height * 0.5f );
			m_pixelOffset = ( center - ( Vector2.one * 0.5f ) ) * m_xyFitSize;
			//Debug.Log( m_pixelOffset.ToString( "N5" ) );
			//Debug.Log( height.ToString( "N5" ) );
			m_xyFitSize *= maxBound;
			m_depthFitSize *= maxBound;
		}

		// For inspector
		public void RenderCombinedAlpha( AmplifyImpostorAsset data = null )
		{
			AmplifyImpostorAsset tempData = m_data;
			if( data != null )
				m_data = data;

			CalculatePixelBounds( m_data.Preset.Output.Count );
			GenerateAlphaTextures( m_data.Preset.Output );

			bool sRGBcache = GL.sRGBWrite;
			GL.sRGBWrite = true;

			// TODO: remove this temporary solution
			CopyTransform();
			try
			{
				RenderImpostor( m_data.ImpostorType, m_data.Preset.Output.Count, false, true, false, m_data.Preset.BakeShader );
				PasteTransform();
			}
			catch( Exception e )
			{
				PasteTransform();
				EditorUtility.ClearProgressBar();
				throw e;
			}

			GL.sRGBWrite = sRGBcache;

			int alphaIndex = m_data.Preset.BakeShader == null ? 2 : m_data.Preset.AlphaIndex;

			RenderTexture combinedAlphaTexture = RenderTexture.GetTemporary( MinAlphaResolution, MinAlphaResolution, m_alphaGBuffers[ alphaIndex ].depth, m_alphaGBuffers[ alphaIndex ].format );
			PackingRemapping( ref m_alphaGBuffers[ alphaIndex ], ref combinedAlphaTexture, 8 );

			ClearAlphaBuffers();

			RenderTexture.active = combinedAlphaTexture;
			m_alphaTex = new Texture2D( combinedAlphaTexture.width, combinedAlphaTexture.height, TextureFormat.RGBAFloat, false );
			m_alphaTex.ReadPixels( new Rect( 0, 0, combinedAlphaTexture.width, combinedAlphaTexture.height ), 0, 0 );
			m_alphaTex.Apply();
			RenderTexture.active = null;

			RenderTexture.ReleaseTemporary( combinedAlphaTexture );

			m_data = tempData;
		}

		public void CreateAssetFile( AmplifyImpostorAsset data = null )
		{
			string folderPath = this.OpenFolderForImpostor();

			if( string.IsNullOrEmpty( folderPath ) )
				return;

			string fileName = m_impostorName;

			if( string.IsNullOrEmpty( fileName ) )
				fileName = m_rootTransform.name + "_Impostor";

			folderPath = folderPath.TrimEnd( new char[] { '/', '*', '.', ' ' } );
			folderPath += "/";
			folderPath = folderPath.TrimStart( new char[] { '/', '*', '.', ' ' } );

			if( m_data == null )
			{
				Undo.RegisterCompleteObjectUndo( this, "Create Impostor Asset" );
				AmplifyImpostorAsset existingAsset = AssetDatabase.LoadAssetAtPath<AmplifyImpostorAsset>( folderPath + fileName + ".asset" );
				if( existingAsset != null )
				{
					m_data = existingAsset;
				}
				else
				{
					m_data = ScriptableObject.CreateInstance<AmplifyImpostorAsset>();
					AssetDatabase.CreateAsset( m_data, folderPath + fileName + ".asset" );
				}
			}
		}

		private void DisplayProgress( float progress )
		{
#if UNITY_EDITOR
			if( !Application.isPlaying )
			{
				EditorUtility.DisplayProgressBar( "Baking Impostor", "Please wait...", progress );

				if( progress >= 1.0f )
					EditorUtility.ClearProgressBar();
			}
#endif
		}

		public void DetectRenderPipeline()
		{
			string pipelineName = string.Empty;
			try
			{
#if UNITY_2019_1_OR_NEWER
				pipelineName = UnityEngine.Rendering.RenderPipelineManager.currentPipeline.ToString();
#else
				pipelineName = UnityEngine.Experimental.Rendering.RenderPipelineManager.currentPipeline.ToString();
#endif
			}
			catch( Exception )
			{
				pipelineName = "";
			}

			if( pipelineName.Contains( "LightweightRenderPipeline" ) )
			{
				m_renderPipelineInUse = RenderPipelineInUse.LW;
			}
			else if( pipelineName.Contains( "HDRenderPipeline" ) )
			{
				m_renderPipelineInUse = RenderPipelineInUse.HD;
			}
			else if( pipelineName.Equals( "" ) )
			{
				m_renderPipelineInUse = RenderPipelineInUse.None;
			}
			else
			{
				m_renderPipelineInUse = RenderPipelineInUse.Custom;
			}

			bool missingFiles = false;
			try
			{
				AmplifyImpostorBakePreset check = AssetDatabase.LoadAssetAtPath<AmplifyImpostorBakePreset>( AssetDatabase.GUIDToAssetPath( LWPreset ) );
				if( check == null && m_renderPipelineInUse == RenderPipelineInUse.LW )
					missingFiles = true;

				check = AssetDatabase.LoadAssetAtPath<AmplifyImpostorBakePreset>( AssetDatabase.GUIDToAssetPath( HDPreset ) );
				if( check == null && m_renderPipelineInUse == RenderPipelineInUse.HD )
					missingFiles = true;
			}
			catch( Exception )
			{
				missingFiles = true;
			}

			if( missingFiles && !string.IsNullOrEmpty( pipelineName ) )
			{
				m_renderPipelineInUse = RenderPipelineInUse.None;
				Debug.LogWarning( "[AmplifyImpostors] Custom render pipeline was detected but necessary files for baking are missing, please make sure the appropriate files were imported.\n" +
					"You can find them at 'RenderPipelinePackages' folder." );
			}
		}

		public void RenderAllDeferredGroups( AmplifyImpostorAsset data = null )
		{
			
			string folderPath = m_folderPath;
			if( m_data == null )
			{
				folderPath = this.OpenFolderForImpostor();
			}
			else if( string.IsNullOrEmpty( folderPath ) )
			{
				m_impostorName = m_data.name;
				folderPath = Path.GetDirectoryName( AssetDatabase.GetAssetPath( m_data ) ).Replace( "\\", "/" ) + "/";
			} else if( m_data != null )
			{
				m_impostorName = m_data.name;
			}

			if( string.IsNullOrEmpty( folderPath ) )
				return;

			DisplayProgress( 0 );
			string fileName = m_impostorName;

			if( string.IsNullOrEmpty( fileName ) )
				fileName = m_rootTransform.name + "_Impostor";

			m_folderPath = folderPath;
			folderPath = folderPath.TrimEnd( new char[] { '/', '*', '.', ' ' } );
			folderPath += "/";
			folderPath = folderPath.TrimStart( new char[] { '/', '*', '.', ' ' } );
			m_impostorName = fileName;

			Undo.RegisterCompleteObjectUndo( this, "Create Impostor" );

			DetectRenderPipeline();

			if( m_data == null )
			{
				AmplifyImpostorAsset existingAsset = AssetDatabase.LoadAssetAtPath<AmplifyImpostorAsset>( folderPath + fileName + ".asset" );
				if( existingAsset != null )
				{
					m_data = existingAsset;
				}
				else
				{
					m_data = ScriptableObject.CreateInstance<AmplifyImpostorAsset>();
					AssetDatabase.CreateAsset( m_data, folderPath + fileName + ".asset" );
				}

				if( data != null )
				{
					m_data.ShapePoints = data.ShapePoints;
				}
			}
			else
			if( data != null )
			{
				m_data = data;
			}
			bool chache = GL.sRGBWrite;
			GL.sRGBWrite = true;

			if( !m_data.DecoupleAxisFrames )
				m_data.HorizontalFrames = m_data.VerticalFrames;

			if( m_data.Preset == null )
			{
				if( m_renderPipelineInUse == RenderPipelineInUse.HD )
					m_data.Preset = AssetDatabase.LoadAssetAtPath<AmplifyImpostorBakePreset>( AssetDatabase.GUIDToAssetPath( HDPreset ) );
				else if( m_renderPipelineInUse == RenderPipelineInUse.LW )
					m_data.Preset = AssetDatabase.LoadAssetAtPath<AmplifyImpostorBakePreset>( AssetDatabase.GUIDToAssetPath( LWPreset ) );
				else
					m_data.Preset = AssetDatabase.LoadAssetAtPath<AmplifyImpostorBakePreset>( AssetDatabase.GUIDToAssetPath( StandardPreset ) );
			}

			bool standardRendering = false;
			if( m_data.Preset.BakeShader == null )
				standardRendering = true;

			List<TextureOutput> outputList = new List<TextureOutput>();
			for( int i = 0; i < m_data.Preset.Output.Count; i++ )
				outputList.Add( m_data.Preset.Output[ i ].Clone() );

			for( int i = 0; i < m_data.OverrideOutput.Count && i < m_data.Preset.Output.Count; i++ )
			{
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.OutputToggle ) == OverrideMask.OutputToggle )
					outputList[ m_data.OverrideOutput[ i ].Index ].Active = m_data.OverrideOutput[ i ].Active;
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.NameSuffix ) == OverrideMask.NameSuffix )
					outputList[ m_data.OverrideOutput[ i ].Index ].Name = m_data.OverrideOutput[ i ].Name;
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.RelativeScale ) == OverrideMask.RelativeScale )
					outputList[ m_data.OverrideOutput[ i ].Index ].Scale = m_data.OverrideOutput[ i ].Scale;
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.ColorSpace ) == OverrideMask.ColorSpace )
					outputList[ m_data.OverrideOutput[ i ].Index ].SRGB = m_data.OverrideOutput[ i ].SRGB;
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.QualityCompression ) == OverrideMask.QualityCompression )
					outputList[ m_data.OverrideOutput[ i ].Index ].Compression = m_data.OverrideOutput[ i ].Compression;
				if( ( m_data.OverrideOutput[ i ].OverrideMask & OverrideMask.FileFormat ) == OverrideMask.FileFormat )
					outputList[ m_data.OverrideOutput[ i ].Index ].ImageFormat = m_data.OverrideOutput[ i ].ImageFormat;
			}
			m_fileNames = new string[ outputList.Count ];
			
			string guid = string.Empty;
			if( m_renderPipelineInUse == RenderPipelineInUse.HD )
				guid = m_data.ImpostorType == ImpostorType.Spherical ? HDShaderGUID : HDShaderOctaGUID;
			else if( m_renderPipelineInUse == RenderPipelineInUse.LW )
				guid = m_data.ImpostorType == ImpostorType.Spherical ? LWShaderGUID : LWShaderOctaGUID;
			else
				guid = m_data.ImpostorType == ImpostorType.Spherical ? ShaderGUID : ShaderOctaGUID;


			CalculatePixelBounds( outputList.Count );
			DisplayProgress( 0.1f );

			GenerateTextures( outputList );
			DisplayProgress( 0.2f );

			// TODO: remove this temporary solution
			CopyTransform();

			try
			{
				RenderImpostor( m_data.ImpostorType, outputList.Count, true, false, true, m_data.Preset.BakeShader );
				PasteTransform();
			}
			catch( Exception e )
			{
				PasteTransform();
				EditorUtility.ClearProgressBar();
				throw e;
			}

			DisplayProgress( 0.5f );

			int alphaIndex = m_data.Preset.AlphaIndex;
			if( standardRendering )
			{
				////// SHADER STUFF //////
				Shader packerShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( PackerGUID ) );
				Material packerMat = new Material( packerShader );

				// Switch alpha with occlusion
				RenderTexture tempTex = RenderTexture.GetTemporary( m_rtGBuffers[ 0 ].width, m_rtGBuffers[ 0 ].height, m_rtGBuffers[ 0 ].depth, m_rtGBuffers[ 0 ].format );
				RenderTexture tempTex2 = RenderTexture.GetTemporary( m_rtGBuffers[ 3 ].width, m_rtGBuffers[ 3 ].height, m_rtGBuffers[ 3 ].depth, m_rtGBuffers[ 3 ].format );

				packerMat.SetTexture( "_A", m_rtGBuffers[ 2 ] );
				Graphics.Blit( m_rtGBuffers[ 0 ], tempTex, packerMat, 4 ); //A.b
				packerMat.SetTexture( "_A", m_rtGBuffers[ 0 ] );
				Graphics.Blit( m_rtGBuffers[ 3 ], tempTex2, packerMat, 4 ); //B.a
				Graphics.Blit( tempTex, m_rtGBuffers[ 0 ] );
				Graphics.Blit( tempTex2, m_rtGBuffers[ 3 ] );
				RenderTexture.ReleaseTemporary( tempTex );
				RenderTexture.ReleaseTemporary( tempTex2 );

				// Pack Depth
				PackingRemapping( ref m_rtGBuffers[ 2 ], ref m_rtGBuffers[ 2 ], 0, packerMat, m_trueDepth );
				m_trueDepth.Release();
				m_trueDepth = null;

				// Fix Albedo
				PackingRemapping( ref m_rtGBuffers[ 0 ], ref m_rtGBuffers[ 0 ], 5, packerMat, m_rtGBuffers[ 1 ] );

				// TransformNormal
				//Matrix4x4 View = Matrix4x4.Rotate(
				//Shader.SetGlobalMatrix( "_Matrix", m_rootTransform.worldToLocalMatrix );
				//PackingRemapping( ref m_rtGBuffers[ 2 ], ref m_rtGBuffers[ 2 ], 9, packerMat );

				// TGA
				for( int i = 0; i < 4; i++ )
				{
					if( outputList[ i ].ImageFormat == ImageFormat.TGA )
						PackingRemapping( ref m_rtGBuffers[ i ], ref m_rtGBuffers[ i ], 6, packerMat );
				}

				// Fix Emission
#if UNITY_2017_3_OR_NEWER && !UNITY_2018_3_OR_NEWER
				PackingRemapping( ref m_rtGBuffers[ 3 ], ref m_rtGBuffers[ 3 ], 1, packerMat );
#endif

				DestroyImmediate( packerMat );
				packerMat = null;

				Shader dilateShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( DilateGUID ) );
				Material dilateMat = new Material( dilateShader );

				// Dilation
				for( int i = 0; i < 4; i++ )
				{
					if( outputList[ i ].Active )
						DilateRenderTextureUsingMask( ref m_rtGBuffers[ i ], ref m_rtGBuffers[ alphaIndex ], m_data.PixelPadding, alphaIndex != i, dilateMat );
				}

				DestroyImmediate( dilateMat );
				dilateMat = null;

				for( int i = 0; i < 4; i++ )
				{
					if( outputList[ i ].Scale != TextureScale.Full )
					{
						RenderTexture resTex = RenderTexture.GetTemporary( m_rtGBuffers[ i ].width / (int)outputList[ i ].Scale, m_rtGBuffers[ i ].height / (int)outputList[ i ].Scale, m_rtGBuffers[ i ].depth, m_rtGBuffers[ i ].format );
						Graphics.Blit( m_rtGBuffers[ i ], resTex );
						m_rtGBuffers[ i ].Release();
						m_rtGBuffers[ i ] = new RenderTexture( resTex.width, resTex.height, m_rtGBuffers[ i ].depth, m_rtGBuffers[ i ].format );
						m_rtGBuffers[ i ].Create();
						Graphics.Blit( resTex, m_rtGBuffers[ i ] );
						RenderTexture.ReleaseTemporary( resTex );
					}
				}
			}
			else
			{

				Shader dilateShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( DilateGUID ) );
				Material dilateMat = new Material( dilateShader );

				// Dilation
				for( int i = 0; i < outputList.Count; i++ )
				{
					if( outputList[ i ].Active )
						DilateRenderTextureUsingMask( ref m_rtGBuffers[ i ], ref m_rtGBuffers[ alphaIndex ], m_data.PixelPadding, alphaIndex != i, dilateMat );
				}

				DestroyImmediate( dilateMat );
				dilateMat = null;

				// Resize Final Textures
				for( int i = 0; i < outputList.Count; i++ )
				{
					if( outputList[ i ].Scale != TextureScale.Full )
					{
						RenderTexture resTex = RenderTexture.GetTemporary( m_rtGBuffers[ i ].width / (int)outputList[ i ].Scale, m_rtGBuffers[ i ].height / (int)outputList[ i ].Scale, m_rtGBuffers[ i ].depth, m_rtGBuffers[ i ].format );
						Graphics.Blit( m_rtGBuffers[ i ], resTex );
						m_rtGBuffers[ i ].Release();
						m_rtGBuffers[ i ] = new RenderTexture( resTex.width, resTex.height, m_rtGBuffers[ i ].depth, m_rtGBuffers[ i ].format );
						m_rtGBuffers[ i ].Create();
						Graphics.Blit( resTex, m_rtGBuffers[ i ] );
						RenderTexture.ReleaseTemporary( resTex );
					}
				}

				Shader packerShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( PackerGUID ) );
				Material packerMat = new Material( packerShader );

				// TGA
				for( int i = 0; i < outputList.Count; i++ )
				{
					if( outputList[ i ].ImageFormat == ImageFormat.TGA )
						PackingRemapping( ref m_rtGBuffers[ i ], ref m_rtGBuffers[ i ], 6, packerMat );
				}

				DestroyImmediate( packerMat );
				packerMat = null;
			}

			DisplayProgress( 0.6f );

			bool isPrefab = false;
			
#if UNITY_2018_3_OR_NEWER
			if( PrefabUtility.GetPrefabAssetType( this.gameObject ) == PrefabAssetType.Regular && PrefabUtility.GetPrefabInstanceHandle( this.gameObject ) == null )
				isPrefab = true;
#else
			if( PrefabUtility.GetPrefabType( this.gameObject ) == PrefabType.Prefab )
				isPrefab = true;
#endif

			// Create billboard
			Shader defaultShader = null;
			if( m_data.Preset.RuntimeShader != null )
			{
				defaultShader = m_data.Preset.RuntimeShader;
			}
			else
			{
				defaultShader = AssetDatabase.LoadAssetAtPath<Shader>( AssetDatabase.GUIDToAssetPath( guid ) );
			}
			Material material = m_data.Material;
			if( material == null )
			{
				material = new Material( defaultShader );
				material.name = fileName;
				material.enableInstancing = true;
				AssetDatabase.AddObjectToAsset( material, m_data );
				m_data.Material = material;
				EditorUtility.SetDirty( material );
			}
			else
			{
				material.shader = defaultShader;
				material.name = fileName;
				EditorUtility.SetDirty( material );
			}

			Texture2D tex = null;
			bool hasDifferentResolution = false;

			// Construct file names
			m_standardFileNames[ 0 ] = ImpostorBakingTools.GlobalAlbedoAlpha;
			m_standardFileNames[ 1 ] = ImpostorBakingTools.GlobalSpecularSmoothness;
			m_standardFileNames[ 2 ] = ImpostorBakingTools.GlobalNormalDepth;
			m_standardFileNames[ 3 ] = ImpostorBakingTools.GlobalEmissionOcclusion;

			for( int i = 0; i < outputList.Count; i++ )
			{
				tex = null;
				m_fileNames[ i ] = string.Empty;
				if( material.HasProperty( outputList[ i ].Name ) )
					tex = material.GetTexture( outputList[ i ].Name ) as Texture2D;
				if( tex != null )
				{
					m_fileNames[ i ] = AssetDatabase.GetAssetPath( tex );
					//m_fileNames[ i ] = Path.GetDirectoryName( AssetDatabase.GetAssetPath( tex ) ).Replace( "\\", "/" ) + "/";
					if( tex.width != (int)m_data.TexSize.x / (int)outputList[ i ].Scale )
						hasDifferentResolution = true;
				}
				else
				{
					m_fileNames[ i ] = folderPath;
					m_fileNames[ i ] += fileName + outputList[ i ].Name + "." + outputList[ i ].ImageFormat.ToString().ToLower();
				}
			}

			for( int i = 0; i < m_propertyNames.Length; i++ )
			{
				tex = null;
				if( material.HasProperty( m_propertyNames[ i ] ) )
				{
					tex = material.GetTexture( m_propertyNames[ i ] ) as Texture2D;
					if( tex != null )
					{
						int indexFound = outputList.FindIndex( x => x.Name == m_standardFileNames[ i ] );
						if( indexFound > -1 )
						{
							m_fileNames[ indexFound ] = AssetDatabase.GetAssetPath( tex );
							//m_fileNames[ indexFound ] = Path.GetDirectoryName( AssetDatabase.GetAssetPath( tex ) ).Replace( "\\", "/" ) + "/";
							//m_fileNames[ indexFound ] += fileName + outputList[ indexFound ].Name + "." + outputList[ indexFound ].ImageFormat.ToString().ToLower();

							if( tex.width != (int)m_data.TexSize.x / (int)outputList[ indexFound ].Scale )
								hasDifferentResolution = true;
						}
					}
				}
			}

			bool resizeTextures = false;
			if( hasDifferentResolution && EditorPrefs.GetInt( ImpostorBakingTools.PrefGlobalTexImport, 0 ) == 0 )
				resizeTextures = EditorUtility.DisplayDialog( "Resize Textures?", "Do you wish to override the Texture Import settings to match the provided Impostor Texture Size?", "Yes", "No" );
			else if( EditorPrefs.GetInt( ImpostorBakingTools.PrefGlobalTexImport, 0 ) == 1 )
				resizeTextures = true;
			else
				resizeTextures = false;

			// save to texture files
			AmplifyTextureImporter.ImportData.Clear();
			if( !Application.isPlaying )
			{
				for( int i = 0; i < outputList.Count; i++ )
				{
					if( outputList[ i ].Active )
					{
						RenderToTexture( ref m_rtGBuffers[ i ], m_fileNames[ i ], outputList[ i ].ImageFormat, (int)outputList[ i ].Scale, outputList[ i ].Channels );
						AmplifyTextureImporter.ImportData.Add( m_fileNames[ i ], new DataHolder( outputList[ i ].SRGB, outputList[ i ].Compression, outputList[ i ].Channels == TextureChannels.RGBA, resizeTextures ? (int)m_data.TexSize.x / (int)outputList[ i ].Scale : -1 ) );
					}
				}
			}

			GL.sRGBWrite = chache;

			GameObject impostorObject = null;
			DisplayProgress( 0.65f );
			//RenderCombinedAlpha();
			Vector4 offsetCalc = /*transform.worldToLocalMatrix **/ new Vector4( m_originalBound.center.x, m_originalBound.center.y, m_originalBound.center.z, 1 );
			Vector4 offset = new Vector4( offsetCalc.x, offsetCalc.y, offsetCalc.z, -m_pixelOffset.y / m_xyFitSize/*(-pixelOffset.y / m_data.VerticalFrames) * ( m_trueFitsize / m_data.VerticalFrames )*/ );
			Vector4 sizeOffset = new Vector4( m_xyFitSize, m_depthFitSize, (m_pixelOffset.x / m_xyFitSize) / (float)m_data.HorizontalFrames, (m_pixelOffset.y / m_xyFitSize) / (float)m_data.VerticalFrames );
			//offset.y += pixelOffset.y;
			bool justCreated = false;
			UnityEngine.Object targetPrefab = null;
			GameObject tempGO = null;


			Mesh mesh = m_data.Mesh;
			if( mesh == null )
			{
				mesh = GenerateMesh( m_data.ShapePoints, offset, m_xyFitSize, m_xyFitSize, true );
				mesh.name = fileName;
				AssetDatabase.AddObjectToAsset( mesh, m_data );
				m_data.Mesh = mesh;
				EditorUtility.SetDirty( mesh );
			}
			else
			{
				Mesh tempmesh = GenerateMesh( m_data.ShapePoints, offset, m_xyFitSize, m_xyFitSize, true );
				EditorUtility.CopySerialized( tempmesh, mesh );
				mesh.vertices = tempmesh.vertices;
				mesh.triangles = tempmesh.triangles;
				mesh.uv = tempmesh.uv;
				mesh.normals = tempmesh.normals;
				mesh.bounds = tempmesh.bounds;
				mesh.name = fileName;
				EditorUtility.SetDirty( mesh );
			}

			if( isPrefab )
			{
#if UNITY_2018_3_OR_NEWER
				if( m_lastImpostor != null && PrefabUtility.GetPrefabAssetType( m_lastImpostor ) == PrefabAssetType.Regular )
#else
				if( m_lastImpostor != null && PrefabUtility.GetPrefabType( m_lastImpostor ) == PrefabType.Prefab )
#endif
				{
					impostorObject = m_lastImpostor;
				}
				else
				{
					GameObject mainGO = new GameObject( "Impostor", new Type[] { typeof( MeshFilter ), typeof( MeshRenderer ) } );
					impostorObject = mainGO;
					justCreated = true;
				}
			}
			else
			{
				if( m_lastImpostor != null )
				{
					impostorObject = m_lastImpostor;
					//impostorObject.transform.position = m_rootTransform.position;
					//impostorObject.transform.rotation = m_rootTransform.rotation;
				}
				else
				{
					impostorObject = new GameObject( "Impostor", new Type[] { typeof( MeshFilter ), typeof( MeshRenderer ) } );
					Undo.RegisterCreatedObjectUndo( impostorObject, "Create Impostor" );
					impostorObject.transform.position = m_rootTransform.position;
					impostorObject.transform.rotation = m_rootTransform.rotation;

					justCreated = true;
				}
			}
			m_lastImpostor = impostorObject;
			impostorObject.transform.localScale = Vector3.one;
			impostorObject.GetComponent<MeshFilter>().sharedMesh = mesh;

			if( justCreated )
			{
				if( LodGroup != null )
				{
					if( isPrefab )
					{
#if UNITY_2018_3_OR_NEWER
						targetPrefab = PrefabUtility.GetPrefabInstanceHandle( ( Selection.activeObject as GameObject ).transform.root.gameObject );
#else
						targetPrefab = PrefabUtility.GetPrefabObject( ( Selection.activeObject as GameObject ).transform.root.gameObject );
#endif
						GameObject targetGO = AssetDatabase.LoadAssetAtPath( folderPath + ( Selection.activeObject as GameObject ).transform.root.gameObject.name + ".prefab", typeof( GameObject ) ) as GameObject;
						UnityEngine.Object inst = PrefabUtility.InstantiatePrefab( targetGO );
						tempGO = inst as GameObject;
						AmplifyImpostor ai = tempGO.GetComponentInChildren<AmplifyImpostor>();
						impostorObject.transform.SetParent( ai.LodGroup.transform );
						ai.m_lastImpostor = impostorObject;
#if UNITY_2018_3_OR_NEWER
						PrefabUtility.SaveAsPrefabAssetAndConnect( tempGO, AssetDatabase.GetAssetPath( targetPrefab ), InteractionMode.AutomatedAction );
#else
						PrefabUtility.ReplacePrefab( tempGO, targetPrefab, ReplacePrefabOptions.ConnectToPrefab );
#endif
						ai = targetGO.GetComponentInChildren<AmplifyImpostor>();
						impostorObject = ai.m_lastImpostor;
						DestroyImmediate( tempGO );
					}
					else
					{
						impostorObject.transform.SetParent( LodGroup.transform, true );
						impostorObject.transform.localScale = Vector3.one;
					}

					switch( m_lodReplacement )
					{
						default:
						case LODReplacement.DoNothing:
						break;
						case LODReplacement.ReplaceCulled:
						{
							LOD[] lods = LodGroup.GetLODs();
							Array.Resize( ref lods, lods.Length + 1 );
							LOD lastLOD = new LOD();
							lastLOD.screenRelativeTransitionHeight = 0;
							lastLOD.renderers = impostorObject.GetComponents<Renderer>();
							lods[ lods.Length - 1 ] = lastLOD;
							LodGroup.SetLODs( lods );
						}
						break;
						case LODReplacement.ReplaceLast:
						{
							LOD[] lods = LodGroup.GetLODs();

							foreach( Renderer item in lods[ lods.Length - 1 ].renderers )
								if( item )
									item.enabled = false;

							lods[ lods.Length - 1 ].renderers = impostorObject.GetComponents<Renderer>();
							LodGroup.SetLODs( lods );
						}
						break;
						case LODReplacement.ReplaceAllExceptFirst:
						{
							LOD[] lods = LodGroup.GetLODs();
							for( int i = lods.Length - 1; i > 0; i-- )
							{
								foreach( Renderer item in lods[ i ].renderers )
									if( item )
										item.enabled = false;
							}
							float lastTransition = lods[ lods.Length - 1 ].screenRelativeTransitionHeight;
							Array.Resize( ref lods, 2 );
							lods[ lods.Length - 1 ].screenRelativeTransitionHeight = lastTransition;
							lods[ lods.Length - 1 ].renderers = impostorObject.GetComponents<Renderer>();
							LodGroup.SetLODs( lods );
						}
						break;
						case LODReplacement.ReplaceSpecific:
						{
							LOD[] lods = LodGroup.GetLODs();
							foreach( Renderer item in lods[ m_insertIndex ].renderers )
								if( item )
									item.enabled = false;

							lods[ m_insertIndex ].renderers = impostorObject.GetComponents<Renderer>();
							LodGroup.SetLODs( lods );
						}
						break;
						case LODReplacement.ReplaceAfterSpecific:
						{
							LOD[] lods = LodGroup.GetLODs();
							for( int i = lods.Length - 1; i > m_insertIndex; i-- )
							{
								foreach( Renderer item in lods[ i ].renderers )
									if( item )
										item.enabled = false;
							}
							float lastTransition = lods[ lods.Length - 1 ].screenRelativeTransitionHeight;
							if( m_insertIndex == lods.Length - 1 )
								lastTransition = 0;
							Array.Resize( ref lods, 2 + m_insertIndex );
							lods[ lods.Length - 1 ].screenRelativeTransitionHeight = lastTransition;
							lods[ lods.Length - 1 ].renderers = impostorObject.GetComponents<Renderer>();
							LodGroup.SetLODs( lods );
						}
						break;
						case LODReplacement.InsertAfter:
						{
							LOD[] lods = LodGroup.GetLODs();
							Array.Resize( ref lods, lods.Length + 1 );
							for( int i = lods.Length - 1; i > m_insertIndex; i-- )
							{
								lods[ i ].screenRelativeTransitionHeight = lods[ i - 1 ].screenRelativeTransitionHeight;
								lods[ i ].fadeTransitionWidth = lods[ i - 1 ].fadeTransitionWidth;
								lods[ i ].renderers = lods[ i - 1 ].renderers;
							}
							
							float firstTransition = 1;
							if( m_insertIndex > 0 )
								firstTransition = lods[ m_insertIndex - 1 ].screenRelativeTransitionHeight;

							lods[ m_insertIndex + 1 ].renderers = impostorObject.GetComponents<Renderer>();
							lods[ m_insertIndex ].screenRelativeTransitionHeight = ( lods[ m_insertIndex + 1 ].screenRelativeTransitionHeight + firstTransition ) * 0.5f;
							LodGroup.SetLODs( lods );
						}
						break;
					}
					Undo.RegisterCompleteObjectUndo( LodGroup, "Create Impostor" );
				}
				else if( !isPrefab )
				{
					impostorObject.transform.SetParent( m_rootTransform.parent );
					int sibIndex = m_rootTransform.GetSiblingIndex();
					impostorObject.transform.SetSiblingIndex( sibIndex + 1 );
					m_rootTransform.SetSiblingIndex( sibIndex );
					impostorObject.transform.localScale = Vector3.one;
				}
			}

			if( LodGroup == null )
			{
				Transform par = impostorObject.transform.parent;
				int sibIndex = impostorObject.transform.GetSiblingIndex();
				impostorObject.transform.SetParent( m_rootTransform, true );
				impostorObject.transform.localScale = Vector3.one;
				impostorObject.transform.SetParent( par, true );
				impostorObject.transform.SetSiblingIndex( sibIndex );
			}


			EditorUtility.SetDirty( m_data );
			if( m_lastImpostor == null )
				impostorObject.name = fileName;
			impostorObject.GetComponent<Renderer>().sharedMaterial = material;
			EditorUtility.SetDirty( impostorObject );

			DisplayProgress( 0.7f );

			// saving and refreshing to make sure textures can be set properly into the material
			AmplifyTextureImporter.Activated = true;
			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
			AmplifyTextureImporter.Activated = false;
			AmplifyTextureImporter.ImportData.Clear();

			DisplayProgress( 0.8f );

			hasDifferentResolution = false;
			tex = null;

			if( standardRendering )
			{
				for( int i = 0; i < outputList.Count; i++ )
				{
					tex = null;
					if( outputList[ i ].Active )
					{
						if( material.HasProperty( m_propertyNames[ i ] ) )
							tex = material.GetTexture( m_propertyNames[ i ] ) as Texture2D;
						if( tex == null )
							tex = AssetDatabase.LoadAssetAtPath<Texture2D>( m_fileNames[ i ] );
						if( tex != null )
							material.SetTexture( m_propertyNames[ i ], tex );

						if( tex != null && tex.width != m_data.TexSize.x / (int)outputList[ i ].Scale )
							hasDifferentResolution = true;
					}
				}
			}
			else
			{
				for( int i = 0; i < outputList.Count; i++ )
				{
					tex = null;
					if( outputList[ i ].Active )
					{
						if( material.HasProperty( outputList[ i ].Name ) )
							tex = material.GetTexture( outputList[ i ].Name ) as Texture2D;
						if( tex == null )
							tex = AssetDatabase.LoadAssetAtPath<Texture2D>( m_fileNames[ i ] );
						if( tex != null )
							material.SetTexture( outputList[ i ].Name, tex );

						if( tex != null && tex.width != m_data.TexSize.x / (int)outputList[ i ].Scale )
							hasDifferentResolution = true;
					}
				}

				for( int i = 0; i < m_propertyNames.Length; i++ )
				{
					tex = null;
					if( material.HasProperty( m_propertyNames[ i ] ) )
						tex = material.GetTexture( m_propertyNames[ i ] ) as Texture2D;
					if( tex == null )
					{
						string filen = folderPath + fileName + m_standardFileNames[ i ] + ".tga";
						tex = AssetDatabase.LoadAssetAtPath<Texture2D>( filen );
					}
					if( tex == null )
					{
						string filen = folderPath + fileName + m_standardFileNames[ i ] + ".png";
						tex = AssetDatabase.LoadAssetAtPath<Texture2D>( filen );
					}
					if( tex != null )
						material.SetTexture( m_propertyNames[ i ], tex );

					if( tex != null )
					{
						int indexFound = outputList.FindIndex( x => x.Name == m_standardFileNames[ i ] );
						if( indexFound > -1 && tex.width != ( (int)m_data.TexSize.x / (int)outputList[ indexFound ].Scale ) )
							hasDifferentResolution = true;
					}
				}
			}

			if( m_data.ImpostorType == ImpostorType.HemiOctahedron )
			{
				material.SetFloat( "_Hemi", 1 );
				material.EnableKeyword( "_HEMI_ON" );
			}
			else
			{
				material.SetFloat( "_Hemi", 0 );
				material.DisableKeyword( "_HEMI_ON" );
			}

			if( m_data.Preset.RuntimeShader == null )
			{
				material.SetFloat( "_Frames", m_data.HorizontalFrames );
				material.SetFloat( "_ImpostorSize", m_xyFitSize );
				material.SetVector( "_Offset", offset );
				material.SetVector( "_AI_SizeOffset", sizeOffset );
				material.SetFloat( "_DepthSize", m_depthFitSize );
				material.SetFloat( "_FramesX", m_data.HorizontalFrames );
				material.SetFloat( "_FramesY", m_data.VerticalFrames );
			}
			else
			{
				material.SetFloat( "_AI_Frames", m_data.HorizontalFrames );
				material.SetFloat( "_AI_ImpostorSize", m_xyFitSize );
				material.SetVector( "_AI_Offset", offset );
				material.SetVector( "_AI_SizeOffset", sizeOffset );
				material.SetFloat( "_AI_DepthSize", m_depthFitSize );
				material.SetFloat( "_AI_FramesX", m_data.HorizontalFrames );
				material.SetFloat( "_AI_FramesY", m_data.VerticalFrames );
			}
			EditorUtility.SetDirty( material );

			if( hasDifferentResolution && resizeTextures )
				resizeTextures = true;
			else
				resizeTextures = false;

			DisplayProgress( 1f );

			for( int i = 0; i < outputList.Count; i++ )
			{
				if( outputList[ i ].Active )
					ChangeTextureImporter( ref m_rtGBuffers[ i ], m_fileNames[ i ], outputList[i].SRGB, resizeTextures, outputList[ i ].Compression, outputList[ i ].Channels == TextureChannels.RGBA );
			}
			ClearBuffers();

			Data.Version = VersionInfo.FullNumber;
		}
#endif

			/// <summary>
			/// Renders Impostors maps to render textures
			/// </summary>
			/// <param name="impostorType"></param>
			/// <param name="impostorMaps">set to true to render all selected maps</param>
			/// <param name="combinedAlphas">set to true to render the combined alpha map which is used to generate the mesh</param>
			public void RenderImpostor( ImpostorType impostorType, int targetAmount, bool impostorMaps = true, bool combinedAlphas = false, bool useMinResolution = false, Shader customShader = null )
		{
			if( !impostorMaps && !combinedAlphas ) //leave early
				return;

			if( targetAmount <= 0 )
				return;

			bool isStandardBake = customShader == null;
			Dictionary<Material, Material> bakeMats = new Dictionary<Material, Material>();

			CommandBuffer commandBuffer = new CommandBuffer();
			if( impostorMaps )
			{
				commandBuffer.name = "GBufferCatcher";
				RenderTargetIdentifier[] rtIDs = new RenderTargetIdentifier[ targetAmount ];
				for( int i = 0; i < targetAmount; i++ )
				{
					rtIDs[ i ] = m_rtGBuffers[ i ];
				}
				commandBuffer.SetRenderTarget( rtIDs, m_trueDepth );
				commandBuffer.ClearRenderTarget( true, true, Color.clear, 1 );
			}

			CommandBuffer commandAlphaBuffer = new CommandBuffer();
			if( combinedAlphas )
			{
				commandAlphaBuffer.name = "DepthAlphaCatcher";
				RenderTargetIdentifier[] rtIDsAlpha = new RenderTargetIdentifier[ targetAmount ];
				for( int i = 0; i < targetAmount; i++ )
				{
					rtIDsAlpha[ i ] = m_alphaGBuffers[ i ];
				}
				commandAlphaBuffer.SetRenderTarget( rtIDsAlpha, rtIDsAlpha[ 0 ] );
				commandAlphaBuffer.ClearRenderTarget( true, true, Color.clear, 1 );
			}

			int hframes = m_data.HorizontalFrames;
			int vframes = m_data.HorizontalFrames;

			if( impostorType == ImpostorType.Spherical )
			{
				vframes = m_data.HorizontalFrames - 1;
				if( m_data.DecoupleAxisFrames )
					vframes = m_data.VerticalFrames - 1;
			}

			List<MeshFilter> validMeshes = new List<MeshFilter>();
			for( int i = 0; i < Renderers.Length; i++ )
			{
				// only allow for renderers that are enabled and not marked as shadow only
				if( Renderers[ i ] == null || !Renderers[ i ].enabled || Renderers[ i ].shadowCastingMode == ShadowCastingMode.ShadowsOnly )
				{
					validMeshes.Add( null );
					continue;
				}

				// skip non-meshes, for now
				MeshFilter mf = Renderers[ i ].GetComponent<MeshFilter>();
				if( mf == null || mf.sharedMesh == null )
				{
					validMeshes.Add( null );
					continue;
				}

				validMeshes.Add( mf );
			}

			int validMeshesCount = validMeshes.Count;

			for( int x = 0; x < hframes; x++ )
			{
				for( int y = 0; y <= vframes; y++ )
				{
					Bounds frameBounds = new Bounds();
					Matrix4x4 camMatrixRot = GetCameraRotationMatrix( impostorType, hframes, vframes, x, y );

					for( int i = 0; i < validMeshesCount; i++ )
					{
						if( validMeshes[ i ] == null )
							continue;

						if( frameBounds.size == Vector3.zero )
							frameBounds = validMeshes[ i ].sharedMesh.bounds.Transform( m_rootTransform.worldToLocalMatrix * Renderers[ i ].localToWorldMatrix );
						else
							frameBounds.Encapsulate( validMeshes[ i ].sharedMesh.bounds.Transform( m_rootTransform.worldToLocalMatrix * Renderers[ i ].localToWorldMatrix ) );
					}

					if( x == 0 && y == 0 )
						m_originalBound = frameBounds;

					frameBounds = frameBounds.Transform( camMatrixRot );
					Matrix4x4 V = camMatrixRot.inverse * Matrix4x4.LookAt( frameBounds.center - new Vector3( 0, 0, m_depthFitSize * 0.5f ), frameBounds.center, Vector3.up );
					float fitSize = m_xyFitSize * 0.5f;
					Matrix4x4 P = Matrix4x4.Ortho( -fitSize+ m_pixelOffset.x, fitSize + m_pixelOffset.x, -fitSize + m_pixelOffset.y, fitSize + m_pixelOffset.y, 0, -m_depthFitSize );

					if( impostorMaps )
					{
						commandBuffer.SetViewProjectionMatrices( V.inverse * m_rootTransform.worldToLocalMatrix, P );
						commandBuffer.SetViewport( new Rect( ( m_data.TexSize.x / hframes ) * x, ( m_data.TexSize.y / ( vframes + ( impostorType == ImpostorType.Spherical ? 1 : 0 ) ) ) * y, ( m_data.TexSize.x / m_data.HorizontalFrames ), ( m_data.TexSize.y / m_data.VerticalFrames ) ) );
					}

					if( combinedAlphas )
					{
						commandAlphaBuffer.SetViewProjectionMatrices( V.inverse * m_rootTransform.worldToLocalMatrix, P );
						commandAlphaBuffer.SetViewport( new Rect( 0, 0, MinAlphaResolution, MinAlphaResolution ) );
					}

					for( int j = 0; j < validMeshesCount; j++ )
					{
						if( validMeshes[ j ] == null )
							continue;

						// Renderer shares array position with validMesh
						Material[] meshMaterials = Renderers[ j ].sharedMaterials;

						// Draw Mesh
						//Transform childTransform = Renderers[ j ].transform;
						//MaterialPropertyBlock pBlock = new MaterialPropertyBlock();
						//Renderers[ j ].GetPropertyBlock( pBlock );
						//Matrix4x4 localMatrix = m_rootTransform.worldToLocalMatrix * childTransform.localToWorldMatrix;

						for( int k = 0; k < meshMaterials.Length; k++ )
						{
							Material renderMaterial = null;
							Mesh mesh = validMeshes[ j ].sharedMesh;
							int pass = 0;
							if( isStandardBake )
							{
								renderMaterial = meshMaterials[ k ];
								pass = renderMaterial.FindPass( "DEFERRED" );
								if( pass == -1 )
									pass = renderMaterial.FindPass( "Deferred" );
								if( pass == -1 ) // last resort fallback
								{
									pass = 0;
									for( int sp = 0; sp < renderMaterial.passCount; sp++ )
									{
										string lightmode = renderMaterial.GetTag( "LightMode", true );
										if( lightmode.Equals( "Deferred" ) )
										{
											pass = sp;
											break;
										}
									}
								}
								// Only useful for 2017.1 and 2017.2
								commandBuffer.EnableShaderKeyword( "UNITY_HDR_ON" );
							}
							else
							{
								if( !bakeMats.TryGetValue( meshMaterials[ k ], out renderMaterial ) )
								{

									renderMaterial = new Material( customShader ) { hideFlags = HideFlags.HideAndDontSave };
#if UNITY_EDITOR
									renderMaterial.CopyPropertiesFrom( meshMaterials[ k ] );
#endif
									bakeMats.Add( meshMaterials[ k ], renderMaterial );
								}
							}

							// Setup Lightmap keywords and values
							bool isUsingBakedGI = Renderers[ j ].lightmapIndex > -1;
							bool isUsingRealtimeGI = Renderers[ j ].realtimeLightmapIndex > -1;
							//Debug.Log( isUsingBakedGI +" "+ isUsingRealtimeGI );
							if(( isUsingBakedGI || isUsingRealtimeGI) && !isStandardBake )
							{
								commandBuffer.EnableShaderKeyword( "LIGHTMAP_ON" );
								if( isUsingBakedGI )
								{
									commandBuffer.SetGlobalVector( "unity_LightmapST", Renderers[ j ].lightmapScaleOffset );
								}

								if( isUsingRealtimeGI )
								{
									commandBuffer.EnableShaderKeyword( "DYNAMICLIGHTMAP_ON" );
									commandBuffer.SetGlobalVector( "unity_DynamicLightmapST", Renderers[ j ].realtimeLightmapScaleOffset );
								}
								else
								{
									commandBuffer.DisableShaderKeyword( "DYNAMICLIGHTMAP_ON" );
								}

								if( isUsingBakedGI && isUsingRealtimeGI )
								{
									commandBuffer.EnableShaderKeyword( "DIRLIGHTMAP_COMBINED" );
								}
								else
								{
									commandBuffer.DisableShaderKeyword( "DIRLIGHTMAP_COMBINED" );
								}
							}
							else
							{
								commandBuffer.DisableShaderKeyword( "LIGHTMAP_ON" );
								commandBuffer.DisableShaderKeyword( "DYNAMICLIGHTMAP_ON" );
								commandBuffer.DisableShaderKeyword( "DIRLIGHTMAP_COMBINED" );
							}

							commandBuffer.DisableShaderKeyword( "LIGHTPROBE_SH" );

							if( impostorMaps )
								commandBuffer.DrawRenderer( Renderers[ j ], renderMaterial, k, pass );
							//commandBuffer.DrawMesh( mesh, localMatrix, renderMaterial, k, pass, pBlock );

							if( combinedAlphas )
								commandAlphaBuffer.DrawRenderer( Renderers[ j ], renderMaterial, k, pass );
							//commandAlphaBuffer.DrawMesh( mesh, localMatrix, renderMaterial, k, pass, pBlock );
						}
					}

					if( impostorMaps )
						Graphics.ExecuteCommandBuffer( commandBuffer );

					if( combinedAlphas )
						Graphics.ExecuteCommandBuffer( commandAlphaBuffer );
				}
			}

			validMeshes.Clear();

			foreach( var pair in bakeMats )
			{
				Material bakeMat = pair.Value;
				if( bakeMat != null )
				{
					if( !Application.isPlaying )
						DestroyImmediate( bakeMat );
					bakeMat = null;
				}
			}
			bakeMats.Clear();

			commandBuffer.Release();
			commandBuffer = null;

			commandAlphaBuffer.Release();
			commandAlphaBuffer = null;
		}

		//public void Update()
		//{
		//	RenderAllDeferredGroups( m_data );
		//}

		private Matrix4x4 GetCameraRotationMatrix( ImpostorType impostorType, int hframes, int vframes, int x, int y )
		{
			Matrix4x4 camMatrixRot = Matrix4x4.identity;
			if( impostorType == ImpostorType.Spherical ) //SPHERICAL
			{
				float fractionY = 0;
				if( vframes > 0 )
					fractionY = -( 180.0f / vframes );
				Quaternion hRot = Quaternion.Euler( fractionY * y + StartYRotation, 0, 0 );
				Quaternion vRot = Quaternion.Euler( 0, ( 360.0f / hframes ) * x + StartXRotation, 0 );
				camMatrixRot = Matrix4x4.Rotate( hRot * vRot );

			}
			else if( impostorType == ImpostorType.Octahedron ) //OCTAHEDRON
			{
				Vector3 forw = OctahedronToVector( ( (float)( x ) / ( (float)hframes - 1 ) ) * 2f - 1f, ( (float)( y ) / ( (float)vframes - 1 ) ) * 2f - 1f );
				Quaternion octa = Quaternion.LookRotation( new Vector3( forw.x * -1, forw.z * -1, forw.y * -1 ), Vector3.up );
				camMatrixRot = Matrix4x4.Rotate( octa ).inverse;
			}
			else if( impostorType == ImpostorType.HemiOctahedron ) //HEMIOCTAHEDRON
			{
				Vector3 forw = HemiOctahedronToVector( ( (float)( x ) / ( (float)hframes - 1 ) ) * 2f - 1f, ( (float)( y ) / ( (float)vframes - 1 ) ) * 2f - 1f );
				Quaternion octa = Quaternion.LookRotation( new Vector3( forw.x * -1, forw.z * -1, forw.y * -1 ), Vector3.up );
				camMatrixRot = Matrix4x4.Rotate( octa ).inverse;
			}
			return camMatrixRot;
		}

		private Vector3 OctahedronToVector( Vector2 oct )
		{
			Vector3 N = new Vector3( oct.x, oct.y, 1.0f - Mathf.Abs( oct.x ) - Mathf.Abs( oct.y ) );
			float t = Mathf.Clamp01( -N.z );
			N.Set( N.x + ( N.x >= 0.0f ? -t : t ), N.y + ( N.y >= 0.0f ? -t : t ), N.z );
			N = Vector3.Normalize( N );
			return N;
		}

		private Vector3 OctahedronToVector( float x, float y )
		{
			Vector3 N = new Vector3( x, y, 1.0f - Mathf.Abs( x ) - Mathf.Abs( y ) );
			float t = Mathf.Clamp01( -N.z );
			N.Set( N.x + ( N.x >= 0.0f ? -t : t ), N.y + ( N.y >= 0.0f ? -t : t ), N.z );
			N = Vector3.Normalize( N );
			return N;
		}

		private Vector3 HemiOctahedronToVector( float x, float y )
		{
			float tempx = x;
			float tempy = y;

			x = ( tempx + tempy ) * 0.5f;
			y = ( tempx - tempy ) * 0.5f;
			Vector3 N = new Vector3( x, y, 1.0f - Mathf.Abs( x ) - Mathf.Abs( y ) );
			N = Vector3.Normalize( N );
			return N;
		}

		public void GenerateAutomaticMesh( AmplifyImpostorAsset data )
		{
			// create a 2d texture for calculations
			Rect testRect = new Rect( 0, 0, m_alphaTex.width, m_alphaTex.height );
			Vector2[][] paths;
			SpriteUtilityEx.GenerateOutline( m_alphaTex, testRect, data.Tolerance, 254, false, out paths );
			int sum = 0;
			for( int i = 0; i < paths.Length; i++ )
			{
				sum += paths[ i ].Length;
			}

			data.ShapePoints = new Vector2[ sum ];
			int index = 0;
			for( int i = 0; i < paths.Length; i++ )
			{
				for( int j = 0; j < paths[ i ].Length; j++ )
				{
					data.ShapePoints[ index ] = (Vector2)( paths[ i ][ j ] ) + ( new Vector2( m_alphaTex.width * 0.5f, m_alphaTex.height * 0.5f ) );
					data.ShapePoints[ index ] = Vector2.Scale( data.ShapePoints[ index ], new Vector2( 1.0f / m_alphaTex.width, 1.0f / m_alphaTex.height ) );
					index++;
				}
			}

			// make it convex hull
			data.ShapePoints = Vector2Ex.ConvexHull( data.ShapePoints );

			// reduce vertices
			data.ShapePoints = Vector2Ex.ReduceVertices( data.ShapePoints, data.MaxVertices );

			// Resize the mesh using calculated normals
			data.ShapePoints = Vector2Ex.ScaleAlongNormals( data.ShapePoints, data.NormalScale );

			// clamp to box (needs a cut algorithm)
			for( int i = 0; i < data.ShapePoints.Length; i++ )
			{
				data.ShapePoints[ i ].x = Mathf.Clamp01( data.ShapePoints[ i ].x );
				data.ShapePoints[ i ].y = Mathf.Clamp01( data.ShapePoints[ i ].y );
			}

			// make it convex hull gain to clean edges
			data.ShapePoints = Vector2Ex.ConvexHull( data.ShapePoints );

			// invert Y
			for( int i = 0; i < data.ShapePoints.Length; i++ )
			{
				data.ShapePoints[ i ] = new Vector2( data.ShapePoints[ i ].x, 1 - data.ShapePoints[ i ].y );
			}
		}

		public Mesh GenerateMesh( Vector2[] points, Vector3 offset, float width = 1, float height = 1, bool invertY = true )
		{
			Vector2[] newPoints = new Vector2[ points.Length ];
			Vector2[] UVs = new Vector2[ points.Length ];
			Array.Copy( points, newPoints, points.Length );
			float halfWidth = width * 0.5f;
			float halfHeight = height * 0.5f;

			if( invertY )
			{
				for( int i = 0; i < newPoints.Length; i++ )
				{
					newPoints[ i ] = new Vector2( newPoints[ i ].x, 1 - newPoints[ i ].y );
				}
			}

			Array.Copy( newPoints, UVs, newPoints.Length );

			for( int i = 0; i < newPoints.Length; i++ )
			{
				newPoints[ i ] = new Vector2( newPoints[ i ].x * width - halfWidth + m_pixelOffset.x, newPoints[ i ].y * height - halfHeight + m_pixelOffset.y );
			}

			Triangulator tr = new Triangulator( newPoints );
			int[] indices = tr.Triangulate();

			Vector3[] vertices = new Vector3[ tr.Points.Count ];
			for( int i = 0; i < vertices.Length; i++ )
			{
				vertices[ i ] = new Vector3( tr.Points[ i ].x, tr.Points[ i ].y, 0 );
			}

			//Vector4[] tangents = new Vector4[ tr.Points.Count ];
			//for( int i = 0; i < vertices.Length; i++ )
			//{
			//	tangents[ i ] = new Vector4( 1, 0, 0, 1 );
			//}

			Mesh mesh = new Mesh();
			mesh.vertices = vertices;
			mesh.uv = UVs;
			//mesh.tangents = tangents;

			mesh.triangles = indices;
			mesh.RecalculateNormals();
			mesh.bounds = new Bounds( offset, m_originalBound.size );

			return mesh;
		}
	}
}
