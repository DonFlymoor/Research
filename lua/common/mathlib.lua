-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--[[
Usage:

a = vec3(1,2,3)
b = vec3({1,2,3})
c = vec3({x = 1, y = 2, z = 3})
print(a == b)
print( (a-b) == vec3(0, 0, 0) )
print( (c*1) )
print( vec3(10,0,0):dot(vec3(10,0,0)) )
]]

local min, max, sqrt, abs = math.min, math.max, math.sqrt, math.abs

local newLuaVec3xyz
local LuaVec3 = {}
LuaVec3.__index = LuaVec3

local ffifound, ffi = pcall(require, 'ffi')
if ffifound then
  -- FFI available, so use it
  ffi.cdef [[struct __luaVec3_t {double x,y,z;};
       struct __luaQuat_t {double x,y,z,w;};]]
  newLuaVec3xyz = ffi.typeof("struct __luaVec3_t")
  ffi.metatype("struct __luaVec3_t", LuaVec3)
else
  ffi = nil
  -- no FFI available, compatibility mode
  newLuaVec3xyz = function (x, y, z)
   return setmetatable({ x = x, y = y, z = z }, LuaVec3)
  end
end

function vec3toString(v)
  return string.format('vec3(%g,%g,%g)', v.x, v.y, v.z)
end

