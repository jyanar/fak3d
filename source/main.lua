import "CoreLibs/graphics"

import "libs/utils"
import "libs/gfx"
import "libs/linear"
import "libs/gfxp"
local lume = import "libs/lume"

local pd <const>  = playdate
local gfx <const> = playdate.graphics
local gfxplib <const> = GFXP.lib
local cos <const> = math.cos
local sin <const> = math.sin

local ASP_RATIO     = 200 / 400
local FOV           = 30
local FOVRAD        = 1 / math.tan(FOV * 0.5 / 180 * math.pi)
local ZFAR          = 10
local ZNEAR         = 1
local Q             = ZFAR / (ZFAR - ZNEAR)
local SCREEN_WIDTH  = 400
local SCREEN_HEIGHT = 200
local CAMERA        = Vector3(0, 0, 1)
-- local LIGHT_DIR     = Vector3(0, 0, -1) -- Light faces us
-- local LIGHT_DIR     = Vector3(0, 0, 1)  -- Light faces away from us
-- local LIGHT_DIR     = Vector3(0, 1, 0)  -- Top down
local LIGHT_DIR     = Vector3(-0.5, 0.8, 0) -- Top down, to the right, to the front

-- Matrices
local mat_proj = Mat4x4()
local mat_rotx = Mat4x4()
local mat_rotz = Mat4x4()
local mat_roty = Mat4x4()

-- Variables
local mesh = {}
local mesh_proj = {}
local theta = 1

function init()
    -- Set up matrices
    mat_proj:set(1, 1, ASP_RATIO * FOVRAD)
    mat_proj:set(2, 2, FOVRAD)
    mat_proj:set(3, 3, Q)
    mat_proj:set(4, 3, -1 * ZNEAR * Q)
    mat_proj:set(3, 4, 1)

    -- Let's read in the file
    mesh = ObjReader.read('assets/dog_friend.obj')

    -- Set up mesh projection
    for i = 1, #mesh, 1 do
        table.insert(mesh_proj, {})
    end

    -- First, let's add a bit of translation into the z-axis
    for idx, _ in ipairs(mesh) do
        mesh[idx][1].x += 1
        mesh[idx][2].x += 1
        mesh[idx][3].x += 1
    end
end



init()

function playdate.update()

    gfx.clear(gfx.kColorWhite)

    -- Update matrix with latest theta
    mat_rotx:set(1, 1, 1)
    mat_rotx:set(2, 2, cos(theta))
    mat_rotx:set(2, 3, sin(theta))
    mat_rotx:set(3, 2, -sin(theta))
    mat_rotx:set(3, 3, cos(theta))
    mat_rotx:set(4, 4, 1)

    mat_rotz:set(1, 1, cos(theta * 0.5))
    mat_rotz:set(1, 2, sin(theta * 0.5))
    mat_rotz:set(2, 1, -sin(theta * 0.5))
    mat_rotz:set(2, 2, cos(theta * 0.5))
    mat_rotz:set(3, 3, 1)
    mat_rotz:set(4, 4, 1)

    mat_roty:set(1, 1, cos(theta))
    mat_roty:set(2, 2, 1)
    mat_roty:set(3, 3, cos(theta))
    mat_roty:set(4, 4, 1)
    mat_roty:set(1, 3, sin(theta))
    mat_roty:set(3, 1, -sin(theta))

    local mat_rot = mat_rotz:mult(mat_roty:mult(mat_rotx))
    -- local mat_rot = mat_roty

    -- Project the triangles onto the screen.
    for idx, _ in ipairs(mesh_proj) do
        -- Now let's rotate the mesh around the z and x axis!
        mesh_proj[idx][1] = mat_rot:multvec3_pre(mesh[idx][1])
        mesh_proj[idx][2] = mat_rot:multvec3_pre(mesh[idx][2])
        mesh_proj[idx][3] = mat_rot:multvec3_pre(mesh[idx][3])
        local a = mesh_proj[idx][2]:sub(mesh_proj[idx][1])
        local b = mesh_proj[idx][3]:sub(mesh_proj[idx][1])
        local n = a:cross(b)

        -- Offset into the screen
        mesh_proj[idx][1].z += 20
        mesh_proj[idx][2].z += 20
        mesh_proj[idx][3].z += 20

        -- Project onto the screen
        mesh_proj[idx][1] = mat_proj:multvec3_pre(mesh_proj[idx][1])
        mesh_proj[idx][2] = mat_proj:multvec3_pre(mesh_proj[idx][2])
        mesh_proj[idx][3] = mat_proj:multvec3_pre(mesh_proj[idx][3])

        -- Illumination
        local d = n:dot(LIGHT_DIR)

        if n.z < 0 then
            -- Scale into view
            mesh_proj[idx][1].x += 1 ; mesh_proj[idx][1].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[idx][1].y += 1 ; mesh_proj[idx][1].y *= 0.5 * SCREEN_HEIGHT
            mesh_proj[idx][2].x += 1 ; mesh_proj[idx][2].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[idx][2].y += 1 ; mesh_proj[idx][2].y *= 0.5 * SCREEN_HEIGHT
            mesh_proj[idx][3].x += 1 ; mesh_proj[idx][3].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[idx][3].y += 1 ; mesh_proj[idx][3].y *= 0.5 * SCREEN_HEIGHT

            -- And draw! (only if the normal of the triangle faces us)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawPolygon(
                mesh_proj[idx][1].x, mesh_proj[idx][1].y,
                mesh_proj[idx][2].x, mesh_proj[idx][2].y,
                mesh_proj[idx][3].x, mesh_proj[idx][3].y
            )
            if d > 0 then
                if d > 0 and d < 0.2 then
                    gfx.setPattern(gfxplib['lightgray'])
                end
                if d > 0.2 and d < 0.4 then
                    gfx.setPattern(gfxplib['gray-4'])
                end
                if d > 0.4 and d < 0.8 then
                    gfx.setPattern(gfxplib['darkgray'])
                end
                if d > 0.8 and d <= 1.0 then
                    gfx.setPattern(gfxplib['black'])
                end

                gfx.fillPolygon(
                    mesh_proj[idx][1].x, mesh_proj[idx][1].y,
                    mesh_proj[idx][2].x, mesh_proj[idx][2].y,
                    mesh_proj[idx][3].x, mesh_proj[idx][3].y
                )
            end
        end
    end

    pd.drawFPS(10, 10)
end

function playdate.cranked(change, acceleratedChange)
    theta += change/180
end

function playdate.upButtonDown()
    FOV += 1
    FOVRAD = 1 / math.tan(FOV * 0.5 / 180 * math.pi)
    mat_proj:set(1, 1, ASP_RATIO * FOVRAD)
    mat_proj:set(2, 2, FOVRAD)
end

function playdate.downButtonDown()
    FOV -= 1
    FOVRAD = 1 / math.tan(FOV * 0.5 / 180 * math.pi)
    mat_proj:set(1, 1, ASP_RATIO * FOVRAD)
    mat_proj:set(2, 2, FOVRAD)
end