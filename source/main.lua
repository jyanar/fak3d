import "CoreLibs/graphics"

import "mat4"
import "vec3d"
import "obj3d"
import "camera"
import "utils"
import "gfxp"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local gfxplib <const> = GFXP.lib

local SCREEN_WIDTH  = 400
local SCREEN_HEIGHT = 200
local ASPECT_RATIO  = SCREEN_HEIGHT/SCREEN_WIDTH
local FOVRAD        = utils.radians(30)
local INV_FOVRAD    = 1 / math.tan(FOVRAD / 2)
local ZFAR          = 100
local ZNEAR         = 0.1
-- local LIGHT_SRC     = vec3d(1, -10, 3)
-- local LIGHT_DIR     = vec3d(0.3, -1, 0.3):normalize()
local LIGHT_DIR     = vec3d(0, 1, 0)        -- down is positive y
local LIGHT_SRC     = vec3d(0, -10, 0)
local DRAWSHADOWS   = true
local FILLTRIANGLES = true
local DRAWWIREFRAME = true
local MESHFILE      = 'assets/icosahedron.obj'

local mesh = {}
local allobj = {} -- list of obj3ds to render

local mat_world = {}      -- transforms objects from .obj to world coordinates
local mat_view = {}       -- transforms objects to camera coordinates
local mat_vp = {}
local mat_projection = mat4.perspective_matrix(ASPECT_RATIO, INV_FOVRAD, ZNEAR, ZFAR)
local mat_scale = mat4.scaling_matrix(SCREEN_WIDTH, SCREEN_HEIGHT)
local mat_shadow_shrink = mat4.identity_matrix() ; mat_shadow_shrink:set(2,2, -0.1)

local camtheta = 0
local theta = 0
local cam_theta = 0

local vec_origin = vec3d(0, 0, -50)
local vec_camera = vec3d(0, 0, -50)
local vec_lookat = vec3d(0, 0, -1)
local vec_target = vec3d(0, 0, -1)
local vec_up     = vec3d(0, -1, 0)

local CRANKPOS = pd.getCrankPosition()
local RECOMPUTE = true

-------------------------------------------------------------------------------

local function apply(matrix, triangle)
   return { matrix:multv(triangle[1]),
            matrix:multv(triangle[2]),
            matrix:multv(triangle[3]),
            triangle[4],
          }
end

local function apply_mesh(matrix, mesh)
   local m = {}
   for itri = 1, #mesh do
      m[itri] = apply(matrix, mesh[itri])
   end
   return m
end

local function setpattern(d)
   d = d * 100
   if d <= 0 then
      gfx.setPattern(gfxplib['white'])
   end
   if d > 0 and d <= 0.25 then
      gfx.setPattern(gfxplib['lightgray'])
   end
   if d > 0.25 and d <= 0.5 then
      gfx.setPattern(gfxplib['gray-4'])
   end
   if d > 0.5 and d <= 0.75 then
      gfx.setPattern(gfxplib['darkgray'])
   end
   if d > 0.75 and d <= 1.0 then
      gfx.setPattern(gfxplib['black'])
   end
end

local function drawtriangles(buffer, wireframe, fill)
   for itri = 1, #buffer do
      if fill then
         setpattern(buffer[itri][4])
         gfx.fillPolygon(buffer[itri][1].x, buffer[itri][1].y,
                         buffer[itri][2].x, buffer[itri][2].y,
                         buffer[itri][3].x, buffer[itri][3].y)
      end
      if wireframe then
         gfx.setColor(gfx.kColorBlack)
         gfx.drawPolygon(buffer[itri][1].x, buffer[itri][1].y,
                         buffer[itri][2].x, buffer[itri][2].y,
                         buffer[itri][3].x, buffer[itri][3].y)
      end
   end
end

local function normal(triangle)
   local a = triangle[2]:subv(triangle[1])
   local b = triangle[3]:subv(triangle[1])
   return a:cross(b):normalize()
end

local function all_points_outside_frustum(triangle)
   if (triangle[1].z < 0 or triangle[1].z >= 1) and
      (triangle[2].z < 0 or triangle[2].z >= 1) and
      (triangle[3].z < 0 or triangle[3].z >= 1) then
      return true
   end
   return false
end

local function triangle_facing_away(triangle, camera)
   return normal(triangle):dot(camera) >= 0
end

local function getuserinput()
   local input = vec3d()
   if pd.buttonIsPressed(pd.kButtonUp) then input = input:addv(vec_lookat):mult(0.3) end
   if pd.buttonIsPressed(pd.kButtonDown) then input = input:subv(vec_lookat):mult(0.3) end
   if pd.buttonIsPressed(pd.kButtonRight) then input = input:addv(vec_up:cross(vec_lookat)):mult(0.3) end
   if pd.buttonIsPressed(pd.kButtonLeft) then input = input:addv(vec_up:cross(vec_lookat:mult(-1))):mult(0.3) end
   return input
end

