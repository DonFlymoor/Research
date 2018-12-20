-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local filtersWhiteList =
{ "Drivetrain"
, "Type"
, "Config Type"
, "Transmission"
, "Country"
, "Derby Class"
, "Performance Class"
, "Value"
, "Brand"
, "Body Style"
, "Source"
, "Weight"
, "Top Speed"
, "0-100 km/h"
, "0-60 mph"
, "Weight/Power"
, "Off-Road Score"
, "Years"
}

local range = {'Years'}

-- agregates only, attribute stays the same
local convertToRange =
  { 'Value'
  , 'Weight'
  , 'Top Speed'
  , '0-100 km/h'
  , '0-60 mph'
  , 'Weight/Power'
  , "Off-Road Score"
  }

-- so th ui knows when to interpret the data as range
local finalRanges = {}
arrayConcat(finalRanges, range)
arrayConcat(finalRanges, convertToRange)

local displayInfo =
{ ranges =
  { all = finalRanges
  , real = range
  }
, units =
  { Weight = {type = 'weight', dec = 0}
  , ['Top Speed'] = {type = 'speed', dec = 0}
  , ['Torque'] = {type = 'torque', dec = 0}
  , ['Power'] = {type = 'power', dec = 0}
  , ['Weight/Power'] = {type = 'weightPower', dec = 2}
  }
, predefinedUnits =
  { ['0-60 mph'] = {unit = 's', type = 'speed', ifIs = 'mph', dec = 1}
  , ['0-100 mph'] = {unit = 's', type = 'speed', ifIs = 'mph', dec = 1}
  , ['0-200 mph'] = {unit = 's', type = 'speed', ifIs = 'mph', dec = 1}
  , ['60-100 mph'] = {unit = 's', type = 'speed', ifIs = 'mph', dec = 1}
  , ['60-0 mph'] = {unit = 'ft', type = 'length', ifIs = 'mph', dec = 1}
  , ['Braking G'] = {unit = '', type = 'length', ifIs = 'mph', dec = 1}
  , ['0-100 km/h'] = {unit = 's', type = 'speed', ifIs = 'km/h', dec = 1}
  , ['0-200 km/h'] = {unit = 's', type = 'speed', ifIs = 'km/h', dec = 1}
  , ['0-300 km/h'] = {unit = 's', type = 'speed', ifIs = 'km/h', dec = 1}
  , ['100-200 km/h'] = {unit = 's', type = 'speed', ifIs = 'km/h', dec = 1}
  , ['100-0 km/h'] = {unit = 'm', type = 'length', ifIs = 'mm', dec = 1}
  , ['Braking G'] = {unit = '', type = 'length', ifIs = 'mm', dec = 1}
  }
, dontShowInDetails =
  { 'Type'
  , 'Config Type'
  }
, perfData =
  { '0-60 mph'
  , '0-100 mph'
  , '0-200 mph'
  , '60-100 mph'
  , '60-0 mph'
  , '0-100 km/h'
  , '0-200 km/h'
  , '0-300 km/h'
  , '100-200 km/h'
  , '100-0 km/h'
  , 'Braking G'
  , 'Top Speed'
  , 'Weight/Power'
  , 'Off-Road Score'
  }
, filterData = filtersWhiteList
}

-- TODO: Think about only operating on cache and not cache + local vairable in function

local files
local filesJBEAM
local filesPC

local showPcs = settings.getValue('showPcs')

local _modelNames

local SteamLicensePlateVehicleId

local cache = {}

local cacheCleared = false

