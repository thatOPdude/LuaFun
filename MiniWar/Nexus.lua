--[[
	NEXUS LOADER (Military Dev Hub Edition)
	Includes "The Convergence" intro ritual & multi-UI engine selector.
]]

local Players                = game:GetService("Players")
local CoreGui                = game:GetService("CoreGui")
local UserInputService       = game:GetService("UserInputService")
local TweenService           = game:GetService("TweenService")
local SoundService           = game:GetService("SoundService")
local RunService             = game:GetService("RunService")
local TextService            = game:GetService("TextService")
local Debris                 = game:GetService("Debris")
local Workspace              = game:GetService("Workspace")
local Lighting               = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser            = game:GetService("VirtualUser")

local localPlayer            = Players.LocalPlayer

-- =======================================================================
--   CONFIG & GITHUB REPOSITORY URLS
-- =======================================================================
local Config = {
	Title          = "NEXUS LOADER",
	Subtitle       = "select a UI engine to launch",
	ToggleKey      = Enum.KeyCode.RightShift,
	CloseAfterLoad = true,
	Sounds         = true,
	Intro          = true, -- Enables "The Convergence" startup animation
	Hotkeys        = true,
}

local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local SCRIPTS = {
	{
		Name = "Grimoire",
		Tag = "2.5D slab window  -  crypt intro, 6 live themes",
		LibURL = "https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/Grimoire.lua",
		Accent = C(228, 28, 62), Glow = C(255, 120, 140), Dark = C(110, 12, 34),
		Icon = "grimoire",
	},
	{
		Name = "Prism",
		Tag = "Crystal engine  -  point-light gem shading",
		LibURL = "https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/Prism.lua",
		Accent = C(160, 110, 255), Glow = C(205, 182, 255), Dark = C(84, 58, 168),
		Icon = "prism",
	},
	{
		Name = "Hallow Radial",
		Tag = "Radial pumpkin hub  -  ember ritual",
		LibURL = "https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/HallowOrbitalRework.lua",
		Accent = C(255, 140, 20), Glow = C(255, 206, 80), Dark = C(150, 66, 10),
		Icon = "hallow",
	},
	{
		Name = "Orbital",
		Tag = "Planetfall  -  procedural 3D globe",
		LibURL = "https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/OrbitalLib.lua",
		Accent = C(0, 210, 255), Glow = C(150, 238, 255), Dark = C(0, 110, 165),
		Icon = "orbital",
	},
	{
		Name = "Hallow Window",
		Tag = "Classic Jack-O'-Lantern sidebar window",
		LibURL = "https://raw.githubusercontent.com/thatOPdude/LuaUILibraries/refs/heads/main/HallowLib.lua",
		Accent = C(255, 110, 20), Glow = C(255, 180, 60), Dark = C(120, 45, 10),
		Icon = "hallowOrbital",
	},
}

local GUI_NAME = "Nexus_Loader"

local Sounds = {
	Click   = "rbxassetid://6895079853",
	Hover   = "rbxassetid://6895079853",
	Toggle  = "rbxassetid://6895079853",
	Notify  = "rbxassetid://4590662766",
	Open    = "rbxassetid://4590662766",
	Thunder = "rbxassetid://4590662766",
}

local Pal = {
	Bg = C(9, 9, 18), Panel = C(15, 15, 28), Card = C(22, 22, 40), CardHover = C(32, 32, 58),
	Border = C(46, 46, 84), Glow = C(205, 212, 255), Accent = C(150, 160, 255), On = C(120, 110, 255),
	Text = C(240, 240, 252), Muted = C(150, 152, 186), Success = C(120, 230, 150),
	Warn = C(255, 205, 80), Danger = C(255, 80, 95), Ink = C(12, 10, 22),
}

