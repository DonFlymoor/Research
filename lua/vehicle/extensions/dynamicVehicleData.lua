-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local timer = 0

local rpmRoundValue = 50
local torqueRoundValue = 5
local weightRoundValue = 5

local fiveKmh = 1.38889
local tenKmh = 2.7777777778
local hundredKmh = 27.77777778
local hundredTwentyKmh = 33.33333
local twoHundredKmh = 55.55555556
local threeHundredKmh = 83.3333333
local sixtyMph = 26.8224
local hundredMph = 44.704
local twoHundredMph = 89.408

local model_key = nil
local config_key = nil
local workerCoroutine = nil

local logTag = "dynamicVehicleData"

local function round(value)
  return floor(value + 0.5)
end

local function wait(seconds)
  local start = timer
  while timer <= start + seconds do
    coroutine.yield()
  end
end

local function compareData(oldData, newData, model_key, config_key)
  local threshold = 0.1

  for k, v in pairs(newData) do
    --print(k .. ": " .. v)
    if oldData then
      if type(oldData[k]) == "number" and type(v) == "number" then
        local relativeDifference = math.abs(1 - (v / oldData[k]))
        if relativeDifference > threshold then
          log("W", logTag, string.format("Old and new '%s' differ by %.2f%% for vehicle: '%s->%s'. Old/New: %f/%f", k, relativeDifference * 100, model_key, config_key, oldData[k], v))
        end
      end
    end
  end
end

local function clearData(data, whiteList)
  --print("data pre clearing:")
  --dump(data)
  for k, v in pairs(whiteList) do
    data[v] = nil
  end
  --print("data post clearing:")
  --dump(data)

  return data
end

-- saves changes to the info json file
local function saveInfo(newData, whiteList)
  print(string.format("Got data (%s/%s):", model_key, config_key))
  print(dumps(newData))
  local filepath = "vehicles/" .. model_key .. "/info_" .. config_key .. ".json"
  local data = readJsonFile(filepath)
  data = clearData(data, whiteList)
  compareData(data, newData, model_key, config_key)
  if data and newData then
    print("Saving...")
    tableMerge(data, newData)
    writeJsonFile(filepath, data, true)
  end
end

local function onInit()
end

-- switches to next vehicle
local function killswitch()
  --print(" === killswitch ===")
  obj:queueGameEngineLua("util_saveDynamicData.vehicleDone()")
end

local function watchdogHeartbeat()
  obj:queueGameEngineLua("util_saveDynamicData.heartbeat()")
end

local function resetVehicle(position)
  obj:queueGameEngineLua("be:resetVehicle(0)")
  wait(2)
  obj:queueGameEngineLua("be:getPlayerVehicle(0):setPositionRotation(" .. position .. ")")
  wait(2)
  obj:queueGameEngineLua("be:getPlayerVehicle(0):autoplace()")
  wait(2)
end

