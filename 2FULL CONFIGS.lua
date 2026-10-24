
--                    UNIFIED LOCAL SCRIPT // V3                     --
--============================================================--
-- Módulos:
-- SIMPLE FLY / BOT DE GIRO / ESP ALL / FULLBRIGHT
-- MIRA RGB / NOCLIP / TP / WEATHERS
--
-- CTRL DERECHO = ABRIR / CERRAR PANEL CON FUNDIDO SUAVE
-- Estilo: NEGRO + MORADO / técnico / acceso temporal / Enum.Font.Code
--============================================================--

local Players = game:GetService("Players")

--============================================================--
-- ORION SERVER BRIDGE (OPTIONAL / EXPERIENCIA PROPIA)
--============================================================--
-- Si existe un RemoteEvent llamado ORION_Remote en ReplicatedStorage,
-- ORION enviará únicamente el estado del BOT DE GIRO al servidor.
-- Sin ese RemoteEvent, el sistema continúa funcionando de forma local.
-- Esto NO convierte un LocalScript en replicación universal para
-- experiencias ajenas: el servidor debe aceptar y aplicar el estado.
--============================================================--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrionServerRemote = ReplicatedStorage:FindFirstChild("ORION_Remote")

local function FireOrionServer(action, payload)
    local remote = OrionServerRemote
    if not remote or not remote.Parent then
        remote = ReplicatedStorage:FindFirstChild("ORION_Remote")
        OrionServerRemote = remote
    end

    if not remote or not remote:IsA("RemoteEvent") then
        return
    end

    pcall(function()
        remote:FireServer(action, payload or {})
    end)
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")


--============================================================--
-- V2 // ACCESO
--============================================================--

local SessionActive = true
local AccessMode = nil
local accessGranted = false
local savedLighting
local MiraConnection
local AccessDuration = 0
local AccessStart = 0

local FREE_NUMBER = "+591 61509991"
local INFINITE_KEY = "170414"

local function DestroyV2()
    if not SessionActive then return end
    SessionActive = false

    -- El estado global de sesión corta todos los loops V2.
    pcall(function()
        RunService:UnbindFromRenderStep("RaulsSpinBotV2")
        RunService:UnbindFromRenderStep("RaulsSpinBotV3")
        RunService:UnbindFromRenderStep("OrionV3AimAssist")
    end)

    if MiraConnection then
        pcall(function() MiraConnection:Disconnect() end)
        MiraConnection = nil
    end

    -- Restaurar Fullbright si estaba activo.
    pcall(function()
        Lighting.Ambient = savedLighting.Ambient
        Lighting.ColorShift_Bottom = savedLighting.ColorShift_Bottom
        Lighting.ColorShift_Top = savedLighting.ColorShift_Top
    end)

    -- Restaurar colisiones.
    pcall(function()
        local character = Player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)

    -- Limpiar GUIs del V2.
    for _, name in ipairs({
        "RaulsRivalsModdedHub",
        "RGBFanCrosshair",
        "RivalsCopyWeather",
        "SimpleFly",
        "RaulsSpinBot",
        "NoclipRivalsCopy",
        "OrionV3AimFOV",
    }) do
        local old = PlayerGui:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
end

local function BuildAccessGate()
    local GateGui = Instance.new("ScreenGui")
    GateGui.Name = "RaulsRivalsModdedAccess"
    GateGui.ResetOnSpawn = false
    GateGui.IgnoreGuiInset = true
    GateGui.DisplayOrder = 10000
    GateGui.Parent = PlayerGui

    local Back = Instance.new("Frame")
    Back.Size = UDim2.fromScale(1,1)
    Back.BackgroundColor3 = Color3.fromRGB(1,0,3)
    Back.BorderSizePixel = 0
    Back.Parent = GateGui

    local Outer = Instance.new("Frame")
    Outer.Size = UDim2.fromOffset(620,520)
    Outer.Position = UDim2.new(.5,-310,.5,-260)
    Outer.BackgroundColor3 = Color3.fromRGB(155,0,255)
    Outer.BorderSizePixel = 0
    Outer.Parent = Back

    local Inner = Instance.new("Frame")
    Inner.Size = UDim2.new(1,-10,1,-10)
    Inner.Position = UDim2.fromOffset(5,5)
    Inner.BackgroundColor3 = Color3.fromRGB(5,0,8)
    Inner.BorderSizePixel = 0
    Inner.Parent = Outer

    local Top = Instance.new("Frame")
    Top.Size = UDim2.new(1,-20,0,78)
    Top.Position = UDim2.fromOffset(10,10)
    Top.BackgroundColor3 = Color3.fromRGB(3,0,5)
    Top.BorderSizePixel = 0
    Top.Parent = Inner

    local TopStroke = Instance.new("UIStroke")
    TopStroke.Color = Color3.fromRGB(190,50,255)
    TopStroke.Thickness = 1
    TopStroke.Parent = Top

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1,-30,1,0)
    Title.Position = UDim2.fromOffset(15,0)
    Title.BackgroundTransparency = 1
    Title.Text = "ORION"
    Title.TextColor3 = Color3.fromRGB(250,240,255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 25
    Title.TextXAlignment = Enum.TextXAlignment.Center
    Title.Parent = Top

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1,-30,0,22)
    Subtitle.Position = UDim2.fromOffset(15,92)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "SISTEMA DE ACCESO // V3"
    Subtitle.TextColor3 = Color3.fromRGB(190,50,255)
    Subtitle.Font = Enum.Font.Code
    Subtitle.TextSize = 11
    Subtitle.TextXAlignment = Enum.TextXAlignment.Center
    Subtitle.Parent = Inner

    local Prompt = Instance.new("TextLabel")
    Prompt.Size = UDim2.new(1,-50,0,25)
    Prompt.Position = UDim2.fromOffset(25,125)
    Prompt.BackgroundTransparency = 1
    Prompt.Text = "PONER CONTRASEÑA"
    Prompt.TextColor3 = Color3.fromRGB(248,238,255)
    Prompt.Font = Enum.Font.GothamBold
    Prompt.TextSize = 15
    Prompt.TextXAlignment = Enum.TextXAlignment.Left
    Prompt.Parent = Inner

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1,-50,0,48)
    Box.Position = UDim2.fromOffset(25,157)
    Box.BackgroundColor3 = Color3.fromRGB(10,0,17)
    Box.BorderColor3 = Color3.fromRGB(145,0,255)
    Box.BorderSizePixel = 1
    Box.ClearTextOnFocus = false
    Box.PlaceholderText = "6 DÍGITOS"
    Box.PlaceholderColor3 = Color3.fromRGB(140,80,180)
    Box.Text = ""
    Box.TextColor3 = Color3.fromRGB(250,240,255)
    Box.Font = Enum.Font.Code
    Box.TextSize = 21
    Box.TextXAlignment = Enum.TextXAlignment.Center
    Box.Parent = Inner

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1,-50,0,22)
    Status.Position = UDim2.fromOffset(25,211)
    Status.BackgroundTransparency = 1
    Status.Text = "ESCRIBE EXACTAMENTE 6 DÍGITOS"
    Status.TextColor3 = Color3.fromRGB(190,135,230)
    Status.Font = Enum.Font.Code
    Status.TextSize = 10
    Status.TextXAlignment = Enum.TextXAlignment.Center
    Status.Parent = Inner

    local Enter = Instance.new("TextButton")
    Enter.Size = UDim2.new(1,-50,0,45)
    Enter.Position = UDim2.fromOffset(25,242)
    Enter.BackgroundColor3 = Color3.fromRGB(70,0,110)
    Enter.BorderColor3 = Color3.fromRGB(190,50,255)
    Enter.BorderSizePixel = 1
    Enter.Text = "ENTRAR"
    Enter.TextColor3 = Color3.fromRGB(250,240,255)
    Enter.Font = Enum.Font.GothamBold
    Enter.TextSize = 14
    Enter.Parent = Inner

    local Quick = Instance.new("TextButton")
    Quick.Size = UDim2.new(1,-50,0,42)
    Quick.Position = UDim2.fromOffset(25,295)
    Quick.BackgroundColor3 = Color3.fromRGB(12,0,20)
    Quick.BorderColor3 = Color3.fromRGB(120,0,200)
    Quick.BorderSizePixel = 1
    Quick.Text = "ACCESO RÁPIDO"
    Quick.TextColor3 = Color3.fromRGB(220,180,255)
    Quick.Font = Enum.Font.Code
    Quick.TextSize = 13
    Quick.Parent = Inner

    local Free = Instance.new("TextButton")
    Free.Size = UDim2.new(1,-50,0,38)
    Free.Position = UDim2.fromOffset(25,345)
    Free.BackgroundTransparency = 1
    Free.Text = "OBTÉN TU CONTRASEÑA GRATIS"
    Free.TextColor3 = Color3.fromRGB(190,50,255)
    Free.Font = Enum.Font.GothamBold
    Free.TextSize = 13
    Free.Parent = Inner

    local Mini = Instance.new("Frame")
    Mini.Size = UDim2.fromOffset(590,230)
    Mini.Position = UDim2.new(.5,-295,.5,-115)
    Mini.BackgroundColor3 = Color3.fromRGB(4,0,7)
    Mini.BorderColor3 = Color3.fromRGB(155,0,255)
    Mini.BorderSizePixel = 2
    Mini.Visible = false
    Mini.Parent = Back

    local MiniTitle = Instance.new("TextLabel")
    MiniTitle.Size = UDim2.new(1,-20,0,30)
    MiniTitle.Position = UDim2.fromOffset(10,10)
    MiniTitle.BackgroundTransparency = 1
    MiniTitle.Text = "OBTENER LLAVE DE ACCESO GRATIS"
    MiniTitle.TextColor3 = Color3.fromRGB(250,240,255)
    MiniTitle.Font = Enum.Font.GothamBold
    MiniTitle.TextSize = 17
    MiniTitle.Parent = Mini

    local MiniText = Instance.new("TextLabel")
    MiniText.Size = UDim2.new(1,-40,0,25)
    MiniText.Position = UDim2.fromOffset(20,62)
    MiniText.BackgroundTransparency = 1
    MiniText.Text = "MANDAR SOLICITUD PARA OBTENER LLAVE A ESTE NÚMERO:"
    MiniText.TextColor3 = Color3.fromRGB(235,215,250)
    MiniText.Font = Enum.Font.GothamBold
    MiniText.TextSize = 12
    MiniText.TextXAlignment = Enum.TextXAlignment.Left
    MiniText.Parent = Mini

    local Number = Instance.new("TextBox")
    Number.Size = UDim2.new(1,-150,0,38)
    Number.Position = UDim2.fromOffset(20,105)
    Number.BackgroundColor3 = Color3.fromRGB(9,0,15)
    Number.BorderColor3 = Color3.fromRGB(90,0,150)
    Number.BorderSizePixel = 1
    Number.Text = FREE_NUMBER
    Number.TextColor3 = Color3.fromRGB(250,240,255)
    Number.Font = Enum.Font.Code
    Number.TextSize = 16
    Number.ClearTextOnFocus = false
    Number.TextEditable = false
    Number.TextXAlignment = Enum.TextXAlignment.Left
    Number.Parent = Mini

    local Copy = Instance.new("TextButton")
    Copy.Size = UDim2.fromOffset(105,38)
    Copy.Position = UDim2.new(1,-125,0,105)
    Copy.BackgroundColor3 = Color3.fromRGB(70,0,110)
    Copy.BorderColor3 = Color3.fromRGB(190,50,255)
    Copy.BorderSizePixel = 1
    Copy.Text = "COPIAR"
    Copy.TextColor3 = Color3.fromRGB(250,240,255)
    Copy.Font = Enum.Font.GothamBold
    Copy.TextSize = 12
    Copy.Parent = Mini

    local CloseMini = Instance.new("TextButton")
    CloseMini.Size = UDim2.fromOffset(24,24)
    CloseMini.Position = UDim2.new(1,-34,0,8)
    CloseMini.BackgroundColor3 = Color3.fromRGB(15,0,25)
    CloseMini.BorderColor3 = Color3.fromRGB(120,0,200)
    CloseMini.Text = "X"
    CloseMini.TextColor3 = Color3.fromRGB(230,190,255)
    CloseMini.Font = Enum.Font.GothamBold
    CloseMini.TextSize = 11
    CloseMini.Parent = Mini

    local function Grant(mode, duration)
        if AccessMode ~= nil then return end
        AccessMode = mode
        AccessDuration = duration
        AccessStart = os.clock()
        accessGranted = true
        GateGui:Destroy()
    end

    Box:GetPropertyChangedSignal("Text"):Connect(function()
        local clean = Box.Text:gsub("%D","")
        if #clean > 6 then clean = clean:sub(1,6) end
        if clean ~= Box.Text then Box.Text = clean end
    end)

    local function TryPassword()
        local key = Box.Text
        if #key ~= 6 or key:match("^%d%d%d%d%d%d$") == nil then
            Status.Text = "LA CONTRASEÑA DEBE TENER 6 DÍGITOS"
            Status.TextColor3 = Color3.fromRGB(205,60,255)
            return
        end

        -- 170414 is intentionally not displayed anywhere in the UI.
        if key == INFINITE_KEY then
            Grant("INFINITE", math.huge)
            return
        end

        Grant("6H", 6*60*60)
    end

    Enter.MouseButton1Click:Connect(TryPassword)

    Box.FocusLost:Connect(function(enterPressed)
        if enterPressed then TryPassword() end
    end)

    Quick.MouseButton1Click:Connect(function()
        Grant("QUICK", 20*60)
    end)

    Free.MouseButton1Click:Connect(function()
        Mini.Visible = not Mini.Visible
        if Mini.Visible then
            Free.Text = "CERRAR SOLICITUD"
        else
            Free.Text = "OBTÉN TU CONTRASEÑA GRATIS"
        end
    end)

    CloseMini.MouseButton1Click:Connect(function()
        Mini.Visible = false
        Free.Text = "OBTÉN TU CONTRASEÑA GRATIS"
    end)

    Copy.MouseButton1Click:Connect(function()
        local copied = false
        pcall(function()
            if setclipboard then
                setclipboard(FREE_NUMBER)
                copied = true
            end
        end)
        if copied then
            Copy.Text = "COPIADO ✓"
            task.delay(1.2, function()
                if Copy.Parent then Copy.Text = "COPIAR" end
            end)
        else
            Number:CaptureFocus()
            Number.SelectionStart = 1
            Number.CursorPosition = #FREE_NUMBER + 1
            Copy.Text = "SELECCIONADO"
            task.delay(1.2, function()
                if Copy.Parent then Copy.Text = "COPIAR" end
            end)
        end
    end)

    return GateGui
