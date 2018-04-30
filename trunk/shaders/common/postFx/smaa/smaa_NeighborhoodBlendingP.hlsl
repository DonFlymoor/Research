
#include "../postFx.hlsl"
#define SMAA_HLSL_4
#define SMAA_PRESET_HIGH
#include "SMAA.h"

struct VertToPix
{
   float4 hpos      : SV_Position;
   float2 uv0       : TEXCOORD0;
   float4 offset  	: TEXCOORD1;
};

uniform_sampler2D( colorTex, 0 );
uniform_sampler2D( blendTex, 1 );

float4 main( VertToPix IN ) : SV_Target
{
#if SMAA_REPROJECTION
    return SMAANeighborhoodBlendingPS(IN.uv0, IN.offset, colorTex._texture, blendTex._texture, velocityTex);
#else
    return SMAANeighborhoodBlendingPS( IN.uv0, IN.offset, colorTex._texture, blendTex._texture);
#endif
}

