Vector = {}
Vector.__index = Vector

function NewVector(x,y,z)
    local self = setmetatable({}, Vector)
    self:set(x or 0, y or 0, z or 0)
    return self
end

function Vector:translate(x,y,z)
    self.x = self.x + x
    self.y = self.y + y
    self.z = self.z + z
end

function Vector:set(x,y,z)
    self.x = x
    self.y = y
    self.z = z
    self.magnitude = math.sqrt(x^2 + y^2 + z^2)
end

function Vector:__add(other)
    if type(self) == "number" then
        return NewVector(self + other.x, self + other.y, self + other.z)
    end

    if type(other) == "number" then
        return NewVector(self.x + other, self.y + other, self.z + other)
    end

    return NewVector(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vector:__sub(other)
    if type(self) == "number" then
        return NewVector(self - other.x, self - other.y, self - other.z)
    end

    if type(other) == "number" then
        return NewVector(self.x - other, self.y - other, self.z - other)
    end

    return NewVector(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vector:__mul(value)
    return NewVector(self.x * value, self.y * value, self.z * value)
end

function Vector:__unm()
    return NewVector(self.x * -1, self.y * -1, self.z * -1)
end

function Vector:cross(b)
    local a = self
    return NewVector(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
end

function Vector:dot(b)
    local a = self
    return a.x*b.x + a.y*b.y + a.z*b.z
end

local function cross(v1, v2)
    return v1:cross(v2)
end

local function dot(v1, v2)
    return v1:dot(v2)
end

local function length(v)
    return math.sqrt(v.x^2 + v.y^2 + v.z^2)
end

local function normalize(v)
    local mag = length(v)
    return NewVector(v.x/mag, v.y/mag, v.z/mag)
end

function Vector:__tostring()
    return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.z) .. ")"
end

-- local --[[vector]] p0, p1, p2 -- triangle corners
-- local --[[vector]] center -- sphere center

function triangleSphere(center, radius, p0, p1, p2)
    local --[[vector]] N = normalize(cross(p1 - p0, p2 - p0)) -- plane normal
    local dist = dot(center - p0, N) -- signed distance between sphere and plane

    --if dist > 0 then
        --goto skipTriangleSphere -- can pass through back side of triangle (optional)
    --end

    if dist < -radius or dist > radius then
        goto skipTriangleSphere
    end

    local --[[vector]] point0 = center - N * dist -- projected sphere center on triangle plane

    -- Now determine whether point0 is inside all triangle edges: 
    local --[[vector]] c0 = cross(point0 - p0, p1 - p0) 
    local --[[vector]] c1 = cross(point0 - p1, p2 - p1) 
    local --[[vector]] c2 = cross(point0 - p2, p0 - p2)
    local inside = dot(c0, N) <= 0 and dot(c1, N) <= 0 and dot(c2, N) <= 0

    if inside then
        local --[[vector]] intersection_point = point0
        local --[[vector]] intersection_vec = center - intersection_point

        return length(intersection_vec), intersection_point, N
    end

    local function closestPointOnLineSegment(A, B, Point)
        local --[[vector]] AB = B - A
        local t = dot(Point - A, AB) / dot(AB, AB)
        return A + math.min(1, math.max(0, t)) * AB
    end

    local radiussq = radius * radius -- sphere radius squared

    -- Edge 1:
    local --[[vector]] point1 = closestPointOnLineSegment(p0, p1, center)
    local --[[vector]] v1 = center - point1
    local distsq1 = dot(v1, v1)
    local intersects = distsq1 < radiussq

    -- Edge 2:
    local --[[vector]] point2 = closestPointOnLineSegment(p1, p2, center)
    local --[[vector]] v2 = center - point2
    local distsq2 = dot(v2, v2)
    intersects = intersects or distsq2 < radiussq

    -- Edge 3:
    local --[[vector]] point3 = closestPointOnLineSegment(p2, p0, center)
    local --[[vector]] v3 = center - point3
    local distsq3 = dot(v3, v3)
    intersects = intersects or distsq3 < radiussq

    if intersects then
        local --[[vector]] d = center - point1
        local best_distsq = dot(d, d)
        intersection_point = point1
        intersection_vec = d

        d = center - point2
        local distsq = dot(d, d)
        if distsq < best_distsq then
            distsq = best_distsq
            intersection_point = point2
            intersection_vec = d
        end

        d = center - point3
        local distsq = dot(d, d)

        if distsq < best_distsq then
            distsq = best_distsq
            intersection_point = point3 
            intersection_vec = d
        end

        return length(intersection_vec), intersection_point, N
    end

    ::skipTriangleSphere::
end

local center = NewVector(0,0,0)
local p1 = NewVector(1,0,0)
local p2 = NewVector(0,1,0)
local p3 = NewVector(0,0,1)
local len, point, norm = triangleSphere(center, 5, p1,p2,p3)
print(len, point, norm)
