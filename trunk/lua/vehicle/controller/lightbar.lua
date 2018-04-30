-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local min = math.min
local max = math.max

local hasRegisteredQuickAccess = false

local modes = nil
local currentMode = nil
local currentModeIndex = 1
local lastLightbarElectric = -1

local function updateGFX(dt)
  if lastLightbarElectric ~= electrics.values.lightbar then
    for k,v in pairs(currentMode.electrics) do
      v.timer = 0
      v.stateIndex = 1
      electrics.values[k] = 0
    end
    lastLightbarElectric = electrics.values.lightbar
  end

  if not currentMode or electrics.values.lightbar <= 0 then return end
  for k,v in pairs(currentMode.electrics) do
    if electrics.values.lightbar > 0 then
      v.timer = v.timer + dt
      if v.timer >= v.states[v.stateIndex].duration then
        v.timer = 0
        v.stateIndex = v.stateIndex + 1
        if v.stateIndex > #v.states then
          v.stateIndex = 1
        end
        electrics.values[k] = v.states[v.stateIndex].value * electrics.values.lightbar
      end
    else
      v.timer = 0
      v.stateIndex = 1
      electrics.values[k] = 0
    end
  end
end

local function setModeIndex(index)
  currentModeIndex = index
  currentMode = modes[currentModeIndex]

  for k,v in pairs(currentMode.electrics) do
    v.timer = 0
    v.stateIndex = 1
    electrics.values[k] = 0
  end

  gui.message("Lightbar Mode: "..currentMode.name, 5, "vehicle.lightbar.mode")
end

local function toggleMode(value)
  currentModeIndex = currentModeIndex + 1
  if currentModeIndex > #modes then
    currentModeIndex = 1
  end
  setModeIndex(currentModeIndex)
end

local function init(jbeamData)
  modes = tableFromHeaderTable(jbeamData.modes)
  for k,v in pairs(modes) do
    local configEntries = tableFromHeaderTable(deepcopy(v.config))
    v.config = nil
    v.electrics = {}
    for i,j in pairs(configEntries) do
      if not v.electrics[j.electric] then
        v.electrics[j.electric] = {states = {}, timer = 0, stateIndex = 1}
      end
      table.insert(v.electrics[j.electric].states, {duration = j.duration, value = j.value})
    end
  end
  --dump(modes)
  currentModeIndex = jbeamData.defaultModeIndex or 1
  currentMode = modes[currentModeIndex]
  lastLightbarElectric = electrics.values.lightbar

  if not hasRegisteredQuickAccess and #modes > 1 then
    core_quickAccess.addEntry({ level = '/electrics/', generator = function(entries)
          if controller.getController('lightbar') then
            table.insert(entries, { title = 'Lightbar Modes', priority = 40, ["goto"] = '/electrics/lightbarmodes/', icon = 'settings' })
          end
        end})
    core_quickAccess.addEntry({ level = '/electrics/lightbarmodes/', generator = function(entries)
          for k,v in pairs(modes) do
            local entry = { title = v.name, onSelect = function() setModeIndex(k) return {'reload'} end}
            if currentModeIndex == k then
              entry.color = '#ff6600'
            end
            table.insert(entries, entry)
          end
        end})
    hasRegisteredQuickAccess = true
  end
end

M.init = init
M.updateGFX = updateGFX
M.toggleMode = toggleMode

return M