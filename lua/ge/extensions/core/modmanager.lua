-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local ready = nil

local persistencyfile = 'mods/db.json'

local mods = {}
local dbHeader = {}
local modeDef = {
  vehicle= {
    has= {'%.jbeam', 'vehicles/'},
    mountPoint= 'vehicles/'
  },
  terrain= {
    has= {'%.mis', "main.level.json", "main"},
    mountPoint= 'levels/'
  },
  app= {
    has= {'ui/'}
  },
  scenario= {
    has= {'scenarios/'},
    hasnt= {'%.mis'}
  },
  sound= {
    has= {'%.sbeam'},
    hasnt= {'%.jbeam', '%.mis'}
  }
}
local checkStartup = false
local checkingModUpdate = false
local autoMount = true

local function updateTranslations ()
  local files = FS:findFilesByPattern('/locales/', '*.json', -1, true, false)
  local lang = {}

  for _, v in pairs(files) do
    -- this counter could later be used to indcate how much of the specific language is translated
    local index = v:match('.*%/(.*)%.json')
    if lang[index] == nil then
      lang[index] = {files = 1, translations = readJsonFile(v)}
    else
      lang[index] = {files = lang[index].files + 1, translations = tableMergeRecursive(lang[index].translations, readJsonFile(v))}
    end
  end
  -- guihooks.trigger('appJsonDump', {lang = lang, files = files})
  guihooks.trigger('translationFileUpdate', lang)
end


local function sendGUIState()
  --local list = {}
  --for k, v in pairs(mods) do
  --  table.insert(list, v)
  --end
  --guihooks.trigger('ModManagerModsChanged', list)

  local vehicles = {}

  local files = FS:findFilesByPattern('/vehicles/', '*', 0, true, true)
  for _, path in ipairs(files) do
    if string.startswith(path, "/vehicles/") and not string.startswith(path, "/vehicles/mod_info") then
    vehicles[string.sub(path, 20)] = 1
    end
  end
  vehicles = tableKeys(vehicles)

  guihooks.trigger('ModManagerModsChanged', mods)
  guihooks.trigger('ModManagerVehiclesChanged', vehicles)

  guihooks.trigger('InstalledContentUpdate', {context='levels', list=extensions.core_levels.getList()})

end

local function stateChanged()
  -- send new state to gui: as a list
  sendGUIState()
  -- update language and send to ui
  updateTranslations()

  -- and save it to disc (if not in safe mode)
  if not isSafeMode() then
    serializeJsonToFile(persistencyfile, { header = dbHeader, mods = mods}, true)
  end
end

-- this mounts a zipfile to the correct place (backward compatibility)
local function addMountEntryToList(list, filename, mountPoint)
  local entry = {}
  entry.srcPath = filename
  entry.mountPath = mountPoint
  table.insert(list, entry)
end

local function openEntryInExplorer(filename)
  if not mods[filename] then return end

  if mods[filename].unpackedPath then
    Engine.Platform.exploreFolder(mods[filename].unpackedPath)
  end
end

local function mountEntry(filename, mountPoint)
  extensions.hook('onBeforeMountEntry', filename, mountPoint)
  local mountList = {}
  addMountEntryToList( mountList, filename, mountPoint )
  FS:mountList(mountList)
end

local function getModNameFromPath(path)
  local modname = string.lower(path)
  modname = modname:gsub('dir:/', '')
  modname = modname:gsub('mods/', '')
  modname = modname:gsub('repo/', '')
  modname = modname:gsub('unpacked/', '')
  modname = modname:gsub('/', '')
  modname = modname:gsub('.zip$', '')
  --log('I', 'modmanager.getModNameFromPath', "getModNameFromPath path = "..path .."    name = "..dumps(modname) )
  return modname
end

