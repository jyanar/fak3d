import "CoreLibs/object"
local matrix = import "matrix"


--
-- Linear algebra methods.
--

local cos <const> = math.cos
local sin <const> = math.sin
local tan <const> = math.tan
local acos <const> = math.acos

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Using the matrix.lua library

class('vector3d').extends()

function vector3d:init(x, y, z, w)
   self.v = matrix{{ x or 0,
                     y or 0,
                     z or 0,
                     w or 1 }}^'T'
end

function vector3d:dot(u)
   local urow, ucol = matrix.size(self.v)
   local vrow, vcol = matrix.size(u)
   if urow == 1 and vcol == 1 then return u:mul(v) end
   if urow == 1 and vcol ~= 1 then return u:mul(v:transpose()) end
   if urow ~= 1 and vcol == 1 then return u:transpose():mul(v) end
   if urow ~= 1 and vcol ~= 1 then return u:transpose():mul(v:transpose()) end
   -- return self.v:mul(u)
end

function dot(u, v)
   local urow, ucol = u:size()
   local vrow, vcol = v:size()
   if urow == 1 and vcol == 1 then return u:mul(v) end
   if urow == 1 and vcol ~= 1 then return u:mul(v:transpose()) end
   if urow ~= 1 and vcol == 1 then return u:transpose():mul(v) end
   if urow ~= 1 and vcol ~= 1 then return u:transpose():mul(v:transpose()) end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

class('vec2').extends()

function vec2:init(x, y)
   self.x = x or 0
   self.y = y or 0
end

function vec2:tostring()
   return string.format('x: %f y: %f', self.x, self.y)
end

function vec2:magnitude()
   return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2:normalize()
   local mag = self:magnitude()
   return vec2(self.x / mag, self.y / mag)
end

function vec2:add(u)
   if u:isa(vec2) then
      return vec2(self.x + u.x, self.y + u.y)
   else
      return vec2(self.x + u, self.y + u)
   end
end

function vec2:mult(scalar)
   return vec2(self.x * scalar, self.y * scalar)
end

function vec2:dot(vec)
   return self.x * vec.x + self.y * vec.y
end

function vec2:cross(vec)
   return vec2(self.x * vec.y - self.y * vec.x)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

class('vec3').extends()

function vec3:init(x, y, z)
   self.x = x or 0
   self.y = y or 0
   self.z = z or 0
end

function vec3:tostring()
   return string.format('x: %f y: %f z: %f', self.x, self.y, self.z)
end

function vec3:magnitude()
   return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function vec3:normalize()
   local mag = self:magnitude()
   return vec3(self.x / mag, self.y / mag, self.z / mag)
end

function vec3:mult(scalar)
   return vec3(self.x * scalar, self.y * scalar, self.z * scalar)
end

function vec3:dot(vec)
   return self.x * vec.x + self.y * vec.y + self.z * vec.z
end

function vec3:angle(vec)
   local a = self:normalize()
   local b = vec:normalize()
   return acos(a:dot(b))
end


function vec3:add(v)
   if type( v ) == 'number' then
      return vec3(self.x + v, self.y + v, self.z + v)
   elseif type( v ) == 'table' then
      return vec3(self.x + v.x, self.y + v.y, self.z + v.z)
   else
      error('vector3:add, invalid type!')
   end
end

function vec3:sub(v)
   return vec3(self.x - v.x, self.y - v.y, self.z - v.z)
end

function vec3:cross(vec)
   local x = self.y * vec.z - self.z * vec.y
   local y = (self.x * vec.z - self.z * vec.x) * -1
   local z = self.x * vec.y - self.y * vec.x
   return vec3(x, y, z)
end

-------------------------------------------------------------------------------

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
   return self.x * vec.x + self.y * vec.y + self.z * vec.z
end

function vec3d:angle(vec)
   local a = self:normalize()
   local b = vec:normalize()
   return acos(a:dot(b))
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

-------------------------------------------------------------------------------

class('mat4').extends()

function mat4:init()
   self.m = {}
   for irow = 1, 4 do
      self.m[irow] = {}
      for icol = 1, 4 do
         self.m[irow][icol] = 0
      end
   end
end

function mat4:set(irow, icol, val)
   self.m[irow][icol] = val
end

function mat4:tostring()
   local str = ''
   for i = 1, 4 do
      str = str .. '['
      for j = 1, 4 do
         str = str .. ' ' .. self.m[i][j]
      end
      str = str .. ']\n'
   end
   return str
end

function mat4:transpose()
   local m = mat4()
   for irow = 1, 4 do
      for icol = 1, 4 do
         m.m[irow][icol] = self.m[icol][irow]
      end
   end
   return m
end

function mat4:add(B)
   local C = mat4()
   for i = 1, 4 do
      for j = 1, 4 do
         C.m[i][j] = self.m[i][j] + B.m[i][j]
      end
   end
   return C
end

function mat4:multv(v)
   -- A v = u
   local u = vec3d(
      v.x*self.m[1][1] + v.y*self.m[1][2] + v.z*self.m[1][3] + self.m[1][4],
      v.x*self.m[2][1] + v.y*self.m[2][2] + v.z*self.m[2][3] + self.m[2][4],
      v.x*self.m[3][1] + v.y*self.m[3][2] + v.z*self.m[3][3] + self.m[3][4]
   )
   -- fourth element, w
   local w = v.x * self.m[4][1] + v.y*self.m[4][2] + v.z*self.m[4][3] + self.m[4][4]
   if w ~= 0 then
      u.x = u.x / w
      u.y = u.y / w
      u.z = u.z / w
   end
   return u
