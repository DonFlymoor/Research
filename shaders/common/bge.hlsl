
#ifndef _BGE_HLSL_
#define _BGE_HLSL_

#if defined(BGE_SHADERGEN)
uniform SamplerState defaultSampler2D : register(S0);
uniform SamplerState defaultSamplerCube : register(S1);
uniform SamplerState defaultSamplerRT : register(S2);
uniform SamplerState defaultSamplerPoint : register(S3);
#endif

#include "shaders/common/hlsl.h"

static float M_HALFPI_F   = 1.57079632679489661923f;
static float M_PI_F       = 3.14159265358979323846f;
static float M_2PI_F      = 6.28318530717958647692f;


/// Calculate fog based on a start and end positions in worldSpace.
float computeSceneFog(  float3 startPos,
                        float3 endPos,
                        float fogDensity,
                        float fogDensityOffset,
                        float fogHeightFalloff )
{      
   float f = length( startPos - endPos ) - fogDensityOffset;
   float h = 1.0 - ( endPos.z * fogHeightFalloff );  
   return exp( -fogDensity * f * h );  
}


/// Calculate fog based on a start and end position and a height.
/// Positions do not need to be in worldSpace but height does.
float computeSceneFog( float3 startPos,
                       float3 endPos,
                       float height,
                       float fogDensity,
                       float fogDensityOffset,
                       float fogHeightFalloff )
{
   float f = length( startPos - endPos ) - fogDensityOffset;
   float h = 1.0 - ( height * fogHeightFalloff );
   return exp( -fogDensity * f * h );
}


/// Calculate fog based on a distance, height is not used.
float computeSceneFog( float dist, float fogDensity, float fogDensityOffset )
{
   float f = dist - fogDensityOffset;
   return exp( -fogDensity * f );
}


/// Convert a float4 uv in viewport space to render target space.
float2 viewportCoordToRenderTarget( float4 inCoord, float4 rtParams )
{   
   float2 outCoord = inCoord.xy / inCoord.w;
   outCoord = ( outCoord * rtParams.zw ) + rtParams.xy;  
   return outCoord;
}


/// Convert a float2 uv in viewport space to render target space.
float2 viewportCoordToRenderTarget( float2 inCoord, float4 rtParams )
{   
   float2 outCoord = ( inCoord * rtParams.zw ) + rtParams.xy;
   return outCoord;
}


/// Convert a float4 quaternion into a 3x3 matrix.
float3x3 quatToMat( float4 quat )
{
   float xs = quat.x * 2.0f;
   float ys = quat.y * 2.0f;
   float zs = quat.z * 2.0f;

   float wx = quat.w * xs;
   float wy = quat.w * ys;
   float wz = quat.w * zs;
   
   float xx = quat.x * xs;
   float xy = quat.x * ys;
   float xz = quat.x * zs;
   
   float yy = quat.y * ys;
   float yz = quat.y * zs;
   float zz = quat.z * zs;
   
   float3x3 mat;
   
   mat[0][0] = 1.0f - (yy + zz);
   mat[0][1] = xy - wz;
   mat[0][2] = xz + wy;

   mat[1][0] = xy + wz;
   mat[1][1] = 1.0f - (xx + zz);
   mat[1][2] = yz - wx;

   mat[2][0] = xz - wy;
   mat[2][1] = yz + wx;
   mat[2][2] = 1.0f - (xx + yy);   

   return mat;
}


/// The number of additional substeps we take when refining
/// the results of the offset parallax mapping function below.
///
/// You should turn down the number of steps if your needing
/// more performance out of your parallax surfaces.  Increasing
/// the number doesn't yeild much better results and is rarely
/// worth the additional cost.
///
#define PARALLAX_REFINE_STEPS 3

/// Performs fast parallax offset mapping using 
/// multiple refinement steps.
///
/// @param texMap The texture map whos alpha channel we sample the parallax depth.
/// @param texCoord The incoming texture coordinate for sampling the parallax depth.
/// @param negViewTS The negative view vector in tangent space.
/// @param depthScale The parallax factor used to scale the depth result.
///
float2 parallaxOffset( sampler2D texMap, float2 texCoord, float3 negViewTS, float depthScale )
{
   float depth = tex2D( texMap, texCoord ).a;
   float2 offset = negViewTS.xy * ( depth * depthScale );

   for ( int i=0; i < PARALLAX_REFINE_STEPS; i++ )
   {
      depth = ( depth + tex2D( texMap, texCoord + offset ).a ) * 0.5;
      offset = negViewTS.xy * ( depth * depthScale );
   }

   return offset;
}

#if defined(BGE_SHADERGEN)
float2 parallaxOffset( Texture2D texMap, float2 texCoord, float3 negViewTS, float depthScale )
{
   float depth = texMap.Sample(defaultSampler2D, texCoord ).a;
   float2 offset = negViewTS.xy * ( depth * depthScale );

   for ( int i=0; i < PARALLAX_REFINE_STEPS; i++ )
   {
      depth = ( depth + texMap.Sample(defaultSampler2D, texCoord + offset ).a ) * 0.5;
      offset = negViewTS.xy * ( depth * depthScale );
   }

   return offset;
}
#endif


/// The maximum value for 16bit per component integer HDR encoding.
static const float HDR_RGB16_MAX = 100.0;