end

BuildAccessGate()

while not accessGranted and SessionActive do
    RunService.RenderStepped:Wait()
end

if not SessionActive then
    return
end

local AccessGui = PlayerGui:FindFirstChild("RaulsRivalsModdedAccess")
if AccessGui then AccessGui:Destroy() end

if AccessMode ~= "INFINITE" then
    task.spawn(function()
        local remaining = AccessDuration
        while SessionActive and remaining > 0 do
            task.wait(1)
            remaining -= 1
        end
        if SessionActive and remaining <= 0 then
            DestroyV2()
        end
    end)
end


--============================================================--
-- LIMPIEZA
--============================================================--

for _, name in ipairs({
	"RaulsRivalsModdedHub",
	"RGBFanCrosshair",
	"RivalsCopyWeather",
	"SimpleFly",
	"RaulsSpinBot",
	"NoclipRivalsCopy",
}) do
	local old = PlayerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

--============================================================--
-- PALETA
--============================================================--

local BLACK = Color3.fromRGB(3, 0, 6)
local BLACK2 = Color3.fromRGB(9, 2, 16)
local BLACK3 = Color3.fromRGB(15, 3, 25)
local PURPLE = Color3.fromRGB(145, 0, 255)
local PURPLE2 = Color3.fromRGB(190, 50, 255)
local PURPLE_DARK = Color3.fromRGB(70, 0, 110)
local TEXT = Color3.fromRGB(248, 238, 255)
local MUTED = Color3.fromRGB(185, 135, 225)
local RED = Color3.fromRGB(180, 0, 255)
local GREEN = Color3.fromRGB(170, 0, 255)

local FONT = Enum.Font.Code

--============================================================--
-- GUI PRINCIPAL
--============================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "RaulsRivalsModdedHub"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.fromOffset(720, 500)
Main.Position = UDim2.new(0.5, -360, 0.5, -250)
Main.BackgroundColor3 = BLACK
Main.BorderColor3 = PURPLE_DARK
Main.BorderSizePixel = 1
Main.Active = true
Main.Parent = Gui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = PURPLE
MainStroke.Thickness = 1
MainStroke.Transparency = 0.35
MainStroke.Parent = Main

--============================================================--
-- HEADER
--============================================================--

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = BLACK2
Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = Main

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(0, 4, 1, 0)
Accent.BackgroundColor3 = PURPLE2
Accent.BorderSizePixel = 0
Accent.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 28)
Title.Position = UDim2.fromOffset(16, 7)
Title.BackgroundTransparency = 1
Title.Text = "ORION"
Title.TextColor3 = TEXT
Title.TextSize = 20
Title.Font = FONT
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -30, 0, 18)
Subtitle.Position = UDim2.fromOffset(17, 33)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "LOCAL SYSTEM // R6 / R15"
Subtitle.TextColor3 = MUTED
Subtitle.TextSize = 10
Subtitle.Font = FONT
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CtrlHint = Instance.new("TextLabel")
CtrlHint.Size = UDim2.fromOffset(180, 20)
CtrlHint.Position = UDim2.new(1, -195, 0, 19)
CtrlHint.BackgroundTransparency = 1
CtrlHint.Text = "LEFT CTRL // TOGGLE PANEL"
CtrlHint.TextColor3 = MUTED
CtrlHint.TextSize = 10
CtrlHint.Font = FONT
CtrlHint.TextXAlignment = Enum.TextXAlignment.Right
CtrlHint.Parent = Header

local AccessTimer = Instance.new("TextLabel")
AccessTimer.Size = UDim2.fromOffset(170, 18)
AccessTimer.Position = UDim2.new(1, -185, 0, 39)
AccessTimer.BackgroundTransparency = 1
AccessTimer.Text = "ACCESS // 06:00:00"
AccessTimer.TextColor3 = PURPLE2
AccessTimer.TextSize = 9
AccessTimer.Font = FONT
AccessTimer.TextXAlignment = Enum.TextXAlignment.Right
AccessTimer.Parent = Header

task.spawn(function()
    while SessionActive and AccessTimer.Parent do
        if AccessMode == "INFINITE" then
            AccessTimer.Text = "ACCESS // UNLIMITED"
        else
            local left = math.max(0, math.floor(AccessDuration - (os.clock() - AccessStart)))
            local h = math.floor(left / 3600)
            local m = math.floor((left % 3600) / 60)
            local s = left % 60
            AccessTimer.Text = string.format("ACCESS // %02d:%02d:%02d", h, m, s)
            if left <= 0 then break end
        end
        task.wait(1)
    end
end)


--============================================================--
-- SIDEBAR
--============================================================--

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 175, 1, -58)
Sidebar.Position = UDim2.fromOffset(0, 58)
Sidebar.BackgroundColor3 = BLACK2
Sidebar.BorderColor3 = Color3.fromRGB(30, 0, 50)
Sidebar.BorderSizePixel = 1
Sidebar.Parent = Main

local SideTitle = Instance.new("TextLabel")
SideTitle.Size = UDim2.new(1, -20, 0, 24)
SideTitle.Position = UDim2.fromOffset(10, 12)
SideTitle.BackgroundTransparency = 1
SideTitle.Text = "MODULES"
SideTitle.TextColor3 = PURPLE2
SideTitle.TextSize = 12
SideTitle.Font = FONT
SideTitle.TextXAlignment = Enum.TextXAlignment.Left
SideTitle.Parent = Sidebar

local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(1, -20, 1, -50)
TabHolder.Position = UDim2.fromOffset(10, 42)
TabHolder.BackgroundTransparency = 1
TabHolder.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabHolder

--============================================================--
-- CONTENT
--============================================================--

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -175, 1, -58)
Content.Position = UDim2.fromOffset(175, 58)
Content.BackgroundColor3 = BLACK
Content.BorderSizePixel = 0
Content.Parent = Main

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -30, 0, 30)
PageTitle.Position = UDim2.fromOffset(15, 12)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "SIMPLE FLY"
PageTitle.TextColor3 = TEXT
PageTitle.TextSize = 18
PageTitle.Font = FONT
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = Content

local PageSub = Instance.new("TextLabel")
PageSub.Size = UDim2.new(1, -30, 0, 20)
PageSub.Position = UDim2.fromOffset(15, 39)
PageSub.BackgroundTransparency = 1
PageSub.Text = "FLIGHT CONTROL // LOCAL"
PageSub.TextColor3 = MUTED
PageSub.TextSize = 10
PageSub.Font = FONT
PageSub.TextXAlignment = Enum.TextXAlignment.Left
PageSub.Parent = Content

local Pages = {}
local Tabs = {}

local function CreatePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, -30, 1, -78)
	page.Position = UDim2.fromOffset(15, 68)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = PURPLE
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	Pages[name] = page
	return page
end

