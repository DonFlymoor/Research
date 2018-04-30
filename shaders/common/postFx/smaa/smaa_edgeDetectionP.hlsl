
#include "../postFx.hlsl"
#define SMAA_HLSL_4
#define SMAA_PRESET_HIGH
#include "SMAA.h"

struct VertToPix
{
   float4 hpos       : SV_Position;
   float2 uv0        : TEXCOORD0;
   float4 offset[3]  : TEXCOORD1;
};

uniform_sampler2D( colorTexGamma, 0 ); // gamma space :(
// TODO depth

float4 main( VertToPix IN ) : SV_Target
{
#if SMAA_PREDICATION
    return SMAALumaEdgeDetectionPS(IN.uv0, IN.offset, colorTexGamma._texture, depthTex._texture);
#else
    return float4(SMAALumaEdgeDetectionPS(IN.uv0, IN.offset, colorTexGamma._texture), 0, 0);
#endif
}

