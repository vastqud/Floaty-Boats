local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Boats = require(ReplicatedStorage.ClientModules.Data.Boats)
local Lobby = require(ReplicatedStorage.ClientModules.Ui.Lobby)
local GunEffects = require(ReplicatedStorage.SharedModules.Gun)
local GunStats = require(ReplicatedStorage.SharedModules.Guns)
local CameraShake = require(ReplicatedStorage.CameraShaker)
--yoyoyo
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui = Player.PlayerGui
local Humanoid = Character:WaitForChild("Humanoid")
local Mouse = Player:GetMouse()
local Cam = workspace.CurrentCamera
local Params = RaycastParams.new()

local InputConnections = {}

local function endControl()
	for i,v in pairs(InputConnections) do
		v:Disconnect()
	end
	InputConnections = {}
	Lobby.Close()
	PlayerGui.Hit.Enabled = false
	UserInputService.MouseIconEnabled = true
end

local function getMotors(seat, accel)
	local boat = seat.Parent
	local motors = {}
	
	for _, object in pairs(boat:GetDescendants()) do
		if object.Name == "Motor" then
			motors[#motors+1] = object
			object.MotorMaxAcceleration = accel
		end
	end
	
	return motors
end

local function shakeCamera(cf)
	Cam.CFrame = Cam.CFrame * cf
end
local renderPriority = Enum.RenderPriority.Camera.Value + 1
local camShake = CameraShake.new(renderPriority, shakeCamera)
camShake:Start()

local function getGyros(seat)
	local boat = seat.Parent
	local gyros = {}
	local base
	
	for _, object in pairs(boat:GetDescendants()) do
		if object.Name == "BodyGyro" then
			gyros[#gyros+1] = object
		end
	end
	
	if boat:FindFirstChild("Gun") then
		base = boat.Gun.base
	end
	
	return gyros, base
end

local function lerp(start, target, t)
	return start * (1 - t) + target * t
end

local function getRayHit(origin, direction)
	local result = workspace:Raycast(origin, direction * 2000, Params)
	
	if result then
		return result.Position
	end
end

local function playSound(name, part, destroyPart)
	local s = game.SoundService.Effects:FindFirstChild(name):Clone()
	s.Parent = part
	s:Play()
	
	s.Ended:Connect(function()
		s:Destroy()
		if destroyPart then part:Destroy() end
	end)
end

local function initControl(seat)
	local throttleTarget = 0
	local steerTarget = 0
	local steer = 0
	
	local boatStats = Boats[seat.Parent.Name]
	local motors = getMotors(seat, boatStats.Acceleration)
	local gyros, gunBase = getGyros(seat)
	local base = seat.Parent.base
	
	local gunOriginPart
	local cooldown
	local gunStats
	local gunName
	local currentCooldown = 0
	local barrel = nil
	local pSpawn
	local lastFire = 0
	if gunBase then
		barrel = gunBase.Parent.gun.barrel.ForcePart
		gunName = gunBase.Parent:GetAttribute("GunName")
		gunOriginPart = barrel.Parent.Spawn
		gunStats = GunStats.Stats[gunName]
		cooldown = gunStats.Cooldown
		pSpawn = barrel.Parent.Spawn
		
		PlayerGui.Hit.Enabled = true
	end
	UserInputService.MouseIconEnabled = false
	PlayerGui.Cursor.Enabled = true
	
	local function shoot()
		if (tick() - lastFire) < gunStats.Cooldown then return end
		if (Mouse.Hit.Position - pSpawn.Position).Magnitude < 10 then return end
		lastFire = tick()

		barrel:ApplyImpulseAtPosition(-pSpawn.CFrame.LookVector * gunStats.Impulse, pSpawn.Position)
		ReplicatedStorage.Remotes.GunFire:FireServer({
			Origin = pSpawn.Position,
			Direction = pSpawn.CFrame.LookVector
		})

		if gunStats.ShotType == "Projectile" then
			GunEffects.InitiateProjectile(pSpawn.Position, pSpawn.CFrame.LookVector, gunStats, {doNotExplode = true})
		end

		playSound("105", pSpawn)
		camShake:Shake(CameraShake.Presets.Bump)
		currentCooldown = 0
		
		coroutine.wrap(function()
			gunBase.Parent.particle.big.Enabled = true; gunBase.Parent.particle.long.Enabled = true
			wait(0.15)
			gunBase.Parent.particle.big.Enabled = false; gunBase.Parent.particle.long.Enabled = false
		end)()
	end
	
	InputConnections[#InputConnections+1] = UserInputService.InputBegan:Connect(function(inp)
		if (inp.KeyCode == Enum.KeyCode.W) or (inp.KeyCode == Enum.KeyCode.S) then
			throttleTarget = (inp.KeyCode == Enum.KeyCode.W) and boatStats.MaxThrottle or -boatStats.MaxThrottle
		elseif (inp.KeyCode == Enum.KeyCode.A) or (inp.KeyCode == Enum.KeyCode.D) then
			steerTarget = (inp.KeyCode == Enum.KeyCode.A) and boatStats.MaxSteer or -boatStats.MaxSteer
		end
	end)
	InputConnections[#InputConnections+1] = UserInputService.InputEnded:Connect(function(inp)
		if (inp.KeyCode == Enum.KeyCode.W) or (inp.KeyCode == Enum.KeyCode.S) then
			throttleTarget = 0
		elseif (inp.KeyCode == Enum.KeyCode.A) or (inp.KeyCode == Enum.KeyCode.D) then
			steerTarget = 0
		end
	end)
	InputConnections[#InputConnections+1] = RunService.RenderStepped:Connect(function(dt)
		steer = lerp(steer, steerTarget, dt*boatStats.SteerSpeed)
		
		for _, motor in pairs(motors) do
			motor.AngularVelocity = throttleTarget * motor.Value.Value
		end

		if gunBase then
			for _, gyro in pairs(gyros) do
				local mousePos = Mouse.Hit.Position
				gyro.CFrame = CFrame.new(gunBase.CFrame.Position, mousePos)
			end
			
			local pos = getRayHit(gunOriginPart.Position, gunOriginPart.CFrame.LookVector)
			if not pos then pos = gunOriginPart.Position + gunOriginPart.CFrame.LookVector*2000 end
			local screenPos, onscreen = Cam:WorldToScreenPoint(pos)
			PlayerGui.Hit.Frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
			
			currentCooldown = math.clamp(currentCooldown + dt, 0, cooldown)
			PlayerGui.Hit.Frame.reload.bar.Size = UDim2.new(currentCooldown/cooldown, 0, 1, 0)
			
			PlayerGui.Hit.Frame.reload.ready.Visible = currentCooldown == cooldown and true or false
			PlayerGui.Hit.Frame.reload.bar.BackgroundColor3 = currentCooldown == cooldown and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
			PlayerGui.Hit.Frame.marker.TextColor3 = currentCooldown == cooldown and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
			
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				shoot()
			end
			
			local mouse3d = Mouse.Hit.Position
			local mousePos = Vector2.new(mouse3d.X, mouse3d.Z)
			local basePos = Vector2.new(gunBase.Position.X, gunBase.Position.Z)
			local between = mousePos - basePos
			local relative = Vector2.new(gunBase.Parent.Platform.CFrame.LookVector.X, gunBase.Parent.Platform.CFrame.LookVector.Z)
			local y = mouse3d.Y - gunBase.Position.Y
			local hyp = (mouse3d - gunBase.Position).Magnitude
			local xAngle = math.deg(math.asin(y / hyp)) - gunBase.Parent.Platform.Orientation.Z
			
			local dot = between.X * relative.X + between.Y * relative.Y
			local det = between.X * relative.Y - between.Y * relative.X
			local angle = math.deg(math.atan2(det, dot))
			if angle < 0 then angle = angle + 360 end
			gunBase.Parent.Hinges.Y.TargetAngle = angle
			gunBase.Parent.Hinges.X.TargetAngle = xAngle
		end
		
		base.AngularVelocity.AngularVelocity = Vector3.new(0, steer, 0)
		PlayerGui.Cursor.Frame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
	end)
end

local function seatChanged()
	local seat = Humanoid.SeatPart
	
	if seat then
		initControl(seat)
	end
end

Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(seatChanged)
Humanoid.Died:Connect(endControl)
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(seatChanged)
	Humanoid.Died:Connect(endControl)
	
	Lobby.Start()
end)

ReplicatedStorage.Remotes.GunFire.OnClientEvent:Connect(function(projectile, data)
	if projectile then
		GunEffects.InitiateProjectile(data.Origin, data.Direction, GunStats.Stats[data.GunName], {doNotExplode = true})
		playSound("105", data.Part)
	end
end)

workspace.ChildAdded:Connect(function(c)
	if c:IsA("Explosion") then
		if Character and Character:FindFirstChild("HumanoidRootPart") then
			if (Character.PrimaryPart.Position - c.Position).Magnitude <= 65 then
				camShake:Shake(CameraShake.Presets.Explosion)
			end
		end
		
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 1
		p.Position = c.Position
		p.Parent = workspace
		playSound("Explosion", p, true)
	end
end)
