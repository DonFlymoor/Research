$pref::BeamNGWaypoint::drawDebug = 1;
$pref::BeamNGNavGraph::drawDebug = 0;
$pref::BeamNGRace::drawDebug = 0;
$pref::DebugDraw::drawAdvancedText = 0;
$pref::Collada::UpdateMaterials = 0; // disable automatic generation of material files by default
$sceneLighting::cacheSize = 20000;
$sceneLighting::purgeMethod = "lastCreated";
$sceneLighting::cacheLighting = 1;

$pref::Video::displayDevice = "D3D11";
$pref::Video::vsync = 2; // smart vsync by default
$pref::Video::canvasSize = "1024 768";
$pref::Video::borderless = 0;
$pref::Video::defaultFenceCount = 0;
$pref::Video::screenShotFormat = "PNG";

/// This disables the hardware FSAA/MSAA so that we depend completely on the FXAA post effect which works on all cards and in deferred mode.
/// Note the new Intel Hybrid graphics on laptops will fail to initialize when hardware AA is enabled... so you've been warned.
$pref::Video::disableNormalmapping = false;
$pref::Video::disablePixSpecular = false;
$pref::Video::disableCubemapping = false;
$pref::Video::disableParallaxMapping = false;
$pref::Video::Gamma = 1.0;

$shaderGen::cachePath = getCacheFolder() @ "/shaders/procedural"; /// This is the path used by ShaderGen to cache procedural shaders. If left blank ShaderGen will only cache shaders to memory and not to disk.
$pref::lightManager = ""; /// The perfered light manager to use at startup.  If blank or if the selected one doesn't work on this platfom it will try the defaults below.
$lightManager::defaults = "Advanced Lighting" NL "Basic Lighting"; /// This is the default list of light managers ordered from most to least desirable for initialization.
$pref::camera::distanceScale = 1.0; /// A scale to apply to the camera view distance typically used for tuning performance.

$pref::SFX::providerName = "FMOD"; /// The sound provider to select at startup.  Typically this is DirectSound, OpenAL, or XACT.  There is also a special Null provider which acts normally, but plays no sound.
$pref::SFX::useHardware = false; /// If true the device will try to use hardware buffers and sound mixing.  If not it will use software.
$pref::SFX::maxSoftwareBuffers = 16; /// If you have a software device you have a choice of how many software buffers to allow at any one time.  More buffers cost more CPU time to process and mix.
$pref::SFX::masterVolume = 0.8; /// The overall system volume at startup.  Note that you can only scale volume down, volume does not get louder than 1.

/// The startup sound channel volumes.  These are used to control the overall volume of different classes of sounds.
$pref::SFX::channelVolume1 = 1;
$pref::SFX::channelVolume2 = 1;
$pref::SFX::channelVolume3 = 1;
$pref::SFX::channelVolume4 = 1;
$pref::SFX::channelVolume5 = 1;
$pref::SFX::channelVolume6 = 1;
$pref::SFX::channelVolume7 = 1;
$pref::SFX::channelVolume8 = 1;

$pref::Reflect::refractTexScale = 1.0; /// This is an scalar which can be used to reduce the reflection textures on all objects to save fillrate.
$pref::Reflect::frameLimitMS = 0; /// This is the total frame in milliseconds to budget for reflection rendering.  If your CPU bound and have alot of smaller reflection surfaces try reducing this time.  A time of 0ms only update 1 reflector per frame.
$pref::Water::disableTrueReflections = false; /// Set true to force all water objects to use static cubemap reflections.
$pref::GroundCover::densityScale = 1.0; // A global LOD scalar which can reduce the overall density of placed GroundCover.
$pref::TS::detailAdjust = 1.0; /// An overall scaler on the lod switching between DTS models. Smaller numbers makes the lod switch sooner.
$pref::Decals::enabled = true;
$pref::Video::textureReductionLevel = 0; /// The number of mipmap levels to drop on loaded textures to reduce video memory usage. It will skip any textures that have been defined as not allowing down scaling.
$pref::Shadows::textureScalar = 1.0;
$pref::Shadows::disable = false;

/// Sets the shadow filtering mode.
///  None - Disables filtering.
///  SoftShadow - Does a simple soft shadow
///  SoftShadowHighQuality
$pref::Shadows::filterMode = "SoftShadow";

$pref::Video::defaultAnisotropy = 4;
$pref::windEffectRadius = 25; /// Radius in meters around the camera that ForestItems are affected by wind. Note that a very large number with a large number of items is not cheap.
$pref::Video::autoDetect = 1; /// AutoDetect graphics quality levels the next startup.

