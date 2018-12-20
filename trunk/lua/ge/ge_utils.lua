-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local logTag = "lua"
local function testPoint3F()
  local p1 = Point3F(1,2,3)
  assert(tostring(p1) == "1.000000,2.000000,3.000000", "Point3F: constructor failed")
  assert(math.abs(p1:lenSquared() - 14) < 0.000001, "Point3F:lenSquared failed")

  local p2 = Point3F(3,2,1)
  p2:neg()
  assert(tostring(p2) == "-3.000000,-2.000000,-1.000000", "Point3F:neg failed")

  -- todo: test asPoint2F

  p2:set(5,6,7)
  assert(tostring(p2) == "5.000000,6.000000,7.000000", "Point3F:set failed")

  p2:setAll(8)
  assert(tostring(p2) == "8.000000,8.000000,8.000000", "Point3F:setAll failed")

  p2:zero()
  assert(tostring(p2) == "0.000000,0.000000,0.000000", "Point3F:zero failed")

  p2 = Point3F(3,2,1)
  p2:normalize()
  assert(tostring(p2) == "0.801784,0.534522,0.267261", "Point3F:normalize failed")

  p2 = Point3F(3,2,1)
  p2:normalizeSafe()
  assert(tostring(p2) == "0.801784,0.534522,0.267261", "Point3F:normalizeSafe failed")

  p1 = Point3F(1,2,3)
  p2 = Point3F(5,6,7)
  assert(tostring(p1+p2) == "6.000000,8.000000,10.000000", "Point3F:operator+ failed")

  assert(tostring(p1-p2) == "-4.000000,-4.000000,-4.000000", "Point3F:operator- failed")

  p2 = Point3F(5,6,7)
  assert(tostring(-p2) == "-5.000000,-6.000000,-7.000000", "Point3F:-operator failed")

  p1 = Point3F(1,2,3)
  p2 = Point3F(5,6,7)
  assert(tostring(p1*p2) == "5.000000,12.000000,21.000000", "Point3F:operator* failed")

  assert(tostring(p1/p2) == "0.200000,0.333333,0.428571", "Point3F:operator/ failed")

  p1 = Point3F(1,2,3)
  p2 = Point3F(1,2,3)

  assert(p1 == p2, "Point3F:operator== failed")
end

--TODO's:

-- integrate Luis's actual setField/getField (actual calls commented out right now)
-- support callbacks/events from the c++ side, i.e.

--scenetree.sunsky.onDelete = function(...)
-- do something on delete
--end

--function eventHandler(object, action, parameters)
--scenetree['k'][v[1]](v[2])
--end

-------------------------------------------------------------------------------
-- Scenetree START
scenetree = {}

-- allows users to find Objects via name: scenetree.findObject('myname')
scenetree.findObject = function(objectName)
  return Sim.findObject(objectName)
end

--findObjectByIdAsTable
scenetree.findObjectById = function(objectId)
  return Sim.findObjectById(objectId)
end

-- allows users to find Objects via classname: scenetree.findClassObjects('BeamNGTrigger')
scenetree.findClassObjects = function(className)
  local res_table = {}
  if Lua:findObjectsByClassAsTable(className, res_table) then
    return res_table
  end
  return nil
end

scenetree.getAllObjects = function()
  local res_table = {}
  if Lua:getAllObjects(res_table) then
    return res_table
  end
  return nil
end

-- used on scenetree object lookups
scenetree.__index = function(class_table, memberName)
  --log('E', logTag,'scenetree.__index('..tostring(class_table) .. ', ' .. tostring(memberName)..')')
  --dump(class_table)
  -- 1. deal with methods on the actual lua object: like get/set below
  if getmetatable(class_table)[memberName] then
    return getmetatable(class_table)[memberName]
  end
  if memberName == 'findClassObjects' then
    return getmetatable(class_table).findClassObjects(memberName)
  end
  -- 2. use findObject to collect the object otherwise
  -- TODO: cache the object!
  return getmetatable(class_table).findObject(memberName)
end
-- the scenetree is read only
scenetree.__newindex = function(...) end -- disallow any assignments
-- scenetree is a singleton, no more than one 'instance' at any time, so hardcode the creation
scenetree = setmetatable({}, scenetree)

-- Scenetree END
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------




