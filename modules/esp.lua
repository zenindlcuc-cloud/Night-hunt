local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function factory(Deps)
    local Config = _G.NH_Config or (Deps and Deps.config) or {}
    local Maid = _G.NH_Maid or (Deps and Deps.maid)

    local ESP = { _tracked = {}, _conn = nil }
    local function applyHighlight(model, color)
        if not model or ESP._tracked[model] then return end
        local hl = Instance.new("Highlight")
        hl.Name = "NH_ESP"; hl.Adornee = model; hl.FillColor = color or Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
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
            if Maid and Maid.Give then
                Maid:Give(p.CharacterAdded:Connect(function(c) task.wait(0.2); applyHighlight(c, Config.ESP_PlayersColor) end))
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
                applyHighlight(obj, Config.ESP_BotsColor)
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
                        applyHighlight(child, Config.ESP_BotsColor)
                    end
                end
            end)
            if Maid and Maid.Give then Maid:Give(ESP._conn) end
        end
    end
    function ESP.Stop()
        if ESP._conn then ESP._conn:Disconnect(); ESP._conn = nil end
        for m, hl in pairs(ESP._tracked) do
            pcall(function() hl:Destroy() end); ESP._tracked[m] = nil
        end
    end
    return ESP
end

return factory
