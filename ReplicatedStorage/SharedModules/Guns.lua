local RunService = game:GetService("RunService")
local BoatDestruction
if RunService:IsServer() then
	BoatDestruction = require(game.ServerScriptService.Modules.BoatDestruction)
end

local EXPLOSION_DAMAGE = 17

local Guns = {}
Guns.Stats = {
	["Launcher"] = {
		Type = "Explosive",
		ShotType = "Projectile",
		Cooldown = 1.5,
		MuzzleVelocity = 820,
		Impulse = 200,
		Explosion = function(position)
			local explosion = Instance.new("Explosion")
			explosion.BlastRadius = 5
			explosion.ExplosionType = Enum.ExplosionType.Craters
			explosion.DestroyJointRadiusPercent = 0
			explosion.BlastPressure = 10000
			explosion.Position = position
			explosion.Parent = game.Workspace
			
			explosion.Hit:Connect(function(part, distance)
				distance = distance * 0.2
				distance = math.clamp(distance, 1, 100)
				local damage = math.clamp(EXPLOSION_DAMAGE / distance, 0, EXPLOSION_DAMAGE)
				
				BoatDestruction.Damage(part, damage)
			end)
		end,
	}
}

return Guns