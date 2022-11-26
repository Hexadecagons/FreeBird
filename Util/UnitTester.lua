--[=[

    @class UnitTester
    Author: Hex (@hexadecagons)

    Utility class used to run automated unit tests to ensure functionality of other modules.

]=]

-- REFERENCES
local RunService            = game:GetService("RunService")

-- DEPENDENCIES
local Debug                 = _G:require("Debug")

-- CONSTANTS
local TEST_TIMEOUT_AFTER    = 2.5                       -- How many seconds to wait before timing out a test function.

-- MODULE
local UnitTester = {}
UnitTester.__index = UnitTester

--- Constructor.
function UnitTester.new(Name: string)

    local _self = setmetatable({},UnitTester)

    --[=[

        @prop Name string

        @within UnitTester

        The name of the unit test, used to identify when outputting to console.

        @readonly
        @private

    ]=]
    _self.Name                  = Name

    --[=[

        @prop Tests table

        @within UnitTester

        Table containing functinos to test.

        @readonly
        @private

    ]=]
    _self.Tests                 = {}

    return _self
end

--- Add a new function to test.
--- This function must return true to pass.
function UnitTester:addTest(Name: string,Function: Function)

    -- What are you even trying to do?
    if type(Function) ~= "function" then Debug:warn("Unit testing may only be done with functions!") end

    table.insert(self.Tests,{ Function = Function; Name = Name})
end

--- Run tests.
function UnitTester:run()

    -- We want to keep track of and tally how many tests we've passed.
    local TestCount     = #self.Tests
    local PassedCount   = 0

    -- Debug:print(string.format("Running Tests: %s",self.Name),{Prefix = "🧪"})

    -- Run all the tests!
    for _,TestData in pairs(self.Tests) do

        -- Record the tick at which we attempt to call the function, in order to timeout!
        local CallTick = tick()

        -- Keep track of if the test has succeded or not.
        local Success, Error = false

        -- Attempt to run test safely in a new thread.
        task.spawn(function()


            Success, Error = pcall(TestData.Function)

            if Success then

                -- Debug:print(string.format("Success: %s/%s",self.Name,TestData.Name),{Prefix = "⚙️"})

                -- Only add to tally if the test does in fact succeed.
                PassedCount = PassedCount + 1
            end
        end)

        -- Wait until success or timeout before moving on.
        repeat RunService.Heartbeat:Wait() until Success or tick()-CallTick >= TEST_TIMEOUT_AFTER

        -- Output if we failed.
        if not Success then

            Debug:print(string.format("Failed: %s/%s",self.Name,TestData.Name),{Prefix = "❌"})
            Debug:print(Error,{Prefix = "❌"})
        end
    end

    -- Did we pass all the tests?
    local TestPassCountString = string.format("%s/%s",PassedCount,TestCount) -- Create a string showing X/Y of tests passed.
    if PassedCount == TestCount then

        -- Yeppers! leave a print and move on.
        Debug:print(string.format("%s : %s Tests Passed!",self.Name,TestPassCountString),{Prefix = "✔️"})
    else

        -- Uh oh! we warn about it since a few of them failed.
        Debug:print(string.format("%s : %s Tests Passed!",self.Name,TestPassCountString),{Prefix = "❌"})
    end
end

return UnitTester