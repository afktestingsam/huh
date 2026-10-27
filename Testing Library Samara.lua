local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local parentGui
if gethui then
	parentGui = gethui()
else
	parentGui = player:WaitForChild("PlayerGui")
end

local SESSION_FILE = "Pompompurin_Session.json"
local SESSION_SECONDS = 24 * 60 * 60

local function hasSession()
	if not (isfile and readfile) then return false end
	local ok, data = pcall(function()
		if not isfile(SESSION_FILE) then return nil end
		return HttpService:JSONDecode(readfile(SESSION_FILE))
	end)
	if not (ok and type(data) == "table" and data.unlocked == true and data.userId == player.UserId) then
		return false
	end
	local age = os.time() - (tonumber(data.savedAt) or 0)
	if age >= 0 and age < SESSION_SECONDS then
		return true
	end
	if delfile then pcall(delfile, SESSION_FILE) end
	return false
end

local function saveSession()
	if not writefile then return end
	pcall(function()
		writefile(SESSION_FILE, HttpService:JSONEncode({
			unlocked = true,
			userId = player.UserId,
			savedAt = os.time(),
		}))
	end)
end

local Library = {}
local OnLoginCallbacks = {}
local WHITELIST_ENABLED = true

local isWhitelisted
local userRanks = {}

do
	local WHITELIST = {
		["jerehzxs"]     = {"OWNER"},
		["chiquille_xd"] = {"NOVIO", "TESTER"},
		["jerehvo"]      = {"PUTA", "TESTER"},
		["b92b08a"]      = {"PUTA", "MEMBER"},
		["astrixrsz"]    = {"MEMBER"},
		["danterafael15"] = {"PUTA", "MEMBER"},
		["28kxlucaz"] = {"PUTA", "MEMBER"},
	}

	local POMPOM = {
		Color3.fromRGB(245, 190, 60), Color3.fromRGB(214, 140, 70),
		Color3.fromRGB(150, 100, 60), Color3.fromRGB(240, 150, 150),
	}

	local RANK_STYLES = {
		OWNER = {text = "Owner", colors = POMPOM},
		NOVIO = {text = "Mi novio por que yo mando", rainbow = true},
		PUTA = {text = "Puta", colors = {
			Color3.fromRGB(255, 105, 180), Color3.fromRGB(214, 112, 230),
			Color3.fromRGB(150, 90, 230), Color3.fromRGB(255, 150, 210),
		}},
		TESTER = {text = "Tester", colors = {
			Color3.fromRGB(0, 80, 255), Color3.fromRGB(255, 0, 0),
		}},
		MEMBER = {text = "Member", colors = POMPOM},
	}

	isWhitelisted = function(name)
		if not name then return false end
		return WHITELIST[name:lower()] ~= nil
	end

	local keys = WHITELIST[player.Name:lower()] or {"MEMBER"}
	for _, key in ipairs(keys) do
		table.insert(userRanks, RANK_STYLES[key])
	end
end

