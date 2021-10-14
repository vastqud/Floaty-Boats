local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui
local Ui = script.Parent

local Logo = Ui.Frame.ImageLabel
local Gradient = Logo.UIGradient
local holder = Ui.holder
local logoFrame = Ui.Frame

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local coreCall do
	local MAX_RETRIES = 8

	local StarterGui = game:GetService('StarterGui')

	function coreCall(method, ...)
		local result = {}
		for retries = 1, MAX_RETRIES do
			result = {pcall(StarterGui[method], StarterGui, ...)}
			if result[1] then
				break
			end
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

coreCall('SetCore', 'ResetButtonCallback', false)

local logoCon

ReplicatedFirst:RemoveDefaultLoadingScreen()
Ui.Parent = PlayerGui

wait(5)

local incrementingTime = true
local x, y = 0.002, 1
local key1 = NumberSequenceKeypoint.new(0, 0)
local key2 = NumberSequenceKeypoint.new(1, 1)
local speed = 1
local doneBind = Instance.new("BindableEvent")

logoCon = RunService.RenderStepped:Connect(function(dt)
	if incrementingTime then
		x = math.clamp(x + (speed*dt), 0, 1)

		Gradient.Transparency = NumberSequence.new{
			key1, NumberSequenceKeypoint.new(x, 1), key2
		}
	end

	if (1 - x) < 0.02 then
		incrementingTime = false
		y = math.clamp(y - (speed*dt), 0, 1)

		Gradient.Transparency = NumberSequence.new{
			key1, NumberSequenceKeypoint.new(0.999, y), key2
		}

		if y < 0.01 then doneBind:Fire() logoCon:Disconnect() end
	end
end)

doneBind.Event:Wait()
doneBind:Destroy()

if not game:IsLoaded() then game.Loaded:Wait() end
local Lobby = require(ReplicatedStorage.ClientModules.Ui.Lobby)
Ui:Destroy()
Lobby.Start()
--[[wait(3)

local Fade = require(ReplicatedStorage.ClientModules.Ui.Fade)
local Lobby = require(ReplicatedStorage.ClientModules.Ui.Lobby)
Fade(true, 2, function()
	holder.Visible = true
	logoFrame.Visible = false
end, 0.2)

local gradientColors = holder.top:GetChildren()
local startTime = 0.4
for count, frame in ipairs(gradientColors) do
	local tween = TweenService:Create(frame, TweenInfo.new(startTime + (count-1)*0.05), {Size = UDim2.new(1, 0, 0.125, 0)})
	tween:Play()
	--tween.Completed:Wait()
end

wait(2.5)

Fade(false, 1.5, function()
	Ui:Destroy()
	Lobby.Start()
end)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)]]
