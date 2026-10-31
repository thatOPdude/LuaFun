-- =======================================================================
--   ☠ LOAD THE GRIMOIRE UI LIBRARY
-- =======================================================================
local Hallow = loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/Grimoire.lua"))()

-- =======================================================================
--   SERVICES
-- =======================================================================
local Players                = game:GetService("Players")
local Workspace              = game:GetService("Workspace")
local RunService             = game:GetService("RunService")
local Lighting               = game:GetService("Lighting")
local UserInputService       = game:GetService("UserInputService")
local VirtualUser            = game:GetService("VirtualUser")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService           = game:GetService("TweenService")
local GuiService             = game:GetService("GuiService")

pcall(function()
	GuiService:SetGameplayPausedNotificationEnabled(false)
end)

local localPlayer = Players.LocalPlayer
local camera      = Workspace.CurrentCamera

-- =======================================================================
--   STATE CONFIGURATION
-- =======================================================================
local tweenSpeed        = 100
local fastTweenSpeed    = 350
local useTweenForTPs    = false
local OFFSET            = Vector3.new(0, 3, 4)
local activeTween       = nil
local tracerEnabled     = false
local espEnabled        = false
local antiAfkEnabled    = false
local antiAfkConn       = nil
local playerAttachment  = nil
local tracerBeam        = nil

local currentWalkSpeed    = 16
local currentJumpPower    = 50
local currentGravity      = Workspace.Gravity
local infJumpEnabled      = false
local fullbrightEnabled   = false

local noclipEnabled       = false
local noclipConn          = nil

local flyEnabled          = false
local flySpeed            = 60
local flyConn             = nil
local flyKeys             = { W = false, A = false, S = false, D = false, Up = false, Down = false }

local walkOnWaterEnabled  = false
local waterWalkConn       = nil
local waterRayParams      = RaycastParams.new()
waterRayParams.FilterType = Enum.RaycastFilterType.Exclude

local ragdollEnabled      = false

local keybinds = {
	Fly = Enum.KeyCode.None,
	Noclip = Enum.KeyCode.None,
	ESP = Enum.KeyCode.None,
	InfiniteJump = Enum.KeyCode.None,
	Ragdoll = Enum.KeyCode.None
}

local autoTotEnabled      = false
local totLoopRunning      = false
local totDelay            = 0.1
local checkLitOnly        = false
local checkCooldowns      = false
local unlitHouses         = {}
local currentKnockingHouse = nil
local HOUSE_COOLDOWN      = 240

local autoDigEnabled      = false
local digLoopRunning      = false
local digDelay            = 0.2

local autoStartGarages = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false
}

local houseOrder = {
	39, 42, 15, 12, 23, 34, 29, 26, 50, 47,
	35, 18, 37, 33, 49, 19, 21, 27, 28, 36,
	7, 6,
	{ target = 13, tween = true },
	"Trick or Treat House", 8, 16, 43, 17, 10, 38, 4,
	"Halloween Hut", 22, 2, 25, 20, 14, 11, 40, 24,
	31, 41, 30, 44, 32, 48, 39
}

-- =======================================================================
--   INITIALIZE WINDOW
-- =======================================================================
local Win = Hallow:CreateWindow({
	Title = "THE GRIMOIRE",
	Subtitle = "halloween hub",
	Theme = "Pumpkin",
	ToggleKey = Enum.KeyCode.RightControl,
	Width = 660,
	Height = 440
})

Hallow:Notify({
	Title = "Grimoire",
	Content = "The Grimoire loaded successfully.",
	Duration = 3.5,
	Type = "success"
})

-- =======================================================================
--   HELPERS
-- =======================================================================
local function getHumanoid(char)
	char = char or localPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
	char = char or localPlayer.Character
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function applyCharacterSettings(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.UseJumpPower = true
		hum.WalkSpeed    = currentWalkSpeed
		hum.JumpPower    = currentJumpPower
	end
end

local function cancelCurrentTween()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	local hrp = getHRP()
	if hrp then
		hrp.Anchored = false
	end
end

local function fastTweenTo(targetCFrame, customSpeed)
	local hrp = getHRP()
	if not hrp or not targetCFrame then return false end

	cancelCurrentTween()
	pcall(function()
		Workspace:RequestStreamAroundAsync(targetCFrame.Position)
	end)

	local distance = (hrp.Position - targetCFrame.Position).Magnitude
	if distance <= 8 then
		hrp.CFrame = targetCFrame
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	local speed = math.max(50, customSpeed or fastTweenSpeed or 350)
	local duration = math.clamp(distance / speed, 0.05, 3.5)

	local tempNoclip = RunService.Stepped:Connect(function()
		local char = localPlayer.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)

	hrp.Anchored = true
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	activeTween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })

	local done = false
	activeTween.Completed:Connect(function() done = true end)
	activeTween:Play()

	while not done and activeTween do task.wait() end

	if tempNoclip then tempNoclip:Disconnect() end

	if hrp and hrp.Parent then
		hrp.Anchored = false
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	activeTween = nil
	return true
