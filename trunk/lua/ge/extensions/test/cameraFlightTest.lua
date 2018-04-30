-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'cameraFlightTest'
local levels = require("core/levels")

-- Test parameters
local movementSpeed = 70
local rotationSpeed = 0.5
local lookingDirection = vec3(-1,-1,0)
local waypointInterpRes = 100
local cameraHeight = 30
local equalDelta = movementSpeed * 0.5
local framesPerBlock = 60
local slowdownToLastBuild = 1.1
local slowdownToAverage = 1.3
local levelsToSkip = {
template = 1, italy = 1, autotest = 1, groundmodeltest = 1, openDriveTest = 1, smallgrid = 1, smallgrid_aitest = 1, smallgrid_soundtest = 1, temp = 1, the_void = 1, utah_offroad_park = 1}
-- Parameters for multiple levels
local allTestResults = {}
local mapNames = {}
local mapCounter = 1
local currentDt = -1
local firstLoaded = true
local gotAllLevels = false

local camera = nil
local waypoints = {}
local waypointIndex = 1
local initDone = false
local piInRadians = math.pi/180
local direction = Point3F(0,0,0)
local terrainName = ""
local noTerrain = false

local vehicleDeleted = false
local testDone = false
local frameInfos = {}

local function writeJsonFile(filename, data)
	local header = {version = 1}
	data["header"] = header
	
	if serializeJsonToFile(filename, data, true) then
		log('I', logTag, "Creation of file \"" .. filename .. "\" successful")
	else
		log('E', logTag, "Creation of file \"" .. filename .. "\" failed")
	end
end

local function saveTestsToJsonFile()
	
	-- Save json-file
	local fileName = "performanceTest.json"
	log('I', logTag, "Saving tests to file \"" .. fileName .. "\" now")
	writeJsonFile(fileName, allTestResults)
end

-- Calculates the frameblock of length "framesPerBlock" with the highest average frametime
local function slowestFrameBlock(frameInfos)
	local maximumIndex = -1
	local maximumAverage = -1
	local slowestBlockCamPos = nil
	local slowestBlockCamRot = nil
	
	for i = 1, table.getn(frameInfos) do
	
		-- Break if the index would go out of bounds
		if i+framesPerBlock > table.getn(frameInfos) then
			break
		end

		-- Compute average of next 60 frames
		local average = 0
		for i2 = i,i+framesPerBlock do
			average = average + frameInfos[i2].frameTime
		end
		average = average / framesPerBlock
		
		
		if average > maximumAverage then
			maximumAverage = average
			maximumIndex = i
			slowestBlockCamPos = frameInfos[i + framesPerBlock/2].position
			slowestBlockCamRot = frameInfos[i + framesPerBlock/2].rotation
		end
	end
	
	return maximumIndex, maximumAverage, slowestBlockCamPos, slowestBlockCamRot
end

