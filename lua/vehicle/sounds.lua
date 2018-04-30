-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min

M.engineNode = nil
M.usesOldCustomSounds = false

local debugVolumeFactor = 1.0
local sbeamVolumeFactor = 1.5

local windSound = nil
local wheelsSounds = nil

local wheelGroundmodelSounds = {}

local soundBank = { sounds = {} }
local sfxprofilecounter = 0 -- local counter to enumerate the profiles without collisions, do not reset ever

local beamSounds = {}
local usingNewEngineSounds = false

M.uiDebugging = false

local soundObj = {}
soundObj.__index = soundObj

local totalSounds = 0
local playingSounds = 0

function newSoundObj(sndObj)
  if sndObj == nil then return nil end
  local data = {obj = sndObj, lastVol = 0, lastPitch = 0}
  setmetatable(data, soundObj)
  return data
end

function soundObj:setVolumePitch(vol, pitch)
  vol = vol * debugVolumeFactor
  totalSounds = totalSounds + 1
  if vol < 0.01 then vol = 0 end
  if vol == 0 then
    if self.lastVol == 0 then return end
  else
    playingSounds = playingSounds + 1
    if math.abs(vol - self.lastVol) < 0.01 and math.abs(pitch - self.lastPitch) < 0.001 then return end
  end
  self.lastVol = vol
  self.lastPitch = pitch
  obj:setVolumePitch(self.obj, vol, pitch)
end

local function playSoundOnceAtNode(soundName, nodeID, volume)
  if volume < 0.01 then return end
  obj:playSFXOnce(soundName, nodeID, volume, 1)
end

local function getSourceValue(sourcename)
  --in the future possibly replace with the same system props uses for source
  if sourcename == "gear" then return drivetrain.gear end
  if electrics.values[sourcename] ~= nil then return electrics.values[sourcename] end
  return nil
end

local function getSoundModifier(modName)
  local modifier = soundBank.modifiersNamed[modName]
  if modifier == nil then return 1 end

  local mVal = getSourceValue(modifier.source)
  if mVal == nil then return 1 end

  return math.min(math.max(modifier.min, modifier.factor * (mVal + modifier.offset)), modifier.max)
end

local function getNodeByName(nodename)
  if not v.data or not v.data.nodes then return nil end
  for _,node in pairs(v.data.nodes) do
    if node.name == nodename then return node.cid end
  end
  return nil
end

local function createSFXSource(filename, description, SFXProfileName, nodeID)
  local snd = obj:createSFXSource(filename, description, SFXProfileName, nodeID)
  if snd == nil then
    M.update = nop
    M.playSoundOnceAtNode = nop
    log('W', 'sounds.createSFXSource', 'failed to create sfx source: ' .. SFXProfileName.. ' from file ' .. filename .. ' with description ' .. description )
    return nil
  end
  return snd
end

local function createSoundObj(filename, description, SFXProfileName, nodeID)
  local snd = obj:createSFXSource(filename, description, SFXProfileName, nodeID)
  if snd == nil then
    M.update = nop
    M.playSoundOnceAtNode = nop
    log('W', 'sounds.createSoundObj', 'failed to create sfx source: ' .. SFXProfileName.. ' from file ' .. filename .. ' with description ' .. description )
    return nil
  end
  return newSoundObj(snd)
end

