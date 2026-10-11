-- ============================================================================
-- NIGHT HUNT FRAMEWORK v3.0 | PRODUCTION BUILD
-- Автор: tvoi_nick (сборка под Delta / loadstring)
-- Репозиторий: github.com/zenindlcuc-cloud/Night-hunt
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

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =========================== MAID (CLEANUP) ===========================
local Maid = { _tasks = {} }
function Maid:Give(task)
    table.insert(self._tasks, task)
    return task
end
function Maid:Cleanup()
    for _, task in ipairs(self._tasks) do
        if typeof(task) == "RBXScriptConnection" then task:Disconnect()
        elseif typeof(task) == "Instance" then task:Destroy()
        elseif type(task) == "function" then pcall(task) end
    end
    table.clear(self._tasks)
end

-- =========================== CONFIG ===========================
local Config = {
    -- Visuals
    ESP_Enabled      = true,
    ESP_PlayersColor = Color3.fromRGB(0, 255, 140),
    ESP_BotsColor    = Color3.fromRGB(255, 60, 60),
    -- Movement
    Noclip           = true,
    NoCollision      = true,
    -- Combat
    AutoKill         = true,
    AttackDistance   = 2.5,
    HeightOffset     = 1.0,
    FastAttack       = true,
    TargetRadius     = 600,
    ScanInterval     = 0.25,
    -- Lobby / Plane
    AutoSeat         = true,
    PlaneWaitTime    = 60, -- seconds
    -- Safety
    Anti773Fallback  = 102616257370565, -- Main Lobby PlaceId
}

-- =========================== PLACE MANAGER ===========================
local LOBBY_IDS = { [102616257370565] = true, [97441945908384] = true }
local PlaceManager = {}
function PlaceManager.GetContext()
    return LOBBY_IDS[game.PlaceId] and "Lobby" or "Match"
end
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

-- =========================== UNIVERSAL GUI CLICKER ===========================
local function ClickButtonByText(text)
    local function deepSearch(gui)
        if not gui then return false end
        if gui:IsA("TextButton") and gui.Text == text and gui.Visible and gui.Active then
            pcall(function()
                -- Fire events for executors
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

-- =========================== MOVEMENT MODULE ===========================
local Movement = { _conn = nil }
local function setCollide(part, state)
    if part and part:IsA("BasePart") then part.CanCollide = state end
end
function Movement.Start()
    Movement.Stop()
    Movement._conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        if Config.Noclip then
            for _, p in ipairs(char:GetDescendants()) do setCollide(p, false) end
        end
        if Config.NoCollision then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    for _, p in ipairs(plr.Character:GetDescendants()) do setCollide(p, false) end
                end
            end
        end
    end)
    Maid:Give(Movement._conn)
end
function Movement.Stop() if Movement._conn then Movement._conn:Disconnect(); Movement._conn = nil end end

