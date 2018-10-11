-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local modKey = nil
local testSkin = nil
local newMod = false

local function copyTemplate(dir, type, mod, key) 
  local files = FS:findFilesByPattern(dir, '*', -1, true, false)

  for k in pairs(files) do 
    local temp = files[k]:gsub(dir, '')
    if key == nil then
      copyfile(files[k], '/mods/unpacked/'.. mod .. '/' .. type .. '/' .. mod .. '/' .. temp)
    else
      copyfile(files[k], '/mods/unpacked/'.. mod .. '/' .. type .. '/' .. key .. '/' .. mod .. '/' .. temp)
    end
  end
end

-- checking all file names within vehicle folder to prevent new mods from overwriting official content
local function validateName(key, modName)
  local files = dirContent('/vehicles/'.. key .. '/')
  local exists = nil;

  for _,v in pairs(files) do
    local temp = string.match(files[_], modName)
    if temp == modName then
      exists = true
      break
    end
  end
  
  return exists
end
-- method used to open mod folder
local function openExplorer(modName)
  Engine.Platform.exploreFolder('/mods/unpacked/'.. modName ..'/')
end     

-- method used to generate skin files
local function createSkin(skinName, key)     
  -- mod directory
  local modDIR = '/mods/unpacked/' .. skinName .. '/vehicles/'.. key ..'/' .. skinName

  -- copying template files to mod directory
  copyTemplate('/ui/modules/modwizard/templates/skin/' .. key .. '/', 'vehicles', skinName, key) 

  -- loading of template files
  local jbeamTemp = readFile(modDIR .. '/' .. key .. '_SKINTEMPLATE.jbeam')     
  local materialTemp = readFile(modDIR .. '/materials.cs')
  local textureFile = readFile(modDIR .. '/' .. key .. '_SKINTEMPLATE.dds')
  local paletteFile = readFile(modDIR .. '/' .. key .. '_SKINTEMPLATE_palette_uv1.dds')

  -- modifying template files with correct values
  local jbeamFile = jbeamTemp:gsub(key .. '_SKINTEMPLATE', skinName)      
  local materialFile = materialTemp:gsub('SKINTEMPLATE', skinName)

  -- saving template files
  writeFile(modDIR .. '/' .. skinName .. '.jbeam', jbeamFile) 
  writeFile(modDIR .. '/materials.cs', materialFile)
  writeFile(modDIR .. '/' .. skinName .. '.dds', textureFile)
  writeFile(modDIR .. '/' .. skinName .. '_palette_uv1.dds', paletteFile)

  -- creating config file
  writeFile(modDIR .. '/' .. skinName .. '.pc',  '"vars":{},"format":2,"model":"' .. key .. '","parts":{"paint_design":"' .. skinName .. '"}') 

  -- creating json file
  writeFile(modDIR .. '/' .. skinName .. '.json',  '{"Configuration": "'.. skinName ..'"}') 

  -- removing unused template files
  FS:removeFile(modDIR .. '/' .. key .. '_SKINTEMPLATE.jbeam')
  FS:removeFile(modDIR .. '/' .. key .. '_SKINTEMPLATE.dds')
  FS:removeFile(modDIR .. '/' .. key .. '_SKINTEMPLATE_palette_uv1.dds')

  testSkin = skinName

  core_modmanager.initDB()
   
end

local function onFreeroamLoaded()
  -- need to check if modwizard has been used or else this replaces vehicle everytime.
  if newMod == true then
    local skinCfg = '/mods/unpacked/' .. testSkin .. '/vehicles/'.. modKey ..'/' .. testSkin .. '/' .. testSkin .. '.pc'
    core_vehicles.replaceVehicle(modKey, { config = skinCfg, color = "0 0 0"})
    newMod = false
  end
end

local function loadSkin(key)
  newMod = true
  modKey = key
  core_levels.startFreeroam("levels/smallgrid/main.level.json");
end

-- method used to generate vehicle files
local function createVehicle(vehicleName) 
  local modDIR = '/mods/unpacked/' .. vehicleName .. '/vehicles/'.. vehicleName
  -- copying template files to mod directory
  copyTemplate('/ui/modules/modwizard/templates/vehicle/VEHICLE_TEMPLATE/', 'vehicles', vehicleName, nil) 
  -- loading of template files
  local jbeamTemp = readFile(modDIR .. '/VEHICLE_TEMPLATE.jbeam')  
  -- modifying jbeam file   
	local jbeamFile = jbeamTemp:gsub('VEHICLE_TEMPLATE', vehicleName)
  -- saving jbeam file
	writeFile(modDIR ..'/' .. vehicleName .. '.jbeam', jbeamFile)
  -- removing unused template file
  FS:removeFile(modDIR .. '/VEHICLE_TEMPLATE.jbeam')
end

-- method used to generate terrain files
local function createTerrain(terrainName)    
  -- copying template files to mod directory
  copyTemplate('/ui/modules/modwizard/templates/terrain/TERRAIN_TEMPLATE/', 'levels', terrainName, nil)
  -- template file names
  local fileNames = {
                      'main.level.json', 'info.json', 'TERRAIN_TEMPLATE.ter', 'TERRAIN_TEMPLATE.terrain.json',
                      'TERRAIN_TEMPLATE.forest.json', 'TERRAIN_TEMPLATE.ter.depth.png', 'TERRAIN_TEMPLATE_preview.jpg'
                    } 
  local tempFileNames = {fileNames[3], fileNames[4], fileNames[5], fileNames[6], fileNames[7]}
  local files = {}
  -- loading of template files
  for i = 1, table.getn(fileNames) do
    files[i] = readFile('/mods/unpacked/'.. terrainName .. '/levels/'.. terrainName .. '/' .. fileNames[i])  
  end
  -- modifying template files
  for i = 1, table.getn(fileNames) do 
    files[i] = files[i]:gsub('TERRAIN_TEMPLATE', terrainName)
    fileNames[i] = fileNames[i]:gsub('TERRAIN_TEMPLATE', terrainName)
  end
  -- writing files
  for i = 1, table.getn(files) do 
    writeFile('/mods/unpacked/'.. terrainName .. '/levels/'.. terrainName .. '/' .. fileNames[i], files[i])
  end
  -- removing unused template files
  for i = 1, table.getn(tempFileNames) do
    FS:removeFile('/mods/unpacked/'.. terrainName .. '/levels/'.. terrainName .. '/' .. tempFileNames[i])
  end
end

-- method used to generate app files
local function createApp(appName)    
  
end


local function onExtensionLoaded()
  log('D', 'modwizard', 'Lua extension loaded')
end

M.onExtensionLoaded = onExtensionLoaded
M.openExplorer = openExplorer
M.validateName = validateName
M.createSkin = createSkin
M.loadSkin = loadSkin
M.createVehicle = createVehicle
M.createTerrain = createTerrain
M.createApp = createApp
M.createConfig = createConfig
M.onFreeroamLoaded = onFreeroamLoaded

return M