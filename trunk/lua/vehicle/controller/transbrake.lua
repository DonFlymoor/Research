-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local gearbox = nil
local electricsName = nil
local hasBuiltPie = false

local function updateGFX(dt)
  electrics.values[electricsName] = gearbox.lockCoef == 0
end

local function setTransbrake(value)
  if gearbox then
    gearbox:setLock(value)
    gui.message("Transbrake is " .. (value and "enabled" or "disabled"), 2, "vehicle.transbrake.status")
  end
end

local function toggleTransbrake()
  if gearbox then
    local enabled = gearbox.lockCoef == 0
    setTransbrake(not enabled)
  end
end

local function init(jbeamData)
  local gearboxName = jbeamData.gearboxName or "gearbox"
  electricsName = jbeamData.electricsName or "transbrake"
  gearbox = powertrain.getDevice(gearboxName)
  M.updateGFX = gearbox and updateGFX or nop

  if not hasBuiltPie then
    if gearbox then
      core_quickAccess.addEntry({ level = '/powertrain/', generator = function(entries)
        local noEntry = { title = 'Transbrake', priority = 40, icon = 'material_swap_horiz', onSelect = function() controller.getController("transbrake").toggleTransbrake() return {'reload'} end }
        if gearbox.lockCoef == 0 then
          noEntry.color = '#ff6600'
        end
        table.insert(entries, noEntry)
      end})
    end
    hasBuiltPie = true
  end
end

M.init = init
M.updateGFX = nop
M.toggleTransbrake = toggleTransbrake
M.setTransbrake = setTransbrake

return M