-- =========================== ESP MODULE ===========================
local ESP = { _tracked = {}, _conn = nil }
local function applyHighlight(model, color)
    if not model or ESP._tracked[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NH_ESP"; hl.Adornee = model; hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    pcall(function() hl.Parent = model end)
    ESP._tracked[model] = hl
    model.AncestryChanged:Connect(function(_, parent)
        if not parent and ESP._tracked[model] then
            pcall(function() ESP._tracked[model]:Destroy() end)
            ESP._tracked[model] = nil
        end
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

-- =========================== COMBAT MODULE (1 vs 14 BOTS) ===========================
local Combat = { _conn = nil, _scanner = nil, _target = nil }
local BLACKLIST = { "rig","dummy","trader","shop","decor","statue","display","dead","npc","lobby","spawn" }
local function isBlacklisted(name)
    name = name:lower()
    for _, w in ipairs(BLACKLIST) do if name:find(w) then return true end end
    return false
end
local function scanNearestBot()
    local char = LocalPlayer.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return nil end
    local nearest, minDist = nil, Config.TargetRadius
    local function eval(mdl)
        if mdl == char or not mdl:IsA("Model") then return end
        if Players:GetPlayerFromCharacter(mdl) then return end -- ONLY BOTS
        if isBlacklisted(mdl.Name) then return end
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
        while Config.AutoKill and PlaceManager.IsMatch() do
            Combat._target = scanNearestBot()
            task.wait(Config.ScanInterval)
        end
    end)
    Combat._conn = RunService.Stepped:Connect(function()
        if not Config.AutoKill then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not root then return end
        local target = Combat._target
        if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = target.CFrame * CFrame.new(0, Config.HeightOffset, Config.AttackDistance)
            local tool = char:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
            if Config.FastAttack then task.spawn(function() pcall(function() VirtualUser:Button1Down(Vector2.new(500,500)); task.wait(0.01); VirtualUser:Button1Up(Vector2.new(500,500)) end) end) end
        else Combat._target = nil end
    end)
    Maid:Give(Combat._conn)
end
function Combat.Stop() if Combat._conn then Combat._conn:Disconnect(); Combat._conn = nil end if Combat._scanner then task.cancel(Combat._scanner); Combat._scanner = nil end Combat._target = nil end

-- =========================== PLANE MODULE ===========================
local Plane = { _seated = false, _elapsed = 0, _thread = nil }
local function findPlaneSeat()
    for _, desc in ipairs(workspace:GetDescendants()) do
        if (desc:IsA("Seat") or desc:IsA("VehicleSeat")) and desc.Occupant == nil then
            local n = desc.Name:lower()
            if n:find("seat") or n:find("chair") or n:find("pilot") or n:find("passenger") then return desc end
        end
    end
    return nil
end
local function startPlaneSequence()
    if not PlaceManager.IsLobby() or Plane._seated then return end
    local seat = findPlaneSeat()
    if seat then
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if hum and root then root.CFrame = seat.CFrame * CFrame.new(0,2,0); seat:Sit(hum); Plane._seated = true; print("[NH]: Seated in plane.") end
    else
        Plane._thread = task.spawn(function() while not findPlaneSeat() do task.wait(5) end startPlaneSequence() end)
    end
end

-- =========================== UI LIBRARY (Lightweight, Tabbed) ===========================
local UI = {}
function UI.Init()
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("NightHuntUI"); if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", parent)
    sg.Name = "NightHuntUI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    Maid:Give(sg)

    -- Main Window
    local main = Instance.new("Frame", sg)
    main.Name = "Main"; main.Size = UDim2.new(0, 420, 0, 360); main.Position = UDim2.new(0.5, -210, 0.5, -180)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 28); main.BackgroundTransparency = 0.05
    main.Active = true; main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(100, 60, 180); stroke.Thickness = 1.5; stroke.Transparency = 0.2

    -- Title Bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1, 0, 0, 40); titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 36); titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(1, -50, 1, 0); title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "NIGHT HUNT v3.0"; title.TextColor3 = Color3.fromRGB(230, 230, 255)
    title.TextSize = 14; title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeBtn.BackgroundTransparency = 1; closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(200, 60, 60); closeBtn.TextSize = 18; closeBtn.Font = Enum.Font.GothamBold
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    -- Tab Buttons
    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, 0, 0, 38); tabBar.Position = UDim2.new(0, 0, 0, 40); tabBar.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabBar); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Content Container
    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1, -20, 1, -98); content.Position = UDim2.new(0, 10, 0, 82)
    content.BackgroundTransparency = 1; content.ClipsDescendants = true

    -- Status Bar
    local statusBar = Instance.new("Frame", main)
    statusBar.Size = UDim2.new(1, -20, 0, 20); statusBar.Position = UDim2.new(0, 10, 1, -30)
    statusBar.BackgroundColor3 = Color3.fromRGB(24, 24, 36); statusBar.BorderSizePixel = 0
    Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6)
    local statusLbl = Instance.new("TextLabel", statusBar)
    statusLbl.Size = UDim2.new(1, -10, 1, 0); statusLbl.Position = UDim2.new(0, 5, 0, 0)
    statusLbl.BackgroundTransparency = 1; statusLbl.Text = "STATUS: INITIALIZING..."; statusLbl.TextColor3 = Color3.fromRGB(180, 120, 255); statusLbl.TextSize = 11; statusLbl.Font = Enum.Font.GothamMedium; statusLbl.TextXAlignment = Enum.TextXAlignment.Left

    local tabs = {}
    local function createTab(name)
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0, 90, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50); btn.Text = name; btn.TextColor3 = Color3.fromRGB(180, 180, 200); btn.TextSize = 11; btn.Font = Enum.Font.GothamSemibold
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local page = Instance.new("ScrollingFrame", content)
        page.Name = name.."Page"; page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 180)
        local layout = Instance.new("UIListLayout", page); layout.Padding = UDim.new(0, 8); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabs[name] = { btn = btn, page = page, active = false }
        btn.MouseButton1Click:Connect(function() UI.SwitchTab(name) end)
        return page
    end

    function UI.SwitchTab(name)
        for n, t in pairs(tabs) do
            t.page.Visible = (n == name)
            t.btn.BackgroundColor3 = (n == name) and Color3.fromRGB(100, 60, 180) or Color3.fromRGB(35, 35, 50)
            t.btn.TextColor3 = (n == name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
            t.active = (n == name)
        end
    end

    function UI.SetStatus(text) statusLbl.Text = "STATUS: " .. text end

    -- Helper to add toggles/sliders
    function UI.AddToggle(page, text, default, callback)
        local frame = Instance.new("Frame", page); frame.Size = UDim2.new(0.9, 0, 0, 40); frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45); frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(0.7, -10, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(240,240,255); lbl.TextSize = 12; lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 48, 0, 24); btn.Position = UDim2.new(1, -58, 0.5, -12); btn.BackgroundColor3 = default and Color3.fromRGB(100, 60, 180) or Color3.fromRGB(55, 55, 75); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame", btn); knob.Size = UDim2.new(0, 20, 0, 20); knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10); knob.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = state and Color3.fromRGB(100, 60, 180) or Color3.fromRGB(55, 55, 75)}):Play()
            callback(state)
        end)
        return frame
    end

    function UI.AddSlider(page, text, min, max, default, callback)
        local frame = Instance.new("Frame", page); frame.Size = UDim2.new(0.9, 0, 0, 50); frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45); frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local lbl = Instance.new("TextLabel", frame); lbl.Size = UDim2.new(1, -20, 0, 20); lbl.Position = UDim2.new(0, 15, 0, 5); lbl.BackgroundTransparency = 1; lbl.Text = text .. ": " .. default; lbl.TextColor3 = Color3.fromRGB(240,240,255); lbl.TextSize = 12; lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", frame); bar.Size = UDim2.new(0.85, 0, 0, 6); bar.Position = UDim2.new(0, 15, 0, 32); bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70); Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
        local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((default-min)/(max-min), 1, 0); fill.BackgroundColor3 = Color3.fromRGB(100, 60, 180); Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
        local dragging = false
        bar.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        RunService.RenderStepped:Connect(function()
            if dragging then
                local rel = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                lbl.Text = text .. ": " .. val
                callback(val)
            end
        end)
        return frame
    end

    function UI.AddButton(page, text, color, callback)
        local btn = Instance.new("TextButton", page); btn.Size = UDim2.new(0.9, 0, 0, 36); btn.BackgroundColor3 = color; btn.Text = text; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 12; btn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Create Tabs
    local tabMain = createTab("Main")
    local tabVisuals = createTab("Visuals")
    local tabCombat = createTab("Combat")
    local tabMovement = createTab("Movement")
    local tabSettings = createTab("Settings")
    UI.SwitchTab("Main")

    -- Populate Main Tab
    UI.AddButton(tabMain, "🔄 RETURN TO VIP LOBBY (SAFE)", Color3.fromRGB(180, 60, 60), function()
        UI.SetStatus("RETURNING TO VIP LOBBY...")
        PlaceManager.SafeReturnToVIP()
    end)
    local lbl = Instance.new("TextLabel", tabMain); lbl.Size = UDim2.new(0.9, 0, 0, 60); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(150,150,170); lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham; lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.Text = "Авто-цикл: Лобби → Посадка в вертолёт (60с) → Процеед → Фарм 14 ботов → Leave → Continue → Повтор.\nВсе функции работают в фоне."

    -- Visuals Tab
    UI.AddToggle(tabVisuals, "ESP Players", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then ESP.Start() else ESP.Stop() end end)
    UI.AddToggle(tabVisuals, "ESP Bots", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then ESP.Start() else ESP.Stop() end end) -- coupled for simplicity

    -- Combat Tab
    UI.AddToggle(tabCombat, "Auto Kill (Bots Only)", Config.AutoKill, function(v) Config.AutoKill = v; if v and PlaceManager.IsMatch() then Combat.Start() else Combat.Stop() end end)
    UI.AddSlider(tabCombat, "Attack Distance", 1, 10, Config.AttackDistance, function(v) Config.AttackDistance = v end)
    UI.AddSlider(tabCombat, "Height Offset", 0, 5, Config.HeightOffset, function(v) Config.HeightOffset = v end)
    UI.AddSlider(tabCombat, "Target Radius", 100, 2000, Config.TargetRadius, function(v) Config.TargetRadius = v end)
    UI.AddToggle(tabCombat, "Fast Attack (VirtualUser)", Config.FastAttack, function(v) Config.FastAttack = v end)

    -- Movement Tab
    UI.AddToggle(tabMovement, "Noclip (Local)", Config.Noclip, function(v) Config.Noclip = v; if v then Movement.Start() else Movement.Stop() end end)
    UI.AddToggle(tabMovement, "No Collision (Others)", Config.NoCollision, function(v) Config.NoCollision = v end)

    -- Settings Tab
    UI.AddSlider(tabSettings, "Plane Wait Time (s)", 10, 120, Config.PlaneWaitTime, function(v) Config.PlaneWaitTime = v end)
    UI.AddButton(tabSettings, "Force Re-scan ESP", Color3.fromRGB(60, 120, 60), function() ESP.Stop(); ESP.Start() end)
    UI.AddButton(tabSettings, "Force Return to VIP", Color3.fromRGB(180, 60, 60), function() PlaceManager.SafeReturnToVIP() end)
    UI.AddButton(tabSettings, "Destroy UI", Color3.fromRGB(60, 60, 60), function() sg:Destroy() end)

    print("[NH UI]: Loaded successfully.")
