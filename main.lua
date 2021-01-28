io.stdout:setvbuf("no")

g3d = require "g3d"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")
    Map = g3d.newModel("assets/map.obj", "assets/texture_1.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})
    --Map = g3d.newModel("assets/parkour.obj", "assets/texture_1.png", {0, 1, 0}, nil, {-1,-1,1})
    Mark = g3d.newModel("assets/sphere.obj", "assets/earth.png", nil, nil, {0.1,0.1,0.1})
    Background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})

    ActivePlayer = true
    ThePlayer = require("capsule_player2")(0,0,0)
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    if ActivePlayer then
        ThePlayer:update(dt)
    end
    --g3d.camera.firstPersonMovement(dt*0.25)
end

function love.keypressed(k)
    if k == "e" then ActivePlayer = not ActivePlayer end
    if k == "escape" then love.event.push("quit") end
end

function listPrint(x,y, ...)
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

function love.draw()
    Map:draw()
    Background:draw()
end
