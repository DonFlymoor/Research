
#include "./postFx.hlsl"
#include "shaders/common/bge.hlsl"


uniform float4x4 matPrevScreenToWorld;
uniform float4x4 matWorldToScreen;

// Passed in from setShaderConsts()
uniform float velocityMultiplier;

uniform_sampler2D( backBuffer , 0 );
uniform_sampler2D( prepassTex , 1 );
uniform_sampler2D( prepassDepthTex , 2 );

float4 main(PFXVertToPix IN) : SV_TARGET0
{
   float samples = 5;
   
   // First get the prepass texture for uv channel 0
   float4 prepass = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams );
   
   // Next extract the depth
   float depth = prepass.a;
   
   // Create the screen position
   float4 screenPos = float4(IN.uv0.x*2-1, IN.uv0.y*2-1, depth*2-1, 1);

   // Calculate the world position
   float4 D = mul(screenPos, matWorldToScreen);
   float4 worldPos = D / D.w;
   
   // Now calculate the previous screen position
   float4 previousPos = mul( worldPos, matPrevScreenToWorld );
   previousPos /= previousPos.w;
	
   // Calculate the XY velocity
   float2 velocity = ((screenPos - previousPos) / velocityMultiplier).xy;
   
   // Generate the motion blur
   float4 color = tex2D(backBuffer, IN.uv0);
	IN.uv0 += velocity;
	
   for(int i = 1; i<samples; ++i, IN.uv0 += velocity)
   {
      float4 currentColor = tex2D(backBuffer, IN.uv0);
      color += currentColor;
   }
   
   return color / samples;
}