-- =======================================================================
--   MILITARY DEV HUB CORE LOGIC
-- =======================================================================
local function startMilitaryDevHub(Lib, uiName)
	local selectedPlotId     = "5"
	local detectedMethod     = "Default"
	local autoCollectEnabled = false
	local collectLoopRunning = false
	local collectDelay       = 0.2
	local teleportToBuilding = false
	local instantPrompts     = true

	local currentWalkSpeed   = 16
	local currentJumpPower   = 50
	local fullbrightEnabled  = false

	local antiAfkEnabled     = false
	local antiAfkConn        = nil
	local antiAfkThread      = nil
	local statusLabel        = nil

	local function getHRP()
		local char = localPlayer.Character
		return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
	end

	local function getHumanoid()
		local char = localPlayer.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	local function interactWithPrompt(prompt)
		if not prompt or not prompt.Parent then return end
		pcall(function()
			if instantPrompts then prompt.HoldDuration = 0 end
			prompt.RequiresLineOfSight = false
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

	local function sendVirtualInput()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:Button2Down(Vector2.zero)
			task.wait(0.05)
			VirtualUser:Button2Up(Vector2.zero)
		end)
	end

	local function detectMyPlot()
		local map = Workspace:FindFirstChild("MilitaryMap")
		local playerPlots = map and map:FindFirstChild("PlayerPlots")
		if not playerPlots then return nil, "No Plots Folder" end

		local myName = localPlayer.Name
		local myDisplayName = localPlayer.DisplayName
		local myUserIdStr = tostring(localPlayer.UserId)
		local allPlots = playerPlots:GetChildren()

		for _, attr in ipairs({ "Plot", "PlotId", "PlayerPlot", "PlotNumber", "Base", "BaseId" }) do
			local val = localPlayer:GetAttribute(attr)
			if val and playerPlots:FindFirstChild(tostring(val)) then return tostring(val), "Player Attribute" end
			local child = localPlayer:FindFirstChild(attr)
			if child and child:IsA("ValueBase") and playerPlots:FindFirstChild(tostring(child.Value)) then return tostring(child.Value), "Player Value" end
		end

		for _, plot in ipairs(allPlots) do
			for attrName, attrVal in pairs(plot:GetAttributes()) do
				local str = tostring(attrVal)
				if str == myName or str == myDisplayName or str == myUserIdStr then return plot.Name, "Attribute (" .. attrName .. ")" end
			end
			for _, valName in ipairs({ "Owner", "Player", "UserId", "OwnerId", "OwnerName", "ClaimedBy", "Leader" }) do
				local item = plot:FindFirstChild(valName, true)
				if item then
					if item:IsA("ObjectValue") and item.Value == localPlayer then
						return plot.Name, "Ownership Object"
					elseif item:IsA("ValueBase") and (tostring(item.Value) == myName or tostring(item.Value) == myDisplayName or tostring(item.Value) == myUserIdStr) then
						return plot.Name, "Ownership Value"
					end
				end
			end
		end

		for _, plot in ipairs(allPlots) do
			for _, desc in ipairs(plot:GetDescendants()) do
				if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text ~= "" then
					if string.find(desc.Text, myName, 1, true) or (myDisplayName ~= myName and string.find(desc.Text, myDisplayName, 1, true)) then
						return plot.Name, "Base Sign / Tag"
					end
				end
			end
		end

		local hrp = getHRP()
		if hrp then
			local closestPlot, closestDist = nil, math.huge
			for _, plot in ipairs(allPlots) do
				local cf = plot:GetPivot()
				if cf then
					local dist = (hrp.Position - cf.Position).Magnitude
					if dist < closestDist then closestDist, closestPlot = dist, plot end
				end
			end
			if closestPlot and closestDist < 1200 then return closestPlot.Name, "Closest Proximity" end
		end
		return nil, "Could not detect"
	end

	local function getPlotFolder(plotId)
		local map = Workspace:FindFirstChild("MilitaryMap")
		local playerPlots = map and map:FindFirstChild("PlayerPlots")
		return playerPlots and playerPlots:FindFirstChild(tostring(plotId))
	end

	local function getCollectablePrompts(plotId)
		local plotModel = getPlotFolder(plotId)
		if not plotModel then return {} end
		local plotSub = plotModel:FindFirstChild("Plot")
		local buildingsFolder = plotSub and plotSub:FindFirstChild("Buildings")
		if not buildingsFolder then return {} end

		local collectables = {}
		for _, building in ipairs(buildingsFolder:GetChildren()) do
			for _, desc in ipairs(building:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					local objText = tostring(desc.ObjectText)
					if (objText == "Collect!" or string.find(string.lower(objText), "collect")) and desc.Enabled then
						table.insert(collectables, {
							building = building,
							prompt = desc,
							hostPart = (desc.Parent:IsA("BasePart") and desc.Parent) or building:FindFirstChildWhichIsA("BasePart", true),
						})
					end
				end
			end
		end
		return collectables
	end

	local RawWin = Lib:CreateWindow({
		Title = "MILITARY DEV HUB",
		Subtitle = "plot auto-collector",
		Theme = "Pumpkin",
		ToggleKey = Enum.KeyCode.RightControl,
		Width = 620,
		Height = 440,
	})

	local function Notify(cfg)
		pcall(function()
			if RawWin and RawWin.Notify then
				RawWin:Notify(cfg)
			elseif Lib and Lib.Notify then
				Lib:Notify(cfg)
			end
		end)
	end

	local function formatIcon(iconDef)
		if typeof(iconDef) == "string" then return iconDef end
		if uiName == "Grimoire" then
			return iconDef.Grimoire or iconDef.Default or "star"
		else
			return iconDef.Radial or iconDef.Default or "💰"
		end
	end

	local function wrapTab(rawTab)
		local TabAdapter = {}
		function TabAdapter:CreateSection(name)
			return rawTab:CreateSection(name)
		end

		function TabAdapter:CreateLabel(text)
			local raw = nil
			if rawTab.CreateLabel then
				local ok, res = pcall(function() return rawTab:CreateLabel(text) end)
				if ok then raw = res end
			end

			if type(raw) == "table" and raw.Set then
				return raw
			end

			local targetLabel = nil
			if rawTab.Page then
				pcall(function()
					local card = Instance.new("Frame")
					card.Size = UDim2.new(1, -10, 0, 42)
					card.BackgroundColor3 = Color3.fromRGB(26, 11, 4)
					card.BorderSizePixel = 0
					card.Parent = rawTab.Page

					local corner = Instance.new("UICorner", card)
					corner.CornerRadius = UDim.new(0, 8)

					local stroke = Instance.new("UIStroke", card)
					stroke.Thickness = 1.2
					stroke.Color = Color3.fromRGB(65, 27, 8)

					local lbl = Instance.new("TextLabel")
					lbl.Text = tostring(text or "")
					lbl.Font = Enum.Font.Gotham
					lbl.TextSize = 13
					lbl.TextColor3 = Color3.fromRGB(220, 185, 160)
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.Position = UDim2.new(0, 14, 0, 0)
					lbl.Size = UDim2.new(1, -28, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.Parent = card

					targetLabel = lbl
				end)
			end

			return {
				Set = function(_, newText)
					if raw and raw.Set then
						pcall(function() raw:Set(newText) end)
					end
					if targetLabel and targetLabel.Parent then
						targetLabel.Text = tostring(newText)
					end
				end,
			}
		end

		function TabAdapter:CreateButton(opts)
			opts.Icon = opts.Icon and formatIcon(opts.Icon) or nil
			return rawTab:CreateButton(opts)
		end
		function TabAdapter:CreateToggle(opts)
			return rawTab:CreateToggle(opts)
		end
		function TabAdapter:CreateSlider(opts)
			return rawTab:CreateSlider(opts)
		end
		function TabAdapter:CreateInput(opts)
			return rawTab:CreateInput(opts)
		end
		return TabAdapter
	end

	local function CreateTab(name, iconDef)
		local icon = formatIcon(iconDef)
		return wrapTab(RawWin:CreateTab(name, icon))
	end

	local function setAntiAfk(state)
		antiAfkEnabled = state
		if antiAfkConn then
			antiAfkConn:Disconnect()
			antiAfkConn = nil
		end
		if state then
			if typeof(getconnections) == "function" then
				pcall(function()
					for _, conn in ipairs(getconnections(localPlayer.Idled)) do
						if conn.Disable then conn:Disable() end
						if conn.Disconnect then conn:Disconnect() end
					end
				end)
			end
			antiAfkConn = localPlayer.Idled:Connect(function()
				if antiAfkEnabled then sendVirtualInput() end
			end)
			antiAfkThread = task.spawn(function()
				while antiAfkEnabled do
					task.wait(180)
					if not antiAfkEnabled then break end
					sendVirtualInput()
				end
			end)
			Notify({ Title = "Anti-AFK", Content = "Anti-AFK enabled", Duration = 2.5, Type = "success" })
		else
			Notify({ Title = "Anti-AFK", Content = "Anti-AFK disabled", Duration = 2, Type = "info" })
		end
	end

	local function runCollectionCycle(singleRun)
		if collectLoopRunning and not singleRun then return end
		collectLoopRunning = true

		pcall(function()
			local prompts = getCollectablePrompts(selectedPlotId)
			if #prompts == 0 and singleRun then
				Notify({ Title = "Collector", Content = "No collectable buildings found on Plot " .. tostring(selectedPlotId), Duration = 2.5, Type = "warn" })
				return
			end
			local collectedCount = 0
			for _, item in ipairs(prompts) do
				if not autoCollectEnabled and not singleRun then break end
				local hrp = getHRP()
				local prompt = item.prompt
				local part = item.hostPart
				if prompt and prompt.Parent and prompt.Enabled then
					if teleportToBuilding and hrp and part then
						hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
						hrp.AssemblyLinearVelocity = Vector3.zero
						task.wait(0.1)
					end
					interactWithPrompt(prompt)
					collectedCount = collectedCount + 1
					task.wait(collectDelay)
				end
			end
			if singleRun and collectedCount > 0 then
				Notify({ Title = "Collection Complete", Content = string.format("Collected from %d buildings!", collectedCount), Duration = 3, Type = "success" })
			end
		end)

		collectLoopRunning = false
	end

	-- Build Tabs
	local collectorTab = CreateTab("Collector", { Grimoire = "star", Radial = "💰" })
	collectorTab:CreateSection("Target Plot")
	statusLabel = collectorTab:CreateLabel("Current Target: Plot " .. selectedPlotId .. " (" .. detectedMethod .. ")")

	local function applyDetectedPlot(plotId, method)
		selectedPlotId = tostring(plotId)
		detectedMethod = method or "Detected"
		if statusLabel then
			statusLabel:Set("Current Target: Plot " .. selectedPlotId .. " (" .. detectedMethod .. ")")
		end
		Notify({
			Title = "Plot Found",
			Content = string.format("Detected Plot: %s (%s)", selectedPlotId, detectedMethod),
			Duration = 3,
			Type = "success",
		})
	end

	collectorTab:CreateButton({
		Name = "Auto-Detect My Plot",
		Description = "Scans signs, player attributes, and base proximity",
		Icon = { Grimoire = "star", Radial = "📍" },
		Callback = function()
			local foundPlot, method = detectMyPlot()
			if foundPlot then
				applyDetectedPlot(foundPlot, method)
			else
				Notify({
					Title = "Detection Failed",
					Content = "Stand inside your base and click again!",
					Duration = 3,
					Type = "warn",
				})
			end
		end,
	})

	collectorTab:CreateInput({
		Name = "Manual Plot ID Override",
		Placeholder = "Enter Plot (e.g. 5)",
		Default = selectedPlotId,
		Callback = function(text)
			if text and text ~= "" then
				selectedPlotId = text
				detectedMethod = "Manual"
				if statusLabel then
					statusLabel:Set("Current Target: Plot " .. selectedPlotId .. " (Manual)")
				end
				Notify({
					Title = "Plot Selected",
					Content = "Target set to Plot " .. selectedPlotId,
					Duration = 2,
					Type = "info",
				})
			end
		end,
	})

	collectorTab:CreateSection("Auto Collect Automation")

	collectorTab:CreateToggle({
		Name = "Auto Collect Loop",
		Description = "Continuously sweeps and collects from ready buildings",
		Default = false,
		Callback = function(val)
			autoCollectEnabled = val
			if autoCollectEnabled then
				task.spawn(function()
					while autoCollectEnabled do
						runCollectionCycle(false)
						task.wait(collectDelay)
					end
				end)
			end
		end,
	})

	collectorTab:CreateButton({
		Name = "Collect All Once",
		Description = "Triggers all 'Collect!' prompts on your plot once",
		Icon = { Grimoire = "bolt", Radial = "⚡" },
		Callback = function()
			task.spawn(function()
				runCollectionCycle(true)
			end)
		end,
	})

	collectorTab:CreateToggle({
		Name = "Teleport to Building",
		Description = "Teleports to the building part before collecting",
		Default = false,
		Callback = function(val)
			teleportToBuilding = val
		end,
	})

	collectorTab:CreateToggle({
		Name = "Instant Prompt Duration",
		Description = "Removes prompt hold time (HoldDuration = 0)",
		Default = true,
		Callback = function(val)
			instantPrompts = val
		end,
	})

	collectorTab:CreateSlider({
		Name = "Collection Delay",
		Min = 0.05,
		Max = 2.0,
		Default = 0.2,
		Increment = 0.05,
		Suffix = "s",
		Callback = function(val)
			collectDelay = val
		end,
	})

	local playerTab = CreateTab("Player", { Grimoire = "bolt", Radial = "👤" })
	playerTab:CreateSection("Character Attributes")

	playerTab:CreateSlider({
		Name = "WalkSpeed",
		Min = 16,
		Max = 150,
		Default = 16,
		Increment = 1,
		Callback = function(val)
			currentWalkSpeed = val
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = val
			end
		end,
	})

	playerTab:CreateSlider({
		Name = "Jump Power",
		Min = 50,
		Max = 250,
		Default = 50,
		Increment = 5,
		Callback = function(val)
			currentJumpPower = val
			local hum = getHumanoid()
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = val
			end
		end,
	})

	playerTab:CreateSection("Utility & Visuals")

	playerTab:CreateToggle({
		Name = "Anti-AFK Protection",
		Description = "Prevents 20-minute idle kicks",
		Default = false,
		Callback = function(val)
			setAntiAfk(val)
		end,
	})

	playerTab:CreateToggle({
		Name = "Fullbright",
		Default = false,
		Callback = function(val)
			fullbrightEnabled = val
			if fullbrightEnabled then
				Lighting.Brightness = 2
				Lighting.ClockTime = 14
				Lighting.FogEnd = 100000
				Lighting.GlobalShadows = false
			else
				Lighting.Brightness = 1
				Lighting.GlobalShadows = true
			end
		end,
	})

	playerTab:CreateButton({
		Name = "Teleport to Plot",
		Icon = { Grimoire = "moon", Radial = "📍" },
		Callback = function()
			local plot = getPlotFolder(selectedPlotId)
			local hrp = getHRP()
			if plot and hrp then
				hrp.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0)
				Notify({
					Title = "Teleported",
					Content = "Moved to Plot " .. selectedPlotId,
					Duration = 2,
				})
			end
		end,
	})

	if RawWin.CreateThemeTab then
		RawWin:CreateThemeTab("Settings", "gear")
	else
		local settingsTab = CreateTab("Settings", { Grimoire = "gear", Radial = "⚙️" })
		settingsTab:CreateSection("Window Management")
		settingsTab:CreateButton({
			Name = "Destroy UI",
			Description = "Completely unloads the script and closes the menu",
			Callback = function()
				RawWin:Destroy()
			end,
		})
	end

	if RawWin.CreateActionNode then
		RawWin:CreateActionNode("Close", "X", function()
			RawWin:Minimize()
		end)
	end

	task.spawn(function()
		task.wait(0.5)
		local plotFound, method = detectMyPlot()
		if plotFound then
			applyDetectedPlot(plotFound, method)
		end
	end)

	localPlayer.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.UseJumpPower = true
			hum.WalkSpeed = currentWalkSpeed
			hum.JumpPower = currentJumpPower
		end
	end)
