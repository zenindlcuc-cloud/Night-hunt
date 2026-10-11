local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

return function(Config, Maid, Place)
    local Combat = { _conn = nil, _scanner = nil, _currentTarget = nil }
    local BLACKLIST = { "rig","dummy","trader","shop","decor","statue","display","dead","npc","lobby","spawn" }
    local function scanNearestTarget()
        local char = LocalPlayer.Character; if not char then return nil end
        local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not myRoot then return nil end
        local nearest, minDist = nil, Config.TargetRadius
        local function evaluate(model)
            if model == char or not model:IsA("Model") then return end
            if Players:GetPlayerFromCharacter(model) then return end
            local name = model.Name:lower(); for _, w in ipairs({"rig","dummy","trader","shop","decor","statue","display","dead","npc","lobby","spawn"}) do if name:find(w) then return end end
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
    function Combat.Start()
        Combat.Stop(); if Place.IsLobby() then return end
        Combat._scanner = task.spawn(function()
            while Config.AutoKill and Place.IsMatch() do Combat._currentTarget = scanNearestTarget(); task.wait(Config.ScanInterval) end
        end)
        Combat._conn = RunService.Stepped:Connect(function()
            if not Config.AutoKill then return end
            local char = LocalPlayer.Character; if not char then return end
            local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart; if not myRoot then return end
            local target = Combat._currentTarget
            if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
                myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
                myRoot.CFrame = target.CFrame * CFrame.new(0, Config.HeightOffset, Config.AttackDistance)
                local tool = char:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
                if Config.FastAttack then task.spawn(function() pcall(function() VirtualUser:Button1Down(Vector2.new(500,500)); task.wait(0.01); VirtualUser:Button1Up(Vector2.new(500,500)) end) end) end
            else Combat._currentTarget = nil end
        end)
        _G.NH_Maid:Give(Combat._conn)
    end
    function Combat.Stop() if Combat._conn then Combat._conn:Disconnect(); Combat._conn = nil end if Combat._scanner then task.cancel(Combat._scanner); Combat._scanner = nil end Combat._currentTarget = nil end
    return Combat
end
