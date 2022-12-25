import "linear"
local lume = import "lume"

local pd <const> = playdate

class('Triangle').extends()
class('Mesh').extends()
class('ObjReader').extends()

function Triangle:init(p1, p2, p3, normal)
    self.p1 = p1
    self.p2 = p2
    self.p3 = p3
    self.normal = normal
end

function Triangle:setp1(p1)
    self.p1 = p1
end


function Triangle:setnormal(normal)
    self.normal = normal
end

function Triangle:vertices()
    return { self.p1, self.p2, self.p3 }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function Mesh:init()
    self.tris = {}
end

function Mesh:addtriangle(tri)
    table.insert(self.tris, tri)
end

function Mesh:addtriangles(triangles)
    for idx, val in ipairs(triangles) do
        table.insert(self.tris, val)
    end
end

function Mesh:triangles()
    return self.tris
end

function Mesh:readobjfile(fname)
    local vtable = {}
    local ftable = {}
    local mesh = {}

    local objfile = pd.file.open(fname)
    local file_not_read = true
    while file_not_read do
        local line = objfile:readline()
        if line ~= nil then
            local words = lume.split(line, ' ')
            -- print(words[1]) ; print(words[2]) ; print(words[3]) ; print(words[4])
            if words[1] == 'v' then
                table.insert(vtable, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
            elseif words[1] == 'f' then
                table.insert(ftable, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
            end
        else
            file_not_read = false
        end
    end
    -- Now insert all the triangles!
    for idx, face in ipairs(ftable) do
        local p1 = vtable[face[1]]
        local p2 = vtable[face[2]]
        local p3 = vtable[face[3]]
        local tri = { Vector3(p1[1], p1[2], p3[3]),
                      Vector3(p2[1], p2[2], p3[3]),
                      Vector3(p3[1], p3[2], p3[3]) }
        table.insert(self.tris, tri)
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function ObjReader:init(fname)
    self.fname = fname
end

function ObjReader.read(fname)
    local vtable = {}
    local ftable = {}
    local mesh = {}
    local objfile = pd.file.open(fname)
    local file_not_read = true
    while file_not_read do
        local line = objfile:readline()
        if line ~= nil then
            local words = lume.split(line, ' ')
            -- print(words[1]) ; print(words[2]) ; print(words[3]) ; print(words[4])
            if words[1] == 'v' then
                table.insert(vtable, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
            elseif words[1] == 'f' then
                table.insert(ftable, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
            end
        else
            file_not_read = false
        end
    end
    -- Now insert all the triangles!
    for idx, face in ipairs(ftable) do
        local p1 = vtable[face[1]]
        local p2 = vtable[face[2]]
        local p3 = vtable[face[3]]
        local tri = { Vector3(p1[1], p1[2], p1[3]),
                      Vector3(p2[1], p2[2], p2[3]),
                      Vector3(p3[1], p3[2], p3[3]) }
        table.insert(mesh, tri)
    end
    return mesh
end


