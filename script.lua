-- ============================================================================
-- NIGHT HUNT FRAMEWORK v3.1 | PRODUCTION BUILD
-- Design System: Glassmorphism + Dark OLED | Gaming Palette | Cyberpunk Typography
-- Repo: github.com/zenindlcuc-cloud/Night-hunt
-- ============================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

-- =========================== SERVICES ===========================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =========================== DESIGN TOKENS ===========================
local Theme = {
    -- Gaming Palette (Neon Purple + Rose + Green)
    Primary      = Color3.fromHex("#7C3AED"),   -- Neon Purple
    PrimaryDim   = Color3.fromHex("#5B21B6"),
    OnPrimary    = Color3.fromHex("#FFFFFF"),
    Secondary    = Color3.fromHex("#A78BFA"),   -- Light Purple
    OnSecondary  = Color3.fromHex("#0F172A"),
    Accent       = Color3.fromHex("#F43F5E"),   -- Rose/Red Accent
    OnAccent     = Color3.fromHex("#000000"),
    Success      = Color3.fromHex("#22C55E"),   -- Score Green
    OnSuccess    = Color3.fromHex("#0F172A"),
    Background   = Color3.fromHex("#0F0F23"),   -- Deep Navy
    Surface      = Color3.fromHex("#1E1C35"),   -- Card Background
    SurfaceHover = Color3.fromHex("#27273B"),
    Foreground   = Color3.fromHex("#E2E8F0"),
    Muted        = Color3.fromHex("#27273B"),
    MutedFG      = Color3.fromHex("#94A3B8"),
    Border       = Color3.fromHex("#4C1D95"),
    BorderBright = Color3.fromHex("#7C3AED"),
    Ring         = Color3.fromHex("#7C3AED"),
    Destructive  = Color3.fromHex("#EF4444"),
    Shadow       = Color3.fromHex("#000000"),
    
    -- Glassmorphism
    GlassBg      = Color3.fromHex("#1E1C35"),
    GlassBorder  = Color3.fromHex("#4C1D95"),
    GlassHighlight = Color3.fromHex("#7C3AED"),
    
    -- Typography (Roblox closest matches)
    FontHeader   = Enum.Font.GothamBold,      -- Orbitron-like
    FontMono     = Enum.Font.RobotoMono,      -- JetBrains Mono-like
    FontBody     = Enum.Font.GothamMedium,
    
    -- Spacing Scale (4dp base)
    Space = { xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48 },
    
    -- Radius
    Radius = { sm=6, md=10, lg=16, xl=24, full=999 },
    
    -- Animation
    Easing = { fast=TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               normal=TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               slow=TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               spring=TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out) },
}

-- =========================== CONFIG ===========================
local Config = {
    ESP_Enabled      = true,
    ESP_PlayersColor = Theme.Primary,
    ESP_BotsColor    = Theme.Accent,
    Noclip           = true,
    NoCollision      = true,
    AutoKill         = true,
    AttackDistance   = 2.5,
    HeightOffset     = 1.0,
    FastAttack       = true,
    TargetRadius     = 600,
    ScanInterval     = 0.25,
    AutoSeat         = true,
    PlaneWaitTime    = 60,
    Anti773Fallback  = 102616257370565,
}

-- =========================== MAID ===========================
local Maid = { _tasks = {} }
function Maid:Give(t) table.insert(self._tasks, t); return t end
function Maid:Cleanup()
    for _, t in ipairs(self._tasks) do
        if typeof(t)=="RBXScriptConnection" then t:Disconnect()
        elseif typeof(t)=="Instance" then t:Destroy()
        elseif type(t)=="function" then pcall(t) end
    end
    table.clear(self._tasks)
end

-- =========================== UTILITIES ===========================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end

local function GlassFrame(props)
    return Create("Frame", {
        BackgroundColor3 = Theme.GlassBg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.md) }),
        Create("UIStroke", { Color = Theme.GlassBorder, Transparency = 0.3, Thickness = 1 }),
        Create("Frame", { -- Inner glow
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BackgroundColor3 = Theme.GlassHighlight,
        }, {
            Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.GlassHighlight),
                    ColorSequenceKeypoint.new(1, Theme.GlassHighlight),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.95),
                    NumberSequenceKeypoint.new(0.5, 0.99),
                    NumberSequenceKeypoint.new(1, 0.95),
                }),
                Rotation = 45,
            })
        })
    })
