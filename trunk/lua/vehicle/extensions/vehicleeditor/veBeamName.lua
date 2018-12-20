local M = {}
local veBeamUtils = extensions.vehicleEditor_veBeamUtils

local im = extensions.ui_imgui
--local ffi = require('ffi')

local visWindow = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(700, 700)
local nextWindowPos = im.ImVec2(600,100)
local curState = {}
curState.selectedBeamId = 0
curState.beamDebugColor = ffi.new("float[4]", {[0] = 0, 0.9, 1.0, 0.3})
curState.beamByName = ffi.new("bool[1]", true)
curState.beamByNameSize = ffi.new("float[1]", 0.01)
curState.toggleButton = ffi.new("bool[1]",false)
curState.beamNameColor = ffi.new("float[4]", {[0] = 1.0, 0, 0, 0.8})
local beamFilter = ffi.new('ImGuiTextFilter[1]')

function M.findBeamByName(beamLenghts)
  local bid = curState.selectedBeamId
  if im.TreeNodeEx1("find Beam by name##beamnamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(beamFilter, "filter") then
      filterchanged = true
      bid = nil
    end
    im.BeginChild1("##beamfilterresults1", im.ImVec2(0, 200))
    im.BeginColumns("beamfiltertable1", 3, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 100)
    im.SetColumnWidth(1, 50)
    im.SetColumnWidth(2, 80)
    im.Separator()
    im.Text('Name')
    im.NextColumn()
    im.Text('Id')
    im.NextColumn()
      -- button column
    im.NextColumn()
    im.Separator()
    im.Separator()
    for b = 0, #v.data.beams - 1 do
      local beam = v.data.beams[b]
      if im.ImGuiTextFilter_PassFilter(beamFilter, beam.name) then
        if (filterchanged and not b) or bid == beam.cid then
          bid = beam.cid
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
        else
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
        end
        if not beam.name then beam.name = "noName" end
        im.Text(tostring(beam.name))
        im.NextColumn()
        im.Text(tostring(beam.cid))
        im.NextColumn()
        if im.SmallButton('sel##beamselect'..tostring(beam.cid)) then
          bid = beam.cid
        end
        im.PopStyleColor()
        im.NextColumn()
      end
    end
    im.EndColumns()
    im.EndChild()
    im.Separator()
    if bid and bid >= 0 and bid < #v.data.beams then
      curState.selectedBeamId = bid
      veBeamUtils.showBeamData(bid)
      if im.Button("Beams Visualization") then
        curState.toggleButton[0] = not curState.toggleButton[0]
        im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
        im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
      end
      if curState.toggleButton[0] then
        if im.Begin("Beam Data",visWindow) then
          if im.TreeNodeEx1("Visualization",im.TreeNodeFlags_DefaultOpen) then
            im.Checkbox("Selected Beam ",curState.beamByName)
            if curState.beamByName[0] then
              im.PushItemWidth(300)
              obj.debugDrawProxy:drawBeam3d(bid,curState.beamByNameSize[0] ,  color(curState.beamNameColor[0] * 255, curState.beamNameColor[1] * 255, curState.beamNameColor[2] * 255, curState.beamNameColor[3] * 255))
              im.SameLine()
              im.SliderFloat("Beams Size", curState.beamByNameSize, 0.01, 1.0, "%.3f", 2)
              im.SameLine()
              im.ColorEdit4("Beams Color", curState.beamNameColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
            end
            im.TreePop()
            veBeamUtils.displayLiveData(bid,beamLenghts)
          end
        end
        im.End()
      end
    else
      im.Text('No Beam selected')
    end
    im.TreePop()
  end
end

function M.onSerialize()
  return{
    beamNameColor0  = curState.beamNameColor[0],
    beamNameColor1  = curState.beamNameColor[1],
    beamNameColor2  = curState.beamNameColor[2],
    beamNameColor3  = curState.beamNameColor[3],
    beamByNameSize = curState.beamByNameSize[0],
    toggleButton   = curState.toggleButton[0],
    selectedBeamId = curState.selectedBeamId,
    beamByName = curState.beamByName[0],
  }
end
function M.onDeserialized(data)
  curState.selectedBeamId = data.selectedBeamId
  curState.beamByName[0] = data.beamByName
  curState.toggleButton[0] = data.toggleButton
  curState.beamByNameSize[0] = data.beamByNameSize
  curState.beamNameColor[0] = data.beamNameColor0
  curState.beamNameColor[1] = data.beamNameColor1
  curState.beamNameColor[2] = data.beamNameColor2
  curState.beamNameColor[3] = data.beamNameColor3
end


return M