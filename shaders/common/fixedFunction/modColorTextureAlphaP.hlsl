
#include "shaders/common/hlsl.h"

uniform_sampler2D( diffuseMap, 0);

uniform float useAlpha;

float4 main( float4 color_in : COLOR0, 
             float2 texCoord_in : TEXCOORD0 ) : SV_Target0
{
   float4 color = tex2D(diffuseMap, texCoord_in) * color_in;
   color.a = lerp( 1, color.a , useAlpha );
   return color;
}