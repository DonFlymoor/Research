-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this extension executes certain tasks that are predefined in a json input file

local M = {}

local N = {} -- work items

local jobfile = '/work.json'

-- -lua extensions.load('util_worker') -console -nouserpath

local function loadMaterialsInPath(path)
  -- old material.cs support
  local matFiles = FS:findFilesByRootPattern( path, 'materials.cs', -1, true, false)
  for k,v in pairs(matFiles) do
    TorqueScript.exec(v)
  end
  local matFiles = FS:findFilesByRootPattern( path, '.material.json', -1, true, false)
  for k,v in pairs(matFiles) do
    Sim.deserializeObjectsFromFile(v, false)
  end
end

local function compileDae(path)
  if not FS:fileExists(path) then
    log('E', 'util_worker.compileDae', 'filename not existing: ' .. tostring(path))
    return false
  end
  local dir, filename, ext = string.match(path, "(.-)([^/]-([^%.]+))$")
  local src = path
  local dst = dir .. filename:sub(1, -4) .. 'cdae'
  local dstData = dir .. filename:sub(1, -4) .. 'meshes.json'

  if compileCollada(src, dst, dstData) == 0 then
    log('I', 'util_worker.compileDae', ' compiled: ' .. tostring(src) .. ' > ' .. tostring(dst))
  else
    log('E', 'util_worker.compileDae', 'unable to compile file: ' .. tostring(src))
  end
  Engine.Render.updateImposters(false)
  return true
end

N.compileMesh = function(w)
  if not w.filename then
    log('E', 'util_worker.compileMesh', 'filename missing: ' .. dumps(w))
    return
  end
  local dir, filename, ext = string.match(w.filename, "(.-)([^/]-([^%.]+))$")
  loadMaterialsInPath(dir)
  compileDae(w.filename)
end

N.testImage = function(w)
  if not FS:fileExists(w.filename) then
    log('E', 'util_worker.testImage', 'filename not existing: ' .. tostring(w.filename))
    return false
  end

  -- TODO: test with w.filename

end

N.compileImposter = function(w)
  Engine.Render.updateImposters(false)
end

N.testMod = function(w)
  extensions.test_testMods.work(w.tagid, w.resource_version_id)
end

N.testVehiclesPerformances = function(w)
  log('I', 'worker', "testVehiclesPerformances: " .. dumps(w.pcFiles))
  extensions.util_saveDynamicData.work(w.pcFiles)
  log('I', 'worker', "testVehiclesPerformances DONE")
end

local function onJobDone(job, totalRunning)
  --log('E', 'onJobDone : ' .. dumps(job) .. ', # = ' .. tostring(totalRunning))
  if totalRunning == 0 then
    shutdown(0)
  end
end

local function work()
  --log('I', 'util_worker', 'working: ' .. tostring(jobfile))
  --TorqueScript.eval("$disableTerrainMaterialCollisionWarning=1;$disableCachedColladaNotification=1;")
  local workItems = jsonReadFile(jobfile)
  if not workItems then
    log('E', 'worker', 'unable to read work items from file: ' .. tostring(jobfile))
  end
  log('I', 'util_worker', tostring(#workItems) .. " items to work off from file " .. tostring(jobfile) .. " ...") -- .. dumps(workItems))

  -- this calls the helper functions in N
  for i = 1, #workItems do
    local w = workItems[i]
    if w.type then
      if N[w.type] then
        N[w.type](w)
      else
        log('E', 'util_worker', " - unknown work type: " .. dumps(w))
      end
    else
      log('E', 'util_worker', " - unknown work type: " .. dumps(w))
    end
  end
  -- we use onJobDone for job tracking :)
  if extensions.core_jobsystem.getRunningJobCount() == 0 then
    -- no jobs? no problem! :)
    shutdown(0)
  end
end

local function onExtensionLoaded()
  Lua:blacklistLogLevel("DA")
  log('I', 'util_worker', 'loaded')
  work()
end

-- interface
M.onExtensionLoaded = onExtensionLoaded
M.onJobDone = onJobDone

return M
