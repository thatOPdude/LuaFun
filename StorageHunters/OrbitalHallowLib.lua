-- =======================================================================
--   🎃 HALLOW-RADIAL UI LIBRARY (STANDALONE MODULE)
--   Theme: Beveled Carved Pumpkin / Fixed Return Highlight / Clean Reset
-- =======================================================================

local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")
local localPlayer      = Players.LocalPlayer

-- GUI Container Selector
local parentGui = (typeof(gethui) == "function" and gethui()) 
	or CoreGui:FindFirstChild("RobloxGui") 
	or localPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("HallowRadial_Main") then
	parentGui:FindFirstChild("HallowRadial_Main"):Destroy()
end

local Hallow = {
	Sounds = {
		Click  = "rbxassetid://6895079853",
		Hover  = "rbxassetid://6895079853",
		Toggle = "rbxassetid://6895079853",
		Notify = "rbxassetid://4590662766", -- Crisp chime / ding
		Open   = "rbxassetid://4590662766",
	},
	Theme = {
		CoreBg       = Color3.fromRGB(18, 8, 3),
		InnerRing    = Color3.fromRGB(32, 14, 5),      -- Inner beveled plate
		NodeBg       = Color3.fromRGB(24, 10, 4),
		NodeHover    = Color3.fromRGB(48, 20, 8),
		NodeActive   = Color3.fromRGB(65, 26, 8),
		Amber        = Color3.fromRGB(255, 140, 20),
		AmberGlow    = Color3.fromRGB(255, 195, 50),   -- Candlelight amber glow
		AmberDark    = Color3.fromRGB(150, 65, 10),
		RedClose     = Color3.fromRGB(255, 55, 65),    -- Bright Red Close X
		RedCloseGlow = Color3.fromRGB(255, 95, 95),
		CardBg       = Color3.fromRGB(28, 11, 4),
		CardHover    = Color3.fromRGB(46, 18, 6),
		BorderDim    = Color3.fromRGB(58, 24, 7),
		BorderGlow   = Color3.fromRGB(255, 145, 25),
		TextPrimary  = Color3.fromRGB(255, 240, 225),
		TextMuted    = Color3.fromRGB(195, 145, 115),
	}
}