local function CreateTab(name, label)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = BLACK3
	button.BorderColor3 = Color3.fromRGB(40, 0, 65)
	button.BorderSizePixel = 1
	button.Text = label
	button.TextColor3 = MUTED
	button.TextSize = 13
	button.Font = FONT
	button.AutoButtonColor = false
	button.Parent = TabHolder

	button.MouseButton1Click:Connect(function()
		for n, p in pairs(Pages) do
			p.Visible = (n == name)
		end

		for _, b in pairs(Tabs) do
			b.BackgroundColor3 = BLACK3
			b.TextColor3 = MUTED
			b.BorderColor3 = Color3.fromRGB(40, 0, 65)
		end

		button.BackgroundColor3 = PURPLE_DARK
		button.TextColor3 = TEXT
		button.BorderColor3 = PURPLE

		PageTitle.Text = label
		PageSub.Text = "ORION SYSTEM // " .. string.upper(name)
	end)

	Tabs[name] = button
	return button
end

local function MakeSection(parent, title, subtitle)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -4, 0, subtitle and 74 or 54)
	box.BackgroundColor3 = BLACK2
	box.BorderColor3 = Color3.fromRGB(45, 0, 75)
	box.BorderSizePixel = 1
	box.Parent = parent

	local line = Instance.new("Frame")
	line.Size = UDim2.fromOffset(3, box.Size.Y.Offset)
	line.BackgroundColor3 = PURPLE
	line.BorderSizePixel = 0
	line.Parent = box

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -28, 0, 24)
	t.Position = UDim2.fromOffset(14, 8)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = TEXT
	t.TextSize = 14
	t.Font = FONT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = box

	if subtitle then
		local s = Instance.new("TextLabel")
		s.Size = UDim2.new(1, -28, 0, 30)
		s.Position = UDim2.fromOffset(14, 32)
		s.BackgroundTransparency = 1
		s.Text = subtitle
		s.TextColor3 = MUTED
		s.TextSize = 11
		s.Font = FONT
		s.TextWrapped = true
		s.TextXAlignment = Enum.TextXAlignment.Left
		s.Parent = box
	end

	return box
end

local function MakeButton(parent, text, height)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, height or 42)
	b.BackgroundColor3 = BLACK3
	b.BorderColor3 = Color3.fromRGB(60, 0, 95)
	b.BorderSizePixel = 1
	b.Text = text
	b.TextColor3 = TEXT
	b.TextSize = 13
	b.Font = FONT
	b.AutoButtonColor = false
	b.Parent = parent

	b.MouseEnter:Connect(function()
		b.BorderColor3 = PURPLE
	end)

	b.MouseLeave:Connect(function()
		b.BorderColor3 = Color3.fromRGB(60, 0, 95)
	end)

	return b
end

local function SetButtonState(button, enabled, onText, offText)
	if enabled then
		button.Text = onText or "[ ON ]"
		button.BackgroundColor3 = PURPLE_DARK
		button.BorderColor3 = PURPLE2
		button.TextColor3 = TEXT
	else
		button.Text = offText or "[ OFF ]"
		button.BackgroundColor3 = BLACK3
		button.BorderColor3 = Color3.fromRGB(60, 0, 95)
		button.TextColor3 = MUTED
	end
end

--============================================================--
-- PÁGINAS
--============================================================--

local FlyPage = CreatePage("FLY")
local SpinPage = CreatePage("SPIN")
local VisualPage = CreatePage("VISUAL")
local MovementPage = CreatePage("MOVEMENT")
local TPPage = CreatePage("TP")
local AimPage = CreatePage("AIM")
local WeatherPage = CreatePage("WEATHER")

CreateTab("FLY", "01 // SIMPLE FLY")
CreateTab("SPIN", "02 // BOT DE GIRO")
CreateTab("VISUAL", "03 // VISUAL")
CreateTab("MOVEMENT", "04 // MOVEMENT")
CreateTab("TP", "05 // TELEPORT")
CreateTab("AIM", "06 // AIM ASSIST")
CreateTab("WEATHER", "07 // WEATHER")

--============================================================--
-- SIMPLE FLY
--============================================================--

local FlyEnabled = false
local FlySpeed = 200
local MIN_SPEED = 50
local MAX_SPEED = 800
local FlyCharacter, FlyHumanoid, FlyRoot

local function GetFlyCharacter()
	FlyCharacter = Player.Character
	if not FlyCharacter then return false end
	FlyHumanoid = FlyCharacter:FindFirstChildOfClass("Humanoid")
	FlyRoot = FlyCharacter:FindFirstChild("HumanoidRootPart")
	return FlyHumanoid ~= nil and FlyRoot ~= nil
end

local flyBox = MakeSection(FlyPage, "SIMPLE FLY", "LOCAL FLIGHT SYSTEM // R6/R15")
local flyToggle = MakeButton(FlyPage, "[ ACTIVATE FLY ]")
local flyStatus = MakeSection(FlyPage, "STATUS // OFFLINE", "W / A / S / D = MOVE    |    SPACE = UP    |    C = DOWN    |    Z = TOGGLE FLY")

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -4, 0, 24)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "VELOCITY    //    200"
speedLabel.TextColor3 = TEXT
speedLabel.TextSize = 12
speedLabel.Font = FONT
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = FlyPage

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.new(1, -4, 0, 8)
speedBar.BackgroundColor3 = Color3.fromRGB(35, 0, 60)
speedBar.BorderSizePixel = 0
speedBar.Parent = FlyPage

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new((FlySpeed-MIN_SPEED)/(MAX_SPEED-MIN_SPEED), 0, 1, 0)
speedFill.BackgroundColor3 = PURPLE
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar

local speedKnob = Instance.new("Frame")
speedKnob.Size = UDim2.fromOffset(16,16)
speedKnob.AnchorPoint = Vector2.new(.5,.5)
speedKnob.Position = UDim2.new((FlySpeed-MIN_SPEED)/(MAX_SPEED-MIN_SPEED),0,.5,0)
speedKnob.BackgroundColor3 = PURPLE2
speedKnob.BorderSizePixel = 0
speedKnob.Parent = speedBar

local speedDragging = false

local function UpdateFlySpeed(x)
	local rel = math.clamp((x-speedBar.AbsolutePosition.X)/math.max(speedBar.AbsoluteSize.X,1),0,1)
	FlySpeed = MIN_SPEED + (MAX_SPEED-MIN_SPEED)*rel
	speedFill.Size = UDim2.new(rel,0,1,0)
	speedKnob.Position = UDim2.new(rel,0,.5,0)
	speedLabel.Text = "VELOCITY    //    " .. math.floor(FlySpeed)
end

speedBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		speedDragging = true
		UpdateFlySpeed(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		UpdateFlySpeed(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		speedDragging = false
	end
end)

local flyKeys = {W=false,A=false,S=false,D=false,Space=false,C=false}

local function SetFlyStatus(on)
	FlyEnabled = on
	if on then
		SetButtonState(flyToggle,true,"[ DEACTIVATE FLY ]","[ ACTIVATE FLY ]")
		flyStatus:FindFirstChildOfClass("TextLabel").Text = "STATUS // ONLINE"
	else
		SetButtonState(flyToggle,false,"[ DEACTIVATE FLY ]","[ ACTIVATE FLY ]")
		flyStatus:FindFirstChildOfClass("TextLabel").Text = "STATUS // OFFLINE"
		if FlyRoot then FlyRoot.AssemblyLinearVelocity = Vector3.zero end
	end
end

flyToggle.MouseButton1Click:Connect(function()
	if not FlyEnabled then
		if GetFlyCharacter() then SetFlyStatus(true) end
	else
		SetFlyStatus(false)
	end
end)

--============================================================--
-- BOT DE GIRO // V3 UNIVERSAL R6 / R15
--============================================================--
--
-- IMPORTANTE:
-- Este bloque ya no depende de "Torso", por lo que funciona con
-- R6 y R15. Se buscan los Motor6D del personaje por nombre y se
-- conserva su Transform original para poder restaurarlos.
--
-- La parte visual del movimiento completo se calcula localmente.
-- Un LocalScript NO puede obligar al servidor de una experiencia
-- ajena a replicar Motor6D.Transform. Si la experiencia es tuya,
-- la replicación real debe hacerse desde el servidor.
--============================================================--

local SpinEnabled = false
local ForwardSpeed = 1500
local SideSpeed = 1500
local Separation = 50

local SpinCharacter
local SpinHumanoid
local SpinRoot
local SpinTorso

-- Tabla universal de articulaciones.
-- R6 y R15 comparten varios nombres conceptuales, aunque R6
-- contiene además nombres con espacios.
local SpinJoints = {}
local OriginalJointTransforms = {}
local SpinJointNames = {
    "RootJoint",
    "Root",
    "Waist",
    "Neck",
    "Left Shoulder",
    "Right Shoulder",
    "Left Hip",
    "Right Hip",
    "LeftShoulder",
    "RightShoulder",
    "LeftHip",
    "RightHip",
    "LeftElbow",
    "RightElbow",
    "LeftWrist",
    "RightWrist",
    "LeftKnee",
    "RightKnee",
    "LeftAnkle",
    "RightAnkle",
    "LeftFoot",
    "RightFoot",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftUpperLeg",
    "RightUpperLeg",
}

local Pitch = 0
local Yaw = 0
local SpinTime = 0

local spinPageInfo = MakeSection(
    SpinPage,
    "BOT DE GIRO",
    "UNIVERSAL R6 / R15 // CUERPO COMPLETO // VELOCITY CONTROL"
)

local spinToggle = MakeButton(SpinPage, "[ ACTIVATE SPIN BOT ]", 48)

local spinInfo = MakeSection(
    SpinPage,
    "MODO UNIVERSAL",
    "R6 + R15 // BRAZOS + PIERNAS + CINTURA + CUELLO + CUERPO COMPLETO"
)

local spinReplicationInfo = MakeSection(
    SpinPage,
    "REPLICACIÓN",
    "MOVIMIENTO LOCAL COMPLETO // LA VISIBILIDAD PARA OTROS JUGADORES DEPENDE DEL SERVIDOR"
)

local function ClearSpinJointCache()
    table.clear(SpinJoints)
    table.clear(OriginalJointTransforms)
end

local function RegisterSpinJoint(motor)
    if not motor:IsA("Motor6D") then
        return
    end

    local name = motor.Name
    if not name then
        return
    end

    SpinJoints[name] = motor
    if OriginalJointTransforms[name] == nil then
        OriginalJointTransforms[name] = motor.Transform
    end
end

local function ScanSpinJoints()
    ClearSpinJointCache()

    if not SpinCharacter then
        return
    end

    -- Primero registramos absolutamente todos los Motor6D.
    -- Esto permite mover articulaciones que no estén en la lista.
    for _, obj in ipairs(SpinCharacter:GetDescendants()) do
        if obj:IsA("Motor6D") then
            RegisterSpinJoint(obj)
        end
    end
end

local function FindSpinJoint(...)
    local candidates = {...}

    for _, candidate in ipairs(candidates) do
        local joint = SpinJoints[candidate]
        if joint and joint.Parent then
            return joint
        end
    end

    -- Segundo intento: comparación normalizada para R6/R15.
    local wanted = {}
    for _, candidate in ipairs(candidates) do
        wanted[string.lower(candidate):gsub("[%s_%-]", "")] = true
    end

    for name, joint in pairs(SpinJoints) do
        local normalized = string.lower(name):gsub("[%s_%-]", "")
        if wanted[normalized] and joint and joint.Parent then
            return joint
        end
    end

    return nil
end

local function GetSpinCharacter()
    SpinCharacter = Player.Character
    if not SpinCharacter then
        return false
    end

    SpinHumanoid = SpinCharacter:FindFirstChildOfClass("Humanoid")
    SpinRoot = SpinCharacter:FindFirstChild("HumanoidRootPart")
    SpinTorso = SpinCharacter:FindFirstChild("Torso")
        or SpinCharacter:FindFirstChild("UpperTorso")
        or SpinCharacter:FindFirstChild("LowerTorso")

    if not SpinHumanoid or not SpinRoot then
        return false
    end

    ScanSpinJoints()

    -- Exponemos los nombres clásicos para que el resto del V3
    -- pueda tratarlos de la misma forma en R6 y R15.
    return true
end

local function CaptureCurrentSpinTransforms()
    if not SpinCharacter then
        return
    end

    for name, motor in pairs(SpinJoints) do
        if motor and motor.Parent then
            OriginalJointTransforms[name] = motor.Transform
        end
    end
end

local function ResetSpinLimbs()
    for name, motor in pairs(SpinJoints) do
        if motor and motor.Parent then
            local original = OriginalJointTransforms[name]
            if original then
                motor.Transform = original
            else
                motor.Transform = CFrame.identity
            end
        end
    end
end

local function ApplyJointOffset(candidates, offset)
    local joint = FindSpinJoint(table.unpack(candidates))
    if joint then
        local original = OriginalJointTransforms[joint.Name] or CFrame.identity
        joint.Transform = original * offset
    end
end

local function SeparateSpinLimbs()
    if not SpinEnabled or not SpinCharacter then
        return
    end

    -- La separación ahora usa una escala más visible y consistente.
    -- 0 = pegado al cuerpo; 100 = separación máxima.
    local normalized = math.clamp(Separation / 100, 0, 1)
    local armDistance = 1.25 + (6.25 * normalized)
    local legDistance = 1.00 + (5.00 * normalized)
    local handDistance = 0.65 + (2.50 * normalized)
    local footDistance = 0.50 + (2.00 * normalized)

    -- HOMBROS: mueve TODO el brazo desde la unión al torso.
    ApplyJointOffset(
        {"Left Shoulder", "LeftShoulder"},
        CFrame.new(-armDistance, 0, 0)
    )

    ApplyJointOffset(
        {"Right Shoulder", "RightShoulder"},
        CFrame.new(armDistance, 0, 0)
    )

    -- CODOS / MUÑECAS: refuerzan el efecto en R15.
    ApplyJointOffset(
        {"LeftElbow"},
        CFrame.new(-handDistance, 0, 0)
    )

    ApplyJointOffset(
        {"RightElbow"},
        CFrame.new(handDistance, 0, 0)
    )

    ApplyJointOffset(
        {"LeftWrist"},
        CFrame.new(-handDistance * 0.55, 0, 0)
    )

    ApplyJointOffset(
        {"RightWrist"},
        CFrame.new(handDistance * 0.55, 0, 0)
    )

    -- CADERAS: mueve TODA la pierna desde el torso.
    ApplyJointOffset(
        {"Left Hip", "LeftHip"},
        CFrame.new(-legDistance, 0, 0)
    )

    ApplyJointOffset(
        {"Right Hip", "RightHip"},
        CFrame.new(legDistance, 0, 0)
    )

    -- RODILLAS / TOBILLOS: refuerzan la separación en R15.
    ApplyJointOffset(
        {"LeftKnee"},
        CFrame.new(-footDistance, 0, 0)
    )

    ApplyJointOffset(
        {"RightKnee"},
        CFrame.new(footDistance, 0, 0)
    )

    ApplyJointOffset(
        {"LeftAnkle", "LeftFoot"},
        CFrame.new(-footDistance * 0.50, 0, 0)
    )

    ApplyJointOffset(
        {"RightAnkle", "RightFoot"},
        CFrame.new(footDistance * 0.50, 0, 0)
    )
end

local function ApplyFullBodySpinPose(dt)
    if not SpinEnabled or not SpinCharacter then
        return
    end

    SpinTime += dt

    -- Oscilaciones suaves para que no se mueva únicamente el root.
    local wave = math.sin(SpinTime * 10)
    local wave2 = math.sin(SpinTime * 13 + 0.7)
    local wave3 = math.cos(SpinTime * 8 + 1.2)

    local bodyPitch = math.sin(Pitch) * 0.18
    local bodyRoll = math.sin(Yaw * 0.5) * 0.12

    -- Cintura / torso.
    ApplyJointOffset(
        {"Waist", "RootJoint", "Root"},
        CFrame.Angles(bodyPitch + wave * 0.10, 0, bodyRoll)
    )

    -- Cuello.
    ApplyJointOffset(
        {"Neck"},
        CFrame.Angles(wave2 * 0.20, wave * 0.15, wave3 * 0.16)
    )

    -- Hombros.
    ApplyJointOffset(
        {"Left Shoulder", "LeftShoulder"},
        CFrame.Angles(wave * 0.32, 0, -math.rad(Separation * 0.12))
    )

    ApplyJointOffset(
        {"Right Shoulder", "RightShoulder"},
        CFrame.Angles(-wave * 0.32, 0, math.rad(Separation * 0.12))
    )

    -- Codos / muñecas si el rig es R15.
    ApplyJointOffset(
        {"LeftElbow"},
        CFrame.Angles(wave2 * 0.35, 0, 0)
    )

    ApplyJointOffset(
        {"RightElbow"},
        CFrame.Angles(-wave2 * 0.35, 0, 0)
    )

    ApplyJointOffset(
        {"LeftWrist"},
        CFrame.Angles(wave3 * 0.22, wave * 0.10, 0)
    )

    ApplyJointOffset(
        {"RightWrist"},
        CFrame.Angles(-wave3 * 0.22, -wave * 0.10, 0)
    )

    -- Caderas y rodillas.
    ApplyJointOffset(
        {"Left Hip", "LeftHip"},
        CFrame.Angles(-wave2 * 0.22, 0, 0)
    )

    ApplyJointOffset(
        {"Right Hip", "RightHip"},
        CFrame.Angles(wave2 * 0.22, 0, 0)
    )

    ApplyJointOffset(
        {"LeftKnee"},
        CFrame.Angles(wave * 0.30, 0, 0)
    )

    ApplyJointOffset(
        {"RightKnee"},
        CFrame.Angles(-wave * 0.30, 0, 0)
    )

    -- Tobillos si existen.
    ApplyJointOffset(
        {"LeftAnkle", "LeftFoot"},
        CFrame.Angles(wave3 * 0.18, 0, 0)
    )

    ApplyJointOffset(
        {"RightAnkle", "RightFoot"},
        CFrame.Angles(-wave3 * 0.18, 0, 0)
    )

    SeparateSpinLimbs()
end

local function MakeSpinSlider(parent, label, min, max, value, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,-4,0,58)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1,0,0,20)
    lab.BackgroundTransparency = 1
    lab.Text = label .. ": " .. math.floor(value)
    lab.TextColor3 = TEXT
    lab.TextSize = 12
    lab.Font = FONT
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,0,7)
    bar.Position = UDim2.fromOffset(0,32)
    bar.BackgroundColor3 = Color3.fromRGB(35,0,60)
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = holder

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = PURPLE
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14,14)
    knob.AnchorPoint = Vector2.new(.5,.5)
    knob.Position = UDim2.new((value-min)/(max-min),0,.5,0)
    knob.BackgroundColor3 = PURPLE2
    knob.BorderSizePixel = 0
    knob.Parent = bar

    local dragging = false

    local function setValue(x)
        local rel = math.clamp(
            (x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),
            0,
            1
        )

        local v = min + (max-min)*rel

        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,.5,0)
        lab.Text = label .. ": " .. math.floor(v)

        callback(v)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValue(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setValue(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

MakeSpinSlider(
    SpinPage,
    "ADELANTE / ATRÁS",
    1500,
    3500,
    ForwardSpeed,
    function(v)
        ForwardSpeed = v
        if SpinEnabled then
            FireOrionServer("SpinConfig", {ForwardSpeed = ForwardSpeed, SideSpeed = SideSpeed, Separation = Separation})
        end
    end
)

MakeSpinSlider(
    SpinPage,
    "LADOS",
    1500,
    3500,
    SideSpeed,
    function(v)
        SideSpeed = v
        if SpinEnabled then
            FireOrionServer("SpinConfig", {ForwardSpeed = ForwardSpeed, SideSpeed = SideSpeed, Separation = Separation})
        end
    end
)

MakeSpinSlider(
    SpinPage,
    "SEPARACIÓN",
    0,
    100,
    Separation,
    function(v)
        Separation = v
        if SpinEnabled then
            FireOrionServer("SpinConfig", {ForwardSpeed = ForwardSpeed, SideSpeed = SideSpeed, Separation = Separation})
        end
    end
)

local function SetSpinButtonText(text)
    if spinToggle and spinToggle.Parent then
        spinToggle.Text = text
    end
end

local function ActivateSpin()
    if SpinEnabled then
        return
    end

    if not GetSpinCharacter() then
        SetSpinButtonText("[ CHARACTER NOT READY ]")

        task.delay(1.2, function()
            if spinToggle and spinToggle.Parent and not SpinEnabled then
                SetSpinButtonText("[ ACTIVATE SPIN BOT ]")
            end
        end)

        return
    end

    CaptureCurrentSpinTransforms()

    SpinEnabled = true
    FireOrionServer("SpinStart", {
        Separation = Separation,
        ForwardSpeed = ForwardSpeed,
        SideSpeed = SideSpeed,
    })
    Pitch = 0
    Yaw = 0
    SpinTime = 0

    if SpinHumanoid then
        SpinHumanoid.AutoRotate = false
    end

    SetButtonState(
        spinToggle,
        true,
        "[ DEACTIVATE SPIN BOT ]",
        "[ ACTIVATE SPIN BOT ]"
    )
end

local function DeactivateSpin()
    SpinEnabled = false
    FireOrionServer("SpinStop", {})

    ResetSpinLimbs()

    if SpinHumanoid then
        SpinHumanoid.AutoRotate = true
    end

    SetButtonState(
        spinToggle,
        false,
        "[ DEACTIVATE SPIN BOT ]",
        "[ ACTIVATE SPIN BOT ]"
    )
end

spinToggle.MouseButton1Click:Connect(function()
    if SpinEnabled then
        DeactivateSpin()
    else
        ActivateSpin()
    end
end)

--============================================================--
-- MOTOR PRINCIPAL DEL BOT DE GIRO
--============================================================--
--
-- A diferencia del V2, este motor:
-- 1) no exige R6;
-- 2) vuelve a escanear el rig si cambia;
-- 3) gira el HumanoidRootPart;
-- 4) aplica una pose al conjunto de Motor6D;
-- 5) restaura las articulaciones al apagar.
--
-- El movimiento de otros jugadores sigue dependiendo de cómo la
-- experiencia maneje la autoridad de red y de su código servidor.
--============================================================--

