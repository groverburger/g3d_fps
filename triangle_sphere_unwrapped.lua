-- local --[[vector]] p0, p1, p2 -- triangle corners
-- local --[[vector]] center -- sphere center

local function fastSubtract(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end

local function fastCrossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

local function fastDotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

local function fastNormalize(x,y,z)
    local mag = math.sqrt(x^2 + y^2 + z^2)
    return x/mag, y/mag, z/mag
end

local function fastMagnitude(x,y,z)
    return math.sqrt(x^2 + y^2 + z^2)
end

local function closestPointOnLineSegment(a_x, a_y, a_z, b_x, b_y, b_z, x,y,z)
    local ab_x, ab_y, ab_z = b_x - a_x, b_y - a_y, b_z - a_z
    local t = fastDotProduct(x - a_x, y - a_y, z - a_z, ab_x, ab_y, ab_z) / (ab_x^2 + ab_y^2 + ab_z^2)
    t = math.min(1, math.max(0, t))
    return a_x + t*ab_x, a_y + t*ab_y, a_z + t*ab_z
end

function triangleSphere(src_x, src_y, src_z, radius, p0_x, p0_y, p0_z, p1_x, p1_y, p1_z, p2_x, p2_y, p2_z)
    local side1_x, side1_y, side1_z = p1_x - p0_x, p1_y - p0_y, p1_z - p0_z
    local side2_x, side2_y, side2_z = p2_x - p0_x, p2_y - p0_y, p2_z - p0_z
    local n_x, n_y, n_z = fastNormalize(fastCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))
    local dist = fastDotProduct(src_x - p0_x, src_y - p0_y, src_z - p0_z, n_x, n_y, n_z)

    if dist < -radius or dist > radius then
        goto skipTriangleSphere
    end

    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- Now determine whether itx is inside all triangle edges: 
    local c0_x, c0_y, c0_z = fastCrossProduct(itx_x - p0_x, itx_y - p0_y, itx_z - p0_z, p1_x - p0_x, p1_y - p0_y, p1_z - p0_z)
    local c1_x, c1_y, c1_z = fastCrossProduct(itx_x - p1_x, itx_y - p1_y, itx_z - p1_z, p2_x - p1_x, p2_y - p1_y, p2_z - p1_z)
    local c2_x, c2_y, c2_z = fastCrossProduct(itx_x - p2_x, itx_y - p2_y, itx_z - p2_z, p0_x - p2_x, p0_y - p2_y, p0_z - p2_z)
    if  fastDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and fastDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and fastDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        return fastMagnitude(src_x - itx_x, src_y - itx_y, src_z - itx_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    local radiussq = radius * radius -- sphere radius squared

    local line1_x, line1_y, line1_z = closestPointOnLineSegment(p0_x, p0_y, p0_z, p1_x, p1_y, p1_z, src_x, src_y, src_z)
    local intersects = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2 < radiussq

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(p1_x, p1_y, p1_z, p2_x, p2_y, p2_z, src_x, src_y, src_z)
    intersects = intersects or ((src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2 < radiussq)

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(p2_x, p2_y, p2_z, p0_x, p0_y, p0_z, src_x, src_y, src_z)
    intersects = intersects or ((src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2 < radiussq)

    if intersects then
        local dist_x, dist_y, dist_z = src_x - line1_x, src_y - line1_y, src_z - line1_z
        local best_distsq = dist_x^2 + dist_y^2 + dist_z^2
        local itx_x, itx_y, itx_z = line1_x, line1_y, line1_z

        local dist_x, dist_y, dist_z = src_x - line2_x, src_y - line2_y, src_z - line2_z
        local distsq = dist_x^2 + dist_y^2 + dist_z^2
        if distsq < best_distsq then
            best_distsq = distsq
            local itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
        end

        local dist_x, dist_y, dist_z = src_x - line3_x, src_y - line3_y, src_z - line3_z
        local distsq = dist_x^2 + dist_y^2 + dist_z^2
        if distsq < best_distsq then
            best_distsq = distsq
            local itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
        end

        return fastMagnitude(src_x - itx_x, src_y - itx_y, src_z - itx_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    ::skipTriangleSphere::
end

--[[
local center = NewVector(0,0,0)
local p1 = NewVector(1,0,0)
local p2 = NewVector(0,1,0)
local p3 = NewVector(0,0,1)
local len, point, norm = triangleSphere(center, 5, p1,p2,p3)
print(len, point, norm)
]]
local len, hx,hy,hz, nx,ny,nz = triangleSphere(0,0,0, 5, 1,0,0, 0,1,0, 0,0,1)
print(len, hx,hy,hz)
print(nx,ny,nz)
