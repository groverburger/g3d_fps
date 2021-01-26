-- written by groverbuger for g3d
-- january 2021
-- MIT license

g3d = require "g3d"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")
    Map = g3d.newModel("assets/map.obj", "assets/texture_1.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})

    ThePlayer = Player:new(0,0,0)
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    ThePlayer:update(dt)
end

function love.draw()
    Map:draw()

    local function round(number)
        if number then
            return math.floor(number*100 + 0.5)/100
        end
        return "nil"
    end

    love.graphics.print("normal: " .. round(ThePlayer.floorNormal[1]) .. ", " .. round(ThePlayer.floorNormal[2]) .. ", " .. round(ThePlayer.floorNormal[3]))
end

Player = {}
Player.__index = Player

function Player:new(x,y,z)
    local self = setmetatable({}, Player)
    self.position = {x,y,z}
    self.speed = {0,0,0}
    self.floorNormal = {0,1,0}
    self.height = 0.5
    self.width = 0.1
    return self
end

function Player:update(dt)
    local acc_x, acc_y, acc_z = 0, 0, 0

    local function getSign(number)
        return (number > 0 and 1) or (number < 0 and -1) or 0
    end

    local function distance(x1,y1, x2,y2)
        return math.sqrt((x1-x2)^2 + (y1-y2)^2)
    end

    -- collect inputs
    do
        local speed = 30
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
    end

    -- apply friction and gravity
    do
        local friction = 10
        acc_x = acc_x + self.speed[1]*-1*friction
        acc_y = 5
        acc_z = acc_z + self.speed[3]*-1*friction
    end

    -- integrate acceleration into speed
    self.speed[1] = self.speed[1] + acc_x*dt
    self.speed[2] = self.speed[2] + acc_y*dt
    self.speed[3] = self.speed[3] + acc_z*dt

    local onGround = false
    local headHeight = self.height/4

    -- vertical collisions
    if self.speed[2] >= 0 then
        -- floor collision
        local gravColl, where_x, where_y, where_z, norm_x, norm_y, norm_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            0,
            self.speed[2]*dt +self.height,
            0
        )

        self.floorNormal[1] = nil
        self.floorNormal[2] = nil
        self.floorNormal[3] = nil

        if gravColl and self.position[2] + self.speed[2]*dt + self.height > where_y then
            self.speed[2] = 0
            self.position[2] = where_y - self.height
            onGround = true

            self.floorNormal[1] = norm_x
            self.floorNormal[2] = norm_y
            self.floorNormal[3] = norm_z

            -- standing on steep slope, slide down
            if math.abs(norm_x) > 0.72 or math.abs(norm_z) > 0.72 then
                self.speed[1] = self.speed[1] + norm_x
                self.speed[3] = self.speed[3] + norm_z
            end
        end
    else
        -- ceiling collision
        local gravColl, where_x, where_y, where_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            0,
            self.speed[2]*dt -headHeight,
            0
        )

        if gravColl and self.position[2] + self.speed[2]*dt - headHeight < where_y then
            self.speed[1] = 0
            self.speed[2] = 0.002
            self.speed[3] = 0
            self.position[2] = where_y - headHeight
        end
    end

    -- jump
    if love.keyboard.isDown("space") and onGround then
        self.speed[2] = -2
    end

    -- integrate vertical speed
    self.position[2] = self.position[2] + self.speed[2]*dt

    local tude = distance(0,0, self.speed[1],self.speed[3])
    if tude > 0 then
        local coll, where_x, where_y, where_z, norm_x, norm_y, norm_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            self.speed[1]*dt + getSign(self.speed[1])*2,
            0,
            self.speed[3]*dt + getSign(self.speed[3])*2
        )

        if not coll or coll > 0.1 then
            -- not hitting a wall, move normally
            self.position[1] = self.position[1] + self.speed[1]*dt
            self.position[3] = self.position[3] + self.speed[3]*dt
        else
            -- hit a wall
            self.position[1] = self.position[1] - self.speed[1]*dt
            self.position[3] = self.position[3] - self.speed[3]*dt
            self.speed[1] = 0
            --self.speed[2] = math.max(0.1, self.speed[2])
            self.speed[3] = 0
        end
    end

    g3d.camera.position = self.position
    g3d.camera.lookInDirection()
end
