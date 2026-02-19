--[Service]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[Modules]
local HighlightModule = require(script.Parent.Parent:FindFirstChild("HighlightModule"))
local AnimationModule = require(ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("AnimationModule"))
local SoundModule = require(ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("SoundModule"))
local ParticleModule = require(ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("ParticleModule"))

--[Objects]
local castbranch = workspace

--[Functions]
local function Hit(Character)
	coroutine.resume(coroutine.create(function()
		Character:SetAttribute("Block", false)
		Character:SetAttribute("Stun", 1)
		HighlightModule.Fire(Character, Color3.new(1,1,1))
		local SetAudio = SoundModule.new(Character:FindFirstChild("HumanoidRootPart"))
		SetAudio:SetAudio("Hit", 1):Play()
		local SetAnim = AnimationModule.new(Character)
		SetAnim:SetAnimation("Ouch", math.random(1, 7)):Play()
	end))
end

local function Guard(Character)
	coroutine.resume(coroutine.create(function()
		local SetEmit = ParticleModule.new(Character)
		SetEmit:SetParticle("BlockedParticle", "", {"HumanoidRootPart"}):Emit(0.5, 1, 0)
		local SetAudio = SoundModule.new(Character:FindFirstChild("HumanoidRootPart"))
		SetAudio:SetAudio("Hit", 2):Play()
		local SetAnim = AnimationModule.new(Character)
		SetAnim:SetAnimation("Guard", math.random(1, 2)):Play()
	end))
end


local function GetDistance(Object : any, EnemyCharacter : Instance)
	local EnemyHRP = EnemyCharacter:FindFirstChild("HumanoidRootPart")
	return (Object.CFrame.Position - EnemyHRP.CFrame.Position)
end

local function dotProductCast(Object : any, Distance, Theta : number, Range : number)
	return Distance.Magnitude <= Range and Distance.Magnitude > 1 and
		((Object.CFrame * CFrame.new(0,0, -1)).LookVector):Dot(Distance.Unit/2) < -Theta
end

local function CircleCast(Object : any, Distance, Range : number)
	return Distance.Magnitude <= Range
end

local function GetCharacter(Object : any)
	local Sum = {}
	for i, v : Instance in ipairs(castbranch:GetChildren()) do
		if v:IsA("Model") and v ~= Object.Parent and v:FindFirstChild("HumanoidRootPart") and v:GetAttribute("Hit") == true then
			table.insert(Sum, v)
		end
	end
	return Sum
end

--[Objects: Case]
local HitboxDesign = {
	["dotproduct"] = function(Object : any, Theta : number, Range : number)
		local Sum = {}
		for i, EnemyCharacter : Instance in GetCharacter(Object) do
			local Distance = GetDistance(Object, EnemyCharacter)

			if dotProductCast(Object, Distance, Theta, Range) and not table.find(Sum, EnemyCharacter) then
				table.insert(Sum, EnemyCharacter)
			end
		end
		return Sum
	end,
	["box"] = function(Character : Instance, Size : Vector3, Position : CFrame)
		local Sum = {}

		return Sum
	end,
	["Circle"] = function(Object : any, Range : number)
		local Sum = {}
		spawn(function()
			for i, EnemyCharacter : Instance in GetCharacter(Object) do
				local Distance = GetDistance(Object, EnemyCharacter)
				if CircleCast(Object, Distance, Range) and not table.find(Sum, EnemyCharacter) then
					table.insert(Sum, EnemyCharacter)
				end
			end
		end)
		return Sum
	end,
}

local case = {
	["Back"] = function(EnemyCharacter, Object : any)
		local Sum = {}
		for i, Character : Instance in EnemyCharacter do
			local EnemyHRP = Character:FindFirstChild("HumanoidRootPart")
			local Distance = GetDistance(Object, Character)
			if Character:GetAttribute("Block") == true 
				and (Object.CFrame.LookVector):Dot(Distance.Unit/2) < -0.2 and (-EnemyHRP.CFrame.LookVector):Dot(Distance.Unit/2) < -0.1 then
				if not table.find(Sum, Character) then
					table.insert(Sum, Character)
				end
			end
		end
		return Sum
	end,
	["circle_blockable"] = function(EnemyCharacter, Object : any)
		local Sum = {}
		for i, Character : Instance in EnemyCharacter do
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			local Distance = GetDistance(Character, Object)
			if (HRP.CFrame.LookVector):Dot(Distance.Unit/2) < -0.33 then
				if not table.find(Sum, Character) then
					table.insert(Sum, Character)
				end
			end
		end
		return Sum
	end,
}

local effect = {
	["ignore"] = function(EnemyCharacter, Damage : number, Late : number, Rate : number)
		local Humanoid = EnemyCharacter:FindFirstChild("Humanoid")
		spawn(function()
			for i=1, Rate do
				Humanoid:TakeDamage(Damage)
				Hit(EnemyCharacter)
				task.wait(Late)
			end
		end)
	end,
	["exclude"] = function(EnemyCharacter, Damage : number, Late : number, Rate : number)
		local Humanoid = EnemyCharacter:FindFirstChild("Humanoid")
		spawn(function()
			for i=1, Rate do
				if EnemyCharacter:GetAttribute("Block") == true then
					Guard(EnemyCharacter)
				else
					Humanoid:TakeDamage(Damage)
					Hit(EnemyCharacter)
				end
				task.wait(Late)
			end
		end)
	end,
}

--[Functions: Methods]
local function GetMethod(Method)
	local Sum = {}
	for i, v in Method do
		local Enemy = HitboxDesign[i](unpack(v))
		for n, x in Enemy do
			if not table.find(Sum, x) then
				table.insert(Sum, x)
			end
		end
	end
	return Sum
end

local function GetCase(EnemyCharacter, Case)
	local Sum = {}
	for i, v in Case do
		local Enemy = case[i](EnemyCharacter, unpack(v))
		for s, t in Enemy do
			table.insert(Sum, t)
		end
	end
	return Sum
end

local function TakeEffect(EnemyCharacter, Effect)
	for i, v in Effect do
		effect[i](EnemyCharacter, unpack(v))
	end
end

local function TakeCurrentEffect(EnemyCharacter, Effect)
	for i, v in Effect do
		effect[i](EnemyCharacter, unpack(v))
	end
end

--[HitboxCaster_v1]
local HitboxCaster = {}

--[Function]
function HitboxCaster.CastStart(self, CastingMount)
	local CastCharacter = {}
	local CaseFilter = {}
	coroutine.resume(coroutine.create(function()
		local t0 = {}
		local t1 = {}
		for i = 1, CastingMount do
			coroutine.resume(coroutine.create(function()
				CastCharacter = GetMethod(self.castStyle)
				CaseFilter = GetCase(CastCharacter, self.case)

				local CurrentSum = CastCharacter

				for s, x in CurrentSum do
					if table.find(CaseFilter, x) then
						table.remove(CurrentSum, s)
					end
				end

				for _, v in CaseFilter do
					if not table.find(t0, v)then
						table.insert(t0, v)
						local CaseAction = TakeEffect(v, self.effect)
					end
				end

				for _, v in CurrentSum do
					if not table.find(t1, v)then
						table.insert(t1, v)
						local CurrentAction = TakeCurrentEffect(v, self.currentEffect)
					end
				end

			end))

			task.wait()
		end
	end))
end

--[Main]
return HitboxCaster
