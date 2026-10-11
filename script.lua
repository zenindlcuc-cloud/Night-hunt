-- ============================================================================
-- NIGHT HUNT FRAMEWORK | TEST HARNESS v2.4 (FULL UI & FEATURES)
-- ============================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Maid = { _tasks = {} }
function Maid:Give(item) table.insert(self._tasks, item); return item end
function Maid:Cleanup()
    for _, item in ipairs(self._tasks) do
        if typeof(item) == "RBXScriptConnection" then item:Disconnect()
        elseif typeof(item) == "Instance" then item:Destroy()
        elseif type(item) == "function" then pcall(item) end
    end
    table.clear(self._tasks)
end

local Config = {
    ESP = true,
    Noclip = true,
    DisableCollision = true,
    AutoSeat = true,
    AutoKill = true,
    AttackDistance = 2.5,
    HeightOffset = 1.0,
    FastAttack = true,
    TargetRadius = 600,
    TargetScanInterval = 0.25,
}

local LOBBY_PLACE_IDS = { [102616257370565] = true, [97441945908384] = true }
local FALLBACK_LOBBY_ID = 102616257370565
local initialJobId = game.JobId
local isPrivateServer = game.PrivateServerId ~= ""

local PlaceManager = {}
function PlaceManager.GetContext() return LOBBY_PLACE_IDS[game.PlaceId] and "Lobby" or "Match" end
function PlaceManager.IsLobby() return PlaceManager.GetContext() == "Lobby" end
function PlaceManager.IsMatch() return PlaceManager.GetContext() == "Match" end

function PlaceManager.ReturnToVIPLobby()
    pcall(function() Maid:Cleanup() end)
    pcall(function()
        if isPrivateServer and initialJobId ~= "" then
            TeleportService:TeleportToPlaceInstance(FALLBACK_LOBBY_ID, initialJobId, LocalPlayer)
        else
            TeleportService:Teleport(FALLBACK_LOBBY_ID, LocalPlayer)
        end
    end)
end

TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
    if player == LocalPlayer then
        task.wait(1)
        PlaceManager.ReturnToVIPLobby()
    end
end)

-- Движение (Noclip)
local Movement = { _conn = nil }
function Movement.Start()
    Movement.Stop()
    Movement._conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        if Config.Noclip then
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end
        if Config.DisableCollision then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, p in ipairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                end
            end
        end
    end)
    Maid:Give(Movement._conn)
end
function Movement.Stop() if Movement._conn then Movement._conn:Disconnect(); Movement._conn = nil end end

-- ESP
local ESP = { _tracked = {}, _conn = nil }
local ESP_COLORS = { Player = Color3.fromRGB(0, 255, 140), Bot = Color3.fromRGB(255, 60, 60) }

local function applyHighlight(model, entityType)
    if not model or ESP._tracked[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "TestESP_Highlight"
    hl.Adornee = model
    hl.FillColor = ESP_COLORS[entityType]
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    pcall(function() hl.Parent = model end)
    ESP._tracked[model] = hl
end

function ESP.Scan()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then applyHighlight(p.Character, "Player") end
        Maid:Give(p.CharacterAdded:Connect(function(c) task.wait(0.2); applyHighlight(c, "Player") end))
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
            applyHighlight(obj, "Bot")
        end
    end
end

function ESP.Start()
    ESP.Scan()
    if not ESP._conn then
        ESP._conn = workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.wait(0.2)
                if child:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(child) and child ~= LocalPlayer.Character then
                    applyHighlight(child, "Bot")
                end
            end
        end)
        Maid:Give(ESP._conn)
    end
end

function ESP.Stop()
    if ESP._conn then ESP._conn:Disconnect(); ESP._conn = nil end
    for m, hl in pairs(ESP._tracked) do pcall(function() hl:Destroy() end); ESP._tracked[m] = nil end
end

-- Бой (CombatFarm)
local CombatFarm = { _conn = nil, _scannerThread = nil, _currentTarget = nil }
local BLACKLIST = { "rig", "dummy", "trader", "shop", "decor", "statue", "display", "dead", "npc", "lobby", "spawn" }

local function scanNearestTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not myRoot then return nil end
    local nearest, minDist = nil, Config.TargetRadius

    local function evaluate(model)
        if model == char or not model:IsA("Model") then return end
        local name = model.Name:lower()
        for _, w in ipairs(BLACKLIST) do if name:find(w) then return end end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if hum and root and hum.Health > 0 then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < minDist then minDist = dist; nearest = root end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then evaluate(p.Character) end end
    for _, obj in ipairs(workspace:GetChildren()) do if not Players:GetPlayerFromCharacter(obj) then evaluate(obj) end end
    return nearest
end

