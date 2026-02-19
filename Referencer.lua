--[[
Referencer.Find()로 반환받은 값은 벨류를가진 인덱스 자체가 아니라 인덱스의 상위테이블임 (참조 이슈)

ex) 
	[string]: {any;} -> X 
	[string]: {[string]: {any;};} -> O
]]
local Referencer = {}

local MasterCache = setmetatable({}, {__mode = "k"})

local function Search (target, key)
	for i, v in pairs(target) do
		if i == key then
			return target
		end

		if type(v) == "table" then
			local _t = Search(v, key)
			if _t then return _t end
		end
	end
end

local function pathFinder (target, path)
	local current = target
	for i = 1, #path - 1 do
		current = current[path[i]]
		if type(current) ~= "table" then return nil end
	end
	return (type(current) == "table") and current or nil
end

function Referencer.Find (targetTable, pathKey)
	MasterCache[targetTable] = MasterCache[targetTable] or {}

	local Cache = MasterCache[targetTable]

	local cacheKey = type(pathKey) == "table" and table.concat(pathKey, ".") or pathKey

	if not Cache[cacheKey] then
		if type(pathKey) == "table" then
			Cache[cacheKey] = pathFinder(targetTable, pathKey)
		else
			Cache[cacheKey] = Search(targetTable, pathKey)
		end
	end

	return Cache[cacheKey]
end

return Referencer
