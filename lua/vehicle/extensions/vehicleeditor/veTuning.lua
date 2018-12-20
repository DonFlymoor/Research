local M ={}

local imguiUtils = require('ui/imguiUtils')
local im = extensions.ui_imgui

local textColor = im.ImVec4(1.0, 1.0, 0.0, 1.0)
local fuelVol = im.FloatPtr(90)

local toeLRtrim = im.IntPtr(0)
local toeAdjust = im.IntPtr(0)
local casterAdjust = im.IntPtr(0)
local camberAdjust = im.IntPtr(0)

function M.tuning()
  im.TextColored(textColor,'Chassis')
  im.Indent()
  im.PushItemWidth(400)
  im.SliderFloat('   Fuel Volume   ',fuelVol,0,90,"%.2f",2)

  im.SameLine()
  im.PushItemWidth(80)
  if im.InputFloat("L", fuelVol, 0.5, 1,"%.1f") then
    if fuelVol[0] >90 then fuelVol[0] = 90 end
    if fuelVol[0] <0 then fuelVol[0] = 0 end
  end
  im.Unindent()
  im.Separator()
  im.Spacing()
  im.TextColored(textColor,'Wheel Alignment')  
  im.Indent()
  im.Text('Front')
  im.PushItemWidth(400)
  im.SliderInt('Toe Left/Right Trim',toeLRtrim,-100,100)
  im.SameLine()
  im.PushItemWidth(80)
  if im.InputInt('%',toeLRtrim,1) then
    if toeLRtrim[0] > 100 then toeLRtrim[0] = 100 end
    if toeLRtrim[0] < -100 then toeLRtrim[0] = -100 end
  end
  im.PushItemWidth(400)
  im.SliderInt('Toe Adjust         ',toeAdjust,-100,100)
  im.SameLine()
  im.PushItemWidth(80)
  if im.InputInt('%',toeAdjust,1) then
    if toeAdjust[0] > 100 then toeAdjust[0] = 100 end
    if toeAdjust[0] < -100 then toeAdjust[0] = -100 end
  end
  im.Text('Front')
  im.PushItemWidth(400)
  im.SliderInt('Camber Adjust      ',camberAdjust,-100,100)
  im.SameLine()
  im.PushItemWidth(80)
  if im.InputInt('%',camberAdjust,1) then
    if camberAdjust[0] > 100 then camberAdjust[0] = 100 end
    if camberAdjust[0] < -100 then camberAdjust[0] = -100 end
  end
  im.PushItemWidth(400)
  im.SliderInt('Caster Adjust     ',casterAdjust,-100,100)
  im.SameLine()
  im.PushItemWidth(80)
  if im.InputInt('%',casterAdjust,1) then
    if casterAdjust[0] > 100 then casterAdjust[0] = 100 end
    if casterAdjust[0] < -100 then casterAdjust[0] = -100 end
  end

end

function M.onSerialize()
  return {
    fuelVol = fuelVol[0],
    toeLRtrim = toeLRtrim[0],
    toeAdjust = toeAdjust[0],
    casterAdjust = casterAdjust[0],
    camberAdjust = camberAdjust[0],
  }
end

function M.onDeserialized(data)
  fuelVol[0] = data.fuelVol
  toeLRtrim[0] = data.toeLRtrim
  toeAdjust[0] = data.toeAdjust
  casterAdjust[0] = data.casterAdjust
  camberAdjust[0] = data.camberAdjust
end--]]
return M