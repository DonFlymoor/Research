-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.devices = {}
M.update = nop

M.init = function()
    local mgr = getVirtualInputManager()
    if not mgr then
      log("E", "", "No virtual input manager found")
      return
    end
    getVirtualInputManager():resetDevices()
end

local function ensureOutgaugeExtension()
  local enabled = settings.getValue("outgaugeEnabled") == true
  local anyDevices = tableSize(M.devices) > 0
  local mustBeLoaded = enabled or anyDevices

  local cmdEnable  = 'if outgauge == nil then extensions.load  ("outgauge") end'
  local cmdDisable = 'if outgauge ~= nil then extensions.unload("outgauge") end'

  be:queueAllObjectLua(cmdDisable)
  if mustBeLoaded then
    local player = 0
    local veh = be:getPlayerVehicle(player)
    if veh then veh:queueLuaCommand(cmdEnable) end
  end
end
M.onVehicleSpawned = ensureOutgaugeExtension
M.onVehicleChanged = ensureOutgaugeExtension
M.onSettingsChanged = ensureOutgaugeExtension

-- consumer API

M.createDevice = function(productName, vidpid, axes, buttons, povs)
    local mgr = getVirtualInputManager()
    if not mgr then return end
    local info = {productName, vidpid, axes, buttons, povs}
    local deviceInstance = mgr:registerDevice(productName, vidpid, axes, buttons, povs)
    if deviceInstance < 0 then
      log("E", "", "No device instance '"..dumps(deviceInstance).." found: "..dumps(info))
      return
    end
    log('I', '', "Registered device '"..dumps(deviceInstance).."' as vinput: "..dumps(info))
    M.devices[deviceInstance] = info
    ensureOutgaugeExtension()
    return deviceInstance
end

M.deleteDevice = function(deviceInstance)
    local mgr = getVirtualInputManager()
    if not mgr then return nil end
    mgr:unregisterDevice('vinput' .. tostring(deviceInstance))
    log('I', '', "Deleted device '"..dumps(deviceInstance).."' as vinput: "..dumps({productName, vidpid, axes, buttons, povs}))
    M.devices[deviceInstance] = nil
    ensureOutgaugeExtension()
end

M.emit = function(deviceInstance, objType, objectInstance, action, val)
    local mgr = getVirtualInputManager()
    if not mgr then return nil end
    mgr:emitEvent('vinput', deviceInstance, objType, objectInstance, action, val)
end

return M
