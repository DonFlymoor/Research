-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local MT = {} -- metatable
local logTag = 'extensions'

M.state = {
  loadedModules = {} -- keeps track opf loaded modules between reloads. comparison between this and luaMods allows to see the changes that should happen
}

local luaMods = {} -- local var that tracks the loaded modules state

local luaModFunctions = {}
local luaModFunctionsSizes = {}
local packagePathTemp = nil
local deprecatedExtensions = nil

local resolvedModules = {}
local resolvedModuleNameToIndex = {}
local resolvedModuleIndexToName = {}
local disabledModuleHooks = {}

local function extNameToLuaName(extName)
  local dir, filename = string.match(extName, "(.*/)(.*)")

  local res = nil
  if not dir then
    res = extName:gsub('_', '/', 1)
  else
    res = extName
  end
  -- print('>> extNameToLuaName >> ' .. tostring(extName) .. ' ('..tostring(dir)..':'..tostring(filename)..') '.. ' = ' .. tostring(res))
  return res
end

local function isAvailable(extName, noNameConversion)
  --print('isAvailable ? ' .. tostring(extName))
  if package.loaded[extName] then
    return true
  end

  local mName
  if noNameConversion then
    mName = extName
  else
    mName = extNameToLuaName(extName)
  end

  for _, searcher in ipairs(package.searchers or package.loaders) do
    local loader = searcher(mName)
    if type(loader) == 'function' then
      package.preload[mName] = loader
      return true
    end
  end
  return false
end

