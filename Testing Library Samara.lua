local S = {
	Players = game:GetService("Players"),
	Tween = game:GetService("TweenService"),
	Input = game:GetService("UserInputService"),
	Run = game:GetService("RunService"),
	Http = game:GetService("HttpService"),
	Lighting = game:GetService("Lighting"),
	Sound = game:GetService("SoundService"),
	RepStorage = game:GetService("ReplicatedStorage"),
	Debris = game:GetService("Debris"),
	CoreGui = game:GetService("CoreGui"),
}
S.Player = S.Players.LocalPlayer
S.PlayerGui = S.Player:WaitForChild("PlayerGui")
S.Workspace = workspace
local WHITE = Color3.new(1,1,1)

local WHITELIST = {
	["samlpzqq"]  = "OWNER",
	["chiquille_xd"] = "TESTER",
	["jerehvo"]   = "MEMBER",
	["b92b08a"]   = "MEMBER",
	["astrixrsz"] = "MEMBER",
}
local function getRank(n) if not n then return nil end return WHITELIST[n:lower()] end
local function isWhitelisted(n) if not n then return false end return WHITELIST[n:lower()] ~= nil end

local MatchaFont, FontReady = nil, false
local function LoadMatchaFont()
	if not (isfile and writefile and getcustomasset) then return end
	local ttfFile = "CNP_Matcha.ttf"
	local jsonFile = "CNP_Matcha.json"
	local ok = pcall(function()
		if not isfile(ttfFile) then
			local data = game:HttpGet("https://raw.githubusercontent.com/samxzqpq/fonts/main/Matcha%20World.ttf")
			if not data or #data < 100 then error("empty") end
			writefile(ttfFile, data)
		end
	end)
	if not ok then return end
	pcall(function()
		local asset = getcustomasset(ttfFile)
		local jsonData = S.Http:JSONEncode({name="Matcha",faces={{name="Regular",weight=400,style="normal",assetId=asset}}})
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

local Storage = {}
function Storage.HasSession()
	local ok, c = pcall(function() if readfile then return readfile("wb_session.txt") end end)
	if not ok or not c then return false end
	local t = tonumber(c); if not t then return false end
	return (os.time() - t) < 86400
end
function Storage.SaveSession() pcall(function() if writefile then writefile("wb_session.txt", tostring(os.time())) end end) end
function Storage.LoadUsage()
	local ok, data = pcall(function() if readfile then return readfile("wb_usage.json") end end)
	if ok and data then
		local ok2, tbl = pcall(function() return S.Http:JSONDecode(data) end)
		if ok2 and type(tbl)=="table" then return tbl end
	end
	return {}
end
function Storage.SaveUsage(tbl) pcall(function() if writefile then writefile("wb_usage.json", S.Http:JSONEncode(tbl)) end end) end

local ToggleUsage = Storage.LoadUsage()
local AllToggles, ToggleRegistry, ExclusiveGroups = {}, {}, {}

local OldGUI = S.PlayerGui:FindFirstChild("WelcomeBackUI")
if OldGUI then OldGUI:Destroy() end

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
		for _, n in ipairs(g.toggles) do
			if n == toggleName then g.activeName = toggleName return end
		end
	end
end
local function ClearExclusiveActive(toggleName)
	for _, g in pairs(ExclusiveGroups) do
		if g.activeName == toggleName then g.activeName = nil end
	end
end

local UI = {}
UI.ACCENT = Color3.fromRGB(62,215,98)

local function ShowNotif(title, text, dur)
	dur = dur or 3
	local n = Instance.new("Frame")
	n.Size = UDim2.fromOffset(300, 62)
	n.Position = UDim2.new(0.5, -150, 0, -80)
	n.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	n.BorderSizePixel = 0
	n.ZIndex = 100
	n.Parent = UI.GUI
	Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke", n)
	s.Color = UI.ACCENT; s.Thickness = 1.5
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 20); t.Position = UDim2.new(0, 10, 0, 6)
	t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = UI.ACCENT
	t.TextSize = 13; t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = n
	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(1, -20, 0, 28); b.Position = UDim2.new(0, 10, 0, 26)
	b.BackgroundTransparency = 1; b.Text = text
	b.TextColor3 = Color3.fromRGB(200, 200, 208); b.TextSize = 11
	b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextWrapped = true; b.Parent = n
	local twIn = S.Tween:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, 20)})
	twIn:Play()
	task.delay(dur, function()
		if not n.Parent then return end
		local tw = S.Tween:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, -80)})
		tw:Play()
		tw.Completed:Connect(function() n:Destroy() end)
	end)
end

local SWEEP_INFO = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local STROKE_IN_INFO = TweenInfo.new(0.15)
local STROKE_OUT_INFO = TweenInfo.new(0.15)

local function AddButtonSweep(btn, stroke)
	if not btn or btn:FindFirstChild("SweepHolder") then return end
	if stroke then
		stroke.Color = Color3.fromRGB(255,255,255)
		stroke.Thickness = 1
		stroke.Transparency = 0.82
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	local sh = Instance.new("Frame")
	sh.Name = "SweepHolder"
	sh.Size = UDim2.new(1,0,1,0)
	sh.BackgroundTransparency = 1
	sh.ClipsDescendants = true
	sh.ZIndex = 5
	sh.Parent = btn
	Instance.new("UICorner", sh).CornerRadius = UDim.new(0,10)
	local sw = Instance.new("Frame")
	sw.Size = UDim2.new(0, 40, 1, 0)
	sw.Position = UDim2.new(0, -40, 0, 0)
	sw.BackgroundColor3 = Color3.fromRGB(255,255,255)
	sw.BackgroundTransparency = 0.94
	sw.BorderSizePixel = 0
	sw.ZIndex = 6
	sw.Parent = sh
	local g = Instance.new("UIGradient", sw)
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)})

	local sweepTween = S.Tween:Create(sw, SWEEP_INFO, {Position = UDim2.new(1, 0, 0, 0)})
	local strokeIn, strokeOut
	if stroke then
		strokeIn = S.Tween:Create(stroke, STROKE_IN_INFO, {Transparency = 0.5})
		strokeOut = S.Tween:Create(stroke, STROKE_OUT_INFO, {Transparency = 0.82})
	end
	local sweeping = false
	sweepTween.Completed:Connect(function() sweeping = false end)
	btn.MouseEnter:Connect(function()
		if strokeIn then strokeIn:Play() end
		if sweeping then return end
		sweeping = true
		sw.Position = UDim2.new(0, -40, 0, 0)
		sweepTween:Play()
	end)
	btn.MouseLeave:Connect(function()
		if strokeOut then strokeOut:Play() end
	end)
end

UI.GUI = Instance.new("ScreenGui")
UI.GUI.Name = "WelcomeBackUI"
UI.GUI.ResetOnSpawn = false
UI.GUI.IgnoreGuiInset = true
UI.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.GUI.DisplayOrder = 999
UI.GUI.Parent = S.PlayerGui

do
	UI.Main = Instance.new("Frame")
	UI.Main.Name = "Main"
	UI.Main.AnchorPoint = Vector2.new(0.5,0.5)
	UI.Main.Position = UDim2.fromScale(0.5,0.5)
	UI.Main.Size = UDim2.new(0,480,0,300)
	UI.Main.BackgroundColor3 = Color3.fromRGB(10,10,14)
	UI.Main.BorderSizePixel = 0
	UI.Main.ClipsDescendants = true
	UI.Main.Parent = UI.GUI
	Instance.new("UICorner", UI.Main).CornerRadius = UDim.new(0,14)
	local ms = Instance.new("UIStroke", UI.Main)
	ms.Color = Color3.fromRGB(42,42,47); ms.Thickness = 1; ms.Transparency = 0.15
	UI.UIScale = Instance.new("UIScale")
	UI.UIScale.Scale = 1
	UI.UIScale.Parent = UI.Main
