-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this file adds core language features we use everywhere

-- tiny compatibility layer depending on if it is run
-- in plain Lua 5.1 - 5.3 or LuaJIT

loadstring = loadstring or load
unpack = unpack or table.unpack

-- notes for developers:
-- string.gfind = string.gmatch
-- table.getn = #

--== lua language core features below ==--

-- this function can load an optional module
function require_optional(module)
  local ok, m = pcall(require, module)
  if ok then return m end
  return nil
end

-- unload a package/module
function unrequire(m)
  package.loaded[m] = nil
  _G[m] = nil
end

-- little snippet that enforces reloading of files
function rerequire(module)
  package.loaded[module] = nil
  local m = require(module)
  if not m then
    log('W', "rerequire", ">>> Module failed to load: " .. tostring(module).." <<<")
  end
  return m
end

-- use luajit extension table.clear and new if they exist, otherwise fallback to lua implementations
ffi = require_optional('ffi') -- this sets the global ffi variable

if not pcall(require, "table.clear") then
  table.clear = function(tab) for k, _ in pairs(tab) do tab[k] = nil end end
end

if not pcall(require, "table.new") then
  table.new = function() return {} end
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

-- safe table iteration functions: it will iterate the tables via a copy: "adding" to the tables will not change the iteration
function ipairs_safe(t)
  local tcount = #t
  local new_table = table.new(tcount, 0)
  for i = 1, tcount do
    new_table[i] = t[i]
  end
  local function ipairs_safe_it(tt, i)
    i = i + 1
    local v = tt[i]
    if v ~= nil then
      return i,v
    else
      return nil
    end
  end
  return ipairs_safe_it, new_table, 0
end

function pairs_safe(t)
  local new_table = table.new(#t, 0)
  for index, value in pairs(t) do
    new_table[index] = value
  end
  local function pairs_safe_it(tt, i)
    local k, v = next(tt, i)
    if k ~= nil then
      return k,v
    else
      return nil
    end
  end
  return pairs_safe_it, new_table, nil
end

function nop()
end

--== Debugger ==--
debugPoll = nop
dbg = { halt = nop }
function startDebugger()
  if debugPoll ~= nop then return end
  dbg = require('libs/luadbg/vscode-debuggee') -- global intentionally
  debugPoll = dbg.poll
  dbg.start(luaVMInstanceName or 'default', {logFunc = log}) -- luaVMInstanceName should be hardcoded in c++
end
