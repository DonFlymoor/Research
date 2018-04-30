
#include "shaders/common/bge.hlsl"


#include "farFrustumQuad.hlsl"
#include "lightingUtils.hlsl"
#include "../../lighting.hlsl"
#include "../shadowMap/shadowMapIO_HLSL.h"
#include "softShadow.hlsl"


struct ConvexConnectP
{
   float4 hpos : SV_Position;
   float4 wsEyeDir : TEXCOORD0;
   float4 ssPos : TEXCOORD1;
   float4 vsEyeDir : TEXCOORD2;
};


#ifdef USE_COOKIE_TEX

/// The texture for cookie rendering.
uniform_sampler2D( cookieMap, 3);

#endif


#ifdef SHADOW_CUBE

   float3 decodeShadowCoord( float3 shadowCoord )
   {
      return shadowCoord;
   }

   float4 shadowSample( samplerCUBE shadowMap, float3 shadowCoord )
   {
      return texCUBE( shadowMap, shadowCoord );
   }
  
#else

   float3 decodeShadowCoord( float3 paraVec )
   {
      // Flip y and z
      paraVec = paraVec.xzy;
      
      #ifndef SHADOW_PARABOLOID

         bool calcBack = (paraVec.z < 0.0);
         if ( calcBack )
         {
            paraVec.z = paraVec.z * -1.0;
            
            #ifdef SHADOW_DUALPARABOLOID
               paraVec.x = -paraVec.x;
            #endif
         }

      #endif

      float3 shadowCoord;
      shadowCoord.x = (paraVec.x / (2*(1 + paraVec.z))) + 0.5;
      shadowCoord.y = 1-((paraVec.y / (2*(1 + paraVec.z))) + 0.5);
      shadowCoord.z = 0;
      
      // adjust the co-ordinate slightly if it is near the extent of the paraboloid
      // this value was found via experementation
      // NOTE: this is wrong, it only biases in one direction, not towards the uv 
      // center ( 0.5 0.5 ).
      //shadowCoord.xy *= 0.997;

      #ifndef SHADOW_PARABOLOID

         // If this is the back, offset in the atlas
         if ( calcBack )
            shadowCoord.x += 1.0;
         
         // Atlasing front and back maps, so scale
         shadowCoord.x *= 0.5;

      #endif

      return shadowCoord;
   }

#endif

uniform_sampler2D( prePassBuffer, 0);
uniform_sampler2D( prePassDepthBuffer, 1);

#ifdef SHADOW_CUBE
    uniform_samplerCUBE( shadowMap, 2);
#else
    uniform_sampler2D( shadowMap, 2);
#endif

float4 main(   ConvexConnectP IN,

               uniform float4 rtParams0,

               uniform float3 lightPosition,
               uniform float4 lightColor,
               uniform float  lightBrightness,
               uniform float  lightRange,
               uniform float2 lightAttenuation,
               uniform float4 lightMapParams,

               uniform float3 eyePosWorld,
               uniform float3 vEye,
               uniform float3x3 worldToLightProj,

               uniform float4 lightParams,
               uniform float shadowSoftness ) : SV_Target0
{   
   // Compute scene UV
   float3 ssPos = IN.ssPos.xyz / IN.ssPos.w;
   float2 uvScene = getUVFromSSPos( ssPos, rtParams0 );

   GBuffer gbuffer = (GBuffer)0;
   gbuffer.depth = tex2Dlod( prePassDepthBuffer, float4(uvScene, 0, 0) ).r;
   gbuffer.target0 = tex2Dlod( prePassBuffer, float4(uvScene, 0, 0) );
   float3 wsEyeVec = normalize(IN.wsEyeDir.xyz);

   // Sample/unpack the normal/z data   
   float3 normal;
   float depth;
   decodeGBuffer(gbuffer, projParams, normal, depth);
   float3 worldPos = calculateWorlPosition(depth, wsEyeVec, eyePosWorld, normalize(vEye));
      
   // Build light vec, get length, clip pixel if needed
   float3 lightVec = lightPosition - worldPos;
   float lenLightV = length( lightVec );
   clip( lightRange - lenLightV );

   // Get the attenuated falloff.
   float atten = attenuate( lightColor, lightAttenuation, lenLightV );
   clip( atten - 1e-6 );

   // Normalize lightVec
   lightVec /= lenLightV;
   
   // If we can do dynamic branching then avoid wasting
   // fillrate on pixels that are backfacing to the light.
   float nDotL = saturate(dot( lightVec, normal ));
   //DB_CLIP( nDotL < 0 );

   #ifdef NO_SHADOW
   
      float shadowed = 1.0;
      	
   #else

      // Get a linear depth from the light source.
      float distToLight = lenLightV / lightRange;      

      #ifdef SHADOW_CUBE
              
         // TODO: We need to fix shadow cube to handle soft shadows!
         float occ = texCUBE( shadowMap, mul( worldToLightProj, -lightVec ) ).r;
         float shadowed = saturate( exp( lightParams.y * ( occ - distToLight ) ) );
         
      #else

         float2 shadowCoord = decodeShadowCoord( mul( worldToLightProj, -lightVec ) ).xy;
         
         float shadowed = softShadow_filter( shadowMap,
                                             ssPos.xy,
                                             shadowCoord,
                                             shadowSoftness,
                                             distToLight,
                                             nDotL,
                                             lightParams.y );

      #endif

   #endif // !NO_SHADOW
   
   #ifdef USE_COOKIE_TEX

      // Lookup the cookie sample.
      float4 cookie = tex2D( cookieMap, mul( worldToLightProj, -lightVec ) );

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
   float specular = AL_CalcSpecular(   lightVec, 
                                       normal, 
                                       -wsEyeVec
                                       /*, specPower*/ ) * lightBrightness * atten * shadowed * nDotL; // TODO

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
