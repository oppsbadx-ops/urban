-- LarpHub | Minimal Roblox utility UI
-- Features: CamLock, Walk Speed, Jump Power

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

--!nocheck

local cloneref = cloneref or function(I) return I end
local Players          = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService       = cloneref(game:GetService("RunService"))
local TweenService     = cloneref(game:GetService("TweenService"))
local HttpService      = cloneref(game:GetService("HttpService"))
local TeleportService  = cloneref(game:GetService("TeleportService"))
local CoreGui          = cloneref(game:GetService("CoreGui"))
local Stats            = cloneref(game:GetService("Stats"))
local LocalPlayer      = Players.LocalPlayer

local Library = {
	Flags         = {},
	Options       = {},
	Connections   = {},
	Folder        = "UrbanHub",
	ConfigFolder  = "UrbanHub/Configs",
	MenuKey       = Enum.KeyCode.RightShift,
	TweenTime     = 0.3,
	RainbowSpeed  = 0.002,
	NotifyPosition = "Top Center",
	Open          = true,
	_Keybinds     = {},
	_Rainbows     = {},
	_Popup        = nil,
	_Drag         = nil,
	_Listening    = nil,
}

local Theme = {
	Accent      = Color3.fromHex("e04444"),
	Background  = Color3.fromHex("141419"),
	Base        = Color3.fromHex("1a1a20"),
	Outline     = Color3.fromHex("26262d"),
	Inline      = Color3.fromHex("0c0c10"),
	Text        = Color3.fromHex("c8c8d0"),
	TextDim     = Color3.fromHex("727278"),
	TextTab     = Color3.fromHex("6e6e75"),
	Title       = Color3.fromHex("d7d7d7"),
	Risky       = Color3.fromHex("de5252"),
	Placeholder = Color3.fromHex("82828c"),
}
Library.Theme = Theme


local function Try(Fn, ...)
	if typeof(Fn) ~= "function" then return false end
	return pcall(Fn, ...)
end

-- LarpHub owns its files; nothing is written to LarpHub's folder.
pcall(function()
	if not isfolder(Library.Folder) then
		makefolder(Library.Folder)
	end
	if not isfolder(Library.ConfigFolder) then
		makefolder(Library.ConfigFolder)
	end
end)

local function FixSpaceAdvance(Data)
	local NumTables = string.unpack(">I2", Data, 5)
	for I = 0, NumTables - 1 do
		local Rec = 13 + I * 16
		if Data:sub(Rec, Rec + 3) == "hmtx" then
			local At = string.unpack(">I4", Data, Rec + 8) + 5
			if string.unpack(">I2", Data, At) == 160 then
				return Data:sub(1, At - 1) .. string.pack(">I2", 192) .. Data:sub(At + 2)
			end
		end
	end
	return Data
end

local MainFont = Font.fromEnum(Enum.Font.Arial)
pcall(function()
	local Ttf   = Library.Folder .. "/tahoma.ttf"
	local Fixed = Library.Folder .. "/tahoma_fixed.ttf"
	local Desc  = Library.Folder .. "/tahoma_fixed.font"
	if not isfile(Ttf) then
		writefile(Ttf, game:HttpGet("https://github.com/networph-private874612748471/curly-octo-memory/raw/refs/heads/main/fs-tahoma-8px.ttf"))
	end
	if not isfile(Fixed) then writefile(Fixed, FixSpaceAdvance(readfile(Ttf))) end
	writefile(Desc, HttpService:JSONEncode({
		name  = "LarpHubTahoma",
		faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(Fixed) } },
	}))
	MainFont = Font.new(getcustomasset(Desc), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end)


local function Mul(C, K) return Color3.new(C.R * K, C.G * K, C.B * K) end
local function GlowOf(C)
	local H, S, V = C:ToHSV()
	return Color3.fromHSV(H, math.min(1, S * 1.75), V * 0.98)
end

local Binds = {}
local function Bind(Key, Fn)
	Binds[#Binds + 1] = { Key, Fn }
	Fn(Theme[Key])
end

function Library:SetTheme(Key, Color)
	Theme[Key] = Color
	for _, B in Binds do
		if B[1] == Key then pcall(B[2], Color) elseif B[1] == "*" then pcall(B[2]) end
	end
end

local OrderN = 0
local function NextOrder() OrderN += 1; return OrderN end

local TextClasses = { TextLabel = true, TextButton = true, TextBox = true }
local function New(Class, Props)
	local I = Instance.new(Class)
	if I:IsA("GuiObject") then I.BorderSizePixel = 0 end
	if TextClasses[Class] then
		I.BackgroundTransparency = 1
		I.FontFace   = MainFont
		I.TextSize   = 12
		I.TextColor3 = Theme.Text
		I.Text       = ""
		if Class == "TextButton" then I.AutoButtonColor = false end
		if Class == "TextBox" then I.ClearTextOnFocus = false end
	end
	for K, V in Props do
		if K ~= "Parent" then I[K] = V end
	end
	I.Parent = Props.Parent
	return I
end

local function Tween(I, T, Props, Style)
	local Tw = TweenService:Create(I, TweenInfo.new(T, Style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
	Tw:Play()
	return Tw
end

local function VGrad(Frame, Top, Bottom)
	Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	local G = Frame:FindFirstChild("VGrad") or New("UIGradient", { Name = "VGrad", Rotation = 90, Parent = Frame })
	G.Color = ColorSequence.new(Top, Bottom)
	return G
end
local function ThemeGrad(Frame, Key, KTop, KBot)
	Bind(Key, function(C) VGrad(Frame, Mul(C, KTop), Mul(C, KBot)) end)
end
local function AccentFill(Frame)
	Bind("Accent", function(C) VGrad(Frame, Mul(C, 0.98), Mul(C, 0.44)) end)
end

local EdgeFade = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.27, 0),
	NumberSequenceKeypoint.new(0.74, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local function Box(Parent, Pos, Size, Layers, Class, Static)
	local Outer = New(Class or "Frame", { Position = Pos, Size = Size, BackgroundTransparency = 0, Parent = Parent })
	local function Paint(F, Key)
		if Static then F.BackgroundColor3 = Theme[Key] else Bind(Key, function(C) F.BackgroundColor3 = C end) end
	end
	Paint(Outer, Layers[1])
	local Cur = Outer
	for I = 2, #Layers + 1 do
		local F = New("Frame", { Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), Parent = Cur })
		if Layers[I] then Paint(F, Layers[I]) end
		Cur = F
	end
	return Outer, Cur
end

local function AutoBox(Parent, Width, Layers)
	local Outer = New("Frame", { Size = Width, AutomaticSize = Enum.AutomaticSize.Y, Parent = Parent })
	Bind(Layers[1], function(C) Outer.BackgroundColor3 = C end)
	local Cur = Outer
	for I = 2, #Layers + 1 do
		New("UIPadding", {
			PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 1),
			PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1), Parent = Cur,
		})
		local F = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = Cur })
		if Layers[I] then local K = Layers[I]; Bind(K, function(C) F.BackgroundColor3 = C end) end
		Cur = F
	end
	return Outer, Cur
end

local function Inside(G, P)
	local A, S = G.AbsolutePosition, G.AbsoluteSize
	return P.X >= A.X and P.X <= A.X + S.X and P.Y >= A.Y and P.Y <= A.Y + S.Y
end

local function KeyName(K)
	if not K then return "None" end
	if K == Enum.UserInputType.MouseButton1 then return "MB1" end
	if K == Enum.UserInputType.MouseButton2 then return "MB2" end
	if K == Enum.UserInputType.MouseButton3 then return "MB3" end
	return K.Name
end

local function KeyFromName(N)
	if type(N) ~= "string" or N == "None" then return nil end
	local Ok, K = pcall(function() return Enum.KeyCode[N] end)
	if Ok and K then return K end
	Ok, K = pcall(function() return Enum.UserInputType[N] end)
	if Ok and K then return K end
	return nil
end

function Library:Connect(Signal, Fn)
	local C = Signal:Connect(Fn)
	table.insert(self.Connections, C)
	return C
end

function Library:_Opt(Flag, Obj, Value)
	Obj.Flag = Flag
	Obj.Serialize = Obj.Serialize or function(S) return S:Get() end
	Obj.Deserialize = Obj.Deserialize or function(S, V) S:Set(V) end
	self.Options[Flag] = Obj
	self.Flags[Flag] = Value
end


