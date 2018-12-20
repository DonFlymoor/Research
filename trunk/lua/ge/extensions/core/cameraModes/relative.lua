-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

local function rotateEuler(x, y, z, q)
  q = q or quat()
  q = quatFromEuler(0, z, 0) * q
  q = quatFromEuler(0, 0, x) * q
  q = quatFromEuler(y, 0, 0) * q
  return q
end

function C:init()
  self.disabledByDefault = true

  self.lightBrightness = 0 -- disable light by default
  self.nearclip = 0.01
  self.camMaxDist = math.huge

  self.slots = {} -- stored position/rotations
  self.slotNameIndexMap = {}

  self.cameraResetted = 2
  self:onVehicleCameraConfigChanged()
  self:reset()
end

function C:onVehicleCameraConfigChanged()
  if not self.refNodes or not self.refNodes.ref or not self.refNodes.left or not self.refNodes.back then
    log('D', 'core_camera.relative', 'No refNodes found, using default fallback')
    self.refNodes = { ref=0, left=1, back=2 }
  end

  -- how to init this
  if #self > 0 then
    for k, cr in ipairs(self) do
      if cr.name then
        table.insert(self.slots, cr)
        self.slotNameIndexMap[cr.name] = #self.slots
      else
        log('W','core_camera.config','node missing type: '..dumps(cr))
      end
    end
    -- start with driver
    if not self:reStoreSlot('driver', true) then
      -- otherwise with first camera
      self:reStoreSlot(1, true)
    end

    --print("imported SLOTS: ")
    --dump(self.slots)
  else
    self.pos = vec3(0,-3,2)
    self.rot = vec3(0,-120,0)
    self.fov = 70
  end

  self.resetPos = vec3(self.pos) -- copy
  self.resetRot = vec3(self.rot) -- copy
  self.resetFOV = self.fov

  -- if a reset countdown is NOT already happening
  if self.cameraResetted <= 0 then
    -- signal to reset that a reload has happened
    self.cameraResetted = -1
  end
end

--function C:__gc()
--  print("############################################GARBAGE COLLECTED")
--end

function C:_updateLight(brightness)
  if brightness ~= nil then
    self.lightBrightness = brightness
  end
  self.lightBrigtness = math.max(0, self.lightBrightness)
  if not scenetree.relativecameralight then
    local l = createObject('PointLight')
    l.canSave  = false
    l.radius = 20
    l:registerObject('relativecameralight')
  end
  scenetree.relativecameralight.isEnabled = self.lightBrightness > 0
  scenetree.relativecameralight.brightness = self.lightBrightness
  scenetree.relativecameralight:postApply()
end

function C:_updateNearClip()
  if scenetree.theLevelInfo then
    scenetree.theLevelInfo.nearClip = self.nearclip
    scenetree.theLevelInfo:postApply()
  end
end

local factorSmoother = newTemporalSmoothing(10,10)
local dxSmoother = newTemporalSmoothing(4,4)
local dySmoother = newTemporalSmoothing(4,4)
local dzSmoother = newTemporalSmoothing(4,4)

