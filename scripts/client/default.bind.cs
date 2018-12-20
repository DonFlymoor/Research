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
            //case 15: %debugMode = "ShowVertexColors"; // Deprecated
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
