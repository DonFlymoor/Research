local M ={}

local jbeam_main = require("jbeam_main")
local imguiUtils = require('ui/imguiUtils')

local im = extensions.ui_imgui
local partsPtr = {}
local partItems = {}
M.initialize = false
local partType ={}
local hp1 = HighPerfTimer()
local curState = {}
local comboIndex = {}


local function init(parts)
  for k,v in pairs(parts) do
    partsPtr[k] = im.IntPtr(0)
    for key,val in pairs(comboIndex) do 
      if key == k then
        partsPtr[k][0] = comboIndex[k]
      end
    end
    for kp,pp in pairs(v) do
      if pp.parts and tableSize(pp.parts) > 0 then
        init(pp.parts)
      end
    end
  end
  M.initialize = false
end

local function checkParts(k,comboItems,p,pp)

  if im.Combo2(k,partsPtr[k], comboItems) then
    curState[k] = pp[partsPtr[k][0]+1]
    comboIndex[k] = partsPtr[k][0]
    if partType[k] and partType[k]:find('licenseplate_design') then
      local pn = pp[partsPtr[k][0]+1]
      p[partsPtr[k][0]+1].partName =  pn     
      for i, v1 in ipairs(jbeam_main.partMap[partType[k]]) do
        if v1.partName == pn and v1.licenseplate_path then
          obj:queueGameEngineLua("core_vehicles.setPlateText( false, "..obj:getID()..",'"..v1.licenseplate_path.. "')")
        end
      end
    end 
   
    if obj.ibody and partType[k] and (partType[k]:find('skin_') or partType[k] == 'paint_design') then
      for i, v1 in ipairs(jbeam_main.partMap[k]) do
        local pn = pp[partsPtr[k][0]+1]
        p[partsPtr[k][0]+1].partName =  pn
        if v1.partName == pn then
          local skinSlot = v1.slotType
          if skinSlot == 'paint_design' then skinSlot = '' end
          obj.ibody:setSkin( skinSlot..'.'..(v1.skinName or v1.globalSkin) )
           table.insert(loadingTimes, {'2.11 skin', hp1:stopAndReset()})
          if obj.ibody then
            obj.ibody:meshCommit()
          end
          if v1.default_color ~= nil then
            obj:queueGameEngineLua("core_vehicles.setVehicleColorsNames( "..obj:getID()..", "..dumps( {v.default_color,v.default_color_2,v.default_color_3} ).. ")")
          end
        end
      end
    end
    partmgmt.setConfig({parts = curState, vars = v.userVars, settings = v.userSettings}, true)
  end
  if im.IsItemHovered() then
    partmgmt.selectPart(k,true)
  end
end

function M.displayParts(parts, fullpath)
  if M.initialize then
    init(v.slotMap)
  end
  for k, p in pairs(parts) do
    local newPath = fullpath .. '/' .. tostring(k)
    local open = im.TreeNode2(newPath, k)
    local comboItems = ''
    im.SameLine()   
    local itemActiveId = 1
    local itemActive = nil
    local partItem = {}   
    for kp, pp in pairs(p) do
      comboItems = comboItems .. pp.partName .. '\0'
      table.insert(partItem,pp.partName)
      partType[k] = pp.partType
      if pp.active then
        itemActiveId = kp
        itemActive = pp
      end
    end
    partItems[k] = partItem
    comboItems = comboItems .. '\0\0'
    checkParts(k,comboItems,p,partItem)

    if open then
      if itemActive and itemActive.parts and tableSize(itemActive.parts) > 0 then
        M.displayParts(itemActive.parts, newPath)
      end
      im.TreePop()
    end
  end

end

local function getValues(tbl)
  local res = {}
  for k,v in pairs(tbl) do
    res[k] = v
  end
  return res
end

function M.onSerialize()
  return {
    initialize = true, 
    curState = getValues(curState),
    comboIndex = getValues(comboIndex),
  }
end

function M.onDeserialized(data)
 
  M.initialize = data.initialize 
  comboIndex = getValues(data.comboIndex)
  curState = getValues(data.curState)
end
return M