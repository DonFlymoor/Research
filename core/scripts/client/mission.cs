/*

// Whether the local client is currently running a mission.
$Client::missionRunning = false;

// Sequence number for currently running mission.
$Client::missionSeq = -1;

new EventManager(LevelEventManager){ queue = "LevelEventManagerQueue"; };
LevelEventManager.registerEvent("onPreLevelLoad");

// Called when mission is started.
function clientStartMission()
{
    // The client recieves a mission start right before
    // being dropped into the game.
    physicsStartSimulation();

    // Start game audio effects channels.

    AudioChannelEffects.play();

    // Create client mission cleanup group.

    new SimGroup( ClientMissionCleanup );

    // Done.

    $Client::missionRunning = true;

    LuaExecuteQueueString("clientStartMission(\"" @ getMissionFilename() @ "\")");
}

// Called when mission is ended (either through disconnect or
// mission end client command).
function clientEndMission()
{
    LuaExecuteQueueString("clientEndMission(\"" @ getMissionFilename() @ "\")");

    // Stop physics simulation on client.
    physicsStopSimulation();

    // Stop game audio effects channels.

    AudioChannelEffects.stop();

    // Delete all the decals.
    decalManagerClear();

    // Delete client mission cleanup group.
    if( isObject( ClientMissionCleanup ) )
        ClientMissionCleanup.delete();

    // Done.
    $Client::missionRunning = false;

    //LogSceneObjects(true);
}

//----------------------------------------------------------------------------
// Mission start / end events sent from the server
//----------------------------------------------------------------------------

function clientCmdMissionStart(%seq)
{
    clientStartMission();
    $Client::missionSeq = %seq;
}

function clientCmdMissionEnd( %seq )
{
    if( $Client::missionRunning && $Client::missionSeq == %seq )
    {
        clientEndMission();
        $Client::missionSeq = -1;
    }
}

/// Expands the name of a mission into the full
/// mission path and extension.
function expandMissionFileName( %missionFile ) {
    // Expand any escapes in it.
    %missionFile = expandFilename( %missionFile );

    // If the mission file doesn't exist... try to fix up the string.
    if ( !isFile( %missionFile ) ) {

        // try the new filename
        if ( strStr( %missionFile, ".level.json" ) == -1 ) {
            %newMission = %missionFile @ ".level.json";
        }
        echo(%newMission);
        if (isFile( %newMission )) {
            return %newMission;
        }

        // Support for old .mis files
        if ( strStr( %missionFile, ".mis" ) == -1 ) {
            %newMission = %missionFile @ ".mis";
        }
        if (isFile( %newMission )) {
            return %newMission;
        }

        warn( "The level file '" @ %missionFile @ "' was not found!" );
        return "";
    }
    return %missionFile;
}
*/