end

-- =======================================================================
--   NEXUS LOADER INTERFACE
-- =======================================================================
local CENTER = Vector2.new(0.5, 0.5)
local Easing, Dir = Enum.EasingStyle, Enum.EasingDirection
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local Reg, Bold, Semi = Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.GothamSemibold
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local NUM_KEYS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
}

local function candidateParents()
	local list = {}
	if typeof(gethui) == "function" then
		local ok, ui = pcall(gethui)
		if ok and ui then table.insert(list, ui) end
	end
	local ok2, rg = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
	if ok2 and rg then table.insert(list, rg) end
	local ok3, pg = pcall(function() return localPlayer:WaitForChild("PlayerGui", 5) end)
	if ok3 and pg then table.insert(list, pg) end
	return list
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function round(parent, radius)
	return new("UICorner", { CornerRadius = radius or UDim.new(1, 0) }, parent)
end

local function outline(parent, color, thickness, transparency)
	return new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = thickness or 1.4,
		Transparency = transparency or 0,
	}, parent)
end

local function label(props, parent)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Reg,
		TextColor3 = Pal.Text,
		TextSize = 14,
		Text = "",
	}
	for k, v in pairs(props) do p[k] = v end
	return new("TextLabel", p, parent)
end

local function bevel(parent, darkness)
	return new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(WHITE, Color3.fromRGB(darkness or 150, darkness or 150, darkness or 150)),
	}, parent)
