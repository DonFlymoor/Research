#include "shaders/common/bge.hlsl"

#include "farFrustumQuad.hlsl"
#include "../../lighting.hlsl"
#include "lightingUtils.hlsl"
#include "../shadowMap/shadowMapIO_HLSL.h"
#include "softShadow.hlsl"

uniform_sampler2D( prePassBuffer, 0);
uniform_sampler2D( prePassDepthBuffer, 1);
uniform_sampler2D( ShadowMap, 2);

uniform_sampler2D( prePassBuffer1, 5);
uniform_sampler2D( prePassBuffer2, 6);
uniform_sampler2D( prePassBuffer3, 7);

// IBL
uniform_samplerCUBE( diffIBL, 8);
uniform_samplerCUBE( specIBL, 9);

uniform_sampler2D( prePassBuffer4, 10);
uniform_sampler2D( prePassBuffer5, 11);

#ifdef USE_SSAO_MASK
uniform_sampler2D( ssaoMask, 3);
uniform float4 rtParams3;
#endif

//#define PSSM_DEBUG_RENDER

//uniform_sampler2D( prePassBuffer , 0 );

uniform float3 lightDirection;
uniform float4 lightColor;
uniform float  lightBrightness;
uniform float4 lightAmbient;

uniform float3 eyePosWorld;
uniform float3 vEye;

uniform float4x4 worldToLightProj;

uniform float4 scaleX;
uniform float4 scaleY;
uniform float4 offsetX;
uniform float4 offsetY;
uniform float4 atlasXOffset;
uniform float4 atlasYOffset;
uniform float2 atlasScale;
uniform float4 zNearFarInvNearFar;
uniform float4 lightMapParams;

uniform float2 fadeStartLength;
uniform float4 farPlaneScalePSSM;
uniform float4 overDarkPSSM;
uniform float shadowSoftness;

float calcShadowPSSM(float3 worldPos, float realDepth, float2 uv, float dotNL, inout float3 debugColor)
{
    debugColor = 0;

    // Compute shadow map coordinate
    float4 pxlPosLightProj = mul(worldToLightProj, float4(worldPos,1));
    #ifdef BGE_USE_REVERSED_DEPTH_BUFFER
    pxlPosLightProj.z = pxlPosLightProj.w - pxlPosLightProj.z;
    #endif
    float2 baseShadowCoord = pxlPosLightProj.xy / pxlPosLightProj.w;

    // Distance to light, in shadowmap space
    float distToLight = pxlPosLightProj.z / pxlPosLightProj.w;
        
    // Figure out which split to sample from.  Basically, we compute the shadowmap sample coord
    // for all of the splits and then check if its valid.  
    float4 shadowCoordX = baseShadowCoord.xxxx;
    float4 shadowCoordY = baseShadowCoord.yyyy;
    float4 farPlaneDists = distToLight.xxxx;      
    shadowCoordX *= scaleX;
    shadowCoordY *= scaleY;
    shadowCoordX += offsetX;
    shadowCoordY += offsetY;
    farPlaneDists *= farPlaneScalePSSM;
    
    // If the shadow sample is within -1..1 and the distance 
    // to the light for this pixel is less than the far plane 
    // of the split, use it.
    float4 finalMask;
    if (  shadowCoordX.x > -0.99 && shadowCoordX.x < 0.99 && 
        shadowCoordY.x > -0.99 && shadowCoordY.x < 0.99 &&
        farPlaneDists.x < 1.0 )
        finalMask = float4(1, 0, 0, 0);

    else if (   shadowCoordX.y > -0.99 && shadowCoordX.y < 0.99 &&
                shadowCoordY.y > -0.99 && shadowCoordY.y < 0.99 && 
                farPlaneDists.y < 1.0 )
        finalMask = float4(0, 1, 0, 0);

    else if (   shadowCoordX.z > -0.99 && shadowCoordX.z < 0.99 && 
                shadowCoordY.z > -0.99 && shadowCoordY.z < 0.99 && 
                farPlaneDists.z < 1.0 )
        finalMask = float4(0, 0, 1, 0);
        
    else
        finalMask = float4(0, 0, 0, 1);
        

#ifdef PSSM_DEBUG_RENDER
    if ( finalMask.x > 0 )
        debugColor += float3( 1, 0, 0 );
    else if ( finalMask.y > 0 )
        debugColor += float3( 0, 1, 0 );
    else if ( finalMask.z > 0 )
        debugColor += float3( 0, 0, 1 );
    else if ( finalMask.w > 0 )
        debugColor += float3( 1, 1, 0 );
#endif

    // Here we know what split we're sampling from, so recompute the texcoord location
    // Yes, we could just use the result from above, but doing it this way actually saves
    // shader instructions.
    float2 finalScale;
    finalScale.x = dot(finalMask, scaleX);
    finalScale.y = dot(finalMask, scaleY);

    float2 finalOffset;
    finalOffset.x = dot(finalMask, offsetX);
    finalOffset.y = dot(finalMask, offsetY);

    float2 shadowCoord;                  
    shadowCoord = baseShadowCoord * finalScale;      
    shadowCoord += finalOffset;

    // Convert to texcoord space
    shadowCoord = 0.5 * shadowCoord + float2(0.5, 0.5);
    shadowCoord.y = 1.0f - shadowCoord.y;

    // Move around inside of atlas 
    float2 aOffset;
    aOffset.x = dot(finalMask, atlasXOffset);
    aOffset.y = dot(finalMask, atlasYOffset);

    shadowCoord *= atlasScale;
    shadowCoord += aOffset;
            
    // Each split has a different far plane, take this into account.
    float farPlaneScale = dot( farPlaneScalePSSM, finalMask );
    distToLight *= farPlaneScale;
    
    float shadowed = softShadow_filter(   ShadowMap,
                                            uv.xy,
                                            shadowCoord,
                                            farPlaneScale * shadowSoftness,
                                            distToLight,
                                            dotNL,
                                            dot( finalMask, overDarkPSSM ) );

    // Fade out the shadow at the end of the range.
    float4 zDist = realDepth; //(zNearFarInvNearFar.x + zNearFarInvNearFar.y * depth);
    float fadeOutAmt = ( zDist.x - fadeStartLength.x ) * fadeStartLength.y;
    shadowed = lerp( shadowed, 1.0, saturate( fadeOutAmt ) );

#ifdef PSSM_DEBUG_RENDER
    if ( fadeOutAmt > 1.0 )
        debugColor = 1.0;
#endif
    return shadowed;
}