local Gui = New("ScreenGui", {
	Name = "LarpHub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
do
	Try(protect_gui or (syn and syn.protect_gui), Gui)
	local Ok = pcall(function() Gui.Parent = (gethui and gethui()) or CoreGui end)
	if not Ok or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end
Library.Gui = Gui

local Overlay = New("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = Gui })
Library.Overlay = Overlay

local function MousePos() return UserInputService:GetMouseLocation() + Overlay.AbsolutePosition end

local NotifyHolder = New("Frame", { Name = "Notifications", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, Parent = Gui })
New("UIPadding", {
	PaddingTop = UDim.new(0, 46), PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = NotifyHolder,
})
local NotifyLayout = New("UIListLayout", {
	Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = NotifyHolder,
})


function Library:ClosePopup()
	local P = self._Popup
	if not P then return end
	self._Popup = nil
	if P.OnClose then pcall(P.OnClose) end
	P.Frame:Destroy()
end

function Library:OpenPopup(Frame, Owner, OnClose)
	self:ClosePopup()
	self._Popup = { Frame = Frame, Owner = Owner, OnClose = OnClose }
end

Library:Connect(UserInputService.InputChanged, function(I)
	local T = I.UserInputType
	if Library._Drag and (T == Enum.UserInputType.MouseMovement or T == Enum.UserInputType.Touch) then
		Library._Drag(I)
	end
end)

Library:Connect(UserInputService.InputEnded, function(I)
	local T = I.UserInputType
	if T == Enum.UserInputType.MouseButton1 or T == Enum.UserInputType.Touch then
		Library._Drag = nil
	end
	for _, B in Library._Keybinds do
		if B:Matches(I) then B:Release() end
	end
end)

Library:Connect(UserInputService.InputBegan, function(I)
	local T = I.UserInputType
	local Mouse = MousePos()

	if (T == Enum.UserInputType.MouseButton1 or T == Enum.UserInputType.MouseButton2) and Library._Popup then
		local P = Library._Popup
		if not Inside(P.Frame, Mouse) and not (P.Owner and Inside(P.Owner, Mouse)) then
			Library:ClosePopup()
		end
	end

	local L = Library._Listening
	if L then
		if T == Enum.UserInputType.Keyboard then
			Library._Listening = nil
			if I.KeyCode == Enum.KeyCode.Escape or I.KeyCode == Enum.KeyCode.Backspace then L:SetKey(nil) else L:SetKey(I.KeyCode) end
		elseif T == Enum.UserInputType.MouseButton2 or T == Enum.UserInputType.MouseButton3 then
			Library._Listening = nil
			L:SetKey(T)
		elseif T == Enum.UserInputType.MouseButton1 then
			Library._Listening = nil
			L:Render()
		end
		return
	end

	if UserInputService:GetFocusedTextBox() then return end
	if T == Enum.UserInputType.Keyboard and I.KeyCode == Library.MenuKey then
		Library:Toggle()
	end
	for _, B in Library._Keybinds do
		if B:Matches(I) then B:Press() end
	end
end)

Library:Connect(RunService.RenderStepped, function()
	local Hue = (os.clock() * Library.RainbowSpeed * 60) % 1
	for _, Fn in Library._Rainbows do pcall(Fn, Hue) end
end)

local function OptionPopup(Anchor, Options, IsSel, OnPick, KeepOpen, OnClose, MinWidth)
	local A, Sz = Anchor.AbsolutePosition - Overlay.AbsolutePosition, Anchor.AbsoluteSize
	local RowH, MaxRows = 18, 8
	local N = #Options
	local W = math.max(Sz.X, MinWidth or 0)
	local H = math.max(1, math.min(N, MaxRows)) * RowH + 4
	local X = W > Sz.X and (A.X + Sz.X - W) or A.X
	local P, PF = Box(Overlay, UDim2.fromOffset(X, A.Y + Sz.Y + 1), UDim2.fromOffset(W, H), { "Inline", "Outline" }, "Frame", true)
	PF.BackgroundColor3 = Theme.Background
	local SF = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, CanvasSize = UDim2.fromOffset(0, N * RowH),
		ScrollBarThickness = N > MaxRows and 1 or 0, ScrollBarImageColor3 = Mul(Theme.Accent, 0.56),
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", ScrollingDirection = Enum.ScrollingDirection.Y, Parent = PF,
	})
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = SF })
	local Rows = {}
	local function Paint()
		for O, R in Rows do R.TextColor3 = IsSel(O) and Theme.Accent or Theme.Text end
	end
	for Idx, O in Options do
		local R = New("TextButton", {
			Size = UDim2.new(1, 0, 0, RowH), Text = tostring(O), TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Theme.Base, LayoutOrder = Idx, Parent = SF,
		})
		New("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = R })
		R.MouseEnter:Connect(function() R.BackgroundTransparency = 0 end)
		R.MouseLeave:Connect(function() R.BackgroundTransparency = 1 end)
		R.MouseButton1Click:Connect(function()
			OnPick(O)
			if KeepOpen then Paint() else Library:ClosePopup() end
		end)
		Rows[O] = R
	end
	Paint()
	Library:OpenPopup(P, Anchor, OnClose)
	return P
end


local function MakeKeybind(Parent, Opts, Flag, Name, Handler)
	local B = { Key = Opts.Default, Mode = Opts.Mode or "Toggle", Name = Name, NoList = Opts.NoList, Handler = Handler }

	local Btn, Fill = Box(Parent, UDim2.new(), UDim2.fromOffset(40, 19), { "Outline", "Inline" }, "TextButton")
	Btn.LayoutOrder = NextOrder()
	Bind("Background", function(C) Fill.BackgroundColor3 = C end)
	local L = New("TextLabel", { Size = UDim2.fromScale(1, 1), Text = KeyName(B.Key), Parent = Fill })
	Bind("Text", function(C) L.TextColor3 = C end)
	L:GetPropertyChangedSignal("TextBounds"):Connect(function()
		Btn.Size = UDim2.fromOffset(math.max(L.TextBounds.X + 18, 19), 19)
	end)

	function B:Render() L.Text = (Library._Listening == self) and "..." or KeyName(self.Key) end
	function B:Matches(I)
		local K = self.Key
		if not K then return false end
		if K.EnumType == Enum.KeyCode then return I.KeyCode == K end
		return I.UserInputType == K
	end
	function B:Active()
		if not self.Key and self.Mode ~= "Always" then return false end
		return self.Handler.Get()
	end
	function B:Press()
		if self.Mode == "Toggle" then self.Handler.Set(not self.Handler.Get())
		elseif self.Mode == "Hold" then self.Handler.Set(true) end
	end
	function B:Release()
		if self.Mode == "Hold" then self.Handler.Set(false) end
	end
	function B:SetKey(K)
		self.Key = K
		self:Render()
		if Opts.Changed then task.spawn(Opts.Changed, K) end
		Library:_RefreshKeylist()
	end
	function B:SetMode(M)
		self.Mode = M
		if M == "Always" then self.Handler.Set(true) elseif M == "Hold" then self.Handler.Set(false) end
		Library:_RefreshKeylist()
	end

	Btn.MouseButton1Click:Connect(function()
		Library._Listening = B
		B:Render()
	end)
	Btn.InputBegan:Connect(function(I)
		if I.UserInputType ~= Enum.UserInputType.MouseButton2 or Library._Listening then return end
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		OptionPopup(Btn, { "Always", "Hold", "Toggle" }, function(O) return B.Mode == O end, function(O) B:SetMode(O) end, false, nil, 64)
	end)

	table.insert(Library._Keybinds, B)
	Library:_Opt(Flag, {
		Type = "Keybind", Save = Opts.Save,
		Get = function() return B.Key end,
		Set = function(_, K) B:SetKey(K) end,
		Serialize = function() return { Key = B.Key and B.Key.Name or "None", Mode = B.Mode } end,
		Deserialize = function(_, D)
			if type(D) ~= "table" then return end
			B:SetKey(KeyFromName(D.Key))
			if D.Mode then B:SetMode(D.Mode) end
		end,
	}, B.Key)
	B.Button = Btn
	return B
end


local function MakeColor(Parent, Opts, Flag)
	local Obj = { Type = "Colorpicker" }
	local H, S, V = (Opts.Default or Color3.new(1, 1, 1)):ToHSV()
	local HasAlpha = Opts.Alpha ~= nil
	local Alpha = Opts.Alpha or 1
	local Rainbow = false
	local Callback = Opts.Callback or function() end
	local Popup

	local Wrap = New("Frame", { Size = UDim2.fromOffset(22, 17), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = Parent })
	local Btn, Fill = Box(Wrap, UDim2.new(), UDim2.fromOffset(20, 17), { "Inline", "Outline" }, "TextButton")

	local function Get() return Color3.fromHSV(H, S, V) end
	local function Paint()
		local C = Get()
		VGrad(Fill, Mul(C, 0.9), Mul(C, 0.36))
		if Popup then Popup() end
	end
	local function Changed()
		Paint()
		Library.Flags[Flag] = Get()
		task.spawn(Callback, Get(), Alpha)
	end

	function Obj:Get() return Get(), Alpha end
	function Obj:Set(C, A)
		if typeof(C) == "Color3" then H, S, V = C:ToHSV() end
		if type(A) == "number" then Alpha = A end
		Changed()
	end
	function Obj:SetRainbow(On) Rainbow = On == true; if Popup then Popup() end end
	function Obj:Serialize() return { Hex = Get():ToHex(), Alpha = Alpha, Rainbow = Rainbow } end
	function Obj:Deserialize(D)
		if type(D) ~= "table" then return end
		Rainbow = D.Rainbow == true
		local Ok, C = pcall(Color3.fromHex, D.Hex or "ffffff")
		self:Set(Ok and C or nil, D.Alpha)
	end
	Library:_Opt(Flag, Obj, Get())
	table.insert(Library._Rainbows, function(Hue)
		if Rainbow then H = Hue; if S < 0.05 then S = 0.6 end; if V < 0.05 then V = 1 end; Changed() end
	end)

	local function Open()
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		local Y0 = HasAlpha and 184 or 166
		local PW, PH = 188, Y0 + 19 + 6 + 4
		local A = Btn.AbsolutePosition - Overlay.AbsolutePosition
		local VP = Overlay.AbsoluteSize
		local X = math.clamp(A.X + 24, 0, VP.X - PW)
		local Y = math.clamp(A.Y, 0, VP.Y - PH)
		local P, PF = Box(Overlay, UDim2.fromOffset(X, Y), UDim2.fromOffset(PW, PH), { "Outline", "Inline" }, "Frame", true)
		PF.BackgroundColor3 = Theme.Base
		local Line = New("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Accent, Parent = PF })
		New("UIGradient", { Transparency = EdgeFade, Parent = Line })

		local SVO, SVF = Box(PF, UDim2.fromOffset(6, 8), UDim2.fromOffset(152, 152), { "Inline", "Outline" }, "TextButton", true)
		local Wh = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = SVF })
		New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = Wh })
		local Bk = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = SVF })
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = Bk })
		local SVC = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = SVF })
		New("UIStroke", { Color = Color3.new(0, 0, 0), Parent = SVC })

		local HO, HF = Box(PF, UDim2.fromOffset(164, 8), UDim2.fromOffset(14, 152), { "Inline", "Outline" }, "TextButton", true)
		HF.BackgroundColor3 = Color3.new(1, 1, 1)
		local Keys = {}
		for I = 0, 6 do Keys[#Keys + 1] = ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1)) end
		New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys), Parent = HF })
		local HC = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), Parent = HF })
		New("UIStroke", { Color = Color3.new(0, 0, 0), Parent = HC })

		local AO, AF, AOv, AC
		if HasAlpha then
			AO, AF = Box(PF, UDim2.fromOffset(6, 166), UDim2.fromOffset(172, 12), { "Inline", "Outline" }, "TextButton", true)
			AF.BackgroundColor3 = Theme.Background
			AOv = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = AF })
			New("UIGradient", { Transparency = NumberSequence.new(1, 0), Parent = AOv })
			AC = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = AF })
			New("UIStroke", { Color = Color3.new(0, 0, 0), Parent = AC })
		end

		local _, HexF = Box(PF, UDim2.fromOffset(6, Y0), UDim2.fromOffset(100, 19), { "Inline", "Outline" }, "Frame", true)
		HexF.BackgroundColor3 = Theme.Background
		HexF.ClipsDescendants = true
		local Hex = New("TextBox", { Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = HexF })

		local RB = New("TextButton", { Position = UDim2.fromOffset(112, Y0), Size = UDim2.fromOffset(66, 19), Parent = PF })
		local _, RBF = Box(RB, UDim2.new(0, 0, 0.5, -7), UDim2.fromOffset(14, 14), { "Inline", "Outline" }, "Frame", true)
		local RBL = New("TextLabel", { Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -19, 1, 0), Text = "Rainbow", TextXAlignment = Enum.TextXAlignment.Left, Parent = RB })

		Popup = function()
			local C = Get()
			SVF.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			SVC.Position = UDim2.fromScale(S, 1 - V)
			HC.Position = UDim2.fromScale(0, H)
			if AF then AOv.BackgroundColor3 = C; AC.Position = UDim2.fromScale(Alpha, 0) end
			if not Hex:IsFocused() then Hex.Text = "#" .. C:ToHex() end
			if Rainbow then VGrad(RBF, Mul(Theme.Accent, 0.98), Mul(Theme.Accent, 0.44)) else VGrad(RBF, Mul(Theme.Base, 0.96), Mul(Theme.Base, 0.43)) end
			RBL.TextColor3 = Rainbow and Theme.Text or Theme.TextDim
		end
		Popup()

		local function Drag(Which, Frame)
			local function Upd()
				local M = MousePos()
				local P0, Sz = Frame.AbsolutePosition, Frame.AbsoluteSize
				local Fx = math.clamp((M.X - P0.X) / Sz.X, 0, 1)
				local Fy = math.clamp((M.Y - P0.Y) / Sz.Y, 0, 1)
				if Which == "SV" then S, V = Fx, 1 - Fy
				elseif Which == "H" then H = math.min(Fy, 0.999)
				else Alpha = Fx end
				Changed()
			end
			Upd()
			Library._Drag = Upd
		end
		SVO.MouseButton1Down:Connect(function() Drag("SV", SVF) end)
		HO.MouseButton1Down:Connect(function() Drag("H", HF) end)
		if AO then AO.MouseButton1Down:Connect(function() Drag("A", AF) end) end
		Hex.FocusLost:Connect(function()
			local Ok, C = pcall(Color3.fromHex, (Hex.Text:gsub("#", "")))
			if Ok and C then H, S, V = C:ToHSV(); Changed() else Popup() end
		end)
		RB.MouseButton1Click:Connect(function() Rainbow = not Rainbow; Popup() end)

		Library:OpenPopup(P, Btn, function() Popup = nil end)
	end
	Btn.MouseButton1Click:Connect(Open)

	Paint()
	Obj.Button = Btn
	return Obj
