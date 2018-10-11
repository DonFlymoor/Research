
singleton GFXStateBlockData( PFX_CausticsStateBlock : PFX_DefaultStateBlock )
{
    blendDefined = true;
    blendEnable = true;
    blendSrc = GFXBlendOne;
    blendDest = GFXBlendOne;

    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
    samplerStates[1] = SamplerClampLinear;
    samplerStates[2] = SamplerWrapLinear;
    samplerStates[3] = SamplerWrapLinear;
};

singleton ShaderData( PFX_CausticsShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/caustics/causticsP.hlsl";

    //OGLVertexShaderFile  = "shaders/common/postFx/gl//postFxV.glsl";
    //OGLPixelShaderFile   = "shaders/common/postFx/gl/passthruP.glsl";

    pixVersion = 3.0;
};

singleton PostEffect( CausticsPFX )
{
    isEnabled = false;
    renderTime = "PFXBeforeBin";
    renderBin = "ObjTranslucentBin";
    //renderPriority = 0.1;

    shader = PFX_CausticsShader;
    stateBlock = PFX_CausticsStateBlock;
    texture[0] = "#prepass[RT0]";
    texture[1] = "#prepass[Depth]";
    texture[2] = "core/scripts/client/postFx/textures/caustics_1";
    texture[3] = "core/scripts/client/postFx/textures/caustics_2";
    target = "$backBuffer";
};
