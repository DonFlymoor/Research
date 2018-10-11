
//*****************************************************************************
// Box Filter
//*****************************************************************************
//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------
struct VertData
{
   float2 texCoord        : TEXCOORD0;
   float4 position        : POSITION;
};

struct ConnectData
{
   float4 hpos            : POSITION;
   float2 tex0            : TEXCOORD0;
};

uniform float4x4 modelview;

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
ConnectData main( VertData IN )
{
   ConnectData OUT;

   OUT.hpos = mul(modelview, IN.position);   
   OUT.tex0 = IN.texCoord;

   return OUT;
}
