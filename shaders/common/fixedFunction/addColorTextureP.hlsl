
float4 main( float4 pos: SV_POSITION,float4 color_in : COLOR0, 
             float2 texCoord_in : TEXCOORD0,
             uniform SamplerState diffuseMap : register(S0),uniform Texture2D diffuseTex : register(T0) ) : SV_TARGET
{
   return float4(color_in.rgb, color_in.a * diffuseTex.Sample(diffuseMap, texCoord_in).r);
}