Shader "Unlit/MeshGrassShader"
{
    Properties{
        [MainTexture] _MainText("Main Texture", 2D) = "white" {}
        _WindStrength("Wind Strength", Range(0, 1)) = 0.3
        _WindSpeed("Wind Speed", Range(0, 5)) = 1.5
        _WindDir("Wind Direction", Vector) = (1, 0, 0.5, 0)
        _GrassHeight("Grass Height", Float) = 1.0
        _RootColor("Root Colour", Color) = (0, 0.1, 0.05, 1)
        _TipColor("Tip Colour", Color) = (0.2, 0.7, 0.2, 1)
        _DisplacementRadius("Player Avoid Radius", Float) = 1.5
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
                float _WindStrength;
                float _WindSpeed;
                float4 _WindDir;
                float _GrassHeight;
                float4 _RootColor;
                float4 _TipColor;
                float _DisplacementRadius;
            CBUFFER_END
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS: NORMAL;
                float2 uv : TEXCOORD0;
            };

            float3 _PlayerPosition;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                // 1. Calculate World Position
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                
                // Use UV.y to determine height. 
                // Assumes UV.y = 0 at the root and 1 at the tip of the mesh.
                float heightFactor = IN.uv.y * _GrassHeight;

                // 2. Calculate Wind Animation
                float phase = posWS.x * 0.5 + posWS.z * 0.3;
                float wave = sin(_Time.y * _WindSpeed + phase);
                float3 windDir = normalize(_WindDir.xyz);
                float3 windOffset = windDir * wave * _WindStrength;

                float3 dirToGrass = posWS - _PlayerPosition;
                dirToGrass.y = 0;

                float distanceToPlayer = length(dirToGrass);
                float interactiveForce = saturate(1.0 - (distanceToPlayer/_DisplacementRadius));
                float3 playerPushOffset = dirToGrass*interactiveForce;
                playerPushOffset.y = -interactiveForce * 0.5;
                // Apply wind offset based on height (roots don't move, tips move most)
                posWS += (windOffset+playerPushOffset) * heightFactor;

                // 3. Transform to Clip Space
                OUT.positionHCS = TransformWorldToHClip(posWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainText);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
               // Color gradient from root to tip based on UV height
                half4 grassColor = lerp(_RootColor, _TipColor, IN.uv.y);

                // Combine them
                return grassColor;
            }

            ENDHLSL
            
        }
    }
}