local function update(dt)
  totalSounds = 0
  playingSounds = 0
  -- sound bank
  for sndkey, snd in pairs(soundBank.sounds) do
    if snd.active == false then goto continue end

    local val = getSourceValue(snd.source) or 0
    val = snd.factor * (val + snd.offset )
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
      sndVol = lerp(snd.minVolume, snd.maxVolume, (((val - snd.volumeBlendOutStartValue) / (snd.volumeBlendOutEndValue - snd.volumeBlendOutStartValue)) -1) * -1)
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
    for _,s in pairs(snd.volumeModifiers) do
      sndVol = sndVol * getSoundModifier(s)
    end
    for _,s in pairs(snd.pitchModifiers) do
      sndPitch = sndPitch * getSoundModifier(s)
    end

    snd.lastVolume = sndVol
    snd.lastPitch = sndPitch
    snd.clip:setVolumePitch(sndVol, sndPitch)
    ::continue::
  end

  -- beam sounds
  ----[[
  for _, snd in ipairs(beamSounds) do
    local currentStress = snd.smoothing:get(obj:getBeamStress(snd.beam), dt)                        -- find the stress on the current sound beam
    local impulse = (snd.lastStress - currentStress) / (dt * 30)                                -- take the difference in beam stress between this frame and the last frame, and save it as impulse
    snd.resonance = math.max(math.min(snd.resonance or 0, snd.maxStress), 0)  --limit sound factor to maxStress to prevent overly loud/long sounds
    local linDecay = (1 - snd.decayMode) * snd.resonance * snd.decayFactor * dt
    local expDecay = snd.decayMode * snd.resonance * snd.decayFactor * dt
    local factor = math.max(impulse, math.max(snd.resonance - linDecay - expDecay, 0)) --sound decays to create a smooth fade out. Rate is dependent on simulation speed.

    snd.lastStress = currentStress  --reset for next frame comparison
    --lastImpulse = impulse   --reset for next frame comparison -- unused?

    local volume = (factor * snd.volumeFactor * 1.3) / snd.maxStress  -- normalize volume (cancel out maxStress factor)
    local pitch = 1 + (snd.pitchFactor * (factor / snd.maxStress))  -- loud suspension sounds also gain a higher pitch

    if snd.resetTimer > 1 then  --prevent loud sounds from playing on spawn
      snd.clip:setVolumePitch(volume, pitch)
    else
      snd.resetTimer = snd.resetTimer + dt
      snd.clip:setVolumePitch(0, 0)
    end

    snd.resonance = factor --reset for next frame comparison
  end
  --]]

  -- wind
  if windSound then
    local speed = obj:getAirflowSpeed() -- speed against wind
    local vol = (speed * speed * 0.001)
    local pitch = speed / 60
    if vol > 10 then vol = 10 end
    windSound:setVolumePitch(vol, pitch)
--	print(vol)
  end

  -- wheels
  for wi,wd in pairs(wheels.wheels) do
    local w = wd.obj
    local slip = wd.lastSlip--m/s
    local absWheelSpeed = math.abs(w.angularVelocity * wd.radius)--m/s

--    for k,v in pairs(wheelGroundmodelSounds[wi]) do
--      if wd.contactMaterialID1 == k then
--        local wheelSpeed = math.abs(w.angularVelocity * wd.radius)
--        local rollVol = 1 * math.min(math.sqrt(wheelSpeed * 0.018), 1)
--        obj:setVolumePitch(v, rollVol, 1)
--        --print(k)
--      else
--        obj:setVolumePitch(v, 0, 1)
--      end
--    end

    local skidVol = 0
    local skidPitch = 0
    local rollVol = 0
    local rollPitch = 0

    --sound tuning variables
    local minSlip = 1           --the amount of wheel slip where cross fade, skid vol and pitching starts
    local maxSlip = 10          --the amount of wheel slip where cross fade ends, skid vol reaches max
    local skidPitchMaxSlip = 13 --the amount of wheel slip where skid pitch reaches max
    local skidStartPitch = 0.7  --starting pitch of the skid sound (at minSlip condition)
    local skidEndPitch = 1      --ending pitch of the skid sound (at pitchMaxSlip condition)
    local skidVolCurveCoef = 3  --changes the curve of skid volume. Higher number creates a faster onset but doesnt change the max/min volume or pitch.
    local rollCurveCoef = 0.1   --changes the curve of rolling sound and pitch. Higher number creates a faster onset but doesnt change the max/min volume or pitch.
    local rollStartPitch = 0.7  --starting pitch of the roll sound (at 0 wheelspeed)
    local rollEndPitch = 1.2    --ending pitch (at infinite wheelspeed)

    local skidPitchSlope = (skidEndPitch - skidStartPitch) / (skidPitchMaxSlip - minSlip)

    --local contact = (wd.contactMaterialID1 == 15 and wd.contactMaterialID2 == 4 and wd.contactDepth == 0) and 1 or 0
    local contact = (wd.contactMaterialID1 == 10 and wd.contactMaterialID2 == 4 and wd.contactDepth == 0) and 1 or 0
    local contactSmooth = wd.tireContactSmoother:getWithRateUncapped(contact, dt, 4)

    --if wd.contactMaterialID1 == 10 and wd.contactMaterialID2 == 4 and wd.contactDepth == 0  then
    if contactSmooth > 0 then
      --reduce minSlip value when the tire is nearly stopped to avoid silence when locked brake skidding to a stop
      minSlip = math.min(absWheelSpeed, minSlip)

      -- crossfade smoothly between skid and rolling
      local slipSm = wd.slipSkidFadeSmoother:get(math.min(slip, maxSlip), dt)
      local skidCrossfade =   math.max(0, math.min((slipSm - minSlip) / maxSlip, 1))
      local rollCrossfade =   1 - skidCrossfade

      -- rolling sound
      local rollSpeed = absWheelSpeed * rollCurveCoef
      rollVol = rollCrossfade * math.min(rollSpeed / (1 + rollSpeed), 1) * contactSmooth
      rollPitch = rollVol * (rollEndPitch - rollStartPitch) + rollStartPitch

      -- scrubbing/skidding sound
      local slipSmSkidVol = wd.slipSkidVolSmoother:get(math.min(slip, maxSlip), dt)
      skidVol = math.max(slipSmSkidVol - minSlip, 0) / (maxSlip - minSlip) * contactSmooth

      local slipSmSkidPitch = wd.slipSkidPitchSmoother:get(math.min(slip, skidPitchMaxSlip), dt)
      skidPitch = skidStartPitch + skidPitchSlope * math.min(slipSmSkidPitch, skidPitchMaxSlip - minSlip)
      --apply scaling curve to volume for faster onset of sound
      skidVol = skidVolCurveCoef * skidVol / ((skidVolCurveCoef - 1) * skidVol + 1)

      --if wi == 0 then log("I", "", "energ: "..graphs(slipEnergySmSkidVol/2, 35).." vol: "..graphs(skidVol*10, 20).." vol: "..dumps(skidVol).." energ: "..dumps(slipEnergySmSkidVol)) end
    end
    --skidVol and rollVol are always 0-1 values
    wheelsSounds[wi]["SkidTestSound"]:setVolumePitch(skidVol, skidPitch)
    wheelsSounds[wi]["RollingTestSound"]:setVolumePitch(rollVol, rollPitch)
  end

  if M.uiDebugging and playerInfo.firstPlayerSeated then
    guihooks.trigger("AudioDebug", soundBank)
  end
  -- print('s: '..playingSounds..'/'..totalSounds)
