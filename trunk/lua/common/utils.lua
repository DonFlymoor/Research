-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- utility things, big chaos

local inspect = require("inspect")

-- this function can load an optional module
function require_optional(module)
  local ok, m = pcall(require, module)
  if ok then return m end
  return nil
end

local ffi = require_optional('ffi')

local __typePoint3F  = (Point3F  ~= nil) and     Point3F(0,0,0).___type or nil
local __typeFloat3   = (float3   ~= nil) and     float3(0,0,0).___type or nil
local __typeQuaternion = (Quaternion ~= nil) and Quaternion().___type or nil
local __typeQuatF = (QuatF ~= nil) and QuatF(0,0,0,1).___type or nil
local __typeColor = (color ~= nil) and color(0,0,0,0).___type or nil
local abs, floor, min, max, stringformat, tableconcat = math.abs, math.floor, math.min, math.max, string.format, table.concat

function dumps(...)
  if #{...} > 1 then
    local res = {}
    for k,v in pairs({...}) do
      table.insert(res, inspect(v))
    end
    return table.concat(res, ', ')
  else
    return inspect(...)
  end
  return 'nil'
end

function dump(...)
  -- to find out who is calling this, you can use this snippet:
  --log('A', "lua.utils.dump-calledby", debug.traceback())

  log('A', "lua.utils", dumps(...))
end

if ffi then
  const = function (table)
    local new = {}
    for k, v in pairs(table) do
        new[k] = v
    end
    local t = ffi.typeof("struct {}")
    ffi.metatype(t, {__index = new})
    return ffi.new(t)
  end
else
  const = function (table) return table end
end

-- use luajit extension table.clear and new if they exist, otherwise fallback to lua implementations
local ok, _ = pcall(require, "table.clear")
if not ok then
  table.clear = function(tab)
                  for k, _ in pairs(tab) do
                      tab[k] = nil
                  end
                end
end

local ok, _ = pcall(require, "table.new")
if not ok then
  table.new = function() return {} end
end

-- ASCII graph
function graphs(v, len)
  local char = v>0 and "+" or "-"
  local result = char
  for i=1, abs(math.min(len,v)) do result = result..char end
  if len then while string.len(result) < len do result = result.." " end end
  if string.len(result) > len then result = string.sub(result, 1, len) end
  return "["..result.."]"
end

function dumpToFile(filename, ...)
  local f = io.open(filename, "w")
  if f then
    f:write(inspect(...))
    f:close()
    return true
  end
  return false
end

function serializeJsonToFile(filename, obj, pretty)
  local f = io.open(filename, "w")
  if f then
    local content
    if pretty then
      content = encodeJsonPretty(obj)
    else
      content = encodeJson(obj)
    end
    f:write(content)
    f:close()
    return true
  end
  return false
end