end

do
	UI.Top = Instance.new("Frame")
	UI.Top.Name = "Top"
	UI.Top.Size = UDim2.new(1,0,0,46)
	UI.Top.BackgroundTransparency = 1
	UI.Top.Active = true
	UI.Top.Parent = UI.Main
	local tl = Instance.new("Frame")
	tl.Size = UDim2.new(1,0,0,1); tl.Position = UDim2.new(0,0,1,-1)
	tl.BackgroundColor3 = Color3.fromRGB(43,43,48); tl.BorderSizePixel = 0; tl.Parent = UI.Top

	local function MakeMacButton(color, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(14,14); b.Position = UDim2.new(0,x,0,15)
		b.BackgroundColor3 = color; b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0
		b.Parent = UI.Top
		Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.72
		return b
	end
	UI.CloseBtn = MakeMacButton(Color3.fromRGB(245,67,67), 16)
	UI.MinBtn = MakeMacButton(Color3.fromRGB(246,190,45), 38)
	UI.MaxBtn = MakeMacButton(Color3.fromRGB(47,195,87), 60)

	local function MakeClassicButton(text, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(26,26); b.Position = UDim2.new(1,x,0,10)
		b.BackgroundColor3 = Color3.fromRGB(24,24,30); b.Text = text
		b.TextColor3 = Color3.fromRGB(220,220,225); b.TextSize = 14
		b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false; b.Visible = false
		b.Parent = UI.Top
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
		local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(52,52,60)
		return b
	end
	UI.ClassicClose = MakeClassicButton("X", -34)
	UI.ClassicMin = MakeClassicButton("-", -66)

	local tg = Instance.new("Frame")
	tg.AnchorPoint = Vector2.new(0.5,0.5); tg.Position = UDim2.new(0.5,0,0,23)
	tg.Size = UDim2.new(0,140,0,30); tg.BackgroundTransparency = 1; tg.Parent = UI.Top
	local ti = Instance.new("ImageLabel")
	ti.Size = UDim2.fromOffset(28,28); ti.Position = UDim2.new(0,0,0.5,-14)
	ti.BackgroundTransparency = 1; ti.Image = "rbxassetid://119972597178070"; ti.Parent = tg
	local tt = Instance.new("TextLabel")
	tt.Size = UDim2.new(1,-34,1,0); tt.Position = UDim2.new(0,34,0,0)
	tt.BackgroundTransparency = 1; tt.Text = "Panel"; tt.TextXAlignment = Enum.TextXAlignment.Left
	tt.TextColor3 = Color3.fromRGB(225,225,232); tt.TextSize = 16
	tt.Font = Enum.Font.GothamBold; tt.Parent = tg
end

do
	UI.Content = Instance.new("Frame")
	UI.Content.Size = UDim2.new(1,0,1,-46); UI.Content.Position = UDim2.new(0,0,0,46)
	UI.Content.BackgroundTransparency = 1; UI.Content.ClipsDescendants = true
	UI.Content.Parent = UI.Main
end

do
	UI.Login = {}
	UI.Login.Page = Instance.new("ScrollingFrame")
	UI.Login.Page.Name = "Login"
	UI.Login.Page.Size = UDim2.new(1,0,1,0)
	UI.Login.Page.BackgroundTransparency = 1; UI.Login.Page.BorderSizePixel = 0
	UI.Login.Page.ScrollingDirection = Enum.ScrollingDirection.Y
	UI.Login.Page.ScrollingEnabled = true; UI.Login.Page.Active = true
	UI.Login.Page.ScrollBarThickness = 3; UI.Login.Page.ScrollBarImageTransparency = 0.4
	UI.Login.Page.CanvasSize = UDim2.new(0,0,0,320)
	UI.Login.Page.Parent = UI.Content

	local p = Instance.new("ImageLabel")
	p.Size = UDim2.fromOffset(80,80); p.Position = UDim2.new(0.5,-40,0,10)
	p.BackgroundColor3 = Color3.fromRGB(15,35,21); p.ScaleType = Enum.ScaleType.Crop
	p.Parent = UI.Login.Page
	Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)
	local ps = Instance.new("UIStroke", p); ps.Color = UI.ACCENT; ps.Thickness = 3
	UI.Login.Profile = p; UI.Login.ProfileStroke = ps

	local w = Instance.new("TextLabel")
	w.Size = UDim2.fromOffset(460,32); w.Position = UDim2.new(0.5,-230,0,98)
	w.BackgroundTransparency = 1; w.Text = "Welcome Back"
	w.TextColor3 = Color3.fromRGB(245,245,247); w.TextSize = 24
	w.Font = Enum.Font.GothamBold; w.Parent = UI.Login.Page
	UI.Login.Welcome = w

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.fromOffset(460,18); sub.Position = UDim2.new(0.5,-230,0,130)
	sub.BackgroundTransparency = 1; sub.Text = "Enter the password"
	sub.TextColor3 = Color3.fromRGB(125,125,130); sub.TextSize = 12
	sub.Font = Enum.Font.Gotham; sub.Parent = UI.Login.Page
	UI.Login.Subtitle = sub

	local pw = Instance.new("TextBox")
	pw.Size = UDim2.fromOffset(280,38); pw.Position = UDim2.new(0.5,-140,0,158)
	pw.BackgroundColor3 = Color3.fromRGB(17,17,21); pw.Text = ""
	pw.PlaceholderText = "Password"; pw.PlaceholderColor3 = Color3.fromRGB(105,105,112)
	pw.TextColor3 = Color3.fromRGB(240,240,240); pw.TextSize = 14
	pw.Font = Enum.Font.Gotham; pw.ClearTextOnFocus = false
	pw.TextXAlignment = Enum.TextXAlignment.Center; pw.TextStrokeTransparency = 1
	pw.Parent = UI.Login.Page
	Instance.new("UICorner", pw).CornerRadius = UDim.new(0,19)
	local pws = Instance.new("UIStroke", pw); pws.Color = UI.ACCENT; pws.Thickness = 1.5
	UI.Login.Password = pw; UI.Login.PassStroke = pws

	local e = Instance.new("TextButton")
	e.Size = UDim2.fromOffset(280,38); e.Position = UDim2.new(0.5,-140,0,206)
	e.BackgroundColor3 = Color3.fromRGB(16,16,20); e.Text = "Enter"
	e.TextColor3 = Color3.fromRGB(235,235,238); e.TextSize = 15
	e.Font = Enum.Font.GothamBold; e.AutoButtonColor = false
	e.Parent = UI.Login.Page
	Instance.new("UICorner", e).CornerRadius = UDim.new(0,19)
	local es = Instance.new("UIStroke", e); es.Color = UI.ACCENT; es.Thickness = 1.5
	UI.Login.Enter = e; UI.Login.EnterStroke = es

	local err = Instance.new("TextLabel")
	err.Size = UDim2.fromOffset(400,18); err.Position = UDim2.new(0.5,-200,0,252)
	err.BackgroundTransparency = 1; err.Text = ""
	err.TextColor3 = Color3.fromRGB(255,80,80); err.TextSize = 12
	err.Font = Enum.Font.Gotham; err.Parent = UI.Login.Page
	UI.Login.Error = err
end

do
	UI.Pages = {}
	UI.Pages.Container = Instance.new("Frame")
	UI.Pages.Container.Size = UDim2.new(1,0,1,-62)
	UI.Pages.Container.BackgroundTransparency = 1
	UI.Pages.Container.ClipsDescendants = true
	UI.Pages.Container.Visible = false
	UI.Pages.Container.Parent = UI.Content

	local function MakePage(name, canvas)
		local pg = Instance.new("ScrollingFrame")
		pg.Name = name; pg.Size = UDim2.new(1,0,1,0)
		pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0
		pg.ScrollingDirection = Enum.ScrollingDirection.Y
		pg.ScrollingEnabled = true; pg.Active = true
		pg.ScrollBarThickness = 3; pg.ScrollBarImageTransparency = 0.4
		pg.CanvasSize = UDim2.new(0,0,0,canvas); pg.Visible = false
		pg.Parent = UI.Pages.Container
		return pg
	end

	UI.Pages.Home = MakePage("Home", 400)
	UI.Pages.Scripts = MakePage("Scripts", 300)
	UI.Pages.Fling = MakePage("Fling", 400)
	UI.Pages.Skys = MakePage("Skys", 2000)
	UI.Pages.Animations = MakePage("Animations", 800)
	UI.Pages.Settings = MakePage("Settings", 400)
	UI.Pages.Home.Visible = true

	for _, pg in ipairs({UI.Pages.Scripts, UI.Pages.Fling, UI.Pages.Skys, UI.Pages.Animations, UI.Pages.Settings}) do
		pcall(function()
			pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
			pg.CanvasSize = UDim2.new(0,0,0,0)
		end)
	end
end

do
	local hp = UI.Pages.Home
	local bp = Instance.new("ImageLabel")
	bp.Size = UDim2.fromOffset(70,70); bp.Position = UDim2.new(0,20,0,16)
	bp.BackgroundColor3 = Color3.fromRGB(15,15,18); bp.ScaleType = Enum.ScaleType.Crop
	bp.Parent = hp
	Instance.new("UICorner", bp).CornerRadius = UDim.new(1,0)
	local bps = Instance.new("UIStroke", bp); bps.Color = UI.ACCENT; bps.Thickness = 3
	UI.Home_BigProfile = bp

	local od = Instance.new("Frame")
	od.Size = UDim2.fromOffset(22,22); od.Position = UDim2.new(1,-16,1,-16)
	od.BackgroundColor3 = UI.ACCENT; od.BorderSizePixel = 0; od.ZIndex = 5; od.Parent = bp
	Instance.new("UICorner", od).CornerRadius = UDim.new(1,0)
	local ods = Instance.new("UIStroke", od); ods.Color = Color3.fromRGB(10,10,14); ods.Thickness = 3

	local un = Instance.new("TextLabel")
	un.Size = UDim2.new(1,-110,0,28); un.Position = UDim2.new(0,100,0,18)
	un.BackgroundTransparency = 1; un.Text = ""
	un.TextXAlignment = Enum.TextXAlignment.Left; un.TextTruncate = Enum.TextTruncate.AtEnd
	un.TextColor3 = Color3.fromRGB(245,245,247); un.TextSize = 19
	un.Font = Enum.Font.GothamBold; un.Parent = hp
	UI.Home_UserName = un

	local st = Instance.new("TextLabel")
	st.Size = UDim2.new(1,-110,0,18); st.Position = UDim2.new(0,100,0,46)
	st.BackgroundTransparency = 1; st.Text = "Online"
	st.TextXAlignment = Enum.TextXAlignment.Left; st.TextColor3 = UI.ACCENT
	st.TextSize = 12; st.Font = Enum.Font.Gotham; st.Parent = hp
	UI.Home_Status = st

	local rk = Instance.new("TextLabel")
	rk.Size = UDim2.new(1,-110,0,18); rk.Position = UDim2.new(0,100,0,64)
	rk.BackgroundTransparency = 1; rk.Text = ""
	rk.TextXAlignment = Enum.TextXAlignment.Left; rk.TextSize = 12
	rk.Font = Enum.Font.GothamBold; rk.Visible = false; rk.Parent = hp
	UI.Home_Rank = rk

	local mut = Instance.new("TextLabel")
	mut.Size = UDim2.new(1,-70,0,20); mut.Position = UDim2.new(0,20,0,100)
	mut.BackgroundTransparency = 1; mut.Text = "Favorite Scripts"
	mut.TextXAlignment = Enum.TextXAlignment.Left; mut.TextColor3 = Color3.fromRGB(245,245,247)
	mut.TextSize = 14; mut.Font = Enum.Font.GothamBold; mut.Parent = hp
	local mus = Instance.new("ImageLabel")
	mus.Size = UDim2.fromOffset(14,14); mus.Position = UDim2.new(1,-34,0,103)
	mus.BackgroundTransparency = 1; mus.Image = "rbxassetid://6031091004"
	mus.ImageColor3 = Color3.fromRGB(150,150,158); mus.Parent = hp

	local mul = Instance.new("Frame")
	mul.Size = UDim2.new(1,-40,0,0); mul.Position = UDim2.new(0,20,0,128)
	mul.BackgroundTransparency = 1; mul.AutomaticSize = Enum.AutomaticSize.Y; mul.Parent = hp
	UI.Home_MostUsedList = mul
	local mulLayout = Instance.new("UIListLayout", mul)
	mulLayout.Padding = UDim.new(0,4); mulLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UI.Home_MostUsedLayout = mulLayout
end

do
	local sp = UI.Pages.Scripts
	local st = Instance.new("TextLabel")
	st.Size = UDim2.new(1,-40,0,26); st.Position = UDim2.new(0,20,0,12)
	st.BackgroundTransparency = 1; st.Text = "Scripts"
	st.TextXAlignment = Enum.TextXAlignment.Left; st.TextColor3 = Color3.fromRGB(245,245,247)
	st.TextSize = 20; st.Font = Enum.Font.GothamBold; st.Parent = sp

	local ss = Instance.new("TextBox")
	ss.Size = UDim2.new(1,-40,0,32); ss.Position = UDim2.new(0,20,0,44)
	ss.BackgroundColor3 = Color3.fromRGB(18,18,23)
	ss.PlaceholderText = "Search scripts..."; ss.PlaceholderColor3 = Color3.fromRGB(105,105,112)
	ss.Text = ""; ss.TextColor3 = Color3.fromRGB(240,240,240); ss.TextSize = 12
	ss.Font = Enum.Font.Gotham; ss.TextXAlignment = Enum.TextXAlignment.Left
	ss.ClearTextOnFocus = false; ss.TextStrokeTransparency = 1; ss.Parent = sp
	Instance.new("UICorner", ss).CornerRadius = UDim.new(0,10)
	local sss = Instance.new("UIStroke", ss); sss.Color = Color3.fromRGB(52,52,60)
	local ssp = Instance.new("UIPadding", ss); ssp.PaddingLeft = UDim.new(0,32)
	local ssi = Instance.new("ImageLabel")
	ssi.Size = UDim2.fromOffset(14,14); ssi.Position = UDim2.new(0,10,0.5,-7)
	ssi.BackgroundTransparency = 1; ssi.Image = "rbxassetid://6031091004"
	ssi.ImageColor3 = Color3.fromRGB(150,150,158); ssi.ZIndex = 3; ssi.Parent = ss
	UI.Scripts_Search = ss

	local sr = Instance.new("Frame")
	sr.Size = UDim2.new(1,-40,0,36); sr.Position = UDim2.new(0,20,0,84)
	sr.BackgroundTransparency = 1; sr.Parent = sp
	local srl = Instance.new("UIListLayout", sr)
	srl.FillDirection = Enum.FillDirection.Horizontal; srl.Padding = UDim.new(0,6)
	UI.Scripts_Row = sr

	local sc = Instance.new("Frame")
	sc.Size = UDim2.new(1,-40,0,0); sc.Position = UDim2.new(0,20,0,130)
	sc.BackgroundTransparency = 1; sc.AutomaticSize = Enum.AutomaticSize.Y; sc.Parent = sp
	UI.Scripts_Content = sc

	local function MakeTabContent(name)
		local f = Instance.new("Frame")
		f.Name = name; f.Size = UDim2.new(1,0,0,0)
		f.AutomaticSize = Enum.AutomaticSize.Y; f.BackgroundTransparency = 1
		f.Visible = false; f.Parent = sc
		local lay = Instance.new("UIListLayout", f)
		lay.Padding = UDim.new(0,6); lay.SortOrder = Enum.SortOrder.LayoutOrder
		local pad = Instance.new("UIPadding", f)
		pad.PaddingTop = UDim.new(0,2); pad.PaddingBottom = UDim.new(0,2)
		return f
	end
	UI.Tabs = {}
	UI.Tabs.MainScript = MakeTabContent("MainScript")
	UI.Tabs.Extra = MakeTabContent("Extra")
end

do
	local ft = Instance.new("TextLabel")
	ft.Size = UDim2.new(1,-40,0,26); ft.Position = UDim2.new(0,20,0,12)
	ft.BackgroundTransparency = 1; ft.Text = "Fling Players"
	ft.TextXAlignment = Enum.TextXAlignment.Left; ft.TextColor3 = Color3.fromRGB(245,245,247)
	ft.TextSize = 20; ft.Font = Enum.Font.GothamBold; ft.Parent = UI.Pages.Fling

	local skt = Instance.new("TextLabel")
	skt.Size = UDim2.new(1,-40,0,26); skt.Position = UDim2.new(0,20,0,12)
	skt.BackgroundTransparency = 1; skt.Text = "Skys"
	skt.TextXAlignment = Enum.TextXAlignment.Left; skt.TextColor3 = Color3.fromRGB(245,245,247)
	skt.TextSize = 20; skt.Font = Enum.Font.GothamBold; skt.Parent = UI.Pages.Skys

	local sett = Instance.new("TextLabel")
	sett.Size = UDim2.new(1,-40,0,26); sett.Position = UDim2.new(0,20,0,12)
	sett.BackgroundTransparency = 1; sett.Text = "Settings"
	sett.TextXAlignment = Enum.TextXAlignment.Left; sett.TextColor3 = Color3.fromRGB(245,245,247)
	sett.TextSize = 20; sett.Font = Enum.Font.GothamBold; sett.Parent = UI.Pages.Settings

	local sl = Instance.new("TextLabel")
	sl.Size = UDim2.new(1,-40,0,16); sl.Position = UDim2.new(0,20,0,46)
	sl.BackgroundTransparency = 1; sl.Text = "Estilo de botones"
	sl.TextXAlignment = Enum.TextXAlignment.Left; sl.TextColor3 = Color3.fromRGB(180,180,188)
	sl.TextSize = 11; sl.Font = Enum.Font.Gotham; sl.Parent = UI.Pages.Settings

	local str = Instance.new("Frame")
	str.Size = UDim2.new(1,-40,0,40); str.Position = UDim2.new(0,20,0,66)
	str.BackgroundColor3 = Color3.fromRGB(18,18,23); str.BorderSizePixel = 0; str.Parent = UI.Pages.Settings
	Instance.new("UICorner", str).CornerRadius = UDim.new(0,12)
	local strs = Instance.new("UIStroke", str); strs.Color = Color3.fromRGB(50,50,58)

	local function MakeStyleOption(text, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.5,-8,1,-10); b.Position = UDim2.new(x,4,0,5)
		b.BackgroundColor3 = Color3.fromRGB(30,30,36); b.Text = text
		b.TextColor3 = Color3.fromRGB(200,200,208); b.TextSize = 12
		b.Font = Enum.Font.GothamMedium; b.AutoButtonColor = false; b.Parent = str
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
		local ss = Instance.new("UIStroke", b)
		ss.Color = Color3.fromRGB(255,255,255); ss.Thickness = 1; ss.Transparency = 0.82
		ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		task.defer(function() AddButtonSweep(b, ss) end)
		return b
	end
	UI.Settings_NewOpt = MakeStyleOption("New", 0)
	UI.Settings_ClassicOpt = MakeStyleOption("Classic", 0.5)

	local kl = Instance.new("TextLabel")
	kl.Size = UDim2.new(1,-40,0,16); kl.Position = UDim2.new(0,20,0,120)
	kl.BackgroundTransparency = 1; kl.Text = "Tecla para minimizar"
	kl.TextXAlignment = Enum.TextXAlignment.Left; kl.TextColor3 = Color3.fromRGB(180,180,188)
	kl.TextSize = 11; kl.Font = Enum.Font.Gotham; kl.Parent = UI.Pages.Settings

	local kr = Instance.new("Frame")
	kr.Size = UDim2.new(1,-40,0,40); kr.Position = UDim2.new(0,20,0,142)
	kr.BackgroundColor3 = Color3.fromRGB(18,18,23); kr.BorderSizePixel = 0; kr.Parent = UI.Pages.Settings
	Instance.new("UICorner", kr).CornerRadius = UDim.new(0,12)
	local krs = Instance.new("UIStroke", kr); krs.Color = Color3.fromRGB(50,50,58)
	local kb = Instance.new("TextButton")
	kb.Size = UDim2.new(1,-20,1,-10); kb.Position = UDim2.new(0,10,0,5)
	kb.BackgroundColor3 = Color3.fromRGB(28,28,35); kb.Text = "M"
	kb.TextColor3 = Color3.fromRGB(225,225,232); kb.TextSize = 12
	kb.Font = Enum.Font.GothamBold; kb.AutoButtonColor = false; kb.Parent = kr
	Instance.new("UICorner", kb).CornerRadius = UDim.new(0,8)
	local kbs = Instance.new("UIStroke", kb)
	kbs.Color = Color3.fromRGB(255,255,255); kbs.Thickness = 1; kbs.Transparency = 0.82
	kbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UI.KeybindBtn = kb
end

do
	UI.Bottom = Instance.new("Frame")
	UI.Bottom.Size = UDim2.fromOffset(460,54); UI.Bottom.Position = UDim2.new(0.5,-230,1,-60)
	UI.Bottom.BackgroundColor3 = Color3.fromRGB(18,18,22); UI.Bottom.BorderSizePixel = 0
	UI.Bottom.Visible = false; UI.Bottom.Parent = UI.Content
	Instance.new("UICorner", UI.Bottom).CornerRadius = UDim.new(0,27)
	local bs = Instance.new("UIStroke", UI.Bottom); bs.Color = Color3.fromRGB(45,45,50)

	UI.NavPill = Instance.new("Frame")
	UI.NavPill.Size = UDim2.fromOffset(76,46); UI.NavPill.Position = UDim2.new(0,2,0,4)
	UI.NavPill.BackgroundColor3 = Color3.fromRGB(255,255,255); UI.NavPill.BackgroundTransparency = 0.88
	UI.NavPill.BorderSizePixel = 0; UI.NavPill.ZIndex = 2; UI.NavPill.Parent = UI.Bottom
	Instance.new("UICorner", UI.NavPill).CornerRadius = UDim.new(1,0)

	local function MakeNavButton(imageId, label, x, w)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(w,46); b.Position = UDim2.new(0,x,0,4)
		b.BackgroundTransparency = 1; b.Text = ""; b.AutoButtonColor = false
		b.ZIndex = 4; b.Parent = UI.Bottom
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
		local ic = Instance.new("ImageLabel")
		ic.Size = UDim2.fromOffset(22,22); ic.Position = UDim2.new(0.5,-11,0,6)
		ic.BackgroundTransparency = 1; ic.Image = "rbxassetid://"..imageId; ic.ZIndex = 7; ic.Parent = b
		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.new(1,0,0,14); lb.Position = UDim2.new(0,0,0,30)
		lb.BackgroundTransparency = 1; lb.Text = label
		lb.TextXAlignment = Enum.TextXAlignment.Center; lb.TextColor3 = Color3.fromRGB(180,180,190)
		lb.TextSize = 10; lb.Font = Enum.Font.GothamMedium; lb.ZIndex = 7; lb.Parent = b
		return b
	end
	UI.NavHome = MakeNavButton("135130950196086", "Home", 2, 76)
	UI.NavScripts = MakeNavButton("79949598410209", "Scripts", 78, 76)
	UI.NavFling = MakeNavButton("101363781360377", "Fling", 154, 76)
	UI.NavSkys = MakeNavButton("107588676615037", "Skys", 230, 76)
	UI.NavAnims = MakeNavButton("135130950196086", "Anims", 306, 76)
	UI.NavSettings = MakeNavButton("114349145444051", "Settings", 382, 76)

	local wm = Instance.new("TextLabel")
	wm.Size = UDim2.new(1,-20,0,14); wm.Position = UDim2.new(0,10,1,-72)
	wm.BackgroundTransparency = 1; wm.Text = "Panel creado por Sam"
	wm.TextXAlignment = Enum.TextXAlignment.Center; wm.TextColor3 = Color3.fromRGB(110,110,118)
	wm.TextSize = 10; wm.Font = Enum.Font.Gotham; wm.TextTransparency = 0.4
	wm.ZIndex = 15; wm.Parent = UI.Content
end

do
	local r = Instance.new("TextButton")
	r.Size = UDim2.fromOffset(52,52); r.Position = UDim2.new(0,16,1,-68)
	r.BackgroundColor3 = Color3.fromRGB(255,255,255); r.Text = ""
	r.AutoButtonColor = false; r.Visible = false; r.Active = true; r.Parent = UI.GUI
	Instance.new("UICorner", r).CornerRadius = UDim.new(1,0)
	local rs = Instance.new("UIStroke", r); rs.Color = Color3.fromRGB(220,220,220)
	local ri = Instance.new("ImageLabel")
	ri.Size = UDim2.new(1,-16,1,-16); ri.Position = UDim2.new(0,8,0,8)
	ri.BackgroundTransparency = 1; ri.Image = "rbxassetid://92472718379692"; ri.Parent = r
	UI.Reopen = r
	UI.ReopenPos = UDim2.new(0,16,1,-68)
end

task.spawn(function()
	while not FontReady do task.wait(0.1) end
	local desc = UI.GUI:GetDescendants()
	for i = 1, #desc do ApplyFont(desc[i]) end
	UI.GUI.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			if MatchaFont then pcall(function() obj.FontFace = MatchaFont end) end
		end
	end)
end)

