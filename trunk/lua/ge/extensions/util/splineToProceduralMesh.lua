local M = {}
local logTag = 'splineTrack'
-- general settings for the position and shape of the mesh.
local settings = {
  -- this is the origin of the mesh.
  uvCenterIndex = nil,
  normalSet = "",
  LUTDetail = 100,
  LUTMax = 0,
  LUTMin = 0,
  vertexLUT = {},
  shapeNames = {"regular","low","preview","square"},
  -- These are the different cross sections of the track. (currently only regular and low detail)
  shapes= {
    regular = {
      uvCenterIndex = 12,
      crossPoints = {
        {x=0.33,   y=0, z=-0.9,  pos = "bot"},
        {x=0,      y=0, z=-1,    pos = "bot"},
        {x=-0.33,  y=0, z=-0.9,  pos = "bot"},
        {x=-0.6,   y=0, z=-0.4,  pos = "left"},
        {x=-0.6,   y=0, z=0.5,   pos = "left"},
        {x=-0.45,  y=0, z=0.6,   pos = "left"},
        {x=-0.225, y=0, z=0.5,   pos = "left"},
        {x=-0,     y=0, z=0.2,   pos = "left"},
        {x=-0.9,   y=0, z=0 ,    pos = "top"},
        {x=-0.6,   y=0, z=-0.15, pos = "top"},
        {x=-0.3,   y=0, z=-0.19, pos = "top"},
        {x=0,      y=0, z=-0.2,  pos = "top"}, -- 12 = center
        {x=0.3,    y=0, z=-0.19, pos = "top"},
        {x=0.6,    y=0, z=-0.15, pos = "top"},
        {x=0.9,    y=0, z=0,     pos = "top"},
        {x=0,      y=0, z=0.2,   pos = "right"},
        {x=0.225,  y=0, z=0.5,   pos = "right"},
        {x=0.45,   y=0, z=0.6,   pos = "right"},
        {x=0.6,    y=0, z=0.5,   pos = "right"},
        {x=0.6,    y=0, z=-0.4,  pos = "right"}
      },
      cap = {
        {5,6,7},
        {5,7,8},
        {5,8,4},
        {4,8,9},
        {4,9,3},
        {3,9,10},
        {3,10,11},
        {3,11,2},
        {2,11,12},
        {2,12,13},
        {2,13,1},
        {1,13,14},
        {1,14,15},
        {1,15,20},
        {20,15,16},
        {20,16,19},
        {19,16,17},
        {19,17,18}
      }
    },
    low = {
      uvCenterIndex = 4,
      crossPoints = {
        {x=0, y=0, z=-1 ,  pos = "bot"},
        {x=0, y=0, z=-0.4, pos = "left"},
        {x=0, y=0, z=0.5,  pos = "left"},
        {x=0, y=0, z=-0.2, pos = "top"}, -- 4 = center
        {x=0, y=0, z=0.5,  pos = "right"},
        {x=0, y=0, z=-0.4, pos = "right"}
      },
      cap = {
        {1,2,3},
        {1,3,4},
        {1,4,5},
        {1,5,6},
      }
    },
    preview = {
    uvCenterIndex = 3,
      crossPoints = {
        {x=0, y=0, z=-0.5 , pos = "bot"},
        {x=0, y=0, z=0, pos = "left"},
        {x=0, y=0, z=0.5, pos = "top"}, -- 4 = center
        {x=0, y=0, z=0, pos = "right"}
      },
      cap = {
      }
  },
  square = {
    uvCenterIndex = 4,
    crossPoints = {
      {x=0, y=0, z=-2.5 ,  pos = "bot"},
      {x=0, y=0, z=-2.5, pos = "left"},
      {x=0, y=0, z=2.5,  pos = "left"},
      {x=0, y=0, z=2.5, pos = "top"}, -- 4 = center
      {x=0, y=0, z=2.5,  pos = "right"},
      {x=0, y=0, z=-2.5, pos = "right"}
    },
    cap = {
      {1,2,3},
      {1,3,4},
      {1,4,5},
      {1,5,6},
    }
  }

  },
  -- sclaing factors for the texture
  uv = {
    width = 0.2,
    height = 0.2
  }
}

-- This is the main function which will create the mesh road along the control points.
local function materialize(segment)
  -- Create the normal lookup table.
  M.caluclateLookupTables(segment)
  -- caluclate the actual mesh info
  M.calculateMeshInfo(segment)

  -- Calculate the mesh info for this part and store it. Low quality track has no extra LOD.
  segment.meshes = {}
  segment.meshes[1] = M.compileMeshInfo(segment,0)
  segment.meshes[2] = M.compileMeshInfo(segment,0)
  segment.meshes[3] = M.compileMeshInfo(segment,0)

  if not segment.mesh then
    local splineObject = createObject("ProceduralMesh")
    splineObject:setPosition(Point3F(0,0,0))
    splineObject:registerObject('procMesh'..segment.index)
    splineObject.material = String(segment.material)
    scenetree.MissionGroup:add(splineObject.obj)
    splineObject:createMesh(segment.meshes)
    segment.mesh = splineObject
  else
    segment.mesh:createMesh(segment.meshes)
  end
  segment.meshes = nil
