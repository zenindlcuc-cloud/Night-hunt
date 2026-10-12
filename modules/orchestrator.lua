local function factory(Deps)
    local Orchestrator = {}

    function Orchestrator.Init()
        local State = { inBattle = false, proceeded = false }

        task.spawn(function()
            while true do
                local Config = Deps.config or _G.NH_Config or {}
                local Place = Deps.place or _G.NH_Place
                local Clicker = Deps.clicker or _G.NH_Clicker
                local Combat = Deps.combat or _G.NH_Combat
                local ESP = Deps.esp or _G.NH_ESP
                local Plane = Deps.plane or _G.NH_Plane
                local UI = Deps.ui or _G.NH_UI

                local ctx = (Place and Place.GetContext and Place.GetContext()) or ((game.PlaceId == 102616257370565 or game.PlaceId == 97441945908384) and "Lobby" or "Match")

                -- LOBBY PHASE
                if ctx == "Lobby" and not State.inBattle then
                    if Config.AutoSeat and Plane and not Plane._seated then
                        if Plane.start then Plane.start() end
                    end
                    if Plane and Plane._seated and (Plane._elapsed or 0) < (Config.PlaneWaitTime or 60) then
                        if not Plane._thread then
                            Plane._thread = task.spawn(function()
                                while (Plane._elapsed or 0) < (Config.PlaneWaitTime or 60) do
                                    task.wait(1)
                                    Plane._elapsed = (Plane._elapsed or 0) + 1
                                end
                                if UI and UI.SetStatus then
                                    UI.SetStatus("AIRCRAFT TIMER COMPLETE - AWAITING MATCH")
                                end
                            end)
                        end
                    end
                end

                -- MATCH PHASE
                if ctx == "Match" then
                    if not State.proceeded then
                        task.wait(1)
                        if Clicker then Clicker("Proceed") end
                        State.proceeded = true
                        if UI and UI.SetStatus then UI.SetStatus("PROCEED CLICKED - ENTERING BATTLE") end
                    end
                    if not State.inBattle then
                        State.inBattle = true
                        if Combat and Combat.Start then Combat.Start() end
                        if ESP and ESP.Start then ESP.Start() end
                        if UI and UI.SetStatus then UI.SetStatus("BATTLE STARTED: 1 VS 14 BOTS") end
                    end
                end

                -- END / RETURN PHASE
                if ctx == "Lobby" and State.inBattle then
                    State.inBattle = false
                    State.proceeded = false
                    if Plane and Plane.reset then Plane.reset() end
                    if Combat and Combat.Stop then Combat.Stop() end
                    if ESP and ESP.Stop then ESP.Stop() end
                    if UI and UI.SetStatus then UI.SetStatus("BATTLE ENDED - COLLECTING REWARDS") end
                    task.wait(2)
                    if Clicker then Clicker("Leave") end
                    task.wait(1)
                    if Clicker then Clicker("Continue") end
                    if UI and UI.SetStatus then UI.SetStatus("REWARDS COLLECTED - RESTARTING LOOP") end
                end

                task.wait(1)
            end
        end)
    end

    return Orchestrator
end

return factory
