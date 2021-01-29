local Player = {}
Player.__index = Player

local vectors = require "g3d/vectors"

-- TODO:
-- jump not full height on slopes
-- on-the-fly stepDownSize calculation based on normal vector of triangle
-- mario 64 style sub-frames for more precise collision checking
-- maximum fall speed
-- delta-time solution

local function instantiate(x,y,z)
    local self = setmetatable({}, Player)
    local vectorMeta = {
        __tostring = vectors.tostring,
    }
    self.position = setmetatable({x,y,z}, vectorMeta)
    self.speed = setmetatable({0,0,0}, vectorMeta)
    self.lastSpeed = setmetatable({0,0,0}, vectorMeta)
    self.normal = setmetatable({0,1,0}, vectorMeta)
    self.radius = 0.2
    self.onGround = false
    self.stepDownSize = 0.075
    return self
end

local function getSign(number)
    return (number > 0 and 1) or (number < 0 and -1) or 0
end

local function round(number)
    if number then
        return math.floor(number*1000 + 0.5)/1000
    end
    return "nil"
end

local accumulator = 0
local timestep = 1/60
function Player:update(dt)
    --accumulator = accumulator + dt
    --while accumulator > timestep do
        --accumulator = accumulator - timestep
        self:fixedUpdate(timestep)
    --end
    g3d.camera.lookInDirection()
end

function Player:collisionTest(mx,my,mz)
    return Map:capsuleIntersection(
        self.position[1] + mx,
        self.position[2] + my - 0.5,
        self.position[3] + mz,
        self.position[1] + mx,
        self.position[2] + my + 0.5,
        self.position[3] + mz,
        0.2
    )
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
            local speedNormalized = {mx / speedLength, my / speedLength, mz / speedLength}
            local dot = vectors.dotProduct(speedNormalized, {nx, ny, nz})
            local undesiredMotion = {nx * dot, ny * dot, nz * dot}

            -- modify output vector based on normal
            my = (speedNormalized[2] - undesiredMotion[2]) * speedLength

            if not ignoreSlopes then
                mx = (speedNormalized[1] - undesiredMotion[1]) * speedLength
                mz = (speedNormalized[3] - undesiredMotion[3]) * speedLength
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

function Player:fixedUpdate(dt)
    -- collect inputs
    local moveX,moveY = 0,0
    local speed = 0.015
    local friction = 0.75
    local gravity = 0.005
    local jump = 1/12

    -- friction
    self.speed[1] = self.speed[1] * friction
    self.speed[3] = self.speed[3] * friction

    -- gravity
    self.speed[2] = self.speed[2] + gravity

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
                local speedNormalized = {mx / speedLength, my / speedLength, mz / speedLength}
                local dot = vectors.dotProduct(speedNormalized, {nx, ny, nz})
                local undesiredMotion = {nx * dot, ny * dot, nz * dot}

                -- modify output vector based on normal
                my = (speedNormalized[2] - undesiredMotion[2]) * speedLength
            end

            -- rejections
            self.position[2] = self.position[2] - ny * (len - self.radius)
            self.speed[2] = 0
            self.onGround = true
        end
    end

    -- wall movement and collision check
    self.speed[1], _ , self.speed[3], nx, ny, nz = self:moveAndSlide(self.speed[1], 0, self.speed[3])

    -- copy speed into lastSpeed
    for i,v in ipairs(self.speed) do
        self.lastSpeed[i] = v
    end

    g3d.camera.position = self.position
end

return instantiate
