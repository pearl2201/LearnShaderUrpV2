Shader "lcl/learnShader1/007_rampTextureMask"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Float) = 1.0
        _SpecularMask ("Specular Mask", 2D) = "white" {}
        _SpecularScale ("Specular Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry"}

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;
                half2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half3 tangentWS : TEXCOORD2;
                half3 bitangentWS : TEXCOORD3;
                half3 normalWS : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_SpecularMask);
            SAMPLER(sampler_SpecularMask);

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
            half _BumpScale;
            half _SpecularScale;
            half4 _Specular;
            half _Gloss;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInput.positionCS;
                OUT.positionWS = vertexInput.positionWS;

                OUT.uv = TRANSFORM_TEX(IN.texcoord, _MainTex);

                half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                half3 tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                half sign = IN.tangentOS.w * GetOddNegativeScale();
                half3 bitangentWS = cross(normalWS, tangentWS) * sign;

                OUT.normalWS = normalWS;
                OUT.tangentWS = tangentWS;
                OUT.bitangentWS = bitangentWS;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Sample and unpack normal map, apply bump scale
                half3 tangentNormal = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // Convert tangent-space normal to world space via TBN matrix
                half3 normalWS = normalize(
                    tangentNormal.x * IN.tangentWS +
                    tangentNormal.y * IN.bitangentWS +
                    tangentNormal.z * IN.normalWS
                );

                // Sample albedo
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * _Color.rgb;

                // Ambient via spherical harmonics, multiplied by albedo
                half3 ambient = SampleSH(normalWS) * albedo;

                // Main directional light
                Light mainLight = GetMainLight();
                half3 lightDirWS = mainLight.direction;

                // Diffuse (Lambertian)
                half NdotL = max(0, dot(normalWS, lightDirWS));
                half3 diffuse = mainLight.color * albedo * NdotL;

                // Specular with mask (Blinn-Phong)
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                half3 halfDir = normalize(lightDirWS + viewDirWS);
                half specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, IN.uv).r * _SpecularScale;
                half3 specular = mainLight.color * _Specular.rgb * pow(max(0, dot(normalWS, halfDir)), _Gloss) * specularMask;

                return half4(ambient + diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Forward"
}
