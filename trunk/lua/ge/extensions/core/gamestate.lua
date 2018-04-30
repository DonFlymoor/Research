local M = {}
local logTag = "gamestate"

M.state = {}

local loadingActive = false
local waitingForUI = false
local UIInitialised = false
-- GameState = GAME (not UI)
-- This is meant to store if we are in freeroam or campaign etc
-- This is espacially helpfull if the campaign contains something similar to a freeroam part
-- this also will hold specific game relevant ui configurations, like applayout and menu items, those can be emited and will then be filled by defaults

local function sendGameState()
  extensions.hook('onGameStateUpdate', M.state)
  guihooks.trigger('GameStateUpdate', M.state)
end

-- if only one should be updated omit the other parameters or set to nil
local function setGameState(state, appLayout, menuItems, options)
  M.state = {
    state = state or M.state.state,
    appLayout = appLayout or M.state.appLayout,
    menuItems = menuItems or M.state.menuItems,
    options = options or M.state.options
  }
  sendGameState()
end

-- called when going back to main menu
local function resetGameState()
  M.state = {}
end

-- UI state === to main menu or not to main menu
-- This is a state for the ui, so it knows if it should show the main menu or the side menu
-- important: this is not meant to change the router state, but only a variable change.
local function sendShowMainMenu ()
  -- TODO check if getter setter is needed or if this is enough and always correct -yh
  local mainMenu = getMissionFilename() == ''
  --log('D', logTag, 'show main menu')
  guihooks.trigger('ShowEntertainingBackground', mainMenu)

  return mainMenu
end

-- loading screen
-- the problem until now, was that lua could not distinguish between level unloads and level switches
-- since we do not want to exit the loading screen when currently switching and unloading stage is finished this was a problem
-- solution: we just wait until the last module finished requiring the loading screen and then and only then exit the loading screen
local loadingScreenRequests = 0
local listeners = {}

local function tellListeners ()
  for k,v in pairs(listeners) do
    v()
    listeners[k] = nop
  end
end

local function showLoadingScreen (func, superSecretIncrementVal)
  local first = loadingScreenRequests == 0
  --log('D', logTag, 'ref counter at: ' .. loadingScreenRequests .. ' increasing by: ' .. (superSecretIncrementVal or 1))
  loadingScreenRequests = loadingScreenRequests + (superSecretIncrementVal or 1)
  func = func or nop

  if first and not loadingActive then
    --log('D', logTag, 'sending show loading screen')
    guihooks.trigger('ChangeState', 'loading')
  end

  if loadingActive then
    --log('D', logTag, 'exec fun dircect')
    func()
  else
    listeners[loadingScreenRequests] = func
    --log('D', logTag, 'ui initialised (' .. tostring(UIInitialised) .. ')')
    --log('D', logTag, 'waiting for ui (' .. tostring(waitingForUI) .. ')')
    if not UIInitialised then
      waitingForUI = true
    end
  end
end

local function exitLoadingScreen ()
  --log('D', logTag, 'exit at current ref counter: ' .. loadingScreenRequests)

  if loadingScreenRequests == 1 then
    if sendShowMainMenu() then
      guihooks.trigger('ChangeState', 'menu.mainmenu')
      --log('D', logTag, 'change state to menu.mainmenu')
      -- this is the only case we aren't in a gamestate everything else should be
      resetGameState()
    else
      --log('D', logTag, 'exiting loading screen to menu')
      guihooks.trigger('ChangeState', 'menu', {'loading', 'menu.mainmenu'})
    end

    listeners = {}
    loadingActive = false
  end

  if loadingScreenRequests > 0 then
    loadingScreenRequests = loadingScreenRequests - 1
  end
end

local function loadingScreenActive ()
  --log('D', logTag, 'ui told us loading screen is now loaded')
  loadingActive = true
  tellListeners()
end

local function onDeserialized(data)
end

local function uiReady ()
  --log('D', logTag, 'ui finished loading')
  UIInitialised = true;

  if waitingForUI then
    --log('D', logTag, 'wait for ui is over')
    guihooks.trigger('ChangeState', 'loading')
  end
end

local function onExtensionLoaded ()
  -- it is important this does happen direclty, so potential others don't get confused
  be:queueJS('core_gamestate.onUIInitialised')
end

-- interface
M.onDeserialized = onDeserialized

M.requestGameState = sendGameState
M.setGameState = setGameState

M.requestMainMenuState = sendShowMainMenu

M.requestEnterLoadingScreen = showLoadingScreen
M.requestExitLoadingScreen = exitLoadingScreen

M.loadingScreenActive = loadingScreenActive

M.onUIInitialised = uiReady

return M