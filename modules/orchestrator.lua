return function(Config, Place, Clicker, Combat, ESP, Plane, UI, startPlaneSequence, resetPlaneState)
    local State = { inBattle = false, proceeded = false }
    task.spawn(function()
        while true do
            local ctx = Place.GetContext()
            if ctx == "Lobby" and not State.inBattle then
                if Config.AutoSeat and not Plane._seated then startPlaneSequence() end
                if Plane._seated and Plane._elapsed < Config.PlaneWaitTime then
                    if not Plane._thread then
                        Plane._thread = task.spawn(function()
                            while Plane._elapsed < Config.PlaneWaitTime do task.wait(1); Plane._elapsed += 1 end
                            UI.SetStatus("AIRCRAFT TIMER COMPLETE - AWAITING MATCH")
                        end)
                    end
                end
            end
            if ctx == "Match" then
                if not State.proceeded then task.wait(1); Clicker("Proceed"); State.proceeded = true; UI.SetStatus("PROCEED CLICKED - ENTERING BATTLE") end
                if not State.inBattle then State.inBattle = true; Combat.Start(); ESP.Start(); UI.SetStatus("BATTLE STARTED: 1 VS 14 BOTS") end
            end
            if ctx == "Lobby" and State.inBattle then
                State.inBattle = false; State.proceeded = false; resetPlaneState()
                Combat.Stop(); ESP.Stop()
                UI.SetStatus("BATTLE ENDED - COLLECTING REWARDS")
                task.wait(2); Clicker("Leave")
                task.wait(1); Clicker("Continue")
                UI.SetStatus("REWARDS COLLECTED - RESTARTING LOOP")
            end
            task.wait(1)
        end
    end)
    return { Init = function() end }
end
