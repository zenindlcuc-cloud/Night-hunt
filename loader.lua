-- loader.lua (GitHub root)
local BASE = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/modules/"

local function httpGet(url)
    local requestFunc = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    if requestFunc then
        local ok, result = pcall(function() 
            return requestFunc({
                Url = url,
                Method = "GET",
                Headers = { ["User-Agent"] = "Roblox/Delta (Windows; U; en-US)" }
            })
        end)
        if ok and type(result) == "table" and result.StatusCode == 200 and type(result.Body) == "string" and #result.Body > 0 then
            return result.Body
        end
    end

    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and type(result) == "string" and #result > 0 then 
        return result 
    end
    
    warn("[NH Loader] Failed to fetch URL: " .. url)
    return nil
end

local function loadMod(name)
    local url = BASE .. name .. ".lua"
    local src = httpGet(url)
    if not src then 
        warn("[NH Loader] Could not fetch module: " .. name)
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

    print("[NH Loader] Initializing Night-Hunt...")
    _G.NH_Deps = _G.NH_Deps or {}

    for _, name in ipairs(mods) do
        local fn = loadMod(name)
        if fn then
            local ok, mod = pcall(fn, _G.NH_Deps)
            if ok and mod ~= nil then
                _G.NH_Deps[name] = mod
                print("[NH Loader] Loaded module: " .. name)
            else
                warn("[NH Loader] Error initializing module: " .. name .. " - " .. tostring(mod))
            end
        else
            warn("[NH Loader] Failed to compile module: " .. name)
        end
    end

    -- Global Aliases & Fallbacks
    _G.NH_Theme = _G.NH_Deps.theme
    _G.NH_Config = _G.NH_Deps.config
    _G.NH_Maid = _G.NH_Deps.maid
    _G.NH_Place = _G.NH_Deps.place
    _G.NH_Clicker = _G.NH_Deps.clicker
    _G.NH_Movement = _G.NH_Deps.movement
    _G.NH_ESP = _G.NH_Deps.esp
    _G.NH_Combat = _G.NH_Deps.combat
    _G.NH_Plane = _G.NH_Deps.plane
    _G.NH_UI = _G.NH_Deps.ui
    _G.NH_Orchestrator = _G.NH_Deps.orchestrator

    -- Initialize UI if available
    if _G.NH_Deps.ui and type(_G.NH_Deps.ui) == "table" and _G.NH_Deps.ui.Init then
        pcall(function()
            _G.NH_Deps.ui.Init(_G.NH_Deps)
        end)
    end

    -- Initialize Orchestrator loop if available
    if _G.NH_Deps.orchestrator and type(_G.NH_Deps.orchestrator) == "table" and _G.NH_Deps.orchestrator.Init then
        pcall(function()
            _G.NH_Deps.orchestrator.Init()
        end)
    end

    print("[NH Loader] Execution complete!")
    return true
end

local success, err = pcall(main)
if not success then
    warn("[NH Loader] Fatal error during launch: " .. tostring(err))
end

return function() return success end