-- SISTEMA PARA BORRAR LA GUI ANTIGUA Y EVITAR QUE SE DUPLIQUE/CORROMPA
local oldGui = parentGui:FindFirstChild("PompompurinGUI") or player:WaitForChild("PlayerGui"):FindFirstChild("PompompurinGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PompompurinGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("ImageLabel")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
MainFrame.Size = UDim2.new(0, 480, 0, 300)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Image = "rbxassetid://107511081354023"
MainFrame.BackgroundTransparency = 1
MainFrame.ImageTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = MainFrame

local function createMacButton(name, posX)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = UDim2.new(0, posX, 0, 14)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.Active = true
    btn.Parent = MainFrame
    return btn
end

local BtnRojo = createMacButton("BtnRojo", 18)
local BtnAmarillo = createMacButton("BtnAmarillo", 50)
local BtnVerde = createMacButton("BtnVerde", 82)

local Burbuja = Instance.new("Frame")
Burbuja.Name = "Burbuja"
Burbuja.Size = UDim2.new(0, 0, 0, 0)
Burbuja.AnchorPoint = Vector2.new(0.5, 0.5)
Burbuja.Position = UDim2.new(0.5, 0, 1, -70)
Burbuja.BackgroundColor3 = Color3.fromRGB(255, 235, 150)
Burbuja.Visible = false
Burbuja.ZIndex = 10
Burbuja.Parent = ScreenGui

local BubbleCorner = Instance.new("UICorner")
BubbleCorner.CornerRadius = UDim.new(0, 12)
BubbleCorner.Parent = Burbuja

local BubbleImage = Instance.new("ImageLabel")
BubbleImage.Name = "BubbleImage"
BubbleImage.Size = UDim2.new(1, 0, 1, 0)
BubbleImage.BackgroundTransparency = 1
BubbleImage.Image = "rbxassetid://127095703258714"
BubbleImage.ScaleType = Enum.ScaleType.Crop
BubbleImage.Parent = Burbuja

local BubbleImageCorner = Instance.new("UICorner")
BubbleImageCorner.CornerRadius = UDim.new(0, 12)
BubbleImageCorner.Parent = BubbleImage

local KeyContainer = Instance.new("Frame")
KeyContainer.Name = "KeyContainer"
KeyContainer.Size = UDim2.new(1, 0, 1, 0)
KeyContainer.BackgroundTransparency = 1
KeyContainer.ZIndex = 4
KeyContainer.Parent = MainFrame

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(0, 300, 0, 25)
KeyTitle.Position = UDim2.new(0.5, -150, 0, 144)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "Enter Password"
KeyTitle.TextColor3 = Color3.fromRGB(110, 75, 50)
KeyTitle.TextSize = 20
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.ZIndex = 6
KeyTitle.Parent = KeyContainer

local KeyAvatar = Instance.new("ImageLabel")
KeyAvatar.Name = "KeyAvatar"
KeyAvatar.Size = UDim2.new(0, 75, 0, 75)
KeyAvatar.Position = UDim2.new(0.5, -37.5, 0, 56)
KeyAvatar.BackgroundTransparency = 1
KeyAvatar.ScaleType = Enum.ScaleType.Fit
KeyAvatar.ZIndex = 6
KeyAvatar.Parent = KeyContainer

local KeyAvatarCorner = Instance.new("UICorner")
KeyAvatarCorner.CornerRadius = UDim.new(1, 0)
KeyAvatarCorner.Parent = KeyAvatar

local BOX_W, BOX_H = 265, 195
local BOX_CENTER_Y = 195

local KeyFrameImg = Instance.new("ImageLabel")
KeyFrameImg.Name = "KeyFrameImg"
KeyFrameImg.AnchorPoint = Vector2.new(0.5, 0.5)
KeyFrameImg.Size = UDim2.new(0, BOX_W, 0, BOX_H)
KeyFrameImg.Position = UDim2.new(0.5, 0, 0, BOX_CENTER_Y)
KeyFrameImg.Image = "rbxassetid://119450379522482"
KeyFrameImg.BackgroundTransparency = 1
KeyFrameImg.ScaleType = Enum.ScaleType.Stretch
KeyFrameImg.Active = false
KeyFrameImg.ZIndex = 5
KeyFrameImg.Parent = KeyContainer

local KeyInput = Instance.new("TextBox")
KeyInput.AnchorPoint = Vector2.new(0.5, 0.5)
KeyInput.Size = UDim2.new(0.56, 0, 0.19, 0)
KeyInput.Position = UDim2.new(0.48, 0, 0.53, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Text = ""
KeyInput.PlaceholderText = "..."
KeyInput.TextColor3 = Color3.fromRGB(110, 75, 50)
KeyInput.PlaceholderColor3 = Color3.fromRGB(150, 120, 100)
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 20
KeyInput.TextXAlignment = Enum.TextXAlignment.Center
KeyInput.ClearTextOnFocus = false
KeyInput.ZIndex = 6
KeyInput.Parent = KeyFrameImg

local BTN_IMG_SIZE = 180
local BTN_HIT_W, BTN_HIT_H = 128, 40
local BTN_CENTER_Y = 246
local SHOW_ENTER_TEXT = false

local EnterImg = Instance.new("ImageLabel")
EnterImg.Name = "EnterImg"
EnterImg.AnchorPoint = Vector2.new(0.5, 0.5)
EnterImg.Size = UDim2.new(0, BTN_IMG_SIZE, 0, BTN_IMG_SIZE)
EnterImg.Position = UDim2.new(0.5, 0, 0, BTN_CENTER_Y)
EnterImg.Image = "rbxassetid://131331951399441"
EnterImg.BackgroundTransparency = 1
EnterImg.ScaleType = Enum.ScaleType.Fit
EnterImg.Active = false
EnterImg.ZIndex = 6
EnterImg.Parent = KeyContainer

local EnterBtn = Instance.new("TextButton")
EnterBtn.Name = "EnterBtn"
EnterBtn.AnchorPoint = Vector2.new(0.5, 0.5)
EnterBtn.Size = UDim2.new(0, BTN_HIT_W, 0, BTN_HIT_H)
EnterBtn.Position = UDim2.new(0.5, 0, 0, BTN_CENTER_Y)
EnterBtn.BackgroundTransparency = 1
EnterBtn.AutoButtonColor = false
EnterBtn.Text = ""
EnterBtn.ZIndex = 7
EnterBtn.Parent = KeyContainer

local EnterText = Instance.new("TextLabel")
EnterText.Name = "EnterText"
EnterText.Size = UDim2.new(1, 0, 1, 0)
EnterText.BackgroundTransparency = 1
EnterText.Text = "Enter"
EnterText.TextColor3 = Color3.fromRGB(110, 75, 50)
EnterText.Font = Enum.Font.GothamBold
EnterText.TextSize = 20
EnterText.Visible = SHOW_ENTER_TEXT
EnterText.ZIndex = 8
EnterText.Parent = EnterBtn

local ProfileContainer = Instance.new("Frame")
ProfileContainer.Name = "ProfileContainer"
ProfileContainer.Size = UDim2.new(1, 0, 1, 0)
ProfileContainer.BackgroundTransparency = 1
ProfileContainer.Visible = false
ProfileContainer.ZIndex = 4
ProfileContainer.Parent = MainFrame

local CONTENT_TOP = 46
local AVATAR_FINAL_X, AVATAR_FINAL_Y = 20 + 70 / 2, 16 + 70 / 2

local PAGE_COUNT = 5
local PAGE_BASE = UDim2.new(0, -10, 0, 2)

local PageViewport = Instance.new("Frame")
PageViewport.Name = "PageViewport"
PageViewport.Position = UDim2.new(0, 10, 0, CONTENT_TOP - 2)
PageViewport.Size = UDim2.new(0, 460, 0, 240)
PageViewport.BackgroundTransparency = 1
PageViewport.ClipsDescendants = true
PageViewport.ZIndex = 5
PageViewport.Parent = ProfileContainer

local Pages = {}

local function makePage(i)
	local page = Instance.new("CanvasGroup")
	page.Name = "Page" .. i
	page.Position = PAGE_BASE
	page.Size = UDim2.new(0, 480, 0, 300 - CONTENT_TOP)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ZIndex = 5
	page.Parent = PageViewport
	Pages[i] = page
	return page
end

local ProfileContent = makePage(1)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Name = "AvatarImage"
AvatarImage.AnchorPoint = Vector2.new(0.5, 0.5)
AvatarImage.Size = UDim2.new(0, 75, 0, 75)
AvatarImage.Position = UDim2.new(0.5, 0, 0, 93.5 - CONTENT_TOP)
AvatarImage.BackgroundTransparency = 1
AvatarImage.ScaleType = Enum.ScaleType.Fit
AvatarImage.ZIndex = 6
AvatarImage.Parent = ProfileContent

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImage

local function makeProfileLabel(name, x, y, w, h, size, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = UDim2.new(0, x, 0, y)
	l.Size = UDim2.new(0, w, 0, h)
	l.BackgroundTransparency = 1
	l.Text = ""
	l.TextColor3 = color
	l.TextSize = size
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.ZIndex = 6
	l.Parent = ProfileContent
	return l
end

local NameLabel   = makeProfileLabel("NameLabel",   100, 16, 360, 26, 22, Color3.fromRGB(80, 50, 20))
local OnlineLabel = makeProfileLabel("OnlineLabel", 100, 46, 200, 16, 15, Color3.fromRGB(84, 165, 98))
local HeaderLabel = makeProfileLabel("HeaderLabel",  20, 100, 300, 24, 18, Color3.fromRGB(110, 75, 50))

HeaderLabel.AnchorPoint = Vector2.new(0.5, 0)
HeaderLabel.Position = UDim2.new(0.5, 0, 0, 100)
HeaderLabel.Size = UDim2.new(0, 340, 0, 24)
HeaderLabel.TextXAlignment = Enum.TextXAlignment.Center

local RankRow = Instance.new("Frame")
RankRow.Name = "RankRow"
RankRow.Position = UDim2.new(0, 100, 0, 64)
RankRow.Size = UDim2.new(0, 365, 0, 36)
RankRow.BackgroundTransparency = 1
RankRow.ZIndex = 6
RankRow.Parent = ProfileContent

local RankLayout = Instance.new("UIListLayout")
RankLayout.FillDirection = Enum.FillDirection.Horizontal
RankLayout.Wraps = true
RankLayout.Padding = UDim.new(0, 8)
RankLayout.SortOrder = Enum.SortOrder.LayoutOrder
RankLayout.Parent = RankRow

local RankLabels = {}
for i, style in ipairs(userRanks) do
	local l = Instance.new("TextLabel")
	l.Name = "Rank" .. i
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.new(0, 0, 0, 18)
	l.BackgroundTransparency = 1
	l.Text = ""
	l.TextColor3 = (style.colors and style.colors[1]) or Color3.fromRGB(255, 255, 255)
	l.TextSize = 15
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = i
	l.ZIndex = 6
	l.Parent = RankRow

	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(100, 68, 45)
	s.Thickness = 1.2
	s.Parent = l

	RankLabels[i] = {label = l, style = style}
end

-- ONLINE DOT MOVIDO UN POQUITO MÁS A LA DERECHA (De 155 a 175)
local OnlineDot = Instance.new("Frame")
OnlineDot.Name = "OnlineDot"
OnlineDot.AnchorPoint = Vector2.new(0.5, 0.5)
OnlineDot.Position = UDim2.new(0, 175, 0, 54)
OnlineDot.Size = UDim2.new(0, 0, 0, 0)
OnlineDot.BackgroundColor3 = Color3.fromRGB(110, 205, 125)
OnlineDot.BorderSizePixel = 0
OnlineDot.ZIndex = 6
OnlineDot.Parent = ProfileContent

local OnlineDotCorner = Instance.new("UICorner")
OnlineDotCorner.CornerRadius = UDim.new(1, 0)
OnlineDotCorner.Parent = OnlineDot

local SearchIcon = Instance.new("TextButton")
SearchIcon.Name = "SearchIcon"
SearchIcon.AnchorPoint = Vector2.new(0.5, 0)
SearchIcon.Position = UDim2.new(0.5, 155, 0, 99)
SearchIcon.Size = UDim2.new(0, 26, 0, 26)
SearchIcon.BackgroundTransparency = 1
SearchIcon.AutoButtonColor = false
SearchIcon.Text = "\u{1F50D}"
SearchIcon.TextSize = 18
SearchIcon.TextTransparency = 1
SearchIcon.Visible = false
SearchIcon.ZIndex = 7
SearchIcon.Parent = ProfileContent

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.AnchorPoint = Vector2.new(0.5, 0)
SearchBox.Position = UDim2.new(0.5, 0, 0, 98)
SearchBox.Size = UDim2.new(0, 340, 0, 28)
SearchBox.BackgroundColor3 = Color3.fromRGB(255, 251, 232)
SearchBox.BorderSizePixel = 0
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search scripts..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 120, 100)
SearchBox.TextColor3 = Color3.fromRGB(110, 75, 50)
SearchBox.TextSize = 16
SearchBox.Font = Enum.Font.GothamBold
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Visible = false
SearchBox.ZIndex = 7
SearchBox.Parent = ProfileContent

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(110, 75, 50)
SearchStroke.Thickness = 1.2
SearchStroke.Transparency = 0.3
SearchStroke.Parent = SearchBox

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 10)
SearchPadding.Parent = SearchBox

local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Name = "ListFrame"
ListFrame.AnchorPoint = Vector2.new(0.5, 0)
ListFrame.Position = UDim2.new(0.5, 0, 0, 128)
ListFrame.Size = UDim2.new(0, 340, 0, 58)
ListFrame.BackgroundTransparency = 1
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 3
ListFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 110, 70)
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ListFrame.Visible = false
ListFrame.ZIndex = 6
ListFrame.Parent = ProfileContent

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ListFrame

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Name = "EmptyLabel"
EmptyLabel.AnchorPoint = Vector2.new(0.5, 0)
EmptyLabel.Position = UDim2.new(0.5, 0, 0, 134)
EmptyLabel.Size = UDim2.new(0, 340, 0, 20)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "No scripts yet"
EmptyLabel.TextColor3 = Color3.fromRGB(150, 120, 100)
EmptyLabel.TextSize = 15
EmptyLabel.Font = Enum.Font.GothamBold
EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
EmptyLabel.Visible = false
EmptyLabel.ZIndex = 6
EmptyLabel.Parent = ProfileContent