function stringToVec3(s)
  local args = split(s, ' ')
  if #args ~= 3 then return nil end
  return newLuaVec3xyz(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
end

function vec3(x, y, z)
  if y == nil then
    if type(x) == 'table' and #x == 3 then
      return newLuaVec3xyz(x[1], x[2], x[3])
    else
      if x ~= nil then
        return newLuaVec3xyz(x.x, x.y, x.z)
      else
        return newLuaVec3xyz(0, 0, 0)
      end
    end
  else
    return newLuaVec3xyz(x, y, z or 0)
  end
end

function LuaVec3:set(x, y, z)
  if y == nil then
    self.x, self.y, self.z = x.x, x.y, x.z
  else
    self.x, self.y, self.z = x, y, z
  end
end

function LuaVec3:__tostring()
  return string.format('vec3(%g,%g,%g)', self.x, self.y, self.z)
end

function LuaVec3:toTable()
  return {self.x, self.y, self.z}
end

function LuaVec3:toDict()
  return {x = self.x, y = self.y, z = self.z}
end

function LuaVec3:length()
  return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function LuaVec3:lengthGuarded()
  return sqrt(self.x * self.x + self.y * self.y + self.z * self.z) + 1e-30
end

function LuaVec3:squaredLength()
  return self.x * self.x + self.y * self.y + self.z * self.z
end

function LuaVec3.__add(a, b)
  return newLuaVec3xyz(a.x + b.x, a.y + b.y, a.z + b.z)
end

function LuaVec3.__sub(a, b)
  return newLuaVec3xyz(a.x - b.x, a.y - b.y, a.z - b.z)
end

function LuaVec3.__unm(a)
  return newLuaVec3xyz(-a.x, -a.y, -a.z)
end

function LuaVec3.__mul(a, b)
  if type(b) == 'number' then
    a, b = b, a
  end
  return newLuaVec3xyz(a * b.x, a * b.y, a * b.z)
end

function LuaVec3.__div(a,b)
  if type(b) == 'number' then
    a, b = b, a
  end
  a = 1 / a
  return newLuaVec3xyz(a * b.x, a * b.y, a * b.z)
end

function LuaVec3.__eq(a, b)
  if b == nil then
    return false
  end
  return a.x == b.x and a.y == b.y and a.z == b.z
end

function LuaVec3:dot(a)
  return self.x * a.x + self.y * a.y + self.z * a.z
end

function LuaVec3:cross(a)
  return newLuaVec3xyz(self.y * a.z - self.z * a.y,
             self.z * a.x - self.x * a.z,
             self.x * a.y - self.y * a.x)
end

function LuaVec3:z0()
  return newLuaVec3xyz(self.x, self.y, 0)
end

function LuaVec3:perpendicular()
  local k = abs(self.x) + 0.5
  k = k - math.floor(k)
  return newLuaVec3xyz(-self.y, self.x - k * self.z, k * self.y)
end

function LuaVec3:perpendicularN()
  local p = self:perpendicular()
  local r = 1/(p:length() + 1e-30)
  p.x = p.x * r
  p.y = p.y * r
  p.z = p.z * r
  return p
end

function LuaVec3:cosAngle(a)
  return self:dot(a) / (sqrt(self:squaredLength() * a:squaredLength()) + 1e-30)
end

function LuaVec3:normalize()
  local r = 1/(self:length() + 1e-30)
  self.x, self.y, self.z = self.x * r, self.y * r, self.z * r
end

function LuaVec3:normalized()
  local r = 1/(self:length() + 1e-30)
  return newLuaVec3xyz(self.x * r, self.y * r, self.z * r)
end

function LuaVec3:distance(a)
  local tmp = (self.x - a.x)
  local d = tmp * tmp
  tmp = (self.y - a.y)
  d = d + tmp * tmp
  tmp = (self.z - a.z)
  return sqrt(d + tmp * tmp)
end

function LuaVec3:squaredDistance(a)
  local tmp = (self.x - a.x)
  local d = tmp * tmp
  tmp = (self.y - a.y)
  d = d + tmp * tmp
  tmp = (self.z - a.z)
  return d + tmp * tmp
end

function LuaVec3:distanceToLine(a, b)
  local ab = a - b
  local an = a - self
  return (an - (ab * ab:dot(an) / (ab:squaredLength() + 1e-30))):length()
end

function LuaVec3:squaredDistanceToLine(a, b)
  local ab = a - b
  local an = a - self
  return (an - (ab * ab:dot(an) / (ab:squaredLength() + 1e-30))):squaredLength()
end

function LuaVec3:distanceToLineSegment(a, b)
  local ab = a - b
  local an = a - self
  local xnorm = ab:dot(an) / (ab:squaredLength() + 1e-30)
  if xnorm < 0 then return an:length() end
  if xnorm > 1 then return self:distance(b) end
  return (an - (ab * xnorm)):length()
end

function LuaVec3:xnormDistanceToLineSegment(a, b)
  local ab = a - b
  local an = a - self
  local xnorm = ab:dot(an) / (ab:squaredLength() + 1e-30)
  if xnorm < 0 then return xnorm, an:length() end
  if xnorm > 1 then return xnorm, self:distance(b) end
  return xnorm, (an - (ab * xnorm)):length()
end

function LuaVec3:xnormSquaredDistanceToLineSegment(a, b)
  local ab = a - b
  local an = a - self
  local xnorm = ab:dot(an) / (ab:squaredLength() + 1e-30)
  if xnorm < 0 then return xnorm, an:squaredLength() end
  if xnorm > 1 then return xnorm, self:squaredDistance(b) end
  return xnorm, (an - (ab * xnorm)):squaredLength()
end

function LuaVec3:squaredDistanceToLineSegment(a, b)
  local ab = a - b
  local an = a - self
  local xnorm = ab:dot(an) / (ab:squaredLength() + 1e-30)
  if xnorm < 0 then return an:squaredLength() end
  if xnorm > 1 then return self:squaredDistance(b) end
  return (an - (ab * xnorm)):squaredLength()
end

function LuaVec3:xnormOnLine(a, b)
  local ab = a - b
  local an = a - self
  return ab:dot(an) / (ab:squaredLength() + 1e-30)
end

function LuaVec3:toPoint3F()
  return Point3F(self.x, self.y, self.z)
end

function LuaVec3:toFloat3()
  return float3(self.x, self.y, self.z)
end

function LuaVec3:projectToOriginPlane(pnorm)
  return self - (pnorm * (self:dot(pnorm)))
end

-- self is a point in plane
function LuaVec3:xnormPlaneWithLine(pnorm, a, b)
  return (self - a):dot(pnorm) / ((b - a):dot(pnorm) + 1e-30)
end

-- self is center of sphere, returns two xnorms (low, high). It returns pair 1,0 if no hit found
function LuaVec3:xnormsSphereWithLine(radius, a, b)
  local lDif = b - a
  local invDif2len = 1 / math.max(lDif:squaredLength(), 1e-30)
  local ac = a - self
  local dotab = -ac:dot(lDif) * invDif2len
  local D = dotab * dotab + (radius * radius - ac:squaredLength()) * invDif2len
  if D >= 0 then
    D = sqrt(D)
    return dotab - D, dotab + D
  else
    return 1, 0
  end
end

function LuaVec3:componentMul(b)
  return newLuaVec3xyz(self.x * b.x, self.y * b.y, self.z * b.z)
end

-- Based on http://geomalgorithms.com/a07-_distance.html
-- returns xnormals for the two lines
function closestLinePoints(l1p0, l1p1, l2p0, l2p1)
  local a, b, c, d, e
  do
    -- limit the number of live vars to help out luajit
    local u = l1p1 - l1p0
    local v = l2p1 - l2p0
    local w = l1p0 - l2p0
    a = u:squaredLength()
    b = u:dot(v)
    c = v:squaredLength()
    d = u:dot(w)
    e = v:dot(w)
  end
  local D = a * c - b * b

  if D < 1e-8 then
    local tc
    if b > c then
      tc = d / b
    else
      tc = e / (c + 1e-30)
    end
    return 0, tc
  else
    return (b * e - c * d) / D, (a * e - b * d) / D
  end
end

function linePointFromXnorm(p0, p1, xnorm)
  return p0 + (p1-p0) * xnorm
end

--------------------------------------------------------------------------------
-- Quaternion

local LuaQuat = {}
LuaQuat.__index = LuaQuat
local newLuaQuatxyzw

if ffi then
  newLuaQuatxyzw = ffi.typeof("struct __luaQuat_t")
  ffi.metatype("struct __luaQuat_t", LuaQuat)
else
  newLuaQuatxyzw = function (_x, _y, _z, _w)
   return setmetatable({ x = _x, y = _y, z = _z, w = _w }, LuaQuat)
  end
end

-- Returns quat. Both inputs should be normalized
function LuaVec3:getRotationTo(v)
  local w = 1 + self:dot(v)
  local qv

  if (w < 1e-6) then
    w = 0
    qv = v:perpendicular()
  else
    qv = self:cross(v)
  end
  local q = newLuaQuatxyzw(qv.x, qv.y, qv.z, -w)
  q:normalize()
  return q
end

-- Rotates by quaternion q
function LuaVec3:rotated(q)
  local qv = newLuaVec3xyz(q.x, q.y, q.z)
  local t = 2 * qv:cross(self)
  return self - q.w * t + qv:cross(t)
end

-- we follow t3d's quat convention which has uses a negative w :/
function quat(x, y, z, w)
  if y == nil then
    if type(x) == 'table' and #x == 4 then
      return newLuaQuatxyzw(x[1], x[2], x[3], x[4])
    elseif x == nil then
      return newLuaQuatxyzw(1, 0, 0, 0)
    else
      return newLuaQuatxyzw(x.x, x.y, x.z, x.w)
    end
  else
    return newLuaQuatxyzw(x, y, z, w)
  end
end

function LuaQuat:__tostring()
  return 'quat('..self.x..','..self.y..','..self.z..','..self.w..')'
end

function LuaQuat:toStringAngle()
  return string.format("[%.3f, %.3f, %.3f, %.3f]", self.x, self.y, self.z, self.w * 180/math.pi)
end

function LuaQuat:toTable()
  return {self.x, self.y, self.z, self.w}
end

function LuaQuat:toDict()
  return {x = self.x, y = self.y, z = self.z, w = self.w}
end

function LuaQuat:norm()
  return sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w)