end

local function interactWithPrompt(prompt)
	if not prompt or not prompt.Parent then return end

	pcall(function()
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		if (prompt.MaxActivationDistance or 10) < 25 then
			prompt.MaxActivationDistance = 25
		end
	end)

	if typeof(fireproximityprompt) == "function" then
		pcall(function() fireproximityprompt(prompt, 1, true) end)
		pcall(function() fireproximityprompt(prompt) end)
	else
		pcall(function()
			prompt:InputHoldBegin()
			task.wait(0.05)
			prompt:InputHoldEnd()
		end)
	end
end

local function getHouseCFrame(house)
	if not house then return nil end
	if house:IsA("BasePart") then return house.CFrame end
	if house:IsA("Model") then
		local pp = house.PrimaryPart
		if pp then return pp.CFrame end
		local cf, _ = house:GetBoundingBox()
		if cf and cf.Position.Magnitude > 1 then return cf end
		local p = house:FindFirstChildWhichIsA("BasePart", true)
		if p then return p.CFrame end
		return house:GetPivot()
	end
	return nil
end

-- =======================================================================
--   INSTANT PROMPTS
-- =======================================================================
local instaRepairEnabled     = false
local originalHoldDurations  = {}
local promptConns            = {}

local function setInstantPrompts(state)
	instaRepairEnabled = state
	for _, c in ipairs(promptConns) do c:Disconnect() end
	table.clear(promptConns)

	if state then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				if originalHoldDurations[desc] == nil then originalHoldDurations[desc] = desc.HoldDuration end
				desc.HoldDuration = 0
				desc.RequiresLineOfSight = false
				if (desc.MaxActivationDistance or 10) < 25 then desc.MaxActivationDistance = 25 end
			end
		end

		table.insert(promptConns, ProximityPromptService.PromptShown:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end
			if originalHoldDurations[prompt] == nil then originalHoldDurations[prompt] = prompt.HoldDuration end
			prompt.HoldDuration = 0
			prompt.RequiresLineOfSight = false
			if (prompt.MaxActivationDistance or 10) < 25 then prompt.MaxActivationDistance = 25 end
		end))

		table.insert(promptConns, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end
			interactWithPrompt(prompt)
		end))
	else
		for prompt, origDuration in pairs(originalHoldDurations) do
			if prompt and prompt.Parent then
				pcall(function() prompt.HoldDuration = origDuration end)
			end
		end
		table.clear(originalHoldDurations)
	end
end

-- =======================================================================
--   GARAGES
-- =======================================================================
local function getGarageEnterPrompt(garageNum)
	local debris = Workspace:FindFirstChild("_Debris")
	local garages = (debris and debris:FindFirstChild("Garages")) or Workspace:FindFirstChild("Garages", true)
	if not garages then return nil, nil end

	local garage = garages:FindFirstChild("Halloween Garage " .. tostring(garageNum))
	if not garage then return nil, nil end

	local entry = garage:FindFirstChild("EntrySquare")
	local pPart = entry and entry:FindFirstChild("PromptPart")
	local prompt = pPart and (pPart:FindFirstChild("EnterAuction") or pPart:FindFirstChildOfClass("ProximityPrompt"))

	return prompt, pPart
end

task.spawn(function()
	while true do
		for garageNum = 1, 4 do
			if autoStartGarages[garageNum] then
				local prompt, pPart = getGarageEnterPrompt(garageNum)
				if prompt and prompt.Enabled and pPart then
					local hrp = getHRP()
					if hrp and (hrp.Position - pPart.Position).Magnitude > (prompt.MaxActivationDistance or 10) then
						hrp.CFrame = pPart.CFrame + Vector3.new(0, 3, 0)
						task.wait(0.15)
					end
					interactWithPrompt(prompt)
					task.wait(0.2)
				end
			end
		end
		task.wait(0.5)
	end
end)

