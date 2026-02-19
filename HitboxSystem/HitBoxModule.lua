--[[
본 모듈은 순전히 HitboxCaster.lua의 이용을 편리하게 하기 위한 예시 모듈에 불과합니다.
]]

--[Service]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[Objects]
local Modules = ReplicatedStorage:FindFirstChild("Modules")

--[Modules]
local HitboxCaster = require(script:FindFirstChild("HitboxCaster"))

--[HitBoxModule]
local HitBoxModule = {}
HitBoxModule.__index = HitBoxModule

--[Functions]
function HitBoxModule.SetHitbox(Character:Instance, ...)
	local Hitbox = setmetatable({
		character = Character,
		getEnemy = {},
		castStyle = {}, -- SetMethod
		case = {}, -- SetCase
		effect = {}, -- SetEffect
		currentEffect = {}, -- SetcurrentEffect
		epiphany = true,
		connectContent = {
			GetStun = Character:GetAttributeChangedSignal("Stun"):Connect(function()
				if Character:GetAttribute("Stun") > 0 then
					return true
				end
			end),
		},
	}, HitBoxModule)
	if Hitbox.connectContent.GetStun == true then
		Hitbox.epiphany = false
	end
	return Hitbox
end

function HitBoxModule:SetMethod(method : string, ...)-- 내적 히트박스를 사용할지, 박스 히트박스를 사용할지를 결정.
	self.castStyle[method] = {...}
	return self
end

function HitBoxModule:SetCase(style : string, ...)--가드를 무시하는가 or 뒤에서 타격해도 가드에 맞는가 등등 규칙설정.
	self.case[style] = {...}
	return self
end

function HitBoxModule:SetEffect(effect : string, ...)-- 넉백방향, 힘, 움직이는 히트박스, 도트대미지 등 특정효과 삽입할때 쓰임.
	self.effect[effect] = {...}
	return self
end

function HitBoxModule:SetCurrentEffect(effect : string, ...)-- 넉백방향, 힘, 움직이는 히트박스, 도트대미지 등 특정효과 삽입할때 쓰임.
	self.currentEffect[effect] = {...}
	return self
end

function HitBoxModule:CastEnd(Mount : number)
	HitboxCaster.CastStart(self, Mount)
	for _, Connection : RBXScriptConnection in self.connectContent  do
		Connection:Disconnect()
	end
	--Function()
	return self
end

--[Main]
return HitBoxModule
