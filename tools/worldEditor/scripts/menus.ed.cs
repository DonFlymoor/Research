
function EditorGui::buildMenus(%this)
{
    if(isObject(%this.menuBar))
        return;

    //set up %cmdctrl variable so that it matches OS standards
    if( $platform $= "macos" )
    {
        %cmdCtrl = "Cmd";
        %menuCmdCtrl = "Cmd";
        %quitShortcut = "Cmd Q";
        %redoShortcut = "Cmd-Shift Z";
    }
    else
    {
        %cmdCtrl = "Ctrl";
        %menuCmdCtrl = "Alt";
        %quitShortcut = "Alt F4";
        %redoShortcut = "Ctrl Y";
    }

    // Sub menus (temporary, until MenuBuilder gets updated)
        // The speed increments located here are overwritten in EditorCameraSpeedMenu::setupDefaultState.
        // The new min/max for the editor camera speed range can be set in each level's levelInfo object.
    %this.cameraSpeedMenu = new PopupMenu(EditorCameraSpeedOptions)
    {
        superClass = "MenuBuilder";
        class = "EditorCameraSpeedMenu";

        item[0] = translate("engine.editor.menu.cameraspeed.slowest", "Slowest") TAB %cmdCtrl @ "-Shift 1" TAB "5";
        item[1] = translate("engine.editor.menu.cameraspeed.slow", "Slow") TAB %cmdCtrl @ "-Shift 2" TAB "35";
        item[2] = translate("engine.editor.menu.cameraspeed.slower", "Slower") TAB %cmdCtrl @ "-Shift 3" TAB "70";
        item[3] = translate("engine.editor.menu.cameraspeed.normal", "Normal") TAB %cmdCtrl @ "-Shift 4" TAB "100";
        item[4] = translate("engine.editor.menu.cameraspeed.faster", "Faster") TAB %cmdCtrl @ "-Shift 5" TAB "130";
        item[5] = translate("engine.editor.menu.cameraspeed.fast", "Fast") TAB %cmdCtrl @ "-Shift 6" TAB "165";
        item[6] = translate("engine.editor.menu.cameraspeed.fastest", "Fastest") TAB %cmdCtrl @ "-Shift 7" TAB "200";
    };
    %this.freeCameraTypeMenu = new PopupMenu(EditorFreeCameraTypeOptions)
    {
        superClass = "MenuBuilder";
        class = "EditorFreeCameraTypeMenu";

        item[0] = translate("engine.editor.menu.gameCamera", "Standard") TAB "Ctrl 1" TAB "EditorGuiStatusBar.setCamera(\"Game Camera\");";
        item[1] = translate("engine.editor.menu.standartCamera", "Standard") TAB "Ctrl 2" TAB "EditorGuiStatusBar.setCamera(\"Standard Camera\");";
        item[2] = translate("engine.editor.menu.orbitCamera", "Orbit Camera") TAB "Ctrl 3" TAB "EditorGuiStatusBar.setCamera(\"Orbit Camera\");";
        Item[3] = "-";
        item[4] = translate("engine.editor.menu.smoothedCamera", "Smoothed") TAB "" TAB "EditorGuiStatusBar.setCamera(\"Smooth Camera\");";
        item[5] = translate("engine.editor.menu.smoothedRotateCamera", "Smoothed Rotate") TAB "" TAB "EditorGuiStatusBar.setCamera(\"Smooth Rot Camera\");";
    };
    %this.cameraBookmarksMenu = new PopupMenu(EditorCameraBookmarks)
    {
        superClass = "MenuBuilder";
        class = "EditorCameraBookmarksMenu";

        //item[0] = "None";
    };
    %this.viewTypeMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";

        item[ 0 ] = translate("engine.editor.menu.camera.top", "Top") TAB "Alt 2" TAB "EditorGuiStatusBar.setCamera(\"Top View\");";
        item[ 1 ] = translate("engine.editor.menu.camera.bottom", "Bottom") TAB "Alt 5" TAB "EditorGuiStatusBar.setCamera(\"Bottom View\");";
        item[ 2 ] = translate("engine.editor.menu.camera.front", "Front") TAB "Alt 3" TAB "EditorGuiStatusBar.setCamera(\"Front View\");";
        item[ 3 ] = translate("engine.editor.menu.camera.back", "Back") TAB "Alt 6" TAB "EditorGuiStatusBar.setCamera(\"Back View\");";
        item[ 4 ] = translate("engine.editor.menu.camera.left", "Left") TAB "Alt 4" TAB "EditorGuiStatusBar.setCamera(\"Left View\");";
        item[ 5 ] = translate("engine.editor.menu.camera.right", "Right") TAB "Alt 7" TAB "EditorGuiStatusBar.setCamera(\"Right View\");";
        item[ 6 ] = translate("engine.editor.menu.camera.perspective", "Perspective") TAB "Alt 1" TAB "EditorGuiStatusBar.setCamera(\"Standard Camera\");";
        item[ 7 ] = translate("engine.editor.menu.camera.isometric", "Isometric") TAB "Alt 8" TAB "EditorGuiStatusBar.setCamera(\"Isometric View\");";
    };

    // Menu bar
    %this.menuBar = new MenuBar()
    {
        dynamicItemInsertPos = 3;
    };

    // File Menu
    %fileMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorFileMenu";

        barTitle = translate("engine.editor.menu.file", "File");
    };

    %fileMenu.appendItem( translate("engine.editor.menu.newLevel", "New Level") TAB "" TAB "schedule( 1, 0, \"EditorNewLevel\" );");
    %fileMenu.appendItem( translate("engine.editor.menu.openLevel", "Open Level...") TAB %cmdCtrl SPC "O" TAB "schedule( 1, 0, \"EditorOpenMission\" );");
    %fileMenu.appendItem( translate("engine.editor.menu.saveLevel", "Save Level") TAB %cmdCtrl SPC "S" TAB "EditorSaveMissionMenu(false);");
    %fileMenu.appendItem( translate("engine.editor.menu.saveLevelAs", "Save Level As...") TAB "" TAB "EditorSaveMissionAs();");
    %fileMenu.appendItem( translate("engine.editor.menu.resaveLevel", "Resave everything") TAB "" TAB "EditorSaveMissionMenu(true);");
    %fileMenu.appendItem("-");

    //if( $platform $= "windows" )
    //{
    //   %fileMenu.appendItem( "Open Project in Torsion" TAB "" TAB "EditorOpenTorsionProject();" );
    //   %fileMenu.appendItem( "Open Level File in Torsion" TAB "" TAB "EditorOpenFileInTorsion();" );
    //   %fileMenu.appendItem( "-" );
    //}

    %fileMenu.appendItem( translate("engine.editor.menu.createBlankTerrain", "Create Blank Terrain") TAB "" TAB "Canvas.pushDialog( CreateNewTerrainGui );");
    %fileMenu.appendItem( translate("engine.editor.menu.importTerrainHeightmap", "Import Terrain Heightmap") TAB "" TAB "Canvas.pushDialog( TerrainImportGui );");

    %fileMenu.appendItem( translate("engine.editor.menu.exportTerrainHeightmap", "Export Terrain Heightmap") TAB "" TAB "Canvas.pushDialog( TerrainExportGui );");
    %fileMenu.appendItem("-");
    %fileMenu.appendItem( translate("engine.editor.menu.exportToCollada", "Export To COLLADA...") TAB "" TAB "EditorExportToCollada();");
    //item[5] = "Import Terraform Data..." TAB "" TAB "Heightfield::import();";
    //item[6] = "Import Texture Data..." TAB "" TAB "Texture::import();";
    //item[7] = "-";
    //item[8] = "Export Terraform Data..." TAB "" TAB "Heightfield::saveBitmap(\"\");";

    %fileMenu.appendItem("-");
    %fileMenu.appendItem( translate("engine.editor.menu.playLevel", "Play Level") TAB "F11" TAB "askToSaveMissionOnExit();");

    %fileMenu.appendItem( translate("engine.editor.menu.exitLevel", "Exit Level") TAB "" TAB "EditorExitMission();");
    %fileMenu.appendItem( translate("engine.editor.menu.quit", "Quit") TAB %quitShortcut TAB "EditorQuitGame();");
    %this.menuBar.insert(%fileMenu, %this.menuBar.getCount());

    // Edit Menu
    %editMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorEditMenu";
        internalName = "EditMenu";

        barTitle = translate("engine.editor.menu.edit", "Edit");

        item[0] = translate("engine.editor.menu.undo", "Undo") TAB %cmdCtrl SPC "Z" TAB "Editor.getUndoManager().undo();";
        item[1] = translate("engine.editor.menu.redo", "Redo") TAB %redoShortcut TAB "Editor.getUndoManager().redo();";
        item[2] = "-";
        item[3] = translate("engine.editor.menu.cut", "Cut") TAB %cmdCtrl SPC "X" TAB "EditorMenuEditCut();";
        item[4] = translate("engine.editor.menu.copy", "Copy") TAB %cmdCtrl SPC "C" TAB "EditorMenuEditCopy();";
        item[5] = translate("engine.editor.menu.paste", "Paste") TAB %cmdCtrl SPC "V" TAB "EditorMenuEditPaste();";
        item[6] = translate("engine.editor.menu.delete", "Delete") TAB "Delete" TAB "EditorMenuEditDelete();";
        item[7] = "-";
        item[8] = translate("engine.editor.menu.deselect", "Deselect") TAB "X" TAB "EditorMenuEditDeselect();";
        Item[9] = translate("engine.editor.menu.select", "Select...") TAB "" TAB "EditorGui.toggleObjectSelectionsWindow();";
        item[10] = "-";
        item[11] = translate("engine.editor.menu.audioParams", "Audio Parameters...") TAB "" TAB "EditorGui.toggleSFXParametersWindow();";
        item[12] = translate("engine.editor.menu.editorSettings", "Editor Settings...") TAB "" TAB "ESettingsWindow.ToggleVisibility();";
        item[13] = translate("engine.editor.menu.snapOptions", "Snap Options...") TAB "" TAB "ESnapOptions.ToggleVisibility();";
        item[14] = "-";
        item[15] = "Complete Scenetree" TAB "" TAB "tree();";
        item[16] = translate("engine.editor.menu.gameOptions", "Game Options...") TAB "" TAB "Canvas.pushDialog(optionsDlg);";
        item[17] = translate("engine.editor.menu.postfxManager", "PostEffect Manager") TAB "" TAB "Canvas.pushDialog(PostFXManager);";
    };
    %this.menuBar.insert(%editMenu, %this.menuBar.getCount());

    // View Menu
    %viewMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorViewMenu";
        internalName = "viewMenu";

        barTitle = translate("engine.editor.menu.view", "View");

        item[ 0 ] = translate("engine.editor.menu.visibilityLayers", "Visibility Layers") TAB "Alt V" TAB "VisibilityDropdownToggle();";
        item[ 1 ] = translate("engine.editor.menu.gridOrtho", "Show Grid in Ortho Views") TAB %cmdCtrl @ "-Shift-Alt G" TAB "EditorGui.toggleOrthoGrid();";
    };
    %this.menuBar.insert(%viewMenu, %this.menuBar.getCount());

    // Camera Menu
    %cameraMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorCameraMenu";

        barTitle = translate("engine.editor.menu.camera", "Camera");

        item[0] = translate("engine.editor.menu.worldCamera", "Camera") TAB %this.freeCameraTypeMenu;
        item[1] = "-";
        Item[2] = translate("engine.editor.menu.toggleCamera", "Toggle Flying Camera") TAB "Shift C" TAB "LuaExecuteStringSync('commands.toggleCamera()');";
        item[3] = translate("engine.editor.menu.placeCameraSelection", "Place Camera at Selection") TAB "Ctrl Q" TAB "EWorldEditor.dropCameraToSelection();";
        item[4] = translate("engine.editor.menu.placeCameraPlayer", "Place Camera at Player") TAB "Alt Q" TAB "LuaExecuteStringSync('commands.dropCameraAtPlayer()');";
        item[5] = translate("engine.editor.menu.placePlayerCamera", "Place Player at Camera") TAB "Alt W" TAB "LuaExecuteStringSync('commands.dropPlayerAtCamera()');";
        item[6] = translate("engine.editor.menu.cameraTranslation", "Camera translation") TAB "" TAB "Canvas.pushDialog(\"CameraTranslationDlg\");";
        item[7] = "-";
        item[8] = translate("engine.editor.menu.fitViewSelection", "Fit View to Selection") TAB "F" TAB "EditorCameraAutoFit(EditorGui.currentEditor.editorGui.getSelectionRadius()+1);";
        item[9] = translate("engine.editor.menu.fitViewSelectionOrbit", "Fit View To Selection and Orbit") TAB "Alt F" TAB "EditorGuiStatusBar.setCamera(\"Orbit Camera\"); EditorCameraAutoFit(EditorGui.currentEditor.editorGui.getSelectionRadius()+1);";
        item[10] = "-";
        item[11] = translate("engine.editor.menu.speed", "Speed") TAB %this.cameraSpeedMenu;
        item[12] = translate("engine.editor.menu.viewType", "View") TAB %this.viewTypeMenu;
        item[13] = "-";
        Item[14] = translate("engine.editor.menu.addBookmark", "Add Bookmark...") TAB "Ctrl B" TAB "EditorGui.addCameraBookmarkByGui();";
        Item[15] = translate("engine.editor.menu.manageBookmarks", "Manage Bookmarks...") TAB "Ctrl-Shift B" TAB "EditorGui.toggleCameraBookmarkWindow();";
        item[16] = translate("engine.editor.menu.jumpBookmark", "Jump to Bookmark") TAB %this.cameraBookmarksMenu;
    };
    %this.menuBar.insert(%cameraMenu, %this.menuBar.getCount());

    // Editors Menu
    %editorsMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorToolsMenu";

        barTitle = translate("engine.editor.menu.editors", "Editors");

            //item[0] = "Object Editor" TAB "F1" TAB WorldEditorInspectorPlugin;
            //item[1] = "Material Editor" TAB "F2" TAB MaterialEditorPlugin;
            //item[2] = "-";
            //item[3] = "Terrain Editor" TAB "F3" TAB TerrainEditorPlugin;
            //item[4] = "Terrain Painter" TAB "F4" TAB TerrainPainterPlugin;
            //item[5] = "-";
    };
    %this.menuBar.insert(%editorsMenu, %this.menuBar.getCount());

    // Lighting Menu
    %lightingMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorLightingMenu";

        barTitle = translate("engine.editor.menu.lighting", "Lighting");

        //item[0] = "Full Relight" TAB "Alt L" TAB "Editor.lightScene(\"\", forceAlways);";
        //item[1] = "Toggle ShadowViz" TAB "" TAB "toggleShadowViz();";
        //item[2] = "-";

            // NOTE: The light managers will be inserted as the
            // last menu items in EditorLightingMenu::onAdd().
    };
    %this.menuBar.insert(%lightingMenu, %this.menuBar.getCount());

    // Help Menu
    /*
    %helpMenu = new PopupMenu()
    {
        superClass = "MenuBuilder";
        class = "EditorHelpMenu";

        barTitle = "Help";

        item[0] = "Online Documentation..." TAB "Alt F1" TAB "gotoWebPage(EWorldEditor.documentationURL);";
        item[1] = "Offline User Guide..." TAB "" TAB "gotoWebPage(EWorldEditor.documentationLocal);";
        item[2] = "Offline Reference Guide..." TAB "" TAB "shellexecute(EWorldEditor.documentationReference);";
        item[3] = "Forums..." TAB "" TAB "gotoWebPage(EWorldEditor.forumURL);";
    };
    %this.menuBar.insert(%helpMenu, %this.menuBar.getCount());
    */

    // Menus that are added/removed dynamically (temporary)

    // World Menu
    if(! isObject(%this.worldMenu))
    {
        %this.dropTypeMenu = new PopupMenu()
        {
            superClass = "MenuBuilder";
            class = "EditorDropTypeMenu";

            // The onSelectItem() callback for this menu re-purposes the command field
            // as the MenuBuilder version is not used.
            item[0] = translate("engine.editor.menu.atOrigin", "at Origin") TAB "" TAB "atOrigin";
            item[1] = translate("engine.editor.menu.atCamera", "at Camera") TAB "" TAB "atCamera";
            item[2] = translate("engine.editor.menu.atCamaraWoRot", "at Camera w/Rotation") TAB "" TAB "atCameraRot";
            item[3] = translate("engine.editor.menu.belowCamera", "Below Camera") TAB "" TAB "belowCamera";
            item[4] = translate("engine.editor.menu.screenCenter", "Screen Center") TAB "" TAB "screenCenter";
            item[5] = translate("engine.editor.menu.atCenteroid", "at Centroid") TAB "" TAB "atCentroid";
            item[6] = translate("engine.editor.menu.toTerrain", "to Terrain") TAB "" TAB "toTerrain";
            item[7] = translate("engine.editor.menu.belowSelection", "Below Selection") TAB "" TAB "belowSelection";
        };

        %this.alignBoundsMenu = new PopupMenu()
        {
            superClass = "MenuBuilder";
            class = "EditorAlignBoundsMenu";

            // The onSelectItem() callback for this menu re-purposes the command field
            // as the MenuBuilder version is not used.
            item[0] = translate("engine.editor.menu.posXAxis", "+X Axis") TAB "" TAB "0";
            item[1] = translate("engine.editor.menu.posYAxis", "+Y Axis") TAB "" TAB "1";
            item[2] = translate("engine.editor.menu.posZAxis", "+Z Axis") TAB "" TAB "2";
            item[3] = translate("engine.editor.menu.negXAxis", "-X Axis") TAB "" TAB "3";
            item[4] = translate("engine.editor.menu.negYAxis", "-Y Axis") TAB "" TAB "4";
            item[5] = translate("engine.editor.menu.negZAxis", "-Z Axis") TAB "" TAB "5";
        };

        %this.alignCenterMenu = new PopupMenu()
        {
            superClass = "MenuBuilder";
            class = "EditorAlignCenterMenu";

            // The onSelectItem() callback for this menu re-purposes the command field
            // as the MenuBuilder version is not used.
            item[0] = translate("engine.editor.menu.xAxis", "X Axis") TAB "" TAB "0";
            item[1] = translate("engine.editor.menu.yAxis", "Y Axis") TAB "" TAB "1";
            item[2] = translate("engine.editor.menu.zAxis", "Z Axis") TAB "" TAB "2";
        };

        %this.worldMenu = new PopupMenu()
        {
            superClass = "MenuBuilder";
            class = "EditorWorldMenu";

            barTitle = translate("engine.editor.menu.object", "Object");

            item[0] = translate("engine.editor.menu.lockSelection", "Lock Selection") TAB %cmdCtrl @ " L" TAB "EWorldEditor.lockSelection(true); EWorldEditor.syncGui();";
            item[1] = translate("engine.editor.menu.unlockSelection", "Unlock Selection") TAB %cmdCtrl @ "-Shift L" TAB "EWorldEditor.lockSelection(false); EWorldEditor.syncGui();";
            item[2] = "-";
            item[3] = translate("engine.editor.menu.hideSelection", "Hide Selection") TAB %cmdCtrl @ " H" TAB "EWorldEditor.hideSelection(true); EWorldEditor.syncGui();";
            item[4] = translate("engine.editor.menu.showSelection", "Show Selection") TAB %cmdCtrl @ "-Shift H" TAB "EWorldEditor.hideSelection(false); EWorldEditor.syncGui();";
            item[5] = "-";
            item[6] = translate("engine.editor.menu.alignBounds", "Align Bounds") TAB %this.alignBoundsMenu;
            item[7] = translate("engine.editor.menu.alignCenter", "Align Center") TAB %this.alignCenterMenu;
            item[8] = "-";
            item[9] = translate("engine.editor.menu.resetTransforms", "Reset Transforms") TAB "Ctrl R" TAB "EWorldEditor.resetTransforms();";
            item[10] = translate("engine.editor.menu.resetSelRot", "Reset Selected Rotation") TAB "" TAB "EWorldEditor.resetSelectedRotation();";
            item[11] = translate("engine.editor.menu.resetSelScale", "Reset Selected Scale") TAB "" TAB "EWorldEditor.resetSelectedScale();";
            item[12] = translate("engine.editor.menu.transformSel", "Transform Selection...") TAB "Ctrl T" TAB "ETransformSelection.ToggleVisibility();";
            item[13] = "-";
            //item[13] = "Drop Camera to Selection" TAB "Ctrl Q" TAB "EWorldEditor.dropCameraToSelection();";
            //item[14] = "Add Selection to Instant Group" TAB "" TAB "EWorldEditor.addSelectionToAddGroup();";
            item[14] = translate("engine.editor.menu.dropSel", "Drop Selection") TAB "Ctrl D" TAB "EWorldEditor.dropSelection();";
            //item[15] = "-";
            item[15] = translate("engine.editor.menu.dropLocation", "Drop Location") TAB %this.dropTypeMenu;
            Item[16] = "-";
            Item[17] = translate("engine.editor.menu.makeSelPrefab", "Make Selection Prefab") TAB "" TAB "EditorMakePrefab();";
            Item[18] = translate("engine.editor.menu.explodeSelPrefab", "Explode Selected Prefab") TAB "" TAB "EditorExplodePrefab();";
        };
    }
}

//////////////////////////////////////////////////////////////////////////

function EditorGui::attachMenus(%this)
{
    %this.menuBar.attachToCanvas(Canvas, 0);
}

function EditorGui::detachMenus(%this)
{
    %this.menuBar.removeFromCanvas();
}

function EditorGui::setMenuDefaultState(%this)
{
    if(! isObject(%this.menuBar))
        return 0;

    for(%i = 0;%i < %this.menuBar.getCount();%i++)
    {
        %menu = %this.menuBar.getObject(%i);
        %menu.setupDefaultState();
    }

    %this.worldMenu.setupDefaultState();
}

//////////////////////////////////////////////////////////////////////////

function EditorGui::findMenu(%this, %name)
{
    if(! isObject(%this.menuBar))
        return 0;

    for(%i = 0;%i < %this.menuBar.getCount();%i++)
    {
        %menu = %this.menuBar.getObject(%i);

        if(%name $= %menu.barTitle)
            return %menu;
    }

    return 0;
}