-- =======================================================================
--   HALLOWEEN / TRICK OR TREAT
-- =======================================================================
task.spawn(function()
	local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
	local uiFolder = eventsFolder and eventsFolder:WaitForChild("UI", 5)
	local notifyRemote = (uiFolder and uiFolder:FindFirstChild("Notify")) or ReplicatedStorage:FindFirstChild("Notify", true)

	if notifyRemote and notifyRemote:IsA("RemoteEvent") then
		notifyRemote.OnClientEvent:Connect(function(msg)
			if typeof(msg) == "string" and string.find(string.lower(msg), "lights are out") then
				if currentKnockingHouse then
					unlitHouses[currentKnockingHouse] = tick() + HOUSE_COOLDOWN
				end
			end
		end)
	end
end)

local function getHalloweenBuildingFolder()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return nil end
	local hw = areas:FindFirstChild("Halloween")
	if not hw then return nil end
	local tot = hw:FindFirstChild("Haloweem Trick or Treat ") or hw:FindFirstChild("Haloweem Trick or Treat")
	if not tot then return nil end
	return tot:FindFirstChild("Building")
end

local function isHousePhysicallyLit(house)
	if not checkLitOnly then return true end
	if house:GetAttribute("Lit") == false or house:GetAttribute("Active") == false then return false end
	local litVal = house:FindFirstChild("IsLit") or house:FindFirstChild("Lit")
	if litVal and litVal:IsA("BoolValue") and not litVal.Value then return false end
	local hasAnyLightSource = false
	for _, desc in ipairs(house:GetDescendants()) do
		if desc:IsA("Light") then
			hasAnyLightSource = true
			if desc.Enabled then return true end
		end
	end
	return not hasAnyLightSource
end

local function getOrderedHouses()
	local buildingFolder = getHalloweenBuildingFolder()
	if not buildingFolder then return {} end

	local children = buildingFolder:GetChildren()
	local houseList = {}

	for orderIdx, entry in ipairs(houseOrder) do
		local targetRef = entry
		local shouldTween = false
		if typeof(entry) == "table" then
			targetRef = entry.target
			shouldTween = entry.tween or false
		end

		local house = nil
		if typeof(targetRef) == "number" then
			house = children[targetRef] or buildingFolder:FindFirstChild(tostring(targetRef))
		elseif typeof(targetRef) == "string" then
			house = buildingFolder:FindFirstChild(targetRef) or children[tonumber(targetRef)]
		end

		if house and house:IsA("Instance") then
			table.insert(houseList, { order = orderIdx, house = house, shouldTween = shouldTween })
		end
	end
	return houseList
end

local function runTrickOrTreatSweep(singleRun)
	if totLoopRunning and not singleRun then return end
	totLoopRunning = true

	pcall(function()
		local houses = getOrderedHouses()
		if #houses == 0 then
			Hallow:Notify({ Title = "Trick or Treat", Content = "Building folder or houses not found!", Duration = 3, Type = "warn" })
			return
		end

		for _, houseData in ipairs(houses) do
			if not autoTotEnabled and not singleRun then break end
			local house = houseData.house
			local hrp = getHRP()
			if not hrp then break end

			if checkCooldowns and unlitHouses[house] and tick() < unlitHouses[house] then continue end
			if checkLitOnly and not isHousePhysicallyLit(house) then continue end

			currentKnockingHouse = house
			cancelCurrentTween()

			local shouldTween = houseData.shouldTween
			local prompt = house:FindFirstChild("TrickOrTreatPrompt", true) or house:FindFirstChildOfClass("ProximityPrompt", true)
			local promptPoint = house:FindFirstChild("TrickOrTreatPromptPoint", true) or (prompt and prompt.Parent)

			if not promptPoint or not prompt then
				local houseCF = getHouseCFrame(house)
				if houseCF then
					local targetDest = houseCF + Vector3.new(0, 3, 0)
					if shouldTween then fastTweenTo(targetDest, fastTweenSpeed) else hrp.CFrame = targetDest end
					task.wait(0.2)
				end
			end

			if promptPoint then
				local targetCFrame = (promptPoint:IsA("Attachment") and promptPoint.WorldCFrame) or (promptPoint:IsA("BasePart") and promptPoint.CFrame)
				if targetCFrame then
					local targetDest = targetCFrame + Vector3.new(0, 1.5, 0)
					if shouldTween then fastTweenTo(targetDest, fastTweenSpeed) else hrp.CFrame = targetDest end
					task.wait(0.15)
				end
			end

			prompt = prompt or house:FindFirstChild("TrickOrTreatPrompt", true) or house:FindFirstChildOfClass("ProximityPrompt", true)
			if prompt then
				interactWithPrompt(prompt)
				task.wait(0.35)
				if checkCooldowns then unlitHouses[house] = tick() + HOUSE_COOLDOWN end
			end

			task.wait(totDelay)
			currentKnockingHouse = nil
		end
	end)

	totLoopRunning = false
