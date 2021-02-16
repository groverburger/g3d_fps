local g3d = require "g3d"
local vectors = require "g3d/vectors"

local primitives = {}
local circleTexture = love.graphics.newImage("assets/circle.png")

local lineModel = g3d.newModel({
    {-1,0,-1},
    {1, 0,-1},
    {-1,0, 1},
    {1, 0, 1},
    {1, 0,-1},
    {-1,0, 1},
})

function primitives.line(x1,y1,z1, x2,y2,z2)
    --local v_x,v_y,v_z = g3d.camera.getLookVector()
    local v_x = (x1+x2)/2 - g3d.camera.position[1]
    local v_y = (y1+y2)/2 - g3d.camera.position[2]
    local v_z = (z1+z2)/2 - g3d.camera.position[3]
    local t_x,t_y,t_z = vectors.normalize(x1-x2, y1-y2, z1-z2)
    local n_x,n_y,n_z = vectors.normalize(vectors.crossProduct(v_x,v_y,v_z, t_x,t_y,t_z))
    local r = 0.1
    n_x, n_y, n_z = n_x*r, n_y*r, n_z*r

    lineModel.mesh:setVertex(1, x1-n_x, y1-n_y, z1-n_z)
    lineModel.mesh:setVertex(2, x1+n_x, y1+n_y, z1+n_z)
    lineModel.mesh:setVertex(3, x2-n_x, y2-n_y, z2-n_z)
    lineModel.mesh:setVertex(4, x2-n_x, y2-n_y, z2-n_z)
    lineModel.mesh:setVertex(5, x2+n_x, y2+n_y, z2+n_z)
    lineModel.mesh:setVertex(6, x1+n_x, y1+n_y, z1+n_z)

    lineModel:draw()
end

local billboardModel = g3d.newModel({
    {-1,0,-1},
    {1, 0,-1},
    {-1,0, 1},
    {1, 0, 1},
    {1, 0,-1},
    {-1,0, 1},
}, circleTexture)

function primitives.axisBillboard(x,y,z, ax,ay,az)
    local v_x,v_y,v_z = g3d.camera.getLookVector()
    local t_x,t_y,t_z = vectors.normalize(ax,ay,az)
    local n_x,n_y,n_z = vectors.normalize(vectors.crossProduct(v_x,v_y,v_z, t_x,t_y,t_z))
    local x1,y1,z1 = x,y,z
    local x2,y2,z2 = x+t_x, y+t_y, z+t_z
    local r = 0.5
    n_x, n_y, n_z = n_x*r, n_y*r, n_z*r

    billboardModel.mesh:setVertex(1, x1-n_x, y1-n_y, z1-n_z, 0,0)
    billboardModel.mesh:setVertex(2, x1+n_x, y1+n_y, z1+n_z, 1,0)
    billboardModel.mesh:setVertex(3, x2-n_x, y2-n_y, z2-n_z, 0,1)
    billboardModel.mesh:setVertex(4, x2-n_x, y2-n_y, z2-n_z, 0,1)
    billboardModel.mesh:setVertex(5, x2+n_x, y2+n_y, z2+n_z, 1,1)
    billboardModel.mesh:setVertex(6, x1+n_x, y1+n_y, z1+n_z, 1,0)

    billboardModel:draw()
end

function primitives.fullBillboard(x,y,z, matrix)
    local matrix = matrix or g3d.camera.viewMatrix
    local x_1, x_2, x_3 = matrix[1], matrix[2], matrix[3]
    local y_1, y_2, y_3 = matrix[5], matrix[6], matrix[7]
    local x1,y1,z1 = x,y,z
    local x2,y2,z2 = x+y_1, y+y_2, z+y_3
    local r = 0.5
    n_x, n_y, n_z = x_1*r, x_2*r, x_3*r

    billboardModel.mesh:setVertex(1, x1-n_x, y1-n_y, z1-n_z, 0,0)
    billboardModel.mesh:setVertex(2, x1+n_x, y1+n_y, z1+n_z, 1,0)
    billboardModel.mesh:setVertex(3, x2-n_x, y2-n_y, z2-n_z, 0,1)
    billboardModel.mesh:setVertex(4, x2-n_x, y2-n_y, z2-n_z, 0,1)
    billboardModel.mesh:setVertex(5, x2+n_x, y2+n_y, z2+n_z, 1,1)
    billboardModel.mesh:setVertex(6, x1+n_x, y1+n_y, z1+n_z, 1,0)

    billboardModel:draw()
end

local circleModel = g3d.newModel({
    {-1,0,-1, 0,0},
    {1, 0,-1, 1,0},
    {-1,0, 1, 0,1},
    {1, 0, 1, 1,1},
    {1, 0,-1, 1,0},
    {-1,0, 1, 0,1},
}, circleTexture)

local translation = {}
local rotation = {}
local scale = {}
function primitives.circle(x,y,z, rx,ry,rz, sx,sy,sz)
    translation[1] = x
    translation[2] = y
    translation[3] = z
    rotation[1] = rx
    rotation[2] = ry
    rotation[3] = rz
    scale[1] = sx
    scale[2] = sy
    scale[3] = sz
    circleModel:setTransform(x and translation, rx and rotation, sx and scale)
    circleModel:draw()
end

--[[
--
-- spherical billboarding shader

local shader = love.graphics.newShader [[
    uniform mat4 projectionMatrix;
    uniform mat4 modelMatrix;
    uniform mat4 viewMatrix;

    varying vec4 vertexColor;

    #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vertexColor = VertexColor;
            mat4 modelView = viewMatrix * modelMatrix;

            modelView[0][0] = 1.0;
            modelView[0][1] = 0.0;
            modelView[0][2] = 0.0;

            modelView[1][0] = 0.0;
            modelView[1][1] = 1.0;
            modelView[1][2] = 0.0;

            modelView[2][0] = 0.0;
            modelView[2][1] = 0.0;
            modelView[2][2] = 1.0;

            return projectionMatrix * modelView * vertex_position;
        }
    #endif

    #ifdef PIXEL
        vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
        {
            vec4 texcolor = Texel(tex, vec2(texcoord.x, 1-texcoord.y));
            if (texcolor.a == 0.0) { discard; }
            return vec4(texcolor)*color*vertexColor;
        }
    #endif
]]

return primitives
