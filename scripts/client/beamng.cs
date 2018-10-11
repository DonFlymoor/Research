function GameTSCtrl::onRightMouseDown( %this )
{
    hideCursor();
    %this.setEnabledControl(false);
    Canvas.alwaysHandleMouseButtons = true;
}


function GameTSCtrl::onRightMouseUp( %this )
{
    showCursor();
    %this.setEnabledControl(true);
    Canvas.alwaysHandleMouseButtons = false;
}

function BeamNGVehicle::init( %this )
{
}

$BeamNGHelpDisplay = false;
function BeamNGHelpToggle(%unused) {
    $BeamNGHelpDisplay = !$BeamNGHelpDisplay;
    beamNGExecuteJS("HookManager.trigger('HelpToggle',"@ $BeamNGHelpDisplay @ ")");
}

function BeamNGVehicle::postSpawn( %this )
{
    // support for old beamngDiffuseColorSlot
    %matCount = %this.getTargetCount();
    for( %i = 0; %i < %matCount; %i++ )
    {
        %matName = %this.getTargetName(%i);
        if(%matName !$= "")
        {
            %mat = getMaterialMapping( %matName );
            %changed = 0;
            if(%this.color !$= "" && %this.color !$= "0 0 0 0" && %mat.beamngDiffuseColorSlot !$= "")
            {
                %mat.instanceDiffuse[%mat.beamngDiffuseColorSlot] = true;
                %changed = 1;
            }
            if(%changed == 1)
            {
                %mat.flush();
                %mat.reload();
            }
        }
    }
    if ($Testing::Enabled)
    {
        Testing::onVehicleSpawned();
        TestEventManager.postEvent("onVehicleChanged", %this);
    }
}

// default cubemap for levels without LevelInfo.globalEnviromentMap
$defaultLevelEnviromentMap = "BNG_Sky_02_cubemap";

// this function wraps around toggleEditor() to not have to load the editor when not needed
function toggleEditorDynamic() {
  if(!isFunction("toggleEditor")) {
    exec("tools/main.cs");
    onEditorStart();
  }
  toggleEditor();
}

// dynamic wrapper around updateTSShapeLoadProgress
function updateTSShapeLoadProgressDynamic(%progress, %msg) {
  if(isFunction("updateTSShapeLoadProgress")) {
    // usually the case if the editor is loaded, it usually calls updateLoadingProgress in it then
    updateTSShapeLoadProgress(%progress, %msg);
  } else {
    // usually the case if the editor is NOT loaded
    //%msg = translate("ui.loading.spawn.collada", "Importing 3D stuff") @ " ...";
    updateLoadingProgress(%progress, %msg);
  }
}

// this tries to replaint the screen while we load a mission
// the c++ side only calls this function if $loadingLevel == true
function onObjectAddedGlobally(%obj) {
    //echo("repainting ... ");
    if(isObject(%obj)) {
        %t = "";
        // some abstraction for the loading messages. Its a little bit cheated as the object is already loaded when we reach this point...

        // name filters first
        if(%obj.getName() $= "thePlayer") {
            %t = translate("ui.loading.spawn.player", "Spawning player");
        } else if(%obj.getName() $= "theTerrain" || %obj.getClassName() $= "GroundPlane") {
            %t = translate("ui.loading.spawn.terrain", "Shoveling dirt");
        // afterwards, class filters
        } else if(%obj.getClassName() $= "BeamNGVehicle") {
            %t = translate("ui.loading.spawn.vehicles", "Preparing engines");
        } else if(%obj.getClassName() $= "TimeOfDay") {
            %t = translate("ui.loading.spawn.time", "Making it day and night");
        } else if(%obj.getClassName() $= "BasicClouds" || %obj.getClassName() $= "CloudLayer" || %obj.getClassName() $= "ScatterSky" || %obj.getClassName() $= "Sun") {
            %t = translate("ui.loading.spawn.sky", "Forming Clouds");
        } else if(%obj.getClassName() $= "DecalRoad" || %obj.getClassName() $= "MeshRoad") {
            %t = translate("ui.loading.spawn.roads", "Building roads");
        } else if(%obj.getClassName() $= "TSStatic") {
            %t = translate("ui.loading.spawn.static", "Constructing buildings");
        } else if(%obj.getClassName() $= "SFXEmitter") {
            %t = translate("ui.loading.spawn.sound", "Making noise");
        } else if(%obj.getClassName() $= "River" || %obj.getClassName() $= "WaterBlock" || %obj.getClassName() $= "Ocean" || %obj.getClassName() $= "WaterPlane") {
            %t = translate("ui.loading.spawn.water", "Pouring water");
        } else if(%obj.getClassName() $= "PointLight" || %obj.getClassName() $= "SpotLight") {
            %t = translate("ui.loading.spawn.lights", "Turning on the lights");
        } else if(%obj.getClassName() $= "GroundCover") {
            %t = translate("ui.loading.spawn.groundcover", "Planting grass");
        } else if(%obj.getClassName() $= "Forest") {
            %t = translate("ui.loading.spawn.forest", "Growing trees");
        } else if(%obj.getClassName() $= "BeamNGWaypoint") {
            %t = translate("ui.loading.spawn.ai", "Teaching AI");
        } else if(%obj.getClassName() $= "PostEffect") {
            %t = translate("ui.loading.spawn.postfx", "Fancy effects");
        }
        if(%t !$= "") {
            updateLoadingProgress(-1, %t @ " ...");
        }
    }
    Canvas.repaintUI(33);
}

//debug("### beamng.cs loaded");