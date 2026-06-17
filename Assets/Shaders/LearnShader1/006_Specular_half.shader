//https://github.com/csdjk/LearnUnityShader/blob/master/Assets/Scenes/LearnShader/LearnShader1/Shader/
Shader "lcl/learnShader1/006_Specular_half"
{
    Properties{
        _Diffuse  ("Diffuse Color", Color) = (1,1,1,1)
        _Specular  ("Specular Color", Color) = (1,1,1,1)
        _Gloss ("Gloss",Range(8,200)) = 10
        _Factor ("Factor", Range(0, 5)) = 1
    }

    SubShader{
        Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry"}

        Pass{
            // Fixed: Moved LightMode here where the render pipeline expects it
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_SHADOW_MIXING

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes{
                float4 positionOS : POSITION;
                float3 normalOS: NORMAL;
            };

            struct Varyings{
                float4 positionCS : SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float3 normalWS      : NORMAL; 
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                half4 _Specular;
                float _Gloss;
                float _Factor;
            CBUFFER_END

            Varyings vert(Attributes IN){
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInput.positionCS;
                OUT.positionWS = vertexInput.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target{
                float3 normalWS = normalize(IN.normalWS);

                float3 ambientColor = SampleSH(normalWS);

                Light mainLight = GetMainLight();
                
                // Clean Half-Lambert calculation
                float halfLambert = dot(normalWS, mainLight.direction) * 0.5 + 0.5;
                float3 diffuse = mainLight.color * (halfLambert * halfLambert);
                float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                float3 halfDir = normalize(viewDir + mainLight.direction);
                float3 specular = _Factor*mainLight.color*pow(max(0,dot(normalWS, halfDir)),_Gloss)*_Specular;
                float3 color = (diffuse) * _Diffuse.rgb + ambientColor + specular;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}