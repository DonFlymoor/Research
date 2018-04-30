--.addVariable("objectCopyFailures", &Con::gObjectCopyFailures)

local M = {}

local logTag = "game.lua"
local gameIsRunning = false

--$Camera::MovementSpeed = 30; not used, we use $Camera::movementSpeed = 30; in core_camera.cs
local function recursiveLoadDatablockFiles(datablockFiles, previousErrors)
  local reloadDatablockFiles = {}

  --Keep track of the number of datablocks that failed during this pass.
  local failedDatablocks = 0

  --Try re-executing the list of datablock files.
  for _, dbFile in pairs(datablockFiles) do 
    if FS:fileExists(dbFile) then
      --Start counting copy constructor creation errors.
      TorqueScript.objectCopyFailures = 0 

      TorqueScript.exec(dbFile)

      --If errors occured then store this file for re-exec later.
      if TorqueScript.objectCopyFailures > 0 then
        table.insert(reloadDatablockFiles, dbFile)
        failedDatablocks = failedDatablocks + TorqueScript.objectCopyFailures
      end
    end
  end

  --Clear the object copy failure counter so that we get console error messages again.
  TorqueScript.objectCopyFailures = -1

  -- If we still have datablocks to retry.
  for _, dbFile in pairs(reloadDatablockFiles) do
    --If the datablock failures have not been reducedfrom the last pass then we must have a real syntax error and not just a bad dependancy.
    if false then -- previousErrors > failedDatablocks then
      gameManager.recursiveLoadDatablockFiles(reloadDatablockFiles, failedDatablocks)
    else
      gameManager.loadDatablockFiles(reloadDatablockFiles, false)
    end
  end
end


local function loadDatablockFiles(datablockFiles, recurse)
  if recurse then
    gameManager.recursiveLoadDatablockFiles(datablockFiles, 9999)
    return
  end

  for _, dbFile in pairs(datablockFiles) do 
    if FS:fileExists(dbFile) then
      TorqueScript.eval("dbFile")
    end
  end
end


-- former onServerCreated from game.cs (not the core one)
local function onCreation()
  -- Create the physics world.
  be:physicsInitWorld()

  -- Load up any objects or datablocks saved to the editor managed scripts
  local datablockFiles = {"art/shapes/particles/managedParticleData.cs", "art/shapes/particles/managedParticleEmitterData.cs","art/decals/managedDecalData.cs","art/datablocks/datablockExec.cs","art/datablocks/managedDatablocks.cs"}

  loadDatablockFiles(datablockFiles, true)
end


local function onDestruction()
  -- Destroy the server physcis world 
  if not gameIsRunning then --should this check be performed? -> should be safe from c++ side (see below)
    --log('E', logTag,"onDestruction(): No game running!")
    return
  end
  be:physicsDestroyWorld()
end


local function onMissionLoaded()
  if gameIsRunning then 
    log('E', logTag, "onMissionLoaded(): End the Game first!")
    return
  end

  gameIsRunning = true
end

local function onMissionEnded()
  --Stop the server physics simulation
  if not gameIsRunning then
    log('E', logTag, "onMissionEnded(): No game running!")
    return
  end
  missionLoad.reset()
  gameIsRunning = false
end

M.onCreation = onCreation
M.onDestruction = onDestruction
M.onMissionEnded = onMissionEnded
M.onMissionLoaded = onMissionLoaded
M.datablockFiles = datablockFiles
M.recursiveLoadDatablockFiles = recursiveLoadDatablockFiles
M.loadDatablockFiles = loadDatablockFiles

return M 