local function compareTests(newTest, oldTest, resultFilename)
	local separator = "---------------------------------------------------------"
	local separator2 = "*********************************************************"
		
	log('I', logTag, separator2)
	log('I', logTag, "Test Comparison")
	log('I', logTag, separator2)
	
	local allComparisonResults = {}
		
	for _,name in ipairs(mapNames) do
		local comparisonResult = {}
	
		local test1 = newTest[name]
		local test2 = oldTest[name]
		
		if test1 and test2 then
			
			-- Check if the parameters are the same for both tests
			if test1.mapName ~= test2.mapName then log('W', logTag, "Different Maps") end
			if test1.waypointInterpRes ~= test2.waypointInterpRes then log('W', logTag, "Different number of waypoints") end
			if test1.movementSpeed ~= test2.movementSpeed then log('W', logTag, "Different movement speeds") end
			if test1.rotationSpeed ~= test2.rotationSpeed then log('W', logTag, "Different rotation speeds") end
			if test1.cameraHeight ~= test2.cameraHeight then log('W', logTag, "Different camera heights") end
			
			log('I', logTag, "Test of map " .. test1.mapName)
			log('I', logTag, "New test from " .. test1.date)
			log('I', logTag, "Old test from " .. test2.date)
			comparisonResult.mapName = test1.mapName
			comparisonResult.newTestDate = test1.date
			comparisonResult.oldTestDate = test2.date
			
			-- Compare total time
			log('I', logTag, separator)
			log('I', logTag, "Total time taken for the test in seconds")
			log('I', logTag, "New Test:\t" .. test1.totalTime)
			log('I', logTag, "Old Test:\t" .. test2.totalTime)
			log('I', logTag, "Difference:\t" .. math.abs(test2.totalTime - test1.totalTime))
			log('I', logTag, separator)	
			comparisonResult.newTestTime = test1.totalTime
			comparisonResult.oldTestTime = test2.totalTime
			
			-- Compare number of frames
			log('I', logTag, "Total frames for the test")
			log('I', logTag, "New Test:\t" .. test1.numberOfFrames)
			log('I', logTag, "Old Test:\t" .. test2.numberOfFrames)
			log('I', logTag, "Difference:\t" .. math.abs(test2.numberOfFrames - test1.numberOfFrames))
			log('I', logTag, separator)
			comparisonResult.newTestFrames = test1.numberOfFrames
			comparisonResult.oldTestFrames = test2.numberOfFrames
			
			-- Compare average frame times
			log('I', logTag, "Average frame time in seconds")
			log('I', logTag, "New Test:\t" .. test1.averageTime)
			log('I', logTag, "Old Test:\t" .. test2.averageTime)	
			local timeDiff = test1.averageTime - test2.averageTime
			if timeDiff < 0 then
				log('I', logTag, "The new Test was on average faster by:\t" .. math.abs(timeDiff) .. " seconds.")
			else
				log('I', logTag, "The old Test was on average faster by:\t" .. math.abs(timeDiff) .. " seconds.")
				
				if (test1.averageTime / test2.averageTime) > slowdownToLastBuild then
					log('E', logTag, "The new test was slower by a factor of " .. (test1.averageTime / test2.averageTime))
				end
			end
			log('I', logTag, separator)
			comparisonResult.newTestAverage = test1.averageTime
			comparisonResult.oldTestAverage = test2.averageTime
			comparisonResult.rateAverageOldToNew = (test1.averageTime / test2.averageTime)
			
			-- Calculate longest frame block
			log('I', logTag, "Longest block of " .. framesPerBlock .. " frames")
			log('I', logTag, "New Test: Frame " .. test1.slowestBlockIndex .. " to " .. test1.slowestBlockIndex + framesPerBlock .. " took " .. test1.slowestBlockTime .. " seconds on average.")
			log('I', logTag, "Old Test: Frame " .. test2.slowestBlockIndex .. " to " .. test2.slowestBlockIndex + framesPerBlock .. " took " .. test2.slowestBlockTime .. " seconds on average.")
			log('I', logTag, separator)
			log('I', logTag, separator2)
			comparisonResult.newTestLongestBlock = {test1.slowestBlockIndex, test1.slowestBlockTime}
			comparisonResult.oldTestLongestBlock = {test2.slowestBlockIndex, test2.slowestBlockTime}
			
			allComparisonResults[name] = comparisonResult
		
		else
			log('E', logTag, "No test of map " .. name .. " found")
		end
	end
	
	local header = {version = 1}
	allComparisonResults["header"] = header
	
	-- Write comparison result to file
	writeJsonFile(resultFilename, allComparisonResults)
end

local function compareTestsFromJsonFile(file1, file2, resultFilename)
	local test1 = readJsonFile(file1)
	if not test1 then
		log('W', logTag, "No json-file \"" .. file1 .. "\" found.")
		return
	end
	
	local test2 = readJsonFile(file2)
	if not test2 then
		log('W', logTag, "No json-file \"" .. file2 .. "\" found.")
		return
	end
	
	compareTests(test1, test2, resultFilename)
end

local function loadLevel(levelname)
	-- Reset stuff for the new loaded level
	currentDt = -1
	testDone = false
	waypoints = {}
	waypointIndex = 1
	vehicleDeleted = false
	initDone = false
	noTerrain = false
	
	log('I', logTag, "Loading level " .. levelname)
	beamng_cef.startLevel('levels/'.. levelname ..'/main')
end

