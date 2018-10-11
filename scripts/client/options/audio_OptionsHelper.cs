//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Audio provider
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(Settings_Audio_provider)
{
    class = "OptionHelper";
};
function Settings_Audio_provider::_buildOptions(%this)
{
    %buffer = sfxGetAvailableDevices();
    %count = getRecordCount( %buffer );
    for(%i = 0; %i < %count; %i++)
    {
        %record = getRecord(%buffer, %i);
        %provider = getField(%record, 0);

        if( strstr( strupr(%provider), "NULL" ) == -1 )
                %this.addOption( %provider, %provider );
    }
}
function Settings_Audio_provider::_getValue( %this )
{
    return $pref::SFX::providerName;
}
function Settings_Audio_provider::_setValue( %this, %value )
{
    $pref::SFX::providerName = %value;
    applyAudioOptions();
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Audio master_vol
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(Settings_Audio_master_vol)
{
    class = "OptionHelper";
};
function Settings_Audio_master_vol::_buildOptions(%this)
{
}
function Settings_Audio_master_vol::_getValue( %this )
{
    return $pref::SFX::masterVolume;
}
function Settings_Audio_master_vol::_setValue( %this, %value )
{
    OptAudioUpdateMasterVolume( %value );
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Audio interface_vol
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(Settings_Audio_interface_vol)
{
    class = "OptionHelper";
};
function Settings_Audio_interface_vol::_buildOptions(%this)
{
}
function Settings_Audio_interface_vol::_getValue( %this )
{
    //sfxGroupToOldChannel function also exists on the lua side, see audio_client
    %channel = sfxGroupToOldChannel( AudioGui.sourceGroup );

    return $pref::SFX::channelVolume[ %channel ];
}
function Settings_Audio_interface_vol::_setValue( %this, %value )
{
    OptAudioUpdateChannelVolume(AudioGui, %value);
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Audio effects_vol
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(Settings_Audio_effects_vol)
{
    class = "OptionHelper";
};
function Settings_Audio_effects_vol::_buildOptions(%this)
{
}
function Settings_Audio_effects_vol::_getValue( %this )
{
    //sfxGroupToOldChannel function also exists on the lua side, see audio_client
    %channel = sfxGroupToOldChannel( AudioEffect.sourceGroup );

    return $pref::SFX::channelVolume[ %channel ];
}
function Settings_Audio_effects_vol::_setValue( %this, %value )
{
    OptAudioUpdateChannelVolume(AudioEffect, %value);
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Audio music_vol
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
singleton SimObject(Settings_Audio_music_vol)
{
    class = "OptionHelper";
};
function Settings_Audio_music_vol::_buildOptions(%this)
{
}
function Settings_Audio_music_vol::_getValue( %this )
{
    //sfxGroupToOldChannel function also exists on the lua side, see audio_client
    %channel = sfxGroupToOldChannel( AudioMusic.sourceGroup );

    return $pref::SFX::channelVolume[ %channel ];
}
function Settings_Audio_music_vol::_setValue( %this, %value )
{
    OptAudioUpdateChannelVolume(AudioMusic, %value);
}

function OptAudioUpdateMasterVolume( %volume )
{
    debug("OptAudioUpdateMasterVolume " @ %volume);
    sfxSetMasterVolume( %volume );
    $pref::SFX::masterVolume = %volume;
    if( !isObject( $AudioTestHandle ) )
        $AudioTestHandle = sfxPlayOnce( AudioChannel, "core/art/sound/volumeTest.wav" );
}

function OptAudioUpdateChannelVolume( %description, %volume )
{
    //sfxGroupToOldChannel function also exists on the lua side, see audio_client
    %channel = sfxGroupToOldChannel( %description.sourceGroup );

    if( %volume == $pref::SFX::channelVolume[ %channel ] )
        return;

    sfxSetChannelVolume( %channel, %volume );
    $pref::SFX::channelVolume[ %channel ] = %volume;

    if( !isObject( $AudioTestHandle ) )
    {
        $AudioTestDescription.volume = %volume;
        $AudioTestHandle = sfxPlayOnce( $AudioTestDescription, "core/art/sound/volumeTest.wav" );
    }
}

function applyAudioOptions()
{
    if ( !sfxCreateDevice(  $pref::SFX::providerName, $pref::SFX::useHardware, -1 ) )
        error( "Unable to create SFX device: " @ $pref::SFX::providerName SPC $pref::SFX::useHardware );
    beamNGExecuteJS( "HookManager.trigger('OptionsChanged')");
}

function getAudioSettingsState()
{
    %str = "";
    %str = %str @ getSetting("Settings_Audio_provider");
    %str = %str @ getSetting("Settings_Audio_master_vol");
    %str = %str @ getSetting("Settings_Audio_interface_vol");
    %str = %str @ getSetting("Settings_Audio_effects_vol");
    %str = %str @ getSetting("Settings_Audio_music_vol");

    return %str;
}

