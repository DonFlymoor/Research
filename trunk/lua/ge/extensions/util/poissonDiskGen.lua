local M = {}

local X0=0
local X1=0
local Y0=0
local Y1=0

local points = {}
local faces = {}





-- this function calculates the position of the keypoints
local function getGraph(width,height,radius)
  local minRad = radius

  local points = {}
  local active  = {}
  active[1] = {x=width/2, y=height/2}

  --dump(active)
  local finished = false
  while not finished do
   -- dump("another sequence.")
    local cIndex = math.random(#active)
    local current = active[cIndex]
    local tries = 50
    local added = false
    local candidate = {}
    while tries > 0 and not added do
     -- dump("try." .. tries)
      local r = (1+math.random()) * (minRad)
      local a = math.random() * 2 * math.pi
      candidate = {
          x = current.x + r * math.cos(a),
          y = current.y + r * math.sin(a);
      }
      -- now check the candidate.
      local badPoint = false
      local inside = false
      local i = 1
      while not badPoint and i <= #points do
        if M.dist(points[i].x,points[i].y,candidate.x,candidate.y) < minRad then
          badPoint = true
        end
        i = i+1
      end
      if candidate.x >= 0 and candidate.y >= 0 and candidate.x <= width and candidate.y <= height then
      	inside = true
      end

      
      if not badPoint and inside then
        points[#points+1] = candidate
        active[#active+1] = candidate
        added = true
      end
      tries = tries-1
    end

    if not added then
      -- remove current from active
      if #active == 1 then
        finished = true
      else
        active[cIndex] = active[#active]
        active[#active] = nil
      end
      -- nothing happens, we added a point and might add more.
    end

  end

  local graph = {
    nodes = points,
    start = nil,
    finish = nil
  }
  for i,p in ipairs(graph.nodes) do
    p.neighbours = {}
    p.name ="Point "..i
  end

  -- set center points and fill nodes from graph.
  

  local ret = M.getDelauny(graph.nodes)
  local edgeIndices = {}
  -- set neighbours for graph nodes.
  for ei,edge in ipairs(ret) do
  for i,a in ipairs(graph.nodes) do
      for j,b in ipairs(graph.nodes) do
        if graph.nodes[i] == edge[1] and graph.nodes[j] == edge[2] then
        	edgeIndices[ei] = {
						i1 = i,
						i2 = j,
						edge = edge
					}
           graph.nodes[i].neighbours[#graph.nodes[i].neighbours+1] = {
            index = j,
            dist =  M.dist(graph.nodes[i].x,graph.nodes[i].y,graph.nodes[j].x,graph.nodes[j].y)
          }

          graph.nodes[j].neighbours[#graph.nodes[j].neighbours+1] = {
            index = i,
            dist =  M.dist(graph.nodes[j].x,graph.nodes[j].y,graph.nodes[i].x,graph.nodes[i].y)
          }
        end
      end
    end
  end
  graph.edges = ret
  graph.edgeIndices = edgeIndices
  -- determine closest neighbours and add to graph nodes.
  for i,r in ipairs(graph.nodes) do
    r.closestNeighbourDist = 1000000
    for _,n in ipairs(r.neighbours) do
      if n.dist < r.closestNeighbourDist then
        r.closestNeighbourDist = n.dist
      end 
    end
    graph.nodes[i].closestNeighbourDist = r.closestNeighbourDist
  end

  return graph
end




-- returns the distance from a/b to x/y.
local function dist(a,b,x,y)
  return math.sqrt((a-x)*(a-x) + (b-y)*(b-y)) 
end







local function makeFace(a,b,c) 
	local sortedPoints = {a,b,c}
	local center = {x = a.x + b.x + c.x , y= a.y + b.y + c.y}
	center.x = center.x / 3
	center.y = center.y / 3
	table.sort(sortedPoints, function(a,b) return math.atan2(a.y-center.y,a.x-center.x) < math.atan2(b.y-center.y,b.x-center.x) end)
--	dump("face created."..sortedPoints[1].name..sortedPoints[2].name..sortedPoints[3].name .. " atans: "..math.atan2(sortedPoints[1].y-center.y,sortedPoints[1].x-center.x) .." |" ..math.atan2(sortedPoints[2].y-center.y,sortedPoints[2].x-center.x) .. " | " ..math.atan2(sortedPoints[3].y-center.y,sortedPoints[3].x-center.x))
	local face = {
		a=sortedPoints[1],
		b=sortedPoints[2],
		c=sortedPoints[3]
	}
	return face
end

local function faceContainsPoint(face, p)
 		return sameSide(p,face.a, face.b,face.c) 
 			and  sameSide(p,face.b, face.a,face.c)
      and  sameSide(p,face.c, face.a,face.b) 
end
function sameSide(p1,p2, a,b)
    local cp1 = crossProduct({x=b.x-a.x,y=b.y-a.y}, {x=p1.x-a.x,y=p1.y-a.y})
    local cp2 = crossProduct({x=b.x-a.x,y=b.y-a.y}, {x=p2.x-a.x,y=p2.y-a.y})
    return cp2 > 0 and cp1 >=0 or cp2 < 0 and cp1<=0 
end

function crossProduct( a, b )
	return a.x * b.y - a.y * b.x
end


local function getDelauny(inPoints)

	points = {}
	faces = {}
	local names = {'A','B','C','D','E','F','G','H','I','J','K','L'}
	local center = {x=0, y=0}

	for i,p in ipairs(inPoints) do
	  if p.x < X0 then X0 = p.x end
    if p.y < Y0 then Y0 = p.y end
    if p.x > X1 then X1 = p.x end
    if p.y > Y1 then Y1 = p.y end
    center.x = center.x + p.x
    center.y = center.y + p.y
	end
	for i,p in ipairs(points) do p.name = names[i] end
	center.x = center.x / #inPoints
	center.y = center.y / #inPoints

	local dx = (X1-X0) 
	local dy = (Y1-Y0) 
	

	points[1] = {x=center.x        , y=center.y +dy, name="1 "}
	points[2] = {x=center.x - 3*dx , y=center.y - .75*dy, name="2 "}
	points[3] = {x=center.x + 3*dx , y=center.y - .75*dy, name="3 "}
	faces[1]=M.makeFace(points[1],points[2],points[3])
--	dump(faces[1])
	--dump(M.faceContainsPoint(faces[1],center))
	for i,p in ipairs(inPoints) do
	M.processPoint(p)
	end
	
	local out = {}
	for i,f in ipairs(faces) do
		if not(f.a == points[1] or f.b == points[1] or f.c == points[1]
			or f.a == points[2] or f.b == points[2] or f.c == points[2]
			or f.a == points[3] or f.b == points[3] or f.c == points[3])
			
		then
			out[#out+1] = M.thinFace(f)
		end
	end

	local edges = {}
	for i,f in ipairs(out) do
		
		local add = {}
		if not f.aSharp and not f.bSharp then
			add[#add+1] = {f.a,f.b}
		end
		if not f.aSharp and not f.cSharp then
			add[#add+1] = {f.a,f.c}
		end
		if not f.bSharp and not f.cSharp then
			add[#add+1] = {f.b,f.c}
		end
		
		for _,a in ipairs(add) do
			local contained = false
			for _,e in ipairs(edges) do
				if e[1] == a[1] and e[2] == a[2] or e[1] == a[2] and e[2] == a[1] then
					contained = true
				end
			end
			if not contained then
				edges[#edges+1] = a
			end
		end

	end

	return edges
end

local function thinFace(f) 
	local ab = {x=f.b.x-f.a.x,y=f.b.y-f.a.y}
	local abLen = math.sqrt(ab.x*ab.x+ab.y*ab.y)
	ab.x = ab.x/abLen
	ab.y = ab.y/abLen

	local bc = {x=f.c.x-f.b.x,y=f.c.y-f.b.y}
	local bcLen = math.sqrt(bc.x*bc.x+bc.y*bc.y)
	bc.x = ab.x/bcLen
	bc.y = ab.y/bcLen

	local ca = {x=f.a.x-f.c.x,y=f.a.y-f.c.y}
	local caLen = math.sqrt(ca.x*ca.x+ca.y*ca.y)
	ca.x = ca.x/caLen
	ca.y = ca.y/caLen

	f.bSharp = math.abs(ab.x*bc.x + ab.y*bc.y) >.8
	f.cSharp = math.abs(ca.x*bc.x + ca.y*bc.y) >.8
	f.aSharp = math.abs(ab.x*ca.x + ab.y*ca.y) >.8
	return f
end
M.thinFace = thinFace

local function processPoint(p)
	local index,face = M.findFaceOf(p)
	if  not index then
return
	end
	faces[index] = M.makeFace(face.a,face.b,p)
	local i1 = #faces+1
	local i2 = #faces+2
	faces[i1] = M.makeFace(face.b,face.c,p)
	faces[i2] = M.makeFace(face.c,face.a,p)

	M.validateEdge(p,faces[index],index)
	M.validateEdge(p,faces[i1],i1)
	M.validateEdge(p,faces[i2],i2)

end

local function findFaceOf(p)
	for i,f in ipairs(faces) do
		if M.faceContainsPoint(f,p) then
	--		dump(p)
	--		dump("is in")
	--		dump(f)
			return i,f
		end
	end
end

local function validateEdge(p,face, faceIndex)
	local indOther,otherFace,uniquePoint,samePoints = M.findOpposingFace(p,face)

	--dump("checking for p = " .. p.name .. " in ".. face.a.name..face.b.name..face.c.name)

	if indOther then
		--dump(" other face of "..face.a.name .. "/"..face.b.name.."/"..face.c.name .. " is " .. otherFace.a.name.."/"..otherFace.b.name.."/"..otherFace.c.name)
		--dump("Found Other face..")
		if M.inCircle(face.a,face.b,face.c,uniquePoint) then
			--dump(uniquePoint.name.." is in "..face.a.name..face.b.name..face.c.name)
		--dump("instead of "..samePoints[1].name..samePoints[2].name .. " now goes through " ..p.name .. uniquePoint.name)
			faces[indOther] = M.makeFace(p,uniquePoint,samePoints[1])
			faces[faceIndex] = M.makeFace(p,uniquePoint,samePoints[2])

			M.validateEdge(p,faces[indOther],indOther)
			M.validateEdge(p,faces[faceIndex],faceIndex)

		else
			--dump(uniquePoint.name.." not contained in circle of "..face.a.name..face.b.name..face.c.name)
		end
	end
	--dump("No Other face for p = "..p.name .. " of ".. face.a.name .. "/"..face.b.name.."/"..face.c.name )

end


local function findOpposingFace(p,face)
	local a
	local b
	if face.a == p then
		a=face.b
		b=face.c
	elseif face.b == p then
		a=face.a
		b=face.c
	elseif face.c == p then
		a=face.a
		b=face.b
	end
	for i,f in ipairs(faces) do
		if f ~= face then
			--dump("checking another face.")
			if f.a == a then
				if f.b == b then
					return i,f,f.c,{f.a,f.b}
				elseif f.c == b then
					return i,f,f.b,{f.c,f.a}
				end

			elseif f.b == a then
				if f.c == b then
					return i,f,f.a,{f.b,f.c}
				elseif f.a == b then
					return i,f,f.c,{f.a,f.b}
				end

			elseif f.c == a then
				if f.b == b then
					return i,f,f.a,{f.b,f.c}
				elseif f.a == b then
					return i,f,f.b,{f.c,f.a}
				end

			end
		end

	end

end


local function inCircle(a,b,c,d)
	local A = a.x - d.x
	local B = a.y - d.y
	local C = (math.pow(a.x-d.x,2) + math.pow(a.y-d.y,2))

	local D = b.x - d.x
	local E = b.y - d.y
	local F = (math.pow(b.x-d.x,2) + math.pow(b.y-d.y,2))

	local G = c.x - d.x
	local H = c.y - d.y
	local I = (math.pow(c.x-d.x,2) + math.pow(c.y-d.y,2))

	return A*E*I + B*F*G + C*D*H -C*E*G - B*D*I - A*F*H > 0
end




M.makeFace = makeFace
M.findFaceOf = findFaceOf
M.processPoint = processPoint
M.crossProduct = crossProduct
M.sameSide = sameSide
M.faceContainsPoint = faceContainsPoint
M.getDelauny = getDelauny
M.validateEdge= validateEdge
M.findOpposingFace = findOpposingFace
M.inCircle = inCircle
M.getGraph = getGraph
M.dist = dist
return M