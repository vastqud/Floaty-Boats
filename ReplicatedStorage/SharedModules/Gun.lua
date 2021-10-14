local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FastCast = require(ReplicatedStorage.FastCastRedux)
local Guns = require(ReplicatedStorage.SharedModules.Guns)

local params = RaycastParams.new()
params.CollisionGroup = "GunSpawn"
local behavior = FastCast.newBehavior()
behavior.Acceleration = Vector3.new(0, -196.2, 0)
behavior.RaycastParams = params

local GunEffects = {}

local function createProjectile(origin)
	local p = ReplicatedStorage.Projectile:Clone()
	p.Position = origin
	p.Parent = workspace
	
	return p
end

if RunService:IsServer() then
	--FastCast.VisualizeCasts = true
end

function GunEffects.InitiateProjectile(origin, direction, gun, parameters)
	local projectile = nil
	if (not parameters["noPhysical"]) then
		projectile = createProjectile(origin)
	end
	local caster = FastCast.new()
	caster:Fire(
		origin,
		direction,
		direction * gun.MuzzleVelocity,
		behavior
	)
	if (not parameters["noPhysical"]) then
		caster.LengthChanged:Connect(function(active)
			projectile.Position = active:GetPosition()
		end)
	end
	caster.CastTerminating:Connect(function(active)
		if RunService:IsClient() then print("hit") end
		if gun.Type == "Explosive" then
			if (not parameters["doNotExplode"]) then
				gun.Explosion(active:GetPosition())
			end
		end
		if projectile then
			projectile.ParticleEmitter.Enabled = false
			projectile.Transparency = 1
			projectile.Trail.Enabled = false
			projectile.SurfaceLight:Destroy()
		end
		coroutine.wrap(function()
			wait(2.1)
			if projectile then projectile:Destroy() end
		end)()
	end)
	
	caster = nil
end

return GunEffects