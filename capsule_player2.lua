local Player = {}
Player.__index = Player

local vectors = require "g3d/vectors"

function Player:new(x,y,z)
    local self = setmetatable({}, Player)
    self.position = {x,y,z}
    self.speed = {0,0,0}
    self.normal = {0,1,0}
    self.radius = 0.2
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

local tiny = 2.2204460492503131e-16
function Player:fixedUpdate(dt)
    -- collect inputs
    local moveX,moveY = 0,0
    local speed = 0.01
    local friction = 0.75

    -- friction
    self.speed[1] = self.speed[1] * friction
    self.speed[3] = self.speed[3] * friction

    -- gravity
    self.speed[2] = self.speed[2] + 0.01

    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end
    if love.keyboard.isDown("space") then
        self.speed[2] = self.speed[2] - 0.05
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

    -- capsule
    local len,x,y,z,nx,ny,nz = Map:capsuleIntersection(
        self.position[1] + self.speed[1],
        self.position[2] + self.speed[2] - 0.5,
        self.position[3] + self.speed[3],
        self.position[1] + self.speed[1],
        self.position[2] + self.speed[2] + 0.5,
        self.position[3] + self.speed[3],
        0.2
    )

    if len then
        local mx = self.speed[1]
        local my = self.speed[2]
        local mz = self.speed[3]

        local speedLength = math.sqrt(mx^2 + my^2 + mz^2)

        if speedLength > 0 then
            local speedNormalized = {mx / speedLength, my / speedLength, mz / speedLength}
            local dot = vectors.dotProduct(speedNormalized, {nx, ny, nz})
            local undesiredMotion = {nx * dot, ny * dot, nz * dot}

            mx = (speedNormalized[1] - undesiredMotion[1]) * speedLength
            my = (speedNormalized[2] - undesiredMotion[2]) * speedLength
            mz = (speedNormalized[3] - undesiredMotion[3]) * speedLength
        end

        -- rejections
        self.position[1] = self.position[1] - nx * (len - self.radius + tiny)
        self.position[2] = self.position[2] - ny * (len - self.radius + tiny)
        self.position[3] = self.position[3] - nz * (len - self.radius + tiny)

        self.speed[1] = mx
        self.speed[2] = my
        self.speed[3] = mz
    end

    self.position[1] = self.position[1] + self.speed[1]
    self.position[2] = self.position[2] + self.speed[2]
    self.position[3] = self.position[3] + self.speed[3]

    g3d.camera.position = self.position
    g3d.camera.lookInDirection()
end

return setmetatable(Player, {__call = Player.new})
