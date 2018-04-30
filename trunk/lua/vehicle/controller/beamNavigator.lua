-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local htmlTexture = require("htmlTexture")

local screenMaterialName = "@screen_gps"
local htmlFilePath = "local://local/vehicles/common/navi_screen.html"
local textureWidth = 256
local textureHeight = 128
local textureFPS = 30

local function updateGFX(dt)
  local pos = obj:getPosition()
  local rotation = math.deg(obj:getDirection()) + 180
  local speed = electrics.values.airspeed * 3.6
  local zoom = math.min(150 + speed * 1.5, 250)

  local data = {x = pos.x, y = pos.y, rotation = rotation, zoom = zoom}
  htmlTexture.call(screenMaterialName, "map.updateData", data)
end

local function init(data)
  screenMaterialName = data.screenMaterialName or screenMaterialName
  htmlFilePath = data.htmlFilePath or htmlFilePath
  textureWidth = data.textureWidth or textureWidth
  textureHeight = data.textureHeight or textureHeight
  textureFPS = data.textureFPS or textureFPS

  htmlTexture.create(screenMaterialName, htmlFilePath, textureWidth, textureHeight, textureFPS, 'automatic')
  obj:queueGameEngineLua(string.format('extensions.ui_uinavi.requestVehicleDashboardMap(%q)', screenMaterialName))
end

M.init = init
M.updateGFX = updateGFX

return M