end

-- =======================================================================
--   GRAVE DIGGING
-- =======================================================================
local function getAllGraveSpots()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return {} end
	local hw = areas:FindFirstChild("Halloween")
	if not hw then return {} end

	local list, added = {}, {}
	for _, desc in ipairs(hw:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and (desc.Name == "GraveDigPrompt" or string.find(desc.Name, "Dig")) then
			if not added[desc] then
				added[desc] = true
				table.insert(list, { prompt = desc, point = desc.Parent })
			end
		end
	end
	return list
end

local function runGraveDigSweep(singleRun)
	if digLoopRunning and not singleRun then return end
	digLoopRunning = true

	pcall(function()
		local graves = getAllGraveSpots()
		if #graves == 0 then
			Hallow:Notify({ Title = "Auto Dig Grave", Content = "No graves found in workspace!", Duration = 3, Type = "warn" })
			return
		end

		for _, graveData in ipairs(graves) do
			if not autoDigEnabled and not singleRun then break end
			local hrp = getHRP()
			local prompt = graveData.prompt
			local targetPoint = graveData.point

			if hrp and prompt and prompt.Parent and targetPoint and prompt.Enabled then
				cancelCurrentTween()
				local targetCFrame = (targetPoint:IsA("BasePart") and targetPoint.CFrame) or (targetPoint:IsA("Attachment") and targetPoint.WorldCFrame)
				if targetCFrame then
					hrp.CFrame = targetCFrame + Vector3.new(0, 2.5, 0)
					task.wait(0.15)
					interactWithPrompt(prompt)
					task.wait(0.3)
					task.wait(digDelay)
				end
			end
		end
	end)

	digLoopRunning = false
end

-- =======================================================================
--   PHYSICS / MOVEMENT
-- =======================================================================
local function setNoclip(state)
	noclipEnabled = state
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if state then
		noclipConn = RunService.Stepped:Connect(function()
			local char = localPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end
end

local function getFlyDirection()
	local cf = camera.CFrame
	local dir = Vector3.zero
	if flyKeys.W    then dir += cf.LookVector end
	if flyKeys.S    then dir -= cf.LookVector end
	if flyKeys.A    then dir -= cf.RightVector end
	if flyKeys.D    then dir += cf.RightVector end
	if flyKeys.Up   then dir += Vector3.new(0, 1, 0) end
	if flyKeys.Down then dir -= Vector3.new(0, 1, 0) end
	return dir.Magnitude > 0 and dir.Unit or dir
end

local function setFly(state)
	flyEnabled = state
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	local hum = getHumanoid()
	local hrp = getHRP()

	if state then
		if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
		flyConn = RunService.RenderStepped:Connect(function(dt)
			local root = getHRP()
			if not root then return end
			local moveDir = getFlyDirection() * flySpeed
			if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + (moveDir * dt) end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	else
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
	end
end

local function setWalkOnWater(state)
	walkOnWaterEnabled = state
	if waterWalkConn then waterWalkConn:Disconnect(); waterWalkConn = nil end
	local hum = getHumanoid()
	if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, not state) end

	if state then
		waterWalkConn = RunService.Heartbeat:Connect(function()
			local char = localPlayer.Character
			local hrp = getHRP(char)
			if not hrp then return end
			waterRayParams.FilterDescendantsInstances = { char }
			local ray = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), waterRayParams)
			if ray and ray.Material == Enum.Material.Water then
				local targetY = ray.Position.Y + 2.8
				if hrp.Position.Y < targetY then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
					hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)
				end
			end
		end)
	end