local State = {
	buttonStyle = "New",
	activeTab = nil,
	activePill = nil,
	unlocked = false,
	minimized = false,
	isMaximized = false,
	animating = false,
	currentPageName = "Home",
	CurrentKey = Enum.KeyCode.M,
	listening = false,
	NormalSize = UDim2.new(0,480,0,300),
	NormalPosition = UDim2.fromScale(0.5,0.5),
	PreMaxSize = nil,
	PreMaxPos = nil,
}
local OnLoginCallbacks = {}

local function RefreshMostUsed()
	local MostUsedList = UI.Home_MostUsedList
	local mul = UI.Home_MostUsedLayout
	for _, c in ipairs(MostUsedList:GetChildren()) do if c ~= mul then c:Destroy() end end
	local sorted = {}
	for k, v in pairs(ToggleUsage) do
		if ToggleRegistry[k] and v > 0 then table.insert(sorted, {name=k, count=v}) end
	end
	table.sort(sorted, function(a,b)
		if a.count == b.count then return a.name < b.name end
		return a.count > b.count
	end)
	if #sorted == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,0,0,20); lbl.BackgroundTransparency = 1
		lbl.Text = "Sin datos de uso aún"; lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(120,120,128); lbl.TextSize = 11
		lbl.Font = Enum.Font.Gotham; lbl.LayoutOrder = 1; lbl.Parent = MostUsedList
		return
	end
	local limit = math.min(5, #sorted)
	for i = 1, limit do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1,0,0,30); entry.BackgroundColor3 = Color3.fromRGB(18,18,23)
		entry.BorderSizePixel = 0; entry.LayoutOrder = i; entry.Parent = MostUsedList
		Instance.new("UICorner", entry).CornerRadius = UDim.new(0,8)
		local num = Instance.new("TextLabel")
		num.Size = UDim2.fromOffset(20,20); num.Position = UDim2.new(0,4,0.5,-10)
		num.BackgroundColor3 = UI.ACCENT; num.Text = tostring(i)
		num.TextColor3 = Color3.fromRGB(20,20,24); num.TextSize = 11
		num.Font = Enum.Font.GothamBold; num.Parent = entry
		Instance.new("UICorner", num).CornerRadius = UDim.new(1,0)
		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1,-90,1,0); nm.Position = UDim2.new(0,30,0,0)
		nm.BackgroundTransparency = 1; nm.Text = sorted[i].name
		nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextColor3 = Color3.fromRGB(225,225,232); nm.TextSize = 11
		nm.Font = Enum.Font.GothamMedium; nm.Parent = entry
		local registry = ToggleRegistry[sorted[i].name]
		local msw = Instance.new("Frame")
		msw.Size = UDim2.fromOffset(32,18); msw.Position = UDim2.new(1,-40,0.5,-9)
		msw.BackgroundColor3 = Color3.fromRGB(70,70,78); msw.BorderSizePixel = 0; msw.Parent = entry
		Instance.new("UICorner", msw).CornerRadius = UDim.new(1,0)
		local msknob = Instance.new("Frame")
		msknob.Size = UDim2.fromOffset(14,14); msknob.Position = UDim2.fromOffset(2,2)
		msknob.BackgroundColor3 = Color3.fromRGB(240,240,245); msknob.Parent = msw
		Instance.new("UICorner", msknob).CornerRadius = UDim.new(1,0)
		local msc = Instance.new("TextButton")
		msc.Size = UDim2.new(1,0,1,0); msc.BackgroundTransparency = 1; msc.Text = ""
		msc.ZIndex = 3; msc.Parent = entry
		local function updateMSVisual(v)
			msw.BackgroundColor3 = v and UI.ACCENT or Color3.fromRGB(70,70,78)
			S.Tween:Create(msknob, TweenInfo.new(0.15), {Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.fromOffset(2,2)}):Play()
		end
		if registry then
			updateMSVisual(registry.getActive())
			msc.MouseButton1Click:Connect(function() registry.setActive(not registry.getActive()) end)
			if registry.listeners then
				local listener = function(v) if entry.Parent then updateMSVisual(v) end end
				table.insert(registry.listeners, listener)
				entry.Destroying:Connect(function()
					if not registry.listeners then return end
					local idx = table.find(registry.listeners, listener)
					if idx then table.remove(registry.listeners, idx) end
				end)
			end
		end
	end
