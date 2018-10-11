-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.mainController = nil
M.isFrozen = false

M.nilController = nil

local blacklist = {"shiftLogic-automaticGearbox", "shiftLogic-cvtGearbox", "shiftLogic-dctGearbox", "shiftLogic-manualGearbox", "shiftLogic-sequentialGearbox"}
local blacklistLookup = nil

local loadedControllers = {}
local sortedControllers = {}
local physicsUpdates = {}
local physicsUpdateCount = 0
local wheelsIntermediateUpdates = {}
local wheelsIntermediateUpdateCount = 0
local gfxUpdates = {}
local gfxUpdateCount = 0
local debugDraws = {}
local debugDrawCount = 0
local beamBrokens = {}
local beamBrokenCount = 0
local beamDeformeds = {}
local beamDeformedCount = 0
local couplerFoundEvents = {}
local couplerFoundEventCount = 0
local couplerAttachedEvents = {}
local couplerAttachedEventCount = 0
local couplerDetachedEvents = {}
local couplerDetachedEventCount = 0
local gameplayEvents = {}
local gameplayEventCount = 0
local controllerJbeamData = {}

local function updateGFX(dt)
  for i = 1, gfxUpdateCount, 1 do
    gfxUpdates[i](dt)
  end
end

local function update(dt)
  for i = 1, physicsUpdateCount, 1 do
    physicsUpdates[i](dt)
  end
end

local function updateWheelsIntermediate(dt)
  for i = 1, wheelsIntermediateUpdateCount, 1 do
    wheelsIntermediateUpdates[i](dt)
  end
end

local function beamBroke(id, energy)
  for i = 1, beamBrokenCount, 1 do
    beamBrokens[i](id, energy)
  end
end

local function beamDeformed(id, ratio)
  for i = 1, beamDeformedCount, 1 do
    beamDeformeds[i](id, ratio)
  end
end

local function onCouplerFound(nodeId, obj2id, obj2nodeId)
  for i = 1, couplerFoundEventCount, 1 do
    couplerFoundEvents[i](nodeId, obj2id, obj2nodeId)
  end
end

local function onCouplerAttached(nodeId, obj2id, obj2nodeId)
  for i = 1, couplerAttachedEventCount, 1 do
    couplerAttachedEvents[i](nodeId, obj2id, obj2nodeId)
  end
end

local function onCouplerDetached(nodeId, obj2id, obj2nodeId)
  for i = 1, couplerDetachedEventCount, 1 do
    couplerDetachedEvents[i](nodeId, obj2id, obj2nodeId)
  end
end

local function onGameplayEvent(eventName, ...)
  for i = 1, gameplayEventCount, 1 do
    gameplayEvents[i](eventName, ...)
  end
end

local function debugDraw(focusPos)
  for i = 1, debugDrawCount, 1 do
    debugDraws[i](focusPos)
  end
end

local function settingsChanged()
  for _, v in pairs(loadedControllers) do
    if v.settingsChanged then
      v.settingsChanged()
    end
  end
end

local function getAllControllers(name)
  return loadedControllers
end

local function getController(name)
  return loadedControllers[name]
end

local function getControllerSafe(name)
  local controller = loadedControllers[name]
  if controller then
    return controller
  else
    log("D", "controller.getControllerSafe", string.format("Didn't find controller '%s', returning nilController.", name))
    --return our nilController that accepts all indexes and can be called without errors
    return M.nilController
  end
end

local function getControllersByType(typeName)
  local controllers = {}
  for _, v in pairs(loadedControllers) do
    if v.typeName == typeName then
      table.insert(controllers, v)
    end
  end
  return controllers
end

local function setFreeze(mode)
  M.isFrozen = mode == 1
  if M.mainController then
    M.mainController.setFreeze(mode)
  end
end

local function adjustControllersPreInit(controllers)
  local escBehavior = settings.getValue("escBehavior") or "realistic"
  if escBehavior ~= "realistic" then
    if escBehavior == "arcade" and controllers.esc == nil then --only add arcade esc if we don't have a factory esc
    --we want arcade esc so we add that controller
    --controllers.escArcade = {fileName = "escArcade"}
    end
  end
  return controllers
end

