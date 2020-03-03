// ██╗  ██╗ ██████╗ ████████╗ █████╗ ████████╗███████╗
// ██║  ██║██╔═══██╗╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
// ███████║██║   ██║   ██║   ███████║   ██║   █████╗  
// ██╔══██║██║   ██║   ██║   ██╔══██║   ██║   ██╔══╝  
// ██║  ██║╚██████╔╝   ██║   ██║  ██║   ██║   ███████╗
// ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                   
Shader "HOTATE/DanceVFX/Particle/Particle"
{
	Properties
	{
		_MemoryTex ("Memory Texture", 2D) = "white" {}
		_ParticleTex ("Particle Texture", 2D) = "white" {}
		[Space(100)]
		[HDR]_ParticleCol ("Particle Col", Color) = (1,1,1,1)
		[Space(20)]
		[HDR]_ColorOverLifetime0 ("ColorOverLifetime0", Color) = (1,1,1,1)
		[HDR]_ColorOverLifetime1 ("ColorOverLifetime1", Color) = (1,1,1,1)
		[HDR]_ColorOverLifetime2 ("ColorOverLifetime2", Color) = (1,1,1,1)
		[HDR]_ColorOverLifetime3 ("ColorOverLifetime3", Color) = (1,1,1,1)
		[Space(100)]
		_ParticleSize ("ParticleSize", Range(0,0.1)) = 0
		[Space(20)]
		_SizeOverLiferime0 ("SizeOverLifetime0", float) = 1
		_SizeOverLiferime1 ("SizeOverLifetime1", float) = 1
		_SizeOverLiferime2 ("SizeOverLifetime2", float) = 1
		_SizeOverLiferime3 ("SizeOverLifetime3", float) = 1
		[Space(100)]
		_ParticleMul ("Position Mul", Vector) = (1,1,1,1)
		_ParticleOffset ("Particle Offset", Vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags { "Queue"="Transparent+500" }

		CGINCLUDE
			#include "UnityCG.cginc"

			sampler2D _MemoryTex;
			sampler2D _ParticleTex;
			float4 _ParticleCol;
			float _ParticleSize;
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
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				particleData pData : PARTICLE_DATA;
			};
			
			appdata vert (appdata v)
			{
				return v;
			}

			#define ADD_VERT(u,v)\
				o.uv = float2(u,v)*0.5+0.5;\
				o.vertex = mul( UNITY_MATRIX_P, position+float4(float2(u,v)*_ParticleSize*sizeOverLifetime(o.pData.uvl.z),0,0));\
				outStream.Append(o);
			
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

			//base on "https://qiita.com/_nabe/items/c8ba019f26d644db34a8"
            float3 rgb2hsv(float3 c) {
                float4 k = float4( 0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0 );
                float e = 1.0e-10;
                float4 p = lerp( float4(c.bg, k.wz), float4(c.gb, k.xy), step(c.b, c.g) );
                float4 q = lerp( float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r) );
                float d = q.x - min(q.w, q.y);
                return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x );
            }
            float3 hsv2rgb(float3 c) {
                float4 k = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
                float3 p = abs( frac(c.xxx + k.xyz) * 6.0 - k.www );
                return c.z * lerp( k.xxx, saturate(p - k.xxx), c.y );
            }

			float4 _ColorOverLifetime0, _ColorOverLifetime1, _ColorOverLifetime2, _ColorOverLifetime3;
			static float4 colorLifetime[4] = {_ColorOverLifetime0, _ColorOverLifetime1, _ColorOverLifetime2, _ColorOverLifetime3};
			float3 colorOverLifetime(float x){
				x = 1.0-x;
				int i = floor(x*3.0);
				return lerp(colorLifetime[i],colorLifetime[i+1],frac(x*3.0)).rgb;
			}

			float _SizeOverLiferime0, _SizeOverLiferime1, _SizeOverLiferime2, _SizeOverLiferime3;
			static float sizeLifetime[4] = {_SizeOverLiferime0, _SizeOverLiferime1, _SizeOverLiferime2, _SizeOverLiferime3};
			float sizeOverLifetime(float x){
				x = 1.0-x;
				int i = floor(x*3.0);
				return lerp(sizeLifetime[i],sizeLifetime[i+1],frac(x*3.0));
			}

			// ==========================================================================
			// Geometry Block
			// ==========================================================================
			[maxvertexcount(4)]
			void geom(point appdata v[1], inout TriangleStream<v2f> outStream)
			{
				v2f o;
				float2 uv = v[0].uv;
				PARTICLE_POSITION(pData,uv); // pData.posにパーティクルのワールド座標が入る
				o.pData = pData;
                // OutputRule
                // Output.rgb = ParticleLocalPosition.xyz
                // Output.a = ParticleLifeTime
				float4 position = mul(UNITY_MATRIX_V,o.pData.pos);
				ADD_VERT(-1,-1)
				ADD_VERT( 1,-1)
				ADD_VERT(-1, 1)
				ADD_VERT( 1, 1)
                outStream.RestartStrip();
			}

			// ==========================================================================
			// Color Block
			// ==========================================================================
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_ParticleTex, i.uv);
				float dist = distance(i.uv,float2(0.5,0.5));
				fixed4 pcol = saturate(0.5-dist) * clamp(_ParticleCol / pow(length(i.uv), 2), 0, 2);
				float3 particleColor = rgb2hsv(i.pData.col.rgb);
				particleColor.y = (particleColor.y+3.0)*0.25;
				particleColor.z = 1.0;
				particleColor = hsv2rgb(particleColor);
				pcol.rgb *= particleColor.rgb * colorOverLifetime(i.pData.uvl.z);
				return pcol;
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
