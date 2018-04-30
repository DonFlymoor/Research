#include "../../postfx/postFx.hlsl"
#include "shaders/common/lighting.hlsl"

uniform_sampler2D( lightPrePassTex, 0);

float4 main( PFXVertToPix IN ) : SV_Target0
{   
   float3 lightcolor;   
   float nl_Att, specular;   
   lightinfoUncondition( tex2D( lightPrePassTex, IN.uv0 ), lightcolor, nl_Att, specular );   
   return float4( lightcolor, 1.0 );   
}
