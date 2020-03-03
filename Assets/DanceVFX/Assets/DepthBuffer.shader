Shader "HOTATE/DanceVFX/DepthBuffer"
{
    Properties
    {
        _DepthTex ("Depth Texture", 2D) = "white" {}
        [IntRange] _Buffer ("Buffer", Range(1,60)) = 10
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            Name "Update"
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            sampler2D _DepthTex;
            int _Buffer;

            float4 frag(v2f_customrendertexture i) : SV_Target
            {
                float2 uv = i.globalTexcoord;

                float uvx = uv.x*_Buffer;
                uv.x = frac(uvx);
                uvx = floor(uvx);

                float4 depth = tex2Dlod( _DepthTex, float4(uv,0,0));
                uv.x = i.globalTexcoord.x - uvx/_Buffer;
                float4 buffer = tex2Dlod( _SelfTexture2D, float4(uv,0,0));

                return uvx == 0 ? depth : buffer;
            }
            ENDCG
        }
    }
}
