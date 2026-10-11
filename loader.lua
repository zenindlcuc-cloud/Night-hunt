-- loader.lua (GitHub root)
local BASE = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/modules/"

local function httpGet(url)
    local requestFunc = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    
    if requestFunc then
        local ok, result = pcall(function() 
            return requestFunc({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Roblox/Delta (Windows; U; en-US)"
                }
            })
        end)
        if not ok then
            warn("[NH Loader] Request failed with error: " .. tostring(result))
        elseif type(result) == "table" then
            if result.StatusCode == 200 then
                return result.Body
            else
                warn("[NH Loader] Request returned status code: " .. tostring(result.StatusCode) .. " for URL: " .. url)
            end
        else
            warn("[NH Loader] Request returned unexpected result type: " .. type(result))
        end
    end

    -- Fallback to game:HttpGet
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and type(result) == "string" and #result > 0 then 
        return result 
    else
        warn("[NH Loader] game:HttpGet failed or returned invalid data: " .. tostring(result))
    end
    
    return nil
end

local function loadMod(name)
    local url = BASE .. name .. ".lua"
    local src = httpGet(url)
    if not src then 
        warn("[NH Loader] Could not fetch source for module: " .. name)
        return nil 
    end
    
    local fn, err = loadstring(src, name)
    if not fn then 
        warn("[NH Loader] Syntax error in module " .. name .. ": " .. tostring(err))
        return nil 
    end
    
    return fn
end

local function main()
    local mods = {"theme","config","maid","place","clicker","movement","esp","combat","plane","ui","orchestrator"}

    print("[NH Loader] Starting...")
    for _, name in ipairs(mods) do
        local fn = loadMod(name)
        if fn then
            local ok, mod = pcall(fn, _G.NH_Deps or {})
            if ok and mod then
                _G.NH_Deps = _G.NH_Deps or {}
                _G.NH_Deps[name] = mod
                print("[NH Loader] Loaded: " .. name)
            else
                warn("[NH Loader] Factory fail: " .. name .. " - Error: " .. tostring(mod))
            end
        else
            warn("[NH Loader] Fetch fail: " .. name)
        end
    end

    -- Fallbacks
    _G.NH_Deps = _G.NH_Deps or {}
    _G.NH_Deps.theme = _G.NH_Deps.theme or {
        Primary=Color3.fromHex("#7C3AED"),Accent=Color3.fromHex("#F43F5E"),Success=Color3.fromHex("#22C55E"),
        Background=Color3.fromHex("#0F0F23"),Surface=Color3.fromHex("#1E1C35"),Foreground=Color3.fromHex("#E2E8F0"),
        MutedFG=Color3.fromHex("#94A3B8"),Border=Color3.fromHex("#4C1D95"),BorderBright=Color3.fromHex("#7C3AED"),
        Destructive=Color3.fromHex("#EF4444"),OnPrimary=Color3.new(1,1,1),OnDestructive=Color3.new(1,1,1),
        GlassBg=Color3.fromHex("#1E1C35"),GlassBorder=Color3.fromHex("#4C1D95"),GlassHighlight=Color3.fromHex("#7C3AED"),
        FontHeader=Enum.Font.GothamBold,FontMono=Enum.Font.RobotoMono,FontBody=Enum.Font.GothamMedium,
        Space={xs=4,sm=8,md=12,lg=16,xl=24,xxl=32},Radius={sm=6,md=10,lg=16},
        Easing={fast=TweenInfo.new(0.15),normal=TweenInfo.new(0.25),spring=TweenInfo.new(0.4,Enum.EasingStyle.Back)},
    }
    _G.NH_Config = _G.NH_Deps.config or {ESP_Enabled=true,Noclip=true,NoCollision=true,AutoKill=true,AttackDistance=2.5,HeightOffset=1.0,FastAttack=true,TargetRadius=600,ScanInterval=0.25,AutoSeat=true,PlaneWaitTime=60,Anti773Fallback=102616257370565}
    _G.NH_Maid = _G.NH_Deps.maid or {_tasks={},Give=function(s,t)table.insert(s._tasks,t)return t end,Cleanup=function(s)for _,t in ipairs(s._tasks)do if typeof(t)=="RBXScriptConnection"then t:Disconnect()elseif typeof(t)=="Instance"then t:Destroy()elseif type(t)=="function"then pcall(t)end end table.clear(s._tasks)end}
    _G.NH_Deps.config = _G.NH_Deps.config or _G.NH_Config
    _G.NH_Deps.maid = _G.NH_Deps.maid or _G.NH_Maid
    _G.NH_Deps.theme = _G.NH_Deps.theme or _G.NH_Theme

    -- Globals for orchestrator
    _G.NH_Config = _G.NH_Deps.config
    _G.NH_Maid = _G.NH_Deps.maid
    _G.NH_Place = _G.NH_Deps.place
    _G.NH_Clicker = _G.NH_Deps.clicker
    _G.NH_UI = _G.NH_Deps.ui
    _G.NH_Plane = _G.NH_Deps.plane
    _G.NH_Combat = _G.NH_Deps.combat
    _G.NH_ESP = _G.NH_Deps.esp

    -- Init UI
    if _G.NH_Deps.ui and _G.NH_Deps.ui.Init then
        _G.NH_Deps.ui.Init(
            _G.NH_Deps.theme, _G.NH_Maid, _G.NH_Config, _G.NH_Place, _G.NH_Clicker,
            _G.NH_Deps.movement, _G.NH_Deps.esp, _G.NH_Deps.combat, _G.NH_Deps.plane
        )
        _G.NH_UI = _G.NH_Deps.ui
    end

    if _G.NH_Deps.orchestrator and _G.NH_Deps.orchestrator.Init then
        _G.NH_Deps.orchestrator.Init()
    end

    print("[NH Loader] Complete.")
    return true
end

return main()
