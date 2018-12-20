local M = {}
local obstacleTypes = {}
local shapeNames = {
  cube1 = 'levels/GridMap/art/shapes/misc/gm_cube_1m.dae',
  cube2 = 'levels/GridMap/art/shapes/misc/gm_cube_2m.dae',
  cube3 = 'levels/GridMap/art/shapes/misc/gm_cube_4m.dae',
  cube4 = 'levels/GridMap/art/shapes/misc/gm_cube_8m.dae',
  sharp1 = 'levels/GridMap/art/shapes/misc/gm_sharp_angle.dae',
  sharp2 = 'levels/GridMap/art/shapes/misc/gm_sharp_vert.dae',
  bump1 = 'levels/GridMap/art/shapes/misc/gm_bump.dae',
  bump2 = 'levels/GridMap/art/shapes/misc/gm_bump_02.dae',
  bump3 = 'levels/GridMap/art/shapes/misc/gm_bump_03.dae',
  ramp1 = 'levels/GridMap/art/shapes/misc/gm_ramp_03.dae',
  ramp2 = 'levels/GridMap/art/shapes/misc/gm_ramp_02.dae',
  ramp3 = 'levels/GridMap/art/shapes/misc/gm_ramp_01.dae',
  ramp4 = 'levels/GridMap/art/shapes/misc/gm_flipramp_01.dae',
  obstacle1 = 'levels/GridMap/art/shapes/misc/gm_rock_02.dae',
  obstacle2 = 'levels/GridMap/art/shapes/misc/gm_rock_03.dae',

}
for name,_ in pairs(shapeNames) do obstacleTypes[#obstacleTypes+1] = name end
local objects = {}
for _,oType in ipairs(obstacleTypes) do objects[oType] = {} end

local function addObject(obstacleType)
  local obj =  createObject('TSStatic')
  obj:setField('shapeName', 0, shapeNames[obstacleType])
  obj:setPosition(Point3F(0,0,0))
  obj.scale = Point3F(1,1,1)
  obj:setField('rotation', 0, '0 0 0 1')
  obj.canSave = false
  obj:registerObject(obstacleType.."Obstacle"..#objects[obstacleType])  
  objects[obstacleType][#objects[obstacleType]+1] = obj
end

local function expandTruncateList(obstacleType, length)
  local list = objects[obstacleType]
  while #list < length do
    addObject(obstacleType)
  end
  for i = length+1, #list do
    local m = #list
    list[m].scale = Point3F(0,0,0)
    list[m]:delete()
    list[m] = nil
  end
  return
end

local turn90 = quatFromEuler(0,0,math.pi/2)
local function placeObstacles(track) 
  local data = {}
  for _,oType in ipairs(obstacleTypes) do data[oType] = {} end
  for _,piece in ipairs(track) do
    if piece.obstacles then
      for _,o in ipairs(piece.obstacles) do

        local pos, rot, width
        if not piece.points or #piece.points == 0 or o.offset == 1 then
          pos = piece.markerInfo.position
          rot = piece.markerInfo.rot
          width = piece.markerInfo.width
        elseif o.offset == 0 then
          pos = piece.points[1].position + vec3(0,0,piece.points[1].zOffset)
          rot = piece.points[1].finalRot
          width = piece.points[1].width
        else
          local targetLen = lerp(piece.startLength, piece.endLength, o.offset)
          for i = 1, #piece.points do
            if piece.points[i].length <= targetLen then 
              pos = piece.points[i].position + vec3(0,0,piece.points[i].zOffset)
              rot = piece.points[i].finalRot
              width = piece.points[i].width
           end
          end
        end

        local name = o.value .. o.variant
        --dump(refPoint)
        data[name][#data[name]+1] = {
          obstacleType = name,
          position = pos + rot:__mul(o.position + vec3(width/2 * (o.anchor-1),0,0)),
          rotation = turn90:__mul(o.rotation:__mul(rot)),
          scale = vec3(o.scale.y,o.scale.x,o.scale.z)
        }
      end
    end
  end

  for name,list in pairs(data) do
    expandTruncateList(name,#list)
    for i,o in ipairs(list) do
      objects[name][i]:setPosition(o.position:toPoint3F())
      objects[name][i].scale = o.scale:toPoint3F()
      local quat = convertQuatToTorqueFormat(o.rotation)
      objects[name][i]:setField('rotation', 0, quat.x .. ' ' ..quat.y..' '..quat.z..' '..quat.w)
    end
  end
end

local function clearReferences()
  for _,oType in ipairs(obstacleTypes) do objects[oType] = {} end
end

M.clearReferences = clearReferences
M.placeObstacles = placeObstacles
return M