local function endTest()
	local testResult = {}
  
	-- Calculate average frame time
	local sum = 0
	for index, info in ipairs(frameInfos) do
		sum = sum + info.frameTime
	end
	
	local averageTime = sum / table.getn(frameInfos)

	log('I', logTag, "Test ran for " .. table.getn(frameInfos) .. " frames.")
	log('I', logTag, "Average frame time in seconds: " .. averageTime)
	log('I', logTag, "Total frame time in seconds: " .. sum)
	
	testResult.averageTime = averageTime
	testResult.totalTime = sum
	testResult.numberOfFrames = table.getn(frameInfos)
	testResult.date = os.date("%c", os.time())
	
	-- Calculate the slowest Block of frames
	local slowestBlockIndex, slowestBlockTime, slowestBlockCameraPos, slowestBlockCameraRot = slowestFrameBlock(frameInfos)
	testResult.slowestBlockIndex = slowestBlockIndex
	testResult.slowestBlockTime = slowestBlockTime
	testResult.slowestBlockCamera = {position = slowestBlockCameraPos, rotation = slowestBlockCameraRot}
	testResult.rateSlowestToAverage = (slowestBlockTime / averageTime)
	
	frameInfos = {}
	
	-- Save settings
	testResult.mapName = mapNames[mapCounter]
	testResult.waypointInterpRes = waypointInterpRes
	testResult.movementSpeed = movementSpeed
	testResult.rotationSpeed = rotationSpeed
	testResult.cameraHeight = cameraHeight
			
	allTestResults[mapNames[mapCounter]] = testResult
	mapCounter = mapCounter + 1
	
	saveTestsToJsonFile()
	
	-- Start next map or if the maps are all done, compare to older test
	if mapCounter > table.getn(mapNames) then
	--if mapCounter > 1 then
		
		compareTestsFromJsonFile("performanceTest.json", "lastPerformanceTest.json", "TestComparison.json")
		compareTestsFromJsonFile("performanceTest.json", "20DayOldPerformanceTest.json", "TestComparison20Days.json")
		log('I', logTag, "Return value is " .. 0)
		serverConnection.disconnect()
		shutdown(0)
	else
		loadLevel(mapNames[mapCounter])
	end
	
end

local function scale(point, scale)
	local result = Point3F(0,0,0)
	result.x = point.x * scale
	result.y = point.y * scale
	result.z = point.z * scale
	return result
end

-- Check if two points are roughly the same
local function circaEqual(a, b)
	return 	a.x < (b.x + equalDelta) and a.x > (b.x - equalDelta) and 
			a.y < (b.y + equalDelta) and a.y > (b.y - equalDelta) and 
			a.z < (b.z + equalDelta) and a.z > (b.z - equalDelta)
end

-- Rotate a 2d point around the origin by angle
local function rotate(x, y, angle)
	local radiansAngle = angle * piInRadians
	local rotatedX = math.cos(angle) * x - math.sin(angle) * y
	local rotatedY = math.sin(angle) * x + math.cos(angle) * y
 
	return rotatedX, rotatedY
end

-- Calculate all the waypoints between given edge points
local function calcWaypoints(terrain, edgePoints)
	local result = {}
	for index=1,table.getn(edgePoints)-1 do
		for factor=1,waypointInterpRes do
			local pointA = scale(edgePoints[index], 1-factor/waypointInterpRes)
			local pointB = scale(edgePoints[(index % table.getn(edgePoints)) + 1], factor/waypointInterpRes)
			local waypoint = pointA + pointB
			waypoint.z = terrain:getHeight(waypoint) + cameraHeight
			table.insert(result, waypoint)
		end
	end
	
	return result
end

local function onWorldReadyState(state)
	if state == 2 then
		currentDt = 0
	end
end

