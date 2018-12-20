#ifndef LIGHTING_HLSL
#define LIGHTING_HLSL

#include "shaders/common/gbuffer.h"

#define PI 3.14159265358979323846f

#ifndef BGE_SHADERGEN

// These are the uniforms used by most lighting shaders.

uniform float4 inLightPos[3];
uniform float4 inLightInvRadiusSq;
uniform float4 inLightColor[4];

#ifndef BGE_BL_NOSPOTLIGHT
   uniform float4 inLightSpotDir[3];
   uniform float4 inLightSpotAngle;
   uniform float4 inLightSpotFalloff;
#endif

uniform float4 ambient;
#define ambientCameraFactor 0.3
uniform float specularPower;
uniform float4 specularColor;

#ifdef BGE_COMPUTE_4_LIGHTS_BACKLIGHT
uniform float backLighting;
#endif //BGE_COMPUTE_4_LIGHTS_BACKLIGHT

#endif // !BGE_SHADERGEN

// ------------------------------------------------------------------------------

struct LightData
{
   float3 inLightPos;
   float inLightInvRadiusSq;
   float4 inLightColor;
   float3 inLightSpotDir;
   float inLightSpotAngle;
   float inLightSpotFalloff;
   float  inLightId;
   float2 inLightPadding;
};

#if BGE_SM >= 50

StructuredBuffer<LightData> LightDataBuffer : register(t127);

#define loadLightData(i, data) data = LightDataBuffer[i];

#else

Texture2D<float4> LightDataBuffer : register(t127);

void loadLightData(uint i, out LightData data)
{
   i *= 4; // sizeof LightData
   float4 dataA = LightDataBuffer.Load( indexTo2D(i+0) );
   float4 dataB = LightDataBuffer.Load( indexTo2D(i+1) );
   float4 dataC = LightDataBuffer.Load( indexTo2D(i+2) );
   float4 dataD = LightDataBuffer.Load( indexTo2D(i+3) );

   data.inLightPos = dataA.xyz;
   data.inLightInvRadiusSq = dataA.w;
   data.inLightColor = dataB;
   data.inLightSpotDir = dataC.xyz;
   data.inLightSpotAngle = dataC.w;
   data.inLightSpotFalloff = dataD.x;
   data.inLightId = dataD.y;
   data.inLightPadding = dataD.zw;
}

#endif

