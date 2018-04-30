-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'createDoc'

local function getParentClasses(cls)
  local res = {}
  if not cls then return res end
  if rawget(cls, '___super') and cls.___super.___type then
    local clsName = string.match(cls.___super.___type, 'class<([^>]+)>')
    if clsName then
      table.insert(res, clsName)
    end
    for _,v in pairs(getParentClasses(cls.___super)) do
      table.insert(res, v)
    end
  end
  return res
end

local function dumpDoc()
  local docs = {}
  for k,v in pairs(getmetatable(ColorI).___module) do
    local v2 = getmetatable(_G[k])
    if v2 and v2.___class and v2.___class.___doc and tableSize(v2.___class.___doc) > 0 then
      local doct = v2.___class.___doc
      docs[k] = {}
      docs[k].parentClasses = getParentClasses(v2.___class)
      for kd, vd in pairs(doct) do
        local lines = split(vd, "\n")
        docs[k][kd] = {}
        for kdd, vdd in pairs(lines) do
          if vdd:sub(1,1) == ':' then
            local p = vdd:find(': ')
            if p then
              docs[k][kd][vdd:sub(2,p-1)] = vdd:sub(p+2)
            end
          else
            table.insert(docs[k][kd], vdd)
          end
        end
      end
    end
    --dump(v.___class.___doc)
  end

  local rst = ''
  for className, v in pairs(docs) do
    local r = '.. lua:class:: ' .. tostring(className) .. '\n\n' .. tostring((v._class_ and v._class_[1]) or k or '')
    for ak, av in pairs(v) do
      if type(av) == 'table' and ak ~= '_class_' then
        r = r .. '.. lua:' .. (av.type or 'function') .. ':: ' .. className .. '.' .. tostring(ak) .. '\n\n' .. (av[1] or '') .. '\n'
      end
    end
    rst = rst .. r
  end
  print(rst)
  dump(docs)
  --dump(getmetatable(ColorI).___class.___doc['a'])
end

local function onExtensionLoaded()
  log('I', logTag, "module loaded")

  dumpDoc()
--[=[
  local docEntries = {}

  local luaFiles = FS:findFilesByRootPattern('game:lua', '*.lua', -1, true, false)
  for _, luaFilename in pairs(luaFiles) do
    --print(luaFilename)
    local content = readFile(luaFilename)
    if not content then
      log('E', 'createDoc', 'unable to read file: ' .. tostring(luaFilename))
      goto continue
    end

    for c in content:gmatch('--%[==%[SPHINX%-RST([^%]]*)%]==%]') do
      dump(c)
      table.insert(docEntries, c)
    end

    ::continue::
  end
  --dump(docEntries)
  
  writeFile('api.rst', join(docEntries, '\n\n'))

  --shutdown(0)
  ]=]
end

local function onExtensionUnloaded()
    log('I', logTag, "module unloaded")
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
