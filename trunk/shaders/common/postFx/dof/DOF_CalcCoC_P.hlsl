
#include "./../postFx.hlsl"

// These are set by the game engine.  
uniform_sampler2D( shrunkSampler , 0 );  // Output of DofDownsample()  
uniform_sampler2D( blurredSampler , 1 ); // Blurred version of the shrunk sampler  

// This is the pixel shader function that calculates the actual  
// value used for the near circle of confusion.  
// "texCoords" are 0 at the bottom left pixel and 1 at the top right.  
float4 main( PFXVertToPix IN ) : SV_TARGET0
{
   float3 color;  
   float coc;  
   half4 blurred;  
   half4 shrunk;  
   
   shrunk = (half4)tex2D( shrunkSampler, IN.uv0 );  
   blurred = (half4)tex2D( blurredSampler, IN.uv1 );  
   color = shrunk.rgb;  
   //coc = shrunk.a;
   //coc = blurred.a;
   //coc = max( blurred.a, shrunk.a );  
   coc = 2 * max( blurred.a, shrunk.a ) - shrunk.a;  
   
   
   //return float4( coc.rrr, 1.0 );
   //return float4( color, 1.0 );
   return float4( color, coc );  
   //return float4( 1.0, 0.0, 1.0, 1.0 );
}