-- tests from thomas
-- TODO: convert to proper unit-tests :)
function scenetree_tests()
  -- scenetree tests:
  log('D', logTag,"scenetree - test #1 = " .. tostring(scenetree.sunsky.shadowDistance))
  log('D', logTag,"scenetree - test #2 = " .. tostring(scenetree.sunsky:getDeclarationLine()))
  log('D', logTag,"scenetree - test #3 = " .. tostring(scenetree['sunsky']:getDeclarationLine()))

  -- manually find the object, working around scenetree
  local obj = scenetree.findObject('sunsky')
  --dump(obj)

  -- getter tests
  log('D', logTag,"-getter tests")
  log('D', logTag,"shadowDistance - getter #1 = " .. tostring(obj.shadowDistance))
  log('D', logTag,"shadowDistance - getter #2 = " .. tostring(obj['shadowDistance']))
  log('D', logTag,"shadowDistance - getter #3 = " .. tostring(obj:get('shadowDistance')))
  if obj.shadowDistanceNonExisting == nil then
    log('D', logTag,"shadowDistance - getter #4 is nil ")
  else
    log('D', logTag,"shadowDistanceNonExisting - getter #4 ERROR = " .. tostring(obj.shadowDistanceNonExisting))
  end

  -- setter tests
  log('D', logTag,"-setter tests")
  obj:set('shadowDistance', 123)
  obj.shadowDistance = 123
  obj['shadowDistance'] = 123

  -- usage tests
  log('D', logTag,"-usage tests")
  log('D', logTag,">> shadowDistance = " .. tostring(obj.shadowDistance))
  obj.shadowDistance = 123
  log('D', logTag,">> shadowDistance = " .. tostring(obj.shadowDistance))

  -- testing protected fields [canSave]
  log('D', logTag,"-protected fields tests")
  log('D', logTag,">> canSave = " .. tostring(obj.canSave))
  log('D', logTag,">> canSave set to false")
  obj.canSave = false
  log('D', logTag,">> canSave = " .. tostring(obj.canSave))
  obj.canSave = true
  log('D', logTag,">> canSave set to true")

  -- test if function to object forwarding works:
  --log('D', logTag,obj:getDataFieldbyIndex(0, 0, 0))
  log('D', logTag,obj:getDeclarationLine())
  --obj:delete(1,2,3, Point3F(1,2,3), "test")
end

function scenetree_test_fields()
  print('testing fields of "thePlayer": ' .. tostring(scenetree.thePlayer))
  local player = scenetree.thePlayer
  local fields = player:getFields()
  for k, f in pairs(fields) do
    if k ~= 'dataBlock' and k ~= 'parentGroup' then -- why do we need to exclude these?
      local val = player[k]
      if val == nil then
        print(' N ' .. tostring(k) .. ' = NIL [' .. (f.type or 'unknown') .. ']')
      else
        print(' * ' .. tostring(k) .. ' = ' .. tostring(player[k]) .. ' [Types| Lua: ' .. type(val) .. ', C: ' .. (f.type or 'unknown') .. ']')
      end
    else
      print(' x UNSUPPORTED TYPE: ' .. tostring(k) .. ' [' .. (f.type or 'unknown') .. ']')

    end
  end
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function test_GE_fields()

  SimFieldTestObject("TestObj")
  local obj = scenetree.findObject('TestObj')
  --dump(obj)

  value_s32 = -5
  obj.staticFieldS32 = value_s32
  assert( obj.staticFieldS32 == value_s32 )
  obj.protectedFieldS32 = value_s32
  assert( obj.protectedFieldS32 == value_s32 )
  obj.dynFieldS32 = value_s32
  assert( obj.dynFieldS32 == value_s32 )

  local value_f32 = -33.330000000000
  obj.staticFieldF32 = value_f32
  assert( math.abs(obj.staticFieldF32 - value_f32) < 0.0001 )
  obj.protectedFieldF32 = value_f32
  assert( math.abs(obj.protectedFieldF32 - value_f32) < 0.0001 )
  obj.dynFieldF32 = value_f32
  assert( math.abs(obj.dynFieldF32 - value_f32) < 0.0001 )

  local value_f64 = -66.660000000000
  obj.staticFieldF64 = value_f64
  assert( math.abs(obj.staticFieldF64 - value_f64) < 0.0001 )
  obj.protectedFieldF64 = value_f64
  assert( math.abs(obj.protectedFieldF64 - value_f64) < 0.0001 )
  obj.dynFieldF64 = value_f64
  assert( math.abs(obj.dynFieldF64 - value_f64) < 0.0001 )

  value_cstring = "CString"
  obj.staticFieldCString = value_cstring
  assert( obj.staticFieldCString == value_cstring )
  obj.protectedFieldCString = value_cstring
  assert( obj.protectedFieldCString == value_cstring )
  obj.dynFieldCString = value_cstring
  assert( obj.dynFieldCString == value_cstring )

  value_string = String("String")
  obj.staticFieldString = value_string
  assert( obj.staticFieldString == value_string )
  obj.protectedFieldString = value_string
  assert( obj.protectedFieldString == value_string )
  obj.dynFieldString = value_string
  assert( obj.dynFieldString == value_string )

  obj.staticFieldSimObjectPtr = obj
  assert( obj.staticFieldSimObjectPtr.staticFieldString == obj.staticFieldString )
  obj.protectedFieldSimObjectPtr = obj
  assert( obj.protectedFieldSimObjectPtr.staticFieldString == obj.staticFieldString )
  obj.dynFieldSimObjectPtr = obj
  assert( obj.dynFieldSimObjectPtr.staticFieldString == obj.staticFieldString )

  obj:delete()
