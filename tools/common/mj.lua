
mjrequire = function(path) --this will be overridden later, after mods have been loaded
    return require(path)
end

local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local normalize = mjm.normalize
local cross = mjm.cross
local length = mjm.length
local mat3LookAtInverse = mjm.mat3LookAtInverse

local mj = {}

-- these constants must not be changed
mj.RENDER_SCALE = 100000
mj.SUBDIVISIONS = 22
---

mj.serverClientID = "ffffffffffffffff"

function mj:mToP(meters) --converts meters to prerender, which is the scale where most things are calulated, sea level is the normal from the center of the planet, at radius 1.0
	return (meters / 8388608.0)
end

function mj:mToR(meters) --converts meters to render, this is the scale which things are actually rendered at, usually offset from a shifting origin
	return (meters * mj.RENDER_SCALE / 8388608.0)
end

function mj:rToM(render)
	return (render * 8388608.0 / mj.RENDER_SCALE)
end

function mj:pToM(prerender)
	return (prerender * 8388608.0)
end

--mj.backgroundColor = vec4(0.776, 0.698, 0.506, 1.0)
mj.backgroundColor = vec4(0.804, 0.788, 0.663, 1)

--mj.textColor = vec4(0.216, 0.110, 0.031, 1.0)
mj.textColor = vec4(1.0,1.0,1.0, 1.0)
mj.outlineColor = vec4(1.000, 0.976, 0.796, 1)
mj.underlineColor = mj.textColor
mj.disabledTextColor = vec4(0.4,0.4,0.4,1.0)

mj.highlightColor = vec4(0.3, 0.7, 1.0, 1.0)
mj.highlightColorDark = mj.textColor

mj.gameName = "Sapiens"


mj.terminal = nil
mj.debugObject = nil

function mj:enum(tbl)
    local lengthl = #tbl
    for i = 1, lengthl do
        local v = tbl[i]
        tbl[v] = i
    end

    return tbl
end

function mj:indexed(tbl)
    local lengthl = #tbl
    for i = 1, lengthl do
        local v = tbl[i]
        tbl[v.key] = v
        v.index = i
    end

    return tbl
end

function mj:insertIndexed(tbl, element)
	table.insert(tbl, element)
	local index = #tbl
	tbl[element.key] = element
	element.index = index
end


