
uniform SamplerState diffuseMap : register(S0);
uniform Texture2D diffuseTex : register(T0);
float4 main( float4 pos : SV_Position,float4 color_in : COLOR0  ) : SV_Target
{
   return color_in;
}