end

local function cleanGuis(names)
	if not names then return end
	local function scan(parent)
		for _, gui in ipairs(parent:GetChildren()) do
			for _, n in ipairs(names) do
				if gui.Name == n or gui.Name:lower():find(n:lower(),1,true) then pcall(function() gui:Destroy() end) end
			end
		end
	end
	scan(S.PlayerGui)
	scan(S.CoreGui)
end

local KNOB_ON = UDim2.new(1,-18,0.5,-8)
local KNOB_OFF = UDim2.fromOffset(2,2)
local TOGGLE_INFO = TweenInfo.new(0.15)

local function CreateToggle(parent, text, callback, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,0,36); btn.BackgroundColor3 = Color3.fromRGB(20,20,26)
	btn.Text = ""; btn.AutoButtonColor = false
	btn.LayoutOrder = order or 1; btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness = 1
	stroke.Transparency = 0.82; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-70,1,0); label.Position = UDim2.new(0,14,0,0)
	label.BackgroundTransparency = 1; label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left; label.TextColor3 = Color3.fromRGB(225,225,232)
	label.TextSize = 12; label.Font = Enum.Font.GothamBold; label.ZIndex = 7; label.Parent = btn
	local sw = Instance.new("Frame")
	sw.Size = UDim2.fromOffset(36,20); sw.Position = UDim2.new(1,-48,0.5,-10)
	sw.BackgroundColor3 = Color3.fromRGB(70,70,78); sw.ZIndex = 7; sw.Parent = btn
	Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16,16); knob.Position = KNOB_OFF
	knob.BackgroundColor3 = Color3.fromRGB(240,240,245); knob.ZIndex = 8; knob.Parent = sw
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

	local active = false
	local listeners = {}
	local function setVisual(v)
		sw.BackgroundColor3 = v and UI.ACCENT or Color3.fromRGB(70,70,78)
		S.Tween:Create(knob, TOGGLE_INFO, {Position = v and KNOB_ON or KNOB_OFF}):Play()
		local n = #listeners
		for i = 1, n do pcall(listeners[i], v) end
	end
	local function registerUsage()
		ToggleUsage[text] = (ToggleUsage[text] or 0) + 1
		Storage.SaveUsage(ToggleUsage)
	end
	btn.MouseButton1Click:Connect(function()
		if not active then
			local canActivate, blocker = CanActivate(text)
			if not canActivate then
				ShowNotif("No se puede activar", "Desactiva primero: " .. blocker, 3)
				return
			end
			active = true; registerUsage(); SetExclusiveActive(text)
		else
			active = false; ClearExclusiveActive(text)
		end
		setVisual(active); pcall(callback, active)
	end)
	ToggleRegistry[text] = {
		getActive = function() return active end,
		setActive = function(v)
			if v == active then return end
			if v then
				local canActivate = CanActivate(text)
				if not canActivate then return end
			end
			active = v
			if active then registerUsage() SetExclusiveActive(text) else ClearExclusiveActive(text) end
			setVisual(active); pcall(callback, active)
		end,
		listeners = listeners,
	}
	table.insert(AllToggles, {btn=btn, label=label, text=text, parent=parent})
	task.defer(function() AddButtonSweep(btn, stroke) end)
	return btn
