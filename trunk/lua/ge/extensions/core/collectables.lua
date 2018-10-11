-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'collectables'

M.state = {}

local itemsDone = {} -- over all levels
local itemsDoneLevel = {}
local itemsDoneLevelCounter = 0
local currentLocation = ''

local itemsTodo = {}
local itemsTodoCounter = 0
local meshName = 'snowman.dae'
-- local prefabfile = 'mods/winter/snow_is.prefab'
local soundEventName = 'event:>Winter>snowman_IS'
local persistencyFilename = '/settings/cloud/snmg.json' -- snmg = snowman mini game :D
local collectionDistance = 2

-- this is heavy on performance
local function findObjects()
  local sceneObjects = scenetree.findClassObjects('TSStatic')
  local res = {}
  for _, o in ipairs(sceneObjects) do
    o = scenetree.findObject(o)
    if o and o.shapeName:find(meshName) then
      -- Need to get coordinates of each snowman so they can be displayed in UI
      res[o.name] = {1, o:getPosition().x, o:getPosition().y}
    end
  end
  return res
end

local function save()
  serializeJsonToFile(persistencyFilename, itemsDone)
end

local function load()
  -- log('I', logTag, "Step K")

  itemsDone = readJsonFile(persistencyFilename) or {}

  if not itemsDone[currentLocation] then 
    itemsDone[currentLocation] = {} 
  end

  itemsDoneLevel = itemsDone[currentLocation]
  itemsDoneLevelCounter = tableSize(itemsDoneLevel)  
end

local function createSnowmanExtras(obj)
  -- log('I', logTag, "Step J")

  local soundId = Engine.Audio.createSource('AudioDefaultLoop2D', soundEventName)
  local sound = scenetree.findObjectById(soundId)
  sound:setTransform(obj:getTransform())
  sound:setParameter("distance_vehicle", 10000)
  sound:setVolume(1)
  sound:play(-1)

  local base =  createObject('TSStatic')
  base:setTransform(obj:getTransform())
  base:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_base.dae")
  base.scale = Point3F(2, 2, 2)
  base.useInstanceRenderData = true
  base:setField('instanceColor', 0, '0.353 0.745 1 1')
  base:setField('collisionType', 0, "Collision Mesh")
  base:setField('decalType', 0, "Collision Mesh")
  base.canSave = false
  base:registerObject('')

  local particles = createObject('ParticleEmitterNode')
  particles:setTransform(obj:getTransform())
  particles:setPosition(obj:getPosition() + Point3F(0, 0, 1.8))
  particles:setField('emitter', 0, 'BNG_snow_explosion_small_particle')
  particles:setField('dataBlock', 0, 'lightExampleEmitterNodeData1')
  particles:setActive(false)
  particles:registerObject('')

  return { soundId = soundId, baseId = base:getID(), particlesId = particles:getID() }
end

local function deleteSnowmanExtras(t)
  -- log('I', logTag, "Step I")

  local sound = scenetree.findObjectById(t.soundId)
  if sound then sound:stop(-1) end

  local base = scenetree.findObjectById(t.baseId)
  if base then base.hidden = true end

  local particles = scenetree.findObjectById(t.particlesId)
  if particles then particles:setActive(true) end
end

local function informUser()
  -- log('I', logTag, "Step H")

  local collectable = ' snowman'

  if itemsDoneLevelCounter == 0 or itemsDoneLevelCounter > 1 then collectable = ' snowmen'  end
  local message = 'Collected  ' .. tostring(itemsDoneLevelCounter) .. collectable .. ', ' .. tostring(itemsTodoCounter) .. ' to go!'

  -- new message if all snowmen have been collected
  if itemsDoneLevelCounter == (itemsTodoCounter + itemsDoneLevelCounter) then
    message = 'You have found all the snowmen on this map, well done!'
  end

  -- overall check
  local doneGlobal = 0
  for _, v in pairs(itemsDone) do
    doneGlobal = doneGlobal + tableSize(v)
  end
  if doneGlobal >= 90 then
    message = 'You have found all the snowmen - Congratulations!'
    Steam.unlockAchievement('CHRISTMAS_COMPLETE')
  end

  ui_message(message, 10, 'christmas_collection', nil)
end

local function collectObject(objName)
  -- log('I', logTag, "Step G")

  if not itemsTodo[objName] then
    log('E', logTag, 'item not on the TODO list? ' .. tostring(objName))
  end
  scenetree.findObject(objName).hidden = true
  itemsDoneLevel[objName] = 1
  deleteSnowmanExtras(itemsTodo[objName][4])
  itemsTodo[objName] = nil

  itemsDoneLevelCounter = tableSize(itemsDoneLevel)
  itemsTodoCounter = tableSize(itemsTodo)

  save()

  -- Send collected snowman name to UI
  guihooks.trigger('CollectablesUpdate', {collectableName = objName, collectableAmount = itemsDoneLevelCounter})

  informUser()
end

