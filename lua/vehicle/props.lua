-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local propCount = 0
local breakGroupMap = {}
local deformGroupMap = {}

local function updateProp(prop)
    local val = prop.dataValue
    if val == nil then return end
    --convert any possible bools to 0/1
    val = type(val) == "boolean" and (val and 1 or 0) or val

    -- respect the function multiplier, limits and offset
    local valTransform = math.min(math.max(val * prop.multiplier, prop.min), prop.max) + prop.offset

    -- application of the value as rotation and translation
    obj:propUpdate(prop.propObj, prop.translation, prop.rotation, not prop.hidden, val, valTransform)
end

local function update()
  local props = v.data.props or {}
  for i = 0, propCount do
    local prop = props[i]
    if prop and (prop.slotID and not prop.disabled) then
      prop.dataValue = electrics.values[prop.func]
      updateProp(prop)
    end
  end
end

local function reset()
  if not v.data.props or not obj.ibody or v.data.props[0] == nil then
    propCount = 0
    M.update = nop
    return
  end

  breakGroupMap = {}
  deformGroupMap = {}

  local newProps = {}

  for propKey, prop in pairs (v.data.props) do
    prop.disabled = false
    prop.hidden = false
    prop.dataValue = 0
    if prop.slotID then
      prop.propObj = obj.ibody:getProp(prop.slotID)
    end
    if prop.propObj == nil then
      prop.disabled = true
    end

    if prop.breakGroup ~= nil then
      local breakGroups = type(prop.breakGroup) == "table" and prop.breakGroup or {prop.breakGroup}
      for _, g in pairs(breakGroups) do
        if type(g) == 'string' and g ~= '' then
          if breakGroupMap[g] == nil then breakGroupMap[g] = {} end
          table.insert(breakGroupMap[g], prop)
        end
      end
    end

    if prop.deformGroup ~= nil then
      local deformGroups = type(prop.deformGroup) == "table" and prop.deformGroup or {prop.deformGroup}
      for _, g in pairs(deformGroups) do
        if type(g) == 'string' and g ~= '' then
          if deformGroupMap[g] == nil then deformGroupMap[g] = {} end
          table.insert(deformGroupMap[g], prop)
        end
      end
    end

    if prop and prop.slotID and not prop.disabled then
      updateProp(prop)
    end
  end

  propCount = #v.data.props
end

local function disablePropsInDeformGroup(deformGroup)
  if deformGroupMap[deformGroup] then
    for _, prop in ipairs(deformGroupMap[deformGroup]) do
      if not (prop.disabled and prop.dataValue == 0) then
        --log('D', "props.disablePropsInDeformGroup", "prop disabled: "..propKey)
        prop.disabled = true
        prop.dataValue = 0
        if prop.propObj ~= nil then
          updateProp(prop)
        end
      end
    end
    deformGroupMap[deformGroup] = nil
  end
end

local function hidePropsInBreakGroup(breakGroup)
  if breakGroupMap[breakGroup] then
    for _, prop in ipairs(breakGroupMap[breakGroup]) do
      if not (prop.hidden and prop.disabled and prop.dataValue == 0) then
        -- log('D', "props.hidePropsInBreakGroup", "prop hidden: ".. tostring(breakGroup))
        prop.disabled = true
        prop.hidden = true
        prop.dataValue = 0
        if prop.propObj ~= nil then
          updateProp(prop)
        end
      end
    end
    breakGroupMap[breakGroup] = nil
  end
end

-- public interface
M.update = update
M.reset = reset
M.init = reset
M.disablePropsInDeformGroup = disablePropsInDeformGroup
M.hidePropsInBreakGroup = hidePropsInBreakGroup

return M
