local function factory(Deps)
    return {
        ESP_Enabled = true,
        ESP_PlayersColor = Color3.fromRGB(0, 255, 0),
        ESP_BotsColor = Color3.fromRGB(255, 0, 0),
        Noclip = true,
        NoCollision = true,
        AutoKill = true,
        AttackDistance = 2.5,
        HeightOffset = 1.0,
        FastAttack = true,
        TargetRadius = 600,
        ScanInterval = 0.25,
        AutoSeat = true,
        PlaneWaitTime = 60,
        Anti773Fallback = 102616257370565
    }
end

return factory
