local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Workspace = workspace
local WHITE = Color3.new(1,1,1)

print("que te importa pendeja de mierda")

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
			if not data or #data < 100 then error("empty font") end
			writefile(ttfFile, data)
		end
	end)
	if not ok then return end
	pcall(function()
		local asset = getcustomasset(ttfFile)
		local jsonData = HttpService:JSONEncode({
			name = "Matcha",
			faces = {{name="Regular", weight=400, style="normal", assetId=asset}}
		})
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
	local t = tonumber(c)
	if not t then return false end
	return (os.time() - t) < 86400
end
local function SaveSession()
	pcall(function() if writefile then writefile("wb_session.txt", tostring(os.time())) end end)
end
local function LoadUsage()
	local ok, data = pcall(function() if readfile then return readfile("wb_usage.json") end end)
	if ok and data then
		local ok2, tbl = pcall(function() return HttpService:JSONDecode(data) end)
		if ok2 and type(tbl)=="table" then return tbl end
	end
	return {}
end
local function SaveUsage(tbl)
	pcall(function() if writefile then writefile("wb_usage.json", HttpService:JSONEncode(tbl)) end end)
end
local function LoadSaveData()
	local ok, data = pcall(function() if readfile then return readfile("wb_save_data.txt") end end)
	if not ok or not data then return false end
	return data == "1" or data == "true"
end
local function SaveSaveData(val)
	pcall(function() if writefile then writefile("wb_save_data.txt", val and "1" or "0") end end)
end
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
local function ClearSavedToggles()
	pcall(function() if writefile then writefile("wb_saved_toggles.json", "[]") end end)
end
local function LoadNotifRead()
	local ok, data = pcall(function() if readfile then return readfile("wb_notif_read.txt") end end)
	if not ok or not data then return false end
	return data == "1" or data == "true"
end
local function SaveNotifRead()
	pcall(function() if writefile then writefile("wb_notif_read.txt", "1") end end)
end

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

GUI.DescendantAdded:Connect(function(obj)
	task.defer(function() if MatchaFont then ApplyFont(obj) end end)
end)
task.spawn(function()
	while not FontReady do task.wait(0.1) end
	for _, obj in ipairs(GUI:GetDescendants()) do ApplyFont(obj) end
end)

local ACCENT = Color3.fromRGB(62,215,98)
local buttonStyle = "New"
local activeTab = nil
local activePill = nil

local function AddButtonSweep(btn, stroke)
	if not btn then return end
	if btn:FindFirstChild("SweepHolder") then return end
	if stroke then
		stroke.Color = Color3.fromRGB(255,255,255)
		stroke.Thickness = 1
		stroke.Transparency = 0.82
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	local sweepHolder = Instance.new("Frame")
	sweepHolder.Name = "SweepHolder"
	sweepHolder.Size = UDim2.new(1,0,1,0)
	sweepHolder.BackgroundTransparency = 1
	sweepHolder.ClipsDescendants = true
	sweepHolder.ZIndex = 5
	sweepHolder.Parent = btn
	Instance.new("UICorner", sweepHolder).CornerRadius = UDim.new(0,10)
	local sweep = Instance.new("Frame")
	sweep.Name = "SweepOverlay"
	sweep.Size = UDim2.new(0, 40, 1, 0)
	sweep.Position = UDim2.new(0, -40, 0, 0)
	sweep.BackgroundColor3 = Color3.fromRGB(255,255,255)
	sweep.BackgroundTransparency = 0.94
	sweep.BorderSizePixel = 0
	sweep.ZIndex = 6
	sweep.Parent = sweepHolder
	local grad = Instance.new("UIGradient", sweep)
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	local sweeping = false
	btn.MouseEnter:Connect(function()
		if stroke then TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play() end
		if sweeping then return end
		sweeping = true
		sweep.Position = UDim2.new(0, -40, 0, 0)
		local tw = TweenService:Create(sweep, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0, 0, 0)})
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
	s.Color = Color3.fromRGB(255,255,255)
	s.Transparency = 0.72
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
NDS.Color = Color3.fromRGB(10,10,14)
NDS.Thickness = 2
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
ProfileStroke.Color = ACCENT
ProfileStroke.Thickness = 3

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
PassStroke.Color = ACCENT
PassStroke.Thickness = 1.5

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
EnterStroke.Color = ACCENT
EnterStroke.Thickness = 1.5

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
BigStroke.Color = ACCENT
BigStroke.Thickness = 3

local OnlineDot = Instance.new("Frame")
OnlineDot.Size = UDim2.fromOffset(22,22)
OnlineDot.Position = UDim2.new(1,-16,1,-16)
OnlineDot.BackgroundColor3 = ACCENT
OnlineDot.BorderSizePixel = 0
OnlineDot.ZIndex = 5
OnlineDot.Parent = BigProfile
Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1,0)
local OS = Instance.new("UIStroke", OnlineDot)
OS.Color = Color3.fromRGB(10,10,14)
OS.Thickness = 3

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

function RefreshMostUsed()
	for _, c in ipairs(MostUsedList:GetChildren()) do
		if c ~= mul then c:Destroy() end
	end
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
		lbl.Text = "No usage data yet"
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
			TweenService:Create(msknob, TweenInfo.new(0.15), {
				Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.fromOffset(2,2)
			}):Play()
		end
		if registry then
			updateMSVisual(registry.getActive())
			msc.MouseButton1Click:Connect(function()
				registry.setActive(not registry.getActive())
			end)
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
	local core = game:GetService("CoreGui")
	for _, gui in ipairs(core:GetChildren()) do
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
		TweenService:Create(knob, TweenInfo.new(0.15), {
			Position = v and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)
		}):Play()
	end
	local function registerUsage()
		ToggleUsage[text] = (ToggleUsage[text] or 0) + 1
		SaveUsage(ToggleUsage)
	end
	btn.MouseButton1Click:Connect(function()
		active = not active
		if active then registerUsage() end
		setVisual(active)
		pcall(callback, active)
		pcall(SaveActiveToggles)
	end)
	ToggleRegistry[text] = {
		getActive = function() return active end,
		setActive = function(v)
			if v == active then return end
			active = v
			if active then registerUsage() end
			setVisual(active)
			pcall(callback, active)
			pcall(SaveActiveToggles)
		end
	}
	table.insert(AllToggles, {btn=btn, label=label, text=text, parent=parent})
	task.defer(function() AddButtonSweep(btn, stroke) end)
	return btn
end

local function Defer(fn)
	task.defer(function() pcall(fn) end)
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
			TweenService:Create(oldPill, TweenInfo.new(0.18), {
				BackgroundColor3 = Color3.fromRGB(20,20,26),
				TextColor3 = Color3.fromRGB(225,225,232)
			}):Play()
			local ps = oldPill:FindFirstChildOfClass("UIStroke")
			if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color=Color3.fromRGB(255,255,255), Transparency = 0.82}):Play() end
		end
		task.delay(0.18, function()
			if oldTab then
				oldTab.Visible = false
				oldTab.Position = UDim2.new(0,0,0,0)
			end
		end)
	end
	activeTab = tab
	activePill = pill
	tab.Visible = true
	tab.Position = UDim2.new(0.15,0,0,0)
	TweenService:Create(tab, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play()
	TweenService:Create(pill, TweenInfo.new(0.18), {
		BackgroundColor3 = ACCENT:Lerp(Color3.new(0,0,0),0.7),
		TextColor3 = ACCENT:Lerp(Color3.new(1,1,1),0.5)
	}):Play()
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
StyleLabel.Text = "Button style"
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
SaveDataLabel.Text = "Save Data"
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
SD_Title.Text = "Save active scripts"
SD_Title.TextXAlignment = Enum.TextXAlignment.Left
SD_Title.TextColor3 = Color3.fromRGB(225,225,232)
SD_Title.TextSize = 12
SD_Title.Font = Enum.Font.GothamBold
SD_Title.Parent = SaveDataBtn

local SD_Sub = Instance.new("TextLabel")
SD_Sub.Size = UDim2.new(1,-70,0,14)
SD_Sub.Position = UDim2.new(0,14,0,22)
SD_Sub.BackgroundTransparency = 1
SD_Sub.Text = "Reload saved scripts on next join"
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
	TweenService:Create(SD_Knob, TweenInfo.new(0.15), {
		Position = SaveDataEnabled and UDim2.new(1,-18,0.5,-8) or UDim2.fromOffset(2,2)
	}):Play()
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
KeybindLabel.Text = "Minimize keybind"
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
	KeybindBtn.Text = "Press any key..."
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
	TweenService:Create(NavPill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, x, 0, 4),
		Size = UDim2.fromOffset(w, 46)
	}):Play()
end

local function ApplyAccent(c)
	ACCENT = c
	ProfileStroke.Color = c
	BigStroke.Color = c
	OnlineDot.BackgroundColor3 = c
	PassStroke.Color = c
	EnterStroke.Color = c
	Status.TextColor3 = c
	if Rank.Visible and getRank(Player.Name) == "MEMBER" then Rank.TextColor3 = c end
	if activePill then
		local ps = activePill:FindFirstChildOfClass("UIStroke")
		if ps then ps.Color = c end
		TweenService:Create(activePill, TweenInfo.new(0.2), {
			BackgroundColor3 = c:Lerp(Color3.new(0,0,0),0.7),
			TextColor3 = c:Lerp(Color3.new(1,1,1),0.5)
		}):Play()
	end
	if buttonStyle == "New" then
		TweenService:Create(NewOption, TweenInfo.new(0.2), {BackgroundColor3=c,TextColor3=Color3.fromRGB(20,20,24)}):Play()
	else
		TweenService:Create(ClassicOption, TweenInfo.new(0.2), {BackgroundColor3=c,TextColor3=Color3.fromRGB(20,20,24)}):Play()
	end
end

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1,-20,0,14)
Watermark.Position = UDim2.new(0,10,1,-72)
Watermark.BackgroundTransparency = 1
Watermark.Text = "Panel created by Sam"
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
NotifPanelTitle.Text = "Notifications"
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
NotifEntryTitle.Text = "New Update!"
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
NotifEntryText.Text = "Next update Sunday will bring more than 20 new skyboxes!"
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
ReadBtn.Text = "Read"
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
end

local function TryLogin()
	if unlocked then return end
	if not isWhitelisted(Player.Name) then Error.Text = "You are not whitelisted" return end
	if Password.Text == "sam2027" then
		Error.Text = ""
		SaveSession()
		LoginSuccess()
	else
		Error.Text = "Incorrect password"
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
	ReadBtn.Text = "Read ✓"
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
	ReadBtn.Text = "Read ✓"
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
	TweenService:Create(Reopen, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0,0),
		Position = UDim2.new(reopenSavedPos.X.Scale, reopenSavedPos.X.Offset+26, reopenSavedPos.Y.Scale, reopenSavedPos.Y.Offset-10)
	}):Play()
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
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = targetSize,
			Position = targetPos
		}):Play()
		task.delay(0.4, function()
			if not isMaximized and not minimized then
				NormalSize = Main.Size
				NormalPosition = Main.Position
			end
		end)
	else
		isMaximized = true
		PreMaxSize = Main.Size
		PreMaxPos = Main.Position
		local maxW = math.max(vp.X - 30, 480)
		local maxH = math.max(vp.Y - 30, 300)
		TweenService:Create(UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(maxW, maxH),
			Position = UDim2.fromScale(0.5, 0.5)
		}):Play()
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

pcall(function()
	local speedActive = false
	local offsetAmount = Vector3.new(0,0,5.2)
	local weightMass = 20.6
	local weightName = "CoMWeight_Object"
	local currentRotSpeed = 0
	local lastLook = workspace.CurrentCamera.CFrame.LookVector
	local function applyWeight(character)
		local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",5)
		if not root then return end
		local ex = character:FindFirstChild(weightName); if ex then ex:Destroy() end
		local w = Instance.new("Part")
		w.Name = weightName; w.Size = Vector3.new(1,1,1); w.Transparency = 1
		w.CanCollide = false; w.CanQuery = false; w.Massless = false; w.Parent = character
		w.CustomPhysicalProperties = PhysicalProperties.new(weightMass,.3,.5)
		local weld = Instance.new("Weld")
		weld.Part0 = root; weld.Part1 = w; weld.C0 = CFrame.new(offsetAmount); weld.Parent = w
	end
	local function removeWeight()
		local character = Player.Character
		if not character then return end
		local ex = character:FindFirstChild(weightName); if ex then ex:Destroy() end
	end
	CreateToggle(MainScriptTab, "SPEED", function(state)
		speedActive = state
		if state then
			if Player.Character then applyWeight(Player.Character) end
		else removeWeight() end
	end, 1)
	RunService.RenderStepped:Connect(function(dt)
		if not speedActive then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local currentLook = cam.CFrame.LookVector
		currentRotSpeed = (currentLook-lastLook).Magnitude / math.max(dt,.001)
		lastLook = currentLook
		local character = Player.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end
		local moveDir = humanoid.MoveDirection
		if moveDir.Magnitude > .1 then
			local isMovingBack = moveDir:Dot(currentLook) < -.35
			if isMovingBack and currentRotSpeed > 8 then
				local boostPower = math.clamp(currentRotSpeed * 1.15,0,52)
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + (moveDir.Unit * boostPower * dt * 42)
			end
		end
	end)
	Player.CharacterAdded:Connect(function(character)
		task.wait(.5)
		if speedActive then applyWeight(character) end
	end)
end)

pcall(function()
	local loaded = false
	CreateToggle(MainScriptTab, "SPEED 2", function(state)
		_G.Speed2Active = state
		if state and not loaded then
			loaded = true
			task.spawn(function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/bitotoso/speed/refs/heads/main/script.lua"))() end) end)
		end
		if not state then
			loaded = false
			if Player.Character then local gp = Player.Character:FindFirstChild("GlitchPart"); if gp then gp:Destroy() end end
			pcall(function() if _G.Speed2Cleanup then _G.Speed2Cleanup() end end)
		end
	end, 2)
end)

pcall(function()
	local loaded = false
	CreateToggle(MainScriptTab, "2020 SPEED", function(state)
		_G.Speed2020Active = state
		if state and not loaded then
			loaded = true
			task.spawn(function() pcall(function() loadstring(game:HttpGet("https://pastefy.app/OQYsFdA0/raw"))() end) end)
		end
		if not state then
			loaded = false
			if Player.Character then local g = Player.Character:FindFirstChild("NatanOldSpeed_Active"); if g then g:Destroy() end end
			pcall(function() if _G.Speed2020Cleanup then _G.Speed2020Cleanup() end end)
		end
	end, 3)
end)

Defer(function()
	local loaded = false
	local toolNames = {"SnowballToy","Speed Coil","Gravity Coil","Dual Gravity Coil","WaterBalloon","Color Candy","RainbowMagicCarpet","Emotes"}
	local ALL_TOOLS_SCRIPT = [==[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RAINBOW_CARPET_ICON = "rbxthumb://type=Asset&w=150&h=150&id=223080070"
local ICON_Y_OFFSET_PX = -6
local function setupHandle(h) h.CanCollide=false h.CanQuery=false h.CanTouch=true h.Massless=true end
local function createSnowball()
    local t = Instance.new("Tool") t.Name = "SnowballToy" t.GripPos = Vector3.new(0.03, -0.24, -0.01) t.RequiresHandle = true
    t.TextureId = "rbxthumb://type=Asset&w=150&h=150&id=6123754554"
    local h = Instance.new("Part") h.Name = "Handle" h.Shape = Enum.PartType.Ball h.Size = Vector3.new(1,1,1)
    h.Material = Enum.Material.Sand h.Color = Color3.new(0.956863,0.968627,1) setupHandle(h) h.Parent = t
    local p1 = Instance.new("ParticleEmitter") p1.Texture = "rbxassetid://2346141109" p1.Enabled = false p1.Rate = 20
    p1.Speed = NumberRange.new(4,4) p1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1875),NumberSequenceKeypoint.new(0.726751,0),NumberSequenceKeypoint.new(1,0)}) p1.Parent = h
    local p2 = Instance.new("ParticleEmitter") p2.Texture = "rbxassetid://1539332776" p2.Enabled = false p2.Rate = 10
    p2.Speed = NumberRange.new(1,1) p2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(0.716258,0.560748),NumberSequenceKeypoint.new(1,0)}) p2.Parent = h
    local anim = Instance.new("Animation") anim.AnimationId = "rbxassetid://18324269091"
    local deb = false
    local function getTarget()
        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            local cam = workspace.CurrentCamera
            if cam then local vp = cam.ViewportSize/2 local ur = cam:ViewportPointToRay(vp.X,vp.Y) return ur.Origin + ur.Direction*1000 end
        end
        return Mouse.Hit.Position
    end
    t.Activated:Connect(function()
        if deb then return end deb = true
        local c = LocalPlayer.Character
        if not c then deb=false return end
        local hum = c:FindFirstChildOfClass("Humanoid") local r = c:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health<=0 or not r then deb=false return end
        local an = hum:FindFirstChildOfClass("Animator") if not an then an=Instance.new("Animator") an.Parent=hum end
        local tr = an:LoadAnimation(anim) tr.Priority = Enum.AnimationPriority.Action4 tr:Play()
        task.wait(0.7) if h then h.Transparency = 1 end
        if c.Parent and hum.Health>0 and r.Parent then
            local tp = getTarget() local ao = r.Position + Vector3.new(0,1.5,0) local rd = tp - ao
            local fs,ul = 120,25
            local fd = Vector3.new(rd.X,0,rd.Z)
            if fd.Magnitude>0.1 then fd=fd.Unit else fd=Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z).Unit end
            local rh = c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")
            local sp = (t.Parent==c and h) and h.Position or (rh and rh.Position or ao)
            local pr = Instance.new("Part") pr.Name = "SnowballProjectile" pr.Shape = Enum.PartType.Ball
            pr.Size = Vector3.new(1,1,1) pr.Material = Enum.Material.Sand
            pr.Color = Color3.new(0.956863,0.968627,1)
            pr.CanCollide=false pr.CanQuery=false pr.CanTouch=true pr.Massless=true
            pr.CFrame = CFrame.new(sp,sp+fd)
            pr.AssemblyLinearVelocity = fd*fs + Vector3.new(0,ul,0)
            pr.Parent = workspace
            local hc
            hc = pr.Touched:Connect(function(hit)
                if hit:IsDescendantOf(c) or hit.Name=="SnowballProjectile" then return end
                if hc then hc:Disconnect() hc=nil end
                local im = Instance.new("Part") im.Size = Vector3.new(0.1,0.1,0.1) im.Transparency=1 im.Anchored=true im.CanCollide=false im.CanQuery=false im.CanTouch=true
                im.CFrame = pr.CFrame im.Parent = workspace
                local b1 = p1:Clone() b1.SpreadAngle = Vector2.new(180,180) b1.Lifetime = NumberRange.new(1,1) b1.Parent = im
                local b2 = p2:Clone() b2.SpreadAngle = Vector2.new(90,90) b2.Lifetime = NumberRange.new(1,1) b2.Parent = im
                b1:Emit(10) b2:Emit(1) Debris:AddItem(im,1) pr:Destroy()
            end)
            Debris:AddItem(pr,4)
            task.delay(4,function() if hc then hc:Disconnect() hc=nil end end)
        end
        task.wait(2) if h then h.Transparency = 0 end task.wait(0.15) deb = false
    end)
    return t