/// The maximum value for 10bit per component integer HDR encoding.
static const float HDR_RGB10_MAX = 4.0;

/// Encodes an HDR color for storage into a target.
float3 hdrEncode( float3 sample )
{
   #if defined( BGE_HDR_RGB16 )

      return sample / HDR_RGB16_MAX;

   #elif defined( BGE_HDR_RGB10 ) 

      return sample / HDR_RGB10_MAX;

   #else

      // No encoding.
      return sample;

   #endif
}

/// Encodes an HDR color for storage into a target.
float4 hdrEncode( float4 sample )
{
   return float4( hdrEncode( sample.rgb ), sample.a );
}

/// Decodes an HDR color from a target.
float3 hdrDecode( float3 sample )
{
   #if defined( BGE_HDR_RGB16 )

      return sample * HDR_RGB16_MAX;

   #elif defined( BGE_HDR_RGB10 )

      return sample * HDR_RGB10_MAX;

   #else

      // No encoding.
      return sample;

   #endif
}

/// Decodes an HDR color from a target.
float4 hdrDecode( float4 sample )
{
   return float4( hdrDecode( sample.rgb ), sample.a );
}

/// Returns the luminance for an HDR pixel.
float hdrLuminance( float3 sample )
{
   // There are quite a few different ways to
   // calculate luminance from an rgb value.
   //
   // If you want to use a different technique
   // then plug it in here.
   //

   ////////////////////////////////////////////////////////////////////////////
   //
   // Max component luminance.
   //
   //float lum = max( sample.r, max( sample.g, sample.b ) );

   ////////////////////////////////////////////////////////////////////////////
   // The perceptual relative luminance.
   //
   // See http://en.wikipedia.org/wiki/Luminance_(relative)
   //
   const float3 RELATIVE_LUMINANCE = float3( 0.2126, 0.7152, 0.0722 );
   float lum = dot( sample, RELATIVE_LUMINANCE );
  
   ////////////////////////////////////////////////////////////////////////////
   //
   // The average component luminance.
   //
   //const float3 AVERAGE_LUMINANCE = float3( 0.3333, 0.3333, 0.3333 );
   //float lum = dot( sample, AVERAGE_LUMINANCE );

   return lum;
}

float3 linearToGammaColor( float3 linearCol)
{
   return pow(max(linearCol, 0), 1.0 / 2.2);
}

float3 toLinearColor( float3 srgb)
{
   return pow(max(srgb, 0), 2.2);
}

float4 toLinearColor( float4 srgba)
{
   return float4(toLinearColor(srgba.rgb), srgba.a);
}

/// Called from the visibility feature to do screen
/// door transparency for fading of objects.
void fizzle(float2 vpos, float visibility)
{
   // NOTE: The magic values below are what give us 
   // the nice even pattern during the fizzle.
   //
   // These values can be changed to get different 
   // patterns... some better than others.
   //
   // Horizontal Blinds - { vpos.x, 0.916, vpos.y, 0 }
   // Vertical Lines - { vpos.x, 12.9898, vpos.y, 78.233 }
   //
   // I'm sure there are many more patterns here to 
   // discover for different effects.
   
   float2x2 m = { vpos.x, 0.916, vpos.y, 0.350 };
   clip( visibility - frac( determinant( m ) ) );
}

/// Fresnel approximation
float3 AL_CalcSpecularFresnel(float3 specColor, float _dot)
{
	return specColor + (1.0 - specColor) * pow(1.0 - _dot, 5);
}

#if defined(BGE_USE_SCENE_CBUFFER)

#define MaterialFlag_diffuseMapUV1      (1 << 0)
#define MaterialFlag_overlayMapUV1      (1 << 1)
#define MaterialFlag_lightMapUV1        (1 << 2) // TODO
#define MaterialFlag_detailMapUV1       (1 << 3)
#define MaterialFlag_normalMapUV1       (1 << 4)
#define MaterialFlag_normalDetailMapUV1 (1 << 5)
#define MaterialFlag_opacityMapUV1      (1 << 6)
#define MaterialFlag_colorPaletteMapUV1 (1 << 7)
#define MaterialFlag_speculareMapUV1    (1 << 8)
#define MaterialFlag_reflectivityMapUV1 (1 << 9)

cbuffer RenderPassConstBuffer : register(b0)
{
    float4 ambient;
    float3 fogData;
    float accumTime;
    float4 fogColor;
    float4 oneOverFarplane;
    float4x4 worldToCamera;
    float4x4 cameraToScreen;
    float4x4 viewProj;
    float3 vEye;
    float _padding0;
    float3 eyePosWorld;
    float _padding1;
    float4x4 eyeMat;
    float3 diffuseEyePosWorld;
    float _padding2;
    float4 clipPlane0;
    float4 projectionParams;
    int4 viewportParams;
}

cbuffer cspPrimitive : register(b1)
{
    float4x4 localTrans;
    float4 windParams;
    float4 shadowAtlasXOffset;
    float4 shadowLightParams;
    float4 uColorPalette[2]; // merge and pack all colors
    float4 instanceDiffuse;
    float3 outputColor1;
    float cspPrimitive_padding0;
    float4 primFadeRange; // merge
    float2 distanceFadeParams; // merge
    float2 shadowAtlasScale;
}

#endif

#endif // _BGE_HLSL_
