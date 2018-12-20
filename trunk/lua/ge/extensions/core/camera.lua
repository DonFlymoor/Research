-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.state = {} -- unused ?

local cameraFiles = {}
local sharedCameras = { --[[collision=false,--]] gameengine=false, transition=false, trackir=false, observer=false } -- same instances are used regardless of currently focused vehicle
local lastVehicleId = nil -- used to detect vehicle switches.
local pendingTrigger = nil
local vehicleData    = {} -- {   vid1={jbeamConfig=foo, cameras={orbit=C, ...}},     vid2={jbeamConfig=foo, cameras={orbit=C, ...}}, ...   }
local vehicleDataOld = {} -- {   vid1={jbeamConfig=foo, cameras={orbit=C, ...}},     vid2={jbeamConfig=foo, cameras={orbit=C, ...}}, ...   }
local requestedCam = {}   -- {name=foo, customData=bar}
local configuration = {}  -- {   {name=foo, enabled=true},  {name=bar, enabled=false},    ...      }
local pendingSerializationData = nil
local currentVersion = 1
local observerCamObject = false
local ignoreVehicleReset = false

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
    local visible = vdata.cameras[v.name] and not vdata.cameras[v.name].hidden
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
  be:executeJS('HookManager.trigger("CameraConfigChanged", ' .. jsonEncode({cameraConfig=config, focusedCamId=vdata.focusedCamId}) .. ')')
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
  be:executeJS('HookManager.trigger("CameraMode", ' .. jsonEncode({ mode = camConfig.name}) .. ')')
  updateOptionsUI(vdata)
end

local function clearInputs()
  MoveManager.rollRight = 0;
  MoveManager.rollLeft = 0;
  MoveManager.pitchUp = 0;
  MoveManager.pitchDown = 0;
  MoveManager.yawRight = 0;
  MoveManager.yawLeft = 0;
  MoveManager.zoomIn = 0;
  MoveManager.zoomOut = 0;
end

local function changeOrder (camId, offset)
  local player = 0
  local veh = be:getPlayerVehicle(player) --TODO refactor this vdata stuff, please.....
  if not veh then return end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return end
  -- iterate through cameras, skipping hidden cams
  local newIdx = camId
  local n = #configuration
  for i = 1, n do
    newIdx = clamp(newIdx + offset, 1, n)
    if not configuration[newIdx].hidden then break end
  end
  if newIdx == camId then return end

  -- move camera to the calculated new index
  configuration[camId], configuration[newIdx] = configuration[newIdx], configuration[camId]

  -- update the focused camera too
  if vdata.focusedCamId == newIdx then
    vdata.focusedCamId = camId
  elseif vdata.focusedCamId == camId then
    vdata.focusedCamId = newIdx
  end

  updateOptionsUI(vdata)
end

local function toggleEnabledCameraById(camId)
  if camId > #configuration then return end
  if camId < 1 then return end
  local player = 0
  local veh = be:getPlayerVehicle(player) --TODO refactor this vdata stuff, please.....
  if not veh then return end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return end
  configuration[camId].enabled = not configuration[camId].enabled
  updateOptionsUI(vdata)
end

local function _setCamera(vdata, newCamId)
  -- satefy checks
  if newCamId > #configuration then newCamId = 1 end
  if newCamId < 1 then newCamId = 1 end

  -- tell cameras about the focus change
  local success = false
  local camConfig = configuration[newCamId]
  if camConfig then
    local newCam = vdata.cameras[camConfig.name]
    if newCam then
      newCam.focused = true
      if type(newCam.onCameraChanged) == 'function' then
        newCam:onCameraChanged(true)
      end
      success = true
    end
  end
  if success then
    log("D","", "Camera switched to "..dumps(camConfig.name))
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

    -- set it actually. This is the only function that is allowed to change focusedCamId directly
    vdata.focusedCamId = newCamId
    clearInputs()

    local camName = configuration[vdata.focusedCamId].name
    extensions.hook('onCameraModeChanged', camName)

    updateAppsUI(vdata)
  else
    log("D","", "Camera not switched to anything")
  end
  return success
end

local function _setCameraByName(vdata, name, withTransition)
  for idx, camConfig in ipairs(configuration) do
    local camName = camConfig.name
    if camName == name then
      local success = _setCamera(vdata, idx)
      if withTransition then
        sharedCameras.transition:start()
      end
      return success
    end
  end
  log('E', 'core_camera.setCameraByName', 'camera not found: ' .. tostring(name))
  return false
end

