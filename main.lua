io.stdout:setvbuf("no")

local lg = love.graphics
lg.setDefaultFilter("nearest")

local g3d = require "g3d"
local Player = require "player"
local vectors = require "g3d/vectors"
local primitives = require "primitives"

local map, background, player
local canvas
local accumulator = 0
local frametime = 1/60
local rollingAverage = {}

function love.load()
    lg.setBackgroundColor(0.25,0.5,1)

    map = g3d.newModel("assets/map.obj", "assets/tileset.png", nil, nil, {-1,-1,1})
    background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", {0,0,0}, nil, {500,500,500})
    player = Player:new(0,0,0)
    player:addCollisionModel(map)

    canvas = {lg.newCanvas(1024,576), depth=true}
end

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
    background:setTranslation(g3d.camera.position[1],g3d.camera.position[2],g3d.camera.position[3])
end

function love.keypressed(k)
    if k == "escape" then love.event.push("quit") end
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end

local function setColor(r,g,b,a)
    lg.setColor(r/255, g/255, b/255, a and a/255)
end

local function drawTree(x,y,z)
    setColor(56,48,46)
    primitives.line(x,y,z, x,y-1.25,z)
    primitives.circle(x,y,z, 0,0,0, 0.1,1,0.1)

    setColor(71,164,61)
    for i=1, math.pi*2, math.pi*2/3 do
        local r = 0.35
        --primitives.axisBillboard(1 + math.cos(i)*r, -0.5, 0 + math.sin(i)*r, 0,-1,0)
        primitives.fullBillboard(x + math.cos(i)*r, y - 1, z + math.sin(i)*r)
    end
    primitives.fullBillboard(x, y-1.5, z)
end

function love.draw()
    lg.setCanvas(canvas)
    lg.clear(0,0,0,0)

    --lg.setDepthMode("lequal", true)
    map:draw()
    background:draw()

    drawTree(1,0.5,0)
    drawTree(0,0.5,1.5)
    drawTree(-2,0.5,-1)

    lg.setColor(1,1,1)

    lg.setCanvas()
    lg.draw(canvas[1], 1024/2, 576/2, 0, 1,-1, 1024/2, 576/2)
    --lg.print(collectgarbage("count"))
end
