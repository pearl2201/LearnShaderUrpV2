Shader "lcl/learnShader1/005_Specular_frag"
{
    Properties{
        _Diffuse  ("Diffuse Color", Color) = (1,1,1,1)
        _Specular  ("Specular Color", Color) = (1,1,1,1)
        _Gloss ("Gloss",Range(8,200)) = 10
    }

    SubShader{
        Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        Pass{
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_SHADOW_MIXING
            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes{
                float4 positionOS : POSITION;
     
                float3 normalOS: NORMAL;
            };

            struct Varyings{
                float4 positionCS : SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float3 normalWS      : NORMAL; // Passing calculated color to fragment
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Diffuse;
                half4 _Specular;
                float _Gloss;
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
                float3 normalWS = IN.normalWS;
                float3 positionWS = IN.positionWS;
                normalWS = normalize(normalWS);

                float3 ambientColor = SampleSH(normalWS);

                Light mainLight = GetMainLight();

                float3 diffuse = mainLight.color * max(dot(normalWS, mainLight.direction),0.0);

               

                float3 viewDir = GetWorldSpaceNormalizeViewDir(positionWS);

                float3 reflectDir = reflect(-mainLight.direction, normalWS);

                float3 specular = mainLight.color * pow(max(0, dot(reflectDir, viewDir)),_Gloss)*_Specular;

                 float3 color = (diffuse) * _Diffuse.rgb + ambientColor + specular;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}