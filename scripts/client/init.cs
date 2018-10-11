
//-----------------------------------------------------------------------------
// Variables used by client scripts & code.  The ones marked with (c)
// are accessed from code.  Variables preceeded by Pref:: are client
// preferences and stored automatically in the ~/client/prefs.cs file
// in between sessions.
//
//    (c) Client::MissionFile             Mission file name
//    ( ) Client::Password                Password for server join
//    (c) pref::Master[n]                 List of master servers
//    (c) pref::Net::RegionMask
//    (c) pref::Client::ServerFavoriteCount
//    (c) pref::Client::ServerFavorite[FavoriteCount]
//    .. Many more prefs... need to finish this off

// Moves, not finished with this either...
//    $mv*Action...

//-----------------------------------------------------------------------------
// These are variables used to control the shell scripts and
// can be overriden by mods:
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
function initClient()
{
    //debug("--------- Initializing: Client Scripts ---------");

    // Game information used to query the master server
    $Client::MissionTypeQuery = "Any";

    // These should be game specific GuiProfiles.  Custom profiles are saved out
    // from the Gui Editor.  Either of these may override any that already exist.
    exec("art/gui/gameProfiles.cs");
    exec("art/gui/customProfiles.cs");

    // The common module provides basic client functionality
    initBaseClient();

    exec("art/gui/OnlyGui.gui");
    exec("art/gui/optionsDlg.gui");
    exec("scripts/gui/optionsDlg.cs");
    exec("./optionsHelper.cs");

    // Default player key bindings
    exec("./default.bind.cs");
    exec("./beamng.cs");
    exec("./beamng_cef.cs");


    // Use our prefs to configure our Canvas/Window
    configureCanvas();

    //if (isFile("./config.cs"))
    //   exec("./config.cs");

    // BEAMNG: DO NOT LOAD MATERIALS globally anymore
    //loadMaterials();

    exec("core/art/datablocks/datablockExec.cs");
    loadDirRec("core/art/");
    loadDirRec("art/");

    if( isFile( expandFilename("./audioData.cs") ) )
        exec( "./audioData.cs" );

    // Start up the main menu... this is separated out into a
    // method for easier mod override.

    if ($startWorldEditor) {
        // Editor GUI's will start up in the primary main.cs once
        // engine is initialized.
        return;
    }

    // Otherwise go to the splash screen.
    Canvas.setCursor("DefaultCursor");
    //loadStartup();
    // BEAMNG: load the menu directly
    loadMainMenu();
}


//-----------------------------------------------------------------------------

function loadMainMenu()
{
    // Startup the client with the Main menu...
    if (isObject( OnlyGui ))
        Canvas.setContent( OnlyGui );

    Canvas.setCursor("DefaultCursor");
}