end
local function createSpeedCoil()
    local t = Instance.new("Tool") t.Name = "Speed Coil" t.TextureId = "rbxassetid://99170415"
    local h = Instance.new("Part") h.Name="Handle" h.Size=Vector3.new(1,1.2,2) setupHandle(h) h.Parent=t
    local m = Instance.new("SpecialMesh") m.MeshType=Enum.MeshType.FileMesh m.MeshId="rbxassetid://16606212" m.TextureId="rbxassetid://99170547" m.Scale=Vector3.new(0.7,0.7,0.7) m.Parent=h
    local s = Instance.new("Sound") s.SoundId="rbxassetid://99173388" s.Volume=1 s.Parent=h
    t.Equipped:Connect(function() s:Play() local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed=32 end end)
    t.Unequipped:Connect(function() local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed=16 end end)
    return t
end
local function createGravityCoil()
    local t = Instance.new("Tool") t.Name = "Gravity Coil" t.TextureId = "rbxassetid://16619617"
    local h = Instance.new("Part") h.Name="Handle" h.Size=Vector3.new(1,1.2,2) setupHandle(h) h.Parent=t
    local m = Instance.new("SpecialMesh") m.MeshType=Enum.MeshType.FileMesh m.MeshId="rbxassetid://16606212" m.TextureId="rbxassetid://16606141" m.Scale=Vector3.new(0.7,0.7,0.7) m.Parent=h
    local s = Instance.new("Sound") s.SoundId="rbxassetid://16619553" s.Volume=1 s.Parent=h
    local cn, f
    t.Equipped:Connect(function() s:Play()
        local c = LocalPlayer.Character local r = c and c:FindFirstChild("HumanoidRootPart") local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not r or not hum then return end
        if hum.UseJumpPower then hum.JumpPower=72 else hum.JumpHeight=18 end
        f = Instance.new("BodyForce") f.Parent=r
        cn = RunService.Heartbeat:Connect(function() if r.Parent and f.Parent then f.Force = Vector3.new(0, r.AssemblyMass*workspace.Gravity*0.75, 0) end end)
    end)
    t.Unequipped:Connect(function()
        if cn then cn:Disconnect() cn=nil end if f then f:Destroy() f=nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then if hum.UseJumpPower then hum.JumpPower=50 else hum.JumpHeight=7.2 end end
    end)
    return t
end
local function createDualGravityCoil()
    local t = Instance.new("Tool") t.Name="Dual Gravity Coil" t.TextureId="rbxassetid://150063217"
    local h = Instance.new("Part") h.Name="Handle" h.Size=Vector3.new(0.2,0.2,0.2) h.Transparency=1 setupHandle(h) h.Parent=t
    local s = Instance.new("Sound") s.SoundId="rbxassetid://16619553" s.Volume=1 s.Parent=h
    local cn, f, lc, rc
    local function legCoil()
        local p = Instance.new("Part") p.Size=Vector3.new(1.2,1.2,1.2)
        p.CanCollide=false p.CanQuery=false p.CanTouch=true p.Massless=true p.Anchored=true
        local m = Instance.new("SpecialMesh") m.MeshType=Enum.MeshType.FileMesh m.MeshId="rbxassetid://16606212" m.TextureId="rbxassetid://150063177" m.Scale=Vector3.new(0.7,0.7,0.7) m.Parent=p
        return p
    end
    t.Equipped:Connect(function() s:Play()
        local c = LocalPlayer.Character local r = c and c:FindFirstChild("HumanoidRootPart") local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not r or not hum then return end
        local ll = c:FindFirstChild("LeftLowerLeg") or c:FindFirstChild("Left Leg")
        local rl = c:FindFirstChild("RightLowerLeg") or c:FindFirstChild("Right Leg")
        lc = legCoil() lc.Parent=workspace rc = legCoil() rc.Parent=workspace
        if hum.UseJumpPower then hum.JumpPower=72 else hum.JumpHeight=18 end
        f = Instance.new("BodyForce") f.Parent=r
        cn = RunService.Heartbeat:Connect(function()
            if r.Parent and f.Parent then f.Force = Vector3.new(0, r.AssemblyMass*workspace.Gravity*0.75, 0) end
            if ll and ll.Parent and lc then lc.CFrame = CFrame.new(ll.Position)*CFrame.Angles(math.rad(90),0,0) end
            if rl and rl.Parent and rc then rc.CFrame = CFrame.new(rl.Position)*CFrame.Angles(math.rad(90),0,0) end
        end)
    end)
    t.Unequipped:Connect(function()
        if cn then cn:Disconnect() cn=nil end if f then f:Destroy() f=nil end
        if lc then lc:Destroy() lc=nil end if rc then rc:Destroy() rc=nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then if hum.UseJumpPower then hum.JumpPower=50 else hum.JumpHeight=7.2 end end
    end)
    return t
end
local function createWaterBalloon()
    local MESH="rbxassetid://95815241513987" local ICON="rbxassetid://18335937543" local ANIM="rbxassetid://18324269091"
    local COL=Color3.fromRGB(226,78,94) local CD=5
    local BG=CFrame.new(0,-0.05,-0.15,-0.866025448,-0.129409596,0.482962877,-5.82214419e-08,0.9659258,0.25881904,-0.5,-0.22414386,-0.8365163)
    local P=Vector3.new(0.023,-0.277,0.057) local R=Vector3.new(-15,0,0)
    local function grip() return BG*CFrame.new(P.X,P.Y,P.Z)*CFrame.Angles(math.rad(R.X),math.rad(R.Y),math.rad(R.Z)) end
    local function splash(pos)
        local p=Instance.new("Part") p.Position=pos p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=true p.Transparency=1 p.Parent=workspace
        local a=Instance.new("Attachment") a.Parent=p
        local s=Instance.new("ParticleEmitter")
        s.Texture="rbxassetid://90910640571504"
        s.Color=ColorSequence.new(Color3.fromRGB(70,150,255),Color3.fromRGB(120,190,255))
        s.LightEmission=0.6
        s.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(0.7,0.3),NumberSequenceKeypoint.new(1,1)})
        s.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.65),NumberSequenceKeypoint.new(0.5,1.5),NumberSequenceKeypoint.new(1,2)})
        s.Lifetime=NumberRange.new(0.8,0.8) s.Speed=NumberRange.new(1.5,3) s.SpreadAngle=Vector2.new(180,180) s.Rotation=NumberRange.new(0,360)
        s.RotSpeed=NumberRange.new(-60,60) s.Acceleration=Vector3.new(0,0.5,0) s.Drag=3 s.Rate=0 s.Parent=a s:Emit(15) Debris:AddItem(p,1.5)
    end
    local function playAnim(c)
        local hum = c and c:FindFirstChildOfClass("Humanoid") if not hum then return end
        local an = hum:FindFirstChildOfClass("Animator") if not an then an=Instance.new("Animator") an.Parent=hum end
        local a = Instance.new("Animation") a.AnimationId=ANIM local t = an:LoadAnimation(a) t.Priority=Enum.AnimationPriority.Action t:Play(0.05,1,1) Debris:AddItem(a,2)
    end
    local t = Instance.new("Tool") t.Name="WaterBalloon" t.TextureId=ICON t.RequiresHandle=true t.CanBeDropped=false t.Grip=grip()
    local h = Instance.new("Part") h.Name="Handle" h.Size=Vector3.new(1,1,1) h.Color=COL h.Material=Enum.Material.SmoothPlastic h.Transparency=0
    setupHandle(h) h.Parent=t
    local m = Instance.new("SpecialMesh") m.MeshType=Enum.MeshType.FileMesh m.MeshId=MESH m.Scale=Vector3.new(0.879,1.025,1) m.Parent=h
    local eq, cd = false, false
    t.Equipped:Connect(function() eq=true h.Transparency=0 end)
    t.Unequipped:Connect(function() eq=false end)
    t.Activated:Connect(function()
        if cd then return end cd=true
        local c=LocalPlayer.Character if not c then cd=false return end
        playAnim(c) task.wait(0.8)
        if c and c.PrimaryPart then
            local rh=c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")
            local sp = rh and rh.Position or c.PrimaryPart.Position
            local tp = Mouse.Hit.Position
            local dv = tp-sp local d = dv.Magnitude
            if d>250 and dv.Magnitude>0 then d=250 tp=sp+dv.Unit*d end
            local pr=Instance.new("Part") pr.Name="ThrownBalloon" pr.Size=Vector3.new(1,1,1)
            pr.CFrame=CFrame.new(sp,tp) pr.Color=COL pr.Material=Enum.Material.SmoothPlastic
            pr.CanCollide=true pr.CanQuery=false pr.CanTouch=true pr.Parent=workspace
            local pm = m:Clone() pm.Parent=pr
            local spd=80 local tt=math.max(d/spd,0.05)
            pr.AssemblyLinearVelocity = (tp-sp)/tt + Vector3.new(0,workspace.Gravity*tt*0.5,0)
            if eq then h.Transparency=1 end
            local cn
            cn = pr.Touched:Connect(function(hit)
                if hit:IsDescendantOf(c) then return end
                if cn then cn:Disconnect() cn=nil end
                splash(pr.Position) pr:Destroy()
            end)
            Debris:AddItem(pr,5)
            task.delay(5,function() if cn then cn:Disconnect() cn=nil end end)
        end
        task.wait(math.max(0,CD-0.8)) if eq then h.Transparency=0 end cd=false
    end)
    return t
end
local function createColorCandy()
    local COL={Color3.fromRGB(255,220,0),Color3.fromRGB(255,20,147),Color3.fromRGB(0,170,255)}
    local t = Instance.new("Tool") t.Name="Color Candy" t.RequiresHandle=true t.CanBeDropped=false
    t.TextureId="rbxassetid://75322375368971" t.Grip=CFrame.new(0,-0.3,0.2)
    local ci=1
    local h = Instance.new("Part") h.Name="Handle" h.Size=Vector3.new(1.7,1.7,1.7) h.Shape=Enum.PartType.Ball
    h.Color=COL[ci] h.Material=Enum.Material.SmoothPlastic setupHandle(h) h.Parent=t
    local r = Instance.new("Part") r.Shape=Enum.PartType.Cylinder r.Size=Vector3.new(0.17,1.8,1.8) r.Color=h.Color
    r.Material=Enum.Material.SmoothPlastic r.CanCollide=false r.CanQuery=false r.CanTouch=true r.CFrame=h.CFrame*CFrame.Angles(0,0,math.rad(90)) r.Parent=t
    local w = Instance.new("WeldConstraint") w.Part0=h w.Part1=r w.Parent=h
    local fi = Instance.new("Fire") fi.Size=3 fi.Heat=5 fi.Enabled=false fi.Parent=h
    local ic=0
    local function nc()
        local ni repeat ni=math.random(1,#COL) until ni~=ci or #COL==1
        ci=ni local c = COL[ci] h.Color=c r.Color=c return c
    end
    t.Equipped:Connect(function() ic += 1 local c = nc() if ic>=10 then fi.Color=c fi.SecondaryColor=c fi.Enabled=true end end)
    t.Unequipped:Connect(function() ic += 1 nc() if fi.Enabled then fi.Enabled=false ic=0 end end)
    return t
end
local function createRainbowCarpet()
    for _, c in ipairs({LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}) do
        if c then for _, it in ipairs(c:GetChildren()) do if it:IsA("Tool") then local n=it.Name:lower() if n:find("rainbow") or n:find("carpet") then it:Destroy() end end end end
    end
    task.spawn(function()
        local seen = {}
        local function snap(c) if c then for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then seen[t]=true end end end end
        snap(LocalPlayer:FindFirstChild("Backpack")) snap(LocalPlayer.Character)
        pcall(function() loadstring(game:HttpGet("https://pastefy.app/4umk7tki/raw"))() end)
        task.wait(1.5)
        local function fix(c)
            if not c then return end
            for _, it in ipairs(c:GetChildren()) do
                if it:IsA("Tool") and not seen[it] then
                    local ln = it.Name:lower()
                    if ln:find("rainbow") or ln:find("carpet") then pcall(function() it.TextureId=RAINBOW_CARPET_ICON end) end
                end
            end
        end
        fix(LocalPlayer:FindFirstChild("Backpack")) fix(LocalPlayer.Character)
    end)
    return nil
end
local customTools = {
    {DisplayName="Snowball",ToolName="SnowballToy",Icon="rbxthumb://type=Asset&w=150&h=150&id=6123754554",Generator=createSnowball},
    {DisplayName="Speed Coil",ToolName="Speed Coil",Icon="rbxassetid://99170415",Generator=createSpeedCoil},
    {DisplayName="Gravity Coil",ToolName="Gravity Coil",Icon="rbxassetid://16619617",Generator=createGravityCoil},
    {DisplayName="Dual Gravity",ToolName="Dual Gravity Coil",Icon="rbxassetid://150063217",Generator=createDualGravityCoil},
    {DisplayName="Water Balloon",ToolName="WaterBalloon",Icon="rbxassetid://18335937543",Generator=createWaterBalloon},
    {DisplayName="Candy Toy",ToolName="Color Candy",Icon="rbxassetid://75322375368971",Generator=createColorCandy},
    {DisplayName="Rainbow Carpet",ToolName="RainbowMagicCarpet",Icon=RAINBOW_CARPET_ICON,Generator=createRainbowCarpet}
}
local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local toolLock = {}
local function giveAndEquip(td)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end
    if toolLock[td.ToolName] then return end
    toolLock[td.ToolName] = true
    task.delay(0.4, function() toolLock[td.ToolName] = nil end)
    local c = LocalPlayer.Character
    for _, cont in ipairs({bp, c}) do
        if cont then for _, ch in ipairs(cont:GetChildren()) do
            if ch:IsA("Tool") and ch.Name == td.ToolName then pcall(function() ch:Destroy() end) end
        end end
    end
    local tgt
    if c then tgt = c:FindFirstChild(td.ToolName) end
    if not tgt then tgt = bp:FindFirstChild(td.ToolName) end
    if not tgt then local g = td.Generator() if g then tgt = g tgt.Parent = bp end end
    if tgt and tgt.Parent ~= c then
        tgt.Parent = bp
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(tgt) end) end
    end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local cp = pGui:FindFirstChild("CrossPlatform")
        if cp then local ew = cp:FindFirstChild("EmoteWindow", true) if ew and ew:IsA("GuiObject") then ew.Visible = false end end
    end
end
local function getEmotePage()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui") if not pGui then return nil end
    local cp = pGui:FindFirstChild("CrossPlatform") if not cp then return nil end
    local e = cp:FindFirstChild("Emotes", true) if not e then return nil end
    local ew = e:FindFirstChild("EmoteWindow", true) if not ew then return nil end
    local ec = ew:FindFirstChild("EmoteContainer", true) if not ec then return nil end
    local ep = ec:FindFirstChild("EmotePages", true) if not ep then return nil end
    return ep:FindFirstChild("Game Emotes")
