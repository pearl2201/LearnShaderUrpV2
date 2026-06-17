//https://github.com/csdjk/LearnUnityShader/blob/master/Assets/Scenes/LearnShader/LearnShader1/Shader/
Shader "lcl/learnShader1/007_rampTexture"
{
    Properties{
        _Color ("Color Tint", Color) = (1,1,1,1)
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _Specular ("Specular Color", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8,200)) = 10
    }

    SubShader{
        Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry"}

        Pass{
            // Fixed: Moved LightMode here where the render pipeline expects it
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes{
                float4 positionOS : POSITION;
                half3 normalOS: NORMAL;
                float4 texcoord: TEXCOORD0;
                half2 uv: TEXCOORD0;
            };

            struct Varyings{
                float4 positionCS : SV_POSITION;
                float3 positionWS: TEXCOORD0;
                half3 normalWS      : NORMAL;
                half2 uv: TEXCOORD1;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half4 _Specular;
            half _Gloss;
            float4 _RampTex_ST;
            CBUFFER_END

            Varyings vert(Attributes IN){
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInput.positionCS;
                OUT.positionWS = vertexInput.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _RampTex);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target{
                half3 normalWS = normalize(IN.normalWS);

                half3 ambientColor = SampleSH(normalWS);

                Light mainLight = GetMainLight();
                half3 worldLightDir = mainLight.direction;
                // Clean Half-Lambert calculation
                half halfLambert = dot(normalWS, worldLightDir) * 0.5 + 0.5;
                half3 diffuseColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, 0.5)).rgb * _Color.rgb;
                half3 diffuse = mainLight.color * diffuseColor;

                half3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                half3 halfDir = normalize(viewDir + mainLight.direction);
                half3 specular = mainLight.color*pow(max(0,dot(normalWS, halfDir)),_Gloss)*_Specular;
                half3 color = (diffuse)  + ambientColor + specular;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}