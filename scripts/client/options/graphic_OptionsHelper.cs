//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// display_driver
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_display_driver)
{
    class = "OptionHelper";
};

function Settings_Graphic_display_driver::_buildOptions(%this)
{
    for( %itr = 0; %itr < GFXInit::getAdapterCount(); %itr++ )
    {
        %this.addOption( GFXInit::getAdapterOutputName( %itr ), GFXInit::getAdapterName( %itr ) );
    }
}
function Settings_Graphic_display_driver::_getValue( %this )
{
    return $pref::Video::displayOutputDevice;
}
function Settings_Graphic_display_driver::_setValue( %this, %value )
{
    $pref::Video::displayOutputDevice = %value;
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// resolutions
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_resolutions)
{
    class = "OptionHelper";
};

function Settings_Graphic_resolutions::_buildPrettyString( %this, %X, %Y)
{
    %pretty = %X @ " x " @ %Y;
    if( %X / %Y == 4/3 )
        %pretty = %pretty SPC "(4/3)";
    else if( %X / %Y == 16/9 )
        %pretty = %pretty SPC "(16/9)";
    return %pretty;
}

function Settings_Graphic_resolutions::_buildOptions(%this)
{
    for( %itr = 0; %itr < Canvas.getModeCount(); %itr++ )
    {
        %mode = Canvas.getMode( %itr );

        %X = getWord( %mode,  $WORD::RES_X);
        %Y = getWord( %mode,  $WORD::RES_Y);
        %pretty = %this._buildPrettyString(%X, %Y);

        %value = getWord( %mode,  $WORD::RES_X) SPC getWord( %mode,  $WORD::RES_Y);
        %this.addOption( %value, %pretty );
    }
}
function Settings_Graphic_resolutions::_getValue( %this )
{
    %value = getWord( $pref::Video::mode,  $WORD::RES_X) SPC getWord( $pref::Video::mode,  $WORD::RES_Y);
    return %value;
}
function Settings_Graphic_resolutions::_setValue( %this, %value )
{
    $pref::Video::mode = setWord($pref::Video::mode,  $WORD::RES_X, getWord( %value, 0) );
    $pref::Video::mode = setWord($pref::Video::mode,  $WORD::RES_Y, getWord( %value, 1) );

    applyOptions_Graphic();
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// fullscreen
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_fullscreen)
{
    class = "OptionHelper";
};
function Settings_Graphic_fullscreen::_buildOptions(%this)
{

}
function Settings_Graphic_fullscreen::_getValue( %this )
{
    return getWord($pref::Video::mode,   $WORD::FULLSCREEN);
}
function Settings_Graphic_fullscreen::_setValue( %this, %value )
{
    $pref::Video::mode = setWord($pref::Video::mode,   $WORD::FULLSCREEN, %value);
    applyOptions_Graphic();
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// borderless
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_borderless)
{
    class = "OptionHelper";
};
function Settings_Graphic_borderless::_buildOptions(%this)
{

}
function Settings_Graphic_borderless::_getValue( %this )
{
    return $pref::Video::borderless;
}
function Settings_Graphic_borderless::_setValue( %this, %value )
{
    $pref::Video::borderless = %value;
    applyOptions_Graphic();
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// refresh_rate
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_refresh_rate)
{
    class = "OptionHelper";
};
function Settings_Graphic_refresh_rate::_buildOptions(%this)
{
    %res = getWord($pref::Video::mode,  $WORD::RES_X) @ " " @ getWord($pref::Video::mode,  $WORD::RES_Y);
    for( %itr = 0; %itr < Canvas.getModeCount(); %itr++ )
    {
        %mode = Canvas.getMode( %itr );
        %rf = getWord( %mode,  $WORD::REFRESH);

        if( strpos(%mode, %res) == -1 )
                continue;

        %this.addOption( %rf, %rf );
    }
}
function Settings_Graphic_refresh_rate::_getValue( %this )
{
    return getWord($pref::Video::mode, $WORD::REFRESH);
}
function Settings_Graphic_refresh_rate::_setValue( %this, %value )
{
    $pref::Video::mode = setWord($pref::Video::mode, $WORD::REFRESH, %value);
    applyOptions_Graphic();
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// antialias
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_antialias)
{
    class = "OptionHelper";
};

function Settings_Graphic_antialias::_buildOptions(%this)
{
    %this.addOption( 0, "Off" );
    %this.addOption( 1, "1x" );
    %this.addOption( 2, "2x" );
    %this.addOption( 4, "4x" );
}
function Settings_Graphic_antialias::_getValue( %this )
{
    return getWord($pref::Video::mode, $WORD::AA);

}
function Settings_Graphic_antialias::_setValue( %this, %value )
{
    $pref::Video::mode = setWord($pref::Video::mode, $WORD::AA, %value);
    applyOptions_Graphic();
    FXAA_PostEffect.isEnabled = ( %value > 0 ) ? true : false;
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Anisotropic filtering
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_anisotropic)
{
    class = "OptionHelper";
};

