if (isObject(moveMap)) moveMap.delete();
new ActionMap(moveMap);


// Movement Keys
function moveleft    (%val) { $mvLeftAction     = %val; }
function moveright   (%val) { $mvRightAction    = %val; }
function moveforward (%val) { $mvForwardAction  = %val; }
function movebackward(%val) { $mvBackwardAction = %val; }
function moveup      (%val) { $mvUpAction       = %val; }
function movedown    (%val) { $mvDownAction     = %val; }


// 3d spacemouse support :)
$absRotateAxisFactorYaw   = 0.0003;
$absRotateAxisFactorPitch = 0.0003;
$absRotateAxisFactorRoll  = 0.0003;
$yawTemp   = 0;
$rollTemp  = 0;
$pitchTemp = 0;
function   yawAbs(%val) {   $mvYaw = (  $yawTemp - %val) * $absRotateAxisFactorYaw;     $yawTemp = %val; }
function  rollAbs(%val) {  $mvRoll = ( $rollTemp - %val) * $absRotateAxisFactorRoll;   $rollTemp = %val; }
function pitchAbs(%val) { $mvPitch = ($pitchTemp - %val) * $absRotateAxisFactorPitch; $pitchTemp = %val; }
$absTranslateAxisFactorX = 0.01;
$absTranslateAxisFactorY = 0.01;
$absTranslateAxisFactorZ = 0.01;
$xAxisAbsTemp = 0;
$yAxisAbsTemp = 0;
$zAxisAbsTemp = 0;
function xAxisAbs(%val) { %tmp = ($xAxisAbsTemp - %val) * $absTranslateAxisFactorX; $mvAbsXAxis = %tmp; $xAxisAbsTemp = %val; }
function yAxisAbs(%val) { %tmp = ($yAxisAbsTemp - %val) * $absTranslateAxisFactorY; $mvAbsYAxis = %tmp; $yAxisAbsTemp = %val; }
function zAxisAbs(%val) { %tmp = ($zAxisAbsTemp - %val) * $absTranslateAxisFactorZ; $mvAbsZAxis = %tmp; $zAxisAbsTemp = %val; }

// camera helper functions
function getMouseAdjustAmount  (%val) { return %val * $cameraFov / 9000; }

// rmb mouse camera
function camXChange(%val) { $mvCamX += getMouseAdjustAmount(%val);   yaw(%val); }
function camYChange(%val) { $mvCamY += getMouseAdjustAmount(%val); pitch(%val); }
function yaw(%val) {
    %yawAdj = getMouseAdjustAmount(%val);
    if(isObject(Game) && isObject(Game.camera) && Game.camera.newtonRotation) {
        // Clamp and scale
        %yawAdj = mClamp(%yawAdj, -m2Pi()+0.01, m2Pi()-0.01);
        %yawAdj *= 0.5;
    }
    $mvYaw += %yawAdj;
}
function pitch(%val) {
    %pitchAdj = getMouseAdjustAmount(%val);
    if(isObject(Game) && isObject(Game.camera) && Game.camera.newtonRotation) {
        // Clamp and scale
        %pitchAdj = mClamp(%pitchAdj, -m2Pi()+0.01, m2Pi()-0.01);
        %pitchAdj *= 0.5;
    }
    $mvPitch += %pitchAdj;
}

function rotate_camera_horizontal(%val) {
    %val = %val * 0.1;
    if(%val > 0) {
        $mvYawLeftSpeed = %val;
        $mvYawRightSpeed = 0;
    } else {
        $mvYawLeftSpeed = 0;
        $mvYawRightSpeed = -%val;
    }
}
function rotate_camera_vertical(%val) {
    %val = %val * 0.1;
    if(%val > 0) {
        $mvPitchDownSpeed = %val;
        $mvPitchUpSpeed = 0;
    } else {
        $mvPitchDownSpeed = 0;
        $mvPitchUpSpeed = -%val;
    }
}

function cameraZoom(%val) {
    %pitchAdj = %val * ($cameraFov / 900);
    if(isObject(Game) && isObject(Game.camera) && Game.camera.newtonRotation) {
        // Clamp and scale
        %pitchAdj = mClamp(%pitchAdj, -m2Pi()+0.01, m2Pi()-0.01);
        %pitchAdj *= 0.5;
    }

    if(%pitchAdj > 0) {
        $mvZoomInSpeed = %pitchAdj;
        $mvZoomOutSpeed = 0;
    } else {
        $mvZoomInSpeed = 0;
        $mvZoomOutSpeed = -%pitchAdj;
    }
}

function clearCameraRotationalSpeeds() {
    $mvZoomInSpeed = 0;
    $mvZoomOutSpeed = 0;
    $mvPitchDownSpeed = 0;
    $mvPitchUpSpeed = 0;
    $mvYawLeftSpeed = 0;
    $mvYawRightSpeed = 0;
}

// Debugging Functions
$MFDebugRenderMode = 0;
function cycleDebugRenderMode() {
    $MFDebugRenderMode++;
    if ($MFDebugRenderMode >  16) $MFDebugRenderMode = 0;
    if ($MFDebugRenderMode == 15) $MFDebugRenderMode = 16;

    setInteriorRenderMode($MFDebugRenderMode);

    if (isObject(ChatHud)) {
        %message = "Setting Interior debug render mode to ";
        %debugMode = "Unknown";

        switch($MFDebugRenderMode) {
            case  0: %debugMode = "NormalRender";
            case  1: %debugMode = "NormalRenderLines";
            case  2: %debugMode = "ShowDetail";
            case  3: %debugMode = "ShowAmbiguous";
            case  4: %debugMode = "ShowOrphan";
            case  5: %debugMode = "ShowLightmaps";
            case  6: %debugMode = "ShowTexturesOnly";
            case  7: %debugMode = "ShowPortalZones";
            case  8: %debugMode = "ShowOutsideVisible";
            case  9: %debugMode = "ShowCollisionFans";
            case 10: %debugMode = "ShowStrips";
            case 11: %debugMode = "ShowNullSurfaces";
            case 12: %debugMode = "ShowLargeTextures";
            case 13: %debugMode = "ShowHullSurfaces";
            case 14: %debugMode = "ShowVehicleHullSurfaces";
            // Deprecated
            //case 15: %debugMode = "ShowVertexColors";
            case 16: %debugMode = "ShowDetailLevel";
        }

        ChatHud.addLine(%message @ %debugMode);
    }
}

function cycleMetrics(%forward) {
    if (%forward) {
        if ($metricsEnabled $= "") metrics("fps");
        else if ($metricsEnabled $= "fps") metrics("time fps gfx terrain net groundCover forest sfx sfxSources sfxStates reflect decal render shadow basicShadow light particle");
        else metrics("");
    } else {
        if ($metricsEnabled $= "") metrics("time fps gfx terrain net groundCover forest sfx sfxSources sfxStates reflect decal render shadow basicShadow light particle");
        else if ($metricsEnabled $= "fps") metrics("");
        else metrics("fps");
    }
}


//------------------------------------------------------------------------------
// Start profiler by pressing ctrl f3
// ctrl f3 - starts profile that will dump to console and file
function doProfile(%val) {
    if (%val) {
        // key down -- start profile
        debug("Starting profile session...");
        profilerReset();
        profilerEnable(true);
    } else {
        // key up -- finish off profile
        debug("Ending profile session...");

        profilerDumpToFile("profilerDumpToFile" @ getSimTime() @ ".txt");
        profilerEnable(false);
    }
}
