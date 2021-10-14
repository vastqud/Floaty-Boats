local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local BoatUtility = require(ReplicatedStorage.SharedModules.BoatUtility)

local Destruction = {}
Destruction.Debris = {}

local DESPAWN_TIME = 10

local function stepDebris()
	for part, timeAdded in pairs(Destruction.Debris) do
		if (tick() - timeAdded) >= DESPAWN_TIME then
			Destruction.Debris[part] = nil
			part:Destroy()
		end
	end
end

local function makeFire(part)
	local firePart = part.FirePart.Value
	if firePart:FindFirstChild("Fire") then return end
	local f = Instance.new("Fire")
	f.Size = 1.2
	f.Parent = firePart
	
	if firePart:FindFirstChild("Smoke") then
		firePart.Smoke:Destroy()
	end
end

local function makeSmoke(part)
	local firePart = part.FirePart.Value
	if firePart:FindFirstChild("Smoke") then return end
	local s = Instance.new("Smoke")
	s.Size = 0.1
	s.Color = Color3.fromRGB(111,111,111)
	s.Parent = firePart
end

local function damageDensity(part)
	if not part.CustomPhysicalProperties then return end
	local old = part.CustomPhysicalProperties
	local new = PhysicalProperties.new(
		old.Density + 0.3,
		0,
		0
	)
	part.CustomPhysicalProperties = new
end

function Destruction.AddDebris(part)
	if not Destruction.Debris[part] then
		Destruction.Debris[part] = tick()
	end
end

function Destruction.BreakPartWeld(part)
	for _, weld in pairs(CollectionService:GetTagged("Welds")) do
		if (weld.Part1 == part) or (weld.Part0 == part) then
			weld:Destroy()
			Destruction.AddDebris(part)
		end
	end
end

function Destruction.GiveHealth(part)
	if part.Name == "float" then return end
	if part.Name == "base" then part:SetAttribute("Health", 45) return end
	local healthMultipler = BoatUtility.ArmorValues[part.Material.Name] or 1
	part:SetAttribute("Health", healthMultipler * 10)
end

function Destruction.Damage(partTouched, damage)
	if not partTouched:GetAttribute("Health") then return end
	local currentHealth = partTouched:GetAttribute("Health")
	local newHealth = currentHealth - damage
	partTouched:SetAttribute("Health", newHealth)

	if newHealth <= 0 then
		partTouched:SetAttribute("Health", nil)
		Destruction.BreakPartWeld(partTouched)
		
		local parent = partTouched.Parent
		partTouched.Parent = workspace.Broken
		
		if partTouched.Name == "hinge" then
			makeFire(partTouched)
			return
		end
		if parent.Name == "paddle" then
			local otherPart = parent:FindFirstChild("Part")
			if otherPart then
				makeSmoke(parent.hinge)
			else
				makeFire(parent.hinge)
			end
		end
		
		return
	end
	
	if newHealth < 10 then
		partTouched.Material = Enum.Material.CorrodedMetal
		damageDensity(partTouched)
		if partTouched.Name == "hinge" then
			makeSmoke(partTouched)
		end
	end
end

RunService.Heartbeat:Connect(stepDebris)

return Destruction