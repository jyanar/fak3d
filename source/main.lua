import "CoreLibs/graphics"

import "utils"

local pd <const>  = playdate
local gfx <const> = playdate.graphics

local SPEED = 5

local center = {x = 200, y = 120}
local spheres = {}

function overlaps(sphere, set)
    local function distanceBetween(a, b)
        return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
    end
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

function generateSpheres(n)
    spheres = {}
    for i = 1, n, 1 do
        local r = math.random(10, 20)
        local x, y, z = math.random(20, 380), math.random(20, 180), math.random(2, 30)
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

function worldtoscreen(x, y, z)
    screenx = x
    screeny = y
    return screenx, screeny
end

function drawSphere(x, y, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(x, y, r+1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, r)
end

function drawSphereShadow(x, y, z, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y + z, r+1)
end

function drawSpheres()
    table.sort(spheres, function (a, b) return a.y+a.z+a.r < b.y+b.z+b.r end)
    for _, c in ipairs(spheres) do
        drawSphereShadow(c.x, c.y, c.z, c.r)
    end
    for _, c in ipairs(spheres) do
        drawSphere(c.x, c.y, c.r)
    end
end

-- local camera = {x = 200, y = 120, z = 50, pitch = 0, rotation = 0}
-- function drawSpheres(camera)
--     -- We are going to compute the 2D projection of the 3D scene onto the camera
--     -- (i.e., the screen).


-- end


function playdate.update()
    -- Initialize
    if #spheres == 0 then
        generateSpheres(30)
        drawSpheres()
    end
    -- Check for input
    movx = 0; movy = 0;
    if pd.buttonIsPressed(pd.kButtonUp)    then movy += SPEED end
    if pd.buttonIsPressed(pd.kButtonDown)  then movy -= SPEED end
    if pd.buttonIsPressed(pd.kButtonLeft)  then movx += SPEED end
    if pd.buttonIsPressed(pd.kButtonRight) then movx -= SPEED end
    -- Apply movement
    for i, _ in ipairs(spheres) do
        spheres[i].x += movx
        --spheres[i].x += movy
        -- For pitch, we need to rotate around the origin. Spheres that are
        -- closer to us will move up, whereas farther away will move down.
        -- This will result in all of them lining up.
        local distancefromcenter = spheres[i].y - center.y
        if distancefromcenter > 0 then
            spheres[i].y, _ = approach(spheres[i].y, center.y, math.abs(movy))
        elseif distancefromcenter < 0 then
            spheres[i].y, _ = approach(spheres[i].y, center.y, math.abs(movy))
        end
        -- if distancefromcenter > 0 then
        -- spheres[i].y = approach(spheres[i].y, center.y, math.abs(movy))
        -- elseif distancefromcenter < 0 then
        --     spheres[i].y = approach(center.y, spheres[i].y, movy)
        -- end
    end

    center.x += movx
    center.y += movy
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
    end
    -- Clear the screen, redraw
    gfx.clear(gfx.kColorWhite)
    drawSpheres()
end
