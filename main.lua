if _G.__XDAYOUNGX_TAP_REBORN then
    return
end
_G.__XDAYOUNGX_TAP_REBORN = true

local VERSION = "1.0.1"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LOCAL = Players.LocalPlayer
local BRAND = "xdayoungx"

local Config = {
    AutoTap = true,
    TapInterval = 0.06,
    UseInGameAutoClicker = true,
    AntiAfk = true,
    ShowUI = true,
    UIToggleKey = Enum.KeyCode.RightControl,
}

local state = {
    seq = 0,
    servicesReady = false,
    tapService = nil,
    autoClickService = nil,
    dataController = nil,
    autoClickerOn = false,
}

local function log(msg)
    print(("[" .. BRAND .. "] %s"):format(msg))
end

local function waitForGame()
    local timeout = os.clock() + 120
    repeat
        if workspace:GetAttribute("IsClientLoaded") == true then
            break
        end
        task.wait(0.25)
    until os.clock() > timeout

    local ok, dc = pcall(function()
        return require(ReplicatedStorage.Controllers.Core.DataController)
    end)
    if not ok then
        error("Join Tap Simulator REBORN first")
    end

    local deadline = os.clock() + 60
    repeat
        local success, replica = pcall(function()
            return dc:GetReplica()
        end)
        if success and replica and replica.Data then
            state.dataController = dc
            return
        end
        task.wait(0.2)
    until os.clock() > deadline
    error("Data not ready")
end

local function buildServices()
    local Comm = require(ReplicatedStorage.Packages.Comm)
    local root = ReplicatedStorage.RemoteServices
    state.tapService = Comm.ClientComm.new(root, false, "TapService"):BuildObject()
    state.autoClickService = Comm.ClientComm.new(root, false, "AutoClickService"):BuildObject()
    state.servicesReady = true
end

local function requestTap()
    if not state.servicesReady or not Config.AutoTap then
        return
    end
    state.seq += 1
    pcall(function()
        state.tapService.TapRequested:Fire({
            Auto = false,
            ClientSequence = state.seq,
            Source = "screen",
        })
    end)
end

local function tryEnableAutoClicker()
    if not Config.UseInGameAutoClicker or state.autoClickerOn or not state.servicesReady then
        return
    end
    local SkillTreeFormula = require(ReplicatedStorage.Shared.Progression.SkillTreeFormula)
    local data = state.dataController:GetReplica().Data
    if not SkillTreeFormula.HasAutoClicker(data) then
        return
    end
    pcall(function()
        state.autoClickService.AutoClickRequested:Fire({ Enabled = true })
    end)
    state.autoClickerOn = true
    log("auto clicker on")
end

