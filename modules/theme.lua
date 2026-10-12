local function factory(Deps)
    return {
        Primary = Color3.fromHex("#7C3AED"),
        Accent = Color3.fromHex("#F43F5E"),
        Success = Color3.fromHex("#22C55E"),
        Destructive = Color3.fromHex("#EF4444"),
        Background = Color3.fromHex("#0F0F23"),
        Surface = Color3.fromHex("#1E1C35"),
        Foreground = Color3.fromHex("#E2E8F0"),
        MutedFG = Color3.fromHex("#94A3B8"),
        Border = Color3.fromHex("#4C1D95"),
        BorderBright = Color3.fromHex("#7C3AED"),
        OnPrimary = Color3.new(1, 1, 1),
        OnDestructive = Color3.new(1, 1, 1),
        GlassBg = Color3.fromHex("#1E1C35"),
        GlassBorder = Color3.fromHex("#4C1D95"),
        GlassHighlight = Color3.fromHex("#7C3AED"),
        FontHeader = Enum.Font.GothamBold,
        FontMono = Enum.Font.RobotoMono,
        FontBody = Enum.Font.GothamMedium,
        Space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 },
        Radius = { sm = 6, md = 10, lg = 16 },
        Easing = {
            fast = TweenInfo.new(0.15),
            normal = TweenInfo.new(0.25),
            spring = TweenInfo.new(0.4, Enum.EasingStyle.Back)
        }
    }
end

return factory