end


local Section = {}
Section.__index = Section

local function MakeSection(Window, Column, Opts)
	local Outer, Fill = AutoBox(Column, UDim2.new(1, -4, 0, 0), { "Outline", "Inline" })
	Outer.LayoutOrder = NextOrder()
	Bind("Base", function(C) Fill.BackgroundColor3 = C end)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Fill })

	local Header = New("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = 0, Parent = Fill })
	local Line = New("Frame", { Size = UDim2.new(1, 0, 0, 2), Parent = Header })
	New("UIGradient", { Transparency = EdgeFade, Parent = Line })
	Bind("Accent", function(C) Line.BackgroundColor3 = C end)
	local Title = New("TextLabel", {
		Position = UDim2.fromOffset(4, 2), Size = UDim2.new(1, -8, 0, 16),
		Text = Opts.Name or "Section", TextXAlignment = Enum.TextXAlignment.Left, Parent = Header,
	})
	Bind("*", function() Title.TextColor3 = Opts.Risky and Theme.Risky or Theme.Text end)

	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = Fill })
	New("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 3), Parent = Body })
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Body })

	return setmetatable({
		Window = Window, Name = Opts.Name or "Section", Side = Opts.Side, Risky = Opts.Risky,
		Frame = Outer, Body = Body, Title = Title,
	}, Section)
end

function Section:_Holder(Height)
	return New("Frame", { Size = UDim2.new(1, 0, 0, Height), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = self.Body })
end

function Section:_Register(Name, Holder, Opts)
	local Entry = { Name = Name or "", Holder = Holder, Section = self }
	if not Opts.NoSearch then table.insert(self.Window.Searchables, Entry) end
	if Opts.Dependency then
		local D = Opts.Dependency
		local function Upd() Holder.Visible = (D:Get() and (not D.Holder or D.Holder.Visible)) and true or false end
		D:OnChange(Upd)
		if D.Holder then D.Holder:GetPropertyChangedSignal("Visible"):Connect(Upd) end
		Upd()
	end
	return Entry
end

local function Addons(Holder)
	local A = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 2, Parent = Holder,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, -3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = A,
	})
	return A
end

local function Label(Holder, Text, X)
	return New("TextLabel", {
		Position = UDim2.fromOffset(X or 1, 0), Size = UDim2.new(1, -(X or 1), 0, 17),
		Text = Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
	})
end

function Section:Toggle(Opts)
	Opts = Opts or {}
	local Name     = Opts.Name or "Toggle"
	local Flag     = Opts.Flag or Name
	local Callback = Opts.Callback or function() end
	local State    = Opts.Default == true
	local Hover    = false
	local Listeners = {}

	local Holder = self:_Holder(22)
	local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = Holder })
	local _, Chk = Box(Holder, UDim2.new(0, 0, 0.5, -7), UDim2.fromOffset(14, 14), { "Inline", "Outline" })
	local Lbl = New("TextLabel", { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	local Add = Addons(Holder)

	local function Render()
		if State then VGrad(Chk, Mul(Theme.Accent, 0.98), Mul(Theme.Accent, 0.44))
		else VGrad(Chk, Mul(Theme.Base, 0.96), Mul(Theme.Base, 0.43)) end
		local On  = Opts.Risky and Theme.Risky or Theme.Text
		local Off = Opts.Risky and Theme.Risky:Lerp(Theme.Base, 0.45) or Theme.TextDim
		if Hover and not State then Off = Off:Lerp(On, 0.35) end
		Tween(Lbl, Library.TweenTime * 0.4, { TextColor3 = State and On or Off })
	end
	Bind("*", Render)

	local Obj = { Type = "Toggle", Holder = Holder }
	function Obj:Get() return State end
	function Obj:Set(V)
		V = V == true
		if V == State then return end
		State = V
		Library.Flags[Flag] = V
		Render()
		task.spawn(Callback, V)
		for _, Fn in Listeners do task.spawn(Fn, V) end
		Library:_RefreshKeylist()
	end
	function Obj:OnChange(Fn) table.insert(Listeners, Fn) end
	function Obj:AddKeybind(O)
		O = O or {}
		self.Keybind = MakeKeybind(Add, O, O.Flag or (Flag .. "_Bind"), Name, {
			Get = function() return State end,
			Set = function(V) Obj:Set(V) end,
		})
		return self
	end
	local Colors = 0
	function Obj:AddColorpicker(O)
		O = O or {}
		Colors += 1
		local C = MakeColor(Add, O, O.Flag or (Flag .. "_Color" .. Colors))
		self.Colorpickers = self.Colorpickers or {}
		table.insert(self.Colorpickers, C)
		return self
	end

	Hit.MouseButton1Click:Connect(function() Obj:Set(not State) end)
	Hit.MouseEnter:Connect(function() Hover = true; Render() end)
	Hit.MouseLeave:Connect(function() Hover = false; Render() end)

	Library:_Opt(Flag, Obj, State)
	self:_Register(Name, Holder, Opts)
	return Obj
end

function Section:Slider(Opts)
	Opts = Opts or {}
	local Name   = Opts.Name or "Slider"
	local Flag   = Opts.Flag or Name
	local Min    = Opts.Min or 0
	local Max    = Opts.Max or 100
	local Dec    = Opts.Decimals or Opts.Rounding or 0
	local Suffix = Opts.Suffix or ""
	local Callback = Opts.Callback or function() end
	local Value  = math.clamp(Opts.Default or Min, Min, Max)

	local Holder = self:_Holder(33)
	local Lbl = Label(Holder, Name)
	Bind("Text", function(C) Lbl.TextColor3 = C end)
	local Bar, Fill = Box(Holder, UDim2.fromOffset(0, 17), UDim2.new(1, 0, 0, 14), { "Inline", "Outline" }, "TextButton")
	Bind("Background", function(C) Fill.BackgroundColor3 = Mul(C, 0.8) end)
	local Prog = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = Fill })
	AccentFill(Prog)
	local ValLbl = New("TextLabel", { Size = UDim2.fromScale(1, 1), TextStrokeTransparency = 0.5, ZIndex = 2, Parent = Fill })
	Bind("Text", function(C) ValLbl.TextColor3 = C end)

	local function Round(V) local M = 10 ^ Dec; return math.floor(V * M + 0.5) / M end
	local function Fmt(V) return (Dec > 0 and string.format("%." .. Dec .. "f", V) or tostring(math.floor(V + 0.5))) .. Suffix end
	local function Render(Instant)
		local P = Max == Min and 0 or (Value - Min) / (Max - Min)
		if Instant then Prog.Size = UDim2.fromScale(P, 1) else Tween(Prog, 0.08, { Size = UDim2.fromScale(P, 1) }) end
		ValLbl.Text = Fmt(Value)
	end

	local Obj = { Type = "Slider", Holder = Holder }
	function Obj:Get() return Value end
	function Obj:Set(V)
		V = math.clamp(Round(tonumber(V) or Min), Min, Max)
		if V == Value then return end
		Value = V
		Library.Flags[Flag] = V
		Render()
		task.spawn(Callback, V)
	end

	Bar.MouseButton1Down:Connect(function()
		local function Upd()
			local M = MousePos()
			local P = math.clamp((M.X - Fill.AbsolutePosition.X) / Fill.AbsoluteSize.X, 0, 1)
			Obj:Set(Min + (Max - Min) * P)
		end
		Upd()
		Library._Drag = Upd
	end)

	Render(true)
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name, Holder, Opts)
	return Obj
end

function Section:Dropdown(Opts)
	Opts = Opts or {}
	local Name    = Opts.Name or "Dropdown"
	local Flag    = Opts.Flag or Name
	local Multi   = Opts.Multi == true
	local Options = Opts.Options or Opts.Values or {}
	local Callback = Opts.Callback or function() end
	local Value = Opts.Default
	if Multi then Value = table.clone(type(Value) == "table" and Value or {})
	elseif Value == nil then Value = Options[1] end

	local HasLabel = Opts.NoLabel ~= true
	local Holder = self:_Holder(HasLabel and 40 or 23)
	if HasLabel then
		local Lbl = Label(Holder, Name)
		Bind("Text", function(C) Lbl.TextColor3 = C end)
	end
	local Btn, Fill = Box(Holder, UDim2.fromOffset(0, HasLabel and 17 or 0), UDim2.new(1, 0, 0, 21), { "Inline", "Outline" }, "TextButton")
	ThemeGrad(Fill, "Background", 1, 0.4)
	local ValLbl = New("TextLabel", {
		Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -22, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Fill,
	})
	local Plus = New("TextLabel", { Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 10, 1, 0), Text = "+", Parent = Fill })
	Bind("Text", function(C) ValLbl.TextColor3 = C; Plus.TextColor3 = C end)

	local function Display()
		if Multi then
			local T = {}
			for _, O in Options do if table.find(Value, O) then table.insert(T, tostring(O)) end end
			ValLbl.Text = #T > 0 and table.concat(T, ", ") or "None"
		else
			ValLbl.Text = Value ~= nil and tostring(Value) or "None"
		end
	end

	local Obj = { Type = "Dropdown", Holder = Holder }
	local function Fire()
		Library.Flags[Flag] = Value
		Display()
		task.spawn(Callback, Value)
	end
	function Obj:Get() return Value end
	function Obj:Set(V)
		if Multi then Value = table.clone(type(V) == "table" and V or {}) else Value = V end
		Fire()
	end
	function Obj:SetOptions(List)
		Options = List or {}
		if Multi then
			for I = #Value, 1, -1 do if not table.find(Options, Value[I]) then table.remove(Value, I) end end
		elseif not table.find(Options, Value) then
			Value = Options[1]
		end
		Fire()
	end

	Btn.MouseButton1Click:Connect(function()
		if Library._Popup and Library._Popup.Owner == Btn then Library:ClosePopup() return end
		Plus.Text = "-"
		OptionPopup(Btn, Options, function(O)
			if Multi then return table.find(Value, O) ~= nil end
			return Value == O
		end, function(O)
			if Multi then
				local I = table.find(Value, O)
				if I then table.remove(Value, I) else table.insert(Value, O) end
			else
				Value = O
			end
			Fire()
		end, Multi, function() Plus.Text = "+" end)
	end)

	Display()
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name, Holder, Opts)
	return Obj
end

function Section:Textbox(Opts)
	Opts = Opts or {}
	local Name  = Opts.Name
	local Flag  = Opts.Flag or Name or ("Textbox" .. NextOrder())
	local Callback = Opts.Callback or function() end
	local Value = Opts.Default or ""

	local Holder = self:_Holder(Name and 40 or 23)
	if Name then
		local Lbl = Label(Holder, Name)
		Bind("Text", function(C) Lbl.TextColor3 = C end)
	end
	local _, Fill = Box(Holder, UDim2.fromOffset(0, Name and 17 or 0), UDim2.new(1, 0, 0, 21), { "Inline", "Outline" })
	ThemeGrad(Fill, "Background", 1, 0.4)
	Fill.ClipsDescendants = true
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 1, 0), Text = Value,
		PlaceholderText = Opts.Placeholder or "", TextXAlignment = Enum.TextXAlignment.Left, Parent = Fill,
	})
	Bind("Text", function(C) TB.TextColor3 = C; TB.PlaceholderColor3 = C end)

	local Obj = { Type = "Textbox", Holder = Holder }
	function Obj:Get() return Value end
	function Obj:Set(V)
		Value = tostring(V or "")
		TB.Text = Value
		Library.Flags[Flag] = Value
		task.spawn(Callback, Value, false)
	end
	TB.FocusLost:Connect(function(Enter)
		Value = TB.Text
		Library.Flags[Flag] = Value
		task.spawn(Callback, Value, Enter)
	end)
	if Opts.Live then
		TB:GetPropertyChangedSignal("Text"):Connect(function()
			Value = TB.Text
			Library.Flags[Flag] = Value
			task.spawn(Callback, Value, false)
		end)
	end

	Obj.Save = Opts.Save
	Library:_Opt(Flag, Obj, Value)
	self:_Register(Name or Opts.Placeholder, Holder, Opts)
	return Obj