pcall(function()
    RunService:UnbindFromRenderStep("RaulsSpinBotV2")
        RunService:UnbindFromRenderStep("RaulsSpinBotV3")
        RunService:UnbindFromRenderStep("OrionV3AimAssist")
end)

RunService:BindToRenderStep(
    "RaulsSpinBotV3",
    Enum.RenderPriority.Character.Value + 1,
    function(deltaTime)
        if not SessionActive or not SpinEnabled then
            return
        end

        if not SpinCharacter
            or not SpinCharacter.Parent
            or not SpinRoot
            or not SpinRoot.Parent
            or not SpinHumanoid
            or not SpinHumanoid.Parent then

            if not GetSpinCharacter() then
                return
            end

            CaptureCurrentSpinTransforms()

            if SpinHumanoid then
                SpinHumanoid.AutoRotate = false
            end
        end

        -- Si el rig recibió o perdió articulaciones, actualizamos la tabla.
        local jointCount = 0
        for _, motor in pairs(SpinJoints) do
            if motor and motor.Parent then
                jointCount += 1
            end
        end

        if jointCount == 0 then
            ScanSpinJoints()
            CaptureCurrentSpinTransforms()
        end

        -- Escala de velocidad basada en los mismos controles del V2.
        local pitchSpeed = math.rad(ForwardSpeed) * deltaTime * 10
        local yawSpeed = math.rad(SideSpeed) * deltaTime * 10

        Pitch += pitchSpeed
        Yaw += yawSpeed

        local currentCFrame = SpinRoot.CFrame

        local pitchRotation = CFrame.Angles(pitchSpeed,0,0)
        local yawRotation = CFrame.Angles(0,yawSpeed,0)

        -- Giro principal del cuerpo.
        SpinRoot.CFrame = currentCFrame * yawRotation * pitchRotation

        -- Movimiento completo de articulaciones.
        ApplyFullBodySpinPose(deltaTime)
    end
)

--============================================================--
-- V3 // DIAGNÓSTICO DEL RIG
--============================================================--
--
-- Este bloque no modifica el juego. Sirve para que el sistema
-- pueda identificar R6/R15 y reconstruir sus referencias después
-- de un respawn o cambio de personaje.
--============================================================--

local function GetRigTypeName()
    if not SpinHumanoid then
        return "UNKNOWN"
    end

    if SpinHumanoid.RigType == Enum.HumanoidRigType.R6 then
        return "R6"
    elseif SpinHumanoid.RigType == Enum.HumanoidRigType.R15 then
        return "R15"
    end

    return "UNKNOWN"
end

local function RefreshSpinRig()
    if not Player.Character then
        return false
    end

    local ok = GetSpinCharacter()

    if ok then
        local rigName = GetRigTypeName()

        if spinReplicationInfo and spinReplicationInfo.Parent then
            local label = spinReplicationInfo:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text =
                    "RIG DETECTADO: " .. rigName ..
                    " // POSE LOCAL ACTIVA // REPLICACIÓN REAL DEPENDE DEL SERVIDOR"
            end
        end
    end

    return ok
end

-- Primer escaneo adicional después de construir la interfaz.
task.defer(function()
    RefreshSpinRig()
end)

--============================================================--
-- V3 // RESTAURACIÓN SEGURA
--============================================================--
--
-- Si el personaje desaparece mientras el botón está activo,
-- se desactiva el motor antes de que el nuevo personaje aparezca.
--============================================================--

Player.CharacterRemoving:Connect(function(character)
    if character ~= SpinCharacter then
        return
    end

    if SpinEnabled then
        SpinEnabled = false
    end

    for name, motor in pairs(SpinJoints) do
        if motor and motor.Parent then
            local original = OriginalJointTransforms[name]
            if original then
                motor.Transform = original
            else
                motor.Transform = CFrame.identity
            end
        end
    end

    if SpinHumanoid and SpinHumanoid.Parent then
        SpinHumanoid.AutoRotate = true
    end

    ClearSpinJointCache()
end)

--============================================================--
-- ORION // NOTA DE REPLICACIÓN REAL
--============================================================--
--
-- La separación y el giro aplicados con Motor6D.Transform en un
-- LocalScript son locales al cliente. No existe una forma fiable
-- de convertir este LocalScript en una replicación universal para
-- todos los jugadores de una experiencia ajena. Para que otros
-- jugadores vean exactamente la separación y el BOT DE GIRO,
-- la experiencia debe ser propia/controlada y necesita lógica
-- de servidor que reciba y valide el estado del personaje.
-- Este hub no intenta falsificar esa capacidad.
--============================================================--

--============================================================--
-- FIN BOT DE GIRO V3
--============================================================--

--============================================================--
-- VISUAL: ESP / FULLBRIGHT / MIRA
--============================================================--

local ESPEnabled = false
local FullbrightEnabled = false
local MiraEnabled = false

-- ORION ESP RANGE
-- Solo se muestran objetivos dentro de 50 studs del personaje local.
local ESP_MAX_DISTANCE = 50
local ESP_UPDATE_INTERVAL = 0.10
local ESPScanAccumulator = 0

local espButton = MakeButton(VisualPage, "[ ESP ALL // OFF ]")
local fullButton = MakeButton(VisualPage, "[ FULLBRIGHT // OFF ]")
local miraButton = MakeButton(VisualPage, "[ MIRA RGB // OFF ]")

local ESPObjects = {}

local function GetESPOrigin()
	local char = Player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function GetESPTargetPart(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("Head")
end

local function IsESPInRange(model)
	local origin = GetESPOrigin()
	local target = GetESPTargetPart(model)
	if not origin or not target then return false end
	return (origin.Position - target.Position).Magnitude <= ESP_MAX_DISTANCE
end

local function RemoveESP(model)
	if not model then return end
	local h = model:FindFirstChild("ESP")
	if h then h:Destroy() end
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if head then
		local bb = head:FindFirstChild("ESP_Nombre")
		if bb then bb:Destroy() end
	end
	ESPObjects[model] = nil
end

local function CreateESP(model, name)
	if not ESPEnabled or not model or model == Player.Character then return end
	if not model:FindFirstChildOfClass("Humanoid") then return end
	if not IsESPInRange(model) then
		RemoveESP(model)
		return
	end
	if model:FindFirstChild("ESP") then
		ESPObjects[model] = true
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP"
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = PURPLE
	highlight.OutlineColor = PURPLE2
	highlight.Parent = model

	local parent = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if parent then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ESP_Nombre"
		billboard.Size = UDim2.new(0,150,0,30)
		billboard.StudsOffset = Vector3.new(0,3,0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = ESP_MAX_DISTANCE
		billboard.Parent = parent

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1,1)
		text.BackgroundTransparency = 1
		text.Text = name
		text.TextColor3 = TEXT
		text.TextStrokeTransparency = 0
		text.TextScaled = true
		text.Font = FONT
		text.Parent = billboard
	end

	ESPObjects[model] = true
end

local function ScanESP()
	if not ESPEnabled then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			CreateESP(plr.Character, plr.Name)
		end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
			CreateESP(obj,obj.Name)
		end
	end
end

local function UpdateESPRange()
	if not ESPEnabled then return end

	for model in pairs(ESPObjects) do
		if not model or not model.Parent or not model:FindFirstChildOfClass("Humanoid") then
			if model then RemoveESP(model) end
		else
			if IsESPInRange(model) then
				if not model:FindFirstChild("ESP") then
					CreateESP(model, model.Name)
				end
			else
				RemoveESP(model)
			end
		end
	end

	ScanESP()
end

local function SetESP(state)
	ESPEnabled = state
	if state then
		ScanESP()
	else
		for model in pairs(ESPObjects) do
			RemoveESP(model)
		end
		for _, model in ipairs(workspace:GetDescendants()) do
			if model:IsA("Model") then RemoveESP(model) end
		end
	end
	SetButtonState(espButton,state,"[ ESP ALL // ON // 50 STUDS ]","[ ESP ALL // OFF ]")
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		task.wait(.3)
		if ESPEnabled then CreateESP(char,plr.Name) end
	end)
end)

workspace.DescendantAdded:Connect(function(obj)
	if ESPEnabled and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
		task.defer(function() CreateESP(obj,obj.Name) end)
	end
end)

espButton.MouseButton1Click:Connect(function() SetESP(not ESPEnabled) end)

RunService.Heartbeat:Connect(function(dt)
	if not ESPEnabled then return end
	ESPScanAccumulator += dt
	if ESPScanAccumulator >= ESP_UPDATE_INTERVAL then
		ESPScanAccumulator = 0
		UpdateESPRange()
	end
end)


savedLighting = {
	Ambient = Lighting.Ambient,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top
}

local function ApplyFullbright()
	Lighting.Ambient = Color3.new(1,1,1)
	Lighting.ColorShift_Bottom = Color3.new(1,1,1)
	Lighting.ColorShift_Top = Color3.new(1,1,1)
end

fullButton.MouseButton1Click:Connect(function()
	FullbrightEnabled = not FullbrightEnabled
	if FullbrightEnabled then
		savedLighting.Ambient = Lighting.Ambient
		savedLighting.ColorShift_Bottom = Lighting.ColorShift_Bottom
		savedLighting.ColorShift_Top = Lighting.ColorShift_Top
		ApplyFullbright()
	else
		Lighting.Ambient = savedLighting.Ambient
		Lighting.ColorShift_Bottom = savedLighting.ColorShift_Bottom
		Lighting.ColorShift_Top = savedLighting.ColorShift_Top
	end
	SetButtonState(fullButton,FullbrightEnabled,"[ FULLBRIGHT // ON ]","[ FULLBRIGHT // OFF ]")
end)

Lighting.LightingChanged:Connect(function()
    if SessionActive and FullbrightEnabled then
        ApplyFullbright()
    end
end)

-- RGB MIRA // ORIGINAL V2
local MiraGui
local MiraCenter
local MiraBlades = {}
local MiraDot
MiraEnabled = false

