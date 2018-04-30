#include "shaders/common/bge.hlsl"
#include "shaders/common/postfx/postFx.hlsl"

uniform_sampler2D(inputBuffer, 0 );
uniform_sampler2D(LidarTex, 1 );

uniform float fadeInput;

float4 main( PFXVertToPix IN, float4 pos : SV_POSITION ) : SV_Target
{
    float4 input = fadeInput * inputBufferTex.Load(uint3(pos.xy, 0));
    float4 lidar =  tex2Dlod( LidarTex, float4(IN.uv0, 0, 0));
    return float4( lerp( input.rgb, lidar.rgb, lidar.a > 0 ), 1);   
}
