-- Alternative mjm.lua intended to work with Blender on multiple platforms
-- do not include in the game scripts!

local mjm = {}

function mjm.mix(x, y, a)
    return x + (y - x) * a
end

local SPVec2MetaTable = {
    __add = function(a, b) return vec2(a.x + b.x, a.y + b.y) end,
    __sub = function(a, b) return vec2(a.x - b.x, a.y - b.y) end,
    __mul = function(a, b) return vec2(a.x * b,a.y * b) end,
    __div = function(a, b) return vec2(a.x / b,a.y / b) end,
    __unm = function(a) return vec2(-a.x,-a.y) end,
    __tostring = function(a) return "vec2("..a.x .. ", " .. a.y .. ")" end,
}
function mjm.vec2(X, Y)
    local self = {}
    self.x = X
    self.y = Y
    setmetatable(self, SPVec2MetaTable)
end

function mjm.vec3(X, Y, Z)
    local self = {}
    self.x = X
    self.y = Y
    self.z = Z
    setmetatable(self, {
    __add = function(a, b) return mjm.vec3(a.x + b.x, a.y + b.y, a.z + b.z) end,
    __sub = function(a, b) return mjm.vec3(a.x - b.x, a.y - b.y, a.z - b.z) end,
    __mul = function(a, b) return mjm.vec3(a.x * b,a.y * b, a.z * b) end,
    __div = function(a, b) return mjm.vec3(a.x / b,a.y / b, a.z / b) end,
    __unm = function(a)    return mjm.vec3(-a.x,-a.y,-a.z) end,
    __tostring = function(a) return "vec3("..a.x .. ", " .. a.y .. ", " .. a.z .. ")" end,
    })
    return self
end

function mjm.vec4(X, Y, Z, W)
    local self = {}
    self.x = X
    self.y = Y
    self.z = Z
    self.w = W
    setmetatable(self, {
    __add = function(a, b) return mjm.vec4(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w) end,
    __sub = function(a, b) return mjm.vec4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w) end,
    __mul = function(a, b) return mjm.vec4(a.x * b,a.y * b, a.z * b, a.w * b) end,
    __div = function(a, b) return mjm.vec4(a.x / b,a.y / b, a.z / b, a.w / b) end,
    __unm = function(a)    return mjm.vec4(-a.x,-a.y,-a.z,-a.w) end,
    __tostring = function(a) return "vec4("..a.x .. ", " .. a.y .. ", " .. a.z .. ", " .. a.w .. ")" end,
})
    return self
end

function mjm.toVec3(v)
    return mjm.vec3(v.x,v.y,v.z)
end

return mjm