end
local _pConn = nil local _curPage = 1 local _totPages = 1
local function findLabel()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui") if not pGui then return nil end
    local cp = pGui:FindFirstChild("CrossPlatform") if not cp then return nil end
    for _, d in ipairs(cp:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and d.Text:find("Game Emotes",1,true) then return d end
    end
    return nil
end
local function isRow(n) if n:match("^Row%d+$") then return true end if n=="CustomToolsRow" then return true end if n:match("^CustomToolsRow_%d+$") then return true end return false end
local function getRows(p)
    local r={}
    for _, ch in ipairs(p:GetChildren()) do if ch:IsA("GuiObject") and isRow(ch.Name) then table.insert(r,ch) end end
    table.sort(r, function(a,b) return a.LayoutOrder < b.LayoutOrder end) return r
end
local function getVisRows(p)
    local r={}
    for _, ch in ipairs(p:GetChildren()) do if ch:IsA("GuiObject") and ch.Visible and ch.AbsoluteSize.Y>0 and isRow(ch.Name) then table.insert(r,ch) end end
    table.sort(r, function(a,b) return a.AbsolutePosition.Y < b.AbsolutePosition.Y end) return r
end
local function setupCounter(p)
    if _pConn then pcall(function() _pConn:Disconnect() end) _pConn=nil end
    local lbl = findLabel()
    if not lbl then task.wait(0.5) lbl = findLabel() end
    if not lbl then return end
    local rows = getRows(p) _totPages = #rows if _totPages<=0 then return end
    _curPage = math.clamp(_curPage,1,_totPages)
    local lastPage = _curPage local lastY = nil
    local function upd()
        if not lbl or not lbl.Parent then return end
        local ex = string.format("Game Emotes (%d/%d)",_curPage,_totPages)
        if lbl.Text~=ex then lbl.Text=ex end
    end
    local function det()
        if not p or not p.Parent then return end
        local r = getRows(p) if #r==0 then return end
        _totPages = #r local dp = _curPage
        if p:IsA("ScrollingFrame") then
            local cy = p.CanvasPosition.Y if lastY==nil then lastY=cy end
            local ci,cd = 1,math.huge
            for i,row in ipairs(r) do
                local rt = row.AbsolutePosition.Y - p.AbsolutePosition.Y + cy
                local d = math.abs(rt-cy) if d<cd then cd=d ci=i end
            end
            dp = ci
            if math.abs(cy-lastY)<0.5 and dp~=lastPage then dp=lastPage end
            lastY = cy
        else
            local vr = getVisRows(p)
            if #vr>0 then
                local ct = p.AbsolutePosition.Y local ci,cd = 1,math.huge
                for i,row in ipairs(vr) do local d = math.abs(row.AbsolutePosition.Y-ct) if d<cd then cd=d ci=i end end
                for i,row in ipairs(r) do if row==vr[ci] then dp=i break end end
            end
        end
        dp = math.clamp(dp,1,_totPages)
        if dp~=lastPage then lastPage=dp _curPage=dp upd() end
    end
    upd() _pConn = RunService.RenderStepped:Connect(det)
end
local function createSlot(sc, td, idx)
    local s = sc:Clone() s.Name = "ToolSlot_"..idx
    for _, d in ipairs(s:GetDescendants()) do
        if d:IsA("TextLabel") then
            local txt = d.Text:gsub("[%s%.]+","")
            if tonumber(txt) then d.RichText=true d.Text='<font color="#FFFFFF">'..idx.."</font>" end
        end
    end
    local nl = s:FindFirstChild("EmoteName") or s:FindFirstChild("Title") or s:FindFirstChild("Name")
    if not nl then for _, d in ipairs(s:GetDescendants()) do if d:IsA("TextLabel") and d.Text~="" and d.Text~=tostring(idx) then nl=d break end end end
    if nl then nl.Text = td.DisplayName end
    for _, d in ipairs(s:GetDescendants()) do
        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
            d.Image = td.Icon
            d.Position = UDim2.new(d.Position.X.Scale,d.Position.X.Offset,d.Position.Y.Scale,d.Position.Y.Offset+ICON_Y_OFFSET_PX)
        end
    end
    local function click() giveAndEquip(td) end
    for _, b in ipairs(s:GetDescendants()) do if b:IsA("GuiButton") then b.Activated:Connect(click) end end
    if s:IsA("GuiButton") then s.Activated:Connect(click) end
    return s
end
local function inject()
    local p = getEmotePage()
    if not p then
        local pGui = LocalPlayer:WaitForChild("PlayerGui")
        local cp = pGui:WaitForChild("CrossPlatform",5) if not cp then return end
        p = getEmotePage()
    end
    if not p then return end
    if _pConn then pcall(function() _pConn:Disconnect() end) _pConn=nil end
    for _, ch in ipairs(p:GetChildren()) do if ch.Name=="CustomToolsRow" or ch.Name:match("^CustomToolsRow_") then ch:Destroy() end end
    local rows={}
    for _, ch in ipairs(p:GetChildren()) do if ch:IsA("GuiObject") and ch.Name:match("^Row%d+$") then table.insert(rows,ch) end end
    table.sort(rows, function(a,b) return a.LayoutOrder < b.LayoutOrder end)
    local last = rows[#rows]
    if not last then for _, ch in ipairs(p:GetChildren()) do if ch:IsA("GuiObject") then last=ch break end end end
    if not last then return end
    local tmpl = last:FindFirstChild("Emote1") or last:FindFirstChildOfClass("GuiButton") or last:FindFirstChildOfClass("Frame")
    if not tmpl then return end
    local chunks = {}
    if isMobileDevice and #customTools>4 then
        for i=1,#customTools,4 do
            local c={} for j=i,math.min(i+3,#customTools) do table.insert(c,customTools[j]) end
            table.insert(chunks,c)
        end
    else table.insert(chunks, customTools) end
    local hasLL = p:FindFirstChildOfClass("UIListLayout") ~= nil
    local bx,by = last.Position.X, last.Position.Y
    local rh = last.AbsoluteSize.Y if rh==0 then rh = last.Size.Y.Offset end if rh==0 then rh = 80 end
    for ci,ch in ipairs(chunks) do
        local nr = last:Clone()
        nr.Name = (ci==1) and "CustomToolsRow" or ("CustomToolsRow_"..ci)
        local sc = tmpl:Clone()
        for _, c in ipairs(nr:GetChildren()) do if c.Name:match("^Emote") or c.Name:match("^ToolSlot") then c:Destroy() end end
        for i,td in ipairs(ch) do local s = createSlot(sc, td, i) s.Parent = nr end
        nr.Parent = p
        if ci>1 and not hasLL then nr.Position = UDim2.new(bx.Scale,bx.Offset,by.Scale,by.Offset+(rh+8)*(ci-1)) end
    end
    sc = nil task.wait(0.25) _curPage = 1 setupCounter(p)
end
task.spawn(function() task.wait(1.5) inject() end)
]==]

	CreateToggle(MainScriptTab, "ALL TOOLS", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(ALL_TOOLS_SCRIPT)() end) end)
			end
		else
			loaded = false
			for _, n in ipairs(toolNames) do
				local bp = Player:FindFirstChild("Backpack")
				if bp then local t = bp:FindFirstChild(n); if t then pcall(function() t:Destroy() end) end end
				if Player.Character then local t = Player.Character:FindFirstChild(n); if t then pcall(function() t:Destroy() end) end end
				local sg = Player:FindFirstChild("StarterGear")
				if sg then local t = sg:FindFirstChild(n); if t then pcall(function() t:Destroy() end) end end
			end
			pcall(function()
				local pGui = Player:FindFirstChild("PlayerGui")
				if not pGui then return end
				for _, gui in ipairs(pGui:GetChildren()) do
					for _, d in ipairs(gui:GetDescendants()) do
						local n = tostring(d.Name)
						if n == "CustomToolsRow" or n:match("^CustomToolsRow_") then pcall(function() d:Destroy() end) end
						if d:IsA("TextLabel") and d.Text and d.Text:match("^Game Emotes %(") then pcall(function() d.Text = "Game Emotes" end) end
					end
				end
			end)
			pcall(function()
				if _G.AllTools_Cleanup then _G.AllTools_Cleanup() end
				if _G.FE_Cleanup then _G.FE_Cleanup() end
			end)
		end
	end, 4)
end)

pcall(function()
	local loaded = false
	local somConnection = nil
	local function aplicarAjuste(som)
		if not som:IsA("Sound") then return end
		if som:FindFirstChild("Configurado") then return end
		local marcador = Instance.new("BoolValue")
		marcador.Name = "Configurado" marcador.Parent = som
		som.Volume = 0.75
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain = 8 eq.MidGain = -12 eq.HighGain = 5 eq.Parent = som
		local comp = Instance.new("CompressorSoundEffect")
		comp.Threshold = -20 comp.Ratio = 4 comp.Attack = 0.01 comp.Parent = som
	end
	local function cleanupAll()
		for _, s in ipairs(SoundService:GetDescendants()) do
			if s:IsA("Sound") then
				pcall(function()
					local comp = s:FindFirstChildOfClass("CompressorSoundEffect"); if comp then comp:Destroy() end
					local eq = s:FindFirstChildOfClass("EqualizerSoundEffect"); if eq then eq:Destroy() end
					local cfg = s:FindFirstChild("Configurado"); if cfg then cfg:Destroy() end
					s.Volume = 1
				end)
			end
		end
		for _, s in ipairs(Lighting:GetDescendants()) do
			if s:IsA("Sound") then
				pcall(function()
					local eq = s:FindFirstChildOfClass("EqualizerSoundEffect"); if eq then eq:Destroy() end
					local comp = s:FindFirstChildOfClass("CompressorSoundEffect"); if comp then comp:Destroy() end
					local cfg = s:FindFirstChild("Configurado"); if cfg then cfg:Destroy() end
					s.Volume = 1
				end)
			end
		end
	end
	CreateToggle(MainScriptTab, "SOM ABAFADO", function(state)
		if state then
			if not loaded then
				loaded = true
				for _, v in pairs(game:GetDescendants()) do aplicarAjuste(v) end
				somConnection = game.DescendantAdded:Connect(aplicarAjuste)
			end
		else
			loaded = false
			if somConnection then pcall(function() somConnection:Disconnect() end) somConnection = nil end
			cleanupAll()
		end
	end, 5)
end)

pcall(function()
	local conn = nil
	local saved = {}
	CreateToggle(MainScriptTab, "HALLOWEEN QUALITY", function(state)
		if state then
			saved.FogColor = Lighting.FogColor; saved.FogStart = Lighting.FogStart
			saved.FogEnd = Lighting.FogEnd; saved.ClockTime = Lighting.ClockTime
			saved.Brightness = Lighting.Brightness; saved.GlobalShadows = Lighting.GlobalShadows
			Lighting.FogColor = Color3.fromRGB(15,15,15); Lighting.FogStart = 10; Lighting.FogEnd = 135
			Lighting.ClockTime = 0; Lighting.Brightness = 3; Lighting.GlobalShadows = false
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then v.Brightness = v.Brightness * 0.5 end
			end
			conn = Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
				if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
			end)
		else
			Lighting.FogColor = saved.FogColor or Color3.fromRGB(192,192,192)
			Lighting.FogStart = saved.FogStart or 0; Lighting.FogEnd = saved.FogEnd or 100000
			Lighting.ClockTime = saved.ClockTime or 14; Lighting.Brightness = saved.Brightness or 1
			Lighting.GlobalShadows = saved.GlobalShadows or true
			if conn then conn:Disconnect() conn = nil end
		end
	end, 6)
end)

Defer(function()
	local loaded = false
	local OLD_GRAPHICS_2_SCRIPT = [==[
local Lighting  = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ORIGINAL_LIGHTING = {
	Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
	FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
	ExposureCompensation = Lighting.ExposureCompensation, GeographicLatitude = Lighting.GeographicLatitude,
	GlobalShadows = Lighting.GlobalShadows, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale, ClockTime = Lighting.ClockTime,
	ShadowSoftness = Lighting.ShadowSoftness,
}
local SOFT_SHADOW_STRENGTH = 0.5
local SOFTER_AMBIENT = Color3.fromRGB(88, 86, 84)
local SOFTER_OUTDOOR = Color3.fromRGB(100, 97, 94)
local SOFTER_DIFFUSE = 0.15
local SOFTER_SPECULAR = 0
local BASE_FOG_COLOR = Color3.fromRGB(145, 140, 135)
local MAP_CONFIG = {
	["Bank 2"] = { x = 47, y = 60, z = 25, light = 100, lightColor = 26 },
	["Bio Lab"] = { x = 47, y = 55, z = 37, light = 100, lightColor = 36 },
	["Factory"] = { x = 53, y = 56, z = 47, light = 47, lightColor = 88 },
	["Hospital 3"] = { x = 45, y = 44, z = 41, light = 33, lightColor = 20 },
	["Hotel 2"] = { x = 47, y = 89, z = 35, light = 27, lightColor = 8 },
	["House 2"] = { x = 46, y = 77, z = 44, light = 45, lightColor = 50 },
	["Mansion 2"] = { x = 53, y = 72, z = 40, light = 16, lightColor = 0 },
	["Mil Base"] = { x = 50, y = 58, z = 40, light = 63, lightColor = 0, defaultLighting = true },
	["Office 3"] = { x = 53, y = 57, z = 36, light = 43, lightColor = 0 },
	["Police Station"] = { x = 51, y = 76, z = 32, light = 19, lightColor = 0 },
	["Research Facility"] = { x = 52, y = 55, z = 26, light = 80, lightColor = 0 },
	["Workplace"] = { x = 53, y = 63, z = 40, light = 42, lightColor = 0 },
}
local MAP_KEYWORDS = {
	["Bank 2"] = { "bank" }, ["Bio Lab"] = { "biolab", "bio_lab", "bio lab", "lab" },
	["Factory"] = { "factory" }, ["Hospital 3"] = { "hospital" }, ["Hotel 2"] = { "hotel" },
	["House 2"] = { "house" }, ["Mansion 2"] = { "mansion" },
	["Mil Base"] = { "milbase", "mil_base", "mil base", "military" }, ["Office 3"] = { "office" },
	["Police Station"] = { "police" }, ["Research Facility"] = { "research" },
	["Workplace"] = { "workplace", "work place" },
}
local LightCache = {}
local function clearModernEffects()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("SunRaysEffect") or child:IsA("BloomEffect")
		or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect") then child:Destroy() end
	end
end
local function detectMapName()
	local containers = { Model = true, Folder = true, Configuration = true }
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if containers[obj.ClassName] then
			local n = obj.Name:lower()
			for mapName, keywords in pairs(MAP_KEYWORDS) do
				for _, kw in ipairs(keywords) do if n == kw or n:find(kw, 1, true) then return mapName end end
			end
		end
	end
	return nil
end
local function isColoredLight(light)
	local c = light.Color
	return (math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B)) > 0.15
end
local function cacheLight(light)
	if LightCache[light] then return end
	if not (light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight")) then return end
	LightCache[light] = { b = light.Brightness, colored = isColoredLight(light), originalColor = light.Color }
end
local function scanAllLights()
	for _, obj in ipairs(Workspace:GetDescendants()) do cacheLight(obj) end
end
local function shouldIgnoreShadow(part)
	if not part:IsA("BasePart") then return true end
	local size = part.Size
	if size.X >= 40 or size.Y >= 40 or size.Z >= 40 then return true end
	local name = part.Name:lower()
	local ignoreNames = {"wall","roof","floor","ceiling","base","map","ground","sky","building","structure"}
	for _, keyword in ipairs(ignoreNames) do if name:find(keyword, 1, true) then return true end end
	return false
end
local function applyShadowToPart(part) part.CastShadow = not shouldIgnoreShadow(part) end
local function applyShadowsToWorkspace()
	for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") then applyShadowToPart(obj) end end
end
local function applyAllLights(mapName)
	local cfg = mapName and MAP_CONFIG[mapName]
	local fw = (cfg and cfg.light or 100) / 100
	local fc = (cfg and cfg.lightColor or 100) / 100
	for light, data in pairs(LightCache) do
		if light and light.Parent then
			local f = data.colored and fc or fw
			light.Brightness = data.b * f
			light.Enabled = f > 0.01
			light.Color = data.originalColor
		end
	end
end
local function softenShadows() Lighting.ShadowSoftness = SOFT_SHADOW_STRENGTH end
local function applyMapConfig(mapName)
	local cfg = mapName and MAP_CONFIG[mapName]
	local useDefaultLighting = cfg and cfg.defaultLighting
	if useDefaultLighting then
		Lighting.Brightness = ORIGINAL_LIGHTING.Brightness
		Lighting.Ambient = ORIGINAL_LIGHTING.Ambient
		Lighting.OutdoorAmbient = ORIGINAL_LIGHTING.OutdoorAmbient
		Lighting.FogColor = ORIGINAL_LIGHTING.FogColor
		Lighting.FogStart = ORIGINAL_LIGHTING.FogStart
		Lighting.FogEnd = ORIGINAL_LIGHTING.FogEnd
		Lighting.ExposureCompensation = ORIGINAL_LIGHTING.ExposureCompensation
		Lighting.GeographicLatitude = ORIGINAL_LIGHTING.GeographicLatitude
		Lighting.GlobalShadows = ORIGINAL_LIGHTING.GlobalShadows
		Lighting.EnvironmentDiffuseScale = ORIGINAL_LIGHTING.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = ORIGINAL_LIGHTING.EnvironmentSpecularScale
		Lighting.ClockTime = 12
		softenShadows()
	else
		clearModernEffects()
		pcall(function() Lighting.Technology = Enum.Technology.ShadowMap end)
		Lighting.GlobalShadows = true
		Lighting.EnvironmentDiffuseScale = SOFTER_DIFFUSE
		Lighting.EnvironmentSpecularScale = SOFTER_SPECULAR
		if cfg then
			Lighting.ClockTime = (cfg.x / 100) * 24
			Lighting.GeographicLatitude = ((cfg.y / 100) * 160) - 80
			Lighting.ExposureCompensation = ((cfg.z / 100) * 4) - 2
		end
		Lighting.Brightness = ORIGINAL_LIGHTING.Brightness
		Lighting.Ambient = SOFTER_AMBIENT
		Lighting.OutdoorAmbient = SOFTER_OUTDOOR
		Lighting.FogColor = BASE_FOG_COLOR
		Lighting.FogStart = 500
		Lighting.FogEnd = 5000
		softenShadows()
	end
	applyShadowsToWorkspace()
	LightCache = {}
	scanAllLights()
	applyAllLights(mapName)
end
local currentMap = detectMapName()
applyMapConfig(currentMap)
task.spawn(function()
	local lastMap = currentMap
	while true do
		task.wait(1)
		local map = detectMapName()
		if map ~= lastMap then applyMapConfig(map) lastMap = map end
	end
end)
Workspace.DescendantAdded:Connect(function(descendant)
	task.wait(0.05)
	if descendant:IsA("BasePart") then applyShadowToPart(descendant)
	elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
		cacheLight(descendant) applyAllLights(detectMapName())
	end
end)
]==]
	CreateToggle(MainScriptTab, "OLD GRAPHICS 2", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(OLD_GRAPHICS_2_SCRIPT)() end) end)
			end
		else
			loaded = false
			pcall(function() if _G.OldGraphics2Cleanup then _G.OldGraphics2Cleanup() end end)
		end
	end, 7)
end)

pcall(function()
	local loaded = false
	local TIMER_SCRIPT = [==[
local lp = game:GetService("Players").LocalPlayer
local pg = lp:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "TimerGui" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.Parent = pg
local tm = Instance.new("TextLabel")
tm.Name = "Timer" tm.Parent = sg tm.BackgroundTransparency = 1
tm.AnchorPoint = Vector2.new(0.5, 0) tm.Position = UDim2.new(0.5, 0, 0.08, 0)
tm.Size = UDim2.fromOffset(300, 50) tm.Font = Enum.Font.GothamBold tm.TextSize = 34
tm.TextColor3 = Color3.fromRGB(255, 255, 255) tm.TextStrokeTransparency = 0
tm.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) tm.TextXAlignment = Enum.TextXAlignment.Center
tm.TextYAlignment = Enum.TextYAlignment.Center tm.Visible = false
local function fmt(s)
	if typeof(s) ~= "number" or s < 0 then return "" end
	s = math.floor(s) local m = math.floor(s / 60) local r = s % 60
	return string.format("%dm %02ds", m, r)
end
task.spawn(function()
	while sg.Parent do
		local rt = workspace:FindFirstChild("RoundTimerPart")
		if rt then
			local t = rt:GetAttribute("Time")
			if typeof(t) == "number" and t >= 0 then tm.Text = fmt(t) tm.Visible = true
			else tm.Text = "" tm.Visible = false end
		else tm.Text = "" tm.Visible = false end
		task.wait(0.1)
	end
end)
]==]
	CreateToggle(MainScriptTab, "TIMER MOBILE", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(TIMER_SCRIPT)() end) end)
			end
		else
			loaded = false
			pcall(function()
				local pg = Player:FindFirstChild("PlayerGui")
				if pg then
					for _, g in ipairs(pg:GetChildren()) do
						if g.Name == "TimerGui" or g.Name:find("Timer") then pcall(function() g:Destroy() end) end
					end
				end
				local cg = game:GetService("CoreGui")
				for _, g in ipairs(cg:GetChildren()) do
					if g.Name == "TimerGui" or g.Name:find("Timer") then pcall(function() g:Destroy() end) end
				end
			end)
		end
	end, 8)
end)

