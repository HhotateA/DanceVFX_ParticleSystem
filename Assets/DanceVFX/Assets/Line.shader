// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HOTATE/DanceVFX/Particle/Line"
{
	Properties
	{
		_MemoryTex ("Memory Texture", 2D) = "white" {}
		[HDR]_ParticleCol ("Particle Col", Color) = (1,1,1,1)
		_Center ("Center", Vector) = (0,0,0,0)
		_ParticleMul ("Position Mul", Vector) = (1,1,1,1)
		_ParticleOffset ("Particle Offset", Vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags { "Queue"="Transparent+500" }

		CGINCLUDE
			#include "UnityCG.cginc"

			sampler2D _MemoryTex;
			float4 _ParticleCol;
			float4 _Center;
			float4 _ParticleMul;
			float4 _ParticleOffset;

			struct particleData{
				float4 pos; // Particle Position
				float4 col; // Particle Color
				float4 vec; // Particle Velocity
				float4 uvl; // UV&Lifetime
			};

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				particleData pData : PARTICLE_DATA;
			};
			
			appdata vert (appdata v)
			{
				return v;
			}

			#define PARTICLE_POSITION(pData,uv)\
				particleData pData;\
				float2 sampleruv = frac(uv*2.0)*0.5;\
				pData.pos = mul(UNITY_MATRIX_M,float4(0,0,0,1));\
				{\
					float3 posBuf = tex2Dlod(_MemoryTex,float4(sampleruv,0,0)).xyz;\
					if(max(posBuf.x,max(posBuf.y,posBuf.z))<0.01) return;\
					pData.pos.xyz += posBuf * _ParticleMul + _ParticleOffset;\
				}\
				pData.col = tex2Dlod(_MemoryTex,float4(sampleruv+float2(1.0/2.0,0.0/2.0),0,0));\
				pData.vec = tex2Dlod(_MemoryTex,float4(sampleruv+float2(0.0/2.0,1.0/2.0),0,0));\
				pData.uvl = tex2Dlod(_MemoryTex,float4(sampleruv+float2(1.0/2.0,1.0/2.0),0,0));\

			[maxvertexcount(2)]
			void geom(point appdata v[1], inout LineStream<v2f> outStream)
			{
				v2f o;
				float2 uv = v[0].uv;
				PARTICLE_POSITION(pData,uv); // pData.posにパーティクルのワールド座標が入る
				o.pData = pData;
				o.vertex = mul(UNITY_MATRIX_VP,pData.pos);
				outStream.Append(o);

				o.vertex = UnityObjectToClipPos(_Center);
				outStream.Append(o);
				
                outStream.RestartStrip();

			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _ParticleCol*i.pData.col;
			}
		ENDCG

		Pass
		{
			Blend One One
			ZWrite Off
			Cull Off
			ColorMask RGB
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			ENDCG
		}

		Pass
		{
			Blend One One
			ZWrite On
			Cull Off
			ColorMask 0
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			ENDCG
		}
	}
}
