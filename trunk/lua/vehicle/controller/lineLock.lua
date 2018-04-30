-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil
M.defaultOrder = 40

local name = nil
local lockedLines = nil
local lockedBrakingTorques = nil
local lineLockActive = 0
local electricsName = nil
local hasBuiltPie = false

local wheelRotatorCountDec = 0

local function updateWheelsIntermediate(dt)
  for i = 0, wheelRotatorCountDec, 1 do
    local wd = wheels.wheelRotators[i]
    wd.desiredBrakingTorque = (lineLockActive > 0 and lockedLines[wd.name]) and lockedBrakingTorques[wd.name] or wd.desiredBrakingTorque
  end
end

local function updateGFX(dt)
  electrics.values[electricsName] = lineLockActive
end

local function setLineLock(value)
  gui.message("Linelock is " .. ((value >= 1) and "enabled" or "disabled"), 2, "vehicle.linelock.status")
  lineLockActive = value

  for i = 0, wheels.wheelRotatorCount - 1, 1 do
    local wd = wheels.wheelRotators[i]
    lockedBrakingTorques[wd.name] = lineLockActive > 0 and wd.brakingTorque or 0
  end
end

local function toggleLineLock()
  lineLockActive = 1 - lineLockActive
  setLineLock(lineLockActive)
end

local function init(jbeamData)
  name = jbeamData.name

  lockedLines = {}
  lockedBrakingTorques = {}
  for _,v in pairs(jbeamData.lockedLines) do
    lockedLines[v] = true
    lockedBrakingTorques[v] = 0
  end

  wheelRotatorCountDec = wheels.wheelRotatorCount - 1

  electricsName = jbeamData.electricsName or "linelock"

  if not hasBuiltPie then
      core_quickAccess.addEntry({ level = '/powertrain/', generator = function(entries)
            local noEntry = { title = 'Line Lock', priority = 40, icon = 'radial_line_lock', onSelect = function() controller.getController(name).toggleLineLock() return {'reload'} end }
            if electrics.values[electricsName] >= 1 then
              noEntry.color = '#ff6600'
            end
            table.insert(entries, noEntry)
          end})
    end
    hasBuiltPie = true

  lineLockActive = 0
end

M.init = init
M.updateGFX = updateGFX
M.updateWheelsIntermediate = updateWheelsIntermediate
M.setLineLock = setLineLock
M.toggleLineLock = toggleLineLock

return M