end

function Section:Button(Opts)
	Opts = Opts or {}
local Holder = self:_Holder(23)
	local Entry = self:_Register(Opts.Name, Holder, Opts)
	local Row = {}

	local function Layout()
		local N = #Row
		for I, B in Row do
			B.Size = UDim2.new(1 / N, -2 * (N - 1) / N, 0, 21)
			B.Position = UDim2.new((I - 1) / N, (I - 1) * 2 / N, 0, 0)
		end
	end

	local function Add(O)
		local B, Fill = Box(Holder, UDim2.new(), UDim2.new(1, 0, 0, 21), { "Inline", "Outline" }, "TextButton")
		ThemeGrad(Fill, "Base", 1, 0.58)
		local Name = O.Name or "Button"
		local L = New("TextLabel", { Size = UDim2.fromScale(1, 1), Text = Name, Parent = Fill })
		local Hover, Pending = false, false
		local function Col()
			local C = O.Risky and Theme.Risky or Theme.Text
			return Hover and C:Lerp(Color3.new(1, 1, 1), 0.35) or C
		end
		Bind("*", function() L.TextColor3 = Col() end)
		B.MouseEnter:Connect(function() Hover = true; L.TextColor3 = Col() end)
		B.MouseLeave:Connect(function() Hover = false; L.TextColor3 = Col(); VGrad(Fill, Theme.Base, Mul(Theme.Base, 0.58)) end)
		B.MouseButton1Down:Connect(function() VGrad(Fill, Mul(Theme.Base, 0.58), Theme.Base) end)
		B.MouseButton1Up:Connect(function() VGrad(Fill, Theme.Base, Mul(Theme.Base, 0.58)) end)
		B.MouseButton1Click:Connect(function()
			if O.Confirm and not Pending then
				Pending = true
				L.Text = "Are you sure?"
				task.delay(2.5, function()
					if Pending then Pending = false; L.Text = Name end
				end)
				return
			end
			Pending = false
			L.Text = Name
			if O.Callback then task.spawn(O.Callback) end
		end)
		table.insert(Row, B)
		Layout()
		if #Row > 1 then Entry.Name = Entry.Name .. " " .. Name end
	end

	Add(Opts)
	local Obj = { Type = "Button", Holder = Holder }
	function Obj:Button(O) Add(O or {}); return self end
	return Obj
end

function Section:Keybind(Opts)
	Opts = Opts or {}
	local Name  = Opts.Name or "Keybind"
	local Flag  = Opts.Flag or Name
	local Callback = Opts.Callback or function() end
	local State = Opts.Mode == "Always"
	local Listeners = {}

	local Holder = self:_Holder(22)
	local Lbl = New("TextLabel", { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -1, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	Bind("Text", function(C) Lbl.TextColor3 = C end)

	local Obj = { Type = "KeybindState", Holder = Holder }
	local B = MakeKeybind(Addons(Holder), Opts, Flag, Name, {
		Get = function() return State end,
		Set = function(V)
			if V == State then return end
			State = V
			task.spawn(Callback, V)
			for _, Fn in Listeners do task.spawn(Fn, V) end
			Library:_RefreshKeylist()
		end,
	})
	function Obj:Get() return State end
	function Obj:GetKey() return B.Key end
	function Obj:SetKey(K) B:SetKey(K) end
	function Obj:SetMode(M) B:SetMode(M) end
	function Obj:OnChange(Fn) table.insert(Listeners, Fn) end
	Obj.Bind = B

	self:_Register(Name, Holder, Opts)
	return Obj
end

function Section:Colorpicker(Opts)
	Opts = Opts or {}
	local Name = Opts.Name or "Color"
	local Holder = self:_Holder(22)
	local Lbl = New("TextLabel", { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	Bind("TextDim", function(C) Lbl.TextColor3 = C end)
	local C = MakeColor(Addons(Holder), Opts, Opts.Flag or Name)
	C.Holder = Holder
	self:_Register(Name, Holder, Opts)
	return C
end

function Section:Label(Opts)
	if type(Opts) == "string" then Opts = { Text = Opts } end
	Opts = Opts or {}
	local Holder = self:_Holder(0)
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	New("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = Holder })
	local L = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
		Text = Opts.Text or "", RichText = true,
		TextXAlignment = Opts.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left, Parent = Holder,
	})
	Bind("*", function() L.TextColor3 = Opts.Risky and Theme.Risky or Theme.Text end)
	if Opts.Dependency then self:_Register(nil, Holder, { Dependency = Opts.Dependency, NoSearch = true }) end
	local Obj = { Holder = Holder, Label = L }
	function Obj:Set(T) L.Text = T end
	return Obj
end

function Section:Separator()
	local Holder = self:_Holder(9)
	local A = New("Frame", { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 1), Parent = Holder })
	local B = New("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 1), Parent = Holder })
	Bind("Outline", function(C) A.BackgroundColor3 = C end)
	Bind("Inline", function(C) B.BackgroundColor3 = C end)
	return { Holder = Holder }
end

function Section:List(Opts)
	Opts = Opts or {}
	local Name     = Opts.Name or "List"
	local Flag     = Opts.Flag or Name
	local Header   = Opts.NoHeader ~= true
	local Height   = Opts.Height or 200
	local RowH     = Opts.RowHeight or 16
	local Options  = Opts.Options or {}
	local Callback = Opts.Callback or function() end
	local Value    = Opts.Default
	local Collapsed = false

	local Holder = self:_Holder(0)
	local _, Fill = Box(Holder, UDim2.new(), UDim2.new(1, 0, 1, -2), { "Inline", "Outline" })
	Bind("Background", function(C) Fill.BackgroundColor3 = C end)
	Fill.ClipsDescendants = true

	local Top, Chevron = 0, nil
	local SF
	local function Resize()
		local H = 4 + (Header and 21 or 0) + (Collapsed and 0 or ((Header and 1 or 0) + Height))
		Holder.Size = UDim2.new(1, 0, 0, H + 2)
		if SF then SF.Visible = not Collapsed end
		if Chevron then Chevron.Text = Collapsed and "v" or "^" end
	end

	if Header then
		local HB = New("TextButton", { Size = UDim2.new(1, 0, 0, 21), Parent = Fill })
		local Ic = New("Frame", { Position = UDim2.fromOffset(9, 7), Size = UDim2.fromOffset(11, 8), BackgroundTransparency = 1, Parent = HB })
		local IcS = New("UIStroke", { Parent = Ic })
		local IcT = New("Frame", { Position = UDim2.fromOffset(9, 5), Size = UDim2.fromOffset(5, 2), Parent = HB })
		local HL = New("TextLabel", { Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -44, 1, 0), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = HB })
		Chevron = New("TextLabel", { Position = UDim2.new(1, -18, 0, 2), Size = UDim2.new(0, 10, 1, 0), Text = "^", Parent = HB })
		local Sep = New("Frame", { Position = UDim2.fromOffset(0, 21), Size = UDim2.new(1, 0, 0, 1), Parent = Fill })
		Bind("Text", function(C) HL.TextColor3 = C; Chevron.TextColor3 = C; IcS.Color = C; IcT.BackgroundColor3 = C end)
		Bind("Outline", function(C) Sep.BackgroundColor3 = C end)
		HB.MouseButton1Click:Connect(function() Collapsed = not Collapsed; Resize() end)
		Top = 22
	end

	SF = New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, Top), Size = UDim2.new(1, 0, 1, -Top), BackgroundTransparency = 1,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 1, TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		Parent = Fill,
	})
	Bind("Accent", function(C) SF.ScrollBarImageColor3 = Mul(C, 0.56) end)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = SF })
	New("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = SF })

	local Rows = {}
	local Obj = { Type = "List", Holder = Holder, Save = Opts.Save }
	local function Paint()
		for O, R in Rows do R.TextColor3 = (O == Value) and Theme.Accent or Theme.Text end
	end
	local function Build()
		for _, R in Rows do R:Destroy() end
		Rows = {}
		for I, O in Options do
			local R = New("TextButton", {
				Size = UDim2.new(1, 0, 0, RowH), Text = tostring(O), LayoutOrder = I,
				TextXAlignment = Opts.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = SF,
			})
			if not Opts.Centered then New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = R }) end
			R.MouseButton1Click:Connect(function() Obj:Set(O) end)
			Rows[O] = R
		end
		Paint()
	end
	Bind("*", Paint)

	function Obj:Get() return Value end
	function Obj:Set(V)
		Value = V
		Library.Flags[Flag] = V
		Paint()
		task.spawn(Callback, V)
	end
	function Obj:SetOptions(List)
		Options = List or {}
		if Value ~= nil and not table.find(Options, Value) then Value = nil; Library.Flags[Flag] = nil end
		Build()
	end

	Resize()
	Build()
	Library:_Opt(Flag, Obj, Value)
	if Header then self:_Register(Name, Holder, Opts) end
	return Obj
end

function Section:PlayerList(Opts)
	Opts = Opts or {}
	local Query, Map, L = "", {}, nil
	local function Build()
		local Out = {}
		Map = {}
		for _, P in Players:GetPlayers() do
			if P ~= LocalPlayer or Opts.IncludeSelf then
				local D = P.DisplayName .. " (@" .. P.Name .. ")"
				if Query == "" or D:lower():find(Query, 1, true) then
					table.insert(Out, D)
					Map[D] = P
				end
			end
		end
		L:SetOptions(Out)
	end
	self:Textbox({
		Name = Opts.SearchName or "Search Players", Placeholder = "Type to search..", Live = true, Save = false,
		Flag = (Opts.Flag or "PlayerList") .. "_Search",
		Callback = function(T) Query = T:lower(); if L then Build() end end,
	})
	L = self:List({
		NoHeader = true, Centered = true, Height = Opts.Height or 300, RowHeight = 15, Save = false,
		Flag = Opts.Flag or "PlayerList",
		Callback = function(D) if Opts.Callback then Opts.Callback(Map[D]) end end,
	})
	Build()
	Library:Connect(Players.PlayerAdded, Build)
	Library:Connect(Players.PlayerRemoving, function() task.defer(Build) end)
	return {
		Get = function() return Map[L:Get()] end,
		Refresh = Build,
	}
end


local Page = {}
Page.__index = Page

local function MakePage(Window, Parent, Top)
	local F = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Parent })
	local function Col(Pos)
		local S = New("ScrollingFrame", {
			Position = Pos, Size = UDim2.new(0.5, -6, 1, -(Top + 6)), BackgroundTransparency = 1,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 1, TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Parent = F,
		})
		Bind("Accent", function(C) S.ScrollBarImageColor3 = Mul(C, 0.56) end)
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = S })
		return S
	end
	return setmetatable({
		Window = Window, Frame = F,
		Left = Col(UDim2.fromOffset(6, Top)),
		Right = Col(UDim2.new(0.5, 4, 0, Top)),
	}, Page)
end

function Page:Section(Opts)
	Opts = Opts or {}
	return MakeSection(self.Window, Opts.Side == "Right" and self.Right or self.Left, Opts)
end

local Tab = {}
Tab.__index = Tab

