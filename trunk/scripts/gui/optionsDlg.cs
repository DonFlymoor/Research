
function GraphicsQualityPopup::init( %this, %qualityGroup )
{
    assert( isObject( %this ) );
    assert( isObject( %qualityGroup ) );

    // Clear the existing content first.
    %this.clear();

    // Fill it.
    %select = -1;
    for ( %i=0; %i < %qualityGroup.getCount(); %i++ )
    {
        %level = %qualityGroup.getObject( %i );
        if ( %level.isCurrent() )
            %select = %i;

        %this.add( %level.getInternalName(), %i );
    }

    // Setup a default selection.
    if ( %select == -1 )
        %this.setText( "Custom" );
    else
        %this.setSelected( %select );
}

function GraphicsQualityPopup::apply( %this, %qualityGroup, %testNeedApply )
{
    assert( isObject( %this ) );
    assert( isObject( %qualityGroup ) );

    %quality = %this.getText();

    %index = %this.findText( %quality );
    if ( %index == -1 )
        return false;

    %level = %qualityGroup.getObject( %index );
    if ( isObject( %level ) && !%level.isCurrent() )
    {
        if ( %testNeedApply )
            return true;

        %level.apply();
    }

    return false;
}

function OptionsDlg::setPane(%this, %pane)
{
    %this-->OptAudioPane.setVisible(false);
    %this-->OptGraphicsPane.setVisible(false);
    %this-->OptNetworkPane.setVisible(false);
    %this-->OptControlsPane.setVisible(false);

    %this.findObjectByInternalName( "Opt" @ %pane @ "Pane", true ).setVisible(true);

    %this.fillRemapList();

    // Update the state of the apply button.
    %this._updateApplyState();
}

function OptionsDlg::onWake(%this)
{
    //initDisplayDeviceInfo();
    %this-->OptGraphicsFullscreenToggle.setStateOn( Canvas.isFullScreen() );
    %this-->OptGraphicsBorderlessToggle.setStateOn( $pref::Video::borderless );

    OptionsDlg.initResMenu();
    %resSelId = OptionsDlg-->OptGraphicsResolutionMenu.findText( _makePrettyResString( $pref::Video::mode ) );
    if( %resSelId != -1 )
    {
        OptionsDlg-->OptGraphicsResolutionMenu.setSelected( %resSelId );
    }

    OptGraphicsDriverMenu.clear();

    // display drivers
    %buffer = getDisplayDeviceList();
    %count = getFieldCount( %buffer );
    for(%i = 0; %i < %count; %i++)
        OptGraphicsDriverMenu.add(getField(%buffer, %i), %i);

    %selId = OptGraphicsDriverMenu.findText( getDisplayDeviceInformation() );
    if ( %selId == -1 )
        OptGraphicsDriverMenu.setFirstSelected();
    else
       OptGraphicsDriverMenu.setSelected( %selId );

    // Setup the graphics quality dropdown menus.
    %this-->OptMeshQualityPopup.init( MeshQualityGroup );
    %this-->OptTextureQualityPopup.init( TextureQualityGroup );
    %this-->OptLightingQualityPopup.init( LightingQualityGroup );
    %this-->OptShaderQualityPopup.init( ShaderQualityGroup );

    // Setup the anisotropic filtering menu.
    %ansioCtrl = %this-->OptAnisotropicPopup;
    %ansioCtrl.clear();
    %ansioCtrl.add( "Off", 0 );
    %ansioCtrl.add( "4X", 4 );
    %ansioCtrl.add( "8X", 8 );
    %ansioCtrl.add( "16X", 16 );
    %ansioCtrl.setSelected( $pref::Video::defaultAnisotropy, false );

    // set up the Refresh Rate menu.
    %refreshMenu = %this-->OptRefreshSelectMenu;
    %refreshMenu.clear();
    // %refreshMenu.add("Auto", 60);
    %refreshMenu.add("59", 59);
    %refreshMenu.add("60", 60);
    %refreshMenu.add("75", 75);
    %refreshMenu.add("120", 120);
    %refreshMenu.setSelected( getWord( $pref::Video::mode, $WORD::REFRESH ) );

    // Audio
    //OptAudioHardwareToggle.setStateOn($pref::SFX::useHardware);
    //OptAudioHardwareToggle.setActive( true );

    debug("Setting optaudiovolumemaster to " @ $pref::SFX::masterVolume);
    %this-->OptAudioVolumeMaster.setValue( $pref::SFX::masterVolume );
    %this-->OptAudioVolumeShell.setValue( $pref::SFX::channelVolume[ $GuiAudioType] );
    %this-->OptAudioVolumeSim.setValue( $pref::SFX::channelVolume[ $SimAudioType ] );
    %this-->OptAudioVolumeMusic.setValue( $pref::SFX::channelVolume[ $MusicAudioType ] );

    OptAudioProviderList.clear();
    %buffer = sfxGetAvailableDevices();
    %count = getRecordCount( %buffer );
    for(%i = 0; %i < %count; %i++)
    {
        %record = getRecord(%buffer, %i);
        %provider = getField(%record, 0);

        if ( OptAudioProviderList.findText( %provider ) == -1 )
                OptAudioProviderList.add( %provider, %i );
    }

    OptAudioProviderList.sort();

    %selId = OptAudioProviderList.findText($pref::SFX::providerName);
    if ( %selId == -1 )
        OptAudioProviderList.setFirstSelected();
    else
       OptAudioProviderList.setSelected( %selId );

    // Populate the Anti-aliasing popup.
    %aaMenu = %this-->OptAAQualityPopup;
    %aaMenu.clear();
    %aaMenu.Add( "Off", 0 );
    %aaMenu.Add( "1x", 1 );
    %aaMenu.Add( "2x", 2 );
    %aaMenu.Add( "4x", 4 );
    %aaMenu.setSelected( getWord( $pref::Video::mode, $WORD::AA ) );

    // Set the graphics pane to start.
    %this-->OptGraphicsButton.performClick();
}

