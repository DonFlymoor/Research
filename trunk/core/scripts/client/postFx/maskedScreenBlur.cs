// ----------------------------------------------

singleton ShaderData( ScreenBlurFX_YShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/dof/DOF_Gausian_V.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/dof/DOF_Gausian_P.hlsl";
    pixVersion = 2.0;
    defines = "BLUR_DIR=float2(0.0,1.0)";
};

singleton ShaderData( ScreenBlurFX_XShader : ScreenBlurFX_YShader )
{
    defines = "BLUR_DIR=float2(1.0,0.0)";
};

singleton GFXStateBlockData( ScreenBlurFX_stateBlock )
{
    zDefined = true;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
    samplerStates[1] = SamplerClampPoint;
};

singleton ShaderData( SimpleBlendShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/simpleBlendV.hlsl";
    DXPixelShaderFile     =  "shaders/common/postFx/simpleBlendP.hlsl";
    pixVersion = 2.0;
};

singleton GFXStateBlockData( SimpleBlendShaderStateBlock )
{
    zDefined = true;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
    samplerStates[1] = SamplerClampLinear;
    samplerStates[2] = SamplerClampLinear;
};

singleton PostEffectMaskedBlur( ScreenBlurFX )
{
    isEnabled = true; // use it only when needed

    renderBin = "EditorBin";
    renderTime = "PFXAfterBin";

    shader = PFX_PassthruShader;
    stateBlock = AL_FormatTokenState;
    texture[0] = "$backBuffer";
    target = "$outTex";
    targetScale = "0.25 0.25";

    singleton PostEffect()
    {
        shader = ScreenBlurFX_YShader;
        stateBlock = ScreenBlurFX_stateBlock;
        texture[0] = "$inTex";
        target = "$outTex";
    };

    singleton PostEffect()
    {
        shader = ScreenBlurFX_XShader;
        stateBlock = ScreenBlurFX_stateBlock;
        texture[0] = "$inTex";
        target = "$outTex";
    };

    /*singleton PostEffect()
    {
        shader = ScreenBlurFX_YShader;
        stateBlock = ScreenBlurFX_stateBlock;
        texture[0] = "$inTex";
        target = "$outTex";
        //targetScale = "0.5 0.5";
    };

    singleton PostEffect()
    {
        shader = ScreenBlurFX_XShader;
        stateBlock = ScreenBlurFX_stateBlock;
        texture[0] = "$inTex";
        target = "$outTex";
    };*/

    singleton PostEffect()
    {
        shader = SimpleBlendShader;
        stateBlock = SimpleBlendShaderStateBlock;
        texture[0] = "$backBuffer";
        texture[1] = "$inTex";
        texture[2] = "#screenBlurMask";
        target = "$backBuffer";
    };
};
