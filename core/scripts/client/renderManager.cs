
function initRenderManager()
{
    // This token, and the associated render managers, ensure that driver MSAA
    // does not get used for Advanced Lighting renders.  The 'AL_FormatResolve'
    // PostEffect copies the result to the backbuffer.
    new RenderFormatToken(AL_FormatToken)
    {
        enabled = "false";

        format[0] = "GFXFormatR8G8B8A8";
        depthFormat = $GFXFormatDefaultDepth;
        aaLevel = 0; // -1 = match backbuffer

        // The contents of the back buffer before this format token is executed
        // is provided in $inTex
        copyEffect = "AL_FormatCopy";

        // The contents of the render target created by this format token is
        // provided in $inTex
        resolveEffect = "AL_FormatCopy";
    };
}

/// This post effect is used to copy data from the non-MSAA back-buffer to the
/// device back buffer (which could be MSAA). It must be declared here so that
/// it is initialized when 'AL_FormatToken' is initialzed.
singleton GFXStateBlockData( AL_FormatTokenState : PFX_DefaultStateBlock )
{
    samplersDefined = true;
    samplerStates[0] = SamplerClampPoint;
};

singleton PostEffect( AL_FormatCopy )
{
    // This PostEffect is used by 'AL_FormatToken' directly. It is never added to
    // the PostEffectManager. Do not call enable() on it.
    isEnabled = false;
    allowReflectPass = true;

    shader = PFX_PassthruShader;
    stateBlock = AL_FormatTokenState;

    texture[0] = "$inTex";
    target = "$backbuffer";
};
