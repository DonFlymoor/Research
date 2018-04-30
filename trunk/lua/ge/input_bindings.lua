-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require("utils")
local json = require("json")
local actions = require("input_actions")
local multiseat = require("multiseat")
local M = {}
M.isMenuActive = false
M.devices = {}

local function fillNormalizeBindingDefaults(binding)
    local binding = deepcopy(binding)
    -- populate any possible missing binding parameter with sensible default values, and upgrade old bindings
    binding.isLinear = nil -- remove deprecated field
    binding.scale    = nil -- remove deprecated field
    binding.isRanged = nil -- remove deprecated field
    if binding.deadzone        == nil then binding.deadzone = { ["end"] = 0 } end
    binding.deadzone.begin = nil -- remove deprecated field
    if binding.deadzone["end"] then binding.deadzone["end"] = tonumber(binding.deadzone["end"]) end
    if binding.deadzone["end"] and not binding.deadzoneResting then binding.deadzoneResting = binding.deadzone["end"] end
    if binding.deadzoneResting then binding.deadzoneResting = tonumber(binding.deadzoneResting) end
    if binding.deadzoneEnd     then binding.deadzoneEnd     = tonumber(binding.deadzoneEnd)     end
    binding.deadzone = nil -- remove deprecated field
    if binding.deadzoneResting == nil  then binding.deadzoneResting = 0 end
    if binding.deadzoneEnd     == nil  then binding.deadzoneEnd = 0 end
    if binding.control         ~= nil then binding.control = string.lower(binding.control) end
    if binding.linearity       == nil then binding.linearity = 1 end
    if binding.isInverted      == nil then binding.isInverted = false end
    if binding.isForceEnabled  == nil then binding.isForceEnabled = false end
    if binding.isForceInverted == nil then binding.isForceInverted = false end
    if binding.ffbUpdateType   == nil then binding.ffbUpdateType = 0 end
    binding.ffbUpdateType = tonumber(binding.ffbUpdateType)
    if binding.ffb             == nil then binding.ffb = { forceCoef = 200, forceLimit = 2, smoothing = 150, smoothingHF = 50 } end
    if binding.ffb.frequency   == nil then binding.ffb.frequency = 0 end
    if binding.ffb.responseCurve==nil then binding.ffb.responseCurve = { {0, 0}, {1, 1} } end
    if binding.ffb.responseCorrected==nil then binding.ffb.responseCorrected = false end
    if binding.ffb.forceCoefLowSpeed==nil then binding.ffb.forceCoefLowSpeed = binding.ffb.forceCoef end
    if binding.filterType      == nil then binding.filterType = -1 end
    if binding.angle           == nil then binding.angle = 0 end
    return binding
end

local function cleanBindingDefaults(binding)
    -- strip the binding settings that are default (leaving only the custom settings)
    local result = deepcopy(binding)
    local default = fillNormalizeBindingDefaults({})
    for k, v in pairs(default) do
        if dumps(result[k]) == dumps(v) then
            result[k] = nil
        end
    end
    return result
end

local function dumpbinding(binding)
    if binding == nil then return dumps(binding) end
    return dumps(cleanBindingDefaults(deepcopy(binding))):gsub("\n", " "):gsub(" +", " ")
end

