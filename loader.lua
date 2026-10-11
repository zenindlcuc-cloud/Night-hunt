-- Night Hunt v3.1 | Module Loader for Delta
-- Put this in Delta AutoExec

local BASE = "https://raw.githubusercontent.com/zenindlcuc-cloud/Night-hunt/main/modules/"

local function loadModule(name)
    local src = game:HttpGet(BASE .. name .. ".lua")
    assert(src and #src > 0, "Failed to load module: " .. name)
    return loadstring(src, name)()
end

-- Load order (dependencies first)
local Theme     = loadModule("theme")
local Maid      = loadModule("maid")
local Config    = loadModule("config")
local Place     = loadModule("place")
local Clicker   = loadModule("clicker")
local Movement  = loadModule("movement")
local ESP       = loadModule("esp")
local Combat    = loadModule("combat")
local Plane     = loadModule("plane")
local UI        = loadModule("ui")
local Orch      = loadModule("orchestrator")

-- Initialize systems
UI.Init(Theme, Maid, Config, Place, Clicker, Movement, ESP, Combat, Plane)
Orch.Init(Theme, Maid, Config, Place, Clicker, Movement, ESP, Combat, Plane, UI)

print("[Night Hunt v3.1] All modules loaded successfully.")
