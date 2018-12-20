-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- utility things, see documentation

require('filters')

--== type definitions ==--
-- used in conversions and serializations
local __typePoint3F  = (Point3F  ~= nil) and Point3F(0,0,0).___type or nil
local __typeFloat3   = (float3   ~= nil) and float3(0,0,0).___type or nil
local __typeQuaternion = (Quaternion ~= nil) and Quaternion().___type or nil
local __typeQuatF = (QuatF ~= nil) and QuatF(0,0,0,1).___type or nil
local __typeColor = (color ~= nil) and color(0,0,0,0).___type or nil

-- useful local shortcuts
local abs, floor, min, max, stringformat, tableconcat = math.abs, math.floor, math.min, math.max, string.format, table.concat
local str_find, str_len, str_sub = string.find, string.len, string.sub

--== color things ==--
-- returns some contrasting colors and loops after a while
contrast_color_list = {
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

-- TODO: convert calls to rainbowColor()
function getContrastColorF(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return ColorF(c[1]/255, c[2]/255, c[3]/255, c[4]/255)
end

-- TODO: convert calls to rainbowColor()
function getContrastColorStringRGB(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return string.format("#%02x%02x%02x", c[1], c[2], c[3])
end

-- TODO: convert calls to rainbowColor()
function getContrastColorStringRGBA(i)
  local c = contrast_color_list[i % (#contrast_color_list) + 1]
  return string.format("#%02x%02x%02x%02x", c[1], c[2], c[3], c[4])
end

-- splits the RGB color range into numOfSteps slices equally. Creates good contrast colors
function rainbowColor(numOfSteps, step, format)
  if format == nil then format = 255 end
  -- This function generates vibrant, "evenly spaced" colours (i.e. no clustering). This is ideal for creating easily distinguishable vibrant markers in Google Maps and other apps.
  -- Adam Cole, 2011-Sept-14
  -- HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
  local r = 0
  local g = 0
  local b = 0
  local h = step / numOfSteps
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local q = 1 - f
  local iMod = i % 6
  if     iMod == 0 then r = 1; g = f; b = 0
  elseif iMod == 1 then r = q; g = 1; b = 0
  elseif iMod == 2 then r = 0; g = 1; b = f
  elseif iMod == 3 then r = 0; g = q; b = 1
  elseif iMod == 4 then r = f; g = 0; b = 1
  elseif iMod == 5 then r = 1; g = 0; b = q
  end
  if format == 255 then
  --return 'rgba(' .. (r*255) .. ',' .. (g*255) .. ',' .. (b*255) .. ',1)'
    return { math.floor(r*255), math.floor(g*255), math.floor(b*255), 1}
  else
    return { r, g, b, 1}
  end
end

--== String utilities ==--

local inspect = require("libs/inspect/inspect")

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

function lpad(s, l, c)
  s = tostring(s)
  return string.rep(c, l - #s)..s
end

function rpad(s, l, c)
  s = tostring(s)
  return s .. string.rep(c, l - #s)
end

function trim(s)
  return s:match("^%s*(.-)%s*$")
end

function join(list, delimiter)
  return table.concat(list, delimiter)
end

-- Compatibility: Lua-5.0
function split(str, delim, nMax)
  local aRecord = {}

  if str_len(str) > 0 then
     nMax = nMax or -1
     local nField, nStart = 1, 1
     local nFirst,nLast = str_find(str, delim, nStart, true)
     while nFirst and nMax ~= 0 do
        aRecord[nField] = str_sub(str, nStart, nFirst-1)
        nField = nField+1
        nStart = nLast+1
        nFirst,nLast = str_find(str, delim, nStart, true)
        nMax = nMax-1
     end
     aRecord[nField] = str_sub(str, nStart)
  end

  return aRecord
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

function string.stripcharsFrontBack(str, chrs)
  str = str:match( "^["..chrs.."]*(.+)" )
  str = str:match( "(.-)["..chrs.."]*$" )
  return str
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

-- converts a byte count to a human readable string
function bytes_to_string(bytes)
    if bytes >= 1000 * 1000 then
      return ("%.2f MB"):format(bytes / (1000 * 1000))
    elseif bytes >= 1000 then
      return ("%.2f KB"):format(bytes / 1000)
    end
    return ("%.2f B"):format(bytes)
  end

-- time string format
function formatTimeStringNow(res)
  local d = os.date('*t')
  res = res:gsub("{YYYY}", string.format('%04d', d.year))
  res = res:gsub("{YY}", string.format('%02d', d.year - 2000))
  res = res:gsub("{Y}", d.year)
  res = res:gsub("{MM}", string.format('%02d', d.month))
  res = res:gsub("{M}", d.month)
  res = res:gsub("{DD}", string.format('%02d', d.day))
  res = res:gsub("{D}", d.day)
  res = res:gsub("{HH}", string.format('%02d', d.hour))
  res = res:gsub("{H}", d.hour)
  res = res:gsub("{mm}", string.format('%02d', d.min))
  res = res:gsub("{m}", d.min)
  res = res:gsub("{ss}", string.format('%02d', d.sec))
  res = res:gsub("{s}", d.sec)
  return res
end

-- ASCII graph
function graphs(v, len)
  local size = math.min(len, math.abs(v))
  return '['..string.rep(v>0 and "+" or "-", size) .. string.rep(' ', len - size)..']'
end


--== Json ==--

function jsonEncode(v)
  local vtype = type(v)

  -- Handle strings
  if vtype == 'string' then
    return stringformat('%q', v)
  end

  -- Handle numbers and booleans
  if vtype == 'number' then
    if v == v + 1 then -- test for inf
      return v >= 0 and '"inf"' or '"-inf"'
    else
      return stringformat('%g', v)
    end
  end

  -- Handle tables
  if vtype == 'table' then
    if next(v) == 1 and next(v, #v) == nil then
      local vcount = #v
      if vcount <= 2 then
        if vcount == 1 then
          return stringformat('[%s]', jsonEncode(v[1]))
        else
          return stringformat('[%s,%s]', jsonEncode(v[1]), jsonEncode(v[2]))
        end
      else
        local tmp = table.new(vcount, 0)
        for i = 1, vcount do
          tmp[i] = jsonEncode(v[i])
        end
        return stringformat('[%s]', tableconcat(tmp, ','))
      end
    else
      local tmp = table.new(0, 2)
      local tmpidx = 1
      for kk, vv in pairs(v) do
        tmp[tmpidx] = stringformat('%q:%s', kk, jsonEncode(vv))
        tmpidx = tmpidx + 1
      end
      return stringformat('{%s}', tableconcat(tmp, ','))
    end
  end

  if vtype == 'boolean' then return tostring(v) end

  return "null"
end

function jsonEncodePretty(v, lvl)
  if v == nil then return "null" end
  local vtype = type(v)
  if vtype == 'string' then return stringformat('%q', v) end
  if vtype == 'number' then return stringformat('%g', v) end
  if vtype == 'boolean' then return tostring(v) end

  -- Handle tables
  if vtype == 'table' then
    lvl = lvl or 0
    local indent = string.rep('  ', lvl)
    local indentPrev = string.rep('  ', math.max(0, lvl - 1))
    local tmp = {}
    if next(v) == 1 and next(v, #v) == nil then
      for _, vv in ipairs(v) do table.insert(tmp, jsonEncodePretty(vv, lvl + 1)) end
      return stringformat('[\n' .. indent .. '%s\n' .. indentPrev .. ']', table.concat(tmp, ',\n' .. indent))
    else
      for kk, vv in pairs(v) do
        local cv = jsonEncodePretty(vv, lvl + 1)
        if cv ~= nil then table.insert(tmp, string.format('"%s":%s', kk, cv)) end
      end
      return stringformat('{\n'..indent .. '%s\n'.. indentPrev ..'}', table.concat(tmp, ',\n' .. indent))
    end
  end
  return nil
end

function jsonDecode(content, context)
  if not json then json = require("json") end
  local state, data = xpcall(function() return json.decode(content) end, debug.traceback)
  if state == false then
    log('E', "jsonDecode", "unable to decode JSON: "..tostring(context))
    log('E', "jsonDecode", "JSON decoding error: "..tostring(data))
    return nil
  end
  return data
end

function jsonWriteFile(filename, obj, pretty)
  local f = io.open(filename, "w")
  if f then
    local content
    if pretty then
      content = jsonEncodePretty(obj)
    else
      content = jsonEncode(obj)
    end
    f:write(content)
    f:close()
    return true
  end
  return false
end

function jsonReadFile(filename)
  local content = readFile(filename)
  if content == nil then
    -- parent needs to deal with error reporting
    return nil
  end
  return jsonDecode(content, filename)
end

function readDictJSONTable(filename)
  local data = jsonReadFile(filename)
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

--== Table utilities ==--

-- checks if the table contains a certain value, compared lower-case. Non-recursive
function tableContainsCaseInsensitive(table, element)
  element = string.lower(element)
  for _, value in pairs(table) do
    if string.lower(value) == element then
      return true
    end
  end
  return false
end

-- checks if the table contains a certain value. Non-recursive
function tableContains(t, element)
  for _, v in pairs(t) do
    if v == element then
      return true
    end
  end
  return false
end

-- checks if the table is a dictionary by checking if key 1 exists
function tableIsDict(tbl)
  if type(tbl) ~= "table" then
    return false
  end
  return next(tbl) ~= 1
end

-- checks if the table is empty. Fors for dicts and arrays
function tableIsEmpty(tbl)
  return type(tbl) ~= 'table' or next(tbl) == nil
end

-- returns a new array containing all table keys
function tableKeys(tbl)
  local keys = table.new(#tbl, 0)
  local keysidx = 1
  for k, _ in pairs(tbl) do
    keys[keysidx] = k
    keysidx = keysidx + 1
  end
  return keys
end

-- appends an array table(int keys) to another
function arrayConcat(dst, src)
  local dstidx = #dst
  for i = src[0] == nil and 1 or 0, #src do
    dstidx = dstidx + 1
    dst[dstidx] = src[i]
  end
  return dst
end

function tableMerge(dst, src)
  for i,v in pairs(src) do
    if type(v) ~= "function" then
      dst[i] = v
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

-- returns the size of the table. Works with arrays and dictionaries. SLOW, as it iterates all ekements
function tableSize(tbl)
  if type(tbl) ~= "table" then
    return 0
  end
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

-- counts the 0 elemnet as well if existing (Lua tables start with 1)
function tableSizeC(tbl)
  return #tbl + (tbl[0] == nil and 0 or 1)
end

-- finds the key of a certain value. Non-recursive
function tableFindKey(t, element)
  for k, v in pairs(t) do
    if v == element then
      return k
    end
  end
  return nil
end

--returns a readonly table (only primary level unless all sub-tables are also created as readonly)
function tableReadOnly(table)
  return setmetatable({}, {
      __index = table,
      __newindex = function(table, key, value)
        error(string.format("Attempt to modify read-only table entry: %s = %s", key, value))
      end,
      __metatable = false
    });
end

-- TODO: duplicate of tableContains ?
function tableFindValue(t, val)
    for index, value in ipairs(t) do
        if value == val then
            return true
        end
    end
    return false
end

-- TODO: duplicate of tableFindKey ?
function arrayFindValueIndex(t, val)
    for i = 1, #t do
        if t[i] == val then
            return i
        end
    end
    return false
end

-- counts the depth of a table. Recursive, super slow
function tableDepth(tbl, lookup)
  if type(tbl) ~= 'table' then return 0 end
  lookup = lookup or {}
  local depth = 1
  for k, v in pairs(tbl) do
    if type(k) == "table" then
      lookup[k] = lookup[k] or tableDepth(k, lookup)
      depth = math.max(depth, lookup[k] + 1)
    end
    if type(v) == "table" then
      lookup[v] = lookup[v] or tableDepth(v, lookup)
      depth = math.max(depth, lookup[v] + 1)
    end
  end
  return depth
end

-- creates a copy of the value or table. Non-recursive
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

-- local, used in deepcopy()
local function _deepcopyTable(lookup_table, object)
  local new_table = table.new(#object, 0)
  lookup_table[object] = new_table
  for index, value in pairs(object) do
    if type(index) == 'table' then
      index = lookup_table[index] or _deepcopyTable(lookup_table, index)
    end
    if type(value) == 'table' then
      value = lookup_table[value] or _deepcopyTable(lookup_table, value)
    end
    new_table[index] = value
  end
  return setmetatable(new_table, getmetatable(object))
end

-- copies the object, recreates an exact  copy. Recursive. Slow
function deepcopy(object)
  if type(object) == 'table' then
    local lookup_table = {}
    return _deepcopyTable(lookup_table, object)
  else
    return object
  end
end


--== Input/Output helpers ==--

-- inspects the arguments and writes the output to the file
function dumpToFile(filename, ...)
  local f = io.open(filename, "w")
  if f then
    f:write(inspect(...))
    f:close()
    return true
  end
  return false
end

-- reads the content of a file
function readFile(filename)
  local f = io.open(filename, "r")
  if f == nil then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

-- writes text to a file
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

--== Math ==--
-- float3 conversion helpers
function tableToFloat3(v)
  if v == nil then
    return float3(0,0,0)
  end
  return float3(v.x, v.y, v.z)
end

-- linear interpolation between two values
function lerp(from, to, t)
  return from + (to - from) * min(max(0, t), 1)
end

--== User interface ==--

function ui_message(msg, ttl, category, icon)
  (obj or be):executeJS("HookManager.trigger('Message',"..jsonEncode({msg=msg, ttl=ttl or 5, category=category or '', icon = icon})..");")
end

--== Extension/Packages ==--

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

--== path/directory utils ==--


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

--== Ini settings file ==--
-- plain, no section, no nested INI support
function loadIni(filename)
  local d = {}
  local f = io.open(filename, "r")
  if not f then return nil end
  for line in f:lines() do
    if string.len(line) > 0 then
      local firstChar = string.sub(line, 1, 1)
      if firstChar ~= '#' and firstChar ~= ';' and firstChar ~= '/' then
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
    end
  end
  f:close()
  return d
end

function saveIni(filename, d)
  local c = {}

  -- sort the keys
  local dkeys = {}
  for k in pairs(d) do table.insert(dkeys, k) end
  table.sort(dkeys)

  -- save a header
  table.insert(c, '# ' .. beamng_windowtitle .. '\r\n')
  table.insert(c, '# ' .. beamng_buildinfo .. '\r\n')
  table.insert(c, '# saved on ' .. formatTimeStringNow('{YYYY}/{MM}/{DD} {HH}:{mm}:{ss}') .. '\r\n')

  -- save the text
  for _, k in pairs(dkeys) do
    local v = d[k]
    table.insert(c, ("%s = %s\r\n"):format(tostring(k), tostring(v)))
  end

  -- create the file
  local f = io.open(filename, "w")
  if not f then return end
  f:write(tableconcat(c, ""))
  f:close()
end


--== Serialization ==--


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

-- function testSerialization()
--   d = {a = "foo", b = {c = 123, d = "foo", p = float3(1,2,3)}}
--   print("original data: " .. tostring(d))
--   dump(d)

--   s = serialize(d)
--   print("serialized data: " .. tostring(s))

--   da = unserialize(s)
--   print("restored data: " .. tostring(da))
--   dump(da)

--   sa = serialize(da)
--   if sa == s then
--     print "serialization seems to work"
--   else
--     print "serialization got problems, look above"
--   end

--   if unserialize(serialize(nil)) ~= nil then print "serialize with nil fails to work corectly" end
-- end
--testSerialization()

--== Other ==--

function detectGlobalWrites()
  setmetatable(_G, {
    __newindex = function (t, key, val)
      rawset(_G, key, val)
      log('W', 'globals', debug.traceback('set new global variable: "' .. tostring(key) .. '"  to "'  .. tostring(val) .. '"', 2, 1, false))
    end,
  })
end


-- safe lua function execution with IO overrides
-- NOTE: this cannot be conceptually safe as you can always get hidden objects
function executeLuaSandboxed(cmd, source)
  source = source or 'executeLuaSandboxed'
  local stdOutCache = {}

  -- sandbox creation
  local fEnv = getfenv(1) -- we reuse the environment and override only some things ...
  -- sandboxed functions
  local print_saved = fEnv.print
  fEnv.print = function(msg)
    --io.write("sandboxed print: " .. tostring(msg) .. "\n")
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
      fEnv.print = print_saved
      return "Error: Lua debug traceback broken"
    end

    local ok, result = xpcall(func, debug.traceback)
    if ok then
      fEnv.print = print_saved
      return result, stdOutCache
    end

    fEnv.print = print_saved
    return "Error: " .. tostring(result)
  end
  fEnv.print = print_saved
  return "Error: " .. tostring(err)
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

--== Package loaders ==--

-- test for writing our own package loader
local function advancedModuleLoader(modulename)
  local modulepath = string.gsub(modulename, "%.", "/")
  for path in string.gmatch(package.path, "([^;]+)") do
    local filename = string.gsub(path, "%?", modulepath)
    local file = io.open(filename, "rb")
    if file then
      local content = file:read("*a")
      file:close()
      --print(">>>>> load <<<< " .. tostring(modulename) .. ' = ' .. tostring(filename))
      if string.find(filename, '/extensions/') then
        local modulenameVirt = string.gsub(modulename, "/", '_')
        -- the trick to not screw with line numbers: everything needs to be in the same line. Otherwise the line numbers for the debuggers won't fit anymore
        content = [[local logTag = "]].. modulenameVirt ..[[" ; local log = function(level, origin, msg) log(level, ']].. modulenameVirt ..[[.' .. origin, msg) end ; local logf = function(level, msg) local d = debug.getinfo(2, "n") ; if d then log(level, d.name, msg) else log(level, ']].. modulenameVirt ..[[', msg) end end ; ]] .. content
        --print(content)
      end
      -- Compile and return the module
      return loadstring(content, filename)
    end
    --errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom loader)"
  end
  return nil
end

-- Install the loader so that it's called just before the normal Lua loader
if vmType == 'game' then
  table.insert(package.loaders, 2, advancedModuleLoader)
end
