-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local presets = {}
local currentValues = {}

local function activate(presetName)
  local p = presets[presetName]
  if not p then
    log('E', 'weather', 'Weather preset not found: ' .. tostring(presetName))
    return
  end

  for objClassStr, attribTable in pairs(p) do
    if type(objClassStr) ~= 'string' or type(attribTable) ~= 'table' then
      log('E', 'weather', 'object class or attrib table invalid: ' .. tostring(objClassStr))
      goto continue
    end
    
    local objs = getObjectsByClass(objClassStr)
    if objs == nil then
      log('E', 'weather', 'object class not found: ' .. tostring(objClassStr))
    else
      for _, obj in pairs(objs) do
        for attrName, attrValue in pairs(attribTable) do
          local fields = obj:getFields()
          if type(fields[attrName]) ~= 'table' then
            log('E', 'weather', 'object attribute invalid: class = ' .. tostring(objClassStr) .. ', attribute = ' .. tostring(attrName))
            goto continue
          end
          
          local val = nil
          if type(attrValue) == fields[attrName].type then
            val = attrValue
          elseif (fields[attrName].type == 'filename' or fields[attrName].type == 'annotation') and type(attrValue) == 'string' then
            val = attrValue
          elseif (fields[attrName].type == 'float' or fields[attrName].type == 'int') and type(attrValue) == 'number' then
            val = attrValue
          elseif fields[attrName].type == 'bool' and type(attrValue) == 'boolean' then
            val = attrValue
          elseif fields[attrName].type == 'ColorF' and type(attrValue) == 'table' and #attrValue == 4 then
            val = Point4F(attrValue[1], attrValue[2], attrValue[3], attrValue[4])
          elseif fields[attrName].type == 'Point4F' and type(attrValue) == 'table' and #attrValue == 4 then
            val = Point4F(attrValue[1], attrValue[2], attrValue[3], attrValue[4])
          elseif fields[attrName].type == 'Point3F' and type(attrValue) == 'table' and #attrValue == 3 then
            val = Point3F(attrValue[1], attrValue[2], attrValue[3])
          end

          if val == nil then
            log('E', 'weather',  'invalid attribute: ' .. tostring(obj.name or '(no name)') .. ' [' .. objClassStr .. '].' .. tostring(attrName) .. ' = ' .. tostring(attrValue))
          else
            log('D', 'weather',  ' * ' .. tostring(obj.name or '(no name)') .. ' [' .. objClassStr .. '].' .. tostring(attrName) .. ' = ' .. dumps(attrValue) .. ' / ' .. tostring(val))
            obj[attrName] = val
            currentValues[attrName] = val
          end
        end
      end
    end
    ::continue::
  end


  -- TODO:
  -- materials: specularity change, darken the colors
end


--[[
-- test code:
local time = 0
local switch = true
local function onPreRender(dt)
  time = time + dt
  print(time)
  if time > 3 then
    if not switch then
      activate('sunny')
    else
      activate('rainy')
    end
    switch = not switch
    time = time - 3
  end
end
--]]

-- loads one preset
local function loadPreset(filename)
  local filePresets = readJsonFile(filename)
  --log('D', 'weather', "Weather preset loaded: " .. tostring(filename) .. ": "..dumps(filePresets))
  if tableSize(filePresets) == 0 then
    log('E', 'weather', 'preset invalid: ' .. tostring(filename))
    return
  end
  tableMerge(presets, filePresets)
end

-- loads the global weather files and then the local weather of the level if existing
local function loadPresets()
  local missionFile = getMissionFilename()
  if type(missionFile) ~= 'string' or string.len(missionFile) == 0 then return end

  local globalFiles = FS:findFilesByRootPattern('game:art/weather/', '*.json', -1, true, false)
  for _, v in pairs(globalFiles) do
    loadPreset(v)
  end

  local levelDir, filename, ext = string.match(missionFile, "(.-)([^/]-([^%.]*))$")
  local levelFiles = FS:findFilesByRootPattern('game:' .. levelDir..'/weather/', '*.json', -1, true, false)
  for _, v in pairs(levelFiles) do
    loadPreset(v)
  end
end

local function onExtensionLoaded()
  --log('I', 'weather', "module loaded")
  loadPresets()
end

local function onClientPostStartMission(missionFile)
  --log('I', 'weather', "map loaded: " .. tostring(mission))
  loadPresets()

  -- load default preset
  --if presets['sunny'] then
  --  activate('sunny')
  --end
end

-- public interface below

M.onExtensionLoaded = onExtensionLoaded
M.onClientPostStartMission = onClientPostStartMission
--M.loadPresets = loadPresets
M.activate = activate
--M.onPreRender = onPreRender

return M
