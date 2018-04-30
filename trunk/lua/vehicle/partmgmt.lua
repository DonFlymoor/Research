-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

-- state to be persistent between reloads and to be sent to gui / set from GUI
M.state = {
  config = {},
}
M.pcPath = ""

local CURRENT_DATAFORMAT = 2

local function save(fn)
  local data = {format = CURRENT_DATAFORMAT, model = v.model, parts = v.userPartConfig, vars = v.userVars}
  data.model = v.vehicleDirectory:gsub("vehicles/", ""):gsub("/", "")
  obj:queueGameEngineLua("core_vehicles.saveVehicleConfig(0, '"..fn.."','"..serialize(data).."')")
  guihooks.trigger('Message', {ttl = 15, msg = 'Configuration saved', icon = 'directions_car'})
end

local function saveLocal(fn)
  save(v.vehicleDirectory .. fn)
end

--[[
send vehicle config data to GameEngine
]]
local function savedefault()
  local vehicleName = v.vehicleDirectory:gsub("vehicles/", ""):gsub("/", "")
  local objTable = {format = CURRENT_DATAFORMAT, parts = v.userPartConfig, vars = v.userVars,model = vehicleName}
  local objString = serialize(objTable)
  guihooks.trigger('Message', {ttl = 15, msg = 'Set new default vehicle', icon = 'directions_car'})
  obj:queueGameEngineLua("saveDefaultVehicle("..objString..")")
end

local function sendData ()
  guihooks.trigger("VehiclePartsTree", {slotMap = v.slotMap, slotDescriptions = v.slotDescriptions, variables = v.variables})
end


local function reset()
  local data = {slotMap=v.slotMap, slotDescriptions=v.slotDescriptions, variables=v.variables}
  guihooks.trigger("VehicleconfigChange", data)
  sendData()
end


local function setConfig(data, respawn)
  if respawn == nil then respawn = true end -- respawn is required all the time except when loading the vehicle

  if not data or type(data) ~= 'table' or type(data.parts) ~= 'table' then
    log('W', "partmgmt.setConfig", "invalid argument: "..tostring(data))
    return
  end

  M.state.config = data
  -- this is the important part actually
  v.userPartConfig = data.parts
  v.userVars = data.vars
  v.userSettings = data.settings

  -- and respawn ourself, this sets the partconfig for the vehicle init()
  if obj.ibody and respawn then
    local d = serialize(data)
    --print("d = " .. tostring(d) .. ' type = ' ..  type(data))
    obj:respawnWithPartConfig(d)
  end
  if data.colors then--and respawn then
    obj:queueGameEngineLua("core_vehicles.setVehicleColors("..obj:getID()..", "..serialize(data.colors)..")")
  end
end

local function setConfigVars (data, respawn)
  setConfig({parts = v.userPartConfig, vars = data, settings = v.userSettings}, respawn)
end

local function setPartsConfig (data, respawn)
  setConfig({parts = data, vars = v.userVars, settings = v.userSettings}, respawn)
end

local function getConfig()
  return { parts = v.userPartConfig, vars = v.userVars, settings = v.userSettings , pcPath = M.pcPath}
end

local function _loadData(data, respawn)
  if data.format == nil then
    -- backward compatibility
    data = {parts = data, vars = {}}
  elseif type(data.format) ~= 'number' or data.format ~= CURRENT_DATAFORMAT then
    log('E', "partmgmt.load", "invalid part config format: " .. tostring(data.format) .. '. Supported format: ' .. tostring(CURRENT_DATAFORMAT))
    return false
  end
  return setConfig(data, respawn)
end

local function load(fn, respawn)
  --print("load " .. tostring(fn) .. ', ' .. tostring(respawn))

  local json = require("json")
  M.pcPath = fn
  -- try to load json first
  local content = readFile(fn)
  if content ~= nil then
    local state, data = pcall(json.decode, content)
    if state == true then
      return _loadData(data, respawn)
    end
  end

  -- try loading the old lua file format now:
  local file, err = io.open(fn, "r")
  if file then
    local contentText = file:read("*all")
    file:close()
    local data = unserialize(contentText)
    return _loadData(data, respawn)
  else
    log('W', "partmgmt.load", "unable to open file for reading: "..fn)
  end
  return false
end

