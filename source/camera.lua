--
-- A simple camera class.
--

-- We could set up the class such that camera modifications are generally done
-- via changing the pos vector (to move it's place in the world) and the lookat
-- vector (i.e., that's what we apply rotation transformations to). We can define
-- a "recompute_up" method or something like that which we can call whenever we
-- update the lookat vector, which recomputes the up vector.
-- Note, recomputing the up vector would only be necessary if we allow the camera
-- to be moved off the horizontal.

import "CoreLibs/object"

import "vec3d"

class('camera').extends()

function camera:init(pos, lookat, up)
    self.pos = pos or vec3d(0, 0, -10)
    self.lookat = lookat or vec3d(0, 0, 1)
    self.up = up or vec3d(0, -1, 0)
end
