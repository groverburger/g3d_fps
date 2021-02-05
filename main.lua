io.stdout:setvbuf("no")

local g3d = require "g3d"
local Player = require "player"
local lg = love.graphics

function love.load()
    lg.setBackgroundColor(0.25,0.5,1)
    lg.setDefaultFilter("nearest")

    local map = g3d.newModel("assets/map.obj", "assets/tileset.png", nil, nil, {-1,-1,1})
    local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
    local player = Player:new(0,0,0)
    player:addCollisionModel(map)

    local lineVerts = {
        {0,0,0},
        {1,0,0},
        {0,0,1},
        {1,0,1},
        {1,0,0},
        {0,0,1},
    }
    local linetest = g3d.newModel(lineVerts)

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
        --player:interpolate(accumulator/frametime)
        --background:setTranslation(g3d.camera.position[1], g3d.camera.position[2],g3d.camera.position[3])
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

        --linetest:setTranslation(2,0,0)
        --linetest:draw()
        --linetest:setTranslation(0,0,0)
        --linetest:draw()

        lg.print(collectgarbage("count"))
    end
end