pcall(function()
	local active = false
	local conns = {}
	local function replace(el)
		if not active then return end
		if not el:IsA("TextLabel") then return end
		local n = tonumber(el.Text)
		if not (n and n >= 1 and n <= 9) then return end
		local pn = el.Parent and el.Parent.Name:lower() or ""
		local gn = (el.Parent and el.Parent.Parent) and el.Parent.Parent.Name:lower() or ""
		local isHotbar = pn:find("slot") or pn:find("action") or pn:find("hotbar") or gn:find("hotbar") or gn:find("inventory") or el.Name:lower():find("hotkey") or el.Name:lower():find("number")
		if not isHotbar then return end
		if el.Name == "CustomMM2Number" then return end
		el.TextTransparency = 1; el.BackgroundTransparency = 1
		local pf = el.Parent
		local cn = pf:FindFirstChild("CustomMM2Number")
		if not cn then cn = Instance.new("TextLabel", pf); cn.Name = "CustomMM2Number" end
		cn.Text = el.Text; cn.Font = Enum.Font.SourceSans; cn.TextSize = 14
		cn.TextColor3 = Color3.fromRGB(255,255,255); cn.TextTransparency = 0; cn.BackgroundTransparency = 1
		cn.TextXAlignment = Enum.TextXAlignment.Left; cn.TextYAlignment = Enum.TextYAlignment.Top
		cn.AnchorPoint = Vector2.new(0,0); cn.Position = UDim2.new(0,-2,0,-5); cn.Size = UDim2.new(0,14,0,14)
		el:GetPropertyChangedSignal("Text"):Connect(function() if cn and cn.Parent then cn.Text = el.Text end end)
	end
	local function scanGui(g)
		for _, d in ipairs(g:GetDescendants()) do replace(d) end
		table.insert(conns, g.DescendantAdded:Connect(replace))
	end
	CreateToggle(MainScriptTab, "SMALL NUMBER", function(state)
		active = state
		if state then
			for _, g in ipairs(PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then scanGui(g) end end
			table.insert(conns, PlayerGui.ChildAdded:Connect(function(g) if g:IsA("ScreenGui") then task.wait(0.05); scanGui(g) end end))
		else
			for _, c in ipairs(conns) do c:Disconnect() end
			conns = {}
			for _, g in ipairs(PlayerGui:GetChildren()) do
				for _, d in ipairs(g:GetDescendants()) do if d.Name == "CustomMM2Number" then d:Destroy() end end
			end
		end
	end, 9)
end)

pcall(function()
	local active = false
	local conn = nil
	local function block(c)
		if not c:IsA("BasePart") then return end
		pcall(function()
			local tt = c:FindFirstChildOfClass("TouchTransmitter"); if tt then tt.Enabled = false end
			c.CanTouch = false; c.CanCollide = false
		end)
	end
	CreateToggle(MainScriptTab, "ANTI COINS", function(state)
		active = state
		if state then
			task.spawn(function()
				if not active then return end
				local coins = {}
				for _, o in pairs(workspace:GetDescendants()) do
					if o:IsA("BasePart") and o.Name:lower():find("coin") then table.insert(coins, o) end
				end
				for i = 1, #coins, 5 do
					if not active then return end
					for j = i, math.min(i+4, #coins) do block(coins[j]) end
					task.wait()
				end
			end)
			conn = workspace.DescendantAdded:Connect(function(o)
				if active and o:IsA("BasePart") and o.Name:lower():find("coin") then task.spawn(function() block(o) end) end
			end)
		else
			if conn then conn:Disconnect() conn = nil end
			for _, o in pairs(workspace:GetDescendants()) do
				if o:IsA("BasePart") and o.Name:lower():find("coin") then
					pcall(function()
						o.CanTouch = true; o.CanCollide = true
						local tt = o:FindFirstChildOfClass("TouchTransmitter"); if tt then tt.Enabled = true end
					end)
				end
			end
		end
	end, 10)
end)

pcall(function()
	local conn = nil
	local hum = nil
	local locked = false
	local off = Vector3.new(1.2, 0.8, 0)
	local norm = Vector3.new(0, 0, 0)
	local function onChar(c) hum = c:WaitForChild("Humanoid") end
	CreateToggle(MainScriptTab, "SHIFTLOCK 2023", function(state)
		if state then
			if Player.Character then onChar(Player.Character) end
			conn = RunService.RenderStepped:Connect(function()
				if not hum then return end
				if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
					if not locked then locked = true; hum.CameraOffset = off end
				else
					if locked then locked = false; hum.CameraOffset = norm end
				end
			end)
		else
			if conn then conn:Disconnect() conn = nil end
			if hum then hum.CameraOffset = norm end
			locked = false
		end
	end, 11)
	Player.CharacterAdded:Connect(onChar)
end)

pcall(function()
	local on = false
	CreateToggle(MainScriptTab, "OLD CAM", function(state)
		on = state
		if Player.Character then
			local hum = Player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.CameraOffset = on and Vector3.new(0,0.3,0) or Vector3.new(0,0,0) end
		end
	end, 12)
	Player.CharacterAdded:Connect(function(c)
		task.wait(1)
		if on then
			local hum = c:FindFirstChildOfClass("Humanoid")
			if hum then hum.CameraOffset = Vector3.new(0,0.3,0) end
		end
	end)
end)

pcall(function()
	local conns = {}
	local savedTime = 14
	local on = false
	local function clear()
		for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
		conns = {}
	end
	CreateToggle(MainScriptTab, "OLD GRAPHICS", function(state)
		on = state
		clear()
		if on then
			savedTime = Lighting.ClockTime
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then v:Destroy() end
			end
			Lighting.Technology = Enum.Technology.Compatibility
			Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.ClockTime = 14
			Lighting.Ambient = Color3.fromRGB(165,165,165); Lighting.OutdoorAmbient = Color3.fromRGB(165,165,165)
			Lighting.FogStart = 900; Lighting.FogEnd = 100000; Lighting.FogColor = Color3.fromRGB(220,220,220)
			Lighting.EnvironmentDiffuseScale = 0.15; Lighting.EnvironmentSpecularScale = 0.05
			for _, o in ipairs(workspace:GetDescendants()) do
				if o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Enabled = false end
			end
			table.insert(conns, Lighting.ChildAdded:Connect(function(o)
				if on and (o:IsA("Atmosphere") or o:IsA("BloomEffect") or o:IsA("SunRaysEffect") or o:IsA("ColorCorrectionEffect") or o:IsA("DepthOfFieldEffect")) then
					task.wait()
					if o.Parent then o:Destroy() end
				end
			end))
			table.insert(conns, workspace.DescendantAdded:Connect(function(o)
				if on and (o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight")) then o.Enabled = false end
			end))
		else
			pcall(function()
				Lighting.Technology = Enum.Technology.ShadowMap
				Lighting.GlobalShadows = true; Lighting.Brightness = 1; Lighting.ClockTime = savedTime
				Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1; Lighting.FogStart = 0
			end)
		end
	end, 13)
end)

pcall(function()
	local conns = {}
	local equip = nil
	local unequip = nil
	local EQ_ID = "rbxassetid://124247245989090"
	local GUN = "Gun"
	local CD = 2
	local function play(s) if not s then return end s:Stop(); s.TimePosition = 0; s:Play() end
	local function setup(ch)
		local lastUn = 0
		local hum = ch:WaitForChild("Humanoid", 10)
		local an = hum and hum:WaitForChild("Animator", 10)
		if an then
			table.insert(conns, an.AnimationPlayed:Connect(function(track)
				local tool = ch:FindFirstChildOfClass("Tool")
				local isGun = tool and tool.Name == GUN
				local wc = (os.clock() - lastUn) <= CD
				if isGun or wc then
					if track.Priority == Enum.AnimationPriority.Action then track:Stop() end
				end
			end))
		end
		table.insert(conns, ch.ChildAdded:Connect(function(c)
			if c:IsA("Tool") and c.Name == GUN then play(equip) end
		end))
		table.insert(conns, ch.ChildRemoved:Connect(function(c)
			if c:IsA("Tool") and c.Name == GUN then lastUn = os.clock(); play(unequip) end
		end))
	end
	local function createSound(name, id, vol)
		local s = Instance.new("Sound"); s.Name = name; s.SoundId = id; s.Volume = vol; s.Parent = SoundService
		return s
	end
	local function cleanup()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		conns = {}
		for _, n in ipairs({"CustomEquipSound","CustomUnequipSound"}) do
			local s = SoundService:FindFirstChild(n)
			if s then s:Destroy() end
		end
		equip = nil; unequip = nil
	end
	CreateToggle(MainScriptTab, "OLD SOUND", function(state)
		if state then
			cleanup()
			equip = createSound("CustomEquipSound", EQ_ID, 1)
			unequip = createSound("CustomUnequipSound", EQ_ID, 1)
			if Player.Character then setup(Player.Character) end
			table.insert(conns, Player.CharacterAdded:Connect(function(c)
				task.wait(0.5); setup(c)
			end))
		else cleanup() end
	end, 14)
end)

Defer(function()
	local loaded = false
	local SHOOT_SOUND_2019_SCRIPT = [==[
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
_G.MM2_ExecID = (_G.MM2_ExecID or 0) + 1
local currentExecID = _G.MM2_ExecID
if _G.MM2_Gun_Connections then
	for _, conn in ipairs(_G.MM2_Gun_Connections) do
		if conn and conn.Connected then conn:Disconnect() end
	end
end
_G.MM2_Gun_Connections = {}
local soundNames = {"CustomEquipSound","CustomShootSound","CustomHitSound","CustomReloadSound"}
for _, sName in ipairs(soundNames) do
	local existing = SoundService:FindFirstChild(sName)
	if existing then existing:Destroy() end
end
local function track(conn) table.insert(_G.MM2_Gun_Connections, conn) return conn end
local EQUIP_SOUND_ID = "rbxassetid://124247245989090"
local SHOOT_SOUND_ID = "rbxassetid://82571833761093"
local HIT_MURDER_SOUND_ID = "rbxassetid://78331207027399"
local RELOAD_SOUND_ID = "rbxassetid://269729563"
local TARGET_TOOL_NAME = "Gun"
local COOLDOWN_DURATION = 2
local SHOOT_COOLDOWN = 3
local function createSound(name, id, vol)
	local sound = Instance.new("Sound")
	sound.Name = name sound.SoundId = id sound.Volume = vol or 1 sound.Parent = SoundService
	return sound
end
local actionSound = createSound("CustomEquipSound", EQUIP_SOUND_ID, 1)
local customShootSound = createSound("CustomShootSound", SHOOT_SOUND_ID, 1)
local customHitMurderSound = createSound("CustomHitSound", HIT_MURDER_SOUND_ID, 1.5)
local customReloadSound = createSound("CustomReloadSound", RELOAD_SOUND_ID, 1)
local function isLocalSound(sound)
	local char = player.Character
	local pack = player:FindFirstChildOfClass("Backpack")
	if char and sound:IsDescendantOf(char) then return true end
	if pack and sound:IsDescendantOf(pack) then return true end
	return false
end
local function processSound(sound)
	if not sound:IsA("Sound") or sound.Name:find("Custom") then return end
	if not isLocalSound(sound) then return end
	local lowerName = sound.Name:lower()
	if lowerName:find("coin") or lowerName:find("collect") or lowerName:find("pickup") then return end
	if lowerName:find("shoot") or lowerName:find("gun") or lowerName:find("fire") or lowerName:find("hit") or sound.SoundId:find("242260117") then
		sound.Volume = 0
	end
end
local function hookContainer(container)
	if not container then return end
	track(container.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Sound") then task.defer(function() processSound(descendant) end) end
	end))
	for _, desc in ipairs(container:GetDescendants()) do processSound(desc) end
end
local murdererPlayer = nil
local function checkPlayerForKnife(p)
	if p == player then return end
	local char = p.Character
	local backpack = p:FindFirstChild("Backpack")
	if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then murdererPlayer = p end
end
track(Workspace.DescendantAdded:Connect(function(desc)
	if desc.Name == "Knife" then
		local char = desc:FindFirstAncestorOfClass("Model")
		if char then
			local p = Players:GetPlayerFromCharacter(char)
			if p and p ~= player then murdererPlayer = p end
		end
	end
end))
for _, p in ipairs(Players:GetPlayers()) do checkPlayerForKnife(p) end
local lastHitPlayTime = 0
local function playSoundInstant(sound)
	sound:Stop() sound.TimePosition = 0 sound:Play()
end
local function triggerHitSoundOverride()
	if os.clock() - lastHitPlayTime < 0.8 then return end
	lastHitPlayTime = os.clock()
	customShootSound:Stop() playSoundInstant(customHitMurderSound)
end
local function isDirectHitOnMurderer(character)
	local mouse = player:GetMouse()
	if not mouse then return false end
	if mouse.Target then
		local hitModel = mouse.Target:FindFirstAncestorOfClass("Model")
		if hitModel then
			local targetPlayer = Players:GetPlayerFromCharacter(hitModel)
			if targetPlayer and targetPlayer == murdererPlayer then return true end
			if hitModel:FindFirstChild("Knife") then murdererPlayer = targetPlayer return true end
		end
	end
	local tool = character:FindFirstChild(TARGET_TOOL_NAME)
	local originPart = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")) or character.PrimaryPart
	if not originPart then return false end
	local origin = originPart.Position
	local targetPos = mouse.Hit.Position
	local direction = (targetPos - origin).Unit * 500
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, Workspace.CurrentCamera }
	raycastParams.IgnoreWater = true
	local result = Workspace:Raycast(origin, direction, raycastParams)
	if result and result.Instance then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		if hitModel then
			local targetPlayer = Players:GetPlayerFromCharacter(hitModel)
			if targetPlayer and targetPlayer == murdererPlayer then return true end
		end
	end
	return false
end
local function setupGunSystem(character)
	hookContainer(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)
	local lastUnequippedTime = 0
	local isReloading = false
	local currentToolConn = nil
	if animator then
		track(animator.AnimationPlayed:Connect(function(trackAnim)
			if _G.MM2_ExecID ~= currentExecID then return end
			local tool = character:FindFirstChildOfClass("Tool")
			local isHoldingGun = (tool and tool.Name == TARGET_TOOL_NAME)
			local timeSinceUnequip = os.clock() - lastUnequippedTime
			local withinCooldown = timeSinceUnequip <= COOLDOWN_DURATION
			if isHoldingGun or withinCooldown then
				if trackAnim.Priority == Enum.AnimationPriority.Action then trackAnim:Stop() end
			end
		end))
	end
	track(character.ChildAdded:Connect(function(child)
		if _G.MM2_ExecID ~= currentExecID then return end
		if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
			hookContainer(child)
			playSoundInstant(actionSound)
			if currentToolConn then currentToolConn:Disconnect() end
			currentToolConn = child.Activated:Connect(function()
				if _G.MM2_ExecID ~= currentExecID then return end
				if isReloading then return end
				isReloading = true
				if isDirectHitOnMurderer(character) then triggerHitSoundOverride()
				else playSoundInstant(customShootSound) end
				task.delay(0.5, function()
					if _G.MM2_ExecID ~= currentExecID then return end
					if character:FindFirstChild(TARGET_TOOL_NAME) then playSoundInstant(customReloadSound) end
				end)
				task.delay(SHOOT_COOLDOWN, function() isReloading = false end)
			end)
			track(currentToolConn)
		end
	end))
	track(character.ChildRemoved:Connect(function(child)
		if _G.MM2_ExecID ~= currentExecID then return end
		if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
			playSoundInstant(actionSound)
			lastUnequippedTime = os.clock()
			if currentToolConn then currentToolConn:Disconnect() currentToolConn = nil end
			customShootSound:Stop() customReloadSound:Stop()
			isReloading = false
		end
	end))
end
if player.Character then setupGunSystem(player.Character) end
track(player.CharacterAdded:Connect(setupGunSystem))
local backpack = player:FindFirstChildOfClass("Backpack")
if backpack then hookContainer(backpack) end
track(player.ChildAdded:Connect(function(child) if child:IsA("Backpack") then hookContainer(child) end end))
]==]
	CreateToggle(MainScriptTab, "SHOOT SOUND 2019", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(SHOOT_SOUND_2019_SCRIPT)() end) end)
			end
		else
			loaded = false
			pcall(function() if _G.ShootSound2019Cleanup then _G.ShootSound2019Cleanup() end end)
			pcall(function()
				if _G.MM2_ExecID then _G.MM2_ExecID = _G.MM2_ExecID + 1 end
				if _G.MM2_Gun_Connections then
					for _, conn in ipairs(_G.MM2_Gun_Connections) do
						if conn and conn.Connected then pcall(function() conn:Disconnect() end) end
					end
					_G.MM2_Gun_Connections = {}
				end
			end)
			pcall(function()
				for _, n in ipairs({"CustomEquipSound","CustomShootSound","CustomHitSound","CustomReloadSound","ShootSound2019"}) do
					local s = SoundService:FindFirstChild(n)
					if s then s:Destroy() end
				end
			end)
			pcall(function()
				local character = Player.Character
				local backpack = Player:FindFirstChildOfClass("Backpack")
				for _, container in ipairs({character, backpack}) do
					if container then
						for _, d in ipairs(container:GetDescendants()) do
							if d:IsA("Sound") and not d.Name:find("Custom") then
								local lower = d.Name:lower()
								if lower:find("shoot") or lower:find("gun") or lower:find("fire") or lower:find("hit") then d.Volume = 1 end
							end
						end
					end
				end
			end)
		end
	end, 15)
end)

pcall(function()
	local conns = {}
	local GUN_ID = "rbxassetid://6968135315"
	local GUN = "Gun"
	local CD = 5
	local snd = Instance.new("Sound")
	snd.Name = "GunSound2023"; snd.SoundId = GUN_ID; snd.Volume = 0; snd.Parent = SoundService
	local function setup(ch)
		for _, c in ipairs(conns) do if c then c:Disconnect() end end
		table.clear(conns)
		local hum = ch:WaitForChild("Humanoid", 10)
		local an = hum and hum:WaitForChild("Animator", 10)
		local lastUn = 0
		if an then
			table.insert(conns, an.AnimationPlayed:Connect(function(track)
				local tool = ch:FindFirstChildOfClass("Tool")
				local isGun = tool and tool.Name == GUN
				local wc = (tick() - lastUn) <= CD
				if isGun or wc then
					if track.Priority == Enum.AnimationPriority.Action then track:Stop() end
				end
			end))
		end
		table.insert(conns, ch.ChildAdded:Connect(function(c)
			if c:IsA("Tool") and c.Name == GUN then snd:Play() end
		end))
		table.insert(conns, ch.ChildRemoved:Connect(function(c)
			if c:IsA("Tool") and c.Name == GUN then snd:Play(); lastUn = tick() end
		end))
	end
	CreateToggle(MainScriptTab, "GUN SOUND 2023", function(state)
		if state then
			snd.Volume = 1
			if Player.Character then setup(Player.Character) end
		else
			for _, c in ipairs(conns) do if c then c:Disconnect() end end
			table.clear(conns)
			snd:Stop(); snd.Volume = 0
		end
	end, 16)
	Player.CharacterAdded:Connect(function(c)
		if snd.Volume > 0 then task.wait(.5); snd.Volume = 1; setup(c) end
	end)
end)

pcall(function()
	local loaded = false
	CreateToggle(MainScriptTab, "CONFETI", function(state)
		_G.ConfetiActive = state
		if state and not loaded then
			loaded = true
			task.spawn(function() pcall(function() loadstring(game:HttpGet("https://pastefy.app/lEdif66x/raw"))() end) end)
		end
		if not state then
			loaded = false
			cleanGuis({"Confeti","Confetti","Lag"})
			pcall(function()
				local ns = settings():GetService("NetworkSettings")
				ns.IncomingReplicationLag = 0; ns.OutgoingReplicationLag = 0
			end)
			pcall(function() if _G.ConfetiCleanup then _G.ConfetiCleanup() end end)
		end
	end, 17)
end)

