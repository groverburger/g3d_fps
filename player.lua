local Player = {}
Player.__index = Player

function Player:new(x,y,z)
    local self = setmetatable({}, Player)
    self.position = {x,y,z}
    self.wasOnGround = false
    self.speed = {0,0,0}
    self.floorNormal = {0,1,0}
    self.height = 0.5
    self.width = 0.1
    return self
end

local function getSign(number)
    return (number > 0 and 1) or (number < 0 and -1) or 0
end

function Player:update(dt)
    local acc_x, acc_y, acc_z = 0, 0, 0

    -- collect inputs
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

    -- apply friction and gravity
    local friction = 10
    acc_x = acc_x + self.speed[1]*-1*friction
    acc_y = 5
    acc_z = acc_z + self.speed[3]*-1*friction

    -- integrate acceleration into speed
    self.speed[1] = self.speed[1] + acc_x*dt
    self.speed[2] = self.speed[2] + acc_y*dt
    self.speed[3] = self.speed[3] + acc_z*dt

    local onGround = false
    local headHeight = self.height/4
    local isSliding = false

    -- vertical collisions
    if self.speed[2] >= 0 then
        -- floor collision
        local coll, where_x, where_y, where_z, norm_x, norm_y, norm_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            0,
            1,
            0
        )

        self.floorNormal[1] = nil
        self.floorNormal[2] = nil
        self.floorNormal[3] = nil

        local stepSize = 1
        if coll then
            local snapToFloor = self.position[2] + self.speed[2]*dt + self.height > where_y
            local stepDown = self.wasOnGround and math.abs(self.position[2] - where_y) < stepSize
            if snapToFloor or stepDown then
                self.speed[2] = 0
                self.position[2] = where_y - self.height
                onGround = true

                self.floorNormal[1] = norm_x
                self.floorNormal[2] = norm_y
                self.floorNormal[3] = norm_z

                -- standing on steep slope, slide down
                -- steep is slightly greater than sqrt(2)/2, a 45 degree incline
                local steep = 0.71
                if math.abs(norm_x) > steep or math.abs(norm_z) > steep then
                    isSliding = true
                    self.speed[1] = self.speed[1] + norm_x
                    self.speed[3] = self.speed[3] + norm_z
                end
            end
        end
    else
        -- ceiling collision
        local coll, where_x, where_y, where_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            0,
            -1,
            0
        )

        --local snapToCeiling = self.position[2] + self.speed[2]*dt - headHeight < where_y
        if coll and snapToCeiling then
            self.speed[1] = 0
            self.speed[2] = math.abs(self.speed[2])/2
            self.speed[3] = 0
            self.position[2] = where_y + headHeight
        end
    end

    -- jump
    if love.keyboard.isDown("space") and onGround and not isSliding then
        self.speed[2] = -2
    end

    -- integrate vertical speed
    self.position[2] = self.position[2] + self.speed[2]*dt

    if self.speed[1]^2 + self.speed[3]^2 > 0 then
        local coll, where_x, where_y, where_z, norm_x, norm_y, norm_z = Map:rayIntersection(
            self.position[1],
            self.position[2],
            self.position[3],
            self.speed[1],
            0,
            self.speed[3]
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

    self.wasOnGround = onGround

    -- attach the camera to the player
    g3d.camera.position = self.position
    g3d.camera.lookInDirection()
end

return setmetatable(Player, {__call = Player.new})
