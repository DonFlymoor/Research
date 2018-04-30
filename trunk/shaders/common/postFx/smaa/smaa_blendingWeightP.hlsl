
#include "../postFx.hlsl"
#define SMAA_HLSL_4
#define SMAA_PRESET_HIGH
#include "SMAA.h"

struct VertToPix
{
   float4 hpos       : SV_Position;
   float2 uv0        : TEXCOORD0;
   float2 pixcoord   : TEXCOORD1;
   float4 offset[3]  : TEXCOORD2;
};

#define uSubsampleIndices 0 // required for temporal modes (SMAA T2x).

uniform_sampler2D( edgesTex, 0 );
uniform_sampler2D( areaTex, 1 );
uniform_sampler2D( searchTex, 2 );

float4 main( VertToPix IN ) : SV_Target
{
	return SMAABlendingWeightCalculationPS(IN.uv0, IN.pixcoord, IN.offset, edgesTex._texture, areaTex._texture, searchTex._texture, uSubsampleIndices);
}

