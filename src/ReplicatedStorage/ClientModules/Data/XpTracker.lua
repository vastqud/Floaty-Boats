local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local XpData = require(ReplicatedStorage.SharedModules.XPData)
local Formatting = require(ReplicatedStorage.SharedModules.Formatting)

local UpdateRemote = ReplicatedStorage.Remotes.Xp
local MoneyUpdateRemote = ReplicatedStorage.Remotes.Money

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local LastMoney = -500

local XpTracking = {}
XpTracking.Level = 0
XpTracking.Xp = 0

function XpTracking.GetCumulative()
    local cumulative = 0
    for i = 1, XpTracking.Level do
        cumulative = cumulative + (i * XpData.Base)
    end

    return cumulative + XpTracking.Xp
end

local function updateHUD()
    --[[local display = hud.xp

    local required = (XpTracking.Level + 1) * XpData.Base
    local percent = XpTracking.Xp/required

    display.bar.current.Text = XpTracking.Level
    display.bar.next.Text = XpTracking.Level + 1
    display.bar.progress.Size = UDim2.new(percent, 0, 1, 0)

    local currentXpText = Formatting.AddCommas(XpTracking.Xp)
    local requiredXpText = Formatting.AddCommas(required)
    display.hover.Text = currentXpText .. "/" .. requiredXpText]]
end

local function onUpdate(tab)
    XpTracking.Level = tab.Level; XpTracking.Xp = tab.Xp

    updateHUD()
end

local function updateMoney(newValue)
	if LastMoney == -500 then LastMoney = newValue end
	
	if (newValue - LastMoney) >= 0 then --increased or same
		--
	else --decreased
		
	end
end

UpdateRemote.OnClientEvent:Connect(onUpdate)
MoneyUpdateRemote.OnClientEvent:Connect(updateMoney)


return XpTracking