local function sendBindingsToGE(devname, bindings, player)
    -- upload the provided bindings data into torque3d, associated with an specific device name
    if bindings == nil then
        log('E', 'bindings', "Error parsing bindings for device "..devname..": bindings is nil"); return false end
    local count = 0
    for i,binding in pairs(bindings) do
        local b = deepcopy(binding)
        local success
        success, b.action = actions.parseAction(b.action)
        if not success then
          log('E', 'bindings', "Skipping invalid 'action' field on binding "..i.." in device "..devname..": "..dumpbinding(binding))
          goto continue
        end

        local success, actionMap, actsOnChange, onChange, actsOnDown, onDown, actsOnUp, onUp, isRelative, ctx, isCentered
        success, actionMap, actsOnChange, onChange, actsOnDown, onDown, actsOnUp, onUp, isRelative, ctx, isCentered = actions.actionToCommands(b["action"])
        if not success then
          log('E', 'bindings', "Couldn't load action "..b["action"])
          goto continue
        end

        b = fillNormalizeBindingDefaults(b)

        local actionMapName = actionMap.."ActionMap"
        local am = scenetree.findObject(actionMapName)
        if not am then
          am = ActionMap(actionMapName)
          log('D', 'bindings', "Registered new action map: "..actionMapName)
        end
        am:bindFull(devname, b.action, b.control, isCentered, b.deadzoneResting, b.deadzoneEnd, b.linearity, b.angle or 0, b.isInverted, b.isForceEnabled, b.isForceInverted, b.ffbUpdateType, encodeJson(b.ffb), actsOnChange, onChange, actsOnDown, onDown, actsOnUp, onUp, b.filterType, isRelative, player, ctx)
        count = count + 1
        ::continue::
    end
    --log('D', 'bindings', "Loaded "..count.." bindings for device "..devname)
    return true
end
local function readBindingsFromDisk(path, vehicleName)
    -- read and normalize/upgrade bindings from a single file on disk
    local f = readFile(path)
    if not f then
        log('E', 'bindings', "Error parsing bindings in file "..path..": cannot open file"); return nil end
    local success, data = pcall(json.decode, f)
    if not success then
        log('E', 'bindings', "Error parsing bindings in file "..path..": "..data); return nil end
    if data.bindings == nil and data.removed == nil then
        log('E', 'bindings', "Error parsing bindings in file "..path..": no 'bindings' nor 'removed' field found: "..dumps(data)); return nil end
    if data.bindings then
        local finalBindings = {}
        for i, b in pairs(data.bindings) do
            if b.control == nil then
                log('E', 'bindings', "Missing 'control' field on binding "..i.." in file "..path..": "..dumpbinding(b)); goto continue; end
            b = fillNormalizeBindingDefaults(b)
            local action = actions.nameToUniqueName(b.action, vehicleName) -- this name-mangling is needed to prevent collisions with other vehicles' action names
            success, action = actions.parseAction(action)
            if not success then
                log('D', 'bindings', "Skipping invalid 'action' field on binding "..i.." in file "..path..": "..dumpbinding(b)); goto continue; end
            b.action = action
            table.insert(finalBindings, b)
            ::continue::
        end
        data.bindings = finalBindings
    end
    if data.removed then
        local finalRemoved = {}
        for i, b in pairs(data.removed) do
            if b.control == nil then
                log('E', 'bindings', "Missing 'control' field on removed binding "..i.." in file "..path..": "..dumpbinding(b)); goto continue; end
            local action = actions.nameToUniqueName(b.action, vehicleName) -- this name-mangling is needed to prevent collisions with other vehicles' action names
            success, action = actions.parseAction(action)
            if not success then
                log('D', 'bindings', "Skipping invalid 'action' field on removed binding "..i.." in file "..path..": "..dumpbinding(b)); goto continue; end
            b.action = action
            table.insert(finalRemoved, b)
            ::continue::
        end
        data.removed = finalRemoved
    end
    return data
end

local function bindingListToDict(list)
    -- convert from a binding list, to a dictionary with control\0action as keys
    local result = {}
    if list == nil then return result end
    for _,v in pairs(list) do
        if v.action  == nil then log("W", "bindings", "Binding is missing the 'action' field: " ..dumpbinding(v)) end
        if v.control == nil then log("W", "bindings", "Binding is missing the 'control' field: "..dumpbinding(v)) end
        if v.action and v.control then result[v.control.."\0"..v.action] = cleanBindingDefaults(v) end
    end
    return result
end

