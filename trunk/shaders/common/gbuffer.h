#ifndef GBUFFER_H
#define GBUFFER_H

float2 OctWrap( float2 v )
{
    return ( 1.0 - abs( v.yx ) ) * ( v.xy >= 0.0 ? 1.0 : -1.0 );
}

half2 encodeNormalOct (half3 n)
{
    n /= ( abs( n.x ) + abs( n.y ) + abs( n.z ) );
    n.xy = n.z >= 0.0 ? n.xy : OctWrap( n.xy );
    n.xy = n.xy * 0.5 + 0.5;
    return n.xy;
}

half3 decodeNormalOct (half2 encN)
{
    encN = encN * 2.0 - 1.0;
 
    float3 n;
    n.z = 1.0 - abs( encN.x ) - abs( encN.y );
    n.xy = n.z >= 0.0 ? encN.xy : OctWrap( encN.xy );
    n = normalize( n );
    return n;
}

half3 encodeNormal (half3 n)
{
    return n * 0.5 + 0.5;
}

half3 decodeNormal (half3 encN)
{
    return normalize(encN * 2 - 1);
}

#ifndef BGE_USE_SCENE_CBUFFER
uniform float4 projParams;
#endif

float ndcToRealDepth(float ndcDepth, float2 projParams)
{
    return (projParams.y / (ndcDepth - projParams.x));
}

float realToLinearDepth(float realDepth, float4 projParams)
{
    return ((realDepth / (projParams.y - projParams.x)) + projParams.x);
}

float realToEyeLinearDepth(float realDepth, float4 projParams)
{
    return realDepth / projParams.y;
}

float3 calculateWorlPosition(float realDepth, float3 pixelVec, float3 viewPos, float3 viewVec)
{
    float factor = max(0, dot(viewVec, pixelVec));
    return viewPos + pixelVec * (realDepth / factor);
}

void encodeGBuffer(float3 normalWS, float specPower, float depthLinear, out float4 bufferA)
{
    bufferA = float4(encodeNormal(normalize(half3(normalWS.xyz))), 0);
}

#ifdef BGE_USE_DEFERRED_SHADING
    struct GBuffer
    {
        float4 target0; // normals.xyz / 2bits ?
        float4 target1; // base color, opacity
        float4 target2; // roughness, metalic, AO, ??
        float4 target3; // clear coat roughness, factor, ZW?
        float4 target4; // 2nd Normal
        float4 target5; // emmissive
        float depth;
    };

    struct GBufferData
    {
        float4 baseColor;
        float3 normal;
        float metalic;

        float roughness;
        float ao;
        float realDepth;
        float clearCoatFactor;

        float3 clearCoat2ndNormal;
        float clearCoatRoughnessFactor;

        float3 emissive;
        float padding;
    };
#else
    struct GBuffer
    {
        float4 target0; // normals.xyz / 2bits ?
        float depth;
    };

    struct GBufferData
    {
        float3 normal;
        float realDepth;
    };
#endif

void decodeGBuffer(in GBuffer gbuffer, in float4 projParams, out float3 normalWS, out float realdepth)
{
    normalWS.xyz = decodeNormal(gbuffer.target0.xyz);
    realdepth = ndcToRealDepth(gbuffer.depth, projParams.zw);
}

float4 decodeGBuffer(sampler2D prepassDepthSamplerVar, sampler2D prepassSamplerVar, float2 screenUVVar, float4 projParams)
{
    // Sampler g-buffer
    GBuffer gbuffer = (GBuffer)0;
    gbuffer.depth = tex2Dlod(prepassDepthSamplerVar, float4(screenUVVar,0,0)).r;
    gbuffer.target0 = tex2Dlod(prepassSamplerVar, float4(screenUVVar,0,0));
    float3 outNormalWS;
    float outDepthWS;
    decodeGBuffer(gbuffer, projParams, outNormalWS, outDepthWS);
    return float4( outNormalWS, realToEyeLinearDepth(outDepthWS, projParams));
}

#ifdef BGE_USE_DEFERRED_SHADING

void encodeGBuffer(in GBufferData data, out float4 target0, out float4 target1, out float4 target2, out float4 target3, out float4 target4, out float4 target5 )
{
    target0 = float4(encodeNormal(normalize(half3(data.normal.xyz))), data.baseColor.a);
    target1 = data.baseColor;
    target2 = float4(data.roughness, data.metalic, data.ao, data.baseColor.a);
    target3 = float4(data.clearCoatRoughnessFactor, data.clearCoatFactor, 0, data.baseColor.a);
    target4 = float4(encodeNormal(normalize(half3(data.clearCoat2ndNormal.xyz + 1e-16))), data.baseColor.a);
    target5 = float4(data.emissive, data.baseColor.a);
}

void decodeGBuffer(in GBuffer gbuffer, in float4 projParams, out GBufferData data)
{
    data.normal.xyz = decodeNormal(gbuffer.target0.xyz);
    data.realDepth = ndcToRealDepth(gbuffer.depth, projParams.zw);
    data.baseColor = gbuffer.target1;
    data.roughness = max(0.02, gbuffer.target2.r);
    data.metalic = gbuffer.target2.g;
    data.ao = gbuffer.target2.b;
    data.clearCoatFactor = gbuffer.target3.g;
    data.clearCoatRoughnessFactor = max(0.02, gbuffer.target3.r);
    data.clearCoat2ndNormal = decodeNormal(gbuffer.target4.xyz);
    data.emissive = gbuffer.target5.rgb;
    data.padding = 0;
}
#endif

#endif //GBUFFER_H
