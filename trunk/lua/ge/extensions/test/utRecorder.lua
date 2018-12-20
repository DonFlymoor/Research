-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local json = require("json")

local state = 'idle'

local timer = hptimer()
local frameIdStart = 0
local file = nil

local im = extensions.ui_imgui
local windowOpen = im.BoolPtr(false)

local lastFrame = nil
local fileSize = 0

local lastFilename

local vdata = {}

local function stop()
  if file then
    file:close()
  end
  be:queueAllObjectLua('extensions.unload("utRecorder")')
  state = 'idle'
  lastFrame = nil
  fileSize = 0
  vdata = {}
end

local function recordFrame(dtReal, dtSim, dtRaw)
  local frame = {
    Engine.Render.getFrameId() - frameIdStart,
    timer:stop(),
    ActionMap.getInputCommands(),
    vdata
  }
  local data = jsonEncode(frame) .. "\n"
  fileSize = fileSize + #data
  file:write(data)

  vdata = {}
  lastFrame = frame
end

local function driveCar(veh, steering, throttle, brake, parkingbrake)
  veh:queueLuaCommand('input.event("steering", ' .. tostring(-steering) .. ', 1) ; input.event("throttle", ' .. tostring(throttle) .. ', 2) ; input.event("brake", ' .. tostring(brake) .. ', 2) ; input.event("parkingbrake", ' .. tostring(parkingbrake) .. ', 2)')
end

local function simpleAI(vehId, data)
  local veh = be:getObjectByID(tonumber(vehId))
  if not veh then
    log('E', 'utRecorder', 'vehicle not found: ' .. tostring(vehId))
    return
  end

  local targetPos = vec3(data[8])
  local aiDirVec = vec3(veh:getDirectionVector())
  local aiPos = vec3(veh:getPosition())

  local targetVec = (targetPos - aiPos):normalized()
  local dirTarget = aiDirVec:dot(targetVec)
  local dirDiff = -math.asin(aiDirVec:cross(vec3(veh:getDirectionVectorUp())):dot(targetVec))

  local brake = 0
  local throttle = 0
  if veh:getVelocity():len() < data[4] then
    throttle = 1
  else
    --brake = 1
  end
  --print(dirDiff, brake, throttle, 0)
  driveCar(veh, -fsign(dirDiff), brake, throttle, 0)
end

local function playFrame()
  local line = file:read('*line')
  if not line then
    stop()
    return
  end
  local frame = json.decode(line)

  local curFrameId = Engine.Render.getFrameId() - frameIdStart

  if frame[1] ~= curFrameId then
    log('E', 'utRecorder', 'Frame desync')
    stop()
  end

  -- resend input?
  if false then
    for k, v in ipairs(frame[3]) do
      ActionMap.sendInputCommand(unpack(v))
    end
  end

  for vehId, data in pairs(frame[4]) do
    for _, d in ipairs(data) do
      simpleAI(vehId, d)
    end
  end

  lastFrame = frame
end

local function onUpdate(dtReal, dtSim, dtRaw)
  if state == 'rec' then
    recordFrame(dtReal, dtSim, dtRaw)
  elseif state == 'play' then
    playFrame(dtReal, dtSim, dtRaw)
  end
end

local function humanReadableSec(seconds)
  local hours =  math.floor(seconds / 3600)
  local mins = math.floor(seconds / 60 - (hours * 60))
  local secsrem = math.floor(seconds - hours * 3600 - mins * 60)
  return string.format("%02.f:%02.f:%02.f", hours, mins, secsrem)
end

local function prepareSession()
  timer:reset()
  frameIdStart = Engine.Render.getFrameId()

  settings.setValue('FPSLimiter', 40, true) -- do not change fro 40 FPS, this is important to have deterministic physics
  settings.setValue('FPSLimiterEnabled', true, true)

  --be:reloadAllVehicles()
  be:queueAllObjectLua('obj:requestReset(RESET_PHYSICS)')
end

local function startPlayback(fn)
  if state ~= 'idle' then
    log('E', 'utRecorder', 'Can only start playback in idle state')
    return false
  end
  prepareSession()
  file = io.open(fn, 'r')
  --fileSize = file:seek("end")
  --file:seek("set", 0)
  state = 'play'
  return true
end

local function startRecording()
  if state ~= 'idle' then
    log('E', 'utRecorder', 'Can only start recording in idle state')
    return false
  end
  prepareSession()

  local foldername = '/utrecordings/'.. os.date('%Y-%m') .. '/'
  local filename = os.date('%Y-%m-%d_%H-%M-%S') .. '.utrec.json'
  local fn = foldername .. filename
  lastFilename = fn
  fileSize = 0
  file = io.open(fn, 'w')
  if not file then
    log('E', 'utRecorder', 'Unable to open file for writing: ' .. fn)
    return false
  end

  be:queueAllObjectLua('extensions.load("utRecorder")')

  state = 'rec'
  return true
end

local function onExtensionLoaded()
  log('I', 'utRecorder', 'loaded')
  -- make sure we start freshly ...
  be:queueAllObjectLua('extensions.unload("utRecorder")')
end

local function onDrawDebug(lastDebugFocusPos, dtReal, dtSim, dtRaw)
  im.Begin("Unit Test recorder", windowOpen)
  im.Text("State: " .. tostring(state))
  if lastFrame then
    im.Text('Frame ' .. tostring(lastFrame[1]))
    im.Text('Time: ' .. humanReadableSec(lastFrame[2] / 1000))
    --im.Text('inputs: ' .. tostring(#lastFrame[3]) .. ', vdata: ' .. tostring(#lastFrame[4]))
    if fileSize and fileSize > 0 then im.Text('Filesize: ' .. tostring(math.floor(fileSize / 1024)) .. ' kB') end
  end
  if state == 'rec' or state == 'play' then
    if im.SmallButton("stop") then
      stop()
    end
  elseif state == 'idle' then
    if im.SmallButton("record") then
      startRecording()
    end
    if lastFilename then
      if im.SmallButton("playback") then
        startPlayback(lastFilename)
      end
    end
  end
  im.End()
  return
end

local function onVehicleData(objId, data)
  objId = tonumber(objId)
  if not vdata[objId] then vdata[objId] = {} end
  table.insert(vdata[objId], data)
end

M.onExtensionLoaded = onExtensionLoaded
M.onDrawDebug = onDrawDebug
M.onUpdate = onUpdate

M.onVehicleData = onVehicleData

M.startRecording = startRecording
M.stop = stop
return M
