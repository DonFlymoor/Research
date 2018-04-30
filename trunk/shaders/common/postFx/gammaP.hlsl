#include "shaders/common/bge.hlsl"

  
#include "./postFx.hlsl"

uniform_sampler2D( backBuffer, 0 );
uniform_sampler1D( colorCorrectionTex, 1 );

uniform float OneOverGamma;


float4 main( PFXVertToPix IN ) : SV_Target 
{
    float4 color = tex2D(backBuffer, IN.uv0.xy);
    
    // Apply the color correction.
   color.r = tex1D( colorCorrectionTex, color.r ).r;
   color.g = tex1D( colorCorrectionTex, color.g ).g;
   color.b = tex1D( colorCorrectionTex, color.b ).b;

   // Apply gamma correction
    color.rgb = pow( abs(color.rgb), OneOverGamma );

    return color;    
}