local function CreateMira()
    if MiraGui then
        MiraGui:Destroy()
    end

    MiraGui = Instance.new("ScreenGui")
    MiraGui.Name = "RGBFanCrosshair"
    MiraGui.ResetOnSpawn = false
    MiraGui.IgnoreGuiInset = true
    MiraGui.DisplayOrder = 999
    MiraGui.Parent = PlayerGui

    MiraCenter = Instance.new("Frame")
    MiraCenter.Name = "CrosshairCenter"
    MiraCenter.AnchorPoint = Vector2.new(0.5,0.5)
    MiraCenter.Position = UDim2.fromScale(0.5,0.5)
    MiraCenter.Size = UDim2.fromOffset(1,1)
    MiraCenter.BackgroundTransparency = 1
    MiraCenter.BorderSizePixel = 0
    MiraCenter.Parent = MiraGui

    MiraDot = Instance.new("Frame")
    MiraDot.Name = "FixedCenter"
    MiraDot.AnchorPoint = Vector2.new(0.5,0.5)
    MiraDot.Position = UDim2.fromOffset(0,0)
    MiraDot.Size = UDim2.fromOffset(7,7)
    MiraDot.BackgroundColor3 = Color3.fromRGB(255,0,0)
    MiraDot.BorderSizePixel = 0
    MiraDot.Parent = MiraCenter

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1,0)
    DotCorner.Parent = MiraDot

    --========================================================--
    -- CONFIGURACIÓN ORIGINAL
    --========================================================--

    local GAP = 17
    local MIN_LENGTH = 27
    local MAX_LENGTH = 68
    local MIN_THICKNESS = 4
    local MAX_THICKNESS = 5

    local SLOW_SPEED = 32
    local FAST_SPEED = 55

    MiraBlades = {}

    local Angles = {0,90,180,270}

    for _, Angle in ipairs(Angles) do
        local Blade = Instance.new("Frame")
        Blade.Name = "RotatingBlade"
        Blade.AnchorPoint = Vector2.new(0.5,0.5)
        Blade.BackgroundColor3 = Color3.fromRGB(255,0,0)
        Blade.BorderSizePixel = 0
        Blade.Size = UDim2.fromOffset(MIN_LENGTH,MIN_THICKNESS)
        Blade.Parent = MiraCenter

        table.insert(MiraBlades,{
            Object = Blade,
            Angle = Angle
        })
    end

    local Rotation = 0
    local CurrentSpeed = SLOW_SPEED
    local CurrentLength = MIN_LENGTH
    local CurrentThickness = MIN_THICKNESS

    local TargetSpeed = SLOW_SPEED
    local TargetLength = MIN_LENGTH
    local TargetThickness = MIN_THICKNESS

    local PhaseTime = 0

    -- Más rápido entre estados; el estado rápido dura un poco más.
    local SlowDuration = 2.0
    local FastDuration = 2.5

    local IsFast = false
    local Hue = 0

    local function SetPhase(Fast)
        IsFast = Fast

        if Fast then
            TargetSpeed = FAST_SPEED
            TargetLength = MAX_LENGTH
            TargetThickness = MAX_THICKNESS
        else
            TargetSpeed = SLOW_SPEED
            TargetLength = MIN_LENGTH
            TargetThickness = MIN_THICKNESS
        end
    end

    SetPhase(false)

    MiraConnection = RunService.RenderStepped:Connect(function(Delta)
        if not SessionActive or not MiraEnabled then return end

        PhaseTime += Delta

        if not IsFast then
            if PhaseTime >= SlowDuration then
                PhaseTime = 0
                SetPhase(true)
            end
        else
            if PhaseTime >= FastDuration then
                PhaseTime = 0
                SetPhase(false)
            end
        end

        -- Mismo comportamiento original, pero con transición más rápida.
        local SpeedSmooth = math.clamp(Delta * 5.0,0,1)
        CurrentSpeed += (TargetSpeed-CurrentSpeed)*SpeedSmooth

        local SizeSmooth = math.clamp(Delta * 4.5,0,1)
        CurrentLength += (TargetLength-CurrentLength)*SizeSmooth
        CurrentThickness += (TargetThickness-CurrentThickness)*SizeSmooth

        Rotation += CurrentSpeed*Delta

        for _, BladeData in ipairs(MiraBlades) do
            local Blade = BladeData.Object
            local Angle = math.rad(BladeData.Angle + Rotation)

            local Distance = GAP + (CurrentLength/2)

            local X = math.cos(Angle)*Distance
            local Y = math.sin(Angle)*Distance

            Blade.Position = UDim2.fromOffset(X,Y)
            Blade.Size = UDim2.fromOffset(CurrentLength,CurrentThickness)
            Blade.Rotation = BladeData.Angle + Rotation
        end

        Hue += Delta*(0.20 + CurrentSpeed/500)

        local RGBColor = Color3.fromHSV(Hue%1,1,1)

        for _, BladeData in ipairs(MiraBlades) do
            BladeData.Object.BackgroundColor3 = RGBColor
        end

        MiraDot.BackgroundColor3 = RGBColor
    end)
end

local function SetMira(state)
    MiraEnabled = state

    if state then
        CreateMira()
    else
        if MiraConnection then
            MiraConnection:Disconnect()
            MiraConnection = nil
        end
        if MiraGui then
            MiraGui:Destroy()
            MiraGui = nil
        end
    end

    SetButtonState(miraButton,state,"[ MIRA RGB // ON ]","[ MIRA RGB // OFF ]")
end

miraButton.MouseButton1Click:Connect(function()
    SetMira(not MiraEnabled)
end)

--============================================================--
-- MOVEMENT: NOCLIP
--============================================================--

local NoclipEnabled = false
local noclipButton = MakeButton(MovementPage, "[ NOCLIP // OFF ]")
local noclipInfo = MakeSection(MovementPage, "NOCLIP", "TOGGLE WITH BUTTON OR N // COLLISION DISABLED WHILE ACTIVE")

local function SetNoclip(state)
	NoclipEnabled = state
	SetButtonState(noclipButton,state,"[ NOCLIP // ON ]","[ NOCLIP // OFF ]")
end

noclipButton.MouseButton1Click:Connect(function() SetNoclip(not NoclipEnabled) end)

--============================================================--
-- TP // POSICIÓN FIJADA + SEGUIMIENTO CON UN SOLO BOTÓN
--============================================================--

local TPEnabled = false
local TPSavedCFrame = nil
local TPMouseHeld = false
local TP_MAX_DISTANCE = 300
local TP_TARGET_OFFSET_Y = 10
local tpButton = MakeButton(TPPage, "[ TELEPORT // OFF ]")
local tpInfo = MakeSection(TPPage, "TELEPORT SYSTEM", "UN BOTÓN: FIJA TU POSICIÓN. MANTÉN CLIC IZQUIERDO PARA SEGUIR UN OBJETIVO; AL SOLTAR, REGRESA A LA POSICIÓN FIJADA.")

local function GetClosestPlayer()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, shortest = nil, TP_MAX_DISTANCE
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character then
            local targetChar = other.Character
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            local sameTeam = Player.Team ~= nil and other.Team ~= nil and Player.Team == other.Team
            if targetRoot and humanoid and humanoid.Health > 0 and not sameTeam then
                local d = (root.Position-targetRoot.Position).Magnitude
                if d <= shortest then
                    shortest = d
                    closest = other
                end
            end
        end
    end
    return closest
end

local function SetTP(state)
    TPEnabled = state
    TPMouseHeld = false
    if state then
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            TPEnabled = false
            SetButtonState(tpButton, false, "[ TELEPORT // ON ]", "[ TELEPORT // OFF ]")
            return
        end
        TPSavedCFrame = root.CFrame
    end
    SetButtonState(tpButton, TPEnabled, "[ TELEPORT // ON ]", "[ TELEPORT // OFF ]")
end

tpButton.MouseButton1Click:Connect(function() SetTP(not TPEnabled) end)

--============================================================--
-- AIM ASSIST // EXPERIENCIA PROPIA
--============================================================--
-- Roblox LocalScripts no pueden reposicionar el cursor físico del sistema.
-- Este módulo orienta la CÁMARA suavemente hacia el objetivo dentro del FOV.
-- Para un shooter propio, el servidor debe validar impactos y daño.

local AimEnabled = false
local AimHolding = false
local AimFOV = 120 -- radio en píxeles
local AimSmooth = 0.18 -- alpha de interpolación; más alto = respuesta más rápida
local AimPageGui = Instance.new("ScreenGui")
AimPageGui.Name = "OrionV3AimFOV"
AimPageGui.ResetOnSpawn = false
AimPageGui.IgnoreGuiInset = true
AimPageGui.DisplayOrder = 20
AimPageGui.Enabled = false
AimPageGui.Parent = PlayerGui

local AimCircle = Instance.new("Frame")
AimCircle.Name = "FOVCircle"
AimCircle.AnchorPoint = Vector2.new(0.5, 0.5)
AimCircle.Position = UDim2.fromScale(0.5, 0.5)
AimCircle.Size = UDim2.fromOffset(AimFOV*2, AimFOV*2)
AimCircle.BackgroundTransparency = 1
AimCircle.BorderSizePixel = 0
AimCircle.Parent = AimPageGui
local AimCircleCorner = Instance.new("UICorner")
AimCircleCorner.CornerRadius = UDim.new(1, 0)
AimCircleCorner.Parent = AimCircle
local AimCircleStroke = Instance.new("UIStroke")
AimCircleStroke.Color = PURPLE
AimCircleStroke.Thickness = 1.5
AimCircleStroke.Transparency = 0.15
AimCircleStroke.Parent = AimCircle

local aimTitle = MakeSection(AimPage, "MOUSE AIM ASSIST", "RMB SOSTENIDO = CÁMARA HACIA EL ENEMIGO DENTRO DEL FOV. SUELTA RMB PARA DETENERLO.")
local aimToggle = MakeButton(AimPage, "[ AIM ASSIST // OFF ]")
local fovButton = MakeButton(AimPage, "[ FOV // 120 PX  (- / +) ]")
local smoothButton = MakeButton(AimPage, "[ SMOOTH // 0.18  (- / +) ]")
local aimStatus = MakeSection(AimPage, "STATUS // OFFLINE", "SELECCIÓN: OBJETIVO VIVO MÁS CERCANO AL CENTRO DE LA PANTALLA; ALIADOS EXCLUIDOS.")

local function UpdateAimControls()
    SetButtonState(aimToggle, AimEnabled, "[ AIM ASSIST // ON ]", "[ AIM ASSIST // OFF ]")
    fovButton.Text = string.format("[ FOV // %d PX  (- / +) ]", AimFOV)
    smoothButton.Text = string.format("[ SMOOTH // %.2f  (- / +) ]", AimSmooth)
    AimPageGui.Enabled = AimEnabled
    AimCircle.Size = UDim2.fromOffset(AimFOV*2, AimFOV*2)
end

aimToggle.MouseButton1Click:Connect(function()
    AimEnabled = not AimEnabled
    if not AimEnabled then AimHolding = false end
    UpdateAimControls()
end)

fovButton.MouseButton1Click:Connect(function()
    -- Click cycles between compact and wider FOV; right-click isn't needed.
    if AimFOV < 180 then AimFOV = AimFOV + 30 else AimFOV = 60 end
    UpdateAimControls()
end)

smoothButton.MouseButton1Click:Connect(function()
    AimSmooth = AimSmooth + 0.05
    if AimSmooth > 0.35 then AimSmooth = 0.10 end
    UpdateAimControls()
end)

