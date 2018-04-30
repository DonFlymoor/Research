
#include "../postFx.hlsl"

uniform_sampler2D( inputTex , 0 );
uniform float2 oneOverTargetSize;


static float2 gTapOffsets[16] = 
{
   { -1.5, -1.5 }, { -0.5, -1.5 }, { 0.5, -1.5 }, { 1.5, -1.5 },
   { -1.5, -0.5 }, { -0.5, -0.5 }, { 0.5, -0.5 }, { 1.5, -0.5 },
   { -1.5, 0.5 },  { -0.5, 0.5 },  { 0.5, 0.5 },  { 1.5, 0.5 },
   { -1.5, 1.5 },  { -0.5, 1.5 },  { 0.5, 1.5 },  { 1.5, 1.5 }
};

float4 main( PFXVertToPix IN ) : SV_TARGET
{
   float2 pixelSize = oneOverTargetSize;

   float average = 0.0;

   for ( int i = 0; i < 16; i++ )
   {
      float lum = tex2D( inputTex, IN.uv0 + ( gTapOffsets[i] * pixelSize ) ).r;
      average += lum;
   }

   return float4( average / 16.0, 0.0, 0.0, 1.0 );
}
