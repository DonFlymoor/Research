
#include "shaders/common/bge.hlsl"
#include "./../postFX.hlsl"

#define SMAA_HLSL_4
#define SMAA_PRESET_HIGH
#include "SMAA.h"

struct VertToPix
{
   float4 hpos		: SV_Position;
   float2 uv0       : TEXCOORD0;
   float4 offset  	: TEXCOORD1;
};

uniform float4 rtParams0;
                    
VertToPix main( PFXVert IN )
{
    VertToPix OUT;

    OUT.hpos = float4(IN.pos,1.0f);
    OUT.uv0 = viewportCoordToRenderTarget( IN.uv, rtParams0 );
    SMAANeighborhoodBlendingVS(OUT.uv0, OUT.offset);

    return OUT;
}
