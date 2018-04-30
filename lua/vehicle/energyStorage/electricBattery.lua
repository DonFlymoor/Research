-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min

local function updateGFX(storage, dt)
  storage.remainingVolume = storage.initialStoredEnergy > 0 and storage.storedEnergy / 3600000 or 0
  storage.remainingRatio = storage.initialStoredEnergy > 0 and storage.storedEnergy / storage.initialStoredEnergy or 0
end

local function registerDevice(storage, device)
  storage.assignedDevices[device.name] = device
end

local function setRemainingRatio(storage, ratio)
  storage.storedEnergy = storage.initialStoredEnergy * min(max(ratio, 0), 1)
end

local function new(jbeamData)
  local storage = {
    name = jbeamData.name,
    type = jbeamData.type,
    energyType = "electricEnergy",

    assignedDevices = {},
    remainingRatio = 1,

    updateGFX = updateGFX,
    registerDevice = registerDevice,
    setRemainingRatio = setRemainingRatio,
  }

  storage.capacity = jbeamData.batteryCapacity or 0 --kWh
  local startingCapacity = jbeamData.startingFuelCapacity or storage.capacity
  storage.storedEnergy = startingCapacity * 3600000 --kWh to J
  storage.remainingVolume = storage.capacity

  storage.initialStoredEnergy = storage.capacity * 3600000 --kWh to J
  storage.remainingRatio = storage.initialStoredEnergy > 0 and storage.storedEnergy / storage.initialStoredEnergy or 0

  storage.jbeamData = jbeamData

  return storage
end

M.new = new

return M