function OptionsDlg::onSleep(%this)
{
    // write out the control config into the rw/config.cs file
    //moveMap.save( "scripts/client/config.cs" );
}

function OptGraphicsDriverMenu::onSelect( %this, %id, %text )
{
    // Attempt to keep the same resolution settings:
    %resMenu = OptionsDlg-->OptGraphicsResolutionMenu;
    %currRes = %resMenu.getText();

    // If its empty the use the current.
    if ( %currRes $= "" )
        %currRes = _makePrettyResString( Canvas.getVideoModeStr() );

    // Fill the resolution list.
    optionsDlg.initResMenu();

    // Try to select the previous settings:
    %selId = %resMenu.findText( %currRes );
    if ( %selId == -1 )
       %selId = 0;
    %resMenu.setSelected( %selId );

    OptionsDlg._updateApplyState();
}

function _makePrettyResString( %resString )
{
    %width = getWord( %resString, $WORD::RES_X );
    %height = getWord( %resString, $WORD::RES_Y );

    %aspect = %width / %height;
    %aspect = mRound( %aspect * 100 ) * 0.01;

    switch$( %aspect )
    {
        case "1.33":
            %aspect = "4:3";
        case "1.78":
            %aspect = "16:9";
        default:
            %aspect = "";
    }

    %outRes = %width @ " x " @ %height;
    if ( %aspect !$= "" )
        %outRes = %outRes @ "  (" @ %aspect @ ")";

    return %outRes;
}

