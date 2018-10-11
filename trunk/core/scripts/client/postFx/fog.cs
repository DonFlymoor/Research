
//------------------------------------------------------------------------------
// Fog
//------------------------------------------------------------------------------

singleton ShaderData( FogPassShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/fogP.hlsl";

//   OGLVertexShaderFile  = "shaders/common/postFx/gl//postFxV.glsl";
//   OGLPixelShaderFile   = "shaders/common/postFx/gl/fogP.glsl";

    samplerNames[0] = "$prepassTex";

    pixVersion = 2.0;
};


singleton GFXStateBlockData( FogPassStateBlock : PFX_DefaultStateBlock )
{
    blendDefined = true;
    blendEnable = true;
    blendSrc = GFXBlendSrcAlpha;
    blendDest = GFXBlendInvSrcAlpha;
};


singleton PostEffect( FogPostFx )
{
    // We forward render the reflection pass
    // so it does its own fogging.
    allowReflectPass = false;

    renderTime = "PFXBeforeBin";
    renderBin = "ObjTranslucentBin";

    shader = FogPassShader;
    stateBlock = FogPassStateBlock;
    texture[0] = "#prepass[RT0]";
    texture[1] = "#prepass[Depth]";

    renderPriority = 5;

    isEnabled = true;
};


//------------------------------------------------------------------------------
// UnderwaterFog
//------------------------------------------------------------------------------

singleton ShaderData( UnderwaterFogPassShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/underwaterFogP.hlsl";

//   OGLVertexShaderFile  = "shaders/common/postFx/gl/postFxV.glsl";
//   OGLPixelShaderFile   = "shaders/common/postFx/gl/fogP.glsl";

    samplerNames[0] = "$prepassTex";

    pixVersion = 2.0;
};


singleton GFXStateBlockData( UnderwaterFogPassStateBlock : PFX_DefaultStateBlock )
{
    samplersDefined = true;
    samplerStates[0] = SamplerClampPoint;
    samplerStates[1] = SamplerClampPoint;
    samplerStates[2] = SamplerClampPoint;
    samplerStates[3] = SamplerClampLinear;
};


singleton PostEffect( UnderwaterFogPostFx )
{
    oneFrameOnly = true;
    onThisFrame = false;

    // Let the fog effect render during the
    // reflection pass.
    allowReflectPass = true;

    renderTime = "PFXBeforeBin";
    renderBin = "ObjTranslucentBin";

    shader = UnderwaterFogPassShader;
    stateBlock = UnderwaterFogPassStateBlock;
    texture[0] = "#prepass[RT0]";
    texture[1] = "#prepass[Depth]";
    texture[2] = "$backBuffer";
    texture[3] = "#waterDepthGradMap";

    // Needs to happen after the FogPostFx
    renderPriority = 4;

    isEnabled = true;
};

function UnderwaterFogPostFx::onEnabled( %this )
{
    //TurbulenceFx.enable();
    CausticsPFX.enable();
    return true;
}

function UnderwaterFogPostFx::onDisabled( %this )
{
    //TurbulenceFx.disable();
    CausticsPFX.disable();
    return false;
}
