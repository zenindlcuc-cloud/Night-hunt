local function factory(Deps)
    local Maid = { _tasks = {} }

    function Maid:Give(task)
        table.insert(self._tasks, task)
        return task
    end

    function Maid:Cleanup()
        for _, task in ipairs(self._tasks) do
            if typeof(task) == "RBXScriptConnection" then
                pcall(function() task:Disconnect() end)
            elseif typeof(task) == "Instance" then
                pcall(function() task:Destroy() end)
            elseif type(task) == "function" then
                pcall(task)
            end
        end
        table.clear(self._tasks)
    end

    return Maid
end

return factory
