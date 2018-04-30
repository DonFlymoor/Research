
#include "./postFx.hlsl"
#include "shaders/common/bge.hlsl"
                    
PFXVertToPix main( PFXVert IN )
{
   PFXVertToPix OUT = (PFXVertToPix)0;
   
   OUT.hpos = float4(IN.pos,1.0f);
   OUT.uv0 = IN.uv;
   return OUT;
}
