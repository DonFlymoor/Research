local M = {}
local logTag = 'splineTrack'
local alpha =1

-- general settings for the position and shape of the mesh.
local settings = {
  -- this is the origin of the mesh.
	position = {
		x = 0,
		y = 0,
		z = 0
	},

  -- how long each segment will be. lower value = more individual objects
	segmentLength = 16, -- deprecated
  -- list of all the points that make up the cross section on the mesh, where x is right and z is up. y would be forward, but is not used here.

  uvCenterIndex = nil,
  normalSet = "",
  LUTDetail = 100,
  LUTMax = 0,
  normalLUT = {

  },

  shapes= {
    regular = {
      uvCenterIndex = 12,
    	crossPoints = {
    		{x=0.33,y=00,z=-0.9, pos = "bot" },
    		{x=0,y=00,z=-1 , pos = "bot"},
    		{x=-0.33,y=00,z=-0.9 , pos = "bot"},
      
    		{x=-0.6,y=00,z=-0.4, pos = "left"},
    		{x=-0.6,y=00,z=0.5, pos = "left"},
        {x=-0.45,y=00,z=0.6, pos = "left"},
    		{x=-0.225,y=00,z=0.5, pos = "left"},
    		{x=-0,y=00,z=0.2, pos = "left"},
      
        {x=-0.9, y=00, z=0 , pos = "top"},
    		{x=-0.6, y=00, z=-0.15, pos = "top"},
    		{x=-0.3, y=00, z=-0.19, pos = "top"},
    		{x=0    , y=00, z=-0.2, pos = "top"}, -- 12 = center
    		{x=0.3,  y=00, z=-0.19, pos = "top"},
    		{x=0.6,  y=00, z=-0.15, pos = "top"},
    		{x=0.9,  y=00, z=0, pos = "top"},
      
    		{x=0,y=00,z=0.2, pos = "right"},
    		{x=0.225,y=00,z=0.5, pos = "right"},
        {x=0.45,y=00,z=0.6, pos = "right"},
    		{x=0.6,y=00,z=0.5, pos = "right"},
    		{x=0.6,y=00,z=-0.4, pos = "right"}
    	},

      cap = {
        {5,7,6},
        {5,8,7},
        {5,4,8},
        {4,9,8},
        {4,3,9},
        {3,10,9},
        {3,11,10},
        {3,2,11},
        {2,12,11},

        {2,13,12},
        {2,1,13},
        {1,14,13},
        {1,15,14},
        {1,20,15},
        {20,16,15},
        {20,19,16},
        {19,17,16},
        {19,18,17}
      }
    },
    low = {
      uvCenterIndex = 4,
      crossPoints = {
        
        {x=0,y=00,z=-1 , pos = "bot"},
      
        {x=-0.6,y=00,z=-0.4, pos = "left"},
        {x=-0.6,y=00,z=0.5, pos = "left"},
            
        {x=0, y=00, z=-0.2, pos = "top"}, -- 4 = center
       
        {x=0.6,y=00,z=0.5, pos = "right"},
        {x=0.6,y=00,z=-0.4, pos = "right"}
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
	},
 

  highQuality = true


}

-- interpolates from control points with the bezier method. control points must have a forwardControlPoint and backwardControlPoint field
local function getBezierPoints(controlPoints)

  local from = 1
  local to = #controlPoints-1
  local pointsMult = 5
  if not settings.highQuality then
    pointsMult = 1
  end
  local ret = {}
  -- we will skip the last point because there is no point to interpolate to after the last point.
  for p = from, to do
    
    -- if this piece is a special piece, just add the custom points and call it a day.
    if controlPoints[p+1].customPoints then
      local startIndex = #ret+1
     -- dump("custom points count " .. #controlPoints[p+1].customPoints)
      for _,c in ipairs(controlPoints[p+1].customPoints) do 
        ret[#ret+1] = c -- custom point should include: x,y,z and rot.
      end
      ret[startIndex].bank = controlPoints[p].bank
      ret[startIndex].height = controlPoints[p].height
      ret[startIndex].width = controlPoints[p].width
      ret[startIndex].originalIndex = p
    else
    --  dump(p .. "no custom points")
      local p0 = controlPoints[p]
      local p1 = p0.forwardControlPoint
      local p3 = controlPoints[p+1]
      local p2 = p3.backwardControlPoint
      
      local numPoints = pointsMult * p3.polyMult
      if numPoints < 1 then
        numPoints = 1 
      end
      if settings.highQuality then
        if numPoints < 5 then
          numPoints = 5
        end
      end
      if numPoints > 300 then
        numPoints = 300
      end
      for i = 0, numPoints-(1) do
        local t = (i / numPoints)
       
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
        local bank = nil
        local height = nil
        local width = nil
        local originalIndex = nil
        if i == 0 then
          height = p0.height
          bank = p0.bank
          width = p0.width
          originalIndex = p
        end
        -- fill in the fields.
        ret[#ret+1] = {
          x = t0*p0.x + t1*p1.x + t2*p2.x + t3*p3.x,
          y = t0*p0.y + t1*p1.y + t2*p2.y + t3*p3.y,
          z = t0*p0.z + t1*p1.z + t2*p2.z + t3*p3.z,
          rot = quatFromEuler(math.pi,0,0):__mul(quatFromEuler(0,0,-hdg - math.pi/2)),

          bank = bank,
          height = height,
          width = width,
          originalIndex = originalIndex

        }

      end
    end
  end

 
  -- for an open track, we need to add a point representing the last point, since interpolating above between two points only includes the first, but excludes the second point.
    ret[#ret+1] = {
          x = controlPoints[to+1].x,
          y = controlPoints[to+1].y,
          z = controlPoints[to+1].z,
          rot = quat(controlPoints[to+1].rot),
        bank = quat(controlPoints[to+1].bank),
        height = controlPoints[to+1].height,
        width = controlPoints[to+1].width,

        originalIndex = to+1

    }
  
  return ret
end


local function CalcNormalLUT(controlpoints)
  local maxWidth = 0
  for _,p in ipairs(controlpoints) do
    if p.width and p.width > maxWidth then
      maxWidth = p.width
    end
  end
  --  dump(maxWidth)
  if maxWidth < settings.LUTMax then
    return
  end

  local cpc = #settings.crossPoints

  for s = settings.LUTMax*settings.LUTDetail, (maxWidth*settings.LUTDetail)+1 do
  --for s = 1, 2 do
    local scl = (s/settings.LUTDetail) 
 --   dump(s)
    local normals  = {}
    for i = 1, #settings.crossPoints do
      local currentP = settings.crossPoints[i]
      local nextP = settings.crossPoints[((i)%cpc)+1]
      local prevP = settings.crossPoints[((i+cpc-2)%cpc+1)]
      --dump(currentP)
      --dump(nextP)
      --dump(prevP)
      local cx,nx,px
      if currentP.pos == "bot" or currentP.pos == "top" then  
        cx = (currentP.x * scl)  
      elseif currentP.pos == "left" then
        cx = (currentP.x - scl)
      elseif currentP.pos == "right" then
        cx = (currentP.x + scl)
      end

      if nextP.pos == "bot" or nextP.pos == "top" then  
        nx = (nextP.x * scl)  
      elseif nextP.pos == "left" then
        nx = (nextP.x - scl)
      elseif nextP.pos == "right" then
        nx = (nextP.x + scl)
      end

      if prevP.pos == "bot" or prevP.pos == "top" then  
        px = (prevP.x * scl)  
      elseif prevP.pos == "left" then
        px = (prevP.x - scl)
      elseif prevP.pos == "right" then
        px = (prevP.x + scl)
      end

      local a = {
        x = cx - px,
        y = currentP.y - prevP.y,
        z = currentP.z - prevP.z,
      }

      local len = 1/( math.sqrt(a.x*a.x + a.z*a.z) + 1e-30)

      a = {
        x = a.x * len,        
        y = a.y * len,
        z = a.z * len,
      }

      local b = {
        x = nx- cx,
        y = nextP.y - currentP.y,
        z = nextP.z - currentP.z,
      }
      len = 1/(math.sqrt(b.x*b.x + b.z*b.z) + 1e-30)
      b = {
        x = b.x * len,        
        y = b.y * len,
        z = b.z * len,
      }

      local n = {
        x = -(a.z) - (b.z),
        y = 0,
        z = (a.x) + (b.x)
      }
      local len = math.sqrt(n.x*n.x + n.z*n.z)
      if len <=0.00001 then
        n = {
          x = -(nextP.z - currentP.z),
          y = 0,
          z = (nx - cx)
        }
        len = math.sqrt(n.x*n.x + n.z*n.z)
      end
        
      if (-(nextP.z - currentP.z)*n.x) + ((nx - cx) * n.z) < 0 then
        n = {
          x = -n.x/len,
          y = -n.y/len,
          z = -n.z/len
        }
      end
      if len ~= 0 then
        len = 1/len
      end
      
      normals[i] = {
        x = n.x,
        y = n.y,
        z = n.z
      }
    end
   -- dump(normals)
    settings.normalLUT[s] = normals

  end

 -- dump(#settings.normalLUT)
end


-- This is the main function which will create the mesh road along the control points.
local function materialize(controlPoints, highQuality)


  settings.checkpointPositions = {}
  settings.highQuality = highQuality
  if not settings.highQuality then
    settings.crossPoints = settings.shapes.low.crossPoints
    settings.cap = settings.shapes.low.cap
    settings.uvCenterIndex = settings.shapes.low.uvCenterIndex
    if settings.normalSet ~= "low" then
      settings.LUTMax = 0
    end
    settings.normalSet = "low"
  else
    settings.crossPoints = settings.shapes.regular.crossPoints
    settings.cap = settings.shapes.regular.cap
    settings.uvCenterIndex = settings.shapes.regular.uvCenterIndex
    if settings.normalSet ~= "regular" then
      settings.LUTMax = 0
    end
    settings.normalSet = "regular"
  end
      CalcNormalLUT(controlPoints)


  local ret = M.getBezierPoints(controlPoints)

 -- M.markSkippablePoints(controlPoints, ret)

  -- these two functions measure some distances needed for later calculation.
  M.measureTrack(ret)
  --M.measureCrossPointsWidth()

 -- M.calcNormalsForCrossPoints()
  -- these two functions apply a smooth gradient from one height/banking control point to the next.
  M.interpolateHeight(ret)
  M.interpolateBanking(ret)
  M.interpolateWidth(ret)


  -- this function creates checkpoints along the way.
 --	M.addCheckPointPositions(ret)
  settings.connected = 
      controlPoints[1].x == controlPoints[#controlPoints].x and
      controlPoints[1].y == controlPoints[#controlPoints].y and
      controlPoints[1].z == controlPoints[#controlPoints].z and
      controlPoints[1].hdg == controlPoints[#controlPoints].hdg and
      controlPoints[1].width == controlPoints[#controlPoints].width and
      controlPoints[1].bankDeg == controlPoints[#controlPoints].bankDeg and
      controlPoints[1].height == controlPoints[#controlPoints].height
  -- this function calculates the final and actual verticies, normals etc for the final mesh.
 -- 

  -- then the final points are hashed into pieces so we end up with multiple objects (for performance reasons)
  local splines = M.hashSplineAndCreateMeshes(ret)
  local objects = {}

  for i,subSpline in ipairs(splines) do

    if controlPoints[i+1].invalid then

      subSpline = M.getSubSpline(ret, subSpline.startIndex, subSpline.endIndex)
      M.calcAllPoints(subSpline)
      subSpline.meshes = {}
      subSpline.meshes[1] =  M.caluclateMeshInfo(subSpline,0)
      if settings.highQuality then
        subSpline.meshes[2] =  M.caluclateMeshInfo(subSpline,1)
        subSpline.meshes[3] =  M.caluclateMeshInfo(subSpline,2)
      else
        subSpline.meshes[2] = M.caluclateMeshInfo(subSpline,0)
        subSpline.meshes[3] = M.caluclateMeshInfo(subSpline,0)
      end


      if not controlPoints[i+1].mesh then
        --dump(i .. "# control point has no mesh.")
        local splineObject = createObject("ProceduralMesh")
        splineObject:setPosition(Point3F(0,0,0))
        splineObject:registerObject('procMesh'..i)
        if controlPoints[i+1].highlighted then
       -- if i == #splines and not settings.connected then
          splineObject.material = String("Grid512_ForestGreenLines_Mat")
        else
          splineObject.material = String("a_asphalt_01_a")
        end
        scenetree.MissionGroup:add(splineObject.obj)
        --  dump(subSpline.meshes)
        splineObject:createMesh(subSpline.meshes)
        objects[#objects+1] = splineObject
      else
      --  dump(i .. "# has a mesh. recreating...")
      --  dump(controlPoints[i+1].mesh)
      --  dump(#subSpline.meshes)

        if controlPoints[i+1].highlighted then
          controlPoints[i+1].mesh.material = String("Grid512_ForestGreenLines_Mat")
        else
          controlPoints[i+1].mesh.material = String("a_asphalt_01_a")
        end
        controlPoints[i+1].mesh:updateMaterial()
        controlPoints[i+1].mesh:createMesh(subSpline.meshes)
        objects[#objects+1] = controlPoints[i+1].mesh
      end

      
    else
      objects[#objects+1] = ''
      --dump("skipped mesh " .. (i))
    end
  end

  local caps = controlPoints.caps

  if not settings.connected then
    M.calcAllPoints(ret,1,1)
    M.calcAllPoints(ret, #ret,#ret)
    objects.caps = {}
    if not caps then
      objects.caps[1] = M.MakeCap(ret[1],false)
      objects.caps[2] = M.MakeCap(ret[#ret],true)
    else
      objects.caps[1] = M.MakeCap(ret[1],false, caps[1])
      objects.caps[2] = M.MakeCap(ret[#ret],true, caps[2])
    end   
  else
    if caps then
      if caps[1] then
        caps[1]:delete()
      end
      if caps[2] then
        caps[2]:delete()
      end
    end
  end
  ret.connected = settings.connected
  be:reloadCollision()
  ret.checkpointPositions = settings.checkpointPositions
  return objects, ret
  
end


local function MakeCap(controlPoint, endPiece, existingMesh) 

  


  local vertices = {}
  local uvs ={}
  local normals = {}
  for i=1, #settings.crossPoints do
    vertices[i] = controlPoint.verticesForControlPoint[i]
    
    local p = settings.crossPoints[i]
    if p.pos == "bot" or p.pos == "top" then
      uvs[i] = {u = p.x * controlPoint.width/2, v = p.z}
    elseif p.pos == "left" then
      uvs[i] = {u = p.x - controlPoint.width/2, v = p.z}
    elseif p.pos == "right" then
      uvs[i] = {u = p.x + controlPoint.width/2, v = p.z}
    end
    normals[i] = M.rotateVectorByQuat({x=0,y=-1,z=0}, controlPoint.rot)
  end
  local faces = {}
  for i = 1, #settings.cap do
    for f = 1, 3 do
      faces[#faces+1] = {v = settings.cap[i][f]-1, n = settings.cap[i][f]-1, u = settings.cap[i][f]-1}
    end
  end


  if not existingMesh then

    local splineObject = createObject("ProceduralMesh")
    splineObject:setPosition(Point3F(0,0,0))
    local name = 'procMeshcap'
    if endPiece then
      name = name .."_end"
    end
    splineObject:registerObject(name)
 
    splineObject.material = String("a_asphalt_01_a")
  
    scenetree.MissionGroup:add(splineObject.obj)
    existingMesh = splineObject
  end
--  dump(subSpline.meshes)
  existingMesh:createMesh({{
    verts = vertices,
    uvs = uvs,
    normals = normals,
    faces = faces
  },{
    verts = vertices,
    uvs = uvs,
    normals = normals,
    faces = faces
  },{
    verts = vertices,
    uvs = uvs,
    normals = normals,
    faces = faces
  }})
  return existingMesh
end

local function calcAllPoints(controlPoints, from, to)

  if not from then from = 1 end
  if not to then to = #controlPoints end

  -- first, calculate all the cross sections and store them next to the points
  for cpIndex = from, to do
    local controlPoint = controlPoints[cpIndex]
    controlPoints[cpIndex].finalRot = controlPoint.bank:__mul(controlPoint.rot)
    M.getRotatedTranslatedPoints(settings.crossPoints, controlPoint, controlPoints[cpIndex].finalRot)
    
    -- calculcate uvX for created verticies 
    local len = 0
    
    for i =  1, #controlPoints[cpIndex].verticesForControlPoint-1 do
      controlPoints[cpIndex].verticesForControlPoint[i].uvX = len

      len = len + M.dist3(
        controlPoints[cpIndex].verticesForControlPoint[i].x, controlPoints[cpIndex].verticesForControlPoint[i].y, controlPoints[cpIndex].verticesForControlPoint[i].z,
        controlPoints[cpIndex].verticesForControlPoint[i+1].x, controlPoints[cpIndex].verticesForControlPoint[i+1].y, controlPoints[cpIndex].verticesForControlPoint[i+1].z
        )
    end
    controlPoints[cpIndex].verticesForControlPoint[#controlPoints[cpIndex].verticesForControlPoint].uvX = len
    local uvCenterOff = controlPoints[cpIndex].verticesForControlPoint[settings.uvCenterIndex].uvX
    for _,p in ipairs(controlPoints[cpIndex].verticesForControlPoint) do
      p.uvX = p.uvX - uvCenterOff
    end
  end

end





local function measureTrack(controlPoints)
	local len = 0
	for i =  1, #controlPoints-1 do
		controlPoints[i].uvY = len
		len = len + M.dist3(
			controlPoints[i].x, controlPoints[i].y, controlPoints[i].z,
			controlPoints[i+1].x, controlPoints[i+1].y, controlPoints[i+1].z
			)
	end
	controlPoints[#controlPoints].uvY = len
	
end


local function  getLengthFromTo(controlPoints,currentBankIndex, nextBankIndex )
  return controlPoints[nextBankIndex].uvY - controlPoints[currentBankIndex].uvY
end

-- returns the distance from a/b to x/y.
local function dist3(a,b,c,x,y,z)
  if not b then
    return math.sqrt((a.x)*(a.x) + (a.y)*(a.y) + (a.z)*(a.z)) 
  else
    return math.sqrt((a-x)*(a-x) + (b-y)*(b-y) + (c-z)*(c-z)) 
  end
end


local function findFieldAfter(nameOfField, currentIndex, controlPoints)
  for i = currentIndex+1, #controlPoints do
    if controlPoints[i][nameOfField] ~= nil then
      return controlPoints[i][nameOfField], i
    end
  end
  return nil, nil
end


local function interpolateField(nameOfField, controlPoints, interpolationFunction)
  local currentValue, nextValue
  local currentValueIndex, nextValueIndex
  currentValue = controlPoints[1][nameOfField]
  currentValueIndex = 1
  nextValue, nextValueIndex = M.findFieldAfter(nameOfField,currentValueIndex, controlPoints)    

  while nextValue ~= nil do
    local length = M.getLengthFromTo(controlPoints,currentValueIndex, nextValueIndex)
    local currentLength = 0
    
    for i = currentValueIndex, nextValueIndex-1 do
      local t = currentLength / length
      interpolationFunction(currentValue, nextValue, t, controlPoints[i])
      currentLength = currentLength + M.dist3(
        controlPoints[i].x, controlPoints[i].y, controlPoints[i].z,
        controlPoints[i+1].x, controlPoints[i+1].y, controlPoints[i+1].z
        )
    end
    -- check for next bank and swap
    currentValue = nextValue
    currentValueIndex = nextValueIndex
    nextValue, nextValueIndex = M.findFieldAfter(nameOfField,currentValueIndex, controlPoints)      
  end

end



local function interpolateHeight( controlPoints )
  local heightFunction = function(t, delta) if t <= 0 then return 0,0 elseif t >= 1 then return delta,0 else return -2*delta*t*t*t + 3*delta*t*t , -6*delta*t*t+6*delta*t end end
  M.interpolateField("height",controlPoints,
    function(current,nextV,t,point)
      local offset, slope = heightFunction(t, nextV - current)
      offset = offset + current
      point.zOffset = offset 
      point.pitch = quatFromEuler(math.atan2(1,slope)/2- math.pi/4,0,0)
    end
  )

  controlPoints[#controlPoints].zOffset = controlPoints[#controlPoints].height
  for i,p in ipairs(controlPoints) do
    if p.zOffset then
      p.z = p.z + p.zOffset
    end
  end

end

local function interpolateBanking(controlPoints)
  local bankFunction = function(p) if p <= 0 then return 0,0 elseif p >= 1 then return 1 else return -2*p*p*p + 3*p*p end end
  M.interpolateField("bank", controlPoints,
    function(current,nextV,t,point)
      point.bank = current:nlerp(nextV, bankFunction(t))
    end
  )
end

local function interpolateWidth(controlPoints)
  local smooth = function(p) if p <= 0 then return 0,0 elseif p >= 1 then return 1 else return -2*p*p*p + 3*p*p end end
  M.interpolateField("width", controlPoints,
    function(current,nextV,t,point)
      point.width = current * (1-smooth(t)) + nextV * smooth(t)
    end
  )
end


local function caluclateMeshInfo(spline, lod) 
	
  local vertices = {}
  local vertexCount = #spline * #settings.crossPoints
  local uvs =  {
  }
  local normals = {}
  local faces = {}
  --  dump(#crossPoints)

  for cpIndex = 1, #spline do
  	if cpIndex == 1 or cpIndex == #spline or (lod == 2 and (1+cpIndex) % 4 == 0) or (lod == 1 and cpIndex % 2 == 0) or lod == 0 then
    	local controlPoint = spline[cpIndex]
      --local verticesForControlPoint = M.getRotatedTranslatedPoints(crossPoints, controlPoint, controlPoint.bank:__mul(controlPoint.rot))
      for i,trp in ipairs(controlPoint.verticesForControlPoint) do
      	vertices[#vertices+1] = {x = trp.x, y = trp.y, z = trp.z}  
      	uvs[#uvs+1] = {u = (trp.uvX * settings.uv.width), v = (controlPoint.uvY * settings.uv.height)}
        normals[#normals+1] = {x = trp.normal.x, y = trp.normal.y, z = trp.normal.z}  
      end
    end
  end
  --dump(#vertices .. " makes " .. (#vertices - #crossPoints))

  for pIndex = 1, #vertices - #settings.crossPoints do

    -- get the four point indices 
    local this = pIndex-1
    local right = pIndex
    if right % #settings.crossPoints == 0 then
      right = right - #settings.crossPoints 
    end
    local up = this + #settings.crossPoints
    local upRight = right + #settings.crossPoints


    
    faces[#faces+1] = {v = this, n = this,u=this}
    faces[#faces+1] = {v = up, n =up,u=up}
    faces[#faces+1] = {v = right, n =right,u=right}

    faces[#faces+1] = {v = up, n =up,u=up}
    faces[#faces+1] = {v = upRight, n =upRight,u=upRight}
    faces[#faces+1] = {v = right, n =right, u=right}
         
    --normals[#normals+1] = --M.normalVector(vertices[this+1], vertices[right+1], vertices[up+1])
  end


  return {
    verts = vertices,
    uvs = uvs,
    normals = normals,
    faces = faces
  }
  
end

-- gets a part of a spline that goes from inclusive begin to inclusive end
local function getSubSpline(spline, inclIndexBegin, inclIndexEnd) 
  local ret = {}
 --dump("getting subspline from " .. inclIndexBegin .. " t "..inclIndexEnd)
  local len = #spline
  for i = inclIndexBegin, inclIndexEnd do
    local index = ((i-1) % len)+1
   -- dump(i.. " to taking index " .. index)
    ret[i - inclIndexBegin +1] = spline[index]
  end
 -- dump(#ret.. "from incl " .. inclIndexBegin .. " to incl " .. inclIndexEnd)
  return ret
end

-- finds and returns the next index in control points where the field OriginalIndex is not nil.
local function findOriginalIndexAfter(currentIndex, controlPoints)
    for i = currentIndex+1, #controlPoints do
    if controlPoints[i].originalIndex ~= nil then
      return controlPoints[i].originalIndex, i
    end
  end
  return nil, nil
end

-- hashes the spline into smaller pieces that have one overlapping element between each piece.
local function hashSplineAndCreateMeshes( spline)
  local totalNumberOfControlPoints = #spline
  local maxPartLength = settings.segmentLength
  local currentStartIndex = 1
  local currentOriginalFromIndex = 1
  local currentOriginalFromIndex, currentEndIndex = M.findFieldAfter("originalIndex",currentStartIndex,spline)
  local splines = {}
  while currentEndIndex ~= nil do
    
    if currentEndIndex ~= currentStartIndex then
      local subSpline = {}
      
     -- subSpline.meshes = {}
     -- subSpline.meshes[1] =  M.caluclateMeshInfo(subSpline,0)
     -- subSpline.meshes[2] =  M.caluclateMeshInfo(subSpline,1)
     -- subSpline.meshes[3] =  M.caluclateMeshInfo(subSpline,2)
      subSpline.startIndex = currentStartIndex
      subSpline.endIndex = currentEndIndex
      splines[#splines+1] =  subSpline
      
    end
    currentStartIndex = currentEndIndex
    currentOriginalFromIndex, currentEndIndex = M.findFieldAfter("originalIndex",currentStartIndex,spline)

   -- dump("totalNumberOfControlPoints" .. totalNumberOfControlPoints ..  " currentEndIndex " .. currentEndIndex)

  end

  return splines
end

-------------------------------
-- helper and mini functions --
-------------------------------

local function normalVector(a,b,c) 

  local v1x = (b.x-a.x)
  local v1y = (b.y-a.y)
  local v1z = (b.z-a.z)

  local v2x = (c.x-a.x)
  local v2y = (c.y-a.y)
  local v2z = (c.z-a.z)
  
  local x = v1y * v2z - v1z * v2y
  local y = v1z * v2x - v1x * v2z
  local z = v1x * v2y - v1y * v2x

  local lenInverse = 1 / (math.sqrt(x*x + y*y+ z*z) + 1e-30)
  return {
	  x = x * lenInverse,
	  y = y * lenInverse,
	  z = z * lenInverse
  }
end

local function getABC(t,ta,tb, pa,pb)
  local paFac = (tb-t)/(tb-ta)
  local pbFac = (t-ta)/(tb-ta)
  return {
    x = paFac*pa.x + pbFac*pb.x, 
    y = paFac*pa.y + pbFac*pb.y, 
    z = paFac*pa.z + pbFac*pb.z
    }
end

local function getP(points, p1Index)
  local len = #points
  local index = p1Index-1
  return ((index + len - 1) % len) + 1, p1Index, ((index + 1) % len) + 1, ((index + 2) % len) + 1
end

local function getT(t,p0,p1) 
  local a = math.pow(p1.x-p0.x,2) + math.pow(p1.y-p0.y,2) + math.pow(p1.z-p0.z,2)
  local b = math.pow(a,0.5)
  local c = math.pow(b,alpha)
  return c+t
end


local function alignPoint(point, alignTo)
  local r = M.rotateVectorByQuat(point,alignTo.rot)
  local q = point.rot:__mul(alignTo.rot)
  return {
    x = r.x + alignTo.x,
    y = r.y + alignTo.y,
    z = r.z + alignTo.z,
    rot = q
  }
end

local function getRotatedTranslatedPoints(crossSection, originPoint, rotationQuaternion)
  local rtp = {}
  local rtn = {}

  local nx = M.rotateVectorByQuat({x=1,y=0,z=0},rotationQuaternion)
  local ny = M.rotateVectorByQuat({x=0,y=1,z=0},rotationQuaternion)
  local nz = M.rotateVectorByQuat({x=0,y=0,z=1},rotationQuaternion)
  --dump(settings.normalLUT[1001])
  local adjusted = {}
  local xAdjusted = 0

  local normal
  for i,p in ipairs(crossSection) do

    -- first, construct cross section according to width
    adjusted = {}
    xAdjusted = 0
    if p.pos == "bot" or p.pos == "top" then  
      xAdjusted = (p.x * originPoint.width*0.5)  
    elseif p.pos == "left" then
      xAdjusted = (p.x - originPoint.width*0.5)
    elseif p.pos == "right" then
      xAdjusted = (p.x + originPoint.width*0.5)
    end
      adjusted = {
        x = xAdjusted * nx.x + p.y * ny.x + p.z * nz.x,
        y = xAdjusted * nx.y + p.y * ny.y + p.z * nz.y,
        z = xAdjusted * nx.z + p.y * ny.z + p.z * nz.z
      }
    --local n = M.rotateVectorByQuat(p.normal, rotationQuaternion)
     
    normal = settings.normalLUT[math.floor(originPoint.width * settings.LUTDetail +1.5)][i]
    rtp[i] = {
      x = adjusted.x + originPoint.x,
      y = adjusted.y + originPoint.y,
      z = adjusted.z + originPoint.z,
      normal = {
        x = normal.x * nx.x + normal.y * ny.x + normal.z * nz.x,
        y = normal.x * nx.y + normal.y * ny.y + normal.z * nz.y,
        z = normal.x * nx.z + normal.y * ny.z + normal.z * nz.z
      }
    }
  end
  originPoint.verticesForControlPoint = rtp


end

local function rotateVectorByQuat(v, q)
  return {
    x = ((1 - 2*q.y*q.y - 2*q.z*q.z) * v.x) + (2*(q.x*q.y + q.w*q.z)      * v.y) + (2*(q.x*q.z - q.w*q.y)       * v.z),
    y = (2*(q.x*q.y - q.w*q.z)       * v.x) + ((1- 2*q.x*q.x - 2*q.z*q.z) * v.y) + (2*(q.y*q.z + q.w*q.x)       * v.z),
    z = (2*(q.x*q.z + q.w*q.y)       * v.x) + (2*(q.y*q.z - q.w*q.x)      * v.y) + ((1 - 2*q.x*q.x - 2*q.y*q.y) * v.z)
  }
end

local function norVec(vec)
  local dist = M.dist(0,0,vec.x,vec.y)
  if dist ~= 0 then
    return {x = vec.x / dist, y = vec.y / dist, originalLength = dist}
  else
    return nil
  end
end

-- returns the distance from a/b to x/y.
local function dist(a,b,x,y)
  return math.sqrt((a-x)*(a-x) + (b-y)*(b-y)) 
end

M.materialize = materialize
M.caluclateMeshInfo = caluclateMeshInfo
M.getSubSpline = getSubSpline
M.hashSplineAndCreateMeshes = hashSplineAndCreateMeshes
M.normalVector = normalVector
M.getABC = getABC
M.getP = getP
M.getT = getT
M.alignPoint = alignPoint
M.getRotatedTranslatedPoints = getRotatedTranslatedPoints
M.rotateVectorByQuat = rotateVectorByQuat
M.interpolateBanking = interpolateBanking
M.interpolateHeight = interpolateHeight
--M.findHeightAfter = findHeightAfter
M.getLengthFromTo = getLengthFromTo
M.dist3 = dist3
--M.findBankAfter = findBankAfter
M.measureTrack = measureTrack
M.measureCrossPointsWidth = measureCrossPointsWidth
M.addCheckPointPositions = addCheckPointPositions
M.settings =settings
M.calcAllPoints = calcAllPoints
M.getCatmullRomPoints = getCatmullRomPoints
M.getBezierPoints = getBezierPoints

--M.findOriginalIndexAfter = findOriginalIndexAfter

M.findFieldAfter = findFieldAfter
M.interpolateField = interpolateField
M.interpolateWidth = interpolateWidth
M.MakeCap = MakeCap
M.CalcNormalLUT = CalcNormalLUT
return M