local function createBindingsDiff(old, new)
    -- create an empty diff, populate it with non-bindings information (guid, devtype, productname, etc)
    local result = { bindings = {}, removed = {}, version = 1 }
    for k,v in pairs(old) do
        if k ~= "bindings" and k ~= "removed" then result[k] = v end
    end

    -- duplicate provided bindings as dicts (to leave originals untouched, and for easier processing)
    local dictOld = bindingListToDict(old.bindings)
    local dictNew = bindingListToDict(new.bindings)

    -- mark bindings that are to be removed
    local markedForRemoval = {}
    for k,v in pairs(dictOld) do
        if dictNew[k] == nil then
            markedForRemoval[k] = v
        end
    end

    -- process removed bindings
    for k,v in pairs(markedForRemoval) do
        log('D', 'bindings', "Removed binding (added to list): "..dumps(v.control).." : "..dumps(v.action))
        table.insert(result.removed, { control = v.control, action = v.action } )
        dictOld[k] = nil
    end

    -- process modified/new bindings
    for k,v in pairs(dictNew) do
        if dumps(dictOld[k]) ~= dumps(v) then
            if dictOld[k] then log('D', 'bindings', "Modified binding (added to list): "..dumps(v.control).." : "..dumps(v.action))
            else               log('D', 'bindings',      "New binding (added to list): "..dumps(v.control).." : "..dumps(v.action)) end
            table.insert(result.bindings, cleanBindingDefaults(v) )
        end
    end
    -- remove empty lists
    if tableSize(result.removed ) == 0 then result.removed  = nil end
    if tableSize(result.bindings) == 0 then result.bindings = nil end
    if result.bindings == nil and result.removed == nil then result = nil end

    return result
end

local function applyResponseCurve(contents, path, curveInverted)
    log("D", "bindings", "Applying response curve from path: "..path)
    for i,binding in pairs(contents.bindings) do
        if binding.ffb and binding.ffb.responseCorrected then
            local f = readFile(path)
            if not f then
                log('E', 'bindings', "Error parsing response curve in file "..path..": cannot open file"); return contents end
            local xcolumn = nil
            local ycolumn = nil
            local responseCurve = {}
            for line in f:gmatch("([^\n\r]*)") do
                if line ~= "" then
                    local x = nil
                    local y = nil
                    local column = 0
                    for field in line:gmatch("([^,|]*)") do
                        field = field:match("^%s*(.-)%s*$")
                        if field ~= "" then
                            local v = tonumber(field)
                            if v then
                                if xcolumn == nil or ycolumn == nil then
                                    log("W", "", "Cannot recognize column headers in FFB response curve file: "..dumps(path))
                                    if xcolumn == nil then
                                      log("W", "", "Assuming X column is at: "..dumps(column))
                                      xcolumn = column
                                    else
                                      if ycolumn == nil then
                                      log("W", "", "Assuming Y column is at: "..dumps(column))
                                        ycolumn = column
                                      end
                                    end
                                end
                                if column == xcolumn then x = v end
                                if column == ycolumn then y = v end
                            else
                                if field == "force"       then xcolumn = column end
                                if field == "LinearForce" then xcolumn = column end
                                if field == "deltaX"                then ycolumn = column end
                                if field == "Linear Force Response" then ycolumn = column end
                            end
                        end
                        column = column + 1
                    end
                    if x ~= nil and y ~= nil then
                        table.insert(responseCurve, {x, y})
                        --log("I", "", dumps({x,y}))
                    else
                        log("D", "bindings", "Skipping invalid datapoint line in FFB response curve file: \""..line.."\"")
                    end
                end
            end
            if curveInverted then
              log("D", "", "Inverting curve path: "..dumps(path))
              for n,v in ipairs(responseCurve) do
                v[2], v[1] = v[1], v[2]
              end
            end
            --log("I", "", "Response curve: "..dumps(responseCurve))
            binding.ffb.responseCurve = responseCurve
        end
    end
    return contents
end

