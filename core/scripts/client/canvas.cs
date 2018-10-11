
//---------------------------------------------------------------------------------------------
// initializeCanvas
// Constructs and initializes the default canvas window.
//---------------------------------------------------------------------------------------------
$canvasCreated = false;

function checkDeviceIsNonINTEL( %newDevice )
{
    if( %newDevice $= $checkDeviceIsNonINTEL_lastDevice )
        return;

    $checkDeviceIsNonINTEL_lastDevice = %newDevice;

    if( strstr( strupr( %newDevice ), "INTEL" ) == -1 )
        return;

    %numAdapters   = GFXInit::getAdapterCount();
    for( %i = 0; %i < %numAdapters; %i ++ )
    {
       if( strstr( strupr( GFXInit::getAdapterName( %i ) ), "INTEL" ) == -1 )
       {
           schedule( 1000, 0, "MessageBoxOK" , "Performance Warning", "You are using an Intel GPU, please choose a different one to improve performance");
           return;
       }
    }
}

function configureCanvas()
{
    checkDeviceIsNonINTEL( getDisplayDeviceInformation() );

    // Setup a good default if we don't have one already.
    if ($pref::Video::mode $= "")
        $pref::Video::mode = "800 600 false 32 60 0";

    %resX = getWord($pref::Video::mode, $WORD::RES_X);
    %resY = getWord($pref::Video::mode, $WORD::RES_Y);
    %fs = getWord($pref::Video::mode,   $WORD::FULLSCREEN);
    %bpp = getWord($pref::Video::mode,  $WORD::BITDEPTH);
    %rate = getWord($pref::Video::mode, $WORD::REFRESH);
    %fsaa = getWord($pref::Video::mode, $WORD::AA);

    //debug("--------------");
    debug("Attempting to set resolution to \"" @ $pref::Video::mode @ "\"");
    if ($pref::Video::borderless == 1)
        debug("(borderless mode enabled)");

    %deskRes    = getDesktopResolution();
    %deskResX   = getWord(%deskRes, $WORD::RES_X);
    %deskResY   = getWord(%deskRes, $WORD::RES_Y);
    %deskResBPP = getWord(%deskRes, 2);

    // We shouldn't be getting this any more but just in case...
    if (%bpp $= "Default")
        %bpp = %deskResBPP;

    // Make sure we are running at a valid resolution
    if (%fs $= "0" || %fs $= "false")
    {
        // Windowed mode has to use the same bit depth as the desktop
        %bpp = %deskResBPP;

        // Windowed mode also has to run at a smaller resolution than the desktop
        /*
        // commented out for Mutli monitor support
        if ((%resX > %deskResX) || (%resY > %deskResY))
        {
            warn("Warning: The requested windowed resolution is equal to or larger than the current desktop resolution. Attempting to find a better resolution");

            %resCount = Canvas.getModeCount();
            for (%i = (%resCount - 1); %i >= 0; %i--)
            {
                %testRes = Canvas.getMode(%i);
                %testResX = getWord(%testRes, $WORD::RES_X);
                %testResY = getWord(%testRes, $WORD::RES_Y);
                %testBPP  = getWord(%testRes, $WORD::BITDEPTH);

                if (%testBPP != %bpp)
                    continue;

                if ((%testResX < %deskResX) && (%testResY < %deskResY))
                {
                    // This will work as our new resolution
                    %resX = %testResX;
                    %resY = %testResY;

                    warn("Warning: Switching to \"" @ %resX SPC %resY SPC %bpp @ "\"");

                    break;
                }
            }
        }
        */
    }

    %newVideoMode = %resX SPC %resY SPC %fs SPC %bpp SPC %rate SPC %fsaa;

    if (%fs == 1 || %fs $= "true")
        %fsLabel = "Yes";
    else
        %fsLabel = "No";

    debug("Accepted Mode: " @ $pref::Video::mode);

    // Actually set the new video mode
    if( $pref::Video::mode !$= %newVideoMode )
        Canvas.setVideoMode(%resX, %resY, %fs, %bpp, %rate, %fsaa);

  $pref::Video::mode = %newVideoMode;

    // FXAA piggybacks on the FSAA setting in $pref::Video::mode.
    if ( isObject( FXAA_PostEffect ) )
        FXAA_PostEffect.isEnabled = ( %fsaa > 0 ) ? true : false;

    if ( $pref::Video::autoDetect )
        GraphicsQualityAutodetect();
}

function initializeCanvas()
{
    // Don't duplicate the canvas.
    if($canvasCreated)
    {
        error("Cannot instantiate more than one canvas!");
        return;
    }

    if (!createCanvas())
    {
        error("Canvas creation failed. Shutting down.");
        quit();
    }

    $canvasCreated = true;
}

//---------------------------------------------------------------------------------------------
// resetCanvas
// Forces the canvas to redraw itself.
//---------------------------------------------------------------------------------------------
function resetCanvas()
{
    if (isObject(Canvas))
        Canvas.repaint();
}

//---------------------------------------------------------------------------------------------
// Callbacks for window events.
//---------------------------------------------------------------------------------------------

function GuiCanvas::onLoseFocus(%this)
{
}

function GuiCanvas::onResize(%this, %width, %height)
{
    $pref::Video::canvasSize = %width SPC %height;
}

//---------------------------------------------------------------------------------------------
// Full screen handling
//---------------------------------------------------------------------------------------------

function GuiCanvas::attemptFullscreenToggle(%this)
{
    // If the Editor is running then we cannot enter full screen mode
    if ( EditorIsActive() && !%this.isFullscreen() )
    {
        MessageBoxOK(translate("engine.windowedModeReq.title", "Windowed Mode Required"), translate("engine.windowedModeReq.msgEditor", "Please exit the Mission Editor to switch to full screen."));
        return;
    }

    %this.toggleFullscreen();
}

//---------------------------------------------------------------------------------------------
// Editor Checking
// Needs to be outside of the tools directory so these work in non-tools builds
//---------------------------------------------------------------------------------------------

function EditorIsActive()
{
    return ( isObject(EditorGui) && Canvas.getContent() == EditorGui.getId() );
}