end

function replace_char(pos, str, r)
  return str:sub(1, pos-1) .. r .. str:sub(pos+1)
end

function testGBitmap()
  --print("testGBitmap...")

  local bitmap = GBitmap()

  -- GBitmap:init( uint width, uint heigt )
    -- create a RGBA image of widthXheight dimension
  bitmap:init(16, 16)
  -- test size
  -- uint GBitmap::getWidth - return the width of the image
  assert( bitmap:getWidth() == 16 )
  -- uint GBitmap::getHeight - return the height of the image
  assert( bitmap:getHeight() == 16 )

  local colorWhite = ColorI(255,255,255,255)
  local colorBlack = ColorI(0, 0, 0, 255)
  assert( colorBlack == colorBlack )
  assert( colorWhite == colorWhite )
  assert( colorBlack ~= colorWhite )

  -- GBitmap:fillColor( ColotI color )
  --    set color for all pixels in the image
  bitmap:fillColor( colorWhite )

  local col = colorBlack

  -- bool GBitmap::setColor( uint pixelAtWidth, uint pixelAtHeight, ColorI color )
  --    set color at requested pixel position.
  --    Return: Bool - false on failed
  bitmap:setColor(8,8, col)

  -- bool GBitmap::getColor( uint pixelAtWidth, uint pixelAtHeight, OUT ColorI color )
  --    set color at requested pixel position.
  --    Return: Bool - false on failed
  --    OUT color - the requested color
  assert( bitmap:getColor( 8, 8, col ) )
  assert( col == colorBlack )
  assert( bitmap:getColor( 0, 0, col ) )
  assert( col == colorWhite )

  --print("testGBitmap... loading/saving")
  local filePath = "test/GBitmap.png"

  -- bool GBitmap::saveFile( string filePath )
  bitmap:saveFile( filePath )
  bitmap:fillColor( ColorI(0, 0, 0, 0) )

  -- bool GBitmap::loadFile( string filePath )
  bitmap:loadFile( filePath )

  assert( bitmap:getColor( 8, 8, col ) )
  assert( col == colorBlack )
  assert( bitmap:getColor( 0, 0, col ) )
  assert( col == colorWhite )
end

function deleteObject(name)
  local sg = scenetree[name]
  if(sg) then
    sg:delete()
  end
end

TorqueScript.call = function( functor, ...)
  local arg = {...}
  local argsStr = ""
  local separator = ""
  for i,v in ipairs(arg) do
    argsStr = argsStr..separator

    if type(v) == 'string' then
      argsStr = argsStr .. '"' .. v .. '"'
    else
      argsStr = argsStr .. tostring(v)
    end

    separator = ','
  end

  --print( functor..'('..argsStr..')' )
  return TorqueScript.eval( 'return '..functor..'('..argsStr..');' )
end

-- TODO: how is this diferent from Torquescript.call?
TorqueScript.callNoReturn = function( functor, ...)
  local arg = {...}
  local argsStr = ""
  local separator = ""
  for i,v in ipairs(arg) do
    argsStr = argsStr..separator

    if type(v) == 'string' then
      argsStr = argsStr .. '"' .. v .. '"'
    else
      argsStr = argsStr .. tostring(v)
    end

    separator = ','
  end

  --print( functor..'('..argsStr..')' )
  return TorqueScript.eval( functor..'('..argsStr..');' )
end

TorqueScript.getVar = function( name )
  return getTSVar( name )
end

TorqueScript.setVar = function( name, value )
  -- booleans need a special care becouse "true" and "false" dont exist on TS
  if value == false then
    value = 0
  elseif value == true then
    value = 1
  end
  setTSVar( name, tostring(value) )
end

