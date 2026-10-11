-- ============================================================
-- LIBRARY - Panel GUI
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Workspace = workspace
local WHITE = Color3.new(1,1,1)

print("Panel library cargada")

local WHITELIST = {
	["jerehzxs"]  = "OWNER",
	["cloudd7qo"] = "TESTER",
	["jerehvo"]   = "MEMBER",
	["b92b08a"]   = "MEMBER",
	["astrixrsz"] = "MEMBER",
}
local function getRank(n) if not n then return nil end return WHITELIST[n:lower()] end
local function isWhitelisted(n) if not n then return false end return WHITELIST[n:lower()] ~= nil end

local MatchaFont = nil
local FontReady = false
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

local function HasSession()
	local ok, c = pcall(function() if readfile then return readfile("wb_session.txt") end end)
	if not ok or not c then return false end
	local t = tonumber(c); if not t then return false end
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
local function LoadSaveData()
	local ok, data = pcall(function() if readfile then return readfile("wb_save_data.txt") end end)
	if not ok or not data then return false end
	return data == "1" or data == "true"
end
local function SaveSaveData(val) pcall(function() if writefile then writefile("wb_save_data.txt", val and "1" or "0") end end) end
local function LoadActiveToggles()
	local ok, data = pcall(function() if readfile then return readfile("wb_saved_toggles.json") end end)
	if not ok or not data then return {} end
	local ok2, tbl = pcall(function() return HttpService:JSONDecode(data) end)
	if not ok2 or type(tbl) ~= "table" then return {} end
	return tbl
end
local function SaveActiveToggles()
	if not SaveDataEnabled then return end
	local active = {}
	for name, reg in pairs(ToggleRegistry) do
		if reg.getActive() then table.insert(active, name) end
	end
	pcall(function() if writefile then writefile("wb_saved_toggles.json", HttpService:JSONEncode(active)) end end)
end
local function ClearSavedToggles() pcall(function() if writefile then writefile("wb_saved_toggles.json", "[]") end end) end
local function LoadNotifRead()
	local ok, data = pcall(function() if readfile then return readfile("wb_notif_read.txt") end end)
	if not ok or not data then return false end
	return data == "1" or data == "true"
end
local function SaveNotifRead() pcall(function() if writefile then writefile("wb_notif_read.txt", "1") end end) end

local ToggleUsage = LoadUsage()
local AllToggles = {}
local ToggleRegistry = {}
local SaveDataEnabled = LoadSaveData()

local OldGUI = PlayerGui:FindFirstChild("WelcomeBackUI")
if OldGUI then OldGUI:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "WelcomeBackUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

GUI.DescendantAdded:Connect(function(obj) task.defer(function() if MatchaFont then ApplyFont(obj) end end) end)
task.spawn(function()
	while not FontReady do task.wait(0.1) end
	for _, obj in ipairs(GUI:GetDescendants()) do ApplyFont(obj) end
end)

local ACCENT = Color3.fromRGB(62,215,98)
local buttonStyle = "New"
local activeTab = nil
local activePill = nil

local ExclusiveGroups = {}
local function RegisterExclusive(groupId, toggleName)
	if not ExclusiveGroups[groupId] then ExclusiveGroups[groupId] = { toggles = {}, activeName = nil } end
	table.insert(ExclusiveGroups[groupId].toggles, toggleName)
end
local function CanActivate(toggleName)
	for _, g in pairs(ExclusiveGroups) do
		for _, n in ipairs(g.toggles) do
			if n == toggleName then
				if g.activeName and g.activeName ~= toggleName then
					return false, g.activeName
				end
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

local function ShowNotif(title, text, dur)
	dur = dur or 3
	local n = Instance.new("Frame")
	n.Size = UDim2.fromOffset(300, 62)
	n.Position = UDim2.new(0.5, -150, 0, -80)
	n.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	n.BorderSizePixel = 0
	n.ZIndex = 100
	n.Parent = GUI
	Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke", n)
	s.Color = ACCENT; s.Thickness = 1.5
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 20); t.Position = UDim2.new(0, 10, 0, 6)
	t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = ACCENT
	t.TextSize = 13; t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = n
	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(1, -20, 0, 28); b.Position = UDim2.new(0, 10, 0, 26)
	b.BackgroundTransparency = 1; b.Text = text
	b.TextColor3 = Color3.fromRGB(200, 200, 208); b.TextSize = 11
	b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextWrapped = true; b.Parent = n
	TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, 20)}):Play()
	task.delay(dur, function()
		local tw = TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, -80)})
		tw:Play()
		tw.Completed:Connect(function() n:Destroy() end)
	end)
end

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
	local sweeping = false
	btn.MouseEnter:Connect(function()
		if stroke then TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play() end
		if sweeping then return end
		sweeping = true
		sw.Position = UDim2.new(0, -40, 0, 0)
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
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.Size = UDim2.new(0,480,0,300)
Main.BackgroundColor3 = Color3.fromRGB(10,10,14)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(42,42,47)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.15
local UIScale = Instance.new("UIScale")
UIScale.Scale = 1
UIScale.Parent = Main

local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Size = UDim2.new(1,0,0,46)
Top.BackgroundTransparency = 1
Top.Active = true
Top.Parent = Main
local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1,0,0,1)
TopLine.Position = UDim2.new(0,0,1,-1)
TopLine.BackgroundColor3 = Color3.fromRGB(43,43,48)
TopLine.BorderSizePixel = 0
TopLine.Parent = Top