local ACCENT = Color3.fromRGB(245, 190, 60)
local BROWN = Color3.fromRGB(110, 75, 50)
local CREAM = Color3.fromRGB(255, 251, 232)
local PAGE_CONTENT_H = 188
local UIX = {}

do
	local function corner(obj, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = radius
		c.Parent = obj
		return c
	end

	local function stroke(obj, color, thickness, transparency)
		local s = Instance.new("UIStroke")
		s.Color = color
		s.Thickness = thickness
		s.Transparency = transparency
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end

	local function makeScrollPage(i, titleText)
		local page = makePage(i)
		page.Visible = false

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Scroll"
		scroll.Size = UDim2.new(1, 0, 0, PAGE_CONTENT_H)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 110, 70)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ZIndex = 6
		scroll.Parent = page

		local title = Instance.new("TextLabel")
		title.Name = "PageTitle"
		title.Position = UDim2.new(0, 20, 0, 6)
		title.Size = UDim2.new(1, -40, 0, 26)
		title.BackgroundTransparency = 1
		title.Text = titleText
		title.TextColor3 = BROWN
		title.TextSize = 20
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 7
		title.Parent = scroll

		return scroll
	end

	local scripts = makeScrollPage(2, "Scripts")
	UIX.ScriptsScroll = scripts

	local search = Instance.new("TextBox")
	search.Name = "ScriptsSearch"
	search.Position = UDim2.new(0, 20, 0, 36)
	search.Size = UDim2.new(1, -40, 0, 28)
	search.BackgroundColor3 = CREAM
	search.BorderSizePixel = 0
	search.PlaceholderText = "Search scripts..."
	search.PlaceholderColor3 = Color3.fromRGB(150, 120, 100)
	search.Text = ""
	search.TextColor3 = BROWN
	search.TextSize = 14
	search.Font = Enum.Font.GothamBold
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.ClearTextOnFocus = false
	search.ZIndex = 7
	search.Parent = scripts
	corner(search, UDim.new(0, 10))
	stroke(search, BROWN, 1, 0.45)
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 32)
	searchPad.Parent = search
	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Size = UDim2.fromOffset(14, 14)
	searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Image = "rbxassetid://6031091004"
	searchIcon.ImageColor3 = Color3.fromRGB(150, 110, 80)
	searchIcon.ZIndex = 8
	searchIcon.Parent = search
	UIX.ScriptsSearch = search

	local pillRow = Instance.new("Frame")
	pillRow.Name = "PillRow"
	pillRow.Position = UDim2.new(0, 20, 0, 70)
	pillRow.Size = UDim2.new(1, -40, 0, 28)
	pillRow.BackgroundTransparency = 1
	pillRow.ZIndex = 7
	pillRow.Parent = scripts
	local pillLayout = Instance.new("UIListLayout")
	pillLayout.FillDirection = Enum.FillDirection.Horizontal
	pillLayout.Padding = UDim.new(0, 6)
	pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pillLayout.Parent = pillRow

	local function makePill(text, order)
		local b = Instance.new("TextButton")
		b.Name = "Pill" .. text
		b.Size = UDim2.fromOffset(120, 28)
		b.BackgroundColor3 = CREAM
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = BROWN
		b.TextSize = 14
		b.Font = Enum.Font.GothamBold
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.ZIndex = 8
		b.Parent = pillRow
		corner(b, UDim.new(1, 0))
		stroke(b, BROWN, 1, 0.55)
		return b
	end
	UIX.PillMain = makePill("Script", 1)
	UIX.PillExtra = makePill("Extra", 2)

	local content = Instance.new("Frame")
	content.Name = "ScriptsContent"
	content.Position = UDim2.new(0, 20, 0, 106)
	content.Size = UDim2.new(1, -40, 0, 0)
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.ZIndex = 7
	content.Parent = scripts

	local function makeTab(name)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.new(1, 0, 0, 0)
		f.AutomaticSize = Enum.AutomaticSize.Y
		f.BackgroundTransparency = 1
		f.Visible = false
		f.ZIndex = 7
		f.Parent = content
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 6)
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = f
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 2)
		pad.PaddingBottom = UDim.new(0, 2)
		pad.Parent = f
		return f
	end
	UIX.TabMain = makeTab("MainScript")
	UIX.TabExtra = makeTab("Extra")

	UIX.FlingScroll = makeScrollPage(3, "Fling Players")
	UIX.SkysScroll = makeScrollPage(4, "Skys")

	local settings = makeScrollPage(5, "Settings")
	UIX.SettingsPage = settings

	local function settingsLabel(text, y)
		local l = Instance.new("TextLabel")
		l.Position = UDim2.new(0, 20, 0, y)
		l.Size = UDim2.new(1, -40, 0, 18)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = BROWN
		l.TextSize = 14
		l.Font = Enum.Font.GothamBold
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 7
		l.Parent = settings
		return l
	end

	settingsLabel("Minimize key", 40)

	local keyBtn = Instance.new("TextButton")
	keyBtn.Name = "KeybindBtn"
	keyBtn.AnchorPoint = Vector2.new(0.5, 0)
	keyBtn.Position = UDim2.new(0.5, 0, 0, 62)
	keyBtn.Size = UDim2.new(1, -40, 0, 36)
	keyBtn.BackgroundColor3 = CREAM
	keyBtn.BorderSizePixel = 0
	keyBtn.Text = "M"
	keyBtn.TextColor3 = BROWN
	keyBtn.TextSize = 16
	keyBtn.Font = Enum.Font.GothamBold
	keyBtn.AutoButtonColor = false
	keyBtn.TextXAlignment = Enum.TextXAlignment.Center
	keyBtn.ZIndex = 7
	keyBtn.Parent = settings
	corner(keyBtn, UDim.new(0, 10))
	stroke(keyBtn, BROWN, 1, 0.45)
	UIX.KeybindBtn = keyBtn

	settingsLabel("Themes", 108)

	local box = Instance.new("Frame")
	box.Name = "ThemesBox"
	box.Position = UDim2.new(0, 20, 0, 130)
	box.Size = UDim2.new(0, 290, 0, 40)
	box.BackgroundColor3 = Color3.fromRGB(28, 22, 20)
	box.BackgroundTransparency = 0.15
	box.BorderSizePixel = 0
	box.ZIndex = 7
	box.Parent = settings
	corner(box, UDim.new(0, 12))
	stroke(box, Color3.fromRGB(90, 68, 52), 2, 0.25)

	local msg = Instance.new("TextLabel")
	msg.Name = "ComingSoon"
	msg.Size = UDim2.new(1, 0, 1, 0)
	msg.BackgroundTransparency = 1
	msg.Text = "Coming soon"
	msg.TextColor3 = Color3.fromRGB(235, 225, 205)
	msg.TextSize = 16
	msg.Font = Enum.Font.GothamBold
	msg.ZIndex = 8
	msg.Parent = box
