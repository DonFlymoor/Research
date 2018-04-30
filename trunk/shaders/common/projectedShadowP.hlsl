#include "shaders/common/hlsl.h"

struct Conn
{
   float4 position : POSITION;
   float2 texCoord : TEXCOORD0;
   float fade : TEXCOORD1;
};

uniform_sampler2D( inputTex , 0 );
uniform float4 ambient;

float4 main( Conn IN ) : SV_TARGET0
{
   //float shadow = tex2D( inputTex, IN.texCoord ).a * IN.color.a;
   //return ( ambient * shadow ) + ( 1 - shadow );
   float shadow = tex2D( inputTex, IN.texCoord ).r;
#ifdef BGE_USE_REVERSED_DEPTH_BUFFER
	shadow = 1.0f - shadow;
#endif
   return shadow;
}