//-----------------------------------------------------------------------------
// Graphics Quality Groups
//-----------------------------------------------------------------------------
// The graphics quality groups are used by the options dialog to control the state of the $prefs.  You should overload these in your game specific defaults.cs file if they need to be changed.

if ( isObject( MeshQualityGroup ) ) MeshQualityGroup.delete();
if ( isObject( TextureQualityGroup ) ) TextureQualityGroup.delete();
if ( isObject( LightingQualityGroup ) ) LightingQualityGroup.delete();
if ( isObject( ShaderQualityGroup ) ) ShaderQualityGroup.delete();

new SimGroup( MeshQualityGroup ) {
    class = "GraphicsQualityGroup";
    new ArrayObject( [Lowest] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::TS::detailAdjust"] = 0.5;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 2.0;
        key["$pref::decalMgr::enabled"] = false;
        key["$pref::GroundCover::densityScale"] = 0;
    };
    new ArrayObject( [Low] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::TS::detailAdjust"] = 0.75;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 1.5;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 0.50;
    };
    new ArrayObject( [Normal] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::TS::detailAdjust"] = 1.0;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 1.0;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 0.75;
    };
    new ArrayObject( [High] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::TS::detailAdjust"] = 1.5;
        key["$pref::TS::skipRenderDLs"] = 0;
        key["$pref::Terrain::lodScale"] = 0.75;
        key["$pref::decalMgr::enabled"] = true;
        key["$pref::GroundCover::densityScale"] = 1.0;
    };
};


new SimGroup( TextureQualityGroup ) {
    class = "GraphicsQualityGroup";
    new ArrayObject( [Lowest] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::textureReductionLevel"] = 2;
        key["$pref::Reflect::refractTexScale"] = 0.5;
        key["$pref::Terrain::detailScale"] = 0.5;
    };
    new ArrayObject( [Low] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::textureReductionLevel"] = 1;
        key["$pref::Reflect::refractTexScale"] = 0.75;
        key["$pref::Terrain::detailScale"] = 0.75;
    };
    new ArrayObject( [Normal] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::textureReductionLevel"] = 0;
        key["$pref::Reflect::refractTexScale"] = 1;
        key["$pref::Terrain::detailScale"] = 1;
    };
    new ArrayObject( [High] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::textureReductionLevel"] = 0;
        key["$pref::Reflect::refractTexScale"] = 1;
        key["$pref::Terrain::detailScale"] = 1.5;
    };
};

function TextureQualityGroup::onApply( %this, %level ) {
    reloadTextures(); // Note that this can be a slow operation.
}


new SimGroup( LightingQualityGroup ) {
    class = "GraphicsQualityGroup";
    new ArrayObject( [Lowest] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::lightManager"] = "Basic Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 0.5;
        key["$pref::Shadows::filterMode"] = "None";
    };
    new ArrayObject( [Low] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 0.5;
        key["$pref::Shadows::filterMode"] = "SoftShadow";
    };
    new ArrayObject( [Normal] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 1.0;
        key["$pref::Shadows::filterMode"] = "SoftShadowHighQuality";
    };
    new ArrayObject( [High] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::lightManager"] = "Advanced Lighting";
        key["$pref::Shadows::disable"] = false;
        key["$pref::Shadows::textureScalar"] = 2.0;
        key["$pref::Shadows::filterMode"] = "SoftShadowHighQuality";
    };
};

function LightingQualityGroup::onApply( %this, %level ) {
    setLightManager( $pref::lightManager ); // Set the light manager.  This should do nothing if its already set or if its not compatible.
}


// TODO: Reduce shader complexity of water and the scatter sky here!
new SimGroup( ShaderQualityGroup ) {
    class = "GraphicsQualityGroup";
    new ArrayObject( [Lowest] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::disablePixSpecular"] = true;
        key["$pref::Video::disableNormalmapping"] = true;
        key["$pref::Video::disableParallaxMapping"] = true;
        key["$pref::Water::disableTrueReflections"] = true;
    };
    new ArrayObject( [Low] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = true;
        key["$pref::Water::disableTrueReflections"] = true;
    };
    new ArrayObject( [Normal] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = false;
        key["$pref::Water::disableTrueReflections"] = false;
        key["$pref::Video::ShaderQualityGroup"] = "Normal";
    };
    new ArrayObject( [High] ) {
        class = "GraphicsQualityLevel";
        caseSensitive = true;
        key["$pref::Video::disablePixSpecular"] = false;
        key["$pref::Video::disableNormalmapping"] = false;
        key["$pref::Video::disableParallaxMapping"] = false;
        key["$pref::Water::disableTrueReflections"] = false;
        key["$pref::Video::ShaderQualityGroup"] = "High";
    };
};