end

function LuaQuat:squaredNorm()
  return self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w
end

function LuaQuat:normalize()
  local r = 1/(self:norm() + 1e-30)
  self.x, self.y, self.z, self.w = self.x * r, self.y * r, self.z * r, self.w * r
  return self
end

function LuaQuat:normalized()
  local r = 1/(self:norm() + 1e-30)
  return newLuaQuatxyzw(self.x * r, self.y * r, self.z * r, self.w * r)
end

function LuaQuat:inversed()
  local InvSqNorm = -1 / (self:squaredNorm() + 1e-30)
  return newLuaQuatxyzw(self.x * InvSqNorm, self.y * InvSqNorm, self.z * InvSqNorm, -self.w * InvSqNorm)
end

function LuaQuat.__unm(a)
  return newLuaQuatxyzw(-a.x, -a.y, -a.z, -a.w)
end

function LuaQuat.__mul(a, b)
  if type(a) == 'number' then
    return newLuaQuatxyzw(b.x * a, b.y * a, b.z * a, b.w * a)
  elseif type(b) == 'number' then
    return newLuaQuatxyzw(a.x * b, a.y * b, a.z * b, a.w * b)
  elseif (ffi and ffi.istype('struct __luaVec3_t', b)) or b.w == nil then
    local qv = newLuaVec3xyz(a.x, a.y, a.z)
    local t = 2 * qv:cross(b)
    return b - a.w * t + qv:cross(t)
  else
    return newLuaQuatxyzw(a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                a.w * b.y + a.y * b.w + a.z * b.x - a.x * b.z,
                a.w * b.z + a.z * b.w + a.x * b.y - a.y * b.x,
                a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z)
  end