LOCAL.Idled:Connect(function()
    if Config.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local function mountUI()
    local THEME = {
        Window = Color3.fromRGB(28, 28, 30),
        Stroke = Color3.fromRGB(72, 72, 74),
        Title = Color3.fromRGB(245, 245, 247),
        Sub = Color3.fromRGB(152, 152, 157),
        Accent = Color3.fromRGB(10, 132, 255),
        Card = Color3.fromRGB(44, 44, 46),
        ToggleOff = Color3.fromRGB(58, 58, 60),
        ToggleOn = Color3.fromRGB(48, 209, 88),
    }

    local function corner(parent, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = parent
    end

    local function makeToggle(parent, title, get, set, onEnable)
        local row = Instance.new("Frame")
        row.BackgroundColor3 = THEME.Card
        row.BackgroundTransparency = 0.12
        row.Size = UDim2.new(1, 0, 0, 42)
        row.Parent = parent
        corner(row, 10)

        local tl = Instance.new("TextLabel")
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamMedium
        tl.TextSize = 14
        tl.TextColor3 = THEME.Title
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Text = title
        tl.Size = UDim2.new(1, -58, 1, 0)
        tl.Position = UDim2.new(0, 12, 0, 0)
        tl.Parent = row

        local track = Instance.new("TextButton")
        track.AutoButtonColor = false
        track.Text = ""
        track.Size = UDim2.fromOffset(44, 26)
        track.Position = UDim2.new(1, -52, 0.5, -13)
        track.Parent = row
        corner(track, 13)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(22, 22)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = track
        corner(knob, 11)

        local function paint(on)
            track.BackgroundColor3 = on and THEME.ToggleOn or THEME.ToggleOff
            knob.Position = on and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        end

        paint(get())
        track.MouseButton1Click:Connect(function()
            local nv = not get()
            set(nv)
            paint(nv)
            if onEnable and nv then
                onEnable()
            end
        end)
    end

    local pg = LOCAL:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild(BRAND .. "_TapReborn")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = BRAND .. "_TapReborn"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = pg

    local root = Instance.new("Frame")
    root.AnchorPoint = Vector2.new(1, 0)
    root.Position = UDim2.new(1, -20, 0, 20)
    root.Size = UDim2.fromOffset(300, 280)
    root.BackgroundColor3 = THEME.Window
    root.BackgroundTransparency = 0.05
    root.Parent = gui
    corner(root, 12)
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Stroke
    stroke.Transparency = 0.4
    stroke.Parent = root

    local titleBar = Instance.new("Frame")
    titleBar.BackgroundColor3 = Color3.fromRGB(48, 48, 50)
    titleBar.BackgroundTransparency = 0.3
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.Parent = root
    corner(titleBar, 12)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = THEME.Title
    title.Text = BRAND
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Parent = titleBar

    local ver = Instance.new("TextLabel")
    ver.BackgroundTransparency = 1
    ver.Font = Enum.Font.Gotham
    ver.TextSize = 10
    ver.TextColor3 = THEME.Sub
    ver.Text = "v" .. VERSION
    ver.AnchorPoint = Vector2.new(1, 0.5)
    ver.Position = UDim2.new(1, -10, 0.5, 0)
    ver.Size = UDim2.fromOffset(40, 14)
    ver.TextXAlignment = Enum.TextXAlignment.Right
    ver.Parent = titleBar

    local tabBar = Instance.new("Frame")
    tabBar.BackgroundTransparency = 1
    tabBar.Size = UDim2.new(1, -16, 0, 28)
    tabBar.Position = UDim2.new(0, 8, 0, 36)
    tabBar.Parent = root
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    local pages = {}
    local function makePage(name)
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.Text = name
        btn.Size = UDim2.fromOffset(88, 26)
        btn.BackgroundColor3 = THEME.Card
        btn.TextColor3 = THEME.Sub
        btn.Parent = tabBar
        corner(btn, 8)

        local list = Instance.new("Frame")
        list.BackgroundTransparency = 1
        list.Size = UDim2.new(1, -16, 1, -76)
        list.Position = UDim2.new(0, 8, 0, 68)
        list.Visible = false
        list.Parent = root
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = list
        pages[name] = { Button = btn, List = list }
        return list
    end

    local function pick(name)
        for key, p in pages do
            local on = key == name
            p.List.Visible = on
            p.Button.BackgroundColor3 = on and THEME.Accent or THEME.Card
            p.Button.TextColor3 = on and THEME.Title or THEME.Sub
        end
    end

    local control = makePage("Control")
    local config = makePage("Config")
    pick("Control")
    pages.Control.Button.MouseButton1Click:Connect(function()
        pick("Control")
    end)
    pages.Config.Button.MouseButton1Click:Connect(function()
        pick("Config")
    end)

    makeToggle(control, "Auto Tap", function()
        return Config.AutoTap
    end, function(v)
        Config.AutoTap = v
    end)
    makeToggle(control, "Anti AFK", function()
        return Config.AntiAfk
    end, function(v)
        Config.AntiAfk = v
    end)
    makeToggle(control, "In-game auto clicker", function()
        return Config.UseInGameAutoClicker
    end, function(v)
        Config.UseInGameAutoClicker = v
    end, function()
        state.autoClickerOn = false
        tryEnableAutoClicker()
    end)

    local intervalBox = Instance.new("Frame")
    intervalBox.BackgroundColor3 = THEME.Card
    intervalBox.BackgroundTransparency = 0.12
    intervalBox.Size = UDim2.new(1, 0, 0, 56)
    intervalBox.Parent = config
    corner(intervalBox, 10)
    local ilab = Instance.new("TextLabel")
    ilab.BackgroundTransparency = 1
    ilab.Font = Enum.Font.Gotham
    ilab.TextSize = 11
    ilab.TextColor3 = THEME.Sub
    ilab.Text = "Tap interval (seconds)"
    ilab.Size = UDim2.new(1, -20, 0, 16)
    ilab.Position = UDim2.new(0, 12, 0, 6)
    ilab.TextXAlignment = Enum.TextXAlignment.Left
    ilab.Parent = intervalBox
    local input = Instance.new("TextBox")
    input.BackgroundColor3 = Color3.fromRGB(36, 36, 38)
    input.TextColor3 = THEME.Title
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 14
    input.Text = tostring(Config.TapInterval)
    input.Size = UDim2.new(1, -24, 0, 28)
    input.Position = UDim2.new(0, 12, 0, 24)
    input.Parent = intervalBox
    corner(input, 8)
    input.FocusLost:Connect(function(enter)
        if not enter then
            return
        end
        local n = tonumber(input.Text)
        if n and n > 0 then
            Config.TapInterval = math.clamp(n, 0.02, 1)
            input.Text = tostring(Config.TapInterval)
        end
    end)

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextColor3 = THEME.Sub
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = ("UI: %s"):format(Config.UIToggleKey.Name)
    hint.Size = UDim2.new(1, 0, 0, 32)
    hint.Parent = config

    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Config.UIToggleKey then
            root.Visible = not root.Visible
        end
    end)
end

task.spawn(function()
    log("v" .. VERSION .. " loading")
    waitForGame()
    buildServices()
    log("running")

    if Config.UseInGameAutoClicker then
        task.delay(2, tryEnableAutoClicker)
    end

    while true do
        requestTap()
        task.wait(Config.TapInterval)
    end
end)

if Config.ShowUI then
    task.defer(mountUI)
end