function GraphicsQualityGroup::applyLevel( %this, %levelString ) {
    for( %itr = 0; %itr < %this.getCount(); %itr++ ) {
        %level = %this.getObject(%itr);
        if( %level.getInternalName() !$= %levelString ) continue;
        %level.apply();
    }
}

function GraphicsQualityGroup::applyLevelId( %this, %levelId ) {
    if( %levelId < %this.getCount() ) {
        %level = %this.getObject(%levelId);
        %level.apply();
    }
}

function GraphicsQualityGroup::getCurrentLevel( %this, %levelString ) {
    for( %itr = 0; %itr < %this.getCount(); %itr++ ) {
        %level = %this.getObject(%itr);
        if( %level.iscurrent() ) return %level.getInternalName();
    }
    return "Custom";
}

function GraphicsQualityGroup::getCurrentLevelId( %this ) {
    for( %itr = 0; %itr < %this.getCount(); %itr++ ) {
        %level = %this.getObject(%itr);
        if( %level.iscurrent() ) return %itr;
    }
    return (%this.getCount()+1) / 2;
}

/// Returns true if the current quality settings equal this graphics quality level.
function GraphicsQualityLevel::isCurrent( %this ) {
    // Test each pref to see if the current value equals our stored value.
    for ( %i=0; %i < %this.count(); %i++ ) {
        %pref = %this.getKey( %i );
        %value = %this.getValue( %i );
        if ( getVariable( %pref ) !$= %value ) return false;
    }
    return true;
}

/// Applies the graphics quality settings and calls 'onApply' on itself or its parent group if its been overloaded.
function GraphicsQualityLevel::apply( %this ) {
    for ( %i=0; %i < %this.count(); %i++ ) {
        %pref = %this.getKey( %i );
        %value = %this.getValue( %i );
        setVariable( %pref, %value );
    }

    // If we have an overloaded onApply method then call it now to finalize the changes.
    if ( %this.isMethod( "onApply" ) )
        %this.onApply();
    else {
        %group = %this.getGroup();
        if ( isObject( %group ) && %group.isMethod( "onApply" ) )
            %group.onApply( %this );
    }
}

function GraphicsQualityAutodetect() {
    $pref::Video::autoDetect = false;
    %shaderVer = getPixelShaderVersion();
    %intel = ( strstr( strupr( getDisplayDeviceInformation() ), "INTEL" ) != -1 ) ? true : false;
    %videoMem = GFXCardProfilerAPI::getVideoMemoryMB();
    return GraphicsQualityAutodetect_Apply( %shaderVer, %intel, %videoMem );
}

function GraphicsQualityAutodetect_Apply( %shaderVer, %intel, %videoMem ) {
    if ( %shaderVer < 2.0 ) {
        error("Your video card does not meet the minimum requirment of shader model 2.0.");
        return;
    }

    if ( %shaderVer < 3.0 ) {
        MeshQualityGroup-->Lowest.apply();
        TextureQualityGroup-->Lowest.apply();
        LightingQualityGroup-->Lowest.apply();
        ShaderQualityGroup-->Lowest.apply();
        PostFXManager::settingsApplyLowestPreset();
    } else {
        if ( %videoMem > 1000 ) {
            MeshQualityGroup-->High.apply();
            TextureQualityGroup-->High.apply();
            LightingQualityGroup-->High.apply();
            ShaderQualityGroup-->High.apply();
            PostFXManager::settingsApplyHighPreset();
        } else if ( %videoMem > 500 || %videoMem == 0 ) {
            MeshQualityGroup-->Normal.apply();
            TextureQualityGroup-->Normal.apply();
            LightingQualityGroup-->Normal.apply();
            ShaderQualityGroup-->Normal.apply();
            PostFXManager::settingsApplyNormalPreset();
            if ( %videoMem == 0 ) {
                error("Unable to detect available video memory. Applying 'Normal' quality.");
                return;
            }
        } else if ( %videoMem > 250 ) {
            MeshQualityGroup-->Low.apply();
            TextureQualityGroup-->Low.apply();
            LightingQualityGroup-->Low.apply();
            ShaderQualityGroup-->Low.apply();
            PostFXManager::settingsApplyLowPreset();
        } else {
            MeshQualityGroup-->Lowest.apply();
            TextureQualityGroup-->Lowest.apply();
            LightingQualityGroup-->Lowest.apply();
            ShaderQualityGroup-->Lowest.apply();
            PostFXManager::settingsApplyLowestPreset();
        }
    }
    info("Graphics quality settings have been auto detected.");
    return;
}
