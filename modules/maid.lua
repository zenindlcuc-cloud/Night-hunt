-- modules/maid.lua
local Maid = { _tasks = {} }
function Maid:Give(task)
    table.insert(self._tasks, task)
    return task
end
function Maid:Cleanup()
    for _, task in ipairs(self._tasks) do
        if typeof(task) == "RBXScriptConnection" then task:Disconnect()
        elseif typeof(task) == "Instance" then task:Destroy()
        elseif type(task) == "function" then pcall(task) end
    end
    table.clear(self._tasks)
end
return Maid