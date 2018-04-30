
#include "./postFx.hlsl"

uniform float  accumTime;
uniform float  turbulenceMultiplier;
uniform float2 projectionOffset;
uniform float4 targetViewport;

uniform_sampler2D( inputTex, 0);

float4 main( PFXVertToPix IN ) : SV_Target
{
	float speed = 2.0;
	float distortion = 6.0;
		
	float y = IN.uv0.y + (cos((IN.uv0.y+projectionOffset.y) * distortion + accumTime * speed) * 0.01 * turbulenceMultiplier);
   float x = IN.uv0.x + (sin((IN.uv0.x+projectionOffset.x) * distortion + accumTime * speed) * 0.01 * turbulenceMultiplier);

   // Clamp the calculated uv values to be within the target's viewport
	y = clamp(y, targetViewport.y, targetViewport.w);
	x = clamp(x, targetViewport.x, targetViewport.z);
	
    return tex2D(inputTex, float2(x, y));
}
