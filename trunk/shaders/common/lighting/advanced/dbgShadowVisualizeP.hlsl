
struct MaterialDecoratorConnectV
{
   float2 uv0 : TEXCOORD0;
};

uniform_sampler2D( shadowMap, 0);
uniform_sampler2D( depthViz, 1);

float4 main( MaterialDecoratorConnectV IN ) : SV_Target0
{   
   float depth = saturate( tex2D( shadowMap, IN.uv0 ).r);
   return float4( tex2D( depthViz, float2(0,depth) ).rgb, 1 );
}