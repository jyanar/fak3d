import "CoreLibs/graphics"

import "vector"
import "matrix"

local pd <const>  = playdate
local gfx <const> = playdate.graphics

local ASP_RATIO     = 200 / 400
local FOV           = 30
local FOVRAD        = 1 / math.tan(FOV * 0.5 / 180 * math.pi)
local ZFAR          = 10
local ZNEAR         = 1
local Q             = ZFAR / (ZFAR - ZNEAR)
local SCREEN_WIDTH  = 400
local SCREEN_HEIGHT = 200

-- Matrices
local mat_proj = Mat4x4()
local mat_rotx = Mat4x4()
local mat_rotz = Mat4x4()
local mat_roty = Mat4x4()

-- Variables
local cube = {}
local cube_proj = {}
local theta = 1

function init()
    -- Set up cube
    cube = {
        -- South
        { Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0) },
        { Vector3(0, 0, 0), Vector3(2, 2, 0), Vector3(2, 0, 0) },
        -- East
        { Vector3(2, 0, 0), Vector3(2, 2, 0), Vector3(2, 2, 2) },
        { Vector3(2, 0, 0), Vector3(2, 2, 2), Vector3(2, 0, 2) },
        -- North
        { Vector3(2, 0, 2), Vector3(2, 2, 2), Vector3(0, 2, 2) },
        { Vector3(2, 0, 2), Vector3(0, 2, 2), Vector3(0, 0, 2) },
        -- West
        { Vector3(0, 0, 2), Vector3(0, 2, 2), Vector3(0, 2, 0) },
        { Vector3(0, 0, 2), Vector3(0, 2, 0), Vector3(0, 0, 0) },
        -- Top
        { Vector3(0, 2, 0), Vector3(0, 2, 2), Vector3(2, 2, 2) },
        { Vector3(0, 2, 0), Vector3(2, 2, 2), Vector3(2, 2, 0) },
        -- Bottom
        { Vector3(2, 0, 2), Vector3(0, 0, 2), Vector3(0, 0, 0) },
        { Vector3(2, 0, 2), Vector3(0, 0, 0), Vector3(2, 0, 0) }
    }
    -- Set up cube projection
    cube_proj = {
        -- South
        { Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0) },
        { Vector3(0, 0, 0), Vector3(1, 1, 0), Vector3(1, 0, 0) },
        -- East
        { Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1) },
        { Vector3(1, 0, 0), Vector3(1, 1, 1), Vector3(1, 0, 1) },
        -- North
        { Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1) },
        { Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(0, 0, 1) },
        -- West
        { Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0) },
        { Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(0, 0, 0) },
        -- Top
        { Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1) },
        { Vector3(0, 1, 0), Vector3(1, 1, 1), Vector3(1, 1, 0) },
        -- Bottom
        { Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 0) },
        { Vector3(1, 0, 1), Vector3(0, 0, 0), Vector3(1, 0, 0) }
    }

    -- Set up matrices
    mat_proj:set(1, 1, ASP_RATIO * FOVRAD)
    mat_proj:set(2, 2, FOVRAD)
    mat_proj:set(3, 3, Q)
    mat_proj:set(4, 3, -1 * ZNEAR * Q)
    mat_proj:set(3, 4, 1)

    -- First, let's add a bit of translation into the z-axis
    for idx, _ in ipairs(cube) do
        cube[idx][1].x += -1
        cube[idx][2].x += -1
        cube[idx][3].x += -1
    end
end


init()

function playdate.update()

    gfx.clear(gfx.kColorWhite)

    -- Update matrix with latest theta
    mat_rotx:set(1, 1, 1)
    mat_rotx:set(2, 2, math.cos(theta))
    mat_rotx:set(2, 3, math.sin(theta))
    mat_rotx:set(3, 2, -math.sin(theta))
    mat_rotx:set(3, 3, math.cos(theta))
    mat_rotx:set(4, 4, 1)

    mat_rotz:set(1, 1, math.cos(theta))
    mat_rotz:set(1, 2, math.sin(theta))
    mat_rotz:set(2, 1, -math.sin(theta))
    mat_rotz:set(2, 2, math.cos(theta))
    mat_rotz:set(3, 3, 1)
    mat_rotz:set(4, 4, 1)

    theta += 1 / 30

    -- Project the triangles onto the screen.
    for idx, _ in ipairs(cube_proj) do
        -- -- Now let's rotate the cube around the z and x axis!
        cube_proj[idx][1] = mat_rotz:multvec3_pre(cube[idx][1])
        cube_proj[idx][2] = mat_rotz:multvec3_pre(cube[idx][2])
        cube_proj[idx][3] = mat_rotz:multvec3_pre(cube[idx][3])
        cube_proj[idx][1] = mat_rotx:multvec3_pre(cube_proj[idx][1])
        cube_proj[idx][2] = mat_rotx:multvec3_pre(cube_proj[idx][2])
        cube_proj[idx][3] = mat_rotx:multvec3_pre(cube_proj[idx][3])

        -- Offset into the screen
        cube_proj[idx][1].z += 10
        cube_proj[idx][2].z += 10
        cube_proj[idx][3].z += 10

        -- Project onto the screen
        cube_proj[idx][1] = mat_proj:multvec3_pre(cube_proj[idx][1])
        cube_proj[idx][2] = mat_proj:multvec3_pre(cube_proj[idx][2])
        cube_proj[idx][3] = mat_proj:multvec3_pre(cube_proj[idx][3])

        -- Scale into view
        cube_proj[idx][1].x += 1
        cube_proj[idx][1].y += 1
        cube_proj[idx][2].x += 1
        cube_proj[idx][2].y += 1
        cube_proj[idx][3].x += 1
        cube_proj[idx][3].y += 1

        cube_proj[idx][1].x *= 0.5 * SCREEN_WIDTH
        cube_proj[idx][1].y *= 0.5 * SCREEN_HEIGHT
        cube_proj[idx][2].x *= 0.5 * SCREEN_WIDTH
        cube_proj[idx][2].y *= 0.5 * SCREEN_HEIGHT
        cube_proj[idx][3].x *= 0.5 * SCREEN_WIDTH
        cube_proj[idx][3].y *= 0.5 * SCREEN_HEIGHT

        -- And draw!
        gfx.drawPolygon(
            cube_proj[idx][1].x, cube_proj[idx][1].y,
            cube_proj[idx][2].x, cube_proj[idx][2].y,
            cube_proj[idx][3].x, cube_proj[idx][3].y
        )
    end

    pd.drawFPS(10, 10)
end
