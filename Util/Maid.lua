--[=[

    @class Maid
    Author: Hex (@hexadecagons)

    Class used to clean up objects.

]=]

-- MODULE
local Maid = {}
Maid.__index = Maid

--- Constructor.
function Maid.new()

    local self = setmetatable({},Maid)

    --[=[

        @prop Tasks table

        @within Maid

        Table containing tasks passed to the maid.

        @private

    ]=]
    self.Tasks = {}

    return self
end

--- Add task to maid.
--- @param Task any -- Task to clean up.
function Maid:giveTask(Task: any)

    table.insert(self.Tasks,Task)
end

--- Clean up garbage.
function Maid:cleanup()

    -- Go through all tasks and handle each task appropriately.
    for _,Task in pairs(self.Tasks) do

        -- Destroy instances.
        if type(Task) == "userdata" then

            Task:Destroy()
        elseif type(Task) == "function" then

            -- Call functions.
            Task()
        elseif Task.Disconnect then

            -- Disconnect events.
            Task:Disconnect()
        elseif Task.Destroy then

            -- Deconstruct classes.
            Task:Destroy()
        end
    end
end

--- @function Destroy
--- @within Maid
--- Alias for [Maid:cleanup]
Maid.Destroy = Maid.cleanup

return Maid