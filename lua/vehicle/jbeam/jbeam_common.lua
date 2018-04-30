--[[
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

--[[doxygen
increases max id
@param vehicle    a table type for vehicles
@param name    the key of maxIDs
@return maxIDs

Example usage:
@code
-- add nodes
increaseMax(vehicleTable, "nodes")
-- vehicle maxID's will be increased by one
@endcode
void increaseMax(string vehicle, string name);
--]]
function increaseMax(vehicle, name)
  local res = vehicle.maxIDs[name] or 0
  vehicle.maxIDs[name] = res + 1
  return res
end


--[[doxygen
addNodeWithOptions  add the node with options
@param vehicle    a table type for vehicle
@param parentSection    parent section
@param pos    position
@param ntype    type of node
@param options    options
@return nextID the next ID
void addNodeWithOptions(string vehicle, table parentSection, number pos, number ntype, table options);
--]]
function addNodeWithOptions(vehicle, parentSection, pos, ntype, options)
  local nextID = increaseMax(vehicle, 'nodes')

  local n = {}
  if type(options) == 'table' then
    n = deepcopy(options)
  end

  n.cid     = nextID
  n.pos     = pos
  n.ntype   = ntype
  n.creator = parentSection

  --log_jbeam('D', "jbeam.addNodeWithOptions","adding node "..(nextID)..".")
  table.insert(vehicle.nodes, n)
  return nextID
end
--[[doxygen
addNode add a new node into vehicles
@param vehicle    a table type for vehicle
@param parentSection    parent section
@param pos    position
@param ntype    type of node
@return nextID the next ID
table addNode(table vehicle, string parentSection, number pos, number ntype);
--]]
function addNode(vehicle, parentSection, pos, ntype)
  return addNodeWithOptions(vehicle, parentSection, pos, ntype, vehicle.options)
end

--[[doxygen
addBeamWithOptions add beams with options
@param vehicle    a table type for vehicle
@param parentSection    parent section
@param id1    id1
@param id2    id2
@param beamType    beam type
@param options    options
@return b or nil
table addBeamWithOptions(table vehicle, string parentSection, string id1, string id2, number beamType, table options);
--]]
function addBeamWithOptions(vehicle, parentSection, id1, id2, beamType, options, id3)
  if id1 == nil and options.id1 ~= nil then id1 = options.id1 end
  if id2 == nil and options.id2 ~= nil then id2 = options.id2 end

  -- check if nodes are valid
  local node1 = vehicle.nodes[id1]
  if node1 == nil then
    log_jbeam('W', "jbeam.addBeamWithOptions","invalid node "..tostring(id1).." for new beam between "..tostring(id1).."->"..tostring(id2))
    return
  end
  local node2 = vehicle.nodes[id2]
  if node2 == nil then
    log_jbeam('W', "jbeam.addBeamWithOptions","invalid node "..tostring(id2).." for new beam between "..tostring(id1).."->"..tostring(id2))
    return
  end

  -- increase counters
  local nextID = increaseMax(vehicle, 'beams')

  local b = {}
  if options ~= nil and type(options) == 'table' then
    b = deepcopy(options)
  end

  local node3
  if id3 ~= nil then
    node3 = vehicle.nodes[id3]
    if node3 == nil then
      log_jbeam('W', "jbeam.addBeamWithOptions","invalid node "..tostring(id3).." for new beam between "..tostring(id1).."->"..tostring(id2))
      return
    else
      beamType = BEAM_LBEAM
    end
    b.id3 = node3.cid
  end

  b.cid      = nextID
  b.id1      = node1.cid
  b.id2      = node2.cid
  b.beamType = beamType
  b.creator  = parentSection

  -- add the beam
  table.insert(vehicle.beams, b)
  return b
end

--[[doxygen
addBeam  add beam
@param vehicle    a table type for vehicle
@param parentSection    parent section
@param id1    id1
@param id2    id2
@return b or nil
table addBeam(table vehicle, string parentSection, string id1, string id2);
--]]
function addBeam(vehicle, parentSection, id1, id2)
  return addBeamWithOptions(vehicle, parentSection, id1, id2, NORMALTYPE, vehicle.options)
end

--[[doxygen
addRotator  add rotator
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
void addRotator(table vehicle, number wheelKey, table wheel);
--]]
function addRotator(vehicle, wheelKey, wheel)
  wheel.frictionCoef = wheel.frictionCoef or 1

  local nodes = {}
  if wheel._group_nodes ~= nil then
    arrayConcat(nodes, wheel._group_nodes)
  end

  if wheel._rotatorGroup_nodes ~= nil then
    arrayConcat(nodes, _rotatorGroup_nodes)
  end

  if next(nodes) ~= nil then
    wheel.nodes = nodes
  end
end
