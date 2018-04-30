// Set profile directory
$Pref::Video::ProfilePath = "core/profile";

new EventManager(MainEventManager){ queue = "MainEventManagerQueue"; };
MainEventManager.registerEvent("onExit");
MainEventManager.registerEvent("onStart");
MainEventManager.registerEvent("onPreStart");

function createCanvas(%windowTitle)
{
    if($forceFullscreen) {
        $pref::Video::displayOutputDevice = "";
    }

    %deskRes    = getDesktopVideoMode();
    %deskResX   = getWord(%deskRes, $WORD::RES_X);
    %deskResY   = getWord(%deskRes, $WORD::RES_Y);

    %deskResBPP = getWord(%deskRes, $WORD::BITDEPTH);
    %deskRefresh  = getWord(%deskRes, $WORD::REFRESH);

    $pref::Video::mode = %deskResX SPC %deskResY SPC "false" SPC %deskResBPP SPC %deskRefresh SPC "4";


    // Create the Canvas
    %foo = new GuiCanvas(Canvas)
    {
        displayWindow = false;
    };

    return true;
}

//------------------------------------------------------------------------------
// Process command line arguments
exec("core/parseArgs.cs");

// Parse the executable arguments with the standard
// function from core/main.cs
defaultParseArgs();

//-----------------------------------------------------------------------------
// The onStart, onExit and parseArgs function are overriden
// by mod packages to get hooked into initialization and cleanup.

function onStart()
{
    // Default startup function
}

function onExit()
{
    // OnExit is called directly from C++ code, whereas onStart is
    // invoked at the end of this file.

    LuaExecuteStringSync("onExit()");
    MainEventManager.postEvent("onExit");
}

function parseArgs()
{
    // Here for mod override, the arguments have already
    // been parsed.
}



//--------------------------------------------------------------------------

// custom beamng function, required for loading vehicles
function loadDirRec(%dir)
{
    %filefilter = %dir@"/*/materials.cs";
    for( %fileC = findFirstFile( %filefilter );
    %fileC !$= "";
    %fileC = findNextFile( %filefilter ))
    {
        //debug(" * loading materials script file: "@ %fileC);
        exec( %fileC );
    }
    //reInitMaterials();
}

function loadModScriptsRec(%dir)
{
    debug("Loading ModScripts on " @ %dir);
    %filefilter = %dir@"/*/modScript.cs";
    for( %fileC = findFirstFile( %filefilter ); %fileC !$= ""; %fileC = findNextFile( %filefilter )) {
        debug(" * loading mod script file: "@ %fileC);
        exec( %fileC );
    }
}

exec("scripts/main.cs");
exec("art/main.cs");

// make sure some important paths exist
if(!IsDirectory("settings/")) createPath( "settings/" );
//if(!IsDirectory("screenshots/")) createPath( "screenshots/" );

// Parse the command line arguments
//debug("--------- Parsing Arguments ---------");
parseArgs();

onPreStartCallback();

// Either display the help message or startup the app.
MainEventManager.postEvent("onPreStart");
onStart();
MainEventManager.postEvent("onStart");
//debug("Engine initialized...");

// As we know at this point that the initial load is complete,
// we can hide any splash screen we have, and show the canvas.
// This keeps things looking nice, instead of having a blank window
//Canvas.showWindow();

// Automatically start up the appropriate editor, if any
if ($startWorldEditor) {
    Canvas.setCursor("DefaultCursor");
    Canvas.setContent(EditorChooseLevelGui);
}

// custom beamng function, required for loading vehicles
function loadVehicleDir(%dir)
{
    //debug(" === BeamNG - loading all .cs files in vehicle folder:" @ %dir);
    loadDirRec(%dir);
    loadDirRec("vehicles/common");
    //debug(" === BeamNG - loading all .cs files in vehicle folder DONE");
}