end

local function GlassButton(text, color, size, callback)
    local btn = Create("TextButton", {
        Size = size or UDim2.new(0, 120, 0, 36),
        BackgroundColor3 = color or Theme.Primary,
        BackgroundTransparency = 0,
        Text = text,
        TextColor3 = Theme.OnPrimary,
        TextSize = 12,
        Font = Theme.FontHeader,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
        Create("UIStroke", { Color = Theme.BorderBright, Transparency = 0.5, Thickness = 1 }),
    })
    
    local hover = false
    btn.MouseEnter:Connect(function() hover = true
        TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.1 }):Play()
    end)
    btn.MouseLeave:Connect(function() hover = false
        TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0 }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.3, Size = UDim2.new(size and size.X.Scale or 0, size and size.X.Offset or 120 - 4, size and size.Y.Scale or 0, size and size.Y.Offset or 36 - 2) }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, Theme.Easing.spring, { BackgroundTransparency = hover and 0.1 or 0, Size = size or UDim2.new(0, 120, 0, 36) }):Play()
    end)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return btn
end

local function GlassToggle(label, default, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    })
    
    local lbl = Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Foreground,
        TextSize = 13,
        Font = Theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { frame })
    
    local track = Create("Frame", {
        Size = UDim2.new(0, 52, 0, 28),
        Position = UDim2.new(1, -52, 0.5, -14),
        BackgroundColor3 = default and Theme.Primary or Theme.Muted,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }),
    }, { frame })
    
    local thumb = Create("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = default and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
        BackgroundColor3 = Theme.OnPrimary,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Create("UIStroke", { Color = Theme.Shadow, Transparency = 0.8, Thickness = 1 }),
    }, { track })
    
    local state = default
    local function setState(s, animate)
        state = s
        local tweenInfo = animate and Theme.Easing.normal or TweenInfo.new(0)
        TweenService:Create(track, tweenInfo, { BackgroundColor3 = s and Theme.Primary or Theme.Muted }):Play()
        TweenService:Create(thumb, tweenInfo, { Position = s and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11) }):Play()
        if callback then callback(s) end
    end
    
    track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state, true) end end)
    lbl.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state, true) end end)
    
    return frame, function() return state end, function(s) setState(s, true) end
end

local function GlassSlider(label, min, max, default, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
    })
    
    local value = default
    local lbl = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = label .. ": " .. value,
        TextColor3 = Theme.Foreground,
        TextSize = 12,
        Font = Theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { frame })
    
    local track = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    }, { frame })
    
    local fill = Create("Frame", {
        Size = UDim2.new((default-min)/(max-min), 1, 0),
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Primary),
                ColorSequenceKeypoint.new(1, Theme.Secondary),
            }),
            Rotation = 90,
        }),
    }, { track })
    
    local handle = Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((default-min)/(max-min), -8, 0.5, -8),
        BackgroundColor3 = Theme.OnPrimary,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Create("UIStroke", { Color = Theme.Shadow, Transparency = 0.7, Thickness = 2 }),
    }, { track })
    
    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        handle.Position = UDim2.new(rel, -8, 0.5, -8)
        lbl.Text = label .. ": " .. value
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateFromX(inp.Position.X) end end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(inp.Position.X) end end)
    
    return frame
end

local function GlassCard(title, children)
    local card = GlassFrame({
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.1,
    })
    
    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, Theme.Space.md),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, { card })
    
    local padding = Create("UIPadding", {
        PaddingTop = UDim.new(0, Theme.Space.lg),
        PaddingBottom = UDim.new(0, Theme.Space.lg),
        PaddingLeft = UDim.new(0, Theme.Space.lg),
        PaddingRight = UDim.new(0, Theme.Space.lg),
    }, { card })
    
    if title then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.Secondary,
            TextSize = 11,
            Font = Theme.FontHeader,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.3,
        }, { card })
    end
    
    if children then for _, c in ipairs(children) do c.Parent = card end end
    return card
end

-- =========================== PLACE MANAGER ===========================
local LOBBY_IDS = { [102616257370565] = true, [97441945908384] = true }
local PlaceManager = {}
function PlaceManager.GetContext() return LOBBY_IDS[game.PlaceId] and "Lobby" or "Match" end
function PlaceManager.IsLobby() return PlaceManager.GetContext() == "Lobby" end
function PlaceManager.IsMatch() return PlaceManager.GetContext() == "Match" end

