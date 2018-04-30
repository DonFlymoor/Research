-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = "transfercase"

local shaft = nil
local rangeBox = nil
local name = nil
local hasBuiltPie = false

local function updateGFX(dt)
  electrics.values.modeRangeBox = rangeBox and (rangeBox.mode == "low" and 1 or 0) or 0
  electrics.values.mode4WD = shaft and (shaft.mode == "connected" and 1 or 0) or 0
end

local function toggleRange()
  if rangeBox then
    powertrain.toggleDeviceMode(rangeBox.name)
    gui.message("Range status: "..rangeBox.mode, 10, "vehicle.powertrain.rangestatus")
  end
end

local function setRangeMode(mode)
  if rangeBox then
    powertrain.setDeviceMode(rangeBox.name, mode)
    gui.message("Range status: "..rangeBox.mode, 10, "vehicle.powertrain.rangestatus")
  end
end

local function toggle4WD()
  if shaft and not shaft.isPhysicallyDisconnected then
    powertrain.toggleDeviceMode(shaft.name)
    gui.message("4WD Status: "..shaft.mode, 10, "vehicle.powertrain.shaftstatus")
  end
end

local function set4WDMode(mode)
  if shaft and not shaft.isPhysicallyDisconnected then
    powertrain.setDeviceMode(shaft.name, mode)
    gui.message("4WD Status: "..shaft.mode, 10, "vehicle.powertrain.shaftstatus")
  end
end

local function serialize()
  return {
    mode4WD = shaft and shaft.mode or nil,
    modeRange = rangeBox and rangeBox.mode or nil
  }
end

local function deserialize(data)
  if data then
    if shaft and data.mode4WD then
      set4WDMode(data.mode4WD)
    end
    if rangeBox and data.modeRange then
      setRangeMode(data.modeRange)
    end
  end
end

local function init(jbeamData)
  name = jbeamData.name
  shaft = powertrain.getDevice(jbeamData.shaftName)
  rangeBox = powertrain.getDevice(jbeamData.rangeBoxName)

  electrics.values.modeRangeBox = rangeBox and (rangeBox.mode == "low" and 1 or 0) or 0
  electrics.values.mode4WD = shaft and (shaft.mode == "connected" and 1 or 0) or 0

  if not hasBuiltPie then
    if shaft then
      core_quickAccess.addEntry({ level = '/powertrain/', generator = function(entries)
            table.insert(entries, { title = 'ui.radialmenu2.powertrain.4WD_Mode', priority = 40, ["goto"] = '/powertrain/4wd/', icon = 'radial_4wd_mode' })
          end})
      core_quickAccess.addEntry({ level = '/powertrain/4wd/', generator = function(entries)
            local connectedEntry = { title = 'ui.radialmenu2.powertrain.4wd.connected', icon="radial_connected" , onSelect = function() controller.getController(name).set4WDMode("connected") return {'reload'} end}
            local disconnectedEntry = { title = 'ui.radialmenu2.powertrain.4wd.disconnected', icon="radial_disconnected" , onSelect = function() controller.getController(name).set4WDMode("disconnected") return {'reload'} end}
            if shaft.mode == "disconnected" then
              disconnectedEntry.color = '#ff6600'
            else
              connectedEntry.color = '#ff6600'
            end
            table.insert(entries, connectedEntry)
            table.insert(entries, disconnectedEntry)
          end})
    end
    if rangeBox then
      core_quickAccess.addEntry({ level = '/powertrain/', generator = function(entries)
            local rmicon
            if rangeBox.mode == "low" then
              rmicon = "radial_lowrangebox"
            else
              rmicon = "radial_highrangebox"
            end
            table.insert(entries, { title = 'ui.radialmenu2.powertrain.rangebox_mode', priority = 40, ["goto"] = '/powertrain/rangebox/', icon = rmicon })
          end})
      core_quickAccess.addEntry({ level = '/powertrain/rangebox/', generator = function(entries)
            local lowEntry = { title = 'ui.radialmenu2.powertrain.rangebox_mode.low', icon="radial_lowrangebox", onSelect = function() controller.getController(name).setRangeMode("low") return {'reload'} end}
            local highEntry = { title = 'ui.radialmenu2.powertrain.rangebox_mode.high', icon="radial_highrangebox", onSelect = function() controller.getController(name).setRangeMode("high") return {'reload'} end}
            if rangeBox.mode == "low" then
              lowEntry.color = '#ff6600'
            else
              highEntry.color = '#ff6600'
            end
            table.insert(entries, lowEntry)
            table.insert(entries, highEntry)
          end})
    end
    hasBuiltPie = true
  end
end

M.init = init
M.updateGFX = updateGFX
M.toggle4WD = toggle4WD
M.set4WDMode = set4WDMode
M.toggleRange = toggleRange
M.setRangeMode = setRangeMode
M.serialize = serialize
M.deserialize = deserialize

return M
