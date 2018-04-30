local M = {}

local states = {}

local function findFiles (file, dir, last) 
  if file.js == nil then
    -- only look in the current folder and not in the childs as well otherwise we will be loading js twice
    local js = FS:findFilesByPattern('/' .. dir, '*.js', 0)

    if tableSize(js) > 0 then
      file.js = {}
      for _,k in pairs(js) do
        local str = string.gsub(k, '/ui2/', '')
        table.insert(file.js, str)
      end
    end
  end
  if file.html == nil and FS:fileExists('/' .. dir .. last .. '.html') then
    file.html = string.gsub(dir .. last .. '.html', 'ui2/', '')
  end
end

local function moduleAvailable (module) 
  if module.available ~= nil then
    if module.available.gamestate ~= nil and not tablecontains(module.available.gamestate, gameState.state.state) then
      return false
    end

    if (module.available.dev or false) and settings.getValue('devMode') then
      return false
    end
  end

  return true
end

local function getStates () 
  local res = {}
  local map = {}
  -- lucklily for us these files are sorted with directive first and then subdirectives
  local files = FS:findFilesByPattern('/ui2/Menu/', 'info.json', -1, true, false)
  local firstLevelReg = '^/((ui2/Menu/(.*)/)info.json)$'
  local secondLevelReg = '^/((ui2/Menu/(.*)/(.*)/)info.json)$'

  for _,v in pairs(files) do
    local depth = tableSize(split(v, "/"))

    -- dump(v, depth)
    if depth == 5 then
      local file, dir, first = string.match(v, firstLevelReg)
      -- dump(string.match(v, firstLevelReg))
      local temp = readJsonFile(file)
      temp.id = first
      findFiles(temp, dir, first)
      -- because lua starts counting at 1...
      map[first] = tableSize(res) + 1
      
      -- dump(moduleAvailable(temp))
      if moduleAvailable(temp) then
        table.insert(res, temp)
      end
    elseif depth == 6 then
      local file, dir, first, second = string.match(v, secondLevelReg)
      if map[first] ~= nil then
        -- dump(string.match(v, secondLevelReg))
        local temp = readJsonFile(file)
        temp.id = second
        findFiles(temp, dir, second)

        -- because the files list is sorted the parent should have run bevor this
        -- now, if there is no entry in the res list, we either have an error, or the parent isn't available, making this module not availabl either
        if res[map[first]] ~= nil and moduleAvailable(temp) then
           if res[map[first]].children == nil then
            res[map[first]].children = {}
          end
          table.insert(res[map[first]].children, temp)
        end
      end
    end

  end
  return res
end


local function sendStates () 
  guihooks.trigger('registerNewMenuStates', getStates())
end

M.requestStates = sendStates
M.getStates = getStates

return M