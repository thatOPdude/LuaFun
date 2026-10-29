-- =======================================================================
--   🌍 LOAD ORBITAL UI LIBRARY
-- =======================================================================
local Orbital = loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/OrbitalLib.lua?nocache=" .. tostring(tick())))()

-- =======================================================================
--   SERVICES
-- =======================================================================
local TweenService           = game:GetService("TweenService")
local Players                = game:GetService("Players")
local Workspace              = game:GetService("Workspace")
local RunService             = game:GetService("RunService")
local Lighting               = game:GetService("Lighting")
local UserInputService       = game:GetService("UserInputService")
local VirtualUser            = game:GetService("VirtualUser")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService             = game:GetService("GuiService")

pcall(function()
	GuiService:SetGameplayPausedNotificationEnabled(false)
end)

local localPlayer = Players.LocalPlayer
local camera      = Workspace.CurrentCamera

local parentGui = (typeof(gethui) == "function" and gethui()) 
	or game:GetService("CoreGui"):FindFirstChild("RobloxGui") 
	or localPlayer:WaitForChild("PlayerGui")

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

-- Keybind State
local keybinds = {
	Fly = Enum.KeyCode.None,
	Noclip = Enum.KeyCode.None,
	ESP = Enum.KeyCode.None,
	InfiniteJump = Enum.KeyCode.None,
	Ragdoll = Enum.KeyCode.None
}
local bindingAction = nil
local keybindLabels = {}

-- Halloween / Trick or Treat State
local autoTotEnabled      = false
local totLoopRunning      = false
local totDelay            = 0.1
local checkLitOnly        = false
local checkCooldowns      = false
local unlitHouses         = {}
local currentKnockingHouse = nil
local minHouseY           = 3
local HOUSE_COOLDOWN      = 240

-- Halloween / Auto Dig Grave State
local autoDigEnabled      = false
local digLoopRunning      = false
local digDelay            = 0.2

-- Garages Auto-Start State
local autoStartGarages = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false
}

-- =======================================================================
--   CUSTOM 47-HOUSE ORDER SEQUENCE
-- =======================================================================
local houseOrder = {
	39, 42, 15, 12, 23, 34, 29, 26, 50, 47,
	35, 18, 37, 33, 49, 19, 21, 27, 28, 36,
	7, 6,
	{ target = 13, tween = true }, -- Tweens across streaming boundary
	"Trick or Treat House", 8, 16, 43, 17, 10, 38, 4,
	"Halloween Hut", 22, 2, 25, 20, 14, 11, 40, 24,
	31, 41, 30, 44, 32, 48, 39
}

-- =======================================================================
--   CREATE MAIN ORBITAL WINDOW
-- =======================================================================
local window = Orbital:CreateWindow({
	Title = "Orbital"
})

window:Notify({
	title = "Orbital",
	content = "Orbital loaded successfully.",
	duration = 3.5
})

-- =======================================================================
--   HELPER & RECOVERY FUNCTIONS
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
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)

	hrp.Anchored = true
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	activeTween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })

	local done = false
	activeTween.Completed:Connect(function()
		done = true
	end)

	activeTween:Play()

	while not done and activeTween do
		task.wait()
	end

	if tempNoclip then
		tempNoclip:Disconnect()
	end

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
		if cf and cf.Position.Magnitude > 1 then
			return cf
		end
		local p = house:FindFirstChildWhichIsA("BasePart", true)
		if p then return p.CFrame end
		return house:GetPivot()
	end
	return nil
end

