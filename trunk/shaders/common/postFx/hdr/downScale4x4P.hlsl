
#define IN_HLSL
#include "../../shdrConsts.h"
#include "../postFx.hlsl"

//-----------------------------------------------------------------------------
// Data 
//-----------------------------------------------------------------------------
struct VertIn
{
	float4 hpos : SV_POSITION;
	float4 texCoords[8] : TEXCOORD0;
};

uniform_sampler2D( inputTex , 0 );
 
//-----------------------------------------------------------------------------
// Main
//-----------------------------------------------------------------------------
float4 main(  VertIn IN ) : SV_TARGET
{
   // We calculate the texture coords
   // in the vertex shader as an optimization.
   float4 sample = 0.0f;
   for ( int i = 0; i < 8; i++ )
   {
      sample += tex2D( inputTex, IN.texCoords[i].xy );
      sample += tex2D( inputTex, IN.texCoords[i].zw );
   }
   
	return sample / 16;
}