end

local DOCK_IMG_SIZE = 250
local DOCK_BAR_W, DOCK_BAR_H = 200, 30
local DOCK_CENTER_Y = 269
local DOCK_IMG_OFFSET_Y = -30
local DOCK_SHOW_OFFSET = 24
local DOCK_SEG_W = DOCK_BAR_W / PAGE_COUNT

local dockWanted = false

local DockContainer = Instance.new("Frame")
DockContainer.Name = "DockContainer"
DockContainer.AnchorPoint = Vector2.new(0.5, 0.5)
DockContainer.Position = UDim2.new(0.5, 0, 0, DOCK_CENTER_Y)
DockContainer.Size = UDim2.new(0, DOCK_BAR_W, 0, DOCK_BAR_H)
DockContainer.BackgroundTransparency = 1
DockContainer.Active = false
DockContainer.Visible = false
DockContainer.ZIndex = 8
DockContainer.Parent = MainFrame

local DockImage = Instance.new("ImageLabel")
DockImage.Name = "DockImage"
DockImage.AnchorPoint = Vector2.new(0.5, 0.5)
DockImage.Position = UDim2.new(0.5, 0, 0.5, DOCK_IMG_OFFSET_Y)
DockImage.Size = UDim2.new(0, DOCK_IMG_SIZE, 0, DOCK_IMG_SIZE)
DockImage.BackgroundTransparency = 1
DockImage.Image = "rbxassetid://114902707491693"
DockImage.ScaleType = Enum.ScaleType.Fit
DockImage.Active = false
DockImage.ZIndex = 8
DockImage.Parent = DockContainer

local DockDot = Instance.new("Frame")
DockDot.Name = "DockDot"
DockDot.AnchorPoint = Vector2.new(0.5, 0.5)
DockDot.Position = UDim2.new(0, DOCK_SEG_W * 0.5, 1, -4)
DockDot.Size = UDim2.new(0, 5, 0, 5)
DockDot.BackgroundColor3 = Color3.fromRGB(110, 75, 50)
DockDot.BorderSizePixel = 0
DockDot.ZIndex = 9
DockDot.Parent = DockContainer

local DockDotCorner = Instance.new("UICorner")
DockDotCorner.CornerRadius = UDim.new(1, 0)
DockDotCorner.Parent = DockDot

local currentPage = 1
local pageToken = 0
local PAGE_SLIDE = 48

local function moveDockDot(index)
	TweenService:Create(DockDot, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, DOCK_SEG_W * (index - 0.5), 1, -4)
	}):Play()
end

local function SwitchPage(newIndex)
	if newIndex == currentPage then return end
	pageToken = pageToken + 1
	local token = pageToken

	local oldPage, newPage = Pages[currentPage], Pages[newIndex]
	local dir = (newIndex > currentPage) and 1 or -1
	currentPage = newIndex
	moveDockDot(newIndex)

	for _, p in ipairs(Pages) do
		if p ~= oldPage and p ~= newPage then p.Visible = false end
	end

	TweenService:Create(oldPage, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(0, PAGE_BASE.X.Offset - dir * PAGE_SLIDE, 0, PAGE_BASE.Y.Offset),
		GroupTransparency = 1
	}):Play()

	newPage.Position = UDim2.new(0, PAGE_BASE.X.Offset + dir * PAGE_SLIDE, 0, PAGE_BASE.Y.Offset)
	newPage.GroupTransparency = 1
	newPage.Visible = true

	task.delay(0.08, function()
		if token ~= pageToken then return end
		TweenService:Create(newPage, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = PAGE_BASE,
			GroupTransparency = 0
		}):Play()
	end)
	task.delay(0.32, function()
		if token == pageToken then oldPage.Visible = false end
	end)
end

local function bounceDock()
	local big = DOCK_IMG_SIZE * 1.05
	TweenService:Create(DockImage, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, big, 0, big)
	}):Play()
	task.delay(0.1, function()
		TweenService:Create(DockImage, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, DOCK_IMG_SIZE, 0, DOCK_IMG_SIZE)
		}):Play()
	end)
end

