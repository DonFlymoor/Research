
#include "../../hlslStructs.h"
#include "farFrustumQuad.hlsl"

uniform float4 rtParams0;

FarFrustumQuadConnectV main( VertexIn_PNTT IN )
{
   FarFrustumQuadConnectV OUT;

   OUT.hpos = float4( IN.uv0, 0, 1 );

   // Get a RT-corrected UV from the SS coord
   OUT.uv0 = getUVFromSSPos( OUT.hpos.xyz, rtParams0 );
   
   // Interpolators will generate eye rays the 
   // from far-frustum corners.
   OUT.wsEyeRay = IN.tangent.xyz;
   OUT.vsEyeRay = IN.normal.xyz;

   return OUT;
}
