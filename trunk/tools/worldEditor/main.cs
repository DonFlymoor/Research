$autoSaveTimerId = 0;
$firstManualSave = false;

function scheduleAutoSave()
{
    if ($firstManualSave == false)
        return;

    if (EWorldEditor.autoSave $= "0")
    {
        echo("Canceled autosaving mission");
        cancel($autoSaveTimerId);
    }
    else if (EWorldEditor.autoSaveInterval >= 1)
    {
        if ($autoSaveTimerId != 0)
            cancel($autoSaveTimerId);

        echo("Schedule next autosaving mission in " SPC EWorldEditor.autoSaveInterval SPC " seconds");
        $autoSaveTimerId = schedule(EWorldEditor.autoSaveInterval * 1000, 0, "doAutoSave");
    }
}

function doAutoSave()
{
    if ($firstManualSave == false)
        return;

    echo("Autosaving mission...");
    EditorSaveMission(false);
    scheduleAutoSave();
}

function askToSaveMissionOnExit()
{
    if (EditorIsDirty() && $firstManualSave == true)
    {
        MessageBoxYesNo("Level Modified",
        "Would you like to save your changes before exiting?",
        "EditorSaveMission(true); EditorClearDirty(); Editor.close(\"OnlyGui\");",
        "EditorClearDirty(); Editor.close(\"OnlyGui\");");
    }
    else
    {
        Editor.close("OnlyGui");
    }
}