local initialJobId = game.JobId
local isPrivateServer = game.PrivateServerId ~= ""

function PlaceManager.SafeReturnToVIP()
    pcall(function() Maid:Cleanup() end)
    pcall(function()
        if isPrivateServer and initialJobId ~= "" then
            TeleportService:TeleportToPlaceInstance(Config.Anti773Fallback, initialJobId, LocalPlayer)
        else
            TeleportService:Teleport(Config.Anti773Fallback, LocalPlayer)
        end
    end)
end

TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
    if plr == LocalPlayer then task.wait(1); PlaceManager.SafeReturnToVIP() end
end)

-- =========================== GUI CLICKER ===========================
local function ClickButtonByText(text)
    local function deepSearch(gui)
        if not gui then return false end
        if gui:IsA("TextButton") and gui.Text == text and gui.Visible and gui.Active then
            pcall(function()
                gui.MouseButton1Click:Fire()
                if gui.MouseEnter then gui.MouseEnter() end
                if gui.MouseButton1Down then gui.MouseButton1Down() end
                task.wait(0.05)
                if gui.MouseButton1Up then gui.MouseButton1Up() end
                if gui.MouseLeave then gui.MouseLeave() end
            end)
            return true
        end
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") and deepSearch(child) then return true end
        end
        return false
    end
    return deepSearch(LocalPlayer:WaitForChild("PlayerGui"))
end

-- =========================== MODULES ===========================
local Movement = { _conn = nil }
function Movement.Start()
    Movement.Stop()
    Movement._conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        if Config.Noclip then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        if Config.NoCollision then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    for _, p in ipairs(plr.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                end
            end
        end
    end)
    Maid:Give(Movement._conn)
end
function Movement.Stop() if Movement._conn then Movement._conn:Disconnect(); Movement._conn = nil end end

