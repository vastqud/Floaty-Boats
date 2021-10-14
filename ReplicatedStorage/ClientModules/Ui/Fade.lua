local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local fadeUi = ReplicatedStorage.UiStorage.Fade
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local function createFadeFrame(startingTransparency)
	local newFade = fadeUi:Clone()
	newFade.Frame.BackgroundTransparency = startingTransparency
	
	newFade.Parent = PlayerGui
	newFade.Enabled = true
	
	return newFade
end

local function fadeInOrOut(startingTransparency, endingTransparency, targetTime, lastFrame)
	local frame = createFadeFrame(startingTransparency)
	local info = TweenInfo.new(targetTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(frame.Frame, info, {BackgroundTransparency = endingTransparency})
	
	if lastFrame then lastFrame:Destroy() end
	
	tween:Play()
	tween.Completed:Wait()
	
	print("fade finished in/out: " .. targetTime)
	
	return frame
end

local styleMap = {
	InOut = function(targetTime, betweenFunction, waitTime)
		local firstFrame = fadeInOrOut(1, 0, targetTime/2)
		if betweenFunction then betweenFunction() end
		wait(waitTime)
		fadeInOrOut(0, 1, targetTime/2, firstFrame):Destroy()
	end,
}

local function Fade(yield, targetTime, betweenFunction, waitTime) --betweenfunction cannot yield
	local style = "InOut"
	if not targetTime then targetTime = 2.4 end
	if not waitTime then waitTime = 0 end
	
	local styleFunction = styleMap[style]
	
	if yield then --if not yield, call it in a coroutine
		styleFunction(targetTime, betweenFunction, waitTime)
	else
		coroutine.wrap(styleFunction)(targetTime, betweenFunction, waitTime)
	end
end
	
return Fade