local function MakeMacButton(color, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(14,14)
	b.Position = UDim2.new(0,x,0,15)
	b.BackgroundColor3 = color
	b.Text = ""
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Parent = Top
	Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
	local s = Instance.new("UIStroke", b)
	s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.72
	return b
end
local CloseButton = MakeMacButton(Color3.fromRGB(245,67,67), 16)
local MinimizeButton = MakeMacButton(Color3.fromRGB(246,190,45), 38)
local MaximizeButton = MakeMacButton(Color3.fromRGB(47,195,87), 60)

local function MakeClassicButton(text, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(26,26)
	b.Position = UDim2.new(1,x,0,10)
	b.BackgroundColor3 = Color3.fromRGB(24,24,30)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(220,220,225)
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Visible = false
	b.Parent = Top
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	local s = Instance.new("UIStroke", b)
	s.Color = Color3.fromRGB(52,52,60)
	return b
end
local ClassicClose = MakeClassicButton("X", -34)
local ClassicMin = MakeClassicButton("-", -66)

local TitleGroup = Instance.new("Frame")
TitleGroup.AnchorPoint = Vector2.new(0.5,0.5)
TitleGroup.Position = UDim2.new(0.5,0,0,23)
TitleGroup.Size = UDim2.new(0,140,0,30)
TitleGroup.BackgroundTransparency = 1
TitleGroup.Parent = Top
local TopIcon = Instance.new("ImageLabel")
TopIcon.Size = UDim2.fromOffset(28,28)
TopIcon.Position = UDim2.new(0,0,0.5,-14)
TopIcon.BackgroundTransparency = 1
TopIcon.Image = "rbxassetid://119972597178070"
TopIcon.Parent = TitleGroup
local TopTitle = Instance.new("TextLabel")
TopTitle.Size = UDim2.new(1,-34,1,0)
TopTitle.Position = UDim2.new(0,34,0,0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "Panel"
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.TextColor3 = Color3.fromRGB(225,225,232)
TopTitle.TextSize = 16
TopTitle.Font = Enum.Font.GothamBold
TopTitle.Parent = TitleGroup

local Notification = Instance.new("TextButton")
Notification.Size = UDim2.fromOffset(30,30)
Notification.Position = UDim2.new(1,-46,0,9)
Notification.BackgroundColor3 = Color3.fromRGB(24,24,30)
Notification.Text = ""
Notification.AutoButtonColor = false
Notification.Parent = Top
Instance.new("UICorner", Notification).CornerRadius = UDim.new(1,0)
local NS = Instance.new("UIStroke", Notification)
NS.Color = Color3.fromRGB(52,52,60)
local NotifIcon = Instance.new("ImageLabel")
NotifIcon.Size = UDim2.new(1,-12,1,-12)
NotifIcon.Position = UDim2.new(0,6,0,6)
NotifIcon.BackgroundTransparency = 1
NotifIcon.Image = "rbxassetid://133824150122272"
NotifIcon.Parent = Notification
local NotificationDot = Instance.new("Frame")
NotificationDot.Size = UDim2.fromOffset(14,14)
NotificationDot.Position = UDim2.new(1,-9,0,-3)
NotificationDot.BackgroundColor3 = Color3.fromRGB(255,60,60)
NotificationDot.BorderSizePixel = 0
NotificationDot.ZIndex = 5
NotificationDot.Parent = Notification
Instance.new("UICorner", NotificationDot).CornerRadius = UDim.new(1,0)
local NDS = Instance.new("UIStroke", NotificationDot)
NDS.Color = Color3.fromRGB(10,10,14); NDS.Thickness = 2
local NotifBadge = Instance.new("TextLabel")
NotifBadge.Size = UDim2.new(1,0,1,0)
NotifBadge.BackgroundTransparency = 1
NotifBadge.Text = "1"
NotifBadge.TextColor3 = Color3.fromRGB(255,255,255)
NotifBadge.TextSize = 9
NotifBadge.Font = Enum.Font.GothamBold
NotifBadge.ZIndex = 6
NotifBadge.Parent = NotificationDot

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-46)
Content.Position = UDim2.new(0,0,0,46)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Main

local LoginPage = Instance.new("ScrollingFrame")
LoginPage.Name = "Login"
LoginPage.Size = UDim2.new(1,0,1,0)
LoginPage.BackgroundTransparency = 1
LoginPage.BorderSizePixel = 0
LoginPage.ScrollingDirection = Enum.ScrollingDirection.Y
LoginPage.ScrollingEnabled = true
LoginPage.Active = true
LoginPage.ScrollBarThickness = 3
LoginPage.ScrollBarImageTransparency = 0.4
LoginPage.CanvasSize = UDim2.new(0,0,0,320)
LoginPage.Parent = Content

local Profile = Instance.new("ImageLabel")
Profile.Size = UDim2.fromOffset(80,80)
Profile.Position = UDim2.new(0.5,-40,0,10)
Profile.BackgroundColor3 = Color3.fromRGB(15,35,21)
Profile.ScaleType = Enum.ScaleType.Crop
Profile.Parent = LoginPage
Instance.new("UICorner", Profile).CornerRadius = UDim.new(1,0)
local ProfileStroke = Instance.new("UIStroke", Profile)
ProfileStroke.Color = ACCENT; ProfileStroke.Thickness = 3

local Welcome = Instance.new("TextLabel")
Welcome.Size = UDim2.fromOffset(460,32)
Welcome.Position = UDim2.new(0.5,-230,0,98)
Welcome.BackgroundTransparency = 1
Welcome.Text = "Welcome Back"
Welcome.TextColor3 = Color3.fromRGB(245,245,247)
Welcome.TextSize = 24
Welcome.Font = Enum.Font.GothamBold
Welcome.Parent = LoginPage
local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.fromOffset(460,18)
Subtitle.Position = UDim2.new(0.5,-230,0,130)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Enter the password"
Subtitle.TextColor3 = Color3.fromRGB(125,125,130)
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = LoginPage

local Password = Instance.new("TextBox")
Password.Size = UDim2.fromOffset(280,38)
Password.Position = UDim2.new(0.5,-140,0,158)
Password.BackgroundColor3 = Color3.fromRGB(17,17,21)
Password.Text = ""
Password.PlaceholderText = "Password"
Password.PlaceholderColor3 = Color3.fromRGB(105,105,112)
Password.TextColor3 = Color3.fromRGB(240,240,240)
Password.TextSize = 14
Password.Font = Enum.Font.Gotham
Password.ClearTextOnFocus = false
Password.TextXAlignment = Enum.TextXAlignment.Center
Password.TextStrokeTransparency = 1
Password.Parent = LoginPage
Instance.new("UICorner", Password).CornerRadius = UDim.new(0,19)
local PassStroke = Instance.new("UIStroke", Password)
PassStroke.Color = ACCENT; PassStroke.Thickness = 1.5

local Enter = Instance.new("TextButton")
Enter.Size = UDim2.fromOffset(280,38)
Enter.Position = UDim2.new(0.5,-140,0,206)
Enter.BackgroundColor3 = Color3.fromRGB(16,16,20)
Enter.Text = "Enter"
Enter.TextColor3 = Color3.fromRGB(235,235,238)
Enter.TextSize = 15
Enter.Font = Enum.Font.GothamBold
Enter.AutoButtonColor = false
Enter.Parent = LoginPage
Instance.new("UICorner", Enter).CornerRadius = UDim.new(0,19)
local EnterStroke = Instance.new("UIStroke", Enter)
EnterStroke.Color = ACCENT; EnterStroke.Thickness = 1.5

local Error = Instance.new("TextLabel")
Error.Size = UDim2.fromOffset(400,18)
Error.Position = UDim2.new(0.5,-200,0,252)
Error.BackgroundTransparency = 1
Error.Text = ""
Error.TextColor3 = Color3.fromRGB(255,80,80)
Error.TextSize = 12
Error.Font = Enum.Font.Gotham
Error.Parent = LoginPage

local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1,0,1,-62)
Pages.BackgroundTransparency = 1
Pages.ClipsDescendants = true
Pages.Visible = false
Pages.Parent = Content

local function MakePage(name, canvas)
	local p = Instance.new("ScrollingFrame")
	p.Name = name
	p.Size = UDim2.new(1,0,1,0)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.ScrollingDirection = Enum.ScrollingDirection.Y
	p.ScrollingEnabled = true
	p.Active = true
	p.ScrollBarThickness = 3
	p.ScrollBarImageTransparency = 0.4
	p.CanvasSize = UDim2.new(0,0,0,canvas)
	p.Visible = false
	p.Parent = Pages
	return p
end

local HomePage = MakePage("Home", 400)
local ScriptsPage = MakePage("Scripts", 300)
local FlingPage = MakePage("Fling", 400)
local SkysPage = MakePage("Skys", 2000)
local AnimationsPage = MakePage("Animations", 800)
local SettingsPage = MakePage("Settings", 400)
HomePage.Visible = true

for _, pg in ipairs({ScriptsPage, FlingPage, SkysPage, AnimationsPage, SettingsPage}) do
	pcall(function()
		pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
		pg.CanvasSize = UDim2.new(0,0,0,0)
	end)
end

local BigProfile = Instance.new("ImageLabel")
BigProfile.Size = UDim2.fromOffset(70,70)
BigProfile.Position = UDim2.new(0,20,0,16)
BigProfile.BackgroundColor3 = Color3.fromRGB(15,15,18)
BigProfile.ScaleType = Enum.ScaleType.Crop
BigProfile.Parent = HomePage
Instance.new("UICorner", BigProfile).CornerRadius = UDim.new(1,0)
local BigStroke = Instance.new("UIStroke", BigProfile)
BigStroke.Color = ACCENT; BigStroke.Thickness = 3

local OnlineDot = Instance.new("Frame")
OnlineDot.Size = UDim2.fromOffset(22,22)
OnlineDot.Position = UDim2.new(1,-16,1,-16)
OnlineDot.BackgroundColor3 = ACCENT
OnlineDot.BorderSizePixel = 0
OnlineDot.ZIndex = 5
OnlineDot.Parent = BigProfile
Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1,0)
local OS = Instance.new("UIStroke", OnlineDot)
OS.Color = Color3.fromRGB(10,10,14); OS.Thickness = 3

