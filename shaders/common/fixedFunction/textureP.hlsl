#include "shaders/common/bge.hlsl"

uniform_sampler2D( diffuseMap, 0 );

float4 main( float4 pos : SV_Position, float4 color: COLOR0, float2 texCoord_in : TEXCOORD0 ) : SV_Target0
{
   return tex2D(diffuseMap, texCoord_in);
}