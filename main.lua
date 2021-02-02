io.stdout:setvbuf("no")

local g3d = require "g3d"
local Player = require "player"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")

    local map = g3d.newModel("assets/map.obj", "assets/tileset.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})
    local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
    local player = Player:new(0,0,0)
    player:addCollisionModel(map)

    local accumulator = 0
    local frametime = 1/60
    local rollingAverage = {}
    function love.update(dt)
        -- rolling average so that abrupt changes in dt
        -- do not affect gameplay
        -- the math works out (div by 60, then mult by 60)
        -- so that this is equivalent to just adding dt, only smoother
        table.insert(rollingAverage, dt)
        if #rollingAverage > 60 then
            table.remove(rollingAverage, 1)
        end
        local avg = 0
        for i,v in ipairs(rollingAverage) do
            avg = avg + v
        end

        -- fixed timestep accumulator
        accumulator = accumulator + avg/#rollingAverage
        while accumulator > frametime do
            accumulator = accumulator - frametime
            player:update(dt)
        end

        -- interpolate player between frames
        -- to stop camera jitter when fps and timestep do not match
        player:interpolate(accumulator/frametime)
    end

    function love.keypressed(k)
        if k == "escape" then love.event.push("quit") end
    end

    function love.mousemoved(x,y, dx,dy)
        g3d.camera.firstPersonLook(dx,dy)
    end

    function love.draw()
        map:draw()
        background:draw()
    end
end
