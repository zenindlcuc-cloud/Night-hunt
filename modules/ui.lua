local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function factory(Deps)
    local UI = {}

    function UI.Init(passedDeps)
        local d = passedDeps or Deps or _G.NH_Deps or {}
        local Theme = d.theme or _G.NH_Theme
        local Maid = d.maid or _G.NH_Maid
        local Config = d.config or _G.NH_Config
        local Place = d.place or _G.NH_Place
        local Clicker = d.clicker or _G.NH_Clicker
        local Movement = d.movement or _G.NH_Movement
        local ESP = d.esp or _G.NH_ESP
        local Combat = d.combat or _G.NH_Combat
        local Plane = d.plane or _G.NH_Plane

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        local function Create(class, props, children)
            local inst = Instance.new(class)
            for k, v in pairs(props) do inst[k] = v end
            if children then for _, c in ipairs(children) do c.Parent = inst end end
            return inst
        end

        local function GlassFrame(props, children)
            return Create("Frame", {
                BackgroundColor3 = Theme.GlassBg or Color3.fromRGB(30,28,53),
                BackgroundTransparency = 0.15,
                BorderSizePixel = 0,
                ClipsDescendants = true
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius and Theme.Radius.md or 10) }),
                Create("UIStroke", { Color = Theme.GlassBorder or Color3.fromRGB(76,29,149), Transparency = 0.3, Thickness = 1 }),
                Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, {
                    Create("UIGradient", {
                        Color = ColorSequence.new(Theme.GlassHighlight or Color3.fromRGB(124,58,237), Theme.GlassHighlight or Color3.fromRGB(124,58,237)),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.95),
                            NumberSequenceKeypoint.new(0.5, 0.99),
                            NumberSequenceKeypoint.new(1, 0.95)
                        }),
                        Rotation = 45
                    })
                })
            })
        end

        local function GlassButton(text, color, size, callback)
            local btn = Create("TextButton", {
                Size = size or UDim2.new(0, 140, 0, 38),
                BackgroundColor3 = color or Theme.Primary,
                Text = text,
                TextColor3 = Theme.OnPrimary or Color3.new(1,1,1),
                TextSize = 12,
                Font = Theme.FontHeader or Enum.Font.GothamBold,
                AutoButtonColor = false,
                ClipsDescendants = true
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, Theme.Radius and Theme.Radius.sm or 6) }),
                Create("UIStroke", { Color = Theme.BorderBright or Color3.fromRGB(124,58,237), Transparency = 0.5, Thickness = 1 }),
            })
            local hover = false
            btn.MouseEnter:Connect(function()
                hover = true
                TweenService:Create(btn, Theme.Easing and Theme.Easing.fast or TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
            end)
            btn.MouseLeave:Connect(function()
                hover = false
                TweenService:Create(btn, Theme.Easing and Theme.Easing.fast or TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
            end)
            btn.MouseButton1Down:Connect(function()
                TweenService:Create(btn, Theme.Easing and Theme.Easing.fast or TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.3,
                    Size = UDim2.new(0, btn.Size.X.Offset - 4, 0, btn.Size.Y.Offset - 2)
                }):Play()
            end)
            btn.MouseButton1Up:Connect(function()
                TweenService:Create(btn, Theme.Easing and Theme.Easing.spring or TweenInfo.new(0.3), {
                    BackgroundTransparency = hover and 0.1 or 0,
                    Size = size or UDim2.new(0, 140, 0, 38)
                }):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            return btn
        end

        local function GlassToggle(label, default, callback)
            local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 })
            Create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Foreground or Color3.new(1,1,1),
                TextSize = 13,
                Font = Theme.FontBody or Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {}, frame)
            local track = Create("Frame", {
                Size = UDim2.new(0, 52, 0, 28),
                Position = UDim2.new(1, -52, 0.5, -14),
                BackgroundColor3 = default and Theme.Primary or (Theme.MutedFG or Color3.fromRGB(148,163,184)),
                BorderSizePixel = 0
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Create("UIStroke", { Color = Theme.Border or Color3.fromRGB(76,29,149), Transparency = 0.5 })
            }, frame)
            local thumb = Create("Frame", {
                Size = UDim2.new(0, 22, 0, 22),
                Position = default and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
                BackgroundColor3 = Theme.OnPrimary or Color3.new(1,1,1),
                BorderSizePixel = 0
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            }, track)

            local state = default
            local function setState(s, anim)
                state = s
                local ti = anim and TweenInfo.new(0.2) or TweenInfo.new(0)
                TweenService:Create(track, ti, { BackgroundColor3 = s and Theme.Primary or Theme.MutedFG }):Play()
                TweenService:Create(thumb, ti, { Position = s and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11) }):Play()
                if callback then callback(s) end
            end
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    setState(not state, true)
                end
            end)
            return frame
        end

        local function GlassSlider(label, min, max, default, callback)
            local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1 })
            local value = default
            local lbl = Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = label .. ": " .. tostring(value),
                TextColor3 = Theme.Foreground or Color3.new(1,1,1),
                TextSize = 12,
                Font = Theme.FontBody or Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {}, frame)
            local track = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundColor3 = Theme.MutedFG or Color3.fromRGB(148,163,184),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }, frame)
            local fill = Create("Frame", {
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Primary,
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }, track)
            local handle = Create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
                BackgroundColor3 = Theme.OnPrimary or Color3.new(1,1,1),
                BorderSizePixel = 0,
                ZIndex = 2
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }, track)

            local dragging = false
            local function upd(x)
                local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel + 0.5)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                handle.Position = UDim2.new(rel, -8, 0.5, -8)
                lbl.Text = label .. ": " .. tostring(value)
                if callback then callback(value) end
            end
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    upd(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    upd(inp.Position.X)
                end
            end)
            return frame
        end

        local function GlassCard(title, children)
            local card = GlassFrame({
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 0.1
            })
            Create("UIListLayout", {
                Padding = UDim.new(0, Theme.Space and Theme.Space.md or 12),
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            }, {}, card)
            Create("UIPadding", {
                PaddingTop = UDim.new(0, Theme.Space and Theme.Space.lg or 16),
                PaddingBottom = UDim.new(0, Theme.Space and Theme.Space.lg or 16),
                PaddingLeft = UDim.new(0, Theme.Space and Theme.Space.lg or 16),
                PaddingRight = UDim.new(0, Theme.Space and Theme.Space.lg or 16)
            }, {}, card)
            if title then
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = title,
                    TextColor3 = Theme.Accent or Color3.fromRGB(244,63,94),
                    TextSize = 11,
                    Font = Theme.FontHeader or Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTransparency = 0.3
                }, {}, card)
            end
            if children then
                for _, c in ipairs(children) do c.Parent = card end
            end
            return card
        end

        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        local old = parent:FindFirstChild("NightHuntUI")
        if old then old:Destroy() end

        local sg = Create("ScreenGui", {
            Name = "NightHuntUI",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        if Maid and Maid.Give then Maid:Give(sg) end

        local main = GlassFrame({
            Name = "MainWindow",
            Size = UDim2.new(0, 480, 0, 520),
            Position = UDim2.new(0.5, -240, 0.5, -260),
            BackgroundTransparency = 0.1,
            Active = true,
            Draggable = true
        })
        main.Parent = sg

        local titleBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 2 }, {}, main)
        Create("TextLabel", {
            Size = UDim2.new(1, -100, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            BackgroundTransparency = 1,
            Text = "NIGHT HUNT",
            TextColor3 = Theme.Foreground or Color3.new(1,1,1),
            TextSize = 16,
            Font = Theme.FontHeader or Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {}, titleBar)

        local tabBar = Create("Frame", { Size = UDim2.new(1, -32, 0, 40), Position = UDim2.new(0, 16, 0, 52), BackgroundTransparency = 1 }, {}, main)
        Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, {}, tabBar)

        local content = Create("Frame", { Size = UDim2.new(1, -32, 1, -120), Position = UDim2.new(0, 16, 0, 98), BackgroundTransparency = 1, ClipsDescendants = true }, {}, main)

        local statusBar = Create("Frame", { Size = UDim2.new(1, -32, 0, 28), Position = UDim2.new(0, 16, 1, -32), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2, BorderSizePixel = 0 }, {}, main)
        local statusLabel = Create("TextLabel", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "STATUS: INITIALIZING...", TextColor3 = Theme.Primary, TextSize = 11, Font = Theme.FontMono or Enum.Font.RobotoMono, TextXAlignment = Enum.TextXAlignment.Left }, {}, statusBar)

        local tabs, currentTab = {}, nil
        local function createTab(name)
            local btn = Create("TextButton", {
                Size = UDim2.new(0, 80, 1, 0),
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0.3,
                Text = name,
                TextColor3 = Theme.MutedFG,
                TextSize = 11,
                Font = Theme.FontHeader or Enum.Font.GothamBold,
                BorderSizePixel = 0
            }, {}, tabBar)
            local page = Create("ScrollingFrame", {
                Name = name .. "Page",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Visible = false,
                ScrollBarThickness = 4,
                AutomaticCanvasSize = Enum.AutomaticSize.Y
            }, {
                Create("UIListLayout", { Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 24) })
            }, content)

            tabs[name] = { btn = btn, page = page }
            btn.MouseButton1Click:Connect(function() UI.SwitchTab(name) end)
        end

        function UI.SwitchTab(name)
            currentTab = name
            for n, t in pairs(tabs) do
                local active = (n == name)
                t.page.Visible = active
                t.btn.TextColor3 = active and (Theme.Foreground or Color3.new(1,1,1)) or (Theme.MutedFG or Color3.fromRGB(148,163,184))
            end
        end

        function UI.SetStatus(text)
            if statusLabel then
                statusLabel.Text = "STATUS: " .. text
            end
        end

        createTab("MAIN")
        createTab("VISUALS")
        createTab("COMBAT")
        createTab("MOVE")
        createTab("CONFIG")
        UI.SwitchTab("MAIN")

        GlassCard("SESSION STATUS", {
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundTransparency = 1,
                Text = "AUTO-LOOP ACTIVE\nLobby -> Aircraft -> Battle -> Rewards",
                TextColor3 = Theme.MutedFG or Color3.fromRGB(148,163,184),
                TextSize = 11,
                Font = Theme.FontMono or Enum.Font.RobotoMono,
                TextXAlignment = Enum.TextXAlignment.Center
            })
        }).Parent = tabs.MAIN.page

        GlassButton("RETURN TO VIP LOBBY", Theme.Destructive, UDim2.new(1, -16, 0, 44), function()
            UI.SetStatus("EMERGENCY RETURN INITIATED")
            if Place and Place.SafeReturnToVIP then Place.SafeReturnToVIP(Config) end
        end).Parent = tabs.MAIN.page

        GlassCard("ENTITY VISUALIZATION", {
            GlassToggle("ESP Players", Config.ESP_Enabled or true, function(v)
                Config.ESP_Enabled = v
                if ESP then if v then ESP.Start() else ESP.Stop() end end
            end)
        }).Parent = tabs.VISUALS.page

        GlassCard("AUTO COMBAT", {
            GlassToggle("Auto Kill Bots", Config.AutoKill or true, function(v)
                Config.AutoKill = v
                if Combat then if v then Combat.Start() else Combat.Stop() end end
            end)
        }).Parent = tabs.COMBAT.page

        GlassCard("PHYSICS OVERRIDE", {
            GlassToggle("Noclip", Config.Noclip or true, function(v)
                Config.Noclip = v
                if Movement then if v then Movement.Start() else Movement.Stop() end end
            end)
        }).Parent = tabs.MOVE.page

        GlassCard("AIRCRAFT SEQUENCE", {
            GlassSlider("Wait Time (s)", 10, 180, Config.PlaneWaitTime or 60, function(v)
                Config.PlaneWaitTime = v
            end)
        }).Parent = tabs.CONFIG.page

        sg.Parent = parent
        UI.SetStatus("SYSTEM READY")
    end

    return UI
end

return factory
