-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local push = function(self, data)
  table.insert(self.data, {payload = data, time = self.currentTime + self.delay})
  self.length = self.length + 1
end

local pop = function(self, dt)
  self.currentTime = self.currentTime + dt
  if self.length == 0 then return nil end

  local delayedData = {}
  local finishedKeysCount = 0
  for i = 1, self.length, 1 do
    if self.data[i].time <= self.currentTime then
      table.insert(delayedData, self.data[i].payload)
      finishedKeysCount = finishedKeysCount + 1
    end
  end

  for i = 1, finishedKeysCount, 1 do
    table.remove(self.data, 1)
    self.length = self.length - 1
  end

  return delayedData
end

local popSum = function(self, dt)
  self.currentTime = self.currentTime + dt
  if self.length == 0 then return 0 end

  local dataSum = 0
  local finishedKeysCount = 0
  for i = 1, self.length, 1 do
    if self.data[i].time <= self.currentTime then
      dataSum = dataSum + self.data[i].payload
      finishedKeysCount = finishedKeysCount + 1
    else
      break
    end
  end

  for i = 1, finishedKeysCount, 1 do
    table.remove(self.data, 1)
    self.length = self.length - 1
  end

  return dataSum
end

local peek = function(self, dt)
  if self.length == 0 then return nil end

  local delayedData = {}
  for i = 1, self.length, 1 do
    if self.data[i].time <= self.currentTime + dt then
      table.insert(delayedData, self.data[i].payload)
    end
  end

  return delayedData
end

local function reset(self)
  self.length = 0
  self.currentTime = 0
  self.data = {}
end

local methods = {
  push = push,
  peek = peek,
  pop = pop,
  popSum = popSum,
  reset = reset,
}

local new = function(delay)
  local r = {delay = delay, length = 0, currentTime = 0, data = {}}

  return setmetatable(r, {__index = methods})
end

return {
  new = new,
}