local UserName = Instance.new("TextLabel")
UserName.Size = UDim2.new(1,-110,0,28)
UserName.Position = UDim2.new(0,100,0,18)
UserName.BackgroundTransparency = 1
UserName.Text = ""
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.TextTruncate = Enum.TextTruncate.AtEnd
UserName.TextColor3 = Color3.fromRGB(245,245,247)
UserName.TextSize = 19
UserName.Font = Enum.Font.GothamBold
UserName.Parent = HomePage

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,-110,0,18)
Status.Position = UDim2.new(0,100,0,46)
Status.BackgroundTransparency = 1
Status.Text = "Online"
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 = ACCENT
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.Parent = HomePage

local Rank = Instance.new("TextLabel")
Rank.Size = UDim2.new(1,-110,0,18)
Rank.Position = UDim2.new(0,100,0,64)
Rank.BackgroundTransparency = 1
Rank.Text = ""
Rank.TextXAlignment = Enum.TextXAlignment.Left
Rank.TextSize = 12
Rank.Font = Enum.Font.GothamBold
Rank.Visible = false
Rank.Parent = HomePage

local MostUsedTitle = Instance.new("TextLabel")
MostUsedTitle.Size = UDim2.new(1,-70,0,20)
MostUsedTitle.Position = UDim2.new(0,20,0,100)
MostUsedTitle.BackgroundTransparency = 1
MostUsedTitle.Text = "Most Used Scripts"
MostUsedTitle.TextXAlignment = Enum.TextXAlignment.Left
MostUsedTitle.TextColor3 = Color3.fromRGB(245,245,247)
MostUsedTitle.TextSize = 14
MostUsedTitle.Font = Enum.Font.GothamBold
MostUsedTitle.Parent = HomePage
local MostUsedSearchIcon = Instance.new("ImageLabel")
MostUsedSearchIcon.Size = UDim2.fromOffset(14,14)
MostUsedSearchIcon.Position = UDim2.new(1,-34,0,103)
MostUsedSearchIcon.BackgroundTransparency = 1
MostUsedSearchIcon.Image = "rbxassetid://6031091004"
MostUsedSearchIcon.ImageColor3 = Color3.fromRGB(150,150,158)
MostUsedSearchIcon.Parent = HomePage

local MostUsedList = Instance.new("Frame")
MostUsedList.Size = UDim2.new(1,-40,0,0)
MostUsedList.Position = UDim2.new(0,20,0,128)
MostUsedList.BackgroundTransparency = 1
MostUsedList.AutomaticSize = Enum.AutomaticSize.Y
MostUsedList.Parent = HomePage
local mul = Instance.new("UIListLayout", MostUsedList)
mul.Padding = UDim.new(0,4)
mul.SortOrder = Enum.SortOrder.LayoutOrder

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
	if #sorted == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,0,0,20)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Sin datos de uso aún"
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(120,120,128)
		lbl.TextSize = 11
		lbl.Font = Enum.Font.Gotham
		lbl.LayoutOrder = 1
		lbl.Parent = MostUsedList
		return
	end
	for i = 1, math.min(5, #sorted) do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1,0,0,30)
		entry.BackgroundColor3 = Color3.fromRGB(18,18,23)
		entry.BorderSizePixel = 0
		entry.LayoutOrder = i
		entry.Parent = MostUsedList
		Instance.new("UICorner", entry).CornerRadius = UDim.new(0,8)
		local num = Instance.new("TextLabel")
		num.Size = UDim2.fromOffset(20,20)
		num.Position = UDim2.new(0,4,0.5,-10)
		num.BackgroundColor3 = ACCENT
		num.Text = tostring(i)
		num.TextColor3 = Color3.fromRGB(20,20,24)
		num.TextSize = 11
		num.Font = Enum.Font.GothamBold
		num.Parent = entry
		Instance.new("UICorner", num).CornerRadius = UDim.new(1,0)
		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1,-90,1,0)
		nm.Position = UDim2.new(0,30,0,0)
		nm.BackgroundTransparency = 1
		nm.Text = sorted[i].name
		nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextColor3 = Color3.fromRGB(225,225,232)
		nm.TextSize = 11
		nm.Font = Enum.Font.GothamMedium
		nm.Parent = entry
		local registry = ToggleRegistry[sorted[i].name]
		local msw = Instance.new("Frame")
		msw.Size = UDim2.fromOffset(32,18)
		msw.Position = UDim2.new(1,-40,0.5,-9)
		msw.BackgroundColor3 = Color3.fromRGB(70,70,78)
		msw.BorderSizePixel = 0
		msw.Parent = entry
		Instance.new("UICorner", msw).CornerRadius = UDim.new(1,0)
		local msknob = Instance.new("Frame")
		msknob.Size = UDim2.fromOffset(14,14)
		msknob.Position = UDim2.fromOffset(2,2)
		msknob.BackgroundColor3 = Color3.fromRGB(240,240,245)
		msknob.Parent = msw
		Instance.new("UICorner", msknob).CornerRadius = UDim.new(1,0)
		local msc = Instance.new("TextButton")
		msc.Size = UDim2.new(1,0,1,0)
		msc.BackgroundTransparency = 1
		msc.Text = ""
		msc.ZIndex = 3
		msc.Parent = entry
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

local ScriptsTitle = Instance.new("TextLabel")
ScriptsTitle.Size = UDim2.new(1,-40,0,26)
ScriptsTitle.Position = UDim2.new(0,20,0,12)
ScriptsTitle.BackgroundTransparency = 1
ScriptsTitle.Text = "Scripts"
ScriptsTitle.TextXAlignment = Enum.TextXAlignment.Left
ScriptsTitle.TextColor3 = Color3.fromRGB(245,245,247)
ScriptsTitle.TextSize = 20
ScriptsTitle.Font = Enum.Font.GothamBold
ScriptsTitle.Parent = ScriptsPage

local ScriptsSearch = Instance.new("TextBox")
ScriptsSearch.Size = UDim2.new(1,-40,0,32)
ScriptsSearch.Position = UDim2.new(0,20,0,44)
ScriptsSearch.BackgroundColor3 = Color3.fromRGB(18,18,23)
ScriptsSearch.PlaceholderText = "Search scripts..."
ScriptsSearch.PlaceholderColor3 = Color3.fromRGB(105,105,112)
ScriptsSearch.Text = ""
ScriptsSearch.TextColor3 = Color3.fromRGB(240,240,240)
ScriptsSearch.TextSize = 12
ScriptsSearch.Font = Enum.Font.Gotham
ScriptsSearch.TextXAlignment = Enum.TextXAlignment.Left
ScriptsSearch.ClearTextOnFocus = false
ScriptsSearch.TextStrokeTransparency = 1
ScriptsSearch.Parent = ScriptsPage
Instance.new("UICorner", ScriptsSearch).CornerRadius = UDim.new(0,10)
local SSS = Instance.new("UIStroke", ScriptsSearch)
SSS.Color = Color3.fromRGB(52,52,60)
local SS_Pad = Instance.new("UIPadding", ScriptsSearch)
SS_Pad.PaddingLeft = UDim.new(0,32)
local ScriptsSearchIcon = Instance.new("ImageLabel")
ScriptsSearchIcon.Size = UDim2.fromOffset(14,14)
ScriptsSearchIcon.Position = UDim2.new(0,10,0.5,-7)
ScriptsSearchIcon.BackgroundTransparency = 1
ScriptsSearchIcon.Image = "rbxassetid://6031091004"
ScriptsSearchIcon.ImageColor3 = Color3.fromRGB(150,150,158)
ScriptsSearchIcon.ZIndex = 3
ScriptsSearchIcon.Parent = ScriptsSearch