local function setCameraById(camId)
  if camId > #configuration then return end
  if camId < 1 then return end
  local player = 0
  local veh = be:getPlayerVehicle(player) --TODO refactor this vdata stuff, please.....
  if not veh then return end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return end
  _setCamera(vdata, camId)
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

  local camConfig = configuration[vdata.focusedCamId]
  if not camConfig then return end
  if camConfig.name == "driver" then return true end -- FIXME: quick fix for one-frame delay in camPosition vs vehicleposition, falling out of cockpit at speed
  if camConfig.name == "onboard.hood" then return false end -- FIXME: quick fix for one-frame delay in camPosition vs vehicleposition, falling out of cockpit at speed

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
  return (vehicleData[vid] or vehicleDataOld[vid]).cameras
  -- return vehicleDataOld[vid].cameras
end

local function getDriverData(player)
  local camNodeID = 0
  local rightHandDrive = false
  local veh = be:getPlayerVehicle(player)
  if not veh then return camNodeID, rightHandDrive end
  local vdata = vehicleData[veh:getID()]
  if not vdata then return camNodeID, rightHandDrive end
  for k,v in pairs(vdata.cameras or {}) do
    if k == "onboard.driver" then
      camNodeID = v.camNodeID
      rightHandDrive = v.rightHandCamera or false -- convert nil to false
      break
    end
  end
  return camNodeID, rightHandDrive
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
  settings.setValue('cameraConfig', jsonEncode({ version=currentVersion, data=configuration }))
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

  local function initCam(camerasOld, vdata, camConfig, camFile, camName)
    if camName ~= "onboard.driver" and string.lower(camName) == "onboard.driver" then
      log("W", "", "Possibly incorrect camera name '"..camName.."' (rename to 'onboard.driver'?)")
    end
    local obj = tableMerge(deepcopy(vdata.jbeamConfig.common), deepcopy(camConfig))
    if #camConfig > 0 then -- if the jbeamConfig contains a numbered list (of cameras or whatever else), merge them too
      for k,v in ipairs(camConfig) do obj[k] = v end
    end
    local camera = camerasOld[camName]
    if camera and type(camera.update) ~= "function" then --FIXME, this should never happen, but deserialization is removing the functions, making the deserialized cameras useless
      log("D", "", "FIXME Unable to correctly reuse the '"..camName.."' camera. Losing state and reloading from scratch instead...")
      camera = nil
    end
    if camera == nil then
      camera = require(cameraFiles[camFile])(obj)
    else
      camera = tableMerge(camera, obj)
      ignoreVehicleReset = true
      if type(camera.onVehicleCameraConfigChanged) == 'function' then
        camera:onVehicleCameraConfigChanged()
      end
    end
    camera.hidden = camera.hidden == true -- convert to boolean
    camera.focused = false -- make sure its set to inactive on start
    vdata.cameras[camName] = camera
    return not camera.hidden
  end
  local function initCamSingle(camerasOld, vdata, camFile)
    return initCam(camerasOld, vdata, vdata.jbeamConfig[camFile] or {}, camFile, camFile)
  end
  local function initCamMultiple(camerasOld, vdata, camFile)
    local ret = false
    for k,v in pairs(vdata.jbeamConfig[camFile] or {}) do
      if initCam(camerasOld, vdata, v, camFile, camFile.."."..v.name) then ret = true end
    end
    return ret
  end

  local usableCamFound = false
  local camerasOld = vdata.cameras or {}
  vdata.cameras = {}
  for camFile, r in pairs(cameraFiles) do
    local multicams = { "onboard" }
    if tableFindKey(multicams, camFile) then
      if initCamMultiple(camerasOld, vdata, camFile) then usableCamFound = true end
    else
      if initCamSingle  (camerasOld, vdata, camFile) then usableCamFound = true end
    end
  end

  if not tableFindValue(tableKeys(vdata.cameras), "onboard.driver") then
    vdata.cameras.driver = nil -- there's no driver data to feed the driver cam, so remove it
  end
  -- no camera found? then add a default camera
  if not usableCamFound then
    log('E', 'camera', 'No usable camera found. Using a default camera placeholder')
    vdata.cameras.orbit = require(cameraFiles['orbit'])({mode = 'center', refNodes = { ref = 0, left = 1, back = 2 }})
  end


  -- initial camera config
  local initialConfiguration = {
     {name="orbit"}
    ,{name="driver"}
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
    savedConfiguration = jsonDecode(savedConfiguration)
    -- if user settings version is good, go ahead and use it
    if savedConfiguration and (savedConfiguration.version or 0) >= currentVersion then
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

  --if not sharedCameras.collision  then sharedCameras.collision  = require(cameraFiles[  'collision'])() end
  if not sharedCameras.gameengine then sharedCameras.gameengine = require(cameraFiles[ 'gameengine'])() end
  if not sharedCameras.transition then sharedCameras.transition = require(cameraFiles[ 'transition'])() end
  if not sharedCameras.trackir    then sharedCameras.trackir    = require(cameraFiles[    'trackir'])() end

  -- 1st try: we got a saved request, honour it before anything else
  local cameraSet = false
  if requestedCam[vid] then
    cameraSet = _setCameraByName(vdata, requestedCam[vid].name)
    if cameraSet and vdata.cameras[requestedCam[vid].name].setCustomData then
      vdata.cameras[requestedCam[vid].name]:setCustomData( requestedCam[vid].customData )
    end
    requestedCam[vid] = nil
  end

  -- 2nd try: let's continue using the previous cam (which may have disappeared if we replaced the vehicle)
  if not cameraSet and vdata_old then
    local camId = vdata_old.focusedCamId
    cameraSet = _setCamera(vdata, camId)
  end

  -- 3rd try: let's find the first 'enabled' camera and use it (i.e. the default camera)
  if not cameraSet then
    for k,v in pairs(configuration) do
      if v.enabled and vdata.cameras[v.name] and not vdata.cameras[v.name].hidden then
        cameraSet = _setCamera(vdata, k)
        if cameraSet then break end
      end
    end
  end

  -- 4th try: let's find the first 'visible' camera and use it
  if not cameraSet then
    for k,v in pairs(configuration) do
      if vdata.cameras[v.name] then
        cameraSet = _setCamera(vdata, k)
        if cameraSet then break end
      end
    end
  end

  -- 5th try: panic and don't keep calm
  if not cameraSet then
    log("E", "", "Unable to find a single usable camera, not even 'orbit' fallback. All bets are off from this point on")
  end

  vehicleDataOld[vid] = nil
  updateOptionsUI(vdata)
  settings.setValue('cameraConfig', jsonEncode({ version=currentVersion, data=configuration }))
end

local function onVehicleCameraConfigChanged(vid, jbeamConfig)
  local veh = be:getObjectByID(vid)
  if not veh then return end

  if vehicleData[vid] and tableSize(vehicleData[vid]) > 0 and not vehicleDataOld[vid] then
    vehicleDataOld[vid] = deepcopy(vehicleData[vid])
    --vehicleData[vid] = {}
  end

  if not vehicleData[vid] then vehicleData[vid] = {} end
  vehicleData[vid].jbeamConfig = jbeamConfig
  --vehicleData[vid].cameras = {}
  if not vehicleData[vid].jbeamConfig then vehicleData[vid].jbeamConfig = {} end
  if not vehicleData[vid].cameras then vehicleData[vid].cameras = {} end

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

local function onPreRender(dtReal, dtSim, dtRaw)
  local player = 0
  local veh = be:getPlayerVehicle(player)
  if not veh then return end
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

  if commands.isFreeCamera(player) then return end -- check for freecam *after* we make sure we got vehicle config data, which may be used on updatedSettings callbacks and other stuff
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
  if settings.getValue('cameraCollision', false) then
    --sharedCameras.collision:update(data)
  end
  sharedCameras.gameengine:update(data) -- send the final data to c++

  MoveManager.yawRelative = 0
  MoveManager.pitchRelative = 0
  MoveManager.rollRelative = 0
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
    local visible = vdata.cameras[m.name] and not vdata.cameras[m.name].hidden
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
      be:executeJS('HookManager.trigger("CameraMode", ' .. jsonEncode({ mode = 'observer'}) .. ')')
      extensions.hook('onCameraModeChanged', 'observer')
    else
      log('E', 'camera', 'camera not found for trigger: ' .. tostring(trigger.cameraOnEnter))
    end
  end
end

local function resetCamera(player)
  clearInputs()
  return proxy_PID(player, 'reset')
end

local function lookBack(player)
  return proxy_PID(player, 'lookback')
end

local function hotkey(player, hotkeyid, modifier)
  return proxy_PID(player, 'hotkey', hotkeyid, modifier)
end

local lastFilter = FILTER_KBD
local function getLastFilter() return lastFilter end
local function rotate_yaw_left (val, filter) MoveManager.yawLeft  = val; lastFilter = filter end
local function rotate_yaw_right(val, filter) MoveManager.yawRight = val; lastFilter = filter end
local function rotate_yaw(val, filter)
  lastFilter = filter
  if val > 0 then
    MoveManager.yawRight = val;
    MoveManager.yawLeft = 0;
  else
    MoveManager.yawLeft = -val;
    MoveManager.yawRight = 0;
  end
end
local function rotate_pitch_up  (val, filter) MoveManager.pitchUp   = val; lastFilter = filter end
local function rotate_pitch_down(val, filter) MoveManager.pitchDown = val; lastFilter = filter end
local function rotate_pitch(val, filter)
  lastFilter = filter
  if val > 0 then
    MoveManager.pitchUp = val
    MoveManager.pitchDown = 0
  else
    MoveManager.pitchDown = -val
    MoveManager.pitchUp = 0
  end
end
local function cameraZoom(val)
  if val > 0 then
    MoveManager.zoomIn = val
    MoveManager.zoomOut = 0
  else
    MoveManager.zoomIn = 0
    MoveManager.zoomOut = -val
  end
end

-- rmb mouse camera
local function rotate_yaw_relative  (val) MoveManager.yawRelative   = MoveManager.yawRelative   + getCameraFov() * val / 4500 end
local function rotate_pitch_relative(val) MoveManager.pitchRelative = MoveManager.pitchRelative + getCameraFov() * val / 4500 end
-- Movement Keys
local function moveleft    (val) MoveManager.left     = val end
local function moveright   (val) MoveManager.right    = val end
local function moveforward (val) MoveManager.forward  = val end
local function movebackward(val) MoveManager.backward = val end
local function moveup      (val) MoveManager.up       = val end
local function movedown    (val) MoveManager.down     = val end

-- 3d spacemouse support :)
local absRotateAxisFactor= 0.0003
local yawTemp   = 0
local rollTemp  = 0
local pitchTemp = 0
local function   yawAbs(val) MoveManager.yawRelative   = (  yawTemp - val) * absRotateAxisFactor;   yawTemp = val end
local function  rollAbs(val) MoveManager.rollRelative  = ( rollTemp - val) * absRotateAxisFactor;  rollTemp = val end
local function pitchAbs(val) MoveManager.pitchRelative = (pitchTemp - val) * absRotateAxisFactor; pitchTemp = val end
local absTranslateAxisFactor = 0.01
local xAxisAbsTemp = 0
local yAxisAbsTemp = 0
local zAxisAbsTemp = 0
local function xAxisAbs(val) local tmp = (xAxisAbsTemp - val) * absTranslateAxisFactor; MoveManager.absXAxis = tmp; xAxisAbsTemp = val end
local function yAxisAbs(val) local tmp = (yAxisAbsTemp - val) * absTranslateAxisFactor; MoveManager.absYAxis = tmp; yAxisAbsTemp = val end
local function zAxisAbs(val) local tmp = (zAxisAbsTemp - val) * absTranslateAxisFactor; MoveManager.absZAxis = tmp; zAxisAbsTemp = val end


