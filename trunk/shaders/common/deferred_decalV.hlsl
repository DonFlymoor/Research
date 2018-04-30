#define BGE_USE_SCENE_CBUFFER
#include "shaders/common/bge.hlsl"

struct Appdata
{
	float3 position   : POSITION;
    uint instanceId   : SV_InstanceID;
};

struct Conn
{
   float4 HPOS             : SV_Position;
   float3 worldPos         : TEXCOORD;
   uint instanceId         : SV_InstanceID;
};

struct DecalInstance_t
{
    float4x4 woldMatrix;
    float4x4 invWoldMatrix ;
    float4 instanceColor;
};

StructuredBuffer<DecalInstance_t> decals : register(t2);

Conn main( Appdata IN )
{
   Conn Out;
   Out.HPOS = mul( mul(viewProj, decals[IN.instanceId].woldMatrix), float4(IN.position,1));
   Out.worldPos = mul(decals[IN.instanceId].woldMatrix, float4(IN.position,1));
   Out.instanceId = IN.instanceId;
   return Out;
}