local ScriptsRow = Instance.new("Frame")
ScriptsRow.Size = UDim2.new(1,-40,0,36)
ScriptsRow.Position = UDim2.new(0,20,0,84)
ScriptsRow.BackgroundTransparency = 1
ScriptsRow.Parent = ScriptsPage
local ScriptsLayout = Instance.new("UIListLayout", ScriptsRow)
ScriptsLayout.FillDirection = Enum.FillDirection.Horizontal
ScriptsLayout.Padding = UDim.new(0,6)

local ScriptsContent = Instance.new("Frame")
ScriptsContent.Size = UDim2.new(1,-40,0,0)
ScriptsContent.Position = UDim2.new(0,20,0,130)
ScriptsContent.BackgroundTransparency = 1
ScriptsContent.AutomaticSize = Enum.AutomaticSize.Y
ScriptsContent.Parent = ScriptsPage

local function MakeTabContent(name)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.new(1,0,0,0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.BackgroundTransparency = 1
	f.Visible = false
	f.Parent = ScriptsContent
	local lay = Instance.new("UIListLayout", f)
	lay.Padding = UDim.new(0,6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", f)
	pad.PaddingTop = UDim.new(0,2)
	pad.PaddingBottom = UDim.new(0,2)
	return f
end

local MainScriptTab = MakeTabContent("MainScript")
local ExtraTab = MakeTabContent("Extra")

local function cleanGuis(names)
	if not names then return end
	for _, gui in ipairs(PlayerGui:GetChildren()) do
		for _, n in ipairs(names) do
			if gui.Name == n or gui.Name:lower():find(n:lower(),1,true) then pcall(function() gui:Destroy() end) end
		end
	end
	for _, gui in ipairs(CoreGui:GetChildren()) do
		for _, n in ipairs(names) do
			if gui.Name == n or gui.Name:lower():find(n:lower(),1,true) then pcall(function() gui:Destroy() end) end
		end
	end
end

local function CreateToggle(parent, text, callback, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,0,36)
	btn.BackgroundColor3 = Color3.fromRGB(20,20,26)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order or 1
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(255,255,255)
	stroke.Thickness = 1
	stroke.Transparency = 0.82
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-70,1,0)
	label.Position = UDim2.new(0,14,0,0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(225,225,232)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.ZIndex = 7
	label.Parent = btn
	local sw = Instance.new("Frame")
	sw.Size = UDim2.fromOffset(36,20)
	sw.Position = UDim2.new(1,-48,0.5,-10)
	sw.BackgroundColor3 = Color3.fromRGB(70,70,78)
	sw.ZIndex = 7
	sw.Parent = btn
	Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16,16)
	knob.Position = UDim2.fromOffset(2,2)
	knob.BackgroundColor3 = Color3.fromRGB(240,240,245)
	knob.ZIndex = 8
	knob.Parent = sw
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
	local active = false
	local function setVisual(v)
		sw.BackgroundColor3 = v and ACCENT or Color3.fromRGB(70,70,78)
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = v and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)}):Play()
	end
	local function registerUsage()
		ToggleUsage[text] = (ToggleUsage[text] or 0) + 1
		SaveUsage(ToggleUsage)
	end
	btn.MouseButton1Click:Connect(function()
		if not active then
			local canActivate, blocker = CanActivate(text)
			if not canActivate then
				ShowNotif("No se puede activar", "Desactiva primero: " .. blocker, 3)
				return
			end
			active = true
			registerUsage()
			SetExclusiveActive(text)
		else
			active = false
			ClearExclusiveActive(text)
		end
		setVisual(active)
		pcall(callback, active)
		pcall(SaveActiveToggles)
	end)
	ToggleRegistry[text] = {
		getActive = function() return active end,
		setActive = function(v)
			if v == active then return end
			if v then
				local canActivate, blocker = CanActivate(text)
				if not canActivate then return end
			end
			active = v
			if active then registerUsage() SetExclusiveActive(text) else ClearExclusiveActive(text) end
			setVisual(active)
			pcall(callback, active)
			pcall(SaveActiveToggles)
		end
	}
	table.insert(AllToggles, {btn=btn, label=label, text=text, parent=parent})
	task.defer(function() AddButtonSweep(btn, stroke) end)
	return btn
end

local function MakeScriptPill(text, order)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(150,36)
	b.BackgroundColor3 = Color3.fromRGB(20,20,26)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(225,225,232)
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.LayoutOrder = order
	b.Parent = ScriptsRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
	local s = Instance.new("UIStroke", b)
	s.Color = Color3.fromRGB(255,255,255)
	s.Thickness = 1
	s.Transparency = 0.82
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	task.defer(function() AddButtonSweep(b, s) end)
	return b
end

local MainScriptBtn = MakeScriptPill("Script", 1)
local ExtraBtn = MakeScriptPill("Extra", 2)

local function SelectTab(tab, pill)
	if activeTab == tab then return end
	if activeTab then
		local oldTab = activeTab
		local oldPill = activePill
		TweenService:Create(oldTab, TweenInfo.new(0.18), {Position=UDim2.new(-0.15,0,0,0)}):Play()
		if oldPill then
			TweenService:Create(oldPill, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20,20,26), TextColor3 = Color3.fromRGB(225,225,232)}):Play()
			local ps = oldPill:FindFirstChildOfClass("UIStroke")
			if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=Color3.fromRGB(255,255,255), Transparency = 0.82}):Play() end
		end
		task.delay(0.18, function()
			if oldTab then oldTab.Visible = false oldTab.Position = UDim2.new(0,0,0,0) end
		end)
	end
	activeTab = tab
	activePill = pill
	tab.Visible = true
	tab.Position = UDim2.new(0.15,0,0,0)
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

local FlingTitle = Instance.new("TextLabel")
FlingTitle.Size = UDim2.new(1,-40,0,26)
FlingTitle.Position = UDim2.new(0,20,0,12)
FlingTitle.BackgroundTransparency = 1
FlingTitle.Text = "Fling Players"
FlingTitle.TextXAlignment = Enum.TextXAlignment.Left
FlingTitle.TextColor3 = Color3.fromRGB(245,245,247)
FlingTitle.TextSize = 20
FlingTitle.Font = Enum.Font.GothamBold
FlingTitle.Parent = FlingPage

local SkysTitle = Instance.new("TextLabel")
SkysTitle.Size = UDim2.new(1,-40,0,26)
SkysTitle.Position = UDim2.new(0,20,0,12)
SkysTitle.BackgroundTransparency = 1
SkysTitle.Text = "Skys"
SkysTitle.TextXAlignment = Enum.TextXAlignment.Left
SkysTitle.TextColor3 = Color3.fromRGB(245,245,247)
SkysTitle.TextSize = 20
SkysTitle.Font = Enum.Font.GothamBold
SkysTitle.Parent = SkysPage

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1,-40,0,26)
SettingsTitle.Position = UDim2.new(0,20,0,12)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Settings"
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.TextColor3 = Color3.fromRGB(245,245,247)
SettingsTitle.TextSize = 20
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.Parent = SettingsPage

local StyleLabel = Instance.new("TextLabel")
StyleLabel.Size = UDim2.new(1,-40,0,16)
StyleLabel.Position = UDim2.new(0,20,0,46)
StyleLabel.BackgroundTransparency = 1
StyleLabel.Text = "Estilo de botones"
StyleLabel.TextXAlignment = Enum.TextXAlignment.Left
StyleLabel.TextColor3 = Color3.fromRGB(180,180,188)
StyleLabel.TextSize = 11
StyleLabel.Font = Enum.Font.Gotham
StyleLabel.Parent = SettingsPage

local StyleRow = Instance.new("Frame")
StyleRow.Size = UDim2.new(1,-40,0,40)
StyleRow.Position = UDim2.new(0,20,0,66)
StyleRow.BackgroundColor3 = Color3.fromRGB(18,18,23)
StyleRow.BorderSizePixel = 0
StyleRow.Parent = SettingsPage
Instance.new("UICorner", StyleRow).CornerRadius = UDim.new(0,12)
local StyleStroke = Instance.new("UIStroke", StyleRow)
StyleStroke.Color = Color3.fromRGB(50,50,58)

