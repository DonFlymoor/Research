--[[--
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

require("jbeam_common")
require("jbeam_wheels")

local mainPartType = 'main'

local min, max = math.min, math.max
local str_byte, str_sub, str_len, str_find = string.byte, string.sub, string.len, string.find

--[[
table M;
ignoreSections;
vehicle_base_path;
userPartConfig;
slotDescriptions;
materials;
materialsMap;
main;
partMap;
vehicles;
data;
slotMap;
vehicleDirectory;
_noSerialize disable module serialization;
--]]

local M = {}

M.ignoreSections = {maxIDs=true, options=true}

M.vehicle_base_path = "vehicles/"

M.userPartConfig = {}
M.userVars = {}

M.slotDescriptions = {}

M.materials, M.materialsMap = particles.getMaterialsParticlesTable()

M.main = {}

M.directoriesloaded = {}

M.partMap = {}

M.vehicles = {}

M.data = {}

M.slotMap = {}

M.vehicleDirectory = nil

M.variables = {}

M._noSerialize = true

M.jbeamVariableEnv = nil

local triTypeMap = {['NORMAL'] = NORMALTYPE, ['NONCOLLIDABLE'] = NONCOLLIDABLE}

local optionalLinks = {['torqueArm:'] = 1,['torqueArm2:'] = 1, ['torqueCoupling:'] = 1, ['torqueCouple:'] = 1, ['nodeArm:'] = 1, ['nodeCoupling:'] = 1, ['nodeCouple:'] = 1}

local expressionParser = nil

--[[doxygen
verify the element name
@param name the element name
@return true if match, otherwise false
Boolean verifyElementName(string name);
--]]
local function verifyElementName(name)
  local match = string.match(name, "^([a-z]+[a-zA-Z0-9]+)$")
  return (match ~= nil)
end

function tableToFloat3Default(v, default)
  if v == nil then
    return default
  end
  return float3(v.x or default.x, v.y or default.y, v.z or default.z)
end

local function _tableDeepestPath(tbl, path)
  if type(tbl) ~= "table" then
    return path
  end
  local pathidx = #path
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      path[pathidx] = k
      pathidx = pathidx + 1
      return _tableDeepestPath(v, path)
    end
  end
  return path
end

local function tableDeepestPath(tbl)
  local p = _tableDeepestPath(tbl, {})
  return p
end

local specialVals = {FLT_MAX = math.huge, MINUS_FLT_MAX = -math.huge}
local typeIds = {
  NORMAL = NORMALTYPE,
  HYDRO = BEAM_HYDRO,
  ANISOTROPIC = BEAM_ANISOTROPIC,
  TIRESIDE = BEAM_ANISOTROPIC,
  BOUNDED = BEAM_BOUNDED,
  PRESSURED = BEAM_PRESSURED,
  SUPPORT = BEAM_SUPPORT,
  LBEAM = BEAM_LBEAM,
  FIXED = NODE_FIXED,
  NONCOLLIDABLE = NONCOLLIDABLE,
  SIGNAL_LEFT = GFX_SIGNAL_LEFT,
  SIGNAL_RIGHT = GFX_SIGNAL_RIGHT,
  HEADLIGHT = GFX_HEADLIGHT,
  BRAKELIGHT = GFX_BRAKELIGHT,
  RUNNINGLIGHT = GFX_RUNNINGLIGHT,
  REVERSELIGHT = GFX_REVERSELIGHT
}

--[[doxygen
replace the val with special values
@param val the variable need to be replaced
@return the replaced val
string replaceSpecialValues(string val);
--]]
local function replaceSpecialValues(val)
  local typeval = type(val)
  if typeval == "table" then
    -- recursive replace
    for k, v in pairs(val) do
      val[k] = replaceSpecialValues(v)
    end
    return val
  end
  if typeval ~= "string" then
    -- only replace strings
    return val
  end

  if specialVals[val] then return specialVals[val] end

  if str_find(val, '|', 1, true) then
    local parts = split(val, "|", 999)
    local ival = 0
    for i = 2, #parts do
      local valuePart = parts[i]
      -- is it a node material?
      if valuePart:sub(1,3) == "NM_" then
        ival = particles.getMaterialIDByName(M.materials, valuePart:sub(4))
        --log_jbeam('D', "jbeam.replaceSpecialValues", "replaced "..valuePart.." with "..ival)
      end
      ival = bit.bor(ival, typeIds[valuePart] or 0)
    end
    if ival ~= 0 then
      --log_jbeam('D', "jbeam.replaceSpecialValues", "### replaced special flags variable '"..val.."' with value '"..tostring(ival).."'")
      return ival
    end
  end
  return val
end

--[[doxygen
process the table according to schema
@param vehicle    a table type contains vehicle information
@param keyEntry   the key entry
@param entry      the entry
@param newList    the new list
@return the size of new list
Boolean processTableWithSchema(table vehicle, number keyEntry, table entry, table newList);
--]]
local function processTableWithSchema(vehicle, keyEntry, entry, newList)
  -- its a list, so a table for us. Verify that the first row is the header
  local header = entry[1]
  if type(header) ~= "table" then
    log_jbeam('W', "processTableWithSchema", "*** Invalid table header: "..dumps(header))
    return false
  end
  if tableIsDict(header) then
    log_jbeam('W', "jbeam.processTableWithSchema", "*** Invalid table header, must be a list, not a dict: "..dumps(header))
    return false
  end

  local headerSize = #header
  local headerSize1 = headerSize + 1
  local newListSize = 0
  local localOptions = replaceSpecialValues(deepcopy( vehicle.options ) )

  -- remove the header from the data, as we dont need it anymore
  table.remove(entry,1)
  --log_jbeam('D', "jbeam.processTableWithSchema", "header size: "..headerSize)

  -- this was a correct able, record that
  vehicle.validTables[keyEntry] = true

  -- walk the list entries
  for rowKey, rowValue in ipairs(entry) do
    if type(rowValue) ~= "table" then
      log_jbeam('W', "processTableWithSchema", "*** Invalid table row: "..dumps(rowValue))
      return false
    end
    if tableIsDict(rowValue) then
      -- case where options is a dict on its own, filling a whole line
      tableMerge( localOptions, replaceSpecialValues(rowValue))
    else
      local newID = rowKey
      --log_jbeam('D', "jbeam.processTableWithSchema", " *** "..tostring(rowKey).." = "..tostring(rowValue).." ["..type(rowValue).."]")

      -- allow last type to be the options always
      if #rowValue > headerSize + 1 then -- and type(rowValue[#rowValue]) ~= "table" then
        log_jbeam('W', "jbeam.processTableWithSchema", "*** Invalid table header, must be as long as all table cells (plus one additional options column):")
        log_jbeam('W', "jbeam.processTableWithSchema", "*** Table header: "..dumps(header))
        log_jbeam('W', "jbeam.processTableWithSchema", "*** Mismatched row: "..dumps(rowValue))
        return false
      end

      -- walk the table row
      -- replace row: reassociate the header colums as keys to the row cells
      local newRow = deepcopy(localOptions)

      -- check if inline options are provided, merge them then
      for rk = headerSize1, #rowValue do
        local rv = rowValue[rk]
        if type(rv) == 'table' and tableIsDict(rv) and #rowValue > headerSize then
          tableMerge(newRow, replaceSpecialValues(rv))
          -- remove the options
          rowValue[rk] = nil -- remove them for now
          header[rk] = "options" -- for fixing some code below - let it know those are the options
          break
        end
      end

      -- now care about the rest
      for rk,rv in ipairs(rowValue) do
        --log_jbeam('D', "jbeam.processTableWithSchema", "### "..header[rk].."//"..tostring(newRow[header[rk]]))
        -- if there is a local option named like a row key, use the option instead
        -- copy things
        if header[rk] == nil then
          log_jbeam('E', "jbeam.processTableWithSchema", "*** unable to parse row, header for entry is missing")
          log_jbeam('E', "jbeam.processTableWithSchema", "*** header: "..dumps(header))
          log_jbeam('E', "jbeam.processTableWithSchema", "*** row: "..dumps(rowValue))
        else
          newRow[header[rk]] = replaceSpecialValues(rv)
        end
      end

      if newRow.id ~= nil then
        newID = newRow.id
        newRow.name = newRow.id -- this keeps the name for debugging or alike
        newRow.id = nil
      end

      -- done with that row
      newList[newID] = newRow
      newListSize = newListSize + 1
    end
  end

  return newListSize
end

--[[doxygen
vechicle preparation
@param vehicles    a table type for vehicles
Boolean prepare(table vehicles);
--]]
local function prepare(vehicles)
  if type(vehicles) ~= "table" then
    log_jbeam('E', "prepare", "*** Wrong top level vehicles type, must be table")
    return false
  end

  --log_jbeam('D', "jbeam.prepare"," found "..tableSize(vehicles).." vehicles")
  -- walk all vehicles
  for keyVehicle, vehicle in pairs(vehicles) do
    log_jbeam('D', "prepare","- Preparing jbeam. "..tostring(keyVehicle)) --.." = "..tostring(vehicle).." ["..type(vehicle).."], path: "..vehicleDirectory)
    -- check for nodes key
    vehicle.maxIDs = {}
    vehicle.validTables = {}
    vehicle.beams = vehicle.beams or {}
    if vehicle.nodes == nil then
      log_jbeam('W', "prepare","*** No nodes existing! '"..keyVehicle.."'")
      return false
    end
    -- create empty options
    vehicle.options = vehicle.options or {}
    -- walk everything and look for options
    for keyEntry, entry in pairs(vehicle) do
      if type(entry) ~= "table" then
        -- seems to be a option, add it to the vehicle options
        vehicle.options[keyEntry] = entry
        vehicle[keyEntry] = nil
      end
    end

    -- then walk all (keys) / entries of that vehicle
    for keyEntry, entry in pairs(vehicle) do
      -- verify key names to be proper formatted
      --[[
      if type(entry) == "table" and tableIsDict(entry) then
        log_jbeam('D', "jbeam.prepare"," ** "..tostring(keyEntry).." = [DICT] #" ..tableSize(entry))
      elseif type(entry) == "table" and not tableIsDict(entry) then
        log_jbeam('D', "jbeam.prepare"," ** "..tostring(keyEntry).." = [LIST] #"..tableSize(entry))
      else
        log_jbeam('D', "jbeam.prepare"," ** "..tostring(keyEntry).." = "..tostring(entry).." ["..type(entry).."]")
      end
      ]]--

      if verifyElementName(keyEntry) == false then
        log_jbeam('E', "prepare","*** Invalid attribute name '"..keyEntry.."'")
        return false
      end
      -- init max
      vehicle.maxIDs[keyEntry] = 0
      --log_jbeam('D', "jbeam.prepare"," ** creating max val "..tostring(keyEntry).." = "..tostring(vehicle.maxIDs[keyEntry]))
      -- then walk the tables
      if type(entry) == "table" and not tableIsDict(entry) and M.ignoreSections[keyEntry] == nil and not tableIsEmpty(entry) then
        if tableIsDict(entry) then
          -- ENTRY DICTS TO BE WRITTEN
        else
          local newList = {}
          local newListSize = processTableWithSchema(vehicle, keyEntry, entry, newList)
          vehicle[keyEntry] = newList
          log_jbeam('D', "prepare"," - "..tostring(newListSize).." "..tostring(keyEntry))
        end
      end
    end
    ::continue::
  end
  --log_jbeam('D', "prepare", "- Vehicle Preparation done.")

  return true
end

local function optimizeNodes(nodes)
  local maxID = 0
  local nonFixedNodes = {}
  local nonFixedNodesidx = 1
  local nonCollidableNodes = {}
  local nonCollidableNodesidx = 1
  -- nodes are a special kind
  for nodeName, node in pairs(nodes) do
    if node.fixed then
      node.cid = maxID
      maxID = maxID + 1
    elseif node.collision ~= nil and node.collision == false then
      nonCollidableNodes[nonCollidableNodesidx] = node
      nonCollidableNodesidx = nonCollidableNodesidx + 1
    else
      nonFixedNodes[nonFixedNodesidx] = node
      nonFixedNodesidx = nonFixedNodesidx + 1
    end
  end

  -- add non collidable nodes
  for _, node in ipairs(nonCollidableNodes) do
    node.cid = maxID
    maxID = maxID + 1
  end

  -- put non fixed nodes at the end
  for _, node in ipairs(nonFixedNodes) do
    node.cid = maxID
    maxID = maxID + 1
  end

  return maxID
end

--[[doxygen
assign CIDs to vehicles
@param vehicles    a table type for vehicles
@return true
Boolean assignCIDs(table vehicles);
--]]
local function assignCIDs(vehicles)
  -- walk all vehicles
  for keyVehicle, vehicle in pairs(vehicles) do
    vehicle.maxIDs = {}
    for keyEntry, entry in pairs(vehicle) do
      if vehicle.validTables[keyEntry] then
        local maxID = 0
        if keyEntry ~= 'nodes' then
          -- everything except nodes
          for rowKey, rowValue in pairs(entry) do
            rowValue.cid = maxID
            maxID = maxID + 1
          end
        else
          maxID = optimizeNodes(entry)
        end
        vehicle.maxIDs[keyEntry] = maxID
      end
    end
  end
  --log_jbeam('D', "jbeam.assignCIDs", "- Vehicle numbering done.")
  return true
end

--[[doxygen
prepare links for vehicles
@param vehicles    a table type for vehicles
@return a table type of links
table prepareLinks(table vehicles);
--]]
local function prepareLinks(vehicles)
  local links = {}
  local linksidx = 1
  local entrykeys = {}

  for _, vehicle in pairs (vehicles) do
    for keyEntry, entry in pairs (vehicle) do
      if type(entry) == "table" then
        local keysLen = 0
        for k, _ in pairs(entry) do
          keysLen = keysLen + 1
          entrykeys[keysLen] = k
        end
        for i = 1, keysLen do
          local rowKey = entrykeys[i]
          local rowValue = entry[rowKey]
          -- Check for links of the form: "link:section":[1,2,3,4]
          if type(rowValue) == "table" then
            if str_find(rowKey, ':', 1, true) then
              local parts = split(rowKey, ":", 2)
              if #parts == 2 then
                local sectionName = "nodes"
                if parts[2] ~= "" then
                  sectionName = parts[2]
                end

                if vehicle[sectionName] ~= nil then
                  for tKey, tValue in ipairs(rowValue) do
                    if vehicle[sectionName][tValue] ~= nil then
                      links[linksidx] = {
                        rv = rowValue,
                        kp = tKey, -- "id"
                        kc = nil,
                        ot = vehicle[sectionName][tValue]
                      }
                      linksidx = linksidx + 1
                    else
                      if not rowValue.optional or (type(rowValue.optional) == 'boolean' and rowValue.optional == false) then
                        log_jbeam('W', "jbeam.prepareLinks", "link target not found: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..tValue .. ' - DATA DISCARDED: ' .. dumps(rowValue))
                      else
                        log_jbeam('D', "jbeam.prepareLinks", "optional link discarded: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..tValue .. ' - OPTIONAL DATA DISCARDED')
                      end
                      entry[rowKey] = nil
                      break
                    end
                  end
                  entry[parts[1]..'_'..sectionName] = rowValue
                  entry[rowKey] = nil
                end
              end
            else
              for cellKey,cellValue in pairs(rowValue) do
                --log_jbeam('D', "jbeam.prepareLinks"," * key:"..tostring(cellKey).." = "..tostring(cellValue)..".")
                if str_find(cellKey, ':', 1, true) then
                  local parts = split(cellKey, ":", 3)
                  if #parts == 2 then
                    if string.match(parts[1], '%[.*%]') == nil then
                      -- its a link
                      -- default, resolve to nodes
                      local sectionName
                      if parts[2] ~= "" then
                        sectionName = parts[2]
                      else
                        sectionName = "nodes"
                      end

                      if vehicle[sectionName] ~= nil then
                        if type(cellValue) == "table" then
                          for tKey, tValue in ipairs(cellValue) do
                            if vehicle[sectionName][tValue] ~= nil then
                              links[linksidx] = {
                                rv = cellValue,
                                kp = tKey, -- "id"
                                kc = nil,
                                ot = vehicle[sectionName][tValue]
                              }
                              linksidx = linksidx + 1
                            else
                              if not rowValue.optional or (type(rowValue.optional) == 'boolean' and rowValue.optional == false) then
                                log_jbeam('W', "jbeam.prepareLinks", "link target not found: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..tValue .. ' - DATA DISCARDED: ' .. dumps(rowValue))
                              else
                                log_jbeam('D', "jbeam.prepareLinks", "optional link discarded: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..tValue .. ' - OPTIONAL DATA DISCARDED')
                              end
                              entry[rowKey] = nil
                              break
                            end
                          end
                        else
                          if vehicle[sectionName][cellValue] ~= nil then
                            links[linksidx] = {
                              rv = rowValue,
                              kp = parts[1], -- "id"
                              kc = cellKey,  -- "id:"
                              ot = vehicle[sectionName][cellValue]
                            }
                            linksidx = linksidx + 1
                          else
                            if optionalLinks[cellKey] == nil then
                              if not rowValue.optional or (type(rowValue.optional) == 'boolean' and rowValue.optional == false) then
                                log_jbeam('W', "jbeam.prepareLinks", "link target not found: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..cellValue .. ' - DATA DISCARDED: ' .. dumps(rowValue))
                              else
                                log_jbeam('D', "jbeam.prepareLinks", "optional link discarded: " .. keyEntry .. "/" .. rowKey .. " > "..sectionName.."/"..cellValue .. ' - OPTIONAL DATA DISCARDED')
                              end
                              entry[rowKey] = nil
                              break
                            end
                          end
                        end
                      end
                      -- else
                      --     local sectionName = "nodes"
                      --     if parts[2] ~= "" then
                      --         sectionName = parts[2]
                      --     end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return links
end

local function resolveLinks(vehicles, links)
  -- walk all vehicles
  for k,d in pairs(links) do
    d.rv[d.kp] = d.ot.cid
    if d.kc ~= nil then
      d.rv[d.kc] = nil
    end
  end

  for keyVehicle, vehicle in pairs(vehicles) do
    -- walk all sections
    for sectionName, section in pairs(vehicle) do
      if type(section) == "table" then
        -- walk all rows
        local newSection = {}
        for rowKey, rowValue in pairs(section) do
          if vehicle.validTables[sectionName] == true and rowValue.cid then
            newSection[rowValue.cid] = rowValue
          else
            newSection[rowKey] = rowValue
          end
        end
        vehicle[sectionName] = newSection
      end
    end
  end
  return true
end

local function resolveGroupLinks(vehicle)
  local journal = {}
  local groupindex = {}
  local table_clear = table.clear
  -- walk all sections
  for _, entry in pairs(vehicle) do
    -- walk all vehicle sections
    if type(entry) == "table" then
      for _, rowValue in pairs(entry) do
        if type(rowValue) == "table" then
          -- walk all cells
          for cellKey, groupvals in pairs(rowValue) do
            if str_byte(cellKey,1) == 91 then -- [
              local groupname
              local sectioname
              groupname, sectioname = string.match(cellKey, '%[(.*)%]:(.*)')
              if groupname then
                if type(groupvals) == 'string' then
                  groupvals = {groupvals}
                end
                local cids = {}
                table_clear(groupindex)
                -- Create groupvals index
                for _, gvalname in pairs(groupvals) do
                  groupindex[gvalname] = 1
                end
                -- walk all specified groups
                if sectioname == '' then sectioname = "nodes" end
                for _, val in pairs(vehicle[sectioname]) do
                  local vgn = val[groupname]
                  if vgn ~= nil then
                    local typevgn = type(vgn)
                    if typevgn == 'string' then
                      if groupindex[vgn] ~= nil then
                        val[groupname] = {vgn}
                        table.insert(cids, val.cid)
                      end
                    elseif typevgn == 'table' then
                      for _, gvalname in pairs(vgn) do
                        if groupindex[gvalname] ~= nil then
                          table.insert(cids, val.cid)
                          break
                        end
                      end
                    end
                  end
                end
                table.insert(journal, {rowValue, '_'..groupname..'_'..sectioname, cids})
              end
            end
          end
        end
      end
    end
  end

  -- play journal
  for _, val in ipairs(journal) do
    val[1][val[2]] = val[3]
  end
  return true
end

local function cleanCameraData(d)
  for k, v in pairs(d) do
    -- delete unneeded data to keep the messages small
    if k == 'group' or k == 'firstGroup' or k == 'partOrigin' or k == 'childParts'
    or k == 'partName' or k == 'slotType' or k == 'collision' or k == 'selfCollision'
    or k == 'nodeWeight' or  k == 'beamnDamp' or k == 'beamDeform' or k == 'beamSpring'
    or k == 'beamDamp' or k == 'cid' or k == 'globalSkin' or k == 'skinName' or k == 'beamStrength' then
      d[k] = nil
    elseif type(v) == 'table' then
      cleanCameraData(v)
    end
  end
end

local function addBeamByData(object, vehicle, beam)
  -- some defaults
  beam.beamStrength = beam.beamStrength or vehicle.options.beamStrength or math.huge
  beam.beamSpring = beam.beamSpring or vehicle.options.beamSpring
  beam.beamDamp = beam.beamDamp or vehicle.options.beamDamp
  beam.beamDeform = beam.beamDeform or vehicle.options.beamDeform
  beam.beamType = beam.beamType or NORMALTYPE

  -- error detection
  if type(beam.id1) == "string" or type(beam.id2) == "string" and tostring(beam.optional) == "true" then
    -- ignored error
    log_jbeam('W', "jbeam.pushToPhysics","- beam not committed as node was not found: " .. tostring(beam.id1) .. " -> " .. tostring(beam.id2) .. ' : ' .. dumps(beam))
    return nil
  end

  -- -1 as beam number appends it
  local node1pos = vehicle.nodes[beam.id1].pos
  local node2pos = vehicle.nodes[beam.id2].pos

  if node1pos.x == node2pos.x and node1pos.y == node2pos.y and node1pos.z == node2pos.z and
  beam.creator ~= "wheels" and tostring(beam.optional) ~= "true" then
    local msg = "zero size beam between nodes " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ', beam details are:\n'
    msg = msg .. dumps(beam)
    log_jbeam('W', "jbeam.pushToPhysics", msg)
  end

  if type(beam.precompressionRange) == 'number' then
    local bL = vec3(node1pos):distance(node2pos)
    beam.beamPrecompression = max(0, (bL + beam.precompressionRange) / (bL + 1e-30))
  end
  local beamPrecompression = beam.beamPrecompression or 1
  if type(beam.beamPrecompressionTime) == 'number' and beam.beamPrecompressionTime > 0 then
    if beam.beamPrecompression == 1 or beam.beamType == BEAM_LBEAM then
      beam.beamPrecompressionTime = nil
    else
      beamPrecompression = 1
    end
  end

  local deformLimit = type(beam.deformLimit) == 'number' and beam.deformLimit or math.huge
  local b = object:setBeam(-1, beam.id1, beam.id2, beam.beamStrength, beam.beamSpring,
    beam.beamDamp, type(beam.dampCutoffHz) == 'number' and beam.dampCutoffHz or 0,
    beam.beamDeform, deformLimit, type(beam.deformLimitExpansion) == 'number' and beam.deformLimitExpansion or deformLimit,
    beamPrecompression
  )

  if b:isValid() then
    if(beam.beamType == BEAM_ANISOTROPIC) then
      beam.springExpansion = beam.springExpansion or beam.beamSpring
      beam.dampExpansion = beam.dampExpansion or beam.beamDamp
      local longBound = type(beam.beamLongExtent) == 'number' and -max(0, beam.beamLongExtent) or max(0, beam.beamLongBound or math.huge)
      b:makeAnisotropic(beam.springExpansion, beam.dampExpansion,
        type(beam.transitionZone) == 'number' and beam.transitionZone or 0, longBound
      )
    elseif(beam.beamType == BEAM_BOUNDED) then
      local longBound = type(beam.longBoundRange) == 'number' and -max(0, beam.longBoundRange) or max(0, beam.beamLongBound or 1)
      local shortBound = type(beam.shortBoundRange) == 'number' and -max(0, beam.shortBoundRange) or max(0, beam.beamShortBound or 1)
      beam.beamLimitSpring = beam.beamLimitSpring or 1
      beam.beamLimitDamp = beam.beamLimitDamp or 1
      beam.beamLimitDampRebound = beam.beamLimitDampRebound or beam.beamLimitDamp
      beam.beamDampRebound = beam.beamDampRebound or beam.beamDamp
      beam.beamDampFast = beam.beamDampFast or beam.beamDamp
      beam.beamDampReboundFast = beam.beamDampReboundFast or beam.beamDampRebound
      beam.beamDampVelocitySplit = beam.beamDampVelocitySplit or math.huge

      b:makeBounded(longBound, shortBound, beam.beamLimitSpring, beam.beamLimitDamp, beam.beamLimitDampRebound,
        beam.beamDampRebound, beam.beamDampFast, beam.beamDampReboundFast, beam.beamDampVelocitySplit,
        type(beam.boundZone) == 'number' and beam.boundZone or 1
      )
    elseif(beam.beamType == BEAM_SUPPORT) then
      local longBound = type(beam.beamLongExtent) == 'number' and -max(0, beam.beamLongExtent) or max(0, beam.beamLongBound or 1)
      beam.springExpansion = 0
      beam.dampExpansion = 0
      b:makeAnisotropic(0, 0, 0, longBound)
    elseif(beam.beamType == BEAM_PRESSURED) then
      if beam.pressure == nil and beam.pressurePSI == nil then beam.pressurePSI = 30 end
      beam.pressure = beam.pressure or (beam.pressurePSI * 6894.757 + 101325) -- From PSI to Pa
      beam.pressurePSI = (beam.pressure - 101325) / 6894.757
      beam.surface = beam.surface or 1
      beam.volumeCoef = beam.volumeCoef or 1

      if beam.maxPressure == nil and beam.maxPressurePSI == nil then beam.maxPressure = math.huge end
      beam.maxPressure = beam.maxPressure or (beam.maxPressurePSI * 6894.757 + 101325)
      beam.maxPressurePSI = (beam.maxPressure - 101325) / 6894.757
      if beam.maxPressure < 0 then beam.maxPressure = math.huge end
      b:makePressured(beam.pressure, beam.surface, beam.volumeCoef, beam.maxPressure)
    elseif(beam.beamType == BEAM_LBEAM) then
      b:makeLbeam(beam.id3,
        type(beam.springExpansion) == 'number' and beam.springExpansion or beam.beamSpring,
        type(beam.dampExpansion) == 'number' and beam.dampExpansion or beam.beamDamp
      )
    end

    if beam.deformationTriggerRatio ~= nil and beam.deformationTriggerRatio ~= "" then
      b:setDeformationTriggerRatio(tonumber(beam.deformationTriggerRatio))
    end
    return b
  end
  return nil
end

--[[doxygen
pushToPhysics  push lua data to c/c++
@param object    object
@return nil or beam
table pushToPhysics(table object, number pos);
--]]
local function pushToPhysics(object)

  -- make sure we use the same directories for the dae files, etc
  if object.ibody then
    object.ibody:clearResourceSearchPath()
    for _, d in ipairs(M.directoriesloaded) do
      object.ibody:addResourceSearchPath(d)
    end
  end

  if M.vehicles == nil then
    return
  end

  for keyVehicle, vehicle in pairs (M.vehicles) do
    -- there is other metadata in there, so just look for tables and assume they are the vehicle data
    if type(vehicle) ~= 'table' then
      goto continue
    end

    log_jbeam('D', "jbeam.pushToPhysics"," ** pushing vehicle to physics: ".. keyVehicle)

    M.data = vehicle

    --dump(vehicle)

    local hp1 = HighPerfTimer()
    local hpo = HighPerfTimer()

    if(object == nil) then
      log_jbeam('W', "jbeam.pushToPhysics","*** Error getting Object")
      return
    end
    object:requestReset(RESET_PHYSICS)

    local addNodeByData = function(node)
      local ntype = NORMALTYPE
      if node.fixed == true then
        ntype = NODE_FIXED
      end

      local collision
      if node.collision ~= nil then
        collision = node.collision
      else
        collision = true
      end

      local selfCollision
      if node.selfCollision ~= nil then
        selfCollision = node.selfCollision
      else
        selfCollision = false
      end

      local staticCollision
      if node.staticCollision ~= nil then
        staticCollision = node.staticCollision
      else
        staticCollision = true
      end

      local frictionCoef = type(node.frictionCoef) == 'number' and node.frictionCoef or 1
      local slidingFrictionCoef = type(node.slidingFrictionCoef) == 'number' and node.slidingFrictionCoef or frictionCoef
      local noLoadCoef = type(node.noLoadCoef) == 'number' and node.noLoadCoef or 1
      local fullLoadCoef = type(node.fullLoadCoef) == 'number' and node.fullLoadCoef or 0
      local loadSensitivitySlope = type(node.loadSensitivitySlope) == 'number' and node.loadSensitivitySlope or 0

      local nodeWeight
      if type(node.nodeWeight) == 'number' then
        nodeWeight = node.nodeWeight
      else
        nodeWeight = vehicle.options.nodeWeight
        node.nodeWeight = nodeWeight
      end

      local nodeMaterialTypeID
      if node.nodeMaterial ~= nil then
        nodeMaterialTypeID = node.nodeMaterial
        if type(nodeMaterialTypeID) ~= "number" then
          log_jbeam('D', "jbeam.pushToPhysics","invalid node material id:"..tostring(nodeMaterialTypeID))
          nodeMaterialTypeID = vehicle.options.nodeMaterial or 0
        end
      else
        nodeMaterialTypeID = vehicle.options.nodeMaterial or 0
      end

      local id = object:setNode(-1, tableToFloat3(node.pos), nodeWeight, ntype, frictionCoef, slidingFrictionCoef, node.stribeckExponent or 1, node.stribeckVelMult or 1, noLoadCoef, fullLoadCoef, loadSensitivitySlope, node.softnessCoef or 0.5, node.treadCoef or 0.5, node.tag or '', node.couplerStrength or math.huge, node.firstGroup or -1, selfCollision, collision, staticCollision, nodeMaterialTypeID)
      if node.pairedNode then
        object:setNodePairWheelId(id, node.pairedNode, node.wheelID or -1)
      end
    end

    -- add nodes first
    if vehicle.nodes ~= nil then
      for k, node in pairs (vehicle.nodes) do
        addNodeByData(node)
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added " .. object.node_count .. " nodes")
    end
    table.insert(loadingTimes, {'2.1 nodes', hp1:stopAndReset()})

    -- then the beams
    if vehicle.beams ~= nil then
      local dedup = {}
      for i, beam in pairs(vehicle.beams) do
        if beam.breakGroup == '' then beam.breakGroup = nil end
        if beam.deformGroup == '' then beam.deformGroup = nil end
        local key
        if beam.beamSpring ~= 0 and beam.deformationTriggerRatio == nil then
          if beam.id1 > beam.id2 then
            key = beam.id1..'\0'..beam.id2
          else
            key = beam.id2..'\0'..beam.id1
          end
          local bType = beam.beamType or NORMALTYPE
          if type(bType) == "string" then bType = NORMALTYPE end
          key = key..'\0'..bType
          if dedup[key] ~= nil then
            local msg = "duplicated beam between nodes: "..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-')..', beam details are:\n'
            msg = msg .. "beam1=" .. dumps(dedup[key]) .. "\n"
            msg = msg .. "beam2=" .. dumps(beam)
            log_jbeam('W', "jbeam.pushToPhysics", msg)
          else
            dedup[key] = beam
          end
        end

        addBeamByData(object, vehicle, beam)
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added " .. object.beam_count .. " beams")
    end
    table.insert(loadingTimes, {'2.2 beams', hp1:stopAndReset()})

    -- wheels
    if vehicle.wheels ~= nil then
      local wheelsToRemove = {}
      for wheelKey, wheel in pairs(vehicle.wheels) do
        if wheel.nodes ~= nil and next(wheel.nodes) ~= nil then
          local torqueArm
          if type(wheel.torqueArm) == 'number' then
            torqueArm = wheel.torqueArm
          else
            if type(wheel.torqueArm) ~= 'nil' then
              log_jbeam('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' could not bind torqueArm for wheel')
            end
          end
          local nodeCouple = wheel.nodeCouple or wheel.nodeCoupling
          if type(nodeCouple) == 'string' then
            log_jbeam('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' nodeCouple needs a ":" at the end')
            nodeCouple = nil
          end
          local torqueCouple = wheel.torqueCouple or wheel.torqueCoupling
          if type(torqueCouple) == 'string' then
            log_jbeam('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' torqueCouple needs a ":" at the end')
            torqueCouple = nil
          end
          local w = object:setWheel(-1, wheel.node1, wheel.node2, wheel.nodeArm or -1,
            torqueArm or -1, torqueCouple or -1, type(wheel.torqueArm2) == 'number' and wheel.torqueArm2 or -1,
            math.max(wheel.brakeTorque or 0, wheel.parkingTorque or 0, 1) * (wheel.brakeSpring or 10))
          wheel.cid = w:getId()
          if w:isValid() and wheel.nodes then
            for k, v in pairs(wheel.nodes) do
              w:addNode(v)
            end
          end
        else
          table.insert(wheelsToRemove, wheelKey)
          log_jbeam('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name.." doesn't have any node bindings")
        end
      end
      for k, v in pairs(wheelsToRemove) do
        vehicle.wheels[v] = nil
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. object.wheel_count .." wheels")
    end
    table.insert(loadingTimes, {'2.3 wheels', hp1:stopAndReset()})

    -- rails
    if vehicle.rails ~= nil then
      local rail_count = 0
      local cids = {}
      for _, rail in pairs(vehicle.rails) do
        if rail["links:"] ~= nil then
          rail_count = rail_count + 1
          local looped = 0
          if rail.looped == 1 or rail.looped == true then
            looped = 1
          end
          if rail.capped == 0 then
            rail.capped = false
          end

          rail.cid = object:addRail(looped)
          cids[rail.cid] = rail

          -- add links
          local brokenmap = {}
          if rail["broken:"] ~= nil then
            for _, nid in pairs(rail["broken:"]) do
              brokenmap[nid] = 1
            end
          end

          local rLinks = rail["links:"]
          local linkSize = #rLinks
          if looped == 1 then rail.capped = false end

          -- guard for mistaken last == 1st link
          if looped == 1 and rLinks[1] == rLinks[linkSize] then
            table.remove(rLinks) -- remove last link
          end

          for i, nid in ipairs(rLinks) do
            local lcapped = 0
            if rail.capped and (i == 1 or i == linkSize) then lcapped = 1 end
            object:addRailLink(rail.cid, nid, lcapped, brokenmap[nid] or 0)
          end
        end
      end
      vehicle.rails.cids = cids
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. rail_count .." rails")
    end
    table.insert(loadingTimes, {'2.4 rails', hp1:stopAndReset()})

    -- slidenodes
    if vehicle.slidenodes ~= nil then
      local snode_count = 0
      for _, snode in pairs(vehicle.slidenodes) do
        snode_count = snode_count + 1
        local attached = 1
        if snode.attached == 0 or snode.attached == false then
          attached = 0
        end
        local fixtorail = 1
        if snode.fixToRail == 0 or snode.fixToRail == false then
          fixtorail = 0
        end
        local railId = -1
        if snode.railName ~= nil and vehicle.rails[snode.railName] ~= nil then
          railId = vehicle.rails[snode.railName].cid or -1
        end

        local spring = snode.spring or vehicle.options.beamSpring
        local strength = snode.strength or math.huge

        snode.cid = object:addSlidenode(
          snode.id,
          railId,
          attached,
          fixtorail,
          snode.tolerance or 0,
          spring,
          strength,
          snode.capStrength or strength
        )
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. snode_count .." slidenodes")
    end
    table.insert(loadingTimes, {'2.5 slidenodes', hp1:stopAndReset()})

    -- Add the torsionHydros
    if vehicle.torsionHydros ~= nil then
      vehicle.torsionbars = vehicle.torsionbars or {}
      local torsionHydroCount = 0

      for i, hydro in pairs(vehicle.torsionHydros) do
        table.insert(vehicle.torsionbars, hydro)
        hydro.inRate = hydro.inRate or 2
        hydro.outRate = hydro.outRate or hydro.inRate
        hydro.autoCenterRate = hydro.autoCenterRate or hydro.inRate
        hydro.inLimit = type(hydro.inExtent) == 'number' and hydro.inExtent or hydro.inLimit
        hydro.outLimit = type(hydro.outExtent) == 'number' and hydro.outExtent or hydro.outLimit
        hydro.inLimit = hydro.inLimit or -1
        hydro.outLimit = hydro.outLimit or 1
        hydro.inputSource = hydro.inputSource or "steering"
        hydro.inputCenter = hydro.inputCenter or 0
        hydro.inputInLimit = hydro.inputInLimit or -1
        hydro.inputOutLimit = hydro.inputOutLimit or 1
        hydro.inputFactor = hydro.inputFactor or 1

        if type(hydro.extentFactor) == 'number' then
          hydro.factor = hydro.extentFactor
        end

        if type(hydro.factor) == 'number' then
          hydro.inLimit = -math.abs(hydro.factor)
          hydro.outLimit = math.abs(hydro.factor)
          hydro.inputFactor = sign2(hydro.factor)
        end

        torsionHydroCount = torsionHydroCount + 1
      end
      log_jbeam('D', "jbeam.postProcess"," - added " .. torsionHydroCount .. " torsionHydros")
    end

    -- torsionbars
    if vehicle.torsionbars ~= nil then
      for _, tb in pairs(vehicle.torsionbars) do
        local spring = tb.spring
        local damp = type(tb.damp) == 'number' and tb.damp or 0
        local id1, id2, id3, id4 = tb.id1, tb.id2, tb.id3, tb.id4
        if type(id1) ~= 'number' then
          id1, spring, damp = 0, 0, 0
        end
        if type(id2) ~= 'number' then
          id2, spring, damp = 0, 0, 0
        end
        if type(id3) ~= 'number' then
          id3, spring, damp = 0, 0, 0
        end
        if type(id4) ~= 'number' then
          id4, spring, damp = 0, 0, 0
        end
        tb.cid = object:setTorsionbar(-1, id1, id2, id3, id4, spring, damp,
          type(tb.strength) == 'number' and tb.strength or math.huge,
          type(tb.deform) == 'number' and tb.deform or math.huge,
          type(tb.precompressionAngle) == 'number' and tb.precompressionAngle or 0)
      end
    end

    -- request the 3d meshes for faster processing on the c++ side
    local reuseMesh = false

    if object.ibody then
      table.insert(loadingTimes, {'2.5.1 torsionbars', hp1:stopAndReset()})
      object.ibody:requestMeshBegin()
      if vehicle.props ~= nil then
        for _, prop in pairs(vehicle.props) do
          if prop.mesh ~= "SPOTLIGHT" and prop.mesh ~= "POINTLIGHT" then
            object.ibody:requestMesh(prop.mesh)
          end
        end
      end
      if vehicle.flexbodies ~= nil then
        for _, flexbody in pairs(vehicle.flexbodies) do
          object.ibody:requestMesh(flexbody.mesh)
        end
      end
      reuseMesh = (object.ibody:requestMeshCommit() == 1)
      table.insert(loadingTimes, {'2.5.2 meshes', hp1:stopAndReset()})
    end

    local disableSteeringProp = settings.getValue("disableSteeringwheel")
    if disableSteeringProp == nil then disableSteeringProp = false end
    -- props
    if vehicle.props ~= nil and object.ibody then
      local prop_count = 0
      for propKey, prop in pairs(vehicle.props) do
        if disableSteeringProp and prop.func == 'steering' then
          log_jbeam('I', 'jbeam.pushToPhysics', 'removed steering wheel prop due to settings')
          goto continue
        end
        local pid = object.ibody:addProp(prop.mesh)
        if pid < 0 then
          log_jbeam('E', 'jbeam.pushToPhysics', 'unable to prop:'.. tostring(prop.mesh))
          goto continue
        end
        prop.pid = pid
        local p = object.ibody:getProp(pid)
        if p ~= nil then
          prop_count = prop_count + 1
          -- now clean up the input data
          prop.rotation        = tableToFloat3(prop.rotation):toRadians()
          prop.translation     = tableToFloat3(prop.translation)

          -- calculation of the base translation is optional
          if prop.baseTranslation ~= nil then
            prop.baseTranslation = tableToFloat3(prop.baseTranslation)
          end

          -- is this prop relative to the vehicle or to the local coordinate system
          if type(prop.referenceSystem) == 'string' then
            if prop.referenceSystem == 'local' then
              p:setType(PROP_PLACEMENT_LOCAL)
            elseif prop.referenceSystem == 'object' then
              p:setType(PROP_PLACEMENT_OBJECT)
            end
          end

          -- translate everything for testing:
          --if prop.translationOffset == nil then prop.translationOffset = {x=0, y=0, z=-2} end
          if prop.translationOffset ~= nil then
            prop.translationOffset = tableToFloat3(prop.translationOffset)
            if prop.translationOffset then
              p:setTranslationOffset(float3_2_Vector3(prop.translationOffset))
            end
          end

          if prop.baseRotation ~= nil then
            prop.baseRotation = tableToFloat3(prop.baseRotation):toRadians()
          end

          if prop.min == nil then prop.min = 0 end
          if prop.max == nil then prop.max = 100 end
          if prop.offset == nil then prop.offset = 0 end
          if prop.multiplier == nil then prop.multiplier = 1 end

          p:set(tonumber(prop.idRef), tonumber(prop.idX), tonumber(prop.idY))
          if prop.baseTranslation then
            p:setBaseTranslation(float3_2_Vector3(prop.baseTranslation))
          end
          if prop.baseRotation then
            p:setBaseRotation(float3_2_Vector3(prop.baseRotation))
          end
          p:update(float3_2_Vector3(prop.translation), float3_2_Vector3(prop.rotation), true, 0)

          --p:updateData(0)
          prop.slotID = pid
          if prop.mesh == "SPOTLIGHT" or prop.mesh == "POINTLIGHT" then
            local plight = p:getLight()
            if not plight then
              log_jbeam('E', 'jbeam.pushToPhysics', 'unable to create light for prop:'.. dumps(prop))
            else
              -- try to set the light options then
              local innerAngle = prop.lightInnerAngle or 40
              local outerAngle = prop.lightOuterAngle or 45
              local brightness = prop.lightBrightness or 1
              local range = prop.lightRange or 10
              local castShadows = prop.lightCastShadows or false
              local flareName = prop.flareName or 'vehicleDefaultLightflare'
              local flareScale = prop.flareScale or 1
              local cookieName = prop.cookieName or ''
              local animationType = prop.animationType or ''
              local animationPeriod = prop.animationPeriod or 1
              local animationPhase = prop.animationPhase or 1
              local texSize = prop.texSize or 256
              local shadowSoftness = prop.shadowSoftness or 1

              local color = color(1, 1, 1, 1)
              if prop.lightColor then color = parseColor(prop.lightColor) end

              local attenuation = float3(0, 1, 1)
              if prop.lightAttenuation then attenuation = tableToFloat3(prop.lightAttenuation) end
              plight:setLightArgs(innerAngle, outerAngle, brightness, range, color, float3_2_Vector3(attenuation), castShadows)
              plight:setLightArgs2(flareName, flareScale, cookieName, animationType, animationPeriod, animationPhase, texSize, shadowSoftness)
            end
          end
        end
        ::continue::
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. prop_count .." props")
    end
    table.insert(loadingTimes, {'2.6 props', hp1:stopAndReset()})

    vehicle.pressureGroups = {}
    local pressureGroupCount = 0

    if vehicle.triangles ~= nil then
      local n = vehicle.nodes
      for triangleKey, triangle in pairs(vehicle.triangles) do
        if triangle.breakGroup == '' then triangle.breakGroup = nil end
        if triangle.triangleType ~= nil and type(triangle.triangleType) == 'string' then
          triangle.triangleType = triTypeMap[triangle.triangleType]
        end
        triangle.triangleType = triangle.triangleType or NORMALTYPE

        local pressureGroup = -1
        local pressure = -1
        if triangle.pressureGroup ~= nil and triangle.pressureGroup ~= '' then
          if vehicle.pressureGroups[triangle.pressureGroup] ~= nil then
            pressureGroup = vehicle.pressureGroups[triangle.pressureGroup]
          else
            vehicle.pressureGroups[triangle.pressureGroup] = pressureGroupCount
            pressureGroup = pressureGroupCount
            pressureGroupCount = pressureGroupCount + 1
          end

          if triangle.pressure ~= nil or triangle.pressurePSI ~= nil then
            triangle.pressure = math.max(triangle.pressure or PSItoPascal(triangle.pressurePSI), 0) -- From PSI to Pa
            triangle.pressurePSI = (triangle.pressure - 101325) / 6894.757
            pressure = triangle.pressure
          end
        end

        local dragCoef = triangle.dragCoef or 100
        local liftCoef = triangle.liftCoef or dragCoef
        if triangle.id1 == triangle.id2 or triangle.id1 == triangle.id3 or triangle.id2 == triangle.id3 then
          local t1, t2, t3 = n[triangle.id1].name, n[triangle.id2].name, n[triangle.id3].name
          log_jbeam('E', "jbeam.pushToPhysics","Found degenerate collision triangle with nodes: "..t1..', '..t2..', '..t3)
        end
        object:setTriangle(-1, triangle.id1, triangle.id2, triangle.id3, dragCoef/100, liftCoef/100,
          type(triangle.stallAngle) == 'number' and triangle.stallAngle or 0.58, pressure, pressureGroup, triangle.triangleType,
          triangle.groundModel or "asphalt")
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. object:getTriangleCount() .." total triangles")
    end
    table.insert(loadingTimes, {'2.7 triangles', hp1:stopAndReset()})

    -- flexbodies (must be the last thing)
    local flexmesh_count = 0
    if vehicle.flexbodies ~= nil and object.ibody then
      for flexKey, flexbody in pairs(vehicle.flexbodies) do
        local flexnodeCount = #flexbody['_group_nodes']
        if flexnodeCount > 0 then
          local fid = object.ibody:addFlexmesh(flexbody.mesh)
          if fid < 0 then
            log_jbeam('E', "jbeam.pushToPhysics","unable to create flexmesh: " .. tostring(flexbody.mesh))
            goto continue
          end
          flexbody.fid = fid
          local f = object.ibody:getFlexmesh(fid)
          if f ~= nil then
            flexmesh_count = flexmesh_count + 1
            local flexnodes = flexbody['_group_nodes']
            for k = 1, flexnodeCount do
              f:addNodeBinding(flexnodes[k])
            end
            if flexbody.pos ~= nil or flexbody.rot ~= nil or flexbody.scale ~= nil then
              local pos = tableToFloat3(flexbody.pos) or float3(0,0,0)
              local rot = tableToFloat3(flexbody.rot) or float3(0,0,0)
              local scale = tableToFloat3Default(flexbody.scale, float3(1,1,1))
              --log_jbeam('D', "jbeam.pushToPhysics","setInitialTransformation: " .. flexbody.mesh .. " = " .. tostring(pos) .. ", ".. tostring(rot) .. ", " .. tostring(scale))
              f:setInitialTransformation(float3_2_Vector3(pos), float3_2_Vector3(rot:toRadians()), float3_2_Vector3(scale))
            end
            --f:initialize()
          else
            log_jbeam('E', "jbeam.pushToPhysics", "unable to create flexmesh: " .. flexbody.mesh)
          end
        else
          log_jbeam('D', "jbeam.pushToPhysics", "flexmesh has no node bindings, ignoring: " .. flexbody.mesh)
        end
        ::continue::
      end
      log_jbeam('D', "jbeam.pushToPhysics","- added ".. flexmesh_count .." flexMeshes")
    end
    table.insert(loadingTimes, {'2.8 flexmeshes', hp1:stopAndReset()})

    if vehicle.refNodes == nil then
      vehicle.refNodes = {}
    end

    -- set cameras
    if vehicle.refNodes[0] ~= nil then
      object:setReferenceNodes(
        vehicle.refNodes[0].ref
        , vehicle.refNodes[0].back
        , vehicle.refNodes[0].left
        , vehicle.refNodes[0].up
        , vehicle.refNodes[0].leftCorner or vehicle.refNodes[0].ref
        , vehicle.refNodes[0].rightCorner or vehicle.refNodes[0].ref
      )
    else
      log_jbeam('E', "jbeam.pushToPhysics", "Reference nodes missing. Please add them")
    end

    if vehicle.refNodes[0] == nil then
      vehicle.refNodes[0] = {ref = 0, back = 1, left = 2, up = 0}
    end

    -- Onboard cameras
    if vehicle.cameras.onboard ~= nil then
      local counter = 1
      local foundCameras = {}
      for k, v in pairs (vehicle.cameras.onboard) do
        -- automatic numeric naming
        if v.name == nil or type(v.name) ~= 'string' then
          v.name = 'onboard_' .. tostring(counter)
          v.order = v.order or counter + 20
          counter = counter + 1
        end
        if v.fov == nil then v.fov = 75 end

        -- check for duplicates:
        if foundCameras[v.name] then
          log_jbeam('E', "jbeam.pushToPhysics", "Ignoring onboard camera with duplicate name: " .. tostring(v.name))
        end
        foundCameras[v.name] = 1
      end
      --log("I", "", "Found cameras: "..dumps(vehicle.cameras.onboard))
    end

    -- compile camera data
    local cameraData = { common = { refNodes = deepcopy(vehicle.refNodes[0]) } }
    for k,v in pairs(vehicle.cameras) do
      v = deepcopy(v) or {}
      -- shift ipair() iterable indices, from 0..N-1  to  1..N
      if v[0] ~= nil then
        table.insert(v, 1, v[0])
        v[0] = nil
      end
      cameraData[k] = v
    end

    cleanCameraData(cameraData)
    setCameraConfig(cameraData)
    table.insert(loadingTimes, {'2.9 camera', hp1:stopAndReset()})

    -- end
    object:finishLoading()
    log_jbeam('D', "jbeam.pushToPhysics","object creation took "..hpo:stop().." ms")
    table.insert(loadingTimes, {'2.10 finish hook', hp1:stopAndReset()})

    -- find active parts
    local activeParts = {}
    local partArrayStack = {}
    for slotName0, partArray0 in pairs(M.slotMap) do
      table.insert(partArrayStack, partArray0)
    end

    while #partArrayStack > 0 do
      local array = partArrayStack[#partArrayStack]
      table.remove(partArrayStack, #partArrayStack)
      for i, data in ipairs(array) do
        if data and data.parts then
          for _, partArray in pairs(data.parts) do
            table.insert(partArrayStack, partArray)
          end
        end

        if data and data.active then
          table.insert(activeParts, data)
        end
      end
    end
    partArrayStack = nil

    -- set license plate
    local useLicensePlate = false
    local licenseplatePath = ''

    -- process active parts
    for i, data in ipairs(activeParts) do
      if data.partType and not useLicensePlate and data.partType:find('_licenseplate') then
        useLicensePlate = true
      end
      -- license plates setup
      if data.partType and data.partType:find('licenseplate_design') then
        for i, v in ipairs(M.partMap[data.partType]) do
          if v.partName == data.partName and v.licenseplate_path then
            licenseplatePath = v.licenseplate_path
          end
        end
      end

      -- skin setup
      if object.ibody and data.partType and (data.partType:find('skin_') or data.partType == 'paint_design') then
        for i, v in ipairs(M.partMap[data.partType]) do
          if v.partName == data.partName then
            local skinSlot = v.slotType
            if skinSlot == 'paint_design' then skinSlot = '' end
            object.ibody:setSkin( skinSlot..'.'..(v.skinName or v.globalSkin) )
            if v.default_color ~= nil then
              obj:queueGameEngineLua("core_vehicles.setVehicleColorsNames( "..obj:getID()..", "..dumps( {v.default_color,v.default_color_2,v.default_color_3} ).. ")")
            end
          end
        end
      end
    end

    if useLicensePlate then
      obj:queueGameEngineLua("core_vehicles.setPlateText( false, "..obj:getID()..",'"..licenseplatePath.. "')")
    end
    table.insert(loadingTimes, {'2.11 skin', hp1:stopAndReset()})

    if object.ibody then
      -- all meshes are done, tell that to the other side...
      object.ibody:meshCommit()
    end
    table.insert(loadingTimes, {'2.12 meshCommit', hp1:stopAndReset()})

    ::continue::
  end
  ::endspawn::
end

--[[doxygen
this is the plain include merge approach
@param target    target
@param source    source
@param level    level
@return nil
void unifyParts(table target, table source, number level);
--]]
local function unifyParts(target, source, level, slotOptions)
  --log_jbeam('D', "jbeam.unifyParts",string.rep(" ", level).."* merging part "..source.partName.." ["..source.slotType.."] => "..target.partName.." ["..target.slotType.."] ... ")
  -- walk and merge all sections
  for sectionKey,section in pairs(source) do
    if sectionKey == 'slots' then
      goto continue
    end

    --log_jbeam('D', "jbeam.unifyParts"," *** "..tostring(sectionKey).." = "..tostring(section).." ["..type(section).."] -> "..tostring(sectionKey).." = "..tostring(target[sectionKey]).." ["..type(target[sectionKey]).."]")
    if target[sectionKey] == nil then
      -- easy merge
      target[sectionKey] = section

      -- care about the slotoptions if we are first
      local localSlotOptions = nil
      if type(section) == "table" and not tableIsDict(section) then
        local counter = 0
        localSlotOptions = deepcopy(slotOptions) or {}
        localSlotOptions.partOrigin = source.partName
        --localSlotOptions.partLevel = level
        table.insert(target[sectionKey], 2, localSlotOptions)
      end
      if localSlotOptions then
        -- now we need to negate the slotoptions out again
        local slotOptionReset = {}
        for k4,v4 in pairs(localSlotOptions) do
          slotOptionReset[k4] = ""
        end
        table.insert(target[sectionKey], slotOptionReset)
      end
    elseif type(target[sectionKey]) == "table" and type(section) == "table" then
      -- append to existing tables
      -- add info where this came from
      local counter = 0
      local localSlotOptions = nil
      for k3,v3 in pairs(section) do
        if tonumber(k3) ~= nil then
          -- if its an index, append if index > 1
          if counter > 0 then
            table.insert(target[sectionKey], v3)
          else
            localSlotOptions = deepcopy(slotOptions) or {}
            localSlotOptions.partOrigin = source.partName
            --localSlotOptions.partLevel = level
            --localSlotOptions.partOrigin = sectionKey .. '/' .. source.partName
            table.insert(target[sectionKey], localSlotOptions)
          end
        else
          -- its a key value table, overwrite
          target[sectionKey][k3] = v3
        end
        counter = counter + 1
      end
      if localSlotOptions then
        -- now we need to negate the slotoptions out again
        local slotOptionReset = {}
        for k4,v4 in pairs(localSlotOptions) do
          slotOptionReset[k4] = ""
        end
        table.insert(target[sectionKey], slotOptionReset)
      end

    else
      -- just overwrite any basic data
      if sectionKey ~= "slotType" and sectionKey ~= "partName" then
        target[sectionKey] = section
      end
    end
    ::continue::
  end
end

--[[
LUA 5.1 compatible

Ordered Table
keys added will be also be stored in a metatable to recall the insertion oder
metakeys can be seen with for i,k in ( <this>:ipairs()  or ipairs( <this>._korder ) ) do
ipairs( ) is a bit faster

variable names inside __index shouldn't be added, if so you must delete these again to access the metavariable
or change the metavariable names, except for the 'del' command. thats the reason why one cannot change its value
]]--
local function newT( t )
  local mt = {}
  -- set methods
  mt.__index = {
    -- set key order table inside __index for faster lookup
    _korder = {},
    -- traversal of hidden values
    hidden = function() return pairs( mt.__index ) end,
    -- traversal of table ordered: returning index, key
    ipairs = function( self ) return ipairs( self._korder ) end,
    -- traversal of table
    pairs = function( self ) return pairs( self ) end,
    -- traversal of table ordered: returning key,value
    opairs = function( self )
      local i = 0
      local function iter( self )
        i = i + 1
        local k = self._korder[i]
        if k then
          return k,self[k]
        end
      end
      return iter,self
    end,
    -- to be able to delete entries we must write a delete function
    del = function( self,key )
      if self[key] then
        self[key] = nil
        for i,k in ipairs( self._korder ) do
          if k == key then
            table.remove( self._korder, i )
            return
          end
        end
      end
    end,
  }
  -- set new index handling
  mt.__newindex = function( self,k,v )
    if k ~= "del" and v then
      rawset( self,k,v )
      table.insert( self._korder, k )
    end
  end
  return setmetatable( t or {},mt )
end

--[[doxygen
fill slots
@param partMap  partMap
@param part    part
@param level   level
@return void
void fillSlots(table partMap, table part, string level);
--]]
local function fillSlots(partMap, part, level, _slotOptions)
  if level > 50 then
    log_jbeam('E', "jbeam.fillSlots","* ERROR: over 50 levels of parts, check if parts are self referential")
    return
  end
  local slotMap = newT()
  local childParts = {}
  local childPartsidx = 1
  if part.slots ~= nil then
    --log_jbeam('D', "jbeam.fillSlots",string.rep(" ", level).."* found "..(#part.slots-1).." slot(s):")
    for k,v in pairs(part.slots) do
      local partType  = v[1]
      local partValue = v[2]
      local slotDescription = partType
      local slotOptions = nil
      -- the options are only valid for this hierarchy.
      -- if we do not clone/deepcopy it, the childs will leak options to the parents
      if _slotOptions == nil then
        slotOptions = {}
      else
        slotOptions = deepcopy(_slotOptions)
      end
      if #v > 2 and type(v[3]) == 'string' then
        slotDescription = v[3]
      end
      if #v > 3 and type(v[4]) == 'table' then
        slotOptions = tableMerge(slotOptions, v[4])
      end

      if partType == "type" then
        -- ignore header
        goto continue
      end

      --log_jbeam('D', "jbeam.fillSlots",string.rep(" ", level+1).."* found slot type "..partType)

      -- next, find all parts that match this type
      if partMap[partType] ~= nil then
        -- choose the part
        slotMap[partType] = {}
        M.slotDescriptions[partType] = slotDescription
        for k2,v2 in pairs(partMap[partType]) do

          -- is the part active / currently used?
          local useThis = false
          if M.userPartConfig[partType] then
            useThis = (v2.partName == M.userPartConfig[partType])
          else
            useThis = (v2.partName == partValue)
          end

          local tmp = {
            partType = partType,
            partName = v2.partName,
            name     = v2.information.name or "",
            authors  = v2.information.authors or "",
            active   = useThis,
            level    = level + 2,
          }
          if slotOptions.coreSlot and type(slotOptions.coreSlot) == 'boolean' and slotOptions.coreSlot == true then
            tmp.coreSlot = true
            slotOptions.coreSlot = nil
          end
          if useThis then
            -- yay, part found, merge now
            -- _childParts: the child parts of one of the parts
            local childSlotMap, _childParts = fillSlots(partMap, v2, tmp.level, slotOptions)

            if not tableIsEmpty(childSlotMap) then
              tmp['parts'] = childSlotMap
            end
            -- childParts: the childparts of the currently looked at slot
            childParts[childPartsidx] = tmp.partName
            childPartsidx = childPartsidx + 1

            if _childParts then
              for _, vv in pairs(_childParts) do
                childParts[childPartsidx] = vv
                childPartsidx = childPartsidx + 1
              end
            end

            -- TODO: add virtual parts
            unifyParts(part, v2, tmp.level, slotOptions)
            slotOptions.childParts = deepcopy(_childParts or {}) -- this is after unifyparts to not leak childparts into all things below
          end
          table.insert(slotMap[partType], tmp)
        end
      else
        --log_jbeam('W', "jbeam.fillSlots","no suitable part found for type: "..tostring(partType))
      end
      ::continue::
    end
  else
    --log_jbeam('D', "jbeam.fillSlots",string.rep(" ", level+1).."* no slots")
  end

  return slotMap, childPartsidx >1 and childParts or nil
end

--[[doxygen
scale values recursively
@param data  data to be scaled
@return c scaled values
table scaleValuesRecursive(table data);
--]]
local function scaleValuesRecursive(data)
  for key, v in pairs(data) do
    local typev = type(v)
    if typev == 'number' then
      if str_byte(key,1)==115 and str_byte(key,2)==99 and str_byte(key,3)==97 and str_byte(key,4)==108 and str_byte(key,5)==101 --scale
      and str_byte(key,6)~=nil then
        -- look for scaled key
        local keytoscale = str_sub(key, 6)
        if type(data[keytoscale]) == "number" then
          data[keytoscale] = data[keytoscale] * v
        end
        data[key] = nil
      end
    elseif typev == 'table' then
      scaleValuesRecursive(v)
    end
  end
end

local function applyVariables(data, vars)
  local stackidx = 2
  local stack = {data}
  while stackidx > 1 do
    stackidx = stackidx - 1
    local d = stack[stackidx]
    for key, v in pairs(d) do
      local typev = type(v)
      if typev == "string" then
        if str_byte(v,1) == 36 then -- $
          if str_byte(v,2) == 61 then -- =
            if not expressionParser then
              expressionParser = require("expressionParser")
              M.jbeamVariableEnv = expressionParser.buildEnvJbeamVariables(vars, M.userVars)
            end
            d[key] = expressionParser.parse(v, M.jbeamVariableEnv)
            --log_jbeam('D', "jbeam.applyVariables", "set variable "..tostring(key).." to ".. tostring(data[key]))
          else
            if vars[v] == nil then
              log_jbeam('E', "jbeam.applyVariables", "missing variable "..tostring(v))
              d[key] = nil
            else
              d[key] = vars[v].val
            end
            --log_jbeam('D', "jbeam.applyVariables", "set variable "..tostring(key).." to ".. tostring(data[key]))
          end
        end
      elseif typev == 'table' and key ~= 'variables' then
        -- ignore the variables table
        stack[stackidx] = v
        stackidx = stackidx + 1
      end
    end
  end
end

local function processWheel(vehicle, wheelSection, wheelCreationFunction)
  if vehicle[wheelSection] ~= nil then
    for k, v in pairs (vehicle[wheelSection]) do
      --log_jbeam('D', "jbeam.processWheel"," * "..tostring(k).." = "..tostring(v).." ["..type(v).."]")
      if v.numRays == nil or v.numRays > 0 then
        local wheelID = increaseMax(vehicle, 'wheels')
        v.wheelID = wheelID
        wheelCreationFunction(vehicle, k, v)
        vehicle.wheels[wheelID] = v
      end
    end
  end
  if not tableIsEmpty(vehicle[wheelSection]) then
    log_jbeam('D', "jbeam.processWheel"," - processed "..tableSize(vehicle[wheelSection]).." of "..wheelSection.."(s)")
  end
end

--[[doxygen
post process vehicles
@param vehicles  a table type for vehiclespost processing done
@return true
Boolean postProcess(table vehicles);
--]]
local function postProcess(vehicles)
  --log_jbeam('D', "jbeam.postProcess","- post processing ...")

  for keyVehicle, vehicle in pairs (vehicles) do
    -- variables
    if vehicle.variables then
      M.variables = {}

      for kv,vv in pairs(vehicle.variables) do
        if vv.type == 'range' then
          if vv.unit == '' then vv.unit = nil end
          if type(vv.min) ~= 'number' then
            log_jbeam('E', 'postProcess.variables', 'variable ' .. vv.name .. ' ignored, min not a number')
            dump(vv)
            goto continue
          end
          if type(vv.max) ~= 'number' then
            log_jbeam('E', 'postProcess.variables', 'variable ' .. vv.name .. ' ignored, max not a number')
            dump(vv)
            goto continue
          end
          if type(vv.default) ~= 'number' then
            log_jbeam('E', 'postProcess.variables', 'variable ' .. vv.name .. ' ignored, default not a number')
            dump(vv)
            goto continue
          end
          -- choose the default or the user set value
          if M.userVars[vv.name] ~= nil then
            vv.val = M.userVars[vv.name]
          else
            vv.val = vv.default
          end
          -- set defaults for variables
          if not vv.minDis then
            if vv.unit then
              vv.minDis = vv.min
            else
              vv.minDis = -100
            end
          end
          if not vv.maxDis then
            if vv.unit then
              vv.maxDis = vv.max
            else
              vv.maxDis = 100
            end
          end
          if not vv.stepDis then
            if vv.unit then
              vv.stepDis = (vv.max - vv.min) / 100
            else
              vv.stepDis = 1
            end
          end
          if vv.unit == nil or vv.unit == '' then
            vv.unit = '%'
          end
          if vv.category == nil or vv.category == '' then
            vv.category = 'alignment'
          end

          if string.match(vv.category, "(.*)%.(.*)") then
            vv.category, vv.subCategory = string.match(vv.category, "(.*)%.(.*)")
          end

          --Make sure our value is actually inside the min/max limits
          --we can't be sure that "min" is actually the smaller number and "max" the bigger one, so for clamping we need to find out which is which first
          vv.val = clamp(vv.val, min(vv.min, vv.max), max(vv.min, vv.max))

          M.variables[vv.name] = vv
        else
          log_jbeam('E', 'postProcess.variables', 'variable ' .. vv.name .. ' ignored, unknown type: ' .. tostring(vv.type))
        end
      end
      --print('known variables:')
      --dump(M.variables)
      if type(vehicle) == 'table' then
        applyVariables(vehicle, M.variables)
      end
      ::continue::
    end

    for k, v in pairs(vehicle.nodes) do
      if v.nodeOffset and type(v.nodeOffset) == 'table' and v.nodeOffset.x and v.nodeOffset.y and v.nodeOffset.z then
        v.posX = v.posX + fsign(v.posX) * v.nodeOffset.x
        v.posY = v.posY + v.nodeOffset.y
        v.posZ = v.posZ + v.nodeOffset.z
      end
      if v.nodeMove and type(v.nodeMove) == 'table' and v.nodeMove.x and v.nodeMove.y and v.nodeMove.z then
        v.posX = v.posX + v.nodeMove.x
        v.posY = v.posY + v.nodeMove.y
        v.posZ = v.posZ + v.nodeMove.z
      end
      --vehicle.nodes[k]['pos'] = float3(v.posX, v.posY, v.posZ)
      vehicle.nodes[k]['pos'] = {x = v.posX, y = v.posY, z = v.posZ}

      -- TODO: REMOVE AGAIN
      v.posX=nil
      v.posY=nil
      v.posZ=nil
    end

    if vehicle.flexbodies ~= nil then
      for _, v in pairs(vehicle.flexbodies) do
        if v.nodeOffset and type(v.nodeOffset) == 'table' and v.nodeOffset.x and v.nodeOffset.y and v.nodeOffset.z then
          v.pos = v.pos or {x = 0, y = 0, z = 0}
          local nodeOffsetCoef = v.ignoreNodeOffset and 0 or 1
          v.pos.x = v.pos.x + fsign(v.pos.x) * v.nodeOffset.x * nodeOffsetCoef
          v.pos.y = v.pos.y + v.nodeOffset.y * nodeOffsetCoef
          v.pos.z = v.pos.z + v.nodeOffset.z * nodeOffsetCoef
        end
        if v.nodeMove and type(v.nodeMove) == 'table' and v.nodeMove.x and v.nodeMove.y and v.nodeMove.z then
          v.pos = v.pos or {x = 0, y = 0, z = 0}
          v.pos.x = v.pos.x + v.nodeMove.x
          v.pos.y = v.pos.y + v.nodeMove.y
          v.pos.z = v.pos.z + v.nodeMove.z
        end
      end
    end

    -- Process wheels section
    if vehicle.wheels ~= nil  then
      local tmpwheels = vehicle.wheels
      vehicle.wheels = {}
      vehicle.maxIDs.wheels = nil
    end

    if vehicle.wheels == nil then vehicle.wheels = {} end

    processWheel(vehicle, "wheels", addWheel)

    processWheel(vehicle, "monoHubWheels", addMonoHubWheel)
    processWheel(vehicle, "hubWheelsTSV", addHubWheelTSV)
    processWheel(vehicle, "hubWheelsTSI", addHubWheelTSI)
    processWheel(vehicle, "hubWheels", addHubWheel)
    processWheel(vehicle, "pressureWheels", addPressureWheel)

    -- Add the hydros to beams section
    local hydroCount = 0
    if vehicle.hydros ~= nil then
      for i, hydro in pairs(vehicle.hydros) do
        hydro.beamType = BEAM_HYDRO
        hydro.beam = addBeamWithOptions(vehicle, 'hydros', nil, nil, BEAM_HYDRO, hydro)
        local bL = vec3(vehicle.nodes[hydro.id1].pos):distance(vehicle.nodes[hydro.id2].pos)

        hydro.inRate = hydro.inRate or 2
        hydro.outRate = hydro.outRate or hydro.inRate
        hydro.autoCenterRate = hydro.autoCenterRate or hydro.inRate

        if type(hydro.inExtent) == 'number' then
          hydro.inLimit = hydro.inExtent / (bL + 1e-30)
        end

        if type(hydro.outExtent) == 'number' then
          hydro.outLimit = hydro.outExtent / (bL + 1e-30)
        end

        hydro.inLimit = hydro.inLimit or 0
        hydro.outLimit = hydro.outLimit or 2
        hydro.inputSource = hydro.inputSource or "steering"
        hydro.inputCenter = hydro.inputCenter or 0
        hydro.inputInLimit = hydro.inputInLimit or -1
        hydro.inputOutLimit = hydro.inputOutLimit or 1
        hydro.inputFactor = hydro.inputFactor or 1

        if type(hydro.extentFactor) == 'number' then
          hydro.factor = hydro.extentFactor / (bL + 1e-30)
        end

        if type(hydro.factor) == 'number' then
          hydro.inLimit = 1 - math.abs(hydro.factor)
          hydro.outLimit = 1 + math.abs(hydro.factor)
          hydro.inputFactor = sign2(hydro.factor)
        end
        hydro.analogue = false

        hydroCount = hydroCount + 1
      end
      log_jbeam('D', "jbeam.postProcess"," - added " .. hydroCount .. " hydros")
    end

    -- commands
    local commandsCount = 0
    if vehicle.commands ~= nil then
      for i, command in pairs (vehicle.commands) do
        command.beamType = BEAM_HYDRO
        command.type = command.type or "toggle"
        command.beam = addBeamWithOptions(vehicle, 'commands', nil, nil, BEAM_HYDRO, command)
        command.inRate = command.inRate or 2
        command.outRate = command.outRate or command.inRate
        command.autoCenterRate = command.autoCenterRate or command.inRate
        command.inLimit = command.inLimit or 0
        command.outLimit = command.outLimit or 2
        command.inputSource = command.inputSource or "steering"
        command.inputCenter = command.inputCenter or 0.5
        command.inputInLimit = command.inputInLimit or 0
        command.inputOutLimit = command.inputOutLimit or 1
        command.inputFactor = command.inputFactor or 1
        if command.factor ~= nil then
          command.inLimit = 1 - math.abs(command.factor)
          command.outLimit = 1 + math.abs(command.factor)
          command.inputFactor = sign(command.factor)
        end
        commandsCount = commandsCount + 1
      end
      log_jbeam('D', "jbeam.postProcess"," - added " .. commandsCount .. " commands")
    end

    -- rope
    local ropeCount = 0
    if vehicle.ropes ~= nil then
      for i, rope in pairs (vehicle.ropes) do
        rope.segments = rope.segments or 1
        if rope.segments < 1 then rope.segments = 1 end
        rope.length = rope.length or 1
        rope.nodeWeight = rope.nodeWeight or 5
        rope.springExpansion = rope.springExpansion or rope.beamSpring
        rope.dampExpansion = rope.dampExpansion or rope.beamDamp
        rope.beamLongBound = rope.beamLongBound or math.huge

        -- figure out where the rope is going
        local startPos = vec3(vehicle.nodes[rope.id1].pos)
        local endPos = startPos + vec3(rope.length, 0, 0)
        if rope.id2 then
          endPos = vec3(vehicle.nodes[rope.id2].pos)
          rope.length = (endPos - startPos):length()
        end
        local vecDiff = (endPos - startPos) / rope.segments
        local nPos = vec3(startPos)

        local lastNodeId = rope.id1
        rope.nodes = nil
        rope.beams = nil
        local ropenodes = {}
        local ropebeams = {}
        local ropecopy = deepcopy(rope)
        ropecopy.length = nil
        ropecopy.id2 = nil
        ropecopy.segments = nil

        -- create the segments
        for si = 1, rope.segments do
          nPos = nPos + vecDiff
          -- if the last step, connect to target node?
          local nid2
          if si == rope.segments and rope.id2 then
            -- last node (id2)
            nid2 = rope.id2
          else
            -- insert new node
            nid2 = addNodeWithOptions(vehicle, 'ropes', nPos:toDict(), NORMALTYPE, ropecopy)
          end
          table.insert(ropenodes, nid2)
          table.insert(ropebeams, addBeamWithOptions(vehicle, 'ropes', lastNodeId, nid2, BEAM_ANISOTROPIC, ropecopy))
          lastNodeId = nid2
        end
        rope.nodes = ropenodes
        rope.beams = ropebeams
        ropeCount = ropeCount + 1
      end
      log_jbeam('D', "jbeam.postProcess"," - added " .. ropeCount .. " ropes")
    end

    -- Process group links
    if not resolveGroupLinks(vehicle) then
      log_jbeam('W', "jbeam.postProcess","*** group link resolving error")
      return nil
    end

    -- post process engine differential
    if vehicle.engine ~= nil then
      --TODO
      vehicle.engine.waterDamage = vehicle.engine.waterDamage or {}
      vehicle.engine.waterDamage.nodes = {}
      arrayConcat(vehicle.engine.waterDamage.nodes, vehicle.engine.waterDamage._group_nodes or {})
      arrayConcat(vehicle.engine.waterDamage.nodes, vehicle.engine.waterDamage._engineGroup_nodes or {})
    end

    -- Process rotators
    local wheelSection = "rotators"
    if vehicle[wheelSection] ~= nil then
      for k, v in pairs (vehicle[wheelSection]) do
        --log_jbeam('D', "jbeam.postProcess"," * "..tostring(k).." = "..tostring(v).." ["..type(v).."]")
        local wheelID = increaseMax(vehicle, 'wheels')
        v.wheelID = wheelID
        addRotator(vehicle, k, v)
        vehicle.wheels[wheelID] = v
      end
    end
    if not tableIsEmpty(vehicle[wheelSection]) then
      log_jbeam('D', "jbeam.postProcess"," - processed "..tableSize(vehicle[wheelSection]).." of "..wheelSection.."(s)")
    end

    -- Camera retrocompatibility conversions:
    local function upgradeCamera(vehicle, oldName, newName)
      if vehicle[oldName] ~= nil then
        if vehicle.cameras[newName] then
          --log("E", "", "Overwriting existing vehicle.cameras."..newName.." with old deprecated vehicle."..oldName.." field")
        end
        if oldName == "camerasInternal" or oldName == "camerasRelative" then
          local driverCameraSet = false -- only set 'driver' once
          for k, v in pairs (vehicle[oldName]) do
            -- rename variable "type" to "name"
            if v.type ~= nil then
              --log("W", "", "Renaming deprecated 'type' camera field to 'name': vehicle."..oldName.."::"..dumps(v.type))
              v.name = v.type
              v.type = nil
            end
            -- backward compatibility for old cockpitCamera flag
            if oldName == "camerasInternal" and v.cockpitCamera == true and v.name == nil and not driverCameraSet then
              --log("W", "", "Renaming deprecated 'cockpitCamera' flag to 'driver'")
              v.name = 'driver'
              driverCameraSet = true
            end
            -- backward compatibility for old 'dash' name
            if v.name == "dash" then
              --log("W", "", "Renaming deprecated 'dash' onboard camera to 'driver'")
              v.name = "driver"
            end
            if v.name == "driver" then
              v.rightHandCamera = v.rightHandCamera or false -- replace missing field with actual, explicit value
            end
          end
        end
        vehicle.cameras[newName] = vehicle[oldName]
        vehicle[oldName] = nil
        --log("W", "", "Upgraded old deprecated vehicle."..oldName.." to new vehicle.cameras."..newName.." field")
      end
    end
    if not vehicle.cameras then vehicle.cameras = {} end
    upgradeCamera(vehicle, "camerasInternal", "onboard")
    upgradeCamera(vehicle, "cameraExternal",  "orbit")
    upgradeCamera(vehicle, "camerasRelative", "relative")
    upgradeCamera(vehicle, "cameraChase",     "chase")

    -- Process onboard cameras
    if vehicle.cameras ~= nil and vehicle.cameras.onboard ~= nil then
      for icKey, icam in pairs (vehicle.cameras.onboard) do
        local nPos = {x=icam.x, y=icam.y, z=icam.z}
        local camNodeID = addNodeWithOptions(vehicle, 'cameras.onboard', nPos, NORMALTYPE, icam)
        addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id1, NORMALTYPE, icam)
        addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id2, NORMALTYPE, icam)
        if icam.id3 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id3, NORMALTYPE, icam) end
        if icam.id4 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id4, NORMALTYPE, icam) end
        if icam.id5 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id5, NORMALTYPE, icam) end
        if icam.id6 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id6, NORMALTYPE, icam) end
        if icam.id7 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id7, NORMALTYPE, icam) end
        if icam.id8 ~= nil then addBeamWithOptions(vehicle, 'cameras.onboard', camNodeID, icam.id8, NORMALTYPE, icam) end

        -- record the camera node id that was created
        icam.camNodeID = camNodeID
      end
      log_jbeam('D', "jbeam.postProcess"," - processed "..tableSize(vehicle.cameras.onboard).." cameras.onboard")
    end

    -- emulation mode for camerasRelative
    if vehicle.cameras.relative == nil and vehicle.cameras.onboard then
      -- backward compatibility: import onboard cameras
      vehicle.cameras.relative = {}
      -- try to emulate one from deducing values from the onboard camera system
      for icKey, icam in pairs (vehicle.cameras.onboard) do
        local cr = {}
        local nPos = {x=icam.x, y=icam.y, z=icam.z}
        if vehicle.refNodes and vehicle.refNodes[0] and vehicle.refNodes[0].ref and vehicle.nodes[vehicle.refNodes[0].ref] then
          local refNode = vehicle.nodes[vehicle.refNodes[0].ref]
          cr.pos = nPos - vec3(refNode.pos) -- calculate out the refnode
          cr.pos.x = - cr.pos.x -- invert X and Y axis for some reason?!
          cr.pos.y = - cr.pos.y -- invert X and Y axis for some reason?!
        end
        cr.name = icam.name
        cr.fov = icam.fov
        cr.rot = vec3(0, 180, 0) -- look forward by default
        table.insert(vehicle.cameras.relative, cr)
      end
    elseif vehicle.cameras.relative ~= nil then

      if vehicle.refNodes and vehicle.refNodes[0] and vehicle.refNodes[0].ref and vehicle.nodes[vehicle.refNodes[0].ref] then
        local refNodePos = vec3(vehicle.nodes[vehicle.refNodes[0].ref].pos)

        -- convert position table to vec3
        for _, cr in pairs (vehicle.cameras.relative) do
          cr.pos = vec3(cr)
          cr.x = nil
          cr.y = nil
          cr.z = nil

          cr.pos = cr.pos - refNodePos -- calculate out the refnode
          cr.pos.x = - cr.pos.x -- invert X and Y axis for some reason?!
          cr.pos.y = - cr.pos.y -- invert X and Y axis for some reason?!

          -- some default values
          if cr.rot == nil then
            cr.rot = vec3()
          else
            cr.rot = vec3(cr.rot)
          end
          if cr.fov == nil then cr.fov = 70 end

          -- rotation is 180 dg off? O_o
          cr.rot = cr.rot + vec3(0, 180, 0)
        end
      end
    end

    local groupCounter = 0
    vehicle.groups = {}
    for keyEntry, entry in pairs (vehicle) do
      if type(entry) == "table" then
        for rowKey, row in pairs (entry) do
          if type(row) == "table" then
            local newGroups = {}
            local firstIdx = -1
            if row.group ~= nil and type(row.group) == "table" then
              for keyGroup, group in pairs(row.group) do
                if group ~= "" then
                  if vehicle.groups[group] == nil then
                    vehicle.groups[group] = groupCounter
                    groupCounter = groupCounter + 1
                  end
                  if firstIdx == -1 then
                    firstIdx = vehicle.groups[group]
                  end
                  newGroups[vehicle.groups[group]] = group
                end
              end
            end
            if firstIdx ~= -1 then
              row.group = newGroups
              row.firstGroup = firstIdx
            end
          end
        end
      end
    end
    if not tableIsEmpty(vehicle.groups) then
      log_jbeam('D', "jbeam.postProcess"," - processed "..tableSize(vehicle.groups).." groups")
      --for k, g in pairs(vehicle.groups) do
      --    log_jbeam('D', "jbeam.postProcess","  - "..k.." : "..g)
      --end
    end

    -- scaling
    for keyEntry, entry in pairs (vehicle) do
      if type(entry) == "table" and tableIsDict(entry) and M.ignoreSections[keyEntry] == nil then
        scaleValuesRecursive(entry)
      end
    end

    -- soundscape
    if vehicle.soundscape ~= nil then
      local newTable = {}
      for _, v in pairs(vehicle.soundscape) do
        newTable[v.name] = v
      end
      vehicle.soundscape = newTable
    end

    -- removing disabled sections
    for keyEntry, entry in pairs (vehicle) do
      if type(entry) == "table" and tableIsDict(entry) and M.ignoreSections[keyEntry] == nil and tableIsDict(entry[0]) and entry[0]['disableSection'] ~= nil then
        log_jbeam('D', "jbeam.postProcess"," - removing disabled section '"..keyEntry.."'")
        vehicle[keyEntry] = nil
      end
    end

    -- add default options
    if vehicle.options.beamSpring   == nil then vehicle.options.beamSpring   = 4300000 end
    if vehicle.options.beamDeform   == nil then vehicle.options.beamDeform   = 220000 end
    if vehicle.options.beamDamp     == nil then vehicle.options.beamDamp     = 580 end
    if vehicle.options.beamStrength == nil then vehicle.options.beamStrength = math.huge end
    if vehicle.options.nodeWeight   == nil then vehicle.options.nodeWeight   = 25 end
  end

  --log_jbeam('D', "jbeam.postProcess","- post processing done.")
  return true
end

--[[doxygen
optimize vehicles
@param vehicles  a table type for vehicles
@return boolean
Boolean optimize(table vehicles);
--]]
local function optimize(vehicles)
  --log_jbeam('D', "jbeam.optimize","- Optimizing ...")
  for keyVehicle, vehicle in pairs (vehicles) do
    -- first: optimize beams
    if vehicle.beams == nil then
      return
    end
    for k, v in pairs(vehicle.beams) do
      if type(v) == "table" and type(v.id1) == "number" and type(v.id2) == "number" and v.id1 > v.id2 then
        -- switch
        local t = v.id1
        v.id1 = v.id2
        v.id2 = t
      end
    end
    -- then order
    --dump(vehicle.beams)
    table.sort(vehicle.beams, function(a,b)
        if a == nil or b == nil or type(a) ~= "number" or type(b) ~= "number" then
          return false
        end
        if a.id1 ~= b.id1 then
          return a.id1 < b.id1
        else
          return a.id2 < b.id2
        end
      end)

    -- update cid to match with the sorted result
    for k, v in pairs(vehicle.beams) do
      v.cid = k
    end
  end
  --log_jbeam('D', "jbeam.optimize","- Optimization done.")

  return true
end

local function generateCollTrisFromQuads(vehicles)
  for keyVehicle, vehicle in pairs (vehicles) do
    -- add quads
    if vehicle.quads ~= nil then
      vehicle.maxIDs.triangles = vehicle.maxIDs.triangles or 0
      if vehicle.triangles == nil then vehicle.triangles = {} end
      -- quads are a way of placing two tris at the same time
      for quadKey, quad in pairs (vehicle.quads) do
        local tri1 = deepcopy(quad)
        tri1.cid = vehicle.maxIDs.triangles
        vehicle.maxIDs.triangles = vehicle.maxIDs.triangles + 1
        table.insert(vehicle.triangles, tri1)
        tri1.id4 = nil

        local tri2 = deepcopy(quad)
        tri2.cid = vehicle.maxIDs.triangles
        vehicle.maxIDs.triangles = vehicle.maxIDs.triangles + 1
        tri2.id1 = quad.id3
        tri2.id2 = quad.id4
        tri2.id3 = quad.id1
        tri2.id4 = nil
        table.insert(vehicle.triangles, tri2)
      end
    end
  end
end

--[[doxygen
update the information of CollTris
@param vehicles  a table type for vehicles
@return Boolean
Boolean updateCollTris(table vehicles);
--]]
local function updateCollTris(vehicles)
  for keyVehicle, vehicle in pairs (vehicles) do
    if vehicle.beams and vehicle.triangles then
      local beamIndex = {}

      for k, v in pairs(vehicle.beams) do
        if type(v.id1) == "number" and type(v.id2) == "number" then
          beamIndex[math.min(v.id1, v.id2)..'\0'..math.max(v.id1, v.id2)] = v
        end
      end

      for k, v in pairs(vehicle.triangles) do
        if type(v.id1) == "number" and type(v.id2) == "number" and type(v.id3) == "number" then
          local beamCount = 0

          local b = math.min(v.id1, v.id2)..'\0'..math.max(v.id1, v.id2)
          if beamIndex[b] then
            if not beamIndex[b].collTris then beamIndex[b].collTris = {} end
            table.insert(beamIndex[b].collTris, v.cid)
            beamCount = beamCount + 1
          end
          b = math.min(v.id1, v.id3)..'\0'..math.max(v.id1, v.id3)
          if beamIndex[b] then
            if not beamIndex[b].collTris then beamIndex[b].collTris = {} end
            table.insert(beamIndex[b].collTris, v.cid)
            beamCount = beamCount + 1
          end
          b = math.min(v.id2, v.id3)..'\0'..math.max(v.id2, v.id3)
          if beamIndex[b] then
            if not beamIndex[b].collTris then beamIndex[b].collTris = {} end
            table.insert(beamIndex[b].collTris, v.cid)
            beamCount = beamCount + 1
          end
          v.beamCount = beamCount
        end
      end
    end
  end
  return true
end

--[[doxygen
compile
@param vehicles  a table type for vehicles
@return vehicles otherwise nil
table compile(table vehicles);
--]]
local function compile(vehicles)
  local hp1 = HighPerfTimer()

  if not prepare(vehicles) then
    log_jbeam('W', "jbeam.compile", "*** preparation error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.1 compile - prepare', hp1:stopAndReset()})

  local linksToResolve = prepareLinks(vehicles)
  if linksToResolve == nil then
    log_jbeam('W', "jbeam.compile", "*** link preparation error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.2 compile - linking', hp1:stopAndReset()})

  if not assignCIDs(vehicles) then
    log_jbeam('W', "jbeam.compile", "*** numbering error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.3 compile - CIDs', hp1:stopAndReset()})

  if not resolveLinks(vehicles, linksToResolve) then
    log_jbeam('W', "jbeam.compile", "*** link resolving error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.4 compile - resolvelinking', hp1:stopAndReset()})

  if not postProcess(vehicles) then
    log_jbeam('W', "jbeam.compile", "*** post processing error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.5 compile - postProcess', hp1:stopAndReset()})

  if not optimize(vehicles) then
    log_jbeam('W', "jbeam.compile", "*** optimization error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.6 compile - optimize', hp1:stopAndReset()})

  generateCollTrisFromQuads(vehicles)

  if not updateCollTris(vehicles) then
    log_jbeam('W', "jbeam.compile", "*** collision triangle update error")
    return nil
  end

  table.insert(loadingTimes, {'1.3.2.7 compile - coltris', hp1:stopAndReset()})

  -- set some options from our side
  vehicles.filename = filename
  vehicles.fullFilename = fn
  vehicles.vehicleDirectory = M.vehicleDirectory
  vehicles.format = "parsed"

  return vehicles
end

-- cleans up some data that is not needed at runtime, but only during assembly of the vehicle
local function removeKeysRecursive(d)
  if type(d) ~= 'table' then return end
  -- what to clean up now
  d.childParts = nil
  d.partName = nil
  d.partOrigin = nil
  d.skinName = nil
  d.slotType = nil
  -- recurse
  for _, v in pairs(d) do
    removeKeysRecursive(v)
  end
end

local function cleanup()
  removeKeysRecursive(M.vehicles)
end

--[[doxygen
assemble vehicles
@return no return if everything goes fine, otherwise false
void assemble();
--]]
local function assemble()
  local hp1 = HighPerfTimer()
  local partsCopy = shallowcopy(M.partMap)
  local mainCopy = deepcopy(M.main)

  M.slotMap = fillSlots(partsCopy, mainCopy, 1)
  --dump(self.slotMap)

  -- now just load the main vehicle :)
  local vehicles_temp = {}
  vehicles_temp.main = mainCopy

  table.insert(loadingTimes, {'1.3.1 fillslots', hp1:stopAndReset()})

  --jsonWriteFile(M.vehicleDirectory .. "all_parts.json", partsCopy, true)
  --saveCompiledJBeam(partsCopy, M.vehicleDirectory .. "all_parts.json", -1)

  -- uncomment this for insights what the jbeamm looks like
  --saveCompiledJBeam(vehicles_temp, M.vehicleDirectory .. "compiled_main.json")

  M.vehicles = compile(vehicles_temp)

  table.insert(loadingTimes, {'1.3.2.X compile (sum)', hp1:stopAndReset()})

  --dumpTableToFile(self.vehicles, false, directory.."post_compiled.txt")
  --log_jbeam('D', "jbeam.assemble","* dumping to file: " .."post_compiled.txt")

  -- TODO: commented for now, needs fixing
  --cleanup()

  if M.vehicles == nil then
    return false
  end
  return true
end

local function resolveBaseParts(allParts)
  local _mergeJBEAM = function(jbeam1, jbeam2)
    for k, v in pairs(jbeam2) do
      if k == 'information' then
        tableMergeRecursive(jbeam1[k], jbeam2[k])
      elseif k == 'slots' or k == 'flexbodies'then
        -- in target jbeam dont have the property, create and copy it
        if not jbeam1[k] then
          jbeam1[k] = {}
          tableMergeRecursive(jbeam1[k], jbeam2[k])
        else
          -- check if the property have a entry with same id
          for _, v2_from in ipairs(jbeam2[k]) do
            local isOverride = false
            if jbeam1[k] then
              for _, v2_to in ipairs(jbeam1[k]) do
                if v2_to[1] == v2_from[1] then
                  tableMergeRecursive(v2_to, v2_from)
                  isOverride = true
                end
              end
            end
            -- if the entry is new copy it
            if not isOverride then
              table.insert(jbeam1[k], v2_from)
            end
          end
        end
      elseif k ~= 'basePart' then
        log_jbeam('E', "jbeam.resolveBaseParts","    "..k.." JBEAM property are not supportted by basePart")
      end
    end
  end

  for k,v in pairs(allParts) do
    if v.basePart and allParts[v.basePart] then
      local tempPart = deepcopy(allParts[v.basePart])
      _mergeJBEAM(tempPart, v)
      allParts[k] = tempPart
      --jsonWriteFile(k.."_orig.jbeam", allParts[v.basePart], true)
      --jsonWriteFile(k..".jbeam", allParts[k], true)
    end
  end
end

local function loadDirectories(directories, _allParts, _partMap)
  local allParts = _allParts or {}
  local partMap = _partMap or {}
  log_jbeam('D', "jbeam.loadDirectories","*** loading jbeam files ***")

  local hp2 = HighPerfTimer()

  -- step 1: find all jbeam files
  local jbeamFiles = {}
  for _, directory in pairs(directories) do
    if not FS:directoryExists(directory) then
      log_jbeam('W', "jbeam.loadDirectories", "error loading vehicle directory:"..directory.." / "..directory )
      goto continue
    end
    table.insert(M.directoriesloaded, directory)
    --log_jbeam('D', "jbeam.loadDirectories","loading vehicle directory:"..directory)
    local folders = {}
    local basePath = directory
    local files = FS:findFiles(directory, "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
      table.insert(jbeamFiles, file)
    end

    ::continue::
  end

  table.insert(loadingTimes, {'1.1.1 filesystem find', hp2:stopAndReset()})

  -- step 2: load them all from the Filesystem in one go - a lot more efficient to read all files first
  local fileContent = {}
  --dump(jbeamFiles)
  for _, filename in pairs(jbeamFiles) do
    fileContent[filename] = readFile(filename)
  end
  table.insert(loadingTimes, {'1.1.2 filesystem read', hp2:stopAndReset()})

  -- step 2: load them all from the Filesystem in one go
  --perf.enable(1)
  local partFilenames = {}

  local json = require("json")
  for filename, content in pairs(fileContent) do
    local state, parts = pcall(json.decode, content)
    if state == false then
      log_jbeam('E', "jbeam.loadDirectories","unable to decode JSON: "..tostring(filename))
      log_jbeam('E', "jbeam.loadDirectories","JSON decoding error: "..tostring(parts))
      return nil
    end

    --log_jbeam('D', "jbeam.loadDirectories","  * " .. filename .. " - "..tableSize(parts).." parts")
    for partName, part in pairs(parts) do
      if allParts[partName] ~= nil then
        log_jbeam('W', "jbeam.loadDirectories", "Duplicated part: "..tostring(partName) .. ' from file: ' .. tostring(filename) .. ' and ' .. (partFilenames[partName] or ''))
      end
      if type(part) == 'table' then
        partFilenames[partName] = filename
        allParts[partName] = part;
      else
        log_jbeam('W', "jbeam.loadDirectories","Ignoring invalid part: "..tostring(part))
      end
    end
  end

  --perf.disable()
  --perf.saveDataToCSV('json_performance.csv')

  -- if there only one part, use that as main
  if next(allParts, next(allParts)) == nil then
    for partK,partV in pairs(allParts) do
      allParts[partK].slotType = "main"
    end
  end

  table.insert(loadingTimes, {'1.1.3 json parsing', hp2:stopAndReset()})

  --dumpTableToFile(allParts, false, "test-out.jbeamp")
  partMap = {}

  for partK,partV in pairs(allParts) do
    local slotType = allParts[partK].slotType
    if slotType ~= nil then
      if partMap[slotType] == nil then
        partMap[slotType] = {}
      end
      partV.partName = partK
      table.insert(partMap[slotType], partV)
    else
      log_jbeam('W', "jbeam.loadDirectories","MISSING slotType for part: "..partK)
    end
  end

  return allParts, partMap
end

local function loadVehicle(vehicleDir)
  local hp1 = HighPerfTimer()

  M.vehicleDirectory = vehicleDir -- assumes the vehicle dir is always last
  log_jbeam('D', "jbeam.loadVehicle","set vehicle directory to "..tostring(M.vehicleDirectory))

  -- 1st: load the vehicle dir:
  local dirs = {M.vehicleDirectory}
  if M.main.information == nil or M.main.information.includes == nil then
    table.insert(dirs, 'vehicles/common')
  end

  local allParts, partMap = loadDirectories(dirs)

  -- 2nd: find the main part in the goo

  if partMap[mainPartType] == nil or partMap[mainPartType][1] == nil then
    log_jbeam('W', "jbeam.loadVehicle","main slot not found, unable to spawn")
    return false
  end

  M.main = partMap[mainPartType][1]

  --3rd: do we need to load more files?
  if type(M.main.information) == 'table' then
    if type(M.main.information.includes) == 'table' then
      -- yes, respect the order
      allParts, partMap = loadDirectories(M.main.information.includes, allParts, partMap)
    else
      log_jbeam('D', "jbeam.loadVehicle","invalid include directive: " .. dumps(M.main.information.includes))
    end
  end

  M.partMap = partMap
  local partCostLookup = {}
  for _,v in pairs(allParts) do
    if v.information and v.partName then
      partCostLookup[v.partName] =
      {
        value = v.information.value or 0,
        name = v.information.name or "None"
      }
    end
  end
  M.partCostLookup = partCostLookup

  log_jbeam('D', "jbeam.loadDirectories","*** jbeam loading done, found "..tableSize(allParts) .. ' parts')

  --jsonWriteFile(M.vehicleDirectory .. "all_parts.json", allParts, true)
  --dumpTableToFile(self.partMap, false, "test-out.jbeamp")

  table.insert(loadingTimes, {'1.X.X filesystem (sum)', hp1:stopAndReset()})

  --log_jbeam('D', "jbeam.loadVehicle","* assembling main jbeam. " ..M.main.partName)

  local res = assemble()
  table.insert(loadingTimes, {'1.3.X.X assemble (sum)', hp1:stopAndReset()})
  return res
end

--[[doxygen
do part of changes of vehicles
  @param object  object
  void doPartChanges(table object);
  --]]
  local function doPartChanges(object)
    assemble()
    -- force reload
    pushToPhysics(object)
  end
  -- public interface

  M.loadVehicle = loadVehicle
  M.pushToPhysics = pushToPhysics
  M.doPartChanges = doPartChanges

  return M
