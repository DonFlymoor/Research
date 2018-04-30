
// This vertex and pixel shader applies a 3 x 3 blur to the image in  
// colorMapSampler, which is the same size as the render target.  
// The sample weights are 1/16 in the corners, 2/16 on the edges,  
// and 4/16 in the center.  

#include "./../postFx.hlsl"
#include "shaders/common/bge.hlsl"

struct Vert
{
   float3 position : POSITION;
   float2 texCoords : TEXCOORD0;
};

struct Pixel
{  
   float4 position : SV_Position;  
   float4 texCoords : TEXCOORD0;  
};  

uniform float2 oneOverTargetSize;  
uniform float4 rtParams0;

Pixel main( Vert IN )  
{  
   Pixel OUT;  
   const float4 halfPixel = { -0.5, 0.5, -0.5, 0.5 };     
   OUT.position = float4(IN.position,1); //Transform_ObjectToClip( IN.position );  
   
   //float2 uv = IN.texCoords + rtParams0.xy;
   float2 uv = viewportCoordToRenderTarget( IN.texCoords, rtParams0 );
   OUT.texCoords = uv.xxyy + halfPixel * oneOverTargetSize.xxyy;  
   return OUT;  
}  