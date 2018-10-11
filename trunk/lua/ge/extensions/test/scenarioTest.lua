-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'scenarioTest'
local scenario_scenarios = require("scenario/scenarios")
local returnValue = 0

-- Parameters for multiple levels
local scenarios = {}
local scenarioCounter = 0
local frameCounter = 1
local scenariosLoaded = false

local excludedScenarios = {

}

local function writeJsonFile(filename, data)
	local header = {version = 1}
	data["header"] = header

	if serializeJsonToFile(filename, data, true) then
		log('I', logTag, "Creation of file \"" .. filename .. "\" successful")
	else
		log('E', logTag, "Creation of file \"" .. filename .. "\" failed")
	end
end

local function writeErrorsToFile()
	local outfilename = "scenarioTest.json"
	log('I', logTag, "Writing errors to file")
	io.input("beamng.log")

	local scenarioErrors = {}
	local currentScenario = ""

    while true do
		local line = io.read()
		if line == nil then break end

		if (string.match(line, "|E|") or string.match(line, "|GELua." .. logTag .. "|")) and not string.match(line, "|GELua." .. logTag .. "|initialized") then

			-- If a new scenario is loaded, set the currentScenario
			if string.match(line, "|GELua." .. logTag .. "|Load scenario: ") then
				-- Get scenario name
				local words = {}
				for word in line:gmatch("%S+") do table.insert(words, word) end
				currentScenario = words[table.getn(words)]
				scenarioErrors[currentScenario] = {}
			end

			-- If there is an error, add it to the errors of the current scenario
			if string.match(line, "|E|") then
				if scenarioErrors[currentScenario] then
					table.insert(scenarioErrors[currentScenario], line)
					returnValue = 1
				end
			end
		end
    end

	-- Write output file
	writeJsonFile(outfilename, scenarioErrors)

	log('I', logTag, "Created output file " .. outfilename)
end

local function onPreRender(dt, simdt, rawdt)
	-- After 300 frames, load the next scenario in the list
	if frameCounter > 300 and scenariosLoaded then
		scenarioCounter = scenarioCounter + 1
		frameCounter = 1

		writeErrorsToFile()

		if scenarioCounter > table.getn(scenarios) then
		--if scenarioCounter > 79 then
			log('I', logTag, "End of test")
			log('I', logTag, "Return value is " .. returnValue)
			shutdown(returnValue)
			return
		end

		--Load the next scenario
		local scenario = scenarios[scenarioCounter]
		if scenario then
			if scenario.scenarioName then
				log('I', logTag, "Load scenario: " .. scenario.scenarioName)
				log('I', logTag, "Scenario number: " .. scenarioCounter)
			else
				log('I', logTag, "No scenario name for scenario " .. scenarioCounter)
			end
			scenario_scenariosLoader.start(scenario)
		else
			log('W', logTag, "No scenario found")
		end
		return
	end
	frameCounter = frameCounter + 1
end

-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
	log('I', logTag, "initialized")
	registerCoreModule("test_scenarioTest")
end

local function initializeScenarioList()
  log('I', logTag, "module loaded")
	local allScenarios = scenario_scenariosLoader.getList()
  log('I', logTag, "Found " .. table.getn(allScenarios) .. " scenarios in total.")
  for k,v in pairs(allScenarios) do
    if tableContains(excludedScenarios, v.scenarioName) then
      log('I', logTag, "Excluded scenario '" .. v.scenarioName "'")
    else
      table.insert(scenarios, v)
    end
  end
  log('I', logTag, "Found " .. table.getn(scenarios) .. " scenarios that need to be tested!")
	scenariosLoaded = true
end

local function onClientStartMission()
	if not scenariosLoaded then
		initializeScenarioList()
	end
end

local function onExtensionUnloaded()
	log('I', logTag, "module unloaded")
end

M.onInit = onInit
M.onClientStartMission = onClientStartMission
M.onExtensionUnloaded = onExtensionUnloaded
M.onPreRender = onPreRender

return M
