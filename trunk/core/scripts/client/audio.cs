
//-----------------------------------------------------------------------------
//    Source groups.
//-----------------------------------------------------------------------------

singleton SFXDescription( AudioMaster );
singleton SFXSourceChannel( AudioChannelMaster )
{
    description = AudioMaster;
};

singleton SFXDescription( AudioChannel )
{
    sourceGroup = AudioChannelMaster;
};

singleton SFXSourceChannel( AudioChannelDefault )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelGui )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelGuiComic )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelEffects )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelMessages )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelMusic )
{
    description = AudioChannel;
};
singleton SFXSourceChannel( AudioChannelAmbience )
{
    description = AudioChannel;
};

// Set default playback states of the channels.

AudioChannelMaster.play();
AudioChannelDefault.play();

AudioChannelGui.play();
AudioChannelMusic.play();
AudioChannelMessages.play();

// Stop in-game effects channels.
AudioChannelEffects.stop();

//-----------------------------------------------------------------------------
//    Master SFXDescriptions.
//-----------------------------------------------------------------------------

// Master description for interface audio.
singleton SFXDescription( AudioGui )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelGui;
    useSimTime     = false;
};

singleton SFXDescription( AudioGuiComic )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelGuiComic;
    useSimTime     = false;
};

// Master description for game effects audio.
singleton SFXDescription( AudioEffect )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelEffects;
};

// Master description for audio in notifications.
singleton SFXDescription( AudioMessage )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelMessages;
};

// Master description for music.
singleton SFXDescription( AudioMusic )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelMusic;
};

// Master description for ambience.
singleton SFXDescription( AudioAmbience )
{
    volume         = 1.0;
    sourceGroup    = AudioChannelAmbience;
};

//-----------------------------------------------------------------------------
//    SFX Functions.
//-----------------------------------------------------------------------------

/// This initializes the sound system device from the defaults in the $pref::SFX:: globals.
function sfxInit() {
    // If already initialized, shut down the current device first.
    if( sfxGetDeviceInfo() !$= "" ) {
        sfxShutdown();
    }

    // Start it up!
    %maxBuffers = $pref::SFX::useHardware ? -1 : $pref::SFX::maxSoftwareBuffers;
    if ( !sfxCreateDevice( $pref::SFX::providerName, $pref::SFX::useHardware, -1 ) ) {
        error( "Failed to initialize provider: " @  $pref::SFX::providerName);
        return sfxCreateDevice( "Null", $pref::SFX::useHardware, -1 );
    }

    // This returns a tab seperated string with the initialized system info.
    %info = sfxGetDeviceInfo();
    $pref::SFX::useHardware    = getField( %info, 2 );
    %useHardware               = $pref::SFX::useHardware ? "Yes" : "No";
    %maxBuffers                = getField( %info, 3 );

    debug( "   Provider: "    @ $pref::SFX::providerName );
    debug( "   Hardware: "    @ %useHardware );
    debug( "   Buffers: "      @ %maxBuffers );

    if( isDefined( "$pref::SFX::distanceModel" ) ) sfxSetDistanceModel( $pref::SFX::distanceModel );
    if( isDefined( "$pref::SFX::dopplerFactor" ) ) sfxSetDopplerFactor( $pref::SFX::dopplerFactor );
    if( isDefined( "$pref::SFX::rolloffFactor" ) ) sfxSetRolloffFactor( $pref::SFX::rolloffFactor );

    // Restore volumes
    sfxSetMasterVolume( $pref::SFX::masterVolume );
    for( %channel = 0; %channel <= 8; %channel ++ )
        sfxSetChannelVolume( %channel, $pref::SFX::channelVolume[ %channel ] );

    return true;
}


/// Destroys the current sound system device.
function sfxShutdown()
{
    // Store volume prefs.
    //debug("Stored volume " @ $pref::SFX::masterVolume);

    for( %channel = 0; %channel <= 8; %channel ++ )
        $pref::SFX::channelVolume[ %channel ] = sfxGetChannelVolume( %channel );

    // We're assuming here that a null info
    // string means that no device is loaded.
    if( sfxGetDeviceInfo() $= "" )
        return;

    sfxDeleteDevice();
}