#ifdef BGE_USE_DEFERRED_SHADING
float3 calculateDirectLight(in GBufferData material, float3 lightColor, float3 L, float3 V, float dotNH, float dotNV, float dotNL, float dotVH)
{
    float3 energy = 1;
    float3 attenLightColor = lightColor * PI; //TODO remove PI
    float3 lightOut = 0;
    float3 specColor = (NON_METALIC_SPECULAR_COLOR * (1 - material.metalic)) + (material.baseColor.rgb * material.metalic);

    // clear coat
    if(material.clearCoatFactor)
    {
        float D = specularD( material.clearCoatRoughnessFactor, dotNH );
        float G = specularG( material.clearCoatRoughnessFactor, dotNV, dotNL );
        float3 F = specularF( NON_METALIC_SPECULAR_COLOR, dotVH );
        float3 specular = saturate(D * F * G) * material.clearCoatFactor; // TODO why saturate?
        lightOut += dotNL * specular * energy;
        energy *= 1 - specular;
        material.roughness = max(material.roughness, material.clearCoatRoughnessFactor);

        float3 H = normalize( L + V );
        dotNL = max(1e-5, dot(material.clearCoat2ndNormal, L));
        dotNV = max(1e-5, dot(material.clearCoat2ndNormal, V));
        dotVH = max(1e-5, dot(V, H));
        dotNH = max(1e-5, dot(material.clearCoat2ndNormal, H));
    }

    // specular
    {
        float D = specularD( material.roughness, dotNH );
        float G = specularG( material.roughness, dotNV, dotNL );
        float3 F = specularF( specColor, dotVH );
        float3 specular = saturate(D * F * G);  // TODO why saturate?
        lightOut += dotNL * specular * energy;
        energy *= 1 - specular;
    }
    
    // diffuse
    lightOut +=  dotNL * (material.baseColor.rgb/PI) * energy;
    return lightOut * attenLightColor;
}

