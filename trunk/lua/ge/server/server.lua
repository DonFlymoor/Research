local M = {}

local logTag = 'server.lua'

local function initBaseServer()
    TorqueScript.exec("core/scripts/server/commands.cs")
end

--seems to work for freeroam
local function createGameActual(levelPath)

    TorqueScript.setVar("$loadingLevel", "true")  -- DO NOT REMOVE, this is used on the c++ side

    TorqueScript.setVar("$Camera::movementSpeed","30")

    clientPreStartMission(levelPath)

    -- Make sure our level name is relative so that it can send
    -- across the network correctly
    levelPath = be:makeRelativePath(levelPath, be:getWorkingDirectory())
    TorqueScript.setVar("$Physics::isSinglePlayer", "true")

    -- Create the ServerGroup that will persist for the lifetime of the server.
    local myServerGroup = createObject('SimGroup')
    if not myServerGroup then
        log('E', logTag, 'could not create ServerGroup')
        return
    end
    myServerGroup:registerObject('ServerGroup')

    --
    scenetree.RootGroup:addObject(myServerGroup.obj)
    --

    -- this creates the game object which is used everywhere to refer to it
    local myGame = createObject('GameConnection')
    if not myGame then
        log('E', logTag, 'could not create Game')
        return
    end
    myGame:registerObject('Game')
    if not scenetree.RootGroup then
        log('E', logTag, 'could not find RootGroup')
        return
    end

    scenetree.RootGroup:addObject(myGame.obj)

     -- Load up any core datablocks
    TorqueScript.exec("core/art/datablocks/datablockExec.cs")

    -- Let the game initialize some things now that the
    -- the server has been created
    gameManager.onCreation()
    missionLoad.loadMission(levelPath, true)

    -- Load the static mission decals.
    if FS:fileExists(levelPath.."/main.decals.json") then
      be:decalManagerLoad(levelPath.."/main.decals.json")
    elseif FS:fileExists(levelPath.."/../main.decals.json") then
        be:decalManagerLoad(levelPath.."/../main.decals.json")
    else
      be:decalManagerLoad(levelPath..".decals")
    end

    -- NOTE(AK): These spawns are only needed by freeroam. Scenario does it's own spawning
    spawn.spawnCamera()

    spawn.spawnPlayer()
    ------------------------------------

    core_gamestate.requestExitLoadingScreen(logTag)

    clientPostStartMission(levelPath)

    clientStartMission(getMissionFilename())

    TorqueScript.setVar("$loadingLevel", "false") -- DO NOT REMOVE, this is used on the c++ side
end


local function destroy()
    TorqueScript.setVar("$missionRunning", "false")

    --End any running levels
    missionLoad.endMission()
    gameManager.onDestruction()

    -- Delete all the server objects
    local serverGroup = scenetree.findObject("ServerGroup")
    if serverGroup then
        serverGroup:delete()
        serverGroup = nil
    end

    TorqueScript.setVar("$Server::GuidList", "")

    -- Delete all the data blocks...
    be:deleteDataBlocks()

    -- Increase the server session number.  This is used to make sure we're
    -- working with the server session we think we are.
    local sessionCnt = (tonumber(TorqueScript.getVar("$Server::Session")) or 0) +1
    TorqueScript.setVar("$Server::Session", sessionCnt)
end

local function createGameWrapper (levelPath)
    local function help ()
        createGameActual(levelPath)
    end
    --log('I', logTag, 'Loading = '..tostring(core_gamestate.loading()))
    -- yes this is weird, but it fixes the problem with createGame and luaPreRender
    core_gamestate.requestEnterLoadingScreen(logTag, help)
    core_gamestate.requestEnterLoadingScreen('worldReadyState')
end

M.createGame = createGameWrapper
M.destroy = destroy
M.initBaseServer = initBaseServer
return M