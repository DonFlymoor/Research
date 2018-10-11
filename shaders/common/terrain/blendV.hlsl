
/// The vertex shader used in the generation and caching of the
/// base terrain texture.

struct VertData
{
   float3 position : POSITION;
   float2 texCoord : TEXCOORD0;
};

struct ConnectData
{
   float4 hpos : SV_Position;
   float2 layerCoord : TEXCOORD0;
   float2 texCoord : TEXCOORD1;
};
uniform float2 texScale;

ConnectData main( VertData IN )
{
   ConnectData OUT;

   OUT.hpos = float4( IN.position.xyz, 1 );
   OUT.layerCoord = IN.texCoord;
   OUT.texCoord = IN.texCoord * texScale;

   return OUT;
}