local ESP = { _tracked = {}, _conn = nil }
local function applyHighlight(model, color)
    if not model or ESP._tracked[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NH_ESP"; hl.Adornee = model; hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    pcall(function() hl.Parent = model end)
    ESP._tracked[model] = hl
    model.AncestryChanged:Connect(function(_, parent)
        if not parent and ESP._tracked[model] then pcall(function() ESP._tracked[model]:Destroy() end); ESP._tracked[model] = nil end
    end)
end
function ESP.Scan()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then applyHighlight(p.Character, Config.ESP_PlayersColor) end
        Maid:Give(p.CharacterAdded:Connect(function(c) task.wait(0.2); applyHighlight(c, Config.ESP_PlayersColor) end))
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
            applyHighlight(obj, Config.ESP_BotsColor)
        end
    end
end
function ESP.Start() ESP.Scan(); if not ESP._conn then ESP._conn = workspace.ChildAdded:Connect(function(child) if child:IsA("Model") then task.wait(0.2); if child:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(child) and child ~= LocalPlayer.Character then applyHighlight(child, Config.ESP_BotsColor) end end end); Maid:Give(ESP._conn) end end
function ESP.Stop() if ESP._conn then ESP._conn:Disconnect(); ESP._conn = nil end for m, hl in pairs(ESP._tracked) do pcall(function() hl:Destroy() end); ESP._tracked[m] = nil end end

local Combat = { _conn = nil, _scanner = nil, _target = nil }
local BLACKLIST = { "rig","dummy","trader","shop","decor","statue","display","dead","npc","lobby","spawn" }
local function scanNearestBot()
    local char = LocalPlayer.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return nil end
    local nearest, minDist = nil, Config.TargetRadius
    local function eval(mdl)
        if mdl == char or not mdl:IsA("Model") then return end
        if Players:GetPlayerFromCharacter(mdl) then return end
        local name = mdl.Name:lower(); for _, w in ipairs(BLACKLIST) do if name:find(w) then return end end
        local hum = mdl:FindFirstChildOfClass("Humanoid")
        local hrp = mdl:FindFirstChild("HumanoidRootPart") or mdl:FindFirstChild("Torso") or mdl:FindFirstChild("Head")
        if hum and hrp and hum.Health > 0 then
            local d = (root.Position - hrp.Position).Magnitude
            if d < minDist then minDist = d; nearest = hrp end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then eval(obj) end end
    return nearest
end
function Combat.Start()
    Combat.Stop(); if PlaceManager.IsLobby() then return end
    Combat._scanner = task.spawn(function()
        while Config.AutoKill and PlaceManager.IsMatch() do Combat._target = scanNearestBot(); task.wait(Config.ScanInterval) end
    end)
    Combat._conn = RunService.Stepped:Connect(function()
        if not Config.AutoKill then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return end
        local target = Combat._target
        if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = target.CFrame * CFrame.new(0, Config.HeightOffset, Config.AttackDistance)
            local tool = char:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
            if Config.FastAttack then task.spawn(function() pcall(function() VirtualUser:Button1Down(Vector2.new(500,500)); task.wait(0.01); VirtualUser:Button1Up(Vector2.new(500,500)) end) end) end
        else Combat._target = nil end
    end)
    Maid:Give(Combat._conn)
end
function Combat.Stop() if Combat._conn then Combat._conn:Disconnect(); Combat._conn = nil end if Combat._scanner then task.cancel(Combat._scanner); Combat._scanner = nil end Combat._target = nil end

-- =========================== IMPROVED PLANE MODULE ===========================
local Plane = { _seated = false, _elapsed = 0, _thread = nil, _seat = nil }
local HELI_KEYWORDS = { "heli", "helicopter", "chopper", "plane", "aircraft", "evac", "board", "start", "seat", "passenger", "pilot", "cargo" }

local function findPlaneSeat()
    -- Priority 1: VehicleSeat with heli/plane keywords
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("VehicleSeat") and desc.Occupant == nil then
            local name = desc.Name:lower()
            for _, kw in ipairs(HELI_KEYWORDS) do
                if name:find(kw) then return desc end
            end
            local model = desc:FindFirstAncestorOfClass("Model")
            if model then
                for _, kw in ipairs(HELI_KEYWORDS) do
                    if model.Name:lower():find(kw) then return desc end
                end
            end
        end
    end
    -- Priority 2: Any empty VehicleSeat (helicopters often use VehicleSeat)
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("VehicleSeat") and desc.Occupant == nil then return desc end
    end
    -- Priority 3: Any empty Seat
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("Seat") and desc.Occupant == nil then return desc end
    end
    return nil
end

local function startPlaneSequence()
    if not PlaceManager.IsLobby() or Plane._seated then return end
    local seat = findPlaneSeat()
    if seat then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if hum and root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
            task.wait(0.1)
            pcall(function() seat:Sit(hum) end)
            Plane._seated = true
            Plane._seat = seat
            print("[NH]: Seated in aircraft: " .. seat:GetFullName())
        end
    else
        Plane._thread = task.spawn(function()
            while not findPlaneSeat() do task.wait(2) end
            startPlaneSequence()
        end)
    end
end

local function resetPlaneState()
    Plane._seated = false
    Plane._elapsed = 0
    Plane._seat = nil
    if Plane._thread then task.cancel(Plane._thread); Plane._thread = nil end
end

-- =========================== UI SYSTEM ===========================
local UI = {}
local statusLabel
local tabs = {}
local currentTab = "Main"

function UI.Init()
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("NightHuntUI"); if old then old:Destroy() end

    local sg = Create("ScreenGui", {
        Name = "NightHuntUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, { parent })
    Maid:Give(sg)

    -- Background blur effect
    local blur = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Visible = false,
    }, { sg })

    -- Main Window
    local main = GlassFrame({
        Name = "MainWindow",
        Size = UDim2.new(0, 480, 0, 520),
        Position = UDim2.new(0.5, -240, 0.5, -260),
        BackgroundTransparency = 0.1,
        Active = true,
        Draggable = true,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.lg) }),
        Create("UIStroke", { Color = Theme.BorderBright, Transparency = 0.4, Thickness = 1.5 }),
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.GlassHighlight),
                ColorSequenceKeypoint.new(1, Theme.GlassHighlight),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.92),
                NumberSequenceKeypoint.new(0.5, 0.98),
                NumberSequenceKeypoint.new(1, 0.92),
            }),
            Rotation = 135,
        }),
    }, { sg })

    -- Title Bar
    local titleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 2,
    }, { main })

    local title = Create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, Theme.Space.lg, 0, 0),
        BackgroundTransparency = 1,
        Text = "NIGHT HUNT",
        TextColor3 = Theme.Foreground,
        TextSize = 16,
        Font = Theme.FontHeader,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextStrokeTransparency = 0.8,
        TextStrokeColor3 = Theme.Primary,
    }, { titleBar })

    local subtitle = Create("TextLabel", {
        Size = UDim2.new(1, -100, 0, 14),
        Position = UDim2.new(0, Theme.Space.lg, 1, -14),
        BackgroundTransparency = 1,
        Text = "v3.1  •  VIP LOOP  •  GLASSMORPHISM EDITION",
        TextColor3 = Theme.MutedFG,
        TextSize = 9,
        Font = Theme.FontMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.4,
    }, { titleBar })

    -- Window Controls
    local controls = Create("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
    }, { titleBar })

    local minimizeBtn = Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -70, 0.5, -16),
        BackgroundColor3 = Theme.Muted,
        BackgroundTransparency = 0.5,
        Text = "−",
        TextColor3 = Theme.Foreground,
        TextSize = 18,
        Font = Theme.FontHeader,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }),
    }, { controls })

    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -35, 0.5, -16),
        BackgroundColor3 = Theme.Destructive,
        BackgroundTransparency = 0.5,
        Text = "✕",
        TextColor3 = Theme.OnDestructive,
        TextSize = 14,
        Font = Theme.FontHeader,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
    }, { controls })

    -- Tab Bar
    local tabBar = Create("Frame", {
        Size = UDim2.new(1, -Theme.Space.xl*2, 0, 40),
        Position = UDim2.new(0, Theme.Space.lg, 0, 52),
        BackgroundTransparency = 1,
    }, { main })

    local tabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, Theme.Space.sm),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }, { tabBar })

    -- Content Container
    local content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -Theme.Space.xl*2, 1, -120),
        Position = UDim2.new(0, Theme.Space.lg, 0, 98),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, { main })

    -- Status Bar
    local statusBar = Create("Frame", {
        Size = UDim2.new(1, -Theme.Space.xl*2, 0, 28),
        Position = UDim2.new(0, Theme.Space.lg, 1, -Theme.Space.xl),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }),
    }, { main })

    statusLabel = Create("TextLabel", {
        Size = UDim2.new(1, -Theme.Space.lg*2, 1, 0),
        Position = UDim2.new(0, Theme.Space.lg, 0, 0),
        BackgroundTransparency = 1,
        Text = "SYSTEM INITIALIZING...",
        TextColor3 = Theme.Primary,
        TextSize = 11,
        Font = Theme.FontMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextStrokeTransparency = 0.9,
    }, { statusBar })

    -- Tab System
    local tabPages = {}
    local tabButtons = {}

    local function createTab(name, icon)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 0.3,
            Text = (icon or "") .. "  " .. name,
            TextColor3 = Theme.MutedFG,
            TextSize = 11,
            Font = Theme.FontHeader,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ClipsDescendants = true,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
            Create("UIStroke", { Color = Theme.Border, Transparency = 0.6 }),
            Create("Frame", { -- Active indicator
                Name = "Indicator",
                Size = UDim2.new(1, 0, 0, 2),
                Position = UDim2.new(0, 0, 1, -2),
                BackgroundColor3 = Theme.Primary,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.full) }) }),
        }, { tabBar })

        local page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Primary,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, Theme.Space.md),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, Theme.Space.md),
                PaddingBottom = UDim.new(0, Theme.Space.xl),
                PaddingLeft = UDim.new(0, Theme.Space.md),
                PaddingRight = UDim.new(0, Theme.Space.md),
            }),
        }, { content })

        tabButtons[name] = btn
        tabPages[name] = page

        btn.MouseButton1Click:Connect(function() UI.SwitchTab(name) end)

        -- Hover effects
        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.1, TextColor3 = Theme.Foreground }):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.3, TextColor3 = Theme.MutedFG }):Play()
            end
        end)

        return page
    end

    function UI.SwitchTab(name)
        for n, btn in pairs(tabButtons) do
            local active = (n == name)
            currentTab = name
            tabPages[n].Visible = active
            
            TweenService:Create(btn, Theme.Easing.normal, {
                BackgroundTransparency = active and 0 or 0.3,
                TextColor3 = active and Theme.Foreground or Theme.MutedFG,
            }):Play()
            
            local indicator = btn:FindFirstChild("Indicator")
            if indicator then
                TweenService:Create(indicator, Theme.Easing.spring, {
                    BackgroundTransparency = active and 0 or 1,
                    BackgroundColor3 = active and Theme.Primary or Theme.Primary,
                }):Play()
            end
        end
    end

    function UI.SetStatus(text)
        if statusLabel then
            statusLabel.Text = "STATUS: " .. text
            -- Pulse animation
            local tween = TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
                TextColor3 = Theme.Accent,
            })
            tween:Play()
            task.wait(0.3)
            TweenService:Create(statusLabel, Theme.Easing.fast, { TextColor3 = Theme.Primary }):Play()
        end
    end

    -- Create Tabs
    local mainPage = createTab("MAIN", "▸")
    local visualsPage = createTab("VISUALS", "◉")
    local combatPage = createTab("COMBAT", "⚔")
    local movementPage = createTab("MOVE", "⚡")
    local settingsPage = createTab("CONFIG", "⚙")

    UI.SwitchTab("MAIN")

    -- ========== MAIN TAB ==========
    local statusCard = GlassCard("SESSION STATUS", {
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 1,
            Text = "AUTO-LOOP ACTIVE\nLobby → Aircraft → Battle → Rewards → Repeat\n\nESC: Toggle UI  |  INSERT: Force Return",
            TextColor3 = Theme.MutedFG,
            TextSize = 11,
            Font = Theme.FontMono,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        })
    }, { mainPage })

    local returnBtn = GlassButton("RETURN TO VIP LOBBY", Theme.Destructive, UDim2.new(1, -Theme.Space.md*2, 0, 44), function()
        UI.SetStatus("EMERGENCY RETURN TO VIP LOBBY")
        PlaceManager.SafeReturnToVIP()
    end)
    returnBtn.Parent = mainPage

    -- Quick Stats
    local statsFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
    })
    local statsLayout = Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Theme.Space.sm), HorizontalAlignment = Enum.HorizontalAlignment.Center }, { statsFrame })
    
    local function statBox(label, value, color)
        return GlassFrame({
            Size = UDim2.new(0, 110, 0, 70),
            BackgroundTransparency = 0.2,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }),
            Create("TextLabel", { Size = UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=label, TextColor3=Theme.MutedFG, TextSize=9, Font=Theme.FontMono }),
            Create("TextLabel", { Size = UDim2.new(1,0,0,22), BackgroundTransparency=1, Text=value, TextColor3=color or Theme.Primary, TextSize=18, Font=Theme.FontHeader }),
        })
    end
    statBox("PLACE", "LOBBY", Theme.Primary).Parent = statsFrame
    statBox("MODE", "VIP", Theme.Success).Parent = statsFrame
    statBox("TARGET", "14 BOTS", Theme.Accent).Parent = statsFrame
    statsFrame.Parent = mainPage

    -- Emergency Return
    GlassButton("FORCE RETURN TO VIP", Theme.Destructive, UDim2.new(1, -Theme.Space.md*2, 0, 36), function()
        UI.SetStatus("FORCE RETURN INITIATED")
        PlaceManager.SafeReturnToVIP()
    end).Parent = mainPage

    -- ========== VISUALS TAB ==========
    local espToggle = GlassCard("ENTITY VISUALIZATION", {
        GlassToggle("ESP Players", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then ESP.Start() else ESP.Stop() end end),
        GlassToggle("ESP Bots", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then ESP.Start() else ESP.Stop() end end),
    })
    espToggle.Parent = visualsPage

    local espColors = GlassCard("ESP COLORS", {
        GlassCard("Player Color", {
            GlassButton("PRIMARY (PURPLE)", Theme.Primary, UDim2.new(0.5, -4, 0, 32), function() Config.ESP_PlayersColor = Theme.Primary end),
            GlassButton("ACCENT (ROSE)", Theme.Accent, UDim2.new(0.5, -4, 0, 32), function() Config.ESP_PlayersColor = Theme.Accent end),
            GlassButton("SUCCESS (GREEN)", Theme.Success, UDim2.new(0.5, -4, 0, 32), function() Config.ESP_PlayersColor = Theme.Success end),
        })
    })
    espColors.Parent = visualsPage

    -- ========== COMBAT TAB ==========
    local combatToggles = GlassCard("AUTO COMBAT", {
        GlassToggle("Auto Kill (Bots Only)", Config.AutoKill, function(v) Config.AutoKill = v; if v and PlaceManager.IsMatch() then Combat.Start() else Combat.Stop() end end),
        GlassToggle("Fast Attack (VirtualUser)", Config.FastAttack, function(v) Config.FastAttack = v end),
    })
    combatToggles.Parent = combatPage

    local combatSliders = GlassCard("TARGETING PARAMETERS", {
        GlassSlider("Attack Distance", 1, 10, Config.AttackDistance, function(v) Config.AttackDistance = v end),
        GlassSlider("Height Offset", 0, 5, Config.HeightOffset, function(v) Config.HeightOffset = v end),
        GlassSlider("Target Radius", 100, 2000, Config.TargetRadius, function(v) Config.TargetRadius = v end),
        GlassSlider("Scan Interval (s)", 0.1, 1, Config.ScanInterval, function(v) Config.ScanInterval = v end),
    })
    combatSliders.Parent = combatPage

    local blacklistCard = GlassCard("BLACKLIST (Case-Insensitive)")
    local blFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    local blLayout = Create("UIListLayout", { Padding = UDim.new(0, 2), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Wraps = true }, { blFrame })
    for _, word in ipairs(BLACKLIST) do
        Create("TextLabel", {
            Size = UDim2.new(0, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Muted,
            BackgroundTransparency = 0.5,
            Text = "  " .. word .. "  ",
            TextColor3 = Theme.MutedFG,
            TextSize = 10,
            Font = Theme.FontMono,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.full) }),
            Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
        }, { blFrame })
    end
    blFrame.Parent = blacklistCard
    blacklistCard.Parent = combatPage

    -- ========== MOVEMENT TAB ==========
    local moveToggles = GlassCard("PHYSICS OVERRIDE", {
        GlassToggle("Noclip (Local Character)", Config.Noclip, function(v) Config.Noclip = v; if v then Movement.Start() else Movement.Stop() end end),
        GlassToggle("No Collision (Others)", Config.NoCollision, function(v) Config.NoCollision = v end),
    })
    moveToggles.Parent = movementPage

    -- ========== CONFIG TAB ==========
    local planeConfig = GlassCard("AIRCRAFT SEQUENCE", {
        GlassSlider("Plane Wait Time (s)", 10, 180, Config.PlaneWaitTime, function(v) Config.PlaneWaitTime = v end),
        GlassToggle("Auto Seat in Aircraft", Config.AutoSeat, function(v) Config.AutoSeat = v end),
    })
    planeConfig.Parent = settingsPage

    local safetyConfig = GlassCard("SAFETY & TELEPORT", {
        GlassButton("Force Re-scan ESP", Theme.Secondary, UDim2.new(0.5, -4, 0, 36), function() ESP.Stop(); ESP.Start(); UI.SetStatus("ESP RE-SCAN COMPLETE") end),
        GlassButton("Force Return to VIP", Theme.Destructive, UDim2.new(0.5, -4, 0, 36), function() PlaceManager.SafeReturnToVIP() end),
    })
    safetyConfig.Parent = settingsPage

    local uiConfig = GlassCard("UI BEHAVIOR", {
        GlassButton("Minimize UI", Theme.Muted, UDim2.new(0.5, -4, 0, 36), function()
            main.Visible = false
            UI.SetStatus("UI MINIMIZED - PRESS INSERT TO RESTORE")
        end),
        GlassButton("Destroy UI", Theme.Destructive, UDim2.new(0.5, -4, 0, 36), function() sg:Destroy() end),
    })
    uiConfig.Parent = settingsPage

    -- Version Info
    Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "NIGHT HUNT v3.1 — GLASSMORPHISM EDITION\nDESIGN SYSTEM: GAMING PALETTE • GLASSMORPHISM • CYBERPUNK TYPOGRAPHY\nREPO: GITHUB.COM/ZENINDLCUC-CLOUD/NIGHT-HUNT",
        TextColor3 = Theme.MutedFG,
        TextSize = 9,
        Font = Theme.FontMono,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextWrapped = true,
        TextTransparency = 0.5,
    }, { settingsPage })

    -- Minimize/Close Logic
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        content.Visible = not minimized
        tabBar.Visible = not minimized
        statusBar.Visible = not minimized
        TweenService:Create(main, Theme.Easing.normal, { Size = minimized and UDim2.new(0, 480, 0, 48) or UDim2.new(0, 480, 0, 520) }):Play()
        minimizeBtn.Text = minimized and "+" or "−"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        UI.SetStatus("UI HIDDEN - PRESS INSERT TO RESTORE")
    end)

    -- Hotkey: INSERT to toggle UI
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.Insert then
            main.Visible = not main.Visible
            if main.Visible then UI.SetStatus("UI RESTORED") else UI.SetStatus("UI HIDDEN") end
        end
    end)

    -- Initial animation
    main.Size = UDim2.new(0, 480, 0, 0)
    main.BackgroundTransparency = 1
    TweenService:Create(main, Theme.Easing.spring, { Size = UDim2.new(0, 480, 0, 520), BackgroundTransparency = 0.1 }):Play()
    task.wait(0.1)
    TweenService:Create(titleBar, Theme.Easing.normal, { BackgroundTransparency = 0 }):Play()

    print("[NH UI]: Glassmorphism UI loaded successfully.")
