// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Good/Grass/Wind-Grass"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_BaseMap("BaseMap", 2D) = "white" {}
		_BassTextureLerp("BassTextureLerp", Range( 0 , 1)) = 1
		_ColorA("ColorA", Color) = (0.4103774,1,0.4275469,0)
		_ColorB("ColorB", Color) = (0.4103774,1,0.4275469,0)
		_TopLightIntensity("Top-Light-Intensity", Range( 0.5 , 3)) = 1
		_RootLightIntensity("Root-Light-Intensity", Range( 0.9 , 3)) = 1
		_ColorNoiseSize("ColorNoiseSize", Range( 0 , 2)) = 0.6
		_WindMap("Wind-Map", 2D) = "white" {}
		_WindMapTiling("Wind-Map-Tiling", Range( 0.1 , 0.7)) = 1
		_WindSpeed("Wind-Speed", Range( 0.01 , 3)) = -0.3
		_WindColor("WindColor", Color) = (0.5238074,0.745283,0.6270263,0)
		_WindDark("WindDark", Range( -3 , 0.45)) = 0.03529409
		[HideInInspector][PerRendererData][NoScaleOffset][Normal]_WindNoiseMap("WindNoiseMap", 2D) = "bump" {}
		_WindNoiseScale("Wind-Noise-Scale", Range( 0 , 1)) = 0.1
		_WindNoiseTiling("Wind-Noise-Tiling", Range( 0.1 , 1)) = 1
		_WindNoiseSpeed("Wind-Noise-Speed", Range( 0.01 , 1)) = -0.3
		_WindSinSpeedX("Wind-SinSpeedX", Range( -1 , 1)) = -0.3
		_WindSinSpeedZ("Wind-SinSpeedZ", Range( -1 , 1)) = -0.3
		_GrassOffsetIntensity("Grass-Offset-Intensity", Range( 0 , 1)) = 0
		_GrassOffsetLerp("Grass-Offset-Lerp", Range( 0 , 1)) = 1
		_ProjectMap("ProjectMap", 2D) = "white" {}
		_ProjectMapSize("ProjectMap-Size", Float) = 40
		_ProjectMapCreatX("ProjectMap-Creat-X", Float) = 0
		_ProjectMapCreatZ("ProjectMap-Creat-Z", Float) = 0
		[HideInInspector]_FogRampmap("Fog-Rampmap", 2D) = "white" {}
		[HideInInspector][HDR]_FogRampColor("Fog-RampColor", Color) = (0.6036298,0.7027331,0.9189587,0)
		[HideInInspector]_FogDistance("Fog-Distance", Range( 0 , 0.1)) = 0.023
		[HideInInspector]_FogDistanceFogInstensity("Fog-DistanceFog-Instensity", Range( 0 , 5)) = 2.74
		[HideInInspector]_FogDistanceFogRampOffset("Fog-DistanceFog-RampOffset", Range( -2 , 2)) = -0.46
		[HideInInspector]_FogHorizontalLine("Fog-HorizontalLine", Range( -22 , 22)) = -17
		[HideInInspector]_FogHeightOffset("Fog-HeightOffset", Range( -1.5 , 1)) = 0.56
		[HideInInspector]_FogHeightHard("Fog-HeightHard", Range( 0 , 0.1)) = 0.015
		[HideInInspector]_FogDistanceAlphaOffset("Fog-Distance-AlphaOffset", Range( -2 , 2)) = -0.03
		_ProjectShadowMap("ProjectShadowMap", 2D) = "white" {}
		_HeightLightPower("HeightLight-Power", Range( 45 , 75)) = 1
		_HeightLightColor("HeightLight-Color", Color) = (0.5829477,0.9433962,0.6076172,0)
		_HeightLightIntensity("HeightLight-Intensity", Range( 1 , 45)) = 2
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Off
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0,0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 70108

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ColorB;
			float4 _FogRampColor;
			float4 _WindColor;
			float4 _HeightLightColor;
			float4 _BaseMap_ST;
			float4 _ColorA;
			float _FogHorizontalLine;
			float _FogDistanceAlphaOffset;
			float _FogDistance;
			float _FogDistanceFogRampOffset;
			float _FogDistanceFogInstensity;
			float _WindDark;
			float _HeightLightIntensity;
			float _HeightLightPower;
			float _TopLightIntensity;
			float _BassTextureLerp;
			float _WindSinSpeedX;
			float _FogHeightHard;
			float _RootLightIntensity;
			float _ProjectMapSize;
			float _ProjectMapCreatZ;
			float _ProjectMapCreatX;
			float _GrassOffsetIntensity;
			float _WindNoiseScale;
			float _WindNoiseTiling;
			float _WindNoiseSpeed;
			float _WindSpeed;
			float _WindMapTiling;
			float _GrassOffsetLerp;
			float _WindSinSpeedZ;
			float _ColorNoiseSize;
			float _FogHeightOffset;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_WindMap);
			SAMPLER(sampler_WindMap);
			TEXTURE2D(_WindNoiseMap);
			SAMPLER(sampler_WindNoiseMap);
			TEXTURE2D(_ProjectShadowMap);
			SAMPLER(sampler_ProjectShadowMap);
			TEXTURE2D(_ProjectMap);
			SAMPLER(sampler_ProjectMap);
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
			TEXTURE2D(_FogRampmap);
			SAMPLER(sampler_FogRampmap);


						
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 temp_cast_0 = (0.0).xxx;
				float DirX334 = _WindSinSpeedX;
				float DirZ335 = _WindSinSpeedZ;
				float3 appendResult338 = (float3(DirX334 , 0.0 , DirZ335));
				float3 normalizeResult339 = normalize( appendResult338 );
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult18 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 temp_output_26_0 = ( appendResult18 * 0.6 );
				float3 appendResult332 = (float3(DirX334 , DirZ335 , 0.0));
				float3 normalizeResult333 = normalize( appendResult332 );
				float3 temp_output_259_0 = ( normalizeResult333 * -1.0 );
				float WindSpeed2281 = _WindSpeed;
				float mulTime24 = _TimeParameters.x * WindSpeed2281;
				float3 WorldUV60 = ( float3( temp_output_26_0 ,  0.0 ) + ( temp_output_259_0 * mulTime24 ) );
				float4 tex2DNode58 = SAMPLE_TEXTURE2D_LOD( _WindMap, sampler_WindMap, ( _WindMapTiling * WorldUV60 ).xy, 0.0 );
				float WindTextureFinal71 = tex2DNode58.r;
				float3 lerpResult267 = lerp( float3(0,1,0) , ( normalizeResult339 * 1.0 ) , ( _GrassOffsetLerp * saturate( (0.53 + (WindTextureFinal71 - 0.0) * (1.0 - 0.53) / (1.0 - 0.0)) ) ));
				float mulTime357 = _TimeParameters.x * _WindNoiseSpeed;
				float3 WorldNoiseUV355 = ( float3( temp_output_26_0 ,  0.0 ) + ( temp_output_259_0 * mulTime357 ) );
				float3 unpack43 = UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( WorldNoiseUV355 * _WindNoiseTiling * WindSpeed2281 ).xy, 0.0 ), ( _WindNoiseScale * WindSpeed2281 ) );
				unpack43.z = lerp( 1, unpack43.z, saturate(( _WindNoiseScale * WindSpeed2281 )) );
				float3 normalizeResult274 = normalize( ( ( lerpResult267 * ( WindSpeed2281 * 1.0 ) ) + abs( (unpack43).xzy ) ) );
				float3 lerpResult293 = lerp( temp_cast_0 , normalizeResult274 , _GrassOffsetIntensity);
				float VCRemap177 = saturate( (-0.04 + (v.ase_color.r - 0.0) * (1.0 - -0.04) / (1.0 - 0.0)) );
				float4 transform54 = mul(GetWorldToObjectMatrix(),float4( ( lerpResult293 * float3(1,0,1) * VCRemap177 ) , 0.0 ));
				float4 GrassOffset127 = transform54;
				
				float2 appendResult137 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 appendResult147 = (float2(_ProjectMapCreatX , _ProjectMapCreatZ));
				float4 tex2DNode182 = SAMPLE_TEXTURE2D_LOD( _ProjectShadowMap, sampler_ProjectShadowMap, ( ( ( appendResult137 + ( appendResult147 * -1.0 ) ) * ( 1.0 / _ProjectMapSize ) ) + 0.5 ), 0.0 );
				float4 UVProjectShadow183 = tex2DNode182;
				float4 UVProject148 = SAMPLE_TEXTURE2D_LOD( _ProjectMap, sampler_ProjectMap, ( ( ( appendResult137 + ( appendResult147 * -1.0 ) ) * ( 1.0 / _ProjectMapSize ) ) + 0.5 ), 0.0 );
				float4 temp_output_185_0 = ( UVProjectShadow183 * UVProject148 * _RootLightIntensity );
				float2 uv_BaseMap = v.ase_texcoord.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D_LOD( _BaseMap, sampler_BaseMap, uv_BaseMap, 0.0 );
				float2 appendResult114 = (float2(ase_worldPos.x , ase_worldPos.z));
				float4 lerpResult119 = lerp( _ColorA , _ColorB , saturate( ( UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( appendResult114 * _ColorNoiseSize ), 0.0 ), 1.0f ).g + 0.0 ) ));
				float4 lerpResult7 = lerp( tex2DNode5 , lerpResult119 , _BassTextureLerp);
				float4 lerpResult180 = lerp( temp_output_185_0 , ( temp_output_185_0 * lerpResult7 * _TopLightIntensity ) , VCRemap177);
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				float3 lerpResult325 = lerp( normalizedWorldNormal , float3(0,1,0) , 0.965);
				float3 worldSpaceViewDir298 = ( _WorldSpaceCameraPos.xyz - mul(GetObjectToWorldMatrix(), float4( 0,0,0,1 ) ).xyz );
				float3 normalizeResult299 = normalize( worldSpaceViewDir298 );
				float3 normalizeResult302 = normalize( ( SafeNormalize(_MainLightPosition.xyz) + normalizeResult299 ) );
				float dotResult305 = dot( lerpResult325 , normalizeResult302 );
				float clampResult328 = clamp( pow( saturate( dotResult305 ) , _HeightLightPower ) , 0.0 , 2.0 );
				float4 HighLight310 = ( clampResult328 * saturate( (-1.6 + (v.ase_color.r - 0.0) * (2.6 - -1.6) / (1.0 - 0.0)) ) * _HeightLightColor * _HeightLightIntensity * UVProjectShadow183 );
				float WindProjectDark167 = saturate( (-0.5 + (( tex2DNode182.r + 0.0 ) - _WindDark) * (1.0 - -0.5) / (0.45 - _WindDark)) );
				float temp_output_82_0 = saturate( ( _FogDistanceFogInstensity * saturate( ( _FogDistanceFogRampOffset + ( distance( _WorldSpaceCameraPos , ase_worldPos ) * _FogDistance ) ) ) ) );
				float2 appendResult92 = (float2(temp_output_82_0 , temp_output_82_0));
				float4 FogColor106 = ( SAMPLE_TEXTURE2D_LOD( _FogRampmap, sampler_FogRampmap, appendResult92, 0.0 ) * _FogRampColor );
				float temp_output_99_0 = saturate( ( ( ( ase_worldPos.y + _FogHorizontalLine ) * _FogHeightHard ) + _FogHeightOffset ) );
				float FogLerp107 = saturate( ( saturate( ( ( ( distance( _WorldSpaceCameraPos , ase_worldPos ) * _FogDistance ) * ( distance( _WorldSpaceCameraPos , ase_worldPos ) * _FogDistance ) ) + _FogDistanceAlphaOffset ) ) - ( temp_output_99_0 * temp_output_99_0 * temp_output_99_0 ) ) );
				float4 lerpResult108 = lerp( ( lerpResult180 + HighLight310 + ( ( tex2DNode58.r * _WindColor ) * WindProjectDark167 * VCRemap177 ) ) , FogColor106 , FogLerp107);
				float4 vertexToFrag350 = lerpResult108;
				o.ase_texcoord3 = vertexToFrag350;
				
				o.ase_texcoord4.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = GrassOffset127.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float4 vertexToFrag350 = IN.ase_texcoord3;
				
				float2 uv_BaseMap = IN.ase_texcoord4.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseMap, sampler_BaseMap, uv_BaseMap );
				float Alpha130 = tex2DNode5.a;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = vertexToFrag350.rgb;
				float Alpha = Alpha130;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 70108

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ColorB;
			float4 _FogRampColor;
			float4 _WindColor;
			float4 _HeightLightColor;
			float4 _BaseMap_ST;
			float4 _ColorA;
			float _FogHorizontalLine;
			float _FogDistanceAlphaOffset;
			float _FogDistance;
			float _FogDistanceFogRampOffset;
			float _FogDistanceFogInstensity;
			float _WindDark;
			float _HeightLightIntensity;
			float _HeightLightPower;
			float _TopLightIntensity;
			float _BassTextureLerp;
			float _WindSinSpeedX;
			float _FogHeightHard;
			float _RootLightIntensity;
			float _ProjectMapSize;
			float _ProjectMapCreatZ;
			float _ProjectMapCreatX;
			float _GrassOffsetIntensity;
			float _WindNoiseScale;
			float _WindNoiseTiling;
			float _WindNoiseSpeed;
			float _WindSpeed;
			float _WindMapTiling;
			float _GrassOffsetLerp;
			float _WindSinSpeedZ;
			float _ColorNoiseSize;
			float _FogHeightOffset;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_WindMap);
			SAMPLER(sampler_WindMap);
			TEXTURE2D(_WindNoiseMap);
			SAMPLER(sampler_WindNoiseMap);
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 temp_cast_0 = (0.0).xxx;
				float DirX334 = _WindSinSpeedX;
				float DirZ335 = _WindSinSpeedZ;
				float3 appendResult338 = (float3(DirX334 , 0.0 , DirZ335));
				float3 normalizeResult339 = normalize( appendResult338 );
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult18 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 temp_output_26_0 = ( appendResult18 * 0.6 );
				float3 appendResult332 = (float3(DirX334 , DirZ335 , 0.0));
				float3 normalizeResult333 = normalize( appendResult332 );
				float3 temp_output_259_0 = ( normalizeResult333 * -1.0 );
				float WindSpeed2281 = _WindSpeed;
				float mulTime24 = _TimeParameters.x * WindSpeed2281;
				float3 WorldUV60 = ( float3( temp_output_26_0 ,  0.0 ) + ( temp_output_259_0 * mulTime24 ) );
				float4 tex2DNode58 = SAMPLE_TEXTURE2D_LOD( _WindMap, sampler_WindMap, ( _WindMapTiling * WorldUV60 ).xy, 0.0 );
				float WindTextureFinal71 = tex2DNode58.r;
				float3 lerpResult267 = lerp( float3(0,1,0) , ( normalizeResult339 * 1.0 ) , ( _GrassOffsetLerp * saturate( (0.53 + (WindTextureFinal71 - 0.0) * (1.0 - 0.53) / (1.0 - 0.0)) ) ));
				float mulTime357 = _TimeParameters.x * _WindNoiseSpeed;
				float3 WorldNoiseUV355 = ( float3( temp_output_26_0 ,  0.0 ) + ( temp_output_259_0 * mulTime357 ) );
				float3 unpack43 = UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( WorldNoiseUV355 * _WindNoiseTiling * WindSpeed2281 ).xy, 0.0 ), ( _WindNoiseScale * WindSpeed2281 ) );
				unpack43.z = lerp( 1, unpack43.z, saturate(( _WindNoiseScale * WindSpeed2281 )) );
				float3 normalizeResult274 = normalize( ( ( lerpResult267 * ( WindSpeed2281 * 1.0 ) ) + abs( (unpack43).xzy ) ) );
				float3 lerpResult293 = lerp( temp_cast_0 , normalizeResult274 , _GrassOffsetIntensity);
				float VCRemap177 = saturate( (-0.04 + (v.ase_color.r - 0.0) * (1.0 - -0.04) / (1.0 - 0.0)) );
				float4 transform54 = mul(GetWorldToObjectMatrix(),float4( ( lerpResult293 * float3(1,0,1) * VCRemap177 ) , 0.0 ));
				float4 GrassOffset127 = transform54;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = GrassOffset127.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_BaseMap = IN.ase_texcoord2.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseMap, sampler_BaseMap, uv_BaseMap );
				float Alpha130 = tex2DNode5.a;
				
				float Alpha = Alpha130;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "ASEMaterialInspector"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18400