local function MakeStyleOption(text, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5,-8,1,-10)
	b.Position = UDim2.new(x,4,0,5)
	b.BackgroundColor3 = Color3.fromRGB(30,30,36)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(200,200,208)
	b.TextSize = 12
	b.Font = Enum.Font.GothamMedium
	b.AutoButtonColor = false
	b.Parent = StyleRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	local soStroke = Instance.new("UIStroke", b)
	soStroke.Color = Color3.fromRGB(255,255,255)
	soStroke.Thickness = 1
	soStroke.Transparency = 0.82
	soStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	task.defer(function() AddButtonSweep(b, soStroke) end)
	return b
end

local NewOption = MakeStyleOption("New", 0)
local ClassicOption = MakeStyleOption("Classic", 0.5)

local SaveDataLabel = Instance.new("TextLabel")
SaveDataLabel.Size = UDim2.new(1,-40,0,16)
SaveDataLabel.Position = UDim2.new(0,20,0,120)
SaveDataLabel.BackgroundTransparency = 1
SaveDataLabel.Text = "Guardar datos"
SaveDataLabel.TextXAlignment = Enum.TextXAlignment.Left
SaveDataLabel.TextColor3 = Color3.fromRGB(180,180,188)
SaveDataLabel.TextSize = 11
SaveDataLabel.Font = Enum.Font.Gotham
SaveDataLabel.Parent = SettingsPage

local SaveDataBtn = Instance.new("TextButton")
SaveDataBtn.Size = UDim2.new(1,-40,0,44)
SaveDataBtn.Position = UDim2.new(0,20,0,142)
SaveDataBtn.BackgroundColor3 = Color3.fromRGB(18,18,23)
SaveDataBtn.Text = ""
SaveDataBtn.AutoButtonColor = false
SaveDataBtn.Parent = SettingsPage
Instance.new("UICorner", SaveDataBtn).CornerRadius = UDim.new(0,12)
local SaveDataStroke = Instance.new("UIStroke", SaveDataBtn)
SaveDataStroke.Color = Color3.fromRGB(50,50,58)

local SD_Title = Instance.new("TextLabel")
SD_Title.Size = UDim2.new(1,-70,0,20)
SD_Title.Position = UDim2.new(0,14,0,4)
SD_Title.BackgroundTransparency = 1
SD_Title.Text = "Guardar scripts activos"
SD_Title.TextXAlignment = Enum.TextXAlignment.Left
SD_Title.TextColor3 = Color3.fromRGB(225,225,232)
SD_Title.TextSize = 12
SD_Title.Font = Enum.Font.GothamBold
SD_Title.Parent = SaveDataBtn

local SD_Sub = Instance.new("TextLabel")
SD_Sub.Size = UDim2.new(1,-70,0,14)
SD_Sub.Position = UDim2.new(0,14,0,22)
SD_Sub.BackgroundTransparency = 1
SD_Sub.Text = "Recargar al volver a entrar"
SD_Sub.TextXAlignment = Enum.TextXAlignment.Left
SD_Sub.TextColor3 = Color3.fromRGB(130,130,138)
SD_Sub.TextSize = 10
SD_Sub.Font = Enum.Font.Gotham
SD_Sub.Parent = SaveDataBtn

local SD_Switch = Instance.new("Frame")
SD_Switch.Size = UDim2.fromOffset(36,20)
SD_Switch.Position = UDim2.new(1,-48,0.5,-10)
SD_Switch.BackgroundColor3 = SaveDataEnabled and ACCENT or Color3.fromRGB(70,70,78)
SD_Switch.BorderSizePixel = 0
SD_Switch.Parent = SaveDataBtn
Instance.new("UICorner", SD_Switch).CornerRadius = UDim.new(1,0)
local SD_Knob = Instance.new("Frame")
SD_Knob.Size = UDim2.fromOffset(16,16)
SD_Knob.Position = SaveDataEnabled and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)
SD_Knob.BackgroundColor3 = Color3.fromRGB(240,240,245)
SD_Knob.Parent = SD_Switch
Instance.new("UICorner", SD_Knob).CornerRadius = UDim.new(1,0)

local function UpdateSaveDataVisual()
	SD_Switch.BackgroundColor3 = SaveDataEnabled and ACCENT or Color3.fromRGB(70,70,78)
	TweenService:Create(SD_Knob, TweenInfo.new(0.15), {Position = SaveDataEnabled and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)}):Play()
end

SaveDataBtn.MouseButton1Click:Connect(function()
	SaveDataEnabled = not SaveDataEnabled
	SaveSaveData(SaveDataEnabled)
	UpdateSaveDataVisual()
	if SaveDataEnabled then SaveActiveToggles() else ClearSavedToggles() end
end)

local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(1,-40,0,16)
KeybindLabel.Position = UDim2.new(0,20,0,200)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Tecla para minimizar"
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindLabel.TextColor3 = Color3.fromRGB(180,180,188)
KeybindLabel.TextSize = 11
KeybindLabel.Font = Enum.Font.Gotham
KeybindLabel.Parent = SettingsPage

local KeybindRow = Instance.new("Frame")
KeybindRow.Size = UDim2.new(1,-40,0,40)
KeybindRow.Position = UDim2.new(0,20,0,222)
KeybindRow.BackgroundColor3 = Color3.fromRGB(18,18,23)
KeybindRow.BorderSizePixel = 0
KeybindRow.Parent = SettingsPage
Instance.new("UICorner", KeybindRow).CornerRadius = UDim.new(0,12)
local KRS = Instance.new("UIStroke", KeybindRow)
KRS.Color = Color3.fromRGB(50,50,58)

local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Size = UDim2.new(1,-20,1,-10)
KeybindBtn.Position = UDim2.new(0,10,0,5)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(28,28,35)
KeybindBtn.Text = "M"
KeybindBtn.TextColor3 = Color3.fromRGB(225,225,232)
KeybindBtn.TextSize = 12
KeybindBtn.Font = Enum.Font.GothamBold
KeybindBtn.AutoButtonColor = false
KeybindBtn.Parent = KeybindRow
Instance.new("UICorner", KeybindBtn).CornerRadius = UDim.new(0,8)
local kbStroke = Instance.new("UIStroke", KeybindBtn)
kbStroke.Color = Color3.fromRGB(255,255,255)
kbStroke.Thickness = 1
kbStroke.Transparency = 0.82
kbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local CurrentKey = Enum.KeyCode.M
local listening = false

KeybindBtn.MouseButton1Click:Connect(function()
	if listening then return end
	listening = true
	KeybindBtn.Text = "Presiona una tecla..."
	KeybindBtn.TextColor3 = ACCENT
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not listening then return end
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		CurrentKey = input.KeyCode
		KeybindBtn.Text = tostring(CurrentKey.Name)
		KeybindBtn.TextColor3 = Color3.fromRGB(225,225,232)
		listening = false
	end
end)

local Bottom = Instance.new("Frame")
Bottom.Size = UDim2.fromOffset(460,54)
Bottom.Position = UDim2.new(0.5,-230,1,-60)
Bottom.BackgroundColor3 = Color3.fromRGB(18,18,22)
Bottom.BorderSizePixel = 0
Bottom.Visible = false
Bottom.Parent = Content
Instance.new("UICorner", Bottom).CornerRadius = UDim.new(0,27)
local BS = Instance.new("UIStroke", Bottom)
BS.Color = Color3.fromRGB(45,45,50)

local NavPill = Instance.new("Frame")
NavPill.Size = UDim2.fromOffset(76,46)
NavPill.Position = UDim2.new(0,2,0,4)
NavPill.BackgroundColor3 = Color3.fromRGB(255,255,255)
NavPill.BackgroundTransparency = 0.88
NavPill.BorderSizePixel = 0
NavPill.ZIndex = 2
NavPill.Parent = Bottom
Instance.new("UICorner", NavPill).CornerRadius = UDim.new(1,0)

