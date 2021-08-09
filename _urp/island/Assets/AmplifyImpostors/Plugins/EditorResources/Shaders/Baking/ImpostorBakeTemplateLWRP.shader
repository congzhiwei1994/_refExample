Shader /*ase_name*/ "Hidden/Impostors/Bake/LightWeight"/*end*/
{
	Properties
    {
		/*ase_props*/
    }

    SubShader
    {
		/*ase_subshader_options:Name=Additional Options
			Option:Receive Shadows:false,true:true
				true:RemoveDefine:_RECEIVE_SHADOWS_OFF 1
				false:SetDefine:_RECEIVE_SHADOWS_OFF 1
		*/

        Tags{ "RenderPipeline" = "LightweightPipeline" "RenderType"="Opaque" "Queue"="Geometry"}
        Cull Back
		HLSLINCLUDE
		#pragma target 3.0
		ENDHLSL

		/*ase_pass*/
        Pass
        {
            Tags{"LightMode" = "LightweightForward"}
            Name "Base"

            Blend One Zero
			ZWrite On
			ZTest LEqual
			Offset 0,0
			ColorMask RGBA
			/*ase_stencil*/

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma shader_feature _SAMPLE_GI

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #pragma vertex vert
            #pragma fragment frag

            /*ase_pragma*/

            // Lighting include is needed because of GI
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/ShaderGraphFunctions.hlsl"
            //#include "Packages/com.unity.render-pipelines.lightweight/Shaders/UnlitInput.hlsl"

			/*ase_globals*/

            struct GraphVertexInput
            {
                float4 vertex : POSITION;
				float4 ase_normal : NORMAL;
				/*ase_vdata:p=p;n=n*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct GraphVertexOutput
            {
                float4 position : POSITION;
				/*ase_interp(0,):sp=sp*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

			/*ase_funcs*/

            GraphVertexOutput vert (GraphVertexInput v/*ase_vert_input*/)
            {
                GraphVertexOutput o = (GraphVertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				/*ase_vert_code:v=GraphVertexInput;o=GraphVertexOutput*/
				v.vertex.xyz += /*ase_vert_out:Vertex Offset;Float3*/ float3( 0, 0, 0 ) /*end*/;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

			void frag( GraphVertexOutput IN /*ase_frag_input*/,
				out half4 outGBuffer0 : SV_Target0,
				out half4 outGBuffer1 : SV_Target1,
				out half4 outGBuffer2 : SV_Target2,
				out half4 outGBuffer3 : SV_Target3,
				out half4 outGBuffer4 : SV_Target4,
				out half4 outGBuffer5 : SV_Target5,
				out half4 outGBuffer6 : SV_Target6,
				out half4 outGBuffer7 : SV_Target7,
				out float outDepth : SV_Depth
			)
            {
				UNITY_SETUP_INSTANCE_ID( IN );
				/*ase_frag_code:IN=GraphVertexOutput*/

				outGBuffer0 = /*ase_frag_out:Output RT 0;Float4*/0/*end*/;
				outGBuffer1 = /*ase_frag_out:Output RT 1;Float4*/0/*end*/;
				outGBuffer2 = /*ase_frag_out:Output RT 2;Float4*/0/*end*/;
				outGBuffer3 = /*ase_frag_out:Output RT 3;Float4*/0/*end*/;
				outGBuffer4 = /*ase_frag_out:Output RT 4;Float4*/0/*end*/;
				outGBuffer5 = /*ase_frag_out:Output RT 5;Float4*/0/*end*/;
				outGBuffer6 = /*ase_frag_out:Output RT 6;Float4*/0/*end*/;
				outGBuffer7 = /*ase_frag_out:Output RT 7;Float4*/0/*end*/;
				float alpha = /*ase_frag_out:Clip;Float*/1/*end*/;
				#if _AlphaClip
					clip( alpha );
				#endif
				outDepth = IN.position.z;
            }
            ENDHLSL
        }
	}
}