function OptionsDlg::initResMenu( %this )
{
    // Clear out previous values
    %resMenu = %this-->OptGraphicsResolutionMenu;
    %resMenu.clear();

    // Loop through all and add all valid resolutions
    %count = 0;
    %resCount = Canvas.getModeCount();
    for (%i = 0; %i < %resCount; %i++)
    {
        %testResString = Canvas.getMode( %i );
        %testRes = _makePrettyResString( %testResString );

        // Only add to list if it isn't there already.
        if (%resMenu.findText(%testRes) == -1)
        {
            %resMenu.add(%testRes, %i);
            %count++;
        }
    }
    %this.customResStart = 5000;

    %currentModeStr = _makePrettyResString( $pref::Video::mode );
    %resSelId = %resMenu.findText( %currentModeStr );
    if( %resSelId == -1 )
    {
        // current res not found, so add it
        %resMenu.add(%currentModeStr, %this.customResStart + 1);
        %count++;
    }

    %resMenu.sort();
}

function OptionsDlg::applyGraphics( %this, %testNeedApply )
{
    %newAdapter    = OptGraphicsDriverMenu.getText();
    %numAdapters   = GFXInit::getAdapterCount();
    %newDevice     = $pref::Video::displayDevice;
    %outputName    = $pref::Video::displayOutputDevice;

    for( %i = 0; %i < %numAdapters; %i ++ )
    {
       if( GFXInit::getAdapterName( %i ) $= %newAdapter )
       {
          %newDevice = GFXInit::getAdapterType( %i );
          %outputName = GFXInit::getAdapterOutputName( %i );
          break;
       }
    }

    // Change the device.
    //if ( %outputName !$= $pref::Video::displayOutputDevice || %newDevice !$= $pref::Video::displayDevice )
    if ( %newDevice !$= $pref::Video::displayDevice )
    {
        if ( %testNeedApply )
            return true;

        $pref::Video::displayDevice = %newDevice;
        if( %newAdapter !$= getDisplayDeviceInformation() )
            MessageBoxOK( "Change requires restart", "Please restart the game for a display device change to take effect." );
    }

    if ( %outputName !$= $pref::Video::displayOutputDevice )
    {
        if(%testNeedApply)
            return true;
        MessageBoxOK( "Change requires restart", "Please restart the game for a display device change to take effect." );
    }

    // Gather the new video mode.
    if(%this-->OptGraphicsResolutionMenu.getSelected() < %this.customResStart)
    {
      %newRes = getWords( Canvas.getMode( %this-->OptGraphicsResolutionMenu.getSelected() ), $WORD::RES_X, $WORD::RES_Y );
    } else {
        // custom res
        %newRes = getWord( %this-->OptGraphicsResolutionMenu.getText(), 0) SPC getWord( %this-->OptGraphicsResolutionMenu.getText(), 2);
    }
    %newBpp        = 32; // ... its not 1997 anymore.
    %newFullScreen = %this-->OptGraphicsFullscreenToggle.getValue() ? "true" : "false";
    %newRefresh    = %this-->OptRefreshSelectMenu.getSelected();
    %newFSAA = %this-->OptAAQualityPopup.getSelected();
    %newBorderless = %this-->OptGraphicsBorderlessToggle.getValue();

    /*
    // disabled to support multi monitor scenarios
    else if ( %newFullScreen $= "false" )
    {
        // If we're in windowed mode switch the fullscreen check
        // if the resolution is bigger than the desktop.
        %deskRes    = getDesktopResolution();
        %deskResX   = getWord(%deskRes, $WORD::RES_X);
        %deskResY   = getWord(%deskRes, $WORD::RES_Y);
       if (  getWord( %newRes, $WORD::RES_X ) > %deskResX ||
             getWord( %newRes, $WORD::RES_Y ) > %deskResY )
        {
            %newFullScreen = "true";
            %this-->OptGraphicsFullscreenToggle.setStateOn( true );
        }
    }
    */

    // Build the final mode string.
    %newMode = %newRes SPC %newFullScreen SPC %newBpp SPC %newRefresh SPC %newFSAA;

    // Change the video mode.
    if (  %newMode !$= $pref::Video::mode ||
            %newBorderless != $pref::Video::borderless ||
            %outputName !$= $pref::Video::displayOutputDevice )
    {
        if ( %testNeedApply )
            return true;

        $pref::Video::mode = %newMode;
        $pref::Video::borderless = %newBorderless;
        $pref::Video::displayOutputDevice = %outputName;

        configureCanvas();
    }

    // Test and apply the graphics settings.
    if ( %this-->OptMeshQualityPopup.apply( MeshQualityGroup, %testNeedApply ) ) return true;
    if ( %this-->OptTextureQualityPopup.apply( TextureQualityGroup, %testNeedApply ) ) return true;
    if ( %this-->OptLightingQualityPopup.apply( LightingQualityGroup, %testNeedApply ) ) return true;
    if ( %this-->OptShaderQualityPopup.apply( ShaderQualityGroup, %testNeedApply ) ) return true;

    // Check the anisotropic filtering.
    %level = %this-->OptAnisotropicPopup.getSelected();
    if ( %level != $pref::Video::defaultAnisotropy )
    {
        if ( %testNeedApply )
            return true;

        $pref::Video::defaultAnisotropy = %level;
    }

    // If we're applying the state then recheck the
    // state to update the apply button.
    if ( !%testNeedApply )
    {
        %this._updateApplyState();
    }


    return false;
}

