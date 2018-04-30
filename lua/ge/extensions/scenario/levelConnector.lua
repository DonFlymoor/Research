local M = {}
local function saveVehicle()
  local veh = be:getPlayerVehicle(0)--get vehicle that drove into trigger see data next: figure out how to transport truck with trailerS
  local vehicleName = string.match(veh:getPath(), "vehicles/([^/]*)/")
  TorqueScript.setVar( '$beamngVehicle', vehicleName )
  local mycolor = beamng_cef.getVehicleColor()
  TorqueScript.setVar("$beamngVehicleColor", mycolor)
  local licenseName = getVehicleLicenseName()
  TorqueScript.setVar( '$beamngVehicleLicenseName', licenseName )   
end

local function onBeamNGTrigger(data)
  if data.event ~= "enter" then return end
  -- trigger that loads a new scenario
  if data.levelLoadScenario then 
    scenario_scenariosLoader.startByPath(data.levelLoadScenario) 
  -- trigger that loads a new level
  elseif data.nextlevel then
     local dir = FS:openDirectory('levels')
      if dir then
        if FS:directoryExists('levels/'..data.nextlevel) then 
          if not data.spawnpoint then data.spawnpoint = "" end
          if data.nextlevel:find(".main.level.json") then
            data.nextlevel = data.nextlevel:gsub(".main.level.json","")
          end
          setSpawnpoint.setDefaultSP(data.spawnpoint,data.nextlevel)
          data.nextlevel = "levels/"..data.nextlevel.."/"..data.nextlevel.."./main.level.json"
          saveVehicle()
          beamng_cef.startLevel(data.nextlevel)
        else
          log('E',logTag,data.nextlevel .." not exist")
        end 
      end
  end
end


M.onBeamNGTrigger = onBeamNGTrigger

return M 
