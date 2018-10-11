-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require("utils")
local deprecatedActions = require("input_deprecated_actions")
local categories = require("input_categories")
local normalActions
local mergedActions
local M = {}

-- join all global actions and per-vehicle actions together
-- this only needs to happen when a new vehicle has been spawned
local function merge(vehiclesActions)
    local actions = {}
    for _,a in pairs(vehiclesActions) do
        for k,v in pairs(a) do
            actions[k] = v
        end
    end
    for k,v in pairs(normalActions) do
        if actions[k] then log("E", "", "Vehicle specific action '"..k.."' already exists in normal actions, and will be ignored") end
        actions[k] = v
    end
    mergedActions = actions
end

-- mangle the action name, needed to prevent collisions with other vehicles' action names
local function nameToUniqueName(actionName, vehicleName)
    local uniqueActionName = actionName
    if vehicleName then uniqueActionName = vehicleName.."__"..uniqueActionName end
    return uniqueActionName
end
local function uniqueNameToName(uniqueActionName, vehicleName)
    local actionName = uniqueActionName
    if vehicleName then
        local prefix = vehicleName.."__"
        if string.startswith(actionName, prefix) then
           actionName = string.sub(actionName, 1+string.len(prefix))
        end
    end
    return actionName
end
-- read the actions from the specified file
local function readActionsFile(path, vehicleName)
    local vehiclesActions = readJsonFile(path)
    if vehiclesActions == nil then
        log("E", "input_actions", 'unable to read json file: ' .. tostring(path))
        return {}
    end
    local result = {}
    for k,v in pairs(vehiclesActions) do
        if vehicleName then
            v.vehicle = vehicleName
            v.cat = v.cat or "vehicle_specific"
            v.ctx = v.ctx or "vlua"
            v.isBasic = v.isBasic or true
        end
        result[nameToUniqueName(k, vehicleName)] = v
    end
    return result
end
-- read the actions for the specified vehicle, or global actions otherwise
-- vehicle-specific actions have certain defaults, to aid modders get it right easily
local function readActions(vehicleName)
    local result = {}
    local directory = vehicleName and "vehicles/"..vehicleName.."/" or "lua/ge/"
    local paths = FS:findFilesByPattern(directory, "input_actions*.json", 0, false, false)

    -- actually parse the actions
    for _,path in pairs(paths) do
        tableMerge(result, readActionsFile(path, vehicleName))
    end
    local resultSize = tableSize(result)
    --[[
    if resultSize > 0 then
        log("D", "input_actions", "Loaded "..resultSize.." actions from "..dumps(paths))
        if vehicleName then
            log("D", "input_actions", "Vehicle "..dumps(vehicleName).." has up to "..resultSize.." custom actions in some of its part configurations")
        end
    end
    --]]
    return result
end


-- re-read all vehicle-specific actions, then merge with the non-vehicle-specific actions
local function updateVehiclesActions()
    local vehiclesActions = {}
    for _,vehicle in ipairs(getAllVehicles()) do
        local vehicleName = vehicle:getJBeamFilename()
        vehiclesActions[vehicleName] = readActions(vehicleName)
    end
    merge(vehiclesActions)
end

local function init()
    normalActions = readActions(nil) -- will not change at runtime, only need to read on init
end

local function getActions()
    return mergedActions
end

local function getActionCategories()
    return categories
end


local function parseAction(action)
    -- check if an action has been deprecated or replaced, and return the new version when possible
    if action == nil then
        log('E', 'bindings', "Cannot parse null action")
        return false
    end
    if mergedActions[action] == nil then
        if deprecatedActions[action] == nil then
            log('E', 'bindings', "Couldn't find action "..action.." in actions lookup table")
            return false
        end

        if deprecatedActions[action]["replacement"] ~= nil then
            log('D', 'bindings', "Replacing deprecated action "..action.." with new action "..deprecatedActions[action]["replacement"]);
            return parseAction(deprecatedActions[action]["replacement"])
        end
        if deprecatedActions[action]["obsolete"] == true then
            log('D', 'bindings', "Ignoring deprecated action: "..action)
            return false
        end
        log('E', 'bindings', "Couldn't process deprecated action "..action..": "..dumps(deprecatedActions[action]))
        return false
    end
    return true, action
end

local function getActionId (action)
    local exists, a = parseAction(action)
    if exists then
        return a
    else
        return nil
    end
end

local function actionToCommands(action)
    -- retrieve the code/parameters that will be used by GameEngine when a binding triggers this action
    local actionMap         = "Normal"
    local actsOnChange      = false
    local     onChange      = ""
    local actsOnDown        = false
    local     onDown        = ""
    local actsOnUp          = false
    local     onUp          = ""
    local isRelative        = false
    local ctx               = "ts"
    local isCentered        = false


    local c = mergedActions[action]
    if c["cat"]      =='menu' then actionMap = "Menu"                                                   end
    if c["ctx"]      =='vlua' then actionMap = "VehicleCommon"                                          end
    if c["actionMap"]  ~= nil then actionMap = c["actionMap"];                                          end
    if c["vehicle"]    ~= nil then actionMap = "VehicleSpecific"                                        end
    if c["onChange"]   ~= nil then onChange  = c["onChange"];   actsOnChange = true;                    end
    if c["onRelative"] ~= nil then onChange  = c["onRelative"]; actsOnChange = true; isRelative = true; end
    if c["onDown"]     ~= nil then onDown    = c["onDown"];     actsOnDown   = true;                    end
    if c["onUp"]       ~= nil then onUp      = c["onUp"];       actsOnUp     = true;                    end
    if c["isCentered"] ~= nil then isCentered= c["isCentered"];                                         end
    if c["ctx"]        ~= nil then ctx       = c["ctx"];                                                end

    if ctx == 'slua' then
      ctx = 'elua'
      log('E', 'bindings', 'Replacing deprecated "slua" context with "elua", for action: '..dumps(action))
    end
    if     ctx == 'ts'    then ctx = COMMAND_CONTEXT_TS
    elseif ctx == 'ui'    then ctx = COMMAND_CONTEXT_UIJS
    elseif ctx == 'vlua'  then ctx = COMMAND_CONTEXT_VLUA
    elseif ctx == 'elua'  then ctx = COMMAND_CONTEXT_ELUA
    elseif ctx == 'tlua'  then ctx = COMMAND_CONTEXT_TLUA
    elseif ctx == 'bvlua' then ctx = COMMAND_CONTEXT_BVLUA end

    return true, actionMap, actsOnChange, onChange, actsOnDown, onDown, actsOnUp, onUp, isRelative, ctx, isCentered
end

M.init = init
M.getActions = getActions
M.getActionCategories = getActionCategories
M.parseAction = parseAction
M.getActionId = getActionId
M.actionToCommands = actionToCommands
M.uniqueNameToName = uniqueNameToName
M.nameToUniqueName = nameToUniqueName
M.updateVehiclesActions = updateVehiclesActions
return M
