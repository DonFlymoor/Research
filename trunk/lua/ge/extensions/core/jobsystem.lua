-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--[==[

How to use the job system:

====
local function workItem(job)
...
job.yield()
...
end

extensions.core_jobsystem.create(workItem, 1) -- maxdt in seconds: 1 second is good for background tasks
====

or:

====
local checkUpdate = extensions.core_jobsystem.wrap(function(job)
 ...
 job.yield()
 ...
end, 0.5)
====

maxdt is the time it will yield. So i.e. 1 second means that it will try to yield every time 1 second passed.
Important: It will not interrupt things, so if your code runs for 10 seconds without job.yield(), then the jobsystem cannot do anything. Consider adding more yield's.
--]==]

local M = {}

local coroutines = {}
local runningFct = {}

local disableBackgroundTasks = false

-- create a job, maxdt is in milliseconds
local function create(fct, maxdt, ...)
  if disableBackgroundTasks then
    -- runs things in the foreground
    fct({yield = function() end}, unpack({...}))
    return
  end
  local res =  {
    fct = fct,
    t = coroutine.create(fct),
    maxdt = maxdt or 0.01,
    args = {...},
    hp = hptimer(),
  }
  runningFct[fct] = true
  res.yield = function()
    if coroutine.running() == nil then return end -- not running in a coroutine, do not try to yield
    local dt = res.hp:stop() / 1000
    if dt > res.maxdt then
      --print(" *** yield taken ***: " .. tostring(dt))
      coroutine.yield()
      res.hp:reset()
    else
      --print("*** yield skipped: " .. tostring(dt))
    end
  end

  table.insert(coroutines, res)
  -- return an object they can work with
  return res
end

local function wrap(fct, maxdt)
  return function(...)
    if runningFct[fct] then
      --log('D', 'jobsystem', 'job already running. ' .. debug.traceback())
      return
    end
    create(fct, maxdt, unpack({...}))
  end
end

-- updates all coroutines
local function onUpdate()
  local toRemove = {}
  for i = 1, #coroutines do
    local co = coroutines[i]
    local errorfree, value = coroutine.resume(co.t, co, unpack(co.args))
    if not errorfree then
      log('E', 'jobsystem', "job error: " .. tostring(value) .. ' / ' .. debug.traceback(co.t))
    end

    if coroutine.status(co.t) == "dead" then
      -- queue to be removed
      table.insert(toRemove, i)
    end
  end
  -- remove the things in reverse
  for i = #toRemove, 1, -1 do
    --print('removing entry ' .. tostring(i) .. ' / fct: ' .. tostring(coroutines[i].fct))
    local ci = toRemove[i]
    runningFct[coroutines[ci].fct] = nil
    table.remove(coroutines, ci)
  end
end

-- public interface
M.onUpdate = onUpdate
M.create = create
M.wrap = wrap

return M
