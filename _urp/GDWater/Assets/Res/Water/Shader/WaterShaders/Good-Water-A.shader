// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Good/Water/Water-A"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_Shininess("Shininess", Range( 0.01 , 1)) = 0.1
		[HDR]_EasyColor("Easy-Color", Color) = (0,1,0.7931035,0)
		_DepthColor("Depth-Color", Color) = (0.3157439,0.3965517,0.5882353,0)
		_DepthPower("Depth-Power", Range( 0 , 2)) = 0.5647059
		_EdgeAlpha("Edge-Alpha", Range( 0.02 , 1.5)) = 0.1
		_DepthDensity("Depth-Density", Range( 0.02 , 1.5)) = 0.1
		_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalTilingV3("Normal-TilingV3", Range( 1 , 12)) = 4.282549
		_NormalBaseLerp("Normal-BaseLerp", Range( 0 , 1)) = 0
		_HeightMap("HeightMap", 2D) = "white" {}
		_HeightMultiply("Height-Multiply", Range( 0 , 10)) = 1
		_SpeedFV4("SpeedFV4", Vector) = (1,0.5,-1,-0.5)
		_SpeedSubTime("Speed-SubTime", Range( 0 , 0.2)) = 0.01
		_Wave1Spped("Wave1-Spped", Range( 0 , 5)) = 0
		_Wave2Spped("Wave2-Spped", Range( 0 , 5)) = 0
		_Wave3Spped("Wave3-Spped", Range( 0 , 5)) = 0
		_Wave1Times("Wave1-Times", Range( 0 , 1)) = 1
		_Wave2Times("Wave2-Times", Range( 0 , 1)) = 1
		_Wave3Times("Wave3-Times", Range( 0 , 1)) = 1
		_Wave1Height("Wave1-Height", Range( 0 , 3)) = 1
		_Wave2Heigh("Wave2-Heigh", Range( 0 , 3)) = 1
		_Wave3Heigh("Wave3-Heigh", Range( 0 , 1)) = 1
		_CubeMapRefl("Cube-Map-Refl", CUBE) = "white" {}
		_ReflInstensity("Refl-Instensity", Range( 0 , 4)) = 2
		_ReflNormalLerp("Refl-Normal-Lerp", Range( 0 , 0.3)) = 0
		_ReflFreInstensity("Refl-Fre-Instensity", Range( 0 , 2)) = 0.8
		_ReflFreDistance("Refl-Fre-Distance", Range( 0 , 1)) = 0.4
		_RefractionDisrt("Refraction-Disrt", Range( 0 , 4)) = 3
		_Wava1Direction("Wava1-Direction", Range( -3 , 3)) = 0.4951346
		_Wava2Direction("Wava2-Direction", Range( -3 , 3)) = 0.4951346
		_MaxHeightLight2("MaxHeightLight2", Range( 0 , 4)) = 1.545907
		_Wava3Direction("Wava3-Direction", Range( -3 , 3)) = 0.4951346
		_HL1Color("HL1-Color", Color) = (1,1,1,0)
		[HDR]_HL2Color("HL2-Color", Color) = (1,1,1,0)
		_HL1Power("HL1-Power", Range( 0 , 4)) = 0
		_HL2Power("HL2-Power", Range( 1 , 600)) = 12
		_FogFarColor("Fog-FarColor", Color) = (0.6763083,0.9165702,0.9622641,0)
		_EdgeIntensity("EdgeIntensity", Range( 0 , 3)) = 0
		_EdgecolorAdd("EdgecolorAdd", Color) = (0,0,0,0)
		_EdgePower("EdgePower", Range( 1 , 12)) = 3
		_FogDistance("Fog-Distance", Range( 0 , 0.1)) = 0.023
		_FogPower("Fog-Power", Range( 0 , 3)) = 1

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

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 3.0

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
			
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 70108
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1

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
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
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
				float4 lightmapUVOrVertexSH : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FogFarColor;
			float4 _EdgecolorAdd;
			float4 _HL2Color;
			float4 _DepthColor;
			float4 _EasyColor;
			float4 _SpeedFV4;
			float4 _HL1Color;
			float _Wave3Heigh;
			float _RefractionDisrt;
			float _DepthDensity;
			float _DepthPower;
			float _ReflNormalLerp;
			float _ReflInstensity;
			float _ReflFreInstensity;
			float _ReflFreDistance;
			float _EdgeAlpha;
			float _EdgeIntensity;
			float _EdgePower;
			float _Shininess;
			float _NormalBaseLerp;
			float _HL1Power;
			float _MaxHeightLight2;
			float _Wava3Direction;
			float _Wave3Spped;
			float _Wave3Times;
			float _Wave2Heigh;
			float _Wava2Direction;
			float _Wave2Spped;
			float _Wave2Times;
			float _Wave1Height;
			float _Wave1Spped;
			float _Wava1Direction;
			float _Wave1Times;
			float _HeightMultiply;
			float _SpeedSubTime;
			float _NormalTilingV3;
			float _HL2Power;
			float _FogDistance;
			float _FogPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);
			TEXTURE2D(_HeightMap);
			SAMPLER(sampler_HeightMap);
			uniform float4 _CameraDepthTexture_TexelSize;
			TEXTURECUBE(_CubeMapRefl);
			SAMPLER(sampler_CubeMapRefl);


			float3 ASEIndirectDiffuse( float2 uvStaticLightmap, float3 normalWS )
			{
			#ifdef LIGHTMAP_ON
				return SampleLightmap( uvStaticLightmap, normalWS );
			#else
				return SampleSH(normalWS);
			#endif
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult590 = (float2(ase_worldPos.x , ase_worldPos.z));
				float cos1015 = cos( _Wava3Direction );
				float sin1015 = sin( _Wava3Direction );
				float2 rotator1015 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos1015 , -sin1015 , sin1015 , cos1015 )) + float2( 0,0 );
				float mulTime1019 = _TimeParameters.x * _Wave3Spped;
				float temp_output_1025_0 = ( _Wave3Heigh * sin( ( ( ( rotator1015 * 0.1 ) + mulTime1019 ) * TWO_PI * _Wave3Times ) ).x );
				float cos912 = cos( _Wava2Direction );
				float sin912 = sin( _Wava2Direction );
				float2 rotator912 = mul( appendResult590 - float2( 0,0.3 ) , float2x2( cos912 , -sin912 , sin912 , cos912 )) + float2( 0,0.3 );
				float mulTime919 = _TimeParameters.x * _Wave2Spped;
				float temp_output_698_0 = ( _Wave2Heigh * sin( ( ( ( rotator912 * 0.1 ) + mulTime919 ) * TWO_PI * _Wave2Times ) ).x );
				float mulTime632 = _TimeParameters.x * _Wave1Spped;
				float cos902 = cos( _Wava1Direction );
				float sin902 = sin( _Wava1Direction );
				float2 rotator902 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos902 , -sin902 , sin902 , cos902 )) + float2( 0,0 );
				float temp_output_1014_0 = ( ( temp_output_1025_0 * temp_output_698_0 ) * temp_output_698_0 * ( _Wave1Height * ( -abs( sin( ( ( mulTime632 + ( rotator902 * 0.1 ) ) * TWO_PI * _Wave1Times ) ).x ) + 1.2 ) ) );
				float temp_output_926_0 = ( temp_output_1025_0 + temp_output_698_0 + temp_output_1014_0 );
				float HeightOffset899 = temp_output_926_0;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord8 = screenPos;
				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz));
				float eyeDepth = -objectToViewPos.z;
				o.ase_texcoord3.w = eyeDepth;
				
				o.ase_texcoord7 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( HeightOffset899 + 0.0 ) * (normalizedWorldNormal).xzy * _HeightMultiply );
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
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;

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
				o.ase_tangent = v.ase_tangent;
				o.texcoord1 = v.texcoord1;
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
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
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
				float mulTime617 = _TimeParameters.x * _SpeedSubTime;
				float2 appendResult610 = (float2(_SpeedFV4.x , _SpeedFV4.y));
				float2 appendResult590 = (float2(WorldPosition.x , WorldPosition.z));
				float cos902 = cos( _Wava1Direction );
				float sin902 = sin( _Wava1Direction );
				float2 rotator902 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos902 , -sin902 , sin902 , cos902 )) + float2( 0,0 );
				float2 temp_output_594_0 = ( rotator902 * _NormalTilingV3 * 0.0066 );
				float2 panner601 = ( mulTime617 * appendResult610 + temp_output_594_0);
				float2 appendResult611 = (float2(_SpeedFV4.z , _SpeedFV4.w));
				float2 panner602 = ( mulTime617 * appendResult611 + ( ( temp_output_594_0 * 0.77 ) + float2( -0.33,0.66 ) ));
				float3 lerpResult648 = lerp( UnpackNormalScale( SAMPLE_TEXTURE2D( _NormalMap, sampler_NormalMap, panner601 ), 1.0f ) , UnpackNormalScale( SAMPLE_TEXTURE2D( _NormalMap, sampler_NormalMap, panner602 ), 1.0f ) , 0.5);
				float2 temp_output_623_0 = ( panner601 * 0.25 );
				float3 lerpResult683 = lerp( lerpResult648 , ( UnpackNormalScale( SAMPLE_TEXTURE2D( _NormalMap, sampler_NormalMap, temp_output_623_0 ), 1.0f ) * 0.8 ) , 0.4);
				float3 Normal935 = lerpResult683;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal1092 = Normal935;
				float3 worldNormal1092 = normalize( float3(dot(tanToWorld0,tanNormal1092), dot(tanToWorld1,tanNormal1092), dot(tanToWorld2,tanNormal1092)) );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult1079 = normalize( ase_worldViewDir );
				float3 normalizeResult1080 = normalize( ( SafeNormalize(_MainLightPosition.xyz) + normalizeResult1079 ) );
				float dotResult1085 = dot( worldNormal1092 , normalizeResult1080 );
				float4 HeightLightL21088 = ( pow( saturate( dotResult1085 ) , _HL2Power ) * _HL2Color );
				float4 temp_cast_0 = (_MaxHeightLight2).xxxx;
				float4 clampResult680 = clamp( HeightLightL21088 , float4( 0,0,0,0 ) , temp_cast_0 );
				float4 tex2DNode580 = SAMPLE_TEXTURE2D( _HeightMap, sampler_HeightMap, panner601 );
				float4 tex2DNode613 = SAMPLE_TEXTURE2D( _HeightMap, sampler_HeightMap, panner602 );
				float lerpResult614 = lerp( tex2DNode580.r , tex2DNode613.r , 0.5);
				float cos1015 = cos( _Wava3Direction );
				float sin1015 = sin( _Wava3Direction );
				float2 rotator1015 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos1015 , -sin1015 , sin1015 , cos1015 )) + float2( 0,0 );
				float mulTime1019 = _TimeParameters.x * _Wave3Spped;
				float temp_output_1025_0 = ( _Wave3Heigh * sin( ( ( ( rotator1015 * 0.1 ) + mulTime1019 ) * TWO_PI * _Wave3Times ) ).x );
				float cos912 = cos( _Wava2Direction );
				float sin912 = sin( _Wava2Direction );
				float2 rotator912 = mul( appendResult590 - float2( 0,0.3 ) , float2x2( cos912 , -sin912 , sin912 , cos912 )) + float2( 0,0.3 );
				float mulTime919 = _TimeParameters.x * _Wave2Spped;
				float temp_output_698_0 = ( _Wave2Heigh * sin( ( ( ( rotator912 * 0.1 ) + mulTime919 ) * TWO_PI * _Wave2Times ) ).x );
				float mulTime632 = _TimeParameters.x * _Wave1Spped;
				float temp_output_1014_0 = ( ( temp_output_1025_0 * temp_output_698_0 ) * temp_output_698_0 * ( _Wave1Height * ( -abs( sin( ( ( mulTime632 + ( rotator902 * 0.1 ) ) * TWO_PI * _Wave1Times ) ).x ) + 1.2 ) ) );
				float temp_output_926_0 = ( temp_output_1025_0 + temp_output_698_0 + temp_output_1014_0 );
				float4 temp_cast_1 = (( (0.5 + (( ( tex2DNode580.r + tex2DNode613.r + ( lerpResult614 + ( SAMPLE_TEXTURE2D( _HeightMap, sampler_HeightMap, temp_output_623_0 ).r * 0.8 ) ) ) + (0.0 + (temp_output_926_0 - -1.0) * (1.0 - 0.0) / (3.0 - -1.0)) ) - 0.0) * (1.0 - 0.5) / (1.1 - 0.0)) * _HL1Power )).xxxx;
				float4 temp_output_43_0_g1 = temp_cast_1;
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult4_g2 = normalize( ( ase_worldViewDir + SafeNormalize(_MainLightPosition.xyz) ) );
				float3 lerpResult673 = lerp( float3(0,0,1) , Normal935 , _NormalBaseLerp);
				float3 tanNormal12_g1 = lerpResult673;
				float3 worldNormal12_g1 = float3(dot(tanToWorld0,tanNormal12_g1), dot(tanToWorld1,tanNormal12_g1), dot(tanToWorld2,tanNormal12_g1));
				float3 normalizeResult64_g1 = normalize( worldNormal12_g1 );
				float dotResult19_g1 = dot( normalizeResult4_g2 , normalizeResult64_g1 );
				float ase_lightAtten = 0;
				Light ase_lightAtten_mainLight = GetMainLight( ShadowCoords );
				ase_lightAtten = ase_lightAtten_mainLight.distanceAttenuation * ase_lightAtten_mainLight.shadowAttenuation;
				float4 temp_output_40_0_g1 = ( _MainLightColor * ase_lightAtten );
				float dotResult14_g1 = dot( normalizeResult64_g1 , SafeNormalize(_MainLightPosition.xyz) );
				float3 bakedGI34_g1 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, normalizeResult64_g1);
				float4 unityObjectToClipPos724 = TransformWorldToHClip(TransformObjectToWorld(IN.ase_texcoord7.xyz));
				float4 computeScreenPos725 = ComputeScreenPos( unityObjectToClipPos724 );
				computeScreenPos725 = computeScreenPos725 / computeScreenPos725.w;
				computeScreenPos725.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos725.z : computeScreenPos725.z* 0.5 + 0.5;
				float2 break737 = (( computeScreenPos725 / (computeScreenPos725).w )).xy;
				float3 break960 = Normal935;
				float2 appendResult745 = (float2(( break737.x + ( break960.x * _RefractionDisrt * 0.02 ) ) , ( ( break960.y * _RefractionDisrt * 0.02 ) + break737.y )));
				float2 UVDistortRelRef946 = appendResult745;
				float4 fetchOpaqueVal749 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( UVDistortRelRef946 ), 1.0 );
				float4 screenPos = IN.ase_texcoord8;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth825 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float eyeDepth = IN.ase_texcoord3.w;
				float temp_output_829_0 = ( eyeDepth825 - eyeDepth );
				float temp_output_831_0 = ( temp_output_829_0 * _DepthDensity );
				float4 appendResult832 = (float4(temp_output_831_0 , temp_output_831_0 , temp_output_831_0 , temp_output_831_0));
				float4 temp_cast_4 = (-0.1).xxxx;
				float4 temp_cast_5 = (( _DepthPower * 12.0 )).xxxx;
				float4 temp_cast_6 = (6.6).xxxx;
				float4 DepthEasyLerp940 = saturate( pow( saturate( (float4( 1,1,1,0 ) + (appendResult832 - temp_cast_4) * (float4( 0,0,0,0 ) - float4( 1,1,1,0 )) / (temp_cast_5 - temp_cast_4)) ) , temp_cast_6 ) );
				float4 lerpResult753 = lerp( _DepthColor , ( _EasyColor * fetchOpaqueVal749 * 6.0 ) , DepthEasyLerp940);
				float4 Albeodo933 = ( lerpResult753 + float4( 0,0,0,0 ) );
				float4 temp_output_42_0_g1 = Albeodo933;
				float3 lerpResult952 = lerp( float3(0,0,1) , Normal935 , _ReflNormalLerp);
				float3 worldRefl873 = reflect( -ase_worldViewDir, float3( dot( tanToWorld0, lerpResult952 ), dot( tanToWorld1, lerpResult952 ), dot( tanToWorld2, lerpResult952 ) ) );
				float4 temp_cast_8 = (0.3).xxxx;
				float fresnelNdotV757 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode757 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV757, 1.0 ) );
				float clampResult772 = clamp( log2( ( (0.0 + (fresnelNode757 - _ReflFreDistance) * (1.0 - 0.0) / (1.8 - _ReflFreDistance)) + 1.07 ) ) , 0.0 , 1.5 );
				float4 lerpResult774 = lerp( ( clampResult680 + saturate( ( ( ( float4( (temp_output_43_0_g1).rgb , 0.0 ) * (temp_output_43_0_g1).a * pow( max( dotResult19_g1 , 0.0 ) , ( _Shininess * 128.0 ) ) * temp_output_40_0_g1 ) + ( ( ( temp_output_40_0_g1 * max( dotResult14_g1 , 0.0 ) ) + float4( bakedGI34_g1 , 0.0 ) ) * float4( (temp_output_42_0_g1).rgb , 0.0 ) ) ) * _HL1Color ) ) ) , max( ( SAMPLE_TEXTURECUBE( _CubeMapRefl, sampler_CubeMapRefl, worldRefl873 ) * _ReflInstensity ) , temp_cast_8 ) , ( _ReflFreInstensity * clampResult772 ));
				float EdgeAlpha1127 = saturate( ( temp_output_829_0 * _EdgeAlpha ) );
				float Fog1121 = saturate( pow( ( distance( _WorldSpaceCameraPos , WorldPosition ) * _FogDistance ) , _FogPower ) );
				float4 lerpResult1112 = lerp( ( lerpResult774 + ( pow( ( ( 1.0 - EdgeAlpha1127 ) * EdgeAlpha1127 * _EdgeIntensity ) , _EdgePower ) * _EdgecolorAdd ) ) , _FogFarColor , Fog1121);
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = lerpResult1112.rgb;
				float Alpha = saturate( EdgeAlpha1127 );
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
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 70108
			#define REQUIRE_DEPTH_TEXTURE 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FogFarColor;
			float4 _EdgecolorAdd;
			float4 _HL2Color;
			float4 _DepthColor;
			float4 _EasyColor;
			float4 _SpeedFV4;
			float4 _HL1Color;
			float _Wave3Heigh;
			float _RefractionDisrt;
			float _DepthDensity;
			float _DepthPower;
			float _ReflNormalLerp;
			float _ReflInstensity;
			float _ReflFreInstensity;
			float _ReflFreDistance;
			float _EdgeAlpha;
			float _EdgeIntensity;
			float _EdgePower;
			float _Shininess;
			float _NormalBaseLerp;
			float _HL1Power;
			float _MaxHeightLight2;
			float _Wava3Direction;
			float _Wave3Spped;
			float _Wave3Times;
			float _Wave2Heigh;
			float _Wava2Direction;
			float _Wave2Spped;
			float _Wave2Times;
			float _Wave1Height;
			float _Wave1Spped;
			float _Wava1Direction;
			float _Wave1Times;
			float _HeightMultiply;
			float _SpeedSubTime;
			float _NormalTilingV3;
			float _HL2Power;
			float _FogDistance;
			float _FogPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float2 appendResult590 = (float2(ase_worldPos.x , ase_worldPos.z));
				float cos1015 = cos( _Wava3Direction );
				float sin1015 = sin( _Wava3Direction );
				float2 rotator1015 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos1015 , -sin1015 , sin1015 , cos1015 )) + float2( 0,0 );
				float mulTime1019 = _TimeParameters.x * _Wave3Spped;
				float temp_output_1025_0 = ( _Wave3Heigh * sin( ( ( ( rotator1015 * 0.1 ) + mulTime1019 ) * TWO_PI * _Wave3Times ) ).x );
				float cos912 = cos( _Wava2Direction );
				float sin912 = sin( _Wava2Direction );
				float2 rotator912 = mul( appendResult590 - float2( 0,0.3 ) , float2x2( cos912 , -sin912 , sin912 , cos912 )) + float2( 0,0.3 );
				float mulTime919 = _TimeParameters.x * _Wave2Spped;
				float temp_output_698_0 = ( _Wave2Heigh * sin( ( ( ( rotator912 * 0.1 ) + mulTime919 ) * TWO_PI * _Wave2Times ) ).x );
				float mulTime632 = _TimeParameters.x * _Wave1Spped;
				float cos902 = cos( _Wava1Direction );
				float sin902 = sin( _Wava1Direction );
				float2 rotator902 = mul( appendResult590 - float2( 0,0 ) , float2x2( cos902 , -sin902 , sin902 , cos902 )) + float2( 0,0 );
				float temp_output_1014_0 = ( ( temp_output_1025_0 * temp_output_698_0 ) * temp_output_698_0 * ( _Wave1Height * ( -abs( sin( ( ( mulTime632 + ( rotator902 * 0.1 ) ) * TWO_PI * _Wave1Times ) ).x ) + 1.2 ) ) );
				float temp_output_926_0 = ( temp_output_1025_0 + temp_output_698_0 + temp_output_1014_0 );
				float HeightOffset899 = temp_output_926_0;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz));
				float eyeDepth = -objectToViewPos.z;
				o.ase_texcoord3.x = eyeDepth;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( HeightOffset899 + 0.0 ) * (normalizedWorldNormal).xzy * _HeightMultiply );
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

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth825 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float eyeDepth = IN.ase_texcoord3.x;
				float temp_output_829_0 = ( eyeDepth825 - eyeDepth );
				float EdgeAlpha1127 = saturate( ( temp_output_829_0 * _EdgeAlpha ) );
				
				float Alpha = saturate( EdgeAlpha1127 );
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
209;469;1577;480;-1091.463;-1660.245;1.3;True;False
Node;AmplifyShaderEditor.CommentaryNode;814;-6382.584,1899.49;Inherit;False;1024.888;1287.806;3Wave-Direct;9;902;911;913;1015;912;1016;590;905;589;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;589;-6312.082,2082.211;Float;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;905;-6025.183,2859.676;Inherit;False;Property;_Wava1Direction;Wava1-Direction;32;0;Create;True;0;0;False;0;False;0.4951346;-2.19;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;590;-5975.282,2097.314;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;634;-5293.021,3007.383;Float;False;Property;_Wave1Spped;Wave1-Spped;16;0;Create;True;0;0;False;0;False;0;0.91;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;902;-5637.46,2825.214;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;911;-5638.002,2710.471;Inherit;False;Constant;_Float2;Float 2;45;0;Create;True;0;0;False;0;False;0.1;0.1;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1016;-6018.726,2334.506;Inherit;False;Property;_Wava3Direction;Wava3-Direction;35;0;Create;True;0;0;False;0;False;0.4951346;-1.9;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;632;-4997.719,3003.436;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;913;-6012.258,2552.115;Inherit;False;Property;_Wava2Direction;Wava2-Direction;33;0;Create;True;0;0;False;0;False;0.4951346;-1.55;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;813;-4919.705,1955.96;Inherit;False;2062.596;1158.792;SinWave;28;1023;924;643;644;1012;1011;1013;1010;640;639;636;1025;698;1026;697;921;1024;1021;922;918;1022;923;1020;919;1019;635;637;638;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;633;-4998.091,2832.078;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;912;-5630.309,2458.118;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0.3;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TauNode;637;-4462.833,2756.86;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;1015;-5638.384,2119.642;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;638;-4480.589,2902.344;Float;False;Property;_Wave1Times;Wave1-Times;19;0;Create;True;0;0;False;0;False;1;0.044;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;920;-5257.789,2593.737;Float;False;Property;_Wave2Spped;Wave2-Spped;17;0;Create;True;0;0;False;0;False;0;0.44;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1018;-5248.426,2285.852;Float;False;Property;_Wave3Spped;Wave3-Spped;18;0;Create;True;0;0;False;0;False;0;0.83;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;635;-4685.421,2801.578;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;1019;-4896.498,2278.716;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;917;-4989.888,2457.196;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1017;-5048.857,2121.485;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;919;-4910.387,2598.353;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;636;-4150.136,2764.711;Inherit;False;3;3;0;FLOAT2;1,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1020;-4658.646,2122.311;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;918;-4664.01,2457.796;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;1022;-4459.371,2184.738;Float;False;Property;_Wave3Times;Wave3-Times;21;0;Create;True;0;0;False;0;False;1;0.573;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;639;-3968.442,2768.457;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;923;-4469.428,2523.723;Float;False;Property;_Wave2Times;Wave2-Times;20;0;Create;True;0;0;False;0;False;1;0.457;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;922;-4155.361,2459.679;Inherit;False;3;3;0;FLOAT2;1,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1021;-4138.45,2119.746;Inherit;False;3;3;0;FLOAT2;1,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;640;-3735.399,2770.911;Inherit;True;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SinOpNode;1024;-3954.611,2118.94;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;1010;-3468.589,2837.233;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;921;-3968.581,2457.136;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;1011;-3317.999,2837.231;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1013;-3466.813,2913.646;Inherit;False;Constant;_Float7;Float 7;38;0;Create;True;0;0;False;0;False;1.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;697;-3469.163,2378.635;Float;False;Property;_Wave2Heigh;Wave2-Heigh;23;0;Create;True;0;0;False;0;False;1;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1026;-3458.464,2084.812;Float;False;Property;_Wave3Heigh;Wave3-Heigh;24;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;924;-3731.88,2457.233;Inherit;True;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;1023;-3733.666,2118.356;Inherit;True;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;1012;-3176.334,2835.964;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;698;-3113.905,2426.341;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;644;-3429.663,2733.347;Float;False;Property;_Wave1Height;Wave1-Height;22;0;Create;True;0;0;False;0;False;1;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1025;-3071.343,2094.573;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;942;-5836.505,3231.383;Inherit;False;1020.665;605.2625;DepthCal;10;1127;1126;1124;1125;842;832;831;829;825;827;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1039;-2772.226,2202.986;Inherit;False;1209.243;701.9148;Height-And-3S-cal;9;696;899;926;1032;1001;1029;1031;1030;1014;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;643;-3033.314,2737.808;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;825;-5711.159,3278.215;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1032;-2728.47,2348.927;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;827;-5758.667,3359.434;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1125;-5762.008,3641.897;Float;False;Property;_EdgeAlpha;Edge-Alpha;7;0;Create;True;0;0;False;0;False;0.1;1.5;0.02;1.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;829;-5441.774,3296.895;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1014;-2533.358,2526.872;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;926;-2329.37,2438.02;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1124;-5377.106,3616.597;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;899;-1914.935,2432.85;Inherit;False;HeightOffset;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;238;848.7667,2103.954;Inherit;False;773.049;506.8568;Height-Offset;7;231;235;476;234;475;900;1033;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;1126;-5207.931,3615.113;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;900;882.2971,2175.787;Inherit;False;899;HeightOffset;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1127;-5033.931,3612.113;Inherit;False;EdgeAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;475;865.4776,2278.576;Float;False;Constant;_HeiOffset;Hei-Offset;26;0;Create;True;0;0;False;0;False;0;0;-5;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;234;870.0997,2360.431;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;711;-5822.521,4667.123;Inherit;False;2972.258;804.5745;Screen-Distrot-NorlmalUV;17;946;745;743;742;737;735;739;734;732;855;960;730;959;727;725;724;723;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;811;-3962.28,1247.061;Inherit;False;2869.688;665.6758;SmoothPBR;10;619;699;694;641;625;614;626;622;580;613;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;931;2241.816,2211.792;Inherit;False;1127;EdgeAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;812;-981.0502,987.2311;Inherit;False;1678.451;788.6122;PBR+Specular;18;1099;680;1098;1063;1090;652;1034;1037;692;674;689;936;1035;1094;1062;673;1095;1003;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;810;-3987.246,192.4341;Inherit;False;2358.184;1005.532;Normal;10;683;648;650;684;646;645;647;627;649;935;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;718;-975.5645,1809.862;Inherit;False;1656.872;549.5181;Ref;9;876;871;877;873;952;950;953;951;1150;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1118;-1079.414,-444.9099;Inherit;False;1729.435;580.8323;Comment;13;1081;1093;1092;1083;1077;1087;1085;1079;1080;1096;1097;1076;1086;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;235;866.2927,2510.119;Float;False;Property;_HeightMultiply;Height-Multiply;13;0;Create;True;0;0;False;0;False;1;0.3;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;714;-2573.017,4633.54;Inherit;False;1405.18;654.2784;Refaction-Screen-Distrot;10;749;747;1141;750;752;947;758;933;941;753;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1135;899.2421,1205.932;Inherit;False;997.75;468.1432;Comment;8;1137;1131;1133;1139;1138;1132;1134;1128;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;815;-5620.968,953.6873;Inherit;False;1317.856;773.9802;SubWaveSpeed-Tiling;16;602;623;599;624;611;601;600;598;610;617;597;594;618;609;596;1100;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;846;-4599.228,3274.791;Inherit;False;1755.744;420.1818;DepthCal;10;940;844;837;838;839;840;836;833;835;843;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;716;-968.4897,2435.393;Inherit;False;1655.12;534.3736;FView-For-Mirror;9;957;954;817;765;772;955;766;757;754;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;476;1235.732,2236.651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;1120;779.004,2864.139;Inherit;False;1567.363;403.3486;Comment;9;1123;1105;1104;1107;1116;1106;1121;1108;1115;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SwizzleNode;1033;1098.584,2372.172;Inherit;False;FLOAT3;0;2;1;3;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;941;-2056.389,4989.901;Inherit;False;940;DepthEasyLerp;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleTimeNode;617;-4881.032,1206.705;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;727;-4951.759,4820.532;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;580;-3847.82,1304.427;Inherit;True;Property;_HeightMap;HeightMap;12;0;Create;True;0;0;False;0;False;-1;None;e34cef78845b62b46b301f2837dc7cad;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;231;1357.817,2335.952;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;774;907.0568,1827.371;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;863;2044.796,1800.9;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;1079;-695.8005,-145.6098;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;694;-1656.792,1413.537;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.1;False;3;FLOAT;0.5;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1088;681.2977,-233.6123;Inherit;False;HeightLightL2;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;959;-4612.986,5033.671;Inherit;False;935;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;753;-1814.988,4840.507;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;598;-5016.32,1273.812;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;649;-3764.869,981.581;Float;False;Constant;_2DetailLerp;2DetailLerp;27;0;Create;True;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1116;1481.485,3137.487;Inherit;False;Property;_FogPower;Fog-Power;45;0;Create;True;0;0;False;0;False;1;2.49;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;699;-1840.332,1414.12;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1035;-414.6737,1587.719;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1062;-225.4771,1183.901;Inherit;False;Blinn-Phong Light;0;;1;cf814dba44d007a4e958d2ddd5813da6;0;3;42;COLOR;0,0,0,0;False;52;FLOAT3;0,0,0;False;43;COLOR;0,0,0,0;False;2;COLOR;0;FLOAT;57
Node;AmplifyShaderEditor.ColorNode;1095;-244.2179,1331.573;Inherit;False;Property;_HL1Color;HL1-Color;36;0;Create;True;0;0;False;0;False;1,1,1,0;0.4105107,0.6619469,0.7075471,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;602;-4608.574,1267.369;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;0.015;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;735;-3949.922,5207.954;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;936;-955.7318,1474.502;Inherit;False;935;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;683;-2775.58,674.8274;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;1037;-250.0739,1599.719;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;641;-1393.672,1400.826;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;732;-4410.964,4730.523;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;833;-4198.048,3418.39;Float;False;Constant;_Float12;Float 12;22;0;Create;True;0;0;False;0;False;-0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1031;-2334.867,2587.309;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;647;-3775.852,766.1387;Inherit;True;Property;_TextureSample12;Texture Sample 12;9;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;645;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;645;-3782.032,370.549;Inherit;True;Property;_NormalMap;NormalMap;9;0;Create;True;0;0;False;0;False;-1;None;5acca8437bb81d54187a16eceab88d9d;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;1083;64.00928,-235.4485;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;673;-618.1871,1357.02;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;947;-2564.355,5109.243;Inherit;False;946;UVDistortRelRef;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;730;-4666.307,4735.609;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1099;451.5148,1305.235;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;950;-949.7065,1867.499;Float;False;Constant;_Vector0;Vector 0;19;0;Create;True;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PowerNode;837;-3457.177,3494.474;Inherit;False;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;1040;-1040.197,1234.414;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;742;-3613.309,4735.272;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;625;-3230.589,1570.072;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;1097;172.6892,-76.07764;Inherit;False;Property;_HL2Color;HL2-Color;37;1;[HDR];Create;True;0;0;False;0;False;1,1,1,0;3.856295,1.790614,0.868171,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;1076;-916.8572,-340.6937;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;723;-5586.943,4736.875;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;1112;2267.654,2006.677;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1107;1163.754,3079.034;Inherit;False;Property;_FogDistance;Fog-Distance;44;0;Create;True;0;0;False;0;False;0.023;0.018;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;1138;1569.177,1301.153;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;960;-4399.993,5036.657;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;842;-5753.296,3447.135;Float;False;Property;_DepthDensity;Depth-Density;8;0;Create;True;0;0;False;0;False;0.1;0.23;0.02;1.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1003;-552.9603,1123.773;Inherit;False;933;Albeodo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;613;-3841.756,1517.774;Inherit;True;Property;_HeightMap2;HeightMap2;12;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;580;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;1136;2460.193,2228.667;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;596;-5512.958,1261.793;Float;False;Constant;_F1;F1;36;0;Create;True;0;0;False;0;False;0.0066;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1131;1169.955,1255.932;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;946;-3142.661,4728.856;Inherit;False;UVDistortRelRef;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;752;-2043.326,4861.192;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PannerNode;601;-4605.072,1097.889;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;0.015;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;1122;1873.226,2147.347;Inherit;False;1121;Fog;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;758;-1627.396,4839.254;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1132;1368.89,1306.198;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;725;-5179.216,4736.04;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;1139;1290.255,1435.337;Inherit;False;Property;_EdgePower;EdgePower;43;0;Create;True;0;0;False;0;False;3;6.82;1;12;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;734;-4439.64,5166.33;Float;False;Property;_RefractionDisrt;Refraction-Disrt;31;0;Create;True;0;0;False;0;False;3;4;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;597;-5512.196,1337.283;Float;False;Constant;_F2;F2;19;0;Create;True;0;0;False;0;False;0.77;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;832;-5061.985,3380.34;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;877;118.2524,2231.049;Inherit;False;Property;_ReflInstensity;Refl-Instensity;27;0;Create;True;0;0;False;0;False;2;0.71;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;724;-5370.097,4735.966;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;600;-5512.662,1409.117;Float;False;Constant;_F2V;F2V;20;0;Create;True;0;0;False;0;False;-0.33,0.66;0.75,-0.84;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;1123;1955.647,3008.29;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;754;-929.9293,2763.896;Float;False;Property;_ReflFreDistance;Refl-Fre-Distance;30;0;Create;True;0;0;False;0;False;0.4;0.898;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1001;-1915.911,2590.069;Inherit;False;Wave3S;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;955;-633.1768,2827.927;Inherit;False;Constant;_Float0;Float 0;36;0;Create;True;0;0;False;0;False;1.07;1.07;-0.4;1.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;675;-1030.34,1565.83;Float;False;Property;_NormalBaseLerp;Normal-BaseLerp;11;0;Create;True;0;0;False;0;False;0;0.43;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;739;-3941.04,4983.038;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;1105;829.004,2914.139;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;594;-5198.285,1091.718;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;1150;436.7424,2143.66;Inherit;False;Constant;_Float9;Float 9;45;0;Create;True;0;0;False;0;False;0.3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;1104;831.835,3064.484;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FresnelNode;757;-930.6741,2525.864;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;1134;1085.248,1487.495;Inherit;False;Property;_EdgecolorAdd;EdgecolorAdd;42;0;Create;True;0;0;False;0;False;0,0,0,0;0.3083831,0.6430483,0.8490566,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldReflectionVector;873;-417.2715,1900.703;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;737;-4152.457,4735.478;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;817;380.7934,2684.102;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;838;-3636.794,3360.958;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;954;-241.2694,2703.653;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;1149;620.7424,2035.66;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;871;-141.9209,1871.212;Inherit;True;Property;_CubeMapRefl;Cube-Map-Refl;26;0;Create;True;0;0;False;0;False;-1;None;bd9f7bd3514558b4584ee46a996f06e7;True;0;False;white;Auto;False;Object;-1;Auto;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;747;-2521.045,4853.904;Float;False;Property;_EasyColor;Easy-Color;4;1;[HDR];Create;True;0;0;False;0;False;0,1,0.7931035,0;0,0.4056604,0.1559671,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1108;1556.931,2983.49;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1141;-2285.205,4938.025;Inherit;False;Constant;_Float3;Float 3;43;0;Create;True;0;0;False;0;False;6;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;766;-605.7509,2612.767;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.8;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1077;-480.7587,-182.5053;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;1093;-1029.414,-182.119;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;674;-941.9922,1322.649;Float;False;Constant;_VUp;VUp;19;0;Create;True;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;614;-3449.125,1439.724;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1029;-2154.877,2593.536;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;844;-3283.202,3494.393;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1030;-2358.48,2674.133;Inherit;False;Constant;_Float4;Float 4;43;0;Create;True;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;772;130.1258,2771.903;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;876;477.8335,1938.056;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;610;-5120.247,1503.723;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;1086;238.1093,-228.2485;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;1115;1797.367,2985.948;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;840;-3938.533,3360.686;Inherit;True;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;3;COLOR;1,1,1,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1094;11.05101,1276.274;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;935;-2536.805,668.8222;Inherit;False;Normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;1063;-25.1913,1110.898;Inherit;False;Property;_MaxHeightLight2;MaxHeightLight2;34;0;Create;True;0;0;False;0;False;1.545907;2;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1098;170.9124,1278.608;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;1081;-607.0005,-394.9099;Inherit;False;935;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Log2OpNode;957;-91.70074,2706.557;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;680;285.3041,1058.646;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;855;-4332.36,5250.319;Float;False;Constant;_Float1;Float 1;39;0;Create;True;0;0;False;0;False;0.02;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1096;471.6892,-228.0776;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;627;-3767.143,1069.222;Float;False;Constant;_L3WaveHeight;L3WaveHeight;27;0;Create;True;0;0;False;0;False;0.8;0.8;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;626;-3441.644,1665.403;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;609;-5515.448,1527.633;Float;False;Property;_SpeedFV4;SpeedFV4;14;0;Create;True;0;0;False;0;False;1,0.5,-1,-0.5;2,-1,-1,1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;843;-4492.536,3484.743;Float;False;Property;_DepthPower;Depth-Power;6;0;Create;True;0;0;False;0;False;0.5647059;1.2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1087;-85.99072,-136.4485;Inherit;False;Property;_HL2Power;HL2-Power;39;0;Create;True;0;0;False;0;False;12;544;1;600;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;618;-5514.53,1180.786;Float;False;Property;_SpeedSubTime;Speed-SubTime;15;0;Create;True;0;0;False;0;False;0.01;0.0385;0;0.2;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;1092;-425.7877,-352.1407;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1137;1750.507,1465.848;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;953;-955.2184,2089.58;Float;False;Property;_ReflNormalLerp;Refl-Normal-Lerp;28;0;Create;True;0;0;False;0;False;0;0.138;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;745;-3373.93,4737.272;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;611;-5121.594,1599.689;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;624;-4758.818,1458.178;Float;False;Constant;_L3Scale;L3-Scale;40;0;Create;True;0;0;False;0;False;0.25;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1100;-5536.042,1044.658;Inherit;False;Property;_NormalTilingV3;Normal-TilingV3;10;0;Create;True;0;0;False;0;False;4.282549;12;1;12;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;1080;-294.8005,-185.6098;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1034;-715.0425,1639.174;Inherit;False;1001;Wave3S;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;646;-3771.841,573.2537;Inherit;True;Property;_TextureSample11;Texture Sample 11;9;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;645;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1133;951.2421,1382.344;Inherit;False;Property;_EdgeIntensity;EdgeIntensity;41;0;Create;True;0;0;False;0;False;0;3;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1128;952.3449,1264.522;Inherit;False;1127;EdgeAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;689;-671.4858,1531.918;Float;False;Property;_PBRSmooth1;PBRSmooth1;25;0;Create;True;0;0;False;0;False;0;1.69;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;650;-3200.119,809.3453;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;839;-3665.523,3583.744;Float;False;Constant;_Float15;Float 15;16;0;Create;True;0;0;False;0;False;6.6;6.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1090;49.86284,1011.832;Inherit;False;1088;HeightLightL2;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;940;-3103.864,3489.6;Inherit;False;DepthEasyLerp;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;652;-928.3932,1246.172;Float;False;Property;_HL1Power;HL1-Power;38;0;Create;True;0;0;False;0;False;0;0.61;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;951;-951.4462,2010.826;Inherit;False;935;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;623;-4430.461,1439.386;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;599;-4854.772,1274.876;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;692;-498.8575,1221.998;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;749;-2297.545,5109.592;Float;False;Global;_GrabScreen1;Grab Screen 1;23;0;Create;True;0;0;False;0;False;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;933;-1479.712,4834.345;Inherit;False;Albeodo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;765;63.19043,2630.157;Float;False;Property;_ReflFreInstensity;Refl-Fre-Instensity;29;0;Create;True;0;0;False;0;False;0.8;0.97;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;1085;-112.9907,-248.4485;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;696;-2137.508,2285.027;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;3;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;835;-4491.438,3563.873;Float;False;Constant;_F12;F12;0;0;Create;True;0;0;False;0;False;12;12;0;12;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;750;-2519.238,4681.121;Float;False;Property;_DepthColor;Depth-Color;5;0;Create;True;0;0;False;0;False;0.3157439,0.3965517,0.5882353,0;0.6092026,0.6714857,0.6981132,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;622;-3832.519,1690.462;Inherit;True;Property;_TextureSample10;Texture Sample 10;12;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;580;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;1121;2137.979,2983.921;Inherit;False;Fog;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;836;-4179.443,3508.091;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;831;-5248.592,3424.377;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;743;-3623.233,4937.253;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;684;-3153.33,1024.613;Float;False;Constant;_SFloat1;SFloat 1;52;0;Create;True;0;0;False;0;False;0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;619;-3027.605,1412.779;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;1106;1177.212,2933.465;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;952;-641.1539,1950.921;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;1113;1866.741,1958.404;Inherit;False;Property;_FogFarColor;Fog-FarColor;40;0;Create;True;0;0;False;0;False;0.6763083,0.9165702,0.9622641,0;0.6763083,0.9165702,0.9622641,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;648;-3230.037,589.4342;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1075;2238.891,1854.891;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1071;2238.891,1854.891;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1074;2238.891,1854.891;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1073;2238.891,1854.891;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1072;2638.683,2033.89;Float;False;True;-1;2;ASEMaterialInspector;0;3;Good/Water/Water-A;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;0;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;True;False;False;;True;0
WireConnection;590;0;589;1
WireConnection;590;1;589;3
WireConnection;902;0;590;0
WireConnection;902;2;905;0
WireConnection;632;0;634;0
WireConnection;633;0;902;0
WireConnection;633;1;911;0
WireConnection;912;0;590;0
WireConnection;912;2;913;0
WireConnection;1015;0;590;0
WireConnection;1015;2;1016;0
WireConnection;635;0;632;0
WireConnection;635;1;633;0
WireConnection;1019;0;1018;0
WireConnection;917;0;912;0
WireConnection;917;1;911;0
WireConnection;1017;0;1015;0
WireConnection;1017;1;911;0
WireConnection;919;0;920;0
WireConnection;636;0;635;0
WireConnection;636;1;637;0
WireConnection;636;2;638;0
WireConnection;1020;0;1017;0
WireConnection;1020;1;1019;0
WireConnection;918;0;917;0
WireConnection;918;1;919;0
WireConnection;639;0;636;0
WireConnection;922;0;918;0
WireConnection;922;1;637;0
WireConnection;922;2;923;0
WireConnection;1021;0;1020;0
WireConnection;1021;1;637;0
WireConnection;1021;2;1022;0
WireConnection;640;0;639;0
WireConnection;1024;0;1021;0
WireConnection;1010;0;640;0
WireConnection;921;0;922;0
WireConnection;1011;0;1010;0
WireConnection;924;0;921;0
WireConnection;1023;0;1024;0
WireConnection;1012;0;1011;0
WireConnection;1012;1;1013;0
WireConnection;698;0;697;0
WireConnection;698;1;924;0
WireConnection;1025;0;1026;0
WireConnection;1025;1;1023;0
WireConnection;643;0;644;0
WireConnection;643;1;1012;0
WireConnection;1032;0;1025;0
WireConnection;1032;1;698;0
WireConnection;829;0;825;0
WireConnection;829;1;827;0
WireConnection;1014;0;1032;0
WireConnection;1014;1;698;0
WireConnection;1014;2;643;0
WireConnection;926;0;1025;0
WireConnection;926;1;698;0
WireConnection;926;2;1014;0
WireConnection;1124;0;829;0
WireConnection;1124;1;1125;0
WireConnection;899;0;926;0
WireConnection;1126;0;1124;0
WireConnection;1127;0;1126;0
WireConnection;476;0;900;0
WireConnection;476;1;475;0
WireConnection;1033;0;234;0
WireConnection;617;0;618;0
WireConnection;727;0;725;0
WireConnection;580;1;601;0
WireConnection;231;0;476;0
WireConnection;231;1;1033;0
WireConnection;231;2;235;0
WireConnection;774;0;1099;0
WireConnection;774;1;1149;0
WireConnection;774;2;817;0
WireConnection;863;0;774;0
WireConnection;863;1;1137;0
WireConnection;1079;0;1093;0
WireConnection;694;0;699;0
WireConnection;1088;0;1096;0
WireConnection;753;0;750;0
WireConnection;753;1;752;0
WireConnection;753;2;941;0
WireConnection;598;0;594;0
WireConnection;598;1;597;0
WireConnection;699;0;619;0
WireConnection;699;1;696;0
WireConnection;1035;0;689;0
WireConnection;1035;1;1034;0
WireConnection;1062;42;1003;0
WireConnection;1062;52;673;0
WireConnection;1062;43;692;0
WireConnection;602;0;599;0
WireConnection;602;2;611;0
WireConnection;602;1;617;0
WireConnection;735;0;960;1
WireConnection;735;1;734;0
WireConnection;735;2;855;0
WireConnection;683;0;648;0
WireConnection;683;1;650;0
WireConnection;683;2;684;0
WireConnection;1037;0;1035;0
WireConnection;641;0;694;0
WireConnection;732;0;730;0
WireConnection;1031;0;1014;0
WireConnection;647;1;623;0
WireConnection;645;1;601;0
WireConnection;1083;0;1085;0
WireConnection;673;0;674;0
WireConnection;673;1;936;0
WireConnection;673;2;675;0
WireConnection;730;0;725;0
WireConnection;730;1;727;0
WireConnection;1099;0;680;0
WireConnection;1099;1;1098;0
WireConnection;837;0;838;0
WireConnection;837;1;839;0
WireConnection;1040;0;641;0
WireConnection;742;0;737;0
WireConnection;742;1;739;0
WireConnection;625;0;614;0
WireConnection;625;1;626;0
WireConnection;1112;0;863;0
WireConnection;1112;1;1113;0
WireConnection;1112;2;1122;0
WireConnection;1138;0;1132;0
WireConnection;1138;1;1139;0
WireConnection;960;0;959;0
WireConnection;613;1;602;0
WireConnection;1136;0;931;0
WireConnection;1131;0;1128;0
WireConnection;946;0;745;0
WireConnection;752;0;747;0
WireConnection;752;1;749;0
WireConnection;752;2;1141;0
WireConnection;601;0;594;0
WireConnection;601;2;610;0
WireConnection;601;1;617;0
WireConnection;758;0;753;0
WireConnection;1132;0;1131;0
WireConnection;1132;1;1128;0
WireConnection;1132;2;1133;0
WireConnection;725;0;724;0
WireConnection;832;0;831;0
WireConnection;832;1;831;0
WireConnection;832;2;831;0
WireConnection;832;3;831;0
WireConnection;724;0;723;0
WireConnection;1123;0;1115;0
WireConnection;1001;0;1029;0
WireConnection;739;0;960;0
WireConnection;739;1;734;0
WireConnection;739;2;855;0
WireConnection;594;0;902;0
WireConnection;594;1;1100;0
WireConnection;594;2;596;0
WireConnection;873;0;952;0
WireConnection;737;0;732;0
WireConnection;817;0;765;0
WireConnection;817;1;772;0
WireConnection;838;0;840;0
WireConnection;954;0;766;0
WireConnection;954;1;955;0
WireConnection;1149;0;876;0
WireConnection;1149;1;1150;0
WireConnection;871;1;873;0
WireConnection;1108;0;1106;0
WireConnection;1108;1;1107;0
WireConnection;766;0;757;0
WireConnection;766;1;754;0
WireConnection;1077;0;1076;0
WireConnection;1077;1;1079;0
WireConnection;614;0;580;1
WireConnection;614;1;613;1
WireConnection;614;2;649;0
WireConnection;1029;0;1031;0
WireConnection;1029;1;1030;0
WireConnection;844;0;837;0
WireConnection;772;0;957;0
WireConnection;876;0;871;0
WireConnection;876;1;877;0
WireConnection;610;0;609;1
WireConnection;610;1;609;2
WireConnection;1086;0;1083;0
WireConnection;1086;1;1087;0
WireConnection;1115;0;1108;0
WireConnection;1115;1;1116;0
WireConnection;840;0;832;0
WireConnection;840;1;833;0
WireConnection;840;2;836;0
WireConnection;1094;0;1062;0
WireConnection;1094;1;1095;0
WireConnection;935;0;683;0
WireConnection;1098;0;1094;0
WireConnection;957;0;954;0
WireConnection;680;0;1090;0
WireConnection;680;2;1063;0
WireConnection;1096;0;1086;0
WireConnection;1096;1;1097;0
WireConnection;626;0;622;1
WireConnection;626;1;627;0
WireConnection;1092;0;1081;0
WireConnection;1137;0;1138;0
WireConnection;1137;1;1134;0
WireConnection;745;0;742;0
WireConnection;745;1;743;0
WireConnection;611;0;609;3
WireConnection;611;1;609;4
WireConnection;1080;0;1077;0
WireConnection;646;1;602;0
WireConnection;650;0;647;0
WireConnection;650;1;627;0
WireConnection;940;0;844;0
WireConnection;623;0;601;0
WireConnection;623;1;624;0
WireConnection;599;0;598;0
WireConnection;599;1;600;0
WireConnection;692;0;1040;0
WireConnection;692;1;652;0
WireConnection;749;0;947;0
WireConnection;933;0;758;0
WireConnection;1085;0;1092;0
WireConnection;1085;1;1080;0
WireConnection;696;0;926;0
WireConnection;622;1;623;0
WireConnection;1121;0;1123;0
WireConnection;836;0;843;0
WireConnection;836;1;835;0
WireConnection;831;0;829;0
WireConnection;831;1;842;0
WireConnection;743;0;735;0
WireConnection;743;1;737;1
WireConnection;619;0;580;1
WireConnection;619;1;613;1
WireConnection;619;2;625;0
WireConnection;1106;0;1105;0
WireConnection;1106;1;1104;0
WireConnection;952;0;950;0
WireConnection;952;1;951;0
WireConnection;952;2;953;0
WireConnection;648;0;645;0
WireConnection;648;1;646;0
WireConnection;648;2;649;0
WireConnection;1072;2;1112;0
WireConnection;1072;3;1136;0
WireConnection;1072;5;231;0
ASEEND*/
//CHKSM=274F2BF4C333D7C65507497FCFB0F26652C6BF66