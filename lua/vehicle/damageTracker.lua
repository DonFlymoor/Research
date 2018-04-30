-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local damageData = {}
local damageTrackerDirtyTimer = 0
local damageTrackerDirtyTime = 1/3

local function updateGFXDirty(dt)
  damageTrackerDirtyTimer = damageTrackerDirtyTimer - dt
  if damageTrackerDirtyTimer <= 0 then
    damageTrackerDirtyTimer = damageTrackerDirtyTime
    M.updateGFX = nop
    guihooks.trigger('DamageData', damageData)
  end
end

local function setDamage(group, name, value)
  if damageData[group] == nil then
    damageData[group] = {}
  end
  if damageData[group][name] == value then return end
  damageData[group][name] = value
  M.updateGFX = updateGFXDirty
end

local function getDamage(group, name)
  return damageData[group] and (damageData[group][name] or false) or false
end

local function setDirty(isDirty)
  if isDirty then
    M.updateGFX = updateGFXDirty
    damageTrackerDirtyTimer = 0
  else
    M.updateGFX = nop
  end
end

local function willSend()
  return damageTrackerDirtyTimer == damageTrackerDirtyTime and playerInfo.firstPlayerSeated
end

local function init()
  damageData = {}
  damageTrackerDirtyTimer = damageTrackerDirtyTime
  setDirty(false)
end

M.init = init
M.reset = init
M.updateGFX = nop
M.setDamage = setDamage
M.getDamage = getDamage
M.setDirty = setDirty
M.willSend = willSend

return M