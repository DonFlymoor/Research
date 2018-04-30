#include "shaders/common/bge.hlsl"

uniform_sampler2D( colorSource, 0 );
uniform float4 offscreenTargetParams;

#ifdef BGE_LINEAR_DEPTH
#define REJECT_EDGES
uniform_sampler2D( edgeSource, 1 );
uniform float4 edgeTargetParams;
#endif


float4 main( float4 hpos : POSITION, float4 offscreenPos : TEXCOORD0, float4 backbufferPos : TEXCOORD1 ) : SV_Target
{  
   // Off-screen particle source screenspace position in XY
   // Back-buffer screenspace position in ZW
   float4 ssPos = float4(offscreenPos.xy / offscreenPos.w, backbufferPos.xy / backbufferPos.w);
   
	float4 uvScene = ( ssPos + 1.0 ) / 2.0;
	uvScene.yw = 1.0 - uvScene.yw;
	uvScene.xy = viewportCoordToRenderTarget(uvScene.xy, offscreenTargetParams);
	
#ifdef REJECT_EDGES
   // Cut out particles along the edges, this will create the stencil mask
	uvScene.zw = viewportCoordToRenderTarget(uvScene.zw, edgeTargetParams);
	float edge = tex2D( edgeSource, uvScene.zw ).r;
	clip( -edge );
#endif
	
	// Sample offscreen target and return
   return tex2D( colorSource, uvScene.xy );
}