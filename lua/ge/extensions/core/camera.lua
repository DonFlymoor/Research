-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.state = {} -- unused ?
--M.freeCam = false

local cameraFiles = {}
local sharedCameras = { gameengine=false, transition=false, trackir=false, observer=false } -- same instances are used regardless of currently focused vehicle
local lastVehicleId = nil -- used to detect vehicle switches.
local pendingTrigger = nil
local vehicleData    = {} -- {   vid1={jbeamConfig=foo, cameras={orbit=C, ...}},     vid2={jbeamConfig=foo, cameras={orbit=C, ...}}, ...   }
local vehicleDataOld = {} -- {   vid1={jbeamConfig=foo, cameras={orbit=C, ...}},     vid2={jbeamConfig=foo, cameras={orbit=C, ...}}, ...   }
local requestedCam = {}   -- {name=foo, customData=bar}
local configuration = {}  -- {   {name=foo, enabled=true},  {name=bar, enabled=false},    ...      }
local pendingSerializationData = nil
local currentVersion = 1
local observerCamObject = false

-- store camera filenames, reload observer camera
local function onExtensionLoaded()
  local directory = '/lua/ge/extensions/core/cameraModes'
  local camFind = FS:findFilesByPattern(directory, "*.lua", 2, true, true)
  if #camFind then
    for _,c in ipairs(camFind) do
      local camMode = c:gsub(directory.."/", ""):sub(1,-5)
      if c and c ~= "" then
        cameraFiles[camMode] = 'core/cameraModes/' .. camMode
      end
    end
  else
    log('E', 'camera', 'no camera dir found: ' .. tostring(directory))
  end
  sharedCameras.observer = require(cameraFiles['observer'])()
end

-- gather data used by Options > Cameras and other code
local function getExtendedConfig(vdata)
  local config = deepcopy(configuration)
  local slotId = 1
  for _, v in ipairs(config) do
    local visible = vdata.cameras[v.name] and vdata.cameras[v.name].hidden ~= true
    v.hidden = not visible
    -- set the binding camera number (keys 1 to 9, for example)
    if visible then
      v.slotId = slotId
      slotId = slotId + 1
    end
  end
  return config
end

-- send data to Options > Cameras menu
local function updateOptionsUI(vdata)
  local config = getExtendedConfig(vdata)
  be:executeJS('HookManager.trigger("CameraConfigChanged", ' .. encodeJson({cameraConfig=config, focusedCamId=vdata.focusedCamId}) .. ')')
end

-- request/send data to Options > Cameras menu
local function requestConfig()
  local player = 0
  local veh = be:getPlayerVehicle(player)
  if not veh then return nil end
  local vdata = vehicleData[veh:getID()]
  updateOptionsUI(vdata)
end

-- send ddata to UI apps and other things
local function updateAppsUI(vdata)
  local camConfig = configuration[vdata.focusedCamId]
  if not camConfig then return end
  -- tell JS for hiding the apps in cockpit for example
  be:executeJS('HookManager.trigger("CameraMode", ' .. encodeJson({ mode = camConfig.name}) .. ')')
  updateOptionsUI(vdata)
end

local function _setCamera(vdata, newCamId)
  -- satefy checks
  if newCamId > #configuration then newCamId = 1 end
  if newCamId < 1 then newCamId = 1 end

  -- tell cameras about the focus change
  local oldCamConfig = configuration[vdata.focusedCamId]
  if oldCamConfig then
    local oldCam = vdata.cameras[oldCamConfig.name]
    if oldCam then
      oldCam.focused = false
      if type(oldCam.onCameraChanged) == 'function' then
        oldCam:onCameraChanged(false)
      end
    end
  end
  local camConfig = configuration[newCamId]
  if camConfig then
    local newCam = vdata.cameras[camConfig.name]
    if newCam then
      newCam.focused = true
      if type(newCam.onCameraChanged) == 'function' then
        newCam:onCameraChanged(true)
      end
    end
  end

  -- set it actually. This is the only function that is allowed to change focusedCamId directly
  vdata.focusedCamId = newCamId
  TorqueScript.eval("clearCameraRotationalSpeeds();")

  local camName = configuration[vdata.focusedCamId].name
  extensions.hook('onCameraModeChanged', camName)

  updateAppsUI(vdata)
