
#include "../../hlslStructs.h"

struct ConvexConnectV
{
   float4 hpos : SV_Position;
   float4 wsEyeDir : TEXCOORD0;
   float4 ssPos : TEXCOORD1;
   float4 vsEyeDir : TEXCOORD2;
};

uniform float4x4 modelview;
uniform float4x4 objTrans;
uniform float4x4 worldViewOnly;
uniform float3 eyePosWorld;

ConvexConnectV main( VertexIn_P IN )
{
   ConvexConnectV OUT;
   float4 pos = float4(IN.pos, 1);
   OUT.hpos = mul( modelview, pos );
   OUT.wsEyeDir = mul( objTrans, pos ) - float4( eyePosWorld, 0.0 );
   OUT.vsEyeDir = mul( worldViewOnly, pos );
   OUT.ssPos = OUT.hpos;

   return OUT;
}
