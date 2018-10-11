
singleton GFXStateBlockData( SMAA_StateBlock : PFX_DefaultStateBlock )
{
    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
    samplerStates[1] = SamplerClampLinear;
    samplerStates[2] = SamplerClampLinear;
};

singleton ShaderData( SMAA_EdgeDetectionShaderData )
{
    DXVertexShaderFile     = "shaders/common/postFx/smaa/smaa_edgeDetectionV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/smaa/smaa_edgeDetectionP.hlsl";

    samplerNames[0] = "$colorTexGamma";
};

singleton ShaderData( SMAA_BlendingWeightShaderData )
{
    DXVertexShaderFile     = "shaders/common/postFx/smaa/smaa_blendingWeightV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/smaa/smaa_blendingWeightP.hlsl";

    samplerNames[0] = "$edgesTex";
    samplerNames[1] = "$areaTex";
    samplerNames[2] = "$searchTex";
};

singleton ShaderData( SMAA_NeighborhoodBlendingShaderData )
{
    DXVertexShaderFile     = "shaders/common/postFx/smaa/smaa_NeighborhoodBlendingV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/smaa/smaa_NeighborhoodBlendingP.hlsl";

    samplerNames[0] = "$colorTex";
    samplerNames[1] = "$blendTex";
};

function SMAA_PostEffect::preProcess( %this )
{
    %size = %this.getRenderTargetSize();
    %rtResolution = "float4(1.0 / " @ %size.x @ ", 1.0 / " @ %size.y @ ", " @ %size.x @ ", " @ %size.y @ ")";
    if(%rtResolution !$= SMAA_PostEffect.rtResolution) {
        SMAA_PostEffect.rtResolution = %rtResolution;
        SMAA_PostEffect.setShaderMacro("SMAA_RT_METRICS", %rtResolution);
        SMAA_PostEffect1.setShaderMacro("SMAA_RT_METRICS", %rtResolution);
        SMAA_PostEffect2.setShaderMacro("SMAA_RT_METRICS", %rtResolution);
    }
}

function SMAA_PostEffect::onEnabled( %this )
{
    FXAA_PostEffect.disable();
    return true;
}

singleton PostEffect( "SMAA_PostEffect" )
{
    isEnabled = false;

    allowReflectPass = false;
    renderTime = "PFXAfterDiffuse";

    texture[0] = "$backBuffer";
    target = "$outTex";
    targetClear = PFXTargetClear_OnDraw;
    targetClearColor = "0 0 0 0";

    stateBlock = SMAA_StateBlock;
    shader = SMAA_EdgeDetectionShaderData;

    new PostEffect(SMAA_PostEffect1) 
    {
        texture[0] = "$inTex";
        texture[1] = "shaders/common/postFx/smaa/AreaTexDX9.dds";
        texture[2] = "shaders/common/postFx/smaa/SearchTex.dds";
        target = "$outTex";
        targetClear = PFXTargetClear_OnDraw;
        targetClearColor = "0 0 0 0";

        stateBlock = SMAA_StateBlock;
        shader = SMAA_BlendingWeightShaderData;

        new PostEffect(SMAA_PostEffect2)
        {
            texture[0] = "$backBuffer";
            texture[1] = "$inTex";
            target = "$backBuffer";

            stateBlock = SMAA_StateBlock;
            shader = SMAA_NeighborhoodBlendingShaderData;
        };
    };
};

SMAA_PostEffect.preProcess();
