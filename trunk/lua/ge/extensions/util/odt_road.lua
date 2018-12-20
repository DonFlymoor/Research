local Road = {}
Road.__index = Road

local stepSize = 2

local materialInfo = {}
local xOff= nil 
local yOff= nil 



----------------------------------------------------------
---         Road Creation and Construction             ---
----------------------------------------------------------

-- This function creates one road segment consisting of multiple lanes and sections. 
-- Returns a road-object which can then be used to add lanes and stuff.
local function create(name, length, id  )
    local r = {}
    setmetatable(r,Road)
    r.geometry = {}
    r.laneSections = {}
    r.laneOffsets = {}
    r.length = length
    r.id = id
    r.name=name
    

    materialInfo = {
        lane = {
            driving = {
                material = "road_asphalt_2lane",
                renderPriority = 10
            },
            border = {
                material = "drain1",
                renderPriority = 9
            },
            sidewalk = {
                material = "concrete_precast",
                renderPriority = 8
            },
            shoulder = {
                material = "road_asphalt_2lane",
                renderPriority = 7
            }
        },
        roadMark = {
            
            solid = {
                material = "line_white",
                renderPriority = 2
            },
            broken = {
                material = "line_white_dashed",
                renderPriority = 1
            }
        }
    }

    setmetatable(materialInfo.lane,     {__index = function() return {material = "no_mat", renderPriority = 20} end})
    setmetatable(materialInfo.roadMark, {__index = function() return {material = "no_mat", renderPriority = 3} end})

    return r
end