function Tab:Section(Opts)
	if not self.Page then
		self.Page = MakePage(self.Window, self.Container, 6)
		self.Page.Frame.Visible = true
	end
	return self.Page:Section(Opts)
end

function Tab:SelectSub(Sub)
	for _, S in self.SubTabs do
		local A = S == Sub
		S.Active = A
		S.Page.Frame.Visible = A
		S.Button.Size = UDim2.new(S.Button.Size.X.Scale, S.Button.Size.X.Offset, 0, A and 27 or 26)
		S.Mid.Size = UDim2.new(1, -2, 1, A and -1 or -2)
		S.Fill.Size = UDim2.new(1, -2, 1, A and -1 or -2)
		S.Gap.Visible = A
		S.Label.TextColor3 = A and Theme.Accent or Theme.TextTab
	end
	self.ActiveSub = Sub
	Library:ClosePopup()
	self.Window:_Research()
end

function Tab:SubTab(Opts)
	if type(Opts) == "string" then Opts = { Name = Opts } end
	Opts = Opts or {}
	if not self.SepLine then
		local A = New("Frame", { Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 1), Parent = self.Container })
		local B = New("Frame", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 1), Parent = self.Container })
		Bind("Inline", function(C) A.BackgroundColor3 = C end)
		Bind("Outline", function(C) B.BackgroundColor3 = C end)
		self.SepLine = true
	end

	local Sub = { Name = Opts.Name or "SubTab", Tab = self }
	local Btn = New("TextButton", { BackgroundTransparency = 0, Parent = self.Container })
	local Mid = New("Frame", { Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), Parent = Btn })
	local Fill = New("Frame", { Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), Parent = Mid })
	local Gap = New("Frame", { Position = UDim2.fromOffset(2, 27), Size = UDim2.new(1, -4, 0, 2), Visible = false, Parent = Btn })
	Bind("Inline", function(C) Btn.BackgroundColor3 = C end)
	Bind("Outline", function(C) Mid.BackgroundColor3 = C end)
	Bind("Background", function(C) Gap.BackgroundColor3 = C end)
	ThemeGrad(Fill, "Base", 1, 0.54)
	local Lbl = New("TextLabel", { Size = UDim2.new(1, 0, 0, 24), Text = Sub.Name, Parent = Fill })

	Sub.Button, Sub.Mid, Sub.Fill, Sub.Gap, Sub.Label = Btn, Mid, Fill, Gap, Lbl
	Sub.Page = MakePage(self.Window, self.Container, 33)
	function Sub:Section(O) return self.Page:Section(O) end

	Btn.MouseButton1Click:Connect(function() self:SelectSub(Sub) end)
	Btn.MouseEnter:Connect(function() if not Sub.Active then Lbl.TextColor3 = Theme.Text end end)
	Btn.MouseLeave:Connect(function() if not Sub.Active then Lbl.TextColor3 = Theme.TextTab end end)

	table.insert(self.SubTabs, Sub)
	local N = #self.SubTabs
	for I, S in self.SubTabs do
		S.Button.Position = UDim2.new((I - 1) / N, (I - 1) * 2 / N, 0, 0)
		S.Button.Size = UDim2.new(1 / N, -2 * (N - 1) / N, 0, S.Active and 27 or 26)
	end
	if N == 1 then self:SelectSub(Sub) end
	return Sub
end

local Window = {}
Window.__index = Window

function Library:Window(Opts)
	Opts = Opts or {}
	local W, H = Opts.Width or 564, Opts.Height or 694
	local Win = setmetatable({ Tabs = {}, Searchables = {}, Library = self, Opts = Opts }, Window)
	self.Window = Win

	local Main = New("Frame", {
		Name = "Main", Size = UDim2.fromOffset(W, H),
		Position = UDim2.new(0.5, -math.floor(W / 2), 0.5, -math.floor(H / 2)), Parent = Gui,
	})
	Bind("Inline", function(C) Main.BackgroundColor3 = C end)
	local Bg = New("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), Parent = Main })
	Bind("Background", function(C) Bg.BackgroundColor3 = C end)
	Win.Main = Main

	local function Edge(Pos, Size, Rot)
		local F = New("Frame", { Position = Pos, Size = Size, BackgroundColor3 = Color3.new(1, 1, 1), Parent = Main })
		return New("UIGradient", { Rotation = Rot, Parent = F })
	end
	local GTop   = Edge(UDim2.new(), UDim2.new(1, 0, 0, 2), 0)
	local GBot   = Edge(UDim2.new(0, 0, 1, -2), UDim2.new(1, 0, 0, 2), 0)
	local GLeft  = Edge(UDim2.new(), UDim2.new(0, 2, 1, 0), 90)
	local GRight = Edge(UDim2.new(1, -2, 0, 0), UDim2.new(0, 2, 1, 0), 90)
	local Phase, Speed = 0.26, Opts.BorderSpeed or 0.035
	local Comets = { 0, 0.145, 0.5, 0.645 }
	Library:Connect(RunService.RenderStepped, function(Dt)
		if not Main.Visible then return end
		Phase = (Phase + Dt * Speed) % 1
		local AW, AH = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
		local Per = 2 * (AW + AH)
		local Base, Glow = Theme.Inline, GlowOf(Theme.Accent)
		local Centers = {}
		for I, O in Comets do Centers[I] = ((Phase + O) % 1) * Per end
		local function Seq(Map)
			local K = table.create(20)
			for I = 0, 19 do
				local T = I / 19
				local P = Map(T)
				local Best = 0
				for _, C in Centers do
					local D = math.abs(P - C)
					D = math.min(D, Per - D)
					local V = D <= 42 and 1 or (D < 122 and 1 - (D - 42) / 80 or 0)
					if V > Best then Best = V end
				end
				K[I + 1] = ColorSequenceKeypoint.new(T, Base:Lerp(Glow, Best))
			end
			return ColorSequence.new(K)
		end
		GTop.Color   = Seq(function(T) return T * AW end)
		GRight.Color = Seq(function(T) return AW + T * AH end)
		GBot.Color   = Seq(function(T) return AW + AH + (AW - T * AW) end)
		GLeft.Color  = Seq(function(T) return 2 * AW + AH + (AH - T * AH) end)
	end)

	local DragBar = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Main })
	local Ver = New("TextLabel", { Position = UDim2.fromOffset(7, 2), Size = UDim2.fromOffset(80, 18), Text = Opts.Version or "V3", TextXAlignment = Enum.TextXAlignment.Left, Parent = Main })
	local Title = New("TextLabel", { Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 18), Text = Opts.Title or "LarpHub", Parent = Main })
	local Game = New("TextLabel", { Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, -7, 0, 18), Text = Opts.Game or "", TextXAlignment = Enum.TextXAlignment.Right, Parent = Main })
	Bind("Accent", function(C) Ver.TextColor3 = C end)
	Bind("Title", function(C) Title.TextColor3 = C end)
	Bind("Risky", function(C) Game.TextColor3 = C end)

	DragBar.InputBegan:Connect(function(I)
		local T = I.UserInputType
		if T ~= Enum.UserInputType.MouseButton1 and T ~= Enum.UserInputType.Touch then return end
		Library:ClosePopup()
		local Start, Orig = UserInputService:GetMouseLocation(), Main.Position
		Library._Drag = function()
			local D = UserInputService:GetMouseLocation() - Start
			Main.Position = UDim2.new(Orig.X.Scale, Orig.X.Offset + D.X, Orig.Y.Scale, Orig.Y.Offset + D.Y)
		end
	end)

	local Panel, PanelFill = Box(Main, UDim2.fromOffset(7, 20), UDim2.new(1, -14, 1, -27), { "Outline", "Inline" })
	Bind("Background", function(C) PanelFill.BackgroundColor3 = C end)
	Win.Panel = Panel

	local _, SFill = Box(Panel, UDim2.new(1, -121, 0, 7), UDim2.fromOffset(114, 24), { "Inline", "Outline" })
	Bind("Background", function(C) SFill.BackgroundColor3 = C end)
	local Icon = New("ImageLabel", {
		Position = UDim2.new(0, 5, 0.5, -5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
		Image = "rbxassetid://3926305904", ImageRectOffset = Vector2.new(964, 324), ImageRectSize = Vector2.new(36, 36), Parent = SFill,
	})
	local SearchBox = New("TextBox", {
		Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -23, 1, 0), PlaceholderText = "Search..",
		TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, Parent = SFill,
	})
	Bind("Placeholder", function(C) SearchBox.PlaceholderColor3 = C; Icon.ImageColor3 = C end)
	Bind("Text", function(C) SearchBox.TextColor3 = C end)

	local _, AFill = Box(Main, UDim2.fromOffset(14, 52), UDim2.new(1, -28, 1, -66), { "Inline", "Outline" })
	Bind("Background", function(C) AFill.BackgroundColor3 = C end)
	local BOuter, BFill = Box(Main, UDim2.fromOffset(21, 59), UDim2.new(1, -42, 1, -80), { "Inline", "Outline" })
	Bind("Background", function(C) BFill.BackgroundColor3 = C end)
	Win.Content = BOuter

	function Win:_LayoutTabs()
		local N = #self.Tabs
		local Area = (W - 14) - 133
		local TW = math.floor((Area - 4 * (N - 1)) / N)
		for I, T in self.Tabs do
			T.Button.Position = UDim2.fromOffset(8 + (I - 1) * (TW + 4), 8)
			T.Button.Size = UDim2.fromOffset(TW, 21)
		end
	end

	local SearchPage, HiddenPage, HiddenTab
	local function ClearSearch()
		for _, E in Win.Searchables do
			if E.Moved then E.Holder.Parent = E.Section.Body; E.Moved = false end
		end
		if SearchPage then SearchPage.Frame:Destroy(); SearchPage = nil end
		if HiddenPage then
			local Cur = HiddenTab.ActiveSub and HiddenTab.ActiveSub.Page or HiddenTab.Page
			if Cur == HiddenPage then HiddenPage.Frame.Visible = true end
			HiddenPage, HiddenTab = nil, nil
		end
	end
	function Win:_Research()
		ClearSearch()
		local Q = SearchBox.Text:lower():match("^%s*(.-)%s*$")
		if Q == "" then return end
		local T = self.Active
		if not T then return end
		local Cur = T.ActiveSub and T.ActiveSub.Page or T.Page
		if Cur then Cur.Frame.Visible = false; HiddenPage, HiddenTab = Cur, T end
		SearchPage = MakePage(self, T.Container, #T.SubTabs > 0 and 33 or 6)
		SearchPage.Frame.Visible = true
		local Groups = {}
		for _, E in self.Searchables do
			if E.Name:lower():find(Q, 1, true) then
				local G = Groups[E.Section]
				if not G then
					G = SearchPage:Section({ Name = E.Section.Name, Side = E.Section.Side, Risky = E.Section.Risky })
					Groups[E.Section] = G
				end
				E.Holder.Parent = G.Body
				E.Moved = true
			end
		end
	end
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function() Win:_Research() end)

	Bind("*", function()
		for _, T in Win.Tabs do T.Label.TextColor3 = T.Active and Theme.Accent or Theme.TextTab end
	end)

	return Win
end

function Window:SelectTab(T)
	for _, X in self.Tabs do
		local A = X == T
		X.Active = A
		X.Container.Visible = A
		X.Label.TextColor3 = A and Theme.Accent or Theme.TextTab
	end
	self.Active = T
	Library:ClosePopup()
	self:_Research()
end

