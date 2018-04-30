
//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------
struct ConnectData
{
   float2 texCoord   : TEXCOORD0;
   float4 tex2       : TEXCOORD1;
};


struct Fragout
{
   float4 col : COLOR0;
};

uniform_sampler2D( texMap, 0);
uniform_sampler2D( refractMap, 1);


//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
Fragout main( ConnectData IN )
{
   Fragout OUT;

   float4 diffuseColor = tex2D( texMap, IN.texCoord );
   float4 reflectColor = tex2D( refractMap, IN.tex2.xy / IN.tex2.w );

   OUT.col = diffuseColor + reflectColor * diffuseColor.a;

   return OUT;
}