local function getVehiclePerformanceData()
  local stats = obj:calcBeamStats()
  local weight = ceil(stats.total_weight / weightRoundValue) * weightRoundValue

  local engine = powertrain.getDevice("mainEngine")
  if not engine then
    return {Weight = weight}
  end
  local torqueData = engine:getTorqueData()

  local maxTorque = torqueData.maxTorque
  local maxPower = torqueData.maxPower
  local minRPMTorque = -1
  local maxRPMTorque = -1
  local minRPMPower = -1
  local maxRPMPower = -1

  local curves = torqueData.curves
  local curve = curves[torqueData.finalCurveName]
  local maxTorqueRPM = torqueData.maxTorqueRPM
  local maxPowerRPM = torqueData.maxPowerRPM

  if curve then
    for i = maxTorqueRPM, 0, -1 do
      local torque = curve.torque[i]
      local relDifference = abs(torque - maxTorque) / maxTorque
      if relDifference > 0.02 then
        minRPMTorque = i
        break
      end
    end
    for i = maxTorqueRPM, torqueData.maxRPM, 1 do
      local torque = curve.torque[i]
      local relDifference = abs(torque - maxTorque) / maxTorque
      if relDifference > 0.02 then
        maxRPMTorque = i
        break
      end
    end

    for i = maxPowerRPM, 0, -1 do
      local power = curve.power[i]
      local relDifference = abs(power - maxPower) / maxPower
      if relDifference > 0.02 then
        minRPMPower = i
        break
      end
    end
    for i = maxPowerRPM, torqueData.maxRPM, 1 do
      local power = curve.power[i]
      local relDifference = abs(power - maxPower) / maxPower
      if relDifference > 0.02 or i == torqueData.maxRPM then
        maxRPMPower = i
        break
      end
    end
  else
    print("Can't get torque curve for peak torque/power RPMs")
  end

  -- clean up the data
  local PowerPeakRPM = nil
  local TorquePeakRPM = nil
  local weightPower = nil
  if maxPower > 0 then
    maxPower = floor(maxPower)

    local powerMinRPM = ceil(minRPMPower / rpmRoundValue) * rpmRoundValue
    local powerMaxRPM = floor(maxRPMPower / rpmRoundValue) * rpmRoundValue
    local maxPowerRange = maxRPMPower - minRPMPower
    if maxPowerRange >= 500 then
      PowerPeakRPM = powerMinRPM .. " - " .. powerMaxRPM
    else
      PowerPeakRPM = powerMinRPM
    end
    weightPower = weight / maxPower
  else
    print("Max power <= 0...")
  end

  if maxTorque > 0 then
    maxTorque = ceil(maxTorque / torqueRoundValue) * torqueRoundValue

    local torqueMinRPM = ceil(minRPMTorque / rpmRoundValue) * rpmRoundValue
    local torqueMaxRPM = ceil(maxRPMTorque / rpmRoundValue) * rpmRoundValue
    local maxTorqueRange = maxRPMTorque - minRPMTorque
    if maxTorqueRange >= 500 then
      TorquePeakRPM = torqueMinRPM .. " - " .. torqueMaxRPM
    else
      TorquePeakRPM = torqueMinRPM
    end
  else
    print("Max torque <= 0...")
  end

  local perfData = {
    Weight = weight,
    PowerPeakRPM = PowerPeakRPM,
    TorquePeakRPM = TorquePeakRPM,
    Torque = maxTorque > 0 and torqueData.maxTorque or nil,
    Power = maxPower > 0 and torqueData.maxPower or nil,
    ["Weight/Power"] = weightPower
  }

  local whiteList = {"Weight", "PowerPeakRPM", "TorquePeakRPM", "Torque", "Power", "Weight/Power"}

  return {data = perfData, whiteList = whiteList}
end

local function writeBasicPerformanceData()
  local perfData = getVehiclePerformanceData()
  saveInfo(perfData.data, perfData.whiteList)
end