end

local function setRagdoll(state)
	ragdollEnabled = state
	local hum = getHumanoid()
	if not hum then return end
	if state then
		hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
		hum.PlatformStand = true
	else
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

-- =======================================================================
--   ZOMBIE HELPERS
-- =======================================================================
local function getZombies()
	local folder = Workspace:FindFirstChild("_Zombies") or Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Enemies")
	if not folder then return {} end
	local list = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			local hrp = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
			local hum = child:FindFirstChildOfClass("Humanoid")
			if hrp and (not hum or hum.Health > 0) then table.insert(list, child) end
		end
	end
	return list
end

local function getNearestZombie()
	local zombies = getZombies()
	local hrp = getHRP()
	if not hrp or #zombies == 0 then return nil end
	local myPos = hrp.Position
	local nearest, nearestDist = nil, math.huge
	for _, z in ipairs(zombies) do
		local zHRP = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
		if zHRP then
			local d = (zHRP.Position - myPos).Magnitude
			if d < nearestDist then
				nearestDist = d
				nearest = z
			end
		end
	end
	return nearest
end

local function clearESP()
	for _, z in ipairs(getZombies()) do
		local hl = z:FindFirstChild("DevZombieHighlight")
		if hl then hl:Destroy() end
	end
end

-- =======================================================================
--   RENDER LOOPS & INPUT
-- =======================================================================
RunService.RenderStepped:Connect(function()
	if tracerEnabled then
		if not tracerBeam then
			tracerBeam = Instance.new("Beam")
			tracerBeam.Name = "TracerBeam"
			tracerBeam.Color = ColorSequence.new(Color3.fromRGB(0, 210, 255))
			tracerBeam.Width0, tracerBeam.Width1 = 0.1, 0.1
			tracerBeam.FaceCamera = true
			tracerBeam.Parent = camera
		end

		local myHRP = getHRP()
		local nearest = getNearestZombie()
		if myHRP and nearest then
			local targetHRP = nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("Torso")
			if targetHRP then
				if not playerAttachment or playerAttachment.Parent ~= myHRP then
					playerAttachment = Instance.new("Attachment", myHRP)
				end
				local targetAtt = targetHRP:FindFirstChild("TargetAtt") or Instance.new("Attachment", targetHRP)
				targetAtt.Name = "TargetAtt"
				tracerBeam.Attachment0 = playerAttachment
				tracerBeam.Attachment1 = targetAtt
				tracerBeam.Enabled = true
			else
				if tracerBeam then tracerBeam.Enabled = false end
			end
		else
			if tracerBeam then tracerBeam.Enabled = false end
		end
	elseif tracerBeam then
		tracerBeam.Enabled = false
	end

	if espEnabled then
		for _, z in ipairs(getZombies()) do
			if not z:FindFirstChild("DevZombieHighlight") then
				local hl = Instance.new("Highlight")
				hl.Name = "DevZombieHighlight"
				hl.FillColor = Color3.fromRGB(0, 210, 255)
				hl.FillTransparency = 0.5
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.OutlineTransparency = 0.2
				hl.Adornee = z
				hl.Parent = z
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled then
		local hum = getHumanoid()
		if hum and hum.Parent then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hum:ChangeState(Enum.HumanoidStateType.Seated)
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W then flyKeys.W = true end
	if k == Enum.KeyCode.A then flyKeys.A = true end
	if k == Enum.KeyCode.S then flyKeys.S = true end
	if k == Enum.KeyCode.D then flyKeys.D = true end
	if k == Enum.KeyCode.Space then flyKeys.Up = true end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W then flyKeys.W = false end
	if k == Enum.KeyCode.A then flyKeys.A = false end
	if k == Enum.KeyCode.S then flyKeys.S = false end
	if k == Enum.KeyCode.D then flyKeys.D = false end
	if k == Enum.KeyCode.Space then flyKeys.Up = false end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = false end
end)

localPlayer.CharacterAdded:Connect(function(char)
	applyCharacterSettings(char)
	task.wait(0.2)
	if noclipEnabled then setNoclip(true) end
	if flyEnabled then setFly(true) end
	if walkOnWaterEnabled then setWalkOnWater(true) end
	if ragdollEnabled then setRagdoll(true) end
end)

