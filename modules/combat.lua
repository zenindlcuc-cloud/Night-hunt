-- modules/combat.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

return function(Config, Maid, Place)
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
        Combat.Stop(); if Place.IsLobby() then return end
        Combat._scanner = task.spawn(function()
            while Config.AutoKill and Place.IsMatch() do Combat._target = scanNearestBot(); task.wait(Config.ScanInterval) end
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
    return Combat
end