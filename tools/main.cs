
//---------------------------------------------------------------------------------------------
// Path to the folder that contains the editors we will load.
//---------------------------------------------------------------------------------------------
$Tools::resourcePath = "tools/";

// These must be loaded first, in this order, before anything else is loaded
$Tools::loadFirst = "editorClasses base worldEditor";

//---------------------------------------------------------------------------------------------
// Object that holds the simObject id that the materialEditor uses to interpret its material list
//---------------------------------------------------------------------------------------------
$Tools::materialEditorList = "";

//---------------------------------------------------------------------------------------------
// Tools Package.
//---------------------------------------------------------------------------------------------
package Tools
{
    function loadKeybindings()
    {
        Parent::loadKeybindings();


    }

    // Start-up.
    function onEditorStart()
    {
        // after level load all objects created are added to $instantGroup
        // and deleted at mission end. We disable it for level objetcs.
        // Need to be restored at the end of this funcion
        %instantGroupSaved = $instantGroup;
        $instantGroup = "";

        new Settings(EditorSettings) { file = "settings/editor.xml"; };
        EditorSettings.read();

        //debug( " % - Initializing Tools" );

        // Default file path when saving from the editor (such as prefabs)
        if ($Pref::WorldEditor::LastPath $= "")
        {
            $Pref::WorldEditor::LastPath = getMainDotCsDir();
        }

        // Common GUI stuff.
        exec( "./gui/cursors.ed.cs" );
        exec( "./gui/profiles.ed.cs" );
        exec( "./editorClasses/gui/panels/navPanelProfiles.ed.cs" );

        // Make sure we get editor profiles before any GUI's
        // BUG: these dialogs are needed earlier in the init sequence, and should be moved to
        // common, along with the guiProfiles they depend on.
        exec( "./gui/guiDialogs.ed.cs" );

        $ignoredDatablockSet = new SimSet();

        // fill the list of editors
        $editors[count] = getWordCount( $Tools::loadFirst );
        for ( %i = 0; %i < $editors[count]; %i++ )
        {
            $editors[%i] = getWord( $Tools::loadFirst, %i );
        }

        %pattern = $Tools::resourcePath @ "/*/main.cs";
        %folder = findFirstFile( %pattern );
        while ( %folder !$= "" )
        {
            if( filePath( %folder ) !$= "tools" ) // Skip the actual 'tools' folder...we want the children
            {
                %folder = filePath( %folder );
                %editor = fileName( %folder );
                if ( IsDirectory( %folder ) )
                {
                    // Yes, this sucks and should be done better
                    if ( strstr( $Tools::loadFirst, %editor ) == -1 )
                    {
                        $editors[$editors[count]] = %editor;
                        $editors[count]++;
                    }
                }
            }
            %folder = findNextFile( %pattern );
        }

        // initialize every editor
        new SimSet( EditorPluginSet );
        %count = $editors[count];
        for ( %i = 0; %i < %count; %i++ )
        {
            exec( "./" @ $editors[%i] @ "/main.cs" );

            %initializeFunction = "initialize" @ $editors[%i];
            if( isFunction( %initializeFunction ) )
                call( %initializeFunction );
        }

        // Popuplate the default SimObject icons that
        // are used by the various editors.
        EditorIconRegistry::loadFromPath( "tools/classIcons/" );

        // Load up the tools resources. All the editors are initialized at this point, so
        // resources can override, redefine, or add functionality.
        Tools::LoadResources( $Tools::resourcePath );

        // restore $instantGroup
        $instantGroup = %instantGroupSaved;
        
        // Setup and start autosave
        EWorldEditor.autoSave = EditorSettings.value("WorldEditor/autoSave");
        EWorldEditor.autoSaveInterval = EditorSettings.value("WorldEditor/autoSaveInterval");
        scheduleAutoSave();
    }

    function startToolTime(%tool)
    {
        if($toolDataToolCount $= "")
            $toolDataToolCount = 0;

        if($toolDataToolEntry[%tool] !$= "true")
        {
            $toolDataToolEntry[%tool] = "true";
            $toolDataToolList[$toolDataToolCount] = %tool;
            $toolDataToolCount++;
            $toolDataClickCount[%tool] = 0;
        }

        $toolDataStartTime[%tool] = getSimTime();
        $toolDataClickCount[%tool]++;
    }

    function endToolTime(%tool)
    {
        %startTime = 0;

        if($toolDataStartTime[%tool] !$= "")
            %startTime = $toolDataStartTime[%tool];

        if($toolDataTotalTime[%tool] $= "")
            $toolDataTotalTime[%tool] = 0;

        $toolDataTotalTime[%tool] += getSimTime() - %startTime;
    }

    function dumpToolData()
    {
        %count = $toolDataToolCount;
        for(%i=0; %i<%count; %i++)
        {
            %tool = $toolDataToolList[%i];
            %totalTime = $toolDataTotalTime[%tool];
            if(%totalTime $= "")
                %totalTime = 0;
            %clickCount = $toolDataClickCount[%tool];
            debug("---");
            debug("Tool: " @ %tool);
            debug("Time (seconds): " @ %totalTime / 1000);
            debug("Activated: " @ %clickCount);
            debug("---");
        }
    }

    // Shutdown.
    function onExit()
    {
        if( EditorGui.isInitialized )
            EditorGui.shutdown();

        // Free all the icon images in the registry.
        EditorIconRegistry::clear();

        // Save any Layouts we might be using
        //GuiFormManager::SaveLayout(LevelBuilder, Default, User);

        %count = $editors[count];
        for (%i = 0; %i < %count; %i++)
        {
            %destroyFunction = "destroy" @ $editors[%i];
            if( isFunction( %destroyFunction ) )
                call( %destroyFunction );
        }

        // Call Parent.
        Parent::onExit();

        // write out our settings xml file
        EditorSettings.write();
    }
};

function Tools::LoadResources( %path )
{
    %resourcesPath = %path @ "resources/";
    %resourcesList = getDirectoryList( %resourcesPath );

    %wordCount = getFieldCount( %resourcesList );
    for( %i = 0; %i < %wordCount; %i++ )
    {
        %resource = GetField( %resourcesList, %i );
        if( isFile( %resourcesPath @ %resource @ "/resourceDatabase.cs") )
            ResourceObject::load( %path, %resource );
    }
}

function Prefab::getToolIcon(%this)
{
    return %this.isLoaded() ? "prefab_loaded" : "prefab_unloaded";
}

function SimGroup::getToolIcon(%this)
{
    if(%this.unpacked_prefab $= "1")
    {
        return "prefab_unpacked";
    }
    return "";
}

function onEditorGetObjectIcon(%obj)
{
    // this function enables the user to have icons depending on the state of a simObject
    if( isObject(%obj) && %obj.isMethod( "getToolIcon" ) )
    {
        return %obj.getToolIcon();
    }
    return "";
}

// central level saving function
function saveMission(%missionFile, %onlySelected)
{
    //clean main folder for avoid dead simgroup items.level.json files
    %path = getMissionPath() @ "/main/*.*";
    for( %file = findFirstFile( %path ); %file !$= ""; %file = findNextFile( %path )) {
        fileDelete( %file );
    }

    LuaExecuteStringSync("Sim.serializeObjectToDirectories('MissionGroup','" @ getMissionPath() @ "/main/')");
    //MissionGroup.save( %missionFile, %onlySelected );
}
//-----------------------------------------------------------------------------
// Activate Package.
//-----------------------------------------------------------------------------
activatePackage(Tools);