local function applyBindingsDiff(base, diff)
    -- duplicate provided bindings as dicts (to leave originals untouched, and for easier processing)
    diff = diff or {}
    base = base or {}
    local version = diff.version or base.version or 0
    local dictBase         = bindingListToDict(base.bindings)
    local dictDiffReplaced = bindingListToDict(diff.bindings)
    local dictDiffRemoved  = bindingListToDict(diff.removed )

    -- upgrade old diff format that had no support for duplicate bindings
    local allowDuplicates = version >= 1
    if not allowDuplicates then
        for k,v in pairs(dictDiffReplaced) do
            for kk,vv in pairs(dictBase) do
                if vv.control == v.control then
                    log("I", "bindings", "Upgrading inputmap from old v0 format - Removing duplicate binding: "..dumps(v.control).." : "..dumps(v.action))
                    dictDiffRemoved[kk] = vv
                end
            end
        end
    end

    -- merge removed bindings
    for k,v in pairs(dictDiffRemoved) do
        if dictBase[k] == nil then log("W", "bindings", "Merge: trying to remove a binding that was not there in the first place: "..dumps(v))
        else                       log("D", "bindings", "Merge: removed binding: "..dumps(v.control).." : "..dumps(v.action)) end
        dictBase[k] = nil
    end

    -- merge new/modified bindings
    for k,v in pairs(dictDiffReplaced) do
        if dictBase[k] then log("D", "bindings", "Merge: modified binding: "..dumps(v.control).." : "..dumps(v.action))
        else                log("D", "bindings", "Merge: added binding: "   ..dumps(v.control).." : "..dumps(v.action)) end
        dictBase[k] = v
    end

    -- convert back to list
    local result = { bindings = {} }
    for _,v in pairs(dictBase) do table.insert(result.bindings, cleanBindingDefaults(v)) end
    return result
end

local function getWritingDir(vehicleName)
    if vehicleName then return "settings/inputmaps/"..vehicleName
    else                return "settings/inputmaps" end
end
local function getWritingPath(vehicleName, devicetype, pidvid)
    -- find out the most appropriate path to write an inputmap file
    local basedir = getWritingDir(vehicleName)
    if devicetype == "mouse" or devicetype == "keyboard" then
        return basedir.."/" .. devicetype .. ".diff"
    end
    return basedir.."/" .. pidvid:lower() .. ".diff"
end

local function getDeviceInfo(device)
    -- ask T3D information about the provided devname
    local guid = WinInput.getProductGUID(device)
    local productName = WinInput.getProductName(device)
    local pidvid = WinInput.getVendorIDProductID(device)
    --local battery = WinInput.getBatteryLevel(device)
    return guid, productName, pidvid, battery
end

local function getInputmapPath(devname, guid, productName, pidvid, vehicleName, suffix)
    -- locate a suitable inputmap file path, returning the most specific file possible (e.g. abcd1234 first, if not found then joystick.json)
    local               basedir =               "settings/inputmaps"
    if vehicleName then basedir = "vehicles/"..vehicleName.."/inputmaps" end

    -- try 1: the Vendor ID and Product ID combined
    local path = basedir.."/" .. pidvid:lower() .. suffix
    if FS:fileExists(path) then return path end

    -- try 2: the controller type
    local devicetype = string.split(devname, "%D+")[1] -- strip trailing number, if it exists (xinput0 -> xinput)
    path = basedir.."/" .. devicetype:lower() .. suffix
    if FS:fileExists(path) then return path end

    if vehicleName then
        basedir = "settings/inputmaps/"..vehicleName
        -- try 3: vehicle path, the Vendor ID and Product ID combined
        local path = basedir.."/" .. pidvid:lower() .. suffix
        if FS:fileExists(path) then return path end

        -- try 4: vehicle path, the controller type
        local devicetype = string.split(devname, "%D+")[1] -- strip trailing number, if it exists (xinput0 -> xinput)
        path = basedir.."/" .. devicetype:lower() .. suffix
        if FS:fileExists(path) then return path end
    end
    --log("D", "bindings", "No luck finding an input map for device "..productName.." / "..pidvid.." / "..guid.." for vehicle "..dumps(vehicleName))
    return nil -- nothing was found
