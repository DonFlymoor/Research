local M = {}
local logTag = 'simpleSplineTrack'

--these two regulate the scaling of the track, though not the width oth scaling of the cross section.
local gridScale = 4
local heightScale = 1



--this creates the actual mesh from the track.
local mesher = require('util/splineToProceduralMesh')
--list of all the track pieces for the current track.
local capObjects = {}
--info of the current track pieces.
local pieces = {}
--more concrete info fo the track.
local track = {}
--point-by-point info of the current track (after meshing)
local currentRet = {}

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

local highQuality = false

-- stack
local stackedPieces = {}
-- where the origin of the track is in the world.
local trackPosition = {}
-- whether the markers are shown or not.
local markersShown = true


----------------------------------------------
--helper and control functions for the app --
----------------------------------------------

--this function creates evenly spaced checkpoints, and adds them to the scenario etc.
local function addCheckPointPositions() 
  local cpCount = math.ceil(currentRet[#currentRet].uvY / 300)
  if cpCount < 3 then
    cpCount = 3
  end
  local dist = currentRet[#currentRet].uvY / cpCount
  local cur = dist -1
  local checkpointPositions = {}

  local scenario = scenario_scenarios.getScenario()

  scenario.lapConfig = {}
  scenario.nodes = {}

  for i,p in ipairs(currentRet) do 
    if p.uvY > cur then
      local num = #checkpointPositions+1

      cur = cur + dist
      checkpointPositions[#checkpointPositions+1] = {
        x = p.x,
        y = p.y,
        z = p.z
      }

      local rot = quatFromEuler(0,0,math.pi):__mul(p.bank:__mul(p.rot))
      local off = M.rotateVectorByQuat({x=0,y=-1,z=0}, rot )

      scenario.nodes['gym_'..num] = {}
      scenario.nodes['gym_'..num].pos = vec3(p.x,p.y,p.z)
      scenario.nodes['gym_'..num].rot = vec3(off.x,off.y,off.z)
      scenario.nodes['gym_'..num].radius = p.width/2 +1
      
        scenario.lapConfig[#scenario.lapConfig+1] = 'gym_'..num
      
    end
  end

  scenario.initialLapConfig = scenario.lapConfig
end

--places the players car at the beginning of the track.
local function positionVehicle()
  local pos= vec3(currentRet[1].x, currentRet[1].y, currentRet[1].z+ 0.25)
 --dump("start is " .. start)
 --dump(currentRet[1])
  local rot = quatFromEuler(0,0,math.pi):__mul(currentRet[1].bank:__mul(currentRet[1].rot))
  local off = M.rotateVectorByQuat({x=0,y=-4,z=0}, rot )
  pos.x = pos.x + off.x
  pos.y = pos.y + off.y
  pos.z = pos.z + off.z
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
end

--sets the values of the trackPosition field
local function setTrackPosition(x,y,z,hdg) 
  trackPosition = {
    x = x,
    y = y ,
    z = z ,
    hdg = -(hdg/180) * math.pi
  }
end

--gets the values of the trackPosition field.
local function getTrackPosition() 
  return trackPosition
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
      trackPosition = trackPosition,
      currentSelected = currentSelected
    }
  end
end

--toggles visibility of markers on or off. (actually destroys and re-creates the markers for width, height and bank.)
local function showMarkers(show)

  if show then
    --if there are already markers, we dont need to recreate them, otherwise do create them
    if #heightMarkers > 0 or #bankMarkers > 0 or #widthMarkers > 0 then
      return
    else
      M.createMarkers()
    end
    M.focusMarkerOn(currentSelected)

  else
    --destroy all the markers
    while #heightMarkers > 0 do
      local m = #heightMarkers
      if heightMarkers[m] then
        heightMarkers[m]:delete()
      end
      heightMarkers[m] = nil
    end

    while #bankMarkers > 0 do
      local m = #bankMarkers
      if bankMarkers[m] then
        bankMarkers[m]:delete()
      end
      bankMarkers[m] = nil
    end

    while #widthMarkers > 0 do
      local m = #widthMarkers
      if widthMarkers[m] then
        widthMarkers[m]:delete()
      end
      widthMarkers[m] = nil
    end

    if trackMarker then
      trackMarker:delete()
      trackMarker = nil
    end

    if pieces then
      if pieces[currentSelected] and pieces[currentSelected].mesh then
        pieces[currentSelected].mesh.material = String("a_asphalt_01_a")
        pieces[currentSelected].mesh:updateMaterial()
      end
    end

  end
  markersShown = show
end

--sets the track to high quality or not.
local function setHighQuality(hq)
  highQuality = hq
end

--lets the app scale the gridsize of the track. (currently not used)
local function setGridSize(size)
  if size < 1 then 
    size = 1 
  end
  gridScale = size
end

--highlights the currently selected piece, by applying a green texture.
local function setTrackHighlight()
  for i,p in ipairs(pieces) do
    if p.mesh then  
      if i == currentSelected then
        p.mesh.material = String("Grid512_ForestGreenLines_Mat")
      else
        p.mesh.material = String("a_asphalt_01_a")
      end
      p.mesh:updateMaterial()
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
 --dump("stack:")
 --dump(stackedPieces)
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


local function getSelectedTrackInfo()
  return track[currentSelected]
end

----------------------
--marker functions --
----------------------
--this places the track marker on a track element by index.
local function focusMarkerOn(index)
  local tip = track[index]
  if not tip then return end
  if not markersShown then
    M.showMarkers(true)
  end

  for i = 1, #currentRet do
    if currentRet[i].originalIndex ~= nil and currentRet[i].originalIndex == index then
      trackMarker:setPosition(Point3F(currentRet[i].x, currentRet[i].y, currentRet[i].z))
    end
  end
  
  trackMarker:setScale(Point3F(2,2,2))
  
  if pieces[currentSelected] and pieces[currentSelected].mesh then
    pieces[currentSelected].mesh.material = String("a_asphalt_01_a")
    pieces[currentSelected].mesh:updateMaterial()
  end
  currentSelected = index
  if pieces[currentSelected].mesh then
    pieces[currentSelected].mesh.material = String("Grid512_ForestGreenLines_Mat")
    pieces[currentSelected].mesh:updateMaterial()
  end

 --M.setTrackHighlight()
end

--creates and places all the neccesary markers.
local function createMarkers() 
  --make the trackMarker visible.
  if trackMarker then
    trackMarker:delete()
    trackMarker = nil
  end

  TorqueScript.eval([[
  new TSStatic(track_marker) {
       shapeName = "art/shapes/interface/checkpoint_marker_sphere.dae";
       playAmbient = "1";
       meshCulling = "0";
       originSort = "0";
       collisionType = "Collision Mesh";
       decalType = "Collision Mesh";
       allowPlayerStep = "1";
       renderNormals = "0";
       forceDetail = "-1";
       position = "0 0 0";
       rotation = "1 0 0 0";
       scale = "0 0 0";
       useInstanceRenderData = "1"; // this activate per instace properties as instanceColor
       instanceColor = "1 1 1 2";
       canSave = "1";
       canSaveDynamicFields = "1";
    };
  ]])

  trackMarker = scenetree.findObject('track_marker')

  --this stores the info the mesh generation returns. using this ensures that the positions, rotation etc. are actually that of the created track.
  local ret = currentRet
  
  --height markers: fetch all indizes of track elements that actually have a height attached to them.
  local heightIndexes = {}
  for i = 1, #ret do
    if ret[i].originalIndex ~= nil and track[ret[i].originalIndex].height ~= nil then
      heightIndexes[#heightIndexes+1] = i
    end
  end

  --expand/shrink the list of markers so that it matches the number of the elements that have a height.
  while #heightMarkers < #heightIndexes do
    M.addHeightMarker()
  end

  while #heightMarkers > #heightIndexes do
    local m = #heightMarkers
    heightMarkers[m]:delete()
    heightMarkers[m] = nil
  end

  --go through all the height-containing elements, transform the markers so that they fit.
  for i = 1, #heightIndexes do
    local node = ret[heightIndexes[i]]
    heightMarkers[i]:setPosition(Point3F(node.x,node.y,node.z-1))
    heightMarkers[i]:setScale(Point3F(1,1, node.z -1))
  end


  --bank markers. Here, we need to destroy all the markers first, and then create them so that 
  --they already fit, since the rotation of objects cant be controlled through lua (afaik)
  while #bankMarkers > 0 do
    local m = #bankMarkers
    bankMarkers[m]:delete()
    bankMarkers[m] = nil
  end
  --after destruction, simply create one banking marker for each element that has a banking.
  for i = 1, #ret do
    if ret[i].originalIndex ~= nil and track[ret[i].originalIndex].bank ~= nil then
      M.addBankMarker(
        {x = ret[i].x, y = ret[i].y , z = ret[i].z},
        quatFromEuler(0,0,0):__mul(quatFromEuler(0,0,math.pi/2)):__mul(ret[i].bank:__mul(ret[i].rot)) --this quaternion rotates the marker correctly. better not touch...
        )
    end
  end

 while #widthMarkers > 0 do
    local m = #widthMarkers
    widthMarkers[m]:delete()
    widthMarkers[m] = nil
  end
  --after destruction, simply create one wudth marker for each element that has a banking.
  for i = 1, #ret do
    if ret[i].originalIndex ~= nil and track[ret[i].originalIndex].width ~= nil then
      M.addWidthMarker(
        {x = ret[i].x, y = ret[i].y , z = ret[i].z},
        quatFromEuler(0,0,0):__mul(quatFromEuler(0,0,math.pi/2)):__mul(ret[i].bank:__mul(ret[i].rot)) --this quaternion rotates the marker correctly. better not touch...
        , track[ret[i].originalIndex].width)
    end
  end
end

--creates a banking marker at the specified position with the correct rotation.
local function addBankMarker(pos, rot)
  local index = #bankMarkers

  --transform the quat to the format that torque uses
  local quat = {x=1,y=0,z=0,w=0}
  quat.w = 2 * math.acos(rot.w)
  local sinHalfAngle = math.sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z)
  if sinHalfAngle ~= 0 then
    quat.x = rot.x / sinHalfAngle
    quat.y = rot.y / sinHalfAngle
    quat.z = rot.z / sinHalfAngle
  end
  quat.w = quat.w * 180 / math.pi


  --create and store the marker.
  TorqueScript.eval([[
  new TSStatic(bankMarker]]..index..[[) {
       shapeName = "art/shapes/interface/track_editor_marker.dae";
       playAmbient = "1";
       meshCulling = "0";
       originSort = "0";
       collisionType = "Collision Mesh";
       decalType = "Collision Mesh";
       allowPlayerStep = "1";
       renderNormals = "0";
       forceDetail = "-1";
       position = "]].. pos.x .. " " ..  pos.y .. " " ..  pos.z .. [[";
       rotation = "]]..quat.x .. " " .. quat.y .. " " .. quat.z .. " " .. quat.w .. [[";
       scale = "5 0.1 2.5";
       useInstanceRenderData = "1"; // this activate per instace properties as instanceColor
       instanceColor = "1 0 0 1";
       canSave = "1";
       canSaveDynamicFields = "1";
    };
  ]])
  bankMarkers[index+1] = scenetree["bankMarker"..index]
end

--creates a height marker.
local function addHeightMarker()
  --create and store the marker.
  local index = #heightMarkers
  TorqueScript.eval([[
  new TSStatic(heightMarker]]..index..[[) {
       shapeName = "art/shapes/interface/track_editor_marker.dae";
       playAmbient = "1";
       meshCulling = "0";
       originSort = "0";
       collisionType = "Collision Mesh";
       decalType = "Collision Mesh";
       allowPlayerStep = "1";
       renderNormals = "0";
       forceDetail = "-1";
       position = "0 0 0";
       rotation = "1 0 0 180";
       scale = "2 2 20";
       useInstanceRenderData = "1"; // this activate per instace properties as instanceColor
       instanceColor = "0.0 0 1 1";
       canSave = "1";
       canSaveDynamicFields = "1";
    };

  ]])
  heightMarkers[index+1] = scenetree["heightMarker"..index]
end

--creates two width markers
local function addWidthMarker(pos, rot, width)
  --create and store marker 1
  local index = #widthMarkers


  --transform the quat to the format that torque uses
  local quat = {x=1,y=0,z=0,w=0}
  quat.w = 2 * math.acos(rot.w)
  local sinHalfAngle = math.sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z)
  if sinHalfAngle ~= 0 then
    quat.x = rot.x / sinHalfAngle
    quat.y = rot.y / sinHalfAngle
    quat.z = rot.z / sinHalfAngle
  end
  quat.w = quat.w * 180 / math.pi
  local right = M.rotateVectorByQuat({y=width/2+1,x=0,z=0}, rot)
  local left =  M.rotateVectorByQuat({y=-width/2-1,x=0,z=0}, rot)

  --create and store the marker.
  TorqueScript.eval([[
  new TSStatic(widthMarker]]..index..[[) {
       shapeName = "art/shapes/interface/checkpoint_marker_sphere.dae";
       playAmbient = "1";
       meshCulling = "0";
       originSort = "0";
       collisionType = "Collision Mesh";
       decalType = "Collision Mesh";
       allowPlayerStep = "1";
       renderNormals = "0";
       forceDetail = "-1";
       position = "]].. pos.x+right.x .. " " ..  pos.y+right.y .. " " ..  pos.z+right.z .. [[";
       rotation = "]]..quat.x .. " " .. quat.y .. " " .. quat.z .. " " .. quat.w .. [[";
       scale = "2 2 2";
       useInstanceRenderData = "1"; // this activate per instace properties as instanceColor
       instanceColor = "0 1 0 1";
       canSave = "1";
       canSaveDynamicFields = "1";
    };
  ]])
  widthMarkers[index+1] = scenetree["widthMarker"..index]

   TorqueScript.eval([[
  new TSStatic(widthMarker]]..index..[[b) {
       shapeName = "art/shapes/interface/checkpoint_marker_sphere.dae";
       playAmbient = "1";
       meshCulling = "0";
       originSort = "0";
       collisionType = "Collision Mesh";
       decalType = "Collision Mesh";
       allowPlayerStep = "1";
       renderNormals = "0";
       forceDetail = "-1";
       position = "]].. pos.x+left.x .. " " ..  pos.y+left.y .. " " ..  pos.z+left.z .. [[";
       rotation = "]]..quat.x .. " " .. quat.y .. " " .. quat.z .. " " .. quat.w .. [[";
       scale = "2 2 2";
       useInstanceRenderData = "1"; // this activate per instace properties as instanceColor
       instanceColor = "0 1 0 1";
       canSave = "1";
       canSaveDynamicFields = "1";
    };
  ]])
  widthMarkers[index+2] = scenetree["widthMarker"..index..'b']
end

-----------------------------
--track to mesh functions --
-----------------------------




--makes an actual mesh from the track info.
local function makeTrack(completeRefresh) 
 --perf.enable(1)

  if #pieces == 0 then
    M.unloadAll()
    M.initTrack()
  end


  M.checkInvalidity()
  if completeRefresh then
    for _,p in ipairs(pieces) do
      p.invalid = true
    end
  end
  --transform raw track data to actual track info
  M.toActualTrack()

  --first, transform the track to the format that the mesh generator accepts.
  local s = M.convertToSpline()
  s.caps = capObjects


  --apply track rotation and translation 
  local rX = {x = math.cos(trackPosition.hdg), y = -math.sin(trackPosition.hdg)}
  local rY = {x = math.sin(trackPosition.hdg), y = math.cos(trackPosition.hdg)}
  local rotQuat = quatFromEuler(0,0,trackPosition.hdg)
  local cpRot = quatFromEuler(0,0,trackPosition.hdg)

  local nX,nY

  for _,p in ipairs(s) do
    nX = p.x * rX.x + p.y * rX.y
    nY = p.x * rY.x + p.y * rY.y
    p.x = nX + trackPosition.x
    p.y = nY + trackPosition.y
    p.z = p.z + trackPosition.z
    if p.forwardControlPoint then
      nX = p.forwardControlPoint.x * rX.x + p.forwardControlPoint.y * rX.y
      nY = p.forwardControlPoint.x * rY.x + p.forwardControlPoint.y * rY.y
      p.forwardControlPoint.x = nX + trackPosition.x
      p.forwardControlPoint.y = nY + trackPosition.y
      p.forwardControlPoint.z = p.forwardControlPoint.z + trackPosition.z
    end
    if p.backwardControlPoint then
      --dump(p.backwardCP)
      nX = p.backwardControlPoint.x * rX.x + p.backwardControlPoint.y * rX.y
      nY = p.backwardControlPoint.x * rY.x + p.backwardControlPoint.y * rY.y
      p.backwardControlPoint.x = nX + trackPosition.x
      p.backwardControlPoint.y = nY + trackPosition.y
      p.backwardControlPoint.z = p.backwardControlPoint.z + trackPosition.z
     --dump(p.backwardCP)
    end
    if p.customPoints then
      for _,c in ipairs(p.customPoints) do
        nX = c.x * rX.x + c.y * rX.y
        nY = c.x * rY.x + c.y * rY.y
        c.x = nX + trackPosition.x
        c.y = nY + trackPosition.y
        c.z = c.z + trackPosition.z  
        
      end
    end

    if p.rot then
      p.rot = rotQuat:__mul(p.rot)
    end

  end

  -- dumps all the pieces which are invalid.
  --[[
  local dbg = ""
  local iCount = 0
  for i = 1, #pieces do
    if pieces[i].invalid then
      dbg = dbg.. "INV "
      iCount = iCount+1
    else
      dbg = dbg.. "ok "
    end
  end

  for _, p in ipairs(pieces) do
    p.invalid = nil
  end
  
  dump(dbg)
  ]]

  local meshes

  --store the list of objects and the spline with the finalized values from the created meshes.
  meshes, currentRet = mesher.materialize(s, highQuality)

  for i = 2, #pieces do
    if meshes[i-1] ~= '' then
      pieces[i].mesh = meshes[i-1]
    end
  end
  capObjects = meshes.caps
  --create the markers.
  if markersShown then
    M.createMarkers()
  end
  markerChanges = {}

  --perf.disable()
  --perf.saveDataToCSV('splineTrackPerf.csv')
end

--checks and marks invalid pieces.
local function checkInvalidity()
  for _,t in ipairs({'bank','height','width'}) do
    if markerChanges[t] ~= nil then
      for _,index in ipairs(markerChanges[t]) do
        M.propagateInvalidity(index,t)
      end
    end
  end
  if markerChanges[''] ~= nil then
 --dump("Invalid pieces by default:")
 --dump(markerChanges[''])
    for _,index in ipairs(markerChanges['']) do
      if pieces[index] then
        pieces[index].invalid = true
      end
    end
  end
  if pieces[#pieces-1] then
    pieces[#pieces-1].invalid = true
  end
  if pieces[#pieces] then
    pieces[#pieces].invalid = true
  end
end

--propagates the invalidity of pieces to the previous/next occurence of the type of marker that was changed.
local function propagateInvalidity(originalIndex, type)
  if not pieces[originalIndex] then return end

  local found = false
  local currentValue = pieces[originalIndex][type]
  local otherValue = nil
  local candidates = {}
  for i = originalIndex+1, #pieces do
    if pieces[i] then
      if not found then
        candidates[#candidates+1] = i
        found = pieces[i][type] ~= nil
        if found then
          otherValue = pieces[i][type]
        end
      end
    end
  end

  for _,c in ipairs(candidates) do
    pieces[c].invalid = true
  end

  found = false
  currentValue = pieces[originalIndex][type]
  otherValue = nil
  candidates = {}
  for i = originalIndex-1, 1, -1 do
    if pieces[i] then
      if not found then
        candidates[#candidates+1] = i
        found = pieces[i][type] ~= nil
        if found then
          otherValue = pieces[i][type]
        end
      end
    end
  end

  for _,c in ipairs(candidates) do
    pieces[c].invalid = true
  end


  if pieces[originalIndex] then
    pieces[originalIndex].invalid = true
  end
end

--marks a piece to be invalidated later, either in general or for a specific type.
local function invalidatePiece(index, types)
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
local function toActualTrack()
  track = {}
  
  --recreate track piece by piece and add infos such as width, height and bank.
  for i,p in ipairs(pieces) do
    if p.piece == "init" then
      track[i] = M.init()
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
    end
   --dump(track)
    track[i].height = p.height
    track[i].bank = p.bank
    track[i].width = p.width
  end
end

--scales and rotated custom points of a piece.
local function calculateCustomPoints(piece)

  if not piece.customPoints then 
   --dump("no custom points to calc")
    return nil 
  end

  local xUnitVector = {
    x =   math.cos(piece.hdg),
    y = - math.sin(piece.hdg) 
  }
  local yUnitVector = {
    x = math.sin(piece.hdg),
    y = math.cos(piece.hdg)
  }
  local points = {}

  for _,p in ipairs(piece.customPoints) do
    local newP = {
      x = (piece.x + p.x * xUnitVector.x + p.y * yUnitVector.x) * gridScale,
      y = (piece.y + p.x * xUnitVector.y + p.y * yUnitVector.y) * gridScale,
      z = (piece.z + p.z) * heightScale,
      rot = p.rot:__mul(quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,piece.hdg + math.pi - trackPosition.hdg)))


    }
    points[#points+1] = newP
  end

  return points
end

--creates a format of the track that the mesh generator accepts
local function convertToSpline()
  local spline = {}
  local defaultBank, defaultHeight, defaultWidth
  --transfer base values to the new table
  for i = 1, #track do
    spline[#spline+1] = {
      x = track[i].x ,
      y = track[i].y ,
      z = track[i].z ,
      rot = quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,track[i].hdg + math.pi)), --this quat contains information to where the track is looking (on the x/y plane)
      polyMult = track[i].polyMult, --controls how many points this piece will use (higher for longer pieces)
      width = track[i].width,
      height = track[i].height,
      pitch = pitch,
      mesh = pieces[i].mesh,
     --invalid = pieces[i].invalid,
    --hasMesh = pieces[i].mesh ~= nil and not pieces[i].invalid,
      highlighted = i == currentSelected
    }

    spline[#spline].customPoints = M.calculateCustomPoints(track[i])
    if track[i].bank then
      spline[#spline].bank = quatFromEuler(0,-(track[i].bank/180) * math.pi  + math.pi,0) --this quat contains the banking information.
      spline[#spline].bankDeg = track[i].bank
    end
    defaultBank = track[i].bank or defaultBank
    defaultWidth = track[i].width or defaultWidth
    defaultHeight = track[i].height or defaultHeight
  end
 
  --add the default values to the end of the track, if not set
  if spline[#spline].bank == nil then
    spline[#spline].bank = quatFromEuler(0,-(defaultBank/180) * math.pi  + math.pi,0)
    spline[#spline].bankDeg = defaultBank
  end
  if spline[#spline].height == nil then
    spline[#spline].height = defaultHeight
  end
  if spline[#spline].width == nil then
    spline[#spline].width = defaultWidth
  end

  --snap to triangular grid
  for i = 1, #spline do
      local intX = spline[i].x / (math.sqrt(3)/2)
      local intY = spline[i].y / 0.5
       
      intX = round(intX)
      intY = round(intY)

      spline[i].x = intX * (math.sqrt(3)/2) * gridScale
      spline[i].y = intY * 0.5 * gridScale
      spline[i].z = spline[i].z * heightScale 
  end

  --detect closedness
  trackClosed = 
    spline[1].x == spline[#spline].x and
    spline[1].y == spline[#spline].y and
    spline[1].z == spline[#spline].z and
    spline[1].hdg == spline[#spline].hdg and
    spline[1].height == spline[#spline].height
   --dump(trackClosed)

  --when the track is closed, copy the parameters from the first element to the last.
  if trackClosed then
    spline[#spline].bank = quatFromEuler(0,-(spline[1].bankDeg/180) * math.pi  + math.pi,0)
    spline[#spline].bankDeg = spline[1].bankDeg
    spline[#spline].height = spline[1].height
    spline[#spline].width = spline[1].width
    M.invalidatePiece(#track)
    M.checkInvalidity()
  end

  for i = 1, #track do
    spline[i].invalid = pieces[i].invalid
  end




  --add control points for bezier
  for i = 1, #spline do
    local forwardBezierCPLength = track[i].forwardBezierCPLength or 0.5
    local forwardCP = M.rotateVectorByQuat({x=0,y=gridScale*forwardBezierCPLength,z=0}, spline[i].rot)
    spline[i].forwardControlPoint = {
      x = spline[i].x + forwardCP.x,
      y = spline[i].y + forwardCP.y,
      z = spline[i].z + forwardCP.z
    }
    local backwardBezierCPLength = track[i].backwardBezierCPLength or 0.5
    local backwardCP = M.rotateVectorByQuat({x=0,y=-gridScale*backwardBezierCPLength,z=0}, spline[i].rot)
    spline[i].backwardControlPoint = {
      x = spline[i].x + backwardCP.x,
      y = spline[i].y + backwardCP.y,
      z = spline[i].z + backwardCP.z
    }
  end

  return spline
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
        x = 0,
        y = 0,
        z = 15,
        bank = 0, --in deg
        height = 0, --in m
        width = 10 --in m
      }
  }
  trackPosition = {
    x = 0,
    y = 0 ,
    z = 0 ,
    hdg = 0
  }
  M.addForward(3)
end

--clears all the fields.
local function unloadAll()
  track = {}
  pieces = {}
  bankMarkers = {}
  widthMarkers = {}
  heightMarkers = {}
  capObjects = {}
  currentRet = {}
  stackedPieces = {}
  trackMarker = nil
  highQuality = false
  markersShown = false
  
end

--removes the whole track, incl. meshes and markers.
local function removeTrack() 
  M.showMarkers(false)
  if capObjects then
    for _,o in ipairs(capObjects) do
      if o then
        o:delete()
      end
    end
  end

  if pieces then
    for _,p in ipairs(pieces) do
      if p.mesh then
        p.mesh:delete()
      end
    end
  end
  capObjects = {}
  track = {}
  pieces = {}

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

  if pieces[index].mesh ~= nil then
    pieces[index].mesh:delete()
    pieces[index].mesh = nil
  end

  if index < #pieces then
    for i = index, #pieces do
      M.invalidatePiece(i,'')
    end
  end

  if pieces[index] then
      M.invalidatePiece(index-1,"bank")
  end
  if pieces[index] then
    M.invalidatePiece(index-1,"width")
  end
  if pieces[index] then
    M.invalidatePiece(index-1,"height")
  end
  M.invalidatePiece(index-1,'')

  for i = index, #pieces-1 do
    pieces[i] = pieces[i+1]
  end
  pieces[#pieces] = nil
end


--these functions add pieces to the low-level track info stored in pieces.

local function addForward(len, index, replace) M.addPiece({piece = 'forward', length = len}, index, replace) end
local function addCurve(len, hardness, dir, index, replace) M.addPiece({piece = 'curve', direction = dir, length = len, hardness = hardness}, index, replace) end
local function addOffsetCurve(len, off, hardness, index, replace) M.addPiece({piece = 'offsetCurve', length = len, xOffset = off, hardness=hardness}, index, replace) end
local function addSpiral(size, inside, dir, index, replace) M.addPiece({piece = 'spiral', size = size, direction = dir, inside = inside}, index, replace) end
local function addLoop(rad, off, index, replace) M.addPiece({piece = 'loop', radius = rad, xOffset = off}, index, replace) end


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
  if replace then
    pieces[index].bank = tmp.bank
    pieces[index].width = tmp.width
    pieces[index].height = tmp.height
    pieces[index].mesh = tmp.mesh

    if tmp.bank then
      M.invalidatePiece(index,"bank")
    end
    if tmp.width then
      M.invalidatePiece(index,"width")
    end
    if tmp.height then
      M.invalidatePiece(index,"height")
    end
    M.invalidatePiece(index,"")
  end
  for i = index, #pieces do
    M.invalidatePiece(i,"")
  end

  if params.bank then
      M.invalidatePiece(index,"bank")
  end
  if params.width then
    M.invalidatePiece(index,"width")
  end
  if params.height then
    M.invalidatePiece(index,"height")
  end

  currentSelected = currentSelected
  focusMarkerOn(index)
end


local function init() 
  return  {
      x = 0, --in units(grid)
      y = 0, --in units(grid)
      z = 15, --in units(heigth)
      polyMult = 1, --(in 10 / piece)
      hdg = 0 --in rad
    }

end

--creates a forward piece of the specified length.
local function forward( length )
  local tip = M.getEndOfTrack()

  --check in which direction we are actually going.
  local off = {
      x = math.sin(tip.hdg) * length,
      y = math.cos(tip.hdg) * length,
      z = 0
  }

  tip.forwardBezierCPLength = 0.25*length
  return
    {
      x = tip.x + off.x,
      y = tip.y + off.y,
      z = tip.z + off.z,
      hdg = tip.hdg,
      backwardBezierCPLength = 0.25 * length,
      polyMult = length/2, 
      parameters = { --for saving the track
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

  local tip = M.getEndOfTrack()
  local off = {
      z = 0
  }
  local sign = sign(direction)

  --theoretically, this function supports 120? and 180? curves, but only the 60? is actually used.
  --if math.abs(direction) == 1 then
  off.x = length * math.sqrt(3)/2
  off.y = length * 1.5
  if not hardness then hardness = 0 end

  
  tip.forwardBezierCPLength = (0.04 + (hardness+5) * 0.12) *length
  


 --[[ elseif math.abs(direction) == 2 then
      off.x = length * math.sqrt(3)*1.5
      off.y = length * 1.5
      tip.forwardBezierCPLength = 1.333 *length
  elseif math.abs(direction) == 3 then
      off.x = length * math.sqrt(3) * 2
      off.y = 0
      tip.forwardBezierCPLength = 2.333*length
    end
  ]]
  off.x = off.x * sign

  --rotate the offset by the hdg of the previous piece.
  local rotOff = M.rotateVectorByQuat({x = off.x, y = off.y, z = 0}, quatFromEuler(0,0,tip.hdg))
  off.x = rotOff.x
  off.y = rotOff.y

  
 return
    {
      x = tip.x + off.x,
      y = tip.y + off.y,
      z = tip.z + off.z,
      hdg = tip.hdg + direction * math.pi / 3,
      backwardBezierCPLength =tip.forwardBezierCPLength,
      polyMult = length*1,
      parameters = { --for saving the track
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
  local off = {
      x = math.sin(tip.hdg) * len + math.cos(tip.hdg) * xOffset *  math.sqrt(3)/2,
      y = math.cos(tip.hdg) * len - math.sin(tip.hdg) * xOffset *  math.sqrt(3)/2,
      z = 0
  }
  if not hardness then hardness = 0 end
  tip.forwardBezierCPLength = math.abs(len) * (0.1 + (hardness+4) * 0.1)
  return
    {
      x = tip.x + off.x,
      y = tip.y + off.y,
      z = tip.z + off.z,      
      hdg = tip.hdg ,
      backwardBezierCPLength = tip.forwardBezierCPLength,
      polyMult = math.abs(len /3) + math.abs(xOffset/3),
      parameters = { --for saving
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

  local off = {
      x = absSize * math.sqrt(3)/2,
      y = absSize * 2.5,
      z = 0
  }

  if inverse then
    off = {
      x = absSize * math.sqrt(3),
      y = absSize * 2,
      z = 0
    }
  end

  off.x = off.x * sign(dir)
  local rotOff = M.rotateVectorByQuat({x = off.x, y = off.y, z = 0}, quatFromEuler(0,0,tip.hdg))
  off.x = rotOff.x
  off.y = rotOff.y
  local backBzLen = 1 * absSize
  tip.forwardBezierCPLength = 1.111 * absSize
  if inverse then
    backBzLen = 1.111 * absSize
    tip.forwardBezierCPLength = 1 * absSize
  end
  return
    {
      x = tip.x + off.x,
      y = tip.y + off.y,
      z = tip.z + off.z,      
      hdg = tip.hdg + dir * math.pi / 3,
      backwardBezierCPLength = backBzLen,
      polyMult = absSize * 1,
      parameters = { --for saving
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
   --local t = curvatureStart
    
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
  --
  local numPoints = radius * 7 + math.abs(xOffset*2)
  if numPoints < 48 then
    numPoints = 48
  end
  if numPoints > 300 then
    numPoints = 300
  end
  if not highQuality then
    numPoints = numPoints / 4
  end
  if numPoints%2 == 1 then
    numPoints = numPoints +1
  end
  
  local offset = xOffset * math.sqrt(3)
  local off = {
      x = math.sin(tip.hdg) * radius + math.cos(tip.hdg) * offset,
      y = math.cos(tip.hdg) * radius - math.sin(tip.hdg) * offset,
      z = 0
  }


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
      x = 0,
      y = -radius+  f.x * (sclaingFactor * heightScale/gridScale),
      z = f.y*sclaingFactor,
      rot = quatFromEuler(tan,0,0)
    }
    customPoints[i+1] = p

    --calculate some length infos.
    if i > 0 then
      customPoints[i+1].dist = math.sqrt(math.pow(customPoints[i].z - customPoints[i+1].z,2)+math.pow(customPoints[i].y - customPoints[i+1].y,2))
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
    customPoints[i+1].x = -offset + (-2*t*t*t + 3*t*t) * offset

    local dx = -offset + (-6*t*t + 6*t) * offset
    local dy = sclaingFactor
    local tan = math.atan2(dx,dy)
    local nq = quatFromEuler(0,0,-tan):__mul(customPoints[i+1].rot)

    customPoints[i+1].rot = nq

  end

  -- adjust the first point to be exactly where needed.
  customPoints[1] = {
    x = -offset,
    y = -radius,
    z = 0,
    rot = quatFromEuler(0,0,0)
  }

  tip.forwardBezierCPLength = 1
  return
    {
      x = tip.x + off.x,
      y = tip.y + off.y,
      z = tip.z + off.z,
      hdg = tip.hdg,
      backwardBezierCPLength = 1,
      polyMult = 4, 
      customPoints = customPoints,
      parameters = { --for saving the track
        piece = "loop",
        xOffset = xOffset,
        radius = radius
      }
    }
end

--change a marker of a piece, marks the piece as invalid
local function markerChange(type, index, value)
  if value == nil and index == 1 then return end
  if index == nil then index = #pieces end

  if trackClosed and (index == 1 or index == #pieces) and value ~= nil then
    pieces[1][type] = value
    pieces[#pieces][type] = value
    M.invalidatePiece(1,type)
    M.invalidatePiece(#pieces,type)
  else
    pieces[index][type] = value
    M.invalidatePiece(index,type)
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


--helper function to rotate a vector by a quat.
local function rotateVectorByQuat(v, q)
  return {
    x = ((1 - 2*q.y*q.y - 2*q.z*q.z) * v.x) + (2*(q.x*q.y + q.w*q.z)      * v.y) + (2*(q.x*q.z - q.w*q.y)       * v.z),
    y = (2*(q.x*q.y - q.w*q.z)       * v.x) + ((1- 2*q.x*q.x - 2*q.z*q.z) * v.y) + (2*(q.y*q.z + q.w*q.x)       * v.z),
    z = (2*(q.x*q.z + q.w*q.y)       * v.x) + (2*(q.y*q.z - q.w*q.x)      * v.y) + ((1 - 2*q.x*q.x - 2*q.y*q.y) * v.z)
  }
end


-----------------------
--Import and Export --
-----------------------

--exports the current track to a simple lua table.
local function exportTrackToTable()
  local export = {
    gridScale = gridScale,
    heightScale = heightScale,
    pieces = pieces,
    trackPosition = trackPosition
  }

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
  trackPosition = import.trackPosition
  capObjects = {}
  M.setHighQuality(true)
  --finally, create the track.
  M.makeTrack(true)
end

--restores the track from the given file by name
local function load( originalFilename )
  local filename = 'game:trackEditor/'..originalFilename..'.json'
 
  if FS:fileExists(filename) then
    local read = readJsonFile(filename)
    if not read then
        log('I',logTag,'No track found in file Documents/BeamNG.drive/'..filename)
        return
    end
    M.importTrackFromTable(read)

  else
      log('I',logTag,'Could not find file Documents/BeamNG.drive/'..filename)
  end
  guihooks.trigger('Message', {ttl = 10, msg = 'Succesfully loaded '..originalFilename, category = "fill", icon = "check_circle"})
end

--only loads the json of a track (for getting infos such as length and author)
local function loadJSON(originalFilename)
  local filename = 'game:trackEditor/'..originalFilename..'.json'
 
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
  exported.length = currentRet[#currentRet].uvY
  exported.connected = currentRet.connected

  filename = filename or string.format("%.4d-%.2d-%.2d_%.2d-%.2d-%.2d", date.year,date.month,date.day, date.hour,date.min,date.sec)
  filename = 'game:trackEditor/'..filename..'.json';

  serializeJsonToFile(filename,exported, false)
  log('I',logTag,'Serialized track to file Documents/BeamNG.drive/'..filename)
  guihooks.trigger('Message', {ttl = 10, msg = 'Serialized track to file Documents/BeamNG.drive/'..filename, category = "fill", icon = "save"})
end

--renames a file
local function rename( oldName, newName )
  local pre = 'game:trackEditor/'
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
  for i, file in ipairs(FS:findFilesByPattern('game:trackEditor/','*.json',-1,true,false)) do
      local _, fn, e = string.match(file, "(.-)([^/]-([^%.]-))$")

      tracks[i] = fn:sub(1,#fn - #e - 1)
  end
  return tracks
end


local function onClientEndMission()

  M.removeTrack()
end

M.onClientEndMission = onClientEndMission

M.init = init
M.initTrack = initTrack
M.removeTrack = removeTrack
M.convertToSpline = convertToSpline
M.getEndOfTrack = getEndOfTrack
M.append = append
M.revert = revert
M.removeAt = removeAt
M.forward = forward
M.curve = curve
M.ramp = ramp
M.rotateVectorByQuat = rotateVectorByQuat
M.elevate = elevate
M.bank = bank
M.width = width

M.markerChange = markerChange
M.invalidatePiece = invalidatePiece
M.makeTrack = makeTrack
M.focusMarkerOn = focusMarkerOn

M.getPieceInfo = getPieceInfo
M.offsetCurve = offsetCurve
M.spiral = spiral
M.addSpiral = addSpiral

M.createMarkers = createMarkers
M.addHeightMarker = addHeightMarker
M.addBankMarker = addBankMarker
M.addWidthMarker = addWidthMarker


M.showMarkers = showMarkers
M.setGridSize = setGridSize

M.exportTrackToTable = exportTrackToTable
M.importTrackFromTable = importTrackFromTable

M.save = save
M.load = load
M.loadJSON = loadJSON
M.rename = rename
M.getCustomTracks = getCustomTracks
M.loop = loop
M.calculateCustomPoints = calculateCustomPoints

M.toActualTrack = toActualTrack

M.addForward = addForward
M.addCurve = addCurve
M.addLoop = addLoop
M.addOffsetCurve = addOffsetCurve
M.addPiece = addPiece
M.checkInvalidity = checkInvalidity
M.propagateInvalidity = propagateInvalidity

M.setHighQuality =setHighQuality

M.setTrackHighlight = setTrackHighlight

M.stack = stack
M.applyStack = applyStack
M.getStackCount = getStackCount
M.stackToCursor = stackToCursor
M.clearStack = clearStack
M.deepcopy = deepcopy
M.setTrackPosition = setTrackPosition
M.getTrackPosition = getTrackPosition

M.positionVehicle = positionVehicle
M.addCheckPointPositions = addCheckPointPositions
M.unloadAll = unloadAll
M.fresnelSC = fresnelSC
M.getSelectedTrackInfo = getSelectedTrackInfo
M.initTrack()
return M