end

do
	local function MakeScriptPill(text, order)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(150,36); b.BackgroundColor3 = Color3.fromRGB(20,20,26)
		b.Text = text; b.TextColor3 = Color3.fromRGB(225,225,232); b.TextSize = 13
		b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false
		b.LayoutOrder = order; b.Parent = UI.Scripts_Row
		Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255,255,255); s.Thickness = 1
		s.Transparency = 0.82; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		task.defer(function() AddButtonSweep(b, s) end)
		return b
	end
	UI.Scripts_BtnMain = MakeScriptPill("Script", 1)
	UI.Scripts_BtnExtra = MakeScriptPill("Extra", 2)

	local function SelectTab(tab, pill)
		if State.activeTab == tab then return end
		if State.activeTab then
			local oldTab, oldPill = State.activeTab, State.activePill
			S.Tween:Create(oldTab, TweenInfo.new(0.18), {Position=UDim2.new(-0.15,0,0,0)}):Play()
			if oldPill then
				S.Tween:Create(oldPill, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20,20,26), TextColor3 = Color3.fromRGB(225,225,232)}):Play()
				local ps = oldPill:FindFirstChildOfClass("UIStroke")
				if ps then S.Tween:Create(ps, TweenInfo.new(0.18), {Color=Color3.fromRGB(255,255,255), Transparency = 0.82}):Play() end
			end
			task.delay(0.18, function()
				if oldTab then oldTab.Visible = false oldTab.Position = UDim2.new(0,0,0,0) end
			end)
		end
		State.activeTab, State.activePill = tab, pill
		tab.Visible = true; tab.Position = UDim2.new(0.15,0,0,0)
		S.Tween:Create(tab, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play()
		S.Tween:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = UI.ACCENT:Lerp(Color3.new(0,0,0),0.7), TextColor3 = UI.ACCENT:Lerp(Color3.new(1,1,1),0.5)}):Play()
		local ps = pill:FindFirstChildOfClass("UIStroke")
		if ps then S.Tween:Create(ps, TweenInfo.new(0.18), {Color=UI.ACCENT, Transparency = 0.2}):Play() end
	end
	UI.SelectTab = SelectTab

	UI.Scripts_BtnMain.MouseButton1Click:Connect(function() SelectTab(UI.Tabs.MainScript, UI.Scripts_BtnMain) end)
	UI.Scripts_BtnExtra.MouseButton1Click:Connect(function() SelectTab(UI.Tabs.Extra, UI.Scripts_BtnExtra) end)
