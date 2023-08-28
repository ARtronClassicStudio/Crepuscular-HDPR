
Shader "Hidden/Crepuscular" 
{
	Properties { [HideInInspector] _MainTex("Main Texture",2DArray) = "white" {}}

	SubShader
	{
		Tags{ "RenderPipeline" = "HDRenderPipeline" }
		Pass
		{
			Name "Crepuscular"

			ZWrite Off
			ZTest Always
			Blend Off
			Cull Off

			HLSLPROGRAM
				#pragma fragment CustomPostProcess
				#pragma vertex Vert
			ENDHLSL
		}

		Pass
		{
			HLSLINCLUDE
			#pragma target 4.5
			#pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

			TEXTURE2D_X(_MainTex);
			SAMPLER(sampler_MainTex);
			float3 _LightPos;
			float _NumSamples;
			float _Density;
			float _Weight;
			float _Decay;
			float _Exposure;
			float _IlluminationDecay;
			float4 _ColorRay;

			struct Attributes
			{
				uint vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
			 	float4 positionCS : SV_POSITION;
				float2 uv   : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings Vert(Attributes input)
			{
				Varyings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
				output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
				return output;
			}

			float4 CustomPostProcess(Varyings i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				float2 deltaTexCoord = (i.uv - _LightPos.xy) * (_LightPos.z < 0 ? -1 : 1);
				deltaTexCoord *= 1.0f / _NumSamples * _Density;
				float2 uv = i.uv;
				float3 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv).xyz;

				for (int i = 0; i < (_LightPos.z < 0 ? 0 : _NumSamples * _LightPos.z); i++)
				{
						uv -= deltaTexCoord;
						float3 sample = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv).xyz;
						sample *= _IlluminationDecay * (_Weight / _NumSamples);
						color += sample * _ColorRay.xyz;
						_IlluminationDecay *= _Decay;		
					
				}
				return float4(color * _Exposure, 1);
			}
			ENDHLSL
		}
	}
}
