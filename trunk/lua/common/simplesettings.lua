-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this is a simple, read only settings adapter

local persistencyfile = 'settings/game-settings.ini'
local persistencyfileCloud = 'settings/cloud/game-settings-cloud.ini'

local M = {}
local values = nil

local function refresh()
  values = nil
end

-- this does not detect any changes to the settings file, its only loaded once
local function getValue(key, defaultValue)
  if not values then
    values = loadIni(persistencyfile)
    if values == nil then
      log("W", "", "Couldn't load file "..dumps(persistencyfile))
      values = {}
    end
    local cloudValues = loadIni(persistencyfileCloud)
    if cloudValues == nil then
      log("W", "", "Couldn't load file "..dumps(persistencyfileCloud))
      cloudValues = {}
    end
    tableMerge(values, cloudValues)
    --log("D", "simpleSettings.getValue", dumps(values))
    --dump(values)
  end
  if values[key] == nil then
    return defaultValue
  end
  return values[key]
end

M.getValue = getValue
M.refresh = refresh

return M