end

local searchJob
UI.Scripts_Search:GetPropertyChangedSignal("Text"):Connect(function()
	if searchJob then task.cancel(searchJob) end
	searchJob = task.delay(0.12, function()
		searchJob = nil
		local q = UI.Scripts_Search.Text:lower()
		if q == "" then
			for i = 1, #AllToggles do AllToggles[i].btn.Visible = true end
		else
			for i = 1, #AllToggles do
				local entry = AllToggles[i]
				entry.btn.Visible = entry.text:lower():find(q,1,true) ~= nil
			end
		end
	end)
end)

local function LoginSuccess()
	if State.unlocked then return end
	State.unlocked = true
	local FadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function Fade(o,p,t) S.Tween:Create(o, FadeInfo, {[p]=t}):Play() end
	Fade(UI.Login.Profile, "ImageTransparency", 1)
	Fade(UI.Login.Profile, "BackgroundTransparency", 1)
	Fade(UI.Login.ProfileStroke, "Transparency", 1)
	Fade(UI.Login.Welcome, "TextTransparency", 1)
	Fade(UI.Login.Subtitle, "TextTransparency", 1)
	Fade(UI.Login.Password, "BackgroundTransparency", 1)
	Fade(UI.Login.Password, "TextTransparency", 1)
	Fade(UI.Login.PassStroke, "Transparency", 1)
	Fade(UI.Login.Enter, "BackgroundTransparency", 1)
	Fade(UI.Login.Enter, "TextTransparency", 1)
	Fade(UI.Login.EnterStroke, "Transparency", 1)
	Fade(UI.Login.Error, "TextTransparency", 1)
	task.wait(0.32)
	UI.Login.Page.Visible = false
	UI.Home_UserName.Text = "@"..S.Player.Name
	local r = getRank(S.Player.Name)
	if r then
		UI.Home_Rank.Text = r
		if r == "OWNER" then UI.Home_Rank.TextColor3 = Color3.fromRGB(255,80,80)
		elseif r == "TESTER" then UI.Home_Rank.TextColor3 = Color3.fromRGB(0,80,255)
		else UI.Home_Rank.TextColor3 = UI.ACCENT end
		UI.Home_Rank.Visible = true
	end
	UI.Pages.Container.Visible = true
	UI.Bottom.Visible = true
	UI.Pages.Home.Visible = true
	UI.Pages.Scripts.Visible = false
	UI.Pages.Fling.Visible = false
	UI.Pages.Skys.Visible = false
	UI.Pages.Animations.Visible = false
	UI.Pages.Settings.Visible = false
	State.currentPageName = "Home"
	for _, p in pairs(UI.Pages) do
		if p ~= UI.Pages.Container then p.CanvasPosition = Vector2.new(0,0) end
	end
	UI.Login.Page.CanvasPosition = Vector2.new(0,0)
	if not State.activeTab then UI.SelectTab(UI.Tabs.MainScript, UI.Scripts_BtnMain) end
	UI.Home_BigProfile.ImageTransparency = 1
	UI.Home_UserName.TextTransparency = 1
	UI.Home_Status.TextTransparency = 1
	UI.Home_Rank.TextTransparency = 1
	for _, o in ipairs({UI.Home_BigProfile, UI.Home_UserName, UI.Home_Status, UI.Home_Rank}) do
		local props = {}
		if o:IsA("TextLabel") then props.TextTransparency = 0 else props.ImageTransparency = 0 end
		S.Tween:Create(o, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
	end
	task.defer(function() pcall(RefreshMostUsed) end)
	for _, fn in ipairs(OnLoginCallbacks) do
		task.spawn(function() pcall(fn) end)
	end
end

local function TryLogin()
	if State.unlocked then return end
	if not isWhitelisted(S.Player.Name) then UI.Login.Error.Text = "No estás en la whitelist" return end
	if UI.Login.Password.Text == "sam2027" then
		UI.Login.Error.Text = ""
		Storage.SaveSession()
		LoginSuccess()
	else
		UI.Login.Error.Text = "Contraseña incorrecta"
		local orig = UI.Login.Password.Position
		local T1 = S.Tween:Create(UI.Login.Password, TweenInfo.new(0.05), {Position=orig+UDim2.fromOffset(7,0)})
		local T2 = S.Tween:Create(UI.Login.Password, TweenInfo.new(0.05), {Position=orig-UDim2.fromOffset(7,0)})
		T1:Play(); T1.Completed:Wait()
		T2:Play(); T2.Completed:Wait()
		UI.Login.Password.Position = orig
		UI.Login.Password.Text = ""
	end
end
UI.Login.Enter.MouseButton1Click:Connect(TryLogin)
UI.Login.Password.FocusLost:Connect(function(e) if e then TryLogin() end end)

UI.KeybindBtn.MouseButton1Click:Connect(function()
	if State.listening then return end
	State.listening = true
	UI.KeybindBtn.Text = "Presiona una tecla..."
	UI.KeybindBtn.TextColor3 = UI.ACCENT
end)

local dragMode = nil
local dragStartInput, dragStartPos
local reopenMoved = false

S.Input.InputChanged:Connect(function(input)
	if not dragMode then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
	local delta = input.Position - dragStartInput
	if dragMode == "main" then
		UI.Main.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+delta.Y)
		if not State.isMaximized then State.NormalPosition = UI.Main.Position end
	else
		if not reopenMoved and (math.abs(delta.X) > 3 or math.abs(delta.Y) > 3) then reopenMoved = true end
		local newPos = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+delta.Y)
		UI.Reopen.Position = newPos
		UI.ReopenPos = newPos
	end
