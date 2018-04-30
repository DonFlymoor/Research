
#include "../postFx.hlsl"
#include "shaders/common/bge.hlsl"



uniform_sampler2D( inputTex , 0 );
uniform float brightPassThreshold;

float4 main( PFXVertToPix IN ) : SV_TARGET
{
   float4 sample = hdrDecode( tex2D( inputTex, IN.uv0 ) );
   
   // Determine the brightness of this particular pixel.
   float lum = hdrLuminance( sample.rgb );

   // Write the colour to the bright-pass render target
   return ( float4( lum.rrr, 1 ) );
}
