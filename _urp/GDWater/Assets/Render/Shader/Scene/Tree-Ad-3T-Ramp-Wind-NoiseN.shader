// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Good/Scene/Tree-Ad-3T-Ramp-Wind-NoiseN"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_MainTex("MainTex", 2D) = "white" {}
		_LightOffset("LightOffset", Range( -2 , 2)) = 0.5
		_LightScale("LightScale", Range( -2 , 2)) = 0.5
		_RampMap("RampMap", 2D) = "white" {}
		[HDR]_MainColor("MainColor", Color) = (1,1,1,0)
		[HideInInspector]_FogRampmap("Fog-Rampmap", 2D) = "white" {}
		[HideInInspector]_FogDistance("Fog-Distance", Range( 0 , 0.1)) = 0.023
		[HideInInspector]_FogDistanceFogRampOffset("Fog-DistanceFog-RampOffset", Range( -2 , 2)) = -0.46
		[HideInInspector]_FogDistanceAlphaOffset("Fog-Distance-AlphaOffset", Range( -2 , 2)) = -0.03
		[HideInInspector][HDR]_FogRampColor("Fog-RampColor", Color) = (0.6036298,0.7027331,0.9189587,0)
		[HideInInspector]_FogDistanceFogInstensity("Fog-DistanceFog-Instensity", Range( 0 , 5)) = 2.74
		[HideInInspector]_FogHorizontalLine("Fog-HorizontalLine", Range( -22 , 22)) = -17
		[HideInInspector]_FogHeightOffset("Fog-HeightOffset", Range( -1.5 , 1)) = 0.56
		[HideInInspector]_FogHeightHard("Fog-HeightHard", Range( 0 , 0.1)) = 0.015
		_NoiseNormal("NoiseNormal", 2D) = "bump" {}
		_NScale("N-Scale", Range( 0 , 2)) = 1
		[HideInInspector][PerRendererData][NoScaleOffset][Normal]_WindNoiseMap("WindNoiseMap", 2D) = "bump" {}
		_WindMultip("Wind-Multip", Range( 0 , 0.5)) = 0.1
		_WindSpeed("WindSpeed", Range( -0.5 , 0.5)) = 0
		[Toggle(_LIGHTSHADOW_ON)] _LightShadow("LightShadow", Float) = 1
		_LightTexture("LightTexture", 2D) = "white" {}
		_Lightintensity("Light-intensity", Range( 0 , 2)) = 0
		_LightDen("Light-Den", Range( 0.2 , 1)) = 0.1668242
		_LightOffsetRing("Light-OffsetRing", Range( 0 , 2)) = 0
		_LightTiling("Light-Tiling", Range( 1 , 50)) = 1
		_StepMin("StepMin", Range( 0 , 1)) = 0.1294118
		_StepMax("StepMax", Range( 0 , 1)) = 0.1294118
		_LightMin("Light-Min", Range( 0 , 0.99)) = 0.1411765
		_LightMax("Light-Max", Range( 0.4 , 1)) = 1
		_LightSpeed("Light-Speed", Range( 0 , 0.5)) = 0.3
		_DarkColor("DarkColor", Color) = (0.3520624,0.3501691,0.5754717,0)
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
			ColorMask RGB
			

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile_instancing
			#define ASE_ABSOLUTE_VERTEX_POS 1
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

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _LIGHTSHADOW_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
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
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			float4 _NoiseNormal_ST;
			float4 _FogRampColor;
			float4 _MainColor;
			float4 _DarkColor;
			float _WindSpeed;
			float _FogHorizontalLine;
			float _FogDistanceAlphaOffset;
			float _FogDistance;
			float _FogDistanceFogRampOffset;
			float _FogDistanceFogInstensity;
			float _LightMax;
			float _LightMin;
			float _Lightintensity;
			float _LightTiling;
			float _LightOffsetRing;
			float _FogHeightHard;
			float _LightDen;
			float _StepMax;
			float _StepMin;
			float _LightOffset;
			float _LightScale;
			float _NScale;
			float _WindMultip;
			float _LightSpeed;
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
			TEXTURE2D(_WindNoiseMap);
			SAMPLER(sampler_WindNoiseMap);
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_RampMap);
			TEXTURE2D(_NoiseNormal);
			SAMPLER(sampler_NoiseNormal);
			SAMPLER(sampler_RampMap);
			TEXTURE2D(_LightTexture);
			SAMPLER(sampler_LightTexture);
			TEXTURE2D(_FogRampmap);
			SAMPLER(sampler_FogRampmap);


						
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float mulTime319 = _TimeParameters.x * _WindSpeed;
				float4 transform299 = mul(GetObjectToWorldMatrix(),float4( v.vertex.xyz , 0.0 ));
				float4 WorldSpeed348 = ( mulTime319 + transform299 );
				float4 break323 = WorldSpeed348;
				float2 appendResult324 = (float2(break323.x , break323.y));
				float3 temp_output_341_0 = (float3( -1,-1,-1 ) + (UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( 0.3 * appendResult324 ), 0.0 ), 1.0f ) - float3( 0,0,0 )) * (float3( 1,1,1 ) - float3( -1,-1,-1 )) / (float3( 1,1,1 ) - float3( 0,0,0 )));
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult359 = (float2(ase_worldPos.x , ( ase_worldPos.x + ( ase_worldPos.y * -1.466196 ) )));
				float mulTime361 = _TimeParameters.x * -0.3;
				float SinWave382 = saturate( (0.2 + (sin( ( ( ( appendResult359 * 0.6 ) + mulTime361 ) * TWO_PI * 1.5 ).y ) - 0.0) * (0.8 - 0.2) / (1.0 - 0.0)) );
				float3 break331 = ( temp_output_341_0 * _WindMultip * SinWave382 );
				float3 appendResult335 = (float3(( break331.x + transform299.x ) , ( break331.y + transform299.y ) , ( break331.z + transform299.z )));
				float4 transform313 = mul(GetWorldToObjectMatrix(),float4( appendResult335 , 0.0 ));
				
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = transform313.xyz;
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
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

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
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
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
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode84 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float2 uv_NoiseNormal = IN.ase_texcoord3.xy * _NoiseNormal_ST.xy + _NoiseNormal_ST.zw;
				float3 unpack189 = UnpackNormalScale( SAMPLE_TEXTURE2D( _NoiseNormal, sampler_NoiseNormal, uv_NoiseNormal ), _NScale );
				unpack189.z = lerp( 1, unpack189.z, saturate(_NScale) );
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal96 = unpack189;
				float3 worldNormal96 = float3(dot(tanToWorld0,tanNormal96), dot(tanToWorld1,tanNormal96), dot(tanToWorld2,tanNormal96));
				float3 NormalsMap244 = worldNormal96;
				float dotResult97 = dot( _MainLightPosition.xyz , NormalsMap244 );
				float2 temp_cast_0 = (( 1.0 - saturate( (dotResult97*_LightScale + _LightOffset) ) )).xx;
				float4 temp_cast_1 = (_StepMin).xxxx;
				float4 temp_cast_2 = (_StepMax).xxxx;
				float2 appendResult415 = (float2(WorldPosition.x , ( WorldPosition.y + ( WorldPosition.z * 1.0 ) )));
				float4 temp_cast_3 = (_LightMin).xxxx;
				float4 temp_cast_4 = (_LightMax).xxxx;
				float4 temp_cast_5 = (1.0).xxxx;
				float4 smoothstepResult410 = smoothstep( temp_cast_1 , temp_cast_2 , ( float4( 0,0,0,0 ) + saturate( (float4( 0,0,0,0 ) + (saturate( ( SAMPLE_TEXTURE2D( _LightTexture, sampler_LightTexture, ( _LightDen * ( ( appendResult415 * 0.005 * _LightTiling ) + ( _LightOffsetRing * sin( ( _LightSpeed * _TimeParameters.x ) ) ) ) ) ) * _Lightintensity ) ) - temp_cast_3) * (temp_cast_5 - float4( 0,0,0,0 )) / (temp_cast_4 - temp_cast_3)) ) ));
				float temp_output_435_0 = ( 3.0 * ase_worldNormal.y );
				float4 temp_cast_6 = (1.0).xxxx;
				float4 clampResult438 = clamp( ( _DarkColor + ( smoothstepResult410 * saturate( temp_output_435_0 ) ) ) , float4( 0,0,0,0 ) , temp_cast_6 );
				float2 temp_cast_7 = (( 1.0 - saturate( (dotResult97*_LightScale + _LightOffset) ) )).xx;
				#ifdef _LIGHTSHADOW_ON
				float4 staticSwitch442 = saturate( ( clampResult438 * ( ( tex2DNode84 * SAMPLE_TEXTURE2D( _RampMap, sampler_RampMap, temp_cast_0 ) * _MainColor ) * float4( 1,1,1,0 ) ) ) );
				#else
				float4 staticSwitch442 = ( ( tex2DNode84 * SAMPLE_TEXTURE2D( _RampMap, sampler_RampMap, temp_cast_0 ) * _MainColor ) * float4( 1,1,1,0 ) );
				#endif
				float temp_output_493_0 = saturate( ( _FogDistanceFogInstensity * saturate( ( _FogDistanceFogRampOffset + ( distance( _WorldSpaceCameraPos , WorldPosition ) * _FogDistance ) ) ) ) );
				float2 appendResult490 = (float2(temp_output_493_0 , temp_output_493_0));
				float4 FogColor495 = ( SAMPLE_TEXTURE2D( _FogRampmap, sampler_FogRampmap, appendResult490 ) * _FogRampColor );
				float temp_output_480_0 = saturate( ( ( ( WorldPosition.y + _FogHorizontalLine ) * _FogHeightHard ) + _FogHeightOffset ) );
				float FogLerp496 = saturate( ( saturate( ( ( ( distance( _WorldSpaceCameraPos , WorldPosition ) * _FogDistance ) * ( distance( _WorldSpaceCameraPos , WorldPosition ) * _FogDistance ) ) + _FogDistanceAlphaOffset ) ) - ( temp_output_480_0 * temp_output_480_0 * temp_output_480_0 ) ) );
				float4 lerpResult497 = lerp( staticSwitch442 , FogColor495 , FogLerp496);
				
				float Alpha193 = tex2DNode84.a;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = lerpResult497.rgb;
				float Alpha = Alpha193;
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
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile_instancing
			#define ASE_ABSOLUTE_VERTEX_POS 1
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

			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
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
			float4 _MainTex_ST;
			float4 _NoiseNormal_ST;
			float4 _FogRampColor;
			float4 _MainColor;
			float4 _DarkColor;
			float _WindSpeed;
			float _FogHorizontalLine;
			float _FogDistanceAlphaOffset;
			float _FogDistance;
			float _FogDistanceFogRampOffset;
			float _FogDistanceFogInstensity;
			float _LightMax;
			float _LightMin;
			float _Lightintensity;
			float _LightTiling;
			float _LightOffsetRing;
			float _FogHeightHard;
			float _LightDen;
			float _StepMax;
			float _StepMin;
			float _LightOffset;
			float _LightScale;
			float _NScale;
			float _WindMultip;
			float _LightSpeed;
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
			TEXTURE2D(_WindNoiseMap);
			SAMPLER(sampler_WindNoiseMap);
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);


			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float mulTime319 = _TimeParameters.x * _WindSpeed;
				float4 transform299 = mul(GetObjectToWorldMatrix(),float4( v.vertex.xyz , 0.0 ));
				float4 WorldSpeed348 = ( mulTime319 + transform299 );
				float4 break323 = WorldSpeed348;
				float2 appendResult324 = (float2(break323.x , break323.y));
				float3 temp_output_341_0 = (float3( -1,-1,-1 ) + (UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( 0.3 * appendResult324 ), 0.0 ), 1.0f ) - float3( 0,0,0 )) * (float3( 1,1,1 ) - float3( -1,-1,-1 )) / (float3( 1,1,1 ) - float3( 0,0,0 )));
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult359 = (float2(ase_worldPos.x , ( ase_worldPos.x + ( ase_worldPos.y * -1.466196 ) )));
				float mulTime361 = _TimeParameters.x * -0.3;
				float SinWave382 = saturate( (0.2 + (sin( ( ( ( appendResult359 * 0.6 ) + mulTime361 ) * TWO_PI * 1.5 ).y ) - 0.0) * (0.8 - 0.2) / (1.0 - 0.0)) );
				float3 break331 = ( temp_output_341_0 * _WindMultip * SinWave382 );
				float3 appendResult335 = (float3(( break331.x + transform299.x ) , ( break331.y + transform299.y ) , ( break331.z + transform299.z )));
				float4 transform313 = mul(GetWorldToObjectMatrix(),float4( appendResult335 , 0.0 ));
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = transform313.xyz;
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

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
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

				float2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode84 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float Alpha193 = tex2DNode84.a;
				
				float Alpha = Alpha193;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
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
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile_instancing
			#define ASE_ABSOLUTE_VERTEX_POS 1
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

			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
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
			float4 _MainTex_ST;
			float4 _NoiseNormal_ST;
			float4 _FogRampColor;
			float4 _MainColor;
			float4 _DarkColor;
			float _WindSpeed;
			float _FogHorizontalLine;
			float _FogDistanceAlphaOffset;
			float _FogDistance;
			float _FogDistanceFogRampOffset;
			float _FogDistanceFogInstensity;
			float _LightMax;
			float _LightMin;
			float _Lightintensity;
			float _LightTiling;
			float _LightOffsetRing;
			float _FogHeightHard;
			float _LightDen;
			float _StepMax;
			float _StepMin;
			float _LightOffset;
			float _LightScale;
			float _NScale;
			float _WindMultip;
			float _LightSpeed;
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
			TEXTURE2D(_WindNoiseMap);
			SAMPLER(sampler_WindNoiseMap);
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float mulTime319 = _TimeParameters.x * _WindSpeed;
				float4 transform299 = mul(GetObjectToWorldMatrix(),float4( v.vertex.xyz , 0.0 ));
				float4 WorldSpeed348 = ( mulTime319 + transform299 );
				float4 break323 = WorldSpeed348;
				float2 appendResult324 = (float2(break323.x , break323.y));
				float3 temp_output_341_0 = (float3( -1,-1,-1 ) + (UnpackNormalScale( SAMPLE_TEXTURE2D_LOD( _WindNoiseMap, sampler_WindNoiseMap, ( 0.3 * appendResult324 ), 0.0 ), 1.0f ) - float3( 0,0,0 )) * (float3( 1,1,1 ) - float3( -1,-1,-1 )) / (float3( 1,1,1 ) - float3( 0,0,0 )));
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult359 = (float2(ase_worldPos.x , ( ase_worldPos.x + ( ase_worldPos.y * -1.466196 ) )));
				float mulTime361 = _TimeParameters.x * -0.3;
				float SinWave382 = saturate( (0.2 + (sin( ( ( ( appendResult359 * 0.6 ) + mulTime361 ) * TWO_PI * 1.5 ).y ) - 0.0) * (0.8 - 0.2) / (1.0 - 0.0)) );
				float3 break331 = ( temp_output_341_0 * _WindMultip * SinWave382 );
				float3 appendResult335 = (float3(( break331.x + transform299.x ) , ( break331.y + transform299.y ) , ( break331.z + transform299.z )));
				float4 transform313 = mul(GetWorldToObjectMatrix(),float4( appendResult335 , 0.0 ));
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = transform313.xyz;
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

				float2 uv_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode84 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
				float Alpha193 = tex2DNode84.a;
				
				float Alpha = Alpha193;
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
209;469;1577;480;18584.4;725.1809;22.38451;True;False
Node;AmplifyShaderEditor.CommentaryNode;381;-2183.99,3170.018;Inherit;False;3088.961;647.7974;Comment;18;382;376;380;367;373;356;366;365;354;355;363;361;364;359;362;372;357;358;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;358;-2133.99,3442.889;Inherit;False;Constant;_WaveDirect;WaveDirect;16;0;Create;True;0;0;False;0;False;-1.466196;0.9;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;356;-2045.028,3220.018;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;357;-1835.99,3409.889;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;372;-1672.308,3369.895;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;350;-2161.517,2043.176;Inherit;False;3013.536;1023.848;Wind;24;313;335;336;334;333;351;331;337;341;284;266;339;324;340;323;349;348;276;299;319;338;306;383;395;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;362;-1400.184,3507.158;Inherit;False;Constant;_WaveSpeed;WaveSpeed;15;0;Create;True;0;0;False;0;False;-0.3;-0.19;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;364;-1467.749,3396.845;Inherit;False;Constant;_WaveSize;WaveSize;16;0;Create;True;0;0;False;0;False;0.6;0.0876;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;338;-1819.479,2641.766;Inherit;False;Property;_WindSpeed;WindSpeed;18;0;Create;True;0;0;False;0;False;0;0.5;-0.5;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;306;-1716.842,2811.377;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;359;-1501.689,3266.889;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;299;-1487.609,2812.692;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;361;-1039.184,3505.158;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;319;-1469.483,2645.828;Inherit;False;1;0;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;363;-1142.831,3279.143;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;365;-814.884,3380.458;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;354;-1042.922,3692.514;Inherit;False;Constant;_WaveTime;WaveTime;15;0;Create;True;0;0;False;0;False;1.5;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;276;-1178.082,2646.821;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TauNode;355;-753.022,3589.912;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;366;-475.1846,3473.458;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;348;-849.1772,2645.313;Inherit;False;WorldSpeed;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;349;-2085.583,2280.328;Inherit;False;348;WorldSpeed;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;373;-340.3448,3469.308;Inherit;True;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SinOpNode;367;-78.36734,3460.487;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;323;-1833.782,2285.338;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TFHCRemapNode;380;145.8325,3459.445;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.2;False;4;FLOAT;0.8;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;340;-1769.593,2193.666;Inherit;False;Constant;_WindTiling;Wind-Tiling;15;0;Create;True;0;0;False;0;False;0.3;0.4;0.1;0.4;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;324;-1597.077,2285.291;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;339;-1444.47,2215.377;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;376;377.5398,3461.078;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;382;524.8387,3453.48;Inherit;False;SinWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;266;-1280.573,2185.794;Inherit;True;Property;_WindNoiseMap;WindNoiseMap;16;4;[HideInInspector];[PerRendererData];[NoScaleOffset];[Normal];Create;True;0;0;False;0;False;-1;6a8bc4649f6847449ac1669de3ed7ea1;6a8bc4649f6847449ac1669de3ed7ea1;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;284;-1058.289,2403.885;Inherit;False;Property;_WindMultip;Wind-Multip;17;0;Create;True;0;0;False;0;False;0.1;0.12;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;341;-925.954,2189.601;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;-1,-1,-1;False;4;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;383;-819.6615,2485.156;Inherit;False;382;SinWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;337;-538.5778,2367.124;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;331;-345.1949,2370.465;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CommentaryNode;205;-1036.911,1036.792;Inherit;False;1125.393;765.7958;Comment;6;188;184;187;84;193;208;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;333;12.37618,2763.396;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;334;16.02804,2670.225;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;84;-993.074,1159.244;Inherit;True;Property;_MainTex;MainTex;0;0;Create;True;0;0;False;0;False;-1;None;a15f0393488a298439fbbfb50003ee4f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;441;-5720.702,-239.4231;Inherit;False;5977.805;1079.08;Comment;42;396;397;398;399;400;401;402;403;404;405;406;407;408;409;410;411;413;414;419;420;421;422;423;424;425;426;427;428;429;431;432;433;434;435;436;437;438;439;200;199;196;198;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;336;16.89608,2850.427;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;396;-5642.706,105.9409;Inherit;False;762;365.0007;WP;5;430;418;417;416;415;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;464;-5858.976,2667.074;Inherit;False;3006.774;485.8276;Height;14;485;483;482;481;480;479;478;477;476;474;473;472;471;468;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;335;227.0174,2738.145;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;203;-3534.293,932.5648;Inherit;False;1416.227;401.7233;Comment;6;244;189;192;97;101;96;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;463;-5841.761,1870.666;Inherit;False;3383.862;702.7815;Fog;16;494;493;492;491;490;489;488;487;486;484;475;470;469;467;466;465;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;204;-2414.723,1362.311;Inherit;False;1126.533;386.2728;Comment;5;186;183;182;131;132;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;393;-763.9826,3935.435;Inherit;False;1627.778;422.8433;Distance;10;392;389;388;386;384;391;385;390;387;394;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;193;-210.5806,1248.665;Inherit;False;Alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;399;-2506.33,104.9027;Inherit;True;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;3;COLOR;0,0,0,0;False;4;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;470;-4385.924,2307.293;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;476;-4523.597,2859.604;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;482;-4189.785,2880.36;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;477;-3905.842,2738.668;Inherit;False;Property;_FogDistanceAlphaOffset;Fog-Distance-AlphaOffset;8;1;[HideInInspector];Create;True;0;0;False;0;False;-0.03;0.21;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;465;-5332.531,2388.41;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;423;-2992.875,485.1257;Inherit;False;Property;_LightMax;Light-Max;28;0;Create;True;0;0;False;0;False;1;0.807;0.4;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;492;-3798.947,2176.82;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;401;-4404.77,227.0077;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;469;-4829.013,2397.13;Inherit;False;Property;_FogDistance;Fog-Distance;6;1;[HideInInspector];Create;True;0;0;False;0;False;0.023;0.018;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;432;-1896.019,183.5243;Inherit;False;Property;_StepMin;StepMin;25;0;Create;True;0;0;False;0;False;0.1294118;0.131;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;427;-4796.348,606.9957;Inherit;False;Property;_LightSpeed;Light-Speed;29;0;Create;True;0;0;False;0;False;0.3;0.07;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;439;-257.3616,-139.2122;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;431;-739.7089,184.9304;Inherit;False;Constant;_Float10;Float 10;16;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;415;-5041.706,168.9413;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;397;-4703.822,728.6569;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;474;-4903.754,2942.658;Inherit;False;Property;_FogHeightOffset;Fog-HeightOffset;12;1;[HideInInspector];Create;True;0;0;False;0;False;0.56;0.6;-1.5;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;473;-4739.771,2799.915;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;489;-2904.065,2260.308;Inherit;False;Property;_FogRampColor;Fog-RampColor;9;2;[HideInInspector];[HDR];Create;True;0;0;False;0;False;0.6036298,0.7027331,0.9189587,0;1.07451,1.419608,1.498039,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;491;-2619.901,2116.779;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RelayNode;475;-4221.954,2306.475;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;433;-919.1949,285.2625;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;429;-4712.683,266.3231;Inherit;False;Constant;_Float9;Float 9;6;0;Create;True;0;0;False;0;False;0.005;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;435;-1172.617,347.1229;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;478;-3915.703,2880.9;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;444;854.7834,1137.327;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;430;-5201.364,231.9423;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;208;-316.2481,1554.449;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;425;-3796.636,131.7538;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;411;-3958.526,221.8427;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;467;-4757.366,2231.915;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;500;1639.854,2062.501;Inherit;False;495;FogColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;472;-4997.321,2717.074;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;419;-3094.522,224.5731;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RelayNode;298;2440.433,2076.68;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;497;1950.716,2006.985;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;420;-2861.722,112.9174;Inherit;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;471;-5202.505,2886.313;Inherit;False;Property;_FogHeightHard;Fog-HeightHard;13;1;[HideInInspector];Create;True;0;0;False;0;False;0.015;0.0107;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;493;-3331.029,2054.896;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;488;-3639.396,2173.991;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;402;-4797.681,341.1063;Inherit;False;Property;_LightTiling;Light-Tiling;24;0;Create;True;0;0;False;0;False;1;34.2;1;50;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;479;-3532.727,2711.844;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;403;-2119.524,92.0376;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldToObjectTransfNode;313;528.1837,2737.513;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;404;-3618.416,318.1112;Inherit;False;Property;_Lightintensity;Light-intensity;21;0;Create;True;0;0;False;0;False;0;1.99;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;389;-415.1449,4170.854;Inherit;False;Constant;_Float5;Float 5;27;0;Create;True;0;0;False;0;False;0.045;0.045;0;0.06;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;445;1250.413,1138.051;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldPosInputsNode;416;-5592.706,155.9413;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceCameraPos;466;-5361.067,2123.373;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;480;-4362.491,2859.644;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;481;-3330.424,2713.162;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;486;-3498.384,2053.828;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;502;501.9614,1559.164;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;484;-4157.454,2148.054;Inherit;False;Property;_FogDistanceFogRampOffset;Fog-DistanceFog-RampOffset;7;1;[HideInInspector];Create;True;0;0;False;0;False;-0.46;-0.48;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;406;-1377.941,321.9461;Inherit;False;Constant;_Float6;Float 6;16;0;Create;True;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;434;-1426.108,427.8875;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceCameraPos;385;-713.9826,4152.957;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TFHCRemapNode;391;257.9253,4089.683;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;495;-2362.474,2104.396;Inherit;False;FogColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;485;-3020.531,2861.192;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;101;-2584.721,990.6919;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.AbsOpNode;387;-253.9827,4062.957;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;202;2265.873,2702.601;Inherit;False;Constant;_Float0;Float 0;13;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;438;72.27346,-147.6552;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;418;-5580.364,354.9423;Inherit;False;Constant;_Float7;Float 7;17;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;483;-3192.815,2864.094;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;428;-4321.347,591.5953;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;384;-651.1716,3985.435;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;192;-3481.185,1184.449;Float;False;Property;_NScale;N-Scale;15;0;Create;True;0;0;False;0;False;1;0.12;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;392;493.4437,4087.417;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;405;-1816.859,-80.04114;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;131;-2363.529,1511.927;Float;False;Property;_LightScale;LightScale;2;0;Create;True;0;0;False;0;False;0.5;0.43;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;398;-4936.399,727.0681;Inherit;False;Constant;_Speed;Speed;8;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;184;-986.9114,1390.487;Inherit;True;Property;_RampMap;RampMap;3;0;Create;True;0;0;False;0;False;-1;9396ba34740c46a4aa6e6eb1a7714315;4d6627ffa32c9da4f84100181dd741dc;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;188;-974.0627,1591.588;Float;False;Property;_MainColor;MainColor;4;1;[HDR];Create;True;0;0;False;0;False;1,1,1,0;2.373669,2.373669,2.373669,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;388;-105.9827,4073.957;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;244;-2564.659,1140.764;Inherit;False;NormalsMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;187;-637.1951,1398.159;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;97;-2353.066,1067.737;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;186;-1486.192,1425.516;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;496;-2724.85,2847.821;Inherit;False;FogLerp;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;189;-3147.041,1134.08;Inherit;True;Property;_NoiseNormal;NoiseNormal;14;0;Create;True;0;0;False;0;False;-1;None;a618b944fabd45046ba6b83a8bd2e15a;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;132;-2327.259,1630.295;Float;False;Property;_LightOffset;LightOffset;1;0;Create;True;0;0;False;0;False;0.5;0.74;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;436;-730.5219,323.9304;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;2252.292,2623.026;Inherit;False;193;Alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;490;-3161.68,2044.727;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;417;-5376.364,314.9423;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;422;-2625.23,451.5789;Inherit;False;Constant;_Float8;Float 8;16;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;421;-2991.654,379.6454;Inherit;False;Property;_LightMin;Light-Min;27;0;Create;True;0;0;False;0;False;0.1411765;0.007;0;0.99;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;414;-4465.399,645.8679;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;400;-4260.923,126.7079;Inherit;False;Property;_LightDen;Light-Den;22;0;Create;True;0;0;False;0;False;0.1668242;0.445;0.2;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;410;-1548.661,87.479;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;426;-4087.913,498.0564;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;413;-3498.092,86.71338;Inherit;True;Property;_LightTexture;LightTexture;20;0;Create;True;0;0;False;0;False;-1;ea713c9e3cd412349a88aa7531365459;ea713c9e3cd412349a88aa7531365459;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;182;-1983.13,1412.311;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;390;79.26537,4074.314;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;501;1646.854,2165.501;Inherit;False;496;FogLerp;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;183;-1669.292,1427.463;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;494;-3887.384,2055.828;Inherit;False;Property;_FogDistanceFogInstensity;Fog-DistanceFog-Instensity;10;1;[HideInInspector];Create;True;0;0;False;0;False;2.74;0.95;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;424;-4769.051,487.0261;Inherit;False;Property;_LightOffsetRing;Light-OffsetRing;23;0;Create;True;0;0;False;0;False;0;0.21;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;394;655.6467,4088.849;Inherit;False;DistanceWind;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;395;-839.6514,2562.812;Inherit;False;394;DistanceWind;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;437;-97.89645,74.88721;Inherit;False;Constant;_Float11;Float 11;16;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;351;-662.4821,2195.485;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DistanceOpNode;386;-416.9831,4063.957;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;408;-559.0648,104.4546;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;442;1506.012,1568.189;Inherit;True;Property;_LightShadow;LightShadow;19;0;Create;True;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;407;-1177.636,-189.4231;Inherit;False;Property;_DarkColor;DarkColor;30;0;Create;True;0;0;False;0;False;0.3520624,0.3501691,0.5754717,0;0.2739851,0.4010432,0.4433959,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;409;-1893.753,264.9384;Inherit;False;Property;_StepMax;StepMax;26;0;Create;True;0;0;False;0;False;0.1294118;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;96;-2800.784,1145.152;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;468;-5509.777,2739.509;Inherit;False;Property;_FogHorizontalLine;Fog-HorizontalLine;11;1;[HideInInspector];Create;True;0;0;False;0;False;-17;-22;-22;22;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;487;-2972.6,2024.904;Inherit;True;Property;_FogRampmap;Fog-Rampmap;5;1;[HideInInspector];Create;True;0;0;False;0;False;-1;409aebad96157034b8cee22c9bb9b3c0;409aebad96157034b8cee22c9bb9b3c0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;196;-2388.111,806.0389;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;198;1329.265,564.7384;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;200;1329.265,564.7384;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;197;2719.379,2679.566;Float;False;True;-1;2;ASEMaterialInspector;0;3;Good/Scene/Tree-Ad-3T-Ramp-Wind-NoiseN;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;True;0;False;-1;True;2;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;0;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;False;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;False;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;0;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;0;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;0;0;5;False;True;True;True;False;False;;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;199;1329.265,564.7384;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
WireConnection;357;0;356;2
WireConnection;357;1;358;0
WireConnection;372;0;356;1
WireConnection;372;1;357;0
WireConnection;359;0;356;1
WireConnection;359;1;372;0
WireConnection;299;0;306;0
WireConnection;361;0;362;0
WireConnection;319;0;338;0
WireConnection;363;0;359;0
WireConnection;363;1;364;0
WireConnection;365;0;363;0
WireConnection;365;1;361;0
WireConnection;276;0;319;0
WireConnection;276;1;299;0
WireConnection;366;0;365;0
WireConnection;366;1;355;0
WireConnection;366;2;354;0
WireConnection;348;0;276;0
WireConnection;373;0;366;0
WireConnection;367;0;373;1
WireConnection;323;0;349;0
WireConnection;380;0;367;0
WireConnection;324;0;323;0
WireConnection;324;1;323;1
WireConnection;339;0;340;0
WireConnection;339;1;324;0
WireConnection;376;0;380;0
WireConnection;382;0;376;0
WireConnection;266;1;339;0
WireConnection;341;0;266;0
WireConnection;337;0;341;0
WireConnection;337;1;284;0
WireConnection;337;2;383;0
WireConnection;331;0;337;0
WireConnection;333;0;331;1
WireConnection;333;1;299;2
WireConnection;334;0;331;0
WireConnection;334;1;299;1
WireConnection;336;0;331;2
WireConnection;336;1;299;3
WireConnection;335;0;334;0
WireConnection;335;1;333;0
WireConnection;335;2;336;0
WireConnection;193;0;84;4
WireConnection;399;0;420;0
WireConnection;399;1;421;0
WireConnection;399;2;423;0
WireConnection;399;4;422;0
WireConnection;470;0;467;0
WireConnection;470;1;469;0
WireConnection;476;0;473;0
WireConnection;476;1;474;0
WireConnection;482;0;480;0
WireConnection;482;1;480;0
WireConnection;482;2;480;0
WireConnection;492;0;484;0
WireConnection;492;1;475;0
WireConnection;401;0;415;0
WireConnection;401;1;429;0
WireConnection;401;2;402;0
WireConnection;439;0;407;0
WireConnection;439;1;408;0
WireConnection;415;0;416;1
WireConnection;415;1;430;0
WireConnection;397;0;398;0
WireConnection;473;0;472;0
WireConnection;473;1;471;0
WireConnection;491;0;487;0
WireConnection;491;1;489;0
WireConnection;475;0;470;0
WireConnection;433;0;435;0
WireConnection;435;0;406;0
WireConnection;435;1;434;2
WireConnection;478;0;475;0
WireConnection;478;1;475;0
WireConnection;444;0;438;0
WireConnection;444;1;502;0
WireConnection;430;0;416;2
WireConnection;430;1;417;0
WireConnection;208;0;187;0
WireConnection;425;0;400;0
WireConnection;425;1;411;0
WireConnection;411;0;401;0
WireConnection;411;1;426;0
WireConnection;467;0;466;0
WireConnection;467;1;465;0
WireConnection;472;0;465;2
WireConnection;472;1;468;0
WireConnection;419;0;413;0
WireConnection;419;1;404;0
WireConnection;298;0;497;0
WireConnection;497;0;442;0
WireConnection;497;1;500;0
WireConnection;497;2;501;0
WireConnection;420;0;419;0
WireConnection;493;0;486;0
WireConnection;488;0;492;0
WireConnection;479;0;478;0
WireConnection;479;1;477;0
WireConnection;403;0;399;0
WireConnection;313;0;335;0
WireConnection;445;0;444;0
WireConnection;480;0;476;0
WireConnection;481;0;479;0
WireConnection;486;0;494;0
WireConnection;486;1;488;0
WireConnection;502;0;208;0
WireConnection;391;0;390;0
WireConnection;495;0;491;0
WireConnection;485;0;483;0
WireConnection;387;0;386;0
WireConnection;438;0;439;0
WireConnection;438;2;437;0
WireConnection;483;0;481;0
WireConnection;483;1;482;0
WireConnection;428;0;414;0
WireConnection;392;0;390;0
WireConnection;405;1;403;0
WireConnection;184;1;186;0
WireConnection;388;0;387;0
WireConnection;388;1;389;0
WireConnection;244;0;96;0
WireConnection;187;0;84;0
WireConnection;187;1;184;0
WireConnection;187;2;188;0
WireConnection;97;0;101;0
WireConnection;97;1;244;0
WireConnection;186;0;183;0
WireConnection;496;0;485;0
WireConnection;189;5;192;0
WireConnection;436;0;435;0
WireConnection;490;0;493;0
WireConnection;490;1;493;0
WireConnection;417;0;416;3
WireConnection;417;1;418;0
WireConnection;414;0;427;0
WireConnection;414;1;397;0
WireConnection;410;0;405;0
WireConnection;410;1;432;0
WireConnection;410;2;409;0
WireConnection;426;0;424;0
WireConnection;426;1;428;0
WireConnection;413;1;425;0
WireConnection;182;0;97;0
WireConnection;182;1;131;0
WireConnection;182;2;132;0
WireConnection;390;0;388;0
WireConnection;183;0;182;0
WireConnection;394;0;392;0
WireConnection;351;0;341;0
WireConnection;386;0;384;0
WireConnection;386;1;385;0
WireConnection;408;0;410;0
WireConnection;408;1;436;0
WireConnection;442;1;502;0
WireConnection;442;0;445;0
WireConnection;96;0;189;0
WireConnection;487;1;490;0
WireConnection;197;2;298;0
WireConnection;197;3;194;0
WireConnection;197;4;202;0
WireConnection;197;5;313;0
ASEEND*/
//CHKSM=16A1BFEF3DFDE7DD01E287940DFC825FBE674152