function onEnabledVisualization(%obj)
{
    if(isObject($CurVisualizeMode) && $CurVisualizeMode != %obj ) {
        $CurVisualizeMode.disable();
        setVariable($CurVisualizeModeVar, false);
    }
    $CurVisualizeMode = %obj;
    $CurVisualizeModeVar = %obj.name @ "Var";
}

new GFXStateBlockData( AL_DepthVisualizeState )
{
    zDefined = true;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampPoint; // depth
    samplerStates[1] = SamplerClampLinear; // viz color lookup
};

new GFXStateBlockData( AL_DefaultVisualizeState )
{
    blendDefined = true;
    blendEnable = true;
    blendSrc = GFXBlendSrcAlpha;
    blendDest = GFXBlendInvSrcAlpha;

    zDefined = true;
    zEnable = false;
    zWriteEnable = false;

    samplersDefined = true;
    samplerStates[0] = SamplerClampPoint;   // #prepass
    samplerStates[1] = SamplerClampLinear;  // depthviz
};

new ShaderData( AL_DepthVisualizeShader )
{
    DXVertexShaderFile = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile  = "shaders/common/lighting/advanced/dbgDepthVisualizeP.hlsl";

    OGLVertexShaderFile = "shaders/common/postFx/postFxV.glsl";
    OGLPixelShaderFile  = "shaders/common/lighting/advanced/gl/dbgDepthVisualizeP.glsl";

    samplerNames[0] = "prepassBuffer";
    samplerNames[1] = "depthViz";

    pixVersion = 2.0;
};

singleton PostEffect( AL_DepthVisualize )
{
    shader = AL_DepthVisualizeShader;
    stateBlock = AL_DefaultVisualizeState;
    texture[0] = "#prepass[RT0]";
    texture[1] = "#prepass[Depth]";
    texture[2] = "depthviz";
    target = "$backBuffer";
    renderPriority = 9999;
};

function AL_DepthVisualize::onEnabled( %this )
{
    onEnabledVisualization(%this);
    return true;
}


new ShaderData( AL_NormalsVisualizeShader )
{
    DXVertexShaderFile = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile  = "shaders/common/lighting/advanced/dbgNormalVisualizeP.hlsl";

    OGLVertexShaderFile = "shaders/common/postFx/postFxV.glsl";
    OGLPixelShaderFile  = "shaders/common/lighting/advanced/gl/dbgNormalVisualizeP.glsl";

    samplerNames[0] = "prepassTex";

    pixVersion = 2.0;
};

singleton PostEffect( AL_NormalsVisualize )
{
    shader = AL_NormalsVisualizeShader;
    stateBlock = AL_DefaultVisualizeState;
    texture[0] = "#prepass[RT0]";
    texture[1] = "#prepass[Depth]";
    target = "$backBuffer";
    renderPriority = 9999;
};

function AL_NormalsVisualize::onEnabled( %this )
{
    onEnabledVisualization(%this);
    return true;
}



new ShaderData( AL_LightColorVisualizeShader )
{
    DXVertexShaderFile = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile  = "shaders/common/lighting/advanced/dbgLightColorVisualizeP.hlsl";

    OGLVertexShaderFile = "shaders/common/postFx/postFxV.glsl";
    OGLPixelShaderFile  = "shaders/common/lighting/advanced/dl/dbgLightColorVisualizeP.glsl";

    samplerNames[0] = "lightInfoBuffer";

    pixVersion = 2.0;
};

singleton PostEffect( AL_LightColorVisualize )
{
    shader = AL_LightColorVisualizeShader;
    stateBlock = AL_DefaultVisualizeState;
    texture[0] = "#lightinfo";
    target = "$backBuffer";
    renderPriority = 9999;
};

function AL_LightColorVisualize::onEnabled( %this )
{
    onEnabledVisualization(%this);
    return true;
}


