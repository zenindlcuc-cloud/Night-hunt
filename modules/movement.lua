local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

return function(Config, Maid)
    local Movement = { _conn = nil }
    local function setCollide(part, state)
        if part and part:IsA("BasePart") then part.CanCollide = state end
    end
    function Movement.Start()
        Movement.Stop()
        Movement._conn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character; if not char then return end
            if Config.Noclip then for _, p in ipairs(char:GetDescendants()) do setCollide(p, false) end end
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
    return Movement
end