function Window:Tab(Opts)
	if type(Opts) == "string" then Opts = { Name = Opts } end
	Opts = Opts or {}
	local T = setmetatable({ Name = Opts.Name or "Tab", SubTabs = {}, Window = self }, Tab)
	local Btn, Fill = Box(self.Panel, UDim2.new(), UDim2.fromOffset(66, 21), { "Outline" }, "TextButton")
	ThemeGrad(Fill, "Base", 1, 0.58)
	T.Button = Btn
	T.Label = New("TextLabel", { Size = UDim2.fromScale(1, 1), Text = T.Name, TextColor3 = Theme.TextTab, Parent = Fill })
	T.Container = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Content })

	Btn.MouseButton1Click:Connect(function() self:SelectTab(T) end)
	Btn.MouseEnter:Connect(function() if not T.Active then T.Label.TextColor3 = Theme.Text end end)
	Btn.MouseLeave:Connect(function() if not T.Active then T.Label.TextColor3 = Theme.TextTab end end)

	table.insert(self.Tabs, T)
	self:_LayoutTabs()
	if #self.Tabs == 1 then self:SelectTab(T) end
	return T
end

function Window:SetVisible(V)
	self.Main.Visible = V
	Library.Open = V
	if not V then Library:ClosePopup() end
end

function Library:Toggle()
	if self.Window then self.Window:SetVisible(not self.Window.Main.Visible) end
end

function Library:Unload()
	for _, C in self.Connections do pcall(function() C:Disconnect() end) end
	self.Connections = {}
	Gui:Destroy()
end


local function FloatBox(Parent, Order)
	local O = New("Frame", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = Order or 0, Parent = Parent })
	Bind("Outline", function(C) O.BackgroundColor3 = C end)
	New("UIPadding", { PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 1), PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1), Parent = O })
	local I = New("Frame", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Parent = O })
	Bind("Inline", function(C) I.BackgroundColor3 = C end)
	New("UIPadding", { PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 1), PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1), Parent = I })
	local F = New("Frame", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Parent = I })
	Bind("Base", function(C) F.BackgroundColor3 = C end)
	New("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = F })
	local Line = New("Frame", { Size = UDim2.new(1, 0, 0, 2), ZIndex = 2, Parent = I })
	New("UIGradient", { Transparency = EdgeFade, Parent = Line })
	Bind("Accent", function(C) Line.BackgroundColor3 = C end)
	return O, F, I
end

local NotifyAlign = {
	["Top Center"]    = { Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top },
	["Top Left"]      = { Enum.HorizontalAlignment.Left,   Enum.VerticalAlignment.Top },
	["Top Right"]     = { Enum.HorizontalAlignment.Right,  Enum.VerticalAlignment.Top },
	["Bottom Center"] = { Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom },
	["Bottom Left"]   = { Enum.HorizontalAlignment.Left,   Enum.VerticalAlignment.Bottom },
	["Bottom Right"]  = { Enum.HorizontalAlignment.Right,  Enum.VerticalAlignment.Bottom },
}

function Library:Notify(Text, Time, Color)
	Time = Time or 3
	local A = NotifyAlign[self.NotifyPosition] or NotifyAlign["Top Center"]
	NotifyLayout.HorizontalAlignment, NotifyLayout.VerticalAlignment = A[1], A[2]
	local O, F, I = FloatBox(NotifyHolder, NextOrder())
	New("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 14), Text = tostring(Text), TextColor3 = Color or Theme.Text, Parent = F })
	local Bar = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Accent, ZIndex = 2, Parent = I })
	Tween(Bar, Time, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)
	task.delay(Time, function() O:Destroy() end)
end

function Library:Watermark(Opts)
	Opts = Opts or {}
	local Holder = New("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Parent = Gui })
	local _, F = FloatBox(Holder)
	local L = New("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 14), Parent = F })
	Bind("Text", function(C) L.TextColor3 = C end)
	local Fps, Acc, Frames = 60, 0, 0
	Library:Connect(RunService.RenderStepped, function(Dt)
		Frames += 1
		Acc += Dt
		if Acc < 0.5 then return end
		Fps = math.floor(Frames / Acc + 0.5)
		Frames, Acc = 0, 0
		local Ping = 0
		pcall(function() Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
		L.Text = string.format("%s | %s | %d fps | %d ms", Opts.Title or "LarpHub", Opts.Game or LocalPlayer.Name, Fps, Ping)
	end)
	L.Text = Opts.Title or "LarpHub"
	self.WatermarkFrame = Holder
	return { SetVisible = function(_, V) Holder.Visible = V end, Frame = Holder }
end

function Library:KeybindList()
	local Holder = New("Frame", { Position = UDim2.new(0, 10, 0.4, 0), Size = UDim2.fromOffset(170, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Gui })
	local _, Fill = AutoBox(Holder, UDim2.new(1, 0, 0, 0), { "Outline", "Inline" })
	Bind("Base", function(C) Fill.BackgroundColor3 = C end)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Fill })
	local Head = New("Frame", { Size = UDim2.new(1, 0, 0, 21), BackgroundTransparency = 1, Parent = Fill })
	local Line = New("Frame", { Size = UDim2.new(1, 0, 0, 2), Parent = Head })
	New("UIGradient", { Transparency = EdgeFade, Parent = Line })
	Bind("Accent", function(C) Line.BackgroundColor3 = C end)
	New("TextLabel", { Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 18), Text = "Keybinds", Parent = Head })
	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = Fill })
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Body })
	New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 3), Parent = Body })

	local Head2 = Head
	Head2.InputBegan:Connect(function(I)
		if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local Start, Orig = UserInputService:GetMouseLocation(), Holder.Position
		Library._Drag = function()
			local D = UserInputService:GetMouseLocation() - Start
			Holder.Position = UDim2.new(Orig.X.Scale, Orig.X.Offset + D.X, Orig.Y.Scale, Orig.Y.Offset + D.Y)
		end
	end)

	function Library:_RefreshKeylist()
		for _, C in Body:GetChildren() do if C:IsA("Frame") then C:Destroy() end end
		for _, B in self._Keybinds do
			if not B.NoList and B.Key and B:Active() then
				local R = New("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Body })
				New("TextLabel", { Size = UDim2.fromScale(1, 1), Text = B.Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = R })
				New("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "[" .. KeyName(B.Key) .. "]", TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Right, Parent = R })
			end
		end
	end
	self:_RefreshKeylist()
	self.KeylistFrame = Holder
	return { SetVisible = function(_, V) Holder.Visible = V end, Frame = Holder }
end
function Library:_RefreshKeylist() end


function Library:GetConfigs()
	local Out = {}
	local Ok, Files = Try(listfiles, self.ConfigFolder)
	if not Ok or type(Files) ~= "table" then return Out end
	for _, F in Files do
		local N = F:match("([^/\\]+)%.json$")
		if N then table.insert(Out, N) end
	end
	table.sort(Out)
	return Out
end

local function SafeConfigName(Name)
		if type(Name) ~= "string" then return nil end
		Name = Name:gsub("%.json$", ""):gsub("[^%w%-%_ ]", "")
		Name = Name:match("^%s*(.-)%s*$")
		if Name == "" then return nil end
		return Name
end

function Library:SaveConfig(Name)
	Name = SafeConfigName(Name)
	if not Name then return false end
	local Data = {}
	for Flag, O in self.Options do
		if O.Save ~= false then
			local Ok, V = pcall(O.Serialize, O)
			if Ok then Data[Flag] = V end
		end
	end
	return Try(writefile, self.ConfigFolder .. "/" .. Name .. ".json", HttpService:JSONEncode(Data))
end

function Library:LoadConfig(Name)
	Name = SafeConfigName(Name)
	if not Name then return false end
	local Ok, Raw = Try(readfile, self.ConfigFolder .. "/" .. Name .. ".json")
	if not Ok then return false end
	local Ok2, Data = pcall(HttpService.JSONDecode, HttpService, Raw)
	if not Ok2 or type(Data) ~= "table" then return false end
	for Flag, V in Data do
		local O = self.Options[Flag]
		if O and O.Save ~= false then pcall(O.Deserialize, O, V) end
	end
	return true
end

function Library:DeleteConfig(Name)
	Name = SafeConfigName(Name)
	if not Name then return false end
	return Try(delfile, self.ConfigFolder .. "/" .. Name .. ".json")
end


function Library:SettingsTab(Win, Opts)
	Opts = Opts or {}
	local T = Win:Tab({ Name = Opts.Name or "Settings" })

	local Cfg = T:Section({ Name = "Configs", Side = "Left" })
	local List = Cfg:List({ Name = "Configs", Height = 250, Options = self:GetConfigs(), Flag = "__ConfigList", Save = false })
	local NameBox = Cfg:Textbox({ Name = "Config Name", Placeholder = "Enter config name (for Save As)..", Flag = "__ConfigName", Save = false })
	local function Target()
		local N = NameBox:Get()
		if N ~= "" then return N end
		return List:Get()
	end
	local function Refresh() List:SetOptions(self:GetConfigs()) end
	Cfg:Button({ Name = "Save", Callback = function()
		local N = Target()
		if not N then return self:Notify("Select or name a config first", 3) end
		if self:SaveConfig(N) then self:Notify("Saved config " .. N, 3) end
		Refresh()
	end }):Button({ Name = "Load", Callback = function()
		local N = Target()
		if N and self:LoadConfig(N) then self:Notify("Loaded config " .. N, 3) else self:Notify("Failed to load config", 3) end
	end })
	Cfg:Button({ Name = "[!] Delete", Risky = true, Confirm = true, Callback = function()
		local N = Target()
		if N and self:DeleteConfig(N) then self:Notify("Deleted config " .. N, 3) end
		Refresh()
	end }):Button({ Name = "Refresh", Callback = Refresh })

	local About = T:Section({ Name = "About", Side = "Left" })
	About:Separator()
	About:Label({ Text = Opts.License or "This library is licensed as LarpHub", Centered = true })
	About:Separator()
	for _, Line in Opts.Credits or { "- you (backend, frontend [library])" } do
		About:Label({ Text = Line, Centered = true })
	end

	local UI = T:Section({ Name = "UI Settings", Side = "Right" })
	UI:Button({ Name = "Rejoin", Callback = function()
		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
		if not ok then
			pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
		end
	end })
	UI:Button({ Name = "Server Hop", Callback = function()
		local placeId = game.PlaceId
		local currentJob = game.JobId
		local servers = {}
		local cursor = ""
		local okFetch = false

		local function fetchPage(url)
			local raw
			local ok = pcall(function()
				if request then
					local res = request({ Url = url, Method = "GET" })
					raw = res.Body or res.body
				else
					raw = game:HttpGet(url)
				end
			end)
			if not ok or not raw then return nil end
			local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, raw)
			if decodeOk then return data end
			return nil
		end

		for _ = 1, 3 do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(
				placeId, cursor ~= "" and ("&cursor=" .. cursor) or ""
			)
			local data = fetchPage(url)
			if data and data.data then
				okFetch = true
				for _, s in ipairs(data.data) do
					if s.id and s.id ~= currentJob and (s.playing or 0) < (s.maxPlayers or 0) then
						table.insert(servers, s)
					end
				end
				cursor = data.nextPageCursor or ""
				if cursor == "" or #servers >= 15 then break end
			else
				break
			end
		end

		if #servers == 0 then
			self:Notify(okFetch and "No other open servers found" or "Failed to fetch servers", 3)
			return
		end

		-- pick a random open server
		local pick = servers[math.random(1, #servers)]
		local okTP = pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId, pick.id, LocalPlayer)
		end)
		if not okTP then
			self:Notify("Teleport failed, try again", 3)
		else
			self:Notify("Hopping to server...", 2)
		end
	end })
	UI:Keybind({ Name = "Menu Keybind", Flag = "MenuKeybind", Default = self.MenuKey, NoList = true,
		Changed = function(K) self.MenuKey = K end })

	local Watermark = self:Watermark({ Title = Win.Opts and Win.Opts.Title, Game = Opts.Game })
	local Keylist = self:KeybindList()
	UI:Toggle({ Name = "Show Watermark", Flag = "ShowWatermark", Default = false, Callback = function(V) Watermark:SetVisible(V) end })
	UI:Toggle({ Name = "Show Keybind List", Flag = "ShowKeybindList", Default = false, Callback = function(V) Keylist:SetVisible(V) end })
	Watermark:SetVisible(false)
	Keylist:SetVisible(false)
	UI:Dropdown({ Name = "Notification Position", Flag = "NotificationPosition", Default = self.NotifyPosition,
		Options = { "Top Center", "Top Left", "Top Right", "Bottom Center", "Bottom Left", "Bottom Right" },
		Callback = function(V) self.NotifyPosition = V end })
	UI:Slider({ Name = "Tween Time", Flag = "TweenTime", Min = 0, Max = 1, Default = self.TweenTime, Decimals = 1, Suffix = "s",
		Callback = function(V) self.TweenTime = V end })
	UI:Slider({ Name = "Rainbow Speed", Flag = "RainbowSpeed", Min = 0, Max = 0.05, Default = self.RainbowSpeed, Decimals = 3,
		Callback = function(V) self.RainbowSpeed = V end })
	UI:Separator()
	UI:Toggle({ Name = "Anti AFK Kick", Flag = "AntiAFK" })
	UI:Toggle({ Name = "Show ESP Preview", Flag = "ShowESPPreview", Callback = Opts.OnESPPreview })
	UI:Separator()
	for _, Pair in { { "Accent Color", "Accent" }, { "Background Color", "Background" }, { "Base Color", "Base" }, { "Outline Color", "Outline" }, { "Text Color", "Text" } } do
		UI:Colorpicker({ Name = Pair[1], Flag = "Theme_" .. Pair[2], Default = Theme[Pair[2]],
			Callback = function(C) self:SetTheme(Pair[2], C) end })
	end

	pcall(function()
		local VirtualUser = cloneref(game:GetService("VirtualUser"))
		self:Connect(LocalPlayer.Idled, function()
			if self.Flags.AntiAFK then
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end
		end)
	end)

	return T
end


--==================================================
-- LARPHUB - LarpHub UI INTEGRATION
-- The previous ScreenGui/button factory has been removed.
--==================================================

--==================================================
-- LARPHUB
-- Features: CamLock, FOV, ESP, Walk Speed, Jump Power
--==================================================

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local OWNER_USER_ID = 11952613409

local AimSettings = {
    Enabled = false,
    Locked = false,
    FOV = 140,
    ShowFOV = false,
    Smoothness = 0.35,   -- 0 = instant, 1 = very slow
    TargetPart = "Head",
    LockedPart = nil,
    LockedPlayer = nil,
}

local ESPSettings = {
    Enabled = false,
    Names = true,
    Distance = true,
    Boxes = true,
    Health = true,
    Tracers = false,
    TeamCheck = true,
    MaxDistance = 2000,
    BoxColor = Color3.fromRGB(224, 68, 68),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(224, 68, 68),
}

local function GetCharacter(Player)
    return Player and Player.Character
end

local function GetHumanoid(Character)
    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(Character)
    return Character and (Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso"))
end

local function GetAimPart(Player)
    local Character = GetCharacter(Player)
    if not Character then return nil end
    return Character:FindFirstChild(AimSettings.TargetPart)
        or Character:FindFirstChild("HumanoidRootPart")
end

local function IsValidTarget(Player)
    if not Player or Player == LocalPlayer then return false end
    local Character = GetCharacter(Player)
    local Humanoid = GetHumanoid(Character)
    local Part = GetAimPart(Player)
    if not Character or not Humanoid or Humanoid.Health <= 0 or not Part then
        return false
    end
    if Player.Team ~= nil and LocalPlayer.Team ~= nil and Player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function IsESPValid(Player)
    if not Player or Player == LocalPlayer then return false end
    local Character = GetCharacter(Player)
    local Humanoid = GetHumanoid(Character)
    local Root = GetRoot(Character)
    if not Character or not Humanoid or Humanoid.Health <= 0 or not Root then
        return false
    end
    if ESPSettings.TeamCheck and Player.Team ~= nil and LocalPlayer.Team ~= nil and Player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function GetClosestTarget()
    Camera = workspace.CurrentCamera
    if not Camera then return nil end

    local Mouse = UserInputService:GetMouseLocation()
    local BestPlayer, BestPart, BestDistance = nil, nil, AimSettings.FOV

    for _, Player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(Player) then
            local Part = GetAimPart(Player)
            local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Part.Position)
            if OnScreen then
                local Distance = (Vector2.new(ScreenPoint.X, ScreenPoint.Y) - Mouse).Magnitude
                if Distance < BestDistance then
                    BestDistance = Distance
                    BestPlayer = Player
                    BestPart = Part
                end
            end
        end
    end

    return BestPlayer, BestPart
end

local function UnlockCam()
    AimSettings.Locked = false
    AimSettings.LockedPart = nil
    AimSettings.LockedPlayer = nil

    local Camera = workspace.CurrentCamera
    if Camera then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom
        end)
    end

    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)
