--
-- A small 3D vector class (with homogenous coordinates) for 3D graphics.
--

import "CoreLibs/object"

local sin <const> = math.sin
local cos <const> = math.cos
local tan <const> = math.tan
local acos <const> = math.acos

class('vec3d').extends()

function vec3d:init(x, y, z, w)
  self.x = x or 0
  self.y = y or 0
  self.z = z or 0
  self.w = w or 0
end

function vec3d:tostring()
  return string.format('x: %f y: %f z: %f w: %f', self.x, self.y, self.z, self.w)
end

function vec3d:magnitude()
  return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end

function vec3d:normalize()
  local mag = self:magnitude()
  return vec3d(self.x / mag, self.y / mag, self.z / mag)
end

function vec3d:mult(scalar)
  return vec3d(self.x * scalar, self.y * scalar, self.z * scalar)
end

function vec3d:dot(vec)
  return self.x*vec.x + self.y*vec.y + self.z*vec.z
end

function vec3d:angle(vec) -- angle between self and vec, in radians
  return math.acos(self:dot(vec) / (self:magnitude() * vec:magnitude()))
end

function vec3d:div(s)
  return vec3d(self.x / s, self.y / s, self.z / s)
end

function vec3d:adds(s)
  return vec3d(self.x + s, self.y + s, self.z + s)
end

function vec3d:subs(s)
  return vec3d(self.x - s, self.y - s, self.z - s)
end

function vec3d:addv(v)
  return vec3d(self.x + v.x, self.y + v.y, self.z + v.z)
end

function vec3d:subv(v)
  return vec3d(self.x - v.x, self.y - v.y, self.z - v.z)
end

function vec3d:cross(vec)
  local x = self.y * vec.z - self.z * vec.y
  local y = (self.x * vec.z - self.z * vec.x) * -1
  local z = self.x * vec.y - self.y * vec.x
  return vec3d(x, y, z)
end
