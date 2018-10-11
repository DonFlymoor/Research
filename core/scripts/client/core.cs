
//---------------------------------------------------------------------------------------------
// initializeCore
// Initializes core game functionality.
//---------------------------------------------------------------------------------------------
function initializeCore()
{
    // Not Reentrant
    if( $coreInitialized == true )
        return;

    // Very basic functions used by everyone.
    exec("./audio.cs");
    exec("./canvas.cs");
    exec("./cursor.cs");
    exec("./persistenceManagerTest.cs");

    // Content.
    exec("~/art/gui/profiles.cs");
    exec("~/scripts/gui/cursors.cs");

    exec( "./audioEnvironments.cs" );
    exec( "./audioDescriptions.cs" );
    //exec( "./audioStates.cs" );
    exec( "./audioAmbiences.cs" );

    // Seed the random number generator.
    setRandomSeed();

    // Initialize the canvas.
    initializeCanvas();

    // Core Guis.
    exec("~/art/gui/console.gui");
    exec("~/art/gui/consoleVarDlg.gui");

    // Gui Helper Scripts.
    exec("~/scripts/gui/help.cs");

    // Random Scripts.
    exec("~/scripts/client/screenshot.cs");
    //exec("~/scripts/client/keybindings.cs");
    exec("~/scripts/client/helperfuncs.cs");

    // Client scripts
    exec("~/scripts/client/metrics.cs");

    // Materials and Shaders for rendering various object types
    loadCoreMaterials();

    exec("~/scripts/client/commonMaterialData.cs");
    exec("~/scripts/client/shaders.cs");
    exec("~/scripts/client/materials.cs");
    exec("~/scripts/client/terrainBlock.cs");
    exec("~/scripts/client/water.cs");
    exec("~/scripts/client/scatterSky.cs");
    exec("~/scripts/client/clouds.cs");

    // Set a default cursor.
    Canvas.setCursor(DefaultCursor);

    loadKeybindings();

    $coreInitialized = true;
}

//---------------------------------------------------------------------------------------------
// shutdownCore
// Shuts down core game functionality.
//---------------------------------------------------------------------------------------------
function shutdownCore()
{
    sfxShutdown();
}

//---------------------------------------------------------------------------------------------
// dumpKeybindings
// Saves of all keybindings.
//---------------------------------------------------------------------------------------------
function dumpKeybindings()
{
    // Loop through all the binds.
    for (%i = 0; %i < $keybindCount; %i++)
    {
        // If we haven't dealt with this map yet...
        if (isObject($keybindMap[%i]))
        {
            // Save and delete.
            $keybindMap[%i].save(getPrefsPath("bind.cs"), %i == 0 ? false : true);
            $keybindMap[%i].delete();
        }
    }
}

function handleEscape()
{

    if (isObject(EditorGui))
    {
        if (Canvas.getContent() == EditorGui.getId())
        {
            EditorGui.handleEscape();
            return;
        }
        else if ( EditorIsDirty() )
        {
            MessageBoxYesNoCancel( translate("engine.levelModified.title", "Level Modified"), translate("engine.levelModified.msg", "Level has been modified in the Editor. Save?"),
                                    "EditorDoExitMission(1);",
                                    "EditorDoExitMission();",
                                    "");
            return;
        }
    }

    //if (OnlyGui.isAwake())
    //   escapeFromGame();
}

//-----------------------------------------------------------------------------
// loadMaterials - load all materials.cs files
//-----------------------------------------------------------------------------
function loadCoreMaterials()
{
    // Load all source material files.

    for( %file = findFirstFile( "core/materials.cs" );
        %file !$= "";
        %file = findNextFile( "core/materials.cs" ))
    {
        exec( %file );
    }
}

function reloadCoreMaterials()
{
    reloadTextures();
    loadCoreMaterials();
    reInitMaterials();
}

//-----------------------------------------------------------------------------
// loadMaterials - load all materials.cs files
//-----------------------------------------------------------------------------
function loadMaterials()
{
    // Load all source material files.

    for( %file = findFirstFile( "*/materials.cs" );
        %file !$= "";
        %file = findNextFile( "*/materials.cs" ))
    {
        exec( %file );
    }

    // Load all materials created by the material editor if
    // the folder exists
    if( IsDirectory( "materialEditor" ) )
    {
        for( %file = findFirstFile( "materialEditor/*.cs" );
           %file !$= "";
           %file = findNextFile( "materialEditor/*.cs" ))
        {
            exec( %file );
        }
    }
}

function reloadMaterials()
{
    reloadTextures();
    loadMaterials();
    reInitMaterials();
}

singleton ShaderData( CorePassthruShaderVP )
{
    DXVertexShaderFile     = "shaders/common/postFx/passthruV.hlsl";
    DXPixelShaderFile     = "shaders/common/postFx/passthruP.hlsl";

//   OGLVertexShaderFile  = "shaders/common/postFx/gl/passthruV.glsl";
//   OGLPixelShaderFile   = "shaders/common/postFx/gl/passthruP.glsl";

    samplerNames[0] = "$inputTex";

    pixVersion = 2.0;
};
