local Player = {}
Player.__index = Player

local vectors = require "g3d/vectors"

local function instantiate(x,y,z)
    local self = setmetatable({}, Player)
    local vectorMeta = {
        __tostring = vectors.tostring,
    }
    self.position = setmetatable({x,y,z}, vectorMeta)
    self.speed = setmetatable({0,0,0}, vectorMeta)
    self.normal = setmetatable({0,1,0}, vectorMeta)
    self.radius = 0.2
    self.onGround = false
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
    accumulator = accumulator + dt
    while accumulator > timestep do
        accumulator = accumulator - timestep
        self:fixedUpdate(timestep)
    end
end

function Player:moveAndSlide(mx,my,mz)
    -- capsule
    local len,x,y,z,nx,ny,nz = Map:capsuleIntersection(
        self.position[1] + mx,
        self.position[2] + my - 0.5,
        self.position[3] + mz,
        self.position[1] + mx,
        self.position[2] + my + 0.5,
        self.position[3] + mz,
        0.2
    )

    self.position[1] = self.position[1] + mx
    self.position[2] = self.position[2] + my
    self.position[3] = self.position[3] + mz

    local ignoreSlopes = ny and ny < -0.5
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
        --print("rejection: " .. tostring(-ny * (len - self.radius + tiny)))
    end

    return mx, my, mz
end

function Player:fixedUpdate(dt)
    --print("-----")
    -- collect inputs
    local moveX,moveY = 0,0
    local speed = 0.02
    local friction = 0.75

    -- friction
    self.speed[1] = self.speed[1] * friction
    self.speed[3] = self.speed[3] * friction

    -- gravity
    self.speed[2] = self.speed[2] + 0.01

    --print("speed: " .. round(self.speed[2]))
    --print("position: " .. round(self.position[2]))

    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end
    if love.keyboard.isDown("space") and self.onGround then
        self.speed[2] = self.speed[2] - 0.1
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

    local _
    _, self.speed[2], _ = self:moveAndSlide(0, self.speed[2], 0)
    self.speed[1], _ , self.speed[3] = self:moveAndSlide(self.speed[1], 0, self.speed[3])

    --self.onGround = len and ny < -0.1 or false

    --print("speed: " .. round(self.speed[2]))
    --print("position: " .. round(self.position[2]))

    g3d.camera.position = self.position
    g3d.camera.lookInDirection()
end

return instantiate
