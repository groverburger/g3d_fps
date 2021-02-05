local g3d = require "g3d"

-- TODO:
-- on-the-fly stepDownSize calculation based on normal vector of triangle
-- mario 64 style sub-frames for more precise collision checking

local function getSign(number)
    return (number > 0 and 1) or (number < 0 and -1) or 0
end

local function round(number)
    if number then
        return math.floor(number*1000 + 0.5)/1000
    end
    return "nil"
end

local Player = {}
Player.__index = Player

function Player:new(x,y,z)
    local self = setmetatable({}, Player)
    local vectorMeta = {
    }
    self.position = setmetatable({x,y,z}, vectorMeta)
    self.speed = setmetatable({0,0,0}, vectorMeta)
    self.lastSpeed = setmetatable({0,0,0}, vectorMeta)
    self.normal = setmetatable({0,1,0}, vectorMeta)
    self.radius = 0.2
    self.onGround = false
    self.stepDownSize = 0.075
    self.collisionModels = {}

    return self
end

function Player:addCollisionModel(model)
    table.insert(self.collisionModels, model)
    return model
end

-- collide against all models in my collision list
-- and return the collision against the closest one
function Player:collisionTest(mx,my,mz)
    local bestLength, bx,by,bz, bnx,bny,bnz

    for _,model in ipairs(self.collisionModels) do
        local len, x,y,z, nx,ny,nz = model:capsuleIntersection(
            self.position[1] + mx,
            self.position[2] + my - 0.15,
            self.position[3] + mz,
            self.position[1] + mx,
            self.position[2] + my + 0.5,
            self.position[3] + mz,
            0.2
        )

        if len and (not bestLength or len < bestLength) then
            bestLength, bx,by,bz, bnx,bny,bnz = len, x,y,z, nx,ny,nz
        end
    end

    return bestLength, bx,by,bz, bnx,bny,bnz
end

function Player:moveAndSlide(mx,my,mz)
    local len,x,y,z,nx,ny,nz = self:collisionTest(mx,my,mz)

    self.position[1] = self.position[1] + mx
    self.position[2] = self.position[2] + my
    self.position[3] = self.position[3] + mz

    local ignoreSlopes = ny and ny < -0.7

    if len then
        local speedLength = math.sqrt(mx^2 + my^2 + mz^2)

        if speedLength > 0 then
            local xNorm, yNorm, zNorm = mx / speedLength, my / speedLength, mz / speedLength
            local dot = xNorm*nx + yNorm*ny + zNorm*nz
            local xPush, yPush, zPush = nx * dot, ny * dot, nz * dot

            -- modify output vector based on normal
            my = (yNorm - yPush) * speedLength
            if ignoreSlopes then my = 0 end

            if not ignoreSlopes then
                mx = (xNorm - xPush) * speedLength
                mz = (zNorm - zPush) * speedLength
            end
        end

        -- rejections
        self.position[2] = self.position[2] - ny * (len - self.radius)

        if not ignoreSlopes then
            self.position[1] = self.position[1] - nx * (len - self.radius)
            self.position[3] = self.position[3] - nz * (len - self.radius)
        end
    end

    return mx, my, mz, nx, ny, nz
end

function Player:update()
    -- collect inputs
    local moveX,moveY = 0,0
    local speed = 0.015
    local friction = 0.75
    local gravity = 0.005
    local jump = 1/12
    local maxFallSpeed = 0.25

    -- friction
    self.speed[1] = self.speed[1] * friction
    self.speed[3] = self.speed[3] * friction

    -- gravity
    self.speed[2] = math.min(self.speed[2] + gravity, maxFallSpeed)

    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end
    if love.keyboard.isDown("space") and self.onGround then
        self.speed[2] = self.speed[2] - jump
    end

    -- do some trigonometry on the inputs to make movement relative to camera's direction
    -- also to make the player not move faster in diagonal directions
    if moveX ~= 0 or moveY ~= 0 then
        local angle = math.atan2(moveY,moveX)
        local direction = g3d.camera.getDirectionPitch()
        local directionX, directionZ = math.cos(direction + angle)*speed, math.sin(direction + angle + math.pi)*speed

        self.speed[1] = self.speed[1] + directionX
        self.speed[3] = self.speed[3] + directionZ
    end

    local _, nx, ny, nz

    -- vertical movement and collision check
    _, self.speed[2], _, nx, ny, nz = self:moveAndSlide(0, self.speed[2], 0)

    -- ground check
    local wasOnGround = self.onGround
    self.onGround = ny and ny < -0.7

    -- smoothly walk down slopes
    if not self.onGround and wasOnGround and self.speed[2] > 0 then
        local len,x,y,z,nx,ny,nz = self:collisionTest(0,self.stepDownSize,0)
        local mx, my, mz = 0,self.stepDownSize,0
        if len then
            -- do the position change only if a collision was actually detected
            self.position[2] = self.position[2] + my

            local speedLength = math.sqrt(mx^2 + my^2 + mz^2)

            if speedLength > 0 then
                local xNorm, yNorm, zNorm = mx / speedLength, my / speedLength, mz / speedLength
                local dot = xNorm*nx + yNorm*ny + zNorm*nz
                local xPush, yPush, zPush = nx * dot, ny * dot, nz * dot

                -- modify output vector based on normal
                my = (yNorm - yPush) * speedLength
            end

            -- rejections
            self.position[2] = self.position[2] - ny * (len - self.radius)
            self.speed[2] = 0
            self.onGround = true
        end
    end

    -- wall movement and collision check
    self.speed[1], _, self.speed[3], nx, ny, nz = self:moveAndSlide(self.speed[1], 0, self.speed[3])

    for i=1, 3 do
        self.lastSpeed[i] = self.speed[i]
        g3d.camera.position[i] = self.position[i]
    end
    g3d.camera.lookInDirection()
end

function Player:interpolate(fraction)
    -- interpolate in every direction except down
    -- because gravity/floor collisions mean that there will often be a noticeable
    -- visual difference between the interpolated position and the real position

    for i=1, 3 do
        if i ~= 2 then
            g3d.camera.position[i] = self.position[i] + self.speed[i]*fraction
        end
    end

    g3d.camera.lookInDirection()
end

return Player
