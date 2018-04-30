
uniform sampler2D colorTarget0Texture : register(s0);
//uniform texture   colorTarget0TexObj  : register(T0);

float4 main( float4 ScreenPos : SV_Position ) : SV_Target
{
   float2 TexCoord = ScreenPos;
   float4 diffuse;
   asm { tfetch2D diffuse, TexCoord, colorTarget0Texture, UnnormalizedTextureCoords = true };
   return diffuse;
}