void getLightData( in uint4 ids, out float4 outLightPos[3], out float4 outLightInvRadiusSq, out float4 outLightColor[4], out float4 outLightSpotDir[3], out float4 outLightSpotAngle, out float4 outLightSpotFalloff )
{
   LightData lights0 = (LightData)0;
   LightData lights1 = (LightData)0;
   LightData lights2 = (LightData)0;
   LightData lights3 = (LightData)0;
   
   [branch] if(ids.x) loadLightData(ids.x, lights0);
   [branch] if(ids.y) loadLightData(ids.y, lights1);
   [branch] if(ids.z) loadLightData(ids.z, lights2);
   [branch] if(ids.w) loadLightData(ids.w, lights3);

   //inLightPos
   outLightPos[0].x = lights0.inLightPos.x;
   outLightPos[1].x = lights0.inLightPos.y;
   outLightPos[2].x = lights0.inLightPos.z;

   outLightPos[0].y = lights1.inLightPos.x;
   outLightPos[1].y = lights1.inLightPos.y;
   outLightPos[2].y = lights1.inLightPos.z;

   outLightPos[0].z = lights2.inLightPos.x;
   outLightPos[1].z = lights2.inLightPos.y;
   outLightPos[2].z = lights2.inLightPos.z;

   outLightPos[0].w = lights3.inLightPos.x;
   outLightPos[1].w = lights3.inLightPos.y;
   outLightPos[2].w = lights3.inLightPos.z;

   //outLightInvRadiusSq
   outLightInvRadiusSq = float4(lights0.inLightInvRadiusSq, lights1.inLightInvRadiusSq, lights2.inLightInvRadiusSq, lights3.inLightInvRadiusSq);

   //outLightColor
   outLightColor[0] = lights0.inLightColor;
   outLightColor[1] = lights1.inLightColor;
   outLightColor[2] = lights2.inLightColor;
   outLightColor[3] = lights3.inLightColor;

   //outLightSpotDir
   outLightSpotDir[0].x = lights0.inLightSpotDir.x;
   outLightSpotDir[1].x = lights0.inLightSpotDir.y;
   outLightSpotDir[2].x = lights0.inLightSpotDir.z;

   outLightSpotDir[0].y = lights1.inLightSpotDir.x;
   outLightSpotDir[1].y = lights1.inLightSpotDir.y;
   outLightSpotDir[2].y = lights1.inLightSpotDir.z;

   outLightSpotDir[0].z = lights2.inLightSpotDir.x;
   outLightSpotDir[1].z = lights2.inLightSpotDir.y;
   outLightSpotDir[2].z = lights2.inLightSpotDir.z;

   outLightSpotDir[0].w = lights3.inLightSpotDir.x;
   outLightSpotDir[1].w = lights3.inLightSpotDir.y;
   outLightSpotDir[2].w = lights3.inLightSpotDir.z;

   //outLightSpotAngle
   outLightSpotAngle = float4(lights0.inLightSpotAngle, lights1.inLightSpotAngle, lights2.inLightSpotAngle, lights3.inLightSpotAngle);

   //outLightSpotFalloff
   outLightSpotFalloff = float4(lights0.inLightSpotFalloff, lights1.inLightSpotFalloff, lights2.inLightSpotFalloff, lights3.inLightSpotFalloff);
}