-- =======================================================================
--   INSTANT PROMPT / INSTA-REPAIR LOGIC
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
				if (desc.MaxActivationDistance or 10) < 25 then
					desc.MaxActivationDistance = 25
				end
			end
		end

		table.insert(promptConns, ProximityPromptService.PromptShown:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end
			if originalHoldDurations[prompt] == nil then originalHoldDurations[prompt] = prompt.HoldDuration end
			prompt.HoldDuration = 0
			prompt.RequiresLineOfSight = false
			if (prompt.MaxActivationDistance or 10) < 25 then
				prompt.MaxActivationDistance = 25
			end
		end))

		table.insert(promptConns, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			if not instaRepairEnabled or not prompt then return end
			interactWithPrompt(prompt)
		end))

		table.insert(promptConns, Workspace.DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") then
				if originalHoldDurations[desc] == nil then originalHoldDurations[desc] = desc.HoldDuration end
				desc.HoldDuration = 0
				desc.RequiresLineOfSight = false
				if (desc.MaxActivationDistance or 10) < 25 then
					desc.MaxActivationDistance = 25
				end
			end
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
--   GARAGE AUTO-START LOGIC
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
		notifyRemote.OnClientEvent:Connect(function(msg, ...)
			if typeof(msg) == "string" and string.find(string.lower(msg), "lights are out") then
				if currentKnockingHouse then
					unlitHouses[currentKnockingHouse] = tick() + HOUSE_COOLDOWN
					print(string.format("[TrickOrTreat] '%s' lights are out!", currentKnockingHouse.Name))
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

	if house:GetAttribute("Lit") == false or house:GetAttribute("Active") == false then
		return false
	end

	local litVal = house:FindFirstChild("IsLit") or house:FindFirstChild("Lit")
	if litVal and litVal:IsA("BoolValue") and not litVal.Value then
		return false
	end

	local hasAnyLightSource = false
	for _, desc in ipairs(house:GetDescendants()) do
		if desc:IsA("Light") then
			hasAnyLightSource = true
			if desc.Enabled then return true end
		end
	end

	if hasAnyLightSource then return false end
	return true
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
			table.insert(houseList, {
				order = orderIdx,
				house = house,
				shouldTween = shouldTween
			})
		end
	end

	return houseList
end

local function runTrickOrTreatSweep(singleRun)
	if totLoopRunning and not singleRun then return end
	totLoopRunning = true

	local success, err = pcall(function()
		local houses = getOrderedHouses()
		if #houses == 0 then
			window:Notify({
				title = "Trick or Treat",
				content = "Building folder or houses not found!",
				duration = 3
			})
			return
		end

		for _, houseData in ipairs(houses) do
			if not autoTotEnabled and not singleRun then break end

			local house = houseData.house
			local hrp = getHRP()
			if not hrp then break end

			if checkCooldowns and unlitHouses[house] and tick() < unlitHouses[house] then
				continue
			end

			if checkLitOnly and not isHousePhysicallyLit(house) then
				continue
			end

			currentKnockingHouse = house
			cancelCurrentTween()

			local shouldTween = houseData.shouldTween
			local prompt = house:FindFirstChild("TrickOrTreatPrompt", true) 
				or house:FindFirstChildOfClass("ProximityPrompt", true)
			local promptPoint = house:FindFirstChild("TrickOrTreatPromptPoint", true) 
				or (prompt and prompt.Parent)

			if not promptPoint or not prompt then
				local houseCF = getHouseCFrame(house)
				if houseCF then
					local targetDest = houseCF + Vector3.new(0, 3, 0)
					if shouldTween then
						fastTweenTo(targetDest, fastTweenSpeed)
					else
						hrp.CFrame = targetDest
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					end

					local elapsed = 0
					while elapsed < 0.4 do
						prompt = house:FindFirstChild("TrickOrTreatPrompt", true) 
							or house:FindFirstChildOfClass("ProximityPrompt", true)
						promptPoint = house:FindFirstChild("TrickOrTreatPromptPoint", true) 
							or (prompt and prompt.Parent)
						if prompt and promptPoint then break end
						task.wait(0.05)
						elapsed = elapsed + 0.05
					end
				end
			end

			if promptPoint then
				local targetCFrame = nil
				if promptPoint:IsA("Attachment") then
					targetCFrame = promptPoint.WorldCFrame
				elseif promptPoint:IsA("BasePart") then
					targetCFrame = promptPoint.CFrame
				elseif promptPoint.Parent and promptPoint.Parent:IsA("BasePart") then
					targetCFrame = promptPoint.Parent.CFrame
				end

				if targetCFrame then
					local targetDest = targetCFrame + Vector3.new(0, 1.5, 0)
					if shouldTween then
						fastTweenTo(targetDest, fastTweenSpeed)
					else
						hrp.CFrame = targetDest
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					end
					task.wait(0.2)
				end
			end

			prompt = prompt or house:FindFirstChild("TrickOrTreatPrompt", true) or house:FindFirstChildOfClass("ProximityPrompt", true)
			if prompt then
				interactWithPrompt(prompt)
				task.wait(0.35)

				if checkCooldowns then
					unlitHouses[house] = tick() + HOUSE_COOLDOWN
				end
				print(string.format("[TrickOrTreat] #%d ('%s') knocked.", houseData.order, house.Name))
			end

			task.wait(totDelay)
			currentKnockingHouse = nil
		end
	end)

	if not success then
		warn("[TrickOrTreat Error]:", err)
	end

	totLoopRunning = false
end

-- =======================================================================
--   ACCURATE MULTI-GRAVE SCANNER
-- =======================================================================
local function getAllGraveSpots()
	local areas = Workspace:FindFirstChild("Areas")
	if not areas then return {} end
	local hw = areas:FindFirstChild("Halloween")
	if not hw then return {} end

	local list = {}
	local addedPrompts = {}

	for _, child in ipairs(hw:GetChildren()) do
		if string.lower(child.Name) == "grave" or string.find(string.lower(child.Name), "grave") then
			local partsFolder = child:FindFirstChild("Parts")
			if partsFolder then
				for _, subGrave in ipairs(partsFolder:GetChildren()) do
					local prompt = subGrave:FindFirstChild("GraveDigPrompt", true) 
						or subGrave:FindFirstChildOfClass("ProximityPrompt", true)
					
					if prompt and not addedPrompts[prompt] then
						addedPrompts[prompt] = true
						local tpPoint = subGrave:FindFirstChild("GraveDigPromptPoint", true) 
							or prompt.Parent
						table.insert(list, {
							part   = subGrave,
							point  = tpPoint,
							prompt = prompt
						})
					end
				end
			end

			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("ProximityPrompt") and (desc.Name == "GraveDigPrompt" or string.find(desc.Name, "Dig")) then
					if not addedPrompts[desc] then
						addedPrompts[desc] = true
						local tpPoint = desc.Parent
						local hostPart = (tpPoint:IsA("BasePart") and tpPoint) 
							or (tpPoint:IsA("Attachment") and tpPoint.Parent) 
							or child:FindFirstChildOfClass("BasePart", true)
						table.insert(list, {
							part   = hostPart,
							point  = tpPoint,
							prompt = desc
						})
					end
				end
			end
		end
	end

	if #list == 0 then
		for _, desc in ipairs(hw:GetDescendants()) do
			if desc:IsA("ProximityPrompt") and (desc.Name == "GraveDigPrompt" or string.find(desc.Name, "Dig")) then
				if not addedPrompts[desc] then
					addedPrompts[desc] = true
					local tpPoint = desc.Parent
					table.insert(list, {
						part   = (tpPoint:IsA("BasePart") and tpPoint) or (tpPoint:IsA("Attachment") and tpPoint.Parent) or desc.Parent,
						point  = tpPoint,
						prompt = desc
					})
				end
			end
		end
	end

	return list
end

local function runGraveDigSweep(singleRun)
	if digLoopRunning and not singleRun then return end
	digLoopRunning = true

	local success, err = pcall(function()
		local graves = getAllGraveSpots()
		if #graves == 0 then
			window:Notify({
				title = "Auto Dig Grave",
				content = "No graves found in workspace!",
				duration = 3
			})
			return
		end

		for _, graveData in ipairs(graves) do
			if not autoDigEnabled and not singleRun then break end

			local hrp = getHRP()
			local prompt = graveData.prompt
			local targetPoint = graveData.point or graveData.part

			if hrp and prompt and prompt.Parent and targetPoint then
				if prompt.Enabled then
					cancelCurrentTween()

					local targetCFrame = nil
					if targetPoint:IsA("BasePart") then
						targetCFrame = targetPoint.CFrame
					elseif targetPoint:IsA("Attachment") then
						targetCFrame = targetPoint.WorldCFrame
					elseif graveData.part and graveData.part:IsA("BasePart") then
						targetCFrame = graveData.part.CFrame
					elseif graveData.part and graveData.part:IsA("Model") then
						targetCFrame = graveData.part:GetPivot()
					end

					if targetCFrame then
						local targetDest = targetCFrame + Vector3.new(0, 2.5, 0)
						hrp.CFrame = targetDest
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero

						task.wait(0.15)
						interactWithPrompt(prompt)
						task.wait(0.3)
						task.wait(digDelay)
					end
				end
			end
		end
	end)

	if not success then
		warn("[GraveDig Error]:", err)
	end

	digLoopRunning = false
end

-- =======================================================================
--   MOVEMENT / PHYSICS
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
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end

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

local function explodeMe()
	local hrp = getHRP()
	local hum = getHumanoid()
	if not hrp then return end
	local exp = Instance.new("Explosion")
	exp.Position = hrp.Position
	exp.BlastPressure = 0
	exp.BlastRadius = 6
	exp.Parent = Workspace
	task.delay(0.05, function() if hum then hum.Health = 0 end end)
end

-- =======================================================================
--   ZOMBIE BOT
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

local function tweenToZombie(targetZombie)
	local myHRP = getHRP()
	local targetHRP = targetZombie and (targetZombie:FindFirstChild("HumanoidRootPart") or targetZombie:FindFirstChild("Torso"))
	if not myHRP or not targetHRP then return end

	cancelCurrentTween()
	local targetPos = targetHRP.Position + OFFSET
	local targetCFrame = CFrame.lookAt(targetPos, targetHRP.Position)
	local distance = (myHRP.Position - targetPos).Magnitude
	local duration = math.max(0.15, distance / math.max(1, tweenSpeed))

	myHRP.Anchored = true
	activeTween = TweenService:Create(myHRP, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
	activeTween.Completed:Connect(function()
		if myHRP and myHRP.Parent then myHRP.Anchored = false end
		activeTween = nil
	end)
	activeTween:Play()
end

local function clearESP()
	for _, z in ipairs(getZombies()) do
		local hl = z:FindFirstChild("DevZombieHighlight")
		if hl then hl:Destroy() end
	end
end

-- =======================================================================
--   RESPAWN HOOKS
-- =======================================================================
localPlayer.CharacterAdded:Connect(function(char)
	applyCharacterSettings(char)

	task.wait(0.2)
	if noclipEnabled then setNoclip(true) end
	if flyEnabled then setFly(true) end
	if walkOnWaterEnabled then setWalkOnWater(true) end
	if ragdollEnabled then setRagdoll(true) end
end)

-- =======================================================================
--   RUNSERVICE RENDER LOOPS
-- =======================================================================
RunService.RenderStepped:Connect(function()
	if tracerEnabled then
		if not tracerBeam then
			tracerBeam = Instance.new("Beam")
			tracerBeam.Name = "TracerBeam"
			tracerBeam.Color = ColorSequence.new(Color3.fromRGB(0, 210, 255))
			tracerBeam.Width0 = 0.1
			tracerBeam.Width1 = 0.1
			tracerBeam.FaceCamera = true
			tracerBeam.LightEmission = 1
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

-- =======================================================================
--   KEYBIND UI HELPER LOGIC
-- =======================================================================
local function findKeybindLabel(actionName)
	if keybindLabels[actionName] and keybindLabels[actionName].Parent then
		return keybindLabels[actionName]
	end

	local main = parentGui:FindFirstChild("Orbital_Main")
	if not main then return nil end

	local searchContainer = main:FindFirstChild("Keybinds_Page", true) or main

	for _, desc in ipairs(searchContainer:GetDescendants()) do
		if desc:IsA("TextLabel") and string.find(desc.Text, "Bind " .. actionName) then
			keybindLabels[actionName] = desc
			return desc
		end
	end

	local page = main:FindFirstChild("Keybinds_Page", true)
	if page then
		for _, desc in ipairs(page:GetDescendants()) do
			if desc:IsA("TextLabel") and string.find(desc.Text, actionName) then
				keybindLabels[actionName] = desc
				return desc
			end
		end
	end

	return nil
end

local function updateKeybindDisplay(actionName, newText)
	local lbl = findKeybindLabel(actionName)
	if lbl then
		lbl.Text = newText
	end
end

-- =======================================================================
--   INPUT & KEYBIND DISPATCHER
-- =======================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
	local k = input.KeyCode

	if bindingAction then
		if k == Enum.KeyCode.Unknown then return end
		local action = bindingAction
		bindingAction = nil

		if k == Enum.KeyCode.Escape then
			keybinds[action] = Enum.KeyCode.None
			updateKeybindDisplay(action, "Bind " .. action .. " [None]")
			window:Notify({
				title = "Keybinds",
				content = action .. " binding cleared.",
				duration = 2
			})
		else
			keybinds[action] = k
			local keyName = k.Name
			updateKeybindDisplay(action, "Bind " .. action .. " [" .. keyName .. "]")
			window:Notify({
				title = "Keybinds",
				content = action .. " bound to [" .. keyName .. "]",
				duration = 2
			})
		end
		return
	end

	if gpe then return end

	if k == keybinds.Fly and k ~= Enum.KeyCode.None then
		setFly(not flyEnabled)
	end
	if k == keybinds.Noclip and k ~= Enum.KeyCode.None then
		setNoclip(not noclipEnabled)
	end
	if k == keybinds.ESP and k ~= Enum.KeyCode.None then
		espEnabled = not espEnabled
		if not espEnabled then clearESP() end
	end
	if k == keybinds.InfiniteJump and k ~= Enum.KeyCode.None then
		infJumpEnabled = not infJumpEnabled
	end
	if k == keybinds.Ragdoll and k ~= Enum.KeyCode.None then
		setRagdoll(not ragdollEnabled)
	end

	if k == Enum.KeyCode.W           then flyKeys.W = true end
	if k == Enum.KeyCode.A           then flyKeys.A = true end
	if k == Enum.KeyCode.S           then flyKeys.S = true end
	if k == Enum.KeyCode.D           then flyKeys.D = true end
	if k == Enum.KeyCode.Space       then flyKeys.Up = true end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W           then flyKeys.W = false end
	if k == Enum.KeyCode.A           then flyKeys.A = false end
	if k == Enum.KeyCode.S           then flyKeys.S = false end
	if k == Enum.KeyCode.D           then flyKeys.D = false end
	if k == Enum.KeyCode.Space       then flyKeys.Up = false end
	if k == Enum.KeyCode.LeftControl then flyKeys.Down = false end
end)

-- =======================================================================
--   TPS LOGIC
-- =======================================================================
local CustomTargets = {
	["Shopping Mall"] = function(area)
		local spawns = area:FindFirstChild("ShoppingMallCarSpawns", true)
		if spawns then
			return spawns:FindFirstChildOfClass("BasePart") or spawns:FindFirstChild("Part") or spawns:FindFirstChildWhichIsA("BasePart", true)
		end
	end,
	["Carnanval"] = function(area)
		local npcFolder = area:FindFirstChild("NPC")
		local monkey = (npcFolder and npcFolder:FindFirstChild("Circus Monkey")) or area:FindFirstChild("Circus Monkey", true)
		return monkey and (monkey:FindFirstChild("HumanoidRootPart") or monkey:FindFirstChild("UpperTorso") or monkey:FindFirstChild("Torso") or monkey.PrimaryPart or monkey:FindFirstChildWhichIsA("BasePart", true))
	end
}

local function resolveAreaTarget(areaFolder)
	if not areaFolder then return nil end
	local name = areaFolder.Name

	if name == "Carnanval" then
		local customFinder = CustomTargets["Carnanval"]
		local monkey = customFinder and customFinder(areaFolder)
		if monkey then
			if monkey:IsA("Model") then return monkey:GetPivot() end
			if monkey:IsA("BasePart") then return monkey.CFrame end
		end
	end

	if name == "Shopping Mall" then
		local customFinder = CustomTargets["Shopping Mall"]
		local spawnTarget = customFinder and customFinder(areaFolder)
		if spawnTarget then
			if spawnTarget:IsA("Model") then return spawnTarget:GetPivot() end
			if spawnTarget:IsA("BasePart") then return spawnTarget.CFrame end
		end
	end

	local box = areaFolder:FindFirstChild("Lost and Found Box", true)
	if box then
		local cube = box:FindFirstChild("Meshes/LNF_Cube", true) or box:FindFirstChild("LNF_Cube", true)
		if cube and cube:IsA("BasePart") then
			return cube.CFrame
		end
		if box:IsA("Model") then
			return box:GetPivot()
		elseif box:IsA("BasePart") then
			return box.CFrame
		end
		local anyPart = box:FindFirstChildWhichIsA("BasePart", true)
		if anyPart then return anyPart.CFrame end
	end

	local anyPart = areaFolder:FindFirstChildWhichIsA("BasePart", true)
	if anyPart then return anyPart.CFrame end
	if areaFolder:IsA("Model") then return areaFolder:GetPivot() end

	return nil
end

local function teleportToTarget(targetCFrame, name, yOffset)
	local hrp = getHRP()
	if not hrp or not targetCFrame then return end

	local offset = yOffset or 4.5
	local destCFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, offset, 0))

	if useTweenForTPs then
		fastTweenTo(destCFrame, fastTweenSpeed)
	else
		cancelCurrentTween()
		hrp.CFrame = destCFrame
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	if name then
		window:Notify({
			title = "Teleport",
			content = "Traveled to " .. name,
			duration = 2
		})
	end
end

-- =======================================================================
--   BUILD ORBITAL NODES (ALL 7 TABS + CLOSE TAB)
-- =======================================================================

-- -----------------------------------------------------------------------
--   NODE 1: HALLOWEEN
-- -----------------------------------------------------------------------
local halloweenTab = window:CreateTab("Halloween", "🎃")

halloweenTab:CreateSection("Trick or Treat (Custom 47-Stop Sequence)")

halloweenTab:CreateToggle({
	Name = "Auto Trick or Treat (Loop)",
	Description = "Loops through the sequence with fast TPs (tweens to #13)",
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
	Name = "Trick or Treat All Houses (Once)",
	Description = "Runs the sequence one time",
	Callback = function()
		task.spawn(function()
			runTrickOrTreatSweep(true)
		end)
	end
})

halloweenTab:CreateToggle({
	Name = "Knock Lit Houses Only",
	Description = "Off = knocks all houses regardless of in-game lights",
	Default = false,
	Callback = function(val)
		checkLitOnly = val
	end
})

halloweenTab:CreateToggle({
	Name = "Skip Houses on 4-Min Cooldown",
	Description = "Off = attempts every house without timer restrictions",
	Default = false,
	Callback = function(val)
		checkCooldowns = val
	end
})

halloweenTab:CreateButton({
	Name = "Reset House Cooldowns",
	Description = "Wipes 4-minute cooldown timer so you can knock again",
	Callback = function()
		table.clear(unlitHouses)
		window:Notify({
			title = "Cooldowns Reset",
			content = "All house timers wiped! Ready to knock.",
			duration = 2.5
		})
	end
})

halloweenTab:CreateSlider({
	Name = "House Post-Knock Delay",
	Description = "Delay before leaving for the next house",
	Min = 0.05,
	Max = 3,
	Default = 0.1,
	Increment = 0.05,
	Callback = function(val)
		totDelay = val
	end
})

halloweenTab:CreateSection("Auto Dig Graves")

halloweenTab:CreateToggle({
	Name = "Auto Dig Graves (Loop)",
	Description = "Loops through and digs all grave spots",
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
	Description = "Digs all graves in the map one time",
	Callback = function()
		task.spawn(function()
			runGraveDigSweep(true)
		end)
	end
})

halloweenTab:CreateSlider({
	Name = "Grave Delay [Rec: 0.5s]",
	Description = "Delay between digging graves (0.1s for fast PCs, 0.5s recommended)",
	Min = 0.1,
	Max = 5,
	Default = 0.5,
	Increment = 0.05,
	Callback = function(val)
		digDelay = val
	end
})

-- -----------------------------------------------------------------------
--   NODE 2: GARAGES
-- -----------------------------------------------------------------------
local garagesTab = window:CreateTab("Garages", "🏚️")

garagesTab:CreateSection("Instant Interaction")

garagesTab:CreateToggle({
	Name = "Insta Repair / Instant Hold",
	Description = "Makes all proximity prompts complete instantly",
	Default = false,
	Callback = function(value)
		setInstantPrompts(value)
	end
})

garagesTab:CreateSection("Halloween Auction Garages")

for i = 1, 4 do
	garagesTab:CreateToggle({
		Name = string.format("Auto Start Garage %d (%d Candy)", i, i * 10),
		Default = false,
		Callback = function(val)
			autoStartGarages[i] = val
		end
	})
end

-- -----------------------------------------------------------------------
--   NODE 3: ZOMBIES
-- -----------------------------------------------------------------------
local zombiesTab = window:CreateTab("Zombies", "🧟")

zombiesTab:CreateSection("Tracking & Detection")

zombiesTab:CreateParagraph({
	Title = "Zombies on Map",
	Content = "Scanning for entities..."
})

zombiesTab:CreateButton({
	Name = "Tween to Nearest Zombie",
	Description = "Smoothly teleports to the closest living zombie",
	Callback = function()
		local n = getNearestZombie()
		if n then tweenToZombie(n) end
	end
})

zombiesTab:CreateButton({
	Name = "Cancel Active Motion",
	Description = "Stops current tween and unanchors root part",
	Callback = function()
		cancelCurrentTween()
	end
})

zombiesTab:CreateSlider({
	Name = "Tween Speed",
	Min = 30,
	Max = 250,
	Default = 100,
	Increment = 5,
	Callback = function(val)
		tweenSpeed = val
	end
})

zombiesTab:CreateSection("Visuals & Aim Assist")

zombiesTab:CreateToggle({
	Name = "Entity Highlight (ESP)",
	Description = "Renders outlines through walls",
	Default = false,
	Callback = function(value)
		espEnabled = value
		if not espEnabled then clearESP() end
	end
})

zombiesTab:CreateToggle({
	Name = "Target Tracer Beam",
	Description = "Draws line to closest target",
	Default = false,
	Callback = function(value)
		tracerEnabled = value
	end
})

-- -----------------------------------------------------------------------
--   NODE 4: PLAYER
-- -----------------------------------------------------------------------
local playerTab = window:CreateTab("Player", "👤")

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
	Callback = function(val)
		camera.FieldOfView = val
	end
})