function C:sendMenus()
  -- add menus?
  core_quickAccess.addEntry({ level = '/', uniqueID = 'relativeCameraMenu', generator = function(entries)
    if not self.focused then return {} end
    table.insert(entries, { title = 'RelCam', icon = 'radial_relative_camera', priority = 10, goto = '/camera_relative_mode/'})
  end})

  core_quickAccess.addEntry({ level = '/camera_relative_mode/', uniqueID = 'index', generator = function(entries)
    if not self.focused then return {} end
    local tmp = { title = 'Light', icon = 'radial_electrics', priority = 10, onSelect = function()
      if self.lightBrightness >= 0 and  self.lightBrightness < 0.1 then
        self.lightBrightness = 0.1
      elseif self.lightBrightness >= 0.1 and self.lightBrightness < 0.5 then
        self.lightBrightness = 0.5
      elseif self.lightBrightness >= 0.5 and self.lightBrightness < 1 then
        self.lightBrightness = 1
      elseif self.lightBrightness >= 1 then
        self.lightBrightness = 0
      end
      --print("new light brightness mode: " .. tostring(self.lightBrightness))
      self:_updateLight()
      ui_message('Light intensity: ' .. math.ceil(self.lightBrightness * 100) .. ' %' , 10, 'cameramode')
      return {'reload'}
    end}
    if self.lightBrightness > 0 then tmp.color = '#ff6600' end
    table.insert(entries, tmp)
    table.insert(entries, { title = 'Near Clip: ' .. self.nearclip, icon = 'radial_near_clip_value', priority = 10, onSelect = function()
      if self.nearclip >= 0 and self.nearclip < 0.01 then
        self.nearclip = 0.01
      elseif self.nearclip >= 0.01 and self.nearclip < 0.1 then
        self.nearclip = 0.1
      elseif self.nearclip >= 0.1 then
        self.nearclip = 0.0005
      end
      self:_updateNearClip()
      ui_message('Near clip: ' .. self.nearclip .. ' m' , 10, 'cameramode')
      return {'reload'}
    end})
    tmp = { title = 'Slots', icon = 'radial_slots', priority = 50, goto = '/camera_relative_mode/slots/' }
    if self.slots[1] then
      tmp.color = '#ff6600'
    end
    table.insert(entries, tmp)
  end})

  core_quickAccess.addEntry({ level = '/camera_relative_mode/slots/', uniqueID = 'slots', generator = function(entries)
    if not self.focused then return {} end

    for i = 1, 10 do
      local tmp = { title = tostring(i), icon = 'radial_relative_camera', priority = i, onSelect = function()
        if self.slots[i] == nil then
          self:storeSlot(i)
        else
          self:reStoreSlot(i)
        end
        return {'reload'}
      end}
      if self.slots[i] then
        -- existing?
        tmp.color = '#ff6600'
        -- use name if existing :)
        if self.slots[i].name then
          tmp.title = self.slots[i].name
        end
      end
      table.insert(entries, tmp)
    end
  end})
end

function C:restoreLightInfo()
  -- restore light brightness info
  if self.storedLightBrightness ~= nil then
    self:_updateLight(self.storedLightBrightness)
    self.storedLightBrightness = nil
  end
end


function C:restoreNearClipping()
  -- fix near clipping
  if scenetree.theLevelInfo then
    self.savedNearClip = scenetree.theLevelInfo.nearClip
    scenetree.theLevelInfo.nearClip = self.nearclip
    scenetree.theLevelInfo:postApply()
  end
end

function C:storeSlot(slot)
  self.slots[slot] = {
    pos = vec3(self.pos),
    rot = vec3(self.rot),
    fov = self.fov
  }
  ui_message('Camera position stored in slot ' .. tostring(slot), 10, 'cameramode')
end

function C:reStoreSlot(slot, skipTransition)
  if type(slot) == 'string' then
    --print(">> slot " .. tostring(slot) .. " is ID " .. tostring(self.slotNameIndexMap[slot]))
    slot = self.slotNameIndexMap[slot] -- convert name to ID
    if not slot then return false end
  end
  if not self.slots[slot] then
    ui_message('Slot ' .. tostring(slot) .. ' empty'  , 10, 'cameramode')
    return false
  end

  -- restore
  local slot = self.slots[slot]
  self.pos = slot.pos
  self.rot = slot.rot
  self.fov = slot.fov
  self.fov = math.min(120, math.max(1, self.fov))

  if not skipTransition then
    core_camera.startTransition()
  end
  --ui_message('Camera position restored from slot ' .. tostring(slot)  , 10, 'cameramode')

  return true
end

function C:setupRelative(pos, rot, fov)
  self.pos = pos
  self.rot = rot
  self.fov = fov
end

function C:hotkey(hotkey, modifier)
  if not self.focused then return end
  if modifier == 0 then
    self:reStoreSlot(hotkey)
  elseif modifier == 1 then
    self:storeSlot(hotkey)
  end
end

function C:storeLightInfo()
  -- store light brightness info
  self.storedLightBrightness = self.lightBrightness
  self:_updateLight(0)
end

