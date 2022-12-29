import "CoreLibs/object"

--
-- Linear algebra methods.
--

local cos <const> = math.cos
local sin <const> = math.sin

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Using the matrix.lua library
function vector3(x, y, z)
    return matrix{{x, y, z}}^'T'
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

class('Vector2').extends()

function Vector2:init(x, y)
    self.x = x or 0
    self.y = y or 0
end

function Vector2:tostring()
    return string.format('x: %f y: %f', self.x, self.y)
end

function Vector2:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2:normalize()
    local mag = self:magnitude()
    return Vector2(self.x / mag, self.y / mag)
end

function Vector2:mult(scalar)
    return Vector2(self.x * scalar, self.y * scalar)
end

function Vector2:dot(vec)
    return self.x * vec.x + self.y * vec.y
end

function Vector2:cross(vec)
    return Vector2(self.x * vec.y - self.y * vec.x)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

class('Vector3').extends()

function Vector3:init(x, y, z)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
end

function Vector3:tostring()
    return string.format('x: %f y: %f z: %f', self.x, self.y, self.z)
end

function Vector3:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector3:normalize()
    local mag = self:magnitude()
    return Vector3(self.x / mag, self.y / mag, self.z / mag)
end

function Vector3:mult(scalar)
    return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)
end

function Vector3:dot(vec)
    return self.x * vec.x + self.y * vec.y + self.z * vec.z
end

function Vector3:sub(vec)
    return Vector3(self.x - vec.x, self.y - vec.y, self.z - vec.z)
end

function Vector3:cross(vec)
    local x = self.y * vec.z - self.z * vec.y
    local y = (self.x * vec.z - self.z * vec.x) * -1
    local z = self.x * vec.y - self.y * vec.x
    return Vector3(x, y, z)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

class('Mat4x4').extends()

function Mat4x4:init()
    self.m = {}
    for irow = 1, 4 do
        self.m[irow] = {}
        for icol = 1, 4 do
            self.m[irow][icol] = 0
        end
    end
end

function Mat4x4:set(irow, icol, val)
    self.m[irow][icol] = val
end

function Mat4x4:tostring()
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

function Mat4x4:add(B)
    local C = Mat4x4()
    for i = 1, 4 do
        for j = 1, 4 do
            C.m[i][j] = self.m[i][j] + B.m[i][j]
        end
    end
    return C
end

function Mat4x4:mult(B)
    if B:isa(Vector3) then
        local u = Vector3(
            B.x * self.m[1][1] + B.y * self.m[2][1] + B.z * self.m[3][1] + self.m[4][1],
            B.x * self.m[1][2] + B.y * self.m[2][2] + B.z * self.m[3][2] + self.m[4][2],
            B.x * self.m[1][3] + B.y * self.m[2][3] + B.z * self.m[3][3] + self.m[4][3]
        )
        -- Fourth element, paddding on the Vec3
        local w = B.x * self.m[1][4] + B.y * self.m[2][4] + B.z * self.m[3][4] + self.m[4][4]
        if w ~= 0 then
            u.x = u.x / w
            u.y = u.y / w
            u.z = u.z / w
        end
        return u
    elseif B:isa(Mat4x4) then
        local M = Mat4x4()
        for i = 1, 4, 1 do
            for j = 1, 4, 1 do
                for k = 1, 4, 1 do
                    M.m[i][j] += self.m[i][k] * B.m[k][j]
                end
            end
        end
        return M
    end
end

function Mat4x4.identity_matrix()
    local m = Mat4x4()
    m:set(1, 1, 1)
    m:set(2, 2, 1)
    m:set(3, 3, 1)
    m:set(4, 4, 1)
    return m
end

function Mat4x4.translation_matrix(dx, dy, dz)
    local m = Mat4x4.identity_matrix()
    -- m:set(1, 4, dx)
    -- m:set(2, 4, dy)
    -- m:set(3, 4, dz)
    m:set(4, 1, dx)
    m:set(4, 2, dy)
    m:set(4, 3, dz)
    return m
end

function Mat4x4.rotation_x_matrix(theta)
    local m = Mat4x4()
    m:set(1, 1, 1)
    m:set(2, 2, cos(theta))
    m:set(2, 3, sin(theta))
    m:set(3, 2, -sin(theta))
    m:set(3, 3, cos(theta))
    m:set(4, 4, 1)
    return m
end

function Mat4x4.rotation_y_matrix(theta)
    local m = Mat4x4()
    m:set(1, 1, cos(theta))
    m:set(2, 2, 1)
    m:set(3, 3, cos(theta))
    m:set(4, 4, 1)
    m:set(1, 3, sin(theta))
    m:set(3, 1, -sin(theta))
    return m
end

function Mat4x4.rotation_z_matrix(theta)
    local m = Mat4x4()
    m:set(1, 1, cos(theta))
    m:set(1, 2, sin(theta))
    m:set(2, 1, -sin(theta))
    m:set(2, 2, cos(theta))
    m:set(3, 3, 1)
    m:set(4, 4, 1)
    return m
end

function Mat4x4.projection_matrix(asp_ratio, fovrad, znear, zfar)
    local m = Mat4x4()
    local q = zfar / (zfar - znear)
    m:set(1, 1, asp_ratio * fovrad)
    m:set(2, 2, fovrad)
    m:set(3, 3, q)
    m:set(4, 3, -1 * znear * q)
    m:set(3, 4, 1)
    return m
end

function Mat4x4.point_at_matrix(pos, target, up)
    -- New up direction
    local newforward = target:sub(pos):normalize()
    local a = newforward:mult(up:dot(newforward))
    local newup = up:sub(a):normalize()

    -- New right direction
    local newright = newup:cross(newforward)

    local m = Mat4x4()
    m:set(1,1, newright.x)   ; m:set(1,2, newright.y)   ; m:set(1,3, newright.z)
    m:set(2,1, newup.x)      ; m:set(2,2, newup.y)      ; m:set(1,3, newup.z)
    m:set(3,1, newforward.x) ; m:set(3,2, newforward.y) ; m:set(3,3, newforward.z)
    m:set(4,1, pos.x)        ; m:set(4,2, pos.y)        ; m:set(4,3, pos.z)
    m:set(4,4, 1)
    return m
end

function Mat4x4.quick_inverse(m)
    local M = Mat4x4()
    M.m[1][1] = m.m[1][1] ; M.m[1][2] = m.m[2][1] ; M.m[1][3] = m.m[3][1] ; M.m[1][4] = 0
    M.m[2][1] = m.m[1][2] ; M.m[2][2] = m.m[2][2] ; M.m[2][3] = m.m[3][2] ; M.m[2][4] = 0
    M.m[3][1] = m.m[1][3] ; M.m[3][2] = m.m[2][3] ; M.m[3][3] = m.m[3][3] ; M.m[3][4] = 0
    M.m[4][1] = -(m.m[4][1] * M.m[1][1] + m.m[4][2] * M.m[2][1] + m.m[4][3] * M.m[3][1])
    M.m[4][2] = -(m.m[4][1] * M.m[1][2] + m.m[4][2] * M.m[2][2] + m.m[4][3] * M.m[3][2])
    M.m[4][3] = -(m.m[4][1] * M.m[1][3] + m.m[4][2] * M.m[2][3] + m.m[4][3] * M.m[3][3])
    M.m[4][4] = 1
    return M
end


