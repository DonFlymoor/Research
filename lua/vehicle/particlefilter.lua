-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local function nodeCollision(p)
  --log('D', "particlefilter.particleEmitted", "particleEmitted()")

  --[[
  attributes of p:
  int id1;
  float3 pos;
  float3 normal;
  float3 nodeVel;
  float perpendicularVel;
  float slipVel;
  float slipForce;
  float normalForce;
  int materialID1;
  int materialID2;

  int particleType;
  float width;
  int count;
  ]]--

  --dump(p)

  --log('D', "particlefilter.particleEmitted", p.materialID1..", "..p.materialID2)
  local pKey = p.materialID1 * 10000 + p.materialID2
  if v.materialsMap[pKey] ~= nil then
    for k,r in pairs(v.materialsMap[pKey]) do
      --log('D', "particlefilter.particleEmitted", r.compareFuncStr)
      if r.compareFunc(p) then
        p.nodeVel:scale(r.veloMult) -- not working?!?!
        p.particleType = r.particleType
        p.width = r.width
        p.count = r.count
        --log('D', "particlefilter.particleEmitted", "spawned particle type " .. tostring(p.particleType))
        obj:addParticle(p)
      end
    end
  end
end

-- public interface
M.nodeCollision = nodeCollision

return M