-- checks the type of a mod based on the existing files
-- should be replaced be info comming from the mod as soon as that is available
local function checkType (files)
  local couldBe = {}
  local cannotBe = {}
  local needsMountPoint = {}

  for _, v in pairs(files) do
    for k2, v2 in pairs(modeDef) do
      if v2.has and not couldBe[k2] then
        for _, v3 in pairs(v2.has) do
          if v:find(v3) then
            couldBe[k2] = true
            if v2.mountPoint ~= nil and not v:find(v2.mountPoint) then
              needsMountPoint[k2] = v2.mountPoint
            end
          end
        end
      end

      if v2.hasnt and not cannotBe[k2] then
        for _, v3 in pairs(v2.hasnt) do
          if v:find(v3) then
            cannotBe[k2] = true
          end
        end
      end
    end
  end

  for k, _ in pairs(couldBe) do
    if cannotBe[k] then
      cannotBe[k] = nil
      couldBe[k] = nil
    end
  end

  local keys = tableKeys(couldBe)
  if tableSize(keys) == 1 then
    if needsMountPoint[keys[1]] then
      return {key = keys[1], mountPoint = needsMountPoint[keys[1]]}
    else
      return {key = keys[1]}
    end
  else
    return {key = 'unknown'}
  end
end

local function modsOwnFile(modname,filepath)
  if mods[modname].modData == nil or mods[modname].modData.hashes == nil then return false end
  for k,v in pairs(mods[modname].modData.hashes) do
    v[1] = v[1]:gsub("\\/","/")
    if v[1] == filepath then
      return true
    end
  end
  return false
end

