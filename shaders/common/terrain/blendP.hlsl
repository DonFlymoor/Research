#include "shaders/common/bge.hlsl"
#include "terrain.hlsl"

struct ConnectData
{
   float4 hpos : SV_Position;
   float2 layerCoord : TEXCOORD0;
   float2 texCoord : TEXCOORD1;
};

uniform_sampler2D( layerTex, 0 );
uniform_sampler2D( textureMap, 1 );
uniform float texId;
uniform float layerSize;

float4 main( ConnectData IN ) : SV_Target
{
   float4 layerSample = round( tex2D( layerTex, IN.layerCoord ) * 255.0f );

   float blend = calcBlend( texId, IN.layerCoord, layerSize, layerSample );

   clip( blend - 0.0001 );

   return float4( tex2D( textureMap, IN.texCoord ).rgb, blend );
}
