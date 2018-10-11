
#include "hlslStructs.h"

struct MaterialDecoratorConnectV
{
   float4 hpos : POSITION;
   float2 uv0 : TEXCOORD0;
};

uniform float4x4 modelview;

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
MaterialDecoratorConnectV main( VertexIn_PCT IN )
{
   MaterialDecoratorConnectV OUT;

   OUT.hpos = mul(modelview, IN.pos);
   OUT.uv0 = IN.uv0;

   return OUT;
}
