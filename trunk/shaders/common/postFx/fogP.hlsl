#include "shaders/common/bge.hlsl"


#include "./postFx.hlsl"


uniform_sampler2D( prepassTex, 0 );
uniform_sampler2D( prepassDepthTex, 1 );
uniform float3    eyePosWorld;
uniform float4    fogColor;
uniform float3    fogData;
uniform float4    rtParams0;

#ifdef BGE_RENDER_ANNOTATION_VERSION
uniform float4 debugColor;
#endif

float4 main( PFXVertToPix IN ) : SV_Target
{   
   //float2 prepassCoord = ( IN.uv0.xy * rtParams0.zw ) + rtParams0.xy;   
   float depth = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams ).w;
   //return float4( depth, 0, 0, 0.7 );
   
   float factor = computeSceneFog( eyePosWorld,
                                   eyePosWorld + ( IN.wsEyeRay * depth ),
                                   fogData.x, 
                                   fogData.y, 
                                   fogData.z );

#ifdef BGE_RENDER_ANNOTATION_VERSION
    if(debugColor.a > 0.1f && saturate(factor) < 0.02) {
        return float4(debugColor.rgb, 1);
    }
    else {
        discard; 
    }
#endif

   return hdrEncode( float4( fogColor.rgb, 1.0 - saturate( factor ) ) );     
}