#include "./postFx.hlsl"

uniform_sampler2D(inputTex, 0 );
uniform_sampler2D(warningTex, 1 );

float4 main( PFXVertToPix IN ) : SV_Target
{
   float4 warning = tex2D( warningTex, saturate(IN.hpos / float2(512.0f, 256.0f)) );
   return float4(lerp(tex2D( inputTex, IN.uv0 ).rgb, 1, warning.a), 1);
}