end

function mat4:multm(m)
   local M = mat4()
   for i = 1, 4 do
      for j = 1, 4 do
         for k = 1, 4 do
            M.m[i][j] += self.m[i][k] * m.m[k][j]
         end
      end
   end
   return M
end

function mat4.identity_matrix()
   local m = mat4()
   m:set(1, 1, 1)
   m:set(2, 2, 1)
   m:set(3, 3, 1)
   m:set(4, 4, 1)
   return m
end

function mat4.translation_matrix(dx, dy, dz)
   local m = mat4.identity_matrix()
   m:set(1, 4, dx)
   m:set(2, 4, dy)
   m:set(3, 4, dz)
   return m
end

function mat4.rotation_x_matrix(theta)
   local m = mat4()
   m:set(1, 1, 1)
   m:set(2, 2, cos(theta))
   m:set(2, 3, -sin(theta))
   m:set(3, 2, sin(theta))
   m:set(3, 3, cos(theta))
   m:set(4, 4, 1)
   return m
end

function mat4.rotation_y_matrix(theta)
   local m = mat4()
   m:set(1, 1, cos(theta))
   m:set(1, 3, sin(theta))
   m:set(2, 2, 1)
   m:set(3, 1, -sin(theta))
   m:set(3, 3, cos(theta))
   m:set(4, 4, 1)
   return m
end

function mat4.rotation_z_matrix(theta)
   local m = mat4()
   m:set(1, 1, cos(theta))
   m:set(1, 2, -sin(theta))
   m:set(2, 1, sin(theta))
   m:set(2, 2, cos(theta))
   m:set(3, 3, 1)
   m:set(4, 4, 1)
   return m
end

-- Defines a viewing frustum at a distance znear from the camera and
-- extending to zfar. The height and width of the frustum are determined
-- by the field of view.
---@param asp_ratio number width/height of the viewport
---@param fovrad number size of the field of view, in radians
---@param znear number distance to the near plane
---@param zfar number distance to the far plane
function mat4.perspective_matrix(asp_ratio, fovrad, znear, zfar)
   local m = mat4()
   local q = zfar / (zfar - znear)
   m:set(1, 1, asp_ratio * fovrad)
   m:set(2, 2, fovrad)
   m:set(3, 3, q)
   m:set(3, 4, -znear * q)
   m:set(4, 3, 1)
   return m
end

function mat4.orthographic_matrix(r, l, b, t, znear, zfar)
   local m = mat4()
   m:set(1, 1, 2/(r - l))
   m:set(1, 4, -(r + l)/(r - l))
   m:set(2, 2, 2/(b - t))
   m:set(2, 4, -(b + t)/(b - t))
   m:set(3, 3, 1 / (zfar - znear))
   m:set(3, 4, -znear/(zfar - znear))
   m:set(4, 4, 1)
   return m
end

function mat4.scaling_matrices(screen_width, screen_height)
   local m = mat4.identity_matrix()
   m:set(1, 4, 1)
   m:set(2, 4, 1)
   local n = mat4.identity_matrix()
   n:set(1, 1, 0.5 * screen_width)
   n:set(2, 2, 0.5 * screen_height)
   return m, n
end

-- Expresses the world's coordinates in terms of the camera's position
-- and viewing angle. Its inverse is the transform which shifts the world
-- such that the camera is positioned at the origin.
---@param eye vec3d position of camera in world space
---@param lookat vec3d position of camera target in world space
---@param up vec3d direction of 'up', typically {0, 1, 0}
function mat4.look_at_matrix(eye, lookat, up)
   local newlookat = lookat:subv(eye):normalize()
   local newup     = up:subv( newlookat:mult(newlookat:dot(up)) ):normalize()
   local newright  = newup:cross(newlookat)
   local m = mat4.translation_matrix(eye.x, eye.y, eye.z)
   m:set(1,1, newright.x)  ; m:set(1,2, newright.y)  ; m:set(1,3, newright.z)
   m:set(2,1, newup.x)     ; m:set(2,2, newup.y)     ; m:set(2,3, newup.z)
   m:set(3,1, newlookat.x) ; m:set(3,2, newlookat.y) ; m:set(3,3, newlookat.z)
   m:set(4,4, 1)
   return m:transpose()
end

function mat4.view_matrix(eye, lookat, up)
   return mat4.quick_inverse(mat4.look_at_matrix(eye, lookat, up))
end

function mat4.quick_inverse(m)
   local M = mat4()
   M.m[1][1] = m.m[1][1] ; M.m[1][2] = m.m[2][1] ; M.m[1][3] = m.m[3][1] ; M.m[1][4] = 0
   M.m[2][1] = m.m[1][2] ; M.m[2][2] = m.m[2][2] ; M.m[2][3] = m.m[3][2] ; M.m[2][4] = 0
   M.m[3][1] = m.m[1][3] ; M.m[3][2] = m.m[2][3] ; M.m[3][3] = m.m[3][3] ; M.m[3][4] = 0
   M.m[4][1] = -(m.m[4][1] * M.m[1][1] + m.m[4][2] * M.m[2][1] + m.m[4][3] * M.m[3][1])
   M.m[4][2] = -(m.m[4][1] * M.m[1][2] + m.m[4][2] * M.m[2][2] + m.m[4][3] * M.m[3][2])
   M.m[4][3] = -(m.m[4][1] * M.m[1][3] + m.m[4][2] * M.m[2][3] + m.m[4][3] * M.m[3][3])
   M.m[4][4] = 1
   return M:transpose()
end


