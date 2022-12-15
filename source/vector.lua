import "CoreLibs/object"

-----------------------------------
class('Vector2').extends()

function Vector2:init(x, y)
    self.x = x
    self.y = y

end

function Vector2:tostring()
    return string.format('x: %f y: %f', self.x, self.y)
end

function Vector2:magnitude()
    return math.sqrt(self.x*self.x + self.y*self.y)
end

function Vector2:normalize()
    local mag = self:magnitude()
    return Vector2(self.x/mag, self.y/mag)
end

function Vector2:mult(scalar)
    return Vector2(self.x * scalar, self.y * scalar)
end

function Vector2:dot(vec)
    return self.x * vec.x + self.y * vec.y
end

function Vector2:cross(vec)
    return Vector2(self.x * vec.y - self.y * vec.x)
end

-----------------------------------

class('Vector3').extends()

function Vector3:init(x, y, z)
    self.x = x
    self.y = y
    self.z = z
end

function Vector3:tostring()
    return string.format('x: %f y: %f z: %f', self.x, self.y, self.z)
end

function Vector3:magnitude()
    return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end

function Vector3:normalize()
    local mag = self:magnitude()
    return Vector3(self.x/mag, self.y/mag, self.z/mag)
end

function Vector3:mult(scalar)
    return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)
end

function Vector3:dot(vec)
    return self.x * vec.x + self.y * vec.y + self.z * vec.z
end

function Vector3:sub(vec)
    return Vector3(self.x - vec.x, self.y - vec.y, self.z - vec.z)
end

function Vector3:cross(vec)
    local x =  self.y*vec.z - self.z*vec.y
    local y = (self.x*vec.z - self.z*vec.x) * -1
    local z =  self.x*vec.y - self.y*vec.x
    return Vector3(x, y, z)
end
