-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local warnedBackwardCompatibility = false

local function deprecated()
  guihooks.trigger("toastrMsg", {type="error", title="Deprecated API: bullettime", msg="At least one mod is obsolete and needs to be updated by its author. Check the logs for more information"})
  log("E","", "An obsolete mod is using a deprecated API. See traceback below for more information:\n"..debug.traceback())
end

local function update()
  deprecated()
end

local function reset()
  deprecated()
end

local function get()
  return obj:getSimulationTimeScale()
end

local function set(v)
  obj:queueGameEngineLua('bullettime.set('..tostring(1/v)..')')
end

local function selectPreset(v)
  obj:queueGameEngineLua('bullettime.selectPreset('..dumps(v)..')')
end

local function slowMotion()
  deprecated()
end

local function requestValue()
  deprecated()
  obj:queueGameEngineLua('bullettime.requestValue()')
end

local backwardCompatibility = {
  __index = function(tbl, key)
    if key == 'simulationSpeed' then
      if not warnedBackwardCompatibility then
        log('E', 'bullettime', 'bullettime.simulationSpeed API is deprecated. Please use bullettime.get()')
        warnedBackwardCompatibility = true
      end
      return get() * 100
    end
    return rawget(tbl, key)
  end
}
setmetatable(M, backwardCompatibility)

-- public interface
M.update = update
M.reset = reset
M.get = get
M.set = set
M.selectPreset = selectPreset
M.slowMotion = slowMotion
M.requestValue = requestValue
return M
