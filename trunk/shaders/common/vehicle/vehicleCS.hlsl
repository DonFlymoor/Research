
#include "shaders/common/vehicle/vehicle.h"

/*
   struct VertData
   {
      float3 position;
      float tangentW;
      float3 normal;
      float3 T;
      float2 texCoord;

      float2 texCoord2;
      float diffuse;
      float texCoord3;
   };
*/

RWByteAddressBuffer outDataBuffer  : register(u0);

[numthreads(NUM_THREAD_X, 1, 1)]
void main(uint3 vertexID : SV_DispatchThreadID)
{
   float3 position;
   float3 normal;
   float3 tang;      

	updateVehicleVertex(position, normal, tang, vertexID.x);

   outDataBuffer.Store((vertexID.x * 16 + 0) * 4, asuint(position.x));
   outDataBuffer.Store((vertexID.x * 16 + 1) * 4, asuint(position.y)); 
   outDataBuffer.Store((vertexID.x * 16 + 2) * 4, asuint(position.z));

   outDataBuffer.Store((vertexID.x * 16 + 4) * 4, asuint(normal.x));
   outDataBuffer.Store((vertexID.x * 16 + 5) * 4, asuint(normal.y)); 
   outDataBuffer.Store((vertexID.x * 16 + 6) * 4, asuint(normal.z)); 

   outDataBuffer.Store((vertexID.x * 16 + 7) * 4, asuint(tang.x));
   outDataBuffer.Store((vertexID.x * 16 + 8) * 4, asuint(tang.y)); 
   outDataBuffer.Store((vertexID.x * 16 + 9) * 4, asuint(tang.z)); 
}