-- =======================================================================
--   TP HELPER
-- =======================================================================
local function resolveAreaTarget(areaFolder)
	if not areaFolder then return nil end
	local name = areaFolder.Name

	if name == "Carnanval" then
		local monkey = areaFolder:FindFirstChild("Circus Monkey", true)
		if monkey then return monkey:IsA("Model") and monkey:GetPivot() or monkey.CFrame end
	end

	if name == "Shopping Mall" then
		local spawns = areaFolder:FindFirstChild("ShoppingMallCarSpawns", true)
		if spawns then
			local p = spawns:FindFirstChildWhichIsA("BasePart", true)
			if p then return p.CFrame end
		end
	end

	local box = areaFolder:FindFirstChild("Lost and Found Box", true)
	if box then return box:IsA("Model") and box:GetPivot() or box.CFrame end

	local anyPart = areaFolder:FindFirstChildWhichIsA("BasePart", true)
	if anyPart then return anyPart.CFrame end
	return areaFolder:IsA("Model") and areaFolder:GetPivot() or nil
end

local function teleportToTarget(targetCFrame, name, yOffset)
	local hrp = getHRP()
	if not hrp or not targetCFrame then return end
	local destCFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, yOffset or 4.5, 0))

	if useTweenForTPs then
		fastTweenTo(destCFrame, fastTweenSpeed)
	else
		cancelCurrentTween()
		hrp.CFrame = destCFrame
	end

	if name then
		Hallow:Notify({ Title = "Teleport", Content = "Traveled to " .. name, Duration = 2, Type = "info" })
	end
end

-- =======================================================================
--   TAB 1: HALLOWEEN
-- =======================================================================
local halloweenTab = Win:CreateTab("Halloween", "pumpkin")

halloweenTab:CreateSection("Trick or Treat (47 Houses)")

halloweenTab:CreateToggle({
	Name = "Auto Trick or Treat (Loop)",
	Description = "Loops through the sequence with fast teleports",
	Default = false,
	Callback = function(value)
		autoTotEnabled = value
		if autoTotEnabled then
			task.spawn(function()
				while autoTotEnabled do
					runTrickOrTreatSweep(false)
					task.wait(totDelay)
				end
			end)
		end
	end
})

halloweenTab:CreateButton({
	Name = "Trick or Treat All (Once)",
	Description = "Runs the sequence one time",
	Icon = "pumpkin",
	Callback = function()
		task.spawn(function() runTrickOrTreatSweep(true) end)
	end
})

halloweenTab:CreateToggle({
	Name = "Knock Lit Houses Only",
	Default = false,
	Callback = function(val) checkLitOnly = val end
})

halloweenTab:CreateToggle({
	Name = "Skip Houses on Cooldown",
	Default = false,
	Callback = function(val) checkCooldowns = val end
})

halloweenTab:CreateButton({
	Name = "Reset House Cooldowns",
	Icon = "bolt",
	Callback = function()
		table.clear(unlitHouses)
		Hallow:Notify({ Title = "Cooldowns Reset", Content = "All house timers cleared!", Duration = 2.5, Type = "success" })
	end
})

halloweenTab:CreateSlider({
	Name = "Post-Knock Delay",
	Min = 0.05,
	Max = 3,
	Default = 0.1,
	Increment = 0.05,
	Suffix = "s",
	Callback = function(val) totDelay = val end
})

halloweenTab:CreateSection("Auto Dig Graves")

halloweenTab:CreateToggle({
	Name = "Auto Dig Graves (Loop)",
	Default = false,
	Callback = function(value)
		autoDigEnabled = value
		if autoDigEnabled then
			task.spawn(function()
				while autoDigEnabled do
					runGraveDigSweep(false)
					task.wait(digDelay)
				end
			end)
		end
	end
})

halloweenTab:CreateButton({
	Name = "Dig All Graves (Once)",
	Icon = "bone",
	Callback = function()
		task.spawn(function() runGraveDigSweep(true) end)
	end
})

halloweenTab:CreateSlider({
	Name = "Grave Dig Delay",
	Min = 0.1,
	Max = 5,
	Default = 0.5,
	Increment = 0.05,
	Suffix = "s",
	Callback = function(val) digDelay = val end
})

-- =======================================================================
--   TAB 2: GARAGES
-- =======================================================================
local garagesTab = Win:CreateTab("Garages", "potion")

