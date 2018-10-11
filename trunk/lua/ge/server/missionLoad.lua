local M = {}

local logTag = "missionLoad.lua"

--$MissionLoadPause = 5000; -> not used anywhere

--tested && working
local function clearLoadInfo() -- former clearLoadInfo() from levelInfo.cs whose usage has been found only here
  local levelInfo = scenetree.findObject("theLevelInfo") --OR: scenetree.theLevelInfo
  if not levelInfo then
    return
  end
  levelInfo:delete()
  levelInfo.obj = nil --??? or how to delete whole project
end

--[[ works for freeroam
used in missionLoad.cs and server.cs
not used in c++
]]
local function endMission()
  if not scenetree.MissionGroup then
    return
  end

  local missionFilename = getMissionFilename()
  log('I', logTag,"*** Mission ended: "..missionFilename)

  --Inform the game code we're done
  gameManager.onMissionEnded()
    
  clientEndMission(missionFilename)

  if(scenetree.EditorGui) then
    TorqueScript.eval("EditorGui.onClientEndMission();")
  end

  if scenetree.AudioChannelEffects then
    scenetree.AudioChannelEffects:stop(-1.0, -1.0)
  end

  decalManagerClear()

  if scenetree.ClientMissionCleanup then
    scenetree.ClientMissionCleanup:delete()
  end
  
  --delete everything
  scenetree.MissionGroup:deleteAllObjects()
  scenetree.MissionGroup:delete()

  if not scenetree.MissionCleanup then
    return -- correct: no error message?
  end
  scenetree.MissionCleanup:delete()
end

local function sortFiles(f1, f2)
  local matRegEx = "materials.cs$"
  if string.find(f1, matRegEx) and not string.find(f2, matRegEx) then
    return true
  else
    return false
  end
end

--[[
used in: server.lua and used in menuHandlers.ed (has been replaced)
not used in c++
--how to get filePath in Lua?
--]]
local function loadMission(levelPath, isFirstMission)
  levelPath = levelPath:lower()
  if not levelPath:find(".json") and not levelPath:find(".mis") then
    levelPath = levelPath .. 'info.json'
  end
 
  endMission()
 
  log('I', logTag, "*** loading mission: "..levelPath)

  TorqueScript.setVar("$missionRunning", "false")
  setMissionFilename(levelPath:gsub("//", "/"))
  
  local levelDir = path.dirname(levelPath).."/"
  setMissionPath(levelDir)

  TorqueScript.setVar("$Server::LoadFailMsg", "")

  -- clear LevelInfo so there is no conflict with the actual
  -- LevelInfo loaded in the level
  clearLoadInfo()

  --Create the mission group off the ServerGroup
  local serverGroup = scenetree.findObject("ServerGroup")
  if not serverGroup then
    log('E', logTag, "ServerGroup not found")
    return
  end
  TorqueScript.setVar("$instantGroup", tostring(serverGroup:getID()))

  local materialfiles = FS:findFilesByPattern(levelDir, "*.cs", -1, true, false)
  -- materials.cs files need to be executed first
  table.sort(materialfiles, sortFiles)
  --dump(materialfiles)
  for  _, csfile in pairs(materialfiles) do
    if FS:fileExists(csfile) then
      TorqueScript.exec(csfile)
    end
  end

  -- if the scenetree folder exists, try to load it
  if FS:directoryExists(levelDir .. '/main/') then
    Sim.deserializeObjectsFromDirectories(levelDir .. '/main/', '*.level.json', true)
  else
    -- backward compatibility: single file mode
    local json_main = levelDir .. '/main.level.json'
    if FS:fileExists(json_main) then
      Sim.deserializeObjectsFromFile(json_main, true)
    else
      -- backward compatibility: single .mis file mode
      -- Make sure the mission exists
      if not FS:fileExists(levelPath) then
        log('E', logTag, "Could not find mission: "..levelPath)
        return
      end
      TorqueScript.exec(levelPath)
    end
  end

  if not scenetree.MissionGroup then
    log('E', logTag, "MissionGroup not found")
    return
  end

  --[[Mission cleanup group.  This is where run time components will reside.
  The MissionCleanup group will be added to the ServerGroup.]]
  local misCleanup = createObject("SimGroup")
  if not misCleanup then
    log('E', logTag, "could not create misCleanup SimGroup")
    return
  end
  misCleanup:registerObject("MissionCleanup")

  --Make the MissionCleanup group the place where all new objects will automatically be added.
  TorqueScript.setVar("$instantGroup", misCleanup:getID())

  log('I', logTag, "*** Mission loaded: "..getMissionFilename())

  --Start all the clients in the mission
  TorqueScript.setVar("$missionRunning", 1)

  -- be:physicsStartSimulation()

  if scenetree.AudioChannelEffects then
    scenetree.AudioChannelEffects:play(-1.0, -1.0)
  end  

  local clientCleanup = createObject("SimGroup")
  if not clientCleanup then
    log('E', logTag, "could not create clientCleanup SimGroup")
    return
  end
  clientCleanup:registerObject("ClientMissionCleanup")

  gameManager.onMissionLoaded()

  -- notify the map
  map.onMissionLoaded()
end

--[[works for freeroam
]]
local function reset()
  --TorqueScript.call("resetMission")
  log('I', logTag, "*** Mission reset: "..getMissionFilename())

  if not scenetree.MissionCleanup then
    log('E', logTag, "MissionCleanup not found")
    return
  end
  scenetree.MissionCleanup:delete()

  TorqueScript.setVar("$instantGroup", scenetree.serverGroup:getID())
  local misCleanup = createObject("SimGroup")
  if not misCleanup then
    log('E', logTag, "could not create SimGroup")
    return
  end
  misCleanup:registerObject("MissionCleanup")

  --Make the MissionCleanup group the place where all new objects will automatically be added.
  TorqueScript.setVar("$instantGroup", misCleanup:getID())

end

M.reset = reset
M.loadMission = loadMission
M.endMission = endMission
return M