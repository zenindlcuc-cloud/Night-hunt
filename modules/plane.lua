local Players = game:GetService("Players")

local HELI_KEYWORDS = { "heli", "helicopter", "chopper", "plane", "aircraft", "evac", "board", "start", "seat", "passenger", "pilot", "cargo" }

local function factory(Deps)
    local Place = Deps.place or _G.NH_Place or { IsLobby = function() return false end }

    local Plane = { _seated = false, _elapsed = 0, _thread = nil, _seat = nil }

    local function findPlaneSeat()
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
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("VehicleSeat") and desc.Occupant == nil then return desc end
        end
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("Seat") and desc.Occupant == nil then return desc end
        end
        return nil
    end

    function Plane.start()
        if Place.IsLobby and not Place.IsLobby() then return end
        if Plane._seated then return end

        local seat = findPlaneSeat()
        if seat then
            local char = Players.LocalPlayer and Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            if hum and root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
                task.wait(0.1)
                pcall(function() seat:Sit(hum) end)
                Plane._seated = true
                Plane._seat = seat
                print("[NH] Seated in aircraft")
            end
        else
            Plane._thread = task.spawn(function()
                while not findPlaneSeat() do
                    task.wait(2)
                end
                Plane.start()
            end)
        end
    end

    function Plane.reset()
        Plane._seated = false
        Plane._elapsed = 0
        Plane._seat = nil
        if Plane._thread then
            task.cancel(Plane._thread)
            Plane._thread = nil
        end
    end

    return Plane
end

return factory
