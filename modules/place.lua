-- modules/place.lua
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local LOBBY_IDS = { [102616257370565] = true, [97441945908384] = true }
local initialJobId = game.JobId
local isPrivateServer = game.PrivateServerId ~= ""

local Place = {}
function Place.GetContext() return LOBBY_IDS[game.PlaceId] and "Lobby" or "Match" end
function Place.IsLobby() return Place.GetContext() == "Lobby" end
function Place.IsMatch() return Place.GetContext() == "Match" end

function Place.SafeReturnToVIP(Config)
    pcall(function() Maid:Cleanup() end) -- Maid будет доступен глобально через _G или передан в Init
    pcall(function()
        if isPrivateServer and initialJobId ~= "" then
            TeleportService:TeleportToPlaceInstance(Config.Anti773Fallback, initialJobId, LocalPlayer)
        else
            TeleportService:Teleport(Config.Anti773Fallback, LocalPlayer)
        end
    end)
end

TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
    if plr == LocalPlayer then task.wait(1); Place.SafeReturnToVIP(_G.NH_Config) end
end)

return Place