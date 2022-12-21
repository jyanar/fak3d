class('Mesh').extends()


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

