local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local WeaponParts = require(ServerScriptService.Modules.WeaponParts)
local BoatDestruction = require(ServerScriptService.Modules.BoatDestruction)

local Rand = Random.new()
local LastSpawnPart = nil

local function setUpBoat(model, player)
	model.PrimaryPart:SetNetworkOwner(player)
	
	for _, object in pairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			BoatDestruction.GiveHealth(object)
			if object.Parent.Name == "paddle" then
				PhysicsService:SetPartCollisionGroup(object, "Paddles")
			elseif (object.Name == "float") then
				PhysicsService:SetPartCollisionGroup(object, "float")
			elseif object.Name == "Spawn" then
				PhysicsService:SetPartCollisionGroup(object, "GunSpawn")
			else
				PhysicsService:SetPartCollisionGroup(object, "BoatParts")
			end
		end
		if object:IsA("WeldConstraint") then
			if object.Parent.Name ~= "hingeP" then
				CollectionService:AddTag(object, "Welds")
			end
		end
	end
	
	local pointer = Instance.new("ObjectValue", player)
	pointer.Name = "Boat"
	pointer.Value = model
end

local function processSpawn(player, boat)
	--if player owns boat
	local character = player.Character
	local humanoid = character.Humanoid
	
	local boat = ReplicatedStorage.BoatModels:FindFirstChild(boat)
	local clone = boat:Clone()
	local spawns = workspace.Spawns:GetChildren()
	local chosenSpawn = spawns[Rand:NextInteger(1, #spawns)]
	if chosenSpawn == LastSpawnPart then
		repeat
			chosenSpawn = spawns[Rand:NextInteger(1, #spawns)]
		until chosenSpawn ~= LastSpawnPart
	end
	LastSpawnPart = chosenSpawn
	
	clone:SetPrimaryPartCFrame(chosenSpawn.CFrame)
	clone.Parent = workspace
	local pos = clone.VehicleSeat.CFrame.Position
	
	character:SetPrimaryPartCFrame(CFrame.new(pos.X, pos.Y + 5, pos.Z))
	setUpBoat(clone, player)
	clone.VehicleSeat:Sit(humanoid)
	
	WeaponParts.AddBoat(clone)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Swimming then
				hum.Health = 0
			end
		end)
		hum.Died:Connect(function()
			local model = player.Boat.Value
			player.Boat:Destroy()
			if model:FindFirstChild("AngularVelocity", true) then
				model:FindFirstChild("AngularVelocity", true).AngularVelocity = Vector3.new()
			end
			if model then
				wait(15)
				model:Destroy()
			end
		end)
	end)
end)

ReplicatedStorage.Remotes.Spawn.OnServerInvoke = processSpawn