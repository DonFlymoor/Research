local M = {}
local logTag = "serverConnection"

local function onCameraHandlerSetInitial()
  local canvas = scenetree.findObject("Canvas")
  if canvas then
    canvas:enableCursorHideIfMouseInactive(true)
  else
    log('E', logTag, 'canvas not found')
  end
  -- The first control object has been set by the server
  -- and we are now ready to go.

  log('D', logTag, 'Everything should be loaded setting worldReadyState to 1')
  worldReadyState = 1 -- should be ready, wait for the vehicle to be done, then switch. stage 2 is in the frame update
  extensions.hook('onWorldReadyState', worldReadyState)
end

--trigger by starting game and then starting a new level
local function disconnectActual(callback)
  -- We need to stop the client side simulation
  -- else physics resources will not cleanup properly.
  be:physicsStopSimulation()
  local canvas = scenetree.findObject("Canvas")
  if not canvas then
    log('E', logTag, 'canvas not found')
  end
  canvas:enableCursorHideIfMouseInactive(false);

  -- Disable mission lighting if it's going, this is here
  -- in case we're disconnected while the mission is loading.

  TorqueScript.setVar("$lightingMission", "false")
  TorqueScript.setVar("$sceneLighting::terminateLighting", "true")

  -- Before we destroy the client physics world
  -- make sure all Game objects are deleted.
  local game = scenetree.findObject("Game")
  if game then
    game:delete('')
    game = nil
  end

  -- Call destroyServer in case we're hosting
  server:destroy()
  setMissionFilename("")
  core_gamestate.requestExitLoadingScreen()
  if callback then
    return callback()
  end
end

local function disconnectWrapper (callback)
  local function help ()
    disconnectActual(callback)
  end
  core_gamestate.requestEnterLoadingScreen(help)
end

M.onCameraHandlerSetInitial = onCameraHandlerSetInitial
M.disconnect = disconnectWrapper
M.noLoadingScreenDisconnect = disconnectActual
return M