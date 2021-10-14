local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GunStats = require(ReplicatedStorage.SharedModules.Guns)
local FastCast = require(ReplicatedStorage.FastCastRedux)
local GunEffects = require(ReplicatedStorage.SharedModules.Gun)

local PlayerShots = {}

ReplicatedStorage.Remotes.GunFire.OnServerEvent:Connect(function(player, data)
	if not player:FindFirstChild("Boat") then return end
	local boat = player.Boat.Value
	if not boat then return end
	
	local gun = boat:FindFirstChild("Gun")	
	if not gun then return end
	
	local gunName = gun:GetAttribute("GunName")
	local gunStats = GunStats.Stats[gunName]
	local firePart = gun:FindFirstChild("Spawn", true)
	
	if (tick() - (PlayerShots[player.UserId] or 0)) < gunStats.Cooldown then return end
	PlayerShots[player.UserId] = tick()
	
	local origin, direction = data.Origin, data.Direction
	if (firePart.Position - origin).Magnitude > 10 then print("Too far") return end
	
	local isProjectile = gunStats.ShotType == "Projectile" and true or false
	for _, thisPlayer in pairs(Players:GetPlayers()) do
		if thisPlayer ~= player then
			ReplicatedStorage.Remotes.GunFire:FireClient(thisPlayer, isProjectile, {
				GunName = gunName,
				Origin = origin,
				Direction = direction,
				Part = firePart
			})
		end
	end
	
	if isProjectile then
		GunEffects.InitiateProjectile(origin, direction, gunStats, {noPhysical = true})
	end
end)

Players.PlayerRemoving:Connect(function(p)
	if PlayerShots[p.UserId] then
		PlayerShots[p.UserId] = nil
	end
end)