end

-- =========================== MAIN ORCHESTRATOR ===========================
local State = { inBattle = false, proceeded = false }

task.spawn(function()
    while true do
        local ctx = PlaceManager.GetContext()

        -- LOBBY PHASE: Aircraft seating
        if ctx == "Lobby" and not State.inBattle then
            if Config.AutoSeat and not Plane._seated then
                startPlaneSequence()
            end
            if Plane._seated and Plane._elapsed < Config.PlaneWaitTime then
                if not Plane._thread then
                    Plane._thread = task.spawn(function()
                        while Plane._elapsed < Config.PlaneWaitTime do
                            task.wait(1)
                            Plane._elapsed += 1
                            if Plane._elapsed % 10 == 0 then
                                UI.SetStatus("AIRCRAFT TIMER: " .. (Config.PlaneWaitTime - Plane._elapsed) .. "s")
                            end
                        end
                        UI.SetStatus("AIRCRAFT TIMER COMPLETE - AWAITING MATCH")
                    end)
                end
            end
        end

        -- MATCH PHASE: Proceed + Combat
        if ctx == "Match" then
            if not State.proceeded then
                task.wait(1)
                ClickButtonByText("Proceed")
                State.proceeded = true
                UI.SetStatus("PROCEED CLICKED - ENTERING BATTLE")
            end
            if not State.inBattle then
                State.inBattle = true
                Combat.Start()
                ESP.Start()
                UI.SetStatus("BATTLE STARTED: 1 VS 14 BOTS")
            end
        end

        -- END/RETURN PHASE: Leave + Continue + Reset
        if ctx == "Lobby" and State.inBattle then
            State.inBattle = false
            State.proceeded = false
            resetPlaneState()
            Combat.Stop()
            ESP.Stop()
            UI.SetStatus("BATTLE ENDED - COLLECTING REWARDS")
            task.wait(2)
            ClickButtonByText("Leave")
            task.wait(1)
            ClickButtonByText("Continue")
            UI.SetStatus("REWARDS COLLECTED - RESTARTING LOOP")
        end

        task.wait(1)
    end
end)

