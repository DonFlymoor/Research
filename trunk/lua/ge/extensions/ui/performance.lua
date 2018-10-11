-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local frameMeters = {'luaDelay',
  'sfxDelay',
  'physDelay',
  'cpuRender',
  'cpuPreRender',
  'cpuPostRender',
  'framePresentDelay',
  'cpuUpdateUI',
  'othersFrameMs'}

local function onPreRender()
  local rawData = getPerformanceMetrics()

  -- fix data up so it is standalone
  rawData.cpuPostRender = rawData.cpuPostRender - rawData.physDelay

  if rawData.frameTimeMs then
    rawData.othersFrameMs = rawData.frameTimeMs
    for i,v in ipairs(frameMeters) do
      if v ~= 'othersFrameMs' and rawData[v] then
        rawData.othersFrameMs = rawData.othersFrameMs - rawData[v]
      end
    end
  end

  -- test data:
  --rawData.random = math.random(1, 10),
  --rawData.sin = math.sin(Engine.Platform.getRealMilliseconds() / 1000) + 1
  --rawData.const = 1
  --rawData.cos = math.cos(Engine.Platform.getRealMilliseconds() / 500) + 1
  --dump(rawData)

  -- TODO: optimize: only get the required data, not everything
  local hw = core_hardwareinfo.getInfo()

  -- merge hw info into flat scheme
  for k,v in pairs(hw) do
    if type(v) == 'table' then
      for k2,v2 in pairs(v) do
        rawData[k..k2] = v2
      end
    end
  end

  --dump(rawData)

  guihooks.triggerStream('PerformanceData', rawData)
end

local function rainbowColor(numOfSteps, step)
  -- This function generates vibrant, "evenly spaced" colours (i.e. no clustering). This is ideal for creating easily distinguishable vibrant markers in Google Maps and other apps.
  -- Adam Cole, 2011-Sept-14
  -- HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
  local r = 0
  local g = 0
  local b = 0
  local h = step / numOfSteps
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local q = 1 - f
  local iMod = i % 6
  if     iMod == 0 then r = 1; g = f; b = 0
  elseif iMod == 1 then r = q; g = 1; b = 0
  elseif iMod == 2 then r = 0; g = 1; b = f
  elseif iMod == 3 then r = 0; g = q; b = 1
  elseif iMod == 4 then r = f; g = 0; b = 1
  elseif iMod == 5 then r = 1; g = 0; b = q
  end
  --return 'rgba(' .. (r*255) .. ',' .. (g*255) .. ',' .. (b*255) .. ',1)'
  return { math.floor(r*255), math.floor(g*255), math.floor(b*255), 1}
end