end

-- public interface
M.update  = update
M.playSoundOnceAtNode = playSoundOnceAtNode

local function addWheelSound(wheelID, wd, filename, description, profile)
  if wheelsSounds == nil then wheelsSounds = {} end
  if wheelsSounds[wheelID] == nil then wheelsSounds[wheelID] = {} end

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
  local file = nil
  local sbeamFiles = {}
  for _, file in ipairs(files) do
    table.insert(sbeamFiles, file)
  end

  --load and merge
  local soundBank = {}
  for _, sbfn in pairs(sbeamFiles) do
    local tmp = readDictJSONTable(sbfn)
    if tmp == nil then
      log('E', 'sounds.lua', 'sbeam file empty or unable to parse: ' .. sbfn)
      goto continue
    end

    for i, v in pairs(tmp.sounds) do
      v.minVolume = v.minVolume * sbeamVolumeFactor
      v.maxVolume = v.maxVolume * sbeamVolumeFactor
    end

    tableMergeRecursive(soundBank, tmp)
    ::continue::
  end

  -- fallback if no sounds were loaded
  if not soundBank.sounds then soundBank.sounds = {} end

  -- create lookup table
  if soundBank.modifiers then
    soundBank.modifiersNamed = {}
    for _, sbm in pairs(soundBank.modifiers) do
      soundBank.modifiersNamed[sbm.name] = sbm
    end
  end

  if type(soundBank.sounds) == 'table' then
    --log('D', "sounds.loadSoundFiles", 'loaded '.. #soundBank.sounds .. ' sounds from directory ' .. directory)
  else
    log('D', "sounds.loadSoundFiles", 'no sounds loaded from directory ' .. directory)
    return nil
  end

  return soundBank
end

local function checkLocalFile(folder,file)
  if not FS:fileExists(file) then
    local testfn = folder..file
    if FS:fileExists(testfn) then
      return testfn
    end
  end
  return file
end

local function getNextProfile()
  sfxprofilecounter = sfxprofilecounter + 1
  return 'LuaSoundProfile'..sfxprofilecounter..'_'.. os.time()
end

local function init()
  obj:deleteSFXSources()
  local cameraNode = 0
  if v.data.camerasInternal ~= nil then
    local k, c = next(v.data.camerasInternal)
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
    for _,v in pairs(powertrain.engineData) do
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

  local loadedFolder = v.vehicleDirectory..'sounds/'

  --load sbeam files
  local sounds = loadSoundFiles(loadedFolder)
  M.usesOldCustomSounds = tableSize(sounds) > 0

  --no sbeam files on current vehicle, load defaults
  if not sounds then
    loadedFolder = 'vehicles/common/sounds/'
    sounds = loadSoundFiles(loadedFolder)
  end

  if sounds then
    --store in module
    soundBank = sounds
    if usingNewEngineSounds then
      soundBank.sounds = {}
    end

    --check and postprocess them
    for skey, s in pairs(soundBank.sounds) do
      -- set default values
      if s.volumeModifiers == nil then s.volumeModifiers = {} end
      if s.pitchModifiers == nil then s.pitchModifiers= {} end
      if s.profile == nil then s.profile = 'AudioDefaultLoop3D' end

      -- create the sfxprofiles dynamically when filename and profile are specified
      if not s.sfxProfile and s.filename and s.profile then
        -- figure out if the filename was specified relative to the current folder
        s.filename = checkLocalFile(loadedFolder,s.filename)

        -- create the SFXProfile on the T3D - at least the supposed SFXprofilename
        s.sfxProfile = getNextProfile()
        s.waitforloading = 1 -- wait one frame before trying to load the sfxprofile
        s.autocreatedSFXProfile = true
      end

      --try to find our node, default to camera
      s.node = getNodeByName(s.nodeName)
      if s.nodeName == "CAMERA" then s.node = cameraNode end
      if s.nodeName == "ENGINE" then s.node = M.engineNode end
      s.node = s.node or cameraNode -- fall back to camera node

      -- load the sound synchronously with the game engine
      s.clip = createSoundObj(s.filename, s.profile, s.sfxProfile, s.node)
      --log('D', 'sounds.update', 'createSFXSource('..s.sfxProfile..','..s.node..') = '..tostring(s.clip))
      if not s.clip then
        log('W', 'sounds.update', 'unable to create sound, removing it: '..s.sfxProfile)
        soundBank.sounds[skey] = nil
      end
    end

    for k1,snd in pairs(soundBank.sounds) do
      for k2,v2 in pairs(snd) do
        if v2 == "MAXRPM" then snd[k2] = maxrpm end
      end
    end

    --initialize groups
    local soundGroup = v.data.engine and v.data.engine.soundGroup
    for _,vl in pairs(soundBank.sounds) do
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
      for k,bm in pairs(v.data.beams) do
        if bm.soundFile ~= nil then
          local soundTable = {}

          --loop
          local soundProfileType = "AudioDefaultLoop3D"

          --setup our table
          local soundFile = checkLocalFile(v.vehicleDirectory,bm.soundFile)
          soundTable.soundType = bm.soundType
          soundTable.sfxProfile = getNextProfile()
          soundTable.clip = createSoundObj(soundFile, soundProfileType, soundTable.sfxProfile, bm.id1)
          if soundTable.clip then
            soundTable.volumeFactor = bm.volumeFactor or 1
            soundTable.pitchFactor = bm.pitchFactor or 0
            soundTable.decayFactor = bm.decayFactor or 1
            soundTable.decayMode = bm.decayMode or 0   --linear or exponential sound decay?
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
      log('E', 'sounds.init', 'unable to load any sound bank (*.sbeam), that is quite bad :/')
    end
  end

  -- TODO: Find a better place to emit wind sounds. Maybe at the windows?
  if windSound == nil then
    windSound = createSoundObj("event:>Wind", 'AudioDefaultLoop3D', "WindTestSound", M.engineNode)
  end

  if wheelsSounds == nil then
    local wheelSoundsNum = 0
    local soundName
    for wi,wd in pairs(wheels.wheels) do
      addWheelSound(wi, wd, "event:>Surfaces>Asphalt_Roll", "AudioDefaultLoop3D", "RollingTestSound")
      addWheelSound(wi, wd, "event:>Surfaces>Asphalt_Skid", "AudioDefaultLoop3D", "SkidTestSound")
--      addWheelSound(wi, wd, "art/sound/groundmodels/asphalt_roll.ogg", "AudioDefaultLoop3D", "RollingTestSound")
--      addWheelSound(wi, wd, "art/sound/groundmodels/asphalt_skid.ogg", "AudioDefaultLoop3D", "SkidTestSound")
      --addWheelSound(wi, wd, "event:>Surfaces>Gravel_Roll", "AudioDefaultLoop3D", "RollingTestSound")
      --addWheelSound(wi, wd, "event:>Surfaces>Gravel_Skid", "AudioDefaultLoop3D", "SkidTestSound")
    end
  end
end

local function destroy()
  obj:deleteSFXSources()

  soundBank = {}
  beamSounds = {}
  wheelsSounds = nil
  windSound = nil

  obj:queueGameEngineLua('core_sounds.delEngineSound('..obj:getID().. ')')
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

local fmodtable = { 20.0, 40.0, 80.0, 160.0, 330.0, 660.0, 1300.0, 2700.0, 5400.0, 11000.0, 22000.0 }
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
M.destroy = destroy
M.init = init
M.setUIDebug = setUIDebug
M.createSFXSource = createSFXSource
M.onDeserialized = onDeserialized --this enables serialization of all M. values for the module so they survive reloads
M.disableOldEngineSounds = disableOldEngineSounds
M.hzToFMODHz = hzToFMODHz

return M
