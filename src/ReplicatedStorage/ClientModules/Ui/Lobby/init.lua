local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fade = require(ReplicatedStorage.ClientModules.Ui.Fade)
local Boats = require(ReplicatedStorage.ClientModules.Data.Boats)
local Utility = require(script.BoatList)

local UiTemplate = ReplicatedStorage.UiStorage.main
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Camera = workspace.CurrentCamera

local fading = false

local Lobby = {}
Lobby.InLobby = false
Lobby.Ui = nil
Lobby.SelectedBoat = "Stingray"
Lobby.TreeOpen = false
Lobby.SelectionConnections = {}

local function getAllBoatsOfClass(class)
	local boats = {}
	
	for boatName, boatData in pairs(Boats) do
		if boatData.Class == class then
			boats[#boats+1] = boatName
		end
	end
	
	return boats
end

local function dcSelection()
	for i,v in pairs(Lobby.SelectionConnections) do
		v:Disconnect()
	end
	Lobby.SelectionConnections = {}
end

local function setCam(bool)
	if bool then
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = workspace.LobbyCamera.CFrame
	else
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = Player.Character.Humanoid
	end
end

function Lobby.Start()
	if Lobby.InLobby then return end
	PlayerGui.hud.Enabled = false
	Lobby.InLobby = true
	
	Lobby.Ui = UiTemplate:Clone()
	Lobby.Ui.Parent = PlayerGui
	setCam(true)
	
	Lobby.ConnectButtons()
end

function Lobby.ConnectButtons()
	local buttons = Lobby.Ui.bottom.buttons
	local treeButtons = Lobby.Ui.techtree.class.holder
	
	buttons.deploy.MouseButton1Click:Connect(function()
		if fading then return end
		fading = true
		Fade(true, 2, function()
			Lobby.Close()
			ReplicatedStorage.Remotes.Spawn:InvokeServer(Lobby.SelectedBoat)
			PlayerGui.hud.Enabled = true
			fading = false
		end, 0.2)
	end)
	buttons.techtree.MouseButton1Click:Connect(function()
		Lobby.ToggleTechTree()
	end)
	for _, object in pairs(treeButtons:GetChildren()) do
		if object:IsA("TextButton") then
			object.MouseButton1Click:Connect(function()
				Lobby.OpenBoatsOfClass(object.Name)
			end)
		end
	end
end

function Lobby.ToggleTechTree()
	local overallFrame = Lobby.Ui.techtree
	if Lobby.TreeOpen then
		overallFrame.Visible = false
		Lobby.TreeOpen = false
	else
		Lobby.TreeOpen = true
		overallFrame.boats.Visible = false; overallFrame.class.Visible = true; overallFrame.Visible = true
	end
end

function Lobby.OpenBoatsOfClass(class)
	if #getAllBoatsOfClass(class) == 0 then return end
	dcSelection()
	
	local overallFrame = Lobby.Ui.techtree
	local allBoats = getAllBoatsOfClass(class)
	local currentIndex = 1
	local selection = overallFrame.boats.selection
	
	overallFrame.class.Visible = false; overallFrame.boats.Visible = true
	
	for i,v in pairs(selection.items:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	
	Utility.Show(allBoats[currentIndex], overallFrame.boats, Lobby.SelectedBoat)
	for i, _ in pairs(allBoats) do
		local new = selection.temp:Clone()
		new.Parent = selection.items
		new.Visible = true
		new.Name = i
		
		new.MouseButton1Click:Connect(function()
			currentIndex = i
			Utility.Show(allBoats[currentIndex], nil, Lobby.SelectedBoat)
		end)
	end
	
	Lobby.SelectionConnections[#Lobby.SelectionConnections+1] = selection.next.MouseButton1Click:Connect(function()
		currentIndex = math.clamp(currentIndex + 1, 1, #allBoats)
		Utility.Show(allBoats[currentIndex], nil, Lobby.SelectedBoat)
	end)
	Lobby.SelectionConnections[#Lobby.SelectionConnections+1] = selection.previous.MouseButton1Click:Connect(function()
		currentIndex = math.clamp(currentIndex - 1, 1, #allBoats)
		Utility.Show(allBoats[currentIndex], nil, Lobby.SelectedBoat)
	end)
	Lobby.SelectionConnections[#Lobby.SelectionConnections+1] = overallFrame.boats.stats.select.MouseButton1Click:Connect(function()
		Lobby.SelectedBoat = allBoats[currentIndex]
		
		overallFrame.boats.stats.select.BackgroundColor3 = Color3.fromRGB(48,163,128)
	end)
end

function Lobby.Close()
	Lobby.InLobby = false
	Lobby.Ui:Destroy()
	Lobby.TreeOpen = false
	setCam()
end

return Lobby