end

local function _setCameraByName(vdata, name, withTransition)
  for idx, camConfig in ipairs(configuration) do
    local camName = camConfig.name
    if camName == name then
      _setCamera(vdata, idx)
      if withTransition then
        sharedCameras.transition:start()
      end
      return true
    end
  end
  log('E', 'core_camera.setCameraByName', 'camera not found: ' .. tostring(name))
  return false
end

local function setCameraByName(player, name, withTransition, customData)
  local veh = be:getPlayerVehicle(player)
  if not veh then
    log('E', 'core_camera.setCameraByName', 'unable to find player: ' .. tostring(player))
    return false
  end

  local vdata = vehicleData[veh:getID()]
  if not vdata then
    -- store the request for when we get the data
    requestedCam[veh:getID()] = { name = name, customData = customData }
    return false
  end

  local res = _setCameraByName(vdata, name, withTransition, customData)
  if res and vdata.cameras[name].setCustomData then
    vdata.cameras[name]:setCustomData( customData )
  end
  return res
end

local function isCameraInside(player)
  local veh = be:getPlayerVehicle(player)
  if not veh then return false end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return false end

  local camPos = getCameraPosition()
  local oobb = veh:getSpawnWorldOOBB()
  if not oobb:isContained(camPos) then return false end

  local calc_camera = function(name)
    if not vdata.cameras[name] then return false end
    local driverNode = vdata.cameras[name].camNodeID
    local driverPos  = vec3(veh:getNodePosition(driverNode)) + veh:getPosition()
    return (driverPos - camPos):length() < 0.6
  end

  return calc_camera("onboard.driver") or calc_camera("onboard.rider")
end

local function getCameraDataById(vid)
  return vehicleData[vid].cameras
end

local function getActiveCamName(player)
  local veh = be:getPlayerVehicle(player)
  if not veh then return nil end

  local camName = nil
  local vdata = vehicleData[veh:getID()]
  if vdata then
    camName = configuration[vdata.focusedCamId].name
  elseif requestedCam[veh:getID()] then
    camName = requestedCam[veh:getID()].name
  else
    log('W', 'core_camera.getActiveCamName', 'unable to find VData for player ' .. tostring(player))
    return nil
  end

  return camName
end

local function updateUIMessage(player)
  local veh = be:getPlayerVehicle(player)
  if not veh then return nil end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return end
  local camName = configuration[vdata.focusedCamId].name
  if not camName then return end
  ui_message({txt='ui.camera.switched', context={name=camName}}, 10, 'cameramode')
end


local function setConfiguration(newConfig, newCamId)
  local player = 0
  local veh = be:getPlayerVehicle(player)
  if not veh then return nil end
  local vdata = vehicleData[veh:getID()]
  configuration = {}
  for k,v in ipairs(newConfig) do
    table.insert(configuration, { name=v.name, enabled=v.enabled })
  end
  if commands.isFreeCamera(player) then
    commands.setGameCamera()
  end
  _setCamera(vdata, newCamId)
  updateUIMessage(player)
  updateOptionsUI(vdata)
  settings.setValue('cameraConfig', encodeJson({ version=currentVersion, data=configuration }))
end

local function setBySlotId(player, slotId)
  local veh = be:getPlayerVehicle(player)
  if not veh then return nil end
  local vdata = vehicleData[veh:getID()]
  local config = getExtendedConfig(vdata)
  for k,v in ipairs(config) do
    if v.slotId == slotId then
      if commands.isFreeCamera(player) then
        commands.setGameCamera()
      end
      setConfiguration(config, k)
      return
    end
  end
end

local function startTransition()
  sharedCameras.transition:start()
end