local function requestConfig()
  log('D', 'performance.requestConfig', 'assembling config')
  local graphCount = 9
  local gpuCount = 11

  local config = {
    metadata = {
      -- make sure all data sources are in here
      physDelay     = { title = 'Physics', unit = 'ms', precision = 3, window = 30, color = rainbowColor(graphCount, 0) },
      cpuRender     = { title = 'CPU Render', unit = 'ms', precision = 1, window = 30, color = rainbowColor(graphCount, 7) },
      fps           = { title = 'FPS', unit = 'fps', precision = 0, window = 30, color = rainbowColor(graphCount, 2) },
      framePresentDelay      = { title = 'GPU Present Delay', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 3) },
      gpuVsync      = { title = 'Vsync', unit = '', precision = 0, window = 30, color = rainbowColor(graphCount, 7) },
      sfxDelay      = { title = 'Audio Delay', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 4) },
      luaDelay      = { title = 'Lua Delay', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 5) },
      cpuPreRender  = { title = 'preRender', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 6) },
      cpuPostRender = { title = 'postRender', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 1) },
      cpuUpdateUI         = { title = 'cpuUpdateUI', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 6) },
      othersFrameMs = { title = 'othersFrameMs', unit = 'ms', precision = 2, window = 30, color = rainbowColor(graphCount, 8) },
      --sin           = { title = 'Sinus test', unit = '', precision = 2, window = 30, color = rainbowColor(graphCount, 6) },
      --const         = { title = 'constant value test', unit = '', precision = 2, window = 30, color = rainbowColor(graphCount, 7) },
      memprocessPhysUsed   = { title = 'Physical memory', unit = 'bytes', precision = 1, window = 30, color = rainbowColor(graphCount, 6) },
      memprocessVirtUsed   = { title = 'Virtual memory', unit = 'bytes', precision = 1, window = 30, color = rainbowColor(graphCount, 7) },
      cpumeasuredSpeed   = { title = 'CPU Speed', unit = 'GHz', precision = 3, window = 30, color = rainbowColor(graphCount, 8) },

      gpu_AL_LightBinMgr       = { title = 'Light', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 0) },
      gpu_AL_PrePassBin        = { title = 'PrePass', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 6) },
      gpu_EditorBin            = { title = 'Editor', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 1) },
      gpu_GlowBin              = { title = 'Glow', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 7) },
      gpu_ObjTranslucentBin    = { title = 'Translucent Objects', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 2) },
      gpu_RenderBinImposter    = { title = 'Imposter', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 8) },
      gpu_RenderBinMesh        = { title = 'Mesh', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 3) },
      gpu_RenderBinParticle    = { title = 'Particle', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 9) },
      gpu_RenderBinTranslucent = { title = 'Translucent', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 4) },
      gpu_RenderTerrain        = { title = 'Terrain', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 10) },
      gpu_PostFX               = { title = 'Post Effects', unit = 'ms', precision = 2, window = 30, color = rainbowColor(gpuCount, 5) },

      -- the default value if it was not found above
      default       = { title = '', unit = '', precision = 3, window = 30, color = 'random' }, -- 'random' as color is special ;)
    },
    stacked = {
      { title = "CPU", precision = 0, unit = 'ms', graphs = frameMeters}
      --{ title = "Test", graphs = {'const', 'sin'} },
    },
    simple = {
      { title = 'FPS', graph = 'fps' },
      { title = 'Physics delay', graph = 'physDelay' },
      { title = 'CPU delay', graph = 'cpuRender' },
      { title = 'GPU Present Delay', graph = 'framePresentDelay' },
      { title = 'GPU vsync', graph = 'gpuVsync' },
      { title = 'Audio delay', graph = 'sfxDelay' },
      { title = 'Lua delay', graph = 'luaDelay' },
      { title = 'Phys. Memory', graph = 'memprocessPhysUsed' },
      { title = 'Virt. Memory', graph = 'memprocessVirtUsed' },
      { title = 'CPU Speed', graph = 'cpumeasuredSpeed' },
      --{ title = 'Sinus Test', graph = 'sin' },
    }
  }

  --print("ligthing quality: " .. tonumber(settings.getValue('GraphicLightingQuality')))
  if tonumber(settings.getValue('GraphicLightingQuality')) > 0 then
    -- all other gfx settings other than lowest
    table.insert(config.stacked, { title = "GPU", precision = 2, unit = 'ms', graphs = {
      'gpu_AL_LightBinMgr',
      'gpu_AL_PrePassBin',
      'gpu_EditorBin',
      'gpu_GlowBin',
      'gpu_ObjTranslucentBin',
      'gpu_RenderBinImposter',
      'gpu_RenderBinMesh',
      'gpu_RenderBinParticle',
      'gpu_RenderBinTranslucent',
      'gpu_RenderTerrain',
      'gpu_PostFX',
      }
    })
  else
    -- lowest graphics settings
    table.insert(config.stacked, { title = "GPU (lowest)", precision = 2, unit = 'ms', graphs = {
      'gpu_EditorBin',
      'gpu_GlowBin',
      'gpu_ObjTranslucentBin',
      'gpu_RenderBinImposter',
      'gpu_RenderBinMesh',
      'gpu_RenderBinParticle',
      'gpu_RenderBinTranslucent',
      'gpu_RenderTerrain',
      }
    })
  end

  guihooks.trigger('PerformanceInit', config)
end

local function onLoad()
  --log('D', 'performance.onLoad', "performance module loaded")
  requestConfig()
end

local function onExtensionUnloaded()
  --log('D', 'performance.onUnload', "performance module unloaded")
end

local function onDeserialized()
end

-- public interface
M.onPreRender = onPreRender
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.requestConfig = requestConfig
M.onDeserialized = onDeserialized

return M


