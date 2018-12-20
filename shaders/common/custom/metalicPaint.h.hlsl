
float calculateFlakesFactor(in Texture2D metallicFlakesMaskMap, in float2 uv0, float flakeScale, float flakeMovement)
{
    uv0 *= flakeScale;
    float rn = 0.48;
    float3 pos = eyePosWorld * 100;
    float value = (pos.x / (0.5 * flakeMovement)) + (pos.y / (0.8 * flakeMovement)) + (pos.z / (0.8 * flakeMovement));
    float mask0 = metallicFlakesMaskMap.Sample(defaultSampler2D, uv0 + (floor(value) * rn)).r;
    float mask1 = metallicFlakesMaskMap.Sample(defaultSampler2D, uv0 + (ceil(value) * rn)).r;
    return max(0, lerp(mask0, mask1, frac(value)));
}

void processCustomMaterial(inout float4 baseColor, inout float3 normalWS, inout float roughness, in float2 uv0, in float3x3 worldToTangent, 
    in Texture2D flakesFactorMap, in Texture2D metallicFlakesMaskMap, in Texture2D metallicFlakesNormalMap,
    float flakePower, float4 flakeColor, float flakeMovement, float maskScale, float normalScale, float flakeRoughness)
{
    float flakesFactor = flakesFactorMap.Sample(defaultSampler2D, uv0).r;
    if(flakesFactor < 0.001) return;

    flakesFactor = flakesFactor * pow(calculateFlakesFactor(metallicFlakesMaskMap, uv0, maskScale, flakeMovement), flakePower);
    float3 flakesNormal = metallicFlakesNormalMap.Sample(defaultSampler2D, uv0 * normalScale).xyz * 2.0 - 1;
    flakesNormal = normalize( mul( flakesNormal.xyz, worldToTangent ) );

    baseColor = lerp(baseColor, flakeColor, flakesFactor);
    normalWS = normalize(lerp(normalWS, flakesNormal, flakesFactor));
    roughness = lerp(roughness, flakeRoughness, flakesFactor);
}