function init()

   obj1 = obj3d(MESHFILE, function (theta) return mat4.translation_matrix(vec_origin.x, vec_origin.y, vec_origin.z):multm(
                                                  mat4.translation_matrix(0, 0, -10):multm(
                                                  mat4.rotation_y_matrix(theta):multm(
                                                  mat4.rotation_x_matrix(theta/2):multm(
                                                  mat4.rotation_z_matrix(theta/3))))) end)

   obj2 = obj3d(MESHFILE, function (theta) return mat4.translation_matrix(vec_origin.x, vec_origin.y, vec_origin.z):multm(
                                                  mat4.translation_matrix(5, 0, -10):multm(
                                                  mat4.rotation_x_matrix(theta))) end)

   obj3 = obj3d('assets/cube.obj', function (theta) return mat4.translation_matrix(vec_origin.x, vec_origin.y, vec_origin.z):multm(
                                                           mat4.translation_matrix(10, 0, -10):multm(
                                                           mat4.rotation_z_matrix(theta):multm(
                                                           mat4.rotation_x_matrix(theta/2)))) end)

   table.insert(allobj, obj1)
   table.insert(allobj, obj2)
   table.insert(allobj, obj3)

end

init()

function playdate.update()

   gfx.clear(gfx.kColorWhite)

   theta += 0.05

   ----------------------------------------------------
   -- Construct model, view, and projection matrices --
   ----------------------------------------------------

   -- Process dpad input
   local input = getuserinput()
   -- Did the user turn the crank?
   if CRANKPOS ~= pd.getCrankPosition() then
      CRANKPOS = pd.getCrankPosition()
      RECOMPUTE = true
   end

   if not input:isempty() or RECOMPUTE == true then
      vec_camera = vec_camera:addv(input)
      vec_lookat = mat4.rotation_y_matrix(utils.radians(-CRANKPOS)):multv(vec_target)
      mat_view = mat4.inverse(mat4.view_matrix(vec_camera, vec_lookat, vec_up))
      mat_vp = mat_projection:multm(mat_view)
      RECOMPUTE = false
      -- print('RECOMPUTED!!')
   end

   -------------------------------------
   -- Apply matrices to mesh and draw --
   -------------------------------------

   -- Apply object-specific matrices and add triangles to pool
   local alltriangles = {}
   for k,obj in pairs(allobj) do
      mesh = obj.mesh
      mesh = apply_mesh(obj.mat_model_fn(theta), mesh)
      for i,tri in ipairs(mesh) do
         table.insert(alltriangles, tri)
      end
   end

   -- Compute triangle shadows, and apply view/projection matrices
   if DRAWSHADOWS then
      -- mat_shadow = mat_shadow:multm(mat4.translation_matrix(0, 1, 0))
      -- local mat_shadow = mat4.shadow_projection_matrix(LIGHT_SRC)
      local mat_shadow = mat_scale:multm(
                           mat_projection:multm(
                              mat_view:multm(
                                 mat_shadow_shrink:multm(
                                    mat4.translation_matrix(0, 20, 0):multm(
                                       mat4.identity_matrix())))))
      local shadows = apply_mesh(mat_shadow, alltriangles)
      for itri, _ in ipairs(shadows) do
         shadows[itri][4] = 1.0 -- Set d to 1, max shading
      end

      -- Cull shadow triangles that lie outside viewing frustum
      for i = #shadows, 1, -1 do
         if all_points_outside_frustum(shadows[i]) or triangle_facing_away(shadows[i], vec_camera) then
            table.remove(shadows, i)
         end
      end
      drawtriangles(shadows, false, true)
   end

   alltriangles = apply_mesh(mat_vp, alltriangles)

   -- Sort model triangles by z depth
   table.sort(alltriangles, function(a, b)
      local z1 = (a[1].z + a[2].z + a[3].z) / 3
      local z2 = (b[1].z + b[2].z + b[3].z) / 3
      return z1 > z2
   end)

   -- Compute projection of triangle normals with light source
   if FILLTRIANGLES then
      for i = 1, #alltriangles do
         local n = normal(alltriangles[i])
         alltriangles[i][4] = n:dot(LIGHT_DIR)
      end
   end

   -- Cull triangles that are either occluded or lie outside the viewing frustum.
   for i = #alltriangles, 1, -1 do
      if all_points_outside_frustum(alltriangles[i]) or triangle_facing_away(alltriangles[i], vec_camera) then
         table.remove(alltriangles, i)
      end
   end

   alltriangles = apply_mesh(mat_scale, alltriangles)

   drawtriangles(alltriangles, DRAWWIREFRAME, FILLTRIANGLES)

   pd.drawFPS(5,5)

   gfx.drawText('theta: ' .. pd.getCrankPosition(), 20, 5)
   gfx.drawText('x: ' .. utils.round(vec_camera.x, 2), 5, 220)
   gfx.drawText('y: ' .. utils.round(vec_camera.y, 2), 70, 220)
   gfx.drawText('z: ' .. utils.round(vec_camera.z, 2), 120, 220)
end
