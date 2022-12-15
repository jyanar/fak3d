import "CoreLibs/object"

import "vector"

-----------------------------------
-----------------------------------
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