function CombatFarm.Start()
    CombatFarm.Stop()
    if PlaceManager.IsLobby() then return end
    CombatFarm._scannerThread = task.spawn(function()
        while Config.AutoKill and PlaceManager.IsMatch() do
            CombatFarm._currentTarget = scanNearestTarget()
            task.wait(Config.TargetScanIntent and Config.TargetScanInterval or 0.25)
        end
    end)
    CombatFarm._conn = RunService.Stepped:Connect(function()
        if not Config.AutoKill then return end
        local char = LocalPlayer.Character
        if not char then return end
        local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if not myRoot then return end
        local target = CombatFarm._currentTarget
        if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            myRoot.CFrame = target.CFrame * CFrame.new(0, Config.HeightOffset, Config.AttackDistance)
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
            if Config.FastAttack then
                task.spawn(function()
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(500, 500))
                        task.wait(0.01)
                        VirtualUser:Button1Up(Vector2.new(500, 500))
                    end)
                end)
            end
        else
            CombatFarm._currentTarget = nil
        end
    end)
    Maid:Give(CombatFarm._conn)
end

function CombatFarm.Stop()
    if CombatFarm._conn then CombatFarm._conn:Disconnect(); CombatFarm._conn = nil end
    if CombatFarm._scannerThread then task.cancel(CombatFarm._scannerThread); CombatFarm._scannerThread = nil end
    CombatFarm._currentTarget = nil
end

-- Полный UI с переключателями и кнопкой VIP
local UI = {}
local statusLabel

function UI.Init()
    local targetParent = gethui and gethui() or CoreGui
    local old = targetParent:FindFirstChild("NightHunt_HarnessUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui", targetParent)
    gui.Name = "NightHunt_HarnessUI"
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 310, 0, 270)
    main.Position = UDim2.new(0.5, -155, 0.5, -135)
    main.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    main.BackgroundTransparency = 0.15
    main.Active = true; main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", main).Color = Color3.fromRGB(138, 75, 255)

    local top = Instance.new("Frame", main)
    top.Size = UDim2.new(1, 0, 0, 34)
    top.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "NIGHT HUNT // HARNESS v2.4"
    title.TextColor3 = Color3.fromRGB(240, 240, 255)
    title.TextSize = 10
    title.Font = Enum.Font.GothamBold

    local container = Instance.new("ScrollingFrame", main)
    container.Size = UDim2.new(1, -16, 1, -110)
    container.Position = UDim2.new(0, 8, 0, 40)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 2
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 5)

    local function addToggle(name, defaultState, callback)
        local card = Instance.new("Frame", container)
        card.Size = UDim2.new(1, 0, 0, 32)
        card.BackgroundColor3 = Color3.fromRGB(28, 30, 46)
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(1, -55, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(240, 240, 255)
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamMedium

        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, 32, 0, 16)
        btn.Position = UDim2.new(1, -40, 0.5, -8)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(138, 75, 255) or Color3.fromRGB(45, 48, 70)
        btn.Text = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local dot = Instance.new("Frame", btn)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = defaultState and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local state = defaultState
        btn.MouseButton1Click:Connect(function()
            state = not state
            local targetPos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            local targetCol = state and Color3.fromRGB(138, 75, 255) or Color3.fromRGB(45, 48, 70)
            TweenService:Create(dot, TweenInfo.new(0.2), { Position = targetPos }):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = targetCol }):Play()
            callback(state)
        end)
    end

    addToggle("ESP Entities", Config.ESP, function(s) Config.ESP = s; if s then ESP.Start() else ESP.Stop() end end)
    addToggle("Noclip & No Collision", Config.Noclip, function(s) Config.Noclip = s; Config.DisableCollision = s; if s then Movement.Start() else Movement.Stop() end end)
    addToggle("Auto-Kill (Combat Farm)", Config.AutoKill, function(s) Config.AutoKill = s; if s and PlaceManager.IsMatch() then CombatFarm.Start() else CombatFarm.Stop() end end)

    local returnBtn = Instance.new("TextButton", main)
    returnBtn.Size = UDim2.new(1, -16, 0, 30)
    returnBtn.Position = UDim2.new(0, 8, 1, -40)
    returnBtn.BackgroundColor3 = Color3.fromRGB(138, 75, 255)
    returnBtn.Text = "RETURN TO VIP LOBBY"
    returnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    returnBtn.TextSize = 10
    returnBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", returnBtn).CornerRadius = UDim.new(0, 6)
    returnBtn.MouseButton1Click:Connect(function() PlaceManager.ReturnToVIPLobby() end)

    Maid:Give(gui)
end

UI.Init()
Movement.Start()
if Config.ESP then ESP.Start() end

print("[Night Hunt v2.4]: Полный интерфейс с тоглы и VIP возвратом активирован.")
