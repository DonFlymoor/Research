local M = {}
local logTag = 'simpleSplineTrack'

--these two regulate the scaling of the track, though not the width oth scaling of the cross section.
local gridScale = 4
local heightScale = 1
local vectorScale = vec3(gridScale,gridScale,heightScale)
local pointsMultiplier = 6
--this creates the actual mesh from the track.
local mesher = require('util/splineToProceduralMesh')
--abstract info of the track pieces
local pieces = {}
--more concrete info fo the track.
local track = {}

--list of all the markers
local heightMarkers = {}
local bankMarkers = {}
local widthMarkers = {}
--currently selected track element marker
local trackMarker 
local currentSelected = 1
local trackClosed = false

-- this holds the indizes of the pieces which markers have been changed.
local markerChanges = {}

-- if the track is high quality
local highQuality = false

-- stack
local stackedPieces = {}
-- where the origin of the track is in the world.
local trackPosition = {}
-- whether the markers are shown or not.
local markersShown = true
-- default number of laps
local defaultLaps = 2
-- if the track is reversible
local reversible = false
local fixedCheckpoints = false

----------------------------------------------
--helper and control functions for the app --
----------------------------------------------

-- helper function that places a checkpoint
local function makeCP(p, scenario)
  local rot = p.finalRot or p.rot
  local off = M.rotateVectorByQuat(vec3(0,1,0), rot )
  local num = #scenario.lapConfig
  scenario.nodes['gym_'..num] = {}
  scenario.nodes['gym_'..num].pos = (p.basePosition and vec3(p.basePosition) or  vec3(p.position)) + vec3(0,0,p.zOffset)
  scenario.nodes['gym_'..num].rot = off
  scenario.nodes['gym_'..num].radius = p.width/2 +1
  
  scenario.lapConfig[#scenario.lapConfig+1] = 'gym_'..num
end

--this function creates evenly spaced checkpoints, and adds them to the scenario etc.
local function addCheckPointPositions(reverse) 
  if not reverse then reverse = false end
  local totalLength = track[#track].points[#track[#track].points].length
  local cpCount = math.ceil(totalLength / 300)
  if cpCount < 3 then
    cpCount = 3
  end
  local dist = totalLength / cpCount
  local cur = dist -1

  local scenario = scenario_scenarios.getScenario()
  scenario.lapConfig = {}
  scenario.nodes = {}

  local trackStart,trackEnd,trackStep
  local pointsStart,pointsEnd,pointsStep
  if reverse then
    cur = totalLength - cur
    dist = -dist
    trackStart = #track
    trackEnd = 1
    trackStep = -1
  else
    trackStart = 1
    trackEnd = #track
    trackStep = 1
  end
  track[#track].hasCheckPoint = true

  for i = trackStart, trackEnd, trackStep do 
    local segment = track[i]
    if segment.points then
      if reverse then
        pointsStart = #segment.points
        pointsEnd = 1
        pointsStep = -1
      else
        pointsStart = 1
        pointsEnd = #segment.points
        pointsStep = 1
      end

      for j = pointsStart, pointsEnd, pointsStep do
        local p = segment.points[j]
        if (not fixedCheckpoints and p.length > cur ~= reverse) or (fixedCheckpoints and segment.hasCheckPoint and j == pointsEnd) then
          cur = cur + dist
          makeCP(p,scenario)
        end
      end

    elseif fixedCheckpoints and segment.hasCheckPoint then
      makeCP(segment.markerInfo,scenario)
    end
  end

  scenario.initialLapConfig = scenario.lapConfig
end

--places the players car at the beginning of the track.
local function positionVehicle(reverse)
  local point = track[1]
  if reverse and not closed then
    point = track[#track]
  end

  local rot = quatFromEuler(0,math.pi,math.pi):__mul(point.rot)
  if reverse then
    rot = rot:__mul(quatFromEuler(0,0,math.pi))
  end

  local off = M.rotateVectorByQuat(vec3(0,-3,0), rot )
  local pos= vec3(0,0,0.25) + point.markerInfo.position + off
  pos = pos:toPoint3F()
  local scenario = scenario_scenarios
  if scenario then
    scenario = scenario.getScenario()
    scenario.startingTransforms['scenario_player0'].pos = pos
    scenario.startingTransforms['scenario_player0'].rot = rot
    vehicleSetPositionRotation(scenario.vehicleNameToId['scenario_player0'], pos.x, pos.y, pos.z,  rot.x, rot.y, rot.z, rot.w)
  else
    local id = be:getPlayerVehicle(0):getID()
    vehicleSetPositionRotation(id, pos.x, pos.y, pos.z,  rot.x, rot.y, rot.z, rot.w)
  end
  be:reloadCollision()
end

-- positions the track 15m in front of the camera. returs false if user is not in free camera mode
local function positionTrackBeforeCamera()
  if not commands.isFreeCamera(0) then 
    return false 
  end

  -- calculate position 5m in front of camera
  local cameraPosition = getCameraPosition()
  local position = M.rotateVectorByQuat(vec3(0, 15, 0), quat(getCameraQuat()))
  position = position + cameraPosition
  M.setTrackPosition(position.x/gridScale, position.y/gridScale, position.z)
  return true
end

--rotates the track so that it points into the direction the camera is looking. returs false if user is not in free camera mode
local function rotateTrackToCamera()
  if not commands.isFreeCamera(0) then 
    return false 
  end

  local cameraLook = M.rotateVectorByQuat(vec3(0, 1, 0), quat(getCameraQuat()))
  M.setTrackPosition(trackPosition.position.x, trackPosition.position.y, trackPosition.position.z, (-math.atan2(cameraLook.y, -cameraLook.x) + math.pi/2)*180 /math.pi)
  return true
end


-- positions the track 15m above the player vehicle. returns false if there is no player vehicle
local function positionTrackAboveVehicle()
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then 
    return false 
  end

  local vehiclePos = vehicle:getPosition()
  M.setTrackPosition(vehiclePos.x/gridScale, vehiclePos.y/gridScale, vehiclePos.z+15)
  return true
end

-- positions the track so it looks into the direction of the player vehicle. returns false if there is no player vehicle
local function rotateTrackToTrackVehicle()
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then 
    return false 
  end

  local vehicleDir = vehicle:getDirectionVector()
  M.setTrackPosition(trackPosition.position.x, trackPosition.position.y, trackPosition.position.z, (-math.atan2(vehicleDir.y, -vehicleDir.x) + math.pi/2)*180 /math.pi)
  return true
end

--sets the values of the trackPosition field
local function setTrackPosition(x,y,z,hdg) 
  trackPosition.position = vec3(x,y,z)
  if hdg then
    hdg = (hdg/180) * math.pi
    trackPosition.hdg = -hdg
    trackPosition.rot = quatFromEuler(0,0,hdg)
  end
  -- rotated unit vectors for snapping points to a grid
  trackPosition.unitX = quatFromEuler(0,0,trackPosition.hdg):__mul(vec3(1,0,0))
  trackPosition.unitY = quatFromEuler(0,0,trackPosition.hdg):__mul(vec3(0,1,0))
  -- place and rotate the origin piece of the track and invalidate whole track
  pieces[1].position = vec3(x,y,z)
  pieces[1].hdg = trackPosition.hdg
  for _,p in ipairs(pieces) do
    p.invalid = true
  end
end

local function setDefaultLaps(laps)
  defaultLaps = laps
end

local function setReversible(rev)
  reversible = rev
end

--gets the values of the trackPosition field.
local function getTrackPosition() 
  return {
    x = trackPosition.position.x,
    y = trackPosition.position.y,
    z = trackPosition.position.z,
    hdg = trackPosition.hdg,
  }
end

--gets the track table of one singular element thereof.
local function getPieceInfo(index)
  if index then
    return pieces[index]
  else
    return {
      pieces = pieces,
      highQuality = highQuality,
      showMarkers = markersShown,
      trackPosition = M.getTrackPosition(),
      currentSelected = currentSelected,
      trackClosed = trackClosed,
      defaultLaps = defaultLaps,
      reversible = reversible
    }
  end
end


--sets the track to high quality or not.
local function setHighQuality(hq)
  highQuality = hq
  local quality = hq and 1 or 4
  -- mark all track pieces which a different quality than target quality to be refreshed
  for _,segment in ipairs(track) do 
    if segment.quality ~= quality then
      segment.quality = quality
      segment.refreshMesh = true
      segment.timer = -1
    end
  end
end

--stacks all the pieces up until the selected piece.
local function stackToCursor()
  M.stack(#pieces - currentSelected)
end

--stacks any number of pieces.
local function stack(count)
  if #pieces <= 2 then return end
  if not count then count = 1 end
  if count <= 0 then return end

  while count > 0 do 
    stackedPieces[#stackedPieces+1] =pieces[#pieces]
   --dump(pieces)
    M.revert()
   --dump(pieces)
    count = count-1
    if #pieces <= 0 then
      count = 0
    end
  end
end

--applies any number of pieces from the stack, with the option to keep the stack.
local function applyStack(count, keep)
  if #stackedPieces == 0 then return end
  if not count then count = 1 end
  if count <= 0 then return end

  local to = #stackedPieces-count
  to = to+1
  if to < 1 then to = 1 end
  for i = #stackedPieces, to, -1 do
    M.addPiece(M.deepcopy(stackedPieces[i]))
    M.invalidatePiece(#pieces)
    pieces[#pieces].fresh = false
    if not keep then
      stackedPieces[#stackedPieces] = nil
    end
  end
end

--helper copy function for stacking.
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else --number, string, boolean, etc
        copy = orig
    end
    return copy
end

--gets number of stacked tiles.
local function getStackCount() 
  return #stackedPieces
end

--clears the stack.
local function clearStack()
  stackedPieces = {}
end

-- gets the track info the currently selected piece.
local function getSelectedTrackInfo()
  return track[currentSelected]
end

----------------------
--marker functions --
----------------------
-- this places the track marker on a track element by index.
local function focusMarkerOn(index)
  local tip = track[index]
  if not tip then return end
  if not markersShown then
    M.showMarkers(true)
  end

  -- position track marker
  trackMarker:setPosition((track[index].markerInfo.position):toPoint3F())
  trackMarker:setScale(Point3F(2,2,2))

  -- change materials of track
  for i, segment in ipairs(track) do
    if segment.mesh then
      if i == index then
        M.setSegmentMaterial(segment,"track_editor_grid")
      else
        M.setSegmentMaterial(segment,"track_editor_base")
      end
      if segment.materialChanged then
        segment.mesh:updateMaterial()
        segment.materialChanged = false
      end
    end
  end
  -- set current index
  currentSelected = index
end

-- toggles visibility of markers on or off. 
local function showMarkers(show)
  markersShown = show
  if show then
    M.createMarkers()
    M.focusMarkerOn(currentSelected)
  else
    --hide all the markers
    for m = 1,#heightMarkers do
      if heightMarkers[m] then
        heightMarkers[m].scale = Point3F(0,0,0)
      end
    end

    for m = 1,#bankMarkers do
      if bankMarkers[m] then
        bankMarkers[m].scale = Point3F(0,0,0)
      end
    end

    for m = 1,#widthMarkers do
      if widthMarkers[m] then
        widthMarkers[m].scale = Point3F(0,0,0)
      end
    end

    if trackMarker then
      trackMarker.scale = Point3F(0,0,0)
    end
  end

end

-- changes all pieces to asphalt material
local function setAllPiecesToAsphalt()
  if track then
    if track[currentSelected] and track[currentSelected].mesh then
      track[currentSelected].mesh.material = String("track_editor_base")
      track[currentSelected].mesh:updateMaterial()
    end
  end
end

-- mini function to get all indizes of the track which contain a specific field
local function indexGetter(track,nameOfField)
  local list = {}
  for i = 1, #track do
    if track[i][nameOfField] ~= nil then
      list[#list+1] = i
    end
  end
  return list
end

-- mini function to fill the list with enough objects and hide unneccesary objects
local function expandTruncateList(list, length, addFunction)
  while #list < length do
    addFunction()
  end
  for i = length+1, #list do
    local m = #list
    list[m].scale = Point3F(0,0,0)
    list[m] = nil
  end
  return
end


--creates and places all the neccesary markers.
local function createMarkers() 
  --make the trackMarker visible/create
  if not trackMarker then
    trackMarker =  createObject('TSStatic')
    trackMarker:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_sphere.dae")
    trackMarker:setPosition(Point3F(0,0,0))
    trackMarker.scale = Point3F(1,1,1)
    trackMarker:setField('rotation', 0, '0 0 0 1')
    trackMarker.useInstanceRenderData = true
    trackMarker:setField('instanceColor', 0, '1 1 1 1')
    trackMarker:setField('collisionType', 0, "Collision Mesh")
    trackMarker:setField('decalType', 0, "Collision Mesh")
    trackMarker:setField('playAmbient', 0, "1")
    trackMarker:setField('allowPlayerStep', 0, "1")
    trackMarker:setField('canSave', 0, "0")
    trackMarker:setField('canSaveDynamicFields', 0, "1")
    trackMarker:setField('renderNormals', 0, "0")
    trackMarker:setField('meshCulling', 0, "0")
    trackMarker:setField('originSort', 0, "0")
    trackMarker:setField('forceDetail', 0, "-1")
    trackMarker.canSave = false
    trackMarker:registerObject("track_marker")
  else
    trackMarker.scale = Point3F(1,1,1)
  end

  local heightIndexes = indexGetter(track,'height')
  expandTruncateList(heightMarkers,#heightIndexes,M.addHeightMarker)
  --go through all the height-containing elements, transform the markers so that they fit.
  for i = 1, #heightIndexes do
    local node = track[heightIndexes[i]]
    heightMarkers[i]:setPosition((node.markerInfo.position + vec3(0,0,-1)):toPoint3F())
    heightMarkers[i]:setScale(Point3F(1,1, node.markerInfo.position.z -1))
  end

  local bankIndexes = indexGetter(track,'bank')
  expandTruncateList(bankMarkers,#bankIndexes,M.addBankMarker)
    --go through all the bank-containing elements, transform the markers so that they fit.
  for i = 1, #bankIndexes do
    local node = track[bankIndexes[i]]
    local rot = node.markerInfo.rot

    -- transform quat into the format that torque uses
    local quat = {x=1,y=0,z=0,w=0}
    quat.w = 2 * math.acos(rot.w)
    local sinHalfAngle = math.sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z)
    if sinHalfAngle ~= 0 then
      quat.x = rot.x / sinHalfAngle
      quat.y = rot.y / sinHalfAngle
      quat.z = rot.z / sinHalfAngle
    end
    quat.w = quat.w * 180 / math.pi

    bankMarkers[i].scale =  Point3F(0.1, 5, 2.5)
    bankMarkers[i]:setPosition(node.markerInfo.position:toPoint3F())
    bankMarkers[i]:setField('rotation', 0, quat.x .. ' ' ..quat.y..' '..quat.z..' '..quat.w)
  end

  local widthIndexes = indexGetter(track,'width')
  expandTruncateList(widthMarkers,#widthIndexes*2,M.addWidthMarker)
    --go through all the bank-containing elements, transform the markers so that they fit.
  for i = 1, #widthIndexes do
    local node = track[widthIndexes[i]]
    local right = M.rotateVectorByQuat(vec3( node.width/2+1, 0, 0), node.markerInfo.rot)
    local left =  M.rotateVectorByQuat(vec3(-node.width/2-1, 0, 0), node.markerInfo.rot)

    widthMarkers[i*2-1]:setPosition((node.markerInfo.position + right ):toPoint3F())
    widthMarkers[i*2-1].scale = Point3F(2,2,2)

    widthMarkers[i*2]:setPosition((node.markerInfo.position + left):toPoint3F())
    widthMarkers[i*2].scale = Point3F(2,2,2)
  end

end

--creates a banking marker at the specified position with the correct rotation.
local function addBankMarker()
  local marker =  createObject('TSStatic')
  marker:setField('shapeName', 0, "art/shapes/interface/track_editor_marker.dae")
  marker:setPosition(Point3F(0,0,0))
  marker.scale = Point3F(0.1, 5, 2.5)
  marker:setField('rotation', 0, '0 0 0 1')
  marker.useInstanceRenderData = true
  marker:setField('instanceColor', 0, '1 0 0 1')
  marker:setField('collisionType', 0, "Collision Mesh")
  marker:setField('decalType', 0, "Collision Mesh")
  marker:setField('playAmbient', 0, "1")
  marker:setField('allowPlayerStep', 0, "1")
  marker:setField('canSave', 0, "0")
  marker:setField('canSaveDynamicFields', 0, "1")
  marker:setField('renderNormals', 0, "0")
  marker:setField('meshCulling', 0, "0")
  marker:setField('originSort', 0, "0")
  marker:setField('forceDetail', 0, "-1")
  marker.canSave = false
  marker:registerObject("bankMarker"..#bankMarkers)

  bankMarkers[#bankMarkers+1] = marker
end

--creates a height marker.
local function addHeightMarker()
  local marker =  createObject('TSStatic')
  marker:setField('shapeName', 0, "art/shapes/interface/track_editor_marker.dae")
  marker:setPosition(Point3F(0,0,0))
  marker.scale = Point3F(2, 2, 20)
  marker:setField('rotation', 0, '1 0 0 180')
  marker.useInstanceRenderData = true
  marker:setField('instanceColor', 0, '0 0 1 1')
  marker:setField('collisionType', 0, "Collision Mesh")
  marker:setField('decalType', 0, "Collision Mesh")
  marker:setField('playAmbient', 0, "1")
  marker:setField('allowPlayerStep', 0, "1")
  marker:setField('canSave', 0, "0")
  marker:setField('canSaveDynamicFields', 0, "1")
  marker:setField('renderNormals', 0, "0")
  marker:setField('meshCulling', 0, "0")
  marker:setField('originSort', 0, "0")
  marker:setField('forceDetail', 0, "-1")
  marker.canSave = false
  marker:registerObject("heightMarker"..#heightMarkers)

  heightMarkers[#heightMarkers+1] = marker
end

--creates two width markers
local function addWidthMarker(pos, rot, width)
  --create and store marker 1
  local index = #widthMarkers
  local markerRight =  createObject('TSStatic')
  markerRight:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_sphere.dae")
  markerRight:setPosition(Point3F(0,0,0))
  markerRight.scale = Point3F(2,2,2)
  markerRight:setField('rotation', 0, '0 0 0 1')
  markerRight.useInstanceRenderData = true
  markerRight:setField('instanceColor', 0, '0 1 0 1')
  markerRight:setField('collisionType', 0, "Collision Mesh")
  markerRight:setField('decalType', 0, "Collision Mesh")
  markerRight:setField('playAmbient', 0, "1")
  markerRight:setField('allowPlayerStep', 0, "1")
  markerRight:setField('canSave', 0, "0")
  markerRight:setField('canSaveDynamicFields', 0, "1")
  markerRight:setField('renderNormals', 0, "0")
  markerRight:setField('meshCulling', 0, "0")
  markerRight:setField('originSort', 0, "0")
  markerRight:setField('forceDetail', 0, "-1")
  markerRight.canSave = false
  markerRight:registerObject("widthMarker"..index)
  widthMarkers[index+1] = markerRight

  local markerLeft =  createObject('TSStatic')
  markerLeft:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_sphere.dae")
  markerLeft:setPosition(Point3F(0,0,0))
  markerLeft.scale = Point3F(2,2,2)
  markerLeft:setField('rotation', 0, '0 0 0 1')
  markerLeft.useInstanceRenderData = true
  markerLeft:setField('instanceColor', 0, '0 1 0 1')
  markerLeft:setField('collisionType', 0, "Collision Mesh")
  markerLeft:setField('decalType', 0, "Collision Mesh")
  markerLeft:setField('playAmbient', 0, "1")
  markerLeft:setField('allowPlayerStep', 0, "1")
  markerLeft:setField('canSave', 0, "0")
  markerLeft:setField('canSaveDynamicFields', 0, "1")
  markerLeft:setField('renderNormals', 0, "0")
  markerLeft:setField('meshCulling', 0, "0")
  markerLeft:setField('originSort', 0, "0")
  markerLeft:setField('forceDetail', 0, "-1")
  markerLeft.canSave = false
  markerLeft:registerObject("widthMarker"..index..'b')
  widthMarkers[index+2] = markerLeft
end

--change a marker of a piece, marks the piece as invalid
local function markerChange(type, index, value)
  if value == nil and index == 1 then return end
  if index == nil then index = #pieces end

  -- if changing the last piece while closed, update the first piece as well so it stays closed.
  if trackClosed and (index == 1 or index == #pieces) and value ~= nil then
    -- only change if there is actual change
    if pieces[1][type] ~= value then
      pieces[1][type] = value
      pieces[#pieces][type] = value
      M.invalidatePiece(1,type)
      M.invalidatePiece(#pieces,type)
    end
  else
    -- only change if there is actual change
    if pieces[index][type] ~= value then
      pieces[index][type] = value
      M.invalidatePiece(index,type, value == nil)
    end
  end
end

--this sets the banking of a piece by index (last piece if no index was given)
local function bank(bank, index)
  M.markerChange("bank",index, bank)
end

--this sets the elevation of a piece by index (last piece if no index was given)
local function elevate(height, index)
  M.markerChange("height",index, height)
end

--this sets the width of a piece by index (last piece if no index was given)
local function width(width, index)
  M.markerChange("width",index, width)
end

-----------------------------
--track to mesh functions --
-----------------------------

-- called every frame. when high quality is enabled, manages the timer on low quality track segments so they can be upgraded one after another.
local function onUpdate()
  if not track or not highQuality or not markersShown then return end
  -- fixed dTime means slower framerate causes slower update frequency
  local dTime = 0.01
  local segmentsToMake = {}
  for i,segment in ipairs(track) do
    if segment.timer and segment.timer > 0 and segment.quality ~= 1 then
      segment.timer  = segment.timer - dTime
      if segment.timer <= 0 then
        segmentsToMake[#segmentsToMake+1] = segment
      end
    end
  end

  for _,segment in ipairs(segmentsToMake) do
    if segment.points then
      segment.quality = 1
      mesher.materialize(segment,highQuality)
    end
    segment.fresh = false
    segment.refreshMesh = false
  end
end

-- smooth slope interpolation, goes from 0/0 to 1/delta, having horizontal slope at 0 and 1
local function smoothSlope(t,delta)
  if t <= 0 then 
    return 0,0 
  elseif t >= 1 then 
    return delta,0 
  else 
    return (3-2*t)*delta*t*t , (6-6*t)*delta*t 
  end 
end

-- smoother slope interpolation, goes from 0/0 to 1/delta, having horizontal slope at 0 and 1
local function smootherSlope(t,delta)
  if t <= 0 then 
    return 0,0 
  elseif t >= 1 then 
    return delta,0 
  else 
    return delta*t*t*t*(t*(t*6-15)+10) , delta*30*(t-1)*(t-1)*t*t
  end 
end

local function interpolateBank(t,a,b,point, length)
  local interpolated = smoothSlope(t,1)
  point.bank = a * (1-interpolated) + b * interpolated
end

local function interpolateWidth(t,a,b,point, length)
  local interpolated = smoothSlope(t,1)
  point.width = a * (1-interpolated) + b * interpolated
end 

local function interpolateHeight(t,a,b,point, length)
  local offset, slope = smoothSlope(t, b - a)
  offset = offset + a
  point.zOffset = offset 
  point.pitch = -(math.atan2(length,slope)- math.pi/2)
  --dump(point.pitch ..  " "..t..": "..a.." - " .. b)
end

--makes an actual mesh from the track info.
local function makeTrack(instantHighQuality) 
  --perf.enable(1)
  if #pieces == 0 then
    M.unloadAll()
    M.initTrack()
  end
  --transform raw track data to actual track info
  M.toSegments()
  -- calculate bezier points or custom points of invalid pieces
  M.convertToSpline()
  -- meause lengths of track pieces for interpolation
  M.measureTrack()

  -- interpolate fields
  M.interpolateField("bank", interpolateBank)
  M.interpolateField("width", interpolateWidth)
  M.interpolateField("height",interpolateHeight)

  -- calculate texture position, final rotation for new points, also calculate position and rotation for markers
  for index,segment in ipairs(track) do
    segment.index = index
    if segment.points and segment.refreshMesh then
      for i,point in ipairs(segment.points) do
        point.uvY = point.length
        point.finalRot = quatFromEuler(
          point.pitch,
          -(point.bank/180) * math.pi  + math.pi,
          0)
        :__mul(point.rot)
      end
    end
    segment.markerInfo.rot = quatFromEuler(
      segment.markerInfo.pitch,
      (-segment.markerInfo.bank/180) * math.pi  + math.pi,
      0):__mul(quatFromEuler(0,math.pi,segment.hdg))
    segment.markerInfo.position = segment.markerInfo.basePosition + vec3(0,0,segment.markerInfo.zOffset)
    segment.invalid = false
  end

  -- update all the meshes that need updating
  local timer = 1
  for i,segment in ipairs(track) do
    if segment.refreshMesh or (segment.quality ~= 1 and instantHighQuality) then
      if segment.points then
        if instantHighQuality then
          segment.timer = -1
          segment.quality = 1
        elseif highQuality then
          segment.timer = timer
          timer = timer + 0.1
          segment.quality = 4
        end
        mesher.materialize(segment)
      end
      segment.fresh = false
      segment.refreshMesh = false
    end
    -- set material for currently selected track piece accordingly
    if segment.mesh and currentSelected == i and not instantHighQuality then
      M.setSegmentMaterial(segment,"track_editor_grid")
    end
    -- update material of all segments which material has changed
    if segment.materialChanged then
      segment.mesh:updateMaterial()
      segment.materialChanged = false
    end
  end
  
  -- create/position markers if neccesary
  if markersShown then
    M.createMarkers()
  end
  --perf.disable()
  --perf.saveDataToCSV('splineTrackPerf.csv')
  -- only refresh collision if the whole track would be updated (like on drive button or quickrace.)
  -- reload collision takes a lot of time on bigger maps
  if instantHighQuality then
    be:reloadCollision()
  end
end

-- sets the material of a segment and marks it for updating if the material actually changed
local function setSegmentMaterial(segment, material)
  if segment.material ~= material then
    segment.mesh.material = String(material)
    segment.material = material
    segment.materialChanged = true
  end
end

-- interpolates the segments with given name of field to interpolate and an interpolation function.
local function interpolateField(nameOfField, interpolationFunction)
  local startIndex, endIndex
  local startValue, endValue
  local startLength, endLength
  local doChange
  -- go through all the pieces and set start/end fields.
  -- calculate actual interpolation when a new field occurs
  for i = 1, #pieces do
    if track[i][nameOfField] ~= nil or i == #track then
      if startValue == nil then
        startValue = track[i][nameOfField]
        startLength = track[i].endLength
        startIndex = i
      else
        if not track[i][nameOfField] then
          endValue = startValue
          endLength = track[i].endLength
          endIndex = i
        else
          endValue = track[i][nameOfField]
          endLength = track[i].endLength
          endIndex = i
        end

        -- only interpolate if one of the segments between start and end is actually contained in the markerChanges table
        doChange = false
        if markerChanges[nameOfField] ~= nil then
          for changeIndex = endIndex, startIndex, -1 do
            if tableContains(markerChanges[nameOfField], changeIndex) then
              doChange = true
            end
          end
        end

        if doChange then
          --dump("Found Values for " .. nameOfField .. ": " .. startValue .. " to " .. endValue .. " ("..startIndex .. " - " .. endIndex..")" .. "["..startLength .. " - " .. endLength .."]")
          if startIndex == 1 then startIndex = 0 end
          for changeIndex = endIndex, startIndex+1, -1 do
            M.interpolateSegment(track[changeIndex],startValue,endValue,startLength,endLength, interpolationFunction)
          end
        end
        if i < #track then
          startValue = track[i][nameOfField]
          startLength = track[i].endLength
          startIndex = i
        end
      end
    end
    -- fresh pieces, which have been added to the end of the track, should be also updated and receive the values of the last value that has been found
    if track[i].fresh and startValue then
      M.interpolateSegment(track[i],startValue,nil,startLength,nil, interpolationFunction)
    end
  end
  -- clear markerChanges for this field
  markerChanges[nameOfField] = {}
end

-- interpolation function for one segment
local function interpolateSegment(segment, startValue, endValue, startLength, endLength, interpolationFunction)
  -- interpolate points if points are available
  if segment.points ~= nil then
    -- if the same value on start and finish, we dont need to calculate the fraction of the lengths and just use 1
    if startValue == endValue or (not endLength and not endValue) then
      for _,p in ipairs(segment.points) do
        interpolationFunction(0,startValue,startValue,p,1)
      end
      interpolationFunction(0, startValue, startValue, segment.markerInfo,1)
    else
      -- otherwise, calculate fraction of distances and then interpolate
      for _,p in ipairs(segment.points) do
        local t = (p.length - startLength) / (endLength - startLength)
        interpolationFunction(t, startValue, endValue, p, endLength - startLength)
      end   
      interpolationFunction(
        (segment.endLength - startLength) / (endLength - startLength)
        , startValue, endValue, segment.markerInfo, endLength - startLength)
    end
    segment.refreshMesh = true
  else
    -- if there are no points, we still need to calculate the markerInfo values
    if startValue == endValue or endLength == startLength then
      interpolationFunction(0, endValue, endValue, segment.markerInfo,1)
    elseif (not endLength and not endValue) then
      interpolationFunction(0, startValue, startValue, segment.markerInfo,1)
    else
      interpolationFunction(
        (segment.endLength - startLength) / (endLength - startLength)
        , startValue, endValue, segment.markerInfo, endLength - startLength)
    end
  end
end

-- snaps a given point to the triangular grid, using the unit vectors in the trackPosition field.
local function snapToGrid(point)
  local adjustedPoint = point - trackPosition.position
  local intX = adjustedPoint:dot(trackPosition.unitX) / (math.sqrt(3)/2)
  local intY = adjustedPoint:dot(trackPosition.unitY) / 0.5
  local originalZ = adjustedPoint.z
  intX = round(intX)
  intY = round(intY)

  adjustedPoint:set(intX * (math.sqrt(3)/2)*trackPosition.unitX + intY * 0.5 *trackPosition.unitY)
  adjustedPoint.z = originalZ
  return adjustedPoint + trackPosition.position
end

-- goes through all segments and calculates the points and other infos for them.
local function convertToSpline()
  -- go through all segments that are invalid and update them.
  for i,segment in ipairs(track) do
    if segment.invalid then
      segment.rot = quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,segment.hdg + math.pi))
      segment.material = "track_editor_base"

      -- snap end points of the segment
      if segment.origin then
        M.snapToGrid(segment.origin)
      end
      if segment.position then
        M.snapToGrid(segment.position)
      end

      -- if this segment has points, either by custom points or bezier points, calculate them
      if not segment.noPoints then
        segment.quality = highQuality and 1 or 4
        -- actually calculate the points
        if segment.customPoints ~= nil then
          segment.points = M.calculateCustomPoints(segment)
        else
          segment.points = M.getBezierPoints(segment)
        end
        -- make sure that the first and last point are always part ot the mesh
        segment.points[1].quality = {true,true,true,true}
        segment.points[#segment.points].quality = {true,true,true,true}

        -- markerInfo position to last point position
        segment.markerInfo.basePosition = vec3(segment.points[#segment.points].position)

        --if this segment has points, then the previous and next segments have no caps 
        if i > 1 then
          if track[i-1].hasEndCap then
            track[i-1].hasEndCap = false
            track[i-1].refreshMesh = true
          end
        end
        if i < #track then
          if track[i+1].hasStartCap then
            track[i+1].hasStartCap = false
            track[i+1].refreshMesh = true
          end
        end

      else
        segment.markerInfo.basePosition = vec3(segment.position):componentMul(vectorScale)

        -- change caps on segments before and after
        if i > 1 then
          if not track[i-1].hasEndCap then
            track[i-1].hasEndCap = true
            track[i-1].refreshMesh = true
          end
        end
        if i < #track then
          if not track[i+1].hasStartCap then
            track[i+1].hasStartCap = true
            track[i+1].refreshMesh = true
          end
        end
      end
      -- in any case, mesh should be refreshed.
      segment.refreshMesh = true
    end
  end

  -- figure out if the track is closed or not
  local lastHeight = 0
  for i =1, #track do
    if track[i].height ~= nil then
      lastHeight = track[i].height
    end
  end

  trackClosed = 
        math.abs(track[1].position.x-track[#track].position.x) < 0.1
    and math.abs(track[1].position.y-track[#track].position.y) < 0.1
    --and math.abs(track[1].hdg%math.pi - track[#track].hdg%math.pi) < 0.1
    and math.abs((track[1].height +track[1].position.z) - (lastHeight + track[#track].position.z)) < 0.1

  if trackClosed then
    track[#track].bank = track[1].bank
    track[#track].width = track[1].width
    track[#track].hasEndCap = false
    track[1].hasStartCap = false
  else
    track[#track].hasEndCap = true
    track[1].hasStartCap = true
  end
end

-- calculates points on a bezier curve
local function getBezierPoints(segment)
  local bezierPoints = {}

  -- get the control points scaled up by the grid size
  local p0 = segment.origin:componentMul(vectorScale)
  local p3 = segment.position:componentMul(vectorScale)
  local p1 = segment.controlPointA:componentMul(vectorScale) + p0
  local p2 = segment.controlPointB:componentMul(vectorScale) + p3

  -- calculate number of points
  local numPoints = pointsMultiplier * segment.polyMult

  -- cap number of points with 300 and make it to integer
  if numPoints > 300 then 
    numPoints = 300 
  end
  numPoints = numPoints - numPoints%1

  for i = 0, numPoints do
    local t = i / numPoints
   
    -- calculate the weights for each point.
    local t0 = math.pow(1-t, 3) 
    local t1 = 3 * (t - 2*t*t + t*t*t)
    local t2 = 3 * (t*t - t*t*t)
    local t3 = t*t*t

    -- calculate the weights for the first derivative.
    local d0 = -3 * (1-t)*(1-t)
    local d1 = (3*(1 - t) * (1-t) - 6*(1 - t)*t)
    local d2 = (6*(1 - t)*t - 3*t*t) 
    local d3 = 3 * t*t

    -- calculate the angle of the spline directly from the first derivative
    local hdg = math.atan2(d0*p0.y + d1*p1.y + d2*p2.y + d3*p3.y, d0*p0.x + d1*p1.x + d2*p2.x + d3*p3.x)

    -- these fields will only be set for points that directly correspond to an original control point.
    -- quality of 4 means that only every 4th point will be in the mesh etc
    local quality = {}
    for q = 1, 4 do
      quality[q] = i%q == 0
    end

    -- fill in the fields.
    bezierPoints[#bezierPoints+1] = {
      position = t0*p0 + t1*p1 + t2*p2 + t3*p3,
      rot = quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,-hdg - math.pi/2)),
      quality = quality
    }
  end
  return bezierPoints
end


--scales and rotated custom points of a piece.
local function calculateCustomPoints(piece)
  if not piece.customPoints then 
    return nil 
  end

  local xUnitVector = vec3(math.cos(piece.hdg), -math.sin(piece.hdg), 0)
  local yUnitVector = vec3(math.sin(piece.hdg), math.cos(piece.hdg), 0)

  local points = {}
  for i,p in ipairs(piece.customPoints) do
    local newP = {
      position = vec3(
       (piece.position.x + p.position.x * xUnitVector.x + p.position.y * yUnitVector.x) * gridScale,
       (piece.position.y + p.position.x * xUnitVector.y + p.position.y * yUnitVector.y) * gridScale,
       (piece.position.z + p.position.z) * heightScale
      ),
      rot = p.rot:__mul(quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,piece.hdg + math.pi))),
      quality = {}
    }
    for q = 1, 4 do
      newP.quality[q] = i%q == 0
    end

    points[#points+1] = newP
  end
  return points
end

-- measures the length of the track
local function measureTrack()
  -- measure only from the last invalid piece
  local length = 0
  for i = 1, #track do
    if not track[i].invalid then
      length = track[i].endLength
    end
  end
  -- start actually measuring the length
  for i,segment in ipairs(track) do
    if segment.invalid then
      segment.startLength = length
      if segment.points then
        for pointIndex = 1, #segment.points-1 do
          segment.points[pointIndex].length = length
          length = length + (segment.points[pointIndex].position - segment.points[pointIndex+1].position):length()
        end
        segment.points[#segment.points].length = length
      end
      segment.endLength = length
    end
  end
end

--marks a piece to be invalidated later, either in general or for a specific type.
local function invalidatePiece(index, types, force)
  if not types then 
    types = {"height","width","bank"}
  else
    types = {types}
  end
  for _,t in ipairs(types) do
    if markerChanges[t] == nil then
        markerChanges[t] = {}
    end
    markerChanges[t][#markerChanges[t]+1] = index
  end
end

--takes the low-level info stored in the pieces-field, and creates the bezier segments or custom point arrays out of it.
local function toSegments()
  for i = #pieces, 1, -1 do
    if pieces[i].invalid and track[i] then
      if track[i].mesh then
        track[i].mesh:delete()
      end
      track[i] = nil
      M.invalidatePiece(i)
    end
  end
  --recreate track piece by piece and add infos such as width, height and bank.
  for i,p in ipairs(pieces) do
    if p.invalid or track[i] == nil then
      if p.piece == "init" then
        track[i] = M.initialTrackPiece(p)
      elseif p.piece == "forward" then
        track[i] = M.forward(p.length)
      elseif p.piece == "curve" then
        track[i] = M.curve(p.length, p.direction, p.hardness)
      elseif p.piece == "offsetCurve" then
        track[i] = M.offsetCurve(p.length, p.xOffset, p.hardness)
      elseif p.piece == "loop" then
        track[i] = M.loop(p.xOffset, p.radius )
      elseif p.piece == "spiral" then
        track[i] = M.spiral(p.size, p.inside, p.direction)
      elseif p.piece == "emptyOffset" then
        track[i] = M.emptyOffset(p.xOff, p.yOff, p.zOff, p.dirOff, p.absolute)
      end

      track[i].invalid = true
      track[i].fresh = p.fresh
      p.fresh = false
      p.invalid = false
      track[i].markerInfo = {
        height = p.height,
        bank = p.bank,
        width = p.width,
        basePosition = vec3(),
        position = vec3(),
        zOffset = 0
      }
    end
    track[i].height = p.height
    track[i].bank = p.bank
    track[i].width = p.width
    track[i].hasCheckPoint = p.hasCheckPoint
  end
end


----------------------------
--track editor functions --
----------------------------

--initializes the track.
local function initTrack() 
  M.unloadAll()
  pieces = {  
      { 
        piece = "init",
        position = vec3(0,0,0),
        bank = 0, 
        height = 0, 
        width = 10,
        fresh = true
      }
  }
  -- initial track position
  trackPosition = {
    position = vec3(),
    hdg = 0
  }
  -- position track before camera, above vehicle or at origin, depending on availability
  if M.positionTrackBeforeCamera() then
    M.rotateTrackToCamera()
  elseif M.positionTrackAboveVehicle() then
    M.rotateTrackToTrackVehicle()
  else
    M.setTrackPosition(0,0,15,0)
  end
  -- add an initial piece
  M.addForward(3)
end

--clears all the fields.
local function unloadAll()
  track = {}
  pieces = {}
  bankMarkers = {}
  widthMarkers = {}
  heightMarkers = {}
  stackedPieces = {}
  trackMarker = nil
  highQuality = false
  markersShown = false
  be:reloadCollision()
end

--removes the whole track, incl. meshes and markers.
local function removeTrack() 
  M.showMarkers(false)
  if track then
    for _,segment in ipairs(track) do
      if segment.mesh then
        segment.mesh:delete()
      end
    end
  end
  track = {}
  pieces = {}
  be:reloadCollision()
end

--returns the last track piece
local function getEndOfTrack() 
  return track[#track]
end

--destroys the last track element (minimum of two elements remain, because only one element makes no track)
local function revert()
  M.removeAt(#pieces)
end

--removes a piece at a position.
local function removeAt(index) 
  if #pieces <= 2 or index == 1 then
    return
  end

  if index < #pieces then
    for i = index, #pieces do
      pieces[i].invalid = true
    end
  end

  M.invalidatePiece(index-1)

  for i = index, #pieces-1 do
    pieces[i].invalid = true
    pieces[i] = pieces[i+1]
  end
  pieces[#pieces] = nil

  if track[#track].mesh ~= nil then
    track[#track].mesh:delete()
    track[#track].mesh = nil
  end
  track[#track] = nil

end

--these functions add pieces to the low-level track info stored in pieces.
--adding new types pieces need to be put in:
-- here
-- function to calculate their points
-- function toSegments => call own function with params
-- trackbuilder.js: piece information, parameters
-- trackbuilder.js: getSelectedTrackElementData
local function addForward(len, index, replace) M.addPiece({piece = 'forward', length = len}, index, replace) end
local function addCurve(len, hardness, dir, index, replace) M.addPiece({piece = 'curve', direction = dir, length = len, hardness = hardness}, index, replace) end
local function addOffsetCurve(len, off, hardness, index, replace) M.addPiece({piece = 'offsetCurve', length = len, xOffset = off, hardness=hardness}, index, replace) end
local function addSpiral(size, inside, dir, index, replace) M.addPiece({piece = 'spiral', size = size, direction = dir, inside = inside}, index, replace) end
local function addLoop(rad, off, index, replace) M.addPiece({piece = 'loop', radius = rad, xOffset = off}, index, replace) end
local function addEmptyOffset(xOff, yOff, zOff, dirOff, absolute, index, replace) M.addPiece({piece = 'emptyOffset', xOff = xOff, yOff = yOff, zOff = zOff, dirOff = dirOff, absolute = absolute}, index, replace) end

--adds a piece to the piece field, at a given position, can replace others, and handles marking affected pieces as invalid.
local function addPiece(params, index, replace)
  if not index then
    index = #pieces+1
  end

  if not replace then
    if index <= #pieces then
      for i = #pieces+1, index, -1 do
        pieces[i] = pieces[i-1]
        pieces[i].invalid = true
      end
    end
  end
  
  local tmp = {}
  if replace and pieces[index] ~= nil then
    tmp = { 
      width = pieces[index].width,
      height = pieces[index].height,
      bank = pieces[index].bank,
      mesh = pieces[index].mesh
    }
  end

  pieces[index] = params
  pieces[index].invalid = true

  if replace then
    pieces[index].bank = tmp.bank
    pieces[index].width = tmp.width
    pieces[index].height = tmp.height
    pieces[index].mesh = tmp.mesh
    pieces[index].invalid = true
    if tmp.bank then
     M.invalidatePiece(index,"bank")
    end
    if tmp.width then
      M.invalidatePiece(index,"width")
    end
    if tmp.height then
      M.invalidatePiece(index,"height")
    end
    if index ~= #track then
      M.invalidatePiece(index)
    end
    for i = index, #pieces do
      M.invalidatePiece(i)
      pieces[i].invalid = true
    end
  end
  pieces[index].fresh = not replace
  focusMarkerOn(index)
end

local function getHdgVector(hdg)
  return vec3(math.sin(hdg), math.cos(hdg), 0)
end

local function initialTrackPiece(p) 
  return  {
      position = p and p.position or vec3(0,0,0),
      hdg = p and p.hdg or 0,
      polyMult = 1,
      noPoints = true
    }
end

--creates a forward piece of the specified length.
local function forward( length )
  local tip = M.getEndOfTrack()
  --check in which direction we are actually going.
  local off = M.getHdgVector(tip.hdg)
  return
    {
      position = tip.position + off * length,
      origin = vec3(tip.position),
      controlPointA =  off * 0.25 * length,
      controlPointB = -off * 0.25 * length,
      hdg = tip.hdg,
      polyMult = length/2, 
      parameters = {
        piece = "forward",
        length = length
      }
    }
  
end

--creates a track fo specified length. direction allows for turning in 60?-steps
local function curve(length, direction, hardness)
  --if it aint a curve, why use this function?
  if direction == 0 then
    return M.forward(length)
  end

  if not hardness then hardness = 0 end

  local tip = M.getEndOfTrack()
  local off = vec3(sign(direction) * math.sqrt(3)/2, 1.5, 0) * length
  local cpLength = (0.04 + (hardness+5) * 0.12) * length 

  --rotate the offset by the hdg of the previous piece.
  off = M.rotateVectorByQuat(off, quatFromEuler(0,0,tip.hdg))

  return
    {
      position = tip.position + off,
      origin = vec3(tip.position),
      controlPointA = M.getHdgVector(tip.hdg) *cpLength,
      controlPointB = M.getHdgVector(tip.hdg + direction * math.pi / 3) * -cpLength,
      hdg = tip.hdg + direction * math.pi / 3,
      polyMult = length*1,
      parameters = {
        piece = "curve",
        length = length,
        direction = direction,
        hardness = hardness
      }
    }
  
end

--this creates an S-curve of specified length and offset to the left or right.
local function offsetCurve(length, xOffset, hardness)
  local tip = M.getEndOfTrack()
  local len = length
  --if the xOffset is not a multiple of 2, increase the length so that it still snaps to the triangular grid.
  if xOffset % 2 == 1 then
    len = len + 0.5
  end
  local off = vec3(
      math.sin(tip.hdg) * len + math.cos(tip.hdg) * xOffset *  math.sqrt(3)/2,
      math.cos(tip.hdg) * len - math.sin(tip.hdg) * xOffset *  math.sqrt(3)/2,
      0
  )
  if not hardness then hardness = 0 end
  local cpLength = math.abs(len) * (0.1 + (hardness+4) * 0.1)
 -- tip.forwardBezierCPLength = math.abs(len) * (0.1 + (hardness+4) * 0.1)
  return
    {
      position = tip.position + off,
      origin = vec3(tip.position),
      controlPointA = M.getHdgVector(tip.hdg) * cpLength,
      controlPointB = M.getHdgVector(tip.hdg) * -cpLength,
      hdg = tip.hdg,
      polyMult = math.abs(len /3) + math.abs(xOffset/3),
      parameters = {
        piece = "offsetCurve",
        length = length,
        xOffset = xOffset,
        hardness = hardness
      }
    }
end


--this creates a spiral piece, leading into a curve.
local function spiral(size, inside, dir)
  local tip = M.getEndOfTrack()
  local inverse = not inside
  local absSize = math.abs(size)

  local off = vec3(absSize * math.sqrt(3)/2, absSize * 2.5, 0)

  if inverse then
    off:set(absSize * math.sqrt(3), absSize * 2, 0)
  end

  off.x = off.x * sign(dir)
  off = M.rotateVectorByQuat(off, quatFromEuler(0,0,tip.hdg))

  local forwardCPLength = 1.111 * absSize
  local backwardCPLength = 1 * absSize
  if inverse then
    backwardCPLength = 1.111 * absSize
    forwardCPLength = 1 * absSize
  end
  return
    {
      position = tip.position + off,
      origin = vec3(tip.position),
      controlPointA = M.getHdgVector(tip.hdg) *forwardCPLength,
      controlPointB = M.getHdgVector(tip.hdg + dir * math.pi / 3) * -backwardCPLength,
      hdg = tip.hdg + dir * math.pi / 3,
      polyMult = absSize * 1,
      parameters = {
        piece = "spiral",
        size = size,
        direction = dir,
        inside = inside
      }
    }
end

--helper function for the loop calculation. returns point from an euler spiral.
local function fresnelSC(d) 
    local point = {x = 0, y = 0}
    if d == 0 then return point end
    local dx, dy
    
    local oldt = 0
    local current = {}
    
    local subdivisions = math.max(150,math.floor(d*400))
    if subs then 
      subdivisions = subs
    end

    local dt = d/subdivisions

    for i=0, subdivisions-1 do
        local t= (i*d)/subdivisions
        dt = (((i+1)*d)/subdivisions) - t

        oldt = t
        dx = math.cos( t*t * math.pi/2 ) * dt
        dy = math.sin( t*t * math.pi/2 ) * dt     
        point= {x = point.x + dx, y = point.y + dy}    
    end
    return point
end

--creates a looping.
local function loop(xOffset, radius)
  local tip = M.getEndOfTrack()
  if radius < 1 then
    radius = 1
  end
  
  --create custom points. treat off x/y as 0/0, ignore heading of tip
  --scaling and rotating is done in converting to Spline.
  --make sure that the first point is at -x/-y.
  local numPoints = radius * 7 + math.abs(xOffset*2)
  if numPoints < 48 then
    numPoints = 48
  end
  if numPoints > 300 then
    numPoints = 300
  end
  if numPoints%2 == 1 then
    numPoints = numPoints +1
  end
  
  local offset = xOffset * math.sqrt(3)
  local off = vec3(
      math.sin(tip.hdg) * radius + math.cos(tip.hdg) * offset,
      math.cos(tip.hdg) * radius - math.sin(tip.hdg) * offset,
      0
  )

  --this is the center position of the looping. used for mirroring.
  local cX = M.fresnelSC(math.sqrt(2)).x
  local sclaingFactor = gridScale*radius/(2*cX)
  local customPoints = {}
  --current length of the loop
  local len = 0

  for i = 0, numPoints-1 do
    local t = i/numPoints
    --halfT is the value we plug into the fresnel function.
    local halfT = t
    if t > 0.5 then
      halfT = 1-t
    end
    halfT = halfT * math.sqrt(2) * 2

    local tan = math.atan2(math.sin(halfT*halfT * math.pi/2), math.cos(halfT*halfT*math.pi/2)) 
    local f = M.fresnelSC(halfT)

    if t > 0.5 then
      f.x = -f.x + 2*cX
      tan = -tan
    end
    local p = {
      position = vec3(
        0,
        -radius+  f.x * (sclaingFactor * heightScale/gridScale),
        f.y*sclaingFactor
        ),
      rot = quatFromEuler(tan,0,0)
    }
    customPoints[i+1] = p

    --calculate some length infos.
    if i > 0 then
      customPoints[i+1].dist = customPoints[i].position:distance(customPoints[i+1].position)
    else
      customPoints[i+1].dist = 0
    end
    if i > 0 then
      len = len + customPoints[i+1].dist
    end
  end
  --after the first pass, add the xOffset and tilt the track to match the offset.
  local currentLen = 0
  for i = 0, numPoints-1 do
    currentLen = currentLen + customPoints[i+1].dist

    local t = currentLen / len
    local off, slope = smoothSlope(t,offset)
    customPoints[i+1].position.x = -offset + off
    local tan = -(math.atan2(len,slope) - math.pi/2)
    local nq = quatFromEuler(0,0,-tan*4):__mul(customPoints[i+1].rot)
    customPoints[i+1].rot = nq
  end

  -- adjust the first point to be exactly where needed.
  customPoints[1] = {
    position = vec3(-offset, -radius, 0),
    rot = quatFromEuler(0,0,0)
  }
  customPoints[#customPoints+1] = {
    position = vec3(0,0, 0),
    rot = quatFromEuler(0,0,0)
  }
  return
    {
      position = tip.position + off,
      origin = vec3(tip.position),
      hdg = tip.hdg,
      polyMult = 4, 
      customPoints = customPoints,
      parameters = {
        piece = "loop",
        xOffset = xOffset,
        radius = radius
      }
    }
end

local function emptyOffset(xOff, yOff, zOff, dirOff, absolute)
  local tip = M.getEndOfTrack()
  if absolute then
    tip = trackPosition
  end
  local adjustedYOff = yOff
  if xOff % 2 == 1 then
    adjustedYOff = adjustedYOff + 0.5
  end
  local off = vec3(
      math.sin(tip.hdg) * adjustedYOff + math.cos(tip.hdg) * xOff *  math.sqrt(3)/2,
      math.cos(tip.hdg) * adjustedYOff - math.sin(tip.hdg) * xOff *  math.sqrt(3)/2,
      zOff
  )
  return
    {
      position = tip.position + off,
      origin = vec3(tip.position),
      hdg = tip.hdg + dirOff * math.pi / 3,
      polyMult = 0,
      noPoints = true,
      parameters = {
        piece = "emptyOffset",
        xOff = xOff,
        yOff = yOff,
        zOff = zOff,
        dirOff = dirOff,
        absolute = absolute
      }
    }

end

--helper function to rotate a vector by a quat.
local function rotateVectorByQuat(v, q)
  return q:__mul(v)
end

-----------------------
--Import and Export --
-----------------------

--exports the current track to a simple lua table.
local function exportTrackToTable()
  local export = {
    gridScale = gridScale,
    heightScale = heightScale,
    pieces = {},
    trackPosition = 
    {
      x = trackPosition.position.x,
      y = trackPosition.position.y,
      z = trackPosition.position.z,
      hdg = trackPosition.hdg
    },
    connected = trackClosed,
    defaultLaps = defaultLaps,
    reversible = reversible
  }

  for i,p in ipairs(pieces) do
    export.pieces[i] = {
      piece = p.piece,
      length = p.length,
      direction = p.direction,
      hardness = p.hardness,
      xOffset = p.xOffset,
      size = p.size,
      radius = p.radius,
      xOff = p.xOff,
      yOff = p.yOff,
      zOff = p.zOff,
      dirOff = p.dirOff,
      inside = p.inside,
      absolute = p.absolute,

      height = p.height,
      width = p.width,
      bank = p.bank
    }
  end

  return export
end

--imports the track from a table. destroys current track.
local function importTrackFromTable(import)
  M.removeTrack()
  M.clearStack()
  currentSelected = 1
  gridScale = import.gridScale
  heightScale = import.heightScale
  pieces = import.pieces
  defaultLaps = import.defaultLaps or 2
  reversible = import.reversible or false
  fixedCheckpoints = import.fixedCheckpoints or false
  local zOff = 0
  if pieces and pieces[1].z == 15 then
    zOff = 15
  end
  M.setTrackPosition(import.trackPosition.x, import.trackPosition.y, import.trackPosition.z + zOff,import.trackPosition.hdg)

  
  for i, p in ipairs(pieces) do
    p.invalid = true
    invalidatePiece(i)
  end

end

--restores the track from the given file by name
local function load(originalFilename, instantHighQuality, increasePointMult)
  local filename = 'trackEditor/'..originalFilename..'.json'
 
  if FS:fileExists(filename) then
    local read = readJsonFile(filename)
    if not read then
        log('I',logTag,'No track found in file Documents/BeamNG.drive/'..filename)
        return
    end
    M.importTrackFromTable(read)

    M.setHighQuality(true)
    --finally, create the track.
    local oldPointMult = pointsMultiplier
    if increasePointMult then
      pointsMultiplier = pointsMultiplier * 1.5
    end
    M.makeTrack(instantHighQuality)
    if increasePointMult then
      pointsMultiplier = oldPointMult
    end
  else
      log('I',logTag,'Could not find file Documents/BeamNG.drive/'..filename)
  end
  guihooks.trigger('Message', {ttl = 10, msg = 'Succesfully loaded '..originalFilename, category = "fill", icon = "check_circle"})
end

--only loads the json of a track (for getting infos such as length and author)
local function loadJSON(originalFilename)
  local filename = 'trackEditor/'..originalFilename..'.json'
 
  if FS:fileExists(filename) then
    local read = readJsonFile(filename)
    if not read then
        log('I',logTag,'No track found in file Documents/BeamNG.drive/'..filename)
        return nil
    end
    return read
  else
      log('I',logTag,'Could not find file Documents/BeamNG.drive/'..filename)
      return nil
  end
end

--saves the track to the given file by name
local function save(filename)    
  local date = os.date("*t")
  local exported = M.exportTrackToTable()

  --additional info, not important for track generation
  local vehicle = be:getPlayerVehicle(0)
  if vehicle then
    exported.author = getVehicleLicenseName(vehicle)
  else
    exported.author = "Anonymous"
  end
  exported.date = os.time() .. ""
  exported.length = track[#track].endLength
  exported.connected = trackClosed

  filename = filename or string.format("%.4d-%.2d-%.2d_%.2d-%.2d-%.2d", date.year,date.month,date.day, date.hour,date.min,date.sec)
  filename = 'trackEditor/'..filename..'.json';

  serializeJsonToFile(filename,exported, false)
  log('I',logTag,'Serialized track to file Documents/BeamNG.drive/'..filename)
  guihooks.trigger('Message', {ttl = 10, msg = 'Serialized track to file Documents/BeamNG.drive/'..filename, category = "fill", icon = "save"})
end

--renames a file
local function rename( oldName, newName )
  local pre = 'trackEditor/'
  if not FS:fileExists(pre..oldName..'.json') then
      log('I',logTag,'Failed renaming '..oldName..' to '..newName..': File not found')
      return 
  end
  FS:renameFile(pre..oldName..'.json', pre..newName..'.json')
  FS:removeFile(pre..oldName..'.json')
  log('I',logTag,'Succesfully renamed '..oldName..' to '..newName..'')
  guihooks.trigger('Message', {ttl = 10, msg = 'Succesfully renamed '..oldName..' to '..newName..'', category = "fill", icon = "save"})
end

--reloads the list of all available tracks, sends those to the app
local function getCustomTracks()
  local tracks = {}
  for i, file in ipairs(FS:findFilesByPattern('trackEditor/','*.json',-1,true,false)) do
      local _, fn, e = string.match(file, "(.-)([^/]-([^%.]-))$")
      tracks[i] = fn:sub(1,#fn - #e - 1)
  end
  return tracks
end

-- Hook for deleting the track when the level is unloaded.
local function onClientEndMission()
  M.unloadAll()
end

local function start()
  positionVehicle()
end

--positioning
M.addCheckPointPositions = addCheckPointPositions
M.positionVehicle = positionVehicle
M.setTrackPosition = setTrackPosition
M.getTrackPosition = getTrackPosition
M.positionTrackAboveVehicle = positionTrackAboveVehicle
M.positionTrackBeforeCamera = positionTrackBeforeCamera
M.rotateTrackToCamera = rotateTrackToCamera
M.rotateTrackToTrackVehicle = rotateTrackToTrackVehicle

M.getPieceInfo = getPieceInfo
M.showMarkers = showMarkers
M.setAllPiecesToAsphalt = setAllPiecesToAsphalt
M.setHighQuality = setHighQuality
M.stackToCursor = stackToCursor
M.stack = stack
M.applyStack = applyStack
M.deepcopy = deepcopy
M.getStackCount = getStackCount
M.clearStack = clearStack
M.getSelectedTrackInfo = getSelectedTrackInfo
M.setDefaultLaps = setDefaultLaps
M.setReversible = setReversible


M.getHdgVector = getHdgVector
M.onUpdate = onUpdate
--marker functions 
M.focusMarkerOn = focusMarkerOn
M.createMarkers = createMarkers
M.addBankMarker = addBankMarker
M.addHeightMarker = addHeightMarker
M.addWidthMarker = addWidthMarker
M.markerChange = markerChange
M.bank = bank
M.elevate = elevate
M.width = width
M.interpolateSegment = interpolateSegment
--track to mesh functions
M.makeTrack = makeTrack


M.invalidatePiece = invalidatePiece
M.toSegments = toSegments
M.calculateCustomPoints = calculateCustomPoints
M.convertToSpline = convertToSpline

--track editor functions 
M.initTrack = initTrack
M.unloadAll = unloadAll
M.removeTrack = removeTrack
M.getEndOfTrack = getEndOfTrack
M.revert = revert
M.removeAt = removeAt
M.addForward = addForward
M.addCurve = addCurve
M.addOffsetCurve = addOffsetCurve
M.addSpiral = addSpiral
M.addLoop = addLoop
M.addPiece = addPiece
M.addEmptyOffset = addEmptyOffset

M.initialTrackPiece = initialTrackPiece
M.forward = forward
M.curve = curve
M.offsetCurve = offsetCurve
M.spiral = spiral
M.fresnelSC = fresnelSC
M.loop = loop
M.emptyOffset = emptyOffset

M.rotateVectorByQuat = rotateVectorByQuat

M.setSegmentMaterial = setSegmentMaterial
--Import and Export 
M.exportTrackToTable = exportTrackToTable
M.importTrackFromTable = importTrackFromTable
M.load = load
M.loadJSON = loadJSON
M.save = save
M.rename = rename
M.getCustomTracks = getCustomTracks
M.onClientEndMission = onClientEndMission
M.interpolateField = interpolateField
M.snapToGrid = snapToGrid
M.measureTrack = measureTrack

M.getBezierPoints = getBezierPoints
M.initTrack()

return M