playerTab:CreateSection("Movement & Travel")

playerTab:CreateToggle({
	Name = "Fly Mode",
	Description = "Controls: WASD + Space (Up) + LeftCtrl (Down)",
	Default = false,
	Callback = function(value)
		setFly(value)
	end
})

playerTab:CreateSlider({
	Name = "Fly Speed",
	Min = 10,
	Max = 200,
	Default = 60,
	Increment = 5,
	Callback = function(val)
		flySpeed = val
	end
})

playerTab:CreateToggle({
	Name = "Noclip",
	Description = "Walk through walls and obstacles",
	Default = false,
	Callback = function(value)
		setNoclip(value)
	end
})

playerTab:CreateToggle({
	Name = "Walk On Water",
	Description = "Surfaces character above water lakes",
	Default = false,
	Callback = function(value)
		setWalkOnWater(value)
	end
})

playerTab:CreateToggle({
	Name = "Infinite Jump",
	Description = "Allows unlimited jumps in air",
	Default = false,
	Callback = function(value)
		infJumpEnabled = value
	end
})

playerTab:CreateSection("Utility & Visuals")

playerTab:CreateToggle({
	Name = "Fullbright / Clear Fog",
	Description = "Disables shadows and clears dark atmosphere",
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
	Description = "Prevents 20-minute idle kicks",
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

playerTab:CreateSection("Fun & Actions")

playerTab:CreateToggle({
	Name = "Ragdoll Mode",
	Default = false,
	Callback = function(value)
		setRagdoll(value)
	end
})

playerTab:CreateButton({
	Name = "Explode Me",
	Description = "Visual explosion in place",
	Callback = function()
		explodeMe()
	end
})

playerTab:CreateButton({
	Name = "Respawn Character",
	Description = "Kills character to force respawn",
	Callback = function()
		local hum = getHumanoid()
		if hum then hum.Health = 0 end
	end
})

-- -----------------------------------------------------------------------
--   NODE 5: KEYBINDS
-- -----------------------------------------------------------------------
local keybindsTab = window:CreateTab("Keybinds", "⌨️")
keybindsTab:CreateSection("Bind Actions (Click to Bind/Unbind)")

local function createBindButton(actionName)
	keybindsTab:CreateButton({
		Name = "Bind " .. actionName .. " [None]",
		Callback = function()
			if bindingAction == actionName then
				bindingAction = nil
				local cur = keybinds[actionName]
				local curName = (cur and cur ~= Enum.KeyCode.None) and cur.Name or "None"
				updateKeybindDisplay(actionName, "Bind " .. actionName .. " [" .. curName .. "]")
			elseif keybinds[actionName] ~= Enum.KeyCode.None then
				keybinds[actionName] = Enum.KeyCode.None
				updateKeybindDisplay(actionName, "Bind " .. actionName .. " [None]")
				window:Notify({
					title = "Keybinds",
					content = actionName .. " unbound.",
					duration = 2
				})
			else
				bindingAction = actionName
				updateKeybindDisplay(actionName, "Press key to bind " .. actionName .. "...")
				window:Notify({
					title = "Keybinds",
					content = "Press any key to bind " .. actionName .. " (Esc to clear)",
					duration = 2.5
				})
			end
		end
	})
end

createBindButton("Fly")
createBindButton("Noclip")
createBindButton("ESP")
createBindButton("InfiniteJump")
createBindButton("Ragdoll")

task.defer(function()
	task.wait(0.2)
	for action in pairs(keybinds) do
		findKeybindLabel(action)
	end
end)

-- -----------------------------------------------------------------------
--   NODE 6: TPS
-- -----------------------------------------------------------------------
local tpsTab = window:CreateTab("TPs", "📍")

tpsTab:CreateSection("Area Locations")

local function buildTPs()
	local areasFolder = Workspace:FindFirstChild("Areas")
	if not areasFolder then return end

	for _, areaFolder in ipairs(areasFolder:GetChildren()) do
		tpsTab:CreateButton({
			Name = "TP " .. areaFolder.Name,
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
						else
							window:Notify({
								title = "Teleport Failed",
								content = "Could not find destination for Shopping Mall",
								duration = 3
							})
						end
					end)
				else
					local targetCFrame = resolveAreaTarget(areaFolder)
					if targetCFrame then
						teleportToTarget(targetCFrame, areaFolder.Name, 4.5)
					else
						window:Notify({
							title = "Teleport Failed",
							content = "Could not find destination for " .. areaFolder.Name,
							duration = 3
						})
					end
				end
			end
		})
	end
end

buildTPs()

-- -----------------------------------------------------------------------
--   NODE 7: SETTINGS
-- -----------------------------------------------------------------------
local settingsTab = window:CreateTab("Settings", "⚙️")

settingsTab:CreateSection("Window Management")

settingsTab:CreateButton({
	Name = "Destroy UI",
	Description = "Completely unloads and closes the script",
	Callback = function()
		window:Destroy()
	end
})

-- -----------------------------------------------------------------------
--   NODE 8: CLOSE TAB (Red X & Glowing Outline)
-- -----------------------------------------------------------------------
window:CreateActionNode("Close", "X", function()
	window:Minimize()
end)

-- =======================================================================
--   DYNAMIC ENTITY COUNTER & KEYBIND INTEGRATION
-- =======================================================================
task.spawn(function()
	while true do
		local count = #getZombies()
		pcall(function()
			local main = parentGui:FindFirstChild("Orbital_Main")
			if main then
				local page = main:FindFirstChild("Zombies_Page", true)
				if page then
					for _, card in ipairs(page:GetChildren()) do
						local tLbl = card:FindFirstChildOfClass("TextLabel")
						if tLbl and tLbl.Text == "Zombies on Map" then
							for _, child in ipairs(card:GetChildren()) do
								if child:IsA("TextLabel") and child ~= tLbl then
									child.Text = tostring(count) .. " zombies currently active on map."
								end
							end
						end
					end
				end
			end
		end)
		task.wait(1)
	end
end)

-- Toggle Menu Keybind (Right Control Minimizes / Restores the Radial HUD)
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
		if window.IsMinimized then
			window:Restore()
		else
			window:Minimize()
		end
	end
end)