for i = 1, PAGE_COUNT do
	local btn = Instance.new("TextButton")
	btn.Name = "DockButton" .. i
	btn.Position = UDim2.new(0, DOCK_SEG_W * (i - 1), 0, 0)
	btn.Size = UDim2.new(0, DOCK_SEG_W, 1, 0)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.ZIndex = 10
	btn.Parent = DockContainer
	btn.MouseButton1Click:Connect(function()
		bounceDock()
		SwitchPage(i)
	end)
end

local function showDock()
	DockContainer.Visible = true
	DockContainer.Position = UDim2.new(0.5, 0, 0, DOCK_CENTER_Y + DOCK_SHOW_OFFSET)
	DockImage.ImageTransparency = 1
	DockDot.BackgroundTransparency = 1
	local info = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(DockContainer, info, {Position = UDim2.new(0.5, 0, 0, DOCK_CENTER_Y)}):Play()
	TweenService:Create(DockImage, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	TweenService:Create(DockDot, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
end

local function hideDock()
	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(DockContainer, info, {Position = UDim2.new(0.5, 0, 0, DOCK_CENTER_Y + DOCK_SHOW_OFFSET)}):Play()
	TweenService:Create(DockImage, info, {ImageTransparency = 1}):Play()
	TweenService:Create(DockDot, info, {BackgroundTransparency = 1}):Play()
end

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
	end)
	if ok and img then
		AvatarImage.Image = img
		KeyAvatar.Image = img
	end
end)

local StarbornFont = nil
local fontLoadDone = false

local function ApplyFontToAll(parent)
	if not StarbornFont then return end
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			if obj.Name ~= "SearchIcon" then
				pcall(function() obj.FontFace = StarbornFont end)
			end
		end
	end
end

local function LoadStarbornFont()
	if not (isfile and writefile and getcustomasset) then return end
	local ttfFile = "Starborn.ttf"
	local jsonFile = "Starborn.json"
	local ok = pcall(function()
		if not isfile(ttfFile) then
			local data = game:HttpGet("https://github.com/samxzqpq/Roblox-Fonts-/raw/refs/heads/main/Starborn.ttf")
			if not data or #data < 100 then error("empty") end
			writefile(ttfFile, data)
		end
	end)
	if not ok then return end
	pcall(function()
		local asset = getcustomasset(ttfFile)
		local jsonData = HttpService:JSONEncode({name="Starborn",faces={{name="Regular",weight=400,style="normal",assetId=asset}}})
		writefile(jsonFile, jsonData)
		local family = getcustomasset(jsonFile)
		StarbornFont = Font.new(family, Enum.FontWeight.Regular, Enum.FontStyle.Normal)

		ApplyFontToAll(ScreenGui)
		
		ScreenGui.DescendantAdded:Connect(function(obj)
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				if obj.Name ~= "SearchIcon" then
					pcall(function() obj.FontFace = StarbornFont end)
				end
			end
		end)
	end)
end
task.spawn(function()
	pcall(LoadStarbornFont)
	fontLoadDone = true
end)

task.spawn(function()
	local t = 0
	while RankRow and RankRow.Parent do
		t = t + task.wait()
		for _, r in ipairs(RankLabels) do
			local style = r.style
			if style.rainbow then
				r.label.TextColor3 = Color3.fromHSV((t * 0.25) % 1, 0.8, 1)
			else
				local colors = style.colors
				local n = #colors
				local pos = (t * 0.6) % n
				local index = math.floor(pos) + 1
				local nextIndex = index % n + 1
				r.label.TextColor3 = colors[index]:Lerp(colors[nextIndex], pos % 1)
			end
		end
	end
end)