local function MakeNavButton(imageId, label, x, w)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w,46)
	b.Position = UDim2.new(0,x,0,4)
	b.BackgroundTransparency = 1
	b.Text = ""
	b.AutoButtonColor = false
	b.ZIndex = 4
	b.Parent = Bottom
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(22,22)
	icon.Position = UDim2.new(0.5,-11,0,6)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://"..imageId
	icon.ZIndex = 7
	icon.Parent = b
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,0,14)
	lbl.Position = UDim2.new(0,0,0,30)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextColor3 = Color3.fromRGB(180,180,190)
	lbl.TextSize = 10
	lbl.Font = Enum.Font.GothamMedium
	lbl.ZIndex = 7
	lbl.Parent = b
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

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1,-20,0,14)
Watermark.Position = UDim2.new(0,10,1,-72)
Watermark.BackgroundTransparency = 1
Watermark.Text = "Panel creado por Sam"
Watermark.TextXAlignment = Enum.TextXAlignment.Center
Watermark.TextColor3 = Color3.fromRGB(110,110,118)
Watermark.TextSize = 10
Watermark.Font = Enum.Font.Gotham
Watermark.TextTransparency = 0.4
Watermark.ZIndex = 15
Watermark.Parent = Content

local NotifPanel = Instance.new("Frame")
NotifPanel.Size = UDim2.fromOffset(280,200)
NotifPanel.Position = UDim2.new(0,-300,0,52)
NotifPanel.BackgroundColor3 = Color3.fromRGB(16,16,21)
NotifPanel.BorderSizePixel = 0
NotifPanel.ZIndex = 20
NotifPanel.Visible = false
NotifPanel.Parent = Main
Instance.new("UICorner", NotifPanel).CornerRadius = UDim.new(0,12)
local NPS = Instance.new("UIStroke", NotifPanel)
NPS.Color = Color3.fromRGB(50,50,58)
local NotifPanelTitle = Instance.new("TextLabel")
NotifPanelTitle.Size = UDim2.new(1,-24,0,28)
NotifPanelTitle.Position = UDim2.new(0,12,0,8)
NotifPanelTitle.BackgroundTransparency = 1
NotifPanelTitle.Text = "Notificaciones"
NotifPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
NotifPanelTitle.TextColor3 = Color3.fromRGB(245,245,247)
NotifPanelTitle.TextSize = 14
NotifPanelTitle.Font = Enum.Font.GothamBold
NotifPanelTitle.ZIndex = 21
NotifPanelTitle.Parent = NotifPanel
local NotifPanelLine = Instance.new("Frame")
NotifPanelLine.Size = UDim2.new(1,-24,0,1)
NotifPanelLine.Position = UDim2.new(0,12,0,40)
NotifPanelLine.BackgroundColor3 = Color3.fromRGB(40,40,46)
NotifPanelLine.BorderSizePixel = 0
NotifPanelLine.ZIndex = 21
NotifPanelLine.Parent = NotifPanel
local NotifEntry = Instance.new("Frame")
NotifEntry.Size = UDim2.new(1,-24,0,120)
NotifEntry.Position = UDim2.new(0,12,0,48)
NotifEntry.BackgroundColor3 = Color3.fromRGB(22,22,28)
NotifEntry.BorderSizePixel = 0
NotifEntry.ZIndex = 21
NotifEntry.Parent = NotifPanel
Instance.new("UICorner", NotifEntry).CornerRadius = UDim.new(0,8)
local NES = Instance.new("UIStroke", NotifEntry)
NES.Color = Color3.fromRGB(60,60,70)
local NotifEntryTitle = Instance.new("TextLabel")
NotifEntryTitle.Size = UDim2.new(1,-20,0,20)
NotifEntryTitle.Position = UDim2.new(0,10,0,8)
NotifEntryTitle.BackgroundTransparency = 1
NotifEntryTitle.Text = "Nueva Actualización!"
NotifEntryTitle.TextXAlignment = Enum.TextXAlignment.Left
NotifEntryTitle.TextColor3 = Color3.fromRGB(245,245,247)
NotifEntryTitle.TextSize = 12
NotifEntryTitle.Font = Enum.Font.GothamBold
NotifEntryTitle.ZIndex = 22
NotifEntryTitle.Parent = NotifEntry
local NotifEntryText = Instance.new("TextLabel")
NotifEntryText.Size = UDim2.new(1,-20,0,50)
NotifEntryText.Position = UDim2.new(0,10,0,30)
NotifEntryText.BackgroundTransparency = 1
NotifEntryText.Text = "La próxima actualización traerá más de 20 skyboxes nuevos!"
NotifEntryText.TextXAlignment = Enum.TextXAlignment.Left
NotifEntryText.TextYAlignment = Enum.TextYAlignment.Top
NotifEntryText.TextWrapped = true
NotifEntryText.TextColor3 = Color3.fromRGB(200,200,208)
NotifEntryText.TextSize = 11
NotifEntryText.Font = Enum.Font.Gotham
NotifEntryText.ZIndex = 22
NotifEntryText.Parent = NotifEntry
local ReadBtn = Instance.new("TextButton")
ReadBtn.Size = UDim2.new(1,-20,0,24)
ReadBtn.Position = UDim2.new(0,10,1,-32)
ReadBtn.BackgroundColor3 = Color3.fromRGB(40,40,48)
ReadBtn.Text = "Leído"
ReadBtn.TextColor3 = Color3.fromRGB(225,225,232)
ReadBtn.TextSize = 11
ReadBtn.Font = Enum.Font.GothamBold
ReadBtn.AutoButtonColor = false
ReadBtn.ZIndex = 22
ReadBtn.Parent = NotifEntry
Instance.new("UICorner", ReadBtn).CornerRadius = UDim.new(0,6)

local Reopen = Instance.new("TextButton")
Reopen.Size = UDim2.fromOffset(52,52)
Reopen.Position = UDim2.new(0,16,1,-68)
Reopen.BackgroundColor3 = Color3.fromRGB(255,255,255)
Reopen.Text = ""
Reopen.AutoButtonColor = false
Reopen.Visible = false
Reopen.Active = true
Reopen.Parent = GUI
Instance.new("UICorner", Reopen).CornerRadius = UDim.new(1,0)
local RS = Instance.new("UIStroke", Reopen)
RS.Color = Color3.fromRGB(220,220,220)
local ReopenIcon = Instance.new("ImageLabel")
ReopenIcon.Size = UDim2.new(1,-16,1,-16)
ReopenIcon.Position = UDim2.new(0,8,0,8)
ReopenIcon.BackgroundTransparency = 1
ReopenIcon.Image = "rbxassetid://92472718379692"
ReopenIcon.Parent = Reopen
local reopenSavedPos = UDim2.new(0,16,1,-68)

local unlocked = false
local minimized = false
local isMaximized = false
local notifOpen = false
local animating = false
local currentPageName = "Home"
local NormalSize = UDim2.new(0,480,0,300)
local NormalPosition = UDim2.fromScale(0.5,0.5)
local PreMaxSize = nil
local PreMaxPos = nil
local UpdateButtonStyle

local function UpdateDeviceSize()
	local cam = workspace.CurrentCamera
	if not cam then UIScale.Scale = 1 return end
	local vp = cam.ViewportSize
	if not vp or vp.X < 100 or vp.Y < 100 then UIScale.Scale = 1 return end
	if isMaximized then
		Main.Size = UDim2.fromOffset(math.max(vp.X - 30, 480), math.max(vp.Y - 30, 300))
		UIScale.Scale = 1
		return
	end
	Main.Size = UDim2.new(0,480,0,300)
	local s = math.min((vp.X-20)/480, (vp.Y-40)/300)
	s = math.clamp(s, 0.5, 1)
	UIScale.Scale = s
	NormalSize = Main.Size
	NormalPosition = Main.Position