end

local function rimLight(stroke)
	return new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.7) }),
	}, stroke)
end

local function mix(a, b, t) return a:Lerp(b, t) end

local function tw(obj, props, duration, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(duration or 0.25, style or Easing.Quad, dir or Dir.Out), props)
	t:Play()
	return t
end

local function ease(a, style, dir)
	return TweenService:GetValue(a, style or Easing.Quad, dir or Dir.Out)
end

local function playSound(id, pitch, volume)
	if not Config.Sounds or not id then return end
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = id
			s.PlaybackSpeed = pitch or 1
			s.Volume = volume or 0.8
			s.Parent = SoundService
			s:Play()
			Debris:AddItem(s, 5)
		end)
	end)
end

local lastHover = 0
local function hoverSound(pitch, volume)
	local now = os.clock()
	if now - lastHover > 0.05 then
		lastHover = now
		playSound(Sounds.Hover, pitch or 1.7, volume or 0.3)
	end
end

local function ssub(s, n)
	if n <= 0 then return "" end
	local len = utf8.len(s)
	if not len or n >= len then return s end
	return string.sub(s, 1, utf8.offset(s, n + 1) - 1)
end

local function rainbow()
	local keys = {}
	local n = #SCRIPTS
	for i = 0, n do
		keys[#keys + 1] = ColorSequenceKeypoint.new(i / n, SCRIPTS[(i % n) + 1].Accent)
	end
	return ColorSequence.new(keys)
end
local RAINBOW = rainbow()

local function cycleColor(t)
	local n = #SCRIPTS
	local p = (t * 0.12) % n
	local i = math.floor(p)
	return SCRIPTS[i + 1].Accent:Lerp(SCRIPTS[((i + 1) % n) + 1].Accent, p - i)
end

local function shockwave(parent, color, from, to, dur, thick, pos)
	local ring = new("Frame", {
		AnchorPoint = CENTER,
		Position = pos or UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, from, 0, from),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, parent)
	round(ring)
	local st = outline(ring, color, thick or 3, 0.1)
	tw(ring, { Size = UDim2.new(0, to, 0, to) }, dur, Easing.Quint)
	tw(st, { Transparency = 1, Thickness = 0.5 }, dur)
	Debris:AddItem(ring, dur + 0.1)
end

local function P(parent, kind, x, y, w, h, col, rot, d)
	local f = new("Frame", {
		AnchorPoint = CENTER,
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		BackgroundColor3 = col,
		BorderSizePixel = 0,
		Rotation = rot or 0,
	}, parent)
	if kind == "ellipse" then
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
	elseif kind == "round" then
		new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, f)
	end
	if d then bevel(f, d) end
	return f
end

local function HL(r, x, y, w, h, rot, a)
	local f = P(r, "ellipse", x, y, w, h, WHITE, rot)
	f.BackgroundTransparency = a or 0.78
	return f
end

local Icons = {}
Icons.grimoire = function(r, e)
	P(r, "round", 0.5, 0.54, 0.76, 0.86, mix(e.Dark, BLACK, 0.3), 0, 160)
	P(r, "round", 0.52, 0.50, 0.68, 0.80, e.Accent, 0, 185)
	P(r, "rect", 0.22, 0.50, 0.09, 0.80, e.Dark)
	P(r, "round", 0.57, 0.50, 0.46, 0.60, C(242, 234, 214), 0, 205)
	P(r, "ellipse", 0.57, 0.50, 0.06, 0.34, e.Accent)
	P(r, "ellipse", 0.57, 0.50, 0.34, 0.06, e.Accent)
	P(r, "ellipse", 0.57, 0.50, 0.12, 0.12, e.Glow)
	HL(r, 0.36, 0.26, 0.08, 0.2, 30)
end

Icons.prism = function(r, e)
	P(r, "round", 0.5, 0.5, 0.64, 0.64, e.Accent, 45, 175)
	P(r, "round", 0.5, 0.42, 0.42, 0.42, e.Glow, 45, 165)
	P(r, "round", 0.5, 0.5, 0.18, 0.18, WHITE, 45)
	HL(r, 0.34, 0.34, 0.08, 0.22, 40, 0.6)
end

Icons.hallow = function(r, e)
	local o1, o2, o3 = C(255, 146, 24), C(232, 108, 10), C(176, 70, 6)
	local dk, gl = C(58, 22, 4), C(255, 224, 110)
	P(r, "ellipse", 0.25, 0.60, 0.38, 0.58, o3, 0, 160)
	P(r, "ellipse", 0.75, 0.60, 0.38, 0.58, o3, 0, 160)
	P(r, "ellipse", 0.37, 0.59, 0.40, 0.68, o2, 0, 175)
	P(r, "ellipse", 0.63, 0.59, 0.40, 0.68, o2, 0, 175)
	P(r, "ellipse", 0.50, 0.58, 0.36, 0.72, o1, 0, 190)
	P(r, "round", 0.53, 0.19, 0.11, 0.22, C(86, 120, 44), 14, 160)
	P(r, "round", 0.37, 0.53, 0.115, 0.115, dk, 45)
	P(r, "round", 0.63, 0.53, 0.115, 0.115, dk, 45)
	P(r, "round", 0.37, 0.53, 0.06, 0.06, gl, 45)
	P(r, "round", 0.63, 0.53, 0.06, 0.06, gl, 45)
	P(r, "ellipse", 0.50, 0.75, 0.38, 0.11, dk)
	P(r, "ellipse", 0.50, 0.75, 0.32, 0.065, gl)
	HL(r, 0.31, 0.42, 0.06, 0.2, 10)
end

Icons.orbital = function(r, e)
	P(r, "ellipse", 0.5, 0.5, 0.60, 0.60, C(16, 80, 160), 0, 170)
	P(r, "ellipse", 0.40, 0.42, 0.22, 0.16, e.Glow, -20)
	P(r, "ellipse", 0.58, 0.58, 0.20, 0.14, e.Glow, 25)
	HL(r, 0.36, 0.34, 0.1, 0.16, 30, 0.6)
	local ring = P(r, "ellipse", 0.5, 0.5, 0.96, 0.28, WHITE, -22)
	ring.BackgroundTransparency = 1
	outline(ring, e.Accent, 2)
	P(r, "ellipse", 0.86, 0.36, 0.09, 0.09, WHITE)