do
	local function corner(obj, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = radius
		c.Parent = obj
		return c
	end

	local function stroke(obj, color, thickness, transparency)
		local s = Instance.new("UIStroke")
		s.Color = color
		s.Thickness = thickness
		s.Transparency = transparency
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end

	local function applyFont(obj)
		pcall(function()
			if StarbornFont and obj.Name ~= "SearchIcon" then obj.FontFace = StarbornFont else obj.Font = Enum.Font.GothamBold end
		end)
	end

	local USAGE_FILE = "wb_usage.json"

	local function loadUsage()
		local ok, data = pcall(function()
			if readfile and isfile and isfile(USAGE_FILE) then return readfile(USAGE_FILE) end
		end)
		if ok and data then
			local ok2, tbl = pcall(function() return HttpService:JSONDecode(data) end)
			if ok2 and type(tbl) == "table" then return tbl end
		end
		return {}
	end

	local function saveUsage(tbl)
		pcall(function()
			if writefile then writefile(USAGE_FILE, HttpService:JSONEncode(tbl)) end
		end)
	end

	local ToggleUsage = loadUsage()
	local AllToggles, ToggleRegistry = {}, {}
	Library.ToggleRegistry = ToggleRegistry

	local ExclusiveGroups = {}

	Library.RegisterExclusive = function(groupId, toggleName)
		if not ExclusiveGroups[groupId] then ExclusiveGroups[groupId] = {toggles = {}, activeName = nil} end
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

	local function ShowNotif(title, text, dur)
		dur = dur or 3
		local n = Instance.new("Frame")
		n.Name = "Notif"
		n.AnchorPoint = Vector2.new(0.5, 0)
		n.Size = UDim2.fromOffset(300, 62)
		n.Position = UDim2.new(0.5, 0, 0, -80)
		n.BackgroundColor3 = CREAM
		n.BorderSizePixel = 0
		n.ZIndex = 100
		n.Parent = ScreenGui
		corner(n, UDim.new(0, 12))
		stroke(n, BROWN, 2, 0.1)

		local t = Instance.new("TextLabel")
		t.Position = UDim2.new(0, 12, 0, 6)
		t.Size = UDim2.new(1, -24, 0, 20)
		t.BackgroundTransparency = 1
		t.Text = title
		t.TextColor3 = BROWN
		t.TextSize = 14
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.ZIndex = 101
		t.Parent = n
		applyFont(t)

		local b = Instance.new("TextLabel")
		b.Position = UDim2.new(0, 12, 0, 26)
		b.Size = UDim2.new(1, -24, 0, 30)
		b.BackgroundTransparency = 1
		b.Text = text
		b.TextColor3 = Color3.fromRGB(150, 110, 80)
		b.TextSize = 12
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.TextYAlignment = Enum.TextYAlignment.Top
		b.TextWrapped = true
		b.ZIndex = 101
		b.Parent = n
		applyFont(b)

		TweenService:Create(n, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 24)
		}):Play()
		task.delay(dur, function()
			if not n.Parent then return end
			local tw = TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -80)
			})
			tw:Play()
			tw.Completed:Connect(function() n:Destroy() end)
		end)
	end
	Library.ShowNotif = ShowNotif

	local SWEEP_INFO = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local function AddButtonSweep(btn, strokeObj)
		if not btn or btn:FindFirstChild("SweepHolder") then return end
		if strokeObj then
			strokeObj.Color = BROWN
			strokeObj.Thickness = 1
			strokeObj.Transparency = 0.55
			strokeObj.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
		local sh = Instance.new("Frame")
		sh.Name = "SweepHolder"
		sh.Size = UDim2.new(1, 0, 1, 0)
		sh.BackgroundTransparency = 1
		sh.ClipsDescendants = true
		sh.ZIndex = 5
		sh.Parent = btn
		corner(sh, UDim.new(0, 10))

		local sw = Instance.new("Frame")
		sw.Size = UDim2.new(0, 40, 1, 0)
		sw.Position = UDim2.new(0, -40, 0, 0)
		sw.BackgroundColor3 = Color3.fromRGB(255, 226, 140)
		sw.BackgroundTransparency = 0.5
		sw.BorderSizePixel = 0
		sw.ZIndex = 6
		sw.Parent = sh
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = sw

		local sweepTween = TweenService:Create(sw, SWEEP_INFO, {Position = UDim2.new(1, 0, 0, 0)})
		local strokeIn, strokeOut
		if strokeObj then
			strokeIn = TweenService:Create(strokeObj, TweenInfo.new(0.15), {Transparency = 0.2})
			strokeOut = TweenService:Create(strokeObj, TweenInfo.new(0.15), {Transparency = 0.55})
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
	Library.AddButtonSweep = AddButtonSweep

	local KNOB_ON = UDim2.new(1, -18, 0.5, -8)
	local KNOB_OFF = UDim2.fromOffset(2, 2)
	local TOGGLE_INFO = TweenInfo.new(0.15)
	local TRACK_OFF = Color3.fromRGB(214, 196, 170)

	local function CreateToggle(parent, text, callback, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = CREAM
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.LayoutOrder = order or 1
		btn.ZIndex = 7
		btn.Parent = parent
		corner(btn, UDim.new(0, 10))
		local btnStroke = stroke(btn, BROWN, 1, 0.55)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -70, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.TextColor3 = BROWN
		label.TextSize = 14
		label.ZIndex = 8
		label.Parent = btn
		applyFont(label)

		local sw = Instance.new("Frame")
		sw.Size = UDim2.fromOffset(36, 20)
		sw.Position = UDim2.new(1, -46, 0.5, -10)
		sw.BackgroundColor3 = TRACK_OFF
		sw.BorderSizePixel = 0
		sw.ZIndex = 8
		sw.Parent = btn
		corner(sw, UDim.new(1, 0))

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(16, 16)
		knob.Position = KNOB_OFF
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.ZIndex = 9
		knob.Parent = sw
		corner(knob, UDim.new(1, 0))

		local active = false
		local listeners = {}

		local function setVisual(v)
			sw.BackgroundColor3 = v and ACCENT or TRACK_OFF
			TweenService:Create(knob, TOGGLE_INFO, {Position = v and KNOB_ON or KNOB_OFF}):Play()
			for i = 1, #listeners do pcall(listeners[i], v) end
		end

		local function registerUsage()
			ToggleUsage[text] = (ToggleUsage[text] or 0) + 1
			saveUsage(ToggleUsage)
		end

		btn.MouseButton1Click:Connect(function()
			if not active then
				local canActivate, blocker = CanActivate(text)
				if not canActivate then
					ShowNotif("No se puede activar", "Desactiva primero: " .. tostring(blocker), 3)
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
				setVisual(active)
				pcall(callback, active)
			end,
			listeners = listeners,
		}

		table.insert(AllToggles, {btn = btn, label = label, text = text, parent = parent})
		task.defer(function() AddButtonSweep(btn, btnStroke) end)
		return btn
	end
	Library.CreateToggle = CreateToggle

	local mostUsedRows = {}

	local function applyMostUsedFilter()
		local q = SearchBox.Text:lower()
		local shown = 0
		for _, r in ipairs(mostUsedRows) do
			local match = (q == "") or (r.name:lower():find(q, 1, true) ~= nil)
			r.frame.Visible = match
			if match then shown = shown + 1 end
		end
		EmptyLabel.Text = (#mostUsedRows == 0) and "No scripts yet" or "No results"
		EmptyLabel.Visible = ListFrame.Visible and shown == 0
	end

	local function RefreshMostUsed()
		for _, r in ipairs(mostUsedRows) do r.frame:Destroy() end
		mostUsedRows = {}

		local sorted = {}
		for k, v in pairs(ToggleUsage) do
			if ToggleRegistry[k] and v > 0 then table.insert(sorted, {name = k, count = v}) end
		end
		table.sort(sorted, function(a, b)
			if a.count == b.count then return a.name < b.name end
			return a.count > b.count
		end)

		for i = 1, math.min(5, #sorted) do
			local name = sorted[i].name
			local registry = ToggleRegistry[name]

			local entry = Instance.new("Frame")
			entry.Size = UDim2.new(1, -8, 0, 26)
			entry.BackgroundColor3 = CREAM
			entry.BorderSizePixel = 0
			entry.LayoutOrder = i
			entry.ZIndex = 7
			entry.Parent = ListFrame
			corner(entry, UDim.new(0, 8))
			stroke(entry, BROWN, 1, 0.55)

			local num = Instance.new("TextLabel")
			num.Size = UDim2.fromOffset(18, 18)
			num.Position = UDim2.new(0, 4, 0.5, -9)
			num.BackgroundColor3 = ACCENT
			num.Text = tostring(i)
			num.TextColor3 = BROWN
			num.TextSize = 11
			num.ZIndex = 8
			num.Parent = entry
			corner(num, UDim.new(1, 0))
			applyFont(num)

			local nm = Instance.new("TextLabel")
			nm.Size = UDim2.new(1, -84, 1, 0)
			nm.Position = UDim2.new(0, 28, 0, 0)
			nm.BackgroundTransparency = 1
			nm.Text = name
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.TextTruncate = Enum.TextTruncate.AtEnd
			nm.TextColor3 = BROWN
			nm.TextSize = 12
			nm.ZIndex = 8
			nm.Parent = entry
			applyFont(nm)

			local msw = Instance.new("Frame")
			msw.Size = UDim2.fromOffset(32, 18)
			msw.Position = UDim2.new(1, -38, 0.5, -9)
			msw.BackgroundColor3 = TRACK_OFF
			msw.BorderSizePixel = 0
			msw.ZIndex = 8
			msw.Parent = entry
			corner(msw, UDim.new(1, 0))

			local msknob = Instance.new("Frame")
			msknob.Size = UDim2.fromOffset(14, 14)
			msknob.Position = UDim2.fromOffset(2, 2)
			msknob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			msknob.BorderSizePixel = 0
			msknob.ZIndex = 9
			msknob.Parent = msw
			corner(msknob, UDim.new(1, 0))

			local click = Instance.new("TextButton")
			click.Size = UDim2.new(1, 0, 1, 0)
			click.BackgroundTransparency = 1
			click.Text = ""
			click.ZIndex = 10
			click.Parent = entry

			local function updateMSVisual(v)
				msw.BackgroundColor3 = v and ACCENT or TRACK_OFF
				TweenService:Create(msknob, TweenInfo.new(0.15), {
					Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(2, 2)
				}):Play()
			end

			if registry then
				updateMSVisual(registry.getActive())
				click.MouseButton1Click:Connect(function() registry.setActive(not registry.getActive()) end)
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

			mostUsedRows[#mostUsedRows + 1] = {frame = entry, name = name}
		end

		applyMostUsedFilter()
	end
	Library.RefreshMostUsed = RefreshMostUsed

	local searchOpen = false
	SearchIcon.MouseButton1Click:Connect(function()
		searchOpen = not searchOpen
		HeaderLabel.Visible = not searchOpen
		SearchBox.Visible = searchOpen
		if searchOpen then
			SearchBox:CaptureFocus()
		else
			SearchBox:ReleaseFocus()
			SearchBox.Text = ""
		end
	end)
	SearchBox:GetPropertyChangedSignal("Text"):Connect(applyMostUsedFilter)

	local activeTab, activePill = nil, nil
	local PILL_ON_BG = Color3.fromRGB(255, 226, 140)

	local function SelectTab(tab, pill)
		if activeTab == tab then return end
		if activeTab then
			local oldTab, oldPill = activeTab, activePill
			TweenService:Create(oldTab, TweenInfo.new(0.18), {Position = UDim2.new(-0.15, 0, 0, 0)}):Play()
			if oldPill then
				TweenService:Create(oldPill, TweenInfo.new(0.18), {BackgroundColor3 = CREAM}):Play()
				local ps = oldPill:FindFirstChildOfClass("UIStroke")
				if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color = BROWN, Transparency = 0.55}):Play() end
			end
			task.delay(0.18, function()
				if oldTab ~= activeTab then oldTab.Visible = false end
				oldTab.Position = UDim2.new(0, 0, 0, 0)
			end)
		end
		activeTab, activePill = tab, pill
		tab.Visible = true
		tab.Position = UDim2.new(0.15, 0, 0, 0)
		TweenService:Create(tab, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
		TweenService:Create(pill, TweenInfo.new(0.18), {BackgroundColor3 = PILL_ON_BG}):Play()
		local ps = pill:FindFirstChildOfClass("UIStroke")
		if ps then TweenService:Create(ps, TweenInfo.new(0.18), {Color = BROWN, Transparency = 0.1}):Play() end
	end

	UIX.PillMain.MouseButton1Click:Connect(function() SelectTab(UIX.TabMain, UIX.PillMain) end)
	UIX.PillExtra.MouseButton1Click:Connect(function() SelectTab(UIX.TabExtra, UIX.PillExtra) end)
	SelectTab(UIX.TabMain, UIX.PillMain)

	local searchJob
	UIX.ScriptsSearch:GetPropertyChangedSignal("Text"):Connect(function()
		if searchJob then task.cancel(searchJob) end
		searchJob = task.delay(0.12, function()
			searchJob = nil
			local q = UIX.ScriptsSearch.Text:lower()
			for i = 1, #AllToggles do
				local entry = AllToggles[i]
				entry.btn.Visible = (q == "") or (entry.text:lower():find(q, 1, true) ~= nil)
			end
		end)
	end)

	-- FUNCIÓN DE LIMPIEZA INTACTA: Segura para no corromper otros juegos, pero sigue borrando viejas UIs nuestras
	Library.cleanGuis = function(names)
		if not names then return end
		local function scan(parent)
			for _, gui in ipairs(parent:GetChildren()) do
				for _, n in ipairs(names) do
					if gui.Name == n or (string.find(gui.Name:lower(), n:lower(), 1, true)) then
						pcall(function() gui:Destroy() end)
					end
				end
			end
		end
		scan(player:WaitForChild("PlayerGui"))
		if gethui then pcall(function() scan(gethui()) end) end
	end
end

local ReabrirVentana

local dragging = false
local dragStart = nil
local startPos = nil
local draggingTarget = nil

local function setupDrag(frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			draggingTarget = frame
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if frame == Burbuja then
						local delta = input.Position - dragStart
						if delta.Magnitude < 5 then
							task.spawn(ReabrirVentana)
						end
					end
				end
			end)
		end
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if dragging and draggingTarget then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			draggingTarget.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

setupDrag(MainFrame)
setupDrag(Burbuja)

local function typeText(label, fullText, delayPerChar)
	local total = utf8.len(fullText) or #fullText
	for i = 1, total do
		local nextByte = utf8.offset(fullText, i + 1) or (#fullText + 1)
		label.Text = string.sub(fullText, 1, nextByte - 1)
		task.wait(delayPerChar)
	end
	label.Text = fullText
end

local function eraseText(label, delayPerChar)
	local full = label.Text
	local total = utf8.len(full) or #full
	for i = total - 1, 0, -1 do
		local nextByte = utf8.offset(full, i + 1) or (#full + 1)
		label.Text = string.sub(full, 1, nextByte - 1)
		task.wait(delayPerChar)
	end
	label.Text = ""
end

local SHOW_WELCOME = true

local function PlayProfileAnimation(skipPassword)
	if not skipPassword then
		KeyInput:ReleaseFocus()
		KeyInput.PlaceholderText = ""
		local fadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fades = {
			{KeyTitle, {TextTransparency = 1}},
			{KeyFrameImg, {ImageTransparency = 1}},
			{KeyInput, {TextTransparency = 1}},
			{EnterImg, {ImageTransparency = 1}},
			{EnterText, {TextTransparency = 1}},
		}
		for _, item in ipairs(fades) do
			TweenService:Create(item[1], fadeInfo, item[2]):Play()
		end
		task.wait(0.3)
	else
		AvatarImage.Size = UDim2.new(0, 0, 0, 0)
		local waitStart = os.clock()
		while (not fontLoadDone or AvatarImage.Image == "") and os.clock() - waitStart < 5 do
			task.wait(0.05)
		end
		task.wait(0.4)
	end

	ProfileContainer.Visible = true
	KeyContainer.Visible = false
	TweenService:Create(AvatarImage, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 88, 0, 88)
	}):Play()
	task.wait(0.55)

	TweenService:Create(AvatarImage, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		Position = UDim2.new(0, AVATAR_FINAL_X, 0, AVATAR_FINAL_Y),
		Size = UDim2.new(0, 70, 0, 70)
	}):Play()
	task.wait(0.55)

	if SHOW_WELCOME then
		typeText(NameLabel, "Welcome back", 0.055)
		task.wait(0.55)
		eraseText(NameLabel, 0.025)
		task.wait(0.1)
	end
	typeText(NameLabel, "@" .. player.Name, 0.05)
	task.wait(0.1)

	typeText(OnlineLabel, "Online", 0.06)
	TweenService:Create(OnlineDot, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 9, 0, 9)
	}):Play()
	TweenService:Create(OnlineDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.5
	}):Play()
	task.wait(0.1)

	for _, r in ipairs(RankLabels) do
		typeText(r.label, r.style.text, 0.06)
		task.wait(0.12)
	end
	task.wait(0.1)

	typeText(HeaderLabel, "Most Used Scripts", 0.03)
	SearchIcon.Visible = true
	TweenService:Create(SearchIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()
	ListFrame.Visible = true
	Library.RefreshMostUsed()

	task.wait(0.15)
	dockWanted = true
	showDock()

	for _, fn in ipairs(OnLoginCallbacks) do
		task.spawn(function() pcall(fn) end)
	end
end

local unlocked = false

local function showKeyError(msg)
	KeyInput.Text = ""
	KeyInput.PlaceholderText = msg
	KeyInput.PlaceholderColor3 = Color3.fromRGB(200, 80, 80)

	local originalPos = UDim2.new(0.5, 0, 0, BOX_CENTER_Y)
	KeyFrameImg.Position = UDim2.new(0.5, 10, 0, BOX_CENTER_Y)
	task.wait(0.05)
	KeyFrameImg.Position = UDim2.new(0.5, -10, 0, BOX_CENTER_Y)
	task.wait(0.05)
	KeyFrameImg.Position = originalPos

	task.wait(1.5)
	KeyInput.PlaceholderText = "..."
	KeyInput.PlaceholderColor3 = Color3.fromRGB(150, 120, 100)
end

EnterBtn.MouseButton1Click:Connect(function()
	if unlocked then return end
	if WHITELIST_ENABLED and not isWhitelisted(player.Name) then
		showKeyError("Not allowed")
	elseif KeyInput.Text:upper() == "SAM2027" then
		unlocked = true
		saveSession()
		PlayProfileAnimation()
	else
		showKeyError("Incorrect!")
	end
end)

local function OcultarElementos(estado)
	BtnRojo.Visible = estado
	BtnAmarillo.Visible = estado
	BtnVerde.Visible = estado
end

local WIN_W, WIN_H = 480, 300
local BUBBLE_SIZE = 50
local isMinimized = false
local isAnimating = false
local savedPos = nil

local function MinimizarVentana()
	if isAnimating or isMinimized then return end
	isAnimating = true

	pcall(function()
		KeyInput:ReleaseFocus()
		SearchBox:ReleaseFocus()
		UIX.ScriptsSearch:ReleaseFocus()
	end)

	if dockWanted then
		hideDock()
	end

	savedPos = MainFrame.Position

	TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(savedPos.X.Scale, savedPos.X.Offset, savedPos.Y.Scale, savedPos.Y.Offset - 15),
		Rotation = -2
	}):Play()
	TweenService:Create(MainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1.03
	}):Play()
	
	task.wait(0.15) 

	local minTweenPos = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = Burbuja.Position,
		Rotation = 15
	})
	local minTweenScale = TweenService:Create(MainScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = 0
	})

	minTweenPos:Play()
	minTweenScale:Play()
	minTweenScale.Completed:Wait()

	MainFrame.Visible = false

	Burbuja.Size = UDim2.new(0, 0, 0, 0)
	Burbuja.Visible = true
	TweenService:Create(Burbuja, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, BUBBLE_SIZE, 0, BUBBLE_SIZE)
	}):Play()

	isMinimized = true
	isAnimating = false
