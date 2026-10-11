-- modules/ui.lua
-- Glassmorphism UI для Night Hunt v3.1
-- Возвращает фабрику: function(Deps) -> UI table

return function(Deps)
    -- ===== DEPENDENCIES =====
    local Theme     = Deps.theme
    local Maid      = Deps.maid
    local Config    = Deps.config
    local Place     = Deps.place
    local Clicker   = Deps.clicker
    local Movement  = Deps.movement
    local ESP       = Deps.esp
    local Combat    = Deps.combat
    local Plane     = Deps.plane
    local startPlaneSequence = Deps.startPlaneSequence
    local resetPlaneState   = Deps.resetPlaneState

    -- ===== SERVICES =====
    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local TweenService     = game:GetService("TweenService")
    local VirtualUser      = game:GetService("VirtualUser")
    local CoreGui          = game:GetService("CoreGui")
    local TeleportService  = game:GetService("TeleportService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer      = Players.LocalPlayer

    -- ===== HELPERS =====
    local function Create(class, props, children)
        local inst = Instance.new(class)
        for k, v in pairs(props) do inst[k] = v end
        if children then for _, c in ipairs(children) do c.Parent = inst end end
        return inst
    end

    -- ===== GLASS COMPONENTS =====
    local function GlassFrame(props)
        return Create("Frame", {
            BackgroundColor3 = Theme.GlassBg,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.md) }),
            Create("UIStroke", { Color = Theme.GlassBorder, Transparency = 0.3, Thickness = 1 }),
            Create("Frame", { -- Inner glow
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            }, {
                Create("UIGradient", {
                    Color = ColorSequence.new(Theme.GlassHighlight, Theme.GlassHighlight),
                    Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(0.5, 0.99), NumberSequenceKeypoint.new(1, 0.95) }),
                    Rotation = 45,
                })
            })
        }, props)
    end

    local function GlassButton(text, color, size, callback)
        local btn = Create("TextButton", {
            Size = size or UDim2.new(0, 140, 0, 38),
            BackgroundColor3 = color or Theme.Primary,
            BackgroundTransparency = 0,
            Text = text,
            TextColor3 = Theme.OnPrimary,
            TextSize = 12,
            Font = Theme.FontHeader,
            AutoButtonColor = false,
            ClipsDescendants = true,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }),
            Create("UIStroke", { Color = Theme.BorderBright, Transparency = 0.5, Thickness = 1 }),
        })
        local hover = false
        btn.MouseEnter:Connect(function() hover = true; TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.1 }):Play() end)
        btn.MouseLeave:Connect(function() hover = false; TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0 }):Play() end)
        btn.MouseButton1Down:Connect(function() TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.3, Size = UDim2.new(0, (size and size.X.Offset or 140) - 4, 0, (size and size.Y.Offset or 38) - 2) }):Play() end)
        btn.MouseButton1Up:Connect(function() TweenService:Create(btn, Theme.Easing.spring, { BackgroundTransparency = hover and 0.1 or 0, Size = size or UDim2.new(0, 140, 0, 38) }):Play() end)
        btn.MouseButton1Click:Connect(function() if callback then callback() end end)
        return btn
    end

    local function GlassToggle(label, default, callback)
        local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 })
        Create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.Foreground, TextSize = 13, Font = Theme.FontBody, TextXAlignment = Enum.TextXAlignment.Left }, { frame })
        local track = Create("Frame", { Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -52, 0.5, -14), BackgroundColor3 = default and Theme.Primary or Theme.Muted, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }) }, { frame })
        local thumb = Create("Frame", { Size = UDim2.new(0, 22, 0, 22), Position = default and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11), BackgroundColor3 = Theme.OnPrimary, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = Theme.Shadow, Transparency = 0.8, Thickness = 1 }) }, { track })
        local state = default
        local function setState(s, animate)
            state = s
            local ti = animate and Theme.Easing.normal or TweenInfo.new(0)
            TweenService:Create(track, ti, { BackgroundColor3 = s and Theme.Primary or Theme.Muted }):Play()
            TweenService:Create(thumb, ti, { Position = s and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11) }):Play()
            if callback then callback(s) end
        end
        track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state, true) end end)
        return frame, function() return state end, function(s) setState(s, true) end
    end

    local function GlassSlider(label, min, max, default, callback)
        local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1 })
        local value = default
        local lbl = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = label .. ": " .. value, TextColor3 = Theme.Foreground, TextSize = 12, Font = Theme.FontBody, TextXAlignment = Enum.TextXAlignment.Left }, { frame })
        local track = Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Theme.Muted, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }, { frame })
        local fill = Create("Frame", { Size = UDim2.new((default-min)/(max-min), 1, 0), BackgroundColor3 = Theme.Primary, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIGradient", { Color = ColorSequence.new(Theme.Primary, Theme.Secondary), Rotation = 90 }) }, { track })
        local handle = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new((default-min)/(max-min), -8, 0.5, -8), BackgroundColor3 = Theme.OnPrimary, BorderSizePixel = 0, ZIndex = 2 }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = Theme.Shadow, Transparency = 0.7, Thickness = 2 }) }, { track })
        local dragging = false
        local function updateFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            handle.Position = UDim2.new(rel, -8, 0.5, -8)
            lbl.Text = label .. ": " .. value
            if callback then callback(value) end
        end
        track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateFromX(inp.Position.X) end end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(inp.Position.X) end end)
        return frame
    end

    local function GlassCard(title, children)
        local card = GlassFrame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.1 })
        Create("UIListLayout", { Padding = UDim.new(0, Theme.Space.md), HorizontalAlignment = Enum.HorizontalAlignment.Center }, { card })
        Create("UIPadding", { PaddingTop = UDim.new(0, Theme.Space.lg), PaddingBottom = UDim.new(0, Theme.Space.lg), PaddingLeft = UDim.new(0, Theme.Space.lg), PaddingRight = UDim.new(0, Theme.Space.lg) }, { card })
        if title then Create("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Secondary, TextSize = 11, Font = Theme.FontHeader, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.3 }, { card }) end
        if children then for _, c in ipairs(children) do c.Parent = card end end
        return card
    end

    -- ===== UI MODULE =====
    local UI = {}
    local sg, main, statusLabel, tabs, tabPages, currentTab = nil, nil, nil, {}, {}, "Main"

    function UI.Init()
        -- Parent
        local parent = (gethui and gethui()) or CoreGui
        local old = parent:FindFirstChild("NightHuntUI"); if old then old:Destroy() end

        sg = Create("ScreenGui", { Name = "NightHuntUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, { Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false }) })
        Maid:Give(sg)

        -- Main Window
        main = GlassFrame({ Name = "MainWindow", Size = UDim2.new(0, 480, 0, 520), Position = UDim2.new(0.5, -240, 0.5, -260), BackgroundTransparency = 0.1, Active = true, Draggable = true }, {
            Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.lg) }),
            Create("UIStroke", { Color = Theme.BorderBright, Transparency = 0.4, Thickness = 1.5 }),
            Create("UIGradient", { Color = ColorSequence.new(Theme.GlassHighlight, Theme.GlassHighlight), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.5, 0.98), NumberSequenceKeypoint.new(1, 0.92) }), Rotation = 135 }),
        }, { sg })

        -- Title Bar
        local titleBar = Create("Frame", { Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, ZIndex = 2 }, { main })
        Create("TextLabel", { Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0, Theme.Space.lg, 0,0), BackgroundTransparency = 1, Text = "NIGHT HUNT", TextColor3 = Theme.Foreground, TextSize = 16, Font = Theme.FontHeader, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.8, TextStrokeColor3 = Theme.Primary }, { titleBar })
        Create("TextLabel", { Size = UDim2.new(1,-100,0,14), Position = UDim2.new(0, Theme.Space.lg, 1,-14), BackgroundTransparency = 1, Text = "v3.1  •  VIP LOOP  •  GLASSMORPHISM", TextColor3 = Theme.MutedFG, TextSize = 9, Font = Theme.FontMono, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.4 }, { titleBar })

        -- Window Controls
        local controls = Create("Frame", { Size = UDim2.new(0,80,1,0), Position = UDim2.new(1,-80,0,0), BackgroundTransparency = 1 }, { titleBar })
        local minimizeBtn = Create("TextButton", { Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-70,0.5,-16), BackgroundColor3 = Theme.Muted, BackgroundTransparency = 0.5, Text = "−", TextColor3 = Theme.Foreground, TextSize = 18, Font = Theme.FontHeader, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }), Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }) }, { controls })
        local closeBtn = Create("TextButton", { Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-35,0.5,-16), BackgroundColor3 = Theme.Destructive, BackgroundTransparency = 0.5, Text = "✕", TextColor3 = Theme.OnDestructive, TextSize = 14, Font = Theme.FontHeader, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }) }, { controls })

        -- Tab Bar
        local tabBar = Create("Frame", { Size = UDim2.new(1, -Theme.Space.xl*2, 0, 40), Position = UDim2.new(0, Theme.Space.lg, 0, 52), BackgroundTransparency = 1 }, { main })
        Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Theme.Space.sm), HorizontalAlignment = Enum.HorizontalAlignment.Left }, { tabBar })

        -- Content Container
        local content = Create("Frame", { Name = "Content", Size = UDim2.new(1, -Theme.Space.xl*2, 1, -120), Position = UDim2.new(0, Theme.Space.lg, 0, 98), BackgroundTransparency = 1, ClipsDescendants = true }, { main })

        -- Status Bar
        local statusBar = Create("Frame", { Size = UDim2.new(1, -Theme.Space.xl*2, 0, 28), Position = UDim2.new(0, Theme.Space.lg, 1, -Theme.Space.xl), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }), Create("UIStroke", { Color = Theme.Border, Transparency = 0.5 }) }, { main })
        statusLabel = Create("TextLabel", { Size = UDim2.new(1, -Theme.Space.lg*2, 1, 0), Position = UDim2.new(0, Theme.Space.lg, 0, 0), BackgroundTransparency = 1, Text = "SYSTEM INITIALIZING...", TextColor3 = Theme.Primary, TextSize = 11, Font = Theme.FontMono, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.9 }, { statusBar })

        -- Tab System
        local tabPages, tabButtons = {}, {}
        local function createTab(name)
            local btn = Create("TextButton", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.3, Text = name, TextColor3 = Theme.MutedFG, TextSize = 11, Font = Theme.FontHeader, BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.sm) }), Create("UIStroke", { Color = Theme.Border, Transparency = 0.6 }), Create("Frame", { Name = "Indicator", Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2), BackgroundColor3 = Theme.Primary, BackgroundTransparency = 1, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius.full) }) }) }, { tabBar })
            local page = Create("ScrollingFrame", { Name = name.."Page", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Primary, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, { Create("UIListLayout", { Padding = UDim.new(0, Theme.Space.md), HorizontalAlignment = Enum.HorizontalAlignment.Center }), Create("UIPadding", { PaddingTop = UDim.new(0, Theme.Space.md), PaddingBottom = UDim.new(0, Theme.Space.xl), PaddingLeft = UDim.new(0, Theme.Space.md), PaddingRight = UDim.new(0, Theme.Space.md) }) }, { content })
            local t = { btn = btn, page = page }
            tabs[name] = t
            btn.MouseButton1Click:Connect(function() UI.SwitchTab(name) end)
            btn.MouseEnter:Connect(function() if currentTab ~= name then TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.1, TextColor3 = Theme.Foreground }):Play() end end)
            btn.MouseLeave:Connect(function() if currentTab ~= name then TweenService:Create(btn, Theme.Easing.fast, { BackgroundTransparency = 0.3, TextColor3 = Theme.MutedFG }):Play() end end)
        end

        function UI.SwitchTab(name)
            currentTab = name
            for n, t in pairs(tabs) do
                local active = (n == name)
                t.page.Visible = active
                TweenService:Create(t.btn, Theme.Easing.normal, { BackgroundTransparency = active and 0 or 0.3, TextColor3 = active and Theme.Foreground or Theme.MutedFG }):Play()
                local ind = t.btn:FindFirstChild("Indicator")
                if ind then TweenService:Create(ind, Theme.Easing.spring, { BackgroundTransparency = active and 0 or 1 }):Play() end
            end
        end

        function UI.SetStatus(text)
            if statusLabel then
                statusLabel.Text = "STATUS: " .. text
                local tw = TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { TextColor3 = Theme.Accent })
                tw:Play()
                task.wait(0.3)
                TweenService:Create(statusLabel, Theme.Easing.fast, { TextColor3 = Theme.Primary }):Play()
            end
        end

        -- Create Tabs
        createTab("MAIN")
        createTab("VISUALS")
        createTab("COMBAT")
        createTab("MOVE")
        createTab("CONFIG")
        UI.SwitchTab("Main")

        -- ========== POPULATE TABS ==========
        -- MAIN
        GlassCard("SESSION STATUS", { Create("TextLabel", { Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, Text = "AUTO-LOOP ACTIVE\nLobby → Aircraft → Battle → Rewards → Repeat\n\nESC: Toggle UI  |  INSERT: Force Return", TextColor3 = Theme.MutedFG, TextSize = 11, Font = Theme.FontMono, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }) }).Parent = tabs.Main.page
        GlassButton("RETURN TO VIP LOBBY", Theme.Destructive, UDim2.new(1, -Theme.Space.md*2, 0, 44), function() UI.SetStatus("EMERGENCY RETURN TO VIP LOBBY"); Place.SafeReturnToVIP(Config) end).Parent = tabs.Main.page

        -- Stats row
        local statsFrame = Create("Frame", { Size = UDim2.new(1,0,0,80), BackgroundTransparency = 1 })
        Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Theme.Space.sm), HorizontalAlignment = Enum.HorizontalAlignment.Center }, { statsFrame })
        local function statBox(label, value, color)
            return GlassFrame({ Size = UDim2.new(0, 110, 0, 70), BackgroundTransparency = 0.2 }, { Create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }), Create("TextLabel", { Size = UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=label, TextColor3=Theme.MutedFG, TextSize=9, Font=Theme.FontMono }), Create("TextLabel", { Size = UDim2.new(1,0,0,22), BackgroundTransparency=1, Text=value, TextColor3=color or Theme.Primary, TextSize=18, Font=Theme.FontHeader }) })
        end
        statBox("PLACE", "LOBBY", Theme.Primary).Parent = statsFrame
        statBox("MODE", "VIP", Theme.Success).Parent = statsFrame
        statBox("TARGET", "14 BOTS", Theme.Accent).Parent = statsFrame
        statsFrame.Parent = tabs.Main.page

        GlassButton("FORCE RETURN TO VIP", Theme.Destructive, UDim2.new(1, -Theme.Space.md*2, 0, 36), function() UI.SetStatus("FORCE RETURN INITIATED"); Place.SafeReturnToVIP(Config) end).Parent = tabs.Main.page

        -- VISUALS
        GlassCard("ENTITY VISUALIZATION", { GlassToggle("ESP Players", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then Deps.esp.Start() else Deps.esp.Stop() end end), GlassToggle("ESP Bots", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v; if v then Deps.esp.Start() else Deps.esp.Stop() end end) }).Parent = tabs.Visuals.page

        -- COMBAT
        GlassCard("AUTO COMBAT", { GlassToggle("Auto Kill (Bots Only)", Config.AutoKill, function(v) Config.AutoKill = v; if v and Place.IsMatch() then Deps.combat.Start() else Deps.combat.Stop() end end), GlassToggle("Fast Attack (VirtualUser)", Config.FastAttack, function(v) Config.FastAttack = v end) }).Parent = tabs.Combat.page
        GlassCard("TARGETING PARAMETERS", { GlassSlider("Attack Distance", 1, 10, Config.AttackDistance, function(v) Config.AttackDistance = v end), GlassSlider("Height Offset", 0, 5, Config.HeightOffset, function(v) Config.HeightOffset = v end), GlassSlider("Target Radius", 100, 2000, Config.TargetRadius, function(v) Config.TargetRadius = v end), GlassSlider("Scan Interval (s)", 0.1, 1, Config.ScanInterval, function(v) Config.ScanInterval = v end) }).Parent = tabs.Combat.page
        GlassCard("BLACKLIST (Case-Insensitive)").Parent = tabs.Combat.page -- можно добавить список позже

        -- MOVE
        GlassCard("PHYSICS OVERRIDE", { GlassToggle("Noclip (Local Character)", Config.Noclip, function(v) Config.Noclip = v; if v then Deps.movement.Start() else Deps.movement.Stop() end end), GlassToggle("No Collision (Others)", Config.NoCollision, function(v) Config.NoCollision = v end) }).Parent = tabs.Move.page

        -- CONFIG
        GlassCard("AIRCRAFT SEQUENCE", { GlassSlider("Plane Wait Time (s)", 10, 180, Config.PlaneWaitTime, function(v) Config.PlaneWaitTime = v end), GlassToggle("Auto Seat in Aircraft", Config.AutoSeat, function(v) Config.AutoSeat = v end) }).Parent = tabs.Config.page
        GlassCard("SAFETY & TELEPORT", { GlassButton("Force Re-scan ESP", Theme.Secondary, UDim2.new(0.5, -4, 0, 36), function() Deps.esp.Stop(); Deps.esp.Start(); UI.SetStatus("ESP RE-SCAN COMPLETE") end), GlassButton("Force Return to VIP", Theme.Destructive, UDim2.new(0.5, -4, 0, 36), function() Place.SafeReturnToVIP(Config) end) }).Parent = tabs.Config.page
        GlassCard("UI BEHAVIOR", { GlassButton("Minimize UI", Theme.Muted, UDim2.new(0.5, -4, 0, 36), function() main.Visible = false; UI.SetStatus("UI MINIMIZED - PRESS INSERT TO RESTORE") end), GlassButton("Destroy UI", Theme.Destructive, UDim2.new(0.5, -4, 0, 36), function() sg:Destroy() end) }).Parent = tabs.Config.page
        Create("TextLabel", { Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Text = "NIGHT HUNT v3.1 — GLASSMORPHISM EDITION\nDESIGN: GAMING PALETTE • GLASSMORPHISM • CYBERPUNK TYPO\nREPO: GITHUB.COM/ZENINDLCUC-CLOUD/NIGHT-HUNT", TextColor3 = Theme.MutedFG, TextSize = 9, Font = Theme.FontMono, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextTransparency = 0.5 }, { tabs.Config.page })

        -- Minimize / Close / Hotkeys
        local minimized = false
        minimizeBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            tabs.Main.page.Parent.Visible = not minimized -- content
            tabBar.Visible = not minimized
            statusBar.Visible = not minimized
            TweenService:Create(main, Theme.Easing.normal, { Size = minimized and UDim2.new(0, 480, 0, 48) or UDim2.new(0, 480, 0, 520) }):Play()
            minimizeBtn.Text = minimized and "+" or "−"
        end)
        closeBtn.MouseButton1Click:Connect(function() main.Visible = false; UI.SetStatus("UI HIDDEN - PRESS INSERT TO RESTORE") end)

        UserInputService.InputBegan:Connect(function(inp, gp)
            if not gp and inp.KeyCode == Enum.KeyCode.Insert then
                main.Visible = not main.Visible
                UI.SetStatus(main.Visible and "UI RESTORED" or "UI HIDDEN")
            end
        end)

        -- Entrance animation
        main.Size = UDim2.new(0, 480, 0, 0)
        main.BackgroundTransparency = 1
        TweenService:Create(main, Theme.Easing.spring, { Size = UDim2.new(0, 480, 0, 520), BackgroundTransparency = 0.1 }):Play()

        print("[NH UI]: Glassmorphism UI initialized.")
    end

    return UI
end