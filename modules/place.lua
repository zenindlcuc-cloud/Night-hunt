local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local LOBBY_IDS = { [102616257370565] = true, [97441945908384] = true }

local function factory(Deps)
    local Place = {}

    function Place.GetContext()
        return LOBBY_IDS[game.PlaceId] and "Lobby" or "Match"
    end

    function Place.IsLobby()
        return Place.GetContext() == "Lobby"
    end

    function Place.IsMatch()
        return Place.GetContext() == "Match"
    end

    function Place.SafeReturnToVIP(Config)
        if _G.NH_Maid and _G.NH_Maid.Cleanup then
            pcall(function() _G.NH_Maid:Cleanup() end)
        end
        pcall(function()
            if game.PrivateServerId ~= "" and game.JobId ~= "" then
                TeleportService:TeleportToPlaceInstance(102616257370565, game.JobId, LocalPlayer)
            else
                TeleportService:Teleport(102616257370565, LocalPlayer)
            end
        end)
    end

    TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == LocalPlayer then
            task.wait(1)
            Place.SafeReturnToVIP(_G.NH_Config)
        end
    end)

    return Place
end

return factory