-- PID end

local function onVehicleResetted(...)
  if ignoreVehicleReset then
    ignoreVehicleReset = false
    return
  end

  resetCameraByID(...)
end

local function onMouseLocked(locked)
  local player = 0
  if commands.isFreeCamera(player) then return end
  return proxy_PID(player, 'mouseLocked', locked)
end

local function onDespawnObject(id, isReloading)
  -- cleaning up some things
  if isReloading == false then
    vehicleData[id]    = nil
    vehicleDataOld[id] = nil
  end
end

local function onSettingsChanged()
  for j,vdata in pairs(vehicleData) do
    for k,m in pairs(vdata.cameras) do
      local camera = vdata.cameras[k]
      if type(camera.onSettingsChanged) == 'function' then
        camera:onSettingsChanged()
      end
    end
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

  pendingSerializationData = nil
end


-- callbacks
M.onPreRender = onPreRender -- just update the camera right before the rendering
M.onTrigger = onTrigger
M.onExtensionLoaded = onExtensionLoaded
M.onDespawnObject = onDespawnObject
M.onSettingsChanged = onSettingsChanged
M.onVehicleResetted = onVehicleResetted
M.onScenarioRestarted = onScenarioRestarted
M.onScenarioChange = onScenarioChange
M.onMouseLocked = onMouseLocked

-- internal things
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

-- interface for the vehicle Lua
M.onVehicleCameraConfigChanged = onVehicleCameraConfigChanged

-- functions used by other GE lua code
M.clearInputs = clearInputs
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
M.setById = setCameraById
M.toggleEnabledById = toggleEnabledCameraById
M.setBySlotId = setBySlotId
M.changeOrder = changeOrder
M.getCameraDataById = getCameraDataById
M.getDriverData = getDriverData
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
M.rotate_pitch = rotate_pitch
M.rotate_pitch_up = rotate_pitch_up
M.rotate_pitch_down = rotate_pitch_down
M.rotate_yaw = rotate_yaw
M.rotate_yaw_left = rotate_yaw_left
M.rotate_yaw_right = rotate_yaw_right
M.cameraZoom = cameraZoom
M.rotate_yaw_relative = rotate_yaw_relative
M.rotate_pitch_relative = rotate_pitch_relative
M.yawAbs = yawAbs
M.rollAbs = rollAbs
M.pitchAbs = pitchAbs
M.moveleft     = moveleft
M.moveright    = moveright
M.moveforward  = moveforward
M.movebackward = movebackward
M.moveup       = moveup
M.movedown     = movedown
M.getLastFilter = getLastFilter

return M
