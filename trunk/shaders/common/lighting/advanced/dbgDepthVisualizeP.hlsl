#include "../../postfx/postFx.hlsl"


uniform_sampler2D( prepassTex, 0 );
uniform_sampler2D( prepassDepthTex, 1 );
uniform_sampler1D( depthViz, 2 );


float4 main( PFXVertToPix IN ) : SV_Target0
{
   float linearDepth = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams ).w;
   return float4( tex1D( depthViz, saturate(linearDepth) ).rgb, 1.0 );
}
