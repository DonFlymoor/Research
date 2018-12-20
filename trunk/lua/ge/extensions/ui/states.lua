local M = {}

local states = {}

local function findFiles (file, dir, last, luaSpecificPrefix)
  if file.data == nil then
    file.data = {}
  end

  if file.data.js == nil then
    -- only look in the current folder and not in the childs as well otherwise we will be loading js twice
    local js = FS:findFilesByPattern('/' .. dir, '*.js', 0)

    if tableSize(js) > 0 then
      file.data.js = {}
      for _,k in pairs(js) do
        local str = string.gsub(k, '/' .. luaSpecificPrefix, '')
        table.insert(file.data.js, str)
      end
    end
  end
  if file.data.html == nil and file.views == nil and FS:fileExists('/' .. dir .. last .. '.html') then
    file.data.html = string.gsub(dir .. last .. '.html', luaSpecificPrefix, '')
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

local function getMenus (baseFolder, searchFolder)
  local res = {}
  local map = {}
  -- local baseFolder = 'ui2/'
  -- local searchFolder = baseFolder .. 'Systems/Menu/Items/'

  -- local baseFolder = 'ui2/'
  -- local searchFolder = baseFolder .. 'Menu/'

  if baseFolder == nil then
    baseFolder = 'ui2/drive/'
  end

  if searchFolder == nil then
    searchFolder = baseFolder .. 'Content/Menus/'
  end


  -- lucklily for us these files are sorted with directive first and then subdirectives
  local files = FS:findFilesByPattern('/' .. searchFolder, 'info.json', -1, true, false)
  local firstLevelReg = '^/(('.. searchFolder .. '(.*)/)info%.json)$'
  local secondLevelReg = '^/(('.. searchFolder .. '(.*)/(.*)/)info%.json)$'

  for _,v in pairs(files) do
    -- only count subfolders of base folder as depth
    local depth = tableSize(split(v:gsub('/' .. searchFolder, ''), '/'))

    -- dump(v, depth)
    if depth == 2 then
      local file, dir, first = string.match(v, firstLevelReg)
      -- dump(string.match(v, firstLevelReg))
      local temp = jsonReadFile(file)
      temp.id = first
      findFiles(temp, dir, first, baseFolder)
      -- because lua starts counting at 1...
      map[first] = tableSize(res) + 1

      -- dump(moduleAvailable(temp))
      if moduleAvailable(temp) then
        table.insert(res, temp)
      end
    elseif depth == 3 then
      local file, dir, first, second = string.match(v, secondLevelReg)
      if map[first] ~= nil then
        -- dump(string.match(v, secondLevelReg))
        local temp = jsonReadFile(file)
        temp.id = second
        findFiles(temp, dir, second, baseFolder)

        -- because the files list is sorted the parent should have run bevor this
        -- now, if there is no entry in the res list, we either have an error, or the parent isn't available, making this module not availabl either
        if res[map[first]] ~= nil and moduleAvailable(temp) then
           if res[map[first]].data.children == nil then
            res[map[first]].data.children = {}
          end
          table.insert(res[map[first]].data.children, temp)
        end
      end
    end
  end
  -- dump(res)
  return res
end


local function sendMenus (baseFolder, searchFolder)
  guihooks.trigger('registerMenus', getMenus(baseFolder, searchFolder))
end


local function getViews (baseFolder, searchFolder)
  local res = {}
  if baseFolder == nil then
    baseFolder = 'ui2/drive/'
  end

  if searchFolder == nil then
    searchFolder = baseFolder .. 'Content/Views/'
  end

  local files = FS:findFilesByPattern('/' .. searchFolder, 'info.json', 5, true, false)
  local reg = '^/(' .. searchFolder .. '(.*)/info%.json)$'

  for _,v in pairs(files) do
    local infoFile, dir = string.match(v, reg)
    dir = dir:lower()
    local temp = jsonReadFile(infoFile)
    temp.id = dir:gsub('/', '.')
    local last = split(dir, '/')
    findFiles(temp, searchFolder .. dir .. '/', last[#last], baseFolder)
    table.insert(res, temp)
  end

  -- dump(res)
  return res
end

local function sendViews (baseFolder, searchFolder)
  guihooks.trigger('registerViews', getViews(baseFolder, searchFolder))
end

M.requestMenus = sendMenus
M.getMenus = getMenus

M.requestViews = sendViews
M.getViews = getViews


return M