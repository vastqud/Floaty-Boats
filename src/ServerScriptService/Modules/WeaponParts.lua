local ServerScriptService = game:GetService("ServerScriptService")
local BoatDestruction = require(ServerScriptService.Modules.BoatDestruction)

local WeaponParts = {}

function WeaponParts.AddBoat(model)
	for _, object in pairs(model:GetDescendants()) do
		if object:GetAttribute("Melee") then
			object.Touched:Connect(function(p)
				BoatDestruction.Damage(p, 1.35)
			end)
		end
	end
end

return WeaponParts