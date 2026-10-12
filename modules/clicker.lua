local Players = game:GetService("Players")

local function factory(Deps)
    local function ClickButtonByText(text)
        local player = Players.LocalPlayer
        local playerGui = player and player:FindFirstChild("PlayerGui")
        if not playerGui then return false end

        local function deepSearch(gui)
            if not gui then return false end
            if gui:IsA("TextButton") and gui.Text == text and gui.Visible and gui.Active then
                pcall(function()
                    gui.MouseButton1Click:Fire()
                    if gui.MouseButton1Down then gui.MouseButton1Down() end
                    task.wait(0.05)
                    if gui.MouseButton1Up then gui.MouseButton1Up() end
                    if gui.MouseLeave then gui.MouseLeave() end
                end)
                return true
            end
            for _, child in ipairs(gui:GetChildren()) do
                if child:IsA("GuiObject") and deepSearch(child) then
                    return true
                end
            end
            return false
        end

        return deepSearch(playerGui)
    end

    return ClickButtonByText
end

return factory