end

function LuaQuat.__sub(a, b)
  return newLuaQuatxyzw(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
end

function LuaQuat.__div(a, b)
  return a * b:inverse()
end

function LuaQuat.__add(a, b)
  return newLuaQuatxyzw(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
end

function LuaQuat:dot(a)
  return self.x * a.x + self.y * a.y + self.z * a.z + self.w * a.w
end

function LuaQuat:nlerp(a, t)
  return ((1 - t) * self + (self:dot(a) < 0 and -t or t) * a):normalize()
end

-- returns reverse rotation
function LuaQuat:conjugated()
  return newLuaQuatxyzw(-self.x, -self.y, -self.z, self.w)
end

function LuaQuat:scale(a)
  self.x, self.y, self.z, self.w = self.x * a, self.y * a, self.z * a, self.w * a
  return self
end

--http://bediyap.com/programming/convert-quaternion-to-euler-rotations/
function LuaQuat.toEulerYXZ(q)
  local wxsq = q.w*q.w-q.x*q.x
  local yzsq = q.z*q.z-q.y*q.y
  return newLuaVec3xyz(
    math.atan2(2*(q.x*q.y + q.w*q.z), wxsq-yzsq),
    math.asin(max(-1,min(1,-2*(q.y*q.z - q.w*q.x)))),
    math.atan2(2*(q.x*q.z + q.w*q.y), wxsq+yzsq))
end

-- function LuaQuat:pow(a)
--   self:scale(a)
--   local vlen = sqrt( self.x*self.x + self.y*self.y + self.z*self.z )
--   local ret = math.exp(self.w)
--   local coef = ret * math.sin(vlen) / (vlen + 1e-60)

--   return newLuaQuatxyzw( coef*self.x, coef*self.y, coef*self.z, -ret* math.cos(vlen) )
-- end

local function quatFromAxesMatrix(m)
  local q = {[0] = 0, 0, 0, 0}
  local trace = m[0][0] + m[1][1] + m[2][2];
  if trace > 0 then
    local s = sqrt(trace + 1)
    q[3] = s * 0.5
    s = 0.5 / s
    q[0] = (m[1][2] - m[2][1]) * s
    q[1] = (m[2][0] - m[0][2]) * s
    q[2] = (m[0][1] - m[1][0]) * s
  else
    local i = 0
    if m[1][1] > m[0][0] then i = 1 end
    if m[2][2] > m[i][i] then i = 2 end
    local j = (i + 1) % 3
    local k = (j + 1) % 3

    local s = sqrt((m[i][i] - (m[j][j] + m[k][k])) + 1)
    q[i] = s * 0.5
    s = 0.5 / s
    q[j] = (m[i][j] + m[j][i]) * s
    q[k] = (m[i][k] + m[k][i]) * s
    q[3] = (m[j][k] - m[k][j]) * s
  end

  return newLuaQuatxyzw(q[0], q[1], q[2], q[3]):normalized()
end

function quatFromDir(dir, up)
  local k = up or vec3(0, 0, 1)
  local dirNorm = dir:normalized()
  local i = dirNorm:cross(k):normalized()

  k = i:cross(dirNorm):normalized()
  return quatFromAxesMatrix({[0]={[0]=i.x, dirNorm.x, k.x}, {[0]=i.y, dirNorm.y, k.y}, {[0]=i.z, dirNorm.z, k.z}})
end

function lookAt(lookAt, up)
  up = up or vec3(0, 0, 1)
	local forward = lookAt:normalized()
	local right = forward:cross(up):normalized()
  up = right:cross(forward):normalized()

	local w = sqrt(1 + right.x + up.y + forward.z) * 0.5
	local w4_recip = 1 / (4 * w)
	local x = (forward.y - up.z) * w4_recip
	local y = (right.z - forward.x) * w4_recip
	local z = (up.x - right.y) * w4_recip
	return newLuaQuatxyzw(x,y,z,w)
end

function quatFromEuler(x, y, z)
  local sx = math.sin(x * 0.5)
  local cx = math.cos(x * 0.5)
  local sy = math.sin(y * 0.5)
  local cy = math.cos(y * 0.5)
  local sz = math.sin(z * 0.5)
  local cz = math.cos(z * 0.5)

  local cycz = cy * cz
  local sysz = sy * sz
  local sycz = sy * cz
  local cysz = cy * sz
  return quat(
  cycz * sx + sysz * cx,
  sycz * cx + cysz * sx,
  cysz * cx - sycz * sx,
  cycz * cx - sysz * sx
  )
end

--------------------------------------------------------------------------------
-- generic things
function sign2(n)
  if n >= 0 then return 1 else return -1 end
end

function sign(n)
  if n > 0 then return 1 end
  if n < 0 then return -1 end
  return 0
end

function fsign(x) --branchless
  return x / (abs(x) + 1e-307)
end

function guardZero(x) --branchless
  return 1 / max(min(1/x, 1e300), -1e300)
end

function clamp(x, minValue, maxValue )
  return min(max(x, minValue), maxValue)
end

function square(a)
  return a * a
end

function round(a)
  return math.floor(a+.5)
end

function isnan(a)
  return not(a == a)
end

function isinf(a)
  return abs(a) == math.huge
end

function smoothstep(x)
  x = min(1, max(0, x))
  return (x*x)*(3 - 2*x) --non monotonic
end

function smootherstep(x)
  return min(1, max(0, (x*x)*x*(x*(x*6 - 15) + 10)))
end

function smoothmin(a, b, k)
    k = k or 0.1
    local h = min(max(0.5 + 0.5*(b-a)/k, 0), 1)
    return a*h - (b - k*h)*(1-h)
end

function axisSystemCreate(nx, ny, nz)
  local rx = vec3()
  local ry = vec3()
  local rz = vec3()

  local row = ny:cross(nz)
  local invdet = 1 / nx:dot(row)
  row = row * invdet
  rx.x = row.x
  ry.x = row.y
  rz.x = row.z

  row = nz:cross(nx) * invdet
  rx.y = row.x
  ry.y = row.y
  rz.y = row.z

  row = nx:cross(ny) * invdet
  rx.z = row.x
  ry.z = row.y
  rz.z = row.z
  return {rx, ry, rz}
end

function axisSystemApply(as, v)
  return as[1] * v.x + as[2] * v.y + as[3] * v.z
end

function catmullRom(p0, p1, p2, p3, t, s)
  s = s or 0.5
  local c0 = p1
  local c1 = s * (p2 - p0)
  local c2 = 2 * s * p0 + (s - 3) * p1 + (3 - 2 * s) * p2 - s * p3
  local c3 = -s * p0 + (2 - s) * p1 +  (s - 2) * p2 + s * p3
  return (c0 + (c1 * t) + (c2 * (t * t)) + (c3 * (t * t * t)))
end

function catmullRomQuat(p0, p1, _p2, p3, t, s)
  local p2 = _p2
  if p1:dot(p2) < 0 then
  p2 = -_p2
  end
  s = s or 0.5
  local c0 = p1
  local c1 = s * (p2 - p0)
  local c2 = 2 * s * p0 + (s - 3) * p1 + (3 - 2 * s) * p2 - s * p3
  local c3 = -s * p0 + (2 - s) * p1 +  (s - 2) * p2 + s * p3
  return (c0 + (c1 * t) + (c2 * (t * t)) + (c3 * (t * t * t)))
end