garagesTab:CreateSection("Instant Interaction")

garagesTab:CreateToggle({
	Name = "Insta Repair / Instant Hold",
	Description = "Triggers ProximityPrompts instantly",
	Default = false,
	Callback = function(value) setInstantPrompts(value) end
})

garagesTab:CreateSection("Halloween Auction Garages")

for i = 1, 4 do
	garagesTab:CreateToggle({
		Name = string.format("Auto Start Garage %d (%d Candy)", i, i * 10),
		Default = false,
		Callback = function(val) autoStartGarages[i] = val end
	})
end

-- =======================================================================
--   TAB 3: ZOMBIES
-- =======================================================================
local zombiesTab = Win:CreateTab("Zombies", "skull")

zombiesTab:CreateSection("Tracking & Detection")

local zombieCounterLabel = zombiesTab:CreateLabel("Scanning for entities...")
task.spawn(function()
	while true do
		local count = #getZombies()
		zombieCounterLabel:Set(tostring(count) .. " zombies active on map.")
		task.wait(1)
	end
end)

zombiesTab:CreateButton({
	Name = "Tween to Nearest Zombie",
	Icon = "skull",
	Callback = function()
		local n = getNearestZombie()
		if n then
			local myHRP = getHRP()
			local targetHRP = n:FindFirstChild("HumanoidRootPart") or n:FindFirstChild("Torso")
			if myHRP and targetHRP then
				cancelCurrentTween()
				local targetCFrame = CFrame.lookAt(targetHRP.Position + OFFSET, targetHRP.Position)
				fastTweenTo(targetCFrame, tweenSpeed)
			end
		end
	end
})

zombiesTab:CreateButton({
	Name = "Cancel Active Motion",
	Icon = "warn",
	Callback = function() cancelCurrentTween() end
})

zombiesTab:CreateSlider({
	Name = "Tween Speed",
	Min = 30,
	Max = 250,
	Default = 100,
	Increment = 5,
	Callback = function(val) tweenSpeed = val end
})

zombiesTab:CreateSection("Visuals")

zombiesTab:CreateToggle({
	Name = "Entity Highlight (ESP)",
	Default = false,
	Callback = function(value)
		espEnabled = value
		if not espEnabled then clearESP() end
	end
})

zombiesTab:CreateToggle({
	Name = "Target Tracer Beam",
	Default = false,
	Callback = function(value) tracerEnabled = value end
})

-- =======================================================================
--   TAB 4: PLAYER
-- =======================================================================
local playerTab = Win:CreateTab("Player", "ghost")

playerTab:CreateSection("Character Attributes")

playerTab:CreateSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 16,
	Increment = 1,
	Callback = function(val)
		currentWalkSpeed = val
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = val end
	end
})

playerTab:CreateSlider({
	Name = "Jump Power",
	Min = 0,
	Max = 300,
	Default = 50,
	Increment = 5,
	Callback = function(val)
		currentJumpPower = val
		local hum = getHumanoid()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = val
		end
	end
})

playerTab:CreateSlider({
	Name = "World Gravity",
	Min = 0,
	Max = 500,
	Default = math.floor(Workspace.Gravity),
	Increment = 10,
	Callback = function(val)
		currentGravity = val
		Workspace.Gravity = val
	end
})

playerTab:CreateSlider({
	Name = "Camera FOV",
	Min = 40,
	Max = 120,
	Default = math.floor(camera.FieldOfView),
	Increment = 1,
	Callback = function(val) camera.FieldOfView = val end
})

playerTab:CreateSection("Movement")

playerTab:CreateToggle({
	Name = "Fly Mode",
	Default = false,
	Callback = function(value) setFly(value) end
})

playerTab:CreateSlider({
	Name = "Fly Speed",
	Min = 10,
	Max = 200,
	Default = 60,
	Increment = 5,
	Callback = function(val) flySpeed = val end
})

playerTab:CreateToggle({
	Name = "Noclip",
	Default = false,
	Callback = function(value) setNoclip(value) end
})

playerTab:CreateToggle({
	Name = "Walk On Water",
	Default = false,
	Callback = function(value) setWalkOnWater(value) end
})

playerTab:CreateToggle({
	Name = "Infinite Jump",
	Default = false,
	Callback = function(value) infJumpEnabled = value end
})

