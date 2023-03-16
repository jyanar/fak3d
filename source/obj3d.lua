--
-- A 3D object, with its own mesh data and associated model transform.
--

import "CoreLibs/object"

class('obj3d').extends()

function obj3d:init(filepath, mat_model_fn, mat_model)
    self.filepath = filepath
    self.mat_model_fn = mat_model_fn
    self.mat_model = mat_model or mat4.identity_matrix()
    self.mesh = utils.readobj(filepath)
end
