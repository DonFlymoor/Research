#ifndef HLSL_H
#define HLSL_H

// Base include for handle HLSL versions

#if BGE_SM >= 40

struct SamplerTexture2D
{
    SamplerState _filter;
    Texture2D _texture;
};

struct SamplerTexture1D
{
    SamplerState _filter;
    Texture1D _texture;
};

struct SamplerTexture3D
{
    SamplerState _filter;
    Texture3D _texture;
};

struct SamplerTextureCube
{
    SamplerState _filter;
    TextureCube _texture;
};

#define uniform_sampler1D( NAME, REG ) uniform SamplerState NAME##_sampler_ : register(S##REG);   \
        uniform Texture1D NAME##Tex : register(T##REG);   \
        static SamplerTexture1D NAME = { NAME##_sampler_, NAME##Tex}
#define uniform_sampler2D( NAME, REG ) uniform SamplerState NAME##_sampler_ : register(S##REG);   \
        uniform Texture2D NAME##Tex : register(T##REG);   \
        static SamplerTexture2D NAME = { NAME##_sampler_, NAME##Tex}
#define uniform_sampler2D_NoReg( NAME ) uniform SamplerState NAME##_sampler_;   \
        uniform Texture2D NAME##Tex;   \
        static SamplerTexture2D NAME = { NAME##_sampler_, NAME##Tex}
#define uniform_sampler3D( NAME, REG ) uniform SamplerState NAME##_sampler_ : register(S##REG);   \
        uniform Texture3D NAME##Tex : register(T##REG);   \
        static SamplerTexture3D NAME = { NAME##_sampler_, NAME##Tex}
#define uniform_samplerCUBE( NAME, REG ) uniform SamplerState NAME##_sampler_ : register(S##REG);  \
        uniform TextureCube NAME##Tex : register(T##REG);   \
        static SamplerTextureCube NAME = { NAME##_sampler_, NAME##Tex}

//#define POSITION SV_Position

#define tex1D( SAMPLER, UV ) SAMPLER._texture.Sample( SAMPLER._filter, UV )
#define tex2D( SAMPLER, UV ) SAMPLER._texture.Sample( SAMPLER._filter, UV )
#define texCUBE( SAMPLER, UV ) SAMPLER._texture.Sample( SAMPLER._filter, UV )
float4 tex2Dlod( in SamplerTexture2D SAMPLER, in float4 UV )
{
    return SAMPLER._texture.SampleLevel( SAMPLER._filter, UV.xy, UV.z, UV.w );
}

float4 tex2Dproj( in SamplerTexture2D SAMPLER, in float4 UV )
{
    return SAMPLER._texture.Sample( SAMPLER._filter, UV.xy/UV.w );
}

float4 tex1Dlod( in SamplerTexture1D SAMPLER, in float4 UV )
{
    return SAMPLER._texture.SampleLevel( SAMPLER._filter, UV.x, UV.y, UV.z );
}

float4 texCUBElod( in SamplerTextureCube SAMPLER, in float4 UV )
{
    return SAMPLER._texture.SampleLevel( SAMPLER._filter, UV.xyz, UV.w );
}

#define sampler1D SamplerTexture1D
#define sampler2D SamplerTexture2D
#define sampler3D SamplerTexture3D
#define samplerCUBE SamplerTextureCube

// this function is used on SM4 hw to simulate Buffer objects. We use fixed width of 4096
int3 indexTo2D(uint idx)
{
   return int3( idx % 4096, idx / 4096, 0 );
}

#else

#define uniform_sampler1D( NAME, REG ) uniform sampler1D NAME : register(S##REG)
#define uniform_sampler2D( NAME, REG ) uniform sampler2D NAME : register(S##REG)
#define uniform_sampler2D_NoReg( NAME ) uniform sampler2D NAME
#define uniform_sampler3D( NAME, REG ) uniform sampler3D NAME : register(S##REG)
#define uniform_samplerCUBE( NAME, REG ) uniform samplerCUBE NAME : register(S##REG)

#define SV_TARGET COLOR
#define SV_TARGET0 COLOR0
#define SV_TARGET1 COLOR1
#define SV_TARGET2 COLOR2
#define SV_TARGET3 COLOR3

#endif

#endif //HLSL_H
