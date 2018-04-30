
#include "shaders/common/hlsl.h"

uniform_sampler2D( diffuseMap, 0);

float4 main( float4 color_in : COLOR0, 
             float2 texCoord_in : TEXCOORD0,
             uniform float useAlpha : register(C0) ) : SV_Target0
{
   float4 color = tex2D(diffuseMap, texCoord_in) * color_in;
   color.a = lerp( 1, color.a , useAlpha );
   return color;
}