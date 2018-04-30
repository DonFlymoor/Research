#include "shaders/common/hlsl.h"
#include "shaders/common/bge.hlsl"
#include "../postFx.hlsl"

uniform_sampler2D( sceneTex, 0 );
uniform_sampler2D( luminanceTex, 1 );
uniform_sampler2D( bloomTex, 2 );
uniform_sampler1D( colorCorrectionTex, 3 );

uniform float2 texSize0;
uniform float2 texSize2;

uniform float g_fEnableToneMapping;
uniform float g_fMiddleGray;
uniform float g_fWhiteCutoff;

uniform float g_fEnableBlueShift;
uniform float3 g_fBlueShiftColor; 

uniform float g_fBloomScale;

uniform float g_fOneOverGamma;

// http://de.slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting
float3 TonemapOperatorUncharted2(float3 x)
{
   float A = 0.15;
   float B = 0.50;
   float C = 0.10;
   float D = 0.20;
   float E = 0.02;
   float F = 0.30;

   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 TonemapUncharted2(float3 color)
{
    const float exposure_adjustment = 2; //16;
    const float exposure_bias = 2;

    color *= exposure_adjustment;
    const float whiteScale = 1.0f / TonemapOperatorUncharted2(11.2f);
    return TonemapOperatorUncharted2(exposure_bias * color) * whiteScale;
}


float4 main( PFXVertToPix IN ) : SV_TARGET0
{
   float4 sample = hdrDecode( tex2D( sceneTex, IN.uv0 ) );
   float adaptedLum = tex2D( luminanceTex, 0.5f ).r;
   float4 bloom = tex2D( bloomTex, IN.uv0 );

   // For very low light conditions, the rods will dominate the perception
   // of light, and therefore color will be desaturated and shifted
   // towards blue.
   if ( g_fEnableBlueShift > 0.0f )
   {
      const float3 LUMINANCE_VECTOR = float3(0.2125f, 0.7154f, 0.0721f);

      // Define a linear blending from -1.5 to 2.6 (log scale) which
      // determines the lerp amount for blue shift
      float coef = 1.0f - ( adaptedLum + 1.5 ) / 4.1;
      coef = saturate( coef * g_fEnableBlueShift );

      // Lerp between current color and blue, desaturated copy
      float3 rodColor = dot( sample.rgb, LUMINANCE_VECTOR ) * g_fBlueShiftColor;
      sample.rgb = lerp( sample.rgb, rodColor, coef );
	  
      rodColor = dot( bloom.rgb, LUMINANCE_VECTOR ) * g_fBlueShiftColor;
      bloom.rgb = lerp( bloom.rgb, rodColor, coef );
   }

   // Add the bloom effect. 
   sample += g_fBloomScale * bloom;

   // Apply the color correction.
   sample.r = tex1D( colorCorrectionTex, sample.r ).r;
   sample.g = tex1D( colorCorrectionTex, sample.g ).g;
   sample.b = tex1D( colorCorrectionTex, sample.b ).b;

    #ifdef BGE_USE_GAMMA_CORRECTION
        // Tonemapping
        sample.rgb = TonemapUncharted2(sample.rgb);

        // gamma correction
        sample.rgb = linearToGammaColor(sample.rgb);
    #else
        // Apply gamma correction
        sample.rgb = pow( abs(sample.rgb), g_fOneOverGamma );
    #endif    

   return sample;
}
