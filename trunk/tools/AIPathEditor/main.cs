
function initializeAIPathEditor()
{
    //debug( " - Initializing AIPath and Path Editor" );

    exec( "./AIPathEditor.cs" );
    exec( "./AIPathEditorGui.gui" );
    exec( "./AIPathEditorToolbar.gui");
    exec( "./AIPathEditorGui.cs" );

    // Add ourselves to EditorGui, where all the other tools reside
    AIPathEditorGui.setVisible( false );
    AIPathEditorToolbar.setVisible( false );
    AIPathEditorOptionsWindow.setVisible( false );
    AIPathEditorTreeWindow.setVisible( false );

    EditorGui.add( AIPathEditorGui );
    EditorGui.add( AIPathEditorToolbar );
    EditorGui.add( AIPathEditorOptionsWindow );
    EditorGui.add( AIPathEditorTreeWindow );

    new ScriptObject( AIPathEditorPlugin )
    {
        superClass = "EditorPlugin";
        editorGui = AIPathEditorGui;
    };

    %map = new ActionMap();
    %map.bindCmd( keyboard, "backspace", "AIPathEditorGui.onDeleteKey();", "" );
    %map.bindCmd( keyboard, "1", "AIPathEditorGui.prepSelectionMode();", "" );
    %map.bindCmd( keyboard, "2", "ToolsPaletteArray->AIPathEditorMoveMode.performClick();", "" );
    %map.bindCmd( keyboard, "4", "ToolsPaletteArray->AIPathEditorScaleMode.performClick();", "" );
    %map.bindCmd( keyboard, "5", "ToolsPaletteArray->AIPathEditorAddAIPathMode.performClick();", "" );
    %map.bindCmd( keyboard, "=", "ToolsPaletteArray->AIPathEditorInsertPointMode.performClick();", "" );
    %map.bindCmd( keyboard, "numpadadd", "ToolsPaletteArray->AIPathEditorInsertPointMode.performClick();", "" );
    %map.bindCmd( keyboard, "-", "ToolsPaletteArray->AIPathEditorRemovePointMode.performClick();", "" );
    %map.bindCmd( keyboard, "numpadminus", "ToolsPaletteArray->AIPathEditorRemovePointMode.performClick();", "" );
    %map.bindCmd( keyboard, "z", "AIPathEditorShowSplineBtn.performClick();", "" );
    %map.bindCmd( keyboard, "x", "AIPathEditorWireframeBtn.performClick();", "" );
    %map.bindCmd( keyboard, "v", "AIPathEditorShowAIPathBtn.performClick();", "" );
    AIPathEditorPlugin.map = %map;

    AIPathEditorPlugin.initSettings();
}

function destroyAIPathEditor()
{
}

function AIPathEditorPlugin::onWorldEditorStartup( %this )
{
    // Add ourselves to the window menu.
    %accel = EditorGui.addToEditorsMenu( "AIPath and Path Editor", "", AIPathEditorPlugin );

    // Add ourselves to the ToolsToolbar
    %tooltip = "AIPath Editor (" @ %accel @ ")";
    EditorGui.addToToolsToolbar( "AIPathEditorPlugin", "AIPathEditorPalette", expandFilename("tools/worldEditor/images/toolbar/ai-path-editor"), %tooltip );

    //connect editor windows
    GuiWindowCtrl::attach( AIPathEditorOptionsWindow, AIPathEditorTreeWindow);

    // Add ourselves to the Editor Settings window
    exec( "./AIPathEditorSettingsTab.gui" );
    ESettingsWindow.addTabPage( EAIPathEditorSettingsPage );
}

function AIPathEditorPlugin::onActivated( %this )
{
    %this.readSettings();

    ToolsPaletteArray->AIPathEditorAddAIPathMode.performClick();
    EditorGui.bringToFront( AIPathEditorGui );

    AIPathEditorGui.setVisible( true );
    AIPathEditorGui.makeFirstResponder( true );
    AIPathEditorToolbar.setVisible( true );

    AIPathEditorOptionsWindow.setVisible( true );
    AIPathEditorTreeWindow.setVisible( true );

    AIPathTreeView.open(ServerAIPathSet,true);

    %this.map.push();

    // Set the status bar here until all tool have been hooked up
    EditorGuiStatusBar.setInfo("AIPath editor.");
    EditorGuiStatusBar.setSelection("");

    LuaExecuteQueueString("extensions.load('util_decalRoadsEditor')");

    Parent::onActivated(%this);
}

