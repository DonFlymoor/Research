
struct Vertex
{
   float3 pos : POSITION;
   float4 color : COLOR0;
   float2 uv0 : TEXCOORD0;
};

struct Conn
{
   float4 hpos : SV_Position;
   float4 color : TEXCOORD0;
   float2 uv0 : TEXCOORD1;
   float4 pos : TEXCOORD2;
   float3 wsPosition   : TEXCOORD3;
};


uniform float4x4 modelViewProj;
uniform float4x4 fsModelViewProj;

Conn main( Vertex In )
{
    Conn Out;

   Out.hpos = mul( modelViewProj, float4(In.pos,1) );
	Out.pos = mul( fsModelViewProj, float4(In.pos,1) );
	Out.color = In.color;
	Out.uv0 = In.uv0;
    Out.wsPosition = In.pos.xyz;
	
    return Out;
}