end)

S.PlayerGui = UI.GUI

local UpdateButtonStyle
UpdateButtonStyle = function()
	if State.buttonStyle == "New" then
		UI.CloseBtn.Visible = true; UI.MinBtn.Visible = true; UI.MaxBtn.Visible = true
		UI.ClassicClose.Visible = false; UI.ClassicMin.Visible = false
		S.Tween:Create(UI.Settings_NewOpt, TweenInfo.new(0.2), {BackgroundColor3=UI.ACCENT, TextColor3=Color3.fromRGB(20,20,24)}):Play()
		S.Tween:Create(UI.Settings_ClassicOpt, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,36), TextColor3=Color3.fromRGB(200,200,208)}):Play()
	else
		UI.CloseBtn.Visible = false; UI.MinBtn.Visible = false; UI.MaxBtn.Visible = false
		UI.ClassicClose.Visible = true; UI.ClassicMin.Visible = true
		S.Tween:Create(UI.Settings_ClassicOpt, TweenInfo.new(0.2), {BackgroundColor3=UI.ACCENT, TextColor3=Color3.fromRGB(20,20,24)}):Play()
		S.Tween:Create(UI.Settings_NewOpt, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,36), TextColor3=Color3.fromRGB(200,200,208)}):Play()
	end
end
UpdateButtonStyle()
UI.Settings_NewOpt.MouseButton1Click:Connect(function() State.buttonStyle = "New" UpdateButtonStyle() end)
UI.Settings_ClassicOpt.MouseButton1Click:Connect(function() State.buttonStyle = "Classic" UpdateButtonStyle() end)

local function UpdateDeviceSize()
	local cam = workspace.CurrentCamera
	if not cam then UI.UIScale.Scale = 1 return end
	local vp = cam.ViewportSize
	if not vp or vp.X < 100 or vp.Y < 100 then UI.UIScale.Scale = 1 return end
	if State.isMaximized then
		UI.Main.Size = UDim2.fromOffset(math.max(vp.X - 30, 480), math.max(vp.Y - 30, 300))
		UI.UIScale.Scale = 1
		return
	end
	UI.Main.Size = UDim2.new(0,480,0,300)
	local s = math.min((vp.X-20)/480, (vp.Y-40)/300)
	s = math.clamp(s, 0.5, 1)
	UI.UIScale.Scale = s
	if not State.minimized then
		State.NormalSize = UI.Main.Size
		State.NormalPosition = UI.Main.Position
	end
end
UpdateDeviceSize()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() pcall(UpdateDeviceSize) end)
end