193;295;1436;571;6419.176;-1896.829;5.882483;True;False
Node;AmplifyShaderEditor.CommentaryNode;12;-3335.922,887.2499;Inherit;False;2402.519;704.9338;SinWave;23;24;281;258;354;355;60;30;259;26;22;341;18;333;15;332;335;334;21;257;356;357;367;368;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;257;-3126.56,1191.84;Inherit;False;Property;_WindSinSpeedX;Wind-SinSpeedX;16;0;Create;True;0;0;False;0;False;-0.3;0.11;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-3126.56,1277.84;Inherit;False;Property;_WindSinSpeedZ;Wind-SinSpeedZ;17;0;Create;True;0;0;False;0;False;-0.3;-0.02;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;334;-2822.459,1193.69;Inherit;False;DirX;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;335;-2819.459,1278.69;Inherit;False;DirZ;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;332;-2589.985,1205.323;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;258;-3111.578,1422.642;Inherit;False;Property;_WindSpeed;Wind-Speed;9;0;Create;True;0;0;False;0;False;-0.3;0.76;0.01;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;341;-2422.887,1313.745;Inherit;False;Constant;_Float5;Float 5;38;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;281;-2781.237,1423.113;Inherit;False;WindSpeed2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;333;-2426.122,1204.419;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;15;-3232.96,945.2499;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;24;-2544.467,1424.7;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;259;-2232.859,1194.083;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;18;-2678.621,959.1208;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-2709.681,1086.077;Inherit;False;Constant;_WindWaveSize;Wind-WaveSize;16;0;Create;True;0;0;False;0;False;0.6;0.6;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-2315.137,964.1774;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;367;-2057.085,1197.143;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;30;-1828.741,1105.307;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-1382.988,1089.298;Inherit;False;WorldUV;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;129;-104.1166,147.1352;Inherit;False;1861.609;776.1179;Wind-Map;14;69;70;249;169;177;161;159;156;160;71;58;278;61;277;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;356;-3101.106,1521.402;Inherit;False;Property;_WindNoiseSpeed;Wind-Noise-Speed;15;0;Create;True;0;0;False;0;False;-0.3;0.309;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-44.72989,452.2707;Inherit;False;60;WorldUV;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;277;-68.63481,208.8675;Inherit;False;Property;_WindMapTiling;Wind-Map-Tiling;8;0;Create;True;0;0;False;0;False;1;0.182;0.1;0.7;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;278;239.6244,287.1504;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;357;-2548.106,1524.402;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;58;450.1681,252.1364;Inherit;True;Property;_WindMap;Wind-Map;7;0;Create;True;0;0;False;0;False;-1;None;d876b964d7a76c64cbc262146888afee;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;368;-2052.219,1406.813;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;13;-4261.534,-222.2844;Inherit;False;4091.445;1050.336;Wind-Noise-VertexOffset;36;127;54;274;261;293;348;269;292;294;344;346;279;267;283;345;266;282;280;349;339;43;268;338;40;284;275;37;276;336;72;285;337;45;55;358;359;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;71;862.7401,244.1438;Inherit;False;WindTextureFinal;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;354;-1815.306,1364.407;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;336;-2868.026,-162.1243;Inherit;False;334;DirX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-3033.125,436.1547;Inherit;False;71;WindTextureFinal;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;355;-1369.508,1348.154;Inherit;False;WorldNoiseUV;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;337;-2868.026,-62.12429;Inherit;False;335;DirZ;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-4112.37,384.9588;Inherit;False;Property;_WindNoiseScale;Wind-Noise-Scale;13;0;Create;True;0;0;False;0;False;0.1;0.759;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-4059.012,252.5055;Inherit;False;Property;_WindNoiseTiling;Wind-Noise-Tiling;14;0;Create;True;0;0;False;0;False;1;0.34;0.1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;338;-2662.026,-137.1243;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;72;-2741.202,439.169;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.53;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;276;-4054.61,153.0843;Inherit;False;355;WorldNoiseUV;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;285;-4047.153,461.4627;Inherit;False;281;WindSpeed2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;268;-2542.564,35.55102;Inherit;False;Property;_GrassOffsetLerp;Grass-Offset-Lerp;19;0;Create;True;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;339;-2502.128,-139.7218;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;359;-2496.134,-57.66556;Inherit;False;Constant;_Float4;Float 4;39;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;284;-3731.302,429.2903;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-3690.366,152.4982;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;275;-2432.068,438.2753;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;282;-2475.863,113.4229;Inherit;False;281;WindSpeed2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;358;-2332.134,-113.6656;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;43;-3458.766,252.2819;Inherit;True;Property;_WindNoiseMap;WindNoiseMap;12;4;[HideInInspector];[PerRendererData];[NoScaleOffset];[Normal];Create;True;0;0;False;0;False;-1;6a8bc4649f6847449ac1669de3ed7ea1;6a8bc4649f6847449ac1669de3ed7ea1;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;349;-2213.107,39.11611;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;266;-2194.723,-203.8886;Inherit;False;Constant;_Vector0;Vector 0;33;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;280;-2220.318,160.6936;Inherit;False;Constant;_Float1;Float 1;36;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;345;-2962.458,253.2153;Inherit;False;FLOAT3;0;2;1;3;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;267;-1944.998,-111.1368;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;283;-1999.959,109.8086;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;158.7005,753.8749;Inherit;False;Constant;_Float6;Float 6;28;0;Create;True;0;0;False;0;False;-0.04;-0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;156;146.7456,583.8864;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;159;376.9858,684.8846;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;346;-2730.25,255.5314;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;279;-1779.478,43.9666;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;344;-1605.995,210.9176;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;161;614.3928,685.8749;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;294;-1448.907,280.5877;Inherit;False;Property;_GrassOffsetIntensity;Grass-Offset-Intensity;18;0;Create;True;0;0;False;0;False;0;0.94;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;177;882.5106,680.1879;Inherit;False;VCRemap;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;274;-1389.613,209.0006;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;292;-1373.506,105.9018;Inherit;False;Constant;_Float9;Float 9;35;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;269;-1288.03,545.0181;Inherit;False;177;VCRemap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;348;-1269.691,365.1165;Inherit;False;Constant;_Vector2;Vector 2;38;0;Create;True;0;0;False;0;False;1,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;293;-1122.615,180.2142;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;261;-949.125,338.1136;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldToObjectTransfNode;54;-755.3016,341.4511;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;124;256.3832,-793.2098;Inherit;False;2091.864;915.9625;Maintex-Color;15;155;0;184;151;7;179;312;185;180;152;186;181;8;130;5;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;5;292.0409,-670.6829;Inherit;True;Property;_BaseMap;BaseMap;0;0;Create;True;0;0;False;0;False;-1;None;7e5d0dcfdefed294cbadbdd27a3fd31b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;127;-486.8773,333.493;Inherit;False;GrassOffset;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;130;742.6544,-579.4783;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;75;-3308.979,1611.238;Inherit;False;3916.518;713.0247;Fog-System;17;101;78;88;95;91;98;83;104;79;92;82;89;106;76;77;85;94;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;125;2435.305,-217.672;Inherit;False;683.0621;369.4681;FogLerp;4;350;108;110;109;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;132;-2747.271,3045.422;Inherit;False;3216.872;947.6923;World-Size-Offset-Project;25;135;170;145;165;192;143;136;142;167;133;139;183;147;137;182;162;146;144;164;141;148;134;138;140;166;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;311;-1291.956,-2213.255;Inherit;False;2778.891;1346.828;Height;23;308;302;326;298;297;299;301;323;320;321;322;310;317;329;324;319;314;304;325;307;328;306;305;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;74;-3297.937,2391.861;Inherit;False;3902.398;507.8676;Fog-Alpha-Lerp;15;86;81;105;102;80;93;107;87;103;96;84;90;100;97;99;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;123;-2243.598,-787.6351;Inherit;False;2366.147;511.9055;Color-A-B-Noise;10;10;114;120;113;116;118;117;115;119;112;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;2751.136,392.5605;Inherit;False;127;GrassOffset;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;104;-1266.166,1917.392;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;312;1653.826,-124.5364;Inherit;False;310;HighLight;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;107;-99.2995,2580.287;Inherit;False;FogLerp;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;76;-436.8185,1757.476;Inherit;True;Property;_FogRampmap;Fog-Rampmap;24;1;[HideInInspector];Create;True;0;0;False;0;False;-1;409aebad96157034b8cee22c9bb9b3c0;409aebad96157034b8cee22c9bb9b3c0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;87;-1344.803,2463.455;Inherit;False;Property;_FogDistanceAlphaOffset;Fog-Distance-AlphaOffset;32;1;[HideInInspector];Create;True;0;0;False;0;False;-0.03;-0.03;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;302;-481.363,-1730.037;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;144;-1795.125,3370.734;Inherit;False;Constant;_Float3;Float 3;4;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-1880.319,-557.608;Inherit;False;Property;_ColorNoiseSize;ColorNoiseSize;6;0;Create;True;0;0;False;0;False;0.6;0.223;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;138;-2032.133,3269.359;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;323;-150.8573,-1387.279;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;1971.287,-154.0828;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-1456.776,-691.1873;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;108;2728.461,-151.72;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;99;-1801.452,2584.431;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;304;-775.5342,-2162.988;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;142;-2255.345,3474.44;Inherit;False;Constant;_ProSize1;Pro-Size1;1;0;Create;True;0;0;False;0;False;1;1;1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-1354.664,2605.687;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;329;359.2751,-1051.254;Inherit;False;183;UVProjectShadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;110;2460.571,3.748118;Inherit;False;107;FogLerp;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;170;-270.0922,3352.689;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;92;-628.8983,1785.299;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;105;-631.7758,2588.881;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;70;587.2318,441.0107;Inherit;False;Property;_WindColor;WindColor;10;0;Create;True;0;0;False;0;False;0.5238074,0.745283,0.6270263,0;0.2538843,0.3018866,0.1666072,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;102;-2178.732,2524.702;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;69;1282.653,317.9124;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;181;1502.916,-454.2844;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;137;-2452.872,3131.822;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector3Node;314;-749.8078,-2018.548;Inherit;False;Constant;_Vector1;Vector 1;35;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;-15.75106,3351.71;Inherit;True;WindProjectDark;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;225.3073,1852.968;Inherit;False;FogColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;320;-618.5659,-1459.268;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;135;-2697.271,3095.422;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;80;-1962.558,2584.391;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;84;-2436.282,2441.861;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;306;-173.1248,-1915.881;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;319;90.04284,-1255.711;Inherit;False;Property;_HeightLightColor;HeightLight-Color;35;0;Create;True;0;0;False;0;False;0.5829477,0.9433962,0.6076172,0;0.7557765,0.9528301,0.4089971,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-854.9344,-615.6332;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;139;-2265.69,3340.388;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;119;-190.0269,-603.5678;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldPosInputsNode;79;-2799.749,2128.982;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;324;32.24593,-1063.177;Inherit;False;Property;_HeightLightIntensity;HeightLight-Intensity;36;0;Create;True;0;0;False;0;False;2;8;1;45;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;141;-2016.591,3504.302;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;169;859.15,532.8386;Inherit;False;167;WindProjectDark;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;-1624.673,1888.626;Inherit;False;Property;_FogDistanceFogRampOffset;Fog-DistanceFog-RampOffset;28;1;[HideInInspector];Create;True;0;0;False;0;False;-0.46;-0.46;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;325;-483.6703,-2052.769;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;146;-1644.153,3265.206;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;140;-2651.577,3284.594;Inherit;False;Property;_ProjectMapCreatX;ProjectMap-Creat-X;22;0;Create;True;0;0;False;0;False;0;-2.78;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;96;-459.492,2585.979;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;307;49.12243,-1642.496;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;192;-1524.009,3440.772;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RelayNode;89;-1689.173,2047.047;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-947.5717,3179.433;Inherit;False;UVProject;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-87.11963,1857.351;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;118;-504.3954,-483.4636;Inherit;False;Property;_ColorB;ColorB;3;0;Create;True;0;0;False;0;False;0.4103774,1,0.4275469,0;0.3066036,0.874788,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-1628.746,2585.41;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-508.1654,-682.5723;Inherit;False;Property;_ColorA;ColorA;2;0;Create;True;0;0;False;0;False;0.4103774,1,0.4275469,0;0.7829549,0.8490566,0.748932,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexToFragmentNode;352;2967.29,398.3978;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;301;-686.9689,-1727.444;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;112;-1193.331,-674.506;Inherit;True;Property;_WolrdNoiseColorMap;WolrdNoiseColorMap;12;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;43;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;180;1704.573,-475.8116;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;322;-384.3253,-1385.27;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;2.6;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;151;991.4188,-586.9379;Inherit;False;148;UVProject;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;86;-2342.715,2667.445;Inherit;False;Property;_FogHeightOffset;Fog-HeightOffset;30;1;[HideInInspector];Create;True;0;0;False;0;False;0.56;0.56;-1.5;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;165;-943.4131,3577.071;Inherit;False;Property;_WindDark;WindDark;11;0;Create;True;0;0;False;0;False;0.03529409;-0.3;-3;0.45;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;85;-1106.615,1914.563;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;120;-623.5524,-548.4583;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;97;-2641.466,2611.1;Inherit;False;Property;_FogHeightHard;Fog-HeightHard;31;1;[HideInInspector];Create;True;0;0;False;0;False;0.015;0.015;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;100;-769.3847,2437.949;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;182;-1307.526,3587.983;Inherit;True;Property;_ProjectShadowMap;ProjectShadowMap;33;0;Create;True;0;0;False;0;False;-1;None;3eac9f7276573074f86b2ccab5e831e7;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;185;1250.33,-608.4889;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;299;-930.0806,-1557.133;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;152;778.9487,-296.1027;Inherit;False;Property;_RootLightIntensity;Root-Light-Intensity;5;0;Create;True;0;0;False;0;False;1;1.326;0.9;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;7;764.0824,-427.7303;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexToFragmentNode;350;2906.487,-149.6506;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;305;-300.4086,-1916.114;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;114;-1815.259,-689.5641;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;183;-938.4885,3264.233;Inherit;False;UVProjectShadow;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;864.7747,317.9855;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;109;2461.64,-73.12617;Inherit;False;106;FogColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;-965.6025,1794.4;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;184;941.0619,-665.1105;Inherit;False;183;UVProjectShadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;297;-1213.914,-1817.464;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;133;-2450.638,3411.657;Inherit;False;Constant;_Float2;Float 2;4;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;317;719.6762,-1510.565;Inherit;False;5;5;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;162;-891.7928,3352.686;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;90;-971.6882,2436.631;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;145;-1284.302,3177.66;Inherit;True;Property;_ProjectMap;ProjectMap;20;0;Create;True;0;0;False;0;False;-1;None;1fa5866ab84d02e4097407a532b4fd2f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;310;991.8392,-1513.453;Inherit;False;HighLight;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;91;-2285.23,2120.702;Inherit;False;Property;_FogDistance;Fog-Distance;26;1;[HideInInspector];Create;True;0;0;False;0;False;0.023;0.023;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;328;367.7934,-1636.12;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-2255.728,3572.472;Inherit;False;Property;_ProjectMapSize;ProjectMap-Size;21;0;Create;True;0;0;False;0;False;40;40;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;98;-2828.285,1863.945;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;136;-2651.577,3368.814;Inherit;False;Property;_ProjectMapCreatZ;ProjectMap-Creat-Z;23;0;Create;True;0;0;False;0;False;0;-1.87;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;186;772.5773,-212.4141;Inherit;False;Property;_TopLightIntensity;Top-Light-Intensity;4;0;Create;True;0;0;False;0;False;1;1.42;0.5;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;2971.562,227.9487;Inherit;False;130;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;308;-335.8215,-1616.41;Inherit;False;Property;_HeightLightPower;HeightLight-Power;34;0;Create;True;0;0;False;0;False;1;75;45;75;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;2990.79,297.1987;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;323.1846,-372.5654;Inherit;False;Property;_BassTextureLerp;BassTextureLerp;1;0;Create;True;0;0;False;0;False;1;0.418;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;77;-1853.143,2047.866;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;113;-2193.598,-737.6351;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;82;-798.2476,1795.468;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;321;-618.6108,-1288.279;Inherit;False;Constant;_HeightLightColor2;HeightLightColor2;29;0;Create;True;0;0;False;0;False;-1.6;-1.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;164;-576.4743,3354.038;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.5;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-2948.738,2464.296;Inherit;False;Property;_FogHorizontalLine;Fog-HorizontalLine;29;1;[HideInInspector];Create;True;0;0;False;0;False;-17;-17;-22;22;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceViewDirHlpNode;298;-1188.079,-1557.133;Inherit;False;1;0;FLOAT4;0,0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;326;-858.0013,-1865.57;Inherit;False;Constant;_WN;WN;39;0;Create;True;0;0;False;0;False;0.965;0.965;0.02;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;179;1446.042,-256.1706;Inherit;False;177;VCRemap;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;95;-1354.603,1796.4;Inherit;False;Property;_FogDistanceFogInstensity;Fog-DistanceFog-Instensity;27;1;[HideInInspector];Create;True;0;0;False;0;False;2.74;2.74;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-949.8203,3659.417;Inherit;False;Constant;_Float7;Float 7;28;0;Create;True;0;0;False;0;False;0.45;0;0.08235291;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-1835.04,3268.882;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;94;-2224.583,1972.487;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;147;-2438.009,3312.75;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;83;-385.2837,1989.88;Inherit;False;Property;_FogRampColor;Fog-RampColor;25;2;[HideInInspector];[HDR];Create;True;0;0;False;0;False;0.6036298,0.7027331,0.9189587,0;0.6036298,0.7027331,0.9189587,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;3381.6,208.7616;Float;False;True;-1;2;ASEMaterialInspector;0;3;Good/Grass/Wind-Grass;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;True;0;False;-1;True;2;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;False;1;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;0;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;True;False;False;;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;796.7333,-10.60683;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
WireConnection;334;0;257;0
WireConnection;335;0;21;0
WireConnection;332;0;334;0
WireConnection;332;1;335;0
WireConnection;281;0;258;0
WireConnection;333;0;332;0
WireConnection;24;0;281;0
WireConnection;259;0;333;0
WireConnection;259;1;341;0
WireConnection;18;0;15;1
WireConnection;18;1;15;3
WireConnection;26;0;18;0
WireConnection;26;1;22;0
WireConnection;367;0;259;0
WireConnection;367;1;24;0
WireConnection;30;0;26;0
WireConnection;30;1;367;0
WireConnection;60;0;30;0
WireConnection;278;0;277;0
WireConnection;278;1;61;0
WireConnection;357;0;356;0
WireConnection;58;1;278;0
WireConnection;368;0;259;0
WireConnection;368;1;357;0
WireConnection;71;0;58;1
WireConnection;354;0;26;0
WireConnection;354;1;368;0
WireConnection;355;0;354;0
WireConnection;338;0;336;0
WireConnection;338;2;337;0
WireConnection;72;0;55;0
WireConnection;339;0;338;0
WireConnection;284;0;45;0
WireConnection;284;1;285;0
WireConnection;40;0;276;0
WireConnection;40;1;37;0
WireConnection;40;2;285;0
WireConnection;275;0;72;0
WireConnection;358;0;339;0
WireConnection;358;1;359;0
WireConnection;43;1;40;0
WireConnection;43;5;284;0
WireConnection;349;0;268;0
WireConnection;349;1;275;0
WireConnection;345;0;43;0
WireConnection;267;0;266;0
WireConnection;267;1;358;0
WireConnection;267;2;349;0
WireConnection;283;0;282;0
WireConnection;283;1;280;0
WireConnection;159;0;156;1
WireConnection;159;3;160;0
WireConnection;346;0;345;0
WireConnection;279;0;267;0
WireConnection;279;1;283;0
WireConnection;344;0;279;0
WireConnection;344;1;346;0
WireConnection;161;0;159;0
WireConnection;177;0;161;0
WireConnection;274;0;344;0
WireConnection;293;0;292;0
WireConnection;293;1;274;0
WireConnection;293;2;294;0
WireConnection;261;0;293;0
WireConnection;261;1;348;0
WireConnection;261;2;269;0
WireConnection;54;0;261;0
WireConnection;127;0;54;0
WireConnection;130;0;5;4
WireConnection;104;0;78;0
WireConnection;104;1;89;0
WireConnection;107;0;96;0
WireConnection;76;1;92;0
WireConnection;302;0;301;0
WireConnection;138;0;137;0
WireConnection;138;1;139;0
WireConnection;323;0;322;0
WireConnection;155;0;180;0
WireConnection;155;1;312;0
WireConnection;155;2;69;0
WireConnection;115;0;114;0
WireConnection;115;1;116;0
WireConnection;108;0;155;0
WireConnection;108;1;109;0
WireConnection;108;2;110;0
WireConnection;99;0;80;0
WireConnection;93;0;89;0
WireConnection;93;1;89;0
WireConnection;170;0;164;0
WireConnection;92;0;82;0
WireConnection;92;1;82;0
WireConnection;105;0;100;0
WireConnection;105;1;81;0
WireConnection;102;0;84;0
WireConnection;102;1;97;0
WireConnection;69;0;249;0
WireConnection;69;1;169;0
WireConnection;69;2;177;0
WireConnection;181;0;185;0
WireConnection;181;1;7;0
WireConnection;181;2;186;0
WireConnection;137;0;135;1
WireConnection;137;1;135;3
WireConnection;167;0;170;0
WireConnection;106;0;88;0
WireConnection;80;0;102;0
WireConnection;80;1;86;0
WireConnection;84;0;79;2
WireConnection;84;1;103;0
WireConnection;306;0;305;0
WireConnection;117;0;112;2
WireConnection;139;0;147;0
WireConnection;139;1;133;0
WireConnection;119;0;10;0
WireConnection;119;1;118;0
WireConnection;119;2;120;0
WireConnection;141;0;142;0
WireConnection;141;1;143;0
WireConnection;325;0;304;0
WireConnection;325;1;314;0
WireConnection;325;2;326;0
WireConnection;146;0;134;0
WireConnection;146;1;144;0
WireConnection;96;0;105;0
WireConnection;307;0;306;0
WireConnection;307;1;308;0
WireConnection;192;0;146;0
WireConnection;89;0;77;0
WireConnection;148;0;145;0
WireConnection;88;0;76;0
WireConnection;88;1;83;0
WireConnection;81;0;99;0
WireConnection;81;1;99;0
WireConnection;81;2;99;0
WireConnection;352;0;128;0
WireConnection;301;0;297;0
WireConnection;301;1;299;0
WireConnection;112;1;115;0
WireConnection;180;0;185;0
WireConnection;180;1;181;0
WireConnection;180;2;179;0
WireConnection;322;0;320;1
WireConnection;322;3;321;0
WireConnection;85;0;104;0
WireConnection;120;0;117;0
WireConnection;100;0;90;0
WireConnection;182;1;192;0
WireConnection;185;0;184;0
WireConnection;185;1;151;0
WireConnection;185;2;152;0
WireConnection;299;0;298;0
WireConnection;7;0;5;0
WireConnection;7;1;119;0
WireConnection;7;2;8;0
WireConnection;350;0;108;0
WireConnection;305;0;325;0
WireConnection;305;1;302;0
WireConnection;114;0;113;1
WireConnection;114;1;113;3
WireConnection;183;0;182;0
WireConnection;249;0;58;1
WireConnection;249;1;70;0
WireConnection;101;0;95;0
WireConnection;101;1;85;0
WireConnection;317;0;328;0
WireConnection;317;1;323;0
WireConnection;317;2;319;0
WireConnection;317;3;324;0
WireConnection;317;4;329;0
WireConnection;162;0;182;1
WireConnection;90;0;93;0
WireConnection;90;1;87;0
WireConnection;145;1;192;0
WireConnection;310;0;317;0
WireConnection;328;0;307;0
WireConnection;77;0;94;0
WireConnection;77;1;91;0
WireConnection;82;0;101;0
WireConnection;164;0;162;0
WireConnection;164;1;165;0
WireConnection;164;2;166;0
WireConnection;134;0;138;0
WireConnection;134;1;141;0
WireConnection;94;0;98;0
WireConnection;94;1;79;0
WireConnection;147;0;140;0
WireConnection;147;1;136;0
WireConnection;1;2;350;0
WireConnection;1;3;131;0
WireConnection;1;4;6;0
WireConnection;1;5;352;0
ASEEND*/
//CHKSM=14E770B39C90BA9088208B768ADD774702153071