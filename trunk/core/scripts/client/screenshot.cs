
//---------------------------------------------------------------------------------------------
// formatImageNumber
// Preceeds a number with zeros to make it 6 digits long.
//---------------------------------------------------------------------------------------------
function formatImageNumber(%number)
{
    if(%number < 10)
        %number = "0" @ %number;
    if(%number < 100)
        %number = "0" @ %number;
    if(%number < 1000)
        %number = "0" @ %number;
    if(%number < 10000)
        %number = "0" @ %number;
    return %number;
}

//---------------------------------------------------------------------------------------------
// formatSessionNumber
// Preceeds a number with zeros to make it 4 digits long.
//---------------------------------------------------------------------------------------------
function formatSessionNumber(%number)
{
    if(%number < 10)
        %number = "0" @ %number;
    if(%number < 100)
        %number = "0" @ %number;
    return %number;
}

function doScreenShot() { _screenShot( 1, 1 ); }
function doBigScreenShot() { _screenShot( 4, 1 ); }

/// A counter for screen shots used by _screenShot().
$screenshotNumber = 0;

/// Internal function which generates unique filename
/// and triggers a screenshot capture.
function _screenShot( %superSampling, %tiles, %overlap )
{
    while(1)
    {
        createPath( "screenshots" );
        %name = "screenshots/screenshot_" @ formatImageNumber($screenshotNumber);
        %name = expandFileName( %name );
        $screenshotNumber++;
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

    if (  ( $pref::Video::screenShotFormat $= "JPEG" ) ||
            ( $pref::video::screenShotFormat $= "JPG" ) )
        screenShot( %name, "JPEG", %superSampling, %tiles, %overlap );
    else
        screenShot( %name, "PNG", %superSampling, %tiles, %overlap );
}

/// This will close the console and take a large format
/// screenshot by tiling the current backbuffer and save
/// it to the root game folder.
///
/// For instance a tile setting of 4 with a window set to
/// 800x600 will output a 3200x2400 screenshot.
function tiledScreenShot( %tiles, %overlap )
{
    // Pop the console off before we take the shot.
    Canvas.popDialog( ConsoleDlg );

    _screenShot( 1, %tiles, %overlap );
}

function bigScreenShot( %superSampling )
{
    // Pop the console off before we take the shot.
    Canvas.popDialog( ConsoleDlg );

    _screenShot( %superSampling, 1, 0 );
}
