local vectors = require(G3D_PATH .. "/vectors")

----------------------------------------------------------------------------------------------------
-- matrix class
----------------------------------------------------------------------------------------------------
-- matrices are just 16 numbers in table, representing a 4x4 matrix
-- an identity matrix is defined as {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}

local matrix = {}
matrix.__index = matrix

local function newMatrix()
    local self = setmetatable({}, matrix)
    self:identity()
    return self
end

function matrix:identity()
    self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
    self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
    self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function matrix:getValueAt(x,y)
    return self[x + (y-1)*4]
end

-- multiply this matrix and another matrix together
-- this matrix becomes the result of the multiplication operation
local orig = newMatrix()
function matrix:multiply(other)
    for i=1, 16 do
        orig[i] = self[i]
    end

    local i = 1
    for y=1, 4 do
        for x=1, 4 do
            self[i] = orig:getValueAt(1,y)*other:getValueAt(x,1)
            self[i] = self[i] + orig:getValueAt(2,y)*other:getValueAt(x,2)
            self[i] = self[i] + orig:getValueAt(3,y)*other:getValueAt(x,3)
            self[i] = self[i] + orig:getValueAt(4,y)*other:getValueAt(x,4)
            i = i + 1
        end
    end
end

function matrix:__tostring()
    local str = ""

    for i=1, 16 do
        str = str .. self[i]

        if i%4 == 0 and i > 1 then
            str = str .. "\n"
        else
            str = str .. ", "
        end
    end

    return str
end

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader


-- returns a transformation matrix
-- translation and rotation are 3d vectors
local rx = newMatrix()
local ry = newMatrix()
local rz = newMatrix()
local sm = newMatrix()
function matrix:setTransformationMatrix(translation, rotation, scale)
    self:identity()

    -- translations
    self[4] = translation[1]
    self[8] = translation[2]
    self[12] = translation[3]

    -- rotations
    -- x
    rx:identity()
    rx[6] = math.cos(rotation[1])
    rx[7] = -1*math.sin(rotation[1])
    rx[10] = math.sin(rotation[1])
    rx[11] = math.cos(rotation[1])
    self:multiply(rx)

    -- y
    ry:identity()
    ry[1] = math.cos(rotation[2])
    ry[3] = math.sin(rotation[2])
    ry[9] = -1*math.sin(rotation[2])
    ry[11] = math.cos(rotation[2])
    self:multiply(ry)

    -- z
    rz:identity()
    rz[1] = math.cos(rotation[3])
    rz[2] = -1*math.sin(rotation[3])
    rz[5] = math.sin(rotation[3])
    rz[6] = math.cos(rotation[3])
    self:multiply(rz)

    -- scale
    sm:identity()
    sm[1] = scale[1]
    sm[6] = scale[2]
    sm[11] = scale[3]
    self:multiply(sm)

    return self
end

-- returns a standard projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setProjectionMatrix(fov, near, far, aspectRatio)
    local top = near * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2*near/(right-left), 0, (right+left)/(right-left), 0
    self[5],  self[6],  self[7],  self[8]  = 0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0
    self[9],  self[10], self[11], self[12] = 0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, -1, 0
end

-- returns an orthographic projection matrix
-- (things farther away are the same size as things closer)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setOrthographicMatrix(fov, size, near, far, aspectRatio)
    local top = size * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2/(right-left), 0, 0, -1*(right+left)/(right-left)
    self[5],  self[6],  self[7],  self[8]  = 0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom)
    self[9],  self[10], self[11], self[12] = 0, 0, -2/(far-near), -(far+near)/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

local function fastCrossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

local function fastDotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

local function fastNormalize(x,y,z)
    local mag = math.sqrt(x^2 + y^2 + z^2)
    return x/mag, y/mag, z/mag
end

-- returns a view matrix
-- eye, target, and down are all 3d vectors
function matrix:setViewMatrix(eye, target, down)
    local z_1, z_2, z_3 = fastNormalize(eye[1] - target[1], eye[2] - target[2], eye[3] - target[3])
    local x_1, x_2, x_3 = fastNormalize(fastCrossProduct(down[1], down[2], down[3], z_1, z_2, z_3))
    local y_1, y_2, y_3 = fastCrossProduct(z_1, z_2, z_3, x_1, x_2, x_3)

    self[1],  self[2],  self[3],  self[4]  = x_1, x_2, x_3, -1*fastDotProduct(x_1, x_2, x_3, eye[1], eye[2], eye[3])
    self[5],  self[6],  self[7],  self[8]  = y_1, y_2, y_3, -1*fastDotProduct(y_1, y_2, y_3, eye[1], eye[2], eye[3])
    self[9],  self[10], self[11], self[12] = z_1, z_2, z_3, -1*fastDotProduct(z_1, z_2, z_3, eye[1], eye[2], eye[3])
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

return newMatrix