end

function ReabrirVentana()
	if isAnimating or not isMinimized then return end
	isAnimating = true

	local hideTween = TweenService:Create(Burbuja, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	})
	hideTween:Play()
	hideTween.Completed:Wait()
	Burbuja.Visible = false

	OcultarElementos(true)
	
	local targetPos = savedPos or UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Position = Burbuja.Position
	MainFrame.Rotation = 20
	MainScale.Scale = 0
	MainFrame.Visible = true

	local openTweenPos = TweenService:Create(MainFrame, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos,
		Rotation = 0
	})
	local openTweenScale = TweenService:Create(MainScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	})

	openTweenPos:Play()
	openTweenScale:Play()
	openTweenScale.Completed:Wait()

	if dockWanted then showDock() end

	isMinimized = false
	isAnimating = false
end

BtnRojo.MouseButton1Click:Connect(function()
	OcultarElementos(false)
	local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		ImageTransparency = 1
	})
	closeTween:Play()
	closeTween.Completed:Wait()
	ScreenGui:Destroy()
end)

BtnAmarillo.MouseButton1Click:Connect(MinimizarVentana)
BtnVerde.MouseButton1Click:Connect(function() end)

local SETTINGS_FILE = "Pompompurin_Settings.json"
local MinimizeKey = Enum.KeyCode.M
local listeningKey = false

