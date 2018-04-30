#ifndef BEAMNG_VEHICLE_H
#define BEAMNG_VEHICLE_H

struct VehicleVertexLocator
{
    float3 coords;
    float ref;
    float3 normal;
    float nx;
    float3 tangent;
    float ny;

    float nz;
    //float3 tangent_binormal;
    float noDeformation;

    float _padding[2];
};

#if BGE_SM >= 50

    StructuredBuffer<VehicleVertexLocator> VehicleVertexLocatorsBuffer;
    #define getVehicleVertexLocators(x) VehicleVertexLocatorsBuffer[x]

    StructuredBuffer<float3> VehicleNodesBuffer;
    #define getVehicleNodesPos(x) VehicleNodesBuffer[x]

#elif BGE_SM >= 40

    Texture2D<float3> VehicleNodesBuffer;
    #define getVehicleNodesPos(x) VehicleNodesBuffer.Load( indexTo2D(x) )

    Texture2D<float4> VehicleVertexLocatorsBuffer;
    VehicleVertexLocator getVehicleVertexLocators(uint index)
    {
        VehicleVertexLocator locator;
        uint offset = index*4;

        float4 data0 = VehicleVertexLocatorsBuffer.Load( indexTo2D(offset  ) );
        float4 data1 = VehicleVertexLocatorsBuffer.Load( indexTo2D(offset+1) );
        float4 data2 = VehicleVertexLocatorsBuffer.Load( indexTo2D(offset+2) );
        float4 data3 = VehicleVertexLocatorsBuffer.Load( indexTo2D(offset+3) );

        locator.coords =    data0.xyz;
        locator.ref =       data0.w;
        locator.normal =    data1.xyz;
        locator.nx =        data1.w;
        locator.tangent =   data2.xyz;
        locator.ny =        data2.w;
        locator.nz =        data3.x;
        locator.noDeformation = data3.y;
        locator._padding[0] = 0;
        locator._padding[1] = 0;
        return locator;
    }

#endif //BGE_SM

uniform int startVertexId;

void updateVehicleVertex( out float3 pos, out float3 normal, out float3 tangent, uint vertexID )
{
    vertexID += startVertexId;
    VehicleVertexLocator loc = getVehicleVertexLocators(vertexID);
    
    float3 refPos = getVehicleNodesPos(loc.ref).xyz;
    float3 nx = getVehicleNodesPos(loc.nx).xyz - refPos;
    float3 ny = getVehicleNodesPos(loc.ny).xyz - refPos;
    float3 nz;

    if(loc.nz == -1) {
        // fallback: calculate nz
        nz = normalize( cross(nx, ny ) );
    }
    else {
        // nz provided
        nz = getVehicleNodesPos(loc.nz).xyz - refPos;
    }

    //////////////////////////////////////////////////////////////////////////
    // tangents Tangent
    normal = normalize( (nx * loc.normal.x) + (ny * loc.normal.y) + (nz * loc.normal.z) );
    tangent = normalize( (nx * loc.tangent.x) + (ny * loc.tangent.y) + (nz * loc.tangent.z) );

    // and the positions:
    pos = (nx * loc.coords.x) + (ny * loc.coords.y) + (nz * loc.coords.z) + refPos;
}

#endif //BEAMNG_VEHICLE_H
