local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Boats = require(ReplicatedStorage.ClientModules.Data.Boats)
local BoatUtility = require(ReplicatedStorage.SharedModules.BoatUtility)

local BoatList = {}
BoatList.Ui = nil

local function getAverageArmor(boat)
	local boatModel = ReplicatedStorage.BoatModels:FindFirstChild(boat)
	local numParts = 0
	local total = 0
	
	for _, object in pairs(boatModel:GetDescendants()) do
		if object:IsA("BasePart") then
			numParts = numParts + 1
			local armor = BoatUtility.ArmorValues[object.Material.Name] or 1
			local final = armor * 10
			total = total + final
		end
	end
	
	return math.round(total / numParts)
end

local function buildViewport(name, frame, offset)
	if frame:FindFirstChild("Camera") then frame.Camera:Destroy() end
	if frame:FindFirstChild("boat") then frame.boat:Destroy() end
	
	local newCam = Instance.new("Camera", frame)
	local model = ReplicatedStorage.BoatModels:FindFirstChild(name):Clone()
	model.PrimaryPart.Anchored = true
	model.Name = "boat"
	
	frame.CurrentCamera = newCam
	model.Parent = frame
	
	local cframe = model.PrimaryPart.CFrame
	newCam.CFrame = CFrame.new(cframe.Position + Vector3.new(0, 5, -offset), cframe.Position)
end

function BoatList.Show(name, ui, selected)
	if ui then BoatList.Ui = ui end
	local stat = Boats[name]
	local statsFrame = BoatList.Ui.stats.holder
	
	statsFrame.accel.Text = '<b>Acceleration: </b>' .. stat.Acceleration
	statsFrame.armor.Text = '<b>Average Armor: </b>' .. getAverageArmor(name)
	statsFrame.weapon.Text = '<b>Main Weapon: </b>' .. stat.MainWeapon
	
	if name == selected then
		statsFrame.Parent.select.BackgroundColor3 = Color3.fromRGB(48,163,128)
	else
		statsFrame.Parent.select.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
	end
	
	BoatList.Ui.name.Text = name
	buildViewport(name, BoatList.Ui.ViewportFrame, stat.Offset)
end

return BoatList