void compute4Lights( float3 wsView, 
                     float3 wsPosition, 
                     float3 wsNormal,
                     float4 shadowMask,

                     #ifdef BGE_SHADERGEN
                        uint4  inLightId,                        
                        float specularPower,
                        float4 specularColor,

                     #endif // BGE_SHADERGEN
                     
                     out float4 outDiffuse,
                     out float4 outSpecular )
{
#ifdef BGE_SHADERGEN
   float4 inLightPos[3];
   float4 inLightInvRadiusSq;
   float4 inLightColor[4];
   float4 inLightSpotDir[3];
   float4 inLightSpotAngle;
   float4 inLightSpotFalloff;

   getLightData(inLightId, inLightPos, inLightInvRadiusSq, inLightColor, inLightSpotDir, inLightSpotAngle, inLightSpotFalloff);
#endif


   // NOTE: The light positions and spotlight directions
   // are stored in SoA order, so inLightPos[0] is the
   // x coord for all 4 lights... inLightPos[1] is y... etc.
   //
   // This is the key to fully utilizing the vector units and
   // saving a huge amount of instructions.
   //
   // For example this change saved more than 10 instructions 
   // over a simple for loop for each light.
   
   int i;

   float4 lightVectors[3];
   for ( i = 0; i < 3; i++ )
      lightVectors[i] = wsPosition[i] - inLightPos[i];

   float4 squareDists = 0;
   for ( i = 0; i < 3; i++ )
      squareDists += lightVectors[i] * lightVectors[i];

   // Accumulate the dot product between the light 
   // vector and the normal.
   //
   // The normal is negated because it faces away from
   // the surface and the light faces towards the
   // surface... this keeps us from needing to flip
   // the light vector direction which complicates
   // the spot light calculations.
   //
   // We normalize the result a little later.
   //   
   float4 nDotL = 0;
   for ( i = 0; i < 3; i++ )
#ifndef BGE_COMPUTE_4_LIGHTS_BACKLIGHT
      nDotL += lightVectors[i] * -wsNormal[i];
#else
      nDotL += (lightVectors[i] * -wsNormal[i] * (1 - backLighting)) + (lightVectors[i] * lightVectors[i] * backLighting);
#endif //BGE_COMPUTE_4_LIGHTS_BACKLIGHT

   float4 rDotL = 0;
   #ifndef BGE_BL_NOSPECULAR

      // We're using the Phong specular reflection model
      // here where traditionally Torque has used Blinn-Phong
      // which has proven to be more accurate to real materials.
      //
      // We do so because its cheaper as do not need to 
      // calculate the half angle for all 4 lights.
      //   
      // Advanced Lighting still uses Blinn-Phong, but the
      // specular reconstruction it does looks fairly similar
      // to this.
      //
      float3 R = reflect( wsView, -wsNormal );

      for ( i = 0; i < 3; i++ )
         rDotL += lightVectors[i] * R[i];

   #endif
 
   // Normalize the dots.
   //
   // Notice we're using the half type here to get a
   // much faster sqrt via the rsq_pp instruction at 
   // the loss of some precision.
   //
   // Unless we have some extremely large point lights
   // i don't believe the precision loss will matter.
   //
   half4 correction = (half4)rsqrt( squareDists );
   nDotL = saturate( nDotL * correction );
   rDotL = clamp( rDotL * correction, 0.00001, 1.0 );

   // First calculate a simple point light linear 
   // attenuation factor.
   //
   // If this is a directional light the inverse
   // radius should be greater than the distance
   // causing the attenuation to have no affect.
   //
   float4 atten = saturate( 1.0 - ( squareDists * inLightInvRadiusSq ) );

   #ifndef BGE_BL_NOSPOTLIGHT

      // The spotlight attenuation factor.  This is really
      // fast for what it does... 6 instructions for 4 spots.

      float4 spotAtten = 0;
      for ( i = 0; i < 3; i++ )
         spotAtten += lightVectors[i] * inLightSpotDir[i];

      float4 cosAngle = ( spotAtten * correction ) - inLightSpotAngle;
      atten *= saturate( cosAngle * inLightSpotFalloff );

   #endif

   // Finally apply the shadow masking on the attenuation.
   atten *= shadowMask;

   // Get the final light intensity.
   float4 intensity = nDotL * atten;

   // Combine the light colors for output.
   outDiffuse = 0;
   for ( i = 0; i < 4; i++ )
      outDiffuse += intensity[i] * inLightColor[i];

   // Output the specular power.
   specularPower = max(specularPower, 1.0f);
   float specNorm = ( specularPower + 8 ) / (8 * PI);
   float4 specularIntensity = pow( rDotL, specularPower) * specNorm * atten;
   
   // Apply the per-light specular attenuation.
   float4 specular = float4(0,0,0,1);
   for ( i = 0; i < 4; i++ )
      specular += float4( inLightColor[i].rgb * inLightColor[i].a * specularIntensity[i], 1);

   // Add the final specular intensity values together
   // using a single dot product operation then get the
   // final specular lighting color.
   outSpecular = specularColor * specular;
}


// This value is used in AL as a constant power to raise specular values
// to, before storing them into the light info buffer. The per-material 
// specular value is then computer by using the integer identity of 
// exponentiation: 
//
//    (a^m)^n = a^(m*n)
//
//       or
//
//    (specular^constSpecular)^(matSpecular/constSpecular) = specular^(matSpecular*constSpecular)   
//
#define AL_ConstantSpecularPower 12.0f

/// The specular calculation used in Advanced Lighting.
///
///   @param toLight    Normalized vector representing direction from the pixel 
///                     being lit, to the light source, in world space.
///
///   @param normal  Normalized surface normal.
///   
///   @param toEye   The normalized vector representing direction from the pixel 
///                  being lit to the camera.
///
float AL_CalcSpecular( float3 L, float3 N, float3 V ) // TODO REMOVE
{
    float3 H = normalize( L + V );
    float dNH = saturate(dot( N, H ));
    return pow(dNH, AL_ConstantSpecularPower);
}