float3 calculateAmbientLight(in GBufferData material, float dotNV, float3 V)
{
    float3 energy = 1;
    float3 specColor = (NON_METALIC_SPECULAR_COLOR * (1 - material.metalic)) + (material.baseColor.rgb * material.metalic);
    float3 lightColorOut = 0;
    float3 R = 2 * dotNV * material.normal - V;

    // clear coat
    if(material.clearCoatFactor)
    {
        float3 specLight = material.ao * texCUBElod( specIBL, float4(toCubeMapCoords(R), lerp(0, 7, material.clearCoatRoughnessFactor))).rgb;
        float3 specular = EnvironmentBRDF_Aprox(NON_METALIC_SPECULAR_COLOR, material.clearCoatRoughnessFactor, dotNV) * material.clearCoatFactor;
        lightColorOut += specLight * specular * energy;
        energy *= 1 - specular;
        material.roughness = max(material.roughness, material.clearCoatRoughnessFactor * material.clearCoatFactor);
        
        dotNV = max(1e-5, dot(material.clearCoat2ndNormal, V));
        R = 2 * dotNV * material.clearCoat2ndNormal - V;
    }

    {
        //specular
        float3 specLight = material.ao * texCUBElod( specIBL, float4(toCubeMapCoords(R), lerp(0, 7, material.roughness))).rgb;
        float3 specular = EnvironmentBRDF_Aprox(specColor, material.roughness, dotNV);
        lightColorOut += specLight * specular * energy;
        energy *= 1 - specular;
    }

    {
        // diffuse
        float3 ambDiff = material.ao * texCUBE( diffIBL, toCubeMapCoords(material.normal) ).rgb;
        lightColorOut += (material.baseColor.rgb) * ambDiff * energy;
    }
    return lightColorOut;
}
#endif


float4 main( FarFrustumQuadConnectP IN ) : SV_Target
{
   // Sample/unpack the normal/z data
   GBuffer gbuffer = (GBuffer)0;
   
   gbuffer.depth = tex2Dlod( prePassDepthBuffer, float4(IN.uv0, 0, 0) ).r;
   gbuffer.target0 = tex2Dlod( prePassBuffer, float4(IN.uv0, 0, 0) );   
   
#ifdef BGE_USE_DEFERRED_SHADING
   gbuffer.target1 = prePassBuffer1._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
   gbuffer.target2 = prePassBuffer2._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
   gbuffer.target3 = prePassBuffer3._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
   gbuffer.target4 = prePassBuffer4._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
   gbuffer.target5 = prePassBuffer5._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
#endif 

   float3 wsEyeVec = normalize(IN.wsEyeRay);

   GBufferData material = (GBufferData)0;

#ifdef BGE_USE_DEFERRED_SHADING
   decodeGBuffer(gbuffer, projParams, material);
#else
   decodeGBuffer(gbuffer, projParams, material.normal,  material.realDepth);
#endif

   float3 worldPos = calculateWorlPosition(material.realDepth, wsEyeVec, eyePosWorld, normalize(vEye));   
   float3 H = normalize( -lightDirection + -wsEyeVec );
   float dotNL = max(1e-5, dot(material.normal, -lightDirection));
   float dotNV = max(1e-5, dot(material.normal, -wsEyeVec));
   float dotVH = max(1e-5, dot(-wsEyeVec, H));
   float dotNH = max(1e-5, dot(material.normal, H));

    float3 debugColor = 1;

    // Fully unshadowed.
    float unshadowed = 1.0;

    // Sample the AO texture.
    float ssao = 1.0;
   #ifdef USE_SSAO_MASK
      ssao = 1.0 - tex2D( ssaoMask, viewportCoordToRenderTarget( IN.uv0.xy, rtParams3 ) ).r;
   #endif
   
   #ifndef NO_SHADOW
      unshadowed = calcShadowPSSM(worldPos, material.realDepth, IN.uv0, dotNL, debugColor);
   #endif // !NO_SHADOW

   float Sat_NL_Att = saturate( dotNL * unshadowed ) * lightBrightness;
   float3 lightColorOut = lightMapParams.rgb * lightColor.rgb;   

   #ifdef PSSM_DEBUG_RENDER
      lightColorOut = debugColor;
   #endif

#ifdef BGE_USE_DEFERRED_SHADING
    lightColorOut *= unshadowed * lightBrightness;
    material.ao *= ssao;
    float3 lightOut = calculateDirectLight(material, lightColorOut, -lightDirection, -wsEyeVec, dotNH, dotNV, dotNL, dotVH);
    lightOut += calculateAmbientLight(material, dotNV, -wsEyeVec);
    lightOut += material.emissive;
    return float4(lightOut, 1);
#else
   // Specular term
   float specular = AL_CalcSpecular(   -lightDirection, material.normal, -wsEyeVec ) * lightBrightness * unshadowed; // * dotNL; TODO   
   float4 addToResult = calcDiffuseAmbient( lightAmbient, material.normal) * ssao;
    return  lightinfoCondition( lightColorOut, Sat_NL_Att, specular, addToResult );
#endif
}