pcall(function()
	local conn = nil
	CreateToggle(MainScriptTab, "INFINITE JUMP", function(state)
		if state then
			if conn then conn:Disconnect() end
			conn = UserInputService.JumpRequest:Connect(function()
				local c = Player.Character
				if not c then return end
				local hum = c:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		else
			if conn then conn:Disconnect() conn = nil end
		end
	end, 18)
end)

pcall(function()
	local on = false
	CreateToggle(MainScriptTab, "NOCLIP", function(state) on = state end, 19)
	RunService.Stepped:Connect(function()
		if not on then return end
		local c = Player.Character
		if not c then return end
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end)
end)

pcall(function()
	local antiClickActive = false
	local originalStates = {}
	local function storeTool(tool)
		if not tool then return end
		if originalStates[tool] then return end
		originalStates[tool] = { Enabled = tool.Enabled, Parts = {} }
		for _, v in pairs(tool:GetDescendants()) do
			if v:IsA("BasePart") then originalStates[tool].Parts[v] = { CanTouch = v.CanTouch, CanCollide = v.CanCollide } end
		end
	end
	local function restoreTool(tool)
		if not tool then return end
		local data = originalStates[tool]
		if data then
			pcall(function() tool.Enabled = data.Enabled end)
			for part, st in pairs(data.Parts) do
				if part and part.Parent then
					pcall(function() part.CanTouch = st.CanTouch end)
					pcall(function() part.CanCollide = st.CanCollide end)
				end
			end
		else
			pcall(function() tool.Enabled = true end)
			for _, v in pairs(tool:GetDescendants()) do
				if v:IsA("BasePart") then
					pcall(function() v.CanTouch = true end)
					pcall(function() v.CanCollide = true end)
				end
			end
		end
	end
	CreateToggle(MainScriptTab, "ANTI-CLICK", function(state)
		antiClickActive = state
		if not state then
			local c = Player.Character
			if c then
				local tool = c:FindFirstChildOfClass("Tool")
				if tool then restoreTool(tool) end
			end
			local bp = Player:FindFirstChild("Backpack")
			if bp then
				for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then restoreTool(t) end end
			end
			originalStates = {}
		end
	end, 20)
	RunService.RenderStepped:Connect(function()
		if not antiClickActive then return end
		local c = Player.Character
		if not c then return end
		local tool = c:FindFirstChildOfClass("Tool")
		if tool then
			storeTool(tool)
			if tool.Enabled then tool.Enabled = false end
			for _, v in pairs(tool:GetDescendants()) do
				if v:IsA("BasePart") then if v.CanTouch then v.CanTouch = false end end
			end
		end
	end)
end)

pcall(function()
	local conns = {}
	_G.ThrowDelay = 0.06
	local FREEZE = 0.4
	_G.IsFreezing = false
	local function setup(c)
		local hum = c:WaitForChild("Humanoid", 5); if not hum then return end
		local an = hum:WaitForChild("Animator", 5); if not an then return end
		table.insert(conns, an.AnimationPlayed:Connect(function(track)
			local anName = string.lower(track.Animation.Name)
			if (string.find(anName,"throw") or string.find(anName,"sleight")) and not string.find(anName,"charge") then
				local tool = c:FindFirstChildOfClass("Tool")
				if tool then
					local tn = string.lower(tool.Name)
					if string.find(tn,"toy") or string.find(tn,"radio") or string.find(tn,"teddy") or string.find(tn,"boombox") or string.find(tn,"balloon") or string.find(tn,"pizza") then return end
				end
				local conn
				conn = RunService.Heartbeat:Connect(function()
					if not track.IsPlaying then conn:Disconnect(); return end
					if track.TimePosition >= _G.ThrowDelay and not _G.IsFreezing then
						_G.IsFreezing = true
						track:AdjustWeight(1); track:AdjustSpeed(0)
						task.spawn(function()
							task.wait(FREEZE)
							track:AdjustSpeed(1)
							task.wait(1)
							_G.IsFreezing = false
						end)
						conn:Disconnect()
					end
				end)
				track.Stopped:Connect(function() if conn then conn:Disconnect() end end)
			end
		end))
	end
	CreateToggle(MainScriptTab, "OLD THROW", function(state)
		if state then
			if Player.Character then setup(Player.Character) end
			table.insert(conns, Player.CharacterAdded:Connect(setup))
		else
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
			conns = {}
			_G.IsFreezing = false
		end
	end, 21)
end)

pcall(function()
	local conns = {}
	local origs = {}
	local function applyKorblox(c)
		local hum = c:WaitForChild("Humanoid", 5); if not hum then return end
		if hum.RigType == Enum.HumanoidRigType.R15 then
			local ru = c:FindFirstChild("RightUpperLeg")
			local rl = c:FindFirstChild("RightLowerLeg")
			local rf = c:FindFirstChild("RightFoot")
			if not (ru and rl and rf) then return end
			origs[ru] = ru.Transparency; origs[rl] = rl.Transparency; origs[rf] = rf.Transparency
			ru.Transparency = 1; rl.Transparency = 1; rf.Transparency = 1
			local fl = Instance.new("Part")
			fl.Name = "FakeKorbloxLeg"; fl.Size = Vector3.new(1,1,1)
			fl.CanCollide = false; fl.CanTouch = false; fl.CanQuery = false
			fl.Massless = true; fl.Transparency = 0
			local m = Instance.new("SpecialMesh", fl)
			m.MeshId = "rbxassetid://902942096"; m.TextureId = "rbxassetid://902843398"
			m.Scale = Vector3.new(0.85,0.85,0.85)
			fl.Parent = c
			local w = Instance.new("Weld", fl)
			w.Part0 = ru; w.Part1 = fl
			w.C0 = CFrame.new(0.10,0.2,-0.1) * CFrame.Angles(math.rad(5),0,math.rad(5))
		else
			local ex = c:FindFirstChild("KorbloxMesh"); if ex then ex:Destroy() end
			local cm = Instance.new("CharacterMesh")
			cm.Name = "KorbloxMesh"; cm.BodyPart = Enum.BodyPart.RightLeg
			cm.MeshId = "rbxassetid://902942096"; cm.Parent = c
		end
	end
	local function removeKorblox(c)
		if not c then return end
		local f = c:FindFirstChild("FakeKorbloxLeg"); if f then f:Destroy() end
		local cm = c:FindFirstChild("KorbloxMesh"); if cm then cm:Destroy() end
		local ru = c:FindFirstChild("RightUpperLeg"); local rl = c:FindFirstChild("RightLowerLeg"); local rf = c:FindFirstChild("RightFoot")
		if ru and origs[ru] then ru.Transparency = origs[ru] end
		if rl and origs[rl] then rl.Transparency = origs[rl] end
		if rf and origs[rf] then rf.Transparency = origs[rf] end
		origs = {}
	end
	CreateToggle(MainScriptTab, "KORBLOX", function(state)
		if state then
			if Player.Character then applyKorblox(Player.Character) end
			table.insert(conns, Player.CharacterAdded:Connect(function(c)
				task.wait(0.5); applyKorblox(c)
			end))
		else
			for _, c in ipairs(conns) do c:Disconnect() end
			conns = {}
			removeKorblox(Player.Character)
		end
	end, 22)
end)

Defer(function()
	local active = false
	local globalConns = {}
	local playerState = {}

	local function getRole(plr)
		local char = plr.Character
		if not char then return "innocent" end
		if char:FindFirstChild("Knife") then return "murderer" end
		if char:FindFirstChild("Gun") then return "sheriff" end
		local bp = plr:FindFirstChildOfClass("Backpack")
		if bp then
			if bp:FindFirstChild("Knife") then return "murderer" end
			if bp:FindFirstChild("Gun") then return "sheriff" end
		end
		return "innocent"
	end

	local function colorOf(role)
		if role == "murderer" then return Color3.fromRGB(255, 0, 0) end
		if role == "sheriff"  then return Color3.fromRGB(0, 140, 255) end
		return Color3.fromRGB(0, 255, 0)
	end

	local function applyChams(plr)
		if not active or plr == Player then return end
		local char = plr.Character
		if not char then return end
		local st = playerState[plr]
		local role = getRole(plr)
		local color = colorOf(role)

		if st and st.role == role then
			local existing = char:FindFirstChild("PlayerCham")
			if existing then return end
		end

		local hl = char:FindFirstChild("PlayerCham")
		if not hl then
			hl = Instance.new("Highlight")
			hl.Name = "PlayerCham"
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillTransparency = 1
			hl.OutlineTransparency = 0
			hl.Parent = char
		end
		hl.FillColor = color
		hl.OutlineColor = color

		local head = char:FindFirstChild("Head")
		if head then
			local bb = head:FindFirstChild("PlayerChamName")
			if not bb then
				bb = Instance.new("BillboardGui")
				bb.Name = "PlayerChamName"
				bb.Adornee = head
				bb.Size = UDim2.fromOffset(200, 50)
				bb.StudsOffset = Vector3.new(0, 2.5, 0)
				bb.AlwaysOnTop = true
				bb.Parent = head
				local t = Instance.new("TextLabel")
				t.Name = "NameText"
				t.Size = UDim2.fromScale(1, 1)
				t.BackgroundTransparency = 1
				t.Font = Enum.Font.GothamBold
				t.TextSize = 14
				t.TextStrokeTransparency = 0
				t.TextStrokeColor3 = Color3.new(0, 0, 0)
				t.Parent = bb
			end
			local txt = bb:FindFirstChild("NameText")
			if txt then
				txt.Text = plr.Name
				txt.TextColor3 = color
			end
		end

		if st then st.role = role end
	end

	local function clearChams(plr)
		local char = plr.Character
		if char then
			local hl = char:FindFirstChild("PlayerCham")
			if hl then hl:Destroy() end
			local head = char:FindFirstChild("Head")
			if head then
				local bb = head:FindFirstChild("PlayerChamName")
				if bb then bb:Destroy() end
			end
		end
		local st = playerState[plr]
		if st then st.role = nil end
	end

	local function watchTools(container, plr)
		if not container then return end
		local st = playerState[plr]
		if not st then return end
		table.insert(st.conns, container.ChildAdded:Connect(function(o)
			if active and o:IsA("Tool") then
				task.defer(function() applyChams(plr) end)
			end
		end))
		table.insert(st.conns, container.ChildRemoved:Connect(function(o)
			if active and o:IsA("Tool") then
				task.defer(function() applyChams(plr) end)
			end
		end))
	end

	local function setupPlayer(plr)
		if plr == Player or playerState[plr] then return end
		playerState[plr] = { conns = {}, role = nil }
		local st = playerState[plr]

		local function bindCharacter(char)
			if not active then return end
			task.wait(0.25)
			if not active then return end
			applyChams(plr)
			watchTools(char, plr)
		end

		table.insert(st.conns, plr.CharacterAdded:Connect(bindCharacter))
		if plr.Character then task.spawn(bindCharacter, plr.Character) end

		local function bindBackpack(bp)
			if not bp then return end
			watchTools(bp, plr)
			if active then task.defer(function() applyChams(plr) end) end
		end

		table.insert(st.conns, plr.ChildAdded:Connect(function(o)
			if o:IsA("Backpack") then bindBackpack(o) end
		end))
		bindBackpack(plr:FindFirstChildOfClass("Backpack"))
	end

	local function teardownPlayer(plr)
		local st = playerState[plr]
		if st then
			for _, c in ipairs(st.conns) do pcall(function() c:Disconnect() end) end
			playerState[plr] = nil
		end
		clearChams(plr)
	end

	CreateToggle(MainScriptTab, "PLAYER CHAMS", function(state)
		active = state
		if state then
			for _, plr in ipairs(Players:GetPlayers()) do setupPlayer(plr) end
			table.insert(globalConns, Players.PlayerAdded:Connect(setupPlayer))
			table.insert(globalConns, Players.PlayerRemoving:Connect(teardownPlayer))
		else
			for _, c in ipairs(globalConns) do pcall(function() c:Disconnect() end) end
			globalConns = {}
			for _, plr in ipairs(Players:GetPlayers()) do teardownPlayer(plr) end
		end
	end, 23)
end)

pcall(function()
	CreateToggle(MainScriptTab, "OLD ANIMATIONS", function(state)
		if state then workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled
		else workspace.Retargeting = Enum.AnimatorRetargetingMode.Default end
	end, 24)
end)

pcall(function()
	local conns = {}
	local TEXTURE_ID = "rbxassetid://92556048164663"
	local function createVoiceIcon(character)
		local head = character:WaitForChild("Head", 10); if not head then return end
		local old = head:FindFirstChild("OldVoiceChatIcon"); if old then old:Destroy() end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "OldVoiceChatIcon"
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(42, 42)
		billboard.StudsOffset = Vector3.new(0, 2.15, 0)
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.MaxDistance = 100
		billboard.Parent = head
		local image = Instance.new("ImageLabel")
		image.Name = "VoiceIcon"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = TEXTURE_ID
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = billboard
	end
	local function removeVoiceIcon(character)
		if not character then return end
		local head = character:FindFirstChild("Head")
		if head then
			local old = head:FindFirstChild("OldVoiceChatIcon")
			if old then old:Destroy() end
		end
	end
	CreateToggle(MainScriptTab, "VOICE CHAT 2023", function(state)
		if state then
			if Player.Character then createVoiceIcon(Player.Character) end
			table.insert(conns, Player.CharacterAdded:Connect(function(character)
				task.wait(0.5); createVoiceIcon(character)
			end))
		else
			for _, c in ipairs(conns) do c:Disconnect() end
			conns = {}
			removeVoiceIcon(Player.Character)
		end
	end, 25)
end)

pcall(function()
	local loaded = false
	local bombMonitorConn = nil
	local function removeBombGui()
		pcall(function()
			local pg = Player:FindFirstChild("PlayerGui")
			if pg then
				for _, g in ipairs(pg:GetChildren()) do
					local n = g.Name:lower()
					if n:find("bomb") or n:find("c4") or n:find("goldbomb") then pcall(function() g:Destroy() end) end
				end
			end
			local cg = game:GetService("CoreGui")
			for _, g in ipairs(cg:GetChildren()) do
				local n = g.Name:lower()
				if n:find("bomb") or n:find("c4") or n:find("goldbomb") then pcall(function() g:Destroy() end) end
			end
		end)
	end
	local function startBombMonitor()
		if bombMonitorConn then return end
		bombMonitorConn = PlayerGui.DescendantAdded:Connect(function(obj)
			if _G.C4Active then return end
			if not obj:IsA("ScreenGui") then return end
			local n = obj.Name:lower()
			if n:find("bomb") or n:find("c4") or n:find("goldbomb") then
				task.defer(function()
					if not _G.C4Active and obj and obj.Parent then pcall(function() obj:Destroy() end) end
				end)
			end
		end)
	end
	local function stopBombMonitor()
		if bombMonitorConn then pcall(function() bombMonitorConn:Disconnect() end) bombMonitorConn = nil end
	end
	CreateToggle(MainScriptTab, "GOLD BOMBS MENU", function(state)
		_G.C4Active = state
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(game:HttpGet("https://pastefy.app/DbKJcA0H/raw"))() end) end)
			end
			stopBombMonitor()
		else
			loaded = false
			removeBombGui()
			startBombMonitor()
			pcall(function() if _G.C4Cleanup then _G.C4Cleanup() end end)
		end
	end, 26)
	Player.CharacterAdded:Connect(function()
		task.wait(1.5)
		if not _G.C4Active then removeBombGui() end
	end)
end)

