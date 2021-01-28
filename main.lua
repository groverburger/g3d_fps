io.stdout:setvbuf("no")

g3d = require "g3d"

function love.load()
    love.graphics.setBackgroundColor(0.25,0.5,1)
    love.graphics.setDefaultFilter("nearest")
    Map = g3d.newModel("assets/map.obj", "assets/texture_1.png", {-2, 2.5, -3.5}, nil, {-1,-1,1})
    Mark = g3d.newModel("assets/sphere.obj", "assets/earth.png", nil, nil, {0.1,0.1,0.1})

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

    --[[
    -- sphere
    local len,x,y,z,nx,ny,nz = Map:sphereIntersection(
        g3d.camera.position[1],
        g3d.camera.position[2],
        g3d.camera.position[3], 1
    )
    ]]

    --[[
    -- closest point
    local len,x,y,z,nx,ny,nz = Map:closestPoint(
        g3d.camera.position[1],
        g3d.camera.position[2],
        g3d.camera.position[3]
    )
    ]]

    --[[
    local len,x,y,z,nx,ny,nz = Map:rayIntersection(
        g3d.camera.position[1],
        g3d.camera.position[2],
        g3d.camera.position[3],
        0,
        1,
        0
    )
    ]]

    -- capsule
    --[[
    local len,x,y,z,nx,ny,nz = Map:capsuleIntersection(
        g3d.camera.position[1],
        g3d.camera.position[2]-0.5,
        g3d.camera.position[3],
        g3d.camera.position[1],
        g3d.camera.position[2]+0.5,
        g3d.camera.position[3],
        0.2
    )

    if len then
        Mark:setTranslation(x,y,z)
        Mark:draw()

        g3d.camera.position[1] = g3d.camera.position[1] + nx*0.1
        g3d.camera.position[2] = g3d.camera.position[2] + ny*0.1
        g3d.camera.position[3] = g3d.camera.position[3] + nz*0.1
    end
    ]]

    --[[
    love.graphics.print(collectgarbage("count"), 0,100)
    ]]
    --love.graphics.print("raycast: " .. round(len) .. ", " .. round(x) .. ", " .. round(y) .. ", " .. round(z))
    --love.graphics.print("speed: " .. round(ThePlayer.speed[1]) .. ", " .. round(ThePlayer.speed[2]) .. ", " .. round(ThePlayer.speed[3]))
    --love.graphics.print("normal: " .. round(nx) .. ", " .. round(ny) .. ", " .. round(nz), 0, 50)
    --listPrint(0,0, len,x,y,z,nx,ny,nz)
    --listPrint(0,0, ThePlayer.position[1],ThePlayer.position[2],ThePlayer.position[3])
    --listPrint(0,50, ThePlayer.normal[1],ThePlayer.normal[2],ThePlayer.normal[3])
end
