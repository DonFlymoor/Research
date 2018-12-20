M = {}

-- the vehicle to test with
local physicsFPS  = 2000
local physicsSteps = 100 -- max physics steps do *NOT* increase beyond this point
local gfxSteps   = 40
local currentObjects = 0
local version = '0.4'
local BeamEngine = initBeamEngine()

function myBenchStep(testVehicle, n)
    local hp = HighPerfTimer()
    -- spawn n vehicles
    for i=currentObjects + 1, n do
        BeamEngine:spawnObject2(i, testVehicle, '', Vector3(300 * i, 300 * i, 300 * i)) -- this assumes that the object is max. 300 meters high
        currentObjects = currentObjects + 1
    end
    local spawntime = hp:stop()

    -- run the update loop and measure the total time

    local dt = (physicsSteps + 0.1)/ physicsFPS
    hp = HighPerfTimer()
    for i=1,gfxSteps do
        BeamEngine:update(dt, dt, 0)
    end
    local t = hp:stop()
    if BeamEngine:instabilityDetected() then
      log('E', "bananabench", ' *** INSTABILITY ***')
    end
    return spawntime, t
end

local logcache = {}
function benchLog(level, origin, msg, newline)
    if level ~= 'A' and level ~= 'D' and level ~= 'S' then
        table.insert(logcache, {level = level, origin = origin, msg = msg, newline = newline})

        -- record max severity
        if level == 'W' and logcache.max == nil then
            logcache.max = 'warn'
        elseif level == 'E' and (logcache.max == nil or logcache.max == 'warn') then
            logcache.max = 'error'
        end
    end
end

local function getAllVehicles()
    local vehicles = {}
    for _, v in ipairs(FS:findFiles('/vehicles', '*', 0, false, true)) do
        if v ~= '/vehicles/common' then
            table.insert(vehicles, string.match(v, '/vehicles/(.*)'))
        end
    end
    return vehicles
end

function benchPhysics(vehicles, vehicleMin, vehicleMax)
    if BeamEngine == nil then
        log('E', "bananabench", 'error loading libbeamng')
        return
    end
    vehicles = vehicles or {'pickup'}
    vehicleMin = vehicleMin or 1
    vehicleMax = vehicleMax or VehiclesToTest or 20
    local res = {
        hw = hw,
        --vehicles = vehicles,
        physicsFPS = physicsFPS,
        physicsSteps = physicsSteps,
        gfxSteps = gfxSteps,
        version=version,
        tests = {},
        vehicleMax=vehicleMax,
        vehicleMin=vehicleMin,
        time = 0,
    }

    -- to disable dynamic collision:
    --Settings.dynamicCollision = false

    logcache = {}
    local timeTotalSum = 0
    for k,vehicle in pairs(vehicles) do
        local testVehicle = 'vehicles/' .. vehicle .. '/'
        local test = {}

        -- init
        BeamEngine:deleteAllObjects()
        local obj = BeamEngine:spawnObject2(k, testVehicle, '', Vector3(300 * k, 300 * k, 300 * k))
        local nodecount = obj:getNodeCount()
        local beamcount = obj:getBeamCount()
        currentObjects = 1

		local skipVehicle = false
        if beamcount == nil or nodecount == nil then
            log('E', "bananabench", 'unable to get beam or node count: vehicle failed to spawn?')
            skipVehicle = true
        end

		if not skipVehicle then
			print(' *** ' .. vehicle .. ' ***')
			test.maxMbeams = 0
			test.version = 2
			test.maxRealtimeVehicles = 0
			test.tests = {}


			-- test start
			local allTestsTime = 0
			local allTestsSpawnTime = 0
			print(' # | Dynamic Collision ON| Dynamic Collision OFF')
			print('   +----------+----------+----------+----------+')
			print('   | MBeams/s | % Realt  | MBeams/s | % Realt  |      ')
			print('---+----------+----------+----------+----------+')
			for n = vehicleMin, vehicleMax, 1 do
				local t = {
					vehicles = n,
					res = {{}, {}}
				}
				for dc = 1, 2 do
					local res = t.res[dc]
					BeamEngine:setDynamicCollisionEnabled(dc == 1)

					-- do a warmup round
					myBenchStep(testVehicle, n)

					local totalTime = 0
					local totalSpawnTime = 0

					--
					local st, lt = myBenchStep(testVehicle, n)
					totalTime = totalTime + lt
					totalSpawnTime = totalSpawnTime + st

					allTestsTime = allTestsTime + totalTime
					allTestsSpawnTime = allTestsSpawnTime + totalSpawnTime

					local totalSteps = physicsSteps * gfxSteps
					local totalBeams = totalSteps * beamcount * n
					local totalNodes = totalSteps * nodecount * n

					-- then calc the stats and output them
					local nodespersec = totalNodes / totalTime
					local Mbeamspersec = (totalBeams / totalTime) / 1000000
					if dc == 1 and Mbeamspersec > test.maxMbeams then
						test.maxMbeams = Mbeamspersec
						test.maxMbeamsNum = n
					end
					if n == 0 then
						nodespersec = 0
						Mbeamspersec = 0
					end
					res.Mbeamspersec = Mbeamspersec
					local percentRealtime = (100 /physicsFPS * totalSteps) / totalTime
					if dc == 1 and percentRealtime > 100 then
						test.maxRealtimeVehicles = math.max(test.maxRealtimeVehicles, n)
					end
					res.percentRealtime = percentRealtime
					res.time = totalTime
					res.spawntime = totalSpawnTime
				end

				local function formatRes(res)
					return lpad(string.format("%0.3f", res.Mbeamspersec), 8, ' ')  .. ' | ' .. lpad(string.format("%0.2f", res.percentRealtime), 8, ' ')
				end
				--dump(t)
				--local diff = t.res[2].Mbeamspersec / t.res[1].Mbeamspersec
				t.msg = lpad(t.vehicles, 2, ' ') .. " | "  .. formatRes(t.res[1]) .. ' | ' .. formatRes(t.res[2]) .. ' | ' -- .. lpad(string.format("%0.2f", diff * 100), 8, ' ')
				table.insert(test.tests, t)
				print(t.msg)
			end

			timeTotalSum = timeTotalSum + allTestsTime
			test.time = allTestsTime

			print("Max Mbeams/s:   " .. string.format("%0.3f", test.maxMbeams) .. " Mbeams/s")
			res.tests[vehicle] = test
		end
    end



    res.time = timeTotalSum
    print("")
    print(" BANANAA!!!")
    print(" .______,# ")
    print(" \\ -----'/ ")
    print("  `-----' ")
    --dump(res)
    return res
end

M.physics = benchPhysics
M.getAllVehicles = getAllVehicles

return M