function C:setNearClipping()
  -- set near clipping back to old value
  if scenetree.theLevelInfo and self.savedNearClip then
    scenetree.theLevelInfo.nearClip = self.savedNearClip
    scenetree.theLevelInfo:postApply()
  end
end

function C:onCameraChanged(focused)
  if focused then
    self:sendMenus()
    self:restoreNearClipping()
    self:restoreLightInfo()
  else
    self:storeLightInfo()
    self:setNearClipping()
  end
end

function C:reset()
  if self.cameraResetted ~= -1 then
    self.pos = self.resetPos
    self.rot = self.resetRot
    self.fov = self.resetFOV
    factorSmoother = newTemporalSmoothing(2.5,2.5)
    dxSmoother = newTemporalSmoothing(2,2)
    dySmoother = newTemporalSmoothing(2,2)
    dzSmoother = newTemporalSmoothing(2,2)
  else
    self.cameraResetted = 0
  end
end

function C:setMaxDistance(d)
  self.camMaxDist = d
end

function C:update(data)
  -- update input
  local dx = dxSmoother:get(MoveManager.right   - MoveManager.left,     data.dt)
  local dy = dySmoother:get(MoveManager.forward - MoveManager.backward, data.dt)
  local dz = dzSmoother:get(MoveManager.up      - MoveManager.down,     data.dt)
  local dtPosFactor = factorSmoother:get(data.speed / 50, data.dt)
  local pd = dtPosFactor * data.dt * vec3(dx, dy, dz)

  local rdx = 10*MoveManager.yawRelative   + 100*data.dt*(MoveManager.yawRight - MoveManager.yawLeft  )
  local rdy = 10*MoveManager.pitchRelative + 100*data.dt*(MoveManager.pitchUp  - MoveManager.pitchDown)
  local rdz = 4.5*data.dt*(MoveManager.zoomIn - MoveManager.zoomOut) * self.fov
  self.rot = self.rot + vec3(rdx, rdy, 0)

  self.fov = math.max(self.fov + rdz, 10)
  self.fov = math.min(self.fov, 120)
  --
  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))

  local dir = (ref - back):normalized()

  local up = dir:cross(left):normalized()

  if dir:squaredLength() == 0 or up:squaredLength() == 0 then
    data.res.pos = data.pos
    data.res.rot = quatFromDir(vec3(0,1,0), vec3(0, 0, 1))
    return false
  end

  local qdir = quatFromDir(dir, up)

  local camOffset = qdir * self.pos

  local qdirLook = rotateEuler(-math.rad(self.rot.x), -math.rad(self.rot.y), 0) --math.rad(self.rot.z))
  local qdirLook2 = rotateEuler(0, 0, math.rad(self.rot.z), qdirLook)
  qdir = qdirLook2 * qdir

  local newPos = self.pos + qdirLook * pd
  local deltaPos = newPos - ref
  if self.camMaxDist and deltaPos:length() < self.camMaxDist then
    self.pos = self.pos + qdirLook * pd
  end

  local pos = data.pos + camOffset

  -- application
  data.res.pos = pos
  data.res.rot = qdir
  data.res.fov = self.fov

  if self.lightBrightness > 0 then
    local lightPos = pos -- + qdirLook * vec3(0.01, 0.01, -0.02)
    scenetree.relativecameralight:setPosRot(lightPos.x, lightPos.y, lightPos.z, data.res.rot.x, data.res.rot.y, data.res.rot.z, data.res.rot.w)
  end

  self.cameraResetted = math.max(self.cameraResetted - 1, 0)
  return true
end

-- dont reset camera with vehicle reset
function C:onVehicleResetted()
  return true
end

function C:setRefNodes(centerNodeID, leftNodeID, backNodeID)
  self.refNodes.ref = centerNodeID
  self.refNodes.left = leftNodeID
  self.refNodes.back = backNodeID
end

function C:onSerialize()
  local data = {}
  for k,v in pairs(self) do
    if type(v) ~= 'function' then
      data[k] = v
    end
  end
  -- log('I', 'relative', 'onSerialize called...')
  -- dump(self)
  return data
end

function C:onDeserialized(data)
 if not data then return end
 for k,v in pairs(data) do
    self[k] = v
  end
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
