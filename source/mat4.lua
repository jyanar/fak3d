--
-- A 4x4 matrix class for 3D graphics.
--

import "CoreLibs/object"

local sin <const> = math.sin
local cos <const> = math.cos

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

function mat4:addm(B)
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
        v.x * self.m[1][1] + v.y * self.m[1][2] + v.z * self.m[1][3] + self.m[1][4],
        v.x * self.m[2][1] + v.y * self.m[2][2] + v.z * self.m[2][3] + self.m[2][4],
        v.x * self.m[3][1] + v.y * self.m[3][2] + v.z * self.m[3][3] + self.m[3][4]
    )
    -- fourth element, w
    local w = v.x * self.m[4][1] + v.y * self.m[4][2] + v.z * self.m[4][3] + self.m[4][4]
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

-- Rotation matrices -- note, theta is in radians

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

-- Defines a viewing frustum at a distance znear and extending to
-- distance zfar. The height and width of the frustum are determined
-- by the field of view.
---@param asp_ratio number width/height of the viewport
---@param inv_fovrad number 1/tan(FOV_RAD/2)
---@param znear number distance to the near plane
---@param zfar number distance to the far plane
function mat4.perspective_matrix(asp_ratio, inv_fovrad, znear, zfar)
    local m = mat4()
    local q = zfar / (zfar - znear)
    m:set(1, 1, asp_ratio * inv_fovrad)
    m:set(2, 2, inv_fovrad)
    m:set(3, 3, q)
    m:set(3, 4, -znear * q)
    m:set(4, 3, 1)
    return m
end

function mat4.orthographic_matrix(r, l, b, t, znear, zfar)
    r = r or 1
    l = l or -1
    b = b or 1
    t = t or -1
    znear = znear or 1
    zfar = zfar or 10
    local m = mat4()
    m:set(1, 1, 2 / (r - l))
    m:set(1, 4, -(r + l) / (r - l))
    m:set(2, 2, 2 / (b - t))
    m:set(2, 4, -(b + t) / (b - t))
    m:set(3, 3, 1 / (zfar - znear))
    m:set(3, 4, -znear / (zfar - znear))
    m:set(4, 4, 1)
    return m
end

-- Scale from normalized device coordinates (NDC) to screen
function mat4.scaling_matrix(screen_width, screen_height)
    local m = mat4.identity_matrix()
    m:set(1, 1, 0.5 * screen_width)
    m:set(1, 4, 0.5 * screen_width)
    m:set(2, 2, 0.5 * screen_height)
    m:set(2, 4, 0.5 * screen_height)
    return m
end

function mat4.shadow_projection_matrix(vec_light_pos)
    local m = mat4()
    m:set(1,1, vec_light_pos.y)
    m:set(1,2, -vec_light_pos.x)
    m:set(3,2, -vec_light_pos.z)
    m:set(3,3, vec_light_pos.y)
    m:set(4,2, -1)
    m:set(4,4, vec_light_pos.y)
    return m
end

-- Expresses the world's coordinates in terms of the camera's position
-- and viewing angle. Its inverse is the transform which shifts the world
-- such that the camera is positioned at the origin.
---@param eye vec3d position of camera in world space
---@param lookat vec3d position of camera target in world space
---@param up vec3d direction of 'up', typically {0, -1, 0}
function mat4.look_at_matrix(eye, lookat, up)
    local newlookat = lookat:subv(eye):normalize()
    local newup     = up:subv( newlookat:mult(newlookat:dot(up)) ):normalize()
    local newright  = newup:cross(newlookat)
    local m = mat4()
    m:set(1,1, newright.x); m:set(1,2, newup.x); m:set(1,3, newlookat.x)
    m:set(2,1, newright.y); m:set(2,2, newup.y); m:set(2,3, newlookat.y)
    m:set(3,1, newright.z); m:set(3,2, newup.z); m:set(3,3, newlookat.z)
    m:set(4,1, eye.x); m:set(4,2, eye.y); m:set(4,3, eye.z); -- translation
    m:set(4,4, 1)
    return m
end

-- Expresses the world's coordinates relative to the camera's position
-- and viewing angle. Callee should ensure lookat and up are normalized
-- when passed in.
---@param eye vec3d position of camera in world space
---@param lookat vec3d direction of camera look at direction in world space
---@param up vec3d direction of 'up', typically {0, -1, 0}
function mat4.view_matrix(eye, lookat, up)
    local right = up:cross(lookat)
    local m = mat4()
    m:set(1,1, right.x);  m:set(1,2, right.y);  m:set(1,3, right.z)
    m:set(2,1, up.x);     m:set(2,2, up.y);    m:set(2,3, up.z)
    m:set(3,1, lookat.x); m:set(3,2, lookat.y); m:set(3,3, lookat.z)
    m:set(1,4, eye.x)
    m:set(2,4, eye.y)
    m:set(3,4, eye.z)
    m:set(4,4, 1)
    return m
end

