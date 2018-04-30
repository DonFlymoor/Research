-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'mapTest'

local settings = require("settings")
local returnValue = 0

-- Parameters for multiple levels
local mapNames = {}
local mapCounter = 0
local frameCounter = 1
local gotAllLevels = false

local quality = 1
local qualitySettings = {}
local qualityLevels = {"Custom", "Lowest", "Low", "Normal", "High"}

local levelsToSkip = {template = 1, italy = 1, west_coast_usa = 1}
local first = true

local function writeJsonFile(filename, data)
	local header = {version = 1}
	data["header"] = header
	
	if serializeJsonToFile(filename, data, true) then
		log('I', logTag, "Creation of file \"" .. filename .. "\" successful")
	else
		log('E', logTag, "Creation of file \"" .. filename .. "\" failed")
	end
end

local function changeQualityLevel(level)

	if not qualitySettings then
		log('E', logTag, "No quality settings")
		return
	end
	
	for parameter, value in pairs(qualitySettings[level]) do
		settings.setValue(parameter, value)
	end
end

local function endTest()
	local outfilename = "mapTest.json"
	log('I', logTag, "End of test")
	io.input("beamng.log")
	
	local mapErrors = {}
	local currentMap = ""
	local currentQuality = ""
	local addErrors = false
	
    while true do
		local line = io.read()
		if line == nil then break end
	  
		if (string.match(line, "|E|") or string.match(line, "|GELua." .. logTag .. "|")) and not string.match(line, "|GELua." .. logTag .. "|initialized") then
		
			-- If a new map is loaded, set the currentMap
			if string.match(line, "|GELua." .. logTag .. "|Map and Quality level: ") then
				-- Get map name
				local words = {}
				for word in line:gmatch("%S+") do table.insert(words, word) end
				currentMap = words[table.getn(words)-1]
				currentQuality = words[table.getn(words)]
				mapErrors[currentMap .. " " .. currentQuality] = {}
				addErrors = true
			end
			
			if string.match(line, "|GELua." .. logTag .. "|Load level: ") then
				addErrors = false
			end

			-- If there is an error, add it to the errors of the current map
			if string.match(line, "|E|") and addErrors then
				if mapErrors[currentMap .. " " .. currentQuality] then
					table.insert(mapErrors[currentMap .. " " .. currentQuality], line)
					returnValue = 1
				end
			end
		end
    end
	
	-- Write output file
	writeJsonFile(outfilename, mapErrors)
	
	log('I', logTag, "Created output file " .. outfilename)
end

local function onPreRender(dt, simdt, rawdt)
	-- After 200 frames, load the next map in the list
	if frameCounter > 400 then
		frameCounter = 1
		
		if quality < 5 and not first then
			quality = quality + 1
			log('I', logTag, "Map and Quality level: " .. mapNames[mapCounter] .. " " .. qualityLevels[quality])
			changeQualityLevel(quality)
		else
			first = false
			quality = 1
			mapCounter = mapCounter + 1
			if mapCounter > table.getn(mapNames) then
			--if mapCounter > 2 then
				endTest()
				log('I', logTag, "Return value is " .. returnValue)
				shutdown(returnValue)
				return
			end
			
			--Load the next map
			local mapName = mapNames[mapCounter]
			if mapName then			
				log('I', logTag, "Load level: " .. mapName)
				beamng_cef.startLevel('levels/'.. mapName ..'/main.level.json')
			else
				log('W', logTag, "No map found")
			end
		end
		return
	end
	frameCounter = frameCounter + 1
end

-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
	log('I', logTag, "initialized")
	-- Get list of all levels
	if not gotAllLevels then
		for k,v in ipairs(core_levels.getList()) do
			if v.size and levelsToSkip[v.levelName] == nil then
				table.insert(mapNames, v.levelName)
			end	
		end
		log('I', logTag, "Found " .. table.getn(mapNames) .. " levels")
		gotAllLevels = true
	end
	
	qualitySettings = readJsonFile("ui/modules/options/settingsPresets.json")
	if not qualitySettings then
		log('E', logTag, "No quality settings found")
	end
end

local function onClientStartMission()
end

local function onExtensionUnloaded()
	log('I', logTag, "module unloaded")
end

M.onInit = onInit
M.onClientStartMission = onClientStartMission
M.onExtensionUnloaded = onExtensionUnloaded
M.onPreRender = onPreRender

return M