new ShaderData( AL_LightSpecularVisualizeShader )
{
    DXVertexShaderFile = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile  = "shaders/common/lighting/advanced/dbgLightSpecularVisualizeP.hlsl";

    OGLVertexShaderFile = "shaders/common/postFx/postFxV.glsl";
    OGLPixelShaderFile  = "shaders/common/lighting/advanced/dl/dbgLightSpecularVisualizeP.glsl";

    samplerNames[0] = "lightInfoBuffer";

    pixVersion = 2.0;
};

singleton PostEffect( AL_LightSpecularVisualize )
{
    shader = AL_LightSpecularVisualizeShader;
    stateBlock = AL_DefaultVisualizeState;
    texture[0] = "#lightinfo";
    target = "$backBuffer";
    renderPriority = 9999;
};

function AL_LightSpecularVisualize::onEnabled( %this )
{
    onEnabledVisualization(%this);
    return true;
}

/// Toggles the visualization of the AL depth buffer.
function toggleDepthViz( %enable )
{
    if ( %enable $= "" )
    {
        $AL_DepthVisualizeVar = AL_DepthVisualize.isEnabled() ? false : true;
        AL_DepthVisualize.toggle();
    }
    else if ( %enable )
        AL_DepthVisualize.enable();
    else if ( !%enable )
        AL_DepthVisualize.disable();
}

/// Toggles the visualization of the AL normals buffer.
function toggleNormalsViz( %enable )
{
    if ( %enable $= "" )
    {
        $AL_NormalsVisualizeVar = AL_NormalsVisualize.isEnabled() ? false : true;
        AL_NormalsVisualize.toggle();
    }
    else if ( %enable )
        AL_NormalsVisualize.enable();
    else if ( !%enable )
        AL_NormalsVisualize.disable();
}

/// Toggles the visualization of the AL lighting color buffer.
function toggleLightColorViz( %enable )
{
    if ( %enable $= "" )
    {
        $AL_LightColorVisualizeVar = AL_LightColorVisualize.isEnabled() ? false : true;
        AL_LightColorVisualize.toggle();
    }
    else if ( %enable )
        AL_LightColorVisualize.enable();
    else if ( !%enable )
        AL_LightColorVisualize.disable();
}

/// Toggles the visualization of the AL lighting specular power buffer.
function toggleLightSpecularViz( %enable )
{
    if ( %enable $= "" )
    {
        $AL_LightSpecularVisualizeVar = AL_LightSpecularVisualize.isEnabled() ? false : true;
        AL_LightSpecularVisualize.toggle();
    }
    else if ( %enable )
        AL_LightSpecularVisualize.enable();
    else if ( !%enable )
        AL_LightSpecularVisualize.disable();
}

new ShaderData( AnnotationVisualizeShader )
{
    DXVertexShaderFile = "shaders/common/postFx/postFxV.hlsl";
    DXPixelShaderFile  = "shaders/common/postFx/annotationViz.hlsl";

    samplerNames[0] = "AnnotationBuffer";
    samplerNames[1] = "warningTex";

    pixVersion = 2.0;
};

singleton PostEffect( AnnotationVisualize )
{
    shader = AnnotationVisualizeShader;
    stateBlock = AL_DefaultVisualizeState;
    texture[0] = "#AnnotationBuffer";
    texture[1] = "shaders/common/postFx/preview_warning.png";
    target = "$backBuffer";
    renderPriority = 9999;
};

function AnnotationVisualize::onEnabled( %this )
{
    onEnabledVisualization(%this);
    LuaExecuteStringSync("Engine.Annotation.enable(true)");
    return true;
}

function AnnotationVisualize::onDisabled( %this )
{
    LuaExecuteStringSync("Engine.Annotation.enable(false)");
}

function toggleAnnotationVisualize( %enable )
{
    if ( %enable $= "" )
    {
        $AnnotationVisualizeVar = AnnotationVisualize.isEnabled() ? false : true;
        AnnotationVisualize.toggle();
    }
    else if ( %enable )
        AnnotationVisualize.enable();
    else if ( !%enable )
        AnnotationVisualize.disable();
}
