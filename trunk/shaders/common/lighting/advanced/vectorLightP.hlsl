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

#ifdef USE_SSAO_MASK
uniform_sampler2D( ssaoMask, 3);
uniform float4 rtParams3;
#endif

//#define PSSM_DEBUG_RENDER

//uniform_sampler2D( prePassBuffer , 0 );

float4 main( FarFrustumQuadConnectP IN,             
             
             uniform float3 lightDirection,
             uniform float4 lightColor,
             uniform float  lightBrightness,
             uniform float4 lightAmbient,
             
             uniform float3 eyePosWorld,
             uniform float3 vEye,
             
             uniform float4x4 worldToLightProj,

             uniform float4 scaleX,
             uniform float4 scaleY,
             uniform float4 offsetX,
             uniform float4 offsetY,
             uniform float4 atlasXOffset,
             uniform float4 atlasYOffset,
             uniform float2 atlasScale,
             uniform float4 zNearFarInvNearFar,
             uniform float4 lightMapParams,

             uniform float2 fadeStartLength,
             uniform float4 farPlaneScalePSSM,
             uniform float4 overDarkPSSM,
             uniform float shadowSoftness ) : SV_Target
{
   // Sample/unpack the normal/z data
   GBuffer gbuffer = (GBuffer)0;
   
#ifdef BGE_USE_DEFERRED_SHADING
   gbuffer.target1 = prePassBuffer1._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
   gbuffer.target2 = prePassBuffer2._texture.SampleLevel( prePassDepthBuffer._filter, IN.uv0, 0, 0 );
#endif
   
   gbuffer.depth = tex2Dlod( prePassDepthBuffer, float4(IN.uv0, 0, 0) ).r;
   gbuffer.target0 = tex2Dlod( prePassBuffer, float4(IN.uv0, 0, 0) );   

   float3 wsEyeVec = normalize(IN.wsEyeRay);

   float4 baseColor;
   float3 normal;
   float metalic;
   float specPower;
   float realDepth;

#ifdef BGE_USE_DEFERRED_SHADING
   decodeGBuffer(gbuffer, projParams, baseColor, normal, metalic, specPower, realDepth);
#else
   decodeGBuffer(gbuffer, projParams, normal,  realDepth);
#endif
   float4 worldPos = float4(calculateWorlPosition(realDepth, wsEyeVec, eyePosWorld, normalize(vEye)), 1);
   
   // Get the light attenuation.
   float dotNL = saturate(dot(-lightDirection, normal));

   #ifdef PSSM_DEBUG_RENDER
      float3 debugColor = 0;
   #endif
   
   #ifdef NO_SHADOW

      // Fully unshadowed.
      float shadowed = 1.0;

      #ifdef PSSM_DEBUG_RENDER
         debugColor = 1.0;
      #endif

   #else

      // Compute shadow map coordinate
      float4 pxlPosLightProj = mul(worldToLightProj, worldPos);
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
                                             IN.uv0.xy,
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

   #endif // !NO_SHADOW

   // Specular term
   float specular = AL_CalcSpecular(   -lightDirection, 
                                       normal, 
                                       -wsEyeVec
                                       #ifdef BGE_USE_DEFERRED_SHADING
                                       , specPower
                                       #endif
                                        ) * lightBrightness * shadowed; // * dotNL; TODO

   float Sat_NL_Att = saturate( dotNL * shadowed ) * lightBrightness;
   float3 lightColorOut = lightMapParams.rgb * lightColor.rgb;
   float4 addToResult = (lightAmbient * (1 - ambientCameraFactor)) + ( lightAmbient * ambientCameraFactor * saturate(dot(-wsEyeVec, normal)) );
   addToResult = calcDiffuseAmbient( lightAmbient, normal);

   // TODO: This needs to be removed when lightmapping is disabled
   // as its extra work per-pixel on dynamic lit scenes.
   //
   // Special lightmapping pass.
   if ( lightMapParams.a < 0.0 )
   {
      // This disables shadows on the backsides of objects.
      shadowed = dotNL < 0.0f ? 1.0f : shadowed;

      Sat_NL_Att = 1.0f;
      lightColorOut = shadowed;
      specular *= lightBrightness;
      addToResult = ( 1.0 - shadowed ) * abs(lightMapParams);
   }

   // Sample the AO texture.      
   #ifdef USE_SSAO_MASK
      float ao = 1.0 - tex2D( ssaoMask, viewportCoordToRenderTarget( IN.uv0.xy, rtParams3 ) ).r;
      addToResult *= ao;
   #endif

   #ifdef PSSM_DEBUG_RENDER
      lightColorOut = debugColor;
   #endif

#ifdef BGE_USE_DEFERRED_SHADING
    float3 diffColor = baseColor.rgb; // * (1 - metalic);
    float3 specColor = 0.04 * (1 - metalic) + baseColor.rgb * metalic;
    lightColorOut = (diffColor * (lightColorOut * Sat_NL_Att)) + (specColor * specular);
    lightColorOut += addToResult.rgb;
    //lightColorOut = Sat_NL_Att;
    return float4(lightColorOut, 1);
#else
    return  lightinfoCondition( lightColorOut, Sat_NL_Att, specular, addToResult );
#endif
}
