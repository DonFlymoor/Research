
#include "shaders/common/postFx/postFx.hlsl"
#include "shaders/common/bge.hlsl"

float4 rtParams0;

struct VertToPix
{
   float4 hpos       : POSITION;
   float2 uv        : TEXCOORD0;
};

VertToPix main( PFXVert IN )
{
   VertToPix OUT;
   
   OUT.hpos = float4(IN.pos, 1);
   OUT.uv = viewportCoordToRenderTarget( IN.uv, rtParams0 );
               
   return OUT;
}