playerTab:CreateSection("Utility")

playerTab:CreateToggle({
	Name = "Fullbright / Clear Fog",
	Default = false,
	Callback = function(value)
		fullbrightEnabled = value
		if fullbrightEnabled then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
		else
			Lighting.Brightness = 1
			Lighting.GlobalShadows = true
		end
	end
})

playerTab:CreateToggle({
	Name = "Anti-AFK Protection",
	Default = false,
	Callback = function(value)
		antiAfkEnabled = value
		if antiAfkEnabled then
			antiAfkConn = localPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end)
		else
			if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
		end
	end
})

playerTab:CreateToggle({
	Name = "Ragdoll Mode",
	Default = false,
	Callback = function(value) setRagdoll(value) end
})

playerTab:CreateButton({
	Name = "Respawn Character",
	Icon = "skull",
	Callback = function()
		local hum = getHumanoid()
		if hum then hum.Health = 0 end
	end
})

-- =======================================================================
--   TAB 5: KEYBINDS
-- =======================================================================
local keybindsTab = Win:CreateTab("Keybinds", "gear")

keybindsTab:CreateSection("Action Keybinds")

keybindsTab:CreateKeybind({
	Name = "Toggle Fly",
	Default = Enum.KeyCode.None,
	OnChange = function(k) keybinds.Fly = k end,
	Callback = function() setFly(not flyEnabled) end
})

keybindsTab:CreateKeybind({
	Name = "Toggle Noclip",
	Default = Enum.KeyCode.None,
	OnChange = function(k) keybinds.Noclip = k end,
	Callback = function() setNoclip(not noclipEnabled) end
})

keybindsTab:CreateKeybind({
	Name = "Toggle ESP",
	Default = Enum.KeyCode.None,
	OnChange = function(k) keybinds.ESP = k end,
	Callback = function()
		espEnabled = not espEnabled
		if not espEnabled then clearESP() end
	end
})

keybindsTab:CreateKeybind({
	Name = "Toggle Infinite Jump",
	Default = Enum.KeyCode.None,
	OnChange = function(k) keybinds.InfiniteJump = k end,
	Callback = function() infJumpEnabled = not infJumpEnabled end
})

keybindsTab:CreateKeybind({
	Name = "Toggle Ragdoll",
	Default = Enum.KeyCode.None,
	OnChange = function(k) keybinds.Ragdoll = k end,
	Callback = function() setRagdoll(not ragdollEnabled) end
})

-- =======================================================================
--   TAB 6: TPS
-- =======================================================================
local tpsTab = Win:CreateTab("TPs", "moon")

tpsTab:CreateSection("Teleport Options")

tpsTab:CreateToggle({
	Name = "Use Fast Tween For Teleports",
	Default = false,
	Callback = function(val) useTweenForTPs = val end
})

tpsTab:CreateSection("Area Locations")

local function buildTPButtons()
	local areasFolder = Workspace:FindFirstChild("Areas")
	if not areasFolder then return end

	for _, areaFolder in ipairs(areasFolder:GetChildren()) do
		tpsTab:CreateButton({
			Name = "TP to " .. areaFolder.Name,
			Icon = "moon",
			Callback = function()
				if areaFolder.Name == "Shopping Mall" then
					task.spawn(function()
						local junkYard = areasFolder:FindFirstChild("Junk Yard") or areasFolder:FindFirstChild("Junkyard")
						if junkYard then
							local jyTarget = resolveAreaTarget(junkYard)
							if jyTarget then
								teleportToTarget(jyTarget, "Junk Yard (Transit)", 4.5)
								task.wait(0.4)
							end
						end
						local mallTarget = resolveAreaTarget(areaFolder)
						if mallTarget then
							teleportToTarget(mallTarget, "Shopping Mall", 4.5)
						end
					end)
				else
					local targetCFrame = resolveAreaTarget(areaFolder)
					if targetCFrame then
						teleportToTarget(targetCFrame, areaFolder.Name, 4.5)
					else
						Hallow:Notify({ Title = "Teleport Failed", Content = "Destination unavailable", Duration = 2.5, Type = "error" })
					end
				end
			end
		})
	end
end

buildTPButtons()

-- =======================================================================
--   TAB 7: THEMES & SETTINGS
-- =======================================================================
Win:CreateThemeTab("Settings", "palette")
