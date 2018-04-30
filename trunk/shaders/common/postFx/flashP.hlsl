
#include "./postFx.hlsl"
#include "shaders/common/bge.hlsl"

uniform float damageFlash;
uniform float whiteOut;
uniform_sampler2D( backBuffer, 0);

float4 main(PFXVertToPix IN) : SV_Target
{
 float4 color1 = tex2D(backBuffer, IN.uv0); 
 float4 color2 = color1 * MUL_COLOR;
 float4 damage = lerp(color1,color2,damageFlash);
 return lerp(damage,WHITE_COLOR,whiteOut);
}
