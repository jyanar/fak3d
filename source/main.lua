import "CoreLibs/graphics"

import "libs/utils"
import "libs/mesh"
import "libs/linear"
import "libs/gfxp"

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
local DRAWWIREFRAME = true
local FILENAME      = 'assets/dog_friend.obj'

-- Matrices
local mat_proj = Mat4x4.projection_matrix(ASP_RATIO, FOVRAD, ZNEAR, ZFAR)

-- Variables
local mesh = {}
local mesh_proj = {}
local theta = 0

function init()
    -- Let's read in the file
    mesh = ObjReader.read(FILENAME)

    -- Set up mesh projection
    for i = 1, #mesh, 1 do
        table.insert(mesh_proj, {})
    end

    -- First, let's add a bit of translation into the z-axis
    local mtrans = Mat4x4.translation_matrix(1, 5, 0)
    for itri, _ in ipairs(mesh) do
        mesh[itri][1] = mtrans:mult(mesh[itri][1])
        mesh[itri][2] = mtrans:mult(mesh[itri][2])
        mesh[itri][3] = mtrans:mult(mesh[itri][3])
    end
end


init()

function playdate.update()

    gfx.clear(gfx.kColorWhite)

    -- Generate updated rotation matrices
    local mat_rotx = Mat4x4.rotation_x_matrix(theta)
    local mat_roty = Mat4x4.rotation_y_matrix(theta)
    local mat_rotz = Mat4x4.rotation_z_matrix(theta)
    local mat_trans = Mat4x4.translation_matrix(0, 0, 20)
    local mat_rot = mat_rotz:mult(mat_roty:mult(mat_rotx))

    local drawbuffer = {}

    -- Project the triangles onto the screen.
    for itri, _ in ipairs(mesh_proj) do
        -- Apply transformation matrix (rotation & translation)
        mesh_proj[itri][1] = mat_rot:mult(mesh[itri][1])
        mesh_proj[itri][2] = mat_rot:mult(mesh[itri][2])
        mesh_proj[itri][3] = mat_rot:mult(mesh[itri][3])
        -- Apply translation
        mesh_proj[itri][1] = mat_trans:mult(mesh_proj[itri][1])
        mesh_proj[itri][2] = mat_trans:mult(mesh_proj[itri][2])
        mesh_proj[itri][3] = mat_trans:mult(mesh_proj[itri][3])
       -- Compute the normal of this triangle
        local a = mesh_proj[itri][2]:sub(mesh_proj[itri][1])
        local b = mesh_proj[itri][3]:sub(mesh_proj[itri][1])
        local n = a:cross(b)
        local d = n:dot(LIGHT_DIR)

        -- Compute projection onto the screen
        mesh_proj[itri][1] = mat_proj:mult(mesh_proj[itri][1])
        mesh_proj[itri][2] = mat_proj:mult(mesh_proj[itri][2])
        mesh_proj[itri][3] = mat_proj:mult(mesh_proj[itri][3])

        -- Only draw triangles whose normal's z component is facing towards us.
        if n.z < 0 then
            -- Scale into view
            mesh_proj[itri][1].x += 1 ; mesh_proj[itri][1].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[itri][1].y += 1 ; mesh_proj[itri][1].y *= 0.5 * SCREEN_HEIGHT
            mesh_proj[itri][2].x += 1 ; mesh_proj[itri][2].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[itri][2].y += 1 ; mesh_proj[itri][2].y *= 0.5 * SCREEN_HEIGHT
            mesh_proj[itri][3].x += 1 ; mesh_proj[itri][3].x *= 0.5 * SCREEN_WIDTH
            mesh_proj[itri][3].y += 1 ; mesh_proj[itri][3].y *= 0.5 * SCREEN_HEIGHT

            table.insert(drawbuffer, {verts = mesh_proj[itri], lightnormaldot = d})
        end
    end

    -- -- sort the triangles based on z-depth
    table.sort(drawbuffer, function(a, b)
        local z1 = (a.verts[1].z + a.verts[2].z + a.verts[3].z)/3
        local z2 = (b.verts[1].z + b.verts[2].z + b.verts[3].z)/3
        return z1 > z2
    end)

    -- And draw! (only if the normal of the triangle faces us)
    for _, triangle in ipairs(drawbuffer) do
        local d = triangle.lightnormaldot
        -- if d > 0 then
        if d < 0 then
            gfx.setPattern(gfxplib['white'])
        end
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
            triangle.verts[1].x, triangle.verts[1].y,
            triangle.verts[2].x, triangle.verts[2].y,
            triangle.verts[3].x, triangle.verts[3].y
        )
        if DRAWWIREFRAME then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawPolygon(
                triangle.verts[1].x, triangle.verts[1].y,
                triangle.verts[2].x, triangle.verts[2].y,
                triangle.verts[3].x, triangle.verts[3].y
            )
        end
    end

    pd.drawFPS(5, 5)
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

