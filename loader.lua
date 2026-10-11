-- loader.lua (в корне репозитория)
local BASE = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/modules/"

local function httpGet(url, retries)
    retries = retries or 3
    for i = 1, retries do
        local ok, result = pcall(function() return game:HttpGet(url) end)
        if ok and result and #result > 0 then return result end
        task.wait(0.5)
    end
    return nil
end

local function loadModule(name)
    local src = httpGet(BASE .. name .. ".lua")
    if not src then return nil end
    local ok, factory = pcall(loadstring, src, name)
    if not ok then return nil end
    return factory
end

local Deps = {}
local modules = {"theme","config","maid","place","clicker","movement","esp","combat","plane","ui","orchestrator"}

for _, name in ipairs(modules) do
    local factory = loadModule(name)
    if factory then
        local ok, mod = pcall(factory, Deps)
        if ok and mod then
            Deps[name] = mod
            print("[NH] Loaded: " .. name)
        else
            warn("Module factory failed: " .. name .. " - " .. tostring(mod))
        end
    else
        warn("Failed to fetch: " .. name)
    end
end

-- ===== FALLBACKS FOR CRITICAL DEPS =====
if not Deps.theme then
    Deps.theme = {
        Primary = Color3.fromHex("#7C3AED"), Accent = Color3.fromHex("#F43F5E"),
        Success = Color3.fromHex("#22C55E"), Background = Color3.fromHex("#0F0F23"),
        Surface = Color3.fromHex("#1E1C35"), Foreground = Color3.fromHex("#E2E8F0"),
        MutedFG = Color3.fromHex("#94A3B8"), Border = Color3.fromHex("#4C1D95"),
        BorderBright = Color3.fromHex("#7C3AED"), Destructive = Color3.fromHex("#EF4444"),
        OnPrimary = Color3.new(1,1,1), OnDestructive = Color3.new(1,1,1),
        GlassBg = Color3.fromHex("#1E1C35"), GlassBorder = Color3.fromHex("#4C1D95"),
        GlassHighlight = Color3.fromHex("#7C3AED"),
        FontHeader = Enum.Font.GothamBold, FontMono = Enum.Font.RobotoMono, FontBody = Enum.Font.GothamMedium,
        Space = {xs=4,sm=8,md=12,lg=16,xl=24,xxl=32},
        Radius = {sm=6,md=10,lg=16},
        Easing = {fast=TweenInfo.new(0.15), normal=TweenInfo.new(0.25), spring=TweenInfo.new(0.4,Enum.EasingStyle.Back)},
    }
end

if not Deps.config then
    Deps.config = {
        ESP_Enabled=true, ESP_PlayersColor=nil, ESP_BotsColor=nil,
        Noclip=true, NoCollision=true, AutoKill=true,
        AttackDistance=2.5, HeightOffset=1.0, FastAttack=true,
        TargetRadius=600, ScanInterval=0.25,
        AutoSeat=true, PlaneWaitTime=60, Anti773Fallback=102616257370565,
    }
end

if not Deps.maid then
    Deps.maid = { _tasks = {} }
    function Deps.maid:Give(t) table.insert(self._tasks, t); return t end
    function Deps.maid:Cleanup() for _,t in ipairs(self._tasks) do if typeof(t)=="RBXScriptConnection" then t:Disconnect() elseif typeof(t)=="Instance" then t:Destroy() elseif type(t)=="function" then pcall(t) end end table.clear(self._tasks) end
end

-- ===== GLOBAL REGISTRY FOR ORCHESTRATOR =====
_G.NH_Config = Deps.config
_G.NH_Maid = Deps.maid
_G.NH_Place = Deps.place
_G.NH_Clicker = Deps.clicker
_G.NH_UI = Deps.ui
_G.NH_Plane = Deps.plane
_G.NH_Combat = Deps.combat
_G.NH_ESP = Deps.esp
_G.NH_Clicker = Deps.clicker
_G.NH_Maid = Deps.maid
_G.NH_Config = Deps.config
_G.NH_Place = Deps.place

-- ===== INITIALIZE UI =====
if Deps.ui and Deps.ui.Init then
    Deps.ui.Init(
        Deps.theme, Deps.maid, Deps.config, Deps.place, Deps.clicker,
        Deps.movement, Deps.esp, Deps.combat, Deps.plane
    end
    _G.NH_UI = Deps.ui  -- глобальная ссылка для orchestrator'а
end

if Deps.orchestrator and Deps.orchestrator.Init then
    Deps.orchestrator.Init()
end

print("[NH] Loader complete.")
