local M = {}
local veTriUtils = extensions.vehicleEditor_veTriUtils

local im = extensions.ui_imgui
local ffi = require('ffi')

local curState = {}
curState.selectedTriId = 0

curState.triByName = ffi.new("bool[1]", true)

curState.toggleButton = ffi.new("bool[1]",false)

local triFilter = ffi.new('ImGuiTextFilter[1]')

function M.findTriByName()
  local tid = curState.selectedTriId
  if im.TreeNodeEx1("find triangle by name##trinamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(triFilter, "filter") then
      filterchanged = true
      tid = nil
    end
    im.BeginChild1("##trifilterresults1", im.ImVec2(0, 200))
    im.BeginColumns("trifiltertable1", 3, im.ColumnsFlags_NoResize)
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
    for t = 0, #v.data.triangles - 1 do
      local tri = v.data.triangles[t]
      if im.ImGuiTextFilter_PassFilter(triFilter, tri.name) then
        if (filterchanged and not t) or tid == tri.cid then
          tid = tri.cid
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
        else
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
        end
        if not tri.name then tri.name = "noName" end
        im.Text(tostring(tri.name))
        im.NextColumn()
        im.Text(tostring(tri.cid))
        im.NextColumn()
        if im.SmallButton('sel##triselect'..tostring(tri.cid)) then
          tid = tri.cid
        end
        im.PopStyleColor()
        im.NextColumn()
      end
    end
    im.EndColumns()
    im.EndChild()
    im.Separator()
    if tid and tid >= 0 and tid < #v.data.triangles then
      curState.selectedTriId = tid
      veTriUtils.showTriData(tid)

    else
      im.Text('No triangle selected')
    end
    im.TreePop()
  end
end

function M.onSerialize()
  return{

  }
end
function M.onDeserialized(data)

end


return M