end

local function BeginLock(Player, Part)
    AimSettings.Locked = true
    AimSettings.LockedPlayer = Player
    AimSettings.LockedPart = Part

    local Camera = workspace.CurrentCamera
    if Camera then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Scriptable
        end)
    end

    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)
end

local function LockOntoClosest()
    if not AimSettings.Enabled then return end
    local Player, Part = GetClosestTarget()
    if Player and Part then
        if AimSettings.Locked and AimSettings.LockedPlayer == Player then
            UnlockCam()
            Library:Notify("CamLock unlocked", 2)
            return
        end
        BeginLock(Player, Part)
        Library:Notify("CamLock: locked onto " .. (Player.DisplayName or Player.Name), 2)
    else
        if AimSettings.Locked then
            UnlockCam()
            Library:Notify("CamLock unlocked", 2)
        else
            Library:Notify("CamLock: no target in FOV", 2)
        end
    end
end

-- ===================== FOV CIRCLE =====================
local FOVCircle = nil
pcall(function()
    if Drawing and Drawing.new then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 64
        FOVCircle.Radius = AimSettings.FOV
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.Color = Color3.fromRGB(224, 68, 68)
        FOVCircle.Transparency = 1
    end
end)

local function CamLockStep()
    if not AimSettings.Enabled or not AimSettings.Locked then
        return
    end

    local Camera = workspace.CurrentCamera
    if not Camera then return end

    -- Keep it Scriptable while locked
    if Camera.CameraType ~= Enum.CameraType.Scriptable then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Scriptable
        end)
    end

    local Player = AimSettings.LockedPlayer
    local Part = AimSettings.LockedPart

    if not Player or not Player.Parent then
        UnlockCam()
        return
    end

    -- Refresh part if needed
    if not Part or not Part.Parent or not Part:IsDescendantOf(Player.Character or workspace) then
        Part = GetAimPart(Player)
        AimSettings.LockedPart = Part
    end

    if not Part or not IsValidTarget(Player) then
        UnlockCam()
        return
    end

    local localRoot = GetRoot(LocalPlayer.Character)
    if not localRoot then return end

    local targetPos = Part.Position

    -- Position camera behind your character looking at the target
    local direction = (targetPos - localRoot.Position)
    if direction.Magnitude < 1 then
        direction = localRoot.CFrame.LookVector
    else
        direction = direction.Unit
    end

    local distance = 11
    local height = 2.5
    local camPos = localRoot.Position - direction * distance + Vector3.new(0, height, 0)

    local desired = CFrame.lookAt(camPos, targetPos)

    local smooth = AimSettings.Smoothness
    if smooth <= 0 then
        Camera.CFrame = desired
    else
        local alpha = math.clamp(1 - smooth, 0.08, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
    end
end

pcall(function()
    RunService:BindToRenderStep("LarpHubCamLock", Enum.RenderPriority.Camera.Value + 1, CamLockStep)
end)
Library:Connect(RunService.RenderStepped, function()
    -- FOV circle only (camlock uses BindToRenderStep)
    if FOVCircle then
        local show = AimSettings.Enabled and AimSettings.ShowFOV
        FOVCircle.Visible = show
        if show then
            local mouse = UserInputService:GetMouseLocation()
            FOVCircle.Position = Vector2.new(mouse.X, mouse.Y)
            FOVCircle.Radius = AimSettings.FOV
        end
    end
end)

-- safety: unlock on disable / character change
LocalPlayer.CharacterAdded:Connect(function()
    if AimSettings.Locked then
        -- keep lock if same target still valid after our character loads
        task.wait(0.3)
        if AimSettings.LockedPlayer and not IsValidTarget(AimSettings.LockedPlayer) then
            UnlockCam()
        end
    end
end)

-- ===================== ESP =====================
local ESPObjects = {} -- [Player] = { box, name, dist, health, tracer, ... }

local function RemoveESP(Player)
    local data = ESPObjects[Player]
    if not data then return end
    for _, obj in pairs(data) do
        pcall(function()
            if typeof(obj) == "Instance" then
                obj:Destroy()
            elseif obj.Remove then
                obj:Remove()
            elseif obj.Destroy then
                obj:Destroy()
            end
        end)
    end
    ESPObjects[Player] = nil
end

local function HasDrawing()
    return type(Drawing) == "table" and type(Drawing.new) == "function"
end

local function CreateESP(Player)
    if ESPObjects[Player] then return end
    local data = {}

    if HasDrawing() then
        local box = Drawing.new("Square")
        box.Thickness = 1.5
        box.Filled = false
        box.Visible = false
        box.Color = ESPSettings.BoxColor
        box.Transparency = 1
        data.Box = box

        local boxOutline = Drawing.new("Square")
        boxOutline.Thickness = 3
        boxOutline.Filled = false
        boxOutline.Visible = false
        boxOutline.Color = Color3.new(0, 0, 0)
        boxOutline.Transparency = 1
        data.BoxOutline = boxOutline

        local name = Drawing.new("Text")
        name.Size = 14
        name.Center = true
        name.Outline = true
        name.OutlineColor = Color3.new(0, 0, 0)
        name.Color = ESPSettings.NameColor
        name.Visible = false
        name.Font = 2
        data.Name = name

        local dist = Drawing.new("Text")
        dist.Size = 13
        dist.Center = true
        dist.Outline = true
        dist.OutlineColor = Color3.new(0, 0, 0)
        dist.Color = Color3.fromRGB(200, 200, 200)
        dist.Visible = false
        dist.Font = 2
        data.Dist = dist

        local healthBar = Drawing.new("Line")
        healthBar.Thickness = 3
        healthBar.Visible = false
        healthBar.Color = Color3.fromRGB(0, 255, 0)
        data.HealthBar = healthBar

        local healthOutline = Drawing.new("Line")
        healthOutline.Thickness = 5
        healthOutline.Visible = false
        healthOutline.Color = Color3.new(0, 0, 0)
        data.HealthOutline = healthOutline

        local tracer = Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Visible = false
        tracer.Color = ESPSettings.TracerColor
        data.Tracer = tracer
    else
        -- Fallback BillboardGui ESP
        local bill = Instance.new("BillboardGui")
        bill.Name = "LarpESP"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.fromOffset(120, 40)
        bill.StudsOffset = Vector3.new(0, 2.5, 0)
        bill.Enabled = false
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextColor3 = ESPSettings.NameColor
        label.TextStrokeTransparency = 0.4
        label.Text = ""
        label.Parent = bill
        data.Billboard = bill
        data.Label = label
    end

    ESPObjects[Player] = data
end

local function HideESPData(data)
    if not data then return end
    if data.Box then data.Box.Visible = false end
    if data.BoxOutline then data.BoxOutline.Visible = false end
    if data.Name then data.Name.Visible = false end
    if data.Dist then data.Dist.Visible = false end
    if data.HealthBar then data.HealthBar.Visible = false end
    if data.HealthOutline then data.HealthOutline.Visible = false end
    if data.Tracer then data.Tracer.Visible = false end
    if data.Billboard then data.Billboard.Enabled = false end
end

local function UpdateESP()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    local myRoot = GetRoot(GetCharacter(LocalPlayer))
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position
    local viewport = Camera.ViewportSize
    local bottomCenter = Vector2.new(viewport.X / 2, viewport.Y)

    for _, Player in ipairs(Players:GetPlayers()) do
        if not ESPSettings.Enabled or not IsESPValid(Player) then
            HideESPData(ESPObjects[Player])
        else
            CreateESP(Player)
            local data = ESPObjects[Player]
            local Character = GetCharacter(Player)
            local Humanoid = GetHumanoid(Character)
            local Root = GetRoot(Character)
            if Root and Humanoid then
                local distance = (Root.Position - myPos).Magnitude
                if distance > ESPSettings.MaxDistance then
                    HideESPData(data)
                else
                    local head = Character:FindFirstChild("Head")
                    local headPos = head and head.Position or (Root.Position + Vector3.new(0, 1.5, 0))
                    local top, topOn = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.4, 0))
                    local bottom, botOn = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    local onScreen = topOn or botOn

                    if not onScreen then
                        HideESPData(data)
                    else
                        local height = math.abs(top.Y - bottom.Y)
                        local width = height / 2.2
                        local boxPos = Vector2.new(top.X - width / 2, top.Y)
                        local boxSize = Vector2.new(width, height)

                        if data.Box then
                            local showBox = ESPSettings.Boxes
                            data.Box.Visible = showBox
                            data.BoxOutline.Visible = showBox
                            if showBox then
                                data.Box.Position = boxPos
                                data.Box.Size = boxSize
                                data.Box.Color = ESPSettings.BoxColor
                                data.BoxOutline.Position = boxPos
                                data.BoxOutline.Size = boxSize
                            end

                            local showName = ESPSettings.Names
                            data.Name.Visible = showName
                            if showName then
                                data.Name.Text = Player.DisplayName ~= Player.Name
                                    and (Player.DisplayName .. " (@" .. Player.Name .. ")")
                                    or Player.Name
                                data.Name.Position = Vector2.new(top.X, top.Y - 16)
                                data.Name.Color = ESPSettings.NameColor
                            end

                            local showDist = ESPSettings.Distance
                            data.Dist.Visible = showDist
                            if showDist then
                                data.Dist.Text = math.floor(distance + 0.5) .. " studs"
                                data.Dist.Position = Vector2.new(bottom.X, bottom.Y + 2)
                            end

                            local showHP = ESPSettings.Health
                            data.HealthBar.Visible = showHP
                            data.HealthOutline.Visible = showHP
                            if showHP then
                                local hp = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 1), 0, 1)
                                local barX = boxPos.X - 6
                                local barTop = boxPos.Y + boxSize.Y * (1 - hp)
                                local barBot = boxPos.Y + boxSize.Y
                                data.HealthOutline.From = Vector2.new(barX, boxPos.Y)
                                data.HealthOutline.To = Vector2.new(barX, boxPos.Y + boxSize.Y)
                                data.HealthBar.From = Vector2.new(barX, barTop)
                                data.HealthBar.To = Vector2.new(barX, barBot)
                                data.HealthBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 40)
                            end

                            local showTracer = ESPSettings.Tracers
                            data.Tracer.Visible = showTracer
                            if showTracer then
                                data.Tracer.From = bottomCenter
                                data.Tracer.To = Vector2.new(bottom.X, bottom.Y)
                                data.Tracer.Color = ESPSettings.TracerColor
                            end
                        elseif data.Billboard then
                            data.Billboard.Adornee = head or Root
                            data.Billboard.Parent = Character
                            data.Billboard.Enabled = true
                            local parts = {}
                            if ESPSettings.Names then
                                table.insert(parts, Player.DisplayName ~= Player.Name
                                    and (Player.DisplayName .. " (@" .. Player.Name .. ")")
                                    or Player.Name)
                            end
                            if ESPSettings.Distance then
                                table.insert(parts, math.floor(distance + 0.5) .. " studs")
                            end
                            if ESPSettings.Health then
                                table.insert(parts, math.floor(Humanoid.Health + 0.5) .. " HP")
                            end
                            data.Label.Text = table.concat(parts, "\n")
                            data.Label.TextColor3 = ESPSettings.NameColor
                        end
                    end
                end
            end
        end
    end
