
struct Vert
{
	float3 position	: POSITION;
    float3 normal          : NORMAL;
    float3 T               : TANGENT;
    float2 texCoord        : TEXCOORD0;
    float4 fadeParans      : TEXCOORD1;
};

struct Conn
{
	float4 position : POSITION;
	float2 texCoord	: TEXCOORD0;
	float fade : TEXCOORD1;
};

uniform float4x4 modelview;
uniform float shadowLength;
uniform float3 shadowCasterPosition;

Conn main( Vert In )
{
    Conn Out;

    // Decals are in world space.
    Out.position = mul( modelview, float4( In.position.xyz, 1.0 ) );
 
    Out.texCoord = In.texCoord;
 
    float fromCasterDist = length( In.position.xyz - shadowCasterPosition ) - shadowLength;   
    Out.fade = 1.0 - saturate( fromCasterDist / shadowLength );
    
   return Out;
}