function mj:cloneTable(orig)
	if not orig then
		return orig
	end
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[mj:cloneTable(orig_key)] = mj:cloneTable(orig_value)
        end
        setmetatable(copy, mj:cloneTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function mj:concatTables(t1,t2)
	if not t1 then
		mj:error("attempt to concat onto nil table")
		return nil
	end
	if not t2 then
		mj:error("attempt to concat nil table")
		return nil
	end

	local result =  mj:cloneTable(t1)
	for i=1,#t2 do
		result[#result+1] = t2[i]
	end
    return result
end


function mj:combineTables(t1,t2)
	if not t1 then
		mj:error("attempt to combine with nil table")
		return nil
	end
	if not t2 then
		mj:error("attempt to combine nil table")
		return nil
	end

	local result =  mj:cloneTable(t1)
	for k,v in pairs(t2) do
		result[k] = v
	end
    return result
end

function mj:get(obj, ...)
	local result = obj
	for i,member in ipairs{...} do
		if not result then
			return nil
		end
		result = result[member]
	end
	return result
end

function mj:getOrCreate(obj, ...)
	if not obj then 
		return nil
	end
	local result = obj
	for i,member in ipairs{...} do
		local nextResult = result[member]
		if not nextResult then
			nextResult = {}
			result[member] = nextResult
		end
		result = nextResult
	end
	return result
end


function mj:tostring (v, indent)
	if v == nil then
		return "nil"
	end
	if not indent then 
		indent = 0 
	end

	if type(v) == "userdata" then
		local mt = getmetatable(v)
		if mt then
			local type = rawget(mt, "__type")
			if type then
				if type == "vec3" then
					mj:log("oops!")
					return "(" .. mj:tostring(v.x) .. "," .. mj:tostring(v.y) .. "," .. mj:tostring(v.z) .. ")"
				elseif type == "mat3" then
					return "(" .. mj:tostring(v.m0) .. "," .. mj:tostring(v.m1) .. "," .. mj:tostring(v.m2) .. ")" ..
					"(" .. mj:tostring(v.m3) .. "," .. mj:tostring(v.m4) .. "," .. mj:tostring(v.m5) .. ")" ..
					"(" .. mj:tostring(v.m6) .. "," .. mj:tostring(v.m7) .. "," .. mj:tostring(v.m8) .. ")"
				end
			end
		end
	end

	if (type(v) == "number") then
		return v
	elseif (type(v) == "string") then
		return v
	elseif (type(v) == "table") then
		return self:tableToString(v, indent + 2)
	else
		return tostring(v)
	end
end

function mj:tableToString (tbl, indent)
	if not tbl then
		return "nil"
	end
	if not indent then 
		indent = 0 
	end

	local toprint = "{\n"
	indent = indent + 2 
	for k, v in pairs(tbl) do
		toprint = toprint .. string.rep(" ", indent)
		if (type(k) == "number") then
			toprint = toprint .. "[" .. k .. "] = "
		elseif (type(k) == "string") then
			toprint = toprint  .. k ..  " = "   
		end

		toprint = toprint .. mj:tostring (v, indent) .. ",\n"
	end
	toprint = toprint .. string.rep(" ", indent-4) .. "}"
	return toprint
end

function mj:printTable(tbl)
	LuaEnvironment:log(self:tableToString(tbl))
end

function mj:capitalize(str)
    --[[local function titleCase(first, rest)
		return first:upper() .. rest:lower()
	end
	 
	return string.gsub(str, "(%a)([%w_']*)", titleCase)]]

	local result = ""
	local caps = true
	for code in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		--mj:log(code)
		if caps then
			result = result .. code:upper()
		else
			result = result .. code:lower()
		end
		local whitespaceMatch = string.match(code, "([%s%p%d])")
		--mj:log("whitespaceMatch:", whitespaceMatch)
		if whitespaceMatch then
			caps = true
		else
			caps = false
		end
	end
	return result
end

function mj:isNan(value)
	return value ~= value
end

local sizes = {
	mat4 = 64,
	mat3 = 36,
	vec4 = 16,
	vec3 = 12,
	vec2 = 8,
	float = 4,
	int32 = 4,
	int = 4,
	uint32 = 4,
	uint = 4,
	int16 = 2,
	uint16 = 2,
	int8 = 1,
	uint8 = 1,
}

function mj:sizeof(name)
	return sizes[name]
end

local function logToTerminal(string)
	if mj.terminal and not mj.terminal.hidden then
		mj.terminal:displayMessage(string)
	end
end

function mj:log(...)
	local string = ""
	local count = select("#",...)
	for i = 1,count do
		string = string .. mj:tostring(select(i,...), 0)
	end
	LuaEnvironment:log(string)
	logToTerminal(string)
end

function mj:warn(...)
	local string = "WARNING:"
	local count = select("#",...)
	for i = 1,count do
		string = string .. mj:tostring(select(i,...), 0)
	end
	LuaEnvironment:log(string)
	logToTerminal(string)
end

function mj:error(...)
	local string = "ERROR:"
	local count = select("#",...)
	for i = 1,count do
		string = string .. mj:tostring(select(i,...), 0)
	end
	LuaEnvironment:log(string)
	mj:log(debug.traceback())
	logToTerminal(string)
end

function mj:debug(...)
	local string = "DEBUG:"
	local count = select("#",...)
	for i = 1,count do
		string = string .. mj:tostring(select(i,...), 0)
	end
	LuaEnvironment:log(string)
	mj:log(debug.traceback())
	logToTerminal(string)
end


function mj:objectLog (objectID, ...)
	if objectID == mj.debugObject then
		local string = "OBJECT LOG:" .. mj:tostring(objectID) .. ":"
		local count = select("#",...)
		for i = 1,count do
			string = string .. mj:tostring(select(i,...), 0)
		end
		LuaEnvironment:log(string)
		logToTerminal(string)
	end
end

function mj:objectLogFunction(objectID, func)
	if objectID == mj.debugObject then
		
		local funcResult = func()
		if funcResult and funcResult[1] then
			local string = "OBJECT LOG:" .. mj:tostring(objectID) .. ":"
			for i,v in ipairs(funcResult) do
				string = string .. mj:tostring(v, 0)
			end
			LuaEnvironment:log(string)
			logToTerminal(string)
		end
	end
end

function mj:callFunctionIfDebugObject(objectID, func)
	if objectID == mj.debugObject then
		func()
	end
end

function mj:getNorthFacingFlatRotationForPoint(point)
	local pointNormalized = normalize(point)
	local perp = normalize(cross(pointNormalized, vec3(0.0,1.0,0.0)))
	return mat3LookAtInverse(-perp, pointNormalized)
end

function mj:calculateTrajectory(startPos, goalPos, velocity)
	local startLength = length(startPos)
	local goalLength = length(goalPos)

	mj:log("goalLength - startLength: ", mj:pToM(goalLength - startLength))

	local startPosNormal = startPos / startLength
	local goalPosNormal = goalPos / goalLength
	local distance = length(goalPosNormal - startPosNormal)
	local g = mj:mToP(10.0)
	local height = goalLength - startLength
	local velocitySquared = velocity * velocity

	local inner = (velocitySquared * velocitySquared) - g * (g * distance * distance + 2 * height * velocitySquared)
	if inner <= 0 then
		mj:log("no solution")
		return normalize(normalize(goalPos - startPos) + normalize(startPos)) * velocity --just send back something in the general direction, even though it would miss
	end
	
	local root = math.sqrt(inner)

	local resultA = (velocitySquared + root) / (g * distance)
	local resultB = (velocitySquared - root) / (g * distance)

	local resultToUse = math.min(resultA, resultB)

	local aimHeight = resultToUse * distance
	local aimFarPos = goalPosNormal * (1.0 + aimHeight)
	local aimDirection = normalize(aimFarPos - startPosNormal)

	return aimDirection * velocity
end

function debugLog(foo)
	mj:log(foo)
end

return mj