-- This functions adds one geometry object to the road.
-- s: the offset from beginning of the road.
-- tag: can be 'arc', 'spiral' and 'line'
-- x,y: position of the start
-- hdg: heading of the geometry
-- length: length of the geometry
-- e1,e2: extra info for arc and spiral.
function Road:addGeometry(s, tag, x, y, hdg, length, e1, e2, e3, e4, e5, e6, e7, e8, e9) 
    local g = {}
    g.s = s
    g.tag = tag
    if xOff == nil then
        xOff = x
        yOff = y
    end
    g.x = x
    g.y = y
    g.hdg = hdg
    g.length = length

    if tag == "arc" then
        g.curvature = e1
    elseif tag == "spiral" then
        g.curvatureStart = e1
        g.curvatureEnd = e2
    elseif tag == "paramPoly3" then
        g.aU = e1
        g.aV = e2
        g.bU = e3
        g.bV = e4
        g.cU = e5
        g.cV = e6
        g.dU = e7
        g.dV = e8
        g.pRange = e9
    end
    self.geometry[#self.geometry+1] = g
end

-- adds a lane section with the offset s.
function Road:addLaneSection(s, index)
    local ls = {}
    ls.s = s
    ls.lanes = {}
    ls.id = index

    self.laneSections[index] = ls
end

function Road:addLaneOffset(s,a,b,c,d)
    local o = {}
    o.s = s
    o.a = a
    o.b = b
    o.c = c
    o.d = d
    self.laneOffsets[#self.laneOffsets+1] = o
end

-- adds a lane to a section.
function Road:addLane(sectionId,id, laneType, level, widths, roadmarks) 
    local l = {}
    l.id = id
    l.laneType = laneType
    l.level = level
    l.widths = widths
    l.roadmarks = roadmarks

    table.sort(l.widths, self.compareWidthOrRoadMark)
    table.sort(l.roadmarks, self.compareWidthOrRoadMark)

    l.section = self.laneSections[sectionId]



    l.name ="R"..tostring(self.id).."_S"..tostring(l.section.id)
    if l.id > 0 then
        l.name = l.name.. "_Ll"..tostring(l.id)
    elseif l.id < 0 then
        l.name = l.name.. "_Lr"..tostring(-l.id)
    else 
        l.name = l.name.. "_Lc0"
    end

    for i,r in ipairs(l.roadmarks) do
        r.name = l.name.."_rm"..tostring(i)
        r.lane = l
        r.id = i
    end

    self.laneSections[sectionId].lanes[id] = l
end

-- used to order Roadmarks or Widths.
function Road:compareWidthOrRoadMark( a ) return tonumber(a.sOffset) > tonumber(self.sOffset) end



----------------------------------------------------------
---        Calculation of Points Functions             ---
----------------------------------------------------------



-- this function gets all the points for one roadmark, including the widths.
function Road:getRoadMarkPoints(roadmark)

    local sFrom = roadmark.lane.section.s + roadmark.sOffset
    local sTo = self.length
    if roadmark.lane.roadmarks[roadmark.id+1] ~= nil then
            sTo = roadmark.lane.section.s + roadmark.lane.roadmarks[roadmark.id+1].sOffset
    elseif self.laneSections[roadmark.lane.section.id+1] ~= nil then
        sTo = self.laneSections[roadmark.lane.section.id+1].s
    end

    return self:getPointsByFunction(roadmark,sFrom, sTo, Road.getRoadMarkPoint)

end

-- this function gets all the points for one lane, inclding the widths.
function Road:getLanePoints(lane)
    local sFrom = lane.section.s
    local sTo = self.length
    if self.laneSections[lane.section.id+1] ~= nil then
        sTo = self.laneSections[lane.section.id+1].s
    end

    return self:getPointsByFunction(lane,sFrom, sTo, Road.getLanePoint)
end


function Road:getPointsByFunction(lane, sFrom, sTo, fn) 

    local s = sFrom
    local points = {}
    local p =  fn(self, lane, sFrom)
    local pn = fn(self, lane, sTo)
    points[#points+1] = p
    points[#points+1] = pn

    local done = false
    local oneAddition = 0
    while not done do
        local newPoints = {}
        done =true
        --dump(#points)
        for i=1,#points-1 do
            local p = points[i]
            local pn = points[i+1]
            local dist = math.sqrt((pn.x-p.x)*(pn.x-p.x) + (pn.y-p.y)*(pn.y-p.y))
            newPoints[#newPoints+1] = p
            if dist > stepSize then
               -- dump(i.." to " .. (i+1).. " = ".. dist)
               -- dump(p)
               -- dump(pn)
                local min = {p=nil, rel=1.1, minA=stepSize*10, minB=stepSize*10}
                for off =  p.s,pn.s,(pn.s-p.s)/100 do
                    local m = fn(self, lane, off)
                    local dA = math.sqrt((m.x-p.x)*(m.x-p.x) + (m.y-p.y)*(m.y-p.y))
                    local dB =  math.sqrt((m.x-pn.x)*(m.x-pn.x) + (m.y-pn.y)*(m.y-pn.y))
                    local rel = math.abs(1-math.abs(dA/dB))

                    if rel < min.rel and dA > stepSize/4 and dB > stepSize/4 then
                        min.p = m
                        min.rel = rel
                        min.off = off
                    end
                    
                end
            
                if min.p then
                    done = false
                    newPoints[#newPoints+1] = min.p
                end
            end
        end
        newPoints[#newPoints+1] = points[#points]
        if #newPoints +1 == #points then
            oneAddition = oneAddition+1
        end
        if oneAddition > 2 then
            done = true
        end
        points = newPoints
    end

    return points
end


function Road:getRoadOffset(s)
    for i,off in ipairs(self.laneOffsets) do
        if self.laneOffsets[i+1] == nil or tonumber(self.laneOffsets[i+1].s) > s then
            s = s - off.s
            return tonumber(off.a) + tonumber(off.b)*s + tonumber(off.c)*s*s + tonumber(off.d)*s*s*s
        end
    end
    return 0
    
end


-- returns one point for a roadmark at point s. s is the offset fron the start of the road.
function Road:getRoadMarkPoint(roadmark, s)

    local point = self:getPoint(s)
    if point == nil then
        return nil
    end
    local offset = self:getRoadMarkOffset(roadmark, s - roadmark.lane.section.s)
    
   -- dump(point.t)

    point.x = point.x + math.cos(point.n) * offset
    point.y = point.y + math.sin(point.n) * offset
    point.w = roadmark.width
    return point

end


-- returns one point for a lane at point s. s is the offset fron the start of the road.
function Road:getLanePoint(lane, s)
    -- dump(self)
    local point = self:getPoint(s)
    local offset = self:getLaneOffset(lane, s - lane.section.s)
    local width = self:getLaneWidth(lane, s - lane.section.s)
    offset = offset + sign(lane.id) * width/2

    if point ~= nil then
        point.x = point.x + math.cos(point.n) * offset
        point.y = point.y + math.sin(point.n) * offset
        point.w = width
    end
    
    return point

end



-- this function returns the offset for one lane, which is the sum of the widths
-- of all the lanes towards the center of the road. does not include the half-width
-- of the lane in question. ds is the offset from the start of the lane section.
function Road:getLaneOffset(lane, ds)
    local s = ds 
    local off = 0

    for i=sign(lane.id), lane.id - sign(lane.id), sign(lane.id) do  
        off = off + self:getLaneWidth(lane.section.lanes[i], s)
    end
    local sign = sign(lane.id)
    if sign == 0 then
        sign = 1
    end
    return self:getRoadOffset(ds + lane.section.s) + off * sign

end

-- this function gets the offset for the roadmark, which is the sum of all the width
-- of all the lanes towards the center of the road, including the lane of the roadmark.
-- ds is the offset from the start of the lane section.
function Road:getRoadMarkOffset(roadmark, ds)

    local s = ds 
    local off = 0
    local lane = roadmark.lane
    if lane.id ~= 0 then 
        for i=sign(lane.id), lane.id , sign(lane.id) do
            off = off + self:getLaneWidth(lane.section.lanes[i], s)
        end
    end
    local sign = sign(lane.id)
    if sign == 0 then
        sign = 1
    end
    return self:getRoadOffset(ds + roadmark.lane.section.s) + off * sign
end

-- gets the width of a lane. ds is the offset from the start of the lane section.
function Road:getLaneWidth(lane, ds)
    local s = ds
    for i,width in ipairs(lane.widths) do
        if lane.widths[i+1] == nil or tonumber(lane.widths[i+1].sOffset) > s then
            s = s - width.sOffset
            return tonumber(width.a) + tonumber(width.b)*s + tonumber(width.c)*s*s + tonumber(width.d)*s*s*s
        end
    end
    dump("something went wrong...")
end


-- gets a point with a given offset of the road.
function Road:getPoint(s)
    --dump(s)
    for i, geo in ipairs(self.geometry) do
        if self.geometry[i+1] == nil or self.geometry[i+1].s > s then
        --    dump("s = ".. s .. " geo = " .. geo.tag)
            if geo.tag == "line" then
                return self:getLinePoint(geo,s)
            elseif geo.tag == "arc" then
                return self:getArcPoint(geo,s)
            elseif geo.tag == "spiral" then
                return self:getSpiralPoint(geo,s)
            elseif geo.tag =="paramPoly3" then
                return self:getParamPolyPoint(geo, s)
            end
        end
    end
    return nil
end

function Road:getParamPolyPoint(poly, s)
    -- dump(poly)
    local p = 0
    -- transform s to p
    if poly.pRange == nil or poly.pRange ~= 'arcLength' then
        -- transform p so that poly.s = 0 and poly.length = 1
        p =  s - poly.s
        p = p / poly.length
    else
        -- transform p so that poly.s = 0 and poly.length = poly.length
        p = s - poly.s
    end
    local uVec = {
        x = math.cos(poly.hdg),
        y = math.sin(poly.hdg)
    }
    local vVec = {
        x = -uVec.y,
        y = uVec.x
    }
    local a = {
        x = poly.aU * uVec.x + poly.aV * uVec.x,
        y = poly.aU * uVec.y + poly.aV * uVec.y
    }
    local b = {
        x = poly.aU * uVec.x*p + poly.aV * uVec.x*p,
        y = poly.aU * uVec.y*p + poly.aV * uVec.y*p
    }
    local c = {
        x = poly.aU * uVec.x*p*p + poly.aV * uVec.x*p*p,
        y = poly.aU * uVec.y*p*p + poly.aV * uVec.y*p*p
    }
    local d = {
        x = poly.aU * uVec.x*p*p*p + poly.aV * uVec.x*p*p*p,
        y = poly.aU * uVec.y*p*p*p + poly.aV * uVec.y*p*p*p
    }

    local t = poly.hdg -- add the derivative of poly at point s, transformed to radians (total will be angle to x axis)
    local n = t + math.pi/2 
    return {
        x = poly.x + a.x + b.x + c.x + d.x,
        y = poly.y + a.y + b.y + c.y + d.y,
        n = n,
        t = t,
        tag = 'paramPoly3',
        s = s
    }

end

-- gets a point on a line.
function Road:getLinePoint(line, s)
    return {
        x = line.x + math.cos(line.hdg) * (s-line.s),
        y = line.y + math.sin(line.hdg) * (s-line.s),
        n = line.hdg + math.pi/2,
        t = line.hdg,
        tag = 'line',
        s = s
    }
end

-- gets a point on an arc.
function Road:getArcPoint(arc, s)
    local alpha = (s-arc.s) * arc.curvature 

    local circleX = arc.x + math.cos(arc.hdg + math.pi/2) /arc.curvature
    local circleY = arc.y + math.sin(arc.hdg + math.pi/2) /arc.curvature

    return {
        x = circleX + math.cos(arc.hdg -math.pi/2 + alpha)/arc.curvature,
        y = circleY + math.sin(arc.hdg -math.pi/2 + alpha)/arc.curvature,
        n = arc.hdg + math.pi/2 + alpha,
        t = arc.hdg + alpha,
        tag =  'arc',
        s = s
    }
end


-- gets a point on a spiral.
function Road:getSpiralPoint(spiral, s)
    local scalingFactor, adjustedLength = self:computeFacAndLength(spiral.curvatureStart,spiral.curvatureEnd,spiral.length)
    local curvatureStart = sign(spiral.curvatureStart)   * math.sqrt(math.abs(spiral.curvatureStart   * adjustedLength/2))
    local curvatureEnd   = sign(spiral.curvatureEnd  )   * math.sqrt(math.abs(spiral.curvatureEnd     * adjustedLength/2))
    local d = (s-spiral.s) * (curvatureEnd - curvatureStart)/spiral.length + curvatureStart

    local x,y = self:fresnelSC(d)
    local origX, origY = self:fresnelSC(curvatureStart)

    -- translate coordinates so that the beginning of the curve is at 0/0
    x = x - origX
    y = y - origY
    
    -- calculate rotation at starting point of the curve
    local theta = spiral.curvatureStart * (adjustedLength/2)
    if spiral.curvatureEnd < spiral.curvatureStart then -- flip curve if backwards
        x = -x
    elseif sign(spiral.curvatureStart) == sign(spiral.curvatureEnd) and math.abs(spiral.curvatureStart) - math.abs(spiral.curvatureEnd) <0 then -- flip rotation if curve moving "towards 0"
        theta = -theta
    end
    
    -- scale accordingly
    x = x * scalingFactor
    y = y * scalingFactor

    -- rotate curve
    x,y = self:rotVectorAroundOrigin(x,y,theta + spiral.hdg)

    -- translate curve so that the beginning is at the position specified in the curve
    x = x + spiral.x
    y = y + spiral.y
    
    return {
        x = x,
        y = y,
        n = d*d  + spiral.hdg + theta + math.pi/2,
        t = d*d  + spiral.hdg + theta,
        tag = 'spiral',
        s = s
    }


end

-- helper function to rotate points
function Road:rotVectorAroundOrigin(x,y, theta)
    return x * math.cos(theta) - y * math.sin(theta), x * math.sin(theta) + y * math.cos(theta)
end

-- helper function for the spiral calculation.
function Road:computeFacAndLength( curvatureStart, curvatureEnd, length )
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
function Road:fresnelSC(d) 
    if d == 0 then return 0,0 end
    local point = {x = 0, y = 0}
    local dx, dy
   -- local t = curvatureStart
    
    local oldt = 0
    local current = {}
    
    local subdivisions = math.max(150,math.floor(d*250))
    local dt = d/subdivisions

    for i=0, subdivisions-1 do
        local t= (i*d)/subdivisions
        dt = (((i+1)*d)/subdivisions) - t

        oldt = t
        dx = math.cos( ( t * t) ) * dt
        dy = math.sin( ( t * t) ) * dt     
        point= {x = point.x + dx, y = point.y + dy}    
    end
    return point.x, point.y
 
end

-- returns n!
function Road:fact (n)
      if n == 0 then
        return 1
      else
        return n * self:fact(n-1)
      end
end    



----------------------------------------------------------
---         Road to TorqueScript functions             ---
----------------------------------------------------------


-- This function returns a the TS-Code to create all elements of this road. 
-- First return value is for the lanes, second return value is for the roadmarks.
function Road:getTS() 
    local totalTS = [[
        if(isObject(RoadGroup_]]..self.id..[[)) {
            RoadGroup_]]..self.id..[[.delete();
        }
        new SimGroup(RoadGroup_]]..self.id..[[); 
        RoadGroup_]]..self.id..[[.clear();
        ODT_Roadgroup.add(RoadGroup_]]..self.id..[[);

        ]]

    dump("TS for "..self.id)
    for sId, laneSection in ipairs(self.laneSections) do
        dump("Section "..sId)
        for lId, lane in pairs(laneSection.lanes) do   
            dump("Lane "..lId)
            totalTS = totalTS .. self:getLaneTS(lane)
            for _,roadmark in ipairs(lane.roadmarks) do
                totalTS = totalTS .. self:getRoadMarkTS(roadmark)
            end
        end
    end
    return totalTS
end




function Road:addStartEndTangentPoints(pnts)
    if pnts[1] and pnts[2] ~= nil then
        local distFirstSecond = math.sqrt(
            (pnts[1].x-pnts[2].x)*(pnts[1].x-pnts[2].x) 
            + (pnts[1].y-pnts[2].y)*(pnts[1].y-pnts[2].y)
            )

        local distPenUltimate = math.sqrt(
            (pnts[#pnts].x-pnts[#pnts-1].x)*(pnts[#pnts].x-pnts[#pnts-1].x) 
            + (pnts[#pnts].y-pnts[#pnts-1].y)*(pnts[#pnts].y-pnts[#pnts-1].y)
            )

        local ret = {}

        ret[#ret+1] = {
            x=pnts[1].x-math.cos(pnts[1].t)*distFirstSecond, 
            y=pnts[1].y-math.sin(pnts[1].t)*distFirstSecond, 
            w = pnts[1].w 
        }

        for _,p in ipairs(pnts) do
            ret[#ret+1] = p
        end

        ret[#ret+1] = {
            x=pnts[#pnts].x+math.cos(pnts[#pnts].t)*distPenUltimate, 
            y=pnts[#pnts].y+math.sin(pnts[#pnts].t)*distPenUltimate, 
            w=pnts[#pnts].w 
        }

        return ret
        
    end
    
end


-- This function returns the TS-Code for one specific lane, exclusing roadmarks.
function Road:getLaneTS(lane) 
    if lane.id == 0 or lane.laneType == "none" then return " " end

    local points = self:getLanePoints(lane)
    points = self:addStartEndTangentPoints(points)

    local mat = materialInfo.lane[lane.laneType]

    local roadTS = [[
        RoadGroup_]]..self.id..[[.add(new DecalRoad(]]..lane.name..[[) {
        Material = "]]..mat.material..[[";
        textureLength = "5";
        breakAngle = "1";
        renderPriority = "]]..mat.renderPriority..[[";
        zBias = "0";
        startEndFade = "0 0";
        position = "0 0 0";
        rotation = "1 0 0 0";
        scale = "1 1 1";
        canSave = "1";
        canSaveDynamicFields = "1";
        drivability = "-1";
        improvedSpline = "1";
        startTangent = "1"; 
        endTangent = "1";
        detail = "1";
    ]]

    if points ~= nil then
        roadTS = roadTS .. self:pointsToNodes(points)
    end
    roadTS = roadTS..'});  '
    
    -- dump('RoadTS: ' .. roadTS)

    return roadTS
end

-- This function returns the TS-Code for one specific roadmark.
function Road:getRoadMarkTS(roadmark) 
    
    if roadmark.roadMarkType == "none" then
        return ""
    end
    local points = self:getRoadMarkPoints(roadmark)   
    points = self:addStartEndTangentPoints(points)

    local mat = materialInfo.roadMark[roadmark.roadMarkType]

    local roadTS = [[
        RoadGroup_]]..self.id..[[.add(new DecalRoad(]]..roadmark.name..[[) {
        Material = "]]..mat.material..[[";
        textureLength = "5";
        breakAngle = "1";
        renderPriority = "]]..mat.renderPriority..[[";
        zBias = "-1";
        startEndFade = "0 0";
        position = "0 0 0";
        rotation = "1 0 0 0";
        scale = "1 1 1";
        canSave = "1";
        canSaveDynamicFields = "1";
        drivability = "-1";
        improvedSpline = "1";
        startTangent = "1"; 
        endTangent = "1";
        detail = "1";
    ]]
    
    
    if points ~= nil then
        roadTS = roadTS .. self:pointsToNodes(points)
    end
        
    roadTS = roadTS..'});  '
    
    
    return roadTS
end

function Road:pointsToNodes(points)
    local ret = ''
    if points == nil then
        return nil
    end
    for _,p in ipairs(points) do
        ret = ret..'Node="'..(p.x)..' '..(p.y)..' 0 '
        if p.w ~= nil then
            ret = ret .. p.w
        else
            ret = ret .. '2'
        end
        ret = ret .. '"; '
    end
    return ret
end










Road.create = create
return Road
