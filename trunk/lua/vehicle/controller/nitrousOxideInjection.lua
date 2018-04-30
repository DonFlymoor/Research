-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = "mainEngine"

local name = nil
local hasBuiltPie = false
local armElectricsName = nil
local overrideElectricsName
local engine = nil
local purgeTime = 0

local function updateGFX(dt)
  if streams.willSend("n2oInfo") and engine then
    gui.send('n2oInfo', {
        tankRatio = engine.nitrousOxideInjection.getTankRatio(),
        isArmed = engine.nitrousOxideInjection.isArmed,
        isActive = engine.nitrousOxideInjection.isActive,
      })
  end
end

local function displayState()
  gui.message("Nitrous Oxide Injection: "..((electrics.values[armElectricsName] or 0) >= 1 and "Armed" or "Disarmed"), 5, "vehicle.powertrain.nitrousOxideInjection")
end

local function setOverride(active)
  electrics.values[overrideElectricsName] = active and 1 or 0
end

local function toggleActive()
  if electrics.values[armElectricsName] == 0 then
    engine.nitrousOxideInjection.purgeLines(purgeTime)
  end
  electrics.values[armElectricsName] = 1 - (electrics.values[armElectricsName] or 0)
  displayState()
end

local function serialize()
  return {
    isArmed = electrics.values[armElectricsName],
  }
end

local function deserialize(data)
  if data and data.isArmed then
    electrics.values[armElectricsName] = data.isArmed
  end
end

local function init(jbeamData)
  M.updateGFX = nop

  name = jbeamData.name
  armElectricsName = jbeamData.electricsArmName or "nitrousOxideArm"
  overrideElectricsName = jbeamData.electricsOverrideName or "nitrousOxideOverride"
  purgeTime = jbeamData.purgeTime or 1
  local engineName = jbeamData.engineName or "mainEngine"
  electrics.values[armElectricsName] = electrics.values[armElectricsName] or 0

  engine = powertrain.getDevice(engineName)
  local hasNitrousOxideInjection = engine and engine.nitrousOxideInjection and engine.nitrousOxideInjection.isExisting
  if hasNitrousOxideInjection then
    M.updateGFX = updateGFX

    if not hasBuiltPie then
      core_quickAccess.addEntry({ level = '/powertrain/', generator = function(entries)
            local noEntry = { title = 'Nitrous Oxide', priority = 40, icon = 'radial_nitrous_oxide', onSelect = function() controller.getController(name).toggleActive() return {'reload'} end }
            if electrics.values[armElectricsName] >= 1 then
              noEntry.color = '#ff6600'
            end
            table.insert(entries, noEntry)
          end})
    end
    hasBuiltPie = true
  end

  displayState()
end

M.init = init
M.updateGFX = nop
M.setOverride = setOverride
M.toggleActive = toggleActive
M.serialize = serialize
M.deserialize = deserialize

return M
