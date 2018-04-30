local M = {}
local logTag = 'splineTrack'
local alpha = 0.5
local controlNodesMultiplier = 2.5


local track = {
  currentEnd = {x=0,y=0,z=0, rot=quatFromEuler(0,0,0,1)},
  pieces = {}
}


local onlyControlNodes = true


--------------------------------------
-- Actual track modification fuctions.
--------------------------------------
-- creates a straight track piece of length, which twists to bank rad over its full length.
local function trackStraight(length, bank )
  local piece = {}
  local endQuat
  if bank then
    endQuat = quatFromEuler(0,-bank,0)
  else
    endQuat = quat(0,0,0,1)
  end
  local points = {}
  local count = math.floor(length)
  for i = -1, count+1 do
   local  t = i / count
    points[#points+1] = {
      x = 0,
      y = t * length,
      z = 0,
      rot = quat(0,0,0,1)
    }
  end

 -- points[#points-1].bank = endQuat

  piece.points = points
  M.appendTrackPiece(piece)
  return points

end


-- creates a smoothed curve.
-- angle: from 1 to 6 (increments in 60° steps)
-- curvature: inverse of the radius of the curve
-- angleDivider: from 0 to 0.5, how much of the curve should be the spiral
-- heightfunction either a function returning height and slope, or a single value (cubic function will be used)
-- banking: in radians, how much the inner part of the curve should be banked
-- fresnelExponent: how quickly the curvature changes across the spiral length.
local function trackSmoothCurve(angle, curvature, angleDivider, heightFunction, banking, fresnelExponent) 
  local piece = {}
  local pointsA = {}
  local pointsB = {}
  local pointsC = {}
  local endQuat
  local pieces = math.ceil((math.ceil(angle) / 5))+1
  local sign = 1
  if curvature < 0 then
    sign = -1
    curvature = math.abs(curvature)
  end
  local bank = banking or math.pi/3
  bank = bank * sign


  local circleX = 1 / curvature
  local circleY = 0

  local mirrorDirX, mirrorDirY = -math.cos(angle/2), math.sin(angle/2)
  
  local totalAngle = angle 
  if not angleDivider then
    angleDivider = 0.5 / (angle*2)
    if angleDivider > 0.3 then
      angleDivider = 0.3
    elseif angleDivider < 0.05 then
      angleDivider = 0.05
    end
  end
  
  local fresnelExponent =fresnelExponent or 2
  local spiralAngle = math.abs(totalAngle * angleDivider)
  local arcAngle = totalAngle - spiralAngle*2

  local bankFunction = function(p) if p <= 0 then return 0,0 elseif p >= 1 then return 1 else return -2*p*p*p + 3*p*p end end
  -- create a height function if none or a number is give.
  if type(heightFunction) == 'number' then
    local hi = heightFunction
    heightFunction = function(p) if p <= 0 then return 0,0 elseif p >= 1 then return hi,0 else return -2*hi*p*p*p + 3*hi*p*p, -6*hi*p*p+6*hi*p end end
  elseif not heightFunction then
    heightFunction = function(p) return 0,0 end
  end
  

  -- step 1: make and arc to angleDivier percent of the total angle. mirror those along the mirror line.

  -- target position of the unscaled fresnel part.
  local sY,sX = M.fresnelSC(math.pow(fresnelExponent*spiralAngle,1/fresnelExponent),nil,fresnelExponent)

  -- curvature at the end point (unscaled), and center point of the circle created by this curvature
  local k = (math.pow(fresnelExponent*spiralAngle,1/fresnelExponent)) / math.sqrt(2)
  local kX,kY = sX + math.cos(spiralAngle) / k, sY - math.sin(spiralAngle) / k
  
  dump(kX.."/"..kY)
  local pieces = math.ceil(spiralAngle * 10)+1
  pieces = math.floor(pieces * controlNodesMultiplier)

  
  for i = -1, pieces do
    -- parameter for the fresnel.
    local d = (i/pieces) * math.pow(math.abs(fresnelExponent*spiralAngle),1/fresnelExponent)
    if i < 0 then
      d = -d 
    end
    local bankPercent = i/pieces
    local y,x = M.fresnelSC(d,nil,fresnelExponent) -- original fresnel code grows along x axis, then upward, thus the switch of x/y.
    -- angle at current point of the spiral
    local alpha = (math.pow(math.abs(d),fresnelExponent))*sign/fresnelExponent

    -- create quaternion and point
    local rot =quat()
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) *  math.sin(0)
    rot.y = math.sin(alpha/2) *0
    rot.z = math.sin(alpha/2) *  math.cos(0)
    rot:normalize()
    local bankQuat =  nil
    --quat(0,0,0,1):nlerp(quatFromEuler(0,-bank,0),bankFunction(bankPercent))
    if i == pieces then
      bankQuat = quatFromEuler(0,-bank,0)
    end
    dump(bankQuat)
    pointsA[#pointsA+1] = {
        x = x,
        y = y,
        z = 0,
        rot = rot,
        bank = bankQuat
    }

    -- get mirrored point.
    rot =quat()
    alpha = (totalAngle - alpha*sign)*sign

    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) *  math.sin(0)
    rot.y = math.sin(alpha/2) *0
    rot.z = math.sin(alpha/2) *  math.cos(0)
    rot:normalize()
  
    local mX, mY = M.mirrorPointAlongLine(x,y,kX,kY,mirrorDirX,mirrorDirY)

     pointsC[#pointsC+1] = {
        x = mX,
        y = mY,
        z = 0,
        rot = rot,
        bank = bankQuat
    }
  end


  -- step 2: create arc to connect the spirals.
  pieces = math.ceil(arcAngle * 7)+1
  pieces = pieces * controlNodesMultiplier
  for i = 1, pieces-1 do
    -- angle and point of the arc
    local alpha = (i/pieces) * arcAngle + (spiralAngle)
    local x = kX - math.cos(0 + alpha)/k
    local y = kY + math.sin(0 + alpha)/k
    

    local rot =quat()
    alpha = alpha * sign
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) *  math.sin(0)
    rot.y = math.sin(alpha/2) *0
    rot.z = math.sin(alpha/2) *  math.cos(0)
    rot:normalize()

    pointsB[#pointsB+1] = {
        x = x,
        y = y,
        z = 0,
        rot = rot,
        bank = nil --quatFromEuler(0,-bank,0)
    }
  end

  -- string up points into one final list.
  local points = {}
  for _,p in ipairs(pointsA) do points[#points+1] = p end
  for _,p in ipairs(pointsB) do points[#points+1] = p end
  for i,p in ipairs(pointsC) do points[#points+1] = pointsC[#pointsC+1 - i] end

  -- step 3: scale up to fit target curvature

  -- end point if the curve was a perfect arc
  local endX,endY = circleX - math.cos(angle)/curvature, circleY + math.sin(angle)/curvature
  local endLength = M.dist(0,0,endX,endY)
  local unscaledLength = M.dist(0,0,pointsC[2].x,pointsC[2].y)
  local scale = endLength /unscaledLength
  if scale < 1 then
    scale = 10
  end
  for _,p in ipairs(points) do 
    p.x = p.x *scale * sign
    p.y = p.y *scale
    p.z = p.z *scale
  end
 


  -- part 4: add height function
  local totalLength = 0
  for i,p in ipairs(points) do 
    if i > 1 and i < #points-1 then 
      totalLength = totalLength + M.dist(p.x,p.y,points[i+1].x,points[i+1].y)
    end
  end

  local len = 0
  for i,p in ipairs(points) do 
    if i > 1 and i <= #points-1 then 
      -- t is the percent of total length
      local t = len / totalLength
      local height,slope = heightFunction(t)
      slope = slope / scale
      p.z = height
      p.rot = quatFromEuler(math.atan2(1,slope)/2- math.pi/4,0,0):__mul(p.rot)
      len = len + M.dist(p.x,p.y,points[i+1].x,points[i+1].y) -- add length to next.
    end
  end

  -- handle point 1 and last (endpoints) for height function
  local len = -M.dist(points[1].x,points[1].y,points[2].x,points[2].y)
  local t = len / totalLength
  local height,slope = heightFunction(t)
  slope = slope / scale
  local angle = math.atan2(1,slope)- math.pi/2
  points[1].z = height
  points[1].rot = quatFromEuler(angle,0,0):__mul(points[1].rot)

  -- last point
  len = totalLength +  M.dist(points[#points-1].x,points[#points-1].y,points[#points].x,points[#points].y)
  t = len / totalLength
  height,slope = heightFunction(t)
  slope = slope / scale
  angle = math.atan2(1,slope)- math.pi/2
  points[#points].z = height
  points[#points].rot = quatFromEuler(angle,0,0):__mul(points[#points].rot)



 

  dump("final end Point is " .. points[#points-1].x .." / " .. points[#points-1].y .. " / ".. points[#points-1].z)

  -- create piece.
  piece.points = points
  M.appendTrackPiece(piece)
  return points
end

local function applyElevation(points, heightDifference)


end


-- creates a spiral track piece. this can be used to ease the curvature to a desired value. 
-- twists to bank over its full length. 
-- zAngle decides the direction of the arc: 0 to left, in radian counter clockwise, so pi/2 goes upward.
local function trackSpiral(length, curvatureStart, curvatureEnd,zAngle, bank)
  local piece = {}
  local points = {}
  local endQuat = quat(0,0,0,1)
  if bank then
    endQuat = quatFromEuler(0,-bank,0)
  else
    endQuat = quat(0,0,0,1)
  end
  
  zAngle = zAngle or 0
  local pieces = math.ceil((math.ceil(length) / 5))+1
  
    local scalingFactor, adjustedLength = M.computeFacAndLength(curvatureStart,curvatureEnd,length)
    local curvStart = sign(curvatureStart)   * math.sqrt(math.abs(curvatureStart   * adjustedLength/2))
    local curvEnd   = sign(curvatureEnd  )   * math.sqrt(math.abs(curvatureEnd     * adjustedLength/2))
    dump("...")
    dump("adjLen" .. adjustedLength)
    dump("scFac" .. scalingFactor)
    dump("curvEnd" .. curvEnd)
  for i = -1, pieces+1 do
    local s = i * (length/pieces)
    local t = i/pieces
   


    local d = (s) * (curvEnd - curvStart)/length + curvStart

    local x,y = M.fresnelSC(d)
    local origX, origY = M.fresnelSC(curvStart)

    -- translate coordinates so that the beginning of the curve is at 0/0
    x = x - origX
    y = y - origY
    
    -- calculate rotation at starting point of the curve
    local theta = curvatureStart * (adjustedLength/2)
    local flipCurve = false
    if curvatureEnd < curvatureStart then -- flip curve if backwards
        x = -x
        flipCurve = true
    elseif sign(curvatureStart) == sign(curvatureEnd) and math.abs(curvatureStart) - math.abs(curvatureEnd) <0 then -- flip rotation if curve moving "towards 0"
        theta = -theta
        
    end
    
    -- scale accordingly
    x = x * scalingFactor
    y = y * scalingFactor

    -- rotate curve
    y,x = M.rotVectorAroundOrigin(x,y,theta) -- swap x and y to align with y axis instead of x axis from the original code

    -- translate curve so that the beginning is at the position specified in the curve
    
    local rot =quat()
    local alpha = d*d 
    if flipCurve then alpha = -alpha
    end
    alpha = alpha + theta
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) * math.sin(-zAngle)
    rot.y = math.sin(alpha/2) *0
    rot.z = math.sin(alpha/2) * math.cos(-zAngle)
    rot:normalize()

    local z = math.sin(zAngle) * x
    x = math.cos(zAngle) * x

    local currentQuat = quat(0,0,0,1):nlerp(endQuat,t)

    points[#points+1] = {
        x = x,
        y = y,
        z = z,
        rot = currentQuat:__mul(rot)
    }
    dump(alpha)
  end

  piece.points = points
  M.appendTrackPiece(piece)
  return points
end

-- creates an arc (curve) with a given curvature.
-- twists to bank over its full length. 
-- zAngle decides the direction of the arc: 0 to left, in radian counter clockwise, so pi/2 goes upward.
local function trackArc(length, curvature, zAngle, bank, heightFunction)
  local piece = {}
  local points = {}
  local endQuat
  if bank then
    endQuat = quatFromEuler(0,bank,0)
  else
    endQuat = quat(0,0,0,1)
  end
  zAngle = zAngle or 0

  -- create a height function if none or a number is give.
  if type(heightFunction) == 'number' then
    local hi = heightFunction
    heightFunction = function(p) if p <= 0 then return 0,0 elseif p >= 1 then return hi,0 else return -2*hi*p*p*p + 3*hi*p*p, -6*hi*p*p+6*hi*p end end
  elseif not heightFunction then
    heightFunction = function(p) return 0,0 end
  end

  local pieces = math.ceil(math.abs((length))/6 )+1
  pieces = math.floor(pieces * controlNodesMultiplier)
  
  local circleX = 1 / curvature
  local circleY = 0
  for i = -1, pieces+1 do
    local alpha = (i*(length/pieces)) * curvature 
    local t = i/pieces

    local x = circleX - math.cos(0 + alpha)/curvature 
    local y = circleY + math.sin(0 + alpha)/curvature 
    -- now we have the points on the XY plane. next to rotate them around the Y axis, on the XZ plane.

   -- local z = math.sin(zAngle) * x
   -- x = math.cos(zAngle) * x


    local rot =quat()
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) * math.sin(-zAngle)
    rot.y = math.sin(alpha/2) *0
    rot.z = math.sin(alpha/2) * math.cos(-zAngle)
    rot:normalize()

    --dump(rot)
    points[#points+1] = {
        x = x,
        y = y,
        z = z,
        rot = (rot),
        bank = nil
    }
  end

 --  add height function
  local totalLength = 0
  for i,p in ipairs(points) do 
    if i > 1 and i < #points-1 then 
      totalLength = totalLength + M.dist(p.x,p.y,points[i+1].x,points[i+1].y)
    end
  end

  local len = 0
  for i,p in ipairs(points) do 
    if i > 1 and i <= #points-1 then 
      -- t is the percent of total length
      local t = len / totalLength
      local height,slope = heightFunction(t)
      slope = slope / totalLength
      local angle = math.atan2(1,slope)- math.pi/2
      p.z = height
      p.rot = quatFromEuler(angle * math.cos(zAngle),0,0):__mul(p.rot)
      len = len + M.dist(p.x,p.y,points[i+1].x,points[i+1].y) -- add length to next.
    end
  end

  -- handle point 1 and last (endpoints) for height function
  local len = -M.dist(points[1].x,points[1].y,points[2].x,points[2].y)
  local t = len / totalLength
  local height,slope = heightFunction(t)
  slope = slope / totalLength
  local angle = math.atan2(1,slope)- math.pi/2
  points[1].z = height
  points[1].rot = quatFromEuler(angle,0,0):__mul(points[1].rot)

  -- last point
  len = totalLength +  M.dist(points[#points-1].x,points[#points-1].y,points[#points].x,points[#points].y)
  t = len / totalLength
  height,slope = heightFunction(t)
  slope = slope 
  angle = math.atan2(1,slope)- math.pi/2
  points[#points].z = height
  points[#points].rot = quatFromEuler(angle,0,0):__mul(points[#points].rot)


  -- rotate points around zAngle if needed.
  if zAngle ~= 0 then
    for _,p in ipairs(points) do 
      local z = math.sin(zAngle) * p.x + math.cos(zAngle) * p.z
      local x = math.cos(zAngle) * p.x + math.sin(zAngle) * p.z
      p.x = x
      p.z = z

    end

  end

  piece.points = points
  --dump(piece)
  M.appendTrackPiece(piece)
  return points
end

local function trackElevate(len, height)
  local gamma = math.pi - (2 * (math.atan2(len,height)))
  local radius = (M.dist(0,0,len,height) / (math.sin(gamma/2) * 2))
  radius = radius /2

  local endPoint = {x = len, y = 0, z = height}
  local piece = {}
  

  local pieces = math.ceil(math.abs((len))/10 )+1
  pieces = pieces * controlNodesMultiplier
  pieces = 10
  local circleY = 0
  local circleZ = 0
  local pointsA = {}
  local pointsB = {}
  local length = gamma * radius
  local curvature = 1/radius
  for i = -1, pieces-1 do
    local alpha = (i*(length/pieces)) * curvature 
    local t = i/pieces

    local y = 0 + math.sin( alpha)*radius
    local z = radius - math.cos( alpha)*radius
    


    local rot =quat()
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) * -1
    rot.y = math.sin(alpha/2) * 0
    rot.z = math.sin(alpha/2) * 0
    rot:normalize()
    local currentQuat = quat(0,0,0,1)
    --dump(rot)
    pointsA[#pointsA+1] = {
        x = 0,
        y = y,
        z = z,
        rot = currentQuat:__mul(rot)
    }

    y = len - y
    z = height - z
    alpha = - alpha
    rot =quat()
    rot.w = math.cos(alpha/2)
    rot.x = math.sin(alpha/2) * 1
    rot.y = math.sin(alpha/2) * 0
    rot.z = math.sin(alpha/2) * 0
    rot:normalize()
    local currentQuat = quat(0,0,0,1)
    --dump(rot)
    pointsB[#pointsB+1] = {
        x = 0,
        y = y,
        z = z,
        rot = currentQuat:__mul(rot)
    }    
  end

  local points = {}
  for _,p in ipairs(pointsA) do points[#points+1] = p end
 for i,p in ipairs(pointsB) do points[#points+1] = pointsB[#pointsB+1 - i] end

 --points[#points-1].bank = quat(0,0,0,1)
  piece.points = points
  --dump(piece)
  M.appendTrackPiece(piece)
  return points

 -- M.trackArc(gamma * radius, 1/radius, math.pi/2)
 -- M.trackArc(gamma * radius, -1/radius, math.pi/2)
end


--removes last piece.
local function undoPiece() 
  local totalTS = [[
    if(isObject(]]..track.pieces[#track.pieces].name..[[))
    { ]]..track.pieces[#track.pieces].name..[[.delete(); }]]
  TorqueScript.eval(totalTS)
  track.pieces[#track.pieces] = nil
  if #track.pieces == 0 then 
    track.currentEnd = {x=0,y=0,z=0, rot=quat(0,0,0,1)}
  else
    track.currentEnd = track.pieces[#track.pieces].points[#track.pieces[#track.pieces].points-1]
  end
end

-- removes all pieces.
local function undoAll() 
  while #track.pieces > 0 do M.undoPiece() end
  M.resetStart()
  
end

-- reset start to a hardcoded value.
local function resetStart()
   track.currentEnd = {x=0,y=0,z=0, rot=quat(0,0,0,1)}
end

local function uniteCurrentTrack(closed) 
  local unifiedPiece = {}
  local points = {}
  M.resetStart()
  --local quat = quatFromEuler(0,0.5,0)
  if not closed then
    points[1] = track.pieces[1].points[1]
  end
 -- points[#points+1] = track.pieces[1].points[2]

  for _,piece in ipairs(track.pieces) do
    for i,point in ipairs(piece.points) do 
      if i > 2 and i < #piece.points then
       -- point.rot = quat:__mul(point.rot)
        points[#points+1] = point--M.alignPoint(point, track.currentEnd)
      end
    end
    --track.currentEnd = points[#points]
  end
  if not closed then
    -- add very last point
    points[#points+1] = track.pieces[#track.pieces].points[#track.pieces[#track.pieces].points]
  end
  points[1].bank = quat(0,0,0,1)
  points[#points].bank = quat(0,0,0,1)
  return points
end


-----------------------------
-- math and helper functions
------------------------------

local function appendTrackPiece(piece, mat)

  for i,p in ipairs(piece.points) do
    piece.points[i] = M.alignPoint(p,track.currentEnd)
  end
 -- dump(track)
  piece.name = "Piece_"..#track.pieces
  track.pieces[#track.pieces+1] = piece
  track.currentEnd = piece.points[#piece.points-1]
  --dump(piece)
 
    if mat then
      piece.object = M.materialize(piece)
    end
  
end

   

local function alignPoint(point, alignTo)
  local r = M.rotateVectorByQuat(point,alignTo.rot)
  local q = point.rot:__mul(alignTo.rot)
  return {
    x = r.x + alignTo.x,
    y = r.y + alignTo.y,
    z = r.z + alignTo.z,
    rot = q,
    bank = point.bank
  }
end

local function getRotatedTranslatedPoints(crossSection, originPoint, rotationQuaternion)
  local ret = {}
  for i,p in ipairs(crossSection) do
    local r = M.rotateVectorByQuat(p,rotationQuaternion)
    ret[i] = {
      x = r.x + originPoint.x,
      y = r.y + originPoint.y,
      z = r.z + originPoint.z,
    }
  end
  return ret
end

local function rotateVectorByQuat(v, q)
  return {
    x = ((1 - 2*q.y*q.y - 2*q.z*q.z) * v.x) + (2*(q.x*q.y + q.w*q.z)      * v.y) + (2*(q.x*q.z - q.w*q.y)       * v.z),
    y = (2*(q.x*q.y - q.w*q.z)       * v.x) + ((1- 2*q.x*q.x - 2*q.z*q.z) * v.y) + (2*(q.y*q.z + q.w*q.x)       * v.z),
    z = (2*(q.x*q.z + q.w*q.y)       * v.x) + (2*(q.y*q.z - q.w*q.x)      * v.y) + ((1 - 2*q.x*q.x - 2*q.y*q.y) * v.z)
  }
end


-- returns the distance from a/b to x/y.
local function dist(a,b,x,y)
  return math.sqrt((a-x)*(a-x) + (b-y)*(b-y)) 
end

-- returns the distance from a/b to x/y.
local function dist3(a,b,c,x,y,z)
  return math.sqrt((a-x)*(a-x) + (b-y)*(b-y) + (c-z)*(c-z)) 
end


-- helper function to rotate points
local function rotVectorAroundOrigin(x,y, theta)
    return x * math.cos(theta) - y * math.sin(theta), x * math.sin(theta) + y * math.cos(theta)
end

-- helper function for the spiral calculation.
local function computeFacAndLength( curvatureStart, curvatureEnd, length )
    local adjustedLength = length
    if curvatureStart == 0 and curvatureEnd == 0 or curvatureStart == curvatureEnd then
        return nil, nil
    end
    local big = curvatureStart
    local small = curvatureEnd
    if math.abs(curvatureStart) < math.abs(curvatureEnd) then     
        big = curvatureEnd
        small = curvatureStart
    end
    big = big
    small = small
    if sign(big) ~= sign(small) then   
        adjustedLength = length/(math.sqrt( math.abs(small) / math.abs(big) ) +1)
    else
        local sqrtStart = math.sqrt(math.abs(big))
        local sqrtEnd = math.sqrt(math.abs(small))
        adjustedLength = length/((sqrtStart - sqrtEnd) / sqrtStart)
    end
    local scalingFactor = math.sqrt(math.abs((1/big)) * math.abs(adjustedLength) * 2)

    return scalingFactor, adjustedLength
end

-- helper function for the spiral caluclation. returns point from an euler spiral.
local function fresnelSC(d, subs, fresnelExponent) 
    if d == 0 then return 0,0 end
    local point = {x = 0, y = 0}
    local dx, dy
   -- local t = curvatureStart
    
    local oldt = 0
    local current = {}
    
    local subdivisions = math.max(150,math.floor(d*400))
    if subs then 
      subdivisions = subs
    end
    fresnelExponent = fresnelExponent or 2
    local dt = d/subdivisions

    for i=0, subdivisions-1 do
        local t= (i*d)/subdivisions
        dt = (((i+1)*d)/subdivisions) - t

        oldt = t
        dx = math.cos( math.pow(t,fresnelExponent)/fresnelExponent ) * dt
        dy = math.sin( math.pow(t,fresnelExponent)/fresnelExponent ) * dt     
        point= {x = point.x + dx, y = point.y + dy}    
    end
    return point.x, point.y 
end

-- returns n!
local function fact (n)
      if n == 0 then
        return 1
      else
        return n * self:fact(n-1)
      end
end 
local function putFresnel()
  for e = 1.5,4, 0.5 do
    local targetC = 1
  for i = 0, 5, 0.01 do
    x,y = M.fresnelSC(i,nil,e)
    M.makeDot({x=x*20,y=y*20,z=20+30*e})
  end
end
  
end
M.putFresnel = putFresnel
local function solveIntersection(circleX, lineX,lineY, spiralX,spiralY)
  local a  = circleX / ((lineY*spiralX)/spiralY - lineX)
  return  circleX + a*lineX, a*lineY
end

local function mirrorPointAlongLine(x,y,x0,y0,nx,ny) 
  local dnx, dny = ((x-x0)*nx + (y-y0)*ny) * nx * 2, ((x-x0)*nx + (y-y0)*ny) * ny * 2
  return -x + 2*x0 + dnx, -y + 2*y0 + dny
end
M.trackElevate = trackElevate
M.trackSmoothCurve = trackSmoothCurve
M.mirrorPointAlongLine = mirrorPointAlongLine
M.solveIntersection = solveIntersection
M.undoPiece = undoPiece
M.undoAll = undoAll
M.resetStart = resetStart
M.appendTrackPiece = appendTrackPiece
M.trackStraight = trackStraight
M.trackSpiral = trackSpiral
M.rotVectorAroundOrigin = rotVectorAroundOrigin
M.computeFacAndLength = computeFacAndLength
M.fresnelSC = fresnelSC
M.fact = fact
M.trackArc = trackArc
M.alignPoint = alignPoint
M.getRotatedTranslatedPoints = getRotatedTranslatedPoints
M.rotateVectorByQuat = rotateVectorByQuat

M.dist3 = dist3
M.dist = dist

M.uniteCurrentTrack = uniteCurrentTrack
M.onlyControlNodes = onlyControlNodes

M.track = track


return M