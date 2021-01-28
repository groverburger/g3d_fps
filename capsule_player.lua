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

local accumulator = 0
local timestep = 1/60
function Player:update(dt)
    accumulator = accumulator + dt
    while accumulator > timestep do
        accumulator = accumulator - timestep
        self:fixedUpdate(timestep)
    end
end

function Player:getCollision(xoff, yoff, zoff)
    return Map:capsuleIntersection(
        self.position[1] + xoff or 0,
        self.position[2]+0.5 + yoff or 0,
        self.position[3] + zoff or 0,
        self.position[1]+ xoff or 0,
        self.position[2]-0.5 + yoff or 0,
        self.position[3] + zoff or 0,
        self.radius
    )
end

local function round(number)
    if number then
        return math.floor(number*1000 + 0.5)/1000
    end
    return "nil"
end

local tiny = 2.2204460492503131e-16
function Player:moveAndSlide(mx, my, mz)
    local coll, where_x, where_y, where_z, norm_x, norm_y, norm_z = self:getCollision(mx, my, mz)

    if coll then
        self.normal[1] = norm_x
        self.normal[2] = norm_y
        self.normal[3] = norm_z

        local speedLength = math.sqrt(mx^2 + my^2 + mz^2)

        if speedLength > 0 then
            local speedNormalized = {mx / speedLength, my / speedLength, mz / speedLength}
            local dot = vectors.dotProduct(speedNormalized, {norm_x, norm_y, norm_z})
            local undesiredMotion = {norm_x * dot, norm_y * dot, norm_z * dot}

            mx = (speedNormalized[1] - undesiredMotion[1]) * speedLength
            my = (speedNormalized[2] - undesiredMotion[2]) * speedLength
            mz = (speedNormalized[3] - undesiredMotion[3]) * speedLength
        end

        --print("correction: " .. tostring((1 * (coll - self.radius + 0.00001))/0.004))
        self.position[1] = self.position[1] - norm_x * (coll - self.radius + tiny)
        self.position[2] = self.position[2] - norm_y * (coll - self.radius + tiny)
        self.position[3] = self.position[3] - norm_z * (coll - self.radius + tiny)
    end
    --print(self.position[1], self.position[2], self.position[3])
    print(round(mx),round(my),round(mz))

    self.position[1] = self.position[1] + mx
    self.position[2] = self.position[2] + my
    self.position[3] = self.position[3] + mz

    return mx, my, mz
end

function Player:fixedUpdate(dt)
    local acc_x, acc_z = 0, 0
    local _

    -- gravity
    self.speed[2] = self.speed[2] + 0.004
    _, self.speed[2], _ = self:moveAndSlide(0, self.speed[2], 0)

    -- collect inputs
    local speed = 0.01
    local move_x, move_z = 0, 0
    if love.keyboard.isDown("w") then move_z = move_z + 1 end
    if love.keyboard.isDown("s") then move_z = move_z - 1 end
    if love.keyboard.isDown("a") then move_x = move_x - 1 end
    if love.keyboard.isDown("d") then move_x = move_x + 1 end

    if move_x ~= 0 or move_z ~= 0 then
        local moveAngle = math.atan2(move_x, move_z)*-1
        local direction = g3d.camera.getDirectionPitch()
        acc_x = math.cos(moveAngle - direction + math.pi/2)*speed
        acc_z = math.sin(moveAngle - direction + math.pi/2)*speed
    end

    -- apply friction
    local friction = 0.25
    acc_x = acc_x + self.speed[1]*-1*friction
    acc_z = acc_z + self.speed[3]*-1*friction

    -- integrate acceleration into speed
    self.speed[1] = self.speed[1] + acc_x
    self.speed[3] = self.speed[3] + acc_z
    self.speed[1], _, self.speed[3] = self:moveAndSlide(self.speed[1], 0, self.speed[3])

    -- jump
    if love.keyboard.isDown("space") then
        self.speed[2] = -0.02
    end

    -- attach the camera to the player
    g3d.camera.position = self.position
    g3d.camera.lookInDirection()
end

return setmetatable(Player, {__call = Player.new})
