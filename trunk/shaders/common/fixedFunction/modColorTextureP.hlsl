
float4 main( float4 pos : SV_Position,
             float4 color_in : COLOR0, 
             float2 texCoord_in : TEXCOORD0,
             uniform SamplerState diffuseMap : register(S0),
             uniform Texture2D diffuseTex :register(T0) ) : SV_Target
{
   return diffuseTex.Sample(diffuseMap, texCoord_in) *color_in; //* color_in;
}