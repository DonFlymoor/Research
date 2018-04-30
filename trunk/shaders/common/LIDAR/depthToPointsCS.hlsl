#include "shaders/common/hlsl.h"
#include "shaders/common/gbuffer.h"

cbuffer cbuffer_data : register(b0)
{
    float4 wsEyeRays[4];
    float4 projParams;
    float3 eyePosWorld;
    float maxDepth;
    float3 vEye;
    float outOffset;
    float2 targetSize;
    float2 oneOverTargetSize;
    float4 debug;
};

RWByteAddressBuffer uav : register(u0);
uniform_sampler2D( prePassDepthBuffer, 0 );

uint packColor(float4 color)
{
    color = saturate(color);
    uint pack = 0;
    pack |= uint(color.r * 255);
    pack |= uint(color.g * 255) << 8;
    pack |= uint(color.b * 255) << 16;
    pack |= uint(color.a * 255) << 24;
    return pack;
}

float4 getDebugcolor()
{
    return float4(0, 1, 0, 1);
    
    float4 color = 1;
    if(debug.r == 1) {
        color = float4(1, 0, 0, 1);
    }
    else if(debug.r == 2) {
        color = float4(0, 1, 0, 1);
    }
    else if(debug.r == 3) {
        color = float4(0, 0, 1, 1);
    }
    return color;
}

[numthreads(1, 1, 1)]
void main(uint3 pixelID : SV_DispatchThreadID)
{
    GBuffer gbuffer = (GBuffer)0;
    float2 uv = (float2(pixelID.xy) * oneOverTargetSize.xy) + (0.5 * oneOverTargetSize.xy);
    gbuffer.depth = prePassDepthBufferTex.Load( pixelID.xyz ).r;

    uint index = 16 * uint(outOffset + pixelID.x + (pixelID.y * targetSize.x));
    
    float3 left = lerp(wsEyeRays[1], wsEyeRays[0], uv.y);
    float3 right = lerp(wsEyeRays[3], wsEyeRays[2], uv.y);
    float3 wsEyeVec = normalize(lerp(left, right, uv.x));
    float realDepth;
    float3 normal;
    
    decodeGBuffer(gbuffer, projParams, normal,  realDepth);
    float3 worldPos = calculateWorlPosition(realDepth, wsEyeVec, eyePosWorld, normalize(vEye));
    
    float4 color = getDebugcolor();
    if(realDepth > maxDepth) {
       color = 0;
       worldPos = 0;
    }       
    
    uav.Store4(index, uint4( asuint(worldPos.x), asuint(worldPos.y), asuint(worldPos.z), packColor(color)));
}