function initializeWorldEditor()
{
    //debug(" % - Initializing World Editor");

    // Load GUI
    exec("./gui/profiles.ed.cs");
    exec("./scripts/cursors.ed.cs");

    exec("./gui/guiCreateNewTerrainGui.gui" );
    exec("./gui/GenericPromptDialog.ed.gui" );
    exec("./gui/guiTerrainImportGui.gui" );
    exec("./gui/guiTerrainExportGui.gui" );
    exec("./gui/EditorGui.ed.gui");
    exec("./gui/objectBuilderGui.ed.gui");
    exec("./gui/TerrainEditorVSettingsGui.ed.gui");
    exec("./gui/EditorChooseLevelGui.ed.gui");
    exec("./gui/VisibilityLayerWindow.ed.gui");
    exec("./gui/ManageBookmarksWindow.ed.gui");
    exec("./gui/ManageSFXParametersWindow.ed.gui" );
    exec("./gui/TimeAdjustGui.ed.gui");
    exec("./gui/SelectObjectsWindow.ed.gui");
    exec("./gui/ProceduralTerrainPainterGui.gui" );

    // Load Scripts.
    exec("./scripts/menus.ed.cs");
    exec("./scripts/menuHandlers.ed.cs");
    exec("./scripts/editor.ed.cs");
    exec("./scripts/editor.bind.ed.cs");
    exec("./scripts/undoManager.ed.cs");
    exec("./scripts/lighting.ed.cs");
    exec("./scripts/EditorGui.ed.cs");
    exec("./scripts/editorPrefs.ed.cs");
    exec("./scripts/editorRender.ed.cs");
    exec("./scripts/editorPlugin.ed.cs");
    exec("./scripts/EditorChooseLevelGui.ed.cs");
    exec("./scripts/visibilityLayer.ed.cs");
    exec("./scripts/cameraBookmarks.ed.cs");
    exec("./scripts/ManageSFXParametersWindow.ed.cs");
    exec("./scripts/SelectObjectsWindow.ed.cs");

    // Load Custom Editors
    loadDirectory(expandFilename("./scripts/editors"));
    loadDirectory(expandFilename("./scripts/interfaces"));

    // Create the default editor plugins before calling buildMenus.

    new ScriptObject( WorldEditorPlugin )
    {
        superClass = "EditorPlugin";
        editorGui = EWorldEditor;
    };

    // aka. The ObjectEditor.
    new ScriptObject( WorldEditorInspectorPlugin )
    {
        superClass = "WorldEditorPlugin";
        editorGui = EWorldEditor;
    };

    new ScriptObject( TerrainEditorPlugin )
    {
        superClass = "EditorPlugin";
        editorGui = ETerrainEditor;
    };

    new ScriptObject( TerrainPainterPlugin )
    {
        superClass = "EditorPlugin";
        editorGui = ETerrainEditor;
    };

    new ScriptObject( MaterialEditorPlugin )
    {
        superClass = "WorldEditorPlugin";
        editorGui = EWorldEditor;
    };

    // Expose stock visibility/debug options.
    EVisibility.addOption( "BeamNG: draw waypoints", "$pref::BeamNGWaypoint::drawDebug", "" );
    EVisibility.addOption( "BeamNG: draw navigation graph", "$pref::BeamNGNavGraph::drawDebug", "" );
    EVisibility.addOption( "BeamNG: draw scenario debug", "$pref::BeamNGRace::drawDebug", "" );
    EVisibility.addOption( "Advanced text drawing", "$pref::DebugDraw::drawAdvancedText", "" );
    EVisibility.addOption( "Wireframe Mode", "$gfx::wireframe", "" );

    EVisibility.addOption( "Bounding Boxes", "$Scene::renderBoundingBoxes", "" );


    EVisibility.addOption( "Frustum Lock", "$Scene::lockCull", "" );

    EVisibility.addOption( "Sound Emitters", "$SFXEmitter::renderEmitters", "" );
    EVisibility.addOption( "Far Sound Emitters", "$SFXEmitter::forceRenderFarEmitters", "" );
    EVisibility.addOption( "Render: Sound Spaces", "$SFXSpace::isRenderable", "" );
    EVisibility.addOption( "Terrain", "TerrainBlock::debugRender", "" );
    EVisibility.addOption( "Decals", "$Decals::debugRender", "" );
    EVisibility.addOption( "Light Frustums", "$Light::renderLightFrustums", "" );
    EVisibility.addOption( "Disable Zone Culling", "$Scene::disableZoneCulling", "" );
    EVisibility.addOption( "Disable Terrain Occlusion", "$Scene::disableTerrainOcclusion", "" );

    EVisibility.addOption( "Zones", "$Zone::isRenderable", "" );
    EVisibility.addOption( "Portals", "$Portal::isRenderable", "" );
    EVisibility.addOption( "Occlusion Volumes", "$OcclusionVolume::isRenderable", "" );
    EVisibility.addOption( "Player Collision", "$Player::renderCollision", "" );
    EVisibility.addOption( "Triggers", "$Trigger::renderTriggers", "" );
    EVisibility.addOption( "PhysicalZones", "$PhysicalZone::renderZones", "" );

    EVisibility.addOption( "Advanced Lighting: Disable Shadows", "$Shadows::disable", "" );
    EVisibility.addOption( "Advanced Lighting: Light Color Viz", "$AL_LightColorVisualizeVar", "toggleLightColorViz" );
    EVisibility.addOption( "Advanced Lighting: Light Specular Viz", "$AL_LightSpecularVisualizeVar", "toggleLightSpecularViz" );
    EVisibility.addOption( "Advanced Lighting: Normals Viz", "$AL_NormalsVisualizeVar", "toggleNormalsViz" );
    EVisibility.addOption( "Advanced Lighting: Depth Viz", "$AL_DepthVisualizeVar", "toggleDepthViz" );
    EVisibility.addOption( "Annotation Viz", "$AnnotationVisualizeVar", "toggleAnnotationVisualize" );
    //EVisibility.addOption( "NavMesh: General Debug", "$Nav::Editor::renderMesh", "" );
    //EVisibility.addOption( "NavMesh: Portals", "$Nav::Editor::renderPortals", "" );
    //EVisibility.addOption( "NavMesh: renderBVTree", "$Nav::Editor::renderBVTree", "" );
}

function destroyWorldEditor()
{
}
