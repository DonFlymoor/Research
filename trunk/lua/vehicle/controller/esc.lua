local M = {}
M.type = "auxiliary"
M.relevantDevice = nil
M.defaultOrder = 50

M.pauseESCAction = false
M.calibrationMeasurementReady = false
M.calibrationSettled = false
M.doSettle = false
M.doMeasure = false
M.stiffnessFront = 0
M.stiffnessRear = 0
M.wheelAngleFront = 0
M.wheelAngleRear = 0
M.isExisting = true

--shorter functions for increased performance
local pow = math.pow
local abs = math.abs
local min = math.min
local max = math.max
local sqrt = math.sqrt
local cos = math.cos
local pi = math.pi

local configData = nil

local escPulse = 0
local tcsPulse = 0

--variables for ESC functionality
local wheelCache = {} --cache for holding all our wheels
local wheelCacheSize = 0
local wheelNameCache = {}
local otherWheelOnAxle = {}
local crossWheels = {}
local tcsWheelBrakeTorques = {}
local revLimiterEngines = {}
local revLimiterEngineCount = 0

local yawSmooth = nil --exponential smoothing for the yaw rate
local desiredYawSmooth = nil --exponential smoothing for the yaw rate
local invSquaredCharacteristicSpeed = 0 --pre calculated, used for desired yaw calculation

local frontLeftWheelId = nil
local frontRightWheelId = nil
local rearRightWheelId = nil
local rearLeftWheelId = nil

local escConfigurations = {}
local currentESCConfiguration = nil
local currentESCConfigurationKey = 1
local lastESCConfigurationKey = -1

local wheelBase = 0 --m
local invWheelBase = 0
local distanceCOGFrontAxle = 0 --m
local distanceCOGRearAxle = 0 --m
local trackWidth = 0
local mass = 0 --kg

local initialWheelCount = 0
local escFailure = false

local desiredYawRateSteering = 0
local desiredYawRateAcceleration = 0
local yawRate = 0
local speed = 0 --m/s
local wheelAngleFront = 0
local wheelAngleRear = 0
local desiredYawRate = 0
local yawDifference = 0
local escEnableThreshold = 6 --m/s

local throttleFactor = 1
local throttleFactorIntegral = 0
local allWheelSlip = false
local tempRevLimiterTimer = 0
local tempRevLimiterActive = false

local tcsDeactivateThreshold = 0.05
local tcsDeactivateSpeedThreshold = 0.55

local escActive = false
local tcsActive = false
local warningLightsDelayTime = 0.15 --s
local warningLightsTimer = 0 --s
local offColor = nil

--ESC calibbration
local escMeasuringStepThreshold = 3500
local escSettlingStepThreshold = 1500
local escMeasuringStepCounter = 0
local escSettlingStepCounter = 0
local stiffnessFrontSum = 0
local stiffnessRearSum = 0

--toggle debug mode
local isDebugMode = 0
local calibrateESC = nop
local hasRegisteredQuickAccess = false

local function generateSteeringCurve(steeringAngle) --generates debug data to visualize the steering part of the desired yaw graph
  local steeringData = {}
  for i = 0, 50, 1 do
    steeringData[i + 1] = abs((steeringAngle * invWheelBase) * (i / (1 + ((i * i) * invSquaredCharacteristicSpeed))))
  end

  return steeringData
end

local function generateAccelerationCurve() --generates debug data to visualize the acceleration part of the desired yaw graph
  local accelerationData = {[1] = 100000}
  for i = 1, 50, 1 do
    accelerationData[i + 1] = currentESCConfiguration.maxSideAcceleration / i
  end

  return accelerationData
end

local function updateGFX(dt)
  warningLightsTimer = warningLightsTimer + dt

  if warningLightsTimer >= warningLightsDelayTime then
    escPulse = escActive and bit.bxor(escPulse, 1) or 0
    tcsPulse = tcsActive and bit.bxor(tcsPulse, 1) or 0
    warningLightsTimer = 0
  end

  if currentESCConfiguration.overrideESCPulse then
    escPulse = currentESCConfiguration.overrideESCPulse
  end

  if currentESCConfiguration.overrideTCSPulse then
    tcsPulse = currentESCConfiguration.overrideTCSPulse
  end

  if escFailure then
    escPulse = 1
    tcsPulse = 1
  end

  electrics.values.esc = escPulse
  electrics.values.tcs = tcsPulse
  electrics.values.escActive = escActive
  electrics.values.tcsActive = tcsActive

  if streams.willSend("escData") then
    gui.send(
      "escData",
      {
        steeringAngle = math.deg(wheelAngleFront),
        yawRate = yawRate,
        desiredYawRate = desiredYawRate,
        difference = yawDifference,
        desiredYawRateAcceleration = desiredYawRateAcceleration * fsign(desiredYawRateSteering),
        desiredYawRateSteering = desiredYawRateSteering,
        steeringCurve = generateSteeringCurve(wheelAngleFront),
        accelerationCurve = generateAccelerationCurve(),
        maxSpeed = 50,
        speed = speed
      }
    )
  end

  if streams.willSend("escInfo") then
    gui.send(
      "escInfo",
      {
        ledColor = (escPulse > 0 or tcsPulse > 0) and offColor or currentESCConfiguration.activeColor
      }
    )
  end

  if streams.willSend("tcsData") then
    local lastSlips = {}
    local wheelBrakeFactors = {}
    for i = 0, wheelCacheSize - 1, 1 do
      local wheel = wheelCache[i]
      lastSlips[wheel.name] = wheel.tractionControlLastSlip
      wheelBrakeFactors[wheel.name] = wheel.tractionControlBrakeFactor
    end

    gui.send(
      "tcsData",
      {
        throttleFactor = throttleFactor,
        wheelBrakeFactors = wheelBrakeFactors,
        allWheelSlip = allWheelSlip and -0.2 or 0,
        wheelSlips = lastSlips,
        slipThreshold = currentESCConfiguration.slipThreshold
      }
    )
  end