Defer(function()
	local loaded = false
	local PRIVATE_COINS_SCRIPT = [==[
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")

local player = Players.LocalPlayer

local SOUND_ID = "rbxassetid://131323304"
local COIN_MESH_ID = "rbxassetid://3227376469"
local COIN_TEXTURE_ID = "rbxassetid://11857962292"
local INNER_MESH_ID = "rbxassetid://4751154219"
local INNER_TEXTURE_ID = "rbxassetid://4751163673"

local SPAWN_INTERVAL = 1
local AREAS_PER_TICK = 6
local MAP_SPAWN_DELAY = 10
local MAX_COINS_PER_AREA = 10
local COIN_SIZE = 1.7
local INNER_RATIO = 0.6
local INNER_OFFSET = CFrame.new(0, 0, 0)
local COIN_ROTATION = CFrame.Angles(0, 0, 0)
local FLOAT_HEIGHT = 1
local SPIN_SPEED = 90
local COLLECT_RADIUS = 3

local RISE_SPEED = 14
local COLLECT_SPIN = 31.41592653589793
local FADE_INFO = TweenInfo.new(0.266, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local COLLECT_LIFETIME = 0.5

local VICTORY_GUI_NAMES = {
	["Victory"] = true, ["VictorySheriff"] = true, ["VictoryInnocent"] = true,
	["VictoryMurderer"] = true, ["Victory Sheriff"] = true,
	["Victory Innocent"] = true, ["Victory Murderer"] = true,
}
local ROLE_TOOLS = { Murderer = "Knife", Sheriff = "Gun" }
local END_ON_DEATH = { Murderer = true, Sheriff = true, Innocent = false }

local coinFolder = Instance.new("Folder")
coinFolder.Name = "ClientNormalCoins"
coinFolder.Parent = Workspace

local activeCoins = {}
local collecting = {}
local areaCounts = {}
local areas = {}
local setupMaps = {}
local roundEnded = false
local spawnStartTime = 0

local function loadMesh(meshId, textureId, maxSide)
	local ok, result = pcall(function()
		return InsertService:CreateMeshPartAsync(meshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
	end)
	if ok and result then
		local native = result.Size
		local biggest = math.max(native.X, native.Y, native.Z)
		result.Size = native * (maxSide / biggest)
		result.TextureID = textureId
		return result
	end
	warn("[NormalCoins] No se pudo cargar el mesh " .. meshId .. ": " .. tostring(result))
	return nil
end

local function prepare(part)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Color = Color3.new(1, 1, 1)
	part.Transparency = 0
end

local template
do
	local outer = loadMesh(COIN_MESH_ID, COIN_TEXTURE_ID, COIN_SIZE)
	if outer then
		prepare(outer)
		outer.Name = "ClientCoin"
		local inner = loadMesh(INNER_MESH_ID, INNER_TEXTURE_ID, COIN_SIZE * INNER_RATIO)
		if inner then
			prepare(inner)
			inner.Name = "Inner"
			local weld = Instance.new("Weld")
			weld.Part0 = outer
			weld.Part1 = inner
			weld.C0 = INNER_OFFSET
			weld.Parent = outer
			inner.Parent = outer
		end
		template = outer
	else
		local fallback = Instance.new("Part")
		fallback.Shape = Enum.PartType.Ball
		fallback.Size = Vector3.new(COIN_SIZE, COIN_SIZE, COIN_SIZE)
		fallback.Color = Color3.fromRGB(255, 200, 0)
		prepare(fallback)
		fallback.Name = "ClientCoin"
		template = fallback
	end
end

local HALF_HEIGHT
do
	local s = template.Size
	local r = COIN_ROTATION
	HALF_HEIGHT = (
		math.abs(r.RightVector.Y) * s.X
		+ math.abs(r.UpVector.Y) * s.Y
		+ math.abs(r.LookVector.Y) * s.Z
	) / 2
end

local function playCollectSound()
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 1
	sound.Parent = Workspace
	sound.Ended:Once(function() sound:Destroy() end)
	sound:Play()
end

local function getGroundPosition(part, area)
	local s = part.Size
	local offset = Vector3.new((math.random() - 0.5) * s.X, 0, (math.random() - 0.5) * s.Z)
	local center = (part.CFrame * CFrame.new(offset)).Position
	local origin = Vector3.new(center.X, center.Y + s.Y / 2 + 2, center.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { coinFolder }
	if player.Character then table.insert(exclude, player.Character) end
	params.FilterDescendantsInstances = exclude
	for _ = 1, 8 do
		local result = Workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
		if not result then break end
		local hit = result.Instance
		if hit:IsA("Terrain") then return result.Position end
		if hit == area or hit:IsDescendantOf(area) or hit.Transparency >= 0.95 then
			table.insert(exclude, hit)
			params.FilterDescendantsInstances = exclude
		else
			return result.Position
		end
	end
	return Vector3.new(center.X, center.Y - s.Y / 2, center.Z)
end

local function setTransparency(coin, value)
	coin.Transparency = value
	coin.LocalTransparencyModifier = 0
	local inner = coin:FindFirstChild("Inner")
	if inner then
		inner.Transparency = value
		inner.LocalTransparencyModifier = 0
	end
end

local function applyCFrame(coin, pos, angle)
	coin.CFrame = CFrame.new(pos) * CFrame.Angles(0, angle, 0) * COIN_ROTATION
end

local function createCoin(groundPos, area)
	local coin = template:Clone()
	local pos = groundPos + Vector3.new(0, HALF_HEIGHT + math.max(FLOAT_HEIGHT, 0.05), 0)
	local angle = math.random() * math.pi * 2
	coin.Anchored = true
	applyCFrame(coin, pos, angle)
	coin.Parent = coinFolder
	activeCoins[coin] = { area = area, pos = pos, angle = angle }
	areaCounts[area] = (areaCounts[area] or 0) + 1
	coin.Destroying:Once(function()
		local data = activeCoins[coin]
		if data then
			areaCounts[data.area] = math.max((areaCounts[data.area] or 1) - 1, 0)
			activeCoins[coin] = nil
		end
		collecting[coin] = nil
	end)
end

local function collectCoin(coin, silent)
	local data = activeCoins[coin]
	if not data then return end
	activeCoins[coin] = nil
	areaCounts[data.area] = math.max((areaCounts[data.area] or 1) - 1, 0)
	collecting[coin] = { t = 0, pos = data.pos, angle = data.angle }
	if not silent then playCollectSound() end
	TweenService:Create(coin, FADE_INFO, { Transparency = 1 }):Play()
	local inner = coin:FindFirstChild("Inner")
	if inner then TweenService:Create(inner, FADE_INFO, { Transparency = 1 }):Play() end
end

local function endRound()
	if roundEnded then return end
	roundEnded = true
	for coin in pairs(activeCoins) do collectCoin(coin, true) end
end

local function getRole(plr, character)
	local backpack = plr:FindFirstChildOfClass("Backpack")
	local function has(name)
		return (character and character:FindFirstChild(name))
			or (backpack and backpack:FindFirstChild(name))
	end
	if has(ROLE_TOOLS.Murderer) then return "Murderer" end
	if has(ROLE_TOOLS.Sheriff) then return "Sheriff" end
	return "Innocent"
end

local function watchCharacter(plr, character)
	local hum = character:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.Died:Once(function()
		if roundEnded then return end
		local role = getRole(plr, character)
		if END_ON_DEATH[role] then endRound() end
	end)
end

local function watchPlayer(plr)
	if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
	plr.CharacterAdded:Connect(function(character) watchCharacter(plr, character) end)
end

for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
Players.PlayerAdded:Connect(watchPlayer)

local function spawnInArea(area)
	if (areaCounts[area] or 0) >= MAX_COINS_PER_AREA then return end
	local parts = {}
	if area:IsA("BasePart") then table.insert(parts, area) end
	for _, d in ipairs(area:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end
	if #parts == 0 then return end
	local p = parts[math.random(#parts)]
	local ok, err = pcall(function()
		createCoin(getGroundPosition(p, area), area)
	end)
	if not ok then warn("[NormalCoins] Error al spawnear: " .. tostring(err)) end
end

local function setupMap(map)
	if setupMaps[map] then return end
	local coinAreas = map:FindFirstChild("CoinAreas", true)
	if not coinAreas then return end
	setupMaps[map] = true
	roundEnded = false
	spawnStartTime = os.clock() + MAP_SPAWN_DELAY
	local mapAreas = {}
	for _, area in ipairs(coinAreas:GetChildren()) do
		areas[area] = true
		mapAreas[area] = true
	end
	local conn
	conn = map.AncestryChanged:Connect(function()
		if map:IsDescendantOf(Workspace) then return end
		conn:Disconnect()
		setupMaps[map] = nil
		for coin, data in pairs(activeCoins) do
			if mapAreas[data.area] then collectCoin(coin, true) end
		end
		for area in pairs(mapAreas) do
			areas[area] = nil
			areaCounts[area] = nil
		end
	end)
end

local function tryMap(child)
	if child:IsA("Model") or child:IsA("Folder") then
		if child == coinFolder then return end
		task.delay(1, function() if child.Parent then setupMap(child) end end)
	end
end

for _, child in ipairs(Workspace:GetChildren()) do tryMap(child) end
Workspace.ChildAdded:Connect(tryMap)

local function watchBanner(gui, initial)
	if not VICTORY_GUI_NAMES[gui.Name] then return end
	local prop
	if gui:IsA("ScreenGui") then prop = "Enabled"
	elseif gui:IsA("GuiObject") then prop = "Visible"
	else return end
	local function check() if gui[prop] then endRound() end end
	gui:GetPropertyChangedSignal(prop):Connect(check)
	if not initial then check() end
end

local playerGui = player:WaitForChild("PlayerGui")
for _, d in ipairs(playerGui:GetDescendants()) do watchBanner(d, true) end
playerGui.DescendantAdded:Connect(function(d) watchBanner(d, false) end)

task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)
		if roundEnded or os.clock() < spawnStartTime then continue end
		local list = {}
		local rnd = {}
		for area in pairs(areas) do
			if area.Parent then
				table.insert(list, area)
				rnd[area] = math.random()
			else
				areas[area] = nil
			end
		end
		table.sort(list, function(a, b)
			local ca, cb = areaCounts[a] or 0, areaCounts[b] or 0
			if ca ~= cb then return ca < cb end
			return rnd[a] < rnd[b]
		end)
		for i = 1, math.min(AREAS_PER_TICK, #list) do
			spawnInArea(list[i])
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local spinStep = math.rad(SPIN_SPEED) * dt
	for coin, data in pairs(activeCoins) do
		if coin.Parent ~= coinFolder then coin.Parent = coinFolder end
		if coin.Transparency ~= 0 then setTransparency(coin, 0) end
		data.angle += spinStep
		applyCFrame(coin, data.pos, data.angle)
		if root and (coin.Position - root.Position).Magnitude <= COLLECT_RADIUS then
			collectCoin(coin)
		end
	end
	for coin, data in pairs(collecting) do
		data.t += dt
		data.pos += Vector3.new(0, RISE_SPEED * dt, 0)
		data.angle += COLLECT_SPIN * dt
		applyCFrame(coin, data.pos, data.angle)
		if data.t >= COLLECT_LIFETIME then
			collecting[coin] = nil
			coin:Destroy()
		end
	end
end)
]==]
	CreateToggle(MainScriptTab, "PRIVATE COINS", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(PRIVATE_COINS_SCRIPT)() end) end)
			end
		else
			loaded = false
			pcall(function()
				local folder = workspace:FindFirstChild("ClientNormalCoins")
				if folder then
					for _, c in ipairs(folder:GetChildren()) do
						if c.Name == "ClientCoin" then c:Destroy() end
					end
				end
			end)
		end
	end, 27)
end)

pcall(function()
	local loaded = false
	CreateToggle(MainScriptTab, "2023 BODY SCALE", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function()
					pcall(function()
						local Character = Player.Character or Player.CharacterAdded:Wait()
						local Humanoid = Character:WaitForChild("Humanoid")
						if Humanoid.RigType == Enum.HumanoidRigType.R15 then
							local Description = Humanoid:GetAppliedDescription()
							Description.HeightScale = 1 Description.WidthScale = 1
							Description.DepthScale = 1 Description.HeadScale = 1
							Description.BodyTypeScale = 0 Description.ProportionScale = 0
							Humanoid:ApplyDescription(Description)
						end
					end)
				end)
			end
		else loaded = false end
	end, 28)
end)

Defer(function()
	local loaded = false
	local HALLOWEEN_COINS_SCRIPT = [==[
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")

local player = Players.LocalPlayer

local MESH_ID = "rbxassetid://139025296710661"
local SOUND_ID = "rbxassetid://160060487"

local SPAWN_INTERVAL = 1
local AREAS_PER_TICK = 6
local MAP_SPAWN_DELAY = 10
local MAX_COINS_PER_AREA = 10
local COIN_SIZE = 1.9
local COIN_ROTATION = CFrame.Angles(0, 0, 0)
local FLOAT_HEIGHT = 1
local SPIN_SPEED = 90
local COLLECT_RADIUS = 3

local RISE_SPEED = 14
local COLLECT_SPIN = 31.41592653589793
local FADE_INFO = TweenInfo.new(0.266, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local COLLECT_LIFETIME = 0.5

local VICTORY_GUI_NAMES = {
	["Victory"] = true, ["VictorySheriff"] = true, ["VictoryInnocent"] = true,
	["VictoryMurderer"] = true, ["Victory Sheriff"] = true,
	["Victory Innocent"] = true, ["Victory Murderer"] = true,
}
local ROLE_TOOLS = { Murderer = "Knife", Sheriff = "Gun" }
local END_ON_DEATH = { Murderer = true, Sheriff = true, Innocent = false }

local CANDY_COLORS = {
	Color3.fromRGB(255, 128, 0),
	Color3.fromRGB(170, 85, 255),
	Color3.fromRGB(100, 220, 60),
	Color3.fromRGB(255, 80, 150),
	Color3.fromRGB(255, 215, 0),
}

local coinFolder = Instance.new("Folder")
coinFolder.Name = "ClientCoinVisuals"
coinFolder.Parent = Workspace

local activeCoins = {}
local collecting = {}
local areaCounts = {}
local areas = {}
local setupMaps = {}
local roundEnded = false
local spawnStartTime = 0

local template
do
	local ok, result = pcall(function()
		return InsertService:CreateMeshPartAsync(MESH_ID, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
	end)
	if ok and result then
		local native = result.Size
		local biggest = math.max(native.X, native.Y, native.Z)
		result.Size = native * (COIN_SIZE / biggest)
		template = result
	else
		warn("[Candys] No se pudo cargar el mesh: " .. tostring(result))
		local fallback = Instance.new("Part")
		fallback.Shape = Enum.PartType.Ball
		fallback.Size = Vector3.new(COIN_SIZE, COIN_SIZE, COIN_SIZE)
		template = fallback
	end
	template.Name = "ClientCoin"
	template.Material = Enum.Material.SmoothPlastic
	template.Anchored = true
	template.CanCollide = false
	template.CanQuery = false
	template.CanTouch = false
	template.CastShadow = false
	template.Transparency = 0
end

local HALF_HEIGHT
do
	local s = template.Size
	local r = COIN_ROTATION
	HALF_HEIGHT = (
		math.abs(r.RightVector.Y) * s.X
		+ math.abs(r.UpVector.Y) * s.Y
		+ math.abs(r.LookVector.Y) * s.Z
	) / 2
end

local function playCollectSound()
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 1
	sound.Parent = Workspace
	sound.Ended:Once(function() sound:Destroy() end)
	sound:Play()
end

local function getGroundPosition(part, area)
	local s = part.Size
	local offset = Vector3.new((math.random() - 0.5) * s.X, 0, (math.random() - 0.5) * s.Z)
	local center = (part.CFrame * CFrame.new(offset)).Position
	local origin = Vector3.new(center.X, center.Y + s.Y / 2 + 2, center.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { coinFolder }
	if player.Character then table.insert(exclude, player.Character) end
	params.FilterDescendantsInstances = exclude
	for _ = 1, 8 do
		local result = Workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
		if not result then break end
		local hit = result.Instance
		if hit:IsA("Terrain") then return result.Position end
		if hit == area or hit:IsDescendantOf(area) or hit.Transparency >= 0.95 then
			table.insert(exclude, hit)
			params.FilterDescendantsInstances = exclude
		else
			return result.Position
		end
	end
	return Vector3.new(center.X, center.Y - s.Y / 2, center.Z)
end

local function applyCFrame(coin, pos, angle)
	coin.CFrame = CFrame.new(pos) * CFrame.Angles(0, angle, 0) * COIN_ROTATION
end

local function createCoin(groundPos, area)
	local coin = template:Clone()
	local pos = groundPos + Vector3.new(0, HALF_HEIGHT + math.max(FLOAT_HEIGHT, 0.05), 0)
	local angle = math.random() * math.pi * 2
	coin.Color = CANDY_COLORS[math.random(#CANDY_COLORS)]
	applyCFrame(coin, pos, angle)
	coin.Parent = coinFolder
	activeCoins[coin] = { area = area, pos = pos, angle = angle }
	areaCounts[area] = (areaCounts[area] or 0) + 1
	coin.Destroying:Once(function()
		local data = activeCoins[coin]
		if data then
			areaCounts[data.area] = math.max((areaCounts[data.area] or 1) - 1, 0)
			activeCoins[coin] = nil
		end
		collecting[coin] = nil
	end)
end

local function collectCoin(coin, silent)
	local data = activeCoins[coin]
	if not data then return end
	activeCoins[coin] = nil
	areaCounts[data.area] = math.max((areaCounts[data.area] or 1) - 1, 0)
	collecting[coin] = { t = 0, pos = data.pos, angle = data.angle }
	if not silent then playCollectSound() end
	TweenService:Create(coin, FADE_INFO, { Transparency = 1 }):Play()
end

local function endRound()
	if roundEnded then return end
	roundEnded = true
	for coin in pairs(activeCoins) do collectCoin(coin, true) end
end

local function getRole(plr, character)
	local backpack = plr:FindFirstChildOfClass("Backpack")
	local function has(name)
		return (character and character:FindFirstChild(name))
			or (backpack and backpack:FindFirstChild(name))
	end
	if has(ROLE_TOOLS.Murderer) then return "Murderer" end
	if has(ROLE_TOOLS.Sheriff) then return "Sheriff" end
	return "Innocent"
end

local function watchCharacter(plr, character)
	local hum = character:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.Died:Once(function()
		if roundEnded then return end
		local role = getRole(plr, character)
		if END_ON_DEATH[role] then endRound() end
	end)
end

local function watchPlayer(plr)
	if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
	plr.CharacterAdded:Connect(function(character) watchCharacter(plr, character) end)
end

for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
Players.PlayerAdded:Connect(watchPlayer)

local function spawnInArea(area)
	if (areaCounts[area] or 0) >= MAX_COINS_PER_AREA then return end
	local parts = {}
	if area:IsA("BasePart") then table.insert(parts, area) end
	for _, d in ipairs(area:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end
	if #parts == 0 then return end
	local p = parts[math.random(#parts)]
	local ok, err = pcall(function()
		createCoin(getGroundPosition(p, area), area)
	end)
	if not ok then warn("[Candys] Error al spawnear: " .. tostring(err)) end
end

local function setupMap(map)
	if setupMaps[map] then return end
	local coinAreas = map:FindFirstChild("CoinAreas", true)
	if not coinAreas then return end
	setupMaps[map] = true
	roundEnded = false
	spawnStartTime = os.clock() + MAP_SPAWN_DELAY
	local mapAreas = {}
	for _, area in ipairs(coinAreas:GetChildren()) do
		areas[area] = true
		mapAreas[area] = true
	end
	local conn
	conn = map.AncestryChanged:Connect(function()
		if map:IsDescendantOf(Workspace) then return end
		conn:Disconnect()
		setupMaps[map] = nil
		for coin, data in pairs(activeCoins) do
			if mapAreas[data.area] then collectCoin(coin, true) end
		end
		for area in pairs(mapAreas) do
			areas[area] = nil
			areaCounts[area] = nil
		end
	end)
end

local function tryMap(child)
	if child:IsA("Model") or child:IsA("Folder") then
		if child == coinFolder then return end
		task.delay(1, function() if child.Parent then setupMap(child) end end)
	end
end

for _, child in ipairs(Workspace:GetChildren()) do tryMap(child) end
Workspace.ChildAdded:Connect(tryMap)

local function watchBanner(gui, initial)
	if not VICTORY_GUI_NAMES[gui.Name] then return end
	local prop
	if gui:IsA("ScreenGui") then prop = "Enabled"
	elseif gui:IsA("GuiObject") then prop = "Visible"
	else return end
	local function check() if gui[prop] then endRound() end end
	gui:GetPropertyChangedSignal(prop):Connect(check)
	if not initial then check() end
end

local playerGui = player:WaitForChild("PlayerGui")
for _, d in ipairs(playerGui:GetDescendants()) do watchBanner(d, true) end
playerGui.DescendantAdded:Connect(function(d) watchBanner(d, false) end)

task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)
		if roundEnded or os.clock() < spawnStartTime then continue end
		local list = {}
		local rnd = {}
		for area in pairs(areas) do
			if area.Parent then
				table.insert(list, area)
				rnd[area] = math.random()
			else
				areas[area] = nil
			end
		end
		table.sort(list, function(a, b)
			local ca, cb = areaCounts[a] or 0, areaCounts[b] or 0
			if ca ~= cb then return ca < cb end
			return rnd[a] < rnd[b]
		end)
		for i = 1, math.min(AREAS_PER_TICK, #list) do
			spawnInArea(list[i])
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local spinStep = math.rad(SPIN_SPEED) * dt
	for coin, data in pairs(activeCoins) do
		if coin.Parent ~= coinFolder then coin.Parent = coinFolder end
		if coin.Transparency ~= 0 then coin.Transparency = 0 end
		coin.LocalTransparencyModifier = 0
		data.angle += spinStep
		applyCFrame(coin, data.pos, data.angle)
		if root and (coin.Position - root.Position).Magnitude <= COLLECT_RADIUS then
			collectCoin(coin)
		end
	end
	for coin, data in pairs(collecting) do
		data.t += dt
		data.pos += Vector3.new(0, RISE_SPEED * dt, 0)
		data.angle += COLLECT_SPIN * dt
		applyCFrame(coin, data.pos, data.angle)
		if data.t >= COLLECT_LIFETIME then
			collecting[coin] = nil
			coin:Destroy()
		end
	end
end)
]==]
	CreateToggle(MainScriptTab, "HALLOWEEN COINS", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function() pcall(function() loadstring(HALLOWEEN_COINS_SCRIPT)() end) end)
			end
		else
			loaded = false
			pcall(function()
				local folder = workspace:FindFirstChild("ClientCoinVisuals")
				if folder then
					for _, c in ipairs(folder:GetChildren()) do
						if c.Name == "ClientCoin" then c:Destroy() end
					end
				end
			end)
		end
	end, 29)
end)

Defer(function()
	local loaded = false
	_G.GrabGunNotify = function(title, content, duration)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = title or "Gun System", Text = content or "", Duration = duration or 3
			})
		end)
	end
	local GRAB_GUN_SCRIPT = [==[
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local GunSystem = {
	AutoGrabEnabled = false, NotifyGunDrop = true, GunDropCheckInterval = 1,
	ActiveGunDrops = {}, OriginalCFrame = nil,
}
local function HasGunDrops()
	for _, child in pairs(workspace:GetDescendants()) do
		if child.Name == "GunDrop" then return true end
	end
	return false
end
local function ScanForGunDrops()
	GunSystem.ActiveGunDrops = {}
	for _, child in pairs(workspace:GetDescendants()) do
		if child.Name == "GunDrop" then table.insert(GunSystem.ActiveGunDrops, child) end
	end
end
local function GetNearestGun()
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local nearestGun = nil
	local minDistance = math.huge
	for _, drop in ipairs(GunSystem.ActiveGunDrops) do
		if drop and drop.Parent then
			local distance = (hrp.Position - drop.Position).Magnitude
			if distance < minDistance then minDistance = distance nearestGun = drop end
		end
	end
	return nearestGun
end
local function GrabGun(gunDrop)
	if not gunDrop then
		ScanForGunDrops()
		if #GunSystem.ActiveGunDrops == 0 then return false, "lobby" end
		gunDrop = GetNearestGun()
	end
	if not gunDrop then return false, "no_gun" end
	local c = LocalPlayer.Character
	if not c then return false, "no_char" end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return false, "no_hrp" end
	GunSystem.OriginalCFrame = hrp.CFrame
	hrp.CFrame = gunDrop.CFrame
	local prompt = gunDrop:FindFirstChildOfClass("ProximityPrompt")
	local grabbed = false
	if prompt then
		for i = 1, 3 do
			pcall(function() fireproximityprompt(prompt) end)
			task.wait(0.05)
			if c:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun")) then
				grabbed = true break
			end
		end
	end
	if GunSystem.OriginalCFrame and hrp and hrp.Parent then hrp.CFrame = GunSystem.OriginalCFrame end
	GunSystem.OriginalCFrame = nil
	if grabbed then
		if _G.GrabGunNotify then _G.GrabGunNotify("Gun System", "Gun grabbed!", 2) end
		return true
	end
	return false, "no_prompt"
end
local function AutoGrabGun()
	while GunSystem.AutoGrabEnabled do
		if not HasGunDrops() then
			task.wait(GunSystem.GunDropCheckInterval)
		else
			ScanForGunDrops()
			if #GunSystem.ActiveGunDrops > 0 and LocalPlayer.Character then
				local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local nearestGun = GetNearestGun()
					if nearestGun then
						GunSystem.OriginalCFrame = hrp.CFrame
						hrp.CFrame = nearestGun.CFrame
						local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt")
						if prompt then
							for i = 1, 3 do
								pcall(function() fireproximityprompt(prompt) end)
								task.wait(0.05)
								if LocalPlayer.Character:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun")) then break end
							end
						end
						if GunSystem.OriginalCFrame and hrp and hrp.Parent then hrp.CFrame = GunSystem.OriginalCFrame end
						GunSystem.OriginalCFrame = nil
						task.wait(0.5)
					end
				end
			end
			task.wait(GunSystem.GunDropCheckInterval)
		end
	end
end
_G.GrabGun_Manual = GrabGun
_G.GrabGun_StartAuto = function()
	GunSystem.AutoGrabEnabled = true
	task.spawn(AutoGrabGun)
end
_G.GrabGun_StopAuto = function()
	GunSystem.AutoGrabEnabled = false
end
]==]
	CreateToggle(MainScriptTab, "GRAB GUN", function(state)
		if state then
			if not loaded then
				loaded = true
				task.spawn(function()
					pcall(function()
						loadstring(GRAB_GUN_SCRIPT)()
						if _G.GrabGun_StartAuto then _G.GrabGun_StartAuto() end
					end)
				end)
			else
				pcall(function() if _G.GrabGun_StartAuto then _G.GrabGun_StartAuto() end end)
			end
		else
			pcall(function() if _G.GrabGun_StopAuto then _G.GrabGun_StopAuto() end end)
		end
	end, 30)
end)

pcall(function()
	local extras = {
		{"CUSTOM SHIFTLOCK","https://pastefy.app/FvWuWuH5/raw"},
		{"FOG SELECTOR","https://pastefy.app/8QJCOhgv/raw"},
		{"NORMAL SKYS","https://pastefy.app/qSmPvTjL/raw"},
		{"FONTS","https://pastefy.app/SLJ18Bf9/raw"},
	}
	for i, data in ipairs(extras) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,34)
		b.BackgroundColor3 = Color3.fromRGB(20,20,26)
		b.Text = data[1]
		b.TextColor3 = Color3.fromRGB(225,225,232)
		b.TextSize = 12
		b.Font = Enum.Font.GothamBold
		b.AutoButtonColor = false
		b.LayoutOrder = i
		b.Parent = ExtraTab
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255,255,255)
		s.Thickness = 1 s.Transparency = 0.82
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		task.defer(function() AddButtonSweep(b, s) end)
		b.MouseButton1Click:Connect(function()
			task.spawn(function() pcall(function() loadstring(game:HttpGet(data[2]))() end) end)
		end)
	end
end)

pcall(function()
	local SelectedTarget = nil
	local checkboxes = {}
	local FlingActive = false
	_G.OldPos = nil
	_G.FPDH = workspace.FallenPartsDestroyHeight
	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1,-40,0,25); status.Position = UDim2.new(0,20,0,44)
	status.BackgroundTransparency = 1
	status.Text = "SELECT A TARGET TO FLING"
	status.TextColor3 = Color3.fromRGB(165,165,170)
	status.Font = Enum.Font.Gotham status.TextSize = 12
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = FlingPage
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-40,0,130); frame.Position = UDim2.new(0,20,0,72)
	frame.BackgroundColor3 = Color3.fromRGB(18,18,23)
	frame.BorderSizePixel = 0 frame.Parent = FlingPage
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
	local scroll = Instance.new("ScrollingFrame", frame)
	scroll.Size = UDim2.new(1,-10,1,-10); scroll.Position = UDim2.fromOffset(5,5)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3; scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local lay = Instance.new("UIListLayout", scroll)
	lay.Padding = UDim.new(0,5); lay.SortOrder = Enum.SortOrder.LayoutOrder
	local btnC = Instance.new("Frame")
	btnC.Size = UDim2.new(1,-40,0,34); btnC.Position = UDim2.new(0,20,0,210)
	btnC.BackgroundTransparency = 1; btnC.Parent = FlingPage
	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0.48,0,1,0); startBtn.Position = UDim2.new(0,0,0,0)
	startBtn.BackgroundColor3 = Color3.fromRGB(0,180,0); startBtn.Text = "START"
	startBtn.TextColor3 = WHITE; startBtn.Font = Enum.Font.GothamBold; startBtn.TextSize = 12
	startBtn.AutoButtonColor = false
	startBtn.Parent = btnC; Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)
	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.new(0.48,0,1,0); stopBtn.Position = UDim2.new(0.52,0,0,0)
	stopBtn.BackgroundColor3 = Color3.fromRGB(180,0,0); stopBtn.Text = "STOP"
	stopBtn.TextColor3 = WHITE; stopBtn.Font = Enum.Font.GothamBold; stopBtn.TextSize = 12
	stopBtn.AutoButtonColor = false
	stopBtn.Parent = btnC; Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,10)
	local antiFlingBtn = Instance.new("TextButton")
	antiFlingBtn.Size = UDim2.new(1,-40,0,34); antiFlingBtn.Position = UDim2.new(0,20,0,250)
	antiFlingBtn.BackgroundColor3 = Color3.fromRGB(20,20,26)
	antiFlingBtn.Text = "ANTI FLING"; antiFlingBtn.TextColor3 = Color3.fromRGB(225,225,232)
	antiFlingBtn.Font = Enum.Font.GothamBold; antiFlingBtn.TextSize = 12
	antiFlingBtn.AutoButtonColor = false
	antiFlingBtn.Parent = FlingPage; Instance.new("UICorner", antiFlingBtn).CornerRadius = UDim.new(0,10)
	local afs = Instance.new("UIStroke", antiFlingBtn); afs.Color = Color3.fromRGB(52,52,60)
	local afLoaded = false
	antiFlingBtn.MouseButton1Click:Connect(function()
		if afLoaded then return end
		afLoaded = true
		task.spawn(function()
			local _P = game:GetService("Players")
			local _R = game:GetService("RunService")
			local _C = game:GetService("CoreGui")
			local _W = game:GetService("Workspace")
			local lp = _P.LocalPlayer
			local conns = {}
			local isEnabled = true
			local gui = Instance.new("ScreenGui")
			gui.Name = "AntiFlingIndicator"
			gui.ResetOnSpawn = false
			local parent = pcall(function() return _C.RobloxGui end) and _C or lp:WaitForChild("PlayerGui")
			gui.Parent = parent
			local lbl = Instance.new("TextButton")
			lbl.Size = UDim2.new(0,200,0,30); lbl.Position = UDim2.new(0,15,1,-45)
			lbl.BackgroundTransparency = 1
			lbl.Text = "Anti-Fling & Ring: Enabled"
			lbl.TextColor3 = Color3.fromRGB(0,255,140)
			lbl.TextSize = 16; lbl.Font = Enum.Font.SourceSansBold
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = gui
			local st = Instance.new("UIStroke", lbl)
			st.Thickness = 1.5; st.Color = Color3.fromRGB(0,0,0); st.Transparency = 0.3
			local function updateUI()
				if isEnabled then lbl.Text = "Anti-Fling & Ring: Enabled"; lbl.TextColor3 = Color3.fromRGB(0,255,140)
				else lbl.Text = "Anti-Fling & Ring: Disabled"; lbl.TextColor3 = Color3.fromRGB(255,80,80) end
			end
			local function setupCol(ch)
				local function dis(p) if isEnabled and p:IsA("BasePart") then p.CanCollide = false end end
				for _, p in ipairs(ch:GetChildren()) do dis(p) end
				local cc = ch.ChildAdded:Connect(dis)
				local sc = _R.Stepped:Connect(function()
					if isEnabled and ch:IsDescendantOf(_W) then
						for _, p in ipairs(ch:GetChildren()) do
							if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
						end
					end
				end)
				ch.Destroying:Connect(function() cc:Disconnect(); sc:Disconnect() end)
			end
			local function track(p)
				if p == lp then return end
				local c = p.CharacterAdded:Connect(setupCol)
				if p.Character then setupCol(p.Character) end
				conns[p] = c
			end
			for _, p in ipairs(_P:GetPlayers()) do track(p) end
			_P.PlayerAdded:Connect(track)
			_P.PlayerRemoving:Connect(function(p) if conns[p] then conns[p]:Disconnect() conns[p]=nil end end)
			local function Secure(part, pos, mc)
				if not part:IsA("BasePart") or part.Anchored or part:IsDescendantOf(mc) then return end
				local d = (part.Position - pos).Magnitude
				if d <= 25 then
					local v = part.AssemblyLinearVelocity.Magnitude
					local rv = part.AssemblyAngularVelocity.Magnitude
					if v > 80 or rv > 80 then
						part.CanCollide = false
						part.AssemblyLinearVelocity = Vector3.new(0,0,0)
						part.AssemblyAngularVelocity = Vector3.new(0,0,0)
						pcall(function() part.CFrame = part.CFrame + Vector3.new(0,500,0) end)
					end
				end
			end
			_R.Heartbeat:Connect(function()
				if not isEnabled then return end
				local mc = lp.Character; if not mc then return end
				local hrp = mc:FindFirstChild("HumanoidRootPart"); if not hrp then return end
				local hp = hrp.Position
				for _, item in ipairs(_W:GetChildren()) do
					if item:IsA("BasePart") then Secure(item, hp, mc)
					elseif item:IsA("Model") and not _P:GetPlayerFromCharacter(item) then
						for _, p in ipairs(item:GetDescendants()) do
							if p:IsA("BasePart") then Secure(p, hp, mc) end
						end
					end
				end
			end)
			lbl.MouseButton1Click:Connect(function() isEnabled = not isEnabled; updateUI() end)
			lp.Chatted:Connect(function(msg)
				msg = msg:lower()
				if msg == ";af on" or msg == ";antifling on" then isEnabled = true
				elseif msg == ";af off" or msg == ";antifling off" then isEnabled = false end
				updateUI()
			end)
		end)
	end)
	local function Refresh()
		for _, c in pairs(scroll:GetChildren()) do if c ~= lay then c:Destroy() end end
		checkboxes = {}
		local pl = Players:GetPlayers()
		table.sort(pl, function(a,b) return a.Name:lower() < b.Name:lower() end)
		local hasOther = false
		local lo = 1
		for _, plr in ipairs(pl) do
			if plr ~= Player then
				hasOther = true
				local pe = Instance.new("Frame")
				pe.Size = UDim2.new(1,-5,0,28); pe.BackgroundColor3 = Color3.fromRGB(30,30,36)
				pe.LayoutOrder = lo; pe.Parent = scroll
				Instance.new("UICorner", pe).CornerRadius = UDim.new(0,8)
				local cb = Instance.new("TextButton")
				cb.Size = UDim2.fromOffset(22,22); cb.Position = UDim2.fromOffset(3,3)
				cb.BackgroundColor3 = Color3.fromRGB(45,45,52); cb.Text = ""; cb.Parent = pe
				Instance.new("UICorner", cb).CornerRadius = UDim.new(0,5)
				local cm = Instance.new("TextLabel")
				cm.Size = UDim2.new(1,0,1,0); cm.BackgroundTransparency = 1; cm.Text = "v"
				cm.TextColor3 = Color3.fromRGB(0,255,0); cm.TextSize = 14; cm.Font = Enum.Font.SourceSansBold
				cm.Visible = SelectedTarget == plr; cm.Parent = cb
				local nl = Instance.new("TextLabel")
				nl.Size = UDim2.new(1,-35,1,0); nl.Position = UDim2.fromOffset(28,0); nl.BackgroundTransparency = 1
				nl.Text = plr.Name:upper(); nl.TextColor3 = Color3.fromRGB(225,225,232); nl.TextSize = 11
				nl.Font = Enum.Font.GothamMedium; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = pe
				local ca = Instance.new("TextButton")
				ca.Size = UDim2.new(1,0,1,0); ca.BackgroundTransparency = 1; ca.Text = ""
				ca.ZIndex = 2; ca.Parent = pe
				ca.MouseButton1Click:Connect(function()
					if SelectedTarget == plr then SelectedTarget = nil cm.Visible = false
					else
						if SelectedTarget then
							local oc = checkboxes[SelectedTarget.Name]
							if oc then oc.Checkmark.Visible = false end
						end
						SelectedTarget = plr cm.Visible = true
					end
					UpdateStatus()
				end)
				checkboxes[plr.Name] = {Entry=pe, Checkmark=cm}
				lo = lo + 1
			end
		end
		if not hasOther then
			local lb = Instance.new("TextLabel")
			lb.Size = UDim2.new(1,-10,0,20); lb.BackgroundTransparency = 1
			lb.Text = "No other players in the server"
			lb.TextXAlignment = Enum.TextXAlignment.Center
			lb.TextColor3 = Color3.fromRGB(120,120,128); lb.TextSize = 11
			lb.Font = Enum.Font.Gotham; lb.LayoutOrder = 1
			lb.Parent = scroll
		end
	end
	function UpdateStatus()
		if FlingActive then
			if SelectedTarget then status.Text = "FLINGING: "..SelectedTarget.Name:upper(); status.TextColor3 = Color3.fromRGB(255,80,80)
			else status.Text = "NO TARGET SELECTED"; status.TextColor3 = Color3.fromRGB(255,80,80) end
		else
			if SelectedTarget then status.Text = "TARGET: "..SelectedTarget.Name:upper(); status.TextColor3 = Color3.fromRGB(0,255,0)
			else status.Text = "SELECT A TARGET TO FLING"; status.TextColor3 = Color3.fromRGB(165,165,170) end
		end
	end
	local function FlingMsg(T, Tx, D)
		game:GetService("StarterGui"):SetCore("SendNotification", {Title=T, Text=Tx, Duration=D or 5})
	end
	local function SkidFling(tp)
		local Char = Player.Character
		local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
		local RP = Hum and Hum.RootPart
		local TC = tp.Character
		if not TC then return end
		local TH, TR, THead, Acc, Hand
		if TC:FindFirstChildOfClass("Humanoid") then TH = TC:FindFirstChildOfClass("Humanoid") end
		if TH and TH.RootPart then TR = TH.RootPart end
		if TC:FindFirstChild("Head") then THead = TC.Head end
		if TC:FindFirstChildOfClass("Accessory") then Acc = TC:FindFirstChildOfClass("Accessory") end
		if Acc and Acc:FindFirstChild("Handle") then Hand = Acc.Handle end
		local function FPos(bp, P, A)
			RP.CFrame = CFrame.new(bp.Position) * P * A
			Char:SetPrimaryPartCFrame(CFrame.new(bp.Position) * P * A)
			RP.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
			RP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		end
		local function SFBasePart(bp)
			local TtW = 2; local T = tick(); local A = 0
			repeat
				if RP and TH then
					if bp.Velocity.Magnitude < 50 then
						A = A + 100
						FPos(bp, CFrame.new(0,1.5,0) + TH.MoveDirection * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(A),0,0)) task.wait()
						FPos(bp, CFrame.new(0,-1.5,0) + TH.MoveDirection * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(A),0,0)) task.wait()
						FPos(bp, CFrame.new(0,1.5,0) + TH.MoveDirection * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(A),0,0)) task.wait()
						FPos(bp, CFrame.new(0,-1.5,0) + TH.MoveDirection * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(A),0,0)) task.wait()
					else
						FPos(bp, CFrame.new(0,1.5,TH.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
						FPos(bp, CFrame.new(0,-1.5,-TH.WalkSpeed), CFrame.Angles(0,0,0)) task.wait()
						FPos(bp, CFrame.new(0,1.5,TH.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
					end
				end
			until T + TtW < tick() or not FlingActive
		end
		if Char and Hum and RP then
			if RP.Velocity.Magnitude < 50 then _G.OldPos = RP.CFrame end
			if TH and TH.Sit then return FlingMsg("Error", tp.Name.." is sitting", 2) end
			if THead then workspace.CurrentCamera.CameraSubject = THead
			elseif Hand then workspace.CurrentCamera.CameraSubject = Hand
			elseif TH and TR then workspace.CurrentCamera.CameraSubject = TH end
			if not TC:FindFirstChildWhichIsA("BasePart") then return end
			workspace.FallenPartsDestroyHeight = 0/0
			local BV = Instance.new("BodyVelocity")
			BV.Parent = RP; BV.Velocity = Vector3.new(0,0,0); BV.MaxForce = Vector3.new(9e9,9e9,9e9)
			Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			if TR then SFBasePart(TR)
			elseif THead then SFBasePart(THead)
			elseif Hand then SFBasePart(Hand)
			else return FlingMsg("Error", tp.Name.." has no valid parts", 2) end
			BV:Destroy()
			Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
			workspace.CurrentCamera.CameraSubject = Hum
			if _G.OldPos then
				repeat
					RP.CFrame = _G.OldPos * CFrame.new(0,.5,0)
					Char:SetPrimaryPartCFrame(_G.OldPos * CFrame.new(0,.5,0))
					Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
					for _, p in pairs(Char:GetChildren()) do
						if p:IsA("BasePart") then p.Velocity, p.RotVelocity = Vector3.new(), Vector3.new() end
					end
					task.wait()
				until (RP.Position - _G.OldPos.p).Magnitude < 25
				workspace.FallenPartsDestroyHeight = _G.FPDH
			end
		else FlingMsg("Error", "Your character is not ready", 2) end
	end
	local function StartFling()
		if FlingActive then return end
		if not SelectedTarget then
			status.Text = "NO TARGET SELECTED!"; status.TextColor3 = Color3.fromRGB(255,80,80)
			task.wait(1); UpdateStatus(); return
		end
		FlingActive = true; UpdateStatus()
		FlingMsg("Started", "Flinging "..SelectedTarget.Name, 2)
		task.spawn(function()
			while FlingActive and SelectedTarget and SelectedTarget.Parent do
				SkidFling(SelectedTarget); task.wait(0.5)
			end
			if FlingActive then FlingActive = false UpdateStatus() end
		end)
	end
	local function StopFling()
		if not FlingActive then return end
		FlingActive = false; UpdateStatus()
		FlingMsg("Stopped", "Fling has been stopped", 2)
	end
	startBtn.MouseButton1Click:Connect(StartFling)
	stopBtn.MouseButton1Click:Connect(StopFling)
	Players.PlayerAdded:Connect(function() Refresh(); UpdateStatus() end)
	Players.PlayerRemoving:Connect(function(plr)
		if SelectedTarget == plr then SelectedTarget = nil StopFling() end
		Refresh(); UpdateStatus()
	end)
	Refresh(); UpdateStatus()
end)

pcall(function()
	local SkysContent = Instance.new("Frame")
	SkysContent.Size = UDim2.new(1,-40,0,0); SkysContent.Position = UDim2.new(0,20,0,44)
	SkysContent.BackgroundTransparency = 1
	SkysContent.AutomaticSize = Enum.AutomaticSize.Y
	SkysContent.Parent = SkysPage
	local scl = Instance.new("UIListLayout", SkysContent)
	scl.Padding = UDim.new(0,6) scl.SortOrder = Enum.SortOrder.LayoutOrder
	local function MakeBtn(text, order, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,34)
		b.BackgroundColor3 = color or Color3.fromRGB(20,20,26)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(225,225,232)
		b.TextSize = 12 b.Font = Enum.Font.GothamBold
		b.AutoButtonColor = false b.LayoutOrder = order b.Parent = SkysContent
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255,255,255) s.Thickness = 1
		s.Transparency = 0.82 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		task.defer(function() AddButtonSweep(b, s) end)
		return b
	end
	local Skyboxes = {
		{Name="Sky 1",Back="122934223825685",Down="115889796012252",Front="127432502457919",Left="118552411654693",Right="79507204666851",Up="90208876152081"},
		{Name="Sky 2",Back="139390286893123",Down="121969345727987",Front="102819125070844",Left="86079154252447",Right="78213322249241",Up="89785225740474"},
		{Name="Sky 3",Back="135297280579161",Down="76872220095611",Front="133452089641107",Left="104464782805839",Right="88627908709078",Up="82728976669867"},
		{Name="Sky 4",Back="125361770311798",Down="84986792965799",Front="71926790036327",Left="80270684482299",Right="139503624377529",Up="129974929767598"},
		{Name="Sky 5",Back="78366053018585",Down="80593398028009",Front="76815829523406",Left="99278660066964",Right="92551426613821",Up="93178570104201"},
		{Name="Sky 6",Back="108490883219950",Down="83979157302834",Front="111509103855418",Left="127713607271834",Right="71576410206100",Up="110575804368654"},
		{Name="Sky 7",Back="95550451962323",Down="83045734646125",Front="129562849054459",Left="118371554826747",Right="101233513548135",Up="88234705892910"},
		{Name="Sky 8",Back="90279174475113",Down="91697419352490",Front="99522435223734",Left="96290695595924",Right="111464690112367",Up="125452256898323"},
		{Name="Sky 9",Back="72619789836283",Down="80110246093743",Front="70567185865768",Left="113675282299602",Right="114492196422762",Up="101531514665368"},
		{Name="Sky 10",Back="116025027141142",Down="91105529996227",Front="90994877832615",Left="76320253022963",Right="131482021172533",Up="109004624250689"},
		{Name="Sky 11",Back="107251355223624",Down="83205792336157",Front="71340008866251",Left="125791437816718",Right="71443059006849",Up="130669603754676"},
		{Name="Sky 12",Back="78974757918476",Down="88177838801532",Front="83696765595194",Left="80447485501505",Right="135497297426946",Up="102091318834072"},
		{Name="Sky 13",Back="105535030667579",Down="113984561181990",Front="72226392275865",Left="88854323447259",Right="110452496687728",Up="122047635706897"},
		{Name="Sky 14",Back="124146095783478",Down="75871503875015",Front="133344723393123",Left="83557645212831",Right="84479739687182",Up="107126607249996"},
		{Name="Sky 15",Back="136271246766239",Down="120742221412719",Front="73227687014244",Left="93167611234429",Right="82709661173321",Up="115140875058317"},
		{Name="Sky 16",Back="114139612934123",Down="90346282865176",Front="94648621639198",Left="95124593236403",Right="115581569699911",Up="82469672086631"},
		{Name="Sky 17",Back="72674991815244",Down="87505757796543",Front="104043580662234",Left="107911309901437",Right="117436248357763",Up="138822078180711"},
		{Name="Sky 18",Back="101374831141830",Down="79523432178948",Front="88809144482369",Left="84329682776067",Right="99623598932161",Up="92829689188161"},
		{Name="Sky 19",Back="84253787357847",Down="98517147316354",Front="85272281419204",Left="82726308499905",Right="130700286255075",Up="112088931574592"},
		{Name="Sky 20",Back="125715699407678",Down="92557144615650",Front="106120373681716",Left="90854332528050",Right="79136222060909",Up="138582836272534"},
		{Name="Sky 21",Back="83065384836758",Down="123753098422400",Front="101874400789076",Left="97676464102987",Right="102889206709438",Up="114893853504854"},
		{Name="Sky 22",Back="126957334839837",Down="124789516913162",Front="106981517570804",Left="110573097753216",Right="108949473348216",Up="81123655405713"},
		{Name="Sky 23",Back="124867445958167",Down="77570414004049",Front="134287027086306",Left="102126593227587",Right="125503342941690",Up="139811186161364"},
		{Name="Sky 24",Back="128240585247257",Down="90711592446732",Front="84230416287375",Left="95408956162423",Right="104372803680818",Up="98218625044448"},
		{Name="Sky 25",Back="70709088911461",Down="DEFAULT",Front="108716398418273",Left="135388293131862",Right="79650912965547",Up="DEFAULT"},
		{Name="Sky 26",Back="128721828976190",Down="118052598671512",Front="83777700844838",Left="73690548531519",Right="115624635885078",Up="90472776728250"},
		{Name="Sky 27",Back="85107330219111",Down="129032897277288",Front="118661492039109",Left="88796316159716",Right="107736507232345",Up="76916029625610"},
		{Name="Sky 28",Back="92398976166346",Down="100496201019934",Front="75701876953479",Left="95047339042001",Right="81354706608954",Up="80818992655814"},
		{Name="Sky 29",Back="130589575166222",Down="107271043230069",Front="86496948749493",Left="97265162197005",Right="83576900387587",Up="126473822656804"},
		{Name="Sky 30",Back="120578338054567",Down="111085377072223",Front="85944987685748",Left="98749617583097",Right="103874052666748",Up="71693043371807"},
	}
	local function ApplySky(d)
		for _, o in ipairs(Lighting:GetChildren()) do if o:IsA("Sky") then o:Destroy() end end
		local s = Instance.new("Sky")
		s.Name = "SelectedSkybox"
		s.SkyboxBk = "rbxassetid://"..d.Back
		if d.Down ~= "DEFAULT" then s.SkyboxDn = "rbxassetid://"..d.Down end
		s.SkyboxFt = "rbxassetid://"..d.Front
		s.SkyboxLf = "rbxassetid://"..d.Left
		s.SkyboxRt = "rbxassetid://"..d.Right
		if d.Up ~= "DEFAULT" then s.SkyboxUp = "rbxassetid://"..d.Up end
		s.Parent = Lighting
	end
	for i, sd in ipairs(Skyboxes) do
		local b = MakeBtn(sd.Name:upper(), 5 + i)
		b.MouseButton1Click:Connect(function() ApplySky(sd) end)
	end
	local resetBtn = MakeBtn("RESET SKY TO DEFAULT", 500, Color3.fromRGB(180,40,40))
	resetBtn.MouseButton1Click:Connect(function()
		for _, o in ipairs(Lighting:GetChildren()) do if o:IsA("Sky") then o:Destroy() end end
	end)
end)

pcall(function()
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1,-40,0,0) box.Position = UDim2.new(0,20,0,20)
	box.BackgroundColor3 = Color3.fromRGB(15,15,20) box.BorderSizePixel = 0
	box.AutomaticSize = Enum.AutomaticSize.Y box.Parent = AnimationsPage
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,12)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(45,45,52)
	local boxPad = Instance.new("UIPadding", box)
	boxPad.PaddingTop = UDim.new(0,12) boxPad.PaddingBottom = UDim.new(0,12)
	boxPad.PaddingLeft = UDim.new(0,12) boxPad.PaddingRight = UDim.new(0,12)
	local boxLay = Instance.new("UIListLayout", box)
	boxLay.Padding = UDim.new(0,8) boxLay.SortOrder = Enum.SortOrder.LayoutOrder
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,22) title.BackgroundTransparency = 1
	title.Text = "Gaze Anims" title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(245,245,247) title.TextSize = 16
	title.Font = Enum.Font.GothamBold title.LayoutOrder = 1 title.Parent = box
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1,0,0,14) sub.BackgroundTransparency = 1
	sub.Text = "R15 required · click to apply" sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextColor3 = Color3.fromRGB(130,130,136) sub.TextSize = 10
	sub.Font = Enum.Font.Gotham sub.LayoutOrder = 2 sub.Parent = box
	local searchRow = Instance.new("Frame")
	searchRow.Size = UDim2.new(1,0,0,32) searchRow.BackgroundColor3 = Color3.fromRGB(18,18,23)
	searchRow.BorderSizePixel = 0 searchRow.LayoutOrder = 3 searchRow.Parent = box
	Instance.new("UICorner", searchRow).CornerRadius = UDim.new(0,8)
	local ss = Instance.new("UIStroke", searchRow)
	ss.Color = Color3.fromRGB(52,52,60)
	local searchTb = Instance.new("TextBox")
	searchTb.Size = UDim2.new(1,-36,1,0) searchTb.Position = UDim2.new(0,32,0,0)
	searchTb.BackgroundTransparency = 1
	searchTb.PlaceholderText = "Search..." searchTb.PlaceholderColor3 = Color3.fromRGB(105,105,112)
	searchTb.Text = "" searchTb.TextColor3 = Color3.fromRGB(240,240,240)
	searchTb.TextSize = 12 searchTb.Font = Enum.Font.Gotham
	searchTb.TextXAlignment = Enum.TextXAlignment.Left searchTb.ClearTextOnFocus = false
	searchTb.Parent = searchRow
	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Size = UDim2.fromOffset(14,14) searchIcon.Position = UDim2.new(0,10,0.5,-7)
	searchIcon.BackgroundTransparency = 1 searchIcon.Image = "rbxassetid://6031091004"
	searchIcon.ImageColor3 = Color3.fromRGB(150,150,158) searchIcon.Parent = searchRow
	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1,0,0,300) listFrame.BackgroundColor3 = Color3.fromRGB(18,18,23)
	listFrame.BorderSizePixel = 0 listFrame.LayoutOrder = 4 listFrame.Parent = box
	Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,8)
	local lfStroke = Instance.new("UIStroke", listFrame)
	lfStroke.Color = Color3.fromRGB(52,52,60)
	local lscroll = Instance.new("ScrollingFrame", listFrame)
	lscroll.Size = UDim2.new(1,-8,1,-8) lscroll.Position = UDim2.new(0,4,0,4)
	lscroll.BackgroundTransparency = 1 lscroll.BorderSizePixel = 0
	lscroll.ScrollBarThickness = 3 lscroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,90)
	lscroll.CanvasSize = UDim2.new() lscroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local llay = Instance.new("UIListLayout", lscroll)
	llay.Padding = UDim.new(0,4) llay.SortOrder = Enum.SortOrder.LayoutOrder
	local Filtered = {
		["Idle"] = {
			["Levitation"]={"616006778","616008087"}, ["Toy"]={"782841498","782845736"},
			["Vampire"]={"1083445855","1083450166"}, ["Zombie"]={"616158929","616160636"},
			["Astronaut"]={"891621366","891633237"}, ["Bubbly"]={"910004836","910009958"},
			["OldSchool"]={"10921230744","10921232093"}, ["Mage"]={"707742142","707855907"},
		},
		["Walk"]={["Levitation"]="616013216",["Toy"]="782843345",["Vampire"]="1083473930",["Zombie"]="616168032",["Astronaut"]="891667138",["Bubbly"]="910034870",["Rthro"]="10921269718",["OldSchool"]="10921244891",["Mage"]="707897309"},
		["Run"]={["Levitation"]="616010382",["Toy"]="10921306285",["Vampire"]="10921320299",["Zombie"]="616163682",["Astronaut"]="10921039308",["Bubbly"]="10921057244",["Rthro"]="10921261968",["OldSchool"]="10921240218",["Mage"]="10921148209"},
		["Jump"]={["Levitation"]="616008936",["Toy"]="10921308158",["Vampire"]="1083455352",["Zombie"]="616161997",["Astronaut"]="891627522",["Bubbly"]="910016857",["Rthro"]="10921263860",["OldSchool"]="10921242013",["Mage"]="10921149743"},
		["Fall"]={["Levitation"]="616005863",["Toy"]="782846423",["Vampire"]="1083443587",["Zombie"]="616157476",["Astronaut"]="891617961",["Bubbly"]="910001910",["Rthro"]="10921262864",["OldSchool"]="10921241244",["Mage"]="707829716"},
	}
	local function GetHum() local c = Player.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
	local function IsR15() local h = GetHum() return h and h.RigType == Enum.HumanoidRigType.R15 end
	local function Freeze()
		local c = Player.Character if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then h.PlatformStand = true end
		task.spawn(function() for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored then p.Anchored = true end end end)
	end
	local function Unfreeze()
		local c = Player.Character if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then h.PlatformStand = false end
		task.spawn(function() for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Anchored then p.Anchored = false end end end)
	end
	local function RefState(s) local h = GetHum() if h then h:ChangeState(s) end end
	local LastA = {}
	local RestoringAnim = false
	local function SetAnim(animType, id, isRestore)
		local c = Player.Character if not c then return end
		local anim = c:FindFirstChild("Animate") if not anim then return end
		if not isRestore then Freeze() task.wait(0.1) end
		pcall(function()
			if animType == "Idle" then
				LastA.Idle = id
				anim.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. id[1]
				anim.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. id[2]
				RefState(Enum.HumanoidStateType.Freefall)
			elseif animType == "Walk" then
				LastA.Walk = id anim.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. id
				RefState(Enum.HumanoidStateType.Freefall)
			elseif animType == "Run" then
				LastA.Run = id anim.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. id
				RefState(Enum.HumanoidStateType.Freefall)
			elseif animType == "Jump" then
				LastA.Jump = id anim.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. id
				RefState(Enum.HumanoidStateType.Freefall)
			elseif animType == "Fall" then
				LastA.Fall = id anim.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. id
				RefState(Enum.HumanoidStateType.Freefall)
			end
		end)
		if not isRestore then task.wait(0.1) Unfreeze() end
	end
	local AnimBtns = {}
	local ORDER = {"Idle","Walk","Run","Jump","Fall"}
	local o = 0
	for _, t in ipairs(ORDER) do
		local list = Filtered[t]
		if list then
			for name, id in pairs(list) do
					o = o + 1
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1,-4,0,32) b.BackgroundColor3 = Color3.fromRGB(28,28,36)
				b.Text = name .. "  ·  " .. t b.TextColor3 = Color3.fromRGB(225,225,232)
				b.TextSize = 11 b.Font = Enum.Font.GothamBold
				b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false
				b.LayoutOrder = o b.Parent = lscroll
				Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
				local pad = Instance.new("UIPadding", b)
				pad.PaddingLeft = UDim.new(0,12)
				b.MouseButton1Click:Connect(function()
					if not IsR15() then
						b.Text = "R15 required!" b.TextColor3 = Color3.fromRGB(255,80,80)
						task.wait(1.2) b.Text = name .. "  ·  " .. t b.TextColor3 = Color3.fromRGB(225,225,232)
						return
					end
					task.spawn(function() SetAnim(t, id, false) end)
					b.TextColor3 = ACCENT task.wait(0.4) b.TextColor3 = Color3.fromRGB(225,225,232)
				end)
				table.insert(AnimBtns, {btn=b, name=name, type=t})
			end
		end
	end
	searchTb:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchTb.Text:lower()
		for _, e in ipairs(AnimBtns) do
			if q == "" then e.btn.Visible = true
			else
				local hay = (e.name .. " " .. e.type):lower()
				e.btn.Visible = hay:find(q,1,true) ~= nil
			end
		end
	end)
	Player.CharacterAdded:Connect(function(newChar)
		if RestoringAnim then return end
		if not (LastA.Idle or LastA.Walk or LastA.Run or LastA.Jump or LastA.Fall) then return end
		RestoringAnim = true
		task.wait(1.5)
		local hum = newChar:FindFirstChildOfClass("Humanoid")
		if not hum then RestoringAnim = false return end
		if hum.RigType ~= Enum.HumanoidRigType.R15 then RestoringAnim = false return end
		local animateScript = newChar:FindFirstChild("Animate")
		if not animateScript then
			for i = 1, 10 do
				task.wait(0.2)
				animateScript = newChar:FindFirstChild("Animate")
				if animateScript then break end
			end
		end
		if animateScript then
			if LastA.Idle then pcall(function() SetAnim("Idle", LastA.Idle, true) end) end
			task.wait(0.15)
			if LastA.Walk then pcall(function() SetAnim("Walk", LastA.Walk, true) end) end
			task.wait(0.15)
			if LastA.Run then pcall(function() SetAnim("Run", LastA.Run, true) end) end
			task.wait(0.15)
			if LastA.Jump then pcall(function() SetAnim("Jump", LastA.Jump, true) end) end
			task.wait(0.15)
			if LastA.Fall then pcall(function() SetAnim("Fall", LastA.Fall, true) end) end
		end
		RestoringAnim = false
	end)
end)

if HasSession() and isWhitelisted(Player.Name) then
	task.defer(function()
		if GUI.Parent then LoginSuccess() end
	end)
end
