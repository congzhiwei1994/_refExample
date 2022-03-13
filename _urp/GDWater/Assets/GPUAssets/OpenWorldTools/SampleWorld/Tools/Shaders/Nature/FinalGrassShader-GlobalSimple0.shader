// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Cl/Nature/Grass/FinalGrassShader-GlobalSimple0"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_ScaleTex("ScaleTex", 2D) = "white" {}
		[Toggle(_SCALETEXCTR_ON)] _ScaleTexCtr("ScaleTexCtr", Float) = 1
		[Toggle(_APPLYLIGHTCOLOR_ON)] _ApplyLightColor("ApplyLightColor", Float) = 1
		[Toggle(_WINDCOLOR_ON)] _WindColor("WindColor", Float) = 1
		[Toggle(_SHADOWCOLOR_ON)] _ShadowColor("ShadowColor", Float) = 1

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
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 70201

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
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _SCALETEXCTR_ON
			#pragma multi_compile __ _SHADOWCOLOR_ON
			#pragma multi_compile __ _WINDCOLOR_ON
			#pragma multi_compile __ _APPLYLIGHTCOLOR_ON
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
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
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D WindNoise;
			float4 WaveControl;
			float WindSpeedX;
			float WindStrength;
			sampler2D _ScaleTex;
			float4 _TerrainUV;
			float WindSpeedZ;
			sampler2D RTDTex;
			float3 RTCameraPosition;
			float RTCameraSize;
			float BendStr;
			float GrassRandStrength;
			float GrassAnimStrength;
			float GrassSpeed;
			float GrassRandObj;
			float GrassSwinging;
			float ScaleStep;
			float4 BaseColor;
			float4 HueColor;
			sampler2D _PigmentMap;
			float ColorMapStrenth;
			float Translucency;
			float CustomLambert;
			float4 WaveColor;
			float4 ShadowColor;


			float BlendOverlay49( float a , float b )
			{
				return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
			}
			
			float BlendOverlay54( float a , float b )
			{
				return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
			}
			
			float BlendOverlay55( float a , float b )
			{
				return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float4 WaveControl191 = WaveControl;
				float4 tex2DNode211 = tex2Dlod( WindNoise, float4( ( ( (ase_worldPos).xz / (WaveControl191).w ) + ( ( _TimeParameters.x ) * -(WaveControl191).xy ) ), 0, 0.0) );
				float2 appendResult161 = (float2(_TerrainUV.z , _TerrainUV.w));
				float2 TerrainUV169 = ( ( ( 1.0 - appendResult161 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (ase_worldPos).xz ) );
				float GlobalScaleChanel172 = tex2Dlod( _ScaleTex, float4( TerrainUV169, 0, 0.0) ).r;
				#ifdef _SCALETEXCTR_ON
				float staticSwitch194 = ( WindStrength * GlobalScaleChanel172 );
				#else
				float staticSwitch194 = WindStrength;
				#endif
				float WindStrength189 = staticSwitch194;
				float3 appendResult227 = (float3(( ase_worldPos.x + ( sin( ( tex2DNode211.r * PI * WindSpeedX ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) ) , ase_worldPos.y , ( ase_worldPos.z + ( sin( ( tex2DNode211.r * PI * WindSpeedZ ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) )));
				float3 worldToObj268 = mul( GetWorldToObjectMatrix(), float4( appendResult227, 1 ) ).xyz;
				float3 ResultGlobalWind324 = worldToObj268;
				float2 appendResult231 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 appendResult232 = (float2(RTCameraPosition.x , RTCameraPosition.z));
				float4 tex2DNode240 = tex2Dlod( RTDTex, float4( ( ( ( appendResult231 - appendResult232 ) / ( RTCameraSize * 2.0 ) ) + 0.5 ), 0, 0.0) );
				float3 appendResult241 = (float3(tex2DNode240.r , 0.0 , tex2DNode240.g));
				float3 worldToObjDir246 = normalize( mul( GetWorldToObjectMatrix(), float4( ( 0.001 + appendResult241 ), 0 ) ).xyz );
				float3 BendDirection248 = worldToObjDir246;
				float3 break251 = BendDirection248;
				float3 appendResult254 = (float3(break251.x , 0.0 , break251.z));
				float BendForce253 = max( ( length( appendResult241 ) * BendStr ) , 0.0 );
				float3 temp_output_255_0 = ( appendResult254 * BendForce253 * v.ase_color.r );
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch258 = ( temp_output_255_0 * GlobalScaleChanel172 );
				#else
				float3 staticSwitch258 = temp_output_255_0;
				#endif
				float3 ResultOtherBlend326 = staticSwitch258;
				float4 break104 = mul( GetObjectToWorldMatrix(), float4(0,0,0,1) );
				float temp_output_15_0 = frac( ( break104.x + break104.y + break104.z ) );
				float ObjRand108 = temp_output_15_0;
				float lerpResult119 = lerp( 1.0 , ObjRand108 , GrassRandStrength);
				float temp_output_132_0 = sin( ( GrassSpeed * ( ( _TimeParameters.x ) + ( ObjRand108 * GrassRandObj ) ) ) );
				float lerpResult133 = lerp( ( ( temp_output_132_0 * 0.5 ) + 0.5 ) , temp_output_132_0 , GrassSwinging);
				float temp_output_141_0 = ( ( lerpResult119 * ( GrassAnimStrength * 0.5 ) ) * ( v.ase_color.r * lerpResult133 ) );
				#ifdef _SCALETEXCTR_ON
				float staticSwitch305 = ( temp_output_141_0 * GlobalScaleChanel172 );
				#else
				float staticSwitch305 = temp_output_141_0;
				#endif
				float3 appendResult143 = (float3(staticSwitch305 , 0.0 , staticSwitch305));
				float3 ResultSelfVertexAnim328 = appendResult143;
				float3 temp_output_260_0 = ( ResultGlobalWind324 + ResultOtherBlend326 + ResultSelfVertexAnim328 );
				float smoothstepResult380 = smoothstep( ScaleStep , 1.0 , GlobalScaleChanel172);
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch265 = ( temp_output_260_0 * smoothstepResult380 );
				#else
				float3 staticSwitch265 = temp_output_260_0;
				#endif
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( staticSwitch265 - v.vertex.xyz );
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
				float4 break104 = mul( GetObjectToWorldMatrix(), float4(0,0,0,1) );
				float temp_output_15_0 = frac( ( break104.x + break104.y + break104.z ) );
				float3 lerpResult14 = lerp( (BaseColor).rgb , (HueColor).rgb , ( HueColor.a * temp_output_15_0 ));
				float3 BaseAlbedo314 = lerpResult14;
				float2 appendResult161 = (float2(_TerrainUV.z , _TerrainUV.w));
				float2 TerrainUV169 = ( ( ( 1.0 - appendResult161 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (WorldPosition).xz ) );
				float3 lerpResult274 = lerp( BaseAlbedo314 , (tex2D( _PigmentMap, TerrainUV169 )).rgb , ColorMapStrenth);
				float3 break51 = BaseAlbedo314;
				float a49 = break51.x;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float dotResult43 = dot( ase_worldViewDir , -SafeNormalize(_MainLightPosition.xyz) );
				float saferPower57 = max( ( saturate( dotResult43 ) * ( IN.ase_color.a * Translucency ) ) , 0.0001 );
				float ase_lightAtten = 0;
				Light ase_lightAtten_mainLight = GetMainLight( ShadowCoords );
				ase_lightAtten = ase_lightAtten_mainLight.distanceAttenuation * ase_lightAtten_mainLight.shadowAttenuation;
				float dotResult61 = dot( float3(0,1,0) , SafeNormalize(_MainLightPosition.xyz) );
				float b49 = ( ( pow( saferPower57 , 4.0 ) * 4.0 * ase_lightAtten ) * saturate( _MainLightColor.rgb ) * saturate( ( dotResult61 * 6.6666 ) ) ).x;
				float localBlendOverlay49 = BlendOverlay49( a49 , b49 );
				float a54 = break51.y;
				float b54 = 0.0;
				float localBlendOverlay54 = BlendOverlay54( a54 , b54 );
				float a55 = break51.z;
				float b55 = 0.0;
				float localBlendOverlay55 = BlendOverlay55( a55 , b55 );
				float3 appendResult56 = (float3(localBlendOverlay49 , localBlendOverlay54 , localBlendOverlay55));
				float3 Translucency317 = appendResult56;
				float3 ase_worldNormal = IN.ase_texcoord3.xyz;
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				float dotResult91 = dot( normalizedWorldNormal , SafeNormalize(_MainLightPosition.xyz) );
				float3 lerpResult396 = lerp( lerpResult274 , ( ( lerpResult274 + ( lerpResult274 * Translucency317 ) ) * ( ( saturate( dotResult91 ) * 0.5 ) + 0.5 ) ) , CustomLambert);
				float3 ResultDiffuse357 = lerpResult396;
				#ifdef _APPLYLIGHTCOLOR_ON
				float3 staticSwitch368 = ( ResultDiffuse357 * _MainLightColor.rgb );
				#else
				float3 staticSwitch368 = ResultDiffuse357;
				#endif
				float4 WaveControl191 = WaveControl;
				float4 tex2DNode211 = tex2D( WindNoise, ( ( (WorldPosition).xz / (WaveControl191).w ) + ( ( _TimeParameters.x ) * -(WaveControl191).xy ) ) );
				float WindNoiseChannelR321 = tex2DNode211.r;
				float4 ResultWindColor351 = ( WaveColor * WindNoiseChannelR321 * IN.ase_color.r );
				#ifdef _WINDCOLOR_ON
				float4 staticSwitch343 = ( float4( staticSwitch368 , 0.0 ) + ResultWindColor351 );
				#else
				float4 staticSwitch343 = float4( staticSwitch368 , 0.0 );
				#endif
				float4 lerpResult440 = lerp( ShadowColor , staticSwitch343 , ase_lightAtten);
				#ifdef _SHADOWCOLOR_ON
				float4 staticSwitch441 = lerpResult440;
				#else
				float4 staticSwitch441 = staticSwitch343;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = staticSwitch441.rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

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

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 70201

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#pragma shader_feature _SCALETEXCTR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
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
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D WindNoise;
			float4 WaveControl;
			float WindSpeedX;
			float WindStrength;
			sampler2D _ScaleTex;
			float4 _TerrainUV;
			float WindSpeedZ;
			sampler2D RTDTex;
			float3 RTCameraPosition;
			float RTCameraSize;
			float BendStr;
			float GrassRandStrength;
			float GrassAnimStrength;
			float GrassSpeed;
			float GrassRandObj;
			float GrassSwinging;
			float ScaleStep;


			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float4 WaveControl191 = WaveControl;
				float4 tex2DNode211 = tex2Dlod( WindNoise, float4( ( ( (ase_worldPos).xz / (WaveControl191).w ) + ( ( _TimeParameters.x ) * -(WaveControl191).xy ) ), 0, 0.0) );
				float2 appendResult161 = (float2(_TerrainUV.z , _TerrainUV.w));
				float2 TerrainUV169 = ( ( ( 1.0 - appendResult161 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (ase_worldPos).xz ) );
				float GlobalScaleChanel172 = tex2Dlod( _ScaleTex, float4( TerrainUV169, 0, 0.0) ).r;
				#ifdef _SCALETEXCTR_ON
				float staticSwitch194 = ( WindStrength * GlobalScaleChanel172 );
				#else
				float staticSwitch194 = WindStrength;
				#endif
				float WindStrength189 = staticSwitch194;
				float3 appendResult227 = (float3(( ase_worldPos.x + ( sin( ( tex2DNode211.r * PI * WindSpeedX ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) ) , ase_worldPos.y , ( ase_worldPos.z + ( sin( ( tex2DNode211.r * PI * WindSpeedZ ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) )));
				float3 worldToObj268 = mul( GetWorldToObjectMatrix(), float4( appendResult227, 1 ) ).xyz;
				float3 ResultGlobalWind324 = worldToObj268;
				float2 appendResult231 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 appendResult232 = (float2(RTCameraPosition.x , RTCameraPosition.z));
				float4 tex2DNode240 = tex2Dlod( RTDTex, float4( ( ( ( appendResult231 - appendResult232 ) / ( RTCameraSize * 2.0 ) ) + 0.5 ), 0, 0.0) );
				float3 appendResult241 = (float3(tex2DNode240.r , 0.0 , tex2DNode240.g));
				float3 worldToObjDir246 = normalize( mul( GetWorldToObjectMatrix(), float4( ( 0.001 + appendResult241 ), 0 ) ).xyz );
				float3 BendDirection248 = worldToObjDir246;
				float3 break251 = BendDirection248;
				float3 appendResult254 = (float3(break251.x , 0.0 , break251.z));
				float BendForce253 = max( ( length( appendResult241 ) * BendStr ) , 0.0 );
				float3 temp_output_255_0 = ( appendResult254 * BendForce253 * v.ase_color.r );
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch258 = ( temp_output_255_0 * GlobalScaleChanel172 );
				#else
				float3 staticSwitch258 = temp_output_255_0;
				#endif
				float3 ResultOtherBlend326 = staticSwitch258;
				float4 break104 = mul( GetObjectToWorldMatrix(), float4(0,0,0,1) );
				float temp_output_15_0 = frac( ( break104.x + break104.y + break104.z ) );
				float ObjRand108 = temp_output_15_0;
				float lerpResult119 = lerp( 1.0 , ObjRand108 , GrassRandStrength);
				float temp_output_132_0 = sin( ( GrassSpeed * ( ( _TimeParameters.x ) + ( ObjRand108 * GrassRandObj ) ) ) );
				float lerpResult133 = lerp( ( ( temp_output_132_0 * 0.5 ) + 0.5 ) , temp_output_132_0 , GrassSwinging);
				float temp_output_141_0 = ( ( lerpResult119 * ( GrassAnimStrength * 0.5 ) ) * ( v.ase_color.r * lerpResult133 ) );
				#ifdef _SCALETEXCTR_ON
				float staticSwitch305 = ( temp_output_141_0 * GlobalScaleChanel172 );
				#else
				float staticSwitch305 = temp_output_141_0;
				#endif
				float3 appendResult143 = (float3(staticSwitch305 , 0.0 , staticSwitch305));
				float3 ResultSelfVertexAnim328 = appendResult143;
				float3 temp_output_260_0 = ( ResultGlobalWind324 + ResultOtherBlend326 + ResultSelfVertexAnim328 );
				float smoothstepResult380 = smoothstep( ScaleStep , 1.0 , GlobalScaleChanel172);
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch265 = ( temp_output_260_0 * smoothstepResult380 );
				#else
				float3 staticSwitch265 = temp_output_260_0;
				#endif
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( staticSwitch265 - v.vertex.xyz );
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
				float4 ase_color : COLOR;

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

				
				float Alpha = 1;
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

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 70201

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#pragma shader_feature _SCALETEXCTR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
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
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D WindNoise;
			float4 WaveControl;
			float WindSpeedX;
			float WindStrength;
			sampler2D _ScaleTex;
			float4 _TerrainUV;
			float WindSpeedZ;
			sampler2D RTDTex;
			float3 RTCameraPosition;
			float RTCameraSize;
			float BendStr;
			float GrassRandStrength;
			float GrassAnimStrength;
			float GrassSpeed;
			float GrassRandObj;
			float GrassSwinging;
			float ScaleStep;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float4 WaveControl191 = WaveControl;
				float4 tex2DNode211 = tex2Dlod( WindNoise, float4( ( ( (ase_worldPos).xz / (WaveControl191).w ) + ( ( _TimeParameters.x ) * -(WaveControl191).xy ) ), 0, 0.0) );
				float2 appendResult161 = (float2(_TerrainUV.z , _TerrainUV.w));
				float2 TerrainUV169 = ( ( ( 1.0 - appendResult161 ) / _TerrainUV.x ) + ( ( _TerrainUV.x / ( _TerrainUV.x * _TerrainUV.x ) ) * (ase_worldPos).xz ) );
				float GlobalScaleChanel172 = tex2Dlod( _ScaleTex, float4( TerrainUV169, 0, 0.0) ).r;
				#ifdef _SCALETEXCTR_ON
				float staticSwitch194 = ( WindStrength * GlobalScaleChanel172 );
				#else
				float staticSwitch194 = WindStrength;
				#endif
				float WindStrength189 = staticSwitch194;
				float3 appendResult227 = (float3(( ase_worldPos.x + ( sin( ( tex2DNode211.r * PI * WindSpeedX ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) ) , ase_worldPos.y , ( ase_worldPos.z + ( sin( ( tex2DNode211.r * PI * WindSpeedZ ) ) * (WaveControl191).z * WindStrength189 * v.ase_color.r ) )));
				float3 worldToObj268 = mul( GetWorldToObjectMatrix(), float4( appendResult227, 1 ) ).xyz;
				float3 ResultGlobalWind324 = worldToObj268;
				float2 appendResult231 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 appendResult232 = (float2(RTCameraPosition.x , RTCameraPosition.z));
				float4 tex2DNode240 = tex2Dlod( RTDTex, float4( ( ( ( appendResult231 - appendResult232 ) / ( RTCameraSize * 2.0 ) ) + 0.5 ), 0, 0.0) );
				float3 appendResult241 = (float3(tex2DNode240.r , 0.0 , tex2DNode240.g));
				float3 worldToObjDir246 = normalize( mul( GetWorldToObjectMatrix(), float4( ( 0.001 + appendResult241 ), 0 ) ).xyz );
				float3 BendDirection248 = worldToObjDir246;
				float3 break251 = BendDirection248;
				float3 appendResult254 = (float3(break251.x , 0.0 , break251.z));
				float BendForce253 = max( ( length( appendResult241 ) * BendStr ) , 0.0 );
				float3 temp_output_255_0 = ( appendResult254 * BendForce253 * v.ase_color.r );
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch258 = ( temp_output_255_0 * GlobalScaleChanel172 );
				#else
				float3 staticSwitch258 = temp_output_255_0;
				#endif
				float3 ResultOtherBlend326 = staticSwitch258;
				float4 break104 = mul( GetObjectToWorldMatrix(), float4(0,0,0,1) );
				float temp_output_15_0 = frac( ( break104.x + break104.y + break104.z ) );
				float ObjRand108 = temp_output_15_0;
				float lerpResult119 = lerp( 1.0 , ObjRand108 , GrassRandStrength);
				float temp_output_132_0 = sin( ( GrassSpeed * ( ( _TimeParameters.x ) + ( ObjRand108 * GrassRandObj ) ) ) );
				float lerpResult133 = lerp( ( ( temp_output_132_0 * 0.5 ) + 0.5 ) , temp_output_132_0 , GrassSwinging);
				float temp_output_141_0 = ( ( lerpResult119 * ( GrassAnimStrength * 0.5 ) ) * ( v.ase_color.r * lerpResult133 ) );
				#ifdef _SCALETEXCTR_ON
				float staticSwitch305 = ( temp_output_141_0 * GlobalScaleChanel172 );
				#else
				float staticSwitch305 = temp_output_141_0;
				#endif
				float3 appendResult143 = (float3(staticSwitch305 , 0.0 , staticSwitch305));
				float3 ResultSelfVertexAnim328 = appendResult143;
				float3 temp_output_260_0 = ( ResultGlobalWind324 + ResultOtherBlend326 + ResultSelfVertexAnim328 );
				float smoothstepResult380 = smoothstep( ScaleStep , 1.0 , GlobalScaleChanel172);
				#ifdef _SCALETEXCTR_ON
				float3 staticSwitch265 = ( temp_output_260_0 * smoothstepResult380 );
				#else
				float3 staticSwitch265 = temp_output_260_0;
				#endif
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( staticSwitch265 - v.vertex.xyz );
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

				
				float Alpha = 1;
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
Version=18301
1920;0;1080;1899;-1965.299;-989.618;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;22;-3081.372,-2279.631;Inherit;False;1775.409;784.5146;Comment;16;96;97;14;18;37;36;11;13;108;15;17;104;101;100;99;314;RandColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;100;-3066.867,-1756.002;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CommentaryNode;158;-46.65614,-1332.004;Inherit;False;1588.018;638.2994;Comment;11;168;167;165;166;163;162;169;164;160;161;159;TerrainUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;99;-3042.968,-1680.083;Inherit;False;Constant;_Vector2;Vector 2;8;0;Create;True;0;0;False;0;False;0,0,0,1;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;-2843.968,-1757.083;Inherit;True;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector4Node;159;3.342734,-1196.704;Float;False;Global;_TerrainUV;_TerrainUV;2;0;Create;True;0;0;False;0;False;0,0,0,0;512,512,257,257;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;104;-2613.496,-1751.424;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;161;333.1436,-1281.003;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;160;276.1976,-827.511;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;281.1436,-964.0039;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;164;517.1439,-1282.004;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;165;566.2005,-833.511;Inherit;False;FLOAT2;0;2;2;2;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;163;431.1439,-1081.004;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;196;-3300.491,-320.9048;Inherit;False;3146.096;1411.576;Comment;35;321;268;227;226;225;223;224;217;216;218;220;222;219;221;215;213;214;212;211;210;207;206;205;201;204;202;203;199;198;200;197;188;324;373;374;Global Wind;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;17;-2358.38,-1752.782;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;228;-4240.042,1233.257;Inherit;False;4083.023;583.5191;Comment;32;259;326;258;257;255;256;252;254;253;251;250;247;249;248;244;245;246;243;241;242;240;239;238;237;235;236;231;234;233;232;230;229;Bend Direction and Force;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;188;-3273.05,605.246;Inherit;False;1117.205;464.4582;Comment;7;189;194;195;192;193;191;190;;0.5955882,0.4510705,0.4510705,1;0;0
Node;AmplifyShaderEditor.FractNode;15;-2119.608,-1750.514;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;166;729.4019,-1075.911;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector3Node;229;-3964.59,1501.195;Float;True;Global;RTCameraPosition;RTCameraPosition;4;0;Create;True;0;0;False;0;False;0,0,0;70.28001,8.7,-6.93;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;230;-4203.147,1476.786;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;167;886.1439,-1186.003;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;168;1083.908,-1092.813;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;231;-3747.339,1274.549;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;232;-3686.62,1529.905;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;108;-1898.936,-1592.726;Inherit;False;ObjRand;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;157;-3294.937,1960.464;Inherit;False;3112.254;1077.862;Comment;26;328;143;305;306;141;301;138;122;117;139;133;119;116;109;137;136;123;134;132;125;127;124;126;130;128;129;Grass Self Anim;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;233;-3652.569,1645.257;Float;False;Global;RTCameraSize;RTCameraSize;5;0;Create;True;0;0;False;0;False;20;42;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;234;-3602.112,1479.677;Float;False;Constant;_CONST_TWO;CONST_TWO;3;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;190;-3084.865,655.246;Inherit;False;Global;WaveControl;WaveControl;4;0;Create;True;0;0;False;0;False;0.1,0.1,0,10;0.1,-0.1,2,19.9;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;169;1316.752,-1110.598;Float;False;TerrainUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;191;-2793.669,654.0861;Inherit;False;WaveControl;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;129;-3244.937,2876.872;Inherit;False;Global;GrassRandObj;GrassRandObj;6;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;300;-45.13447,-560.3731;Inherit;False;978.261;283;Comment;3;171;172;170;GlobalScaleTex;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;236;-3471.392,1385.557;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-3145.228,2795.646;Inherit;False;108;ObjRand;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;235;-3448.569,1670.258;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;170;-25.13447,-482.756;Inherit;False;169;TerrainUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;238;-3270.233,1685.741;Float;False;Constant;_CONST_POINTFIVE;CONST_POINT FIVE;3;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;126;-3139.55,2616.379;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;197;-3143.719,283.4133;Inherit;False;191;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;237;-3219.952,1391.243;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;130;-2937.136,2798.413;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;200;-2930.243,283.0163;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;-3176.239,-47.39075;Inherit;False;191;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;124;-2958.685,2483.087;Inherit;False;Global;GrassSpeed;GrassSpeed;2;0;Create;True;0;0;False;0;False;1;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;198;-3250.491,-270.9048;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;239;-3076.734,1384.349;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;127;-2833.55,2637.379;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;171;189.6585,-504.3732;Inherit;True;Property;_ScaleTex;ScaleTex;3;0;Create;True;0;0;False;0;False;-1;None;895457350a5c8344c96bf7b2e556b6f2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TimeNode;203;-2934.267,97.42727;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;172;520.1277,-502.2391;Inherit;True;GlobalScaleChanel;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;204;-2762.243,285.0163;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;240;-2844.768,1365.299;Inherit;True;Global;RTDTex;RTDTex;1;0;Create;True;0;0;False;0;False;-1;None;21170930751283c409bc9e958e90e2e6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;202;-2992.825,-144.4538;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;125;-2658.323,2598.393;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;201;-2978.238,-46.39075;Inherit;False;FLOAT;3;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;205;-2648.269,159.4273;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;206;-2727.824,-108.4537;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;241;-2522.426,1376.245;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;192;-3210.89,871.3762;Inherit;False;Global;WindStrength;WindStrength;3;0;Create;True;0;0;False;0;False;0.5;0.26;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;132;-2493.957,2607.761;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;242;-2582.046,1280.257;Float;False;Constant;_SmallValue;SmallValue;6;0;Create;True;0;0;False;0;False;0.001;0.001;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;193;-3146.141,992.0803;Inherit;False;172;GlobalScaleChanel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-2255.179,2522.431;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;243;-2291.046,1286.257;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;195;-2878.14,955.0803;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;207;-2489.785,56.65127;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;373;-2014.926,265.1633;Inherit;False;Global;WindSpeedX;WindSpeedX;13;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;244;-2423.404,1606.208;Float;False;Global;BendStr;BendStr;1;0;Create;True;0;0;False;0;False;1.2;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-1937.216,2219.859;Inherit;False;Global;GrassAnimStrength;GrassAnimStrength;4;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;123;-2105.438,2114.154;Inherit;False;Global;GrassRandStrength;GrassRandStrength;5;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;194;-2712.14,878.0803;Inherit;False;Property;_Keyword0;Keyword 0;4;0;Create;True;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;265;False;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;136;-2074.183,2526.431;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;374;-1987.032,624.5182;Inherit;False;Global;WindSpeedZ;WindSpeedZ;13;0;Create;True;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;246;-2066.02,1282.433;Inherit;False;World;Object;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;211;-2359.946,30.1852;Inherit;True;Global;WindNoise;WindNoise;0;0;Create;True;0;0;False;0;False;-1;None;87062f5b399912a478d0735553ac419c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;109;-2043.012,2038.456;Inherit;False;108;ObjRand;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;137;-2265.47,2688.564;Inherit;False;Global;GrassSwinging;GrassSwinging;2;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;210;-2006.171,410.9501;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;245;-2292.887,1508.212;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;119;-1753.313,2010.465;Inherit;True;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;139;-1774.743,2373.907;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;215;-1511.626,284.1733;Inherit;False;191;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;213;-1712.84,204.0382;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;212;-1538.47,804.4111;Inherit;False;191;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;248;-1838.052,1287.976;Float;False;BendDirection;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;249;-2202.606,1644.399;Float;False;Constant;_CONST_ZERO_B;CONST_ZERO_B;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;214;-1694.147,474.5211;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;-1599.844,2236.53;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;189;-2444.772,885.6172;Inherit;False;WindStrength;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;247;-2158.884,1497.212;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;133;-1879.203,2590.045;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;222;-1307.3,667.9621;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;250;-1975.182,1490.812;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;220;-1288.01,942.4321;Inherit;False;189;WindStrength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;218;-1207.685,511.4462;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-1456.444,2013.153;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;251;-1555.44,1301.844;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-1512.234,2397.682;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;216;-1293.47,807.4111;Inherit;False;FLOAT;2;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;221;-1498.84,205.0382;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;217;-1300.727,286.7731;Inherit;False;FLOAT;2;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;219;-1313.942,432.5861;Inherit;False;189;WindStrength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-1004.731,190.8002;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;252;-1416.189,1583.935;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;253;-1766.053,1486.974;Float;False;BendForce;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;301;-1481.715,2651.883;Inherit;True;172;GlobalScaleChanel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;223;-906.7104,651.3452;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;-1264.907,2256.914;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;254;-1170.495,1328.177;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;306;-1148.137,2502.606;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;225;-827.4005,-42.67884;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;256;-891.3245,1705.212;Inherit;False;172;GlobalScaleChanel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;255;-1027.417,1433.951;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;226;-933.8476,-259.9338;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;305;-1012.186,2366.465;Inherit;False;Property;_Keyword3;Keyword 3;4;0;Create;True;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;265;False;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;227;-736.4235,-215.3528;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;257;-665.9178,1667.212;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;143;-767.7111,2321.31;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;258;-604.2629,1429.852;Inherit;False;Property;_Keyword1;Keyword 1;4;0;Create;True;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;265;False;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;268;-617.045,22.56228;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;328;-531.909,2326.961;Inherit;False;ResultSelfVertexAnim;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;324;-380.0476,25.33718;Inherit;False;ResultGlobalWind;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;307;2643.306,2943.495;Inherit;False;735.3674;452.8086;Comment;6;264;263;261;262;376;377;Global Scale;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;326;-360.8725,1413.327;Inherit;False;ResultOtherBlend;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;377;2685.232,3210.252;Inherit;False;Global;ScaleStep;ScaleStep;13;0;Create;True;0;0;False;0;False;0;0.45;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;327;2121.395,2690.211;Inherit;False;326;ResultOtherBlend;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;2117.835,2602.865;Inherit;False;324;ResultGlobalWind;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;262;2692.306,3101.494;Inherit;False;172;GlobalScaleChanel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;329;2113.972,2779.184;Inherit;False;328;ResultSelfVertexAnim;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;380;3094.046,2791.563;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;260;2502.902,2599.26;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;356;67.90331,580.6664;Inherit;False;1814.032;1063.264;Comment;5;357;396;274;106;311;ResultDiffuse;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;379;3293.413,2683.446;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;312;2627.344,1358.466;Inherit;False;611.533;484.3409;Comment;3;289;291;440;ShadowColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;106;90.9892,1033.614;Inherit;False;1536.655;593.1197;Comment;13;315;90;95;53;93;318;94;92;91;89;88;395;397;Half Lambert;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;323;-3084.311,-2983.016;Inherit;False;1039.223;537.1788;Comment;5;271;320;322;270;351;WindColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;364;1867.689,1876.86;Inherit;False;1515.125;502.8562;Comment;8;360;343;353;345;368;339;358;441;RenderType==OnlyDiffuse;1,0.5411765,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;311;100.2772,677.3842;Inherit;False;762.5449;304.8642;Comment;4;173;174;319;273;ColorMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;65;-3069.169,-1332.371;Inherit;False;2834.89;662.1401;Comment;28;40;317;56;55;49;54;52;51;63;316;66;67;58;73;48;62;57;61;47;60;46;41;59;43;39;42;45;44;Translucency;1,1,1,1;0;0
Node;AmplifyShaderEditor.StaticSwitch;265;3580.718,2590.327;Inherit;False;Property;_ScaleTexCtr;ScaleTexCtr;4;0;Create;True;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;266;3640.236,2741.682;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;358;1954.691,1926.86;Inherit;False;357;ResultDiffuse;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;36;-1892.754,-2130.727;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-1350.577,-1024.614;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;259;-4215.948,1270.366;Inherit;True;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LightColorNode;360;1944.689,2080.86;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.WorldNormalVector;88;194.6474,1320.026;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;339;2151.972,2084.329;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;357;1650.517,770.5785;Inherit;False;ResultDiffuse;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightAttenuation;289;2680.344,1619.466;Inherit;True;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;270;-2993.681,-2933.016;Inherit;False;Global;WaveColor;WaveColor;10;0;Create;True;0;0;False;0;False;1,1,1,0;0.25,1,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;37;-1913.56,-2007.67;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;49;-925.8549,-1261.973;Inherit;False;return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b)@;1;False;2;True;a;FLOAT;0;In;;Inherit;False;True;b;FLOAT;0;In;;Inherit;False;BlendOverlay;True;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;319;703.9838,757.5073;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;321;-1793.074,27.24721;Inherit;False;WindNoiseChannelR;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;273;661.7805,901.7303;Inherit;False;Global;ColorMapStrenth;ColorMapStrenth;14;0;Create;True;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;46;-2305.941,-1230.869;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;42;-2931.658,-1233.253;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;14;-1711.198,-2051.631;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;-1622.527,-1215.113;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;4;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;59;-2201.001,-976.7581;Inherit;False;Constant;_Vector0;Vector 0;8;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;441;3112.8,1926.023;Inherit;False;Property;_ShadowColor;ShadowColor;7;0;Create;True;0;0;False;0;False;1;1;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-2102.576,-1225.065;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;43;-2514.415,-1231.495;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;96;-2129.963,-1930.716;Inherit;False;return frac(UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3])@;1;False;0;ObjectPosRand01;True;False;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;345;2548.634,2154.66;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;353;2318.568,2171.592;Inherit;True;351;ResultWindColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-1733.292,-959.4982;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;6.6666;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;351;-2361.83,-2916.395;Inherit;False;ResultWindColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;271;-2631.504,-2925.56;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;94;535.6868,1431.631;Inherit;False;Constant;_Float3;Float 3;8;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;91;421.5775,1314.28;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;397;1342.506,1461.394;Inherit;False;Global;CustomLambert;CustomLambert;9;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;619.8926,1090.68;Inherit;False;314;BaseAlbedo;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-3038.416,-806.1053;Inherit;False;Global;Translucency;Translucency;2;0;Create;True;0;0;False;0;False;0.8;0.304;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2496.848,-968.0034;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;-1913.653,-1823.354;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;440;2930.8,1571.023;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;61;-1963.892,-958.9838;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;320;-2957.345,-2681.448;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;318;666.238,1164.173;Inherit;False;317;Translucency;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;92;552.4493,1312.553;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;60;-2219.165,-806.8995;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;56;-749.5764,-1162.289;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;57;-1864.323,-1210.726;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;4;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;73;-1882.891,-1087.044;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;261;2729.093,2981.495;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CustomExpressionNode;54;-923.5647,-1124.708;Inherit;False;return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b)@;1;False;2;True;a;FLOAT;0;In;;Inherit;False;True;b;FLOAT;0;In;;Inherit;False;BlendOverlay;True;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;396;1493.308,771.2346;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;44;-2965.271,-1073.49;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-1912.842,-1930.668;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;376;2926.232,3185.252;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;39;-2695.941,-1009.632;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LightColorNode;48;-1721.628,-820.9066;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;322;-3034.311,-2758.617;Inherit;False;321;WindNoiseChannelR;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;51;-1222.115,-1289.448;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;89;159.1138,1464.199;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;267;3869.642,2598.171;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;53;1105.601,1131.162;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;66;-1547.796,-809.9504;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;11;-2167.199,-2229.631;Inherit;False;Global;BaseColor;BaseColor;0;0;Create;True;0;0;False;0;False;0.6015961,0.7735849,0.3393556,1;0.6015961,0.7735849,0.3393552,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;274;1001.378,768.6893;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;395;932.2315,1148.071;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;708.0376,1314.031;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;95;898.1369,1307.68;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;55;-935.9998,-987.4606;Inherit;False;return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b)@;1;False;2;True;a;FLOAT;0;In;;Inherit;False;True;b;FLOAT;0;In;;Inherit;False;BlendOverlay;True;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;264;3235.093,2998.495;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;45;-2696.47,-1161.229;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;52;-1214.833,-1033.254;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ColorNode;291;2683.577,1428.721;Inherit;False;Global;ShadowColor;ShadowColor;8;0;Create;True;0;0;False;0;False;0.3161765,0.3068772,0.3068772,0;0.007843138,0.1568628,0.03921569,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;316;-1428.567,-1289.022;Inherit;False;314;BaseAlbedo;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;368;2276.522,1925.523;Inherit;False;Property;_ApplyLightColor;ApplyLightColor;5;0;Create;True;0;0;False;0;False;1;1;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;314;-1519.776,-2039.813;Inherit;False;BaseAlbedo;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;173;374.122,727.3853;Inherit;True;Global;_PigmentMap;_PigmentMap;2;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;13;-2376.799,-2008.93;Inherit;False;Global;HueColor;HueColor;1;0;Create;True;0;0;False;0;False;1,0.9356071,0.3066036,0;1,0.9356071,0.3066032,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;317;-600.766,-1125.558;Inherit;False;Translucency;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;263;3135.657,3164.891;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;90;1296.84,1225.067;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;343;2639.788,1928.892;Inherit;False;Property;_WindColor;WindColor;6;0;Create;True;0;0;False;0;False;1;1;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;67;-1565.712,-963.0333;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;174;150.2776,741.8483;Inherit;True;169;TerrainUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;428;3608.718,1998.676;Float;False;True;-1;2;ASEMaterialInspector;0;3;Cl/Nature/Grass/FinalGrassShader-GlobalSimple0;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;7;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;21;Surface;0;  Blend;0;Two Sided;0;Cast Shadows;1;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;431;6324.436,2188.563;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;430;6324.436,2188.563;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;427;6324.436,2188.563;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;429;6324.436,2188.563;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
WireConnection;101;0;100;0
WireConnection;101;1;99;0
WireConnection;104;0;101;0
WireConnection;161;0;159;3
WireConnection;161;1;159;4
WireConnection;162;0;159;1
WireConnection;162;1;159;1
WireConnection;164;0;161;0
WireConnection;165;0;160;0
WireConnection;163;0;159;1
WireConnection;163;1;162;0
WireConnection;17;0;104;0
WireConnection;17;1;104;1
WireConnection;17;2;104;2
WireConnection;15;0;17;0
WireConnection;166;0;163;0
WireConnection;166;1;165;0
WireConnection;167;0;164;0
WireConnection;167;1;159;1
WireConnection;168;0;167;0
WireConnection;168;1;166;0
WireConnection;231;0;230;1
WireConnection;231;1;230;3
WireConnection;232;0;229;1
WireConnection;232;1;229;3
WireConnection;108;0;15;0
WireConnection;169;0;168;0
WireConnection;191;0;190;0
WireConnection;236;0;231;0
WireConnection;236;1;232;0
WireConnection;235;0;233;0
WireConnection;235;1;234;0
WireConnection;237;0;236;0
WireConnection;237;1;235;0
WireConnection;130;0;128;0
WireConnection;130;1;129;0
WireConnection;200;0;197;0
WireConnection;239;0;237;0
WireConnection;239;1;238;0
WireConnection;127;0;126;2
WireConnection;127;1;130;0
WireConnection;171;1;170;0
WireConnection;172;0;171;1
WireConnection;204;0;200;0
WireConnection;240;1;239;0
WireConnection;202;0;198;0
WireConnection;125;0;124;0
WireConnection;125;1;127;0
WireConnection;201;0;199;0
WireConnection;205;0;203;2
WireConnection;205;1;204;0
WireConnection;206;0;202;0
WireConnection;206;1;201;0
WireConnection;241;0;240;1
WireConnection;241;2;240;2
WireConnection;132;0;125;0
WireConnection;134;0;132;0
WireConnection;243;0;242;0
WireConnection;243;1;241;0
WireConnection;195;0;192;0
WireConnection;195;1;193;0
WireConnection;207;0;206;0
WireConnection;207;1;205;0
WireConnection;194;1;192;0
WireConnection;194;0;195;0
WireConnection;136;0;134;0
WireConnection;246;0;243;0
WireConnection;211;1;207;0
WireConnection;245;0;241;0
WireConnection;119;1;109;0
WireConnection;119;2;123;0
WireConnection;213;0;211;1
WireConnection;213;1;210;0
WireConnection;213;2;373;0
WireConnection;248;0;246;0
WireConnection;214;0;211;1
WireConnection;214;1;210;0
WireConnection;214;2;374;0
WireConnection;117;0;116;0
WireConnection;189;0;194;0
WireConnection;247;0;245;0
WireConnection;247;1;244;0
WireConnection;133;0;136;0
WireConnection;133;1;132;0
WireConnection;133;2;137;0
WireConnection;222;0;214;0
WireConnection;250;0;247;0
WireConnection;250;1;249;0
WireConnection;122;0;119;0
WireConnection;122;1;117;0
WireConnection;251;0;248;0
WireConnection;138;0;139;1
WireConnection;138;1;133;0
WireConnection;216;0;212;0
WireConnection;221;0;213;0
WireConnection;217;0;215;0
WireConnection;224;0;221;0
WireConnection;224;1;217;0
WireConnection;224;2;219;0
WireConnection;224;3;218;1
WireConnection;253;0;250;0
WireConnection;223;0;222;0
WireConnection;223;1;216;0
WireConnection;223;2;220;0
WireConnection;223;3;218;1
WireConnection;141;0;122;0
WireConnection;141;1;138;0
WireConnection;254;0;251;0
WireConnection;254;1;249;0
WireConnection;254;2;251;2
WireConnection;306;0;141;0
WireConnection;306;1;301;0
WireConnection;225;0;198;3
WireConnection;225;1;223;0
WireConnection;255;0;254;0
WireConnection;255;1;253;0
WireConnection;255;2;252;1
WireConnection;226;0;198;1
WireConnection;226;1;224;0
WireConnection;305;1;141;0
WireConnection;305;0;306;0
WireConnection;227;0;226;0
WireConnection;227;1;198;2
WireConnection;227;2;225;0
WireConnection;257;0;255;0
WireConnection;257;1;256;0
WireConnection;143;0;305;0
WireConnection;143;2;305;0
WireConnection;258;1;255;0
WireConnection;258;0;257;0
WireConnection;268;0;227;0
WireConnection;328;0;143;0
WireConnection;324;0;268;0
WireConnection;326;0;258;0
WireConnection;380;0;262;0
WireConnection;380;1;377;0
WireConnection;260;0;325;0
WireConnection;260;1;327;0
WireConnection;260;2;329;0
WireConnection;379;0;260;0
WireConnection;379;1;380;0
WireConnection;265;1;260;0
WireConnection;265;0;379;0
WireConnection;36;0;11;0
WireConnection;63;0;58;0
WireConnection;63;1;66;0
WireConnection;63;2;67;0
WireConnection;339;0;358;0
WireConnection;339;1;360;1
WireConnection;357;0;396;0
WireConnection;37;0;13;0
WireConnection;49;0;51;0
WireConnection;49;1;52;0
WireConnection;319;0;173;0
WireConnection;321;0;211;1
WireConnection;46;0;43;0
WireConnection;14;0;36;0
WireConnection;14;1;37;0
WireConnection;14;2;18;0
WireConnection;58;0;57;0
WireConnection;58;2;73;0
WireConnection;441;1;343;0
WireConnection;441;0;440;0
WireConnection;47;0;46;0
WireConnection;47;1;41;0
WireConnection;43;0;42;0
WireConnection;43;1;45;0
WireConnection;345;0;368;0
WireConnection;345;1;353;0
WireConnection;62;0;61;0
WireConnection;351;0;271;0
WireConnection;271;0;270;0
WireConnection;271;1;322;0
WireConnection;271;2;320;1
WireConnection;91;0;88;0
WireConnection;91;1;89;0
WireConnection;41;0;39;4
WireConnection;41;1;40;0
WireConnection;18;0;13;4
WireConnection;18;1;15;0
WireConnection;440;0;291;0
WireConnection;440;1;343;0
WireConnection;440;2;289;0
WireConnection;61;0;59;0
WireConnection;61;1;60;0
WireConnection;92;0;91;0
WireConnection;56;0;49;0
WireConnection;56;1;54;0
WireConnection;56;2;55;0
WireConnection;57;0;47;0
WireConnection;261;0;260;0
WireConnection;54;0;51;1
WireConnection;396;0;274;0
WireConnection;396;1;90;0
WireConnection;396;2;397;0
WireConnection;97;0;96;0
WireConnection;97;1;13;4
WireConnection;376;0;377;0
WireConnection;51;0;316;0
WireConnection;267;0;265;0
WireConnection;267;1;266;0
WireConnection;53;0;274;0
WireConnection;53;1;395;0
WireConnection;66;0;48;1
WireConnection;274;0;315;0
WireConnection;274;1;319;0
WireConnection;274;2;273;0
WireConnection;395;0;274;0
WireConnection;395;1;318;0
WireConnection;93;0;92;0
WireConnection;93;1;94;0
WireConnection;95;0;93;0
WireConnection;95;1;94;0
WireConnection;55;0;51;2
WireConnection;264;0;261;0
WireConnection;264;1;263;0
WireConnection;264;2;261;2
WireConnection;45;0;44;0
WireConnection;52;0;63;0
WireConnection;368;1;358;0
WireConnection;368;0;339;0
WireConnection;314;0;14;0
WireConnection;173;1;174;0
WireConnection;317;0;56;0
WireConnection;263;0;261;1
WireConnection;263;1;376;0
WireConnection;90;0;53;0
WireConnection;90;1;95;0
WireConnection;343;1;368;0
WireConnection;343;0;345;0
WireConnection;67;0;62;0
WireConnection;428;2;441;0
WireConnection;428;5;267;0
ASEEND*/
//CHKSM=3E9D3A4CDB800D98EFCE971EEC51030ECD09918F