pcall(function()
	if isfile and readfile and isfile(SETTINGS_FILE) then
		local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
		local kc = type(data) == "table" and data.minimizeKey and Enum.KeyCode[data.minimizeKey]
		if kc then MinimizeKey = kc end
	end
end)
UIX.KeybindBtn.Text = MinimizeKey.Name

UIX.KeybindBtn.MouseButton1Click:Connect(function()
	if listeningKey then return end
	listeningKey = true
	UIX.KeybindBtn.Text = "Press a key..."
	UIX.KeybindBtn.TextColor3 = Color3.fromRGB(214, 140, 70)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if listeningKey then
		if not gp and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			MinimizeKey = input.KeyCode
			UIX.KeybindBtn.Text = MinimizeKey.Name
			UIX.KeybindBtn.TextColor3 = BROWN
			listeningKey = false
			pcall(function()
				if writefile then
					writefile(SETTINGS_FILE, HttpService:JSONEncode({minimizeKey = MinimizeKey.Name}))
				end
			end)
		end
		return
	end
	if gp or UserInputService.TouchEnabled then return end
	if not unlocked or input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= MinimizeKey then return end
	if isMinimized then task.spawn(ReabrirVentana) else task.spawn(MinimizarVentana) end
end)

if hasSession() and (not WHITELIST_ENABLED or isWhitelisted(player.Name)) then
	unlocked = true
	KeyContainer.Visible = false
	task.spawn(PlayProfileAnimation, true)
end

do
	local PAGE_INDEX = {Home = 1, Scripts = 2, Fling = 3, Skys = 4, Settings = 5}

	local detachedAnimations = Instance.new("ScrollingFrame")
	detachedAnimations.Name = "Animations"

	Library.GUI = ScreenGui
	Library.Window = MainFrame
	Library.Content = PageViewport
	Library.ACCENT = ACCENT
	Library.WHITE = Color3.new(1, 1, 1)
	Library.Pages = {
		Home = ProfileContent,
		Scripts = UIX.ScriptsScroll,
		Fling = UIX.FlingScroll,
		Skys = UIX.SkysScroll,
		Settings = UIX.SettingsPage,
		Animations = detachedAnimations,
	}
	Library.Tabs = {MainScript = UIX.TabMain, Extra = UIX.TabExtra}
	
	Library.Services = {
		Players = Players, Player = player, PlayerGui = player:WaitForChild("PlayerGui"),
		TweenService = TweenService, UserInputService = UserInputService,
		RunService = RunService, HttpService = HttpService,
		Lighting = game:GetService("Lighting"), SoundService = game:GetService("SoundService"),
		ReplicatedStorage = game:GetService("ReplicatedStorage"), Debris = game:GetService("Debris"),
		CoreGui = game:GetService("CoreGui"), Workspace = workspace,
	}
	Library.SwitchPage = function(target)
		if not dockWanted then return end
		SwitchPage(PAGE_INDEX[target] or target)
	end
	Library.OnLogin = function(fn) table.insert(OnLoginCallbacks, fn) end
	Library.IsLoggedIn = function() return unlocked end
end

return Library