function lpad(s, l, c)
  s = tostring(s)
  return string.rep(c, l - #s)..s
end

function rpad(s, l, c)
  s = tostring(s)
  return s .. string.rep(c, l - #s)
end

function saveG()
  dumpToFile("global_state.lua", _G)
end

function nop()
end

function sign(n)
  if n > 0 then return 1 end
  if n < 0 then return -1 end
  return 0
end

function fsign(x) --branchless
  return x / (abs(x) + 1e-307)
end

function guardZero(x) --branchless
  return 1 / max(min(1/x, 1e300), -1e300)
end

function msgs(txt, t, name)
  t = t or 5
  if name == nil then
    BeamEngine:queueLuaCommand("msg('"..txt.."',"..t..")")
  else
    BeamEngine:queueLuaCommand("msg('"..txt.."',"..t..",'"..name.."')")
  end
end

local singleEventTimer = {}
singleEventTimer.__index = singleEventTimer

function newSingleEventTimer()
  local data = {waitDt = -1, update = nop, eventFun = nop}
  setmetatable(data, singleEventTimer)
  return data
end

function singleEventTimer:update(dt)
  local waitDt = max(0, self.waitDt - dt)
  self.waitDt = waitDt
  if waitDt == 0 then
    self.update = nop
    self.eventFun(unpack(self.params))
  end
end

function singleEventTimer:callAfter(dt, eventFun, ...)
  self.waitDt = dt
  self.eventFun = eventFun
  self.params = {...}
  self.update = singleEventTimer.update
end

local temporalSpring = {}
temporalSpring.__index = temporalSpring

function newTemporalSpring(spring, damp, startingValue)
  local data = {spring = spring or 10, damp = damp or 2, state = startingValue or 0, vel = 0}
  setmetatable(data, temporalSpring)
  return data
end

function temporalSpring:get(sample, dt)
  self.vel = self.vel * max(1 - self.damp * dt, 0) + (sample - self.state) * min(self.spring * dt, 1/dt)
  self.state = self.state + self.vel * dt
  return self.state
end

function temporalSpring:set(sample)
  self.state = sample
  self.vel = 0
end

function temporalSpring:value()
  return self.state
end

local temporalSigmoidSmoothing = {}
temporalSigmoidSmoothing.__index = temporalSigmoidSmoothing

function newTemporalSigmoidSmoothing(inRate, startAccel, stopAccel, outRate, startingValue)
  local rate = inRate or 1
  local startaccel = startAccel or math.huge
  local data = {[false] = rate, [true] = outRate or rate, startAccel = startaccel, stopAccel = stopAccel or startaccel, state = startingValue or 0, prevvel = 0}
  setmetatable(data, temporalSigmoidSmoothing)
  return data
end

function temporalSigmoidSmoothing:get(sample, dt)
  local dif = sample - self.state

  local prevvel = self.prevvel * max(fsign(self.prevvel * dif), 0)
  local vsq = prevvel * prevvel
  local absdif = abs(dif)
  local difsign = dif / (absdif + 1e-307)
  local acceldt

  local absdif2 = absdif * 2
  if vsq > absdif2 * self.stopAccel then
    acceldt = -difsign * min((vsq / absdif2) * dt, abs(prevvel))
  else
    acceldt = difsign * self.startAccel * dt
  end

  local ratelimit = self[dif * self.state >= 0]
  self.state = self.state + difsign * min(min(abs(prevvel + 0.5 * acceldt), ratelimit) * dt, absdif)
  self.prevvel = difsign * min(abs(prevvel + acceldt), ratelimit)
  return self.state
end

function temporalSigmoidSmoothing:getWithRateAccel(sample, dt, ratelimit, startAccel, stopAccel)
  local dif = sample - self.state
  local prevvel = self.prevvel * max(fsign(self.prevvel * dif), 0)
  local vsq = prevvel * prevvel
  local absdif = abs(dif)
  local difsign = dif / (absdif + 1e-307)
  local acceldt

  local absdif2 = absdif * 2
  if vsq > absdif2 * (stopAccel or startAccel) then
    acceldt = -difsign * min((vsq / absdif2) * dt, abs(prevvel))
  else
    acceldt = difsign * startAccel * dt
  end

  self.state = self.state + difsign * min(min(abs(prevvel + 0.5 * acceldt), ratelimit) * dt, absdif)
  self.prevvel = difsign * min(abs(prevvel + acceldt), ratelimit)
  return self.state
end

function temporalSigmoidSmoothing:set(sample)
  self.state = sample
  self.prevvel = 0
end

function temporalSigmoidSmoothing:value()
  return self.state
end

local temporalSmoothingNonLinear = {}
temporalSmoothingNonLinear.__index = temporalSmoothingNonLinear

function newTemporalSmoothingNonLinear(inRate, outRate, startingValue)
  local rate = inRate or 1
  local data = {[false] = rate, [true] = outRate or rate, state = startingValue or 0}
  setmetatable(data, temporalSmoothingNonLinear)
  return data
end

function temporalSmoothingNonLinear:get(sample, dt)
  local dif = sample - self.state
  self.state = self.state + dif * min(self[dif * self.state >= 0] * dt, 1)
  return self.state
end

function temporalSmoothingNonLinear:getWithRate(sample, dt, rate)
  self.state = self.state + (sample - self.state) * min(rate * dt, 1)
  return self.state
end

function temporalSmoothingNonLinear:set(sample)
  self.state = sample
end

function temporalSmoothingNonLinear:value()
  return self.state
end

function temporalSmoothingNonLinear:reset()
  self.state = 0
end

local temporalSmoothing = {}
temporalSmoothing.__index = temporalSmoothing

function newTemporalSmoothing(inRate, outRate, autoCenterRate, startingValue)
  inRate = max(inRate or 1, 1e-307)
  startingValue = startingValue or 0

  local data = {[false] = inRate, [true] = max(outRate or inRate, 1e-307),
                autoCenterRate = max(autoCenterRate or inRate, 1e-307),
                _startingValue = startingValue,
                state = startingValue}

  setmetatable(data, temporalSmoothing)

  if data.autoCenterRate ~= inRate then
    data.getUncapped = data.getUncappedAutoCenter
  end
  return data
end

function temporalSmoothing:getUncappedAutoCenter(sample, dt)
  local st = self.state
  local dif = (sample - st)
  local rate

  if sample == 0 then
    rate = self.autoCenterRate  -- autocentering
  else
    rate = self[dif * st >= 0]
  end
  st = st + dif * min(rate * dt / abs(dif), 1)
  self.state = st
  return st
end

function temporalSmoothing:getUncapped(sample, dt) -- no autocenter
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(self[dif * st >= 0] * dt / abs(dif), 1)
  self.state = st
  return st
end

function temporalSmoothing:get(sample, dt)
  return max(min(self:getUncapped(sample, dt), 1), -1)
end

function temporalSmoothing:getWithRateUncapped(sample, dt, rate)
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(rate * dt / (abs(dif) + 1e-307), 1)
  self.state = st
  return st
end

function temporalSmoothing:getWithRate(sample, dt, rate)
  return max(min(self:getWithRateUncapped(sample, dt, rate), 1), -1)
end

function temporalSmoothing:reset()
  self.state = self._startingValue
end

function temporalSmoothing:value()
  return self.state
end

function temporalSmoothing:set(v)
  self.state = v
end

local linearSmoothing = {}
linearSmoothing.__index = linearSmoothing

function newLinearSmoothing(dt, inRate, outRate)
  inRate = max(inRate or 1, 1e-307)
  local data = {[false] = inRate * dt, [true] = max(outRate or inRate, 1e-307) * dt, state = 0}
  setmetatable(data, linearSmoothing)
  return data
end

function linearSmoothing:get(sample) -- no autocenter
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(self[dif * st >= 0] / abs(dif), 1)
  self.state = st
  return st
end

function linearSmoothing:set(v)
  self.state = v
end

function linearSmoothing:reset()
  self.state = 0
end

local ExponentialSmoothing = {}
ExponentialSmoothing.__index = ExponentialSmoothing

-- creation method of the object, inits the member variables
function newExponentialSmoothing(window, startingValue)
  local data = {a = 2 / window, _startingValue = startingValue or 0, st = startingValue or 0}
  setmetatable(data, ExponentialSmoothing)
  return data
end

function ExponentialSmoothing:get(sample)
  local st = self.st
  st = st + self.a * (sample - st)
  self.st = st
  return st
end

function ExponentialSmoothing:getWindow(sample, window)
  local st = self.st
  st = st + 2 * (sample - st) / max(window, 2)
  self.st = st
  return st
end

function ExponentialSmoothing:value()
  return self.st
end

function ExponentialSmoothing:set(value)
  self.st = value
end

function ExponentialSmoothing:reset(value)
  self.st = self._startingValue
end

-- little snippet that enforces reloading of files
function rerequire(module)
  package.loaded[module] = nil
  m = require(module)
  if not m then
    log('W', "rerequire", ">>> Module failed to load: " .. tostring(module).." <<<")
  end
  return m
end

function readJsonData(content, context)
  if not json then json = require("json") end
  local state, data = xpcall(function() return json.decode(content) end, debug.traceback)
  if state == false then
    log('E', "readJsonData", "unable to decode JSON: "..tostring(context))
    log('E', "readJsonData", "JSON decoding error: "..tostring(data))
    return nil
  end
  return data
end

-- alias
writeJsonFile = serializeJsonToFile

function readJsonFile(filename)
  local content = readFile(filename)
  if content == nil then
    -- parent needs to deal with error reporting
    --log('D', "readJsonFile","unable to open JSON file: "..tostring(filename))
    return nil
  end
  return readJsonData(content, filename)
end

function readDictJSONTable(filename)
  local data = readJsonFile(filename)
  if not data then return nil end
  for k,v in pairs(data) do
    for k2,v2 in pairs(v) do
      if k2 > 1 then
        -- re-add headers
        for i=1,#v[1],1 do

          v[k2][v[1][i]] = v[k2][i]
          v[k2][i] = nil
        end
      end
    end
    v[1] = nil
  end
  --dump(data)
  return data
end

function toJSONString(d)
  if type(d) == "string" then
    return "\""..d.."\""
  elseif type(d) == "number" then
    return string.format('%g', d)
  else
    return tostring(d)
  end
end

function saveCompiledJBeamRecursive(f, data, level)
  local indent = string.rep(" ", level*2)
  local nl = true
  if level > 2 then nl = false end
  if level > 3 then indent = "" end
  --f:write(level..indent
  f:write(indent)

  if type(data) == "table" and type(data["partOrigin"]) == 'string' and data["partOrigin"] ~= ""  then
    f:write("\n"..indent.."/*"..string.rep("*", 50).."\n")
    f:write(indent .. " * part " .. tostring(data["partOrigin"]).."\n")
    f:write(indent .. " *"..string.rep("*", 49) .. "*/\n")
    f:write("\n"..indent)
  end

  if level > 2 then indent = "" end
  if type(data) == "table" then
    if tableIsDict(data) then
      f:write("{")
      if nl then f:write("\n") end
      local localColumnCount = 0
      for _,_ in pairs(data) do
        localColumnCount = localColumnCount + 1
      end
      local i = 1
      for k,v in pairs(data) do
        if type(v) == "table" then
          f:write(toJSONString(k).." : ")
          --if nl then f:write("\n" end
          saveCompiledJBeamRecursive(f, v, level + 1)
          --if nl then f:write("\n" end
        else
          --local txt = tostring(joinKVES(columnSize,toJSONString(k), toJSONString(v)))
          local txt = toJSONString(k) .. ' : ' .. toJSONString(v)
          f:write(txt)
        end
        if i < localColumnCount then
          f:write(", ")
        elseif i == localColumnCount then
          if nl then f:write("\n") end
        end
        i = i + 1
      end
      if nl then f:write("\n") end
      f:write("}")
      if level < 2 then f:write("\n") end
    else
      local nl = true
      if level > 2 then nl = false end
      f:write("[")
      if nl then f:write("\n") end
      for i=1,#data,1 do
        --k,v in pairs(data) do
        local v = data[i]
        if type(v) == "table" then
          saveCompiledJBeamRecursive(f, v, level + 1)
        else
          local txt = toJSONString(v)
          f:write(txt)
        end
        if i < #data then
          f:write(", ")
          if level == 2 then f:write("\n") end
        end
      end
      f:write("]")
      if level < 2 then f:write("\n") end
    end
  end
end

function saveCompiledJBeam(data, filename, lvl)
  local f = io.open(filename, "w")
  if f == nil then
    log('W', "saveCompiledJBeam", "unable to open file "..filename.." for writing")
    return false
  end
  saveCompiledJBeamRecursive(f, data, lvl or 0)
  f:close()
  return true
end

function readFile(filename)
  local f = io.open(filename, "r")
  if f == nil then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

function writeFile(filename, data)
  local file, err = io.open(filename,"w")
  if file == nil then
    log('W', "writeFile", "Error opening file for writing: "..filename..": "..err)
    return nil
  end
  local content = file:write(data)
  file:close()
  return true
end

function isOfficialContent(path)
  return string.startswith(path, FS:getGamePath())
end

function fileExistsOrNil(path)
  if type(path) == 'string' and FS:fileExists(path) then
    return path
  end
  return nil
end

function imageExistsDefault(path, fallbackPath)
  if path ~= nil and FS:fileExists(path) then
    return path
  else
    return fallbackPath or '/ui/images/appDefault.png'
  end
end

function dirContent(path)
  return FS:findFilesByPattern(path, '*', -1, true, false)
end

function getDirs(path, recursiveLevels)
  local files = FS:findFilesByPattern(path, '*', recursiveLevels, false, true)
  local res = {}
  local residx = 1
  for _, value in pairs(files) do
    if not tableContains(res, value) then
      res[residx] = value
      residx = residx + 1
    end
  end

  return res
end

function getFileSize(filename)
  local res = -1
  local f = io.open(filename, "r")
  if f == nil then
    return res
  end
  res = f:seek("end")
  f:close()
  return res
end

function pairs_tail(t, last) return next, t, last end

function tableContainsCaseInsensitive(table, element)
  element = string.lower(element)
  for _, value in pairs(table) do
    if string.lower(value) == element then
      return true
    end
  end
  return false
end

function tableContains(t, element)
  for _, v in pairs(t) do
    if v == element then
      return true
    end
  end
  return false
end

function locals()
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getlocal(2, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end

function tableIsDict(tbl)
  if type(tbl) ~= "table" then
    return false
  end
  return next(tbl) ~= 1
end

function tableIsEmpty(tbl)
  return type(tbl) ~= 'table' or next(tbl) == nil
end

function tableKeys(tbl)
  local keys = table.new(#tbl, 0)
  local keysidx = 1
  for k, _ in pairs(tbl) do
    keys[keysidx] = k
    keysidx = keysidx + 1
  end
  return keys
end

function arrayConcat(dst, src)
  local dstidx = #dst
  for i, v in pairs(src) do
    dstidx = dstidx + 1
    dst[dstidx] = v
  end
  return dst
end

function tableMerge(dst, src)
  for i,v in pairs(src) do
    if (type(v) ~= "function") then
      dst[i] = v;
    end
  end
  return dst
end

-- http://stackoverflow.com/questions/1283388/lua-merge-tables
function tableMergeRecursive(t1, t2)
  for k,v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k]) == "table" then
        tableMergeRecursive(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

function tableFromHeaderTable(entry)
  --local function processTableWithSchema(vehicle, keyEntry, entry, newList)
  -- its a list, so a table for us. Verify that the first row is the header
  local header = entry[1]

  if type(header) ~= "table" then
    log('W', "tableFromHeaderTable", "*** Invalid table header: "..dumps(header))
    return false
  end

  local headerSize = #header
  local newListSize = 0
  local localOptions = {}
  local output = {}
  local outputidx = 1

  -- walk the list entries
  for i = 2, #entry do
    local rowValue = entry[i]

    if type(rowValue) ~= "table" then
      log('W', "tableFromHeaderTable", "*** Invalid table row: "..dumps(rowValue))
      return false
    end
    if tableIsDict(rowValue) then
      -- case where options is a dict on its own, filling a whole line
      localOptions = tableMerge( localOptions, deepcopy(rowValue) )
    else
      -- allow last type to be the options always
      if #rowValue > headerSize + 1 then -- and type(rowValue[#rowValue]) ~= "table" then
        log('W', "tableFromHeaderTable", "*** Invalid table header, must be as long as all table cells (plus one additional options column):")
        log('W', "tableFromHeaderTable", "*** Table header: "..dumps(header))
        log('W', "tableFromHeaderTable", "*** Mismatched row: "..dumps(rowValue))
        return false
      end

      local newRow
      if next(localOptions) == nil then
        newRow = {}
      else
        newRow = deepcopy(localOptions)
      end

      local rvcc = 0
      for rk,rv in pairs(rowValue) do
        --log('D', "jbeam.processTableWithSchema", "### "..header[rk].."//"..tostring(newRow[header[rk]]))
        if header[rk] ~= nil then
          newRow[header[rk]] = rv
        end
        -- check if inline options are provided, merge them then
        if rvcc >= headerSize and type(rv) == 'table' and tableIsDict(rv) and #rowValue > headerSize then
          tableMerge(newRow, rv)
          break
        end
        rvcc = rvcc  + 1
      end

      if newRow.id ~= nil then
        newRow.name = newRow.id -- this keeps the name for debugging or alike
        newRow.id = nil
      end

      output[outputidx] = newRow
      outputidx = outputidx + 1
    end
  end
  return output
end

-- Return the string 'str', with all magic (pattern) characters escaped.
function escape_magic(str)
  assert(type(str) == "string", "utils.escape: Argument 'str' is not a string.")
  local escaped = str:gsub('[%-%.%+%[%]%(%)%^%%%?%*%^%$]','%%%1')
  return escaped
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function trimr(str, chrs)
  return str:match("(.-)["..chrs.."]*$")
end

-- Compatibility: Lua-5.0
function split(str, delim, maxNb)
  -- delim = delim or " "
  -- if delim == " " then
  --   str = trim(str)
  -- end
  -- Eliminate bad cases...
  if string.find(str, delim) == nil then
    return { str }
  end
  if maxNb == nil or maxNb < 1 then
    maxNb = 0  -- No limit
  end
  local result = {}
  local pat = "(.-)" .. delim .. "()"
  local nb = 0
  local lastPos
  for part, pos in string.gmatch(str, pat) do
    nb = nb + 1
    result[nb] = part
    lastPos = pos
    if nb == maxNb then break end
  end
  -- Handle the last field
  if nb ~= maxNb or lastPos < string.len(str) then
    result[nb + 1] = string.sub(str, lastPos)
  end
  --print('split str: "'.. str .. '", delim: "'..delim..'", nb: '..nb .. ', lastPos: '..lastPos.. ', strlen: ' .. string.len(str) .. ', maxNb: ' .. maxNb .. ', result: ' .. dumps(result))
  return result
end

function splitAsKeys(str, delim, maxNb, value)
  local res = {}
  local items = split(str, delim, maxNb)
  for _, i in ipairs(items) do
    res[i] = value or 1
  end
  return res
end


function joinKVES(space, k, v)
  local diff = space - string.len(k)
  local str = (k) .. string.rep(" ", diff)
  str = str .. ": "
  local diff2 = space - string.len(v)
  if diff < 0 then diff2 = diff2 + diff end
  str = str .. v .. string.rep(" ", diff2)
  return str
end

-- join equally spaced
function joinES(space, list, delimiter)
  local diff = space - string.len(list[1])
  local str = list[1] .. string.rep(" ", diff)
  for i = 2, #list do
    diff = space - string.len(list[i])
    str = str .. delimiter .. list[i] .. string.rep(" ", diff)
  end
  return str
end

function join(list, delimiter)
  return table.concat(list, delimiter)
end

function joinKeys(list, delimiter)
  return table.concat(tableKeys(list), delimiter)
end

function tableFirstKey(tbl)
  if type(tbl) ~= "table" then
    return ""
  end
  for k, v in pairs (tbl) do
    --log('I', "tableFirstKey", "*** "..tostring(k).." = "..tostring(v).." ["..type(v).."]")
    return k
  end
end

function tableSize(tbl)
  if type(tbl) ~= "table" then
    return 0
  end
  local count = 0
  for _ in pairs (tbl) do
    count=count+1
  end
  return count
end

function tableFindKey(t, element)
  for k, v in pairs(t) do
    if v == element then
      return k
    end
  end
  return nil
end

local __randomWasSeeded = false
function tableChooseRandomKey(t)
  if t == nil then return nil end
  if not __randomWasSeeded then
    math.randomseed(os.time())
    __randomWasSeeded = true
  end
  local randval = math.random(1, tableSize(t))
  local n = 0
  for k, v in pairs(t) do
    n = n + 1
    if n == randval then
      return k
    end
  end
  return nil
end

function randomASCIIString(len)
  if not __randomWasSeeded then
    math.randomseed(os.time())
    __randomWasSeeded = true
  end
  local res = ''
  local ascii = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local sl = string.len(ascii)
  for i = 1, len do
    local k = math.random(1, sl)
    res = res .. string.sub(ascii, k, k + 1)
  end
  return res
end

function tableClear(tbl)
  local count = #tbl
  for i = 1, count do
    tbl[i] = nil
  end
end

function _tableDepth(tbl, depth)
  if type(tbl) ~= "table" then
    return 0
  end
  for k, v in pairs (tbl) do
    if type(v) == "table" then
      return _tableDepth(v, depth + 1)
    end
  end
  return depth
end

function tableDepth(tbl)
  return _tableDepth(tbl, 0)
end

function shallowcopy(orig)
  local copy
  if type(orig) == 'table' then
    copy = table.new(#orig, 0)
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function deepcopy(object)
  local lookup_table = {}
  local function _copy(object)
    if lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = table.new(#object, 0)
    lookup_table[object] = new_table
    for index, value in pairs(object) do
      if type(index) == 'table' then index = _copy(index) end
      if type(value) == 'table' then value = _copy(value) end
      new_table[index] = value
    end
    return setmetatable(new_table, getmetatable(object))
  end
  if type(object) == 'table' then
    return _copy(object)
  else
    return object
  end
end

-- float3 conversion helpers
function tableToFloat3(v)
  if v == nil then
    return float3(0,0,0)
  end
  return float3(v.x, v.y, v.z)
end

-- converts string str separated with separator sep to table
function stringToTable(str, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  local i = 1
  for s in string.gmatch(str, "([^"..sep.."]+)") do
    t[i] = s
    i = i + 1
  end
  return t
end

-- color conversion helpers
function tableToColor(v)
  if v == nil then
    return color(0,0,0,0)
  end
  return color(v.r, v.g, v.b, v.a)
end

function parseColor(v)
  if v == nil then
    return color(0,0,0,0)
  end
  if type(v) == 'table' then
    return color(v.r, v.g, v.b, v.a)
  elseif type(v) == 'string' and string.len(v) > 7 and v:sub(1,1) == '#' then
    v = v:gsub("#","")
    return color(tonumber("0x"..v:sub(1,2)), tonumber("0x"..v:sub(3,4)), tonumber("0x"..v:sub(5,6)), tonumber("0x"..v:sub(7,8)))
  end
end

-- safe table iteration functions: it will iterate the tables via a copy: "adding" to the tables will not change the iteration
function ipairs_safe(t)
  local tcount = #t
  local new_table = table.new(tcount, 0)
  for i = 1, tcount do
    new_table[i] = t[i]
  end
  local function ipairs_safe_it(t, i)
    i = i + 1
    local v = t[i]
    if v ~= nil then
      return i,v
    else
      return nil
    end
  end
  return ipairs_safe_it, new_table, 0
end

function pairs_safe(t)
  local new_table = {}
  for index, value in pairs(t) do
    new_table[index] = value
  end
  local function pairs_safe_it(t, i)
    local k, v = next(t, i)
    if k ~= nil then
      return k,v
    else
      return nil
    end
  end
  return pairs_safe_it, new_table, nil
end

function CatMullRomSpline(points, returnArray)
  if #points < 3 then return nil end

  local res
  if returnArray then
    if ffi then
      res = ffi.new("float[?]", points[#points][1] + 1)
    else
      res = table.new(points[#points][1] + 1, 0)
    end
  else
    res = table.new(points[#points][1] + 1, 0)
  end

  local p0, p1, p2, p3, x, steps, t

  for i = 1, #points - 1 do
    p0, p1, p2, p3 = points[max(i - 1, 1)], points[i], points[i + 1], points[min(i + 2, #points)]
    steps = p2[1] - p1[1]
    t = 0
    for x = floor(p1[1]), floor(p2[1]) do
      res[x] = 0.5 * (
      (2 * p1[2])
      + (  p2[2] -   p0[2]) * t
      + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t * t
      + (3 * p1[2] -   p0[2] - 3 * p2[2] + p3[2]) * t * t * t)
      t = t + 1/steps
    end
  end
  return res
end

function createCurve(points, returnArray)
  if #points < 2 then return nil end
  local res
  if returnArray then
    if ffi then
      res = ffi.new("float[?]", points[#points][1] + 1)
    else
      res = table.new(points[#points][1] + 1, 0)
    end
  else
    res = table.new(points[#points][1] + 1, 0)
  end
  local p1, p2, steps, t

  if #points == 2 then
    p1, p2 = points[1], points[2]
    steps = p2[1] - p1[1]
    local p2p1 = p2[2] - p1[2]
    t = 0
    for x = floor(p1[1]), floor(p2[1]) do
      res[x] = p1[2] + t * p2p1
      t = t + 1/steps
    end
    return res
  end

  return CatMullRomSpline(points, returnArray)
end

function createCurveArray(points)
  if #points < 2 then return nil end

  return createCurve(points, true), points[#points][1] + 1
end

function PSItoPascal(psi)
  return psi * 6894.757 + 101325
end

function unrequire(m)
  package.loaded[m] = nil
  _G[m] = nil
end

function encodeJson(v)
  local vtype = type(v)

  -- Handle strings
  if vtype == 'string' then
    return stringformat('%q', v)
  end

  -- Handle numbers and booleans
  if vtype == 'number' then
    if v == v + 1 then -- test for inf
      if v >= 0 then
        return '"inf"'
      else
        return '"-inf"'
      end
    else
      return stringformat('%g', v)
    end
  end

  -- Handle tables
  if vtype == 'table' then
    if next(v) ~= 1 then
      local tmp = {}
      local tmpidx = 1
      for kk, vv in pairs(v) do
        tmp[tmpidx] = stringformat('%q:%s', kk, encodeJson(vv))
        tmpidx = tmpidx + 1
      end
      return stringformat('{%s}', tableconcat(tmp, ','))
    else
      local vcount = #v
      local tmp = table.new(vcount, 0)
      for i = 1, vcount do
        tmp[i] = encodeJson(v[i])
      end
      return stringformat('[%s]', tableconcat(tmp, ','))
    end
  end

  if vtype == 'boolean' then return tostring(v) end

  return "null"
end

function encodeJsonPretty(v, lvl)
  if v == nil then return "null" end
  if lvl == nil then lvl = 0 end

  local vtype = type(v)

  -- Handle strings
  if vtype == 'string' then
    return stringformat('%q', v)
  end

  -- Handle numbers and booleans
  if vtype == 'number' then
    return stringformat('%g', v)
  elseif vtype == 'boolean' then
    return tostring(v)
  end

  -- Handle tables
  if vtype == 'table' then
    local indent = string.rep('  ', lvl)
    local indentPrev = ''
    if lvl > 1 then
      indentPrev = string.rep('  ', lvl - 1)
    end
    local tmp = {}
    if next(v) ~= 1 then
      for kk, vv in pairs(v) do
        local cv = encodeJsonPretty(vv, lvl + 1)
        if cv ~= nil then
          -- no keys with nil as value, happens on functions
          table.insert(tmp, string.format('"%s":%s', kk, cv))
        end
      end
      return stringformat('{\n'..indent .. '%s\n'.. indentPrev ..'}', table.concat(tmp, ',\n' .. indent))
    else
      for kk, vv in pairs(v) do
        table.insert(tmp, encodeJsonPretty(vv, lvl + 1))
      end
      return stringformat('[\n' .. indent .. '%s\n' .. indentPrev .. ']', table.concat(tmp, ',\n' .. indent))
    end
  end

  return nil
end

local function isPackage(name, entry)
  if name == 'extensions' then
    return false
  end

  if type(entry) == 'function' then
    return false
  elseif type(entry) == 'table' and entry.__extensionsName__ then
    return false
  end

  return true
end

function serializePackages(reason)
  --log("I", 'lua.extensions', "serializePackages called.....")
  if reason == nil then reason = 'reload' end
  local tmp = {}
  for k,v in pairs(package.loaded) do
    local shouldProcess = isPackage(k, v)
    -- log("I", "serialize", "K: "..k.."  isPackage: "..tostring(shouldProcess))
    if shouldProcess and type(v) == 'table' and (v['onDeserialized'] ~= nil or v['onSerialize'] ~= nil) then
      -- log("I", "serialize", "Package: "..k)
      if type(v['onSerialize']) == 'function' then
        -- if serialization function is existing, use that
        tmp[k] = v['onSerialize'](reason)
      elseif v['state']  then
        -- if M.state is existing, use only that
        tmp[k] = v.state
      else
        -- fallback: whole M
        tmp[k] = v
      end
    end
  end

  local extensionsModulesData = extensions.getSerializationData(reason)
  -- combine the 2 results into 1
  local fullData = tableMerge(tmp, extensionsModulesData)
  return serialize(tmp)
end

function deserializePackages(data, filter)
  if data == nil then return end
  -- log("I", 'lua.extensions', "deserializePackages called.....")

  -- Process extensions first so that calls to extensions.belongsToExtensions work with newly loaded modules
  extensions.deserialize(data)

  for k,v in pairs(package.loaded) do
    --print("k="..tostring(k) .. " = " .. tostring(v))
    local shouldProcess = isPackage(k, v)
    if shouldProcess and (filter == nil or k == filter) and type(v) == 'table' and (v['onDeserialized'] ~= nil or v['onDeserialize'] ~= nil) and data[k] ~= nil then
      --log("I", "deserialize", "Package: "..k)

      if type(v['onDeserialize']) == 'function' then
        -- having a deserilization function? then use that!
        v['onDeserialize'](data[k])
      elseif type(v['state']) == 'table' then
        -- only merge M.state
        tableMerge(v['state'], data[k])
      else
        -- merge whole M
        tableMerge(v, data[k])
      end
      if type(v['onDeserialized']) == 'function' then
        v['onDeserialized'](data[k])
      end
    end
  end
end

-- serialization functions, see testSerialization, be aware that you need to add custom datatypes in this in case you need them
-- serialized Lua
function serialize(val)
  local vtype = type(val)

  if vtype == "string" then
    return stringformat("%q", val)
  elseif vtype == "number" then
    return stringformat('%g',val)
  elseif vtype == "table" then
    if val["_noSerialize"] then
      return 'nil'
    end
    if val["_serialize"] ~= nil then
      local tmp = {}
      local tmpidx = 1
      if type(val["_serialize"]) == "table" then
        local incl = val["_serialize"]
        for k, v in pairs(val) do
          if incl[k] then
            tmp[tmpidx] = stringformat('[%s]=%s', type(k) == 'string' and string.format("%q", k) or k, serialize(v))
            tmpidx = tmpidx + 1
          end
        end
      else
        for k, v in pairs(val) do
          tmp[tmpidx] = stringformat('[%s]=%s', type(k) == 'string' and string.format("%q", k) or k, serialize(v))
          tmpidx = tmpidx + 1
        end
      end
      return stringformat('{%s}', tableconcat(tmp, ','))
    else
      if next(val) ~= 1 then
        local tmp = {}
        local tmpidx = 1
        for k, v in pairs(val) do
          tmp[tmpidx] = stringformat('[%s]=%s', type(k) == 'string' and string.format("%q", k) or k, serialize(v))
          tmpidx = tmpidx + 1
        end
        return stringformat('{%s}', tableconcat(tmp, ','))
      else
        local vcount = #val
        local tmp = table.new(vcount, 0)
        for i = 1, vcount do
          tmp[i] = serialize(val[i])
        end
        return stringformat('{%s}', tableconcat(tmp, ','))
      end
    end
  elseif vtype == "boolean" then
    return tostring(val)
  elseif vtype == 'nil' then
    return 'nil'
  elseif vtype == "userdata" then
    -- %g produces the shortest numbers
    if val.___type == __typePoint3F then
      return stringformat("Point3F(%g,%g,%g)", val.x, val.y, val.z)
    elseif val.___type == __typeFloat3 then
      return stringformat("float3(%g,%g,%g)", val.x, val.y, val.z)
    elseif val.___type == __typeQuaternion then
      return stringformat("Quaternion():setXYZW(%g,%g,%g,%g)", val.x, val.y, val.z, val.w)
    elseif val.___type == __typeColor then
      return stringformat("color(%g,%g,%g,%g)", val.r, val.g, val.b, val.a)
    elseif val.___type == __typeQuatF then
      return stringformat("QuatF(%g,%g,%g,%g)", val.x, val.y, val.z, val.w)
    else
      log("E", "serialize", "Unrecognized data ___type: "..dumps(val.___type))
    end
  elseif vtype == 'cdata' then
    return tostring(val)
  elseif vtype == 'function' then
    return 'nil'
  else
    log("E", "serialize", "Unrecognized data type: "..type(val))
  end
end

function unserialize(s)
  if s == nil then return nil end
  return loadstring("return " .. s)()
end

function testSerialization()
  d = {a = "foo", b = {c = 123, d = "foo", p = float3(1,2,3)}}
  print("original data: " .. tostring(d))
  dump(d)

  s = serialize(d)
  print("serialized data: " .. tostring(s))

  da = unserialize(s)
  print("restored data: " .. tostring(da))
  dump(da)

  sa = serialize(da)
  if sa == s then
    print "serialization seems to work"
  else
    print "serialization got problems, look above"
  end

  if unserialize(serialize(nil)) ~= nil then print "serialize with nil fails to work corectly" end
end
--testSerialization()

function copyfile(src, dst)
  local infile = io.open(src, "r")
  if not infile then return nil end
  local outfile = io.open(dst, "w")
  if not outfile then return nil end
  outfile:write(infile:read("*a"))
  infile:close()
  outfile:close()
end

--[[
LUA 5.1 compatible

Ordered Table
keys added will be also be stored in a metatable to recall the insertion oder
metakeys can be seen with for i,k in ( <this>:ipairs()  or ipairs( <this>._korder ) ) do
ipairs( ) is a bit faster

variable names inside __index shouldn't be added, if so you must delete these again to access the metavariable
or change the metavariable names, except for the 'del' command. thats the reason why one cannot change its value
]]--
function newT( t )
  local mt = {}
  -- set methods
  mt.__index = {
    -- set key order table inside __index for faster lookup
    _korder = {},
    -- traversal of hidden values
    hidden = function() return pairs( mt.__index ) end,
    -- traversal of table ordered: returning index, key
    ipairs = function( self ) return ipairs( self._korder ) end,
    -- traversal of table
    pairs = function( self ) return pairs( self ) end,
    -- traversal of table ordered: returning key,value
    opairs = function( self )
      local i = 0
      local function iter( self )
        i = i + 1
        local k = self._korder[i]
        if k then
          return k,self[k]
        end
      end
      return iter,self
    end,
    -- to be able to delete entries we must write a delete function
    del = function( self,key )
      if self[key] then
        self[key] = nil
        for i,k in ipairs( self._korder ) do
          if k == key then
            table.remove( self._korder, i )
            return
          end
        end
      end
    end,
  }
  -- set new index handling
  mt.__newindex = function( self,k,v )
    if k ~= "del" and v then
      rawset( self,k,v )
      table.insert( self._korder, k )
    end
  end
  return setmetatable( t or {},mt )
end

function string.startswith(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

function string.endswith(String,End)
  return End=='' or string.sub(String,-string.len(End))==End
end

function string.rstripchars(String, chrs)
  return String:gsub("["..chrs.."]$", '')
end

function string.stripchars(String, chrs)
  return String:gsub("["..chrs.."]", '')
end

function string.split(String, delimregex)
  if not delimregex then
    delimregex = "%S+"
  end
  local t = {}
  for i in string.gmatch(String, delimregex) do
    t[#t + 1] = i
  end
  return t
end

path = {}
path.dirname = function (filename)
  while true do
    if filename == "" or string.sub(filename, -1) == "/" then
      break
    end
    filename = string.sub(filename, 1, -2)
  end
  if filename == "" then
    filename = "."
  end

  return filename
end

path.is_file = function (filename)
  local f = io.open(filename, "r")
  if f ~= nil then
    io.close(f)
    return true
  end
  return false
end

path.split = function(path)
  local dir, filename, ext = string.match(path, "(.-)([^/]-([^/%.]*))$") --  "(.-)([^/]-([^/%.]+))$" - enforces a filename
  if filename == ext then ext = '' end
  return dir, filename, ext
end

-- WIP
path.split2 = function(filepath)
  local dir, filename, ext = path.split(filepath)
  filename = filename:gsub('.'..ext, "")
  return dir, filename, ext
end

path.getCurrentPath = function()
  local dirname, filename = path.split(debug.getinfo(2).short_src)
  return dirname
end

-- returns some contrasting colors and loops after a while
local contrast_color_list = {
  {255, 0, 0, 255},
  {0, 255, 0, 255},
  {0, 0, 255, 255},
  {255, 255, 0, 255},
  {255, 0, 255, 255},
  {0, 255, 255, 255},
  {96, 128, 200, 255},
  {196, 8, 0, 255},
  {120, 0, 196, 255},
  {90, 255, 255, 255},
  {63, 102, 190, 255},
  {235, 135, 63, 255}
}

function getContrastColor(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return color(c[1], c[2], c[3], c[4])
end

function getContrastColorF(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return ColorF(c[1]/255, c[2]/255, c[3]/255, c[4]/255)
end

function getContrastColorStringRGB(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return string.format("#%02x%02x%02x", c[1], c[2], c[3])
end

function getContrastColorStringRGBA(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return string.format("#%02x%02x%02x%02x", c[1], c[2], c[3], c[4])
end

-- plain, no section, no nested INI support
function loadIni(filename)
  local d = {}
  local f = io.open(filename, "r")
  if not f then return nil end
  for line in f:lines() do
    local key, value = line:match("^([^%s=]+)%s-=%s-(.+)$")
    if key and value then
      value = trim(value)
      if tonumber(value) then
        value = tonumber(value)
      elseif value == "true" then
        value = true
      elseif value == "false" then
        value = false
      end
      d[key] = value
    else
      log("E", "", "Unable to parse INI line: "..line)
    end
  end
  f:close()
  return d
end

function saveIni(filename, d)
  local c = ""
  for k,v in pairs(d) do
    c = c .. ("%s = %s\r\n"):format(tostring(k), tostring(v))
  end
  local f = io.open(filename, "w")
  if not f then return end
  f:write(c)
  f:close()
end

function hex_dump_file(buf, filename)
  local f = io.open(filename, "w")
  for i=1,math.ceil(#buf/16) * 16 do
    if (i-1) % 16 == 0 then f:write(string.format('%08X  ', i-1)) end
    f:write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
    if i %  8 == 0 then f:write(' ') end
    if i % 16 == 0 then f:write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
  end
  f:close()
end

function ui_message(msg, ttl, category, icon)
  (obj or be):executeJS("HookManager.trigger('Message',"..encodeJson({msg=msg, ttl=ttl or 5, category=category or '', icon = icon})..");")
  --log('D', "gui.message", msg)
end

function isint(n)
  local m = tonumber(n)
  return m == floor(m)
end

function detectGlobalWrites()
  setmetatable(_G, {
    --__index = function (t, key)
    --  log('D', 'globals', 'read: ' .. tostring(key))
    --  rawget(_G[key])
    --end,
    __newindex = function (t, key, val)
      rawset(_G, key, val)
      log('W', 'globals', debug.traceback('set new global variable: "' .. tostring(key) .. '"  to "'  .. tostring(val) .. '"', 2, 1, false))
    end,
  })
end

function lerp(from,to,t)
  return from + (to - from) * min(max(0, t),1)
end

function invertLerp(from,to,value)
  value = min(max(from, value),to)
  return (value - from) / (to-from)
end

function stringHash(text)
  -- From: http://wowwiki.wikia.com/wiki/StringHash/Analysis
  -- available under CC-BY-SA
  local counter = 1
  local len = string.len(text)
  for i = 1, len, 3 do
    counter = math.fmod(counter * 8161, 4294967279) +
    (string.byte(text, i) * 16776193) +
    ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) +
    ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
  end
  return math.fmod(counter, 4294967291)
end

function bytes_to_string(bytes)
    if bytes >= 1024 * 1000 then
      return ("%.2f MiB"):format(bytes / (1024 * 1024))
    else
      return ("%.2f KiB"):format(bytes / 1024)
    end
end

-- safe lua function execution with IO overrides
-- NOTE: this cannot be conceptually safe as you can always get hidden objects
function executeLuaSandboxed(cmd, source)
  source = source or 'executeLuaSandboxed'
  local stdOutCache = {}

  -- sandbox creation
  local fEnv = getfenv(1) -- we reuse the environment and override only some things ...
  -- sandboxed functions
  fEnv.print = function(msg)
    io.write("sandboxed print: " .. tostring(msg) .. "\n")
    table.insert(stdOutCache, tostring(msg))
  end

  -- parse the lua
  local func, err = load(
    cmd,
    source,
    't',
    fEnv -- this is the tiny sandbox that we have to redirect stdout
  )

  -- execute the lua
  if func then
    if type(debug.traceback) ~= "function" then
      return "Error: Lua debug traceback broken"
    end

    local ok, result = xpcall(func, debug.traceback)
    if ok then
      return result, stdOutCache
    end

    return "Error: " .. tostring(result)
  end
  return "Error: " .. tostring(err)
end

function convertVehicleIdKeysToVehicleNameKeys(data)
  local result = {}
  if data and type(data) == 'table' then
    for vid,entry in pairs(data) do
      local vehicle = be:getObjectByID(vid)
      if vehicle then
        local vehicleName = vehicle:getField('name', '')
        result[vehicleName] = entry
      end
    end
  end
  return result
end

function convertVehicleNameKeysToVehicleIdKeys(data)
  local result = {}
  if data and type(data) == 'table' then
    for vehicleName,entry in pairs(data) do
      local vehicle = scenetree.findObject(vehicleName)
      if vehicle then
        local vehicleID = vehicle:getID()
        result[vehicleID] = entry
      end
    end
  end
  return result
end

-- returns a list of immidiate directories with full path in given path
function getDirectories(path)
  local files = FS:findFilesByPattern(path,"*", 0, true, true)
  local dirs = {}
  for _,v in pairs(files) do
    if FS:directoryExists(v) and not FS:fileExists(v) then
      table.insert(dirs, v)
    end
  end
  return dirs
end

-- prints KB of garbage created since previous call
function gcprobe(printZero)
  local newgccount = collectgarbage("count")
  if __prevgccount__ then
    local dif = newgccount - __prevgccount__
    if dif > 0 or printZero then print(newgccount - __prevgccount__) end
    __prevgccount__ = false
  else
    __prevgccount__ = newgccount
  end
end

-- prints duration in ms
function timeprobe()
  if not __hp__ then
    if be then
      __hp__ = hptimer()
    else
      __hp__ = HighPerfTimer()
    end
  end
  local t = __hp__:stopAndReset()
  if not __prevtime__ then
    __prevtime__ = t
  else
    if be then
      print(t)
      t = t / 1000
    else
      print(t)
    end
    __prevtime__ = false
    return t
  end
end

debugPoll = nop
dbg = { halt = nop }
function startDebugger()
  if debugPoll ~= nop then return end
  dbg = require('debugger/vscode-debuggee') -- global intentionally
  debugPoll = dbg.poll
  dbg.start(luaVMInstanceName, {logFunc = log}) -- luaVMInstanceName should be hardcoded in c++
end

function hex2rgb(hex)
  local hex = hex:gsub("#","")
  if hex:len() == 3 then
    return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
  else
    return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
  end
end
