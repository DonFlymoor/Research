-- Highscore System
local M = {}

local highscoreFile = "highscores"
local maxHighScoreCount = 50
local adapter

-- highscores.setScenarioHighscores(123456,"vehicleName","playerName","eca","track","reverse",0)

local function getHighscores()
 local content = readFile(highscoreFile)
  if content == nil or content == "" then
    return {}
  end
  return jsonDecode(content, highscoreFile)
end

local function setHighscores(scores)
 	jsonWriteFile(highscoreFile,scores, false)
 	jsonWriteFile(highscoreFile.."_beautfied",scores, true)
end

local function getScenarioHighscores(levelName, scenarioName, configKey)
	local scores = M.getHighscores()

	if scores == nil then return {} end
	scores = scores[levelName]

	if scores == nil then return {} end
	scores = scores[scenarioName]

	if scores == nil then return {} end
	scores = scores[configKey]


	if scores == nil then return {} end
	table.sort(scores, function (a,b)
      return (a.timeInMillis < b.timeInMillis)
    end)

    for i,v in ipairs(scores) do
    	v.place = i
    end

	return scores
end

-- formats the time given nicely.
local function formatMillis( timeInMillis, addSign )
    if timeInMillis == nil then
        return nil
    end
    if addSign then
        if timeInMillis >= 0 then
            return '+' .. M.formatMillis(timeInMillis,false)
        else
            return '-' .. M.formatMillis(-timeInMillis,false)
        end
    else
        return string.format("%.2d:%.2d.%.3d", (timeInMillis/1000)/60, (timeInMillis/1000)%60, timeInMillis%1000)
    end
end



local function setScenarioHighscores(timeInMillis, vehicleBrand, vehicleName, playerName, levelName, scenarioName, configKey)

	local record = {
		playerName = playerName,
		vehicleBrand = vehicleBrand,
		vehicleName = vehicleName
	}
	return M.setScenarioHighscoresCustom(timeInMillis,record,levelName,scenarioName,configKey)
end

local function setScenarioHighscoresCustom(timeInMillis, record, levelName, scenarioName, configKey)



	local currentHighscores = getScenarioHighscores(levelName,scenarioName,configKey)
	timeInMillis = math.floor(timeInMillis+.5)

	record.detailed = false
    record.timeStamp = os.time()
    record.formattedTimestamp = os.date("!%c",os.time())
    record.timeInMillis = timeInMillis
    record.formattedTime = string.format("%.2d:%.2d.%.3d", (timeInMillis/1000)/60, (timeInMillis/1000)%60, timeInMillis%1000)

    log('I', 'highscores', 'Writing Highscore for '..levelName.."/"..scenarioName.."/"..configKey .. ' = ' .. dumps(record))

	currentHighscores[#currentHighscores+1] = record

	table.sort(currentHighscores, function (a,b)
      return (a.timeInMillis < b.timeInMillis)
    end)

	local newIndex = -1
	for k,v in ipairs(currentHighscores) do
		if v == record then newIndex = k end
	end

	if newIndex > maxHighScoreCount then
		return -1
	end

    local newHighscores = {}
    for i = 1,maxHighScoreCount do
    	newHighscores[i] = currentHighscores[i]
    end


	local scores = M.getHighscores()
	if scores[levelName] == nil then
		scores[levelName] = {}
	end

	if scores[levelName][scenarioName] == nil then
		scores[levelName][scenarioName] = {}
	end

	if scores[levelName][scenarioName][configKey] == nil then
		scores[levelName][scenarioName][configKey] = {}
	end

	scores[levelName][scenarioName][configKey] = newHighscores
	setHighscores(scores)
	return newIndex
end

local function onNewHighScore()

end

local function fillHighscoresTest( )
	--setScenarioHighscores(timeInMillis, vehicleBrand, vehicleName, playerName, levelName, scenarioName, configKey)
	M.setScenarioHighscores(123450,"Ibishu","Name","RuegenwaeldA","levels.east_coast_usa.info.title","town_course_a","standingReverse1")
	M.setScenarioHighscores(223450,"Ibishu","Name","RuegenwaeldB","levels.east_coast_usa.info.title","town_course_a","standingReverse1")
	M.setScenarioHighscores(323450,"Ibishu","Name","RuegenwaeldC","levels.east_coast_usa.info.title","town_course_a","standingReverse1")
	M.setScenarioHighscores(423450,"Ibishu","Name","RuegenwaeldD","levels.east_coast_usa.info.title","town_course_a","standingReverse1")
end


M.setHighscores = setHighscores
M.getHighscores = getHighscores
M.setScenarioHighscores = setScenarioHighscores
M.setScenarioHighscoresCustom = setScenarioHighscoresCustom
M.getScenarioHighscores = getScenarioHighscores

M.getVehicleName = getVehicleName
M.getVehicleBrand = getVehicleBrand

M.fillHighscoresTest = fillHighscoresTest


return M