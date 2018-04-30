#define BGE_USE_SCENE_CBUFFER
#include "shaders/common/bge.hlsl"
#include "shaders/common/gbuffer.h"

uniform Texture2D depthMap : register(t0);
uniform_sampler2D(diffuseMap, 1);

struct Conn
{
   float4 HPOS             : SV_Position;
   float3 worldPos         : TEXCOORD0;
   uint instanceId         : SV_InstanceID;
};

struct DecalInstance_t
{
    float4x4 woldMatrix;
    float4x4 invWoldMatrix ;
    float4 instanceColor;
};

StructuredBuffer<DecalInstance_t> decals : register(t2);

float4 main( Conn IN ) : SV_Target
{
    float realDepth = ndcToRealDepth(depthMap.Load(int3(IN.HPOS.xy, 0)).r, projectionParams.zw);
    float3 pixelVec = normalize(IN.worldPos - eyePosWorld);
    float3 worldPos = calculateWorlPosition(realDepth, pixelVec, eyePosWorld, normalize(vEye));

    float3 decalPos = mul(decals[IN.instanceId].invWoldMatrix, float4(worldPos, 1)).xyz;
    clip(0.5 - abs(decalPos));
    float2 uv = decalPos.xy + 0.5;
    uv.y = 1 - uv.y;
    return tex2D(diffuseMap, uv) * decals[IN.instanceId].instanceColor;
}
