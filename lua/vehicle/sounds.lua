-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs
local random = math.random

M.engineNode = nil
M.usesOldCustomSounds = false

local sbeamVolumeFactor = 1.5

local windSound = nil
local wheelsSounds = nil

local soundBank = {sounds = {}}
local sfxprofilecounter = 0 -- local counter to enumerate the profiles without collisions, do not reset ever

local beamSounds = {}
local usingNewEngineSounds = false

local boolToNum = {[true] = 1, [false] = 0}

M.uiDebugging = false

local soundObj = {}
soundObj.__index = soundObj

local function createSoundscapeSound(name)
  local soundscapes = v.data.soundscape
  if not soundscapes or not soundscapes[name] then
    return
  end
  local soundscape = soundscapes[name]
  local eventPath = soundscape.src
  local node = type(soundscape.node) == "number" and soundscape.node or M.engineNode
  --print(node)

  local snd = obj:createSFXSource(eventPath, soundscape.descriptor or "AudioDefaultLoop3D", "", node)
  obj:stopSFX(snd)
  return snd
end

local function newSoundObj(sndObj)
  if sndObj == nil then
    return nil
  end
  local data = {obj = sndObj, lastVol = 0, lastPitch = 0, lastColor = 0, lastTexture = 0}
  setmetatable(data, soundObj)
  return data
end

function soundObj:setVolumePitch(vol, pitch, color, texture)
  if vol < 0.01 then
    vol = 0
  end
  if vol == 0 then
    if self.lastVol == 0 then
      return
    end
    color, texture = color or 0, texture or 0
  else
    color, texture = color or 0, texture or 0
    if abs(pitch - self.lastPitch) < 0.001 and max(abs(vol - self.lastVol), abs(color - self.lastColor), abs(texture - self.lastTexture)) < 0.01 then
      return
    end
  end
  self.lastVol = vol
  self.lastPitch = pitch
  self.lastColor = color
  self.lastTexture = texture
  obj:setVolumePitchCT(self.obj, vol, pitch, color, texture)
end

local function playSound(sound, volume)
  if sound then
    obj:setVolume(sound, volume or 1)
    obj:playSFX(sound)
  end
end

local function playSoundOnceAtNode(soundName, nodeID, volume, pitch, color, texture)
  if volume >= 0.01 then
    obj:playSFXOnceStaticCT(soundName, nodeID, volume, pitch or 0, color or 0, texture or 0)
  end
end

local function playSoundOnceFollowNode(soundName, nodeID, volume, pitch, color, texture)
  if volume >= 0.01 then
    obj:playSFXOnceCT(soundName, nodeID, volume, pitch or 0, color or 0, texture or 0)
  end
end

local function getSourceValue(sourcename)
  --in the future possibly replace with the same system props uses for source
  if sourcename == "gear" then
    return drivetrain.gear
  end
  if electrics.values[sourcename] ~= nil then
    return electrics.values[sourcename]
  end
  return nil
end

local function getSoundModifier(modName)
  local modifier = soundBank.modifiersNamed[modName]
  if modifier == nil then
    return 1
  end

  local mVal = getSourceValue(modifier.source)
  if mVal == nil then
    return 1
  end

  return math.min(math.max(modifier.min, modifier.factor * (mVal + modifier.offset)), modifier.max)
end

local function createSFXSource(filename, description, SFXProfileName, nodeID)
  local snd = obj:createSFXSource(filename, description, SFXProfileName, nodeID)
  if snd == nil then
    M.update = nop
    M.playSoundOnceAtNode = nop
    log("W", "sounds.createSFXSource", "failed to create sfx source: " .. SFXProfileName .. " from file " .. filename .. " with description " .. description)
    return nil
  end
  return snd
end

local function createSoundObj(filename, description, SFXProfileName, nodeID)
  local snd = obj:createSFXSource(filename, description, SFXProfileName, nodeID)
  if snd == nil then
    M.update = nop
    M.playSoundOnceAtNode = nop
    log("W", "sounds.createSoundObj", "failed to create sfx source: " .. SFXProfileName .. " from file " .. filename .. " with description " .. description)
    return nil
  end
  return newSoundObj(snd)
end

local function randomGauss()
  local sum = random() + random() + random() + random()
  return sum * 0.25
end