local function updateFunctionList()
  luaModFunctions = {}
  luaModFunctionsSizes = {}
  for i = 1, (#resolvedModules or 0) do
    local m = resolvedModules[i]
    if type(m) == "table" then
      for functName,v2 in pairs(m) do
        if type(v2) == 'function' then
          if luaModFunctions[functName] == nil then luaModFunctions[functName] = {} end
          table.insert(luaModFunctions[functName], v2)
          luaModFunctionsSizes[functName] = #(luaModFunctions[functName])
        end
      end
    end
  end

  -- process disabled functions
  for functName,disabledList in pairs(disabledModuleHooks) do
    if #disabledList > 0 then
      local curList = luaModFunctions[functName]
      local newList = {}
      for _,disabledFunct in ipairs(disabledList) do
        for i,v in ipairs(curList) do
          if v ~= disabledFunct then
            table.insert(newList, v)
          end
        end
      end

      luaModFunctions[functName] = newList
      luaModFunctionsSizes[functName] = #(luaModFunctions[functName])
    end
  end
end

local function enableHook(module, hookName)
  -- log('I', logTag, 'enableHook called:  '..module.__extensionsName__..'::'..hookName)

  local func = module[hookName]
  if type(func) == 'function' then
    local disabledList = disabledModuleHooks[hookName]
    if disabledList then
      local newList = {}
      for _,disabledFunct in ipairs(disabledList) do
        if func ~= disabledFunct then
          table.insert(newList, func)
        end
      end
      if #newList ~= #disabledList then
        disabledModuleHooks[hookName] = newList
        updateFunctionList()
      end
    end
  end
end

local function disableHook(module, hookName)
  -- log('I', logTag, 'disableHook called:  '..module.__extensionsName__..'::'..hookName)

  local func = module[hookName]
  if type(func) == 'function' then
    if not disabledModuleHooks[hookName] then
      disabledModuleHooks[hookName] = {}
    end

    table.insert(disabledModuleHooks[hookName], func)
    updateFunctionList()
  end
end

local function resolveDependencies()
  -- log('I', logTag, 'resolveDependencies called..')
  local emptyList = {}
  local toResolveModules = shallowcopy(luaMods)
  local sizeResolved = 0
  resolvedModules = {}
  resolvedModuleNameToIndex = {}
  resolvedModuleIndexToName = {}
  repeat
    sizeResolved = #resolvedModules
    for k,m in pairs(toResolveModules) do
      local resolve = true
      for _,v in ipairs(m.dependencies or emptyList) do
        if not resolvedModuleNameToIndex[v] and toResolveModules[v] then
          resolve = false
          break
        end
      end

      if resolve then
        -- log('I', logTag, 'resolving '..k )
        table.insert(resolvedModules, luaMods[k])
        table.insert(resolvedModuleIndexToName, k)
        resolvedModuleNameToIndex[k] = #resolvedModules
        toResolveModules[k] = nil
      end
    end
  until (#resolvedModules == sizeResolved)

  if #toResolveModules > 0 then
    for moduleName,module in pairs(toResolveModules) do
      log('W', logTag, 'could not resolve dependencies for '..moduleName)
      table.insert(resolvedModules, luaMods[moduleName])
      table.insert(resolvedModuleIndexToName, moduleName)
      resolvedModuleNameToIndex[moduleName] = #resolvedModules
    end
  end

  -- dump(resolvedModules)
  updateFunctionList()
end

local function unloadInternal(extName)
  log('D', logTag, 'unloadInternal: '.. tostring(extName))

  local m = rawget(M, extName)

  if m == nil then
    log('I', logTag, 'unable to unload module ' .. tostring(extName) .. ': not loaded')
    return
  end

  if type(m.onUnload) == 'function' then
    log('W', logTag, "Lua extension '".. extName.."' uses deprecated 'onUnload()' method, please use 'onExtensionUnloaded()' instead")
    m.onUnload()
  end

  if type(m.onExtensionUnloaded) == 'function' then
    m.onExtensionUnloaded()
  end

  -- rawset avoids global setter wrapper detections
  rawset(_G, m.__globalAlias__, nil)

  -- unload it finally
  luaMods[extName] = nil
  M[extName] = nil
  M.state.loadedModules[extName] = nil
  package.loaded[extName] = nil
end

local function unload(extName)
  unloadInternal(extName)
  resolveDependencies()
end

M.unloadModule = function(extName)
                   log("W", logTag, "unloadModule(extName) is deprecated. Please switch to unload(extName)")
                   unload(extName)
                 end

local function unloadExcept(...)
  -- log('I', logTag, "unloadExcept called...")
  local exceptionList = {}

  if #{...} > 1 then
    for k,array in pairs({...}) do
      for i, v in pairs(array) do
        table.insert(exceptionList, v)
      end
    end
  else
    exceptionList = ... or {}
  end

  for i = (#resolvedModules or 0), 1, -1 do
    -- check if its null because a previous unload may have also unloaded child extensions e.g. scenario unloads
    -- its extensions so the entry for those extensions here would be null
    if resolvedModules[i] then
      local moduleName = resolvedModules[i].__extensionsName__
      if not tableContains(exceptionList, moduleName) then
        unloadInternal(moduleName)
      end
    end
  end
  resolveDependencies()
end

local function loadInternal(extName, globalAlias, noNameConversion)
  --log('I', logTag, 'loadInternal: '.. tostring(extName)..' , '..tostring(globalAlias)..' , '..tostring(noNameConversion))

  if luaMods[extName] ~= nil then
    --log('D', logTag, 'extension already loaded: '..tostring(extName))
    return true
  end

  local mName
  if noNameConversion then
    mName = extName
  else
    mName = extNameToLuaName(extName)
  end

  if not isAvailable(extName, noNameConversion) then
    log('E', logTag, 'extension unavailable: ' .. tostring(extName)..' at location: '..tostring(mName))
    return false
  end

  local m = require(mName)
  if m.dependencies then
    for _,path in ipairs(m.dependencies) do
      -- log('I', logTag, 'Loading dependency for '..extName..': '..path)
      local dependencyLoaded = loadInternal(path)
      if not dependencyLoaded then
        log('W', logTag, 'Failed to loaded dependency: '..path)
      end
    end
  end

  if type(m) ~= "table" and type(m) ~= "function" then
    log('I', logTag, "Lua extension invalid: " .. mName .. '. Does it return M? It returned this: ' .. tostring(m))
    return false
  end

  if type(m) == "table" then
    -- check for deprecated functions being used in this module
    if deprecatedExtensions then
      for name,data in pairs(deprecatedExtensions) do
        if type(m[name]) == 'function' then
          log('W', logTag, "Lua extension '".. mName.."' uses deprecated '" ..name.."()' function, please use '"..data.replacement.."()' instead")
          if not data.disablePatching and not m[data.replacement] then
            log('W', logTag, "Patching function " ..name.."() to "..data.replacement.."()")
            m[data.replacement] = m[name]
            m[name] = nil
          end
          if data.executeOnModuleLoad then
            local res = m[data.replacement]()
            if type(res) == 'boolean' and res == false and data.returnOnFail then
              log('W', logTag, "Earlying out of loading module "..mName)
              return false
            end
          end
        end
      end
    end

    -- allow the module to refuse loading
    if type(m.onExtensionLoaded) == 'function' then
      local res = m.onExtensionLoaded()
      if type(res) == 'boolean' and res == false then
      return false
      end
    end
  end

  -- check if duplicate?
  if luaMods[extName] then
    log('E', logTag, '*******************************************************************************')
    log('E', logTag, '** Lua extensions name collision while trying to load extension: "' .. extName .. '"')
    log('E', logTag, '** Extensions are case sensitive, but due to the underlying Filesystem, they might load with the wrong case. Please make sure you used the correct case for it.')
    log('E', logTag, '*******************************************************************************')
  end
  -- ok, register now
  luaMods[extName] = m
  M[extName] = m

  globalAlias = globalAlias or extName

  -- also add to global scope:
  rawset(_G, globalAlias, m) -- rawset avoids global setter wrapper detections

  m.__extensionsName__ = extName
  m.__globalAlias__ = globalAlias
  M.state.loadedModules[extName] = true

  --[[
  -- this ignores error mods and does not load them, not used atm
  local ok, m = pcall(require, module)
  if ok then
  luaMods[module] = m
  end
  ]]--
  return true, m
end

local function load(...)
  -- log('I', logTag, "load called...")
  -- dump(...)

  local moduleDataArray = {}
  local numArgs = #{...}
  local noNameConversion = nil
  if numArgs > 1 then
    local lastArg = select(numArgs, ...)
    -- log('I', logTag, "type of lastArg = "..type(lastArg))

    if type(lastArg) == 'boolean' then
      noNameConversion = lastArg
      -- log('I', logTag, "noNameConversion = "..tostring(noNameConversion))
    end
  end

  for k,entry in pairs({...}) do
    local array = entry

    if type(entry) == 'string' then
      array = {entry}
    end

    if type(entry) ~= 'boolean' then
      for i, v in pairs(array) do
        table.insert(moduleDataArray, v)
      end
    end
  end

  local success = true
  if moduleDataArray then
    for _, moduleData in ipairs(moduleDataArray) do
      local extName
      local globalAlias
      if type(moduleData) == 'table' then
        extName = moduleData.extName
        globalAlias = moduleData.globalAlias
      else
        extName = moduleData
        globalAlias = nil
      end

      local loaded , m = loadInternal(extName, globalAlias, noNameConversion)
      if vmType == 'game' and loaded and m and type(m.onInit) == 'function' then
          m.onInit()
      end
      success = success and loaded
    end
    resolveDependencies()
  end

  return success
end

local function addModulePath(directory)
  --local savedPath = package.path
  package.path = directory .. "/?.lua;".. package.path
end

local function loadModulesInDirectory(directory, noNameConversion, excludeSubdirectories)
  -- log('I', logTag, "loadModulesInDirectory called...")
  --[[ -- Game engine version not working on libbeamng side

  local luaFiles = FS:findFilesByPattern(directory, '*.lua', -1, true, false)
  for _,luaFilename in pairs(luaFiles) do
    load(luaFilename:sub(1,-5))  -- strip '.lua'
  end
  ]]

  --local savedPath = package.path
  --package.path = directory .. "/?.lua;".. package.path
  -- addModulePath(directory)
  local filePaths = FS:findFiles(directory, "*.lua", -1, true, false)

  if excludeSubdirectories then
    local processed = {}
    for _, file in ipairs(filePaths) do
      local skip = false
      for _,subDir in pairs(excludeSubdirectories) do
        if string.find(file, subDir) then
          skip = true
          break
        end
      end
      if not skip then
        table.insert(processed, file)
      end
    end
    filePaths = processed
  end

  for _, file in ipairs(filePaths) do
    -- find the lua module files now
    if not file then break end
    if FS:fileExists(file) then
      local dirname, file, ext = path.split(file)
      load(file:sub(1,-5), noNameConversion)
    end
  end
  --package.path = savedPath
  resolveDependencies()
end

local completedCallbacks = {}
local function setCompletedCallback(funcName, callback)
  if callback then
    if not completedCallbacks[funcName] then
      completedCallbacks[funcName] = {}
    end
    table.insert(completedCallbacks[funcName], callback)
  end
end

local function hook(func, ...)
  local funcList = luaModFunctions[func]
  for i = 1, (luaModFunctionsSizes[func] or 0) do
    funcList[i](select(1, ...))
  end
end

local function hookExcept(exceptionList, func, ...)
  local exceptionDict = {}
  for _,value in ipairs(exceptionList) do
    exceptionDict[value] = true
  end

  for i = 1,#resolvedModules do
    local m = resolvedModules[i]
    local modulePath = m.__extensionsModulePath__
    if not exceptionDict[modulePath] then
      if m[func] and type(m[func]) == 'function' then
        m[func](...)
      end
    end
  end
end

local function hookNotify(func, ...)
  -- log("I", logTag, "hookNotify called..."..func)
  hook(func, ...)

  local completedList = completedCallbacks[func]
  if completedList then
    -- dump(completedList)
    for i = 1, (#completedList or 0) do
      completedList[i](select(1, ...))
    end
    completedCallbacks[func] = nil
  end
end

local function hookCount(func)
  return luaModFunctionsSizes[func] or 0
end

local function saveModulePath()
  packagePathTemp = package.path
end

local function restoreModulePath()
  package.path = packagePathTemp
end

local function reload( extPath )
  unload(extPath)
  load(extPath)
end

M.reloadModule =  function(modulePath)
                     log("W", logTag, "reloadModule(modulePath) is deprecated. Please switch to reload(modulePath)")
                     reload( modulePath )
                   end

local function setDeprecatedExtensions(deprecatedList)
    --log('I', logTag, 'setDeprecatedExtensions called..')
    --dump(deprecatedList)
    deprecatedExtensions = deprecatedList
    --log('I', logTag, 'finshed setDeprecatedExtensions')
end

local function getSerializationData(reason)
  if reason == nil then reason = 'reload' end
  local tmp = {}
  if vmType == 'game' then
    tmp['extensions'] = M.state
    local newLoadedModules = {}
    for k,_ in pairs(M.state.loadedModules) do
      table.insert(newLoadedModules, k)
    end
    tmp['extensions'].loadedModules = newLoadedModules

    for i = 1,#resolvedModules do
      local v = resolvedModules[i]
      local k = resolvedModuleIndexToName[i]
      if type(v) == 'table' and (v['onDeserialized'] ~= nil or v['onSerialize'] ~= nil) then
        if type(v['onSerialize']) == 'function' then
          -- if serialization function is existing, use that
          tmp[k] = v['onSerialize'](reason)
        elseif v['state']  then
          -- if M.state is existing, use only that
          tmp[k] = v.state
        else
          -- fallback: whole M
          tmp[k] = v
        end
      end
    end
  end
  return tmp
end

local function deserialize(data, filter)
  if data == nil then return end
  if vmType == 'game' then
    local extensionsData = data['extensions']
    if extensionsData and extensionsData.loadedModules then
      load(extensionsData.loadedModules)
    end

    for i = 1,#resolvedModules do
      local v = resolvedModules[i]
      local k = resolvedModuleIndexToName[i]
      --print("k="..tostring(k) .. " = " .. tostring(v))
      if (filter == nil or k == filter) and type(v) == 'table' and (v['onDeserialized'] ~= nil or v['onDeserialize'] ~= nil) and data[k] ~= nil then
        if type(v['onDeserialize']) == 'function' then
          -- having a deserilization function? then use that!
          v['onDeserialize'](data[k])
        elseif v['state'] then
          -- only merge M.state
          tableMerge(v['state'], data[k])
        else
          -- merge whole M
          tableMerge(v, data[k])
        end
        if type(v['onDeserialized']) == 'function' then
          v['onDeserialized'](data[k])
        end
      end
    end
  end
end

-- public interface
MT.__index = function(tbl, key)
  if key == nil then return nil end
  --print('__index called: ' .. tostring(tbl) .. ', ' .. tostring(key))
  -- load the module
  tbl.load(key)
  -- return the new module if existing, this only happens once as its cached in M
  return rawget(M, key)
end

-- backward compatibility things below
M.loadModule = function(extName)
  log("W", logTag, "loadModule(extName) is deprecated. Please switch to load(extName)")
  load(extName)
end

M.use = function(key)
  load(key)
  --log("W", logTag, "use(extName) is deprecated. Please use the following syntax: core_extensions.<modulename>.doSomething()")
  return rawget(M, key)
end

-- normal interface

M.load = load
M.loadModulesInDirectory = loadModulesInDirectory
M.reload = reload
M.unload = unload
M.unloadExcept = unloadExcept
M.hook = hook
M.hookExcept = hookExcept
M.hookNotify = hookNotify
M.hookCount = hookCount
M.setDeprecatedExtensions = setDeprecatedExtensions
M.belongsToExtensions = belongsToExtensions
M.addModulePath = addModulePath
M.saveModulePath = saveModulePath
M.restoreModulePath = restoreModulePath
M.getSerializationData = getSerializationData
M.deserialize = deserialize
M.enableHook = enableHook
M.disableHook = disableHook
M.setCompletedCallback = setCompletedCallback

M.onDeserialized = nop
M.onDeserialize = nop
M.onSerialize = nop

setmetatable(M, MT)

--getmetatable(_G).__index = MT.__index

return M