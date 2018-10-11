
//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------
struct ConnectData
{
   float2 texCoord        : TEXCOORD0;
};


struct Fragout
{
   float4 col : COLOR0;
};

uniform sampler2D diffuseMap;
uniform float4    shadeColor;

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
Fragout main( ConnectData IN )
{
   Fragout OUT;

   OUT.col = shadeColor;
   OUT.col *= tex2D(diffuseMap, IN.texCoord);

   return OUT;
}
