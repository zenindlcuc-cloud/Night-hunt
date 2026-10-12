-- loader.lua (Night-Hunt GitHub root)
local BASE_MODULES = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/modules/"
local BASE_MODULE = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/module/"

local function httpGet(url)
    -- 1. Try game:HttpGet first as standard Roblox/Delta method
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and type(result) == "string" and #result > 0 then
        return result
    end

    -- 2. Fallback to custom request functions in executors like Delta
    local requestFunc = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    if requestFunc then
        local reqOk, reqResult = pcall(function()
            return requestFunc({
                Url = url,
                Method = "GET",
                Headers = { ["User-Agent"] = "Roblox/Delta (Android; Mobile)" }
            })
        end)
        if reqOk and type(reqResult) == "table" then
            local body = reqResult.Body or reqResult.body or reqResult.response or reqResult.Response
            local status = reqResult.StatusCode or reqResult.status_code or reqResult.Status or 200
            if (status == 200 or status == 0) and type(body) == "string" and #body > 0 then
                return body
            end
        end
    end

    warn("[NH Loader] Failed to fetch URL: " .. tostring(url))
    return nil
end

local function loadMod(name)
    -- Try modules/ path first, then module/ fallback path
    local src = httpGet(BASE_MODULES .. name .. ".lua") or httpGet(BASE_MODULE .. name .. ".lua")
    if not src then 
        warn("[NH Loader] Could not fetch source for module: " .. tostring(name))
        return nil 
    end
    
    -- In some mobile Luau executors loadstring takes only 1 argument (the source code)
    local fn, err
    local loadOk, loadRes = pcall(function() return loadstring(src, name) end)
    if loadOk and loadRes then
        fn = loadRes
    else
        -- Fallback to single argument loadstring
        local singleOk, singleRes = pcall(function() return loadstring(src) end)
        if singleOk and singleRes then
            fn = singleRes
        else
            err = loadRes or singleRes
        end
    end

    if not fn then 
        warn("[NH Loader] Syntax error compiling module " .. tostring(name) .. ": " .. tostring(err))
        return nil 
    end
    
    return fn
end

print("[NH Loader] Initializing Night-Hunt on Delta...")
_G.NH_Deps = _G.NH_Deps or {}

local mods = {"theme","config","maid","place","clicker","movement","esp","combat","plane","ui","orchestrator"}

for _, name in ipairs(mods) do
    local factoryFn = loadMod(name)
    if factoryFn then
        local ok, mod = pcall(factoryFn, _G.NH_Deps)
        if ok and mod ~= nil then
            _G.NH_Deps[name] = mod
            print("[NH Loader] Loaded: " .. name)
        else
            warn("[NH Loader] Factory error in module " .. name .. ": " .. tostring(mod))
        end
    else
        warn("[NH Loader] Failed to compile module: " .. name)
    end
end

-- Global Aliases
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

-- Init UI
if _G.NH_Deps.ui and type(_G.NH_Deps.ui) == "table" and _G.NH_Deps.ui.Init then
    pcall(function()
        _G.NH_Deps.ui.Init(_G.NH_Deps)
    end)
end

-- Init Orchestrator
if _G.NH_Deps.orchestrator and type(_G.NH_Deps.orchestrator) == "table" and _G.NH_Deps.orchestrator.Init then
    pcall(function()
        _G.NH_Deps.orchestrator.Init()
    end)
end

print("[NH Loader] Complete!")