end

local function ListToSet(list)
    -- {'a', 'b', 'c'} ==> {a=true, b=true, c=true}
    local res = {}
    for _,e in ipairs(list) do
        res[e] = true
    end
    return res
end
local function updateDevicesList(oldDevices)
    -- refreshes the list of plugged input devices, notifying UI of new/removed devices
    local newDevicesList = string.split(WinInput.getRegisteredDevices(), "%S+")
    local newDevicesSet = ListToSet(newDevicesList)
    local newDevices = {}
    -- first check for new or modified devices (using devname as the id)
    for _,device in ipairs(newDevicesList) do
        local guid, productName, pidvid, battery = getDeviceInfo(device)
        newDevices[device] = {guid, productName, pidvid}
        if oldDevices[device] == nil then
            -- a new devname was found: user just plugged it
            local msg = "Controller connected: "..productName
            local isCommonDevice = device == 'mouse0' or device == 'keyboard0'

            if not isCommonDevice then
                log("I", "bindings", msg.." ("..device.."/0x"..pidvid..")")
            end
            if string.startswith(device, "xinput") then
                local n = string.sub(device, -1, -1) -- get controller number (xinput3 -> 3)
                local event = {controller = n, connected = true}
                be:executeJS("HookManager.trigger('XInputControllerUpdated', "..tostring(encodeJson(event))..");")
            elseif not isCommonDevice then
                ui_message(msg)
            end
        else
            if oldDevices[device][3] ~= pidvid then
                -- the pidvid of a devname has changed! new drivers have been loaded by Windows, or user has replaced a device veeery quickly
                local msg = "Controller changed: "..productName
                log("I", "bindings", msg.." ("..device.."/0x"..pidvid..")")
                ui_message(msg)
            end
        end
    end
    -- now check for removed devices
    for device,_ in pairs(oldDevices) do
        if newDevicesSet[device] == nil then
            local guid = oldDevices[device][1]
            local productName = oldDevices[device][2]
            local pidvid = oldDevices[device][3]
            local msg =  "Controller unplugged: "..productName
            log("I", "bindings", msg.." ("..device.."/0x"..pidvid..")")
            if string.startswith(device, "xinput") then
                local n = string.sub(device, -1, -1) -- get controller number (xinput3 -> 3)
                local event = {controller = n, connected = false}
                be:executeJS("HookManager.trigger('XInputControllerUpdated', "..tostring(encodeJson(event))..");")
            else
                ui_message(msg)
            end
        end
    end
    return newDevices
end

local function getBindings(devname, guid, productName, pidvid, vehicleName, default)
    -- read the default bindings, then custom diff bindings (if not "default"), join them, and return the resulting (full) list of bindings
    -- taking into that each of both defaults and diffs may not even exist
    local base, diff = nil, nil
    local devicetype = string.split(devname, "%D+")[1] -- strip trailing number, if it exists (xinput0 -> xinput)

    local curvePath = nil -- response curve correction file (lut/log/fcm/csv)
    local curveInverted = false
    if not default then
        curvePath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".lut")
        if not curvePath then
            curvePath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".log")
            if not curvePath then
                curvePath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".fcm")
                if not curvePath then
                    curvePath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".csv")
                end
            end
        else
          curveInverted = true -- only for LUT files
        end
    end

    local diffPath = nil
    if not default then diffPath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".diff") end
    local               basePath = getInputmapPath(devicetype, guid, productName, pidvid, vehicleName, ".json")

    if basePath then base = readBindingsFromDisk(basePath, vehicleName) end
    if diffPath then diff = readBindingsFromDisk(diffPath, vehicleName) end

    local result = applyBindingsDiff(base, diff)
    if curvePath then result = applyResponseCurve(result, curvePath, curveInverted) end
    result.guid, result.vidpid, result.name, result.devicetype = guid, pidvid, productName, devicetype
    return result
