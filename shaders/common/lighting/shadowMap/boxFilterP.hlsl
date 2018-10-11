
//*****************************************************************************
// Box Filter
//*****************************************************************************

struct ConnectData
{
   float2 tex0 : TEXCOORD0;
};

// If not defined from ShaderData then define 
// the default blur kernel size here.
//#ifndef blurSamples
//   #define blurSamples 4
//#endif

float log_conv ( float x0, float X, float y0, float Y )
{
    return (X + log(x0 + (y0 * exp(Y - X))));
}

uniform_sampler2D( diffuseMap0 , 0 );

uniform float texSize;
uniform float2 blurDimension;
uniform float2 blurBoundaries;

float4 main( ConnectData IN ) : SV_TARGET0
{   
   // 5x5
   if (IN.tex0.x <= blurBoundaries.x)
   {
      float texelSize = 1.2f / texSize;
      float2 sampleOffset = texelSize * blurDimension;
      //float2 offset = 0.5 * float( blurSamples ) * sampleOffset;

      float2 texCoord = IN.tex0;
      
      float accum = log_conv(0.3125, tex2D(diffuseMap0, texCoord - sampleOffset), 0.375, tex2D(diffuseMap0, texCoord));
      accum = log_conv(1, accum, 0.3125, tex2D(diffuseMap0, texCoord + sampleOffset));      
               
      return accum;
   } else {
      // 3x3
      if (IN.tex0.x <= blurBoundaries.y)
      {
         float texelSize = 1.3f / texSize;
         float2 sampleOffset = texelSize * blurDimension;
         //float2 offset = 0.5 * float( blurSamples ) * sampleOffset;

         float2 texCoord = IN.tex0;
         float accum = log_conv(0.5, tex2D(diffuseMap0, texCoord - sampleOffset), 0.5, tex2D(diffuseMap0, texCoord + sampleOffset));
                  
         return accum;
      } else {
         return tex2D(diffuseMap0, IN.tex0);
      }
   }
}