local function accelerationTests()
  if wheels.wheelCount <= 0 then
    return
  end

  resetVehicle("20,0,0.5,0,0,0,1")

  extensions.load("perfectLaunch")
  perfectLaunch.onInit()
  perfectLaunch.prepare(vec3(20, -10, 0.5))

  wait(4)

  perfectLaunch.go()

  local time100kmh = nil
  local time200kmh = nil
  local time300kmh = nil
  local time100200kmh = nil
  local time60mph = nil
  local time100mph = nil
  local time200mph = nil
  local time60100mph = nil
  local maxSpeed = -1
  local maxSpeedTime = timer

  local speed = 0
  timer = 0
  repeat
    speed = electrics.values.airspeed
    coroutine.yield()

    if timer > 10 then
      print("Can't accelerate, aborting...")
      return
    end
  until speed > 0.15 --wait for the car to start moving before actually timing it

  timer = 0

  while timer <= 400 do
    speed = electrics.values.airspeed
    if not speed then
      -- no speed info, ship this
      print("Not getting any speed info, aborting...")
      return
    end

    if timer > 20 and speed <= fiveKmh then
      print("Can't accelerate, aborting...")
      return
    end

    if speed >= hundredKmh and not time100kmh then
      time100kmh = timer
      time100200kmh = timer
      print("0-100: " .. tostring(timer))
    end
    if speed >= twoHundredKmh and not time200kmh then
      time200kmh = timer
      time100200kmh = timer - time100200kmh
      print("0-200: " .. tostring(timer))
    end
    if speed >= threeHundredKmh and not time300kmh then
      time300kmh = timer
      print("0-300: " .. tostring(timer))
    end
    if speed >= sixtyMph and not time60mph then
      time60mph = timer
      time60100mph = timer
    end
    if speed >= hundredMph and not time100mph then
      time100mph = timer
      time60100mph = timer - time60100mph
    end
    if speed >= twoHundredMph and not time200mph then
      time200mph = timer
    end

    if speed >= maxSpeed then
      maxSpeed = speed
      maxSpeedTime = timer
    end
    -- reached no new max speed for at least 5 seconds?
    -- TODO: this needs some more improvements
    if perfectLaunch.launchFailed then
      print("launch failed...")
      break
    end

    if input.throttle < 0.95 then
      maxSpeedTime = timer
    end

    if timer - maxSpeedTime > 5 then
      print("reached max speed")
      break
    end
    coroutine.yield()
  end

  if timer >= 400 then
    print("high speed test timed out")
  end

  if not time200kmh then
    time100200kmh = nil
  end
  if not time100mph then
    time60100mph = nil
  end

  perfectLaunch.stop()

  local perfData = {
    ["Top Speed"] = maxSpeed,
    ["0-100 km/h"] = time100kmh and (round(time100kmh * 10) / 10) or nil,
    ["0-200 km/h"] = time200kmh and (round(time200kmh * 10) / 10) or nil,
    ["0-300 km/h"] = time300kmh and (round(time300kmh * 10) / 10) or nil,
    ["100-200 km/h"] = time100200kmh and (round(time100200kmh * 10) / 10) or nil,
    ["0-60 mph"] = time60mph and (round(time60mph * 10) / 10) or nil,
    ["0-100 mph"] = time100mph and (round(time100mph * 10) / 10) or nil,
    ["0-200 mph"] = time200mph and (round(time200mph * 10) / 10) or nil,
    ["60-100 mph"] = time60100mph and (round(time60100mph * 10) / 10) or nil
  }

  local whiteList = {"Top Speed", "0-100 km/h", "0-200 km/h", "0-300 km/h", "100-200 km/h", "0-60 mph", "0-100 mph", "0-200 mph", "60-100 mph"}

  saveInfo(perfData, whiteList)
end

local function brakingTests()
  if wheels.wheelCount <= 0 then
    return
  end

  resetVehicle("20,0,0.5,0,0,0,1")

  controller.mainController.setGearboxMode("arcade")
  wheels.setABSBehavior("arcade")

  extensions.load("cruiseControl")
  extensions.load("straightLine")
  straightLine.onInit()
  straightLine.setTargetDirection(vec3(20, -10, 0.5), "road")
  cruiseControl.setSpeed(hundredTwentyKmh)

  timer = 0
  while not cruiseControl.hasReachedTargetSpeed do
    coroutine.yield()

    if timer > 20 and electrics.values.airspeed <= fiveKmh then
      print("Can't accelerate, aborting...")
      return
    end

    if timer > 120 then
      print("Can't accelerate fast enough for brake test, aborting...")
      return
    end
  end

  wait(2)

  local startingSpeed = electrics.values.airspeed
  repeat
    input.event("brake", 1, 1)
    input.event("clutch", 1, 1)
    coroutine.yield()
  until (electrics.values.airspeed <= hundredKmh) --wait for the car to start slowing down before actually timing it

  local startingPosition100 = vec3(obj:getPosition())
  local startingPosition60 = nil
  while electrics.values.airspeed > 0.5 do
    input.event("brake", 1, 1)
    input.event("clutch", 1, 1)
    if electrics.values.airspeed <= sixtyMph and not startingPosition60 then
      startingPosition60 = vec3(obj:getPosition())
    end
    coroutine.yield()
  end
  local endPosition = vec3(obj:getPosition())
  local distance100 = (endPosition - startingPosition100):length()
  local distance60 = (endPosition - startingPosition60):length() * 3.28084
  local avgDeceleration = -(square(electrics.values.airspeed) - square(hundredKmh)) / (2 * distance100)

  input.event("brake", 0, 1)
  input.event("clutch", 0, 1)

  wait(1)

  print("Brake distance: " .. tostring(distance100) .. " m")
  saveInfo(
    {
      ["100-0 km/h"] = round(distance100 * 10) / 10,
      ["60-0 mph"] = round(distance60 * 10) / 10,
      ["Braking G"] = round(avgDeceleration / 9.81 * 1000) / 1000
    },
    {"100-0 km/h", "60-0 mph", "Braking G"}
  )

  obj:queueGameEngineLua("be:resetVehicle(0)")
  wait(2)
