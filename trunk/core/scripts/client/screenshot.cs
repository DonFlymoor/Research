// be aware: this is all supposed to be converted to screenshot.lua.
// Please do not add new things in here

function doScreenShot()     { _screenShot(  1, 1, 0, false ); }
function doBigScreenShot()  { Canvas.popDialog(ConsoleDlg); _screenShot(  4, 1, 0, true ); }
function doHugeScreenShot() { Canvas.popDialog(ConsoleDlg); _screenShot( 32, 1, 0, true ); }


/// This will close the console and take a large format
/// screenshot by tiling the current backbuffer and save
/// it to the root game folder.
///
/// For instance a tile setting of 4 with a window set to
/// 800x600 will output a 3200x2400 screenshot.
function bigScreenShot( %superSampling ) { Canvas.popDialog(ConsoleDlg); _screenShot( %superSampling, 1, 0 ); }
function tiledScreenShot( %tiles, %overlap ) { Canvas.popDialog(ConsoleDlg); _screenShot( 1, %tiles, %overlap ); }

/// Internal function which generates unique filename
/// and triggers a screenshot capture.
$screenshotHighest = false;


function _screenShot( %superSampling, %tiles, %overlap, %highest )
{
    $screenshotHighest = %highest;
    // save current values
    $sc_detailAdjustSaved = $pref::TS::detailAdjust;
    $sc_lodScaleSaved = $pref::Terrain::lodScale;
    if(isObject(sunsky)) {
        $sc_sunskyTexSizeSaved = sunsky.texSize;
        %sc_sunskyShadowDistanceSaved = sunsky.shadowDistance;
    }
    // set the new values
    if($screenshotHighest) {
        // store old values
        $sc_detailAdjustSaved = $pref::TS::detailAdjust;
        $sc_lodScaleSaved = $pref::Terrain::lodScale;
        $sc_GroundCoverScaleSaved = getGroundCoverScale();
        if(isObject(sunsky)) {
            $sc_sunskyTexSizeSaved = sunsky.texSize;
            $sc_sunskyShadowDistanceSaved = sunsky.shadowDistance;
        }

        info("Setting new render parameters ...");
        $pref::TS::detailAdjust = 20; // 1.5; // high is better
        $pref::Terrain::lodScale = 0.001; // 0.75; // lower is better
        setGroundCoverScale(8); // 1 // bigger is better
        flushGroundCoverGrids();
        if(isObject(sunsky)) {
            sunsky.texSize = 8192; // 1024; // default value on our levels, high is better
            sunsky.shadowDistance =  8000; // 1600; // default for gridmap, high is better
        }
    }
    // it's temporary
    %screenshotNumber = 0;
    while(1)
    {
        createPath( "screenshots"  );
        createPath( "screenshots/" @ getScreenShotFolderString() );

        %name = "screenshots/" @ getScreenShotFolderString() @ "/screenshot_" @ getScreenShotDateTimeString();
        if(%screenshotNumber > 0) {
            %name = %name @ "_" @ %screenshotNumber;
        }
        %name = expandFileName( %name );
        %screenshotNumber++;
        if (  ( $pref::Video::screenShotFormat $= "JPEG" ) || ( $pref::video::screenShotFormat $= "JPG" ) )
            %fullFilename = %name @ ".jpg";
        else
            %fullFilename = %name @ ".png";

        if(!isFile( %fullFilename ))
        {
            info("writing screenshot: " @ %fullFilename);
            break;
        }
    }

    if (  ( $pref::Video::screenShotFormat $= "JPEG" ) || ( $pref::video::screenShotFormat $= "JPG" ) )
        screenShot( %name, "JPEG", %superSampling, %tiles, %overlap );
    else
        screenShot( %name, "PNG", %superSampling, %tiles, %overlap );
}

// executed by c++ when the screenshot is done
function _screenShotDone()
{
    info("Screenshot done, resetting render parameters");
    if($screenshotHighest) {
        $pref::TS::detailAdjust = $sc_detailAdjustSaved;
        $pref::Terrain::lodScale = $sc_lodScaleSaved;
        setGroundCoverScale($sc_GroundCoverScaleSaved);
        if(isObject(sunsky)) {
            sunsky.texSize = $sc_sunskyTexSizeSaved;
            sunsky.shadowDistance = $sc_sunskyShadowDistanceSaved;
        }
    }
}
