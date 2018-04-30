#include "../../../gl/hlslCompat.glsl"

in vec2 uv0;
uniform sampler2D shadowMap;
uniform sampler1D depthViz;

void main()
{
   float depth = saturate( texture( shadowMap, uv0 ).r );
   OUT_FragColor0 = vec4( texture( depthViz, depth ).rgb, 1 );
}