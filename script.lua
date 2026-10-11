-- ============================================================================
-- NIGHT HUNT FRAMEWORK | v2.5 FULL AUTO (VIP LOOP + GUI CLICKS)
-- ============================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ----------------------------------------------------------------------------
-- MAID & CONFIG
-- ----------------------------------------------------------------------------
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
    ESP = true, Noclip = true, DisableCollision = true, AutoSeat = true,
    AutoKill = true, AttackDistance = 2.5, HeightOffset = 1.0,
    FastAttack = true, TargetRadius = 600, TargetScanInterval = 0.25,
}

local LOBBY_PLACE_IDS = { [102616257370565] = true, [97441945908384] = true }
local FALLBACK_LOBBY_ID = 102616257370565
local initialJobId = game.JobId
local isPrivateServer = game.PrivateServerId ~= ""

-- ----------------------------------------------------------------------------
-- PLACE MANAGER & VIP RETURN (Anti-773)
-- ----------------------------------------------------------------------------
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
    if player == LocalPlayer then task.wait(1); PlaceManager.ReturnToVIPLobby() end
end)

-- ----------------------------------------------------------------------------
-- UNIVERSAL GUI CLICKER (Leave / Proceed / Continue)
-- ----------------------------------------------------------------------------
local function ClickButtonByText(text)
    local function search(gui)
        if not gui then return false end
        if gui:IsA("TextButton") and gui.Text == text then
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
            if child:IsA("GuiObject") and search(child) then return true end
        end
        return false
    end
    return search(LocalPlayer:WaitForChild("PlayerGui"))
end

-- ----------------------------------------------------------------------------
-- MOVEMENT (Noclip / NoCollision)
-- ----------------------------------------------------------------------------
local Movement = { _conn = nil }
function Movement.Start()
    Movement.Stop()
    Movement._conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        if Config.Noclip then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        if Config.DisableCollision then
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

