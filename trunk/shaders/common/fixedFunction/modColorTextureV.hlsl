
struct Appdata
{
	float3 position   : POSITION;
	float4 color      : COLOR;
	float2 texCoord   : TEXCOORD0;
};
struct Conn
{
   float4 HPOS             : SV_Position;
   float4 color            : COLOR;
   float2 texCoord         : TEXCOORD0;
};
Conn main( Appdata In, uniform float4x4 modelview : register(C0) )
{
   Conn Out;
   Out.HPOS = mul(modelview, float4(In.position,1));
   Out.color = In.color;
   Out.texCoord = In.texCoord;
   return Out;
}