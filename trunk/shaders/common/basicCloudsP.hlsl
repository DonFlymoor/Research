
#include "shaders/common/bge.hlsl"

struct ConnectData
{
   float4 hpos : POSITION;
   float2 texCoord : TEXCOORD0;
};

uniform_sampler2D( diffuseMap , 0 );

float4 main( ConnectData IN ) : SV_TARGET
{
   float4 col = tex2D( diffuseMap, IN.texCoord );
   return hdrEncode( col );
}