function testZIP()

  local zip = ZipArchive()

  -- openArchiveName( pathSrc, mode )
  zip:openArchiveName('testZIP/testZIP.zip', 'w')

  -- addFile( path [, pathInZIP, overrideFile] )
  zip:addFile( 'torque3d.log', 'logs/torque3d.log', true )
  zip:addFile( 'settings/game-settings.ini' )
  zip:addFile( 'settings/cloud/game-settings-cloud.ini' )
  zip:addFile( 'settings/game-settings.cs' )
  zip:close()

  zip = ZipArchive()
  zip:openArchiveName('testZIP/testZIP.zip', 'r')
  local files = zip:getFileList()
  dump(files)
  for i,v in ipairs(files) do
    -- extractFile( pathInZIP [, pathDst ] )
    zip:extractFile( v, 'testZIP/testZIP.zip.content/'..v )
  end
  zip:close()

  zip = ZipArchive()
  zip:openArchiveName('testZIP/testZIP.zip', 'r')
  files = zip:getFileList()
  print("Hash of files in testZIP/testZIP.zip ")
  for i, v in ipairs( files ) do
    print( '  '..zip:getFileEntryHashByIdx(i)..' '..v)
  end
  zip:close()
end

function testHWInfo()
  local mem = memory_info_t()
  if Engine.Platform.getMemoryInfo(mem) then
    local byteToGB = 1 / (1024 * 1024 * 1024)
    print('Memory.osVirtAvailable: '..mem.osVirtAvailable * byteToGB)
    print('Memory.osVirtUsed: '   ..mem.osVirtUsed * byteToGB)
    print('Memory.osPhysAvailable: '..mem.osPhysAvailable * byteToGB)
    print('Memory.osPhysUsed: '   ..mem.osPhysUsed * byteToGB)
    print('Memory.processVirtUsed: '..mem.processVirtUsed * byteToGB)
    print('Memory.processPhysUsed: '..mem.processPhysUsed * byteToGB)
  end

  local cpu = cpu_info_t()
  if Engine.Platform.getCPUInfo(cpu) then
    print('CPU.name: '..cpu.name)
    print('CPU.cores: '..cpu.cores)
    print('CPU.clockSpeed: '..cpu.clockSpeed)
    print('CPU.measuredSpeed: '..cpu.measuredSpeed)
  end

  local gpu = gpu_info_t()
  if Engine.Platform.getGPUInfo(gpu) then
    print('GPU.name: '..gpu.name)
    print('GPU.version: '..gpu.version)
    print('GPU.memoryMB: '..gpu.memoryMB)
  end

  print('OS: '..Engine.Platform.getWindowsVersionName())
end


-- helper function that can determine if an object is part of a simgroup
function prefabIsChildOfGroup(obj, groupName)
  if not obj then
    return false
  end

  local group = scenetree.findObject(groupName)
  if not group then
    return false
  end

  if obj:isChildOfGroup(group.obj) then
    return true
  end

  local parentPrefab = Prefab.getPrefabByChild( obj )
  if parentPrefab and parentPrefab:isChildOfGroup(group.obj) then
    return true
  end
  return false
end


--function testLicensePlate()
  --local v = be:getPlayerVehicle(0)
  --v:createUITexture("@licenseplate", "local://local/ui/simple/licenseplate.html", 128, 64, UI_TEXTURE_USAGE_AUTOMATIC, 1)
  --be:getPlayerVehicle(0):queueJSUITexture("@licenseplate", 'setPlateText("ABCDE");')
  --v:destroyUITexture("@licenseplate")
--end


function createObject(className)
  if _G[className] == nil then
    log('E', 'scenetree', 'Unable to create object: unknown class: ' .. tostring(className))
    return nil
  end
  local obj = _G[className]()
  obj:incRefCount()
  return obj
end

function collisionReloadTest()
  local h = hptimer()
  be:reloadCollision()
  print("reloading the collision took: " .. h:stop() .. ' ms')
end


function vehicleSetPositionRotation(id, px, py, pz, rx, ry, rz, rw)
  local bo = be:getObjectByID(id)
  if bo then
    bo:setPositionRotation(px, py, pz, rx, ry, rz, rw)
  else
    log('E', "vehicleSetPositionRotation", 'vehicle not found: ' .. tostring(id))
  end
end

