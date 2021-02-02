io.stdout:setvbuf("no")

local g3d = require "g3d"
local Player = require "player"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")
    Map = g3d.newModel("assets/map.obj", "assets/tileset.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})
    --Map = g3d.newModel("assets/parkour.obj", "assets/texture_1.png", {0, 1, 0}, nil, {-1,-1,1})
    Mark = g3d.newModel("assets/sphere.obj", "assets/earth.png", nil, nil, {0.1,0.1,0.1})
    Background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})

    ThePlayer = Player:new(0,0,0)
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    ThePlayer:update(dt)
    --g3d.camera.firstPersonMovement(dt*0.25)
end

function love.keypressed(k)
    if k == "escape" then love.event.push("quit") end
end

local function listPrint(x,y, ...)
    local function round(number)
        if number then
            return math.floor(number*100 + 0.5)/100
        end
        return "nil"
    end

    local str = ""
    local t = {...}
    for i,value in ipairs(t) do
        --assert(value == value, "value " .. i .. " is nan!")
        str = str .. tostring(round(value))
        if i < #t then
            str = str .. ", "
        end
    end

    love.graphics.print(str, x,y)
end

--local frameCount = 0
--local totalGameTime = 0
--local framesSinceLastUpdate = 0
function love.draw()
    Map:draw()
    Background:draw()
    --love.graphics.print(frameCount / totalGameTime)
end

function love.interpolate(fraction)
    ThePlayer:interpolate(fraction)
end

local usedDeltas = {}
function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0
    local accumulator = 0
    local frametime = 1/60
    local rollingAverage = {}

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        table.insert(rollingAverage, dt)
        if #rollingAverage > 60 then
            table.remove(rollingAverage, 1)
        end
        local avg = 0
        for i,v in ipairs(rollingAverage) do
            avg = avg + v
        end
        local delta = avg/#rollingAverage

        accumulator = accumulator + delta

        --[[
        table.insert(usedDeltas, (accumulator/frametime)%1)
        if #usedDeltas > 120 then
            table.remove(usedDeltas, 1)
        end
        ]]

        --totalGameTime = totalGameTime + dt

        -- Call update and draw
        --print(accumulator/frametime)
        while accumulator > frametime do
            accumulator = accumulator - frametime
            if love.update then love.update(frametime) end
            --if framesSinceLastUpdate < 7 then
                --print(framesSinceLastUpdate)
            --end
            framesSinceLastUpdate = 0
        end

        if love.interpolate then love.interpolate(accumulator/frametime) end

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end
            --frameCount = frameCount + 1
            --framesSinceLastUpdate = framesSinceLastUpdate + 1

            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end

--[[
function love.quit()
    for i,v in ipairs(usedDeltas) do
        print(i,v)
    end
end
]]
