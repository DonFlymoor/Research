
#include "../postFx.hlsl"


uniform float3    eyePosWorld;
uniform float4    rtParams0;
uniform float4    waterFogPlane;
uniform float     accumTime;

float distanceToPlane(float4 plane, float3 pos)
{
   return (plane.x * pos.x + plane.y * pos.y + plane.z * pos.z) + plane.w;
}

uniform_sampler2D( prepassTex, 0);
uniform_sampler2D( prepassDepthTex, 1);
uniform_sampler2D( causticsTex0, 2);
uniform_sampler2D( causticsTex1, 3);

float4 main( PFXVertToPix IN ) : SV_Target
{   
   //Sample the pre-pass
   float4 prePass = decodeGBuffer( prepassDepthTex, prepassTex, IN.uv0, projParams );
   
   //Get depth
   float depth = prePass.w;   
   if(depth > 0.9999)
      return float4(0,0,0,0);
   
   //Get world position
   float3 pos = eyePosWorld + IN.wsEyeRay * depth;
   
   // Check the water depth
   float waterDepth = -distanceToPlane(waterFogPlane, pos);
   if(waterDepth < 0)
      return float4(0,0,0,0);
   // 10 is the depth in meters at which the caustics disappear
   waterDepth = 1 - (saturate(waterDepth * 0.10));
   
   //Use world position X and Y to calculate caustics UV 
   float2 causticsUV0 = (abs(pos.xy * 0.25) % float2(1, 1));
   float2 causticsUV1 = (abs(pos.xy * 0.2) % float2(1, 1));
   
   //Animate uvs
   float timeSin = sin(accumTime);
   causticsUV0.xy += float2(accumTime*0.1, timeSin*0.2);
   causticsUV1.xy -= float2(accumTime*0.15, timeSin*0.15);   
   
   //Sample caustics texture   
   float4 caustics = tex2D(causticsTex0, causticsUV0);   
   caustics *=  tex2D(causticsTex1, causticsUV1);
   
   //Use normal Z to modulate caustics  
   //float waterDepth = 1 - saturate(pos.z + waterFogPlane.w + 1);
   caustics *= saturate(prePass.z) * pow(1-depth, 64) * waterDepth; 
      
   return caustics;   
}
