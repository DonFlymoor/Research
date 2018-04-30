
//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------
struct Conn
{
   float2 texCoord : TEXCOORD0;
   float4 color : COLOR0;
};

struct Frag
{
   float4 col : COLOR0;
};

uniform_sampler2D( diffuseMap , 0 );

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
Frag main( Conn In )
{
   Frag Out;

   Out.col = tex2D(diffuseMap, In.texCoord) * In.color;

   return Out;
}
