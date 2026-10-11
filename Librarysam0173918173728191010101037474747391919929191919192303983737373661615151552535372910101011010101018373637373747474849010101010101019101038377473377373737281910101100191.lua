-- ============================================================
-- UI_LIBRARY.LUA (Subir a GitHub)
-- ============================================================
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
	-- SISTEMA DE SESIÓN Y DATOS
	-- ==========================================
	local WHITELIST = {
		["jerehzxs"]  = "OWNER", ["cloudd7qo"] = "TESTER",
		["jerehvo"]   = "MEMBER", ["b92b08a"]   = "MEMBER", ["astrixrsz"] = "MEMBER",
	}
	local function isWhitelisted(n) if not n then return false end return WHITELIST[n:lower()] ~= nil end

	local function HasSession()
		local ok, c = pcall(function() if readfile then return readfile("wb_session.txt") end end)
		if not ok or not c then return false end
		return (os.time() - (tonumber(c) or 0)) < 86400
	end
	local function SaveSession() pcall(function() if writefile then writefile("wb_session.txt", tostring(os.time())) end end) end

	local AllToggles = {}

	local OldGUI = PlayerGui:FindFirstChild("WelcomeBackUI")
	if OldGUI then OldGUI:Destroy() end
	local OldCoreGUI = CoreGui:FindFirstChild("WelcomeBackUI")
	if OldCoreGUI then OldCoreGUI:Destroy() end

	-- ==========================================
	-- CARGA DE FUENTES (MATCHA FONT)
	-- ==========================================
	local MatchaFont = nil
	local FontReady = false
	local function LoadMatchaFont()
		if not (isfile and writefile and getcustomasset) then return end
		local ttfFile = "CNP_Matcha.ttf"
		local jsonFile = "CNP_Matcha.json"
		local ok = pcall(function()
			if not isfile(ttfFile) then
				local data = game:HttpGet("https://raw.githubusercontent.com/samxzqpq/fonts/main/Matcha%20World.ttf")
				if not data or #data < 100 then return end
				writefile(ttfFile, data)
			end
		end)
		if not ok then return end
		pcall(function()
			local asset = getcustomasset(ttfFile)
			local jsonData = HttpService:JSONEncode({name="Matcha",faces={{name="Regular",weight=400,style="normal",assetId=asset}}})
			writefile(jsonFile, jsonData)
			local family = getcustomasset(jsonFile)
			MatchaFont = Font.new(family, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			FontReady = true
		end)
	end
	task.spawn(LoadMatchaFont)
	local function ApplyFont(obj)
		if not MatchaFont then return end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			pcall(function() obj.FontFace = MatchaFont end)
		end
	end

	-- ==========================================
	-- CREACIÓN DE INTERFAZ BASE
	-- ==========================================
	local GUI = Instance.new("ScreenGui")
	GUI.Name = "WelcomeBackUI"
	GUI.ResetOnSpawn = false
	GUI.IgnoreGuiInset = true
	GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	GUI.DisplayOrder = 999
	pcall(function() GUI.Parent = CoreGui end)
	if not GUI.Parent then GUI.Parent = PlayerGui end

	GUI.DescendantAdded:Connect(function(obj) task.defer(function() ApplyFont(obj) end) end)
	task.spawn(function()
		while not FontReady do task.wait(0.1) end
		for _, obj in ipairs(GUI:GetDescendants()) do ApplyFont(obj) end
	end)

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
	-- ARRASTRE Y TOP BAR
	-- ==========================================
	local Top = Instance.new("Frame")
	Top.Name = "Top"; Top.Size = UDim2.new(1,0,0,46); Top.BackgroundTransparency = 1; Top.Active = true; Top.Parent = Main
	local TopLine = Instance.new("Frame")
	TopLine.Size = UDim2.new(1,0,0,1); TopLine.Position = UDim2.new(0,0,1,-1); TopLine.BackgroundColor3 = Color3.fromRGB(43,43,48); TopLine.BorderSizePixel = 0; TopLine.Parent = Top

	local dragging, dragInput, dragStart, startPos
	Top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = Main.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
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
	-- PANELES Y PAGINAS
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

	local BigProfile = Instance.new("ImageLabel")
	BigProfile.Size = UDim2.fromOffset(70,70); BigProfile.Position = UDim2.new(0,20,0,16)
	BigProfile.BackgroundColor3 = Color3.fromRGB(15,15,18); BigProfile.ScaleType = Enum.ScaleType.Crop; BigProfile.Parent = HomePage
	Instance.new("UICorner", BigProfile).CornerRadius = UDim.new(1,0)
	local BigStroke = Instance.new("UIStroke", BigProfile); BigStroke.Color = ACCENT; BigStroke.Thickness = 3

	local UserName = Instance.new("TextLabel")
	UserName.Size = UDim2.new(1,-110,0,28); UserName.Position = UDim2.new(0,100,0,18)
	UserName.BackgroundTransparency = 1; UserName.TextXAlignment = Enum.TextXAlignment.Left
	UserName.TextColor3 = Color3.fromRGB(245,245,247); UserName.TextSize = 19; UserName.Font = Enum.Font.GothamBold; UserName.Parent = HomePage

	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1,-110,0,18); Status.Position = UDim2.new(0,100,0,46)
	Status.BackgroundTransparency = 1; Status.Text = "Online"; Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.TextColor3 = ACCENT; Status.TextSize = 12; Status.Font = Enum.Font.Gotham; Status.Parent = HomePage

	local Reopen = Instance.new("ImageButton")
	Reopen.Size = UDim2.fromOffset(56,56); Reopen.Position = UDim2.new(0,16,1,-72)
	Reopen.BackgroundColor3 = Color3.fromRGB(15,15,18); Reopen.Visible = false; Reopen.Parent = GUI
	Reopen.ScaleType = Enum.ScaleType.Crop
	Instance.new("UICorner", Reopen).CornerRadius = UDim.new(1,0)
	local ReopenStroke = Instance.new("UIStroke", Reopen); ReopenStroke.Color = ACCENT; ReopenStroke.Thickness = 2.5

	-- Carga de Imagen de Perfil
	task.spawn(function()
		local content, isReady = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		if isReady then 
			Profile.Image = content; BigProfile.Image = content; Reopen.Image = content 
		end
	end)

	local function MinimizeWindow()
		Main.Visible = false
		Reopen.Visible = true
	end
	MinimizeButton.MouseButton1Click:Connect(MinimizeWindow)
	Reopen.MouseButton1Click:Connect(function()
		Reopen.Visible = false
		Main.Visible = true
	end)
	CloseButton.MouseButton1Click:Connect(function() GUI:Destroy() end)

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
			activeTab.Visible = false
			local oldPill = activePill
			TweenService:Create(oldPill, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20,20,26), TextColor3 = Color3.fromRGB(225,225,232)}):Play()
			local ps = oldPill:FindFirstChildOfClass("UIStroke")
			if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=WHITE, Transparency = 0.82}):Play() end
		end
		activeTab = tab; activePill = pill
		tab.Visible = true
		TweenService:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = ACCENT:Lerp(Color3.new(0,0,0),0.7), TextColor3 = ACCENT:Lerp(Color3.new(1,1,1),0.5)}):Play()
		local ps = pill:FindFirstChildOfClass("UIStroke")
		if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=ACCENT, Transparency = 0.2}):Play() end
	end
	MainScriptBtn.MouseButton1Click:Connect(function() SelectTab(MainScriptTab, MainScriptBtn) end)
	ExtraBtn.MouseButton1Click:Connect(function() SelectTab(ExtraTab, ExtraBtn) end)

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

	local unlocked = false; local animating = false
	local currentPageName = "Home"
	local PageMap = {Home=HomePage, Scripts=ScriptsPage, Fling=FlingPage, Skys=SkysPage, Animations=AnimationsPage}
	
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

	HomeButton.MouseButton1Click:Connect(function() SwitchPage("Home", false) TweenService:Create(NavPill, TweenInfo.new(0.1), {Position=UDim2.new(0,2,0,4)}):Play() end)
	ScriptsButton.MouseButton1Click:Connect(function() SwitchPage("Scripts", true) TweenService:Create(NavPill, TweenInfo.new(0.1), {Position=UDim2.new(0,78,0,4)}):Play() end)
	FlingButton.MouseButton1Click:Connect(function() SwitchPage("Fling", true) TweenService:Create(NavPill, TweenInfo.new(0.1), {Position=UDim2.new(0,154,0,4)}):Play() end)
	SkysButton.MouseButton1Click:Connect(function() SwitchPage("Skys", true) TweenService:Create(NavPill, TweenInfo.new(0.1), {Position=UDim2.new(0,230,0,4)}):Play() end)
	AnimationsButton.MouseButton1Click:Connect(function() SwitchPage("Animations", true) TweenService:Create(NavPill, TweenInfo.new(0.1), {Position=UDim2.new(0,306,0,4)}):Play() end)

	local function LoginSuccess()
		if unlocked then return end
		unlocked = true
		LoginPage.Visible = false
		UserName.Text = "@"..(Player and Player.Name or "Player")
		Pages.Visible = true; Bottom.Visible = true
		if not activeTab then SelectTab(MainScriptTab, MainScriptBtn) end
	end

	Enter.MouseButton1Click:Connect(function()
		if Password.Text == "sam2027" then SaveSession() LoginSuccess() else ErrorText.Text = "Clave incorrecta" end
	end)
	if HasSession() and isWhitelisted(Player and Player.Name or "") then task.defer(function() LoginSuccess() end) end

	local WindowElements = {}
	WindowElements.MainScriptTab = MainScriptTab
	WindowElements.ExtraTab = ExtraTab
	WindowElements.FlingPage = FlingPage
	WindowElements.SkysPage = SkysPage
	WindowElements.AnimationsPage = AnimationsPage
	WindowElements.ShowNotif = ShowNotif 

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
			active = not active
			setVisual(active)
			pcall(callback, active)
		end)
		
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