end
UpdateDeviceSize()
local Camera = workspace.CurrentCamera
if Camera then Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() pcall(UpdateDeviceSize) end) end

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
	end)
	if ok and img then
		Profile.Image = img
		BigProfile.Image = img
	end
end)

local function colorOwnerRainbow() return Color3.fromHSV((os.clock() * 0.25) % 1, 1, 1) end
local function colorTesterRGB()
	local t = (os.clock() * 0.5) % 1
	local blue = Color3.fromRGB(0,80,255)
	local red = Color3.fromRGB(255,0,0)
	if t < 0.5 then return blue:Lerp(red, t*2)
	else return red:Lerp(blue, (t-0.5)*2) end
end

local rankAccum = 0
RunService.Heartbeat:Connect(function(dt)
	if not Rank.Visible then return end
	local r = getRank(Player.Name)
	if r ~= "OWNER" and r ~= "TESTER" then return end
	rankAccum += dt
	if rankAccum < 0.05 then return end
	rankAccum = 0
	if r == "OWNER" then Rank.TextColor3 = colorOwnerRainbow()
	elseif r == "TESTER" then Rank.TextColor3 = colorTesterRGB() end
end)

local PageMap = {Home=HomePage, Scripts=ScriptsPage, Fling=FlingPage, Skys=SkysPage, Animations=AnimationsPage, Settings=SettingsPage}
local function ResetScroll()
	for _, p in pairs(PageMap) do p.CanvasPosition = Vector2.new(0,0) end
	LoginPage.CanvasPosition = Vector2.new(0,0)
end

local function SwitchPage(target, fromRight)
	if animating or currentPageName == target or not unlocked then return end
	local FromPage = PageMap[currentPageName]
	local ToPage = PageMap[target]
	if not FromPage or not ToPage then return end
	animating = true
	local Dir = fromRight and 1 or -1
	local Info = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	ToPage.Position = UDim2.new(Dir,0,0,0)
	ToPage.Visible = true
	TweenService:Create(FromPage, Info, {Position=UDim2.new(-Dir,0,0,0)}):Play()
	TweenService:Create(ToPage, Info, {Position=UDim2.new(0,0,0,0)}):Play()
	task.wait(0.15)
	FromPage.Visible = false
	FromPage.Position = UDim2.new(0,0,0,0)
	currentPageName = target
	animating = false
	ResetScroll()
end

local _onLoginCallbacks = {}

local function LoginSuccess()
	if unlocked then return end
	unlocked = true
	local FadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function Fade(o,p,t) TweenService:Create(o, FadeInfo, {[p]=t}):Play() end
	Fade(Profile, "ImageTransparency", 1)
	Fade(Profile, "BackgroundTransparency", 1)
	Fade(ProfileStroke, "Transparency", 1)
	Fade(Welcome, "TextTransparency", 1)
	Fade(Subtitle, "TextTransparency", 1)
	Fade(Password, "BackgroundTransparency", 1)
	Fade(Password, "TextTransparency", 1)
	Fade(PassStroke, "Transparency", 1)
	Fade(Enter, "BackgroundTransparency", 1)
	Fade(Enter, "TextTransparency", 1)
	Fade(EnterStroke, "Transparency", 1)
	Fade(Error, "TextTransparency", 1)
	task.wait(0.32)
	LoginPage.Visible = false
	UserName.Text = "@"..Player.Name
	local r = getRank(Player.Name)
	if r then
		Rank.Text = r
		if r == "OWNER" then Rank.TextColor3 = Color3.fromRGB(255,80,80)
		elseif r == "TESTER" then Rank.TextColor3 = Color3.fromRGB(0,80,255)
		else Rank.TextColor3 = ACCENT end
		Rank.Visible = true
	end
	Pages.Visible = true
	Bottom.Visible = true
	HomePage.Visible = true
	ScriptsPage.Visible = false
	FlingPage.Visible = false
	SkysPage.Visible = false
	AnimationsPage.Visible = false
	SettingsPage.Visible = false
	currentPageName = "Home"
	ResetScroll()
	if not activeTab then SelectTab(MainScriptTab, MainScriptBtn) end
	BigProfile.ImageTransparency = 1
	UserName.TextTransparency = 1
	Status.TextTransparency = 1
	Rank.TextTransparency = 1
	for _, o in ipairs({BigProfile, UserName, Status, Rank}) do
		local props = {}
		if o:IsA("TextLabel") then props.TextTransparency = 0
		else props.ImageTransparency = 0 end
		TweenService:Create(o, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
	end
	task.defer(function() pcall(RefreshMostUsed) end)
	if SaveDataEnabled then
		task.spawn(function()
			task.wait(1.5)
			local saved = LoadActiveToggles()
			if not saved or #saved == 0 then return end
			local function applyAll()
				for _, name in ipairs(saved) do
					local reg = ToggleRegistry[name]
					if reg then pcall(function() reg.setActive(true) end) end
				end
			end
			if not Player.Character then
				local conn
				conn = Player.CharacterAdded:Connect(function()
					if conn then conn:Disconnect() conn = nil end
					task.wait(1)
					applyAll()
				end)
				task.delay(20, function() if conn then conn:Disconnect() conn = nil end end)
			else
				applyAll()
			end
		end)
	end
	for _, fn in ipairs(_onLoginCallbacks) do
		task.spawn(function() pcall(fn) end)
	end
end

local function TryLogin()
	if unlocked then return end
	if not isWhitelisted(Player.Name) then Error.Text = "No estás en la whitelist" return end
	if Password.Text == "sam2027" then
		Error.Text = ""
		SaveSession()
		LoginSuccess()
	else
		Error.Text = "Contraseña incorrecta"
		local orig = Password.Position
		local T1 = TweenService:Create(Password, TweenInfo.new(0.05), {Position=orig+UDim2.fromOffset(7,0)})
		local T2 = TweenService:Create(Password, TweenInfo.new(0.05), {Position=orig-UDim2.fromOffset(7,0)})
		T1:Play(); T1.Completed:Wait()
		T2:Play(); T2.Completed:Wait()
		Password.Position = orig
		Password.Text = ""
	end
end
Enter.MouseButton1Click:Connect(TryLogin)
Password.FocusLost:Connect(function(e) if e then TryLogin() end end)

local notifRead = LoadNotifRead()
if notifRead then
	NotificationDot.Visible = false
	ReadBtn.Text = "Leído ✓"
	ReadBtn.BackgroundColor3 = Color3.fromRGB(35,90,50)
end

local function CloseNotifications()
	notifOpen = false
	NotifPanel.Position = UDim2.new(0,-300,0,52)
	NotifPanel.Visible = false
end
Notification.MouseButton1Click:Connect(function()
	if notifOpen then
		local tw = TweenService:Create(NotifPanel, TweenInfo.new(0.28), {Position=UDim2.new(0,-300,0,52)})
		tw:Play()
		notifOpen = false
		tw.Completed:Connect(function() if not notifOpen then NotifPanel.Visible = false end end)
	else
		notifOpen = true
		NotifPanel.Visible = true
		NotifPanel.Position = UDim2.new(0,-300,0,52)
		TweenService:Create(NotifPanel, TweenInfo.new(0.3), {Position=UDim2.new(0,12,0,52)}):Play()
	end
end)
ReadBtn.MouseButton1Click:Connect(function()
	if notifRead then return end
	notifRead = true
	SaveNotifRead()
	NotificationDot.Visible = false
	ReadBtn.Text = "Leído ✓"
	ReadBtn.BackgroundColor3 = Color3.fromRGB(35,90,50)
end)

UpdateButtonStyle = function()
	if buttonStyle == "New" then
		CloseButton.Visible = true
		MinimizeButton.Visible = true
		MaximizeButton.Visible = true
		ClassicClose.Visible = false
		ClassicMin.Visible = false
		Notification.Position = UDim2.new(1,-46,0,9)
		TweenService:Create(NewOption, TweenInfo.new(0.2), {BackgroundColor3=ACCENT, TextColor3=Color3.fromRGB(20,20,24)}):Play()
		TweenService:Create(ClassicOption, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,36), TextColor3=Color3.fromRGB(200,200,208)}):Play()
	else
		CloseButton.Visible = false
		MinimizeButton.Visible = false
		MaximizeButton.Visible = false
		ClassicClose.Visible = true
		ClassicMin.Visible = true
		Notification.Position = UDim2.new(0,16,0,9)
		TweenService:Create(ClassicOption, TweenInfo.new(0.2), {BackgroundColor3=ACCENT, TextColor3=Color3.fromRGB(20,20,24)}):Play()
		TweenService:Create(NewOption, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,36), TextColor3=Color3.fromRGB(200,200,208)}):Play()
	end