end

Library:Connect(RunService.RenderStepped, function()
    if ESPSettings.Enabled then
        UpdateESP()
    end
end)

Library:Connect(Players.PlayerRemoving, function(P)
    RemoveESP(P)
end)

-- Owner / Developer join notification
local function NotifyDeveloperJoined(Player)
    if not Player or Player.UserId ~= OWNER_USER_ID then return end
    local Name = Player.DisplayName or Player.Name
    Library:Notify("Developer " .. Name .. " Joined", 6)
end

for _, P in ipairs(Players:GetPlayers()) do
    if P.UserId == OWNER_USER_ID and P ~= LocalPlayer then
        task.defer(NotifyDeveloperJoined, P)
    end
end

Library:Connect(Players.PlayerAdded, function(P)
    if P.UserId == OWNER_USER_ID then
        task.defer(NotifyDeveloperJoined, P)
    end
end)

-- ===================== UI =====================
local Win = Library:Window({
    Title = "LARPHUB",
    Version = "V1.2",
    Game = "urban",
    Width = 560,
    Height = 520,
})

local AimTab = Win:Tab({ Name = "Combat" })
local VisualsTab = Win:Tab({ Name = "Visuals" })
local SettingsTab = Win:Tab({ Name = "Settings" })

-- Combat / CamLock
local AimSection = AimTab:Section({ Name = "CamLock", Side = "Left" })
local AimToggle = AimSection:Toggle({
    Name = "Enable CamLock",
    Flag = "CamLockEnabled",
    Default = false,
    Callback = function(Value)
        AimSettings.Enabled = Value
        if not Value then
            UnlockCam()
            Library:Notify("CamLock disabled", 2)
        else
            Library:Notify("CamLock enabled – press Q on a target", 2)
        end
    end,
})
AimToggle:AddKeybind({
    Flag = "CamLockKey",
    Default = Enum.KeyCode.Q,
    Mode = "Toggle",
})

do
    local KeyObj = AimToggle.Keybind
    if KeyObj then
        KeyObj.Handler = {
            Get = function()
                return AimSettings.Locked
            end,
            Set = function(_V)
                if not AimSettings.Enabled then
                    UnlockCam()
                    return
                end
                LockOntoClosest()
            end,
        }
    end
end

AimSection:Toggle({
    Name = "Show FOV Circle",
    Flag = "ShowFOVCircle",
    Default = false,
    Callback = function(Value)
        AimSettings.ShowFOV = Value
    end,
})

AimSection:Slider({
    Name = "Aim FOV",
    Flag = "AimFOV",
    Min = 25,
    Max = 500,
    Default = AimSettings.FOV,
    Suffix = " px",
    Callback = function(Value)
        AimSettings.FOV = Value
        if FOVCircle then
            FOVCircle.Radius = Value
        end
    end,
})

AimSection:Slider({
    Name = "CamLock Smoothness",
    Flag = "CamLockSmoothness",
    Min = 0,
    Max = 0.9,
    Default = 0.35,
    Decimals = 2,
    Callback = function(Value)
        AimSettings.Smoothness = Value
    end,
})

AimSection:Dropdown({
    Name = "Target Part",
    Flag = "AimTargetPart",
    Options = { "Head", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(Value)
        AimSettings.TargetPart = Value
        if AimSettings.Locked and AimSettings.LockedPlayer then
            AimSettings.LockedPart = GetAimPart(AimSettings.LockedPlayer)
        end
    end,
})

AimSection:Button({
    Name = "Unlock Cam",
    Callback = function()
        UnlockCam()
        Library:Notify("CamLock unlocked", 2)
    end,
})

-- Visuals / ESP
local ESPSection = VisualsTab:Section({ Name = "ESP", Side = "Left" })
ESPSection:Toggle({
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    Default = false,
    Callback = function(Value)
        ESPSettings.Enabled = Value
        if not Value then
            for P in pairs(ESPObjects) do
                RemoveESP(P)
            end
        end
        Library:Notify(Value and "ESP enabled" or "ESP disabled", 2)
    end,
})
ESPSection:Toggle({
    Name = "Names",
    Flag = "ESPNames",
    Default = true,
    Callback = function(V) ESPSettings.Names = V end,
})
ESPSection:Toggle({
    Name = "Distance",
    Flag = "ESPDistance",
    Default = true,
    Callback = function(V) ESPSettings.Distance = V end,
})
ESPSection:Toggle({
    Name = "Boxes",
    Flag = "ESPBoxes",
    Default = true,
    Callback = function(V) ESPSettings.Boxes = V end,
})
ESPSection:Toggle({
    Name = "Health Bar",
    Flag = "ESPHealth",
    Default = true,
    Callback = function(V) ESPSettings.Health = V end,
})
ESPSection:Toggle({
    Name = "Tracers",
    Flag = "ESPTracers",
    Default = false,
    Callback = function(V) ESPSettings.Tracers = V end,
})
ESPSection:Toggle({
    Name = "Team Check",
    Flag = "ESPTeamCheck",
    Default = true,
    Callback = function(V) ESPSettings.TeamCheck = V end,
})
ESPSection:Slider({
    Name = "Max Distance",
    Flag = "ESPMaxDistance",
    Min = 100,
    Max = 5000,
    Default = 2000,
    Suffix = " studs",
    Callback = function(V) ESPSettings.MaxDistance = V end,
})

local ESPColors = VisualsTab:Section({ Name = "ESP Colors", Side = "Right" })
ESPColors:Colorpicker({
    Name = "Box Color",
    Flag = "ESPBoxColor",
    Default = ESPSettings.BoxColor,
    Callback = function(C) ESPSettings.BoxColor = C end,
})
ESPColors:Colorpicker({
    Name = "Name Color",
    Flag = "ESPNameColor",
    Default = ESPSettings.NameColor,
    Callback = function(C) ESPSettings.NameColor = C end,
})
ESPColors:Colorpicker({
    Name = "Tracer Color",
    Flag = "ESPTracerColor",
    Default = ESPSettings.TracerColor,
    Callback = function(C) ESPSettings.TracerColor = C end,
})

local ControlSection = SettingsTab:Section({ Name = "Keybinds", Side = "Left" })
ControlSection:Keybind({
    Name = "Menu Toggle",
    Flag = "LarpMenuKey",
    Default = Enum.KeyCode.RightShift,
    Mode = "Toggle",
    Changed = function(Key)
        Library.MenuKey = Key or Enum.KeyCode.RightShift
    end,
})

-- Full Settings / Configs tab (save, load, delete, rejoin, server hop, theme, etc.)
Library:SettingsTab(Win, {
    Name = "Configs",
    Game = "urban",
    Credits = { "- LarpHub developer" },
})

Library:Notify("LarpHub loaded", 4)
print("[LarpHub] Loaded. RightShift opens menu. CamLock + ESP + FOV ready.")
return Library