end

local function getAllBindings(devices, players)
    local result = {}

    for devname,info in pairs(devices) do
        local player = players[devname]

        -- normal bindings
        local contents = getBindings(devname, info[1], info[2], info[3], nil, false)

        -- vehicle specific bindings
        local vehicle = be:getPlayerVehicle(player)
        if vehicle then
            local vehicleName = vehicle:getJBeamFilename()
            local vehicleContents = getBindings(devname, info[1], info[2], info[3], vehicleName, false)

            -- fill/rewrite metadata (all except bindings themselves: guid, devtype...)
            for k,v in pairs(vehicleContents) do
                if k ~= "bindings" then contents[k] = v end
            end

            -- now append all new bindings
            for _,b in ipairs(vehicleContents.bindings) do
                table.insert(contents.bindings, deepcopy(b))
            end
        end

        for _,b in ipairs(contents.bindings) do b.player = player end
        table.insert(result, {devname = devname, contents = contents})
    end

    return result
end

local function notifyUI(reason)
    WinInput.sendJavaScriptHardwareInfo() -- send devices information from c++ to UI
    local result = { actionCategories= actions.getActionCategories(),
                     actions         = actions.getActions(),
                     bindingTemplate = fillNormalizeBindingDefaults({}),
                     bindings        = M.bindings }
    be:executeJS("HookManager.trigger('InputBindingsChanged', "..tostring(encodeJson(result))..");")
end

local function resetDeviceBindings(devname, guid, name, pidvid, vehicleName)
    -- remove custom user bindings of the desired device, reverting back to beamng-provided defaults
    local basePath = getInputmapPath(devname, guid, name, pidvid, vehicleName, ".json")
    local diffPath = getInputmapPath(devname, guid, name, pidvid, vehicleName, ".diff")
    if basePath then FS:removeFile(basePath) end -- only removed if stored in user folder
    if diffPath then FS:removeFile(diffPath) end -- diffs are only present in user folder
end

-- take a full set of customized bindings, compare them to the defaults (if they exist), and save the resulting diff on disk
local function saveBindingsFileToDisk(data, vehicleName)
    -- compute diff from default to desired data
    resetDeviceBindings(data.devicetype, data.guid, data.name, data.vidpid, vehicleName) -- revert to defaults (so we can read them and use as reference for diff)
    local defaultData = getBindings(data.devicetype, data.guid, data.name, data.vidpid, vehicleName, true)
    local diffData = createBindingsDiff(defaultData, data)

    -- write the diff to disk
    if diffData == nil then return false end
    -- convert from vehicle__actionname to actionname. this name-mangling is needed to prevent collisions with other vehicles' action names
    for _,b in pairs(diffData.bindings or {}) do b.action = actions.uniqueNameToName(b.action, vehicleName) end
    for _,b in pairs(diffData.removed  or {}) do b.action = actions.uniqueNameToName(b.action, vehicleName) end

    local contents = encodeJson(diffData)
    local path = getWritingPath(vehicleName, data.devicetype, data.vidpid)
    if contents == nil then
        log('E', 'bindings', "Couldn't parse bindings data for file: "..path); return false end
    if saveCompiledJBeam(diffData, path) == nil then -- some simple indentation
    --if writeFile(path, contents) == nil then   -- straight dump with no format
        log('E', 'bindings', "Couldn't write bindings file to: "..path);
        return false
    end
    log("D", "bindings", "Custom bindings for "..data.name.." ("..data.devicetype.."/"..data.vidpid..") at: "..path)
end

