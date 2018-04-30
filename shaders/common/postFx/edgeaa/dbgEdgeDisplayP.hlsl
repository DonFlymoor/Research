
#include "../postFx.hlsl"


uniform_sampler2D( edgeBuffer , 0 );

float4 main( PFXVertToPix IN ) : SV_TARGET0
{
   return float4( tex2D( edgeBuffer, IN.uv0 ).rrr, 1.0 );
}