end

local function offroadTests()
  if wheels.wheelCount <= 0 then
    return
  end

  resetVehicle("0,0,0.5,0,0,0,1")

  extensions.load("straightLine")
  straightLine.onInit()
  straightLine.setTargetDirection(vec3(0, 600, 0), "offroad")

  controller.mainController.setGearboxMode("arcade")
  local esc = controller.getController("esc")
  if esc then
    esc.pauseESCAction = true
  end

  for _, v in pairs(controller.getControllersByType("4wd")) do
    print("Setting low range")
    v.setRangeMode("low")
    print("Enabling 4WD")
    v.set4WDMode("connected")
  end

  for _, diff in pairs(powertrain.getDevicesByType("differential")) do
    for _, mode in pairs(diff.availableModes) do
      if mode == "locked" and diff.mode ~= mode then
        print("Setting diff '" .. diff.name .. "' to locked")
        diff:setMode(mode)
      end
    end
  end

  extensions.load("cruiseControl")
  cruiseControl.minimumSpeed = tenKmh
  cruiseControl.setSpeed(tenKmh)

  local startingPosition = vec3(obj:getPosition())
  local firstBeamBreakPosition = nil
  wait(5)
  local stats = obj:calcBeamStats()
  local startingBrokenBeams = stats.beams_broken

  local distance = 0
  local beamBrokenDistance = -1
  timer = 0

  while timer < 5 and distance < 500 do
    local endPosition = vec3(obj:getPosition())
    distance = (endPosition - startingPosition):length()
    timer = electrics.values.airspeed > 1 and 0 or timer
    stats = obj:calcBeamStats()
    if not firstBeamBreakPosition and stats.beams_broken > startingBrokenBeams then
      firstBeamBreakPosition = vec3(obj:getPosition())
      beamBrokenDistance = (firstBeamBreakPosition - startingPosition):length()
      print("beam broken")
    end
    coroutine.yield()
  end

  straightLine.stop()
  cruiseControl.setEnabled(false)

  for _, v in pairs(controller.getControllersByType("4wd")) do
    print("Setting high range")
    v.setRangeMode("high")
  end

  if beamBrokenDistance < 0 then
    beamBrokenDistance = distance
  end

  print("Off-Road distance: " .. tostring(distance) .. " m")
  print("Off-Road beam break distance: " .. tostring(beamBrokenDistance) .. " m")
  saveInfo({["Off-Road Score"] = math.ceil(((3 * distance + beamBrokenDistance) / 500 / 4) * 100)}, {"Off-Road Score"})

  if esc then
    esc.pauseESCAction = true
  end
end

local function updateGFX(dt)
  timer = timer + dt

  if workerCoroutine ~= nil then
    local errorfree, value = coroutine.resume(workerCoroutine)
    if not errorfree then
      log("E", logTag, debug.traceback(workerCoroutine, "workerCoroutine: " .. value))
    end
    watchdogHeartbeat()
    if coroutine.status(workerCoroutine) == "dead" then
      print("coroutine dead, hitting killswitch")
      killswitch()
      workerCoroutine = nil
      return
    end
  end
end

local function performTests(_model_key, _config_key)
  workerCoroutine =
    coroutine.create(
    function()
      -- save for later usage
      model_key = _model_key
      config_key = _config_key
      log("I", logTag, string.format(" *** testing car: %s / %s ***", model_key, config_key))

      log("I", logTag, " *** getting static performance data ***")
      writeBasicPerformanceData()

      log("I", logTag, " *** getting offroad data ***")
      offroadTests()

      log("I", logTag, " *** getting acceleration data ***")
      accelerationTests()

      log("I", logTag, " *** getting braking data ***")
      brakingTests()

      local touchedFilePath = "vehicles/" .. model_key .. "/info_" .. config_key .. ".touched"
      --writeJsonFile(touchedFilePath, {}, true)

      log("I", logTag, " *** finished ***")
    end
  )
end

-- public interface
M.onInit = onInit
M.onReset = onInit
M.performTests = performTests
M.updateGFX = updateGFX

return M