end
UpdateButtonStyle()
NewOption.MouseButton1Click:Connect(function() buttonStyle = "New" UpdateButtonStyle() end)
ClassicOption.MouseButton1Click:Connect(function() buttonStyle = "Classic" UpdateButtonStyle() end)

HomeButton.MouseButton1Click:Connect(function() SwitchPage("Home", false) MoveNavPill(2, 76) end)
ScriptsButton.MouseButton1Click:Connect(function() SwitchPage("Scripts", true) MoveNavPill(78, 76) end)
FlingButton.MouseButton1Click:Connect(function() SwitchPage("Fling", true) MoveNavPill(154, 76) end)
SkysButton.MouseButton1Click:Connect(function() SwitchPage("Skys", true) MoveNavPill(230, 76) end)
AnimationsButton.MouseButton1Click:Connect(function() SwitchPage("Animations", true) MoveNavPill(306, 76) end)
SettingsButton.MouseButton1Click:Connect(function() SwitchPage("Settings", true) MoveNavPill(382, 76) end)

CloseButton.MouseButton1Click:Connect(function() pcall(SaveActiveToggles) GUI:Destroy() end)
ClassicClose.MouseButton1Click:Connect(function() pcall(SaveActiveToggles) GUI:Destroy() end)

local restoring = false
local function Minimize()
	if minimized then return end
	minimized = true
	NormalSize = Main.Size
	NormalPosition = Main.Position
	CloseNotifications()
	TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale=0}):Play()
	task.wait(0.28)
	Main.Visible = false
	UpdateDeviceSize()
	Reopen.Visible = true
	Reopen.Size = UDim2.fromOffset(0,0)
	Reopen.Position = UDim2.new(reopenSavedPos.X.Scale, reopenSavedPos.X.Offset+26, reopenSavedPos.Y.Scale, reopenSavedPos.Y.Offset-10)
	TweenService:Create(Reopen, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.fromOffset(52,52), Position=reopenSavedPos}):Play()
end
local function Restore()
	if restoring then return end
	if not minimized then return end
	restoring = true
	minimized = false
	TweenService:Create(Reopen, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0,0), Position = UDim2.new(reopenSavedPos.X.Scale, reopenSavedPos.X.Offset+26, reopenSavedPos.Y.Scale, reopenSavedPos.Y.Offset-10)}):Play()
	task.wait(0.2)
	Reopen.Visible = false
	Main.Visible = true
	if isMaximized then
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800,600)
		Main.Size = UDim2.fromOffset(math.max(vp.X - 30, 480), math.max(vp.Y - 30, 300))
		Main.Position = UDim2.fromScale(0.5, 0.5)
		UIScale.Scale = 1
	else
		Main.Size = NormalSize
		Main.Position = NormalPosition
		UIScale.Scale = 0
	end
	Main.Rotation = -3
	CloseNotifications()
	TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation=0}):Play()
	if not isMaximized then
		TweenService:Create(UIScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale=1}):Play()
	end
	task.delay(0.5, function()
		if not minimized and not isMaximized then UpdateDeviceSize() end
		restoring = false
	end)
end
MinimizeButton.MouseButton1Click:Connect(Minimize)
ClassicMin.MouseButton1Click:Connect(Minimize)

MaximizeButton.MouseButton1Click:Connect(function()
	if minimized then return end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	if isMaximized then
		isMaximized = false
		local targetSize = PreMaxSize or UDim2.new(0, 480, 0, 300)
		local targetPos = PreMaxPos or UDim2.fromScale(0.5, 0.5)
		local s = math.min((vp.X-20)/480, (vp.Y-40)/300)
		s = math.clamp(s, 0.5, 1)
		TweenService:Create(UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = s}):Play()
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize, Position = targetPos}):Play()
		task.delay(0.4, function()
			if not isMaximized and not minimized then NormalSize = Main.Size NormalPosition = Main.Position end
		end)
	else
		isMaximized = true
		PreMaxSize = Main.Size
		PreMaxPos = Main.Position
		local maxW = math.max(vp.X - 30, 480)
		local maxH = math.max(vp.Y - 30, 300)
		TweenService:Create(UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(maxW, maxH), Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
end)

if not UserInputService.TouchEnabled then
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not unlocked then return end
		if input.KeyCode == CurrentKey then
			if minimized then Restore() else Minimize() end
		end
	end)
end

local reopenDragging, reopenMoved, reopenDragStart, reopenStartPos = false, false, nil, nil
Reopen.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		reopenDragging = true
		reopenMoved = false
		reopenDragStart = input.Position
		reopenStartPos = Reopen.Position
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				reopenDragging = false
				if conn then conn:Disconnect() end
				if not reopenMoved then Restore() end
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not reopenDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - reopenDragStart
		if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then reopenMoved = true end
		local newPos = UDim2.new(reopenStartPos.X.Scale, reopenStartPos.X.Offset+delta.X, reopenStartPos.Y.Scale, reopenStartPos.Y.Offset+delta.Y)
		Reopen.Position = newPos
		reopenSavedPos = newPos
	end
end)

local dragging, dragStart, startPos, dragConn = false, nil, nil, nil
Top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		if dragConn then dragConn:Disconnect() end
		dragConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if dragConn then dragConn:Disconnect() dragConn = nil end
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
		if not isMaximized then NormalPosition = Main.Position end
	end
end)

-- ============================================================
-- API
-- ============================================================
local Library = {
	GUI = GUI,
	Window = Main,
	Content = Content,
	ACCENT = ACCENT,
	WHITE = WHITE,
	Pages = {
		Home = HomePage, Scripts = ScriptsPage,
		Fling = FlingPage, Skys = SkysPage,
		Animations = AnimationsPage, Settings = SettingsPage,
	},
	Tabs = { MainScript = MainScriptTab, Extra = ExtraTab },
	Services = {
		Players = Players, Player = Player, PlayerGui = PlayerGui,
		TweenService = TweenService, UserInputService = UserInputService,
		RunService = RunService, HttpService = HttpService,
		Lighting = Lighting, SoundService = SoundService,
		ReplicatedStorage = ReplicatedStorage, Debris = Debris,
		CoreGui = CoreGui, Workspace = workspace,
	},
	CreateToggle = CreateToggle,
	ShowNotif = ShowNotif,
	RegisterExclusive = RegisterExclusive,
	AddButtonSweep = AddButtonSweep,
	SaveActiveToggles = SaveActiveToggles,
	RefreshMostUsed = RefreshMostUsed,
	ToggleRegistry = ToggleRegistry,
	LoadActiveToggles = LoadActiveToggles,
	SwitchPage = SwitchPage,
	cleanGuis = cleanGuis,
	OnLogin = function(fn) table.insert(_onLoginCallbacks, fn) end,
	IsLoggedIn = function() return unlocked end,
}

if HasSession() and isWhitelisted(Player.Name) then
	task.defer(function()
		if GUI.Parent then LoginSuccess() end
	end)
end

return Library