local function GetAimTarget(camera)
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X*0.5, viewport.Y*0.5)
    local bestPlayer, bestPart, bestDistance = nil, nil, AimFOV
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character then
            local character = other.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            local sameTeam = Player.Team ~= nil and other.Team ~= nil and Player.Team == other.Team
            if humanoid and humanoid.Health > 0 and part and not sameTeam then
                local point, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and point.Z > 0 then
                    local distance = (Vector2.new(point.X, point.Y)-center).Magnitude
                    if distance <= bestDistance then
                        bestDistance = distance
                        bestPlayer, bestPart = other, part
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

RunService:BindToRenderStep("OrionV3AimAssist", Enum.RenderPriority.Camera.Value + 1, function()
    if not SessionActive or not AimEnabled or not AimHolding then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local targetPlayer, targetPart = GetAimTarget(camera)
    if not targetPlayer or not targetPart or not targetPart.Parent then return end
    local desired = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
    camera.CFrame = camera.CFrame:Lerp(desired, AimSmooth)
end)

UpdateAimControls()

--============================================================--
-- WEATHER
--============================================================--

local SnowEnabled = false
local RainEnabled = false
local SnowSpeed = 145
local RainSpeed = 300
local SNOW_COUNT = 35
local RAIN_COUNT = 30

local weatherBox = MakeSection(WeatherPage, "WEATHER SYSTEM", "NIEVE + LLUVIA // OPTIMIZADO")
local snowButton = MakeButton(WeatherPage, "[ NIEVE // OFF ]")
local rainButton = MakeButton(WeatherPage, "[ LLUVIA // OFF ]")

local weatherTab = MakeButton(WeatherPage, "[ NIEVE SETTINGS ]")
local rainTab = MakeButton(WeatherPage, "[ LLUVIA SETTINGS ]")

local snowLabel = Instance.new("TextLabel")
snowLabel.Size = UDim2.new(1,-4,0,22)
snowLabel.BackgroundTransparency = 1
snowLabel.Text = "NIEVE VELOCIDAD // 145"
snowLabel.TextColor3 = TEXT
snowLabel.Font = FONT
snowLabel.TextSize = 11
snowLabel.TextXAlignment = Enum.TextXAlignment.Left
snowLabel.Parent = WeatherPage

local snowBar = Instance.new("Frame")
snowBar.Size = UDim2.new(1,-4,0,7)
snowBar.BackgroundColor3 = Color3.fromRGB(40,30,50)
snowBar.BorderSizePixel = 0
snowBar.Parent = WeatherPage

local snowFill = Instance.new("Frame")
snowFill.Size = UDim2.new((SnowSpeed-50)/250,0,1,0)
snowFill.BackgroundColor3 = PURPLE
snowFill.BorderSizePixel = 0
snowFill.Parent = snowBar

local snowKnob = Instance.new("Frame")
snowKnob.Size = UDim2.fromOffset(14,14)
snowKnob.AnchorPoint = Vector2.new(.5,.5)
snowKnob.Position = UDim2.new((SnowSpeed-50)/250,0,.5,0)
snowKnob.BackgroundColor3 = TEXT
snowKnob.BorderSizePixel = 0
snowKnob.Parent = snowBar

local rainLabel = Instance.new("TextLabel")
rainLabel.Size = UDim2.new(1,-4,0,22)
rainLabel.BackgroundTransparency = 1
rainLabel.Text = "LLUVIA VELOCIDAD // 300"
rainLabel.TextColor3 = TEXT
rainLabel.Font = FONT
rainLabel.TextSize = 11
rainLabel.TextXAlignment = Enum.TextXAlignment.Left
rainLabel.Parent = WeatherPage

local rainBar = Instance.new("Frame")
rainBar.Size = UDim2.new(1,-4,0,7)
rainBar.BackgroundColor3 = Color3.fromRGB(40,30,50)
rainBar.BorderSizePixel = 0
rainBar.Parent = WeatherPage

local rainFill = Instance.new("Frame")
rainFill.Size = UDim2.new((RainSpeed-100)/400,0,1,0)
rainFill.BackgroundColor3 = PURPLE
rainFill.BorderSizePixel = 0
rainFill.Parent = rainBar

local rainKnob = Instance.new("Frame")
rainKnob.Size = UDim2.fromOffset(14,14)
rainKnob.AnchorPoint = Vector2.new(.5,.5)
rainKnob.Position = UDim2.new((RainSpeed-100)/400,0,.5,0)
rainKnob.BackgroundColor3 = Color3.fromRGB(190,50,255)
rainKnob.BorderSizePixel = 0
rainKnob.Parent = rainBar

local WeatherParticles = Instance.new("Folder")
WeatherParticles.Name = "WeatherParticles"
WeatherParticles.Parent = Gui

local SnowParticles = {}
local RainParticles = {}

local function CreateSnowflake()
	local container = Instance.new("Frame")
	container.Name = "Snowflake"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AnchorPoint = Vector2.new(.5,.5)

	local size = math.random(4,9)
	container.Size = UDim2.fromOffset(size*3,size*3)
	container.Visible = false
	container.Parent = WeatherParticles

	local x = math.random()
	local y = math.random(-100,0)/100
	local vy = math.random(130,180)
	local dir = math.random(0,1)==0 and -1 or 1
	local vx = math.random(45,75)*dir

	local halo = Instance.new("Frame")
	halo.AnchorPoint = Vector2.new(.5,.5)
	halo.Position = UDim2.fromScale(.5,.5)
	halo.Size = UDim2.fromScale(.7,.7)
	halo.BackgroundColor3 = Color3.fromRGB(225,215,255)
	halo.BackgroundTransparency = .35
	halo.BorderSizePixel = 0
	halo.Parent = container

	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(1,0)
	hc.Parent = halo

	local core = Instance.new("Frame")
	core.AnchorPoint = Vector2.new(.5,.5)
	core.Position = UDim2.fromScale(.5,.5)
	core.Size = UDim2.fromScale(.3,.3)
	core.BackgroundColor3 = Color3.new(1,1,1)
	core.BorderSizePixel = 0
	core.Parent = container

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1,0)
	cc.Parent = core

	table.insert(SnowParticles,{Object=container,X=x,Y=y,VX=vx,VY=vy})
end

local function CreateRainDrop()
	local drop = Instance.new("Frame")
	drop.Name = "RainDrop"
	drop.AnchorPoint = Vector2.new(.5,.5)
	drop.BorderSizePixel = 0
	drop.BackgroundColor3 = Color3.fromRGB(145,190,245)
	drop.BackgroundTransparency = .48

	local length = math.random(14,25)
	drop.Size = UDim2.fromOffset(math.random(1,2),length)

	local x = math.random()
	local y = math.random(-100,0)/100
	drop.Position = UDim2.new(x,0,y,0)
	drop.Rotation = math.random(-10,10)
	drop.Visible = false
	drop.Parent = WeatherParticles

	table.insert(RainParticles,{Object=drop,X=x,Y=y,VX=math.random(2,7),VY=math.random(250,340)})
end

for i=1,SNOW_COUNT do CreateSnowflake() end
for i=1,RAIN_COUNT do CreateRainDrop() end

local function SetWeatherButton(button,state,onText,offText)
	SetButtonState(button,state,onText,offText)
end

snowButton.MouseButton1Click:Connect(function()
	SnowEnabled = not SnowEnabled
	SetWeatherButton(snowButton,SnowEnabled,"[ NIEVE // ON ]","[ NIEVE // OFF ]")
	for _,p in ipairs(SnowParticles) do p.Object.Visible=SnowEnabled end
end)

rainButton.MouseButton1Click:Connect(function()
	RainEnabled = not RainEnabled
	SetWeatherButton(rainButton,RainEnabled,"[ LLUVIA // ON ]","[ LLUVIA // OFF ]")
	for _,p in ipairs(RainParticles) do p.Object.Visible=RainEnabled end
end)

local weatherDragging = nil

local function SetWeatherSlider(bar,fill,knob,min,max,callback,x)
	local rel = math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
	local v = min+(max-min)*rel
	fill.Size = UDim2.new(rel,0,1,0)
	knob.Position = UDim2.new(rel,0,.5,0)
	callback(v)
end

snowBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		weatherDragging="snow"
		SetWeatherSlider(snowBar,snowFill,snowKnob,50,300,function(v)
			SnowSpeed=math.floor(v)
			snowLabel.Text="NIEVE VELOCIDAD // "..SnowSpeed
		end,input.Position.X)
	end
end)

rainBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		weatherDragging="rain"
		SetWeatherSlider(rainBar,rainFill,rainKnob,100,500,function(v)
			RainSpeed=math.floor(v)
			rainLabel.Text="LLUVIA VELOCIDAD // "..RainSpeed
		end,input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType~=Enum.UserInputType.MouseMovement then return end
	if weatherDragging=="snow" then
		SetWeatherSlider(snowBar,snowFill,snowKnob,50,300,function(v)
			SnowSpeed=math.floor(v)
			snowLabel.Text="NIEVE VELOCIDAD // "..SnowSpeed
		end,input.Position.X)
	elseif weatherDragging=="rain" then
		SetWeatherSlider(rainBar,rainFill,rainKnob,100,500,function(v)
			RainSpeed=math.floor(v)
			rainLabel.Text="LLUVIA VELOCIDAD // "..RainSpeed
		end,input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		weatherDragging=nil
	end
end)

--============================================================--
-- RENDER LOOPS
--============================================================--

RunService.RenderStepped:Connect(function()
	if not SessionActive or not FlyEnabled then return end
	if not FlyCharacter or not FlyCharacter.Parent or not FlyRoot or not FlyRoot.Parent then
		if not GetFlyCharacter() then return end
	end

	local camera = workspace.CurrentCamera
	if not camera then return end

	local forward = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector

	forward = Vector3.new(forward.X,0,forward.Z)
	right = Vector3.new(right.X,0,right.Z)

	if forward.Magnitude>0 then forward=forward.Unit end
	if right.Magnitude>0 then right=right.Unit end

	local direction = Vector3.zero
	if flyKeys.W then direction+=forward end
	if flyKeys.S then direction-=forward end
	if flyKeys.D then direction+=right end
	if flyKeys.A then direction-=right end
	if flyKeys.Space then direction+=Vector3.new(0,1,0) end
	if flyKeys.C then direction-=Vector3.new(0,1,0) end
	if direction.Magnitude>1 then direction=direction.Unit end

	FlyRoot.AssemblyLinearVelocity = direction*FlySpeed
end)


RunService.Stepped:Connect(function()
	if not SessionActive or not NoclipEnabled then return end
	local character = Player.Character
	if not character then return end
	for _,part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide=false end
	end
end)

task.spawn(function()
    while SessionActive and Gui.Parent do
        if TPEnabled then
            local character = Player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                if TPMouseHeld then
                    local target = GetClosestPlayer()
                    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local destination = targetRoot.Position + Vector3.new(0, TP_TARGET_OFFSET_Y, 0)
                        root.CFrame = CFrame.lookAt(destination, targetRoot.Position)
                    elseif TPSavedCFrame then
                        root.CFrame = TPSavedCFrame
                    end
                elseif TPSavedCFrame then
                    root.CFrame = TPSavedCFrame
                end
            end
        end
        task.wait(1/60)
    end
end)

RunService.RenderStepped:Connect(function(dt)
	if not SessionActive then return end
	local camera=workspace.CurrentCamera
	if not camera then return end
	local viewport=camera.ViewportSize
	local sx,sy=viewport.X,viewport.Y

	if SnowEnabled then
		for _,p in ipairs(SnowParticles) do
			p.Y+=(p.VY/sy)*dt*(SnowSpeed/145)
			p.X+=(p.VX/sx)*dt
			p.Object.Position=UDim2.new(p.X,0,p.Y,0)
			if p.Y>1.12 or p.X<-.15 or p.X>1.15 then
				p.Y=-math.random(5,20)/100
				p.X=math.random()
				local dir=math.random(0,1)==0 and -1 or 1
				p.VX=math.random(45,75)*dir
			end
		end
	end

	if RainEnabled then
		for _,p in ipairs(RainParticles) do
			p.Y+=(p.VY/sy)*dt*(RainSpeed/300)
			p.X+=(p.VX/sx)*dt
			p.Object.Position=UDim2.new(p.X,0,p.Y,0)
			if p.Y>1.12 or p.X>1.12 then
				p.Y=-math.random(5,25)/100
				p.X=math.random()
			end
		end
	end
end)

--============================================================--
-- INPUT
--============================================================--

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if AimEnabled then AimHolding = true end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if TPEnabled then TPMouseHeld = true end
    end
    if processed then return end

	if input.KeyCode==Enum.KeyCode.W then flyKeys.W=true
	elseif input.KeyCode==Enum.KeyCode.A then flyKeys.A=true
	elseif input.KeyCode==Enum.KeyCode.S then flyKeys.S=true
	elseif input.KeyCode==Enum.KeyCode.D then flyKeys.D=true
	elseif input.KeyCode==Enum.KeyCode.Space then flyKeys.Space=true
	elseif input.KeyCode==Enum.KeyCode.C then flyKeys.C=true
	elseif input.KeyCode==Enum.KeyCode.Z then
		-- Z = activar/desactivar FLY sin depender del botón.
		if FlyEnabled then
			SetFlyStatus(false)
		else
			if GetFlyCharacter() then
				SetFlyStatus(true)
			end
		end
	elseif input.KeyCode==Enum.KeyCode.N then SetNoclip(not NoclipEnabled)
	end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then AimHolding = false end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then TPMouseHeld = false end
	if input.KeyCode==Enum.KeyCode.W then flyKeys.W=false
	elseif input.KeyCode==Enum.KeyCode.A then flyKeys.A=false
	elseif input.KeyCode==Enum.KeyCode.S then flyKeys.S=false
	elseif input.KeyCode==Enum.KeyCode.D then flyKeys.D=false
	elseif input.KeyCode==Enum.KeyCode.Space then flyKeys.Space=false
	elseif input.KeyCode==Enum.KeyCode.C then flyKeys.C=false
	end
end)

--============================================================--
-- RESPAWN
--============================================================--

Player.CharacterAdded:Connect(function()
    -- El nuevo personaje siempre empieza limpio.
    FlyEnabled=false

    if SpinEnabled then
        SpinEnabled=false
    end

    FlyCharacter=nil
    FlyHumanoid=nil
    FlyRoot=nil

    SpinCharacter=nil
    SpinHumanoid=nil
    SpinRoot=nil
    SpinTorso=nil

    ClearSpinJointCache()

    SetButtonState(flyToggle,false,"[ DEACTIVATE FLY ]","[ ACTIVATE FLY ]")
    SetButtonState(spinToggle,false,"[ DEACTIVATE SPIN BOT ]","[ ACTIVATE SPIN BOT ]")

	task.wait(.5)

	GetFlyCharacter()
	RefreshSpinRig()

	if NoclipEnabled then
		NoclipEnabled=false
		SetButtonState(noclipButton,false,"[ NOCLIP // ON ]","[ NOCLIP // OFF ]")
	end
end)

--============================================================--
-- DRAG PRINCIPAL
--============================================================--

local dragging=false
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=true
		dragStart=input.Position
		startPos=Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
		local delta=input.Position-dragStart
		Main.Position=UDim2.new(
			startPos.X.Scale,startPos.X.Offset+delta.X,
			startPos.Y.Scale,startPos.Y.Offset+delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=false
	end
end)

--============================================================--
-- CTRL DERECHO: FUNDIDO SUAVE
--============================================================--

local PanelOpen=true
local FadeBusy=false

local function TweenPanel(open)
	if FadeBusy then return end
	FadeBusy=true
	PanelOpen=open

	local info=TweenInfo.new(
		0.38,
		Enum.EasingStyle.Quad,
		open and Enum.EasingDirection.Out or Enum.EasingDirection.In
	)

	if open then
		Main.Visible=true
		Main.BackgroundTransparency=1
		MainStroke.Transparency=1

		for _,obj in ipairs(Main:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				obj.TextTransparency=1
			elseif obj:IsA("Frame") then
				obj.BackgroundTransparency=1
			elseif obj:IsA("UIStroke") then
				obj.Transparency=1
			end
		end

		local tweens={TweenService:Create(Main,info,{BackgroundTransparency=0})}
		table.insert(tweens,TweenService:Create(MainStroke,info,{Transparency=.35}))

		for _,obj in ipairs(Main:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				table.insert(tweens,TweenService:Create(obj,info,{TextTransparency=0}))
			elseif obj:IsA("Frame") and obj~=Main then
				local target=(obj==Header and 0) or (obj==Sidebar and 0) or (obj==Content and 0) or (obj==Accent and 0) or 0
				table.insert(tweens,TweenService:Create(obj,info,{BackgroundTransparency=target}))
			elseif obj:IsA("UIStroke") then
				table.insert(tweens,TweenService:Create(obj,info,{Transparency=.35}))
			end
		end

		for _,t in ipairs(tweens) do t:Play() end
		task.delay(.48,function() FadeBusy=false end)
	else
		local tweens={TweenService:Create(Main,info,{BackgroundTransparency=1}),TweenService:Create(MainStroke,info,{Transparency=1})}

		for _,obj in ipairs(Main:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				table.insert(tweens,TweenService:Create(obj,info,{TextTransparency=1}))
			elseif obj:IsA("Frame") and obj~=Main then
				table.insert(tweens,TweenService:Create(obj,info,{BackgroundTransparency=1}))
			elseif obj:IsA("UIStroke") then
				table.insert(tweens,TweenService:Create(obj,info,{Transparency=1}))
			end
		end

		for _,t in ipairs(tweens) do t:Play() end
		task.delay(.48,function()
			if not PanelOpen then Main.Visible=false end
			FadeBusy=false
		end)
	end
end

UserInputService.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.RightControl then
		TweenPanel(not PanelOpen)
	end
end)

--============================================================--
-- INICIO
--============================================================--

Pages.FLY.Visible=true
Tabs.FLY.BackgroundColor3=PURPLE_DARK
Tabs.FLY.TextColor3=TEXT
Tabs.FLY.BorderColor3=PURPLE

GetFlyCharacter()
GetSpinCharacter()

print("[ORION V3] Unified local system loaded.")

--============================================================--
-- V2 READY
--============================================================--
print("[ORION V3] Aim assist (RMB hold), unified TP and original modules loaded. RIGHT CTRL toggles panel.")
--============================================================--
-- V3 // COMPATIBILITY NOTES
--============================================================--
-- 01. FLY:
--     Y toggles the flight system.
--     SPACE raises the character.
--     C lowers the character.
--     W/A/S/D move relative to the current camera.
--
-- 02. PANEL:
--     RightControl opens/closes the main panel.
--     LeftControl is no longer used for the panel.
--
-- 03. RIG:
--     The spin system accepts both HumanoidRigType.R6 and
--     HumanoidRigType.R15.
--
-- 04. BODY:
--     The spin system no longer requires a Torso instance.
--     It works from HumanoidRootPart + Motor6D discovery.
--
-- 05. LIMBS:
--     R6 shoulder/hip names are supported.
--     R15 shoulder/hip/waist/neck and additional joints are
--     supported when those Motor6D instances exist.
--
-- 06. RESTORE:
--     Every cached Motor6D.Transform is restored when the
--     spin system is disabled or the character is removed.
--
-- 07. SERVER:
--     A LocalScript cannot guarantee that another player's
--     client will receive arbitrary Motor6D.Transform changes.
--     That requires server-side authority in an experience
--     that you control.
--
-- 08. LENGTH:
--     This file intentionally preserves the original hub and
--     adds the V3 compatibility layer rather than replacing
--     the project with a tiny rewritten script.
--============================================================--

-- Diagnostic constants are kept here so future revisions can
-- inspect the intended control layout without changing the GUI.
local V3_PANEL_KEY = Enum.KeyCode.RightControl
local V3_FLY_TOGGLE_KEY = Enum.KeyCode.Z
local V3_FLY_DOWN_KEY = Enum.KeyCode.C

-- Keep explicit names for the controls used by the V3 build.
local V3_CONTROL_LAYOUT = {
    PANEL = "RIGHT CTRL",
    FLY_TOGGLE = "Y",
    FLY_UP = "SPACE",
    FLY_DOWN = "C",
    FLY_FORWARD = "W",
    FLY_BACK = "S",
    FLY_LEFT = "A",
    FLY_RIGHT = "D",
}

--============================================================--
-- V3 // END COMPATIBILITY NOTES
--============================================================--

--============================================================--
-- ORION // SERVIDOR OPCIONAL
--============================================================--
-- Para una experiencia propia, coloca el archivo companion
-- ORION_SERVER_REPLICATION.lua en ServerScriptService y crea/usa
-- ReplicatedStorage.ORION_Remote. El cliente detectará el RemoteEvent
-- automáticamente. En una experiencia ajena, no hay forma fiable de
-- instalar esta autoridad de servidor desde este LocalScript.
--============================================================--

--============================================================--
-- ORION V4 // COMPATIBILIDAD Y MANTENIMIENTO
--============================================================--
-- Z = FLY TOGGLE
-- C = FLY DOWN
-- RIGHT CTRL = OPEN / CLOSE PANEL
-- R6 + R15 = SPIN RIG SUPPORT
-- ESP = MAX 50 STUDS
-- SEPARATION = MOTOR6D TRANSFORM OFFSETS
-- SERVER REPLICATION = SOLO MEDIANTE SERVIDOR DE UNA EXPERIENCIA PROPIA
--============================================================--

--============================================================--
-- V3 TECHNICAL NOTE
--============================================================--
-- Roblox's standard LocalScript API does not expose a supported way to
-- set the physical desktop cursor position. AIM ASSIST therefore steers
-- CurrentCamera while RMB is held; it does not move the OS cursor itself.
-- TP is client-side prototype logic; for a live own game, move authoritative
-- teleport validation to a server Script and validate requests there.
--============================================================--