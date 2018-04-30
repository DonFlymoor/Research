
#include "./../postFx.hlsl"

float4 main( PFXVertToPix IN ) : SV_TARGET
{  
   float power = pow( max( IN.uv0.x, 0 ), 0.1 );   
   return float4( power, 0, 0, 1 );   
}