end

-- =========================== MAIN ORCHESTRATOR ===========================
local State = { inBattle = false, proceeded = false }

task.spawn(function()
    while true do
        local ctx = PlaceManager.GetContext()

        -- LOBBY PHASE
        if ctx == "Lobby" and not State.inBattle then
            if Config.AutoSeat and not Plane._seated then startPlaneSequence() end
            if Plane._seated and Plane._elapsed < Config.PlaneWaitTime then
                if not Plane._thread then
                    Plane._thread = task.spawn(function()
                        while Plane._elapsed < Config.PlaneWaitTime do task.wait(1); Plane._elapsed += 1 end
                        UI.SetStatus("PLANE TIMER DONE. WAITING FOR MATCH...")
                    end)
                end
            end
        end

        -- MATCH PHASE
        if ctx == "Match" then
            if not State.proceeded then
                task.wait(1); ClickButtonByText("Proceed"); State.proceeded = true; UI.SetStatus("CLICKED PROCEED. ENTERING BATTLE.")
            end
            if not State.inBattle then
                State.inBattle = true; Combat.Start(); ESP.Start(); UI.SetStatus("BATTLE STARTED: 1 VS 14 BOTS.")
            end
        end

        -- END / RETURN PHASE
        if ctx == "Lobby" and State.inBattle then
            State.inBattle = false; State.proceeded = false; Plane._seated = false; Plane._elapsed = 0
            Combat.Stop(); ESP.Stop()
            UI.SetStatus("BATTLE ENDED. COLLECTING REWARDS...")
            task.wait(2); ClickButtonByText("Leave")
            task.wait(1); ClickButtonByText("Continue")
            UI.SetStatus("REWARDS COLLECTED. RESTARTING LOOP.")
        end

        task.wait(1)
    end
end)

-- =========================== INIT ===========================
UI.Init()
Movement.Start()
if Config.ESP_Enabled then ESP.Start() end

print("==========================================")
print(" NIGHT HUNT v3.0 LOADED")
print(" Repo: github.com/zenindlcuc-cloud/Night-hunt")
print(" UI: Tabbed (Main, Visuals, Combat, Move, Settings)")
print(" Loop: VIP Plane -> Battle -> Rewards -> Repeat")
print("==========================================")