--[[getVehicleColor
@param vehicleID int, optional
@return vehicle color in form of a string or table
]]
function getVehicleColor(vehicleID)
  local game = scenetree.findObject("Game")
  if not game then return "" end
  local vehicle
  if vehicleID then
    vehicle = scenetree.findObjectById(vehicleID)
  else
    vehicle = scenetree.findObjectById(be:getPlayerVehicle(0):getID()) -- TODO: add a check whether the game is running?
  end

  if not vehicle then
    log('E', logTag, 'vehicle not found')
    return
  end

  local w = round(vehicle.color.w*100)/100 -- this is because the TS version was only up to the second decimal
  local x = round(vehicle.color.x*100)/100
  local y = round(vehicle.color.y*100)/100
  local z = round(vehicle.color.z*100)/100

  local color =  tostring(x).." "..tostring(y).." "..tostring(z).." "..tostring(w) -- the TS sequence was like this
  return color
end

-- returns a list of all BeamNGVehicle objects currently spawned in the level
function getAllVehicles()
    local result = {}
    local nVehicles = be:getObjectCount()
    for objectId=0,nVehicles-1,1 do
        local vehicleObj = be:getObject(objectId)
        table.insert(result, vehicleObj)
    end
    return result
end

function getClosestVehicle(requesterID, callbackfct)
  local vehr = be:getObjectByID(requesterID)
  if not vehr then return end
  local pos1 = vec3(vehr:getPosition())

  local c = be:getObjectCount()

  local minDist = 9999999
  local minVehId = nil
  for i = 0, c do
  local veh = be:getObject(i)
  if veh then
    local tid = veh:getID()
    if tid ~= requesterID then
    local pos2 = vec3(veh:getPosition())
    local dist = (pos1 - pos2):length()
    if dist < minDist then
      minDist = dist
      minVehId = tid
    end
    end
  end
  end
  if not minVehId then
  vehr:queueLuaCommand(callbackfct .. '(-1, -1)')
  else
  vehr:queueLuaCommand(callbackfct .. '(' .. minVehId .. ',' .. minDist .. ')')
  end
end

function forEachAudioChannel(callback)
  local AudioChannelDefault = scenetree.AudioChannelDefault
  if AudioChannelDefault then callback('AudioChannelDefault', AudioChannelDefault) end
  local AudioChannelGui = scenetree.AudioChannelGui
  if AudioChannelGui then callback('AudioChannelGui', AudioChannelGui) end
  local AudioChannelEffects = scenetree.AudioChannelEffects
  if AudioChannelEffects then callback('AudioChannelEffects', AudioChannelEffects) end
  local AudioChannelMessages = scenetree.AudioChannelMessages
  if AudioChannelMessages then callback('AudioChannelMessages', AudioChannelMessages) end
  local AudioChannelMusic = scenetree.AudioChannelMusic
  if AudioChannelMusic then callback('AudioChannelMusic', AudioChannelMusic) end
end

function getAudioChannelsVolume()
  local lastVolumes = {}
  local callback = function(name, audio)
    lastVolumes[name] = audio.getVolume()
  end
  forEachAudioChannel(callback)
  return lastVolumes
end

function setAudioChannelsVolume(data)
  for k, v in pairs(data) do
    local AudioChannel = scenetree[k]
    if AudioChannel then AudioChannel:setVolume(v) end
  end
end

-- TODO remove
function testSounds()
  paramGroupG = SFXParameterGroup()
  paramGroupG:setPrefixFilter('global_')
  paramGroupG:registerObject('')

  paramGroupA = SFXParameterGroup()
  paramGroupA:registerObject('')

  paramGroupB = SFXParameterGroup()
  paramGroupB:registerObject('')

  soundA = Engine.Audio.createSource2('AudioGui', 'event:>TestGroup>TestEvent')
  paramGroupA:addSource(soundA)
  soundB = Engine.Audio.createSource2('AudioGui', 'event:>TestGroup>TestEvent')
  paramGroupB:addSource(soundB)

  soundA:play(-1)
  soundB:play(-1)

  paramGroupA:setParameterValue('test0', 0)
  paramGroupB:setParameterValue('test0', 0)
end

-- returns first hit with the correct class. Example: getObjectByClass("TimeOfDay")
function getObjectByClass(className)
  local o = scenetree.findClassObjects(className)
  if not o or #o == 0 then return nil end
  o = scenetree.findObject(o[1])
  if not o then return nil end
  return o
end

-- returns all hit with the correct class. Example: getObjectsByClass("CloudLayer")
function getObjectsByClass(className)
  local res = {}
  local o = scenetree.findClassObjects(className)
  if not o or #o == 0 then return nil end
  for _, v in pairs(o) do
    table.insert(res, scenetree.findObject(v))
  end
  return res
end

