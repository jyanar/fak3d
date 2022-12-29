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
-- local LIGHT_DIR     = Vector3(0, 0, -1) -- Light faces us
-- local LIGHT_DIR     = Vector3(0, 0, 1)  -- Light faces away from us
-- local LIGHT_DIR     = Vector3(0, 1, 0)  -- Top down
local LIGHT_DIR     = Vector3(-0.5, 0.8, 0) -- Top down, to the right, to the front
local DRAWWIREFRAME = true
local FILENAME      = 'assets/icosahedron.obj'

-- Matrices
local mat_proj = Mat4x4.projection_matrix(ASP_RATIO, FOVRAD, ZNEAR, ZFAR)
local mat_addonexy, mat_scale = Mat4x4.scaling_matrices(SCREEN_WIDTH, SCREEN_HEIGHT)

-- Variables
local mesh = {}
local mesh_proj = {}
local mesh_view = {}
local theta = 0
local camera = Vector3(0, 0, -1)
local yaw = 0
local vec_lookdir = Vector3(0, 0, 1)

local function apply(matrix, triangle)
    return {matrix:mult(triangle[1]), matrix:mult(triangle[2]), matrix:mult(triangle[3])}
end

local function drawtriangles(buffer, wireframe)
    for _, triangle in ipairs(buffer) do
        local d = triangle.lightnormaldot
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
        if wireframe then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawPolygon(
                triangle.verts[1].x, triangle.verts[1].y,
                triangle.verts[2].x, triangle.verts[2].y,
                triangle.verts[3].x, triangle.verts[3].y
            )
        end
    end
end

local function init()
    -- Let's read in the file
    mesh = ObjReader.read(FILENAME)

    -- Set up projection and view meshes
    for i = 1, #mesh, 1 do
        table.insert(mesh_proj, {})
        table.insert(mesh_view, {})
    end

    -- First, let's add a bit of translation into the z-axis
    local mtrans = Mat4x4.translation_matrix(1, 0, 0)
    for itri, _ in ipairs(mesh) do
        mesh[itri][1] = mtrans:mult(mesh[itri][1])
        mesh[itri][2] = mtrans:mult(mesh[itri][2])
        mesh[itri][3] = mtrans:mult(mesh[itri][3])
    end
end

init()

function playdate.update()

    gfx.clear(gfx.kColorWhite)

    -- User input
    if pd.buttonIsPressed(pd.kButtonUp) then
        camera.y -= 1
        print(camera.z)
    end
    if pd.buttonIsPressed(pd.kButtonDown) then
        camera.y += 1
        print(camera.z)
    end

    -- Generate updated rotation matrices
    local mat_rotx = Mat4x4.rotation_x_matrix(theta)
    local mat_roty = Mat4x4.rotation_y_matrix(theta)
    local mat_rotz = Mat4x4.rotation_z_matrix(theta)
    local mat_move = Mat4x4.translation_matrix(0, 0, 10)
    local mat_rot = mat_rotz:mult(mat_roty:mult(mat_rotx))

    -- Construct "point at" matrix for camera
    local vec_up = Vector3(0, 1, 0)
    local vec_target = Vector3(0, 0, 1)
    local mat_camrot = Mat4x4.rotation_y_matrix(yaw)
    vec_lookdir = mat_camrot:mult(vec_target)
    vec_target = camera:add(vec_lookdir)
    local mat_cam = Mat4x4.point_at_matrix(camera, vec_target, vec_up)
    local mat_view = Mat4x4.quick_inverse(mat_cam)

    local drawbuffer = {}

    -- Project the triangles onto the screen.
    for itri, _ in ipairs(mesh_proj) do
        -- Apply rotation and translation transforms
        mesh_proj[itri] = apply(mat_rot, mesh[itri])
        mesh_proj[itri] = apply(mat_move, mesh_proj[itri])

        -- Compute the normal of this triangle
        local a = mesh_proj[itri][2]:sub(mesh_proj[itri][1])
        local b = mesh_proj[itri][3]:sub(mesh_proj[itri][1])
        local n = a:cross(b)
        local d = n:dot(LIGHT_DIR)

        -- Convert from world space to view space
        mesh_view[itri] = apply(mat_view, mesh_proj[itri])

        -- Compute projection, 3D -> 2D
        mesh_view[itri] = apply(mat_proj, mesh_view[itri])

        -- Get ray from triangle to camera
        local vec_camray = mesh_proj[itri][1]:sub(camera)

        -- Only draw triangles whose normal's z component is facing towards us.
        -- if n.z < 0 then
        if vec_camray:dot(n) then
            -- Scale projection onto screen
            mesh_view[itri] = apply(mat_addonexy, mesh_view[itri])
            mesh_view[itri] = apply(mat_scale, mesh_view[itri])
            table.insert(drawbuffer, {verts = mesh_view[itri], lightnormaldot = d})
        end
    end

    -- sort the triangles based on z-depth
    table.sort(drawbuffer, function(a, b)
        local z1 = (a.verts[1].z + a.verts[2].z + a.verts[3].z)/3
        local z2 = (b.verts[1].z + b.verts[2].z + b.verts[3].z)/3
        return z1 > z2
    end)

    -- And draw! (only if the normal of the triangle faces us)
    drawtriangles(drawbuffer, DRAWWIREFRAME)

    pd.drawFPS(5, 5)
end

function playdate.cranked(change, acceleratedChange)
    theta += change/180
end


