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
-- local LIGHT_DIR     = vec3(0, 0, -1) -- Light faces us
-- local LIGHT_DIR     = vec3(0, 0, 1)  -- Light faces away from us
-- local LIGHT_DIR     = vec3(0, 1, 0)  -- Top down
local LIGHT_DIR     = vec3(-0.5, 0.8, 0) -- Top down, to the right, to the front
local DRAWWIREFRAME = true
local FILENAME      = 'assets/icosahedron.obj'

-- Matrices
local matrix_transform = {}
local mat_init = mat4.translation_matrix(0, 0, 0)
local mat_move = mat4.translation_matrix(0, 0, 0)
local mat_proj = mat4.projection_matrix(ASP_RATIO, FOVRAD, ZNEAR, ZFAR)
local mat_addonexy, mat_scale = mat4.scaling_matrices(SCREEN_WIDTH, SCREEN_HEIGHT)

-- Variables
local clear_screen = true
local mesh = {}
local mesh_proj = {}
local mesh_view = {}
local yaw = 0
local theta = 0
local camera = vec3(0, 0, -10)
local vec_lookdir = vec3(0, 0, 1)

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
    for itri, _ in ipairs(mesh) do
        mesh[itri] = apply(mat_init, mesh[itri])
    end
end

init()

function playdate.update()

    if clear_screen then
        gfx.clear(gfx.kColorWhite)
    end

    -- User input
    if pd.buttonIsPressed(pd.kButtonUp)    then camera.z += 0.3 end
    if pd.buttonIsPressed(pd.kButtonDown)  then camera.z -= 0.3 end
    -- if pd.buttonIsPressed(pd.kButtonLeft)  then camera.x += 0.3 end
    -- if pd.buttonIsPressed(pd.kButtonRight) then camera.x -= 0.3 end
    if pd.buttonIsPressed(pd.kButtonLeft)  then yaw -= 1 end
    if pd.buttonIsPressed(pd.kButtonRight) then yaw += 1 end
    if pd.buttonJustPressed(pd.kButtonA) then
        if clear_screen == true then
            clear_screen = false
        elseif clear_screen == false then
            clear_screen = true
        end
    end
    if pd.buttonJustPressed(pd.kButtonB) then
        -- mat_move = mat4.translation_matrix(0, 0, 3)
        mat_move:set(4, 3, mat_move.m[3][4] + 1)
    end

    -- Generate transformation matrices
    matrix_transform = mat4.identity_matrix()
    matrix_transform = matrix_transform:mult(
        mat4.rotation_z_matrix(theta):mult(
        mat4.translation_matrix(0, 0, 3):mult(
        mat4.rotation_y_matrix(theta/2):mult(
        mat4.translation_matrix(0, 0, -3)
    ))))

    -- Construct "point at" matrix for camera
    local vec_up = vec3(0, 1, 0)
    local vec_target = vec3(0, 0, 1)
    local mat_camrot = mat4.rotation_y_matrix(yaw)
    vec_lookdir = mat_camrot:mult(vec_target)
    vec_target = camera:add(vec_lookdir)
    local mat_cam = mat4.point_at_matrix(camera, vec_target, vec_up)
    local mat_view = mat4.quick_inverse(mat_cam)

    local drawbuffer = {}

    -- project triangles onto 2D plane
    for itri, _ in ipairs(mesh_proj) do
        -- Copy triangle
        mesh_proj[itri] = apply(mat4.identity_matrix(), mesh[itri])

        -- Apply all transforms
        mesh_proj[itri] = apply(matrix_transform, mesh_proj[itri])

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

        -- only add triangles to the draw buffer whose normal
        -- z component is facing the camera.
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


