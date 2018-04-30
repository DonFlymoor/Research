
//-----------------------------------------------------------------------------
// Data
//-----------------------------------------------------------------------------
uniform sampler2D diffuseMap, refractMap;
uniform vec4 shadeColor;

in vec2 TEX0;
in vec4 TEX1;

//-----------------------------------------------------------------------------
// Main                                                                        
//-----------------------------------------------------------------------------
void main()
{
   vec4 diffuseColor = texture( diffuseMap, TEX0 );
   vec4 reflectColor = textureProj( refractMap, TEX1 );

   OUT_FragColor0 = diffuseColor + reflectColor * diffuseColor.a;
}