-- ----------------------------------------------------------------------------
-- ESP (Highlights)
-- ----------------------------------------------------------------------------
local ESP = { _tracked = {}, _conn = nil }
local ESP_COLORS = { Player = Color3.fromRGB(0, 255, 140), Bot = Color3.fromRGB(255, 60, 60) }
local function applyHighlight(model, entityType)
    if not model or ESP._tracked[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NightHunt_ESP"; hl.Adornee = model; hl.FillColor = ESP_COLORS[entityType]
    hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    pcall(function() hl.Parent = model end); ESP._tracked[model] = hl
    model.AncestryChanged:Connect(function(_, parent) if not parent and ESP._tracked[model] then pcall(function() ESP._tracked[model]:Destroy() end); ESP._tracked[model] = nil end end)
end
function ESP.Scan()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then applyHighlight(p.Character, "Player") end
        Maid:Give(p.CharacterAdded:Connect(function(c) task.wait(0.2); applyHighlight(c, "Player") end)) end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then applyHighlight(obj, "Bot") end
    end
end
function ESP.Start() ESP.Scan(); if not ESP._conn then ESP._conn = workspace.ChildAdded:Connect(function(child) if child:IsA("Model") then task.wait(0.2); if child:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(child) and child ~= LocalPlayer.Character then applyHighlight(child, "Bot") end end end); Maid:Give(ESP._conn) end end
function ESP.Stop() if ESP._conn then ESP._conn:Disconnect(); ESP._conn = nil end for m, hl in pairs(ESP._tracked) do pcall(function() hl:Destroy() end); ESP._tracked[m] = nil end end

-- ----------------------------------------------------------------------------
-- COMBAT FARM (1 vs 14 Bots)
-- ----------------------------------------------------------------------------
local CombatFarm = { _conn = nil, _scannerThread = nil, _currentTarget = nil }
local BLACKLIST = { "rig", "dummy", "trader", "shop", "decor", "statue", "display", "dead", "npc", "lobby", "spawn" }

local function scanNearestTarget()
    local char = LocalPlayer.Character; if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not myRoot then return nil end
    local nearest, minDist = nil, Config.TargetRadius
    local function evaluate(model)
        if model == char or not model:IsA("Model") then return end
        if Players:GetPlayerFromCharacter(model) then return end -- Только боты
        local name = model.Name:lower(); for _, w in ipairs(BLACKLIST) do if name:find(w) then return end end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
        if hum and root and hum.Health > 0 then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < minDist then minDist = dist; nearest = root end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then evaluate(obj) end end
    return nearest
end

function CombatFarm.Start()
    CombatFarm.Stop(); if PlaceManager.IsLobby() then return end
    CombatFarm._scannerThread = task.spawn(function()
        while Config.AutoKill and PlaceManager.IsMatch() do CombatFarm._currentTarget = scanNearestTarget(); task.wait(Config.TargetScanInterval) end
    end)
    CombatFarm._conn = RunService.Stepped:Connect(function()
        if not Config.AutoKill then return end
        local char = LocalPlayer.Character; if not char then return end
        local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not myRoot then return end
        local target = CombatFarm._currentTarget
        if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
            myRoot.CFrame = target.CFrame * CFrame.new(0, Config.HeightOffset, Config.AttackDistance)
            local tool = char:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
            if Config.FastAttack then task.spawn(function() pcall(function() VirtualUser:Button1Down(Vector2.new(500,500)); task.wait(0.01); VirtualUser:Button1Up(Vector2.new(500,500)) end) end) end
        else CombatFarm._currentTarget = nil end
    end)
    Maid:Give(CombatFarm._conn)
end
function CombatFarm.Stop() if CombatFarm._conn then CombatFarm._conn:Disconnect(); CombatFarm._conn = nil end if CombatFarm._scannerThread then task.cancel(CombatFarm._scannerThread); CombatFarm._scannerThread = nil end CombatFarm._currentTarget = nil end

-- ----------------------------------------------------------------------------
-- PLANE SEATING & 60s TIMER
-- ----------------------------------------------------------------------------
local PlaneTimer = { _thread = nil, _elapsed = 0, _seated = false }
local function FindPlaneSeat()
    for _, desc in ipairs(workspace:GetDescendants()) do
        if (desc:IsA("Seat") or desc:IsA("VehicleSeat")) and desc.Occupant == nil then
            local name = desc.Name:lower()
            if name:find("seat") or name:find("chair") or name:find("pilot") or name:find("passenger") then return desc end
        end
    end
    return nil
end

local function StartPlaneSequence()
    if not PlaceManager.IsLobby() or PlaneTimer._seated then return end
    local seat = FindPlaneSeat()
    if seat then
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if hum and root then root.CFrame = seat.CFrame * CFrame.new(0, 2, 0); seat:Sit(hum); PlaneTimer._seated = true; print("[Night Hunt]: Seated in plane.") end
    else
        PlaneTimer._thread = task.spawn(function() while not FindPlaneSeat() do task.wait(5) end StartPlaneSequence() end)
    end
end

-- ----------------------------------------------------------------------------
-- MAIN ORCHESTRATOR (Loop: Lobby -> Plane -> Proceed -> Battle -> Leave/Continue -> Repeat)
-- ----------------------------------------------------------------------------
local inBattle = false
local proceeded = false

task.spawn(function()
    while true do
        local ctx = PlaceManager.GetContext()

        -- LOBBY: Sit in plane, wait 60s
        if ctx == "Lobby" and not inBattle then
            if not PlaneTimer._seated then StartPlaneSequence() end
            if PlaneTimer._seated and PlaneTimer._elapsed < 60 then
                if not PlaneTimer._thread then
                    PlaneTimer._thread = task.spawn(function()
                        while PlaneTimer._elapsed < 60 do task.wait(1); PlaneTimer._elapsed += 1 end
                        print("[Night Hunt]: Timer done. Ready for battle.")
                    end)
                end
            end
        end

        -- MATCH: Click Proceed, Start Battle
        if ctx == "Match" then
            if not proceeded then
                task.wait(1); ClickButtonByText("Proceed"); proceeded = true
                print("[Night Hunt]: Clicked Proceed.")
            end
            if not inBattle then
                inBattle = true; CombatFarm.Start(); ESP.Start()
                print("[Night Hunt]: Battle STARTED (1 vs 14 Bots).")
            end
        end

        -- END / RETURN: Click Leave -> Continue -> Reset state
        if ctx == "Lobby" and inBattle then
            inBattle = false; proceeded = false; PlaneTimer._seated = false; PlaneTimer._elapsed = 0
            CombatFarm.Stop(); ESP.Stop()
            print("[Night Hunt]: Battle ENDED. Handling rewards...")
            task.wait(2); ClickButtonByText("Leave")
            task.wait(1); ClickButtonByText("Continue")
        end

        task.wait(1)
    end
end)

-- ----------------------------------------------------------------------------
-- MINIMAL UI (Return button)
-- ----------------------------------------------------------------------------
local UI = {}
function UI.Init()
    local targetParent = gethui and gethui() or CoreGui
    local old = targetParent:FindFirstChild("NightHunt_HarnessUI"); if old then old:Destroy() end
    local gui = Instance.new("ScreenGui", targetParent); gui.Name = "NightHunt_HarnessUI"; gui.ResetOnSpawn = false
    local main = Instance.new("Frame", gui); main.Size = UDim2.new(0, 310, 0, 100); main.Position = UDim2.new(0.5, -155, 0.5, -50)
    main.BackgroundColor3 = Color3.fromRGB(15,16,24); main.BackgroundTransparency = 0.15; main.Active = true; main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,8); Instance.new("UIStroke", main).Color = Color3.fromRGB(138,75,255)
    local btn = Instance.new("TextButton", main); btn.Size = UDim2.new(1,-20,0,44); btn.Position = UDim2.new(0,10,0.5,-22)
    btn.BackgroundColor3 = Color3.fromRGB(138,75,255); btn.Text = "RETURN TO VIP LOBBY (SAFE)"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function() PlaceManager.ReturnToVIPLobby() end)
    Maid:Give(gui)
end
UI.Init()

-- Autostart
Movement.Start()
if Config.ESP then ESP.Start() end

print("[Night Hunt v2.5]: Fully loaded. VIP Loop active. Buttons: Leave / Proceed / Continue.")