float AL_CalcSpecular( float3 L, float3 N, float3 V, float specPower )
{
    specPower = max(1, specPower);
    float3 H = normalize( L + V );
    float dNH = saturate(dot( N, H ));
    float dNL = saturate(dot( N, L ));
    float normalization = (specPower + 8) / (8 * PI);
    return normalization * pow(dNH, specPower) * dNL;
}

float AL_CalcSpecular2( float3 L, float3 N, float3 V, float specPower )
{
    specPower = max(1, specPower);
    float3 H = normalize( L + V );
    float dNH = max(0.0001, saturate(dot(N, H)));
    float dLH = saturate(dot(L, H));
    float dNL = saturate(dot(N, L));
    return ((specPower + 1)/(8 * pow(dLH, 3))) * pow(dNH, specPower);
}

#define NON_METALIC_SPECULAR_COLOR 0.04

float specularD( float roughness, float dotNH  )
{
    float a = roughness * roughness;
    float a2 = a * a;
    float temp = (dotNH * dotNH) * (a2-1) + 1;
    return a2 / (PI * temp * temp);
}

float specularG( float roughness, float dotNV, float dotNL )
{
    // include specular denominator
    float a = roughness * roughness;
    float a2 = a * a;
    float GV = dotNL * sqrt((dotNV - a2 * dotNV) * dotNV + a2);
    float GL = dotNV * sqrt((dotNL - a2 * dotNL) * dotNL + a2);
    return 0.5 / (GV + GL);
}

float3 specularF( float3 f0, float dotVH )
{
    return f0 + (1 - f0) * pow(1.0 - dotVH, 5.0);
}

float3 EnvironmentBRDF_Aprox( float3 specColor, float roughness, float dotNV)
{
    float4 t = float4( 1/0.96, 0.475, (0.0275 -0.25 * 0.04)/0.96, 0.25 );
    t *= (1 - roughness);
    t += float4(0, 0, (0.015 -0.75 * 0.04)/0.96, 0.75 );
    float a0 = t.x * min( t.y, exp2( -9.28 * dotNV ) ) + t.z;
    float a1 = t.w;
    return saturate( a0 + specColor * ( a1 - a0 ));
}

float3 toCubeMapCoords(float3 normal)
{
    return float3(normal.x, normal.z, normal.y);
}

float4 calcDiffuseAmbient( float4 upAmbColor, float3 normal )
{
   float4 downAmbColor = upAmbColor * 0.5f;

   float NdotL = clamp( dot( normal, float3(0, 0, 1.0f) ), -1 , 1);
   float factor = ( NdotL * 0.5f ) + 0.5f;
   return lerp( downAmbColor, upAmbColor, factor );
}

float3 FresnelSchlickWithRoughness(float3 SpecularColor, float3 V, float3 N, float roughness)
{
   return SpecularColor + (max(1.0f - roughness, SpecularColor) - SpecularColor) * pow(1 - saturate(dot(V, N)), 5);
}

float3 FresnelSchlickWithRoughness2(float3 SpecularColor, float3 V, float3 N, float roughness)
{
   float F0 = pow(1 - saturate(dot(V, N)), 5);
   return F0 + (1.0f - F0) * SpecularColor;
}

//------------------------------------------------------------------------------
// Autogenerated 'Light Buffer Conditioner [RGB]' Condition Method
//------------------------------------------------------------------------------
inline float4 lightinfoCondition(in float3 lightColor, in float NL_att, in float specular, in float4 bufferSample)
{
   float4 rgbLightInfoOut = float4(lightColor, 0) * NL_att + float4(bufferSample.rgb, specular);

   return rgbLightInfoOut;
}


//------------------------------------------------------------------------------
// Autogenerated 'Light Buffer Conditioner [RGB]' Uncondition Method
//------------------------------------------------------------------------------
inline void lightinfoUncondition(in float4 bufferSample, out float3 lightColor, out float NL_att, out float specular)
{
   lightColor = bufferSample.rgb;
   NL_att = dot(bufferSample.rgb, float3(0.3576, 0.7152, 0.1192));
   specular = bufferSample.a;
}


#endif //LIGHTING_HLSL
