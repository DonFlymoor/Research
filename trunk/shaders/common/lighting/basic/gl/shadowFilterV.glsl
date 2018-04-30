
#include "../../../../../../shaders/common/gl/bge.glsl"

in vec4 vPosition;
in vec2 vTexCoord0;

uniform vec4 rtParams0;

out vec2 uv;

void main()
{
   gl_Position = vPosition;   
   uv = viewportCoordToRenderTarget( vTexCoord0.st, rtParams0 ); 
   gl_Position.y *= -1; //correct ssp
}