function Settings_Graphic_anisotropic::_buildOptions(%this)
{
    %this.addOption( 0, "Off");
    %this.addOption( 4, "4x");
    %this.addOption( 8, "8x");
    %this.addOption( 16, "16x");
}
function Settings_Graphic_anisotropic::_getValue( %this )
{
    return $pref::Video::defaultAnisotropy;
}
function Settings_Graphic_anisotropic::_setValue( %this, %value )
{
    $pref::Video::defaultAnisotropy = %value;
    applyOptions_Graphic();
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Grass density
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_grass_density)
{
    class = "OptionHelper";
};

function Settings_Graphic_grass_density::_buildOptions(%this)
{
    %this.addOption(1, 1);
}
function Settings_Graphic_grass_density::_getValue( %this )
{
    return $pref::GroundCover::densityScale;
}
function Settings_Graphic_grass_density::_setValue( %this, %value )
{
    $pref::GroundCover::densityScale = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// dyn_reflection_enabled
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(dyn_reflection_enabled)
{
    class = "OptionHelper";
};
function dyn_reflection_enabled::_buildOptions(%this)
{
    //%this.addOption(1, 1);
}
function dyn_reflection_enabled::_getValue( %this )
{
    return $pref::BeamNGVehicle::dynamicReflection::enabled;
}
function dyn_reflection_enabled::_setValue( %this, %value )
{
    $pref::BeamNGVehicle::dynamicReflection::enabled = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// dyn_reflection_detail
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(dyn_reflection_detail)
{
    class = "OptionHelper";
    optionType = "Slice";
};
function dyn_reflection_detail::_buildOptions(%this)
{
    //%this.addOption(1, 1);
}
function dyn_reflection_detail::_getValue( %this )
{
    return $pref::BeamNGVehicle::dynamicReflection::detail;
}
function dyn_reflection_detail::_setValue( %this, %value )
{
    $pref::BeamNGVehicle::dynamicReflection::detail = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// dyn_reflection_distance
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(dyn_reflection_distance)
{
    class = "OptionHelper";
    optionType = "Slice";
};
function dyn_reflection_distance::_buildOptions(%this)
{
    //%this.addOption(1000, 1000);
}
function dyn_reflection_distance::_getValue( %this )
{
    return $pref::BeamNGVehicle::dynamicReflection::distance;
}
function dyn_reflection_distance::_setValue( %this, %value )
{
    $pref::BeamNGVehicle::dynamicReflection::distance = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// dyn_reflection_texsize
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(dyn_reflection_texsize)
{
    class = "OptionHelper";
    optionType = "Slice";
};
function dyn_reflection_texsize::_buildOptions(%this)
{
    //%this.addOption(4, 4);
}
function dyn_reflection_texsize::_getValue( %this )
{
    return mRound( $pref::BeamNGVehicle::dynamicReflection::textureSize / 256);
}
function dyn_reflection_texsize::_setValue( %this, %value )
{
    $pref::BeamNGVehicle::dynamicReflection::textureSize = %value * 256;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// _________________________
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(dyn_reflection_facesPerupdate)
{
    class = "OptionHelper";
    optionType = "Slice";
};
function dyn_reflection_facesPerupdate::_buildOptions(%this)
{
    //%this.addOption(6, 6);
}
function dyn_reflection_facesPerupdate::_getValue( %this )
{
    return $pref::BeamNGVehicle::dynamicReflection::facesPerUpdate;
}
function dyn_reflection_facesPerupdate::_setValue( %this, %value )
{
    $pref::BeamNGVehicle::dynamicReflection::facesPerUpdate = %value;
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// gamma
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_gamma)
{
    class = "OptionHelper";
    optionType = "Slice";
};
function Settings_Graphic_gamma::_buildOptions(%this)
{

}
function Settings_Graphic_gamma::_getValue( %this )
{
    return $pref::Video::Gamma;
}
function Settings_Graphic_gamma::_setValue( %this, %value )
{
    $pref::Video::Gamma = %value;
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// mesh_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_mesh_quality)
{
    class = "OptionHelper";
};
function Settings_Graphic_mesh_quality::_getValue( %this )
{
    return MeshQualityGroup.getCurrentLevelId();
}
function Settings_Graphic_mesh_quality::_setValue( %this, %value )
{
    MeshQualityGroup.applyLevelId( %value );
}
function Settings_Graphic_mesh_quality::_buildOptions(%this)
{
    %this.addOption(0, "Lowest");
    %this.addOption(1, "Low");
    %this.addOption(2, "Normal");
    %this.addOption(3, "High");
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// texture_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_texture_quality)
{
    class = "OptionHelper";
};

function Settings_Graphic_texture_quality::_buildOptions(%this)
{
    %this.addOption(0, "Lowest");
    %this.addOption(1, "Low");
    %this.addOption(2, "Normal");
    %this.addOption(3, "High");
}
function Settings_Graphic_texture_quality::_getValue( %this )
{
    return TextureQualityGroup.getCurrentLevelId();
}
function Settings_Graphic_texture_quality::_setValue( %this, %value )
{
    TextureQualityGroup.applyLevelId( %value );
}
function Settings_Graphic_texture_quality::onLevelChanged(%this, %level)
{
    debug("Setting texture quality for level:" SPC %level);
}
LevelEventManager.subscribe(Settings_Graphic_texture_quality, "onPreLevelLoad", "onLevelChanged");
*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// lighting_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_lighting_quality)
{
    class = "OptionHelper";
};
function Settings_Graphic_lighting_quality::_buildOptions(%this)
{
    %this.addOption(0, "Lowest");
    %this.addOption(1, "Low");
    %this.addOption(2, "Normal");
    %this.addOption(3, "High");
}
function Settings_Graphic_lighting_quality::_getValue( %this )
{
    return LightingQualityGroup.getCurrentLevelId();
}
function Settings_Graphic_lighting_quality::_setValue( %this, %value )
{
    LightingQualityGroup.applyLevelId( %value );
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// shader_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_shader_quality)
{
    class = "OptionHelper";
};
function Settings_Graphic_shader_quality::_buildOptions(%this)
{
    %this.addOption(0, "Lowest");
    %this.addOption(1, "Low");
    %this.addOption(2, "Normal");
    %this.addOption(3, "High");
}
function Settings_Graphic_shader_quality::_getValue( %this )
{
    return ShaderQualityGroup.getCurrentLevelId();
}
function Settings_Graphic_shader_quality::_setValue( %this, %value )
{
    haderQualityGroup.applyLevelId( %value );
}*/

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// postf_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*singleton SimObject(Settings_Graphic_postfx_quality)
{
    class = "OptionHelper";
};
function Settings_Graphic_postfx_quality::_buildOptions(%this)
{
    %this.addOption(0, "Lowest");
    %this.addOption(1, "Low");
    %this.addOption(2, "Normal");
    %this.addOption(3, "High");
}
function Settings_Graphic_postfx_quality::_getValue( %this )
{
    if( $PostFXManager::Settings::quality $= "" )
        return 2;

    return $PostFXManager::Settings::quality;
}
function Settings_Graphic_postfx_quality::_setValue( %this, %value )
{
    $PostFXManager::Settings::quality = %value;

    if( %value == 3 )
        PostFXManager::loadPresetHandler( $PostFXManager::highPreset );
    else if( %value == 2 )
        PostFXManager::loadPresetHandler( $PostFXManager::normalPreset );
    else if( %value == 1 )
        PostFXManager::loadPresetHandler( $PostFXManager::lowPreset );
    else if( %value == 0 )
        PostFXManager::loadPresetHandler( $PostFXManager::lowestPreset );
}*/

/*function applyOptions_Graphic()
{
    debug("    >>>> applyOptions_Graphic <<<<<");
    %resX = getWord($pref::Video::mode, $WORD::RES_X);
    %resY = getWord($pref::Video::mode, $WORD::RES_Y);
    %fs = getWord($pref::Video::mode,   $WORD::FULLSCREEN);
    %bpp = getWord($pref::Video::mode,  $WORD::BITDEPTH);
    %rate = getWord($pref::Video::mode, $WORD::REFRESH);
    %fsaa = getWord($pref::Video::mode, $WORD::AA);
    Canvas.setVideoMode(%resX, %resY, %fs, %bpp, %rate, %fsaa);

    beamNGExecuteJS( "HookManager.trigger('OptionsChanged')");
}*/


//basic graphic qualitynew
singleton SimGroup( BasicRenderQualityGroup )
{
    class = "GraphicsQualityGroup";
    new ArrayObject( [Lowest] )
    {
       class = "GraphicsQualityLevel";
       caseSensitive = true;

        // MeshQualityGroup
        key["$pref::TS::detailAdjust"] = 0.5;
        key["$pref::TS::skipRenderDLs"] = 1;
        key["$pref::Terrain::lodScale"] = 2.0;
        key["$pref::decalMgr::enabled"] = false;
        key["$pref::GroundCover::densityScale"] = 0;

        //TextureQualityGroup
        key["$pref::Video::textureReductionLevel"] = 2;
        key["$pref::Reflect::refractTexScale"] = 0.5;
        key["$pref::Terrain::detailScale"] = 0.5;

        //LightingQualityGroup
        key["$pref::lightManager"] = "Basic Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 0.5;
        key["$pref::Shadows::filterMode"] = "None";

        //ShaderQualityGroup
        key["$pref::Video::disablePixSpecular"] = true;
        key["$pref::Video::disableNormalmapping"] = true;
        key["$pref::Video::disableParallaxMapping"] = true;
        key["$pref::Water::disableTrueReflections"] = true;

        key["$pref::BeamNGVehicle::dynamicReflection::enabled"] = false;
    };

    new ArrayObject( [Low] )
    {
       class = "GraphicsQualityLevel";
       caseSensitive = true;

        // MeshQualityGroup
        key["$pref::TS::detailAdjust"] = 0.75;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 1.5;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 0.5;

        //TextureQualityGroup
        key["$pref::Video::textureReductionLevel"] = 1;
        key["$pref::Reflect::refractTexScale"] = 0.75;
        key["$pref::Terrain::detailScale"] = 0.75;

        //LightingQualityGroup
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 0.5;
        key["$pref::Shadows::filterMode"] = "SoftShadow";

        //ShaderQualityGroup
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = true;
        key["$pref::Water::disableTrueReflections"] = true;

        key["$pref::BeamNGVehicle::dynamicReflection::enabled"] = false;
    };

    new ArrayObject( [Normal] )
    {
       class = "GraphicsQualityLevel";
       caseSensitive = true;

        // MeshQualityGroup
        key["$pref::TS::detailAdjust"] = 1.0;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 1.0;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 0.75;

        //TextureQualityGroup
        key["$pref::Video::textureReductionLevel"] = 0;
        key["$pref::Reflect::refractTexScale"] = 1;
        key["$pref::Terrain::detailScale"] = 1;

        //LightingQualityGroup
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 1.0;
        key["$pref::Shadows::filterMode"] = "SoftShadowHighQuality";

        //ShaderQualityGroup
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = false;
        key["$pref::Water::disableTrueReflections"] = false;

        key["$pref::BeamNGVehicle::dynamicReflection::enabled"] = false;
    };

    new ArrayObject( [High] )
    {
       class = "GraphicsQualityLevel";
       caseSensitive = true;

        // MeshQualityGroup
        key["$pref::TS::detailAdjust"] = 1.5;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 0.75;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 1.0;

        //TextureQualityGroup
        key["$pref::Video::textureReductionLevel"] = 0;
        key["$pref::Reflect::refractTexScale"] = 1.25;
        key["$pref::Terrain::detailScale"] = 1.5;

        //LightingQualityGroup
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 2.0;
        key["$pref::Shadows::filterMode"] = "SoftShadowHighQuality";

        //ShaderQualityGroup
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = false;
        key["$pref::Water::disableTrueReflections"] = false;

        key["$pref::BeamNGVehicle::dynamicReflection::enabled"] = false;
    };
};



function Settings_Graphic_basic_quality_getValue()
{
    return BasicRenderQualityGroup.getCurrentLevelId();
}
function Settings_Graphic_basic_quality_setValue( %value )
{
    BasicRenderQualityGroup.applyLevelId( %value );
}
function Settings_Graphic_basic_quality_getOptions()
{
    return "[" SPC "\"" @ BasicRenderQualityGroup.getCount() @ "\"" SPC "]";
}

function getGraphicSettingsState()
{
    %str = "";
    %str = %str @ getSetting("Settings_Graphic_display_driver");
    %str = %str @ getSetting("Settings_Graphic_resolutions");
    %str = %str @ getSetting("Settings_Graphic_fullscreen");
    %str = %str @ getSetting("Settings_Graphic_borderless");
    %str = %str @ getSetting("Settings_Graphic_refresh_rate");
    %str = %str @ getSetting("Settings_Graphic_antialias");
    %str = %str @ getSetting("Settings_Graphic_anisotropic");
    %str = %str @ getSetting("Settings_Graphic_grass_density");
    %str = %str @ getSetting("dyn_reflection_enabled");
    %str = %str @ getSetting("dyn_reflection_detail");
    %str = %str @ getSetting("dyn_reflection_distance");
    %str = %str @ getSetting("dyn_reflection_texsize");
    %str = %str @ getSetting("dyn_reflection_facesPerupdate");
    %str = %str @ getSetting("Settings_Graphic_gamma");
    %str = %str @ getSetting("Settings_Graphic_mesh_quality");
    %str = %str @ getSetting("Settings_Graphic_texture_quality");
    %str = %str @ getSetting("Settings_Graphic_lighting_quality");
    %str = %str @ getSetting("Settings_Graphic_shader_quality");
    %str = %str @ getSetting("Settings_Graphic_postfx_quality");

    //debug( %str );

    return %str;
}

function reloadTS()
{
    exec("./graphic_optionsHelper.cs");
}
