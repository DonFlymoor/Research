local M = {}

local forLoad = {}
local forLoadLevel = {}

local inited = false
local inLevel = false

local function onFirstUpdate()
    SFXFMODProject.loadBaseBank('art/sound/FMOD/Desktop/Main.bank', true)
    SFXFMODProject.loadBaseBank('art/sound/FMOD/Desktop/UI.bank', true)
    SFXFMODProject.loadBaseBank('art/sound/FMOD/Desktop/Vehicle.bank', true)
    inited = true

    for i, v in ipairs(forLoad) do
        SFXFMODProject.loadBaseBank(v)
    end
    forLoad = {}
end

local function onSerialize()
    SFXFMODProject.clearBaseBanks();
end

local function registerBaseBank(path)
    if inLevel then        
        log("E", "registerBaseBank", 'Not posible to register base banks inside a level')
        return
    end

    if inited then
         SFXFMODProject.loadBaseBank(path)
    else
        table.insert(forLoad, path)
    end
end

local function loadLevelBank(path)
    if not inLevel then        
        table.insert(forLoadLevel, path)
        return
    end

    local project = SFXFMODProject()
    project.fileName = String(path)
    project:registerObject('')
    scenetree.DataBlockGroup:addObject(project) -- TODO find a way to do it implicitly
end

local function onClientPreStartMission()
    log("I", "loadLevelBank", "Loaded default level banks")
    inLevel = true

    loadLevelBank("art/sound/FMOD/Desktop/Ambient_Generic.bank")    
    loadLevelBank("art/sound/FMOD/Desktop/Ambient_Maps.bank")    
    loadLevelBank("art/sound/FMOD/Desktop/Ambient_Single_Animals.bank")

    for i, v in ipairs(forLoadLevel) do        
        loadLevelBank(v)
    end
    forLoadLevel = {}
end

local function onClientEndMission()
    inLevel = false
end

M.onFirstUpdate = onFirstUpdate
M.onSerialize = onSerialize
M.registerBaseBank = registerBaseBank
M.loadLevelBank = loadLevelBank

M.onClientPreStartMission = onClientPreStartMission
M.onClientEndMission = onClientEndMission

return M
