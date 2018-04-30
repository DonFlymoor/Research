
#include "./postFx.hlsl"

uniform_sampler2D(inputTex0, 0 );
uniform_sampler2D(inputTex1, 1 );
uniform_sampler2D(blendTex,  2 );

float4 main( PFXVertToPix IN ) : SV_Target
{
   return lerp( tex2D( inputTex0, IN.uv0 ), tex2D( inputTex1, IN.uv0 ), tex2D( blendTex, IN.uv0 ).a);
}