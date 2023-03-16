--
-- Various utilities.
--

import "CoreLibs/graphics"

import "vec3d"
local lume = import "lume"

local pd <const> = playdate

local PI <const> = math.pi

class('utils').extends()

function utils.readobj(filepath)
   local vtable = {}
   local ftable = {}
   local mesh = {}
   local objfile = pd.file.open(filepath)
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
      local tri = { vec3d(p1[1], p1[2], p1[3]),
                    vec3d(p2[1], p2[2], p2[3]),
                    vec3d(p3[1], p3[2], p3[3]) }
      table.insert(mesh, tri)
   end
   return mesh
end

function utils.radians(degrees)
   return (degrees * PI)/180
end

function utils.degrees(radians)
   return (radians * 180)/PI
end

function utils.round(x, n)
   n = 10 ^ (n or 0)
   x = x * n
   if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
   return x / n
end

function utils.gfxplib(d)
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
end