end

local function updateWheelsIntermediate(dt)
  if not currentESCConfiguration.escEnabled or (electrics.values.gearIndex or 0) < 0 then
    electrics.values.throttleFactor = 1
    escActive = false
    tcsActive = false
    if tempRevLimiterActive then
      tempRevLimiterActive = false
      for i = 1, revLimiterEngineCount, 1 do
        revLimiterEngines[i]:resetTempRevLimiter()
      end
    end
    return
  end

  --if we lose a wheel, we want to deactivate the ESC
  if initialWheelCount ~= wheels.wheelCount then
    M.updateWheelsIntermediate = nop
    escFailure = true
    electrics.values.throttleFactor = 1
    tempRevLimiterActive = false
    for i = 1, revLimiterEngineCount, 1 do
      revLimiterEngines[i]:resetTempRevLimiter()
    end
    controller.cacheAllControllerFunctions()
    return
  end

  speed = electrics.values.wheelspeed
  escActive = false
  tcsActive = false

  local vectorForward = obj:getDirectionVector()
  local vectorUp = obj:getDirectionVectorUp()
  local vectorRight = vectorForward:cross(vectorUp)
  local steeringInput = input.steering
  local wheelFront = steeringInput < 0 and wheelCache[frontRightWheelId] or wheelCache[frontLeftWheelId]
  local wheelRear = steeringInput < 0 and wheelCache[rearRightWheelId] or wheelCache[rearLeftWheelId]

  wheelAngleFront = math.acos(obj:nodeVecPlanarCos(wheelFront.node1, wheelFront.node2, vectorRight, vectorForward))
  wheelAngleRear = math.acos(obj:nodeVecPlanarCos(wheelRear.node1, wheelRear.node2, vectorRight, vectorForward))
  if wheelAngleFront > 1.5708 then
    wheelAngleFront = (pi - wheelAngleFront)
  end
  wheelAngleFront = wheelAngleFront * fsign(-steeringInput)
  if wheelAngleFront ~= wheelAngleFront then
    wheelAngleFront = 0
  end

  if wheelAngleRear > 1.5708 then
    wheelAngleRear = (pi - wheelAngleRear)
  end
  wheelAngleRear = wheelAngleRear * fsign(-steeringInput)
  if wheelAngleRear ~= wheelAngleRear then
    wheelAngleRear = 0
  end

  M.wheelAngleFront = wheelAngleFront
  M.wheelAngleRear = wheelAngleRear

  ---------------------
  ---------ESC---------
  ---------------------

  yawRate = yawSmooth:get(-obj:getYawAngularVelocity())

  --calculate expected yaw rate based on steering angle
  desiredYawRateSteering = ((wheelAngleFront * invWheelBase) * (speed / (1 + (speed * speed * invSquaredCharacteristicSpeed))))
  --calculate expected yaw rate based on Gs
  desiredYawRateAcceleration = currentESCConfiguration.maxSideAcceleration / (speed + 1e-30)

  --get the resulting desired yaw rate (smallest) and make sure to use the sign from the steering part (acceleration part is always positive)
  desiredYawRate = fsign(desiredYawRateSteering) * min(abs(desiredYawRateSteering), abs(desiredYawRateAcceleration))
  desiredYawRate = desiredYawSmooth:get(desiredYawRate)

  local counterSteerFlag = false
  if yawRate * desiredYawRate < 0 then --check if we are counter steering while oversteering.
    desiredYawRate = -desiredYawRate --If we do, we need to adjust our desired yaw rate because its sign is wrong at this point (since we are steering in the "wrong" direction
    counterSteerFlag = true --we need to save this information because we need to alter the wheel that needs to be braked
  end

  yawDifference = yawRate - desiredYawRate --calculate the difference between expected yaw and actual yaw, ~0 means we're all good, > 0 means oversteer, < 0 means understeer
  local absYawDifference = abs(yawDifference)

  local escWheelToBrake = nil
  local escDesiredBrakeTorque = 0
  if speed >= escEnableThreshold and absYawDifference > currentESCConfiguration.escThreshold and not M.pauseESCAction then --only act if we are fast enough and pass the threshold
    yawDifference = yawDifference - (fsign(yawDifference) * currentESCConfiguration.escThreshold)

    if abs(yawRate) > abs(desiredYawRate) or counterSteerFlag then --Oversteer
      if yawRate > 0 then --turning left
        escWheelToBrake = frontRightWheelId
      elseif yawRate < 0 then --turning right
        escWheelToBrake = frontLeftWheelId
      end
    else --Understeer
      if yawRate > 0 then --turning left
        escWheelToBrake = rearLeftWheelId

        if counterSteerFlag then
          escWheelToBrake = frontLeftWheelId --switch to the FRONT wheel when braking, otherwise we would work AGAINST the driver while counter steering
          yawDifference = yawDifference * 0.5 --also reduce the severity of the brake action for a smoother drift
        end
      elseif yawRate < 0 then --turning right
        escWheelToBrake = rearRightWheelId

        if counterSteerFlag then
          escWheelToBrake = frontRightWheelId
          yawDifference = yawDifference * 0.5
        end
      end
    end

    if escWheelToBrake ~= nil then
      escActive = true
      local wheel = wheelCache[escWheelToBrake] --get the wheel we need to brake
      wheel.stabilityControlBrakeIntegral = min(max(wheel.stabilityControlBrakeIntegral + absYawDifference * dt, 0), currentESCConfiguration.maxIntegralPart)

      local wheelAntiLockupFactor = min(max((abs(wheel.angularVelocity) - 10) * 0.1, 0), 1) --factor in some coef from the wheelspeed, if the AV drops below 1 we gradually lower the braking torque to prevent wheel lockup
      local brakeCoef = min((absYawDifference * currentESCConfiguration.proportionalFactor + wheel.stabilityControlBrakeIntegral * currentESCConfiguration.integralFactor) * wheelAntiLockupFactor, 1)
      local brakingTorque = min(brakeCoef * currentESCConfiguration.brakeForceMultiplier * wheel.brakeTorque, wheel.brakeTorque) --calculate our actual braking torque based on the brake's maximum torque

      escDesiredBrakeTorque = brakingTorque
    end
  else
    yawDifference = 0
    for i = 0, wheelCacheSize - 1, 1 do
      wheelCache[i].stabilityControlBrakeIntegral = 0
    end
  end

  ---------------------
  ---------------------
  ---------------------

  ---------------------
  ---------TCS---------
  ---------------------

  allWheelSlip = true
  local averageSlipError = 0
  local peakSlipError = 0
  local wheelCount = 0
  local tcsWheelBrakeCount = wheelCacheSize
  local throttle = electrics.values.throttle or 0

  if speed < tcsDeactivateSpeedThreshold or throttle < tcsDeactivateThreshold or M.pauseESCAction then
    --If we are braking or barely accelerating or below a certain speed, TCS is deactivated and resets all interesting values
    throttleFactor = 1
    for i = 0, wheelCacheSize - 1, 1 do
      local wheel = wheelCache[i]
      wheel.tractionControlBrakeFactor = 0
      wheel.tractionControlBrakeIntegral = 0
      wheel.tractionControlLastSlip = 0
    end
    allWheelSlip = false
    throttleFactorIntegral = 0
  else
    for i = 0, wheelCacheSize - 1, 1 do
      local wheel = wheelCache[i]
      if wheel.isPropulsed then
        wheelCount = wheelCount + 1
        --Look at the AV of each propulsed wheel
        local wheelSpeed = wheel.speedSmoother:get(wheel.angularVelocity * wheel.wheelDir / wheel.tractionControlSpeedCorrectionFactor) --take different turning radius into account for wheelspeed
        if abs(wheelSpeed) < 1 then
          wheelSpeed = 0
        end
        local crossWheelName = crossWheels[i]
        local crossWheel = wheelCache[crossWheelName]
        local crossWheelSpeed = crossWheel.speedSmoother:get(crossWheel.angularVelocity * crossWheel.wheelDir * crossWheel.tractionControlSpeedCorrectionFactor) --take different turning radius into account for expected wheelspeed
        if abs(crossWheelSpeed) < 1 then
          crossWheelSpeed = 0
        end
        if wheelSpeed * crossWheelSpeed < 0 and (abs(wheelSpeed) - abs(crossWheelSpeed) > 10) then
          crossWheelSpeed = fsign(wheelSpeed) * crossWheelSpeed
        end
        --And calculate how much deviation there is compared to the diagonal wheel
        local crossWheelSlip = min(max((wheelSpeed - crossWheelSpeed) / (wheelSpeed + 1e-30), 0), 1) --make sure wheelSpeed can never be exactly 0 so we can divide by it

        local slipError = wheelSpeed > currentESCConfiguration.tcsWheelSpeedThreshold and crossWheelSlip - currentESCConfiguration.slipThreshold or 0
        averageSlipError = averageSlipError + slipError
        peakSlipError = max(peakSlipError, slipError)

        wheel.tractionControlBrakeIntegral = min(max(wheel.tractionControlBrakeIntegral + slipError * dt, -1), 2)
        wheel.tractionControlBrakeFactor = min(max(slipError * currentESCConfiguration.brakingProportionalFactor + wheel.tractionControlBrakeIntegral * currentESCConfiguration.brakingIntegralFactor, 0), currentESCConfiguration.maxBrakingFactor)

        --Check what to do, either tell the next frame that we don't have allWheelSlip (if we are with any wheel below the slip threshold)
        --or go on and counter act the slip which is above the threshold
        if crossWheelSlip <= currentESCConfiguration.slipThreshold then
          --No slip here, let the next frame know that we have at least one good wheel
          allWheelSlip = false
          tcsWheelBrakeTorques[i] = 0
        else
          --try to reduce the slip based on the current slip value and the last frame's information about allWheelSlip
          tcsActive = true --activate the esc light
          tcsWheelBrakeTorques[i] = wheel.brakeTorque * wheel.tractionControlBrakeFactor
        end

        wheel.tractionControlLastSlip = crossWheelSlip --save slip for debug app
      end
    end
  end

  local absWheelAngle = abs(wheelAngleFront)
  if absWheelAngle > 0.01 then
    --calculate wheel speed correction factors for next frame (different wheel speeds because of turning
    local innerTurningCircleRadius = wheelBase / (sqrt(1 - pow(cos(absWheelAngle), 2)) + 1e-30)
    local outerTurningCircleRadius = innerTurningCircleRadius + trackWidth

    local ratio = outerTurningCircleRadius / innerTurningCircleRadius
    if wheelAngleFront > 0 then --turning left
      wheelCache[frontRightWheelId].tractionControlSpeedCorrectionFactor = ratio --outer wheels will turn faster
      wheelCache[rearRightWheelId].tractionControlSpeedCorrectionFactor = ratio --outer wheels will turn faster
      wheelCache[frontLeftWheelId].tractionControlSpeedCorrectionFactor = 1
      wheelCache[rearLeftWheelId].tractionControlSpeedCorrectionFactor = 1
    else --turning right
      wheelCache[frontLeftWheelId].tractionControlSpeedCorrectionFactor = ratio --outer wheels will turn faster
      wheelCache[rearLeftWheelId].tractionControlSpeedCorrectionFactor = ratio --outer wheels will turn faster
      wheelCache[frontRightWheelId].tractionControlSpeedCorrectionFactor = 1
      wheelCache[rearRightWheelId].tractionControlSpeedCorrectionFactor = 1
    end
  else
    --reset all values, we are not turning
    wheelCache[frontLeftWheelId].tractionControlSpeedCorrectionFactor = 1
    wheelCache[rearLeftWheelId].tractionControlSpeedCorrectionFactor = 1
    wheelCache[frontRightWheelId].tractionControlSpeedCorrectionFactor = 1
    wheelCache[rearRightWheelId].tractionControlSpeedCorrectionFactor = 1
  end

  ---------------------
  ---------------------
  ---------------------

  ---------------------
  ---Decision Block----
  ---------------------

  local reduceThrottle = false
  local brakeESCWheel = false
  local brakeTCSWheel = false
  local previousTempRevLimiterTimer = tempRevLimiterTimer
  if escActive and tcsActive then
    tcsWheelBrakeCount = 0
    reduceThrottle = true
    brakeESCWheel = true
    tempRevLimiterTimer = 0.3
  elseif escActive then
    brakeESCWheel = true
    reduceThrottle = true
    tempRevLimiterTimer = 0.2
  elseif tcsActive and not allWheelSlip and speed < currentESCConfiguration.brakeThrottleSwitchThreshold then
    brakeTCSWheel = true
  elseif tcsActive then
    reduceThrottle = true
  end

  if brakeESCWheel then
    local wheel = wheelCache[escWheelToBrake]
    local otherWheel = wheelCache[otherWheelOnAxle[escWheelToBrake]] --get the other wheel on the axle from our prepared mapping
    if wheel.desiredBrakingTorque == 0 and otherWheel.desiredBrakingTorque == 0 then --if we are not braking, apply torque normally
      wheel.desiredBrakingTorque = escDesiredBrakeTorque
    else --if we ARE already braking, we need to adjust to that and potentially reduce braking torque on other wheels for the desired effect
      if wheel.absActive or (wheel.desiredBrakingTorque + escDesiredBrakeTorque) > wheel.brakeTorque then
        --in case we are already at the limit of grip (ABS active) or we can't add any additional torque to our target wheel anymore
        --Simply reduce the torque on the other axle wheel (this assumes that both wheel have roughly similar brake torques)
        otherWheel.desiredBrakingTorque = max(otherWheel.desiredBrakingTorque - escDesiredBrakeTorque, 0)
      else
        --in the simply case of additional available grip, add our esc torque on top of the already existing brake torque
        --this might not work prefectly if we are right below the grip threshold
        wheel.desiredBrakingTorque = min(wheel.desiredBrakingTorque + escDesiredBrakeTorque, wheel.brakeTorque)
      end
    end
  end

  if brakeTCSWheel then
    for i = 0, tcsWheelBrakeCount - 1, 1 do
      wheelCache[i].desiredBrakingTorque = wheelCache[i].desiredBrakingTorque + tcsWheelBrakeTorques[i]
    end
  end

  if reduceThrottle then
    local slipError = peakSlipError
    throttleFactorIntegral = max(min(throttleFactorIntegral + slipError * dt, 1), 0)
    local throttleFactorPI = slipError * currentESCConfiguration.throttleProportionalFactor + throttleFactorIntegral * currentESCConfiguration.throttleIntegralFactor
    throttleFactor = min(max(1 - throttleFactorPI, currentESCConfiguration.minThrottleFactor), 1)
  else
    throttleFactorIntegral = max(min(throttleFactorIntegral - currentESCConfiguration.slipThreshold * dt, 1), 0)
    throttleFactor = min(max(1 - (throttleFactorIntegral * currentESCConfiguration.throttleIntegralFactor), currentESCConfiguration.minThrottleFactor), 1)
  end

  if tempRevLimiterTimer > previousTempRevLimiterTimer then
    tempRevLimiterActive = true
    for i = 1, revLimiterEngineCount, 1 do
      local engine = revLimiterEngines[i]
      engine:setTempRevLimiter(engine.outputAV1)
    end
  elseif tempRevLimiterTimer <= 0 and tempRevLimiterActive then
    tempRevLimiterActive = false
    for i = 1, revLimiterEngineCount, 1 do
      revLimiterEngines[i]:resetTempRevLimiter()
    end
  end

  tempRevLimiterTimer = tempRevLimiterTimer - dt

  --Apply our throttle factor
  electrics.values.throttleFactor = throttleFactor
  ---------------------
  ---------------------
  ---------------------

  --use existing ESC data for calibration purposes (nop'ed when not in use)
  calibrateESC()
end

local function doCalibration()
  if M.doMeasure then
    escMeasuringStepCounter = escMeasuringStepCounter + 1

    local velocity = vec3(obj:getVelocity())
    local directionVector = vec3(obj:getDirectionVector())
    local actualVelocity = (directionVector:dot(velocity) / (directionVector:length() * directionVector:length()) * directionVector):length()
    local velocityVector = vec3(velocity.x, velocity.y, 0)
    local dot = velocityVector:dot(directionVector)
    local floatAngle = math.acos(dot / (directionVector:length() * velocityVector:length()))

    local yawRateCalibration = abs(yawRate) * -1
    local wheelAngleFrontCalibration = abs(wheelAngleFront) * -1
    local wheelAngleRearCalibration = abs(wheelAngleRear) * -1

    local stiffnessFront = (distanceCOGRearAxle * mass * yawRateCalibration * actualVelocity) / ((distanceCOGFrontAxle + distanceCOGRearAxle) * (wheelAngleFrontCalibration - (distanceCOGFrontAxle * yawRateCalibration / actualVelocity) - floatAngle))
    local stiffnessRear = ((yawRateCalibration * mass * actualVelocity) - stiffnessFront * (wheelAngleFrontCalibration - (distanceCOGFrontAxle * yawRateCalibration / actualVelocity) - floatAngle)) / (wheelAngleRearCalibration + (distanceCOGRearAxle * yawRateCalibration / actualVelocity) - floatAngle)

    stiffnessFrontSum = stiffnessFrontSum + stiffnessFront
    stiffnessRearSum = stiffnessRearSum + stiffnessRear

    if escMeasuringStepCounter >= escMeasuringStepThreshold then
      M.stiffnessFront = stiffnessFrontSum / escMeasuringStepCounter
      M.stiffnessRear = stiffnessRearSum / escMeasuringStepCounter
      stiffnessFrontSum = 0
      stiffnessRearSum = 0
      M.doMeasure = false
      M.calibrationMeasurementReady = true
      escMeasuringStepCounter = 0
    end
  end

  if M.doSettle then
    escSettlingStepCounter = escSettlingStepCounter + 1
    if escSettlingStepCounter >= escSettlingStepThreshold then
      M.doSettle = false
      M.calibrationSettled = true
      escSettlingStepCounter = 0
    end
  end
end

local function startESCCalibration()
  M.calibrationMeasurementReady = false
  M.doMeasure = false
  M.doSettle = false
  M.calibrationSettled = false
  stiffnessFrontSum = 0
  stiffnessRearSum = 0
  M.stiffnessFront = 0
  M.stiffnessRear = 0
  escMeasuringStepCounter = 0
  escSettlingStepCounter = 0
  calibrateESC = doCalibration
end

local function stopESCCalibration()
  calibrateESC = nop
end

local function getCarData()
  if mass <= 0 then
    return nil
  end

  return {
    wheels = wheelCache,
    frontLeftWheelId = frontLeftWheelId,
    frontRightWheelId = frontRightWheelId,
    rearLeftWheelId = rearLeftWheelId,
    rearRightWheelId = rearRightWheelId,
    wheelBase = wheelBase,
    trackWidth = trackWidth,
    distanceCOGRearAxle = distanceCOGRearAxle,
    distanceCOGFrontAxle = distanceCOGFrontAxle,
    mass = mass
  }
end

local function getCurrentConfigData()
  return currentESCConfiguration
end

local function sanitizeConfiguration(config, name)
  config.name = name
  config.escEnabled = config.escEnabled or false
  config.activeColor = config.activeColor or "98FB00"
  config.characteristicSpeed = config.characteristicSpeed or 0

  config.proportionalFactor = config.proportionalFactor or 1
  config.integralFactor = config.integralFactor or 0
  config.maxIntegralPart = config.maxIntegralPart or 2

  config.maxSideAcceleration = config.maxSideAcceleration or 0
  config.brakeForceMultiplier = config.brakeForceMultiplier or 0
  config.escThreshold = config.escThreshold or 0
  config.skewStiffnessFront = config.skewStiffnessFront or 1
  config.skewStiffnessRear = config.skewStiffnessRear or 1
  config.desiredYawRateSmoothing = config.desiredYawRateSmoothing or 500

  config.slipThreshold = config.slipThreshold or 0
  config.tcsWheelSpeedThreshold = config.tcsWheelSpeedThreshold or 10

  config.throttleProportionalFactor = config.throttleProportionalFactor or 1.5
  config.throttleIntegralFactor = config.throttleIntegralFactor or 1

  config.brakingProportionalFactor = config.brakingProportionalFactor or 1.2
  config.brakingIntegralFactor = config.brakingIntegralFactor or 0

  config.maxBrakingFactor = max(min(config.maxBrakingFactor or 0, 1), 0)
  config.minThrottleFactor = max(min(config.minThrottleFactor or 1, 1), 0)

  config.brakeThrottleSwitchThreshold = config.brakeThrottleSwitchThreshold or 10

  return config
end

local function preCalculate()
  invSquaredCharacteristicSpeed = 1 / (currentESCConfiguration.characteristicSpeed * currentESCConfiguration.characteristicSpeed)
end

local function setESCMode(key)
  if currentESCConfiguration == nil then --if we don't have any current config, the vehicle does not have esc at all, abort here
    return
  end

  if initialWheelCount ~= wheels.wheelCount then --if we have detached wheels, the esc is disabled anyway, no need to switch modes anymore
    return
  end

  currentESCConfigurationKey = key
  if currentESCConfigurationKey > #escConfigurations then
    currentESCConfigurationKey = 1
  end

  currentESCConfiguration = escConfigurations[currentESCConfigurationKey] --load new esc config

  preCalculate() -- make sure to update our precalculated values with the new config

  lastESCConfigurationKey = currentESCConfigurationKey
  gui.message(currentESCConfiguration.name, 5, "vehicle.esc.mode")
end

local function toggleESCMode()
  local key = currentESCConfigurationKey + 1
  setESCMode(key)
  if currentESCConfigurationKey > #escConfigurations then
    currentESCConfigurationKey = 1
  end
end

local function registerQuickAccess()
  if not hasRegisteredQuickAccess then
    core_quickAccess.addEntry(
      {
        level = "/",
        generator = function(entries)
          table.insert(entries, {title = "ui.radialmenu2.ESC", priority = 40, ["goto"] = "/esc/", icon = "radial_regular_esc"})
        end
      }
    )

    core_quickAccess.addEntry(
      {
        level = "/esc/",
        generator = function(entries)
          for k, v in pairs(escConfigurations) do
            local entry = {
              title = "ui.radialmenu2.ESC." .. v.name:gsub(" ", "_"),
              icon = "radial_" .. string.lower(v.name:gsub(" ", "_")),
              onSelect = function()
                controller.getController("esc").setESCMode(k)
                return {"reload"}
              end
            }
            if currentESCConfiguration == v then
              entry.color = "#ff6600"
            end
            table.insert(entries, entry)
          end
        end
      }
    )
    hasRegisteredQuickAccess = true
  end
end

local function calculateCharacteristicSpeed(config)
  local eg = (mass * (config.skewStiffnessRear * distanceCOGRearAxle - config.skewStiffnessFront * distanceCOGFrontAxle)) / (config.skewStiffnessFront * config.skewStiffnessRear * wheelBase)
  local characteristicSpeed = sqrt(wheelBase / abs(eg + 1e-30)) --guard against infinity
  if isDebugMode and config.escEnabled then
    log("D", "ESC", string.format("Calculated EG: %s --> %.6f", config.name, eg))
    log("D", "ESC", string.format("Calculated characteristic speed: %s --> %.2f m/s", config.name, characteristicSpeed))
    if eg < 0 then
      log("W", "ESC", string.format("Calculated EG (%s) is lower than 0 (oversteery car setup), ESC might not work perfectly!", config.name))
    end
  end
  return characteristicSpeed
end

local function calculateAxleDistances()
  wheelBase = obj:nodeLength(wheelCache[frontRightWheelId].node1, wheelCache[rearRightWheelId].node1) --calculate wheelbase from the distance of the front and rear wheels
  invWheelBase = 1 / wheelBase

  local tmp = vec3(0, 0, 0)
  local totalMass = 0
  for _, v in pairs(v.data.nodes) do
    tmp = tmp + vec3(v.pos) * v.nodeWeight
    totalMass = totalMass + v.nodeWeight
  end

  local realCOG = tmp / totalMass

  --Find the positions of the front and rear axle
  local frontAxlePos = 0
  local rearAxlePos = 0
  local twLeft = 0
  local twRight = 0
  for _, n in pairs(v.data.nodes) do
    if n.cid == wheelCache[frontRightWheelId].node1 then
      frontAxlePos = n.pos.y
      twRight = n.pos.x
    elseif n.cid == wheelCache[rearRightWheelId].node1 then
      rearAxlePos = n.pos.y
    elseif n.cid == wheelCache[frontLeftWheelId].node1 then
      twLeft = n.pos.x
    end
  end

  distanceCOGFrontAxle = abs(realCOG.y - frontAxlePos)
  distanceCOGRearAxle = abs(realCOG.y - rearAxlePos)

  trackWidth = abs(twLeft - twRight)

  if isDebugMode then
    log("D", "ESC", "Distance COG to Rearaxle: " .. distanceCOGRearAxle .. " m")
    log("D", "ESC", "Distance COG to Frontaxle: " .. distanceCOGFrontAxle .. " m")
    log("D", "ESC", "Wheelbase: " .. wheelBase .. " m")
    log("D", "ESC", "Track width: " .. trackWidth .. " m")
  end
end

local function init(jbeamData)
  configData = jbeamData
end

local function initSecondStage()
  escPulse = 0
  tcsPulse = 0
  escFailure = false
  M.pauseESCAction = false
  M.wheelAngleFront = 0
  M.wheelAngleRear = 0
  M.stiffnessFront = 0
  M.stiffnessRear = 0

  calibrateESC = nop
  M.updateWheelsIntermediate = nil
  M.updateGFX = nil

  wheelCache = table.new(4, 0)
  wheelCacheSize = 0
  wheelNameCache = {}
  tcsWheelBrakeTorques = {}
  throttleFactor = 1
  allWheelSlip = false

  --cache all wheels for easy access
  for id, wd in pairs(wheels.wheels) do
    local wheelCacheEntry = wd
    wheelCacheEntry.speedSmoother = newExponentialSmoothing(500)
    wheelCacheEntry.stabilityControlBrakeIntegral = 0
    wheelCacheEntry.tractionControlBrakeIntegral = 0
    wheelCacheEntry.tractionControlBrakeFactor = 0
    wheelCacheEntry.tractionControlLastSlip = 0
    wheelCacheEntry.tractionControlSpeedCorrectionFactor = 1
    --table.insert(wheelCache, wheelCacheEntry)
    wheelCache[id] = wheelCacheEntry
    wheelNameCache[wd.name] = id
    wheelCacheSize = wheelCacheSize + 1
    tcsWheelBrakeTorques[id] = 0
  end

  yawSmooth = newExponentialSmoothing(50) --windows of 50 frames

  --we need to find the average wheel position (basically the "center" of our vehicle)
  local avgWheelPos = vec3(0, 0, 0)
  local wheelCount = 0

  local escConfigs = configData

  if v.userSettings and v.userSettings.escConfig then
    escConfigs = tableMergeRecursive(escConfigs, v.userSettings.escConfig)
  end

  for _, wheelName in ipairs(escConfigs.actionedWheels) do
    if wheelNameCache[wheelName] == nil then
      log("W", "ESC", "Could not find wheel: " .. wheelName .. " defined in escConfig")
      M.update = nop
      M.graphicsStep = nop
      return
    end
    local wheelNodePos = v.data.nodes[wheelCache[wheelNameCache[wheelName]].node1].pos --find the wheel position
    avgWheelPos = avgWheelPos + wheelNodePos --sum up all positions
    wheelCount = wheelCount + 1
  end

  avgWheelPos = avgWheelPos / wheelCount --make the average of all positions

  local vectorForward = vec3(v.data.nodes[v.data.refNodes[0].ref].pos) - vec3(v.data.nodes[v.data.refNodes[0].back].pos) -- vec3(obj:getDirectionVector()) --vector facing forward
  local vectorUp = vec3(v.data.nodes[v.data.refNodes[0].up].pos) - vec3(v.data.nodes[v.data.refNodes[0].ref].pos)

  local vectorRight = vectorForward:cross(vectorUp) --vector facing to the right

  offColor = escConfigs.offColor or "343434"

  --iterate over all wheels that should be included in the esc
  for _, wheelName in ipairs(escConfigs.actionedWheels) do
    local wheelNodePos = vec3(v.data.nodes[wheelCache[wheelNameCache[wheelName]].node1].pos) --find the wheel position
    local wheelVector = wheelNodePos - avgWheelPos --create a vector from our "center" to the wheel
    local dotForward = vectorForward:dot(wheelVector) --calculate dot product of said vector and forward vector
    local dotLeft = vectorRight:dot(wheelVector) --calculate dot product of said vector and left vector

    if dotForward >= 0 then
      if dotLeft >= 0 then
        frontRightWheelId = wheelNameCache[wheelName] --this case can only mean it's our front right wheel
      else
        frontLeftWheelId = wheelNameCache[wheelName] -- ...
      end
    else
      if dotLeft >= 0 then
        rearRightWheelId = wheelNameCache[wheelName] -- ...
      else
        rearLeftWheelId = wheelNameCache[wheelName] -- ...
      end
    end
  end

  initialWheelCount = wheels.wheelCount

  --create an easy way to access the "other" wheel on an axle
  otherWheelOnAxle[frontLeftWheelId] = frontRightWheelId
  otherWheelOnAxle[frontRightWheelId] = frontLeftWheelId
  otherWheelOnAxle[rearLeftWheelId] = rearRightWheelId
  otherWheelOnAxle[rearRightWheelId] = rearLeftWheelId

  local tmpConfigs = {}
  for name, config in pairs(escConfigs.configurations) do
    if type(config) == "table" and config.escConfigurationEnabled then
      table.insert(tmpConfigs, sanitizeConfiguration(shallowcopy(config), name)) --we need to create copies of all our configurations as we are going to use them for saving a few values as well and we want a fresh copy every time we reset the vehicle
    end
  end

  local counter = 1
  escConfigurations = {}
  table.sort(
    tmpConfigs,
    function(a, b)
      return b.order > a.order
    end
  )
  for _, config in pairs(tmpConfigs) do
    escConfigurations[counter] = config
    counter = counter + 1
  end

  if lastESCConfigurationKey ~= -1 then
    currentESCConfigurationKey = lastESCConfigurationKey
  else
    currentESCConfigurationKey = escConfigs.defaultConfig or 1
    lastESCConfigurationKey = currentESCConfigurationKey
  end
  currentESCConfiguration = escConfigurations[currentESCConfigurationKey] --load the default configuration
  gui.message(currentESCConfiguration.name, 5, "vehicle.esc.mode")

  isDebugMode = escConfigs.isDebugMode > 0

  if isDebugMode then
    log("D", "ESC", "ESC configuration data:")
    log("D", "ESC", dumps(configData))
    log("D", "ESC", "Using ESC configuration: " .. currentESCConfiguration.name)
    log("D", "ESC", "Front Left wheel: " .. frontLeftWheelId)
    log("D", "ESC", "Front Right wheel: " .. frontRightWheelId)
    log("D", "ESC", "Rear Left wheel: " .. rearLeftWheelId)
    log("D", "ESC", "Rear Right wheel: " .. rearRightWheelId)
  end

  calculateAxleDistances()
  local statsObj = obj:calcBeamStats()
  mass = statsObj.total_weight --simply the mass of the car

  for _, config in pairs(escConfigurations) do
    if type(config) == "table" and config.escConfigurationEnabled and config.characteristicSpeed <= 0 then --calculate char. speed if no override is provided
      config.characteristicSpeed = calculateCharacteristicSpeed(config)
    end
  end

  desiredYawSmooth = newExponentialSmoothing(currentESCConfiguration.desiredYawRateSmoothing)

  preCalculate()

  --TCS
  crossWheels[frontLeftWheelId] = rearRightWheelId
  crossWheels[rearRightWheelId] = frontLeftWheelId
  crossWheels[frontRightWheelId] = rearLeftWheelId
  crossWheels[rearLeftWheelId] = frontRightWheelId

  local engines = powertrain.getDevicesByCategory("engine") --get all devices with "engine" category
  local blacklistedEngines = {}
  if escConfigs.blacklistedEngines and type(escConfigs.blacklistedEngines) == "table" then
    for _, v in pairs(escConfigs.blacklistedEngines) do
      blacklistedEngines[v] = true
    end
  end
  revLimiterEngines = {}
  for _, v in pairs(engines) do
    --make sure the device supports temp rev limiters, otherwise we'll just run into issues
    if v.setTempRevLimiter and v.resetTempRevLimiter and not blacklistedEngines[v.name] then
      table.insert(revLimiterEngines, v)
    end
  end
  revLimiterEngineCount = #revLimiterEngines
  tempRevLimiterActive = false
  tempRevLimiterTimer = 0

  registerQuickAccess()

  --M.update = update
  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

local function serialize()
  return {escConfigKey = currentESCConfigurationKey}
end

local function deserialize(data)
  if data and data.escConfigKey then
    setESCMode(data.escConfigKey)
  end
end

-- public interface
M.init = init
M.initSecondStage = initSecondStage
M.updateWheelsIntermediate = nil
M.updateGFX = nil
M.toggleESCMode = toggleESCMode
M.setESCMode = setESCMode
M.getCarData = getCarData
M.getCurrentConfigData = getCurrentConfigData
M.startESCCalibration = startESCCalibration
M.stopESCCalibration = stopESCCalibration
M.serialize = serialize
M.deserialize = deserialize

return M