local function processVehicleCameraConfigChanged(vid)
  local veh = be:getObjectByID(vid)
  if not veh then return end

  local vdata     = vehicleData[vid]
  local vdata_old = vehicleDataOld[vid]

  local function initCam(vdata, camConfig, camFile, camName)
    local obj = tableMerge(deepcopy(vdata.jbeamConfig.common), deepcopy(camConfig))
    -- if the jbeamConfig contains a numbered list (of cameras or whatever else), merge them too
    if #camConfig > 0 then
      for k,v in ipairs(camConfig) do obj[k] = v end
    end
    obj.otherCameras = deepcopy(vdata.jbeamConfig)
    local camera = require(cameraFiles[camFile])(obj)
    camera.focused = false -- make sure its set to inactive on start
    vdata.cameras[camName] = camera
    return camera.hidden ~= true
  end
  local function initCamSingle(vdata, camFile)
    return initCam(vdata, vdata.jbeamConfig[camFile] or {}, camFile, camFile)
  end
  local function initCamMultiple(vdata, camFile)
    local ret = false
    for k,v in pairs(vdata.jbeamConfig[camFile] or {}) do
      if initCam(vdata, v, camFile, camFile.."."..v.name) then ret = true end
    end
    return ret
  end

  --local tmp = settings.getValue('cameraLoadCustomModes')
  local usableCamFound = false
  for camFile, r in pairs(cameraFiles) do
    local multicams = { "onboard" }
    if tableFindKey(multicams, camFile) then
      if initCamMultiple(vdata, camFile) then usableCamFound = true end
    else
      if initCamSingle  (vdata, camFile) then usableCamFound = true end
    end
  end

  -- no camera found? then add a default camera
  if not usableCamFound then
    log('E', 'camera', 'No usable camera found. Using a default camera placeholder')
    vdata.cameras.orbit = require(cameraFiles['orbit'])({mode = 'center', refNodes = { ref = 0, left = 1, back = 2 }})
  end


  -- initial camera config
  local initialConfiguration = {
     {name="orbit"}
    ,{name="onboard.driver"}
    ,{name="onboard.hood"}
    ,{name="external"}
    ,{name="relative"}
    ,{name="chase"}
  }
  local savedConfiguration = settings.getValue('cameraConfig')
  if savedConfiguration and savedConfiguration ~= "" then
    -- fix INI values that passed through javascript (e.g. when opening Options menu)
    savedConfiguration = savedConfiguration:gsub("'",'"')
    -- and then deserialize, so we can follow the user settings
    savedConfiguration = readJsonData(savedConfiguration)
    -- if user settings version is good, go ahead and use it
    if (savedConfiguration.version or 0) >= currentVersion then
      initialConfiguration = savedConfiguration.data
    end
  end

  -- fill pre-configured cameras (even if it's a disabled/unknown camera)
  configuration = {}
  for k,v in ipairs(initialConfiguration) do
    local enabled = v.enabled
    if enabled == nil then
      enabled = true
      local m = vdata.cameras[v.name]
      if m then
        enabled = m.disabledByDefault ~= true
      end
    end
    table.insert(configuration, {name=v.name, enabled=enabled})
  end

  -- append non-configured cameras
  local renaminingCamNames = {}
  for name, m in pairs(vdata.cameras) do
    local configured = false
    for _,v in ipairs(configuration) do
      if v.name == name then configured = true end
    end
    if not configured then
      table.insert(renaminingCamNames, name)
    end
  end

  -- now, a bit more complex: order the remaining cameras with their order number (if present) or jbeam order
  while #renaminingCamNames > 0 do
    local orderMin = 99999
    local lowestOrderId = nil
    for k, name in ipairs(renaminingCamNames) do
      -- locate idx with the minimum order value
      local m = vdata.cameras[name]
      if m.order then
        if type(m.order) == 'number' then
          if m.order < orderMin then
            orderMin = m.order
            lowestOrderId = k
          end
        else
          log("E", "", "Incorrectly defined camera, 'order' field is not numeric: "..dumps(type(order)))
        end
      end
    end
    if not lowestOrderId then
      -- no ordering? simply take first one then
      lowestOrderId = 1
    end
    local name = renaminingCamNames[lowestOrderId]
    local enabled = vdata.cameras[name].disabledByDefault ~= true
    table.insert(configuration, {name=name, enabled=enabled})
    table.remove(renaminingCamNames, lowestOrderId)
  end

  local function _reloadModule(module)
    if module and type(module.reloaded) == 'function' then
      module:reloaded()
    end
    return module
  end

  sharedCameras.gameengine = _reloadModule(sharedCameras.gameengine) or require(cameraFiles['gameengine'])()
  sharedCameras.transition = _reloadModule(sharedCameras.transition) or require(cameraFiles['transition'])()
  sharedCameras.trackir    = _reloadModule(sharedCameras.trackir)    or require(cameraFiles[   'trackir'])()

  -- default focused camera
  local newCamId = 1
  for k,v in pairs(configuration) do
    if v.enabled and vdata.cameras[v.name] then
      newCamId = k
      break
    end
  end
  if vdata_old then
    newCamId = vdata_old.focusedCamId
  end

  -- we got a saved request, serve this no matter what
  local cameraSet = false
  if requestedCam[vid] then
    cameraSet = _setCameraByName(vdata, requestedCam[vid].name)
    if cameraSet and vdata.cameras[requestedCam[vid].name].setCustomData then
      vdata.cameras[requestedCam[vid].name]:setCustomData( requestedCam[vid].customData )
    end
    requestedCam[vid] = nil
  end

  if not cameraSet then
    _setCamera(vdata, newCamId)
  end

  vehicleDataOld[vid] = nil
  updateOptionsUI(vdata)
  settings.setValue('cameraConfig', encodeJson({ version=currentVersion, data=configuration }))
end

local function onVehicleCameraConfigChanged(vid, jbeamConfig)
  local veh = be:getObjectByID(vid)
  if not veh then return end

  if vehicleData[vid] and tableSize(vehicleData[vid]) > 0 and not vehicleDataOld[vid] then
    vehicleDataOld[vid] = deepcopy(vehicleData[vid])
    vehicleData[vid] = {}
  end

  vehicleData[vid] = {
    jbeamConfig = jbeamConfig,
    cameras = {},
  }

  processVehicleCameraConfigChanged(vid)
end

local function vehicleChanged(oldVehId, newVehId)
  if oldVehId then
    -- disable all cameras
    local vdata = vehicleData[oldVehId]
    if vdata then
      for k, m in pairs(vdata.cameras) do
        local camera = vdata.cameras[k]
        camera.wasFocused = vdata.focused
        camera.focused = false
        if type(camera.onCameraChanged) == 'function' then
          camera:onCameraChanged(false)
        end
      end
    end
  end
  if newVehId then
    -- enable previously disabled cameras
    local vdata = vehicleData[newVehId]
    if vdata then
      for k, m in pairs(vdata.cameras) do
        local camera = vdata.cameras[k]
        if camera.wasFocused == true then
          camera.focused = true
          if type(camera.onCameraChanged) == 'function' then
            camera:onCameraChanged(true)
          end
        end
        camera.wasFocused = nil
      end
      updateAppsUI(vdata)
    end
  end
end

local function onUpdate(dtReal, dtSim, dtRaw)
  -- the free camera mode is not handled by this class yet, so do not update anything in here
  -- TODO: FIXME, requires rewrite of GE camera subsystem
  --if M.freeCam then
  --  return
  --end
  local player = 0
  local veh = be:getPlayerVehicle(player)
  if not veh then return end
  local interiorValue=nil
  local cameraPosition=nil
  local vid = veh:getID()
  local vdata = vehicleData[vid]

  if lastVehicleId ~= vid then
    vehicleChanged(lastVehicleId, vid)
    lastVehicleId = vid
  end

  if not vdata then
    veh:queueLuaCommand('requestCameraConfig()')
    return
  end

  if not configuration then return end

  if pendingSerializationData then
    M.onDeserialized(pendingSerializationData)
  end

  local data = {}
  data.pos = vec3(veh:getPosition()) -- vehicle position
  data.vid = vid
  data.dtSim = dtSim -- smoothed dt used by physics, includes time scaling
  data.dtReal = dtReal   -- smoothed gfx render dt
  data.dtRaw = dtRaw -- gfx render dt, in seconds from wall clock
  data.dt = data.dtReal
  data.speed = tonumber(getTSVar('$Camera::movementSpeed'))
  data.res = { pos       = vec3(),                 -- camera position
               targetPos = vec3(data.pos),         -- tracked target
               rot=quatFromDir(data.pos-vec3()),   -- direction towards target
               fov=60 }
  data.veh = veh

  -- update the selected camera
  if observerCamObject then
    if not sharedCameras.observer:update(data) then
      observerCamObject = false
      return
    end
  else
    -- one of the vehicle cameras
    if vdata.cameras[configuration[vdata.focusedCamId].name].update then
      vdata.cameras[configuration[vdata.focusedCamId].name]:update(data)
    else
      log("E", "", "Couldn't call update. Context: "..dumps({configuration[vdata.focusedCamId].name
      --, vdata.cameras[configuration[vdata.focusedCamId].name]
      }))
    end
    data.dt = data.dtReal -- revert back to gfx dt, in case one filter switched it
    -- filters
    sharedCameras.transition:update(data)
  end

  sharedCameras.trackir:update(data)
  sharedCameras.gameengine:update(data) -- send the final data to c++
end

local function switchCamera(player, offset)
  if commands.isFreeCamera(player) then
    commands.setGameCamera()
    updateUIMessage(player)
    return
  end
  local veh = be:getPlayerVehicle(player)
  if not veh then return end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return end

  -- this loop is supposed to skip over hidden/disabled cameras
  local newCamId = vdata.focusedCamId
  for i = 1, #configuration do
    newCamId = newCamId + offset
    if newCamId > #configuration then newCamId = 1 end
    if newCamId < 1 then newCamId = #configuration end
    local m = configuration[newCamId]
    local enabled = m.enabled
    local visible = vdata.cameras[m.name] and vdata.cameras[m.name].hidden ~= true
    if visible and enabled then break end
  end

  _setCamera(vdata, newCamId)
  updateUIMessage(player)
  sharedCameras.transition:start()
end

local function proxy_VID(vid, fct, ...)
  local veh = be:getObjectByID(vid)
  if not veh then return end

  local vdata = vehicleData[veh:getID()]
  if not vdata then return end

  local c = vdata.cameras[configuration[vdata.focusedCamId].name]
  if c and type(c[fct]) == 'function' then
    return c[fct](c, ...) -- c = self
  end
end

local function proxy_PID(player, fct, ...)
  local vid = be:getPlayerVehicleID(player)
  if vid < 0 then
    log('E', 'camera', 'player not found: ' .. tostring(player))
    return
  end
  return proxy_VID(vid, fct, ...)
end

--- VID

local function onVehicleResettedByID(vid, ...)
  return proxy_VID(vid, 'onVehicleResetted', ...)
end

local function resetCameraByID(vid, ...)
  return proxy_VID(vid, 'reset', ...)
end

local function setRotation(vid, ...)
  return proxy_VID(vid, 'setRotation', ...)
end

local function setFOV(vid, ...)
  return proxy_VID(vid, 'setFOV', ...)
end

local function setOffset(vid, ...)
  return proxy_VID(vid, 'setOffset', ...)
end

local function setup(vid, ...)
  return proxy_VID(vid, 'setup', ...)
end

local function setRefNodes(vid, ...)
  return proxy_VID(vid, 'setRefNodes', ...)
end

local function setRef(vid, ...)
  return proxy_VID(vid, 'setRef', ...)
end

local function setTargetMode(vid, ...)
  return proxy_VID(vid, 'setTargetMode', ...)
end

local function setDefaultDistance(vid, ...)
  return proxy_VID(vid, 'setDefaultDistance', ...)
end

local function setDistance(vid, ...)
  return proxy_VID(vid, 'setDistance', ...)
end

local function setMaxDistance(vid, ...)
  return proxy_VID(vid, 'setMaxDistance', ...)
end
--- PID

local function proxy_Player(fct, ...)
  local player = 0
  return proxy_PID(player, fct, ...)
end

local function onTrigger(trigger)
  if not trigger or not trigger.subjectID then return end

  local player = 0
  local vid = be:getPlayerVehicleID(player)
  local otherId = nil
  local triggerTargetOverride = nil
  if trigger.triggerOverride then
    local overrideObj = scenetree.findObject(trigger.triggerOverride)
    if overrideObj then
      otherId = overrideObj:getID()
    end
    if otherId == trigger.subjectID then
      triggerTargetOverride = trigger.triggerOverride
    end
  end

  if not vid and not otherId then return end
  if trigger.subjectID ~= vid and trigger.subjectID ~= otherId then return end

  local triggeredDuringSpawning = false
  local scenario = scenario_scenarios and scenario_scenarios.getScenario()
  if scenario and (scenario.state == nil or (scenario.state == 'pre-start' or scenario.state == 'restart')) then
    triggeredDuringSpawning = true
  end

  if getActiveCamName(player) == 'path' or triggeredDuringSpawning then
    if type(trigger.cameraOnEnter) == 'string' and string.len(trigger.cameraOnEnter) > 0 then
      local cam = scenetree.findObject(trigger.cameraOnEnter)
      if cam.showApps ~= '1' then
        guihooks.trigger('appContainer:loadLayout', "scenario_cinematic_start")
      end
      pendingTrigger = trigger
      return
    end
  end

  local vehicle = be:getObjectByID(vid)

  if trigger.event == 'exit' and type(trigger.cameraOnLeave) == 'boolean' and trigger.cameraOnLeave == true then
    observerCamObject = false
    sharedCameras.observer:setCamera(false, vehicle)
    local vdata = vehicleData[vid]
    if vdata then
      updateAppsUI(vdata)
      local camName = configuration[vdata.focusedCamId].name
      if scenario then guihooks.trigger('appContainer:loadLayout', "scenario") end
      extensions.hook('onCameraModeChanged', camName)
    end
    return
  elseif trigger.event == 'enter' and type(trigger.cameraOnEnter) == 'string' and string.len(trigger.cameraOnEnter) > 0 then
    local cam = scenetree.findObject(trigger.cameraOnEnter)
    if cam then
      observerCamObject = cam
      sharedCameras.observer:setCamera(cam, vehicle, triggerTargetOverride or cam.targetOverride)
      be:executeJS('HookManager.trigger("CameraMode", ' .. encodeJson({ mode = 'observer'}) .. ')')
      extensions.hook('onCameraModeChanged', 'observer')
    else
      log('E', 'camera', 'camera not found for trigger: ' .. tostring(trigger.cameraOnEnter))
    end
  end
end

local function resetCamera(player)
  return proxy_PID(player, 'reset')
end

local function lookBack(player)
  return proxy_PID(player, 'lookback')
end

local function hotkey(player, hotkeyid, modifier)
  return proxy_PID(player, 'hotkey', hotkeyid, modifier)
end

-- PID end

local function onVehicleResetted(...)
  -- if camera doesnt the manage the event, reset camera
  if not onVehicleResettedByID(...) then
    resetCameraByID(...)
  end
end


local function onDespawnObject(id, isReloading)
  -- cleaning up some things
  if isReloading == false then
    vehicleData[id]    = nil
    vehicleDataOld[id] = nil
  end
end

local function onSettingsChanged()
  -- resets can happen even when the data is not ready again yet resulting in storing the empty 'old' jbeamConfig
  if tableSize(vehicleData) > 0 then
    vehicleDataOld = vehicleData
    vehicleData = {}
  end
end

local function resetConfiguration()
  settings.setValue('cameraConfig', "")
  for vid, vdata in pairs(vehicleData) do
    if vdata then
      processVehicleCameraConfigChanged(vid)
      break
    end
  end
end

local function resetObserverMode()
  if observerCamObject then
    local player = 0
    local vehicle = be:getPlayerVehicle(player)
    observerCamObject = false
    sharedCameras.observer:setCamera(false, vehicle)
  end
end

local function onScenarioRestarted()
  resetObserverMode()
end

local function onScenarioChange(scenario)
  if not scenario then
    resetObserverMode()
  else
    if pendingTrigger and scenario.state == 'running' then
      log('I', 'camera', 'onScenarioChange processing pendingTrigger...')
      local tempTrigger = deepcopy(pendingTrigger)
      pendingTrigger = nil
      onTrigger(tempTrigger)
    end
  end
end

local function exitCinematicCamera()
  resetObserverMode()
end

local function onSerialize()
  local data = {}

  data.observerModeSet = observerCamObject and true
  if observerCamObject then
    data.observerCamName = observerCamObject:getField('name', '')
  end

  if lastVehicleId then
    local vehicle = be:getObjectByID(lastVehicleId)
    if vehicle then
      data.lastVehicleName = vehicle:getField('name', '')
    end
  end

  data.pendingTrigger = pendingTrigger
  data.vehicleData    = convertVehicleIdKeysToVehicleNameKeys(vehicleData)
  data.vehicleDataOld = convertVehicleIdKeysToVehicleNameKeys(vehicleDataOld)
  data.requestedCam = requestedCam

  for k,v in pairs(sharedCameras) do
    if v and type(v.onSerialize) == 'function' then
      data[k] = v:onSerialize()
    end
  end

  for vid, vdata in pairs(vehicleData) do
    if vdata then
      local camerasData = {}
      for camName,camMode in pairs(vdata.cameras) do
        if type(camMode.onSerialize) == 'function' then
          camerasData[camName] = camMode:onSerialize()
        end
      end
      local vehicle = be:getObjectByID(vid)
      if vehicle then
        local vehicleName = vehicle:getField('name', '')
        data[vehicleName] = camerasData
      end
    end
  end

  --data.freeCam = M.freeCam

  return data
end

local function onDeserialized(data)
  local veh = be:getPlayerVehicle(0)
  if not veh or not vehicleData[veh:getID()] or vehicleData[veh:getID()].focusedCamId == nil then
    pendingSerializationData = data
    return
  end

  if data.observerModeSet and data.observerCamName then
    observerCamObject = scenetree.findObject(data.observerCamName)
  end

  if data.lastVehicleName then
    local vehicle = scenetree.findObject(data.lastVehicleName)
    if vehicle then
      lastVehicleId = vehicle:getID()
    end
  end

  pendingTrigger = data.pendingTrigger
  requestedCam = data.requestedCam

  vehicleData    = convertVehicleNameKeysToVehicleIdKeys(data.vehicleData)
  vehicleDataOld = convertVehicleNameKeysToVehicleIdKeys(data.vehicleDataOld)

  for k,v in pairs(sharedCameras) do
    if data[k] then
      v:onDeserialized(data[k])
    end
  end

  for vid, vdata in pairs(vehicleData) do
    if vdata then
      local vehicle = be:getObjectByID(vid)
      if vehicle then
        local vehicleName = vehicle:getField('name', '')
        local modeData = data[vehicleName]
        for camName,camMode in pairs(vdata.cameras) do
          if type(camMode.onDeserialized) == 'function' then
            camMode:onDeserialized(modeData[camName])
          end
        end
      end
    end
  end

  --M.freeCam = data.freeCam

  pendingSerializationData = nil
end


-- callbacks
M.onUpdate = onUpdate
M.onTrigger = onTrigger
M.onExtensionLoaded = onExtensionLoaded
M.onDespawnObject = onDespawnObject
M.onSettingsChanged = onSettingsChanged
M.onVehicleResetted = onVehicleResetted
M.onScenarioRestarted = onScenarioRestarted
M.onScenarioChange = onScenarioChange

-- internal things
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

-- interface for the vehicle Lua
M.onVehicleCameraConfigChanged = onVehicleCameraConfigChanged

-- functions used by other GE lua code
M.resetCameraByID = resetCameraByID
M.setRotation = setRotation
M.setFOV = setFOV
M.setOffset = setOffset
M.setRefNodes = setRefNodes
M.setRef = setRef
M.setTargetMode = setTargetMode
M.setDefaultDistance = setDefaultDistance
M.setDistance = setDistance
M.setMaxDistance = setMaxDistance
M.startTransition = startTransition
M.setByName = setCameraByName
M.setBySlotId = setBySlotId
M.getCameraDataById = getCameraDataById
M.getActiveCamName = getActiveCamName
M.exitCinematicCamera = exitCinematicCamera
M.updateUIMessage = updateUIMessage
M.isCameraInside = isCameraInside

M.proxy_Player = proxy_Player

-- functions used by UI options
M.requestConfig = requestConfig
M.resetConfiguration = resetConfiguration
M.setConfiguration = setConfiguration

-- functions used from the input code
M.switchCamera = switchCamera
M.resetCamera = resetCamera
M.lookBack = lookBack
M.hotkey = hotkey

return M
