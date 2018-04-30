#include "shaders/common/hlsl.h"
#include "shaders/common/bge.hlsl"

// This vertex and pixel shader applies a 3 x 3 blur to the image in  
// colorMapSampler, which is the same size as the render target.  
// The sample weights are 1/16 in the corners, 2/16 on the edges,  
// and 4/16 in the center.  

uniform_sampler2D_NoReg(colorSampler);  // Output of DofNearCoc()  

struct Pixel
{  
   float4 position : SV_Position;  
   float4 texCoords : TEXCOORD0;  
};  

float4 main( Pixel IN ) : SV_TARGET
{  
   float4 color;  
   color = 0.0;  
   color += tex2D( colorSampler, IN.texCoords.xz );  
   color += tex2D( colorSampler, IN.texCoords.yz );  
   color += tex2D( colorSampler, IN.texCoords.xw );  
   color += tex2D( colorSampler, IN.texCoords.yw );  
   return color / 4.0;  
}  