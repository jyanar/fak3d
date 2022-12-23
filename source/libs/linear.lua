import "CoreLibs/object"

--
-- Linear algebra methods.
--

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

class('Vector2').extends()

function Vector2:init(x, y)
    self.x = x
    self.y = y

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
    self.x = x
    self.y = y
    self.z = z
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
    for i = 1, 4 do
        self.m[i] = {}
        for j = 1, 4 do
            self.m[i][j] = 0
        end
    end
end

function Mat4x4:set(i, j, val)
    self.m[i][j] = val
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

function Mat4x4:mult(B)
    M = Mat4x4()
    for i = 1, 4, 1 do
        for j = 1, 4, 1 do
            for k = 1, 4, 1 do
                M.m[i][j] += self.m[i][k] * B.m[k][j]
            end
        end
    end
    return M
end

function Mat4x4:multvec3_pre(v)
    local u = Vector3(
        v.x * self.m[1][1] + v.y * self.m[2][1] + v.z * self.m[3][1] + self.m[4][1],
        v.x * self.m[1][2] + v.y * self.m[2][2] + v.z * self.m[3][2] + self.m[4][2],
        v.x * self.m[1][3] + v.y * self.m[2][3] + v.z * self.m[3][3] + self.m[4][3]
    )
    -- Fourth element, paddding on the Vec3
    local w = v.x * self.m[1][4] + v.y * self.m[2][4] + v.z * self.m[3][4] + self.m[4][4]
    if w ~= 0 then
        u.x = u.x / w
        u.y = u.y / w
        u.z = u.z / w
    end
    return u
end
