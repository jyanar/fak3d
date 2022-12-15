import "CoreLibs/graphics"

import "utils"
import "vector"

local pd <const>  = playdate
local gfx <const> = playdate.graphics

-- Constants
local SCREEN_WIDTH  = 400
local SCREEN_HEIGHT = 240
local SPEED = 5
local LO_X = -100
local HI_X = SCREEN_WIDTH + 100
local LO_Y = -100
local HI_Y = SCREEN_HEIGHT + 100
local CENTER = Vector2(200, 120, 0)

-- Vars
local center = {x = 200, y = 120, z = 0}
local spheres = {}

function overlaps(sphere, set)
    if #spheres == 0 then
        return false
    else
        for idx, sphere2 in ipairs(set) do
            if distanceBetween(sphere, sphere2) < sphere.r + sphere2.r then
                return true
            end
        end
        return false
    end
end

local toGround = Vector2(0, -1)

function generateSpheres(n)
    spheres = {}
    for i = 1, n, 1 do
        local r = math.random(10, 20)
        -- local x, y, z = math.random(20, 380), math.random(20, 180), math.random(2, 30)
        local x, y, z = math.random(LO_X, HI_X), math.random(LO_Y, HI_Y), math.random(2, 30)
        local sphere = {x = x, y = y, z = z, r = r}
        while overlaps(sphere, spheres) do
            r = math.random(10, 20)
            x, y, z = math.random(20, 380), math.random(20, 180), math.random(2, 40)
            sphere = {x = x, y = y, z = z, r = r}
        end
        table.insert(spheres, {r = r, x = x, y = y, z = z})
    end
    return spheres
end

function drawSphere(x, y, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(x, y, r+1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, r)
end

-- TODO rotate shadows with crank
function drawSphereShadow(x, y, z, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y - z, r+1)
end

function drawSphereShadow2(pos, toGround, r)
    gfx.setColor(gfx.kColorBlack)
    toGround = toGround:normalize():mult(pos.z)
    gfx.fillCircleAtPoint(pos.x + toGround.x, pos.y + toGround.y, r)
end

-- function drawSpheres()
--     table.sort(spheres, function (a, b) return a.y+a.z+a.r < b.y+b.z+b.r end)
--     for _, c in ipairs(spheres) do
--         drawSphereShadow(c.x, c.y, c.z, c.r)
--     end
--     for _, c in ipairs(spheres) do
--         drawSphere(c.x, c.y, c.r)
--     end
-- end

camera = {x = 200, y = 120, z = 50} -- for now, no pitch/rotation. let's always point to origin
nhat = Vector3(center.x - camera.x, center.y - camera.y, center.z - camera.z)
function drawSpheres()
    local spheresSP = {}
    -- We are going to compute the 2D projection of the 3D scene onto the camera
    -- (i.e., the screen). Let's point the camera to the origin.
    -- local to_origin = Vector3(center.x - camera.x, center.y - camera.y, center.z - camera.z)

    -- To start, let's compute the distance from the camera to each sphere.
    -- This determines the draw sorting.
    for i, _ in ipairs(spheres) do
        spheres[i].depth = distanceBetween(camera, spheres[i])
    end
    table.sort(spheres, function(a, b) return a.depth < b.depth end)

    -- spheresSP = spheres
    -- -- Now let's compute the location of these spheres relative to the camera.
    -- -- Note, there is space to either side of the camera: we'll display things up to
    -- -- SCREEN_WIDTH/2 on either side of the camera placement. Because the camera is
    -- -- always facing the center, we do not have to do anything. We would have to
    -- -- revisit this if we allowed for moving the camera further and closer.
    -- local origin = Vector3(camera.x, camera.y, camera.z)
    -- -- local nhat = to_origin:normalize()
    -- for _, s in ipairs(spheres) do
    --     local point = Vector3(s.x, s.y, s.z)
    --     local originToPoint = point:sub(origin)
    --     local distPlaneToPoint = originToPoint:dot(nhat)
    --     local normalProjection = nhat:mult(distPlaneToPoint)
    --     local planeProj = point:sub(normalProjection)
    --     table.insert(spheresSP, {x = planeProj.x, y = planeProj.y, z = planeProj.z, r = s.r})
    -- end

    for _, s in ipairs(spheres) do
        drawSphereShadow2(Vector3(s.x, s.y, s.z), toGround, s.r)
        -- drawSphereShadow(s.x, s.y, s.z, s.r)
    end

    for _, s in ipairs(spheres) do
        drawSphere(s.x, s.y, s.r)
    end
end

function getinput()
    local movx, movy = 0, 0;
    if pd.buttonIsPressed(pd.kButtonUp)    then movy += SPEED end
    if pd.buttonIsPressed(pd.kButtonDown)  then movy -= SPEED end
    if pd.buttonIsPressed(pd.kButtonLeft)  then movx += SPEED end
    if pd.buttonIsPressed(pd.kButtonRight) then movx -= SPEED end
    return movx, movy
end


function playdate.update()
    -- Initialize
    if #spheres == 0 then
        generateSpheres(30)
        drawSpheres()
    end

    -- Check for input
    local movx, movy = getinput()

    -- Apply movement
    for i, _ in ipairs(spheres) do
        spheres[i].x -= movx
        spheres[i].y -= movy
    end

    center.x -= movx
    center.y -= movy

    gfx.clear(gfx.kColorWhite)
    drawSpheres()

    gfx.sprite.update()
end

function playdate.cranked(change, acceleratedChange)
    change = change / 360
    -- Update all spheres
    for i, _ in ipairs(spheres) do
        -- Compute sphere positions relative to screen center
        local x = spheres[i].x - center.x
        local y = spheres[i].y - center.y
        -- Apply rotation
        spheres[i].x = x * math.cos(change) - y * math.sin(change)
        spheres[i].y = x * math.sin(change) + y * math.cos(change)
        -- Unapply coordinate transform
        spheres[i].x += center.x
        spheres[i].y += center.y

        -- Apply rotation to the toGround vector
        toGround.x = toGround.x * math.cos(change) - toGround.y * math.sin(change)
        toGround.y = toGround.x * math.sin(change) + toGround.y * math.cos(change)
    end
    -- Clear the screen, redraw
    gfx.clear(gfx.kColorWhite)
    drawSpheres()
end