end

Icons.hallowOrbital = function(r, e)
	local sub = new("Frame", {
		AnchorPoint = CENTER,
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.62, 0.62),
		BackgroundTransparency = 1,
	}, r)
	Icons.hallow(sub, e)
	local ring = P(r, "ellipse", 0.5, 0.5, 0.98, 0.30, WHITE, -22)
	ring.BackgroundTransparency = 1
	outline(ring, e.Accent, 2)
	P(r, "ellipse", 0.88, 0.34, 0.09, 0.09, WHITE)
end

Icons.nexus = function(r)
	local n = #SCRIPTS
	for i = 1, n do
		local a = -math.pi / 2 + (i - 1) * 2 * math.pi / n
		P(r, "ellipse", 0.5 + math.cos(a) * 0.33, 0.5 + math.sin(a) * 0.33, 0.28, 0.28, SCRIPTS[i].Accent, 0, 170)
	end
	P(r, "ellipse", 0.5, 0.5, 0.26, 0.26, C(240, 240, 255), 0, 190)
end

local function drawInto(root, name, entry)
	for _, c in ipairs(root:GetChildren()) do c:Destroy() end
	local fn = Icons[name]
	if fn then fn(root, entry or SCRIPTS[1]) end
end

local function mkIcon(name, parent, o)
	o = o or {}
	local sz = o.Size or 24
	local root = new("CanvasGroup", {
		AnchorPoint = o.AnchorPoint or Vector2.new(0, 0),
		Position = o.Position or UDim2.new(0, 0, 0, 0),
		Size = (typeof(sz) == "number") and UDim2.new(0, sz, 0, sz) or sz,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = o.ZIndex or 1,
	}, parent)
	if name then drawInto(root, name, o.Entry) end
	return root
end