-- =========================== INIT ===========================
UI.Init()
Movement.Start()
if Config.ESP_Enabled then ESP.Start() end

print([[
========================================================
 NIGHT HUNT v3.1 — GLASSMORPHISM PRODUCTION BUILD
========================================================
 DESIGN SYSTEM:
   • Style: Glassmorphism + Dark OLED
   • Palette: Neon Purple (#7C3AED) • Rose (#F43F5E) • Green (#22C55E)
   • Typography: Orbitron-style Headers • JetBrains Mono Body
   • Background: #0F0F23 | Surface: #1E1C35 | Border: #4C1D95
   
 FEATURES:
   ✓ Fixed Aircraft Seating (VehicleSeat priority + keyword scan)
   ✓ Glassmorphism UI (5 Tabs: Main, Visuals, Combat, Move, Config)
   ✓ Gaming Palette: Purple Primary • Rose Accent • Green Success
   ✓ Cyberpunk Typography: Orbitron Headers • Mono Body
   ✓ Smooth Animations: Spring/Quad easing • Hover/Press states
   ✓ VIP Loop: Aircraft(60s) → Proceed → 1vs14 Bots → Leave → Continue
   ✓ Anti-773 Teleport: JobId preservation + Fallback
   ✓ Smart Combat: Bot-only targeting • Blacklist • Cached scanner
   ✓ ESP: Players (Purple) • Bots (Rose) • Highlights
   ✓ Maid Cleanup: All connections/instances on teleport
   ✓ Hotkeys: INSERT (Toggle UI) | Minimize | Close
   
 REPO: github.com/zenindlcuc-cloud/Night-hunt
========================================================
]])
