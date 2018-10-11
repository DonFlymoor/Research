
singleton GFXStateBlockData( PFX_TurbulenceStateBlock : PFX_DefaultStateBlock)
{
    zDefined = false;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
};

singleton ShaderData( PFX_TurbulenceShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/turbulenceP.hlsl";

    pixVersion = 3.0;
};

singleton PostEffect( TurbulenceFx )
{
    isEnabled = false;
    allowReflectPass = true;

    renderTime = "PFXAfterBin";
    renderBin = "GlowBin";
    renderPriority = 0.5; // Render after the glows themselves

    shader = PFX_TurbulenceShader;
    stateBlock=PFX_TurbulenceStateBlock;
    texture[0] = "$backBuffer";
 };
