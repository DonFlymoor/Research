
#include "shaders/common/hlsl.h"


#include "farFrustumQuad.hlsl"
#include "lightingUtils.hlsl"
#include "../../lighting.hlsl"
#include "../shadowMap/shadowMapIO_HLSL.h"
#include "softShadow.hlsl"


struct ConvexConnectP
{
   float4 position : SV_Position;
   float4 wsEyeDir : TEXCOORD0;
   float4 ssPos : TEXCOORD1;
   float4 vsEyeDir : TEXCOORD2;
};

#ifdef USE_COOKIE_TEX

/// The texture for cookie rendering.
uniform_sampler2D( cookieMap, 3);

#endif

uniform_sampler2D( prePassBuffer, 0);
uniform_sampler2D( prePassDepthBuffer, 1);
uniform_sampler2D( shadowMap, 2);


float4 main(   ConvexConnectP IN,

               uniform float4 rtParams0,

               uniform float3 lightPosition,
               uniform float4 lightColor,
               uniform float  lightBrightness,
               uniform float  lightRange,
               uniform float2 lightAttenuation,
               uniform float3 lightDirection,
               uniform float4 lightSpotParams,
               uniform float4 lightMapParams,

               uniform float4x4 worldToLightProj,
               uniform float3 eyePosWorld,
               uniform float3 vEye,

               uniform float4 lightParams,
               uniform float shadowSoftness ) : SV_Target0
{   
   // Compute scene UV
   float3 ssPos = IN.ssPos.xyz / IN.ssPos.w;
   float2 uvScene = getUVFromSSPos( ssPos, rtParams0 );

   GBuffer gbuffer = (GBuffer)0;
   gbuffer.depth = tex2Dlod( prePassDepthBuffer, float4(uvScene, 0, 0) ).r;
   gbuffer.target0 = tex2Dlod( prePassBuffer, float4(uvScene, 0, 0) );

   float3 wsEyeVec = normalize(IN.wsEyeDir).xyz;
   
   // Sample/unpack the normal/z data
   float3 normal;
   float depth;
   decodeGBuffer(gbuffer, projParams, normal, depth);
   float3 worldPos = calculateWorlPosition(depth, wsEyeVec, eyePosWorld, normalize(vEye));

   // Build light vec, get length, clip pixel if needed
   float3 lightToPxlVec = worldPos - lightPosition;
   float lenLightV = length( lightToPxlVec );
   lightToPxlVec /= lenLightV;

   //lightDirection = float3( -lightDirection.xy, lightDirection.z ); //float3( 0, 0, -1 );
   float cosAlpha = dot( lightDirection, lightToPxlVec );   
   clip( cosAlpha - lightSpotParams.x );
   clip( lightRange - lenLightV );

   float atten = attenuate( lightColor, lightAttenuation, lenLightV );
   atten *= ( cosAlpha - lightSpotParams.x ) / lightSpotParams.y;
   clip( atten - 1e-6 );
   atten = saturate( atten );
   
   float nDotL = saturate(dot( normal, -lightToPxlVec ));

   // Get the shadow texture coordinate
   float4 pxlPosLightProj = mul( worldToLightProj, float4( worldPos, 1 ) );
   float2 shadowCoord = ( ( pxlPosLightProj.xy / pxlPosLightProj.w ) * 0.5 ) + float2( 0.5, 0.5 );
   shadowCoord.y = 1.0f - shadowCoord.y;

   #ifdef NO_SHADOW
   
      float shadowed = 1.0;
      	
   #else

      // Get a linear depth from the light source.
      float distToLight = pxlPosLightProj.z / pxlPosLightProj.w; // / lightRange;
      #ifdef BGE_USE_REVERSED_DEPTH_BUFFER
         distToLight = 1.0f - distToLight;
      #endif

      float shadowed = softShadow_filter( shadowMap,
                                          ssPos.xy,
                                          shadowCoord,
                                          shadowSoftness,
                                          distToLight,
                                          nDotL,
                                          lightParams.y );

   #endif // !NO_SHADOW
   
   #ifdef USE_COOKIE_TEX

      // Lookup the cookie sample.
      float4 cookie = tex2D( cookieMap, shadowCoord );

      // Multiply the light with the cookie tex.
      lightColor.rgb *= cookie.rgb;

      // Use a maximum channel luminance to attenuate 
      // the lighting else we get specular in the dark
      // regions of the cookie texture.
      atten *= max( cookie.r, max( cookie.g, cookie.b ) );

   #endif

   // NOTE: Do not clip on fully shadowed pixels as it would
   // cause the hardware occlusion query to disable the shadow.

   // Specular term
   float specular = AL_CalcSpecular(   -lightToPxlVec, 
                                       normal, 
                                       -wsEyeVec/*, specPower*/ ) * lightBrightness * atten * shadowed * nDotL; // TODO

   float Sat_NL_Att = saturate( nDotL * atten * shadowed ) * lightBrightness;
   float3 lightColorOut = lightMapParams.rgb * lightColor.rgb;
   float4 addToResult = 0.0;

   // TODO: This needs to be removed when lightmapping is disabled
   // as its extra work per-pixel on dynamic lit scenes.
   //
   // Special lightmapping pass.
   if ( lightMapParams.a < 0.0 )
   {
      // This disables shadows on the backsides of objects.
      shadowed = nDotL < 0.0f ? 1.0f : shadowed;

      Sat_NL_Att = 1.0f;
      shadowed = lerp( 1.0f, shadowed, atten );
      lightColorOut = shadowed;
      specular *= lightBrightness;
      addToResult = ( 1.0 - shadowed ) * abs(lightMapParams);
   }

   return lightinfoCondition( lightColorOut, Sat_NL_Att, specular, addToResult );
}