function mat4.inverse(matrix)
    A3434 = matrix.m[3][3]*matrix.m[4][4] - matrix.m[3][4]*matrix.m[4][3]
    A2434 = matrix.m[3][2]*matrix.m[4][4] - matrix.m[3][4]*matrix.m[4][2]
    A2334 = matrix.m[3][2]*matrix.m[4][3] - matrix.m[3][3]*matrix.m[4][2]
    A1434 = matrix.m[3][1]*matrix.m[4][4] - matrix.m[3][4]*matrix.m[4][1]
    A1334 = matrix.m[3][1]*matrix.m[4][3] - matrix.m[3][3]*matrix.m[4][1]
    A1234 = matrix.m[3][1]*matrix.m[4][2] - matrix.m[3][2]*matrix.m[4][1]
    A3424 = matrix.m[2][3]*matrix.m[4][4] - matrix.m[2][4]*matrix.m[4][3]
    A2424 = matrix.m[2][2]*matrix.m[4][4] - matrix.m[2][4]*matrix.m[4][2]
    A2324 = matrix.m[2][2]*matrix.m[4][3] - matrix.m[2][3]*matrix.m[4][2]
    A3423 = matrix.m[2][3]*matrix.m[3][4] - matrix.m[2][4]*matrix.m[3][3]
    A2423 = matrix.m[2][2]*matrix.m[3][4] - matrix.m[2][4]*matrix.m[3][2]
    A2323 = matrix.m[2][2]*matrix.m[3][3] - matrix.m[2][3]*matrix.m[3][2]
    A1424 = matrix.m[2][1]*matrix.m[4][4] - matrix.m[2][4]*matrix.m[4][1]
    A1324 = matrix.m[2][1]*matrix.m[4][3] - matrix.m[2][3]*matrix.m[4][1]
    A1423 = matrix.m[2][1]*matrix.m[3][4] - matrix.m[2][4]*matrix.m[3][1]
    A1323 = matrix.m[2][1]*matrix.m[3][3] - matrix.m[2][3]*matrix.m[3][1]
    A1224 = matrix.m[2][1]*matrix.m[4][2] - matrix.m[2][2]*matrix.m[4][1]
    A1223 = matrix.m[2][1]*matrix.m[3][2] - matrix.m[2][2]*matrix.m[3][1]

	det = matrix.m[1][1]*(matrix.m[2][2]*A3434-matrix.m[2][3]*A2434+matrix.m[2][4]*A2334) -
          matrix.m[1][2]*(matrix.m[2][1]*A3434-matrix.m[2][3]*A1434+matrix.m[2][4]*A1334) +
          matrix.m[1][3]*(matrix.m[2][1]*A2434-matrix.m[2][2]*A1434+matrix.m[2][4]*A1234) -
          matrix.m[1][4]*(matrix.m[2][1]*A2334-matrix.m[2][2]*A1334+matrix.m[2][3]*A1234)
    det = 1 / det

    m = mat4()
	m.m[1][1] = det *  (matrix.m[2][2]*A3434 - matrix.m[2][3]*A2434 + matrix.m[2][4]*A2334)
	m.m[1][2] = det * -(matrix.m[1][2]*A3434 - matrix.m[1][3]*A2434 + matrix.m[1][4]*A2334)
	m.m[1][3] = det *  (matrix.m[1][2]*A3424 - matrix.m[1][3]*A2424 + matrix.m[1][4]*A2324)
	m.m[1][4] = det * -(matrix.m[1][2]*A3423 - matrix.m[1][3]*A2423 + matrix.m[1][4]*A2323)
	m.m[2][1] = det * -(matrix.m[2][1]*A3434 - matrix.m[2][3]*A1434 + matrix.m[2][4]*A1334)
	m.m[2][2] = det *  (matrix.m[1][1]*A3434 - matrix.m[1][3]*A1434 + matrix.m[1][4]*A1334)
	m.m[2][3] = det * -(matrix.m[1][1]*A3424 - matrix.m[1][3]*A1424 + matrix.m[1][4]*A1324)
	m.m[2][4] = det *  (matrix.m[1][1]*A3423 - matrix.m[1][3]*A1423 + matrix.m[1][4]*A1323)
	m.m[3][1] = det *  (matrix.m[2][1]*A2434 - matrix.m[2][2]*A1434 + matrix.m[2][4]*A1234)
	m.m[3][2] = det * -(matrix.m[1][1]*A2434 - matrix.m[1][2]*A1434 + matrix.m[1][4]*A1234)
	m.m[3][3] = det *  (matrix.m[1][1]*A2424 - matrix.m[1][2]*A1424 + matrix.m[1][4]*A1224)
	m.m[3][4] = det * -(matrix.m[1][1]*A2423 - matrix.m[1][2]*A1423 + matrix.m[1][4]*A1223)
	m.m[4][1] = det * -(matrix.m[2][1]*A2334 - matrix.m[2][2]*A1334 + matrix.m[2][3]*A1234)
	m.m[4][2] = det *  (matrix.m[1][1]*A2334 - matrix.m[1][2]*A1334 + matrix.m[1][3]*A1234)
	m.m[4][3] = det * -(matrix.m[1][1]*A2324 - matrix.m[1][2]*A1324 + matrix.m[1][3]*A1224)
	m.m[4][4] = det *  (matrix.m[1][1]*A2323 - matrix.m[1][2]*A1323 + matrix.m[1][3]*A1223)

    return m
end