local function updateGFX(dt)
  -- sound bank
  for _, snd in pairs(soundBank.sounds) do
    if snd.active then
      local val = getSourceValue(snd.source) or 0
      val = snd.factor * (val + snd.offset)
      snd.lastVal = val

      local sndVol = 0
      local sndPitch = 0

      --check volume conditions
      if val < snd.volumeBlendInStartValue or val > snd.volumeBlendOutEndValue then
        sndVol = snd.minVolume
      end
      if val > snd.volumeBlendInStartValue and val < snd.volumeBlendInEndValue then
        --blend in volume
        sndVol = lerp(snd.minVolume, snd.maxVolume, (val - snd.volumeBlendInStartValue) / (snd.volumeBlendInEndValue - snd.volumeBlendInStartValue))
      elseif val > snd.volumeBlendInEndValue and val < snd.volumeBlendOutStartValue then
        sndVol = snd.maxVolume
      elseif val > snd.volumeBlendOutStartValue and val < snd.volumeBlendOutEndValue then
        --blend out volume
        sndVol = lerp(snd.minVolume, snd.maxVolume, (((val - snd.volumeBlendOutStartValue) / (snd.volumeBlendOutEndValue - snd.volumeBlendOutStartValue)) - 1) * -1)
      end

      --check pitch conditions
      if val < snd.pitchBlendInStartValue then
        sndPitch = snd.minPitch
      end
      if val > snd.pitchBlendInEndValue then
        sndPitch = snd.maxPitch
      end
      if val > snd.pitchBlendInStartValue and val < snd.pitchBlendInEndValue then
        --blend pitch
        sndPitch = lerp(snd.minPitch, snd.maxPitch, (val - snd.pitchBlendInStartValue) / (snd.pitchBlendInEndValue - snd.pitchBlendInStartValue))
      end

      --apply modifiers if applicable
      for _, s in pairs(snd.volumeModifiers) do
        sndVol = sndVol * getSoundModifier(s)
      end
      for _, s in pairs(snd.pitchModifiers) do
        sndPitch = sndPitch * getSoundModifier(s)
      end

      snd.lastVolume = sndVol
      snd.lastPitch = sndPitch
      snd.clip:setVolumePitch(sndVol, sndPitch)
    end
  end

  -- beam sounds
  for _, snd in ipairs(beamSounds) do
    local currentStress = snd.smoothing:get(obj:getBeamStress(snd.beam), dt) -- find the stress on the current sound beam
    local impulse = (snd.lastStress - currentStress) / (dt * 30) -- take the difference in beam stress between this frame and the last frame, and save it as impulse
    snd.resonance = math.max(math.min(snd.resonance or 0, snd.maxStress), 0) --limit sound factor to maxStress to prevent overly loud/long sounds
    local linDecay = (1 - snd.decayMode) * snd.resonance * snd.decayFactor * dt
    local expDecay = snd.decayMode * snd.resonance * snd.decayFactor * dt
    local factor = math.max(impulse, math.max(snd.resonance - linDecay - expDecay, 0)) --sound decays to create a smooth fade out. Rate is dependent on simulation speed.

    snd.lastStress = currentStress --reset for next frame comparison

    local volume = (factor * snd.volumeFactor * 1.3) / snd.maxStress -- normalize volume (cancel out maxStress factor)
    local pitch = 1 + (snd.pitchFactor * (factor / snd.maxStress)) -- loud suspension sounds also gain a higher pitch

    if snd.resetTimer > 1 then --prevent loud sounds from playing on spawn
      snd.clip:setVolumePitch(volume, pitch)
    else
      snd.resetTimer = snd.resetTimer + dt
      snd.clip:setVolumePitch(0, 0)
    end

    snd.resonance = factor --reset for next frame comparison
  end

  -- wind
  if windSound then
    local speed = obj:getAirflowSpeed() -- speed against wind
    local vol = min(speed * speed * 0.001, 10)
    local pitch = speed / 60
    windSound:setVolumePitch(vol, pitch)
  end

  -- wheels
  for wi, wd in pairs(wheels.wheels) do
    local wheelSound = wheelsSounds[wi]
    local slip = wd.lastSlip

    local maxLooseRollVolume = 0
    local maxLooseRollPitch = 0
    local maxLooseRollSlip = 0

    --asphalt: 10
    --asphalt prepped: 10
    --asphalt old: 11
    --asphalt wet: 11
    --rock: 13
    --dirt dusty: 14
    --dirt: 15
    --sand: 16
    --gravel: 19
    --grass: 20
    --ice: 21
    --rumble strip: 29

    --shared stuff for most surfaces
    local isRubberTire = wd.contactMaterialID2 == 4
    local tirePatchPressure = wd.downForce * 0.00001 / (wd.radius * wd.tireWidth)
    local absWheelSpeed = abs(wd.angularVelocity * wd.radius)
    local wheelPeripherySpeed = max(slip * 5, absWheelSpeed)
    local rollVol = tirePatchPressure * min(1, wheelPeripherySpeed * 0.5)
    local surfaceLooseness = 0

    local gravelContactSmooth = wheelSound.gravelContactSmoother:getUncapped(boolToNum[wd.contactMaterialID1 == 19 and isRubberTire], dt)
    if gravelContactSmooth > 0 then
      --we need two different periphery speeds, one for general "pitch" of the roll noise and the other for kickup timing, they differ in how slip velocity affects them
      surfaceLooseness = 0.2 * gravelContactSmooth + surfaceLooseness * (1 - gravelContactSmooth)
      maxLooseRollPitch = max(maxLooseRollPitch, min(1, wheelPeripherySpeed * 0.01))
      maxLooseRollVolume = max(maxLooseRollVolume, rollVol * gravelContactSmooth)
      maxLooseRollSlip = max(maxLooseRollSlip, slip * 0.01)

      wheelSound.looseSurfaceKickupTimer = wheelSound.looseSurfaceKickupTimer - dt
      if wheelSound.looseSurfaceKickupTimer <= 0 then
        local wheelPeripherySpeedKickup = max(slip * 20, absWheelSpeed)
        if wheelPeripherySpeedKickup > 2 then
          local kickupVolume = min(1, wheelPeripherySpeedKickup * 0.005)
          playSoundOnceAtNode("event:>Surfaces>kickup_gravel", wd.node1, kickupVolume, 1)
          local kickupTime = 8 / wheelPeripherySpeedKickup
          wheelSound.looseSurfaceKickupTimer = kickupTime * randomGauss() * 2
        end
      end
    end

    local dirtContactSmooth = wheelSound.dirtContactSmoother:getUncapped(boolToNum[(wd.contactMaterialID1 == 15 or wd.contactMaterialID1 == 14) and isRubberTire], dt)
    if dirtContactSmooth > 0 then
      surfaceLooseness = 0.4 * dirtContactSmooth + surfaceLooseness * (1 - dirtContactSmooth)
      maxLooseRollPitch = max(maxLooseRollPitch, min(1, wheelPeripherySpeed * 0.01))
      maxLooseRollVolume = max(maxLooseRollVolume, rollVol * dirtContactSmooth)
      maxLooseRollSlip = max(maxLooseRollSlip, slip * 0.01)

      wheelSound.looseSurfaceKickupTimer = wheelSound.looseSurfaceKickupTimer - dt
      if wheelSound.looseSurfaceKickupTimer <= 0 then
        local wheelPeripherySpeedKickup = max(slip * 20, absWheelSpeed)
        if wheelPeripherySpeedKickup > 2 then
          local kickupVolume = min(1, wheelPeripherySpeedKickup * 0.01)
          playSoundOnceAtNode("event:>Surfaces>kickup_dirt", wd.node1, kickupVolume, 1)
          wheelSound.looseSurfaceKickupTimer = randomGauss() * 16 / wheelPeripherySpeedKickup
        end
      end
    end

    local grassContactSmooth = wheelSound.grassContactSmoother:getUncapped(boolToNum[wd.contactMaterialID1 == 20 and isRubberTire], dt)
    if grassContactSmooth > 0 then
      surfaceLooseness = 0.6 * grassContactSmooth + surfaceLooseness * (1 - grassContactSmooth)
      maxLooseRollPitch = max(maxLooseRollPitch, min(1, wheelPeripherySpeed * 0.01))
      maxLooseRollVolume = max(maxLooseRollVolume, rollVol * grassContactSmooth)
      maxLooseRollSlip = max(maxLooseRollSlip, slip * 0.01)

      wheelSound.looseSurfaceKickupTimer = wheelSound.looseSurfaceKickupTimer - dt
      if wheelSound.looseSurfaceKickupTimer <= 0 then
        local wheelPeripherySpeedKickup = max(slip * 12, absWheelSpeed)
        if wheelPeripherySpeedKickup > 2 then
          local kickupVolume = min(1, wheelPeripherySpeedKickup * 0.01)
          playSoundOnceAtNode("event:>Surfaces>kickup_grass", wd.node1, kickupVolume, 1)
          wheelSound.looseSurfaceKickupTimer = randomGauss() * 12 / wheelPeripherySpeedKickup
        end
      end
    end

    local sandContactSmooth = wheelSound.sandContactSmoother:getUncapped(boolToNum[wd.contactMaterialID1 == 16 and isRubberTire], dt)
    if sandContactSmooth > 0 then
      surfaceLooseness = 0.8 * sandContactSmooth + surfaceLooseness * (1 - sandContactSmooth)
      maxLooseRollPitch = max(maxLooseRollPitch, min(1, wheelPeripherySpeed * 0.01))
      maxLooseRollVolume = max(maxLooseRollVolume, rollVol * sandContactSmooth)
      maxLooseRollSlip = max(maxLooseRollSlip, slip * 0.01)

      wheelSound.looseSurfaceKickupTimer = wheelSound.looseSurfaceKickupTimer - dt
      if wheelSound.looseSurfaceKickupTimer <= 0 then
        local wheelPeripherySpeedKickup = max(slip * 12, absWheelSpeed)
        if wheelPeripherySpeedKickup > 2 then
          local kickupVolume = min(1, wheelPeripherySpeedKickup * 0.01)
          playSoundOnceAtNode("event:>Surfaces>kickup_sand", wd.node1, kickupVolume, 1)
          wheelSound.looseSurfaceKickupTimer = randomGauss() * 8 / wheelPeripherySpeedKickup
        end
      end
    end

    surfaceLooseness = wheelSound.loosenessSmoother:getUncapped(surfaceLooseness, dt)
    wheelSound.looseSurfaceRoll:setVolumePitch(maxLooseRollVolume, maxLooseRollPitch, maxLooseRollSlip, surfaceLooseness)

    -- asphalt
    local asphaltRollVolume = 0
    local asphaltRollPitch = 0
    local asphaltSkidVolume = 0
    local asphaltSkidPitch = 0
    local asphaltSkidColor = 0
    local asphaltSkidTexture = 0

    local asphaltContactSmooth = wheelSound.asphaltContactSmoother:getUncapped(boolToNum[(wd.contactMaterialID1 == 10 or wd.contactMaterialID1 == 29) and isRubberTire and wd.contactDepth == 0], dt)
    if asphaltContactSmooth > 0 then
      asphaltRollPitch = min(1, absWheelSpeed * 0.0125)
      asphaltRollVolume = rollVol * asphaltContactSmooth * 3

      asphaltSkidVolume = tirePatchPressure * slip * 0.1 * asphaltContactSmooth
      asphaltSkidPitch = 0.005 * slip * wheelSound.tireVolumePitchCoef

      local pressureSmooth = wheelSound.asphaltPressureSmoother:get(tirePatchPressure, dt)
      asphaltSkidColor = ((tirePatchPressure - pressureSmooth) * 4.0) + 0.5
      asphaltSkidTexture = absWheelSpeed * 0.1 - 2
    end

    wheelSound.asphaltRoll:setVolumePitch(asphaltRollVolume, asphaltRollPitch)
    wheelSound.asphaltSkid:setVolumePitch(asphaltSkidVolume, asphaltSkidPitch, asphaltSkidColor, asphaltSkidTexture)

    --rumblestrip
    local rumbleStripContactSmooth = wheelSound.rumbleStripContactSmoother:getUncapped(boolToNum[wd.contactMaterialID1 == 29 and isRubberTire], dt)
    if rumbleStripContactSmooth > 0 then
      local vehicleSpeed = obj:getGroundSpeed()
      local peakForce = wd.peakForce
      if peakForce > 0 and wd.obj:getPeakPeriod() * vehicleSpeed > 0.2 then
        local volume = max(0, min(1, vehicleSpeed) * peakForce * 0.00001 / (wd.radius * wd.tireWidth) - 0.4) * 2
        playSoundOnceAtNode("event:>Surfaces>rumblestrip_single_mark", wd.node1, volume, vehicleSpeed * 0.015)
      end
    end
  end

  if M.uiDebugging and playerInfo.firstPlayerSeated then
    guihooks.trigger("AudioDebug", soundBank)
  end
