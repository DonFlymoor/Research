
#include "../postFx.hlsl"


uniform_sampler2D( currLum , 0 );
uniform_sampler2D( lastAdaptedLum , 1 );

uniform float adaptRate;
uniform float deltaRealTime;

float4 main( PFXVertToPix IN ) : SV_TARGET
{
   float fAdaptedLum = tex2D( lastAdaptedLum, float2(0.5f, 0.5f) ).r;
   float fCurrentLum = tex2D( currLum, float2(0.5f, 0.5f) ).r;

   // The user's adapted luminance level is simulated by closing the gap between
   // adapted luminance and current luminance by 2% every frame, based on a
   // 30 fps rate. This is not an accurate model of human adaptation, which can
   // take longer than half an hour.
   float diff = fCurrentLum - fAdaptedLum;
   float fNewAdaptation = fAdaptedLum + ( diff * ( 1.0 - exp( -deltaRealTime * adaptRate ) ) );

   return float4( fNewAdaptation, 0.0, 0.0, 1.0f );
}
