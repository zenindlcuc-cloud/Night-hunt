local HELI_KEYWORDS = { "heli","helicopter","chopper","plane","aircraft","evac","board","start","seat","passenger","pilot","cargo" }

return function(Config, Place)
    local Plane = { _seated = false, _elapsed = 0, _thread = nil, _seat = nil }
    local function findPlaneSeat()
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("VehicleSeat") and desc.Occupant == nil then
                local name = desc.Name:lower()
                for _, kw in ipairs({ "heli","helicopter","chopper","plane","aircraft","evac","board","start","seat","passenger","pilot","cargo" }) do if name:find(kw) then return desc end end
                local model = desc:FindFirstAncestorOfClass("Model")
                if model then for _, kw in ipairs({ "heli","helicopter","chopper","plane","aircraft","evac","board","start","seat","passenger","pilot","cargo" }) do if model.Name:lower():find(kw) then return desc end end end
            end
        end
        for _, desc in ipairs(workspace:GetDescendants()) do if desc:IsA("VehicleSeat") and desc.Occupant == nil then return desc end end
        for _, desc in ipairs(workspace:GetDescendants()) do if desc:IsA("Seat") and desc.Occupant == nil then return desc end end
        return nil
    end
    local function startPlaneSequence()
        if not Place.IsLobby() or Plane._seated then return end
        local seat = findPlaneSeat()
        if seat then
            local char = game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            if hum and root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
                task.wait(0.1)
                pcall(function() seat:Sit(hum) end)
                Plane._seated = true; Plane._seat = seat
                print("[NH] Seated in aircraft")
            end
        else
            Plane._thread = task.spawn(function() while not findPlaneSeat() do task.wait(2) end startPlaneSequence() end)
        end
    end
    local function resetPlaneState()
        Plane._seated = false; Plane._elapsed = 0; Plane._seat = nil
        if Plane._thread then task.cancel(Plane._thread); Plane._thread = nil end
    end
    return Plane, startPlaneSequence, resetPlaneState
end
