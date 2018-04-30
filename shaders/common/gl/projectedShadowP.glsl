
in vec2 texCoord;
in vec4 color;
in float fade;

out vec4 OUT_FragColor0;

uniform sampler2D inputTex;
uniform vec4 ambient;
            
            
void main()
{   
	float shadow = texture( inputTex, texCoord ).a * color.a;           
    OUT_FragColor0 = ( ambient * shadow ) + ( 1 - shadow );
}
