
// Load up core script base
exec("core/main.cs"); // Should be loaded at a higher level, but for now leave -- SRZ 11/29/07

//-----------------------------------------------------------------------------
// Package overrides to initialize the mod.
package fps {

function onStart()
{
    $pref::Directories::Terrain = "levels/";

    // Load preferences
    exec( "settings/game-settings-default.cs" );
    if ( isFile("settings/game-settings.cs") ) exec( "settings/game-settings.cs" );

    Parent::onStart();
    //debug("--------- Initializing Directory: scripts ---------");

    // Load the scripts that start it all...
    exec("./client/init.cs");

    // Init the physics plugin.
    physicsInit();

    // Start up the audio system.
    if( !sfxInit() ) error("Couldn't initialize sfx");

    // Specify where the mission files are.
    $Server::MissionFileSpec = "levels/*.mis";

    // The common module provides the basic server functionality
    LuaExecuteQueueString("server.initBaseServer()");

    initClient();
}

function saveGlobalOptions()
{
    //debug("Exporting client prefs");
    createPath( "settings" );
    export("$pref::*", "settings/game-settings.cs", False);
}

function onExit()
{
    // Ensure that we are disconnected and/or the server is destroyed.
    // This prevents crashes due to the SceneGraph being deleted before
    // the objects it contains.
    LuaExecuteStringSync("serverConnection.noLoadingScreenDisconnect()");

    // Destroy the physics plugin.
    physicsDestroy();

    debug("Exporting settings");
    createPath( "settings" );
    export("$pref::*", "settings/game-settings.cs", False);

    Parent::onExit();
}

}; // package fps

// Activate the game package.
activatePackage(fps);