local function loadLocal(fn, respawn)
  --print("loadLocal " .. tostring(fn) .. ', ' .. tostring(respawn))
  load(v.vehicleDirectory .. fn, respawn)
end

local function getConfigList()
  local files = FS:findFiles(v.vehicleDirectory, "*.pc", -1, true, false) or {}
  local result = {}
  for _, file in pairs(files) do
    local basename = string.sub(file,string.len(v.vehicleDirectory)+1, -1)
    table.insert(result, basename)
  end
  return result
end


local function doPartChanges()
  --v.doPartChanges(obj)
end

local function selectReset()
  -- show all
  if obj.ibody then
    obj:setMeshNameAlpha(1, "", false)
  end
end

-- function to highlight multiple selected parts
local function highlightParts(parts)
  obj:setMeshNameAlpha(0, "", true)
  if v.data.flexbodies then
    for _, flexbody in pairs (v.data.flexbodies) do
      for _, part in pairs(parts) do
        if flexbody.partOrigin == part.val and part.highlight == true then
          if flexbody.id ~= nil then
            local f = obj.ibody:getFlexmesh(flexbody.fid)
            if f then
              obj:setMeshAlpha(f, 1)
            end
          else 
            obj:setMeshNameAlpha(1, flexbody.mesh, false) -- sets mesh to visibile if flexmesh doesn't exist
          end
        elseif flexbody.partOrigin == nil then
          obj:setMeshNameAlpha(1, flexbody.mesh, false) -- if part doesnt have an origin, we just set the mesh to visible
        end
      end
    end
  end

  if v.data.props then
    for _, part in pairs(parts) do
      for _, prop in pairs (v.data.props) do
        if prop.partOrigin == part.val and part.highlight == true then
          local p = obj.ibody:getProp(prop.pid)
          if p then
            obj:setPropAlpha(p, 1)
          end
        end
      end
    end
  end
end

local function selectPart(partName, selectSubParts)
  if not obj.ibody then return end

  -- make everything invisible
  obj:setMeshNameAlpha(0, "", true)

  local showedParts = false

  -- now show the flexbodies and parts that origin from that slot
  if v.data.flexbodies then
    local partsToShow = {}
    for _, flexbody in pairs (v.data.flexbodies) do
      if flexbody.partOrigin == partName then
        partsToShow[partName] = true
        if selectSubParts and type(flexbody.childParts) == "table" then
          for _, vv in pairs(flexbody.childParts) do
            partsToShow[vv] = true
          end
        end
      end
    end
    for _, flexbody in pairs (v.data.flexbodies) do
       -- if not partsToShow[flexbody.partOrigin] then obj:setMeshNameAlpha(1, "", false) end
      if partsToShow[flexbody.partOrigin] and flexbody.fid then
        local f = obj.ibody:getFlexmesh(flexbody.fid)
        if f then
          obj:setMeshAlpha(f, 1)
          showedParts = true
        end
      end
    end
  end
  if v.data.props then
    local partsToShow = {}
    for _, prop in pairs (v.data.props) do
      if prop.partOrigin == partName then
        partsToShow[partName] = true
        if selectSubParts and type(prop.childParts) == "table" then
          for _, vv in pairs(prop.childParts) do
            partsToShow[vv] = true
          end
        end
      end
    end
    for _, prop in pairs (v.data.props) do
      if partsToShow[prop.partOrigin] then
        local p = obj.ibody:getProp(prop.pid)
        if p then
          showedParts = true
          obj:setPropAlpha(p, 1)
        end
      end
    end
  end

  if not showedParts then
    selectReset()
  end
end

local function onDeserialized()
end


local function resetConfig()
  setConfig({})
end


-- public interface
M.save = save
M.load = load
M.highlightParts = highlightParts
M.selectPart = selectPart
M.selectReset = selectReset
M.setConfig = setConfig
M.setConfigVars = setConfigVars
M.setPartsConfig = setPartsConfig
M.getConfig = getConfig
M.guiCallback = guiCallback
M.onDeserialized = onDeserialized
M.resetConfig = resetConfig
M.reset = reset
M.requestPartsTree = sendData
M.vehicleResetted = reset
M.getConfigList = getConfigList
M.loadLocal = loadLocal
M.saveLocal = saveLocal
M.savedefault =savedefault

return M
