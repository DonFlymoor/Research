
#include "bge.glsl"
#include "hlslCompat.glsl"

in vec4 offscreenPos;
in vec4 backbufferPos;

#define IN_offscreenPos offscreenPos
#define IN_backbufferPos backbufferPos

uniform sampler2D colorSource;
uniform vec4 offscreenTargetParams;

#ifdef BGE_LINEAR_DEPTH
#define REJECT_EDGES
uniform sampler2D edgeSource;
uniform vec4 edgeTargetParams;
#endif


void main()
{  
   // Off-screen particle source screenspace position in XY
   // Back-buffer screenspace position in ZW
   vec4 ssPos = vec4(offscreenPos.xy / offscreenPos.w, backbufferPos.xy / backbufferPos.w);
   
	vec4 uvScene = ( ssPos + 1.0 ) / 2.0;
	uvScene.yw = 1.0 - uvScene.yw;
	uvScene.xy = viewportCoordToRenderTarget(uvScene.xy, offscreenTargetParams);
	
#ifdef REJECT_EDGES
   // Cut out particles along the edges, this will create the stencil mask
	uvScene.zw = viewportCoordToRenderTarget(uvScene.zw, edgeTargetParams);
	float edge = texture( edgeSource, uvScene.zw ).r;
	clip( -edge );
#endif
	
	// Sample offscreen target and return
   OUT_FragColor0 = texture( colorSource, uvScene.xy );
}