-- data bindings may have mixed vehicle/generic bindings. split them up and save in separate files when necessary
local function saveBindingsToDisk(data)
    local inputmapTemplate = deepcopy(data)
    inputmapTemplate.bindings = {}

    -- 'inputmaps' will hold the generic ("none") bindings as well as each vehicle's bindings

    -- first we initialize them as empty. this forces empty inputmaps to be saved too (instead of being ignored because UI didn't mention the vehicle in incoming data)
    local inputmaps = { none=deepcopy(inputmapTemplate) }
    for _,vehicle in ipairs(getAllVehicles()) do
        inputmaps[vehicle:getJBeamFilename()] = deepcopy(inputmapTemplate)
    end

    -- then we add them with whatever 'data' came from the UI side
    for _,b in ipairs(data.bindings) do
        local vehicleName = actions.getActions()[b.action].vehicle
        local vehicleNameStr = vehicleName or "none" -- temporarily rename to 'none' for during this function
        b.player = nil -- clear variable used to let UI know which player's binding this is
        table.insert(inputmaps[vehicleNameStr].bindings, b)
    end

    -- save each of the computed split inputmaps to a separate file
    for vehicleNameStr,v in pairs(inputmaps) do
        local vehicleName = vehicleNameStr
        if vehicleName == "none" then vehicleName = nil end
        log("D", "bindings", "Saving "..tableSize(v.bindings).." bindings for vehicle: "..dumps(vehicleName))
        saveBindingsFileToDisk(v, vehicleName)
    end
end

local function notifyGE(reason)
    for i,s in pairs(ActionMap:getList())do
      for j,v in ipairs(s) do
        if v.name:endswith("ActionMap") then -- skip the editor (and similar) action maps
          scenetree[v.name]:clear()
        end
      end
    end

    for _,data in pairs(M.bindings) do
        sendBindingsToGE(data.devname, data.contents.bindings, M.players[data.devname])
    end

    for devname,player in pairs(M.players) do
      be:ensurePlayerSeated(player) -- seat players in cars if necessary
    end
end

local function notifyHydros(veh, ffbConfig)
  veh:queueLuaCommand("hydros.onFFBConfigChanged("..serialize(ffbConfig)..")")
end
local function notifyFFB(reason)
    WinInput.updateFFBBindingParameters()
    local action = "steering"
    for _,veh in ipairs(getAllVehicles()) do
        local FFBID = veh:getFFBID(action) -- will automatically return -1 if no player is seated there with an ffb input controller
        if FFBID < 0 then
            notifyHydros(veh, nil)
            goto cont
        end
        local ffbConfigString = be:getFFBConfig(FFBID)
        local state, ffbConfig = pcall(json.decode, ffbConfigString)
        if state == false then
            log('E', "", "Couldn't decode ffbconfig JSON: "..tostring(ffbConfig))
            notifyHydros(veh, nil)
            goto cont
        end
        if ffbConfig == nil then
            log("E", "", "Got a nil ffbConfig for vehicle with ID "..dumps(veh:getID())..", ffb action "..dumps(action).." and FFFBID "..dumps(FFBID))
            notifyHydros(veh, nil)
            goto cont
        end
        local state, ffbparams = pcall(json.decode, ffbConfig.ffbParams)
        if state ~= true then
            log("E", "", "Couldn't parse FFB params:"..dumps(state).." & "..dumps(ffbparams).."\n"..dumps(ffbConfig.ffbParams))
            notifyHydros(veh, nil)
            goto cont
        end
        ffbConfig.ffbParams = ffbparams
        local response = {}
        response[action] = ffbConfig
        response[action]["FFBID"] = FFBID
        notifyHydros(veh, response)
        ::cont::
    end
end

M.bindings = {}
M.players = {}
local function notifyExtensions(reason)
    extensions.hook('onInputBindingsChanged', M.players)
end
local function notifyAll(reason)
    notifyGE(reason)
    notifyUI(reason)
    notifyFFB(reason)
    notifyExtensions(reason)
end

local function resetAllBindings()
    -- remove all custom user bindings of currently plugged devices, reverting back to beamng-provided defaults

    -- normal bindings
    for devname,info in pairs(M.devices) do
        resetDeviceBindings(devname, info[1], info[2], info[3], nil)
    end
    FS:removeFile(getWritingDir(nil))

    -- vehicle specific bindings
    for devname,info in pairs(M.devices) do
        local vehicle = be:getPlayerVehicle(M.players[devname])
        if vehicle then
            local vehicleName = vehicle:getJBeamFilename()
            resetDeviceBindings(devname, info[1], info[2], info[3], vehicleName)
            FS:removeFile(getWritingDir(vehicleName))
        end
    end
end

-- is called whenever player switches to a new vehicle, or to an existing vehicle, or exits a vehicle is not driving anymore
-- new vehicle may have been added to the level, or it may be replacing an existing vehicle (which gets removed)
-- that's why we simply re-read all vehicles' actions, instead of keeping track of which vehicle went away and which didn't
local function onVehicleChanged(oldVehicle, newVehicle, player)
    local oldName = oldVehicle and oldVehicle:getJBeamFilename() or "<none>"
    local newName = newVehicle and newVehicle:getJBeamFilename() or "<none>"
    if oldName ~= newName then
        actions.updateVehiclesActions()
        M.players = multiseat.getAssignedPlayers(M.devices, true)
        M.bindings = getAllBindings(M.devices, M.players)
    end
    notifyAll("player #"..player.." switched from "..oldName.." to "..newName)
end

local function menuActive(active)
    --log("D", "bindings", "Menu bindings enabled: "..dumps(active))
    scenetree.MenuActionMap:setEnabled(active)
    M.isMenuActive = active
end

local function getAssignedPlayers()
    return M.players
end

local filechangeTimeout = 0 -- seconds
local function updateGFX(dtRaw)
  filechangeTimeout = filechangeTimeout - dtRaw
  if filechangeTimeout <= 0 then
    M.bindings = getAllBindings(M.devices, M.players)
    notifyAll("some inputmap file changed")
    M.updateGFX = nop
    filechangeTimeout = 0
  end
end

local function onFileChanged(filename)
  if string.startswith(filename, "settings/inputmaps/") then
    filechangeTimeout = 0.1 -- seconds
    M.updateGFX = updateGFX
  end
end
local function onDeviceChanged()
  M.devices = updateDevicesList(M.devices)
  M.players = multiseat.getAssignedPlayers(M.devices, true)
  M.bindings = getAllBindings(M.devices, M.players)
  notifyAll("a device changed")
end
local function onMultiseatChanged()
  M.players = multiseat.getAssignedPlayers(M.devices, true)
  M.bindings = getAllBindings(M.devices, M.players)
  notifyAll("multiseat changed")
end
local function deprecatedNotifyAll(reason)
  log("W", "", "bindings.notifyAll has been deprecated in favour of bindings.notifyUI, please rewrite that call. Provided context was: "..dumps(reason))
  notifyUI("DEPRECATED "..dumps(reason))
end

local function init()
  actions.updateVehiclesActions()
  M.devices = updateDevicesList(M.devices)
  M.players = multiseat.getAssignedPlayers(M.devices, true)
  M.bindings = getAllBindings(M.devices, M.players)
  notifyAll("input_bindings.lua init")
end

M.init = init
M.resetAllBindings = resetAllBindings
M.saveBindingsToDisk = saveBindingsToDisk
M.notifyAll = deprecatedNotifyAll
M.notifyUI = notifyUI
M.menuActive = menuActive
M.getAssignedPlayers= getAssignedPlayers
M.onFileChanged = onFileChanged
M.onDeviceChanged = onDeviceChanged
M.onMultiseatChanged = onMultiseatChanged
M.onVehicleChanged = onVehicleChanged
M.updateGFX = nop

return M
