-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require("utils")
local M = {}

local triggers = {}
local triggerList = {}

M.switches = {}

local deformMeshes = {}
local brokenSwitches = {}
local lastValues = {}
local changedMats = {}
local matState = {}

-- really needs to be global as the particle filters use this
local mv = {}

local function materialLoadStr(str, name)
  local f, err = load("return function () " .. str .. " end", name or str, 't', M.mv)
  if f then
    return f()
  else
    log('E', "material.init", tostring(err))
    return nop
  end
end

local function switchMaterial(msc, matname)
  if matname == nil then
    if matState[msc] ~= false then
      matState[msc] = false
      obj:resetMaterials(msc)
    end
  else
    if matState[msc] ~= matname then
      matState[msc] = matname
      obj:switchMaterial(msc, matname)
    end
  end
end

local function init()
  if obj.ibody == nil then
    return
  end

  -- clean material cache
  M.mv = mv
  brokenSwitches = {}
  triggers = {}
  matState = {}
  local triggerSet = {}

  -- store the flexbody materials for later usage
  local flexmeshMats = {}
  v.data.flexbodies = v.data.flexbodies or {}

  for flexKey, flexbody in pairs(v.data.flexbodies) do
    local matNamesStr = obj.ibody:getMeshsMaterials(flexbody.mesh)
    --log('D', "material.init", "flexbody mesh '"..flexbody.mesh.."' contains the following materials: " .. matNamesStr)
    flexmeshMats[flexbody.mesh] = split(trim(matNamesStr)," ")
  end

  -- now the glow map
  if v.data.glowMap ~= nil then
    for orgMat, gm in pairs (v.data.glowMap) do
      --log('D', "material.init", "getSwitchableMaterial("..orgMat..")")
      local meshStr = obj.ibody:getMeshesContainingMaterial(orgMat)
      --log('D', "material.init", "[glowmap] meshes containing material " .. orgMat .. ": " .. tostring(meshStr))
      local meshes = split(trim(meshStr)," ")
      --if(not meshes or #meshes == 0 or (#meshes == 1 and meshes[1] == '')) then log('E', "material.init", "[glowmap] No meshes containing material " .. orgMat) end
      for meshi, mesh in pairs(meshes) do
        local gmat = deepcopy(gm)
        gmat.orgMat = orgMat

        if mesh == "" then goto continue end
        gmat.msc = obj.ibody:getSwitchableMaterial(orgMat, gm.off, mesh)
        if gmat.msc and gmat.msc >= 0 then
          table.insert(triggers, gmat)
          local switchName = tostring(orgMat) .. "|"..tostring(mesh)
          --log('D', "material.init", "[glowmap] created materialSwitch '"..switchName.."' [" .. tostring(gmat.msc) .. "] for material " .. tostring(orgMat) .. " on mesh " .. mesh)
          gmat.mesh = mesh
          M.switches[switchName] = gmat.msc
          local fields = {}
          if gm.simpleFunction then
            local cmd = nil
            if type(gm.simpleFunction) == 'string' then
              cmd = gm.simpleFunction
              mv[gm.simpleFunction] = 0
              triggerSet[gm.simpleFunction] = true
            elseif type(gm.simpleFunction) == 'table' then
              for fk, fc in pairs(gm.simpleFunction) do
                local s = '('..fk..'*'..fc..')'
                table.insert(fields, s)
                mv[fk] = 0
                triggerSet[fk] = true
              end
              cmd = "(" .. join(fields, " + ") .. ")"
            end
            --if gm.limit then
            --    cmd = 'math.min('..gm.limit..', ('..cmd..'))'
            --end
            gmat.evalFunction = materialLoadStr("return "..cmd)
          elseif gm.advancedFunction and gm.advancedFunction.triggers and gm.advancedFunction.cmd then
            for _, fc in pairs(gm.advancedFunction.triggers) do
              mv[fc] = 0
              triggerSet[fc] = true
            end
            gmat.evalFunction = materialLoadStr('return ('..gm.advancedFunction.cmd..')')
          end
        else
          log('E', "material.init", "[glowmap] failed to create materialSwitch '"..switchName.."' for material " .. tostring(k) .. " on mesh " .. tostring(mesh))
        end
        ::continue::
      end
    end
  end

  --log('D', "material.init", "###########################################################################")
  --dump(triggers)
  --dumpTableToFile(triggers, false, "triggers.js")
  --log('D', "material.init", "###########################################################################")
  -- and the deform groups
  local switchTmp = {}

  -- debug helper: list all materials on a mesh:
  --for flexKey, flexbody in pairs(v.data.flexbodies) do
  --    log('D', "material.init", "flexbody mesh '"..flexbody.mesh.."' contains the following materials: " .. obj.ibody:getMeshsMaterials(flexbody.mesh))
  --end

  for flexKey, flexbody in pairs(v.data.flexbodies) do
    if flexbody.deformGroup and flexbody.deformGroup ~= "" then

      if flexbody.deformSound and flexbody.deformSound ~= "" then    -- cache deform sounds
        deformMeshes[flexbody.deformGroup] = flexbody
      end
      --log('I', "material.init", "found deformGroup "..flexbody.deformGroup.." on flexmesh " .. flexbody.mesh)
      local meshStr = obj.ibody:getMeshesContainingMaterial(flexbody.deformMaterialBase)

      --log('I', "material.init", "[deformgroup] meshes containing material " .. flexbody.deformMaterialBase .. ": " .. tostring(meshStr))
      --log('I', "material.init", "flexbody mesh '"..flexbody.mesh.."' contains the following materials: " .. obj.ibody:getMeshsMaterials(flexbody.mesh))


      for mati, matName in pairs(flexmeshMats[flexbody.mesh]) do
        if matName == "" then goto continue end
        local switchName = tostring(matName) .. "|" .. tostring(flexbody.mesh)
        local s = M.switches[switchName]
        if s == nil then
          s = obj.ibody:getSwitchableMaterial(matName, matName, flexbody.mesh)
          if s >= 0 then
            --log('I', "material.init", "[deformgroup] created materialSwitch '"..switchName.."' [" .. tostring(s) .. "] for material " .. tostring(matName) .. " on mesh " .. tostring(flexbody.mesh))
          end
        else
          --log('I', "material.init", "[deformgroup] reused materialSwitch '"..switchName.."' [" .. tostring(s) .. "] for material " .. tostring(matName) .. " on mesh " .. tostring(flexbody.mesh))
        end
        if s and s >= 0 then
          M.switches[switchName] = s
          if switchTmp[flexbody.deformGroup] == nil then
            switchTmp[flexbody.deformGroup] = {}
          end
          table.insert(switchTmp[flexbody.deformGroup], {switch = s, dmgMat = flexbody.deformMaterialDamaged, mesh = flexbody.mesh, deformGroup = flexbody.deformGroup})
        else
          log('W', "material.init", "[deformgroup] failed to create materialSwitch '"..switchName.."' for material " .. tostring(matName) .. " on mesh " .. tostring(flexbody.mesh))
        end
        ::continue::
      end
    end
  end

  -- add flexmesh switches to beam of the same deform group
  if v.data.beams ~= nil then
    local assignStats = {}

    for i, b in pairs(v.data.beams) do
      if b.deformGroup then
        local deformGroups = type(b.deformGroup) == "table" and b.deformGroup or {b.deformGroup}
        for _, g in pairs(deformGroups) do
          if switchTmp[g] ~= nil then
            for sk, sv in pairs(switchTmp[g]) do
              if b.deformSwitches == nil then b.deformSwitches = {} end
              b.deformSwitches[sv.switch] = sv
              switchMaterial(sv.switch, sv.dmgMat) -- preload dmg material
              if assignStats[g] == nil then assignStats[g] = 0 end
              assignStats[g] = assignStats[g] + 1
            end
          else
            --log('W', "material.init", "deformGroup on beam not found on any flexmesh: "..beam.deformGroup)
          end
        end
      end
    end
    --log('I', "material.init", "available deformGroups:")
    --for k, va in pairs (assignStats) do
    --    log('I', "material.init", " * " .. k .. " on " .. va .. " beams")
    --end
  end

  -- switch all the materials through their states to precompile the shaders so it doesnt lag when the material switches really
  local matSet = {}
  triggerList = {}
  for _, s in pairs(triggers) do
    matSet[s.msc] = s
  end

  for tk, _ in pairs(triggerSet) do
    table.insert(triggerList, tk)
  end

  for _, s in pairs(matSet) do
    if s.on then
      switchMaterial(s.msc, s.on)
    end
    if s.on_intense then
      switchMaterial(s.msc, s.on_intense)
    end
    switchMaterial(s.msc)
  end

  for _, va in pairs(M.switches) do
    switchMaterial(va)
  end
end

local function updateGFX()
  -- check for changes
  local eVals = electrics.values
  local varChanged = false
  for _, f in ipairs(triggerList) do
    local v = eVals[f]
    if v ~= nil and v ~= lastValues[f] then
      lastValues[f] = v
      if type(v) == "boolean" then v = v and 1 or 0 end
      mv[f] = v
      varChanged = true
    end
  end

  if not varChanged then
    return
  end

  -- change materials
  -- log('E', "material.funcChanged", "funcChanged("..f..","..val)
  table.clear(changedMats)
  for _, va in ipairs(triggers) do
    if brokenSwitches[va.msc] == nil then
      local localVal = va.evalFunction()
      if localVal == nil then
        brokenSwitches[va.msc] = true
        return
      end
      local newMat = nil
      if localVal > 0.0001 then
        newMat = va.on
        if va.on_intense ~= nil then -- we have sth with 2 glow layers
          if localVal > 0.5 then
            newMat = va.on_intense
          end
        end
      end
      -- log('W', "material.funcChanged", "switchMaterial(" .. tostring(va.msc) .. ", '" .. tostring(newMat).."')")
      if newMat == nil then
        if matState[va.msc] ~= false and changedMats[va.msc] == nil then
          changedMats[va.msc] = false
        end
      else
        changedMats[va.msc] = newMat
      end
    end
  end

  for msc, newMat in pairs(changedMats) do
    if newMat ~= matState[msc] then
      matState[msc] = newMat
      if newMat then
        obj:switchMaterial(msc, newMat)
      else
        obj:resetMaterials(msc)
      end
    end
  end
end

local function switchBrokenMaterial(beam)
  for msc, g in pairs(beam.deformSwitches) do
    --log('D', "material.switchBrokenMaterial", "mesh broke: "..g.mesh.. " with deformGroup " .. g.deformGroup)
    props.disablePropsInDeformGroup(g.deformGroup)
    local dm = deformMeshes[g.deformGroup]
    if dm then --if there is a mesh assigned to this deformGroup
      if dm.deformSound and dm.deformSound ~= "" and not brokenSwitches[msc] then    --check if the mesh has a deform sound
        --sounds.playSoundOnceAtNode(dm.deformSound, beam.id1, dm.deformVolume or 1)   --play the deform sound
		sounds.playSoundOnceAtNode(dm.deformSound, beam.id1, (dm.deformVolume or 1) * 0.5)
		--print ((dm.deformVolume or 1) * 0.5)
        beamstate.addDamage(500)
      end
    end
    switchMaterial(msc, g.dmgMat)
    brokenSwitches[msc] = true
  end
end

local function reset()
  for k,va in pairs(M.switches) do
    switchMaterial(va)
  end
  brokenSwitches = {}
end

-- public interface
M.init = init
M.reset = reset
M.switchBrokenMaterial = switchBrokenMaterial
M.updateGFX = updateGFX

return M