end

-- This functions creates a lookup table for the vertices of varying width, including normals and uv x-coordinates
local function caluclateLookupTables(segment)
  --  check which is the widest part of the track. If it is slimmer that the widest stored values, we can skip this function.
  local maxWidth = 0
  for _,p in ipairs(segment.points) do
    if p.width and p.width > maxWidth then
      maxWidth = p.width
    end
  end
  maxWidth = 50
  if maxWidth < settings.LUTMax then
    return
  end

  for _,shape in ipairs(settings.shapeNames) do
    settings.shapes[shape].vertexLUT= {}

    local cpc = #settings.shapes[shape].crossPoints
    -- Go through all integers ranging from the current maximum width of normals to the maximum width of the track
    -- multiplied by the detail value 
    --dump((settings.LUTMax*settings.LUTDetail) .. " to " .. ((maxWidth*settings.LUTDetail)+1))
    for s = settings.LUTMax*settings.LUTDetail, (maxWidth*settings.LUTDetail)+1 do
      -- This is the actual width of the track we are dealing with in this step.
      local scl = (s/settings.LUTDetail) /2
      local vertices = {}
      -- calculate the scaled vertices first.
      for i = 1, #settings.shapes[shape].crossPoints do
        local currentP = settings.shapes[shape].crossPoints[i]
        local cx = 0
        if currentP.pos == "bot" or currentP.pos == "top" then  
          cx = (currentP.x * scl)  
        elseif currentP.pos == "left" then
          cx = (currentP.x - scl)
        elseif currentP.pos == "right" then
          cx = (currentP.x + scl)
        end
        vertices[i] = {}
        vertices[i].position = vec3(cx, currentP.y, currentP.z)
      end
      -- caluclate the normals
      for i = 1, #settings.shapes[shape].crossPoints do      
        local currentP = vertices[i].position
        local nextP = vertices[((i)%cpc)+1].position
        local prevP = vertices[((i+cpc-2)%cpc+1)].position

        -- Vector from previous point to current point.
        local a = (currentP - prevP)
        a:normalize()
        -- Vector from current point to next point.
        local b = (nextP - currentP)
        b:normalize()

        -- Actual normal.
        local n = vec3(
          -(a.z) - (b.z),
          0,
          (a.x) + (b.x)
        )
        local len = n:length()
        -- If the normal has no length (a and b parallel), simply use perpendicular vector from a.
        if len <=0.00001 then
          n = vec3(
            -(nextP.z - currentP.z),
            0,
            (nextP.x - currentP.x)
          )
        end
        -- Make sure that the normal is actually pointing outwards.
        if (-(nextP.z - currentP.z)*n.x) + ((nextP.x - currentP.x) * n.z) < 0 then
          n = -n / len
        end
        n:normalize()
        vertices[i].normal = n
      end

      -- calculcate uvX  
      local len = 0
      for i =  1, #vertices-1 do
        vertices[i].uvX = len
        len = len +vertices[i].position:distance(vertices[i+1].position)
      end
      vertices[#vertices].uvX = len
      local uvCenterOff = vertices[settings.shapes[shape].uvCenterIndex].uvX
      for _,p in ipairs(vertices) do
        p.uvX = p.uvX - uvCenterOff
      end

      settings.shapes[shape].vertexLUT[s] = vertices
    end
  end

  settings.LUTMax = maxWidth+1
end

-- This function calculates the rotated and scaled vertices, normals and uv X values for this subspline. 
local function calculateMeshInfo(segment)
  local LUTindex, vertexLUT, nx, ny, nz
  segment.shape = "regular"
  if segment.quality == 4 then
    segment.shape = "low"
  end
  --segment.shape = "square"
  for _,controlPoint in ipairs(segment.points) do
    if controlPoint.quality[segment.quality] then
      controlPoint.verticesForControlPoint = {}
    --  dump(controlPoint)
      -- index for the lookup table for the points, normals and uvX.
      LUTindex = math.floor(controlPoint.width * settings.LUTDetail +1.5)
      vertexLUT = settings.shapes[segment.shape].vertexLUT[LUTindex]

      -- get final rotation and rotated unit vectors.

      nx = M.rotateVectorByQuat(vec3(1,0,0),controlPoint.finalRot)
      ny = M.rotateVectorByQuat(vec3(0,1,0),controlPoint.finalRot)
      nz = M.rotateVectorByQuat(vec3(0,0,1),controlPoint.finalRot)

      -- put in the rotated vertex, normal and uvX
      for i,p in ipairs(vertexLUT) do
        controlPoint.verticesForControlPoint[i] = {
          position = p.position.x * nx + p.position.y * ny + p.position.z * nz + controlPoint.position + vec3(0,0,controlPoint.zOffset),
          normal =  p.normal.x * nx + p.normal.y * ny + p.normal.z * nz,
          uvX = p.uvX
        }
      end
    end
  end
end

-- This function compiles the vertices, normals etc. so that it can be sent to the engine side and create the actual mesh.
-- Also creates caps on the front and or end of the spline if needed.
local function compileMeshInfo(segment, lod)
  local points = segment.points 
  local vertices = {}

  local shape = settings.shapes[segment.shape]
  local vertexCount = #points * #shape.crossPoints
  local uvs =  {}
  local normals = {}
  local faces = {}
  -- first, put the vertices, uvs and normals in their respective arrays.
  for cpIndex = 1, #points do
    local controlPoint = points[cpIndex]
    if controlPoint.quality[segment.quality] then
      for i,trp in ipairs(controlPoint.verticesForControlPoint) do
        vertices[#vertices+1] = {x = trp.position.x, y = trp.position.y, z = trp.position.z}  
        uvs[#uvs+1] = {u = (trp.uvX * settings.uv.width), v = (controlPoint.uvY * settings.uv.height)}
        normals[#normals+1] = {x = trp.normal.x, y = trp.normal.y, z = trp.normal.z}  
      end
    end
  end

  -- Create faces
  for pIndex = 1, #vertices - #shape.crossPoints do
    local this = pIndex-1
    local right = pIndex
    if right % #shape.crossPoints == 0 then
      right = right - #shape.crossPoints 
    end
    local up = this + #shape.crossPoints
    local upRight = right + #shape.crossPoints

    faces[#faces+1] = {v = this, n = this,u=this}
    faces[#faces+1] = {v = up, n =up,u=up}
    faces[#faces+1] = {v = right, n =right,u=right}

    faces[#faces+1] = {v = up, n =up,u=up}
    faces[#faces+1] = {v = upRight, n =upRight,u=upRight}
    faces[#faces+1] = {v = right, n =right, u=right}
  end

  -- Create the cap part(s) of the mesh.
  if segment.hasEndCap then
    local vertsCount = #vertices
    local faceCount = #faces
    local controlPoint = points[#points]
    for i=1, #shape.crossPoints do
      vertices[i + vertsCount] = {
        x = controlPoint.verticesForControlPoint[i].position.x,
        y = controlPoint.verticesForControlPoint[i].position.y, 
        z = controlPoint.verticesForControlPoint[i].position.z
      }
      local p = shape.crossPoints[i]
      if p.pos == "bot" or p.pos == "top" then
        uvs[i + vertsCount] = {u = p.x * controlPoint.width/2, v = p.z}
      elseif p.pos == "left" then
        uvs[i + vertsCount] = {u = p.x - controlPoint.width/2, v = p.z}
      elseif p.pos == "right" then
        uvs[i + vertsCount] = {u = p.x + controlPoint.width/2, v = p.z}
      end
      local normal = M.rotateVectorByQuat({x=0,y=-1,z=0}, controlPoint.rot)
      normals[i + vertsCount] = {x = normal.x, y = normal.y, z = normal.z}
    end

    for i = 1, #shape.cap do
      for f = 3, 1,-1 do
        faces[#faces+1] = {v = shape.cap[i][f]-1 + vertsCount, n = shape.cap[i][f]-1 + vertsCount, u = shape.cap[i ][f]-1 + vertsCount}
      end
    end
  end

  if segment.hasStartCap then
    local vertsCount = #vertices
    local faceCount = #faces
    local controlPoint = points[1]
    for i=1, #shape.crossPoints do
      vertices[i + vertsCount] = {
        x = controlPoint.verticesForControlPoint[i].position.x,
        y = controlPoint.verticesForControlPoint[i].position.y, 
        z = controlPoint.verticesForControlPoint[i].position.z
      }
      local p = shape.crossPoints[i]
      if p.pos == "bot" or p.pos == "top" then
        uvs[i + vertsCount] = {u = p.x * controlPoint.width/2, v = p.z}
      elseif p.pos == "left" then
        uvs[i + vertsCount] = {u = p.x - controlPoint.width/2, v = p.z}
      elseif p.pos == "right" then
        uvs[i + vertsCount] = {u = p.x + controlPoint.width/2, v = p.z}
      end
    local normal = M.rotateVectorByQuat({x=0,y=-1,z=0}, controlPoint.rot)
      normals[i + vertsCount] = {x = normal.x, y = normal.y, z = normal.z}
    end

    for i = 1, #shape.cap do
      for f = 1,3 do
        faces[#faces+1] = {v = shape.cap[i][f]-1 + vertsCount, n = shape.cap[i][f]-1 + vertsCount, u = shape.cap[i][f]-1 + vertsCount}
      end
    end
  end

  return {
    verts = vertices,
    uvs = uvs,
    normals = normals,
    faces = faces
  }
end

-------------------------------
-- helper and mini functions --
-------------------------------

-- Rotates a vector by a given quat.
local function rotateVectorByQuat(v, q)
  return q:__mul(v)
  
end

M.settings = settings

M.materialize = materialize
M.caluclateLookupTables = caluclateLookupTables

M.calculateMeshInfo = calculateMeshInfo
M.compileMeshInfo = compileMeshInfo

M.rotateVectorByQuat = rotateVectorByQuat


return M