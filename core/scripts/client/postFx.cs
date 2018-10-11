

singleton GFXStateBlockData( PFX_DefaultStateBlock )
{
    zDefined = true;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampLinear;
};

singleton ShaderData( PFX_PassthruShader )
{
    DXVertexShaderFile     = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/passthruP.hlsl";

//   OGLVertexShaderFile  = "shaders/common/postFx/gl//postFxV.glsl";
//   OGLPixelShaderFile   = "shaders/common/postFx/gl/passthruP.glsl";

    samplerNames[0] = "$inputTex";

    pixVersion = 2.0;
};

function initPostEffects()
{
    // First exec the scripts for the different light managers
    // in the lighting folder.

    exec("core/scripts/client/postFx/caustics.cs");
    exec("core/scripts/client/postFx/chromaticLens.cs");
    exec("core/scripts/client/postFx/default.postfxpreset.cs");
    exec("core/scripts/client/postFx/dof.cs");
    exec("core/scripts/client/postFx/edgeAA.cs");
    exec("core/scripts/client/postFx/flash.cs");
    exec("core/scripts/client/postFx/fog.cs");
    exec("core/scripts/client/postFx/fxaa.cs");
    exec("core/scripts/client/postFx/GammaPostFX.cs");
    exec("core/scripts/client/postFx/glow.cs");
    exec("core/scripts/client/postFx/hdr.cs");
    exec("core/scripts/client/postFx/lightRay.cs");
    exec("core/scripts/client/postFx/maskedScreenBlur.cs");
    exec("core/scripts/client/postFx/MotionBlurFx.cs");
    exec("core/scripts/client/postFx/postFxManager.gui.cs");
    exec("core/scripts/client/postFx/postFxManager.gui.settings.cs");
    exec("core/scripts/client/postFx/postFxManager.persistance.cs");
    exec("core/scripts/client/postFx/smaa.cs");
    exec("core/scripts/client/postFx/ssao.cs");
    exec("core/scripts/client/postFx/turbulence.cs");
}

function PostEffect::inspectVars( %this )
{
    %name = %this.getName();
    %globals = "$" @ %name @ "::*";
    inspectVars( %globals );
}

function PostEffect::viewDisassembly( %this )
{
    %file = %this.dumpShaderDisassembly();

    if ( %file $= "" )
    {
        debug( "PostEffect::viewDisassembly - no shader disassembly found." );
    }
    else
    {
        debug( "PostEffect::viewDisassembly - shader disassembly file dumped ( " @ %file @ " )." );
        openFile( %file );
    }
}

// Return true if we really want the effect enabled.
// By default this is the case.
function PostEffect::onEnabled( %this )
{
    return true;
}
