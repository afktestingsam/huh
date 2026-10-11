local Library = {}

function Library:CreateWindow()
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local Lighting = game:GetService("Lighting")
	local CoreGui = game:GetService("CoreGui")
	local Player = Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")
	
	local ACCENT = Color3.fromRGB(62,215,98)
	local WHITE = Color3.new(1,1,1)

	-- ==========================================
	-- SISTEMA DE DATOS Y SESIÓN
	-- ==========================================
	local WHITELIST = {
		["jerehzxs"]  = "OWNER", ["cloudd7qo"] = "TESTER",
		["jerehvo"]   = "MEMBER", ["b92b08a"]   = "MEMBER", ["astrixrsz"] = "MEMBER",
	}
	local function isWhitelisted(n) if not n then return false end return WHITELIST[n:lower()] ~= nil end

	local function HasSession()
		local ok, c = pcall(function() if readfile then return readfile("wb_session.txt") end end)
		if not ok or not c then return false end
		local t = tonumber(c)
		if not t then return false end
		return (os.time() - t) < 86400
	end
	local function SaveSession() pcall(function() if writefile then writefile("wb_session.txt", tostring(os.time())) end end) end

	local function LoadUsage()
		local ok, data = pcall(function() if readfile then return readfile("wb_usage.json") end end)
		if ok and data then
			local ok2, tbl = pcall(function() return HttpService:JSONDecode(data) end)
			if ok2 and type(tbl)=="table" then return tbl end
		end
		return {}
	end
	local function SaveUsage(tbl) pcall(function() if writefile then writefile("wb_usage.json", HttpService:JSONEncode(tbl)) end end) end

	local ToggleUsage = LoadUsage()
	local AllToggles = {}
	local ToggleRegistry = {}

	local OldGUI = PlayerGui:FindFirstChild("WelcomeBackUI")
	if OldGUI then OldGUI:Destroy() end
	local OldCoreGUI = CoreGui:FindFirstChild("WelcomeBackUI")
	if OldCoreGUI then OldCoreGUI:Destroy() end

	-- ==========================================
	-- CREACIÓN DE INTERFAZ BASE
	-- ==========================================
	local GUI = Instance.new("ScreenGui")
	GUI.Name = "WelcomeBackUI"
	GUI.ResetOnSpawn = false
	GUI.IgnoreGuiInset = true
	GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	GUI.DisplayOrder = 999
	
	-- Intenta ponerlo en CoreGui para que no se borre, si falla va a PlayerGui
	local successCore = pcall(function() GUI.Parent = CoreGui end)
	if not successCore then GUI.Parent = PlayerGui end

	local ExclusiveGroups = {}
	local function RegisterExclusive(groupId, toggleName)
		if not ExclusiveGroups[groupId] then ExclusiveGroups[groupId] = { toggles = {}, activeName = nil } end
		table.insert(ExclusiveGroups[groupId].toggles, toggleName)
	end
	local function CanActivate(toggleName)
		for _, g in pairs(ExclusiveGroups) do
			for _, n in ipairs(g.toggles) do
				if n == toggleName then
					if g.activeName and g.activeName ~= toggleName then return false, g.activeName end
					return true
				end
			end
		end
		return true
	end
	local function SetExclusiveActive(toggleName)
		for _, g in pairs(ExclusiveGroups) do
			for _, n in ipairs(g.toggles) do if n == toggleName then g.activeName = toggleName return end end
		end
	end
	local function ClearExclusiveActive(toggleName)
		for _, g in pairs(ExclusiveGroups) do if g.activeName == toggleName then g.activeName = nil end end
	end

	local function ShowNotif(title, text, dur)
		dur = dur or 3
		local n = Instance.new("Frame")
		n.Size = UDim2.fromOffset(300, 62); n.Position = UDim2.new(0.5, -150, 0, -80)
		n.BackgroundColor3 = Color3.fromRGB(20, 20, 26); n.BorderSizePixel = 0; n.ZIndex = 100; n.Parent = GUI
		Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
		local s = Instance.new("UIStroke", n); s.Color = ACCENT; s.Thickness = 1.5
		
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -20, 0, 20); t.Position = UDim2.new(0, 10, 0, 6); t.BackgroundTransparency = 1
		t.Text = title; t.TextColor3 = ACCENT; t.TextSize = 13; t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = n
		
		local b = Instance.new("TextLabel")
		b.Size = UDim2.new(1, -20, 0, 28); b.Position = UDim2.new(0, 10, 0, 26); b.BackgroundTransparency = 1
		b.Text = text; b.TextColor3 = Color3.fromRGB(200, 200, 208); b.TextSize = 11; b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; b.TextWrapped = true; b.Parent = n
		
		TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, 20)}):Play()
		task.delay(dur, function()
			local tw = TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, -80)})
			tw:Play()
			tw.Completed:Connect(function() n:Destroy() end)
		end)
	end

	local function AddButtonSweep(btn, stroke)
		if not btn or btn:FindFirstChild("SweepHolder") then return end
		if stroke then stroke.Color = WHITE stroke.Thickness = 1 stroke.Transparency = 0.82 stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end
		local sh = Instance.new("Frame")
		sh.Name = "SweepHolder"; sh.Size = UDim2.new(1,0,1,0); sh.BackgroundTransparency = 1; sh.ClipsDescendants = true; sh.ZIndex = 5; sh.Parent = btn
		Instance.new("UICorner", sh).CornerRadius = UDim.new(0,10)
		local sw = Instance.new("Frame")
		sw.Size = UDim2.new(0, 40, 1, 0); sw.Position = UDim2.new(0, -40, 0, 0); sw.BackgroundColor3 = WHITE; sw.BackgroundTransparency = 0.94; sw.BorderSizePixel = 0; sw.ZIndex = 6; sw.Parent = sh
		local g = Instance.new("UIGradient", sw)
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)})
		local sweeping = false
		btn.MouseEnter:Connect(function()
			if stroke then TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play() end
			if sweeping then return end
			sweeping = true; sw.Position = UDim2.new(0, -40, 0, 0)
			local tw = TweenService:Create(sw, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0, 0, 0)})
			tw:Play()
			tw.Completed:Connect(function() sweeping = false end)
		end)
		btn.MouseLeave:Connect(function()
			if stroke then TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.82}):Play() end
		end)
	end

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.AnchorPoint = Vector2.new(0.5,0.5); Main.Position = UDim2.fromScale(0.5,0.5)
	Main.Size = UDim2.new(0,480,0,300); Main.BackgroundColor3 = Color3.fromRGB(10,10,14)
	Main.BorderSizePixel = 0; Main.ClipsDescendants = true; Main.Parent = GUI
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
	local MainStroke = Instance.new("UIStroke", Main)
	MainStroke.Color = Color3.fromRGB(42,42,47); MainStroke.Thickness = 1; MainStroke.Transparency = 0.15

	-- ==========================================
	-- TOP BAR Y ARRASTRE (DRAGGING)
	-- ==========================================
	local Top = Instance.new("Frame")
	Top.Name = "Top"; Top.Size = UDim2.new(1,0,0,46); Top.BackgroundTransparency = 1; Top.Active = true; Top.Parent = Main
	local TopLine = Instance.new("Frame")
	TopLine.Size = UDim2.new(1,0,0,1); TopLine.Position = UDim2.new(0,0,1,-1); TopLine.BackgroundColor3 = Color3.fromRGB(43,43,48); TopLine.BorderSizePixel = 0; TopLine.Parent = Top

	-- DRAGGING LOGIC
	local dragging, dragInput, dragStart, startPos
	Top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Top.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local function MakeMacButton(color, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(14,14); b.Position = UDim2.new(0,x,0,15); b.BackgroundColor3 = color
		b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Parent = Top
		Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
		local s = Instance.new("UIStroke", b); s.Color = WHITE; s.Transparency = 0.72
		return b
	end
	local CloseButton = MakeMacButton(Color3.fromRGB(245,67,67), 16)
	local MinimizeButton = MakeMacButton(Color3.fromRGB(246,190,45), 38)
	local MaximizeButton = MakeMacButton(Color3.fromRGB(47,195,87), 60)

	local TitleGroup = Instance.new("Frame")
	TitleGroup.AnchorPoint = Vector2.new(0.5,0.5); TitleGroup.Position = UDim2.new(0.5,0,0,23)
	TitleGroup.Size = UDim2.new(0,140,0,30); TitleGroup.BackgroundTransparency = 1; TitleGroup.Parent = Top
	local TopIcon = Instance.new("ImageLabel")
	TopIcon.Size = UDim2.fromOffset(28,28); TopIcon.Position = UDim2.new(0,0,0.5,-14)
	TopIcon.BackgroundTransparency = 1; TopIcon.Image = "rbxassetid://119972597178070"; TopIcon.Parent = TitleGroup
	local TopTitle = Instance.new("TextLabel")
	TopTitle.Size = UDim2.new(1,-34,1,0); TopTitle.Position = UDim2.new(0,34,0,0); TopTitle.BackgroundTransparency = 1
	TopTitle.Text = "Panel"; TopTitle.TextXAlignment = Enum.TextXAlignment.Left
	TopTitle.TextColor3 = Color3.fromRGB(225,225,232); TopTitle.TextSize = 16; TopTitle.Font = Enum.Font.GothamBold; TopTitle.Parent = TitleGroup

	local Notification = Instance.new("TextButton")
	Notification.Size = UDim2.fromOffset(30,30); Notification.Position = UDim2.new(1,-46,0,9)
	Notification.BackgroundColor3 = Color3.fromRGB(24,24,30); Notification.Text = ""; Notification.AutoButtonColor = false; Notification.Parent = Top
	Instance.new("UICorner", Notification).CornerRadius = UDim.new(1,0)
	local NS = Instance.new("UIStroke", Notification); NS.Color = Color3.fromRGB(52,52,60)
	local NotifIcon = Instance.new("ImageLabel")
	NotifIcon.Size = UDim2.new(1,-12,1,-12); NotifIcon.Position = UDim2.new(0,6,0,6)
	NotifIcon.BackgroundTransparency = 1; NotifIcon.Image = "rbxassetid://133824150122272"; NotifIcon.Parent = Notification
	local NotificationDot = Instance.new("Frame")
	NotificationDot.Size = UDim2.fromOffset(14,14); NotificationDot.Position = UDim2.new(1,-9,0,-3)
	NotificationDot.BackgroundColor3 = Color3.fromRGB(255,60,60); NotificationDot.BorderSizePixel = 0; NotificationDot.ZIndex = 5; NotificationDot.Parent = Notification
	Instance.new("UICorner", NotificationDot).CornerRadius = UDim.new(1,0)
	local NDS = Instance.new("UIStroke", NotificationDot); NDS.Color = Color3.fromRGB(10,10,14); NDS.Thickness = 2
	local NotifBadge = Instance.new("TextLabel")
	NotifBadge.Size = UDim2.new(1,0,1,0); NotifBadge.BackgroundTransparency = 1; NotifBadge.Text = "1"
	NotifBadge.TextColor3 = WHITE; NotifBadge.TextSize = 9; NotifBadge.Font = Enum.Font.GothamBold; NotifBadge.ZIndex = 6; NotifBadge.Parent = NotificationDot

	-- ==========================================
	-- NOTIFICATION PANEL DESPLEGABLE
	-- ==========================================
	local NotifPanel = Instance.new("Frame")
	NotifPanel.Size = UDim2.fromOffset(200,220); NotifPanel.Position = UDim2.new(1,-210,0,50)
	NotifPanel.BackgroundColor3 = Color3.fromRGB(16,16,21); NotifPanel.Visible = false
	NotifPanel.ZIndex = 20; NotifPanel.Parent = Main
	Instance.new("UICorner", NotifPanel).CornerRadius = UDim.new(0,10)
	local NotifPanelStroke = Instance.new("UIStroke", NotifPanel)
	NotifPanelStroke.Color = Color3.fromRGB(45,45,50)
	
	local NPTitle = Instance.new("TextLabel")
	NPTitle.Size = UDim2.new(1,0,0,30); NPTitle.BackgroundTransparency = 1
	NPTitle.Text = " Notifications"; NPTitle.TextColor3 = WHITE; NPTitle.TextSize = 12
	NPTitle.Font = Enum.Font.GothamBold; NPTitle.TextXAlignment = Enum.TextXAlignment.Left; NPTitle.Parent = NotifPanel
	local NPLine = Instance.new("Frame")
	NPLine.Size = UDim2.new(1,0,0,1); NPLine.Position = UDim2.new(0,0,0,30)
	NPLine.BackgroundColor3 = Color3.fromRGB(43,43,48); NPLine.BorderSizePixel = 0; NPLine.Parent = NotifPanel
	
	local NotifScroll = Instance.new("ScrollingFrame")
	NotifScroll.Size = UDim2.new(1,0,1,-32); NotifScroll.Position = UDim2.new(0,0,0,32)
	NotifScroll.BackgroundTransparency = 1; NotifScroll.BorderSizePixel = 0
	NotifScroll.ScrollBarThickness = 2; NotifScroll.Parent = NotifPanel
	local NotifLay = Instance.new("UIListLayout", NotifScroll)
	NotifLay.Padding = UDim.new(0,5); NotifLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local NotifExample = Instance.new("Frame")
	NotifExample.Size = UDim2.new(1,-10,0,45); NotifExample.BackgroundColor3 = Color3.fromRGB(24,24,30)
	NotifExample.BorderSizePixel = 0; NotifExample.Parent = NotifScroll
	Instance.new("UICorner", NotifExample).CornerRadius = UDim.new(0,6)
	local NExTitle = Instance.new("TextLabel")
	NExTitle.Size = UDim2.new(1,-10,0,15); NExTitle.Position = UDim2.new(0,5,0,5); NExTitle.BackgroundTransparency = 1
	NExTitle.Text = "System"; NExTitle.TextColor3 = ACCENT; NExTitle.TextSize = 11; NExTitle.Font = Enum.Font.GothamBold; NExTitle.TextXAlignment = Enum.TextXAlignment.Left; NExTitle.Parent = NotifExample
	local NExDesc = Instance.new("TextLabel")
	NExDesc.Size = UDim2.new(1,-10,0,20); NExDesc.Position = UDim2.new(0,5,0,20); NExDesc.BackgroundTransparency = 1
	NExDesc.Text = "Bienvenido de vuelta, " .. Player.Name; NExDesc.TextColor3 = Color3.fromRGB(200,200,208); NExDesc.TextSize = 10; NExDesc.Font = Enum.Font.Gotham; NExDesc.TextXAlignment = Enum.TextXAlignment.Left; NExDesc.TextWrapped = true; NExDesc.Parent = NotifExample

	local NotifOpen = false
	Notification.MouseButton1Click:Connect(function()
		NotifOpen = not NotifOpen
		NotifPanel.Visible = NotifOpen
		if NotifOpen then NotificationDot.Visible = false end
	end)

	-- ==========================================
	-- LOGIN Y NAVEGACIÓN
	-- ==========================================
	local Content = Instance.new("Frame")
	Content.Size = UDim2.new(1,0,1,-46); Content.Position = UDim2.new(0,0,0,46)
	Content.BackgroundTransparency = 1; Content.ClipsDescendants = true; Content.Parent = Main

	local LoginPage = Instance.new("ScrollingFrame")
	LoginPage.Name = "Login"; LoginPage.Size = UDim2.new(1,0,1,0)
	LoginPage.BackgroundTransparency = 1; LoginPage.BorderSizePixel = 0; LoginPage.ScrollingDirection = Enum.ScrollingDirection.Y
	LoginPage.Active = true; LoginPage.ScrollBarThickness = 3; LoginPage.CanvasSize = UDim2.new(0,0,0,320); LoginPage.Parent = Content

	local Profile = Instance.new("ImageLabel")
	Profile.Size = UDim2.fromOffset(80,80); Profile.Position = UDim2.new(0.5,-40,0,10)
	Profile.BackgroundColor3 = Color3.fromRGB(15,35,21); Profile.ScaleType = Enum.ScaleType.Crop; Profile.Parent = LoginPage
	Instance.new("UICorner", Profile).CornerRadius = UDim.new(1,0)
	local ProfileStroke = Instance.new("UIStroke", Profile); ProfileStroke.Color = ACCENT; ProfileStroke.Thickness = 3

	local Welcome = Instance.new("TextLabel")
	Welcome.Size = UDim2.fromOffset(460,32); Welcome.Position = UDim2.new(0.5,-230,0,98); Welcome.BackgroundTransparency = 1
	Welcome.Text = "Welcome Back"; Welcome.TextColor3 = Color3.fromRGB(245,245,247); Welcome.TextSize = 24; Welcome.Font = Enum.Font.GothamBold; Welcome.Parent = LoginPage
	
	local Subtitle = Instance.new("TextLabel")
	Subtitle.Size = UDim2.fromOffset(460,18); Subtitle.Position = UDim2.new(0.5,-230,0,130); Subtitle.BackgroundTransparency = 1
	Subtitle.Text = "Enter the password"; Subtitle.TextColor3 = Color3.fromRGB(125,125,130); Subtitle.TextSize = 12; Subtitle.Font = Enum.Font.Gotham; Subtitle.Parent = LoginPage

	local Password = Instance.new("TextBox")
	Password.Size = UDim2.fromOffset(280,38); Password.Position = UDim2.new(0.5,-140,0,158)
	Password.BackgroundColor3 = Color3.fromRGB(17,17,21); Password.Text = ""
	Password.PlaceholderText = "Password"; Password.PlaceholderColor3 = Color3.fromRGB(105,105,112)
	Password.TextColor3 = Color3.fromRGB(240,240,240); Password.TextSize = 14; Password.Font = Enum.Font.Gotham
	Password.ClearTextOnFocus = false; Password.TextXAlignment = Enum.TextXAlignment.Center; Password.Parent = LoginPage
	Instance.new("UICorner", Password).CornerRadius = UDim.new(0,19)
	local PassStroke = Instance.new("UIStroke", Password); PassStroke.Color = ACCENT; PassStroke.Thickness = 1.5

	local Enter = Instance.new("TextButton")
	Enter.Size = UDim2.fromOffset(280,38); Enter.Position = UDim2.new(0.5,-140,0,206)
	Enter.BackgroundColor3 = Color3.fromRGB(16,16,20); Enter.Text = "Enter"; Enter.TextColor3 = Color3.fromRGB(235,235,238)
	Enter.TextSize = 15; Enter.Font = Enum.Font.GothamBold; Enter.AutoButtonColor = false; Enter.Parent = LoginPage
	Instance.new("UICorner", Enter).CornerRadius = UDim.new(0,19)
	local EnterStroke = Instance.new("UIStroke", Enter); EnterStroke.Color = ACCENT; EnterStroke.Thickness = 1.5

	local ErrorText = Instance.new("TextLabel")
	ErrorText.Size = UDim2.fromOffset(400,18); ErrorText.Position = UDim2.new(0.5,-200,0,252); ErrorText.BackgroundTransparency = 1
	ErrorText.Text = ""; ErrorText.TextColor3 = Color3.fromRGB(255,80,80); ErrorText.TextSize = 12; ErrorText.Font = Enum.Font.Gotham; ErrorText.Parent = LoginPage

	local Pages = Instance.new("Frame")
	Pages.Size = UDim2.new(1,0,1,-62); Pages.BackgroundTransparency = 1; Pages.ClipsDescendants = true; Pages.Visible = false; Pages.Parent = Content

	local function MakePage(name, canvas)
		local p = Instance.new("ScrollingFrame")
		p.Name = name; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
		p.ScrollingDirection = Enum.ScrollingDirection.Y; p.Active = true; p.ScrollBarThickness = 3
		p.ScrollBarImageTransparency = 0.4; p.CanvasSize = UDim2.new(0,0,0,canvas); p.Visible = false; p.Parent = Pages
		p.AutomaticCanvasSize = Enum.AutomaticSize.Y
		return p
	end

	local HomePage = MakePage("Home", 400); HomePage.Visible = true
	local ScriptsPage = MakePage("Scripts", 300)
	local FlingPage = MakePage("Fling", 400)
	local SkysPage = MakePage("Skys", 2000)
	local AnimationsPage = MakePage("Animations", 800)
	local SettingsPage = MakePage("Settings", 400)

	-- ==========================================
	-- HOME PAGE CONTENT
	-- ==========================================
	local BigProfile = Instance.new("ImageLabel")
	BigProfile.Size = UDim2.fromOffset(70,70); BigProfile.Position = UDim2.new(0,20,0,16)
	BigProfile.BackgroundColor3 = Color3.fromRGB(15,15,18); BigProfile.ScaleType = Enum.ScaleType.Crop; BigProfile.Parent = HomePage
	Instance.new("UICorner", BigProfile).CornerRadius = UDim.new(1,0)
	local BigStroke = Instance.new("UIStroke", BigProfile); BigStroke.Color = ACCENT; BigStroke.Thickness = 3

	local OnlineDot = Instance.new("Frame")
	OnlineDot.Size = UDim2.fromOffset(22,22); OnlineDot.Position = UDim2.new(1,-16,1,-16)
	OnlineDot.BackgroundColor3 = ACCENT; OnlineDot.BorderSizePixel = 0; OnlineDot.ZIndex = 5; OnlineDot.Parent = BigProfile
	Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1,0)
	local OS = Instance.new("UIStroke", OnlineDot); OS.Color = Color3.fromRGB(10,10,14); OS.Thickness = 3

	local UserName = Instance.new("TextLabel")
	UserName.Size = UDim2.new(1,-110,0,28); UserName.Position = UDim2.new(0,100,0,18)
	UserName.BackgroundTransparency = 1; UserName.TextXAlignment = Enum.TextXAlignment.Left
	UserName.TextColor3 = Color3.fromRGB(245,245,247); UserName.TextSize = 19; UserName.Font = Enum.Font.GothamBold; UserName.Parent = HomePage

	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1,-110,0,18); Status.Position = UDim2.new(0,100,0,46)
	Status.BackgroundTransparency = 1; Status.Text = "Online"; Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.TextColor3 = ACCENT; Status.TextSize = 12; Status.Font = Enum.Font.Gotham; Status.Parent = HomePage

	local MostUsedTitle = Instance.new("TextLabel")
	MostUsedTitle.Size = UDim2.new(1,-70,0,20); MostUsedTitle.Position = UDim2.new(0,20,0,100)
	MostUsedTitle.BackgroundTransparency = 1; MostUsedTitle.Text = "Most Used Scripts"; MostUsedTitle.TextXAlignment = Enum.TextXAlignment.Left
	MostUsedTitle.TextColor3 = Color3.fromRGB(245,245,247); MostUsedTitle.TextSize = 14; MostUsedTitle.Font = Enum.Font.GothamBold; MostUsedTitle.Parent = HomePage

	local MostUsedList = Instance.new("Frame")
	MostUsedList.Size = UDim2.new(1,-40,0,0); MostUsedList.Position = UDim2.new(0,20,0,128)
	MostUsedList.BackgroundTransparency = 1; MostUsedList.AutomaticSize = Enum.AutomaticSize.Y; MostUsedList.Parent = HomePage
	local mul = Instance.new("UIListLayout", MostUsedList)
	mul.Padding = UDim.new(0,4); mul.SortOrder = Enum.SortOrder.LayoutOrder

	local function RefreshMostUsed()
		for _, c in ipairs(MostUsedList:GetChildren()) do if c ~= mul then c:Destroy() end end
		local sorted = {}
		for k, v in pairs(ToggleUsage) do
			if ToggleRegistry[k] and v > 0 then table.insert(sorted, {name=k, count=v}) end
		end
		table.sort(sorted, function(a,b)
			if a.count == b.count then return a.name < b.name end
			return a.count > b.count
		end)
		if #sorted == 0 then return end
		for i = 1, math.min(5, #sorted) do
			local entry = Instance.new("Frame")
			entry.Size = UDim2.new(1,0,0,30); entry.BackgroundColor3 = Color3.fromRGB(18,18,23); entry.BorderSizePixel = 0; entry.LayoutOrder = i; entry.Parent = MostUsedList
			Instance.new("UICorner", entry).CornerRadius = UDim.new(0,8)
			
			local num = Instance.new("TextLabel")
			num.Size = UDim2.fromOffset(20,20); num.Position = UDim2.new(0,4,0.5,-10); num.BackgroundColor3 = ACCENT
			num.Text = tostring(i); num.TextColor3 = Color3.fromRGB(20,20,24); num.TextSize = 11; num.Font = Enum.Font.GothamBold; num.Parent = entry
			Instance.new("UICorner", num).CornerRadius = UDim.new(1,0)
			
			local nm = Instance.new("TextLabel")
			nm.Size = UDim2.new(1,-90,1,0); nm.Position = UDim2.new(0,30,0,0); nm.BackgroundTransparency = 1
			nm.Text = sorted[i].name; nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextColor3 = Color3.fromRGB(225,225,232); nm.TextSize = 11; nm.Font = Enum.Font.GothamMedium; nm.Parent = entry
			
			local registry = ToggleRegistry[sorted[i].name]
			local msw = Instance.new("Frame")
			msw.Size = UDim2.fromOffset(32,18); msw.Position = UDim2.new(1,-40,0.5,-9); msw.BackgroundColor3 = Color3.fromRGB(70,70,78); msw.BorderSizePixel = 0; msw.Parent = entry
			Instance.new("UICorner", msw).CornerRadius = UDim.new(1,0)
			local msknob = Instance.new("Frame")
			msknob.Size = UDim2.fromOffset(14,14); msknob.Position = UDim2.fromOffset(2,2); msknob.BackgroundColor3 = Color3.fromRGB(240,240,245); msknob.Parent = msw
			Instance.new("UICorner", msknob).CornerRadius = UDim.new(1,0)
			local msc = Instance.new("TextButton")
			msc.Size = UDim2.new(1,0,1,0); msc.BackgroundTransparency = 1; msc.Text = ""; msc.ZIndex = 3; msc.Parent = entry
			
			local function updateMSVisual(v)
				msw.BackgroundColor3 = v and ACCENT or Color3.fromRGB(70,70,78)
				TweenService:Create(msknob, TweenInfo.new(0.15), {Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.fromOffset(2,2)}):Play()
			end
			if registry then
				updateMSVisual(registry.getActive())
				msc.MouseButton1Click:Connect(function() registry.setActive(not registry.getActive()) end)
				task.spawn(function()
					while entry.Parent do
						updateMSVisual(registry.getActive())
						task.wait(0.15)
					end
				end)
			end
		end
	end

	-- ==========================================
	-- SCRIPTS PAGE Y BUSCADOR
	-- ==========================================
	local ScriptsTitle = Instance.new("TextLabel")
	ScriptsTitle.Size = UDim2.new(1,-40,0,26); ScriptsTitle.Position = UDim2.new(0,20,0,12)
	ScriptsTitle.BackgroundTransparency = 1; ScriptsTitle.Text = "Scripts"; ScriptsTitle.TextXAlignment = Enum.TextXAlignment.Left; ScriptsTitle.TextColor3 = Color3.fromRGB(245,245,247)
	ScriptsTitle.TextSize = 20; ScriptsTitle.Font = Enum.Font.GothamBold; ScriptsTitle.Parent = ScriptsPage

	local ScriptsSearch = Instance.new("TextBox")
	ScriptsSearch.Size = UDim2.new(1,-40,0,32); ScriptsSearch.Position = UDim2.new(0,20,0,44)
	ScriptsSearch.BackgroundColor3 = Color3.fromRGB(18,18,23); ScriptsSearch.PlaceholderText = "Search scripts..."
	ScriptsSearch.TextColor3 = Color3.fromRGB(240,240,240); ScriptsSearch.TextSize = 12
	ScriptsSearch.Font = Enum.Font.Gotham; ScriptsSearch.TextXAlignment = Enum.TextXAlignment.Left; ScriptsSearch.Parent = ScriptsPage
	Instance.new("UICorner", ScriptsSearch).CornerRadius = UDim.new(0,10)
	local SSS = Instance.new("UIStroke", ScriptsSearch); SSS.Color = Color3.fromRGB(52,52,60)
	local SS_Pad = Instance.new("UIPadding", ScriptsSearch); SS_Pad.PaddingLeft = UDim.new(0,32)
	
	local ScriptsRow = Instance.new("Frame")
	ScriptsRow.Size = UDim2.new(1,-40,0,36); ScriptsRow.Position = UDim2.new(0,20,0,84)
	ScriptsRow.BackgroundTransparency = 1; ScriptsRow.Parent = ScriptsPage
	local ScriptsLayout = Instance.new("UIListLayout", ScriptsRow)
	ScriptsLayout.FillDirection = Enum.FillDirection.Horizontal; ScriptsLayout.Padding = UDim.new(0,6)

	local ScriptsContent = Instance.new("Frame")
	ScriptsContent.Size = UDim2.new(1,-40,0,0); ScriptsContent.Position = UDim2.new(0,20,0,130)
	ScriptsContent.BackgroundTransparency = 1; ScriptsContent.AutomaticSize = Enum.AutomaticSize.Y; ScriptsContent.Parent = ScriptsPage

	local function MakeTabContent(name)
		local f = Instance.new("Frame")
		f.Name = name; f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
		f.BackgroundTransparency = 1; f.Visible = false; f.Parent = ScriptsContent
		local lay = Instance.new("UIListLayout", f)
		lay.Padding = UDim.new(0,6); lay.SortOrder = Enum.SortOrder.LayoutOrder
		return f
	end

	local MainScriptTab = MakeTabContent("MainScript")
	local ExtraTab = MakeTabContent("Extra")

	local activeTab = nil
	local activePill = nil

	local function MakeScriptPill(text, order)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(150,36); b.BackgroundColor3 = Color3.fromRGB(20,20,26)
		b.Text = text; b.TextColor3 = Color3.fromRGB(225,225,232)
		b.TextSize = 13; b.Font = Enum.Font.GothamBold; b.LayoutOrder = order; b.Parent = ScriptsRow
		Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
		local s = Instance.new("UIStroke", b); s.Color = WHITE; s.Transparency = 0.82
		task.defer(function() AddButtonSweep(b, s) end)
		return b
	end
	local MainScriptBtn = MakeScriptPill("Script", 1)
	local ExtraBtn = MakeScriptPill("Extra", 2)

	local function SelectTab(tab, pill)
		if activeTab == tab then return end
		if activeTab then
			local oldTab = activeTab; local oldPill = activePill
			TweenService:Create(oldTab, TweenInfo.new(0.18), {Position=UDim2.new(-0.15,0,0,0)}):Play()
			if oldPill then
				TweenService:Create(oldPill, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20,20,26), TextColor3 = Color3.fromRGB(225,225,232)}):Play()
				local ps = oldPill:FindFirstChildOfClass("UIStroke")
				if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=WHITE, Transparency = 0.82}):Play() end
			end
			task.delay(0.18, function() if oldTab then oldTab.Visible = false oldTab.Position = UDim2.new(0,0,0,0) end end)
		end
		activeTab = tab; activePill = pill
		tab.Visible = true; tab.Position = UDim2.new(0.15,0,0,0)
		TweenService:Create(tab, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play()
		TweenService:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = ACCENT:Lerp(Color3.new(0,0,0),0.7), TextColor3 = ACCENT:Lerp(Color3.new(1,1,1),0.5)}):Play()
		local ps = pill:FindFirstChildOfClass("UIStroke")
		if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=ACCENT, Transparency = 0.2}):Play() end
	end
	MainScriptBtn.MouseButton1Click:Connect(function() SelectTab(MainScriptTab, MainScriptBtn) end)
	ExtraBtn.MouseButton1Click:Connect(function() SelectTab(ExtraTab, ExtraBtn) end)

	ScriptsSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local q = ScriptsSearch.Text:lower()
		for _, entry in ipairs(AllToggles) do
			if q == "" then entry.btn.Visible = true
			else entry.btn.Visible = entry.text:lower():find(q,1,true) ~= nil end
		end
	end)

	local function CreatePageTitle(parent, text)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1,-40,0,26); t.Position = UDim2.new(0,20,0,12); t.BackgroundTransparency = 1
		t.Text = text; t.TextXAlignment = Enum.TextXAlignment.Left; t.TextColor3 = Color3.fromRGB(245,245,247)
		t.TextSize = 20; t.Font = Enum.Font.GothamBold; t.Parent = parent
	end
	CreatePageTitle(FlingPage, "Fling Players")
	CreatePageTitle(SkysPage, "Skys")
	CreatePageTitle(AnimationsPage, "Animations")
	CreatePageTitle(SettingsPage, "Settings")

	-- ==========================================
	-- BOTTOM NAVIGATION BAR
	-- ==========================================
	local Bottom = Instance.new("Frame")
	Bottom.Size = UDim2.fromOffset(460,54); Bottom.Position = UDim2.new(0.5,-230,1,-60)
	Bottom.BackgroundColor3 = Color3.fromRGB(18,18,22); Bottom.BorderSizePixel = 0; Bottom.Visible = false; Bottom.Parent = Content
	Instance.new("UICorner", Bottom).CornerRadius = UDim.new(0,27)
	local BS = Instance.new("UIStroke", Bottom); BS.Color = Color3.fromRGB(45,45,50)

	local NavPill = Instance.new("Frame")
	NavPill.Size = UDim2.fromOffset(76,46); NavPill.Position = UDim2.new(0,2,0,4); NavPill.BackgroundColor3 = WHITE
	NavPill.BackgroundTransparency = 0.88; NavPill.BorderSizePixel = 0; NavPill.ZIndex = 2; NavPill.Parent = Bottom
	Instance.new("UICorner", NavPill).CornerRadius = UDim.new(1,0)

	local function MakeNavButton(imageId, label, x, w)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(w,46); b.Position = UDim2.new(0,x,0,4); b.BackgroundTransparency = 1; b.Text = ""; b.ZIndex = 4; b.Parent = Bottom
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromOffset(22,22); icon.Position = UDim2.new(0.5,-11,0,6); icon.BackgroundTransparency = 1; icon.Image = "rbxassetid://"..imageId; icon.ZIndex = 7; icon.Parent = b
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,0,0,14); lbl.Position = UDim2.new(0,0,0,30); lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = Color3.fromRGB(180,180,190); lbl.TextSize = 10; lbl.Font = Enum.Font.GothamMedium; lbl.ZIndex = 7; lbl.Parent = b
		return b
	end
	local HomeButton = MakeNavButton("135130950196086", "Home", 2, 76)
	local ScriptsButton = MakeNavButton("79949598410209", "Scripts", 78, 76)
	local FlingButton = MakeNavButton("101363781360377", "Fling", 154, 76)
	local SkysButton = MakeNavButton("107588676615037", "Skys", 230, 76)
	local AnimationsButton = MakeNavButton("135130950196086", "Anims", 306, 76)
	local SettingsButton = MakeNavButton("114349145444051", "Settings", 382, 76)

	local function MoveNavPill(x, w)
		TweenService:Create(NavPill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, x, 0, 4), Size = UDim2.fromOffset(w, 46)}):Play()
	end

	local unlocked = false; local animating = false
	local currentPageName = "Home"
	local PageMap = {Home=HomePage, Scripts=ScriptsPage, Fling=FlingPage, Skys=SkysPage, Animations=AnimationsPage, Settings=SettingsPage}
	
	local function SwitchPage(target, fromRight)
		if animating or currentPageName == target or not unlocked then return end
		local FromPage = PageMap[currentPageName]
		local ToPage = PageMap[target]
		animating = true
		local Dir = fromRight and 1 or -1
		ToPage.Position = UDim2.new(Dir,0,0,0); ToPage.Visible = true
		TweenService:Create(FromPage, TweenInfo.new(0.15), {Position=UDim2.new(-Dir,0,0,0)}):Play()
		TweenService:Create(ToPage, TweenInfo.new(0.15), {Position=UDim2.new(0,0,0,0)}):Play()
		task.wait(0.15)
		FromPage.Visible = false; currentPageName = target; animating = false
	end

	HomeButton.MouseButton1Click:Connect(function() SwitchPage("Home", false) MoveNavPill(2, 76) end)
	ScriptsButton.MouseButton1Click:Connect(function() SwitchPage("Scripts", true) MoveNavPill(78, 76) end)
	FlingButton.MouseButton1Click:Connect(function() SwitchPage("Fling", true) MoveNavPill(154, 76) end)
	SkysButton.MouseButton1Click:Connect(function() SwitchPage("Skys", true) MoveNavPill(230, 76) end)
	AnimationsButton.MouseButton1Click:Connect(function() SwitchPage("Animations", true) MoveNavPill(306, 76) end)
	SettingsButton.MouseButton1Click:Connect(function() SwitchPage("Settings", true) MoveNavPill(382, 76) end)

	local function LoginSuccess()
		if unlocked then return end
		unlocked = true
		LoginPage.Visible = false
		local pName = Player and Player.Name or "Player"
		UserName.Text = "@"..pName
		Pages.Visible = true; Bottom.Visible = true
		if not activeTab then SelectTab(MainScriptTab, MainScriptBtn) end
		RefreshMostUsed()
	end

	Enter.MouseButton1Click:Connect(function()
		if Password.Text == "sam2027" then SaveSession() LoginSuccess() else ErrorText.Text = "Clave incorrecta" end
	end)

	if HasSession() and isWhitelisted(Player and Player.Name or "") then task.defer(function() LoginSuccess() end) end

	local function MinimizeWindow()
		TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)}):Play()
		-- Opcional: mostrar un botón flotante para reabrir
	end
	MinimizeButton.MouseButton1Click:Connect(MinimizeWindow)
	CloseButton.MouseButton1Click:Connect(function() GUI:Destroy() end)

	-- ==========================================
	-- MÉTODOS PÚBLICOS Y CONTENEDORES
	-- ==========================================
	local WindowElements = {}
	
	WindowElements.MainScriptTab = MainScriptTab
	WindowElements.ExtraTab = ExtraTab
	WindowElements.FlingPage = FlingPage
	WindowElements.SkysPage = SkysPage
	WindowElements.AnimationsPage = AnimationsPage

	-- Contenedor especial para Skys (UIListLayout)
	local SkysContent = Instance.new("Frame")
	SkysContent.Size = UDim2.new(1,-40,0,0); SkysContent.Position = UDim2.new(0,20,0,44)
	SkysContent.BackgroundTransparency = 1; SkysContent.AutomaticSize = Enum.AutomaticSize.Y; SkysContent.Parent = SkysPage
	local scl = Instance.new("UIListLayout", SkysContent)
	scl.Padding = UDim.new(0,6); scl.SortOrder = Enum.SortOrder.LayoutOrder
	WindowElements.SkysContainer = SkysContent

	function WindowElements:CreateToggle(parent, text, callback, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,0,36); btn.BackgroundColor3 = Color3.fromRGB(20,20,26)
		btn.Text = ""; btn.LayoutOrder = order or 1; btn.Parent = parent
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = WHITE; stroke.Transparency = 0.82
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1,-70,1,0); label.Position = UDim2.new(0,14,0,0)
		label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Color3.fromRGB(225,225,232)
		label.TextSize = 12; label.Font = Enum.Font.GothamBold; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = btn
		
		local sw = Instance.new("Frame")
		sw.Size = UDim2.fromOffset(36,20); sw.Position = UDim2.new(1,-48,0.5,-10)
		sw.BackgroundColor3 = Color3.fromRGB(70,70,78); sw.Parent = btn
		Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
		
		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(16,16); knob.Position = UDim2.fromOffset(2,2)
		knob.BackgroundColor3 = Color3.fromRGB(240,240,245); knob.Parent = sw
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
		
		local active = false
		local function setVisual(v)
			sw.BackgroundColor3 = v and ACCENT or Color3.fromRGB(70,70,78)
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = v and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)}):Play()
		end
		
		btn.MouseButton1Click:Connect(function()
			if not active then
				local canActivate, blocker = CanActivate(text)
				if not canActivate then ShowNotif("No se puede activar", "Desactiva primero: " .. blocker, 3) return end
				active = true
				ToggleUsage[text] = (ToggleUsage[text] or 0) + 1; SaveUsage(ToggleUsage)
				SetExclusiveActive(text)
			else
				active = false
				ClearExclusiveActive(text)
			end
			setVisual(active)
			pcall(callback, active)
			RefreshMostUsed()
		end)
		
		ToggleRegistry[text] = { getActive = function() return active end, setActive = function(v) active = v setVisual(v) pcall(callback, v) end }
		table.insert(AllToggles, {btn=btn, label=label, text=text, parent=parent})
		task.defer(function() AddButtonSweep(btn, stroke) end)
		return btn
	end

	function WindowElements:CreateButton(parent, text, callback, order, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,34); b.BackgroundColor3 = color or Color3.fromRGB(20,20,26)
		b.Text = text; b.TextColor3 = Color3.fromRGB(225,225,232)
		b.TextSize = 12; b.Font = Enum.Font.GothamBold
		b.AutoButtonColor = false; b.LayoutOrder = order; b.Parent = parent
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
		local s = Instance.new("UIStroke", b)
		s.Color = WHITE; s.Transparency = 0.82
		task.defer(function() AddButtonSweep(b, s) end)
		b.MouseButton1Click:Connect(function() pcall(callback) end)
		return b
	end

	return WindowElements
end

return Library