local function onPreRender(dt, simdt, rawdt)
	currentDt = (currentDt >= 0 and currentDt + dt) or currentDt

	-- Wait a few frames to skip a level with no terrain. Or else the next level won't be loaded properly
	if not firstLoaded and noTerrain and currentDt > 10 then
		mapCounter = mapCounter + 1
		dump(mapCounter)
		loadLevel(mapNames[mapCounter])
	end

	--Wait 200 frames with the movement because the dt is much too high beforehand (Also for loading first level)
	if camera and initDone and not testDone and currentDt > 10 then
    
		--Load the first level.
		if firstLoaded then
			firstLoaded = false
			loadLevel(mapNames[mapCounter])
			return
		end

		-- Calculate direction
		local direction = (waypoints[waypointIndex] - camera:getPosition())
		direction:normalize()
		direction = direction * Point3F(movementSpeed,movementSpeed,movementSpeed)
			
		-- Calculate new position
		local deltaVelocity = direction * Point3F(rawdt,rawdt,rawdt)
		local newPos = camera:getPosition() + deltaVelocity

		-- Calculate rotation
		local rotatedX, rotatedY = rotate(lookingDirection.x, lookingDirection.y, rotationSpeed * dt)
		lookingDirection.x = rotatedX
		lookingDirection.y = rotatedY
		local rot = quatFromDir(lookingDirection)

				
		-- Change to the next waypoint, if the waypoint is reached
		if circaEqual(camera:getPosition(), waypoints[waypointIndex]) then
			waypointIndex = (waypointIndex % table.getn(waypoints)) + 1
			if waypointIndex == 1 then
				testDone = true
			end
		end

		-- Delete the vehicle
		if not vehicleDeleted then
			vehicleDeleted = true
			local vehicle = be:getPlayerVehicle(0)
			if vehicle then
				vehicle:delete()
				log('I', logTag, "Vehicle deleted")
			end
		end
		
		-- Save frame time, position, rotation
		table.insert(frameInfos, {frameTime = rawdt, rotation = {x=rot.x, y=rot.y, z=rot.z, w=rot.w}, position = {x=newPos.x, y=newPos.y, z=newPos.z}})
		
		-- Set position and rotation
		camera:setPosRot(newPos.x, newPos.y, newPos.z, rot.x, rot.y, rot.z, rot.w)
		
		-- End of test
		if testDone then
			endTest()
		end
	end
end

-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
  log('I', logTag, "initialized")
  registerCoreModule("test_cameraFlightTest")
end

local function onClientStartMission()
	log('I', logTag, "module loaded")

	-- Get list off all levels
	if not gotAllLevels then
		for k,v in ipairs(core_levels.getList()) do
			if v.size and levelsToSkip[v.levelName] == nil and v.levelName == 'GridMap' then
				table.insert(mapNames, v.levelName)
			end	
		end
		log('I', logTag, "Found " .. table.getn(mapNames) .. " levels")
		gotAllLevels = true
	end

	-- disable vsync and FPS limiter
	settings.setState({FPSLimiterEnabled = false}, true)
	settings.setState({vsync = 0}, true)

	local game = commands.getGame()
	if not game then 
		log('E', logTag, "No game found")
		return 
	end

	camera = commands.getCamera(game)
	if not camera then 
		log('E', logTag, "No camera found")
		return 
	end
	
	initDone = true	

	local terrains = scenetree.findClassObjects("TerrainBlock")
	if not terrains[1] then 
		log('E', logTag, "No terrain found.")
		noTerrain = true		
		return
	end

	terrainName = terrains[1]	
	
	local terrain = scenetree.findObject(terrains[1])	
	local mapSize = terrain:getWorldBlockSize()
	print("Map size: ", mapSize)
	
	-- Add waypoints at the corners of the map
	local edgePoints = {}
	table.insert(edgePoints, Point3F((mapSize/2-10), (mapSize/2-10), 0))
	table.insert(edgePoints, Point3F(-(mapSize/2-10), -(mapSize/2-10), 0))
	table.insert(edgePoints, Point3F((mapSize/2-10), -(mapSize/2-10), 0))
	table.insert(edgePoints, Point3F(-(mapSize/2-10), (mapSize/2-10), 0))
	table.insert(edgePoints, Point3F((mapSize/2-10), (mapSize/2-10), 0))
	
	waypoints = calcWaypoints(terrain, edgePoints)

	-- Set camera position
	commands.setFreeCamera()
	local startPoint = edgePoints[1]
	startPoint.z = terrain:getHeight(startPoint) + cameraHeight
	
	-- Calculate rotation
	local rot = quatFromDir(lookingDirection)
	
	-- Set position and rotation
	camera:setPosRot(startPoint.x, startPoint.y, startPoint.z, rot.x, rot.y, rot.z, rot.w)
	print("Starting position: ", camera:getPosition())
end


local function onExtensionUnloaded()
	log('I', logTag, "module unloaded")
end

M.onInit = onInit
M.onClientStartMission = onClientStartMission
M.onExtensionUnloaded = onExtensionUnloaded
M.onPreRender = onPreRender
M.onWorldReadyState = onWorldReadyState

return M
