
#include "shaders/common/bge.hlsl"
#include "./../postFX.hlsl"

struct VertToPix
{
   float4 hpos       : SV_Position;
   float2 uv0        : TEXCOORD0;
};

uniform float4 rtParams0;
                    
VertToPix main( PFXVert IN )
{
   VertToPix OUT;
   
   OUT.hpos = float4(IN.pos,1.0f);
   OUT.uv0 = viewportCoordToRenderTarget( IN.uv, rtParams0 ); 
   
   return OUT;
}
