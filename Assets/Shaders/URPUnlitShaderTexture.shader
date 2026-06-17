Shader "Unlit/URPUnlitShaderTexture"
{
    Properties{
        [MainTexture] _MainText("Main Texture", 2D) = "white" {}
    }
    SubShader{
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }


        Pass{
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainText);
            SAMPLER(sampler_MainText);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainText_ST;
            CBUFFER_END
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };



            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv + (_SinTime, _SinTime);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainText, sampler_MainText, IN.uv);
            }

            ENDHLSL
            
        }
    }
}