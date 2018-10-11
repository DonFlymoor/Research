
#include "hlslStructs.h"

//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------

struct ConnectData
{
   float4 hpos            : POSITION;
   float2 outTexCoord     : TEXCOORD0;
};

uniform float4x4 modelview;

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
ConnectData main( VertexIn_PNTTTB IN )
{
   ConnectData OUT;

   OUT.hpos = mul(modelview, IN.pos);
   OUT.outTexCoord = IN.uv0;

   return OUT;
}
