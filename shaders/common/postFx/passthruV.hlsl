
#include "./postFx.hlsl"
#include "shaders/common/bge.hlsl"
                    
PFXVertToPix main( PFXVert IN )
{
   PFXVertToPix OUT;
   
   OUT.hpos = float4(IN.pos,1.0f);
   OUT.uv0 = IN.uv;
   OUT.uv1 = IN.uv;
   OUT.uv2 = IN.uv;
   OUT.uv3 = IN.uv;
   OUT.wsEyeRay = float3(0, 0, 1);
   return OUT;
}