local function _parseVehicleNameBackwardCompatibility(vehicleName)
    --print("_parseVehicleNameBackwardCompatibility: " .. tostring(vehicleName))

    -- get name.cs
    local nameCS = "vehicles/" .. vehicleName .. "/name.cs"
    local res = { configs = {} }
    local f = io.open(nameCS, "r")
    if f then
        for line in f:lines() do
            --print(line)
            local key, value = line:match("^%%(%w+)%s-=%s-\"(.+)\";")
            --print("key = " .. tostring(key))
            --print("value = " .. tostring(value))
            if key ~= nil and key == "vehicleName" and value ~= nil then
                res.Name = value
            end
        end
        f:close()
    end

    -- get .pc files and fix them up for the new system
    local pcfiles = FS:findFilesByRootPattern("vehicles/" .. vehicleName .. "/", "*.pc", 0, true, false)
    for k,v in pairs(pcfiles) do
        local dir, filename, ext = path.split(v)
        if dir and filename and ext and ext == "pc" then
            local pcfn = filename:sub(1, #filename - 3)
            res.configs[pcfn] = { Configuration = pcfn}
        end
    end

    --really no name? :(
    if res.Name == nil then
        res.Name = vehicleName
    end

    -- bold assumption :|
    res.Type = "Car"

    return res
end




local function _fillAggregates(data, destination)
  for key, value in pairs(data) do
    if tableContains(range, key) then
      if not destination[key] then
        destination[key] = deepcopy(data[key])
      end

      destination[key].min = math.min(data[key].min, destination[key].min)
      destination[key].max = math.max(data[key].max, destination[key].max)
    elseif tableContains(convertToRange, key) then
      if type(data[key]) == 'number' then
        if not destination[key] then
          destination[key] = {min = data[key], max = data[key]}
        end
        destination[key].min = math.min(data[key], destination[key].min)
        destination[key].max = math.max(data[key], destination[key].max)
      end
    elseif tableContains(filtersWhiteList, key) then
      if not destination[key] then
        destination[key] = {}
      end

      destination[key][value] = true
    end
  end
end

local function _mergeAggregates(data, destination)
  for key, value in pairs(data) do
    if tableContains(range, key) or tableContains(convertToRange, key) then
      if not destination[key] then
        destination[key] = deepcopy(data[key])
      end

      destination[key].min = math.min(data[key].min, destination[key].min)
      destination[key].max = math.max(data[key].max, destination[key].max)
    elseif tableContains(filtersWhiteList, key) then
      if not destination[key] then
        destination[key] = deepcopy(data[key])
      else
        for key2, _ in pairs(value) do
          destination[key][key2] = true
        end
      end

    end
  end
end

local function addDirs(f)
  local outfiles = {}
  local prevDir = ''
  for i = 1, #f do
    local dir = string.match(f[i], '^(.*/)[^/]*$')
    if dir ~= prevDir then
      prevDir = dir
      table.insert(outfiles, 'DIR:'..dir)
    end
    table.insert(outfiles, f[i])
  end
  return outfiles
end

-- gets all files related to vehicle info
local function _getFiles ()
  local jfiles = FS:findFilesByRootPattern("vehicles/", "*.j*\t*.pc", -1, true, false)
  files = {}
  filesJBEAM = {}
  filesPC = {}
  for _, f in ipairs(jfiles) do
    if string.sub(f, -5) == '.json' then
      table.insert(files, f)
    elseif string.sub(f, -6) == '.jbeam' then
      table.insert(filesJBEAM, f)
    elseif string.sub(f, -3) == '.pc' then
      table.insert(filesPC, f)
    end
  end
  files = addDirs(files)
  filesJBEAM = addDirs(filesJBEAM)
  filesPC = addDirs(filesPC)

  -- files       = FS:findFilesByRootPattern("vehicles/", "*.json", -1, true, true)
  -- filesJBEAM  = FS:findFilesByRootPattern("vehicles/", "*.jbeam", -1, true, true)
  -- filesPC     = FS:findFilesByRootPattern("vehicles/", "*.pc", 1, true, true)
end

-- returns all found model names
local function getModelNames ()
  if _modelNames then
    return _modelNames
  end

  -- name of a file or directory can have alphanumerics, hyphens and underscores.
  local modelRegex  = "vehicles/([%w|_|%-|%s]+)/$"

  if files == nil or filesJBEAM == nil then
    _getFiles()
  end

  local modelNames = {}

  -- Get the models. They are the directories one level under vehicles folder
  for _, path in ipairs(files) do
    if string.sub(path, 1, 4) == "DIR:" then
      local model = string.match(path, modelRegex)
      if model then
        table.insert(modelNames, model)
      end
    end
  end

  -- fix bad vehicle mods without info.json :(
  for _, path in ipairs(filesJBEAM) do
    if string.sub(path, 1, 4) == "DIR:" then
      local model = string.match(path, modelRegex)
      if model and model ~= "common" and not tableContainsCaseInsensitive(modelNames, model) then
        table.insert(modelNames, model)
        log("E", "vehicles", "Vehicle '" .. model .. "' missing info.json")
      end
    end
  end
  _modelNames = modelNames
  return modelNames
end



-- Get the configuration-names for the specific model, i.e. the .json files inside model's folder
local function _getModelConfigNames (key, pcs, includePath)
  if key and tableContainsCaseInsensitive(getModelNames(), key) then
    local configRegex = "vehicles/"..escape_magic(key).."/info_(.*)%.json"
    local configRegexPcs = "vehicles/"..escape_magic(key).."/(.*)%.pc"
    local configNames = {}
    local list = {}

    for _, path in ipairs(files) do
      local config = string.match(path, configRegex)

      if config then
        table.insert(configNames, config)
        list[path] = config
      end
    end

    if pcs then
      for _, path in ipairs(filesPC) do
        local config = string.match(path, configRegexPcs)

        if config and not tableContains(configNames, config) then
          table.insert(configNames, config)
          list[path] = config
        end
      end
    end

    if includePath then
      return list
    else
      return configNames
    end
  end

  return {}
end



local function _modelConfigsHelper (key, model, ignoreCache, pcs)
  if key and tableContainsCaseInsensitive(getModelNames(), key) then

    if cache[key].configs and not ignoreCache then
      return cache[key].configs
    end

    if not cache[key].configs then
      cache[key].configs = {}
    end

    local configNames = _getModelConfigNames(key, pcs, true)

    local configs = {}

    for path, configName in pairs(configNames) do
      local fn = "vehicles/" .. key .. "/info_" .. configName .. ".json"
      local readData = {}
      if FS:fileExists(fn) then
        readData = jsonReadFile(fn)
        if readData == nil then
          log('E', 'vehicles', 'unable to read info file, ignoring: '.. fn)
          readData = {}
        end
      else
        log('W', 'vehicles', 'unable to find info file: '.. fn)
      end

      if isOfficialContent(FS:getFileRealPath(path)) then
        readData.Source = 'BeamNG - Official'
      elseif string.sub(path, -3) == '.pc' then
        readData.Source = 'Custom'
      else
        readData.Source = 'Mod'
      end

      local configData = readData

      if model.default_pc == nil then
        model.default_pc = configName
      end

      -- makes life easier
      configData.model_key = key
      configData.key = configName
      configData.aggregates = {}

      if not configData.Configuration then
        configData.Configuration = configName
      end
      configData.Name = model.Name .. " " .. configData.Configuration

      configData.preview = imageExistsDefault('/vehicles/' .. key .. '/' .. configName .. '.png')

      if configData.default_color ~= nil and configData.default_color ~= '' then
        if not model.colors then
          model.colors = model.colors or {}
          log('E', 'vehicles', key..':'..configName..': cannot set default color for model with no colors data.')
        end

        configData.default_colorname = configData.default_color
        configData.default_color = model.colors[configData.default_colorname]
      end

      if configData.Value then --if we have a value number
        configData.Value = tonumber(configData.Value) or configData.Value --make sure it's actually a NUMBER and not a string
      end

      configData.is_default_config = (configName == model.default_pc)

      if readData then
        _fillAggregates(readData, configData.aggregates)
      end

      configs[configName] = configData
    end

    return configs
  end

  return nil
end



-- get all info to one model
local function getModel (key, ignoreCache, forcePcs)
  if key and tableContainsCaseInsensitive(getModelNames(), key) then
    if cache[key] and not ignoreCache then
      return cache[key]
    end

    if not cache[key] then
      cache[key] = {}
    end


    local model = {}

    local data = jsonReadFile("vehicles/"..key.."/info.json")

    local fixedVehicle = false
    if data == nil then
      data = _parseVehicleNameBackwardCompatibility(key)
      fixedVehicle = true
    end

    local realPath = FS:getFileRealPath("vehicles/"..key.."/info.json")

    -- Patch up old vehicles for new System
    local missingInfoConfigs = nil;
    if data.configs then
      missingInfoConfigs = data.configs
      for mConfigName, mConfig in pairs(missingInfoConfigs) do
        mConfig.is_default_config = false
        if not data.default_pc then
          data.default_pc = mConfigName
          mConfig.is_default_config = true
        end
        mConfig.aggregates = {}
        mConfig.Configuration = mConfigName
        mConfig.Name = data.Name .. ' ' .. mConfigName
        mConfig.key = mConfigName
        mConfig.model_key = key
        mConfig.preview = imageExistsDefault('/vehicles/' .. key .. '/' .. mConfigName .. '.png')
      end
      data.configs = nil
    end

    if data then
      model = deepcopy(data)

      if not data.Type then
        model.Type = "Unknown"
        --log('E', 'vehicles', "model" .. dumps(model) .. "has type \"Unknown\"")
      end

      model.aggregates = {} -- values for filtering
    end

    -- get preview if it exists
    model.preview = imageExistsDefault('/vehicles/' .. key .. '/default.png')

    if  FS:fileExists("vehicles/" .. key .. "/logo.png") then
      model.logo = "/vehicles/" .. key .. "/logo.png"
    end

    if model.default_color then
      model.default_colorname = model.default_color
      model.default_color = model.colors[model.default_colorname]
    else
      model.default_color = ""
      model.default_colorname = ""
    end

    model.key = key -- redundant but makes life easy

    cache[key].model = model

    cache[key].configs = missingInfoConfigs or _modelConfigsHelper(key, model, ignoreCache, showPcs or forcePcs)

    if cache[key].configs and tableSize(cache[key].configs) < 1 then
      cache[key].configs[key] = deepcopy(model)
      if (cache[key].configs[key].model_key == nil) then
        cache[key].configs[key].model_key = cache[key].configs[key].key
      end
      if cache[key].model.default_pc == nil then
        cache[key].model.default_pc = key
      end
      if isOfficialContent(realPath) then
        data.Source = 'BeamNG - Official'
      else
        data.Source = 'Mod'
      end
    end

    if fixedVehicle then
      data.Source = 'Mod'
    end

    if data then
      _fillAggregates(data, model.aggregates)
    end

    local aggHelper = {}
    for _, config in pairs(cache[key].configs) do
      _mergeAggregates(config.aggregates, aggHelper)
    end
    _mergeAggregates(aggHelper, cache[key].model.aggregates)

    return cache[key]
  end

  return nil
end

local function getVehicle()
  local mydataobj={}
  local myObj = be:getPlayerVehicle(0)
  if myObj then
    mydataobj.model = myObj:getField('JBeam','0')
    mydataobj.configuration = myObj:getField('partConfig', '0')--jsonEncode(myObj.partConfig:c_str())
    mydataobj.position = myObj:getField('position','0')
    mydataobj.color = myObj:getField('color', "0")
  end
  return mydataobj
end

-- returns the key of the current vehicle (of player one)
-- one could also use: be:getPlayerVehicle(0):getJBeamFilename()
local function getCurrentVehicleDetails ()
  local res=getVehicle()
  res.key = res.model
  res.model = nil
  local model = getModel(res.key) or {}
  local config = {}
  local default = res.configuration == "settings/default.pc"
  if res.configuration ~= nil then
    res.config_key = string.match(res.configuration, "vehicles/".. res.key .."/(.*).pc")
    res.pc_file = res.configuration
    res.configuration = nil
    config = model.configs[res.config_key]
  end
  return {current = res, model = model.model, configs = config, userDefault = default}
end


local function createFilters (list)
  local filter = {}

  if list then
    for _, value in pairs(list) do
      for propName, propVal in pairs(value.aggregates) do

        if tableContains(finalRanges, propName) then
          if filter[propName] then
            filter[propName].min = math.min(value.aggregates[propName].min, filter[propName].min)
            filter[propName].max = math.max(value.aggregates[propName].max, filter[propName].max)
          else
            filter[propName] = deepcopy(value.aggregates[propName])
          end
        else
          if not filter[propName] then
            filter[propName] = {}
          end
          for key,_ in pairs(propVal) do
            filter[propName][key .. ''] = true
          end
        end
      end
    end
  end

  return filter
end


-- get the list of all available models
local function getModelList (array)
  local models = {}
  local modelNames = getModelNames()

  for _, value in pairs(modelNames) do
    local model = getModel(value)
    if array then
      table.insert(models, model.model)
    else
      models[model.model.key] = model.model
    end
  end

  return {models = models, filters = createFilters(models), displayInfo = displayInfo}
end

-- get the list of all available configurations
local function getConfigList (array)
  local configList = {}
  local modelNames = getModelNames()

  for _, value in pairs(modelNames) do
    local model = getModel(value)
    -- dump(model.configs)
    if model.configs and tableSize(model.configs) > 0 then
      for _, config in pairs(model.configs) do
        if array then
          table.insert(configList, config)
        else
          -- dump(config)
          configList[config.model_key .. '_' .. config.key] = config
        end
      end
    end
  end

  return {configs = configList, filters = createFilters(configList), displayInfo = displayInfo}
end

local function sendPcList ()
  local modelnames = getModelNames()
  local res = {}
  local acceptTypes = {'Custom'}
  -- todo check if in correct folder to exclude vehicles without info.json that aren't from the user himself -yh

  for _, key in pairs(modelnames) do
    local model = getModel(key, true, true)
    for _, v in pairs(model.configs) do
      if tableContains(acceptTypes, v.Source) then
        table.insert(res, v)
      end
    end
  end

  guihooks.trigger('customVehicleList', res);
end


-- get the list of all available vehicles
-- mainly thought for ui
local uiRequestedData = false
local function sendList ()
  uiRequestedData = true
  local models = getModelList(true)
  local configs = getConfigList(true)
  guihooks.trigger('sendVehicleList', {models = models.models, configs = configs.configs, filters = models.filters, displayInfo = displayInfo})
end


local function sendSimpleVehicleList ()
  local models = getModelNames()
  local res = {}
  local acceptTypes = {'Car', 'Truck', 'Automation'}

  for _, key in pairs(models) do
    local model = getModel(key)
    if tableContains(acceptTypes, model.model.Type) then
      local temp = {key = key}
      temp.preview = model.model.preview
      temp.logo = model.model.logo
      temp.configs = {}
      for _, v in pairs(model.configs) do
        -- garage images:
        local short = '/vehicles/' .. v.model_key .. '/' .. v.key .. '_garage_'
        v.previewGarage = imageExistsDefault(short .. 'side.png', '/ui/images/emptyBackground.png')

        if v.is_default_config then
          temp.previewGarage = imageExistsDefault(short .. 'front.png', '/ui/images/emptyBackground.png')
        end
        -- alternate end

        table.insert(temp.configs, v)
      end
      table.insert(res, temp)
    end
  end

  guihooks.trigger('simpleVehicleList', res);
end

local function spawnFilldefaults (key, opt)
  local model = getModel(key)

  -- TODO: crash on invalid vehicle name ... !

  -- dump(model)
  if not opt then
    opt = {}
  end

  local config = model.configs[opt.config] or {}

  if opt.color and type(opt.color) == 'string' and model.model.colors and model.model.colors[opt.color] then
    opt.color = model.model.colors[opt.color]
  end

  if not opt.color and opt.config then
    local config = model.configs[opt.config]
    if config then
      opt.color = config.default_color
    end
  end

  if not opt.color then
    opt.color = model.model.default_color
  end

  opt.color2 = opt.color2 or config.default_color_2 or opt.color
  if opt.color2 and type(opt.color2) == 'string' and model.model.colors and model.model.colors[opt.color2] then
    opt.color2 = model.model.colors[opt.color2]
  end

  opt.color3 = opt.color3 or config.default_color_3 or opt.color
  if opt.color3 and type(opt.color3) == 'string' and model.model.colors and model.model.colors[opt.color3] then
    opt.color3 = model.model.colors[opt.color3]
  end

  if not opt.config then
    opt.config = 'vehicles/' .. key .. '/' .. model.model.default_pc .. '.pc'
  elseif type(opt.config) == 'string' and not string.find(opt.config, '.pc') and FS:fileExists('vehicles/' .. key .. '/' .. opt.config .. '.pc') then
    opt.config = 'vehicles/' .. key .. '/' .. opt.config .. '.pc'
  end

  return opt
end

-- opt: {config, color, pos}
-- config: key
-- color can be a key from the colors list or an rgb string with spaces as seperators i.e "5 5 5"
-- pos should be a string with xyz coordinates as string with spaces as seperators i.e "5 5 5"
local function sanitizeOptions(key, opt)
  local options = spawnFilldefaults(key, opt)

  if type(options.color) == 'string' then
    options.color = stringToTable(options.color, '%s')
  end
  if type(options.color2) == 'string' then
    options.color2 = stringToTable(options.color2, '%s')
  end
  if type(options.color3) == 'string' then
    options.color3 = stringToTable(options.color3, '%s')
  end

  if type(options.color) == 'table' and #options.color == 4 then
    options.color = ColorF(options.color[1], options.color[2], options.color[3], options.color[4])
  else
    options.color = nil
  end
  if type(options.color2) == 'table' and #options.color2 == 4 then
    options.color2 = ColorF(options.color2[1], options.color2[2], options.color2[3], options.color2[4])
  else
    options.color2 = nil
  end
  if type(options.color3) == 'table' and #options.color3 == 4 then
    options.color3 = ColorF(options.color3[1], options.color3[2], options.color3[3], options.color3[4])
  else
    options.color3 = nil
  end

  options.licenseText = opt.licenseText
  options.vehicleName = opt.vehicleName

  options.rot = quat(1, 0, 0, 0)
  local dir = vec3(0, -1, 0)

  if getCamera() and getCamera():isSubClassOf('BeamNGVehicle') then
    local playerVehicleID = be:getPlayerVehicleID(0)
    for k, v in pairs(map.objects) do
      if k == playerVehicleID then
        dir = v.dirVec:normalized()
        options.rot = quatFromDir(dir)
      end
    end
    if not options.pos then
      local playerVehicle = be:getPlayerVehicle(0)
      local offset = vec3(-dir.y, dir.x, 0)
      options.pos = vec3(playerVehicle:getPosition()) + offset * 5
    end
  else
    if not options.pos then
      options.pos = vec3(0, 0, 0)
    end

    local camera = commands.getCamera(commands.getGame())
    if camera then
      options.pos = camera:getPosition();
      local camRot = camera:getRotation()
      options.rot = quat(camRot.x, camRot.y, camRot.z, camRot.w)
    end
  end

  return options
end

local function finalizeSpawn(options)
  local firstVehicle = (be:getObjectCount() == 0)
  if firstVehicle then
    local player = 0
    be:enterNextVehicle(player, 0) -- enter any vehicle
  end
  commands.setGameCamera()

  local vehicle = be:getPlayerVehicle(0)
  if options.licenseText then
    vehicle:setDynDataFieldbyName("licenseText", 0, options.licenseText)
  end

  if options.vehicleName then
    vehicle:setField('name', '', options.vehicleName)
  end

  if be:getObjectCount() > 1 then
    ui_message("Press [action=switch_next_vehicle] or [action=switch_previous_vehicle] to switch vehicle", 10, "spawn")
  end
end

local function spawnNewVehicle (key, opt)
  local options = sanitizeOptions(key, opt)

  spawn.spawnVehicle(key, options.config, options.pos, options.rot, options.color, options.color2, options.color3)

  finalizeSpawn(options)
end

local function replaceCurrentVehicle (key, opt)
  local options = sanitizeOptions(key, opt)

  local playerVehicle = be:getPlayerVehicle(0)
  spawn.setVehicleObject(playerVehicle, key, options.config, options.pos, options.rot, options.color, options.color2, options.color3)

  finalizeSpawn(options)
end

local function removeCurrent()
  local veh = be:getPlayerVehicle(0)
  if veh then
    if be:getObjectCount() == 1 then
      commands.setFreeCamera() -- reuse current vehicle camera position for free camera, before removing vehicle
    end
    veh:delete()
  end
  if be:getObjectCount() > 0 then
    local player = 0
    be:enterNextVehicle(player, 0) -- enter any vehicle
  end
end

-- opt: {config, color, reload}
-- config: key
-- color can be a key from the colors list or an rgb string with spaces as seperators i.e "5 5 5"
local function replaceVehicle (key, opt)
  -- when no vehicle is spawned, spawn a new one instead
  if be:getObjectCount() == 0 then
    spawnNewVehicle(key, opt)
    return
  else -- spawn new vehicle in place and remove current
    local current = be:getPlayerVehicle(0)
    opt.pos = current:getPosition()
    opt.vehicleName = current:getField('name', '')
    replaceCurrentVehicle(key, opt)
  end
end

local function removeAllExceptCurrent()
  local lveh = be:getPlayerVehicle(0)
  local vid = lveh and lveh:getID()
  while be:getObjectCount() > 1 do
    for i = 0, be:getObjectCount() do
      local veh = be:getObject(i)
      if veh and veh:getID() ~= vid then
        veh:delete()
      end
    end
  end
end

local function cloneCurrent()
  local veh = be:getPlayerVehicle(0)
  local vehicleObjWrapper = veh and scenetree.findObject(veh:getID())
  if not veh or not vehicleObjWrapper then
    log('E', 'vehicles', 'unable to clone vehicle: player 0 vehicle not found')
    return false
  end

  -- we get the current vehicles parameters and feed it into the spawning function
  local jbeam = vehicleObjWrapper.JBeam
  local options = {
    config = vehicleObjWrapper.partConfig,
    color = {vehicleObjWrapper.color.x, vehicleObjWrapper.color.y, vehicleObjWrapper.color.z, vehicleObjWrapper.color.w},
    color2 = {vehicleObjWrapper.colorPalette0.x, vehicleObjWrapper.colorPalette0.y, vehicleObjWrapper.colorPalette0.z, vehicleObjWrapper.colorPalette0.w},
    color3 = {vehicleObjWrapper.colorPalette1.x, vehicleObjWrapper.colorPalette1.y, vehicleObjWrapper.colorPalette1.z, vehicleObjWrapper.colorPalette1.w}
  }
  --options.config = options.config:gsub('\"', '\\\"') -- fixes things, still horrible ...
  spawnNewVehicle(jbeam, options)
end

local function removeAll()
  if be:getPlayerVehicle(0) then
    commands.setFreeCamera() -- reuse current vehicle camera position for free camera, before removing vehicles
  end
  while be:getObjectCount() > 0 do
    local veh = be:getObject(0)
    if veh then
      veh:delete()
    end
  end
end

local function removeAllWithProperty(propertyName, value)
  -- log('I', 'vehicles', 'removeAllWithProperty called with '..propertyName .. ', '..value)
  local deletedVehicle = true
  while deletedVehicle do
    deletedVehicle = false
    for i = 0, be:getObjectCount() do
      local veh = be:getObject(i)
      if veh then
        local sceneVehicle = scenetree.findObjectById(veh:getID())
        -- local name = veh:getField('name', '')
        -- dump(dumps(name)..' : '..dumps(sceneVehicle[propertyName]))
        if sceneVehicle and sceneVehicle[propertyName] == value then
          veh:delete()
          deletedVehicle = true
        end
      end
    end
  end
end

local function loadDefault ()
  if FS:fileExists('settings/default.pc') then
    local data = jsonReadFile('settings/default.pc')
    replaceVehicle(data.model, {config = 'settings/default.pc'})
  end
end

local function spawnDefault ()
  if FS:fileExists('settings/default.pc') then
    local data = jsonReadFile('settings/default.pc')
    spawnNewVehicle(data.model, {config = 'settings/default.pc'})
  else
    spawnNewVehicle(defaultVehicleModel)
  end
end


local function numConfigOfModel (model)
  return tableSize(_getModelConfigNames(model, true))
end

local function saveVehicleConfig(id, file, data)
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then return end
  if type(data) == 'string' then
    data = unserialize(data)
  end
  data.colors = {}
  local colors = vehicle:getColorFTable()
  data.colors[1] = {colors[1].r, colors[1].g, colors[1].b, colors[1].a}
  data.colors[2] = {colors[2].r, colors[2].g, colors[2].b, colors[2].a}
  data.colors[3] = {colors[3].r, colors[3].g, colors[3].b, colors[3].a}
  local res = jsonWriteFile(file, data, true)
  if res then
    guihooks.trigger("VehicleconfigSaved", {})
  else
    log('W', "vehicles.save", "unable to save config: "..fn)
  end
end

local function setVehicleColors(id, colors)
  local vehicle = scenetree.findObjectById(id)
  if not vehicle then return end
  if colors[1] then
    vehicle.color = ColorF(colors[1][1], colors[1][2], colors[1][3], colors[1][4]):asLinear4F()
  end
  if colors[2] then
    vehicle.colorPalette0 = ColorF(colors[2][1], colors[2][2], colors[2][3], colors[2][4]):asLinear4F()
  end
  if colors[3] then
    vehicle.colorPalette1 = ColorF(colors[3][1], colors[3][2], colors[3][3], colors[3][4]):asLinear4F()
  end
end

local function setVehicleColorsNames(id, colors, optional)
  local vehicle = scenetree.findObjectById(id)
  local data = getCurrentVehicleDetails()
  if not vehicle then return end
  if optional ~= nil and vehicle.color == vehicle.colorPalette0 == vehicle.colorPalette1 then return end
  local colortmp = {}
  if colors[1] and data.model.colors[colors[1]] then
    for v in data.model.colors[colors[1]]:gmatch( "([%d.]*)") do
      table.insert(colortmp, tonumber(v) )
    end
    vehicle.color = ColorF(colortmp[1], colortmp[2], colortmp[3], colortmp[4]):asLinear4F()
  end
  colortmp = {}
  if colors[2] and data.model.colors[colors[2]] then
    for v in data.model.colors[colors[2]]:gmatch( "([%d.]*)") do
      table.insert(colortmp, tonumber(v) )
    end
    vehicle.colorPalette0 = ColorF(colortmp[1], colortmp[2], colortmp[3], colortmp[4]):asLinear4F()
  end
  colortmp = {}
  if colors[3] and data.model.colors[colors[3]] then
    for v in data.model.colors[colors[3]]:gmatch( "([%d.]*)") do
      table.insert(colortmp, tonumber(v) )
    end
    vehicle.colorPalette1 = ColorF(colortmp[1], colortmp[2], colortmp[3], colortmp[4]):asLinear4F()
  end
end

local lastClear = 0
local function onPreRender (dt)
  if cacheCleared then
    lastClear = lastClear + dt
    if lastClear > 0.5 then
      guihooks.trigger('VehicleCacheInvalid')
      log('D', 'vehiclesData', 'send list to UI')
      sendList()
      lastClear = 0
      cacheCleared = false
      M.onPreRender = nop
    end
  end
end

local function clearCache ()
  files = nil
  filesJBEAM = nil
  cache = {}
  _modelNames = nil
  cacheCleared = true and uiRequestedData
  --log('D', 'vehiclesData', 'clear cache')
  M.onPreRender = onPreRender
end

local function onFileChanged(filename, type)
  -- TODO: think about only deleting the according data from the cache
  local f = filename
  if string.find(f, 'vehicles/') == 1 or string.find(f, 'mods/') == 1 then
    if string.sub(f, -5) == '.json' or string.sub(f, -6) == '.jbeam' or string.sub(f, -3) == '.pc' then
      clearCache()
    end
    -- sendList() -- DO NOT DO THIS IN HERE - it slows down the whole engine down to a halt when changing multiple files. Every file will be ~600ms delay - will lock up the engine
    -- print('Throw away vehicles.lua\'s cache')
  end
end

local function onSettingsChanged()
  if showPcs ~= settings.getValue('showPcs') then
    clearCache()
    showPcs = settings.getValue('showPcs')
    --sendList() -- DO NOT DO THIS IN HERE - mark it as dirty and do it somewhere else

    -- print('Throw away vehicles.lua\'s cache')
  end
end

local function getVehicleLicenseName(veh)
  if gdcdemo then
    return 'GDC2017'
  end

  if not veh then veh = be:getPlayerVehicle(0) end
  if not veh then return '' end
  if type(veh) == 'number' then
    veh = be:getObjectByID(veh)
  end
  if not veh then return '' end

  local txt = veh:getDynDataFieldbyName("licenseText", 0)
  if txt and txt:len() > 0 then return txt end

  if Steam and Steam.isWorking and Steam.accountLoggedIn and not SteamLicensePlateVehicleId and veh:getID() == be:getPlayerVehicle(0):getID() then
    SteamLicensePlateVehicleId = veh:getID()
    txt = Steam.playerName
    --print("steam username: " .. Steam.playerName)
    txt = txt:gsub('%"', '%\'') -- replace " with '
    -- more cleaning up required?
  else
    local T = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
    txt = T[math.random(1, #T)] .. T[math.random(1, #T)] .. T[math.random(1, #T)] ..'-'..math.random(0, 9)..math.random(0, 9)..math.random(0, 9)..math.random(0, 9)
  end

  veh:setDynDataFieldbyName("licenseText", 0, txt)
  return txt
end

-- nil values are equal last values
local function setPlateText(txt, vehId, designPath)
  local veh = nil
  if vehId then
    veh = be:getObjectByID(vehId)
  else
    veh = be:getPlayerVehicle(0)
  end
  if not veh then return end
  if txt then
    veh:setDynDataFieldbyName("licenseText", 0, txt)
  else
    txt = getVehicleLicenseName(vehId)
  end

  if not designPath then
    designPath = veh:getDynDataFieldbyName("licenseDesign", 0) or ''
  else
    veh:setDynDataFieldbyName("licenseDesign", 0, designPath)
  end

  local design = jsonReadFile(designPath)
 -- dump(design)
  if not design or not design.data then
    if designPath:len() > 0 then
      log('E', 'main', "License plate "..designPath.." not existing")
    end
    local levelPath, levelName, _ = path.split( getMissionFilename() )
    if levelPath then
      local levelName = string.match(levelPath,'levels/(%a+)')
      --log('E', 'main.setPlateText', "levelPath= "..tostring(levelPath).." levelName="..tostring(levelName))
      designPath =  'vehicles/common/licenseplates/'..levelPath:gsub('levels/', '')..'/licensePlate-default.json'
      design = jsonReadFile(designPath)
    end
  end

  if not design or not design.data then
    designPath = 'vehicles/common/licenseplates/default/licensePlate-default.json'
    design = jsonReadFile(designPath)
  end

----adding licenseplate html generator and characterlayout to Json file

  if design then
    if design.data.characterLayout then
      if FS:fileExists(design.data.characterLayout) then
        design.data.characterLayout = jsonReadFile(design.data.characterLayout)
      else
        log('E',tostring(design.data.characterLayout) , ' File not existing')
      end
    else
      design.data.characterLayout= "vehicles/common/licenseplates/default/platefont.json"
      design.data.characterLayout= jsonReadFile(design.data.characterLayout)
    end

    if design.data.generator then
      if FS:fileExists(design.data.generator) then
        design.data.generator = "local://local/" .. design.data.generator
      else
        log('E',tostring(design.data.generator) , ' File not existing')
      end
    else
      design.data.generator = "local://local/vehicles/common/licenseplates/default/licenseplate-default.html"
    end
    veh:createUITexture("@licenseplate-default", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default", 'init("diffuse","' .. txt .. '", '.. jsonEncode(design) .. ');')
    veh:createUITexture("@licenseplate-default-normal", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default-normal", 'init("bump","' .. txt .. '", '.. jsonEncode(design) .. ');')
    veh:createUITexture("@licenseplate-default-specular", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default-specular", 'init("specular","' .. txt .. '", '.. jsonEncode(design) .. ');')
  end
end

local function onVehicleDestroyed(vid) 
  if SteamLicensePlateVehicleId == vid then
    SteamLicensePlateVehicleId = nil
  end
end

--public interface
M.getCurrentVehicleDetails = getCurrentVehicleDetails

M.getModel = getModel
M.requestList = sendList
M.getModelList = getModelList
M.getConfigList = getConfigList
M.requestPcList = sendPcList
M.requestSimpleVehicleList = sendSimpleVehicleList

M.replaceVehicle = replaceVehicle
M.spawnNewVehicle = spawnNewVehicle
M.removeCurrent = removeCurrent
M.cloneCurrent = cloneCurrent
M.removeAll = removeAll
M.removeAllExceptCurrent = removeAllExceptCurrent
M.removeAllWithProperty = removeAllWithProperty
M.loadDefault = loadDefault
M.spawnDefault = spawnDefault

M.numConfigOfModel = numConfigOfModel

M.fillDefaults = spawnFilldefaults

M.clearCache = clearCache

M.onPreRender = onPreRender

-- not sure if needed
M.getModelNames = getModelNames

-- used to delete the cached data
M.onFileChanged = onFileChanged
M.onSettingsChanged = onSettingsChanged
M.saveVehicleConfig = saveVehicleConfig
M.setVehicleColors = setVehicleColors
M.setVehicleColorsNames = setVehicleColorsNames

-- License plate
M.setPlateText = setPlateText
M.getVehicleLicenseName = getVehicleLicenseName

M.onVehicleDestroyed = onVehicleDestroyed

return M
