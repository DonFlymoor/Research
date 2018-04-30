local M = {}

local logfileJson = 'loggedStreams.json'
local logfileWikitable = 'loggedStreams.txt'
local logfileRst = 'loggedStreams.rst'


local function saveJson(data)
  serializeJsonToFile(logfileJson, data, true)
end

local function readJson()
  return readJsonFile(logfileJson)
end

local function saveWikitable(data)
  writeFile(logfileWikitable, data)
end

local function readWikitable()
  -- huge hack and not happy about it, but it works! finally! \o/
  return readFile(logfileWikitable):gsub('\n', '\\n')
end

local function saveRst(data)
  writeFile(logfileRst, data)
end

local function readRst()
  -- huge hack and not happy about it, but it works! finally! \o/
  return readFile(logfileRst):gsub('\n', '\\n')
end

M.saveJson = saveJson
M.readJson = readJson
M.saveWikitable = saveWikitable
M.readWikitable = readWikitable

M.saveRst = saveRst
M.readRst = readRst
return M