task.spawn(function()
	local ok, img = pcall(function()
		return S.Players:GetUserThumbnailAsync(S.Player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
	end)
	if ok and img then
		UI.Login.Profile.Image = img
		UI.Home_BigProfile.Image = img
	end
end)

local MY_RANK = getRank(S.Player.Name)
local rankAnimating = (MY_RANK == "OWNER" or MY_RANK == "TESTER")
local rankAccum = 0
S.Run.Heartbeat:Connect(function(dt)
	if not rankAnimating then return end
	if not UI.Home_Rank.Visible then return end
	rankAccum += dt
	if rankAccum < 0.05 then return end
	rankAccum = 0
	if MY_RANK == "OWNER" then
		UI.Home_Rank.TextColor3 = Color3.fromHSV((os.clock() * 0.25) % 1, 1, 1)
	else
		local t = (os.clock() * 0.5) % 1
		local blue = Color3.fromRGB(0,80,255)
		local red = Color3.fromRGB(255,0,0)
		if t < 0.5 then UI.Home_Rank.TextColor3 = blue:Lerp(red, t*2)
		else UI.Home_Rank.TextColor3 = red:Lerp(blue, (t-0.5)*2) end
	end
end)

local PageMap = {Home=UI.Pages.Home, Scripts=UI.Pages.Scripts, Fling=UI.Pages.Fling, Skys=UI.Pages.Skys, Animations=UI.Pages.Animations, Settings=UI.Pages.Settings}
local function ResetScroll()
	for _, p in pairs(PageMap) do p.CanvasPosition = Vector2.new(0,0) end
	UI.Login.Page.CanvasPosition = Vector2.new(0,0)
end
local function SwitchPage(target, fromRight)
	if State.animating or State.currentPageName == target or not State.unlocked then return end
	local FromPage = PageMap[State.currentPageName]
	local ToPage = PageMap[target]
	if not FromPage or not ToPage then return end
	State.animating = true
	local Dir = fromRight and 1 or -1
	local Info = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	ToPage.Position = UDim2.new(Dir,0,0,0); ToPage.Visible = true
	S.Tween:Create(FromPage, Info, {Position=UDim2.new(-Dir,0,0,0)}):Play()
	S.Tween:Create(ToPage, Info, {Position=UDim2.new(0,0,0,0)}):Play()
	task.wait(0.15)
	FromPage.Visible = false; FromPage.Position = UDim2.new(0,0,0,0)
	State.currentPageName = target; State.animating = false
	ResetScroll()
end
UI.SwitchPage = SwitchPage

local PILL_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function MoveNavPill(x, w)
	S.Tween:Create(UI.NavPill, PILL_INFO, {Position = UDim2.new(0, x, 0, 4), Size = UDim2.fromOffset(w, 46)}):Play()
end
UI.NavHome.MouseButton1Click:Connect(function() SwitchPage("Home", false) MoveNavPill(2, 76) end)
UI.NavScripts.MouseButton1Click:Connect(function() SwitchPage("Scripts", true) MoveNavPill(78, 76) end)
UI.NavFling.MouseButton1Click:Connect(function() SwitchPage("Fling", true) MoveNavPill(154, 76) end)
UI.NavSkys.MouseButton1Click:Connect(function() SwitchPage("Skys", true) MoveNavPill(230, 76) end)
UI.NavAnims.MouseButton1Click:Connect(function() SwitchPage("Animations", true) MoveNavPill(306, 76) end)
UI.NavSettings.MouseButton1Click:Connect(function() SwitchPage("Settings", true) MoveNavPill(382, 76) end)

UI.CloseBtn.MouseButton1Click:Connect(function() UI.GUI:Destroy() end)
UI.ClassicClose.MouseButton1Click:Connect(function() UI.GUI:Destroy() end)

local restoring = false
local MIN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local MIN_REOPEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RESTORE_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function Minimize()
	if State.minimized then return end
	if restoring then return end
	State.minimized = true
	State.NormalSize = UI.Main.Size
	State.NormalPosition = UI.Main.Position
	S.Tween:Create(UI.UIScale, MIN_INFO, {Scale=0}):Play()
	task.wait(0.32)
	UI.Main.Visible = false
	UI.Reopen.Visible = true
	UI.Reopen.Size = UDim2.fromOffset(0,0)
	UI.Reopen.Position = UDim2.new(UI.ReopenPos.X.Scale, UI.ReopenPos.X.Offset+26, UI.ReopenPos.Y.Scale, UI.ReopenPos.Y.Offset-10)
	S.Tween:Create(UI.Reopen, MIN_REOPEN_INFO, {Size=UDim2.fromOffset(52,52), Position=UI.ReopenPos}):Play()
end

function Restore()
	if restoring then return end
	if not State.minimized then return end
	restoring = true
	State.minimized = false
	S.Tween:Create(UI.Reopen, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0,0), Position = UDim2.new(UI.ReopenPos.X.Scale, UI.ReopenPos.X.Offset+26, UI.ReopenPos.Y.Scale, UI.ReopenPos.Y.Offset-10)}):Play()
	task.wait(0.2)
	UI.Reopen.Visible = false
	UI.Main.Visible = true
	if State.isMaximized then
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800,600)
		UI.Main.Size = UDim2.fromOffset(math.max(vp.X - 30, 480), math.max(vp.Y - 30, 300))
		UI.Main.Position = UDim2.fromScale(0.5, 0.5)
		UI.UIScale.Scale = 1
	else
		UI.Main.Size = State.NormalSize
		UI.Main.Position = State.NormalPosition
		UI.UIScale.Scale = 0
	end
	UI.Main.Rotation = -3
	S.Tween:Create(UI.Main, RESTORE_INFO, {Rotation=0}):Play()
	if not State.isMaximized then
		S.Tween:Create(UI.UIScale, RESTORE_INFO, {Scale=1}):Play()
	end
	task.delay(0.6, function()
		if not State.minimized and not State.isMaximized then
			UpdateDeviceSize()
			if UI.UIScale.Scale < 0.1 then UI.UIScale.Scale = 1 end
		end
		restoring = false
	end)
end

S.Input.InputBegan:Connect(function(input, gp)
	if State.listening then
		if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
			State.CurrentKey = input.KeyCode
			UI.KeybindBtn.Text = tostring(State.CurrentKey.Name)
			UI.KeybindBtn.TextColor3 = Color3.fromRGB(225,225,232)
			State.listening = false
		end
		return
	end
	if gp then return end
	if not S.Input.TouchEnabled and State.unlocked and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == State.CurrentKey then
		if State.minimized then
			task.spawn(Restore)
		else
			task.spawn(Minimize)
		end
	end
end)

UI.MinBtn.MouseButton1Click:Connect(Minimize)
UI.ClassicMin.MouseButton1Click:Connect(Minimize)

local MAX_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
UI.MaxBtn.MouseButton1Click:Connect(function()
	if State.minimized then return end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	if State.isMaximized then
		State.isMaximized = false
		local targetSize = State.PreMaxSize or UDim2.new(0, 480, 0, 300)
		local targetPos = State.PreMaxPos or UDim2.fromScale(0.5, 0.5)
		local s = math.min((vp.X-20)/480, (vp.Y-40)/300)
		s = math.clamp(s, 0.5, 1)
		S.Tween:Create(UI.UIScale, MAX_INFO, {Scale = s}):Play()
		S.Tween:Create(UI.Main, MAX_INFO, {Size = targetSize, Position = targetPos}):Play()
		task.delay(0.4, function()
			if not State.isMaximized and not State.minimized then State.NormalSize = UI.Main.Size State.NormalPosition = UI.Main.Position end
		end)
	else
		State.isMaximized = true
		State.PreMaxSize = UI.Main.Size
		State.PreMaxPos = UI.Main.Position
		local maxW = math.max(vp.X - 30, 480)
		local maxH = math.max(vp.Y - 30, 300)
		S.Tween:Create(UI.UIScale, MAX_INFO, {Scale = 1}):Play()
		S.Tween:Create(UI.Main, MAX_INFO, {Size = UDim2.fromOffset(maxW, maxH), Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
end)

UI.Reopen.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragMode = "reopen"
		reopenMoved = false
		dragStartInput = input.Position
		dragStartPos = UI.Reopen.Position
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if conn then conn:Disconnect() end
				if dragMode == "reopen" then
					dragMode = nil
					if not reopenMoved then Restore() end
				end
			end
		end)
	end
end)

UI.Top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragMode = "main"
		dragStartInput = input.Position
		dragStartPos = UI.Main.Position
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if conn then conn:Disconnect() end
				if dragMode == "main" then dragMode = nil end
			end
		end)
	end
end)

if Storage.HasSession() and isWhitelisted(S.Player.Name) then
	task.defer(function()
		if UI.GUI.Parent then LoginSuccess() end
	end)
end

local Library = {
	GUI = UI.GUI,
	Window = UI.Main,
	Content = UI.Content,
	ACCENT = UI.ACCENT,
	WHITE = WHITE,
	Pages = {
		Home = UI.Pages.Home, Scripts = UI.Pages.Scripts,
		Fling = UI.Pages.Fling, Skys = UI.Pages.Skys,
		Animations = UI.Pages.Animations, Settings = UI.Pages.Settings,
	},
	Tabs = { MainScript = UI.Tabs.MainScript, Extra = UI.Tabs.Extra },
	Services = {
		Players = S.Players, Player = S.Player, PlayerGui = S.PlayerGui,
		TweenService = S.Tween, UserInputService = S.Input,
		RunService = S.Run, HttpService = S.Http,
		Lighting = S.Lighting, SoundService = S.Sound,
		ReplicatedStorage = S.RepStorage, Debris = S.Debris,
		CoreGui = S.CoreGui, Workspace = workspace,
	},
	CreateToggle = CreateToggle,
	ShowNotif = ShowNotif,
	RegisterExclusive = RegisterExclusive,
	AddButtonSweep = AddButtonSweep,
	RefreshMostUsed = RefreshMostUsed,
	ToggleRegistry = ToggleRegistry,
	SwitchPage = SwitchPage,
	cleanGuis = cleanGuis,
	OnLogin = function(fn) table.insert(OnLoginCallbacks, fn) end,
	IsLoggedIn = function() return State.unlocked end,
}

return Library