function AIPathEditorPlugin::onDeactivated( %this )
{
    %this.writeSettings();

    AIPathEditorGui.setVisible( false );
    AIPathEditorToolbar.setVisible( false );
    AIPathEditorOptionsWindow.setVisible( false );
    AIPathEditorTreeWindow.setVisible( false );
    %this.map.pop();

    LuaExecuteQueueString("extensions.unload('util_decalRoadsEditor')");

    Parent::onDeactivated(%this);
}

function AIPathEditorPlugin::onEditMenuSelect( %this, %editMenu )
{
    %hasSelection = false;

    if( isObject( AIPathEditorGui.aip ) )
        %hasSelection = true;

    %editMenu.enableItem( 3, false ); // Cut
    %editMenu.enableItem( 4, false ); // Copy
    %editMenu.enableItem( 5, false ); // Paste
    %editMenu.enableItem( 6, %hasSelection ); // Delete
    %editMenu.enableItem( 8, false ); // Deselect
}

function AIPathEditorPlugin::handleDelete( %this )
{
    AIPathEditorGui.onDeleteKey();
}

function AIPathEditorPlugin::handleEscape( %this )
{
    return AIPathEditorGui.onEscapePressed();
}

function AIPathEditorPlugin::isDirty( %this )
{
    return AIPathEditorGui.isDirty;
}

function AIPathEditorPlugin::onSaveMission( %this, %missionFile )
{
    if( AIPathEditorGui.isDirty )
    {
        saveMission(%missionFile, false);
        AIPathEditorGui.isDirty = false;
    }
}

function AIPathEditorPlugin::setEditorFunction( %this )
{
    %terrainExists = parseMissionGroup( "TerrainBlock" );

    if( %terrainExists == false )
        MessageBoxYesNoCancel("No Terrain","Would you like to create a New Terrain?", "Canvas.pushDialog(CreateNewTerrainGui);");

    return %terrainExists;
}

//-----------------------------------------------------------------------------
// Settings
//-----------------------------------------------------------------------------

function AIPathEditorPlugin::initSettings( %this )
{
    EditorSettings.beginGroup( "AIPathEditor", true );

    EditorSettings.setDefaultValue(  "DefaultWidth",         "10" );
    EditorSettings.setDefaultValue(  "HoverSplineColor",     "255 0 0 255" );
    EditorSettings.setDefaultValue(  "SelectedSplineColor",  "0 255 0 255" );
    EditorSettings.setDefaultValue(  "HoverNodeColor",       "255 255 255 255" ); //<-- Not currently used
    EditorSettings.setDefaultValue(  "MaterialName",         "DefaultAIPathMaterial" );

    EditorSettings.endGroup();
}

function AIPathEditorPlugin::readSettings( %this )
{
    EditorSettings.beginGroup( "AIPathEditor", true );

    AIPathEditorGui.DefaultWidth         = EditorSettings.value("DefaultWidth");
    AIPathEditorGui.HoverSplineColor     = EditorSettings.value("HoverSplineColor");
    AIPathEditorGui.SelectedSplineColor  = EditorSettings.value("SelectedSplineColor");
    AIPathEditorGui.HoverNodeColor       = EditorSettings.value("HoverNodeColor");
    AIPathEditorGui.materialName         = EditorSettings.value("MaterialName");

    EditorSettings.endGroup();
}

function AIPathEditorPlugin::writeSettings( %this )
{
    EditorSettings.beginGroup( "AIPathEditor", true );

    EditorSettings.setValue( "DefaultWidth",           AIPathEditorGui.DefaultWidth );
    EditorSettings.setValue( "HoverSplineColor",       AIPathEditorGui.HoverSplineColor );
    EditorSettings.setValue( "SelectedSplineColor",    AIPathEditorGui.SelectedSplineColor );
    EditorSettings.setValue( "HoverNodeColor",         AIPathEditorGui.HoverNodeColor );
    EditorSettings.setValue( "MaterialName",           AIPathEditorGui.materialName );

    EditorSettings.endGroup();
}
