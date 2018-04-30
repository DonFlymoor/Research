
struct FarFrustumQuadConnectV
{
   float4 hpos : SV_Position;
   float2 uv0 : TEXCOORD0;
   float3 wsEyeRay : TEXCOORD1;
   float3 vsEyeRay : TEXCOORD2;
};

struct FarFrustumQuadConnectP
{
   float4 hpos : SV_Position;
   float2 uv0 : TEXCOORD0;
   float3 wsEyeRay : TEXCOORD1;
   float3 vsEyeRay : TEXCOORD2;
};


float2 getUVFromSSPos( float3 ssPos, float4 rtParams )
{
	float2 outPos = ( ssPos.xy + 1.0 ) / 2.0;
	outPos.y = 1.0 - outPos.y;
	outPos = ( outPos * rtParams.zw ) + rtParams.xy;
	return outPos;
}
