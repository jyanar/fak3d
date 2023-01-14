-- Various utility functions

-- Pretty-print a table
function tprint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

-- From the Noble engine
function approach(value, target, step)
    if value == target then
        return value, true
    end
    local d = target - value
    if d > 0 then
        value = value + step
        if value >= target then
            return target, true
        else
            return value, false
        end
    elseif d < 0 then
        value = value - step
        if value <= target then
            return target, true
        else
            return value, false
        end
    else
        return value, true
    end
end

function distanceBetween(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end

function round(x, n)
    n = 10 ^ (n or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end

function rad2deg(rad)
    return (rad * 180)/math.pi
end

function deg2rad(deg)
    return (deg * math.pi)/180
end

-- binary string to number
local function b(e)
    return tonumber(e, 2)
end

PATTERN_DIAG_LINES = { --  diagonal lines
    b('11110000'),
    b('11100001'),
    b('11000011'),
    b('10000111'),
    b('00001111'),
    b('00011110'),
    b('00111100'),
    b('01111000'),
}

PATTERN_VERTICAL_LINES = {
    b('11100011'),
    b('11100011'),
    b('11100011'),
    b('11100011'),
    b('11100011'),
    b('11100011'),
    b('11100011'),
    b('11100011'),
}
