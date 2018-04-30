
#include "shdrConsts.h"

//-----------------------------------------------------------------------------
// Structures                                                                  
//-----------------------------------------------------------------------------
struct ConnectData
{
   float2 texCoord        : TEXCOORD0;
   float4 lum				  : COLOR0;
   float4 groundAlphaCoeff : COLOR1;
   float2 alphaLookup	  : TEXCOORD1;
};

struct Fragout
{
   float4 col : COLOR0;
};

uniform_sampler2D( diffuseMap , 0 );
uniform_sampler2D( alphaMap , 1 );

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
Fragout main( ConnectData IN,
              uniform float4 groundAlpha,
              uniform float4 ambient )
{
   Fragout OUT;

	float4 alpha = tex2D(alphaMap, IN.alphaLookup);
   OUT.col = float4( ambient.rgb * IN.lum.rgb, 1.0 ) * tex2D(diffuseMap, IN.texCoord);
   OUT.col.a = OUT.col.a * min(alpha, groundAlpha + IN.groundAlphaCoeff.x).x;
   
   return OUT;
}
