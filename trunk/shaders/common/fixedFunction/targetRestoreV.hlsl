
float4 main( const float2 inPosition : POSITION ) : SV_Position
{
   return float4( inPosition, 0, 1 );
}