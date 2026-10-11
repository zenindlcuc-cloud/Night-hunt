-- modules/orchestrator.lua (ИСПРАВЛЕННЫЙ)
return function(Deps)
    local Config = Deps.config
    local Place = Deps.place
    local Clicker = Deps.clicker
    local Combat = Deps.combat
    local ESP = Deps.esp
    local Plane = Deps.plane
    local UI = Deps.ui

    local State = { inBattle = false, proceeded = false }

    task.spawn(function()
        while true do
            local ctx = Place.GetContext and Place.GetContext() or (game.PlaceId == 102616257370565 or game.PlaceId == 97441945908384) and "Lobby" or "Match"
            
            -- LOBBY PHASE
            if ctx == "Lobby" and not State.inBattle then
                if Config.AutoSeat and not (Plane._seated or false) then
                    if Plane.start then Plane.start() end
                end
                if Plane._seated and (Plane._elapsed or 0) < (Config.PlaneWaitTime or 60) then
                    if not Plane._thread then
                        Plane._thread = task.spawn(function()
                            while (Plane._elapsed or 0) < (Config.PlaneWaitTime or 60) do
                                task.wait(1)
                                Plane._elapsed = (Plane._elapsed or 0) + 1
                            end
                            if _G.NH_UI and _G.NH_UI.SetStatus then
                                _G.NH_UI.SetStatus("AIRCRAFT TIMER COMPLETE - AWAITING MATCH")
                            end
                        end)
                    end
                end
            end

            -- MATCH PHASE
            if ctx == "Match" then
                if not State.proceeded then
                    task.wait(1)
                    if _G.NH_Clicker then _G.NH_Clicker("Proceed") end
                    State.proceeded = true
                    if _G.NH_UI and _G.NH_UI.SetStatus then _G.NH_UI.SetStatus("PROCEED CLICKED - ENTERING BATTLE") end
                end
                if not State.inBattle then
                    State.inBattle = true
                    if Combat.Start then Combat.Start() end
                    if ESP.Start then ESP.Start() end
                    if _G.NH_UI and _G.NH_UI.SetStatus then _G.NH_UI.SetStatus("BATTLE STARTED: 1 VS 14 BOTS") end
                end
            end

            -- END / RETURN PHASE
            if ctx == "Lobby" and State.inBattle then
                State.inBattle = false
                State.proceeded = false
                if Plane.reset then Plane.reset() end
                if Combat.Stop then Combat.Stop() end
                if ESP.Stop then ESP.Stop() end
                if _G.NH_UI and _G.NH_UI.SetStatus then _G.NH_UI.SetStatus("BATTLE ENDED - COLLECTING REWARDS") end
                task.wait(2)
                if _G.NH_Clicker then _G.NH_Clicker("Leave") end
                task.wait(1)
                if _G.NH_Clicker then _G.NH_Clicker("Continue") end
                if _G.NH_UI and _G.NH_UI.SetStatus then _G.NH_UI.SetStatus("REWARDS COLLECTED - RESTARTING LOOP") end
            end

            task.wait(1)
        end
    end)

    return { Init = function() end }
end
    return { Init = function() end }
end
