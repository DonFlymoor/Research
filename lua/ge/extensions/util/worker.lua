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

N.compileMeshFolder = function(job, w)
  loadMaterialsInPath(w.path)
  local files = FS:findFilesByRootPattern(w.path, '*.dae', -1, true, false)
  for i = 1, #files do
    job.yield()
    compileDae(files[i])
  end
end

N.compileMesh = function(job, w)
  if not w.filename then
    log('E', 'util_worker.compileMesh', 'filename missing: ' .. dumps(w))
    return
  end
  local dir, filename, ext = string.match(w.filename, "(.-)([^/]-([^%.]+))$")
  loadMaterialsInPath(dir)
  compileDae(w.filename)
end

N.compileImposter = function(job, w)
  Engine.Render.updateImposters(false)
end

local function work(job)
  --log('I', 'util_worker', 'working: ' .. tostring(jobfile))
  --TorqueScript.eval("$disableTerrainMaterialCollisionWarning=1;$disableCachedColladaNotification=1;")
  local workItems = readJsonFile(jobfile)
  if not workItems then
    log('E', 'worker', 'unable to read work items from file: ' .. tostring(jobfile))
  end
  log('I', 'util_worker', tostring(#workItems) .. " items to work off from file " .. tostring(jobfile) .. " ...") -- .. dumps(workItems))

  -- this calls the helper functions in N
  for i = 1, #workItems do
    job.yield()
    local w = workItems[i]
    if w.type then
      if N[w.type] then
        N[w.type](job, w)
      else
        log('E', 'util_worker', " - unknown work type: " .. dumps(w))
      end
    else
      log('E', 'util_worker', " - unknown work type: " .. dumps(w))
    end
  end
  shutdown(0)
end

local function onExtensionLoaded()
  Lua:blacklistLogLevel("DA")
  log('I', 'util_worker', 'loaded')
  extensions.core_jobsystem.create(work, 1) -- yield every second, good for background tasks
end

-- interface
M.onExtensionLoaded = onExtensionLoaded

return M