local function checkMod(modname)
  if modname == nil or mods[modname] == nil then return nil end
  --if not FS:isMounted(mods[modname].fullpath) then log('D', 'modmanager.checkMod', "Mods "..modname.." isn't mounted yet"); return nil end
  mods[modname].valid = true
  if mods[modname].modData.hashes then
    local hashes = mods[modname].modData.hashes
    for k,v in pairs(hashes) do
      v[1] = v[1]:gsub("\\/","/")
      if FS:fileExists(v[1]) then
        local hash = FS:hashFile(v[1])
        if hash ~= v[2] then
          log('E', 'modmanager.checkMod', "Mods "..modname.. " have a wrong file : "..v[1].. "  original Hash="..v[2].."  Current Hash="..hash)
          mods[modname].valid = false
        end
      else
          log('E', 'modmanager.checkMod', "Mods "..modname.. " have a missing file : "..v[1])
          mods[modname].valid = false
      end
    end
  else
    log('E', 'modmanager.checkMod', "Mods "..modname.. " doesn't have hash manifest")
    mods[modname].valid = false
  end

  local vehiculesTest =false
  local vehName =""
  mods[modname].conflict = {}
  if mods[modname].modData.hashes ~= nil then
    for k,v in pairs(mods[modname].modData.hashes) do
      v[1] = v[1]:gsub("\\/","/")
      if v[1]:match("vehicles/[%w]+") ~= nil and not vehiculesTest then
        vehName =v[1]:match("vehicles/([%w]+)")
        vehiculesTest = true
      end
    end
    if vehiculesTest and vehName~="" then
      local vfiles = FS:findFilesByRootPattern("/vehicles/"..vehName, "*", -1, true, false)


      for _,vf in pairs(vfiles) do
        if not modsOwnFile(modname,vf) then
          table.insert(mods[modname].conflict,{file=vf, path=FS:getFileRealPath(vf)})
          log('I', 'modmanager.checkMod', "Mods "..modname.." have a file conflict "..dumps({file=vf, path=FS:getFileRealPath(vf)}) )
        end
      end
    end
  end

  log('I', 'modmanager.checkMod', "Mods "..modname.." valid= "..tostring(mods[modname].valid) .. " conflict="..#(mods[modname].conflict or {}) )
  return mods[modname].valid and #mods[modname].conflict == 0
end

-- adds / updates a file in the DB
local function updateZIPEntry(filename)
  local modname = getModNameFromPath(filename)
  local zip = ZipArchive()
  zip:openArchiveName( filename, "R" )
  local filesInZIP = zip:getFileList()

  if mods[modname] and mods[modname].fullpath == filename then
    --log('D', 'modmanager.updateZIPEntry', "mod already known: " .. tostring(filename))

  else
    if FS:isMounted(filename) then
      FS:unmount(filename)
    end
    -- new entry
    local d = {}
    --log('D', 'modmanager.updateZIPEntry', "new DB entry: " .. filename )
    local hash = 'wip' -- FS:hashFile(filename)
    if hash then
      d.hash = string.lower(hash)
      --log('D', 'modmanager.updateZIPEntry', " * " .. tostring(filename) .. " = " .. tostring(hash))
    end

    d.mountPoint = nil -- normally mounts in the game main directory
    d.dateAdded = os.time(os.date('*t'))
    d.stat = FS:stat(filename)

    -- get file list of each zip files
    if FS:isMounted(filename) then
      FS:unmount(filename)
    end
    --local zip = ZipArchive()
    --zip:openArchiveName( filename, "R" )
    --filesInZIP = zip:getFileList()
    --log('D', 'modmanager.updateZIPEntry', "  entries: " .. tostring( #filesInZIP ) )
    --d.files = {}

    local typeHelper = checkType(filesInZIP);
    if typeHelper.mountPoint then
      d.mountPoint = typeHelper.mountPoint
      d.oldFolders = true
    end

    d.modType = typeHelper.key

    -- activated by default
    d.active = true
    d.fullpath = filename
    d.dirname, d.filename = path.split(d.fullpath)

    if filename:find('unpacked/') and filename:endswith('/') then
      d.orgZipFilename = filename:gsub('unpacked/', '')
      d.orgZipFilename = d.orgZipFilename:gsub('.zip/', '/') -- old format
      d.orgZipFilename = d.orgZipFilename:gsub('/$', '')
      d.orgZipFilename = d.orgZipFilename..'.zip'
      d.unpackedPath = filename

      if #FS:findFilesByRootPattern( "/"..filename..'levels/', "*.mis", 1, true, false ) > 0 then d.modType = 'terrain' end
      if #FS:findFilesByRootPattern( "/"..filename..'vehicles/', "*", 0, true, true ) > 0 then d.modType = 'vehicle' end
    end

    d.modname = modname
    mods[d.modname] = d

    --log('D', 'modmanager.updateZIPEntry', "new zip:")
    --dump(d)
  end

  --refresh mod info if file is changed
  for k2, v2 in pairs(filesInZIP) do
    v2 = string.lower(v2)
    local modID = string.match(tostring(v2), '^mod_info/([0-9a-zA-Z]*)/info%.json')
    if modID then
      -- its a repo info file!
      modID = modID:upper()
      mods[modname].modID = modID
      mods[modname].modInfoPath = '/mod_info/'..modID..'/'
      local jsonContent = zip:readFileEntryByIdx(k2)
      if jsonContent then
      mods[modname].modData = readJsonData(jsonContent, tostring(filename) .. ' : ' .. tostring(k2))
      -- fix the relative paths to be absolute paths for the UI
        if type(mods[modname].modData.attachments) == 'table' then
          mods[modname].modData.imgs = {}
          for k2,v2 in pairs(mods[modname].modData.attachments) do
            table.insert(mods[modname].modData.imgs, mods[modname].modInfoPath .. v2.thumb_filename:gsub("\\", "/") )
            --table.insert(d.modData.imgs, d.modInfoPath .. "/images/" .. v2.data_filename:gsub("\\", "/") )
          end
        end
        if type(mods[modname].modData.icon) == 'string' then
          mods[modname].modData.icon = mods[modname].modInfoPath .. mods[modname].modData.icon
        end
      end
      break
    end
  end

  return mods[modname]
end

local function checkDuplicatedMods(filelist)
  local outFilelist = {}
  local uniqueModList = {}
  for _, filepath in ipairs(filelist) do
    local modname = getModNameFromPath(filepath)
    if not uniqueModList[modname] then
      table.insert(outFilelist, filepath)
      uniqueModList[modname] = filepath
    else
      local errMsg = 'Duplicated mod[ '..modname..' ]\n['..uniqueModList[modname]..']\n - ['..filepath..']'
      log('E', 'modmanager.initDB', errMsg)
      guihooks.trigger('modmanagerError', errMsg)
      mods[modname] = nil -- force update DB
    end
  end
  return outFilelist
end

local initDB = extensions.core_jobsystem.wrap(function(job)
  --log('D', 'modmanager.initDB', 'initDB() ...')

  -- check DB version number
  if not dbHeader or dbHeader.version ~= 1.1 then
    mods = {} -- rebuild DB
    dbHeader = { version = 1.1 }
  end

  -- catch new files
  local zipfileList = FS:findFilesByRootPattern( "mods", "*.zip", -1, true, false )
  local unpackedList = FS:findFilesByRootPattern( "mods/unpacked/", "*", 0, true, true )
  --if unpackedList[1] == 'mods/unpacked/' then unpackedList[1] = '' end --fix for previous FS
  local fileList = {}
  for k, v in ipairs(unpackedList) do table.insert(fileList, v) end
  for k, v in ipairs(zipfileList) do table.insert(fileList, v) end
  fileList = checkDuplicatedMods(fileList)

  local mountList = {}
  for k,filename in pairs(fileList) do
    filename = string.lower(filename)
    -- ensure the window is refreshing
    Engine.Platform.repaintCanvas()

    -- mount only zip files and unpacked zip folders
    if string.endswith(filename, '.zip') or FS:directoryExists(filename) then
      -- check for unpacked mods

      if FS:directoryExists(filename) then filename=filename.."/" end

      local mod = updateZIPEntry(filename)
      if mod and isSafeMode() then mod.active = false end
      if mod and mod.active ~= false then
        log('D', 'modmanager.initDB', 'mountEntry -- ' .. tostring(filename) .. ': ' .. (mod.modID or '') .. ' : ' .. (mod.modname or ''))
        addMountEntryToList(mountList, filename, mod.mountPoint)
        job.yield()
      end
    end
  end

  if( #mountList > 0) then
    FS:mountList(mountList)
  end
  --log('D', 'modmanager.initDB', '... finished')

  -- catch deleted files
  for k,v in pairs(mods) do
    if not FS:fileExists(v.fullpath) and not FS:directoryExists(v.fullpath) then
      mods[v.modname] = nil
      log('W', 'modmanager', 'mod vanished: ' .. tostring(v.fullpath))
    end
  end

  --dump(mods)
  stateChanged()
  extensions.load('core_repository') -- load core_repository if not loaded to make sure event gets fired
  if ready ~= true then
    extensions.hook('onModManagerReady')
  end
  ready = true

  -- execute modScripts
  -- TODO deprecated: some modScripts are used to load extensions, added backward compatibility
  local old_loadModule = extensions.load
  extensions.load = function(module)
    log('E', 'modmanager.modScript', 'extensions.luaModule(m) is deprecated for this case, please use registerCoreModule(m)', module)
    old_loadModule(module)
    registerCoreModule(module)
  end

  local modScriptFiles = FS:findFilesByRootPattern('/scripts/', 'modScript.lua', -1, true, false)
  for k,v in ipairs(modScriptFiles) do
    dofile(v)
  end

  modScriptFiles = FS:findFilesByRootPattern('/mods_data/', 'modScript.lua', 1, true, false)
  for k,v in ipairs(modScriptFiles) do
    dofile(v)
  end

  extensions.load = old_loadModule
  loadCoreExtensions()

  if checkStartup and settings.getValue('modAutoUpdates') and Engine.Platform.isNetworkUnrestricted() then
    M.checkUpdate()
    checkStartup = false
  end
end)

local function deactivateAllMods()
  for modname, v in pairs(mods) do
    if FS:isMounted(v.fullpath) then
      FS:unmount(v.fullpath)
    end
    if mods[modname] then
      mods[modname].active = false
    end
  end
  stateChanged()
end



local function onUiReady()
  local data = nil
  data = readJsonFile(persistencyfile)
  if data == nil then
    initDB()
    data = readJsonFile(persistencyfile)
  end

  if data == nil then
    log('W', 'modmanager', 'failed to start up: unable to load persistency file: ' .. tostring(persistencyfile))
    return
  end

  dbHeader = data.header

  if data.mods then
    tableMerge(mods, data.mods)
  end
  initDB()
end


local function safeDelete(filename)
  if not string.startswith(filename, 'mods/') or filename:find("%.%.") ~= nil then
    log('E', 'modmanager', 'unable to delete file: not in mods folder: ' .. filename)
    return false
  end
  if not FS:fileExists(filename) and not FS:directoryExists(filename) then
    return true
  end
  if not FS:removeFile(filename) then
    local errMsg = FS:getLastError() or ''
    log('E', 'modmanager', 'unable to delete file: ' .. filename .. ' : ' .. errMsg)
    return false
  end
  return true
end

local function safeDeleteFolder(folderPath)
  -- delete old files in reverse order for empty folders before try to delete it
  local deleteFileList = FS:findFilesByRootPattern( folderPath, "*", -1, true, true )
  --dump(deleteFileList)
  for i = #deleteFileList, 1, -1 do
    safeDelete( deleteFileList[i] )
  end
  safeDelete(folderPath)
end



-- WIP ZIP interface
--[[
local function test()
  local files = getFilesInDirectory('mods')
  for k, v in pairs(files) do
    --local hash = hashFile(v)
    print(" * " .. tostring(v) .. " = " .. tostring(hash))


    local path, filename, ext = string.match(v, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    local infofile = path .. string.sub(filename, 0, -string.len(ext)-2) .. '.json'
    local data = readJsonFile(infofile)
    if data then
      dump(data)
    end
  end
end
local function testZips()
  print('testZips')
  local fileList = FS:findFilesByPattern( "/mods", "*.zip", -1, true, false )
  for k,v in pairs(fileList) do
    print( "ZIP file: " .. v )

    -- get file list of each zip files
    local zip = ZipArchive()
    zip:openArchiveName( v, "R" )
    local filesInZIP = zip:getFileList()
    print("  entries: " .. tostring( #filesInZIP ) )
    for k2,v2 in pairs(filesInZIP) do
      print( "  " .. v2 )
      if v2:find(".jbeam") then
        local text = zip:readFileEntryByIdx(k2)
        print( "     Contains: " .. text)
      end

    end

    -- test mounting
    print( "  Testing mounting of " .. v)
    print( "     checking isMountedZIP ... RESULT " .. tostring( FS:isMounted(v) ))
    print( "     checking mountZIP ... RESULT " .. tostring( FS:mount(v) ))
    print( "     checking isMountedZIP ... RESULT " .. tostring( FS:isMounted(v) ))
    print( "     checking unmountZIP ... RESULT " .. tostring( FS:unmount(v) ))
    print( "     checking isMountedZIP ... RESULT " .. tostring( FS:isMounted(v) ))

  end
end
--]]

local function deactivateMod(modname)
  if not mods[modname] then
    log('I', 'modmanager.deactivateMod', 'mod not existing ' .. tostring(modname))
    return
  end
  local filename = mods[modname].fullpath
  if FS:isMounted(filename) then
    FS:unmount(filename)
  end
  mods[modname].active = false
  extensions.hook('onModDeactivated', deepcopy(mods[modname]))
  stateChanged()
end

local function getModNameFromID(modID)
  for name,m in pairs(mods) do
    if m.modData ~= nil and m.modData.tagid ~= nil and m.modData.tagid == modID then
      return name
    end
    if name == modID then return modID end
  end
  return nil
end

local function deactivateModId(modID)
  local name = getModNameFromID(modID)
  if name then
      deactivateMod(name)
  else
    log('I', 'modmanager.deactivateModId', 'mod not existing ' .. tostring(modID))
  end
end

local function activateMod(modname)
  if not mods[modname] then
     log('I', 'modmanager.activateMod', 'mod not existing ' .. tostring(modname))
    return
  end
  if not FS:isMounted(mods[modname].fullpath) then
    mountEntry(mods[modname].fullpath, mods[modname].mountPoint)
  end
  mods[modname].active = true
  extensions.hook('onModActivated', deepcopy(mods[modname]))
  stateChanged()
end

local function activateAllMods()
  local mountList = {}
  for modname, v in pairs(mods) do
    if not FS:isMounted(v.fullpath) then
      addMountEntryToList( mountList, v.fullpath, v.mountPoint )
    end
    if mods[modname] then
      mods[modname].active = true
    end
  end
  if( #mountList > 0) then
    FS:mountList(mountList)
  end
  stateChanged()
end

local function deleteMod(modname)
  --print("removeMod")
  --print(hash)
  if not mods[modname] then
    log('I', 'modmanager.deleteMod', 'mod not existing ' .. tostring(modname))
    return
  end
  local filename = mods[modname].fullpath
  if FS:isMounted(filename) then
    FS:unmount(filename)
  end

  if not safeDelete(filename) then return false end
  mods[modname] = nil
  stateChanged()
  return true
end

local function deleteAllMods()
  for mod, v in pairs(mods) do
    if v.dirname == "mods/repo/" then
      deleteMod(mod)
    end
  end
  core_online.apiCall('s2/v4/modUnsubscribeAll')
  stateChanged()
end

local function unpackMod(modname)
  if not mods[modname] then
    guihooks.trigger('modmanagerError', 'Error extracting file:  not existing:' .. tostring(modname))
    return
  end

  local filename = mods[modname].fullpath
  if FS:isMounted(filename) then
    FS:unmount(filename)
  end

  local dir, basefilename, ext = path.split2(filename)
  local targetPathOrg = 'mods/unpacked/' .. basefilename .. '/'
  local targetPath = targetPathOrg

  local zipOldCopy = deepcopy(mods[filename])
  -- auto-corrects the mount point
  if mods[modname].mountPoint then
    targetPath = targetPath .. '/' .. mods[modname].mountPoint .. '/'
    mods[modname].mountPoint = nil
  end
  --print("targetPath: " .. targetPath)

  local zip = ZipArchive()
  if not zip:openArchiveName(filename, 'r') then
    guihooks.trigger('modmanagerError', 'Error unpacking mod[ '..modname.. ' ]. ZIP file is not valid')
    return
  end
  local files = zip:getFileList()
  --dump(files)
  local extractionRes = true
  for i,v in ipairs(files) do
    --print('extractFile: ' .. tostring(v) .. ' -> ' .. tostring(targetPath) .. v)
    if not zip:extractFile(v, targetPath .. v) then
      extractionRes = false
      guihooks.trigger('modmanagerError', 'Error extracting file: ' .. tostring(v))
      log('E', 'modmanager', 'error extracting file: ' .. tostring(v))
    end
  end
  zip:close()

  if not extractionRes then
    safeDeleteFolder(targetPath)
    mods[modname] = zipOldCopy
    guihooks.trigger('modmanagerError', 'Error extracting file: ' .. tostring(v))
    return
  end

  if not safeDelete(filename) then
    guihooks.trigger('modmanagerError', 'Error extracting file: could not safe delete: ' .. tostring(v))
    return false
  end

  FS:mount(targetPathOrg)
  mods[modname].dirname, mods[modname].filename = path.split(targetPathOrg)

  mods[modname].orgZipFilename = filename
  mods[modname].unpackedPath = targetPathOrg
  mods[modname].fullpath = targetPathOrg
  stateChanged()
end

local function packMod(dirPath)
  log('D', 'modmanager', 'Packing : ' .. tostring(dirPath))
  if not dirPath:endswith('/') then
    return
  end
  local modpath, modname, modext = path.split2( dirPath:gsub('/$', '')..'.zip' )
  if not mods[modname] then
    guihooks.trigger('modmanagerError', 'Unable to pack mod: not existing: ' .. tostring(dirPath))
    return
  end
  if not mods[modname].unpackedPath then
    guihooks.trigger('modmanagerError', 'Unable to pack mod: not unpacked: ' .. tostring(filename))
    log('E', 'modmanager', 'unable to pack mod: not unpacked: ' .. tostring(filename))
    return
  end

  if FS:isMounted(mods[modname].unpackedPath) then
    FS:unmount(mods[modname].unpackedPath)
  end

  local zipFilename = mods[modname].orgZipFilename
  if not zipFilename then
    log('E', 'modmanager', 'unable to pack mod: no zip filename')
    guihooks.trigger('modmanagerError', 'Unable to pack mod: no zip existing')
    return false
  end

  safeDelete(zipFilename)

  local zip = ZipArchive()
  zip:openArchiveName(zipFilename, 'w')

  local fileList = FS:findFilesByRootPattern( mods[modname].unpackedPath, "*", -1, true, false )

  for k,v in pairs(fileList) do
    local zipPath = v
    -- copy only files
    if zipPath:startswith(mods[modname].unpackedPath) then
      zipPath = string.sub(zipPath, string.len(mods[modname].unpackedPath) + 1)
      if string.startswith(zipPath, '/') then
        zipPath = string.sub(zipPath, 2)
      end
    end
    log('D', 'modmanager.packMod', 'zip-addfile: ' .. tostring(v) .. ' > ' .. tostring(zipPath))
    zip:addFile(v, zipPath)
  end
  zip:close()

  -- debug output the files in there
  --zip = ZipArchive()
  --zip:openArchiveName(zipFilename, 'r')
  --local files = zip:getFileList()
  --dump(files)
  safeDeleteFolder(mods[modname].unpackedPath)

  mods[modname].unpackedPath = nil
  mods[modname].orgZipFilename = nil


  mods[modname].fullpath = zipFilename
  mods[modname].dirname, mods[modname].filename = path.split(zipFilename)

  stateChanged()
end

local function workOffChangedMod(filename, type)
  -- check if we have mod unpacked
  local modname = getModNameFromPath(filename)
  if mods[modname] and mods[modname].unpackedPath and type == 'added' then
    safeDelete(filename)
    log('E', 'modmanager.onFileChanged', 'You have a unpacked version of [ '..modname..' ]. Need to be Packed before update')
    guihooks.trigger('modmanagerError', 'You have a unpacked version of [ '..modname..' ]. Need to be Packed before update')
    return
  end
  local dir, basefilename, ext = path.split2(filename)
  if ext == 'zip' and FS:fileExists(filename) and (type == 'added' or type == 'modified') then
    log('D', 'modmanager.onFileChanged', tostring(filename) .. ' : ' .. tostring(type) .. ' > ' .. tostring(ext))
    local mod = updateZIPEntry(filename)
    if mod and mod.active ~= false then
      log('D', 'modmanager.onFileChanged', 'activateMod -- ' .. tostring(filename))
      activateMod(mod.modname)
    end
    stateChanged()
  end
end

local function onFileChanged(filename, type)
  if filename:startswith("mods/unpacked") then return end
  if filename:startswith("mods/") and filename:endswith(".zip") and filename ~= persistencyfile and autoMount then
    workOffChangedMod(filename, type)
  end
end

local function isReady()
  return ready
end

local checkUpdate = extensions.core_jobsystem.wrap(function(job)

  if checkingModUpdate == true then return end

  checkingModUpdate = true

  local data = {}

  for k,v in pairs(mods) do
    if v.modData ~= nil and v.modData.tagid ~= nil then
      table.insert(data, {id = v.modData.tagid, ver = (v.modData.resource_version_id or 0)})
    else
      if v.fullpath:match("mods/unpacked") == nil then --no check for unpacked
        log('I', 'modmanager.checkUpdate', 'old mod ' .. tostring(k))
        --[[local wasMounted = false
        if FS:isMounted(v.fullpath) then --TODO FS
          wasMounted = true
          FS:unmount(v.fullpath)
        end
        local zip = ZipArchive()
        if not zip:openArchiveName(v.fullpath, "r") then
          log('E', 'modmanager.checkUpdate', 'error opening zip file for reading: ' .. tostring(v.fullpath))
          goto continue
        end
        local filesInZIP = zip:getFileList()
        log('D', 'modmanager.checkUpdate', "  entries: " .. tostring( #filesInZIP ) )
        table.insert(data, {name = k, hash = {} } )
        data[#data] = filesInZIP
        --]]
        --[[
        for k, v in pairs(filesInZIP) do
          local hash = zip:getFileEntryHashByIdx(k)
          if hash == '' then
            log('E', 'modmanager.checkUpdate', 'unable to hash file in zip: ' .. tostring(v.fullpath) .. ' / ' .. tostring(v))
          else
            table.insert(data[#data].hash, {file = v, hash = hash})
          end
        end

        if wasMounted then
          FS:mount(v.fullpath)
        end--]]
      end
    end
    guihooks.trigger('checkUpdateCheckedMod', k)
    ::continue::
  end
  log('D', 'modmanager.checkUpdate', dumps(data))

  core_online.apiCall('s2/v4/modSync', function(request)
      if request.responseData == nil then
        guihooks.trigger('modmanagerError', 'Server Error')
        log('E', 'modmanager.installMod.downloadFinishedCallback', 'Server Error')
        log('E', 'modmanager.installMod.downloadFinishedCallback', 'url = '..tostring(request.uri))
        log('E', 'modmanager.installMod.downloadFinishedCallback', 'responseBuf = '..tostring(request.responseBuffer))
        return
      end
      --print(dumps( request.responseData) )
      if not request.responseData and request.responseData.ok == 1 then
        log('E', 'modmanager.checkUpdate', 'modSync failed =' .. (request.responseBuffer or "")  )
        guihooks.trigger('modmanagerError', 'Check Update failed')
      else
        for k,v in pairs(request.responseData.data) do
          if v['action'] ~= nil then
            if v['action'] == "deactivate" then
              deactivateModId(v.id)
              guihooks.trigger('modmanagerError', 'You have an outdated version of [ '..tostring(getModNameFromID(v.id))..' ]. This mod have been deactivated`')
            else if v['action'] == "update" or v['action'] == "missing" then
              v.reason = v.action
              log('I', 'modmanager.checkUpdate', tostring(v['action'])..' -- ' .. tostring(v.id) .. "  to " .. tostring(v.ver))
              extensions.core_repository.addUpdateQueue(v)
              else if v['action'] == "404OLD" then
                log('I', 'modmanager.checkUpdate', 'update OLD Didn\'t found any replacement :' .. v.name)
                guihooks.trigger('modmanagerError', "Didn't found replacement for this mod : "..v.name)
                deactivateMod(v.name)
                else
                    log('I', 'modmanager.checkUpdate', 'unknown action for mod ' .. tostring(v.id))
                end
              end
            end
          end
          guihooks.trigger('checkUpdateCheckedMod', "SYNC "..tostring(core_modmanager.getModNameFromID(v.id) or v.filename:gsub(".zip","")) )
          job.yield()
        end
      end
      extensions.core_repository.uiUpdateQueue()
      guihooks.trigger('checkingUpdatesEnd')

      core_repository.updateAllMods()
    end, {
      mods = data,
    })

  guihooks.trigger('ModManagerModsChanged', mods)
  checkingModUpdate = false

end, 500)

local function getConflict(modname)
  if mods[modname] == nil or mods[modname].conflict == nil then return nil end
  return mods[modname].conflict
end

local function getModDB(modname)
  return mods[modname]
end

local function openModFolderInExplorer()
    Engine.Platform.exploreFolder("/mods/")
end

local function modIsUnpacked(modname)
  local modname = getModNameFromPath(modname)
  --log('I', 'modmgmt.modIsUnpacked', modname)
  if mods[modname] == nil then return false end
  --log('I', 'modmgmt.modIsUnpacked', mods[modname].unpackedPath)
  return mods[modname].unpackedPath ~= nil
end

local function check4Update()
  checkStartup = true
end

local function onSettingsChanged()
  if ready == nil then return end
  if settings.getValue('onlineFeatures') == 'enable' then
    checkStartup = true
  end
end

local function disableAutoMount()
  autoMount = false
end

local function enableAutoMount()
  autoMount = true
  initDB()
end

-- public interface
M.isReady = isReady
M.onFileChanged = onFileChanged
M.initDB = initDB

--M.testZips = testZips
M.unpackMod = unpackMod
M.openEntryInExplorer = openEntryInExplorer
M.openModFolderInExplorer = openModFolderInExplorer
M.packMod = packMod
M.onUiReady = onUiReady
M.requestState = sendGUIState
M.requestTranslations = updateTranslations

M.getModNameFromID = getModNameFromID

M.deleteMod = deleteMod
M.deactivateMod = deactivateMod
M.deactivateModId = deactivateModId
M.activateMod = activateMod

M.deactivateAllMods = deactivateAllMods
M.activateAllMods = activateAllMods
M.deleteAllMods = deleteAllMods
M.workOffChangedMod = workOffChangedMod
M.checkMod = checkMod
M.checkUpdate = checkUpdate
M.getConflict = getConflict
M.getModDB = getModDB
M.modIsUnpacked = modIsUnpacked
M.check4Update = check4Update

M.disableAutoMount = disableAutoMount
M.enableAutoMount = enableAutoMount

return M