local function init()
  loadedControllers = {}
  sortedControllers = {}
  controllerJbeamData = {}

  M.mainController = nil

  --Here we create a bit of special magic to deal with fire and forget controller access
  --for example: controller.getController("abc").doSomething()
  --in this case an error is thrown if "abc" is not a valid controller.
  --Using controller.getControllerSafe() instead returns a magic table that
  --happily accepts all indexes and can be called without throwing errors
  M.nilController = {}
  local mt = {
    __index = function(t, _)
      return t
    end, --return self when indexing
    __call = function(t, ...)
      return t
    end, --return self when being called
    __newindex = function(_, _, _)
    end, --prevent any write access
    __metatable = false --hide metatable to prevent any changes to it
  }
  setmetatable(M.nilController, mt)

  local jbeamControllers = v.data.controller
  if not jbeamControllers then
    jbeamControllers = {{fileName = "dummy"}}
    log("D", "controller.init", "No controllers found, adding a dummy controller!")
  end

  blacklistLookup = {}
  for _, v in pairs(blacklist) do
    blacklistLookup[v] = true
  end

  local controllers = {}
  for _, v in pairs(jbeamControllers) do
    if v.fileName and not blacklistLookup[v.fileName] then
      local name = v.name or v.fileName
      controllers[name] = v
    end
  end

  controllers = adjustControllersPreInit(controllers)

  local directory = "controller/"
  for k, c in pairs(controllers) do
    local filePath = directory .. c.fileName
    local loadFunc = function()
      local controller = rerequire(filePath)
      if controller then
        local data = tableMergeRecursive(c, v.data[k] or {})
        c.name = c.name or k
        controllerJbeamData[c.name] = data
        controller.name = c.name
        controller.typeName = c.fileName
        controller.init(data)
        controller.manualOrder = data.manualOrder
        loadedControllers[c.name] = controller

        if controller.type == "main" then
          if not M.mainController then
            M.mainController = controller
          else
            log("W", "controller.init", string.format("Found more than one main controller, 1: '%s', 2: '%s', unloading the first one...", M.mainController.name, controller.name))
            loadedControllers[M.mainController.name] = nil
            M.mainController = controller
          end
        end
      end
    end
    local result, errorStr = pcall(loadFunc)
    if not result then
      log("E", "controller.init", string.format("Can't load controller '%s', looking for file: '%s', further info below:", c.fileName, filePath))
      log("E", "controller.init", errorStr)
      log("E", "controller.init", debug.traceback())
    end
  end

  if not M.mainController then
    log("W", "controller.init", "No main controller found, adding a dummy controller!")
    local dummyName = "dummy"
    local controller = require(directory .. dummyName)
    if controller then
      loadedControllers[dummyName] = controller
      controller.init()
      controller.name = dummyName
      M.mainController = controller
    end
  end

  for _, v in pairs(loadedControllers) do
    table.insert(sortedControllers, v)
  end

  local ranks = {}
  for k, v in ipairs(powertrain.getOrderedDevices()) do
    ranks[v.name] = k * 100
  end
  table.sort(
    sortedControllers,
    function(a, b)
      local ra, rb = ranks[a.relevantDevice or ""] or a.manualOrder or a.defaultOrder or 100000, ranks[b.relevantDevice or ""] or b.manualOrder or b.defaultOrder or 100000
      a.order = ra
      b.order = rb
      if ra == rb then
        return a.name < b.name
      else
        return ra < rb
      end
    end
  )

  --  for k,v in pairs(sortedControllers) do
  --    print(string.format("%s -> %d", v.name, v.order))
  --  end

  --backwards compatiblity for old scenario.lua:freeze(), we don't know if any mod ever used this, just here as a precaution
  scenario = {
    freeze = function(mode)
      log("W", "controller", "scenario.freeze(mode) is deprecated. Please switch to controller.setFreeze(mode)")
      setFreeze(mode)
    end
  }
end

local function cacheControllerFunctions(controller)
  if controller.update then
    table.insert(physicsUpdates, controller.update)
  end
  if controller.updateWheelsIntermediate then
    table.insert(wheelsIntermediateUpdates, controller.updateWheelsIntermediate)
  end
  if controller.updateGFX then
    table.insert(gfxUpdates, controller.updateGFX)
  end
  if controller.debugDraw then
    table.insert(debugDraws, controller.debugDraw)
  end
  if controller.beamBroken then
    table.insert(beamBrokens, controller.beamBroken)
  end
  if controller.beamDeformed then
    table.insert(beamDeformeds, controller.beamDeformed)
  end
  if controller.onCouplerFound then
    table.insert(couplerFoundEvents, controller.onCouplerFound)
  end
  if controller.onCouplerAttached then
    table.insert(couplerAttachedEvents, controller.onCouplerAttached)
  end
  if controller.onCouplerDetached then
    table.insert(couplerDetachedEvents, controller.onCouplerDetached)
  end
  if controller.onGameplayEvent then
    table.insert(gameplayEvents, controller.onGameplayEvent)
  end
end