end

local function addWheelSound(wheelID, wd, filename, description, profile)
  if wheelsSounds[wheelID] == nil then
    wheelsSounds[wheelID] = {
      gravelContactSmoother = newTemporalSmoothing(2, 4),
      dirtContactSmoother = newTemporalSmoothing(2, 4),
      grassContactSmoother = newTemporalSmoothing(2, 4),
      sandContactSmoother = newTemporalSmoothing(2, 4),
      asphaltContactSmoother = newTemporalSmoothing(4, 4),
      loosenessSmoother = newTemporalSmoothing(5, 5),
      rumbleStripContactSmoother = newTemporalSmoothing(3, 10000),
      asphaltPressureSmoother = newTemporalSmoothingNonLinear(1, 1),
      looseSurfaceKickupTimer = 0,
      tireVolumePitchCoef = (0.5 - 2) * (wd.tireVolume - 0.010) / (0.2 - 0.01) + 2
    }
  end

  -- const char *filename, const char *descriptionName, const char* sfxProfileName, bool preload
  wheelsSounds[wheelID][profile] = createSoundObj(filename, description, profile, wd.node1)
end

local function loadSoundFiles(directory)
  --log('D', "sounds.loadSoundFiles", "loading sound files from: "..directory)
  local files = FS:findFiles(directory, "*.sbeam", -1, true, false)
  if not files or #files == 0 then
    --log('D', 'sounds.loadSoundFiles', 'unable to open directory for reading: ' .. directory)
    return
  end

  -- first: figure out all the filenames. TODO: recursive?
  local sbeamFiles = {}
  for _, file in ipairs(files) do
    table.insert(sbeamFiles, file)
  end

  --load and merge
  local soundBank = {}
  for _, sbfn in pairs(sbeamFiles) do
    local tmp = readDictJSONTable(sbfn)
    if tmp then
      for _, v in pairs(tmp.sounds) do
        v.minVolume = v.minVolume * sbeamVolumeFactor
        v.maxVolume = v.maxVolume * sbeamVolumeFactor
      end

      tableMergeRecursive(soundBank, tmp)
    else
      log("E", "sounds.lua", "sbeam file empty or unable to parse: " .. sbfn)
    end
  end

  -- fallback if no sounds were loaded
  if not soundBank.sounds then
    soundBank.sounds = {}
  end

  -- create lookup table
  if soundBank.modifiers then
    soundBank.modifiersNamed = {}
    for _, sbm in pairs(soundBank.modifiers) do
      soundBank.modifiersNamed[sbm.name] = sbm
    end
  end

  if type(soundBank.sounds) == "table" then
    --log('D', "sounds.loadSoundFiles", 'loaded '.. #soundBank.sounds .. ' sounds from directory ' .. directory)
  else
    log("D", "sounds.loadSoundFiles", "no sounds loaded from directory " .. directory)
    return nil
  end

  return soundBank
end

local function checkLocalFile(folder, file)
  if not FS:fileExists(file) then
    local testfn = folder .. file
    if FS:fileExists(testfn) then
      return testfn
    end
  end
  return file
end

local function getNextProfile()
  sfxprofilecounter = sfxprofilecounter + 1
  return "LuaSoundProfile" .. sfxprofilecounter .. "_" .. os.time()
end

local function init()
  obj:deleteSFXSources()
  local cameraNode = 0
  if v.data.camerasInternal ~= nil then
    local _, c = next(v.data.camerasInternal)
    if c ~= nil then
      cameraNode = c.camNodeID
    end
  end

  --replace constants
  local maxrpm = 1
  if v.data.refNodes and v.data.refNodes[0] and v.data.refNodes[0].leftCorner then
    M.engineNode = v.data.refNodes[0].leftCorner
  elseif cameraNode > 0 then
    M.engineNode = cameraNode
  elseif v.data.refNodes and v.data.refNodes[0] and v.data.refNodes[0].ref then
    M.engineNode = v.data.refNodes[0].ref
  else
    M.engineNode = 0
  end
  if #powertrain.engineData > 0 then
    for _, v in pairs(powertrain.engineData) do
      maxrpm = math.max(maxrpm, v.maxSoundRPM or 1)
    end

    -- Try to get a node on the engine. There is currently a libbeamng bug that
    -- causes sound sources at the camera to cause problems for multichannel
    -- setups, as small variations in position can cause sound to dither back
    -- and forth between the channels when in cockpit view.
    if powertrain.engineData[1].torqueReactionNodes then
      local t = powertrain.engineData[1].torqueReactionNodes
      if #t > 0 and v.data.nodes[t[1]] ~= nil then
        M.engineNode = t[1]
      end
    end
  end

  local loadedFolder = v.vehicleDirectory .. "sounds/"

  --load sbeam files
  local sounds = loadSoundFiles(loadedFolder)
  M.usesOldCustomSounds = tableSize(sounds) > 0

  --no sbeam files on current vehicle, load defaults
  if not sounds then
    loadedFolder = "vehicles/common/sounds/"
    sounds = loadSoundFiles(loadedFolder)
  end

  if sounds then
    --store in module
    soundBank = sounds
    if usingNewEngineSounds then
      soundBank.sounds = {}
    end

    -- build node name index
    local nodeNameIdx = {}
    for _, node in pairs(v.data.nodes) do
      if node.name then
        nodeNameIdx[node.name] = node.cid
      end
    end

    --check and postprocess them
    for skey, s in pairs(soundBank.sounds) do
      -- set default values
      if s.volumeModifiers == nil then
        s.volumeModifiers = {}
      end
      if s.pitchModifiers == nil then
        s.pitchModifiers = {}
      end
      if s.profile == nil then
        s.profile = "AudioDefaultLoop3D"
      end

      -- create the sfxprofiles dynamically when filename and profile are specified
      if not s.sfxProfile and s.filename and s.profile then
        -- figure out if the filename was specified relative to the current folder
        s.filename = checkLocalFile(loadedFolder, s.filename)

        -- create the SFXProfile on the T3D - at least the supposed SFXprofilename
        s.sfxProfile = getNextProfile()
        s.waitforloading = 1 -- wait one frame before trying to load the sfxprofile
        s.autocreatedSFXProfile = true
      end

      --try to find our node, default to camera
      s.node = nodeNameIdx[s.nodeName]
      if s.nodeName == "CAMERA" then
        s.node = cameraNode
      end
      if s.nodeName == "ENGINE" then
        s.node = M.engineNode
      end
      s.node = s.node or cameraNode -- fall back to camera node

      s.clip = createSoundObj(s.filename, s.profile, s.sfxProfile, s.node)
      --log('D', 'sounds.update', 'createSFXSource('..s.sfxProfile..','..s.node..') = '..tostring(s.clip))
      if not s.clip then
        log("W", "sounds.update", "unable to create sound, removing it: " .. s.sfxProfile)
        soundBank.sounds[skey] = nil
      end
    end

    for _, snd in pairs(soundBank.sounds) do
      for k2, v2 in pairs(snd) do
        if v2 == "MAXRPM" then
          snd[k2] = maxrpm
        end
      end
    end

    --initialize groups
    local soundGroup = v.data.engine and v.data.engine.soundGroup
    for _, vl in pairs(soundBank.sounds) do
      vl.active = (vl.group == "default" or vl.group == soundGroup)
    end

    --    local rollingSoundLookup = {}
    --    --surface sounds
    --    for k,v in pairs(soundBank.groundmodelSounds or {}) do
    --      if not rollingSoundLookup[v.rubberRollingSound] then
    --        rollingSoundLookup[v.rubberRollingSound] = {}
    --      end
    --      table.insert(rollingSoundLookup[v.rubberRollingSound], v.groundmodel)
    --    end
    --    dump(rollingSoundLookup)

    --    wheelGroundmodelSounds = {}
    --    local groundModelIDLookupTmp = {ASPHALT = 10, DIRT_DUSTY = 14, DIRT = 15, GRAVEL = 19}
    --    for wi,wd in pairs(wheels.wheels) do
    --      wheelGroundmodelSounds[wi] = {}
    --      for k,v in pairs(rollingSoundLookup) do
    ----        local sound = obj:createSFXSource("art/sound/groundmodels/"..k, "AudioDefaultLoop3D", k, wd.node1)
    ----        for _,gm in pairs(v) do
    ----          local gmId = groundModelIDLookupTmp[gm]-- obj:getGroundModelId(gm)
    ----          print(gmId)
    ----          wheelGroundmodelSounds[wi][gmId] = sound
    ----        end
    --      end
    --    end
    --    dump(wheelGroundmodelSounds)

    --initialize per beam sounds
    if v.data.beams then
      for _, bm in pairs(v.data.beams) do
        if bm.soundFile ~= nil then
          local soundTable = {}

          --loop
          local soundProfileType = "AudioDefaultLoop3D"

          --setup our table
          local soundFile = checkLocalFile(v.vehicleDirectory, bm.soundFile)
          soundTable.soundType = bm.soundType
          soundTable.sfxProfile = getNextProfile()
          soundTable.clip = createSoundObj(soundFile, soundProfileType, soundTable.sfxProfile, bm.id1)
          if soundTable.clip then
            soundTable.volumeFactor = bm.volumeFactor or 1
            soundTable.pitchFactor = bm.pitchFactor or 0
            soundTable.decayFactor = bm.decayFactor or 1
            soundTable.decayMode = bm.decayMode or 0 --linear or exponential sound decay?
            soundTable.minStress = bm.minStress or 25000
            soundTable.maxStress = bm.maxStress or 35000

            soundTable.beam = bm.cid
            soundTable.lastStress = 0

            soundTable.smoothing = newTemporalSmoothingNonLinear(10)

            soundTable.resonance = 0
            soundTable.resetTimer = 0

            soundTable.clip:setVolumePitch(0, 0)

            --finally, insert it
            table.insert(beamSounds, soundTable)
          else
            --log('E', 'sounds.init', 'unable to load sound: ' .. tostring(soundFile))
          end
        end
      end
    else
      log("E", "sounds.init", "unable to load any sound bank (*.sbeam), that is quite bad :/")
    end
  end

  -- TODO: Find a better place to emit wind sounds. Maybe at the windows?
  if windSound == nil then
    windSound = createSoundObj("event:>Wind", "AudioDefaultLoop3D", "WindTestSound", M.engineNode)
  end

  if wheelsSounds == nil then
    wheelsSounds = {}

    for wi, wd in pairs(wheels.wheels) do
      addWheelSound(wi, wd, "event:>Surfaces>roll_loose", "AudioDefaultLoop3D", "looseSurfaceRoll")
      addWheelSound(wi, wd, "event:>Surfaces>roll_asphalt", "AudioDefaultLoop3D", "asphaltRoll")
      addWheelSound(wi, wd, "event:>Surfaces>skid_asphalt", "AudioDefaultLoop3D", "asphaltSkid")
      -- addWheelSound(wi, wd, "event:>Surfaces>rumblestrip_loop_mark", "AudioDefaultLoop3D", "rumbleStripRoll")
    end
  end
end

-- this function enables or disables the data reporting to the UI. It is quite performance heavy and should be only used for debugging
local function setUIDebug(enabled, data)
  M.uiDebugging = enabled
  -- todo: save data
end

local function onDeserialized()
end

local function disableOldEngineSounds()
  soundBank.sounds = {}
  usingNewEngineSounds = true
end

local fmodtable = {20.0, 40.0, 80.0, 160.0, 330.0, 660.0, 1300.0, 2700.0, 5400.0, 11000.0, 22000.0}
local function hzToFMODHz(hzValue)
  local range = #fmodtable - 1
  hzValue = max(fmodtable[1], min(hzValue, fmodtable[#fmodtable]))
  for i = range, 1, -1 do
    if fmodtable[i] <= hzValue then
      range = i
      break
    end
  end
  return 100 * ((range - 1) + ((hzValue - fmodtable[range]) / (fmodtable[range + 1] - fmodtable[range])))
end

-- public interface
M.updateGFX = updateGFX
M.playSoundOnceAtNode = playSoundOnceAtNode
M.playSoundOnceFollowNode = playSoundOnceFollowNode
M.destroy = destroy
M.init = init
M.setUIDebug = setUIDebug
M.createSFXSource = createSFXSource
M.onDeserialized = onDeserialized --this enables serialization of all M. values for the module so they survive reloads
M.disableOldEngineSounds = disableOldEngineSounds
M.hzToFMODHz = hzToFMODHz
M.createSoundscapeSound = createSoundscapeSound
M.playSound = playSound

return M