-- returns our time of the day, if not possible, nil
-- uses 24h time format
function getTimeOfDay(asString)
  local tod = getObjectByClass("TimeOfDay")
  if not tod then return nil end

  -- convert our crazy time of day format into sth that makes sense: 24 h clock
  local seconds = ((tod.time + 0.5) % 1) * 86400
  local r = {}
  r.hours = seconds / 3600
  r.mins  = math.floor(seconds / 60 - (r.hours * 60))
  r.secs  = math.floor(seconds - r.hours * 3600 - r.mins * 60)
  if asString then
    return string.format("%02.f", r.hours) .. ":" .. string.format("%02.f", r.mins) .. ":" .. string.format("%02.f", r.secs)
  end
  return r
end

-- sets the time. example: setTimeOfDay('13:00')
-- uses 24h time format
function setTimeOfDay(inp)
  local tod = getObjectByClass("TimeOfDay")
  if not tod then return false end

  if type(inp) == 'string' then
    -- parse the string then
    local h, m, s = string.match(inp, "([0-9]*):?([0-9]*):?([0-9]*)")
    inp = {
      hours = tonumber(h) or 0,
      mins = tonumber(m) or 0,
      secs = tonumber(s) or 0
    }
  end
  --dump(inp)
  tod.time = (((inp.hours * 3600 + inp.mins * 60 + inp.secs) / 86400) + 0.5) % 1
end

function addPrefab(objName, objFileName, objPos, objRotation, objScale)
  local obj = scenetree[objName]
  if not obj then
    log('D', logTag, 'adding prefab '..objName)
    local p = createObject('Prefab')
    p.filename = String(objFileName)
    p.loadMode = 1 --'Manual'
    p:setField('position', '', objPos)
    p:setField('rotation', '', objRotation)
    p:setField('scale', '', objScale)
    p.canSave  = true
    p.canSaveDynamicFields = true
    p:registerObject(objName)
    --MissionCleanup.add(%p)
    return p
  else
    log('E', logTag, 'Object already exists: '..objName)
    return nil
  end
end

function spawnPrefab(objName, objFileName, objPos, objRotation, objScale)
  local p = addPrefab(objName, objFileName, objPos, objRotation, objScale)
  if p then
    log('D', logTag, 'loading prefab '..objName)
    p:load();
  end
  return p
end

function removePrefab(objName)
    local obj = scenetree[objName]
    if obj then
      log('D', logTag, 'unloading prefab '..objName)
      obj:unload()
      obj:delete()
    end
end

function pushActionMap (map)
  local o = scenetree[map .. "ActionMap"]
  if o then
    return o:push()
  end
  return false
end

function popActionMap (map)
  local o = scenetree[map .. "ActionMap"]
  if o then
    return o:pop()
  end
  return false
end

function queueCallbackInVehicle(veh, ge_function_str, veh_cmd_str)
  if not veh or not ge_function_str or not veh_cmd_str then return end
  local ge_cmd = string.format('%s%s', ge_function_str, '(unserialize(%q))')
  local cmd = string.format('obj:queueGameEngineLua(string.format(%q, serialize(%s)))', ge_cmd, veh_cmd_str)
  veh:queueLuaCommand(cmd)
end

function queueObjectLua(objId, cmd)
  local object = be:getObjectByID(objId)
  if object then
    object:queueLuaCommand(cmd)
  end
end

-- returns the radius of a scene object beamng waypoint
function getSceneWaypointRadius(o)
  local oScale = o:getScale()
  return math.max(oScale.x, oScale.y, oScale.z)
end

function checkVehicleProperty(vid, propertyName, value)
  local sceneVehicle = scenetree.findObjectById(vid)
  return sceneVehicle and sceneVehicle[propertyName] == value
end

function setVehicleProperty(vid, propertyName, value)
  local sceneVehicle = scenetree.findObjectById(vid)
  if sceneVehicle then
    sceneVehicle[propertyName] = value
  end
end


------------------------------------------------------------------------------

function create_simobject_metatable(classname)
  -- we cache some values to be used as upvalues later
  -- not good to use metatable when you are executing code inside :P
  local classtable = _G[classname].___class

  local getDynDataFieldbyName = classtable.getDynDataFieldbyName
  local getStaticDataFieldbyName = classtable.getStaticDataFieldbyName

  local setDynDataFieldbyName = classtable.setDynDataFieldbyName
  local setStaticDataFieldbyName = classtable.setStaticDataFieldbyName

  local getClassName = classtable.getClassName
  local old_index = classtable.__index

  -- new getter
  classtable.__index = function(obj, k)
    if k == 'obj' then return obj end
    if k == 'className' then return getClassName(obj) end

    -- TODO: tried to SimObject upcast here but not working for some dark magic reason

    local field = old_index(obj, k)
    if field then return field end

    field = getStaticDataFieldbyName(obj, k, 0)
    if field then return field end

    field = getDynDataFieldbyName(obj, k, 0)
    if field then return field end

    return nil
  end

  -- new setter
  local old_newindex = classtable.__newindex
  classtable.__newindex = function(obj, k, v)
    if v == nil then return end
    if old_index(obj, k) then
      old_newindex(obj, k, v)
      return
    end

    if setStaticDataFieldbyName(obj, k, 0, v) then return end
    if setDynDataFieldbyName(obj, k, 0, v) then return end
  end
