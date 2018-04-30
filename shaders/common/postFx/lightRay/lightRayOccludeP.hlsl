#include "shaders/common/bge.hlsl"


#include "../postFx.hlsl"

uniform_sampler2D( backBuffer, 0 );   // The original backbuffer.
uniform_sampler2D( prepassTex, 1 );   // The pre-pass depth and normals.
uniform_sampler2D( prepassDepthTex, 2 );

uniform float brightScalar;

static const float3 LUMINANCE_VECTOR = float3(0.3125f, 0.6154f, 0.0721f);


float4 main( PFXVertToPix IN ) : SV_TARGET0
{
    float4 col = float4( 0, 0, 0, 1 );
    
    // Get the depth at this pixel.
    float depth = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams ).w;
    
    // If the depth is equal to 1.0, read from the backbuffer
    // and perform the exposure calculation on the result.
    if ( depth >= 0.999 )
    {
        col = tex2D( backBuffer, IN.uv0 );

        //col = 1 - exp(-120000 * col);
        col += dot( col.rgb, LUMINANCE_VECTOR ) + 0.0001f;
        col *= brightScalar;
    }
    
    return col;
}