local function updateFunctionCounts()
  physicsUpdateCount = #physicsUpdates
  wheelsIntermediateUpdateCount = #wheelsIntermediateUpdates
  gfxUpdateCount = #gfxUpdates
  debugDrawCount = #debugDraws
  beamBrokenCount = #beamBrokens
  beamDeformedCount = #beamDeformeds
  couplerFoundEventCount = #couplerFoundEvents
  couplerAttachedEventCount = #couplerAttachedEvents
  couplerDetachedEventCount = #couplerDetachedEvents
  gameplayEventCount = #gameplayEvents

  M.update = physicsUpdateCount > 0 and update or nop
  M.updateWheelsIntermediate = wheelsIntermediateUpdateCount > 0 and updateWheelsIntermediate or nop
  M.updateGFX = gfxUpdateCount > 0 and updateGFX or nop
  M.debugDraw = debugDrawCount > 0 and debugDraw or nop
  M.beamBroke = beamBrokenCount > 0 and beamBroke or nop
  M.beamDeformed = beamDeformedCount > 0 and beamDeformed or nop
  M.onCouplerFound = couplerFoundEventCount > 0 and onCouplerFound or nop
  M.onCouplerAttached = couplerAttachedEventCount > 0 and onCouplerAttached or nop
  M.onCouplerDetached = couplerDetachedEventCount > 0 and onCouplerDetached or nop
  M.onGameplayEvent = gameplayEventCount > 0 and onGameplayEvent or nop
end

local function cacheAllControllerFunctions()
  physicsUpdates = {}
  wheelsIntermediateUpdates = {}
  gfxUpdates = {}
  beamBrokens = {}
  couplerAttachedEvents = {}
  couplerDetachedEvents = {}
  couplerFoundEvents = {}
  gameplayEvents = {}
  debugDraws = {}

  for _, controller in ipairs(sortedControllers) do
    cacheControllerFunctions(controller)
  end

  updateFunctionCounts()
end

local function initSecondStage()
  for _, v in pairs(sortedControllers) do
    if v.initSecondStage then
      v.initSecondStage()
    end
  end

  cacheAllControllerFunctions()
end

local function initLastStage()
  for _, v in pairs(sortedControllers) do
    if v.initLastStage then
      v.initLastStage()
    end
  end

  cacheAllControllerFunctions()
end

local function initSounds()
  for _, v in pairs(sortedControllers) do
    if v.initSounds then
      v.initSounds()
    end
  end

  cacheAllControllerFunctions()
end

local function reset()
  for _, v in pairs(sortedControllers) do
    if not v.reset then
      v.init(controllerJbeamData[v.name])
    end
  end
end

local function resetSecondStage()
  for _, v in pairs(sortedControllers) do
    if v.reset then
      v.reset()
    elseif v.initSecondStage then
      v.initSecondStage()
    end
  end

  cacheAllControllerFunctions()
end

local function resetLastStage()
  for _, v in pairs(sortedControllers) do
    if v.resetLastStage then
      v.resetLastStage()
    end
  end

  cacheAllControllerFunctions()
end

local function resetSounds()
  for _, v in pairs(sortedControllers) do
    if v.resetSounds then
      v.resetSounds()
    end
  end

  cacheAllControllerFunctions()
end

local function onDeserialize(data)
  if not data or type(data) ~= "table" then
    return
  end

  for name, controllerData in pairs(data) do
    if name and loadedControllers[name] and loadedControllers[name].deserialize then
      loadedControllers[name].deserialize(controllerData)
    end
  end
end

local function onSerialize()
  local data = {}
  for _, controller in ipairs(sortedControllers) do
    if controller.serialize then
      data[controller.name] = controller.serialize()
    end
  end
  return data
end

M.init = init
M.reset = reset
M.resetSecondStage = resetSecondStage
M.initSecondStage = initSecondStage
M.resetLastStage = resetLastStage
M.initLastStage = initLastStage
M.initSounds = initSounds
M.resetSounds = resetSounds

M.cacheAllControllerFunctions = cacheAllControllerFunctions

M.setFreeze = setFreeze --TBD in the future, use onGameplayEvent with freeze param instead

M.update = nop
M.updateWheelsIntermediate = nop
M.updateGFX = nop
M.beamBroke = nop
M.beamDeformed = nop
M.debugDraw = nop

M.onCouplerFound = nop
M.onCouplerAttached = nop
M.onCouplerDetached = nop

M.onGameplayEvent = nop

M.getController = getController
M.getAllControllers = getAllControllers
M.getControllerSafe = getControllerSafe
M.getControllersByType = getControllersByType

M.settingsChanged = settingsChanged
M.onDeserialize = onDeserialize
M.onSerialize = onSerialize

return M
