-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this is a tiny example imgui app to be integrated within the vehicle editor. Please copy and rename it before modifying it.

local M = {}

local max, min, abs, random = math.max, math.min, math.abs, math.random

M.menuEntry = 'Suspension Audio Debug' -- what the menu item will be

local im = extensions.ui_imgui

local windowOpen = im.BoolPtr(false)

local counter = 1

local displayColor = im.BoolPtr(false)

local filter = {'Front Left', 'Front Right', 'Rear Left', 'Rear Right'}

-- main drawing function
local function updateGFX(dt)
  if windowOpen[0] ~= true then return end -- if window is invisible, do nothing

  -- window
  if im.Begin('Suspension Audio Debug', windowOpen, 0) then
    local beamSounds = sounds.getBeamSounds()

    for bi, snd in ipairs(beamSounds) do
      local currentStress = snd.smoothing:get(obj:getBeamStress(snd.beam), dt) -- find the stress on the current sound beam
      local impulse = (snd.lastStress - currentStress) / (dt * 30) -- take the difference in beam stress between this frame and the last frame, and save it as impulse
      snd.resonance = max(min(snd.resonance, snd.maxStress), 0) --limit sound factor to maxStress to prevent overly loud/long sounds
      local linDecay = (1 - snd.decayMode) * snd.resonance * snd.decayFactor * dt
      local expDecay = snd.decayMode * snd.resonance * snd.decayFactor * dt
      local factor = max(impulse, max(snd.resonance - linDecay - expDecay, 0)) --sound decays to create a smooth fade out. Rate is dependent on simulation speed.
      local normFactor = factor / snd.maxStress
      local volume = snd.volumeFactor * 1.0 * normFactor -- normalize volume (cancel out maxStress factor)
      local pitch = 1 + snd.pitchFactor * normFactor -- loud suspension sounds also gain a higher pitch
      local color = min(1, snd.colorFactor * normFactor * 1.0) -- the impulse - used for strength - controls volume curve and EQ in FMOD but no idea why the value of 1.3
      snd.lastStress = currentStress --reset for next frame comparison
      snd.resonance = factor --reset for next frame comparison
      snd.color = color
      snd.volume = volume

      if not snd.beamPos then
        if v.data.beams[snd.beam] then
          if v.data.nodes[v.data.beams[snd.beam].id1] then
            snd.beamPos = v.data.nodes[v.data.beams[snd.beam].id1].pos
            if snd.beamPos.y < 0 then
              snd.position = "Front "
            else 
              snd.position = "Rear "
            end

            if snd.beamPos.x < 0 then
              snd.position = snd.position .. "Right"
            else 
              snd.position = snd.position .. "Left"
            end
          end
        end
      end

      if not snd.volumeTbl then
        snd.volumeTbl = {}
        for i = 1, 100 do
          snd.volumeTbl[i] = 0
        end
      else 
        snd.volumeTbl[counter] = volume
      end

      if not snd.colorTbl then
        snd.colorTbl = {}
        for i = 1, 100 do
          snd.colorTbl[i] = 0
        end
      else 
        snd.colorTbl[counter] = color
      end
    end

    im.Checkbox("Display Color Values", displayColor)
    im.BeginColumns("AudioTable", 2)
    for i,v in pairs(filter) do
      for _, val in ipairs(beamSounds) do
        if v == val.position then
          im.Text("Position: ")
          im.SameLine()
          im.Text(tostring(val.position))
          if displayColor[0] then
            im.Text("Color")
            im.SameLine()
            im.Text(tostring(val.color))
            local colorArr = im.TableToArrayFloat( val.colorTbl )
            im.PlotLines1("", colorArr , im.GetLengthArrayFloat(colorArr), counter, "", 0, 1, im.ImVec2(400, 100))
          else 
            im.Text("Volume")
            im.SameLine()
            im.Text(tostring(val.volume))
            local volumeArr = im.TableToArrayFloat( val.volumeTbl )
            im.PlotLines1("", volumeArr , im.GetLengthArrayFloat(volumeArr), counter, "", 0, 1, im.ImVec2(400, 100))
          end
          im.NextColumn()
        end
      end
    end
    im.EndColumns()
  end

  if counter > 100 then
    counter = 1;
  end
  counter = counter + 1

  im.End()
end

-- helper function to open the window
local function open()
  windowOpen[0] = true
end

-- called when the extension is loaded (might be invisible still)
local function onExtensionLoaded()
end

-- called when the extension is unloaded
local function onExtensionUnloaded()
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.updateGFX = updateGFX

M.open = open

return M
