
#include "../../postfx/postFx.hlsl"


uniform_sampler2D( prepassTex, 0);
uniform_sampler2D( prepassDepthTex, 1);

float4 main( PFXVertToPix IN ) : SV_Target0
{   
   float3 normal = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams ).xyz;   
   return float4( ( normal + 1.0 ) * 0.5, 1.0 );
}