local function onUpdate(dtReal, dtSim, dtRaw)
  if not M.state.enabled then return end

  -- log('I', logTag, "onUpdate called....")

  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then return end
  local vpos = vec3(vehicle:getPosition())

  local nearestDistance = math.huge
  local nearestMatrix = MatrixF(true)

  for o, t in pairs(itemsTodo) do
    if scenetree.findObject(o) then
      local opos = vec3(scenetree.findObject(o):getPosition())
      local dist = (opos - vpos):length()

      local sound = scenetree.findObjectById(t[4].soundId)
      if sound then sound:setParameter("distance_vehicle", dist) end

      if dist < collectionDistance then
        collectObject(o)
        break
      end
    end
  end
end

local function initLogic()
  -- log('I', logTag, "Step E")

  load()

  -- change freeroam layout when mod is enabled so that nav map is visible by default.
  core_gamestate.setGameState('freeroam', 'christmasEvent')

  -- reset values or else they persist on level change
  itemsTodo = {}
  itemsTodoCounter = 0;

  local objects = findObjects()


  log('D', logTag, ' ** level ' .. tostring(currentLocation) .. ' = ' .. dumps(tableKeys(objects)))
  log('D', logTag, ' ** visited objects: ' .. dumps(tableKeys(itemsDoneLevel)))
  for k, o in pairs(objects) do
    if itemsDoneLevel[k] then
      scenetree.findObject(k).hidden = true
    else
      local obj = scenetree.findObject(k)
      itemsTodo[k] = {1, o[2], o[3], createSnowmanExtras(obj)}
      itemsTodoCounter = itemsTodoCounter + 1
      obj.hidden = false
    end
  end

  log('D', logTag, ' ** todo objects: ' .. dumps(tableKeys(itemsTodo)))
  informUser()

  local layout = extensions.core_apps.getLayouts()
  for k,v in pairs(layout.freeroam) do
    if v.directive == "navigation" then log('D', logTag, 'christmas_collection_OK_nav'); return end
  end
  log('D', logTag, 'christmas_collection_no_nav')
  ui_message('You may need to use the Navigation app to find the snowmen more easily', 20, 'christmas_collection_no_nav', nil)
end

local function onClientStartMission(missionFile)
  -- log('I', logTag, "onClientStartMission called..." .. tostring(missionFile))
end

local function onExtensionLoaded()
  -- log('I', logTag, "Step A")

  -- local missionFile = getMissionFilename()
  -- -- log('I', logTag, "module loaded")
  -- -- dump(missionFile)
  -- if missionFile and missionFile:len() > 0 then
  --   onClientStartMission(missionFile)
  -- end
end

local function onExtensionUnloaded()
  -- log('I', logTag, "Step B")
  -- log('I', logTag, "module unloaded")

  -- Removing any spawned collectable objects from the level as collectables have been disabled.
  local prefab = scenetree.findObject("snowmans")
  if prefab then
    prefab:deleteObject()
  end

  -- TODO(DA): Undo any UI changes here e.g. the Nav app
  
  --if soundObj then
  --  Engine.Audio.deleteSource(soundObj)
  --end
end

local function sendUIState()
  -- log('I', logTag, "Step C")

  -- Send snowmen locations to UI
  local totalCollecatables = itemsTodoCounter + itemsDoneLevelCounter
  guihooks.trigger('CollectablesInit', {collectableItems = itemsTodo, collectableAmount = totalCollecatables, collectableCurrent = itemsDoneLevelCounter})
end

local function setupCollectables(configData)
  -- log('I', logTag, "Step D")

  --TODO(AK): Find out why getMissionFilename() fails and returns an empty string
  local missionFile = getMissionFilename()

  if not missionFile then
    log('E', logTag, "No mission filename specified")
    return
  end

  log('I', logTag, "setting up collectables for: " .. missionFile)
  
  TorqueScript.exec('scripts/christmas/levelAudioDatablocks.cs')
  
  local currentLevel = string.match(missionFile, "/?levels/(.-)/") or ''

  if campaign_campaigns and campaign_campaigns.getCampaignActive() then
    currentLocation = campaign_campaigns.getCurrentLocation()
  elseif scenario_scenarios then
    currentLocation = scenario_scenarios.getscenarioName()
  else
    currentLocation = currentLevel
  end

  local prefabfile = 'mods/winter/snow_'..currentLevel..'.prefab'
  local prefab_path = path.split(missionFile)..prefabfile
  if not scenetree.snowmans and FS:fileExists(prefab_path) then
      local prefab = createObject('Prefab')
      prefab.filename = String(prefab_path)
      prefab.canSave = false
      prefab:setPosition(Point3F(0,0,0))
      prefab:registerObject("snowmans");
      scenetree.MissionGroup:addObject(prefab.obj)
  end
  
  initLogic()  
end

local function initialise(configData)
  -- log('I', logTag, "initialise called..." .. dumps(configData))
  
  if configData then
    M.state.configData = configData
    M.state.enabled = configData.enabled or false 
    if configData.enabled then
      setupCollectables(configData)
    else
      extensions.unload("core_collectables")
    end
  end
end

M.onExtensionLoaded     = onExtensionLoaded
M.onExtensionUnloaded   = onExtensionUnloaded
M.onClientStartMission  = onClientStartMission
M.onUpdate              = onUpdate
M.sendUIState           = sendUIState
M.initialise            = initialise

-- cheats :D
M.collectObject = collectObject

return M

-- extensions['scripts/christmas/minigame'].collectObject('s_is_1')