-- =======================================================================
--   CREATE NEXUS LOADER WITH "THE CONVERGENCE" INTRO
-- =======================================================================
local function CreateLoader()
	local W, H = 620, 490
	local toggleKey = Config.ToggleKey
	local closeAfter = Config.CloseAfterLoad

	for _, p in ipairs(candidateParents()) do
		local old = p:FindFirstChild(GUI_NAME)
		if old then pcall(function() old:Destroy() end) end
	end

	local Win = { Started = false, InIntro = false, Minimized = false, Busy = false, Destroyed = false }

	local conns = {}
	local function track(c) conns[#conns + 1] = c return c end

	local ScreenGui = new("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})

	local spinners = {}
	local function sweep(target, speed)
		local g = new("UIGradient", { Color = RAINBOW, Rotation = math.random(0, 359) }, target)
		spinners[#spinners + 1] = { g = g, speed = speed or 50 }
		return g
	end

	local Dim = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, ScreenGui)

	local Flash = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, ScreenGui)

	local NotifyHolder = new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -22, 1, -22),
		Size = UDim2.new(0, 320, 1, -44),
		BackgroundTransparency = 1,
		ZIndex = 60,
	}, ScreenGui)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
	}, NotifyHolder)

	local function notify(cfg)
		if not NotifyHolder or not NotifyHolder.Parent then return end
		local title = tostring(cfg.Title or "Notice")
		local text = tostring(cfg.Content or "")
		local duration = cfg.Duration or 3.5
		local accent = ({ info = Pal.Glow, success = Pal.Success, warn = Pal.Warn, error = Pal.Danger })[cfg.Type or "info"] or Pal.Glow
		playSound(Sounds.Notify, 1, 0.9)

		local okT, sz = pcall(function() return TextService:GetTextSize(text, 12, Reg, Vector2.new(260, 10000)) end)
		local textH = okT and sz.Y or 14
		local height = math.max(60, 40 + textH + 14)
		local DEPTH = 6

		local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, height + DEPTH), BackgroundTransparency = 1 }, NotifyHolder)
		local mover = new("Frame", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1.2, 0, 0, 0), BackgroundTransparency = 1 }, wrap)
		local slab = new("Frame", {
			Position = UDim2.new(0, 0, 0, DEPTH), Size = UDim2.new(1, 0, 1, -DEPTH),
			BackgroundColor3 = mix(accent, BLACK, 0.62), BorderSizePixel = 0,
		}, mover)
		round(slab, UDim.new(0, 10))
		local toast = new("Frame", {
			Size = UDim2.new(1, 0, 1, -DEPTH), BackgroundColor3 = Pal.Bg, BackgroundTransparency = 0.03,
			BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
		}, mover)
		round(toast, UDim.new(0, 10))
		bevel(toast, 190)
		rimLight(outline(toast, accent, 1.5, 0.1))
		new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, toast)
		label({
			Text = title, Font = Bold, TextSize = 14, TextColor3 = accent, TextXAlignment = Left,
			Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -26, 0, 18),
		}, toast)
		label({
			Text = text, TextSize = 12, TextColor3 = Pal.Muted, TextXAlignment = Left,
			TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
			Position = UDim2.new(0, 16, 0, 31), Size = UDim2.new(1, -28, 0, textH),
		}, toast)
		local bar = new("Frame", {
			Position = UDim2.new(0, 16, 1, -7), Size = UDim2.new(1, -32, 0, 2),
			BackgroundColor3 = accent, BackgroundTransparency = 0.25, BorderSizePixel = 0,
		}, toast)
		round(bar)

		tw(mover, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Easing.Back)
		tw(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Easing.Linear)

		local dismissed = false
		local function dismiss()
			if dismissed then return end
			dismissed = true
			local out = tw(mover, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3, Easing.Back, Dir.In)
			out.Completed:Connect(function()
				local shrink = tw(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
				shrink.Completed:Connect(function() wrap:Destroy() end)
			end)
		end
		local catcher = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, toast)
		catcher.MouseButton1Click:Connect(dismiss)
		task.delay(duration, dismiss)
	end

	-- Intro stage for ritual animations
	local Stage = new("Frame", {
		AnchorPoint = CENTER,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, ScreenGui)
	local StageScale = new("UIScale", nil, Stage)

	local Root = new("Frame", {
		Name = "Root",
		AnchorPoint = CENTER,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
	}, ScreenGui)
	local RootScale = new("UIScale", nil, Root)
	local RootFX = new("Frame", {
		AnchorPoint = CENTER,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 25,
	}, Root)

	local function applyScale()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.clamp(math.min(vp.X / (W + 70), vp.Y / (H + 90)), 0.4, 1)
		RootScale.Scale = s
		StageScale.Scale = s
	end
	applyScale()
	if Workspace.CurrentCamera then
		track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end

	local GLOW_PADS, GLOW_BASE = { 20, 48, 88 }, { 0.86, 0.93, 0.968 }
	local Glow = {}
	for i = 1, 3 do
		local g = new("Frame", {
			AnchorPoint = CENTER,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Pal.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, Root)
		round(g, UDim.new(0, 14 + GLOW_PADS[i]))
		Glow[i] = g
	end
	local glowTarget, glowI = 0, 0

	local SLABS = 9
	local Slab = {}
	for k = SLABS, 1, -1 do
		local s = new("Frame", {
			AnchorPoint = CENTER,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = mix(Pal.Border, BLACK, (k - 1) / (SLABS - 1) * 0.82),
			BorderSizePixel = 0,
			ZIndex = 3 + (SLABS - k),
		}, Root)
		round(s, UDim.new(0, 14))
		Slab[k] = s
	end
	local SlabLip = outline(Slab[1], Pal.Accent, 1.2, 0.5)

	local Window = new("Frame", {
		Name = "Window",
		AnchorPoint = CENTER,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H),
		BackgroundColor3 = Pal.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 20,
	}, Root)
	round(Window, UDim.new(0, 14))
	bevel(Window, 205)
	local WinStroke = outline(Window, WHITE, 2.5, 0.05)
	sweep(WinStroke, 40)

	local Body = new("Frame", {
		AnchorPoint = CENTER,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
	}, Window)

	local Header = new("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Pal.Panel,
		BorderSizePixel = 0,
		ZIndex = 3,
		Active = true,
	}, Body)
	round(Header, UDim.new(0, 14))
	new("Frame", {
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = Pal.Panel,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, Header)
	local HeaderLine = new("Frame", {
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, Header)
	new("UIGradient", { Color = RAINBOW }, HeaderLine)

	local HMedal = new("Frame", {
		Position = UDim2.new(0, 12, 0.5, -22),
		Size = UDim2.new(0, 44, 0, 44),
		BackgroundColor3 = Pal.Card,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, Header)
	round(HMedal)
	bevel(HMedal, 170)
	sweep(outline(HMedal, WHITE, 1.8, 0.1), 80)
	mkIcon("nexus", HMedal, { Size = 32, AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 5 })

	local TitleL = label({
		Text = Config.Title,
		Font = Bold,
		TextSize = 18,
		TextColor3 = WHITE,
		TextXAlignment = Left,
		Position = UDim2.new(0, 68, 0, 12),
		Size = UDim2.new(0, 300, 0, 24),
		ZIndex = 5,
	}, Header)
	sweep(TitleL, 25)
	label({
		Text = Config.Subtitle,
		TextSize = 11,
		TextColor3 = Pal.Muted,
		TextXAlignment = Left,
		Position = UDim2.new(0, 68, 0, 37),
		Size = UDim2.new(0, 300, 0, 14),
		ZIndex = 5,
	}, Header)

	local CloseBtn = new("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -42, 0.5, -14),
		BackgroundColor3 = Pal.Card,
		BorderSizePixel = 0,
		Text = "X",
		TextColor3 = Pal.Muted,
		Font = Bold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 6,
	}, Header)
	round(CloseBtn)

	do
		local dragging, dragStart, startPos = false, nil, nil
		Header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = true, input.Position, Root.Position
			end
		end)
		track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end

	local Footer = new("Frame", {
		Position = UDim2.new(0, 0, 1, -52),
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, Body)
	new("Frame", {
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = Pal.Border,
		BorderSizePixel = 0,
	}, Footer)

	local StatusL = label({
		Text = #SCRIPTS .. " hubs ready",
		TextSize = 12,
		TextColor3 = Pal.Muted,
		TextXAlignment = Right,
		Position = UDim2.new(1, -316, 0, 0),
		Size = UDim2.new(0, 284, 1, 0),
		ZIndex = 4,
	}, Footer)
	local StatusDot = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -26, 0.5, 0),
		Size = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Pal.Success,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, Footer)
	round(StatusDot)

	local function setStatus(text, col)
		StatusL.Text = text
		StatusL.TextColor3 = col or Pal.Muted
		tw(StatusDot, { BackgroundColor3 = col or Pal.Success }, 0.25)
	end

	local List = new("ScrollingFrame", {
		Position = UDim2.new(0, 16, 0, 78),
		Size = UDim2.new(1, -32, 1, -78 - 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Pal.Accent,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 3,
	}, Body)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, List)
	new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8) }, List)

	local DEPTH, REST, PRESS, CARD_H = 5, 2, 4, 58
	local entries = {}

	local function ripple(card)
		local m = UserInputService:GetMouseLocation()
		local sc = RootScale.Scale
		local r = new("Frame", {
			AnchorPoint = CENTER,
			Position = UDim2.new(0, (m.X - card.AbsolutePosition.X) / sc, 0, (m.Y - card.AbsolutePosition.Y) / sc),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, card)
		round(r)
		tw(r, { Size = UDim2.new(0, 380, 0, 380), BackgroundTransparency = 1 }, 0.55)
		Debris:AddItem(r, 0.6)
	end

	local function buildEntry(idx, e)
		local Holder = new("Frame", {
			Size = UDim2.new(1, -4, 0, CARD_H + DEPTH),
			BackgroundTransparency = 1,
			LayoutOrder = idx,
		}, List)
		local Mover = new("Frame", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 60, 0, 0), BackgroundTransparency = 1 }, Holder)

		local Base = new("Frame", {
			Position = UDim2.new(0, 0, 0, DEPTH),
			Size = UDim2.new(1, 0, 1, -DEPTH),
			BackgroundColor3 = mix(e.Dark, BLACK, 0.6),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, Mover)
		round(Base, UDim.new(0, 12))

		local Card = new("Frame", {
			Position = UDim2.new(0, 0, 0, REST),
			Size = UDim2.new(1, 0, 1, -DEPTH),
			BackgroundColor3 = Pal.Card,
			BorderSizePixel = 0,
			ZIndex = 2,
			ClipsDescendants = true,
		}, Mover)
		round(Card, UDim.new(0, 12))
		bevel(Card, 200)
		local stroke = outline(Card, Pal.Border, 1.3)
		rimLight(stroke)

		local Medal = new("Frame", {
			Position = UDim2.new(0, 18, 0.5, -20),
			Size = UDim2.new(0, 40, 0, 40),
			BackgroundColor3 = mix(e.Dark, BLACK, 0.55),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, Card)
		round(Medal)
		bevel(Medal, 170)
		local medalStroke = outline(Medal, e.Accent, 1.5, 0.45)
		rimLight(medalStroke)
		mkIcon(e.Icon, Medal, { Size = 30, AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 3, Entry = e })

		label({
			Text = e.Name,
			Font = Bold,
			TextSize = 15,
			TextXAlignment = Left,
			Position = UDim2.new(0, 72, 0, 9),
			Size = UDim2.new(1, -240, 0, 20),
			ZIndex = 2,
		}, Card)
		local TagL = label({
			Text = e.Tag,
			TextSize = 12,
			TextColor3 = Pal.Muted,
			TextXAlignment = Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 72, 0, 30),
			Size = UDim2.new(1, -240, 0, 16),
			ZIndex = 2,
		}, Card)

		local Pill = new("Frame", {
			Position = UDim2.new(1, -118, 0.5, -15),
			Size = UDim2.new(0, 104, 0, 30),
			BackgroundColor3 = e.Accent,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, Card)
		round(Pill)
		bevel(Pill, 185)
		local PillS = outline(Pill, e.Glow, 1.4, 0.3)
		local PillL = label({
			Text = "LAUNCH",
			Font = Bold,
			TextSize = 12,
			TextColor3 = Pal.Ink,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 3,
		}, Pill)

		local Click = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 6 }, Card)

		local st = { entry = e, state = "ready", hover = false, pillL = PillL, pillS = PillS, mover = Mover }
		entries[idx] = st

		local function launch()
			if st.state == "loading" or Win.Destroyed then return end
			st.state = "loading"
			PillL.Text = "LOADING"
			PillS.Transparency = 0.3
			tw(Pill, { BackgroundColor3 = Pal.Panel }, 0.2)
			tw(PillL, { TextColor3 = e.Glow }, 0.2)
			tw(PillS, { Color = e.Accent }, 0.2)
			TagL.Text = "mounting UI engine..."
			TagL.TextColor3 = e.Glow
			setStatus("loading " .. e.Name .. "...", e.Glow)

			task.spawn(function()
				local ok, Lib = pcall(function()
					local raw = game:HttpGet(e.LibURL)
					return loadstring(raw)()
				end)

				if not ok or not Lib then
					st.state = "failed"
					PillL.Text = "FAILED"
					tw(Pill, { BackgroundColor3 = Pal.Danger }, 0.2)
					tw(PillL, { TextColor3 = Pal.Ink }, 0.2)
					TagL.Text = "failed to fetch library"
					TagL.TextColor3 = Pal.Danger
					setStatus(e.Name .. " failed", Pal.Danger)
					return
				end

				PillL.Text = "LOADED"
				tw(Pill, { BackgroundColor3 = Pal.Success }, 0.2)
				tw(PillL, { TextColor3 = Pal.Ink }, 0.2)
				TagL.Text = "hub is running"
				TagL.TextColor3 = Pal.Success
				setStatus(e.Name .. " loaded", Pal.Success)
				playSound(Sounds.Open, 1.3, 0.8)

				startMilitaryDevHub(Lib, e.Name)

				if closeAfter then
					task.delay(0.8, function()
						Win:Destroy()
					end)
				end
			end)
		end
		st.launch = launch

		Click.MouseEnter:Connect(function()
			st.hover = true
			hoverSound(1.7, 0.3)
			tw(Card, { BackgroundColor3 = Pal.CardHover, Position = UDim2.new(0, 0, 0, 0) }, 0.15)
		end)
		Click.MouseLeave:Connect(function()
			st.hover = false
			tw(Card, { BackgroundColor3 = Pal.Card, Position = UDim2.new(0, 0, 0, REST) }, 0.2)
		end)
		Click.MouseButton1Down:Connect(function() tw(Card, { Position = UDim2.new(0, 0, 0, PRESS) }, 0.06) end)
		Click.MouseButton1Up:Connect(function() tw(Card, { Position = UDim2.new(0, 0, 0, 0) }, 0.2) end)
		Click.MouseButton1Click:Connect(function()
			playSound(Sounds.Click, 1.0, 0.9)
			ripple(Card)
			launch()
		end)
	end

	for i, e in ipairs(SCRIPTS) do buildEntry(i, e) end

	local function playCards()
		for i, st in ipairs(entries) do
			st.mover.Position = UDim2.new(0, 60, 0, 0)
			task.delay((i - 1) * 0.07, function()
				if st.mover.Parent then
					tw(st.mover, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, Easing.Quint)
				end
			end)
		end
	end

	-- =====================================================================
	--   EFFECT HELPERS
	-- =====================================================================
	local function lightning(power)
		power = power or 1
		task.spawn(function()
			Flash.BackgroundColor3 = WHITE
			Flash.BackgroundTransparency = 1 - 0.5 * power
			tw(Flash, { BackgroundTransparency = 1 }, 0.12)
			task.wait(0.15)
			Flash.BackgroundTransparency = 1 - 0.7 * power
			tw(Flash, { BackgroundTransparency = 1 }, 0.5)
		end)
		playSound(Sounds.Thunder, 0.5, 1)
	end

	local function shake(target, power, dur)
		task.spawn(function()
			local base = target.Position
			local t = 0
			while t < dur do
				local dt = RunService.RenderStepped:Wait()
				t += dt
				local k = 1 - t / dur
				target.Position = UDim2.new(
					base.X.Scale, base.X.Offset + (math.random() - 0.5) * 2 * power * k,
					base.Y.Scale, base.Y.Offset + (math.random() - 0.5) * 2 * power * k
				)
			end
			target.Position = base
		end)
	end

	local function scramble(lbl, text)
		local pool = "#%&@$?/\\|<>~^*+="
		local n = utf8.len(text) or #text
		for i = 1, n do
			for _ = 1, 2 do
				if not lbl.Parent then return end
				local r = math.random(#pool)
				lbl.Text = ssub(text, i - 1) .. string.sub(pool, r, r)
				task.wait(0.025)
			end
		end
		if lbl.Parent then lbl.Text = text end
	end

	local function openWindow()
		Root.Visible = true
		Window.BackgroundColor3 = C(225, 228, 255)
		Window.Size = UDim2.new(0, 3, 0, 0)
		glowTarget = 1
		playSound(Sounds.Open, 1.1, 0.9)
		tw(Window, { Size = UDim2.new(0, 3, 0, H) }, 0.35, Easing.Quint)
		task.wait(0.3)
		shockwave(RootFX, Pal.Glow, 60, W * 1.1, 0.7, 3)
		tw(Window, { Size = UDim2.new(0, W, 0, H), BackgroundColor3 = Pal.Bg }, 0.7, Easing.Quint)
		task.wait(0.6)
	end

	local function closeWindow()
		glowTarget = 0
		tw(Window, { Size = UDim2.new(0, 3, 0, H), BackgroundColor3 = C(225, 228, 255) }, 0.4, Easing.Quint, Dir.In)
		task.wait(0.4)
		tw(Window, { Size = UDim2.new(0, 3, 0, 0) }, 0.22, Easing.Quint, Dir.In)
		task.wait(0.22)
		Root.Visible = false
	end

	function Win:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		playSound(Sounds.Click, 0.8, 0.9)
		task.spawn(function()
			if Root.Visible then closeWindow() end
			task.wait(0.35)
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
			ScreenGui:Destroy()
		end)
	end

	CloseBtn.MouseButton1Click:Connect(function() Win:Destroy() end)

	-- =====================================================================
	--   INTRO: THE CONVERGENCE
	-- =====================================================================
	local function animate(dur, step)
		local start = os.clock()
		while true do
			RunService.RenderStepped:Wait()
			if Win.Destroyed then return false end
			local a = math.clamp((os.clock() - start) / dur, 0, 1)
			step(a)
			if a >= 1 then return true end
		end
	end

	local function runIntro()
		Win.InIntro = true
		local ritual = {}
		local function keep(o) ritual[#ritual + 1] = o return o end
		local RING_R = 120

		local ring = keep(new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1, ZIndex = 1,
		}, Stage))
		round(ring)
		local ringS = outline(ring, WHITE, 2, 1)
		sweep(ringS, 140)

		local orbs = {}
		for i, e in ipairs(SCRIPTS) do
			local halo = keep(new("Frame", {
				AnchorPoint = CENTER, Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = e.Accent,
				BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 2,
			}, Stage))
			round(halo)
			local core = keep(new("Frame", {
				AnchorPoint = CENTER, Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = e.Glow, BorderSizePixel = 0, ZIndex = 3,
			}, Stage))
			round(core)
			orbs[i] = { halo = halo, core = core, color = e.Glow, base = (i - 1) / #SCRIPTS * math.pi * 2 }
		end

		local status = keep(label({
			Text = "", TextSize = 13, TextColor3 = Pal.Muted, TextTransparency = 1, AnchorPoint = CENTER,
			Position = UDim2.new(0, 0, 0, RING_R + 56), Size = UDim2.new(0, 320, 0, 20), ZIndex = 4,
		}, Stage))
		local function say(text)
			status.Text = text
			status.TextTransparency = 1
			tw(status, { TextTransparency = 0.15 }, 0.35)
		end

		local iR, iAng, iSpin, iSize = 0, 0, 1.5, 0
		local trailT = 0
		local conn = RunService.RenderStepped:Connect(function(dt)
			iAng += iSpin * dt
			trailT += dt
			local dropTrail = trailT > 0.045 and iSize > 0.3
			if dropTrail then trailT = 0 end
			for _, o in ipairs(orbs) do
				local a = o.base + iAng
				local x, y = math.cos(a) * iR, math.sin(a) * iR
				local pos = UDim2.new(0, x, 0, y)
				o.core.Position, o.halo.Position = pos, pos
				o.core.Size = UDim2.new(0, 12 * iSize, 0, 12 * iSize)
				o.halo.Size = UDim2.new(0, 46 * iSize, 0, 46 * iSize)
				if dropTrail then
					local d = new("Frame", {
						AnchorPoint = CENTER, Position = pos, Size = UDim2.new(0, 9 * iSize, 0, 9 * iSize),
						BackgroundColor3 = o.color, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 2,
					}, Stage)
					round(d)
					tw(d, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.5, Easing.Quad)
					Debris:AddItem(d, 0.6)
				end
			end
		end)

		local function abort()
			conn:Disconnect()
			for _, o in ipairs(ritual) do pcall(function() o:Destroy() end) end
		end

		tw(Dim, { BackgroundTransparency = 0.4 }, 0.8)
		task.wait(0.35)
		if Win.Destroyed then return abort() end

		say("gathering the hubs...")
		playSound(Sounds.Open, 0.7, 0.8)
		tw(ring, { Size = UDim2.new(0, RING_R * 2, 0, RING_R * 2) }, 0.9, Easing.Quint)
		tw(ringS, { Transparency = 0.4 }, 0.9)
		if not animate(0.9, function(a)
			local k = ease(a, Easing.Quint, Dir.Out)
			iR, iSize = RING_R * k, k
		end) then return abort() end
		task.wait(0.25)

		say("binding them together...")
		if not animate(1.0, function(a)
			iSpin = 1.5 + 11 * ease(a, Easing.Quad, Dir.In)
		end) then return abort() end

		status.TextTransparency = 1
		tw(ring, { Size = UDim2.new(0, 0, 0, 0) }, 0.55, Easing.Quint, Dir.In)
		tw(ringS, { Transparency = 1 }, 0.5)
		if not animate(0.55, function(a)
			iR = RING_R * (1 - ease(a, Easing.Quint, Dir.In))
			iSize = 1 + a * 0.8
		end) then return abort() end

		lightning(1)
		shake(Stage, 10, 0.4)
		for i, e in ipairs(SCRIPTS) do
			task.delay((i - 1) * 0.07, function()
				if not Win.Destroyed then shockwave(Stage, e.Glow, 120, 900, 1.0, 4) end
			end)
		end
		abort()
		if Win.Destroyed then return end

		openWindow()
		if Win.Destroyed then return end
		tw(Dim, { BackgroundTransparency = 1 }, 0.9)

		Win.InIntro = false
		Win.Started = true
		playCards()
		task.spawn(scramble, TitleL, Config.Title)
		notify({
			Title = "Nexus ready",
			Content = "Press 1-5 or click LAUNCH to mount any UI engine.",
			Duration = 4,
		})
	end

	track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or Win.Destroyed then return end
		if Config.Hotkeys and Win.Started and Root.Visible and not Win.InIntro then
			for i, k in ipairs(NUM_KEYS) do
				if input.KeyCode == k and entries[i] then
					entries[i].launch()
					break
				end
			end
		end
	end))

	track(RunService.RenderStepped:Connect(function(dt)
		if Win.Destroyed then return end
		local t = os.clock()

		for i = #spinners, 1, -1 do
			local s = spinners[i]
			if s.g:IsDescendantOf(ScreenGui) then
				s.g.Rotation = (s.g.Rotation + s.speed * dt) % 360
			else
				table.remove(spinners, i)
			end
		end

		if Root.Visible then
			local col = cycleColor(t)
			glowI += (glowTarget - glowI) * math.min(1, dt * 4)
			local flick = math.clamp(0.5 + math.noise(t * 2.2, 3.71), 0, 1)
			local gw, gh = Window.Size.X.Offset, Window.Size.Y.Offset
			for i, g in ipairs(Glow) do
				local pad = GLOW_PADS[i] * (0.94 + 0.12 * flick)
				g.Size = UDim2.new(0, gw + pad * 2, 0, gh + pad * 2)
				g.BackgroundColor3 = col
				g.BackgroundTransparency = 1 - (1 - GLOW_BASE[i]) * glowI * (0.8 + 0.2 * flick)
			end
			SlabLip.Color = col
		end
	end))

	for _, p in ipairs(candidateParents()) do
		local ok = pcall(function() ScreenGui.Parent = p end)
		if ok and ScreenGui.Parent == p then break end
	end

	task.defer(function()
		if Win.Destroyed then return end
		if Config.Intro then
			runIntro()
		else
			openWindow()
			TitleL.Text = Config.Title
			Win.Started = true
			playCards()
		end
	end)

	return Win
end

return CreateLoader()