end

-- iterate all tables in global namespace to search for SimObject's metatables
for k, v in pairs(_G) do
  -- ___class is used by LuaIntf, we know this is a type from c++
  local classtable = (type(v) == 'table' and v.___class) or nil
  -- isSubClassOf is a member function all SimObject's metatables should have
  if classtable and type(classtable) == 'table' and classtable.isSubClassOf then
      -- process found SimObject's metatable
      create_simobject_metatable(k)
  end
end

local function new_SimObject(t)
  local obj = SimGroup()
  for k, v in pairs(t) do
    obj[k] = v
  end
  obj:registerObject(t.name)
  return obj
end

function test_lua()
  local obj2 = new_SimObject {
    name = 'hey',
    internalName = 2
  }
  dump(obj2.internalName)

  obj2 = Sim.findObject('hey')
  obj2:findObjectById(3)

  obj2:deleteObject()
end


function createPlayerSpawningData(model, config, color, licenseText)
  local spawningData = {options={}}

  if not model then
    log('W',logTag, 'createPlayerSpawningData - No model supplied.')
  end

  if not config then
    log('W',logTag, 'createPlayerSpawningData - No config supplied.')
  end

  spawningData.model = model
  spawningData.options.config = config
  spawningData.options.licenseText = licenseText
  spawningData.options.color = color

  return spawningData
end

function extractVehicleData(vid)
  local campaign = campaign_campaigns and campaign_campaigns.getCampaign()
  local vehicleData = campaign and campaign.state.userVehicle
  if not vehicleData then
    local vehicle = scenetree.findObjectById(vid)
    if not vehicle then
      log('W',logTag, 'there is no player vehicle.')
      return
    end

    vehicleData = {}
    local _, config, _ = path.split2(vehicle.partConfig)
    vehicleData.config = config
    vehicleData.licenseText = vehicle:getDynDataFieldbyName("licenseText", 0)
    vehicleData.color = string.format("%0.2f %0.2f %0.2f %0.2f", vehicle.color.x, vehicle.color.y, vehicle.color.z, vehicle.color.w)
    vehicleData.model = vehicle.JBeam
  end

  return vehicleData
end

-- little helper for the raycasting function
-- returns nil on no hit, otherwise table
function castRay(origin, target, includeTerrain, renderGeometry)
  if includeTerrain == nil then includeTerrain = false end
  if renderGeometry == nil then renderGeometry = false end

  local res = Engine.castRay(origin:toPoint3F(), target:toPoint3F(), includeTerrain, renderGeometry)
  if not res then return res end

  res.pt = vec3(res.pt)
  res.norm = vec3(res.norm)
  return res
end

-- same as castRay, but with debug drawing
function castRayDebug(origin, target, includeTerrain, renderGeometry)
  if includeTerrain == nil then includeTerrain = false end
  if renderGeometry == nil then renderGeometry = false end

  -- ray line
  debugDrawer:drawSphere(origin:toPoint3F(), 0.1, ColorF(1,0,0,1))
  debugDrawer:drawSphere(target:toPoint3F(), 0.1, ColorF(0,0,1,1))

  local res = castRay(origin, target, includeTerrain, renderGeometry)

  -- the ray line
  local col = ColorF(0,1,0,1)
  if not res then col = ColorF(1,0,0,1) end
  debugDrawer:drawLine(origin:toPoint3F(), target:toPoint3F(), col)

  if not res then return end

  -- draw the collision and the normal of it
  debugDrawer:drawSphere(res.pt:toPoint3F(), 0.1, ColorF(0,1,0,1))
  debugDrawer:drawLine(res.pt:toPoint3F(), (res.pt + res.norm):toPoint3F(), col)

  return res
end

local castRayTest = 0
function testRaycasting(dtReal)
  castRayTest = castRayTest + dtReal

  local a = vec3(4 + math.sin(castRayTest) * 3,-2+math.cos(castRayTest) * 3,10)
  local b = vec3(4 + math.cos(castRayTest) * 3,-2+math.sin(castRayTest) * 3,-10)
  castRayDebug(a, b, false, false)
