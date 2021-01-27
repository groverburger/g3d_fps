io.stdout:setvbuf("no")

g3d = require "g3d"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")
    Map = g3d.newModel("assets/map.obj", "assets/texture_1.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})
    Mark = g3d.newModel("assets/sphere.obj", "assets/earth.png", nil, nil, {0.1,0.1,0.1})

    --ThePlayer = require("player")(0,0,0)
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

function love.update(dt)
    --ThePlayer:update(dt)
    g3d.camera.firstPersonMovement(dt)
end

function love.draw()
    Map:draw()

    local len,x,y,z = Map:sphereIntersection(
        g3d.camera.position[1],
        g3d.camera.position[2],
        g3d.camera.position[3],
        1
    )

    if len then
        Mark:setTranslation(x,y,z)
        Mark:draw()
    end

    local function round(number)
        if number then
            return math.floor(number*100 + 0.5)/100
        end
        return "nil"
    end

    love.graphics.print("raycast: " .. round(len) .. ", " .. round(x) .. ", " .. round(y) .. ", " .. round(z))
    love.graphics.print(collectgarbage("count"), 0,100)
end