function OptionsDlg::_updateApplyState( %this )
{
    %applyCtrl = %this-->Apply;
    %graphicsPane = %this-->OptGraphicsPane;

    assert( isObject( %applyCtrl ) );
    assert( isObject( %graphicsPane ) );

    %applyCtrl.active = %graphicsPane.isVisible() && %this.applyGraphics( true );
}

function OptionsDlg::_fullscreenChanged( %this )
{
    // Switching between fullscreen and windowed can trigger the vsync mode to change,
    // so temporarily set the new mode string to see what vsync we will get and
    // update the UI appropriately.
    // TODO: This is hacky, write a dedicated function for this instead.
    %newFullScreen = %this-->OptGraphicsFullscreenToggle.getValue() ? "true" : "false";

    %oldMode = $pref::Video::mode;
    $pref::Video::mode = setWord(%oldMode, $WORD::FULLSCREEN, %newFullScreen);
    $pref::Video::mode = %oldMode;

    %this._updateApplyState();
}

function OptionsDlg::_autoDetectQuality( %this )
{
    %msg = GraphicsQualityAutodetect();
    %this.onWake();

    if ( %msg !$= "" )
    {
        MessageBoxOK( "Notice", %msg );
    }
}


$AudioTestHandle = 0;
// Description to use for playing the volume test sound.  This isn't
// played with the description of the channel that has its volume changed
// because we know nothing about the playback state of the channel.  If it
// is paused or stopped, the test sound would not play then.
$AudioTestDescription = new SFXDescription()
{
    sourceGroup = AudioChannelMaster;
};


function OptAudioProviderList::onSelect( %this, %id, %text )
{
    // Skip empty provider selections.
    if ( %text $= "" )
        return;

    $pref::SFX::providerName = %text;
    OptAudioDeviceList.clear();

    %buffer = sfxGetAvailableDevices();
    %count = getRecordCount( %buffer );
    for(%i = 0; %i < %count; %i++)
    {
        %record = getRecord(%buffer, %i);
        %provider = getField(%record, 0);
        %device = getField(%record, 1);

        if (%provider !$= %text)
            continue;

       if ( OptAudioDeviceList.findText( %device ) == -1 )
                OptAudioDeviceList.add( %device, %i );
    }

    // Find the previous selected device.
    OptAudioDeviceList.setFirstSelected();
}

/*
function OptAudioHardwareToggle::onClick(%this)
{
    if (!sfxCreateDevice($pref::SFX::providerName, $pref::SFX::useHardware, -1))
        error("Unable to create SFX device: " @ $pref::SFX::providerName SPC $pref::SFX::useHardware);
}
*/