-- Fast Tween Helper
local function tw(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local anim = TweenService:Create(obj, info, props)
	anim:Play()
	return anim
end

-- Sound Player
local function playSound(soundId, pitch, volume)
	task.spawn(function()
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Pitch = pitch or 1
		s.Volume = volume or 0.85
		s.Parent = SoundService
		s:Play()
		s.Ended:Connect(function() s:Destroy() end)
	end)
end

-- Hover sound with debounce
local lastHoverTick = 0
local function playHoverSound(pitch, volume)
	local now = tick()
	if now - lastHoverTick > 0.04 then
		lastHoverTick = now
		playSound(Hallow.Sounds.Hover, pitch or 1.65, volume or 0.5)
	end
end

-- =======================================================================
--   NOTIFICATION SYSTEM (TOASTS)
-- =======================================================================
local NotifyHolder
local function initNotifyHolder(gui)
	if not NotifyHolder then
		NotifyHolder = Instance.new("Frame")
		NotifyHolder.Name = "NotifyHolder"
		NotifyHolder.AnchorPoint = Vector2.new(1, 1)
		NotifyHolder.Position = UDim2.new(1, -24, 1, -24)
		NotifyHolder.Size = UDim2.new(0, 320, 1, -48)
		NotifyHolder.BackgroundTransparency = 1
		NotifyHolder.Parent = gui

		local layout = Instance.new("UIListLayout", NotifyHolder)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Padding = UDim.new(0, 10)
	end
end

function Hallow:Notify(config)
	config = config or {}
	local title = config.Title or config.title or "🎃 Notification"
	local text = config.Content or config.content or ""
	local duration = config.Duration or config.duration or 3.5

	playSound(Hallow.Sounds.Notify, 1, 0.95)

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 76)
	toast.BackgroundColor3 = Hallow.Theme.CoreBg
	toast.BorderSizePixel = 0
	toast.BackgroundTransparency = 1
	toast.ClipsDescendants = true
	toast.Parent = NotifyHolder

	local corner = Instance.new("UICorner", toast)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", toast)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Hallow.Theme.Amber
	stroke.Thickness = 1.4
	stroke.Transparency = 1

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = Hallow.Theme.AmberGlow
	bar.BorderSizePixel = 0
	bar.Parent = toast

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = title
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 14
	tLbl.TextColor3 = Hallow.Theme.AmberGlow
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Position = UDim2.new(0, 16, 0, 10)
	tLbl.Size = UDim2.new(1, -26, 0, 18)
	tLbl.BackgroundTransparency = 1
	tLbl.TextTransparency = 1
	tLbl.Parent = toast

	local dLbl = Instance.new("TextLabel")
	dLbl.Text = text
	dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 12
	dLbl.TextColor3 = Hallow.Theme.TextMuted
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextWrapped = true
	dLbl.Position = UDim2.new(0, 16, 0, 30)
	dLbl.Size = UDim2.new(1, -26, 0, 36)
	dLbl.BackgroundTransparency = 1
	dLbl.TextTransparency = 1
	dLbl.Parent = toast

	tw(toast, { BackgroundTransparency = 0.05 }, 0.35, Enum.EasingStyle.Back)
	tw(stroke, { Transparency = 0 }, 0.35)
	tw(tLbl, { TextTransparency = 0 }, 0.3)
	tw(dLbl, { TextTransparency = 0 }, 0.3)

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1, -4, 0, 2)
	progress.Position = UDim2.new(0, 4, 1, -2)
	progress.BackgroundColor3 = Hallow.Theme.Amber
	progress.BorderSizePixel = 0
	progress.Parent = toast

	tw(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not toast or not toast.Parent then return end
		local outTween = tw(toast, {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0)
		}, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(stroke, { Transparency = 1 }, 0.2)
		tw(tLbl, { TextTransparency = 1 }, 0.2)
		tw(dLbl, { TextTransparency = 1 }, 0.2)
		outTween.Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

-- =======================================================================
--   CREATE WINDOW (RADIAL SYSTEM INITIALIZER)
-- =======================================================================
function Hallow:CreateWindow(settings)
	settings = settings or {}
	local winTitle = settings.Title or "HALLOW"

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "HallowRadial_Main"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = parentGui

	initNotifyHolder(ScreenGui)

	local BaseCenter = Instance.new("Frame")
	BaseCenter.Name = "BaseCenter"
	BaseCenter.AnchorPoint = Vector2.new(0.5, 0.5)
	BaseCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
	BaseCenter.Size = UDim2.new(0, 0, 0, 0)
	BaseCenter.BackgroundTransparency = 1
	BaseCenter.Parent = ScreenGui

	-- Floating Top Reopen Pumpkin Button
	local MiniPumpkin = Instance.new("TextButton")
	MiniPumpkin.Name = "MiniPumpkin"
	MiniPumpkin.AnchorPoint = Vector2.new(0.5, 0)
	MiniPumpkin.Position = UDim2.new(0.5, 0, -0.12, 0)
	MiniPumpkin.Size = UDim2.new(0, 74, 0, 74)
	MiniPumpkin.BackgroundColor3 = Hallow.Theme.CoreBg
	MiniPumpkin.BorderSizePixel = 0
	MiniPumpkin.AutoButtonColor = false
	MiniPumpkin.Text = "🎃"
	MiniPumpkin.TextSize = 40
	MiniPumpkin.Visible = false
	MiniPumpkin.Parent = ScreenGui
	Instance.new("UICorner", MiniPumpkin).CornerRadius = UDim.new(1, 0)

	local MiniStroke = Instance.new("UIStroke", MiniPumpkin)
	MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MiniStroke.Color = Hallow.Theme.Amber
	MiniStroke.Thickness = 3.5

	MiniPumpkin.MouseEnter:Connect(function()
		tw(MiniPumpkin, { Size = UDim2.new(0, 82, 0, 82) }, 0.15)
		tw(MiniStroke, { Color = Hallow.Theme.AmberGlow, Thickness = 4 })
		playHoverSound(1.6, 0.4)
	end)
	MiniPumpkin.MouseLeave:Connect(function()
		tw(MiniPumpkin, { Size = UDim2.new(0, 74, 0, 74) }, 0.15)
		tw(MiniStroke, { Color = Hallow.Theme.Amber, Thickness = 3.5 })
	end)

	-- Central Core: Starts HUGE at 380px on load
	local CoreHolder = Instance.new("Frame")
	CoreHolder.Name = "CoreHolder"
	CoreHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	CoreHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
	CoreHolder.Size = UDim2.new(0, 380, 0, 380)
	CoreHolder.BackgroundColor3 = Hallow.Theme.CoreBg
	CoreHolder.BorderSizePixel = 0
	CoreHolder.ClipsDescendants = false
	CoreHolder.Visible = true
	CoreHolder.Parent = ScreenGui
	Instance.new("UICorner", CoreHolder).CornerRadius = UDim.new(1, 0)

	local CoreStroke = Instance.new("UIStroke", CoreHolder)
	CoreStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	CoreStroke.Color = Hallow.Theme.Amber
	CoreStroke.Thickness = 4.5

	local DecRing = Instance.new("Frame")
	DecRing.AnchorPoint = Vector2.new(0.5, 0.5)
	DecRing.Position = UDim2.new(0.5, 0, 0.5, 0)
	DecRing.Size = UDim2.new(1, -36, 1, -36)
	DecRing.BackgroundTransparency = 1
	DecRing.Parent = CoreHolder
	Instance.new("UICorner", DecRing).CornerRadius = UDim.new(1, 0)

	local DecStroke = Instance.new("UIStroke", DecRing)
	DecStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	DecStroke.Color = Hallow.Theme.BorderDim
	DecStroke.Thickness = 1.5
	DecStroke.Transparency = 0.5

	-- Collapsed View
	local CollapsedView = Instance.new("Frame")
	CollapsedView.Name = "CollapsedView"
	CollapsedView.Size = UDim2.new(1, 0, 1, 0)
	CollapsedView.BackgroundTransparency = 1
	CollapsedView.Parent = CoreHolder

	local InnerCoreDeco = Instance.new("Frame")
	InnerCoreDeco.AnchorPoint = Vector2.new(0.5, 0.5)
	InnerCoreDeco.Position = UDim2.new(0.5, 0, 0.5, 0)
	InnerCoreDeco.Size = UDim2.new(0, 160, 0, 160)
	InnerCoreDeco.BackgroundColor3 = Hallow.Theme.InnerRing
	InnerCoreDeco.BorderSizePixel = 0
	InnerCoreDeco.Parent = CollapsedView
	Instance.new("UICorner", InnerCoreDeco).CornerRadius = UDim.new(1, 0)

	local CoreIcon = Instance.new("TextLabel")
	CoreIcon.Text = "🎃"
	CoreIcon.TextSize = 54
	CoreIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	CoreIcon.Position = UDim2.new(0.5, 0, 0.38, 0)
	CoreIcon.Size = UDim2.new(0, 60, 0, 60)
	CoreIcon.BackgroundTransparency = 1
	CoreIcon.Parent = CollapsedView

	local CoreTitle = Instance.new("TextLabel")
	CoreTitle.Text = string.upper(winTitle)
	CoreTitle.Font = Enum.Font.GothamBold
	CoreTitle.TextSize = 18
	CoreTitle.TextColor3 = Hallow.Theme.AmberGlow
	CoreTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	CoreTitle.Position = UDim2.new(0.5, 0, 0.72, 0)
	CoreTitle.Size = UDim2.new(1, 0, 0, 22)
	CoreTitle.BackgroundTransparency = 1
	CoreTitle.Parent = CollapsedView

	-- Expanded Portal View (680px Disc)
	local ExpandedView = Instance.new("Frame")
	ExpandedView.Name = "ExpandedView"
	ExpandedView.Size = UDim2.new(1, 0, 1, 0)
	ExpandedView.BackgroundTransparency = 1
	ExpandedView.Visible = false
	ExpandedView.Parent = CoreHolder

	local HeaderPill = Instance.new("Frame")
	HeaderPill.AnchorPoint = Vector2.new(0.5, 0)
	HeaderPill.Position = UDim2.new(0.5, 0, 0, 38)
	HeaderPill.Size = UDim2.new(0, 280, 0, 40)
	HeaderPill.BackgroundColor3 = Hallow.Theme.CardBg
	HeaderPill.BorderSizePixel = 0
	HeaderPill.Parent = ExpandedView
	Instance.new("UICorner", HeaderPill).CornerRadius = UDim.new(1, 0)

	local HeaderStroke = Instance.new("UIStroke", HeaderPill)
	HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	HeaderStroke.Color = Hallow.Theme.BorderDim
	HeaderStroke.Thickness = 1.4

	local PortalTitle = Instance.new("TextLabel")
	PortalTitle.Text = "🎃 OPTIONS"
	PortalTitle.Font = Enum.Font.GothamBold
	PortalTitle.TextSize = 16
	PortalTitle.TextColor3 = Hallow.Theme.AmberGlow
	PortalTitle.Size = UDim2.new(1, 0, 1, 0)
	PortalTitle.BackgroundTransparency = 1
	PortalTitle.Parent = HeaderPill

	local ReturnBtn = Instance.new("TextButton")
	ReturnBtn.Name = "ReturnBtn"
	ReturnBtn.AnchorPoint = Vector2.new(0.5, 1)
	ReturnBtn.Position = UDim2.new(0.5, 0, 1, -32)
	ReturnBtn.Size = UDim2.new(0, 180, 0, 40)
	ReturnBtn.BackgroundColor3 = Color3.fromRGB(36, 14, 5)
	ReturnBtn.Text = "◀ RETURN"
	ReturnBtn.Font = Enum.Font.GothamBold
	ReturnBtn.TextSize = 14
	ReturnBtn.TextColor3 = Hallow.Theme.Amber
	ReturnBtn.BorderSizePixel = 0
	ReturnBtn.AutoButtonColor = false
	ReturnBtn.Parent = ExpandedView
	Instance.new("UICorner", ReturnBtn).CornerRadius = UDim.new(1, 0)

	local ReturnStroke = Instance.new("UIStroke", ReturnBtn)
	ReturnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ReturnStroke.Color = Hallow.Theme.BorderDim
	ReturnStroke.Thickness = 1.4

	ReturnBtn.MouseEnter:Connect(function()
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(56, 20, 8) })
		tw(ReturnStroke, { Color = Hallow.Theme.AmberGlow, Thickness = 2 })
	end)
	ReturnBtn.MouseLeave:Connect(function()
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(36, 14, 5) })
		tw(ReturnStroke, { Color = Hallow.Theme.BorderDim, Thickness = 1.4 })
	end)

	-- Fade-Mask Container for options list
	local PagesMask = Instance.new("CanvasGroup")
	PagesMask.Name = "PagesMask"
	PagesMask.AnchorPoint = Vector2.new(0.5, 0.5)
	PagesMask.Position = UDim2.new(0.5, 0, 0.51, 0)
	PagesMask.Size = UDim2.new(0, 420, 0, 470)
	PagesMask.BackgroundTransparency = 1
	PagesMask.BorderSizePixel = 0
	PagesMask.GroupTransparency = 0
	PagesMask.Parent = ExpandedView

	local MaskGradient = Instance.new("UIGradient", PagesMask)
	MaskGradient.Name = "FadeMask"
	MaskGradient.Rotation = 90
	MaskGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.0),
		NumberSequenceKeypoint.new(0.08, 0.0),
		NumberSequenceKeypoint.new(0.92, 0.0),
		NumberSequenceKeypoint.new(1.00, 1.0),
	})

	-- Window Handler State
	local WindowHandler = {
		Tabs = {},
		Radius = 235,
		CurrentActive = nil,
		IsExpanded = false,
		IsMinimized = false,
		Started = false,
		InStartupAnim = false,
		PagesMask = PagesMask
	}

	-- Clean Helper: Resets any tab back to its idle, unhighlighted baseline!
	local function resetTabToIdle(tab)
		local isClose = (string.lower(tab.Title):find("close") ~= nil)

		tw(tab.Frame, {
			Size = UDim2.new(0, 130, 0, 130),
			BackgroundColor3 = Hallow.Theme.NodeBg
		}, 0.2)

		-- Turn off outer glowing stroke
		tw(tab.Stroke, {
			Transparency = 1,
			Color = isClose and Hallow.Theme.RedClose or Hallow.Theme.Amber
		}, 0.2)

		-- Reset inner bevel groove ring to subtle dark border!
		if tab.DecStroke then
			tw(tab.DecStroke, {
				Transparency = 0.5,
				Color = Hallow.Theme.BorderDim
			}, 0.2)
		end

		-- Reset inner beveled plate
		if tab.InnerPlate then
			tw(tab.InnerPlate, { BackgroundColor3 = Hallow.Theme.InnerRing }, 0.2)
		end

		-- Reset icon back to centered position & neutral color!
		if tab.Icon then
			tw(tab.Icon, {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				TextColor3 = isClose and Hallow.Theme.RedClose or Hallow.Theme.TextMuted
			}, 0.2)
		end

		-- Hide hover label completely
		if tab.Label then
			tw(tab.Label, {
				TextTransparency = 1,
				TextColor3 = isClose and Color3.fromRGB(255, 120, 120) or Hallow.Theme.TextPrimary
			}, 0.2)
		end
	end

	local function collapseToRadial()
		if not WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.InStartupAnim then return end
		WindowHandler.IsExpanded = false
		playSound(Hallow.Sounds.Click, 0.9)

		ExpandedView.Visible = false
		CollapsedView.Visible = true

		tw(CoreHolder, { Size = UDim2.new(0, 210, 0, 210) }, 0.4, Enum.EasingStyle.Back)

		-- Cleanly restore every single tab to unhighlighted baseline!
		for _, tab in ipairs(WindowHandler.Tabs) do
			if tab.Page then tab.Page.Visible = false end
			tab.Frame.Visible = true
			resetTabToIdle(tab)
		end
		WindowHandler.CurrentActive = nil
	end

	ReturnBtn.MouseButton1Click:Connect(collapseToRadial)

	function WindowHandler:Minimize()
		if WindowHandler.IsMinimized or WindowHandler.InStartupAnim then return end
		WindowHandler.IsMinimized = true
		playSound(Hallow.Sounds.Click, 0.85)

		tw(CoreHolder, { Size = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)

		for _, tab in ipairs(WindowHandler.Tabs) do
			tw(tab.Frame, { Size = UDim2.new(0, 0, 0, 0) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end

		task.delay(0.25, function()
			CoreHolder.Visible = false
			for _, tab in ipairs(WindowHandler.Tabs) do
				tab.Frame.Visible = false
			end
			MiniPumpkin.Visible = true
			tw(MiniPumpkin, { Position = UDim2.new(0.5, 0, 0.04, 0) }, 0.4, Enum.EasingStyle.Back)
		end)
	end

	function WindowHandler:Restore()
		if not WindowHandler.IsMinimized or WindowHandler.InStartupAnim then return end
		WindowHandler.IsMinimized = false
		playSound(Hallow.Sounds.Open, 1.1)

		local hideLogo = tw(MiniPumpkin, { Position = UDim2.new(0.5, 0, -0.12, 0) }, 0.25)
		hideLogo.Completed:Connect(function()
			MiniPumpkin.Visible = false
		end)

		WindowHandler.IsExpanded = false
		CollapsedView.Visible = true
		ExpandedView.Visible = false
		CoreHolder.Visible = true

		tw(CoreHolder, { Size = UDim2.new(0, 210, 0, 210) }, 0.45, Enum.EasingStyle.Back)

		for i, tab in ipairs(WindowHandler.Tabs) do
			tab.Frame.Visible = true
			local total = #WindowHandler.Tabs
			local angle = ((i - 1) * (2 * math.pi / total)) - (math.pi / 2)
			local targetX = math.cos(angle) * WindowHandler.Radius
			local targetY = math.sin(angle) * WindowHandler.Radius

			tab.Frame.Position = UDim2.new(0.5, targetX, 0.5, targetY)
			resetTabToIdle(tab)
		end
	end

	MiniPumpkin.MouseButton1Click:Connect(function()
		WindowHandler:Restore()
	end)

	function WindowHandler:Destroy()
		playSound(Hallow.Sounds.Click, 0.8, 0.9)
		ScreenGui:Destroy()
	end

	function WindowHandler:Notify(cfg)
		Hallow:Notify(cfg)
	end

	-- Node Base Generator
	local function createBaseNode(title, iconText, isCloseTab)
		local NodeFrame = Instance.new("Frame")
		NodeFrame.Name = title .. "_Node"
		NodeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		NodeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		NodeFrame.Size = UDim2.new(0, 0, 0, 0)
		NodeFrame.BackgroundColor3 = Hallow.Theme.NodeBg
		NodeFrame.BorderSizePixel = 0
		NodeFrame.Visible = false
		NodeFrame.Parent = BaseCenter
		Instance.new("UICorner", NodeFrame).CornerRadius = UDim.new(1, 0)

		local NodeStroke = Instance.new("UIStroke", NodeFrame)
		NodeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		NodeStroke.Thickness = 3.8
		NodeStroke.Color = isCloseTab and Hallow.Theme.RedClose or Hallow.Theme.Amber
		NodeStroke.Transparency = 1

		local NodeDecRing = Instance.new("Frame")
		NodeDecRing.Name = "BevelRing"
		NodeDecRing.AnchorPoint = Vector2.new(0.5, 0.5)
		NodeDecRing.Position = UDim2.new(0.5, 0, 0.5, 0)
		NodeDecRing.Size = UDim2.new(1, -18, 1, -18)
		NodeDecRing.BackgroundTransparency = 1
		NodeDecRing.Parent = NodeFrame
		Instance.new("UICorner", NodeDecRing).CornerRadius = UDim.new(1, 0)

		local NodeDecStroke = Instance.new("UIStroke", NodeDecRing)
		NodeDecStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		NodeDecStroke.Color = Hallow.Theme.BorderDim
		NodeDecStroke.Thickness = 1.2
		NodeDecStroke.Transparency = 0.5

		local InnerNodePlate = Instance.new("Frame")
		InnerNodePlate.Name = "InnerPlate"
		InnerNodePlate.AnchorPoint = Vector2.new(0.5, 0.5)
		InnerNodePlate.Position = UDim2.new(0.5, 0, 0.5, 0)
		InnerNodePlate.Size = UDim2.new(1, -30, 1, -30)
		InnerNodePlate.BackgroundColor3 = Hallow.Theme.InnerRing
		InnerNodePlate.BorderSizePixel = 0
		InnerNodePlate.Parent = NodeFrame
		Instance.new("UICorner", InnerNodePlate).CornerRadius = UDim.new(1, 0)

		local ClickBtn = Instance.new("TextButton")
		ClickBtn.Size = UDim2.new(1, 0, 1, 0)
		ClickBtn.BackgroundTransparency = 1
		ClickBtn.Text = ""
		ClickBtn.AutoButtonColor = false
		ClickBtn.Parent = NodeFrame

		local NodeIcon = Instance.new("TextLabel")
		NodeIcon.Text = iconText or "🎃"
		NodeIcon.Font = Enum.Font.GothamBold
		NodeIcon.TextSize = isCloseTab and 46 or 42
		NodeIcon.TextColor3 = isCloseTab and Hallow.Theme.RedClose or Hallow.Theme.TextMuted
		NodeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		NodeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		NodeIcon.Size = UDim2.new(0, 56, 0, 56)
		NodeIcon.BackgroundTransparency = 1
		NodeIcon.Parent = InnerNodePlate

		local NodeLabel = Instance.new("TextLabel")
		NodeLabel.Text = string.upper(title)
		NodeLabel.Font = Enum.Font.GothamBold
		NodeLabel.TextSize = 13
		NodeLabel.TextColor3 = isCloseTab and Color3.fromRGB(255, 120, 120) or Hallow.Theme.TextPrimary
		NodeLabel.AnchorPoint = Vector2.new(0.5, 1)
		NodeLabel.Position = UDim2.new(0.5, 0, 1, -12)
		NodeLabel.Size = UDim2.new(1, -10, 0, 18)
		NodeLabel.BackgroundTransparency = 1
		NodeLabel.TextTransparency = 1
		NodeLabel.Parent = InnerNodePlate

		ClickBtn.MouseEnter:Connect(function()
			playHoverSound(1.65, 0.4)
			if not WindowHandler.IsExpanded and not WindowHandler.IsMinimized and not WindowHandler.InStartupAnim then
				tw(NodeFrame, { Size = UDim2.new(0, 146, 0, 146), BackgroundColor3 = Hallow.Theme.NodeHover }, 0.18)
				tw(InnerNodePlate, { BackgroundColor3 = Color3.fromRGB(44, 18, 6) }, 0.18)
				tw(NodeStroke, {
					Transparency = 0,
					Color = isCloseTab and Hallow.Theme.RedCloseGlow or Hallow.Theme.AmberGlow
				}, 0.18)
				tw(NodeDecStroke, { Transparency = 0.2, Color = Hallow.Theme.AmberDark }, 0.18)
				tw(NodeIcon, {
					Position = UDim2.new(0.5, 0, 0.38, 0),
					TextColor3 = isCloseTab and Hallow.Theme.RedCloseGlow or Hallow.Theme.AmberGlow
				}, 0.18)
				tw(NodeLabel, { TextTransparency = 0 }, 0.18)
			end
		end)

		ClickBtn.MouseLeave:Connect(function()
			if not WindowHandler.IsExpanded and not WindowHandler.IsMinimized and not WindowHandler.InStartupAnim then
				tw(NodeFrame, { Size = UDim2.new(0, 130, 0, 130), BackgroundColor3 = Hallow.Theme.NodeBg }, 0.18)
				tw(InnerNodePlate, { BackgroundColor3 = Hallow.Theme.InnerRing }, 0.18)
				tw(NodeStroke, { Transparency = 1 }, 0.18)
				tw(NodeDecStroke, { Transparency = 0.5, Color = Hallow.Theme.BorderDim }, 0.18)
				tw(NodeIcon, {
					Position = UDim2.new(0.5, 0, 0.5, 0),
					TextColor3 = isCloseTab and Hallow.Theme.RedClose or Hallow.Theme.TextMuted
				}, 0.18)
				tw(NodeLabel, { TextTransparency = 1 }, 0.18)
			end
		end)

		return NodeFrame, ClickBtn, NodeStroke, NodeIcon, NodeLabel, InnerNodePlate, NodeDecStroke
	end

	function WindowHandler:RealignNodes()
		local total = #self.Tabs
		if total == 0 then return end

		for i, tab in ipairs(self.Tabs) do
			local angle = ((i - 1) * (2 * math.pi / total)) - (math.pi / 2)
			local targetX = math.cos(angle) * self.Radius
			local targetY = math.sin(angle) * self.Radius

			if self.Started and not self.InStartupAnim then
				tw(tab.Frame, { Position = UDim2.new(0.5, targetX, 0.5, targetY) }, 0.45, Enum.EasingStyle.Back)
			else
				tab.Frame.Position = UDim2.new(0.5, targetX, 0.5, targetY)
			end
		end
	end

	-- ===================================================================
	--   ✨ SYNCHRONIZED SHRINK + ACCELERATED ORBITAL REVOLUTION ANIMATION
	-- ===================================================================
	task.defer(function()
		task.wait(0.35)
		WindowHandler.InStartupAnim = true

		playSound(Hallow.Sounds.Open, 0.9, 1.0)
		task.wait(0.4)

		local total = #WindowHandler.Tabs
		local animDuration = 1.3
		local fullRotations = math.pi * 2.8
		local startRadius = 70
		local endRadius = WindowHandler.Radius

		for _, tab in ipairs(WindowHandler.Tabs) do
			tab.Frame.Size = UDim2.new(0, 24, 0, 24)
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, -startRadius)
			tab.Frame.Visible = true
			tab.Stroke.Transparency = 0
			tab.Icon.TextTransparency = 1
			tab.Label.TextTransparency = 1
		end

		local startTime = tick()
		local renderConn

		renderConn = RunService.RenderStepped:Connect(function()
			local now = tick()
			local p = math.clamp((now - startTime) / animDuration, 0, 1)

			local coreEase = TweenService:GetValue(p, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local currentCoreSize = 380 - ((380 - 210) * coreEase)
			CoreHolder.Size = UDim2.new(0, currentCoreSize, 0, currentCoreSize)

			local spinProgress = (1 - p) ^ 1.85
			local radialEase = TweenService:GetValue(p, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local currentRadius = startRadius + ((endRadius - startRadius) * radialEase)
			local currentTabSize = 24 + ((130 - 24) * radialEase)

			for i, tab in ipairs(WindowHandler.Tabs) do
				local finalAngle = ((i - 1) * (2 * math.pi / total)) - (math.pi / 2)
				local currentAngle = finalAngle - (spinProgress * fullRotations)

				local targetX = math.cos(currentAngle) * currentRadius
				local targetY = math.sin(currentAngle) * currentRadius

				tab.Frame.Position = UDim2.new(0.5, targetX, 0.5, targetY)
				tab.Frame.Size = UDim2.new(0, currentTabSize, 0, currentTabSize)
				tab.Icon.TextTransparency = 1 - math.clamp(p * 1.5, 0, 1)
			end

			if p >= 1 then
				renderConn:Disconnect()

				playSound(Hallow.Sounds.Notify, 1.4, 1.0) -- Ding!

				for _, tab in ipairs(WindowHandler.Tabs) do
					tab.Stroke.Thickness = 4.8
				end

				task.wait(0.18)

				for _, tab in ipairs(WindowHandler.Tabs) do
					resetTabToIdle(tab)
				end

				WindowHandler.InStartupAnim = false
				WindowHandler.Started = true
			end
		end)
	end)

	function WindowHandler:CreateActionNode(tabName, icon, callback)
		local isClose = (string.lower(tabName):find("close") ~= nil)
		local NodeFrame, ClickBtn, NodeStroke, NodeIcon, NodeLabel, InnerNodePlate, NodeDecStroke = createBaseNode(tabName, icon, isClose)

		local tabData = {
			Frame = NodeFrame,
			ClickBtn = ClickBtn,
			Icon = NodeIcon,
			Label = NodeLabel,
			Stroke = NodeStroke,
			DecStroke = NodeDecStroke,
			InnerPlate = InnerNodePlate,
			Title = tabName
		}
		table.insert(self.Tabs, tabData)
		self:RealignNodes()

		ClickBtn.MouseButton1Click:Connect(function()
			if self.IsExpanded or self.IsMinimized or self.InStartupAnim then return end
			playSound(Hallow.Sounds.Click, 1.1, 0.95)
			tw(NodeFrame, { BackgroundColor3 = Hallow.Theme.NodeActive, Size = UDim2.new(0, 138, 0, 138) }, 0.1)
			task.delay(0.12, function()
				resetTabToIdle(tabData)
			end)
			task.spawn(callback or function() end)
		end)
	end

	function WindowHandler:CreateTab(tabName, icon)
		local NodeFrame, ClickBtn, NodeStroke, NodeIcon, NodeLabel, InnerNodePlate, NodeDecStroke = createBaseNode(tabName, icon, false)

		local Page = Instance.new("ScrollingFrame")
		Page.Name = tabName .. "_Page"
		Page.AnchorPoint = Vector2.new(0.5, 0.5)
		Page.Position = UDim2.new(0.5, 0, 0.5, 0)
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = Hallow.Theme.Amber
		Page.ScrollBarImageTransparency = 0.5
		Page.Visible = false
		Page.Parent = PagesMask

		local PageLayout = Instance.new("UIListLayout", Page)
		PageLayout.Padding = UDim.new(0, 10)

		local PagePadding = Instance.new("UIPadding", Page)
		PagePadding.PaddingTop = UDim.new(0, 16)
		PagePadding.PaddingBottom = UDim.new(0, 36)

		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 52)
		end)

		local tabData = {
			Frame = NodeFrame,
			ClickBtn = ClickBtn,
			Icon = NodeIcon,
			Label = NodeLabel,
			Stroke = NodeStroke,
			DecStroke = NodeDecStroke,
			InnerPlate = InnerNodePlate,
			Page = Page,
			Title = tabName
		}
		table.insert(self.Tabs, tabData)
		self:RealignNodes()

		ClickBtn.MouseButton1Click:Connect(function()
			if WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.InStartupAnim then return end
			WindowHandler.IsExpanded = true
			WindowHandler.CurrentActive = tabData

			playSound(Hallow.Sounds.Open, 1.15, 0.95)

			-- Instantly clean and hide all tabs
			for _, tab in ipairs(WindowHandler.Tabs) do
				if tab.Page then tab.Page.Visible = false end
				resetTabToIdle(tab)
				tw(tab.Frame, { Size = UDim2.new(0, 0, 0, 0) }, 0.25).Completed:Connect(function()
					tab.Frame.Visible = false
				end)
			end

			Page.CanvasPosition = Vector2.zero
			CollapsedView.Visible = false
			ExpandedView.Visible = true
			PortalTitle.Text = (icon or "🎃") .. " " .. string.upper(tabName)
			Page.Visible = true

			tw(CoreHolder, { Size = UDim2.new(0, 680, 0, 680) }, 0.45, Enum.EasingStyle.Back)
		end)

		local TabElements = {}

		local function makeCapsule(h)
			local Card = Instance.new("Frame")
			Card.Size = UDim2.new(1, -12, 0, h or 58)
			Card.BackgroundColor3 = Hallow.Theme.CardBg
			Card.BackgroundTransparency = 0.1
			Card.BorderSizePixel = 0
			Card.Parent = Page
			Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 16)

			local stroke = Instance.new("UIStroke", Card)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Hallow.Theme.BorderDim
			stroke.Thickness = 1.4

			local Pip = Instance.new("Frame")
			Pip.Size = UDim2.new(0, 5, 0, 22)
			Pip.Position = UDim2.new(0, 6, 0.5, -11)
			Pip.BackgroundColor3 = Hallow.Theme.AmberDark
			Pip.BorderSizePixel = 0
			Pip.Parent = Card
			Instance.new("UICorner", Pip).CornerRadius = UDim.new(1, 0)

			Card.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.6)
				tw(stroke, { Color = Hallow.Theme.Amber })
				tw(Card, { BackgroundColor3 = Hallow.Theme.CardHover })
				tw(Pip, { BackgroundColor3 = Hallow.Theme.AmberGlow, Size = UDim2.new(0, 5, 0, 30), Position = UDim2.new(0, 6, 0.5, -15) })
			end)
			Card.MouseLeave:Connect(function()
				tw(stroke, { Color = Hallow.Theme.BorderDim })
				tw(Card, { BackgroundColor3 = Hallow.Theme.CardBg })
				tw(Pip, { BackgroundColor3 = Hallow.Theme.AmberDark, Size = UDim2.new(0, 5, 0, 22), Position = UDim2.new(0, 6, 0.5, -11) })
			end)

			return Card, stroke, Pip
		end

		function TabElements:CreateSection(secName)
			local sec = Instance.new("Frame")
			sec.Size = UDim2.new(1, -12, 0, 36)
			sec.BackgroundTransparency = 1
			sec.Parent = Page

			local sLbl = Instance.new("TextLabel")
			sLbl.Text = string.upper(secName)
			sLbl.Font = Enum.Font.GothamBold
			sLbl.TextSize = 13
			sLbl.TextColor3 = Hallow.Theme.AmberGlow
			sLbl.TextXAlignment = Enum.TextXAlignment.Left
			sLbl.Position = UDim2.new(0, 8, 0, 10)
			sLbl.Size = UDim2.new(1, -16, 0, 20)
			sLbl.BackgroundTransparency = 1
			sLbl.Parent = sec

			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, -16, 0, 1)
			line.Position = UDim2.new(0, 8, 1, -2)
			line.BackgroundColor3 = Hallow.Theme.BorderDim
			line.BorderSizePixel = 0
			line.Parent = sec
		end

		function TabElements:CreateButton(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Button"
			local desc = opts.Description or opts.Desc or ""
			local callback = opts.Callback or function() end

			local hasDesc = (desc ~= "")
			local Card = makeCapsule(hasDesc and 68 or 54)

			local ClickArea = Instance.new("TextButton")
			ClickArea.Size = UDim2.new(1, 0, 1, 0)
			ClickArea.BackgroundTransparency = 1
			ClickArea.Text = ""
			ClickArea.Parent = Card

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.TextPrimary
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, hasDesc and 11 or 17)
			t.Size = UDim2.new(1, -64, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			if hasDesc then
				local d = Instance.new("TextLabel")
				d.Text = desc
				d.Font = Enum.Font.Gotham
				d.TextSize = 12
				d.TextColor3 = Hallow.Theme.TextMuted
				d.TextXAlignment = Enum.TextXAlignment.Left
				d.Position = UDim2.new(0, 18, 0, 35)
				d.Size = UDim2.new(1, -64, 0, 18)
				d.BackgroundTransparency = 1
				d.Parent = Card
			end

			local icon = Instance.new("TextLabel")
			icon.Text = "🎃"
			icon.TextSize = 20
			icon.Position = UDim2.new(1, -40, 0.5, -12)
			icon.Size = UDim2.new(0, 24, 0, 24)
			icon.BackgroundTransparency = 1
			icon.Parent = Card

			ClickArea.MouseButton1Click:Connect(function()
				playSound(Hallow.Sounds.Click, 1.0, 0.95)
				local flash = tw(Card, { BackgroundColor3 = Color3.fromRGB(72, 28, 9) }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				flash.Completed:Connect(function()
					tw(Card, { BackgroundColor3 = Hallow.Theme.CardBg }, 0.15)
				end)
				task.spawn(callback)
			end)
		end
		TabElements.AddButton = TabElements.CreateButton

		function TabElements:CreateToggle(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Toggle"
			local desc = opts.Description or opts.Desc or ""
			local state = opts.Default or false
			local callback = opts.Callback or function() end

			local hasDesc = (desc ~= "")
			local Card, stroke, pip = makeCapsule(hasDesc and 68 or 56)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.TextPrimary
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, hasDesc and 11 or 0)
			t.Size = UDim2.new(1, -86, hasDesc and 0 or 1, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			if hasDesc then
				local d = Instance.new("TextLabel")
				d.Text = desc
				d.Font = Enum.Font.Gotham
				d.TextSize = 12
				d.TextColor3 = Hallow.Theme.TextMuted
				d.TextXAlignment = Enum.TextXAlignment.Left
				d.Position = UDim2.new(0, 18, 0, 35)
				d.Size = UDim2.new(1, -86, 0, 18)
				d.BackgroundTransparency = 1
				d.Parent = Card
			end

			local Switch = Instance.new("TextButton")
			Switch.Size = UDim2.new(0, 56, 0, 28)
			Switch.Position = UDim2.new(1, -68, 0.5, -14)
			Switch.BackgroundColor3 = state and Hallow.Theme.Amber or Color3.fromRGB(42, 17, 6)
			Switch.BorderSizePixel = 0
			Switch.AutoButtonColor = false
			Switch.Text = ""
			Switch.Parent = Card
			Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

			local Thumb = Instance.new("Frame")
			Thumb.Size = UDim2.new(0, 20, 0, 20)
			Thumb.Position = state and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
			Thumb.BackgroundColor3 = Color3.fromRGB(255, 245, 230)
			Thumb.BorderSizePixel = 0
			Thumb.Parent = Switch
			Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

			if state then pip.BackgroundColor3 = Hallow.Theme.AmberGlow end

			Switch.MouseButton1Click:Connect(function()
				state = not state
				playSound(Hallow.Sounds.Toggle, state and 1.3 or 0.85, 0.95)
				if state then
					tw(Switch, { BackgroundColor3 = Hallow.Theme.Amber })
					tw(Thumb, { Position = UDim2.new(1, -24, 0.5, -10) }, 0.2, Enum.EasingStyle.Back)
					tw(pip, { BackgroundColor3 = Hallow.Theme.AmberGlow })
				else
					tw(Switch, { BackgroundColor3 = Color3.fromRGB(42, 17, 6) })
					tw(Thumb, { Position = UDim2.new(0, 4, 0.5, -10) }, 0.2)
					tw(pip, { BackgroundColor3 = Hallow.Theme.AmberDark })
				end
				task.spawn(callback, state)
			end)
		end
		TabElements.AddToggle = TabElements.CreateToggle

		function TabElements:CreateSlider(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Slider"
			local min = tonumber(opts.Min) or 0
			local max = tonumber(opts.Max) or 100
			local step = tonumber(opts.Increment or opts.Step) or 1
			local def = tonumber(opts.Default) or min
			def = math.clamp(def, min, max)
			local callback = opts.Callback or function() end

			local decimals = 0
			if step < 1 then
				local s = tostring(step)
				local dot = s:find("%.")
				decimals = dot and (#s - dot) or 1
			end

			local function formatVal(v)
				if decimals > 0 then
					return string.format("%." .. decimals .. "f", v)
				else
					return tostring(math.floor(v + 0.5))
				end
			end

			local Card, stroke, pip = makeCapsule(70)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.TextPrimary
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, 9)
			t.Size = UDim2.new(1, -78, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local valLbl = Instance.new("TextLabel")
			valLbl.Text = formatVal(def)
			valLbl.Font = Enum.Font.GothamBold
			valLbl.TextSize = 15
			valLbl.TextColor3 = Hallow.Theme.AmberGlow
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.Position = UDim2.new(1, -60, 0, 9)
			valLbl.Size = UDim2.new(0, 42, 0, 18)
			valLbl.BackgroundTransparency = 1
			valLbl.Parent = Card

			local Track = Instance.new("TextButton")
			Track.Size = UDim2.new(1, -36, 0, 7)
			Track.Position = UDim2.new(0, 18, 0, 44)
			Track.BackgroundColor3 = Color3.fromRGB(45, 18, 6)
			Track.BorderSizePixel = 0
			Track.Text = ""
			Track.AutoButtonColor = false
			Track.Parent = Card
			Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

			local Fill = Instance.new("Frame")
			local startPercent = math.clamp((def - min) / math.max(0.0001, (max - min)), 0, 1)
			Fill.Size = UDim2.new(startPercent, 0, 1, 0)
			Fill.BackgroundColor3 = Hallow.Theme.Amber
			Fill.BorderSizePixel = 0
			Fill.Parent = Track
			Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

			local sliding = false
			local function updateFromInput(input)
				local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local rawVal = min + ((max - min) * pos)
				local steppedVal = math.floor((rawVal / step) + 0.5) * step
				local clampedVal = math.clamp(steppedVal, min, max)

				local strVal = formatVal(clampedVal)
				valLbl.Text = strVal

				local visualPos = math.clamp((clampedVal - min) / math.max(0.0001, (max - min)), 0, 1)
				tw(Fill, { Size = UDim2.new(visualPos, 0, 1, 0) }, 0.04)
				task.spawn(callback, tonumber(strVal) or clampedVal)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					playSound(Hallow.Sounds.Click, 1.4, 0.8)
					updateFromInput(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end)
		end
		TabElements.AddSlider = TabElements.CreateSlider

		function TabElements:CreateDropdown(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Dropdown"
			local items = opts.Options or {}
			local selected = opts.Default or (items[1] or "Select...")
			local callback = opts.Callback or function() end

			local expanded = false
			local itemHeight = 36
			local collapsedHeight = 54

			local Card, stroke = makeCapsule(collapsedHeight)
			Card.ClipsDescendants = true

			local HeaderBtn = Instance.new("TextButton")
			HeaderBtn.Size = UDim2.new(1, 0, 0, collapsedHeight)
			HeaderBtn.BackgroundTransparency = 1
			HeaderBtn.Text = ""
			HeaderBtn.Parent = Card

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.TextPrimary
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, 17)
			t.Size = UDim2.new(0.5, 0, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local curLbl = Instance.new("TextLabel")
			curLbl.Text = tostring(selected)
			curLbl.Font = Enum.Font.Gotham
			curLbl.TextSize = 13
			curLbl.TextColor3 = Hallow.Theme.AmberGlow
			curLbl.TextXAlignment = Enum.TextXAlignment.Right
			curLbl.Position = UDim2.new(1, -75, 0, 17)
			curLbl.Size = UDim2.new(0, 44, 0, 18)
			curLbl.BackgroundTransparency = 1
			curLbl.Parent = Card

			local Arrow = Instance.new("TextLabel")
			Arrow.Text = "▼"
			Arrow.Font = Enum.Font.GothamBold
			Arrow.TextSize = 12
			Arrow.TextColor3 = Hallow.Theme.TextMuted
			Arrow.Position = UDim2.new(1, -28, 0, 17)
			Arrow.Size = UDim2.new(0, 16, 0, 18)
			Arrow.BackgroundTransparency = 1
			Arrow.Parent = Card

			local ListHolder = Instance.new("Frame")
			ListHolder.Size = UDim2.new(1, -24, 0, #items * itemHeight)
			ListHolder.Position = UDim2.new(0, 12, 0, collapsedHeight + 4)
			ListHolder.BackgroundTransparency = 1
			ListHolder.Parent = Card

			local lLayout = Instance.new("UIListLayout", ListHolder)
			lLayout.Padding = UDim.new(0, 4)

			for _, item in ipairs(items) do
				local itmBtn = Instance.new("TextButton")
				itmBtn.Size = UDim2.new(1, 0, 0, itemHeight)
				itmBtn.BackgroundColor3 = Color3.fromRGB(36, 14, 5)
				itmBtn.BorderSizePixel = 0
				itmBtn.Font = Enum.Font.Gotham
				itmBtn.TextSize = 13
				itmBtn.TextColor3 = Hallow.Theme.TextPrimary
				itmBtn.Text = "   " .. tostring(item)
				itmBtn.TextXAlignment = Enum.TextXAlignment.Left
				itmBtn.AutoButtonColor = false
				itmBtn.Parent = ListHolder
				Instance.new("UICorner", itmBtn).CornerRadius = UDim.new(0, 8)

				itmBtn.MouseEnter:Connect(function()
					playHoverSound(1.85, 0.5)
					tw(itmBtn, { BackgroundColor3 = Hallow.Theme.CardHover })
				end)
				itmBtn.MouseLeave:Connect(function()
					tw(itmBtn, { BackgroundColor3 = Color3.fromRGB(36, 14, 5) })
				end)

				itmBtn.MouseButton1Click:Connect(function()
					selected = item
					curLbl.Text = tostring(item)
					playSound(Hallow.Sounds.Click, 1.2, 0.9)
					expanded = false
					tw(Arrow, { Rotation = 0 }, 0.2)
					tw(Card, { Size = UDim2.new(1, -12, 0, collapsedHeight) }, 0.25)
					task.spawn(callback, selected)
				end)
			end

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Hallow.Sounds.Click, 1.0, 0.9)
				local targetH = expanded and (collapsedHeight + (#items * itemHeight) + 14) or collapsedHeight
				tw(Arrow, { Rotation = expanded and 180 or 0 }, 0.25)
				tw(Card, { Size = UDim2.new(1, -12, 0, targetH) }, 0.3)
			end)
		end

		function TabElements:CreateKeybind(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Keybind"
			local currentKey = opts.Default or Enum.KeyCode.None
			local callback = opts.Callback or function() end

			local Card = makeCapsule(54)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.TextPrimary
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, 17)
			t.Size = UDim2.new(0.6, 0, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local KeyBtn = Instance.new("TextButton")
			KeyBtn.Size = UDim2.new(0, 85, 0, 30)
			KeyBtn.Position = UDim2.new(1, -98, 0.5, -15)
			KeyBtn.BackgroundColor3 = Color3.fromRGB(42, 17, 6)
			KeyBtn.BorderSizePixel = 0
			KeyBtn.Font = Enum.Font.GothamBold
			KeyBtn.TextSize = 13
			KeyBtn.TextColor3 = Hallow.Theme.AmberGlow
			KeyBtn.Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name
			KeyBtn.Parent = Card
			Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 8)

			local listening = false
			KeyBtn.MouseButton1Click:Connect(function()
				listening = true
				KeyBtn.Text = "..."
				playSound(Hallow.Sounds.Click, 1.25, 0.9)
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					listening = false
					currentKey = input.KeyCode
					KeyBtn.Text = currentKey.Name
					playSound(Hallow.Sounds.Click, 0.95, 0.95)
					task.spawn(callback, currentKey)
				elseif not gpe and input.KeyCode == currentKey and currentKey ~= Enum.KeyCode.None then
					task.spawn(callback, currentKey)
				end
			end)
		end

		function TabElements:CreateParagraph(opts)
			opts = opts or {}
			local title = opts.Title or "Information"
			local content = opts.Content or ""

			local Card = makeCapsule(80)

			local t = Instance.new("TextLabel")
			t.Text = title
			t.Font = Enum.Font.GothamBold
			t.TextSize = 15
			t.TextColor3 = Hallow.Theme.AmberGlow
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 18, 0, 12)
			t.Size = UDim2.new(1, -36, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local c = Instance.new("TextLabel")
			c.Text = content
			c.Font = Enum.Font.Gotham
			c.TextSize = 13
			c.TextColor3 = Hallow.Theme.TextMuted
			c.TextXAlignment = Enum.TextXAlignment.Left
			c.TextWrapped = true
			c.Position = UDim2.new(0, 18, 0, 36)
			c.Size = UDim2.new(1, -36, 0, 36)
			c.BackgroundTransparency = 1
			c.Parent = Card
		end

		return TabElements
	end

	return WindowHandler
end

return Hallow
