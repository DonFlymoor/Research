
#include "./postFx.hlsl"

uniform_sampler2D(inputTex, 0 );

float4 main( PFXVertToPix IN ) : SV_Target
{
   return tex2D( inputTex, IN.uv0 );   
}