end

function convertVehicleIdKeysToVehicleNameKeys(data)
  local result = {}
  if data and type(data) == 'table' then
    for vid,entry in pairs(data) do
      local vehicle = be:getObjectByID(vid)
      if vehicle then
        local vehicleName = vehicle:getField('name', '')
        result[vehicleName] = entry
      end
    end
  end
  return result
end

function convertVehicleNameKeysToVehicleIdKeys(data)
  local result = {}
  if data and type(data) == 'table' then
    for vehicleName,entry in pairs(data) do
      local vehicle = scenetree.findObject(vehicleName)
      if vehicle then
        local vehicleID = vehicle:getID()
        result[vehicleID] = entry
      end
    end
  end
  return result
end

function isOfficialContent(path)
  return string.startswith(path, FS:getGamePath())
end

function imageExistsDefault(path, fallbackPath)
  if path ~= nil and FS:fileExists(path) then
    return path
  else
    return fallbackPath or '/ui/images/appDefault.png'
  end
end

function dirContent(path)
  return FS:findFilesByPattern(path, '*', -1, true, false)
end

function fileExistsOrNil(path)
  if type(path) == 'string' and FS:fileExists(path) then
    return path
  end
  return nil
end

function getDirs(path, recursiveLevels)
  local files = FS:findFilesByPattern(path, '*', recursiveLevels, false, true)
  local res = {}
  local residx = 1
  for _, value in pairs(files) do
    -- because for some reason there are files inside the result if recursive level is >0
    if not tableContains(res, value) and not string.match(value, '^.*/.*%..*$') then
      res[residx] = value
      residx = residx + 1
    end
  end

  return res
end

function getFileSize(filename)
  local res = -1
  local f = io.open(filename, "r")
  if f == nil then
    return res
  end
  res = f:seek("end")
  f:close()
  return res
end

-- Return the string 'str', with all magic (pattern) characters escaped.
function escape_magic(str)
  assert(type(str) == "string", "utils.escape: Argument 'str' is not a string.")
  local escaped = str:gsub('[%-%.%+%[%]%(%)%^%%%?%*%^%$]','%%%1')
  return escaped
end

local __randomWasSeeded = false
function tableChooseRandomKey(t)
  if t == nil then return nil end
  if not __randomWasSeeded then
    math.randomseed(os.time())
    __randomWasSeeded = true
  end
  local randval = math.random(1, tableSize(t))
  local n = 0
  for k, v in pairs(t) do
    n = n + 1
    if n == randval then
      return k
    end
  end
  return nil
end

function randomASCIIString(len)
  if not __randomWasSeeded then
    math.randomseed(os.time())
    __randomWasSeeded = true
  end
  local res = ''
  local ascii = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local sl = string.len(ascii)
  for i = 1, len do
    local k = math.random(1, sl)
    res = res .. string.sub(ascii, k, k + 1)
  end
  return res
end

-- converts string str separated with separator sep to table
function stringToTable(str, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  local i = 1
  for s in string.gmatch(str, "([^"..sep.."]+)") do
    t[i] = s
    i = i + 1
  end
  return t
end

function copyfile(src, dst)
  local infile = io.open(src, "r")
  if not infile then return nil end
  local outfile = io.open(dst, "w")
  if not outfile then return nil end
  outfile:write(infile:read("*a"))
  infile:close()
  outfile:close()
end

-- returns a list of immidiate directories with full path in given path
function getDirectories(path)
  local files = FS:findFilesByPattern(path,"*", 0, true, true)
  local dirs = {}
  for _,v in pairs(files) do
    if FS:directoryExists(v) and not FS:fileExists(v) then
      table.insert(dirs, v)
    end
  end
  return dirs
end

function the_high_sea_crap_detector()
  -- this function only shows a message to entice people to buy the game.
  -- please support development of BeamNG.drive and leave this in here :)
  local files = FS:findFilesByPattern('/', '*.url', 0, false, false)
  local knownHashes = {
    ['24cc61dd875c262b4bbdd0d07e448015ae47b678'] = 1,
    ['a42eba9d2cf366fb52589517f7f260c401c99925'] = 1
  }
  for _, f in pairs(files) do
    --print( ' - ' .. string.upper(f) .. ' = ' .. hashStringSHA1(string.upper(f)))
    if knownHashes[hashStringSHA1(string.upper(f))] then
      log('I', 'highSeas','Ahoy!')
      return true
    end
  end
  return false
end