/// Determines which of the two SFX providers is preferable.
function sfxCompareProvider( %providerA, %providerB )
{
    if( %providerA $= %providerB )
        return 0;

    switch$( %providerA )
    {
        // Prefer OpenAL over anything
        case "OpenAL":
        case "OpenALSoft":
            return 1;

        // As long as the XAudio SFX provider still has issues, choose stable DSound over it.
        case "DirectSound":
            if( %providerB $= "OpenAL" )
                return -1;
            else
                return 0;

        case "XAudio":
            if( %providerB !$= "OpenAL" && %providerB !$= "DirectSound" )
                return 1;
            else
                return -1;

        default:
            return -1;
    }
}

//-----------------------------------------------------------------------------
//    Backwards-compatibility with old channel system.
//-----------------------------------------------------------------------------

// Volume channel IDs for backwards-compatibility.

$GuiAudioType        = 1;  // Interface.
$SimAudioType        = 2;  // Game.
$MessageAudioType    = 3;  // Notifications.
$MusicAudioType      = 4;  // Music.
$AmbienceAudioType   = 5;

$AudioChannels[ 0 ] = AudioChannelDefault;
$AudioChannels[ $GuiAudioType ] = AudioChannelGui;
$AudioChannels[ $SimAudioType ] = AudioChannelEffects;
$AudioChannels[ $MessageAudioType ] = AudioChannelMessages;
$AudioChannels[ $MusicAudioType ] = AudioChannelMusic;
$AudioChannels[ $AmbienceAudioType ] = AudioChannelAmbience;

function sfxOldChannelToGroup( %channel )
{
    return $AudioChannels[ %channel ];
}

//This function has been implemented on the lua side, see audio_client
function sfxGroupToOldChannel( %group )
{
    %id = %group.getId();
    for( %i = 0;; %i ++ )
        if( !isObject( $AudioChannels[ %i ] ) )
            return -1;
        else if( $AudioChannels[ %i ].getId() == %id )
            return %i;

    return -1;
}

function sfxSetMasterVolume( %volume )
{
    //debug("Setting master volume to " @ %volume);
    AudioChannelMaster.setVolume( %volume );
}

function sfxGetMasterVolume( %volume )
{
    return AudioChannelMaster.getVolume();
}

function sfxStopAll( %channel )
{
    // Don't stop channel itself since that isn't quite what the function
    // here intends.

    %channel = sfxOldChannelToGroup( %channel );
    if (isObject(%channel))
    {
        foreach( %source in %channel )
            %source.stop();
    }
}

function sfxGetChannelVolume( %channel )
{
    %obj = sfxOldChannelToGroup( %channel );
    if( isObject( %obj ) )
        return %obj.getVolume();
}

function sfxSetChannelVolume( %channel, %volume )
{
    %obj = sfxOldChannelToGroup( %channel );
    if( isObject( %obj ) )
        %obj.setVolume( %volume );
}

singleton SimSet( SFXPausedSet );


/// Pauses the playback of active sound sources.
///
/// @param %channels    An optional word list of channel indices or an empty
///                     string to pause sources on all channels.
/// @param %pauseSet    An optional SimSet which is filled with the paused
///                     sources.  If not specified the global SfxSourceGroup
///                     is used.
///
/// @deprecated
///
function sfxPause( %channels, %pauseSet )
{
    // Did we get a set to populate?
    if ( !isObject( %pauseSet ) )
        %pauseSet = SFXPausedSet;

    %count = SFXSourceSet.getCount();
    for ( %i = 0; %i < %count; %i++ )
    {
        %source = SFXSourceSet.getObject( %i );

        %channel = sfxGroupToOldChannel( %source.getGroup() );
        if( %channels $= "" || findWord( %channels, %channel ) != -1 )
        {
            %source.pause();
            %pauseSet.add( %source );
        }
    }
}


/// Resumes the playback of paused sound sources.
///
/// @param %pauseSet    An optional SimSet which contains the paused sound
///                     sources to be resumed.  If not specified the global
///                     SfxSourceGroup is used.
/// @deprecated
///
function sfxResume( %pauseSet )
{
    if ( !isObject( %pauseSet ) )
        %pauseSet = SFXPausedSet;

    %count = %pauseSet.getCount();
    for ( %i = 0; %i < %count; %i++ )
    {
        %source = %pauseSet.getObject( %i );
        %source.play();
    }

    // Clear our pause set... the caller is left
    // to clear his own if he passed one.
    %pauseSet.clear();
}
