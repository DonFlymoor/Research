local mt = {}
mt.__index = mt

function mt:addEvent(time, fn)
    table.insert(self, {fn = fn, time = time})
end

function mt:clear()
    tableClear(self)
end

function mt:process(dt)
    local size = #self
    for i = size, 1, -1 do
    self[i].time = self[i].time - dt
    if self[i].time < 0 then
        self[i].fn()
        table.remove(self, i)
    end
    end
end

function createTimeEvents()
    local data = {}   
  
    setmetatable(data, mt)
    return data
end

local M = {}
M.create = createTimeEvents
return M
