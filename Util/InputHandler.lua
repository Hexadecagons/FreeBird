--[=[

    @class InputHandler
    Author: Hex (@hexadecagons)

    Class for handling player input and providing an interface to map keys.

]=]

-- DEPENDENCIES
local Enum                  = _G:require("Enum")
local Maid                  = _G:require("Maid")
local PlatformUtil          = _G:require("PlatformUtil")

-- REFERENCES
local UserInputService      = game:GetService("UserInputService")

-- MODULE
local InputHandler = {}
InputHandler.__index = InputHandler

--- Constructor.
function InputHandler.new()

    local self = setmetatable({},InputHandler)

    --[[ PROPERTIES ]]--

    self.Enabled                    = true                  -- If the handler is enabled or not.
    self.InputMap                   = {}                    -- Stores keymaps to named inputs.
    self.InputStates                = {}                    -- Keeps track if named inputs are active or not.
    self.InputFunctions             = {}                    -- Functions connected to fire on activation/deactivation of named inputs. [InputName: string] = Functions: table
    self.Maid                       = Maid.new()            -- Maid used to clean up connections later.

    --[[ INITIALIZATION ]]--

    self:initialize()

    return self
end

--- Enable/Disable the handler.
--- Useful for preventing all input from the handler.
function InputHandler:setHandlerEnabled(Boolean: boolean)

    -- Reset all input states.
    for State,_ in pairs(self.InputStates) do self.InputStates[State] = false end

    self.Enabled = Boolean
end

--[=[

    Map keys to activate the given input.

    ```
    table KeyMap
        { Enum.PlatformType|string Platform = { Key: KeyCode|UserInputType|string; Type: InputEventType|string } ... }
            Key:
                Keycode: Corresponds to the function being activated on that key press.
                UserInputType: Triggers the function whenever an input event of that UserInputType is fired.
                string: Corresponds to a mobile UI button.
            Type:
                InputEventType: Is used directly.
                string: Is used to lookup the appropriate InputEventType and replaces the variable with it.
    ```

]=]
function InputHandler:map(InputName: string, KeyMap: table)

    -- Resolve Platform and Type into Enums when given as string.
    for Platform,Entry in pairs(KeyMap) do

        if Enum.InputEventType[Entry.Type] then

            Entry.Type = Enum.InputEventType[Entry.Type]
        end

        if type(Platform) == "string" then

            -- We do something kinda hacky where we set the current pair to nil, and redefine with the resolved platform.
            local ResolvedPlatform = Enum.PlatformType[Platform]
            KeyMap[Platform] = nil
            KeyMap[ResolvedPlatform] = Entry
        end
    end

    -- Register the mapping to the appropriate input.
    self.InputMap[InputName] = KeyMap
end

--- Call a function on a certain input being activated / deactivated.
--- An 'activated' boolean is passed to Function as the first argument which can be used to determine if the input is activated or not.
function InputHandler:onInput(InputName: string, Function: Function)

    -- If functions table for this named input doesn't exist, create it.
    if not self.InputFunctions[InputName] then self.InputFunctions[InputName] = {} end

    -- Insert this function to the table.
    table.insert(self.InputFunctions[InputName], Function)
end

--- Get if an input is currently active.
function InputHandler:isActive(InputName: string)

    return self.InputStates[InputName]
end

--- Set a given input active/inactive.
function InputHandler:setActive(InputName: string, Active: boolean)

    -- Toggle the input state.
    self.InputStates[InputName] = Active

    -- Don't do anything unless the handler is enabled.
    if not self.Enabled then return end

    -- Get functions listening for input state changes.
    local Functions = self.InputFunctions[InputName]

    -- Can't continue if the functions don't exist.
    if not Functions then return end

    -- Call the functions.
    for _,Function in pairs(Functions) do Function(Active) end
end

--- Deconstructor.
function InputHandler:Destroy()

    self:setHandlerEnabled(false)
    self.Maid:cleanup()
end

--- @private
--- Handle a named input event based on type.
function InputHandler:handleEventType(InputName: string, InputEventType: InputEventType, InputBegan: boolean)

    -- Handle input began event.
    if InputBegan then

        -- 'TOGGLE' case: we flip the activation state.
        if InputEventType == Enum.InputEventType.Toggle then self:setActive(InputName, not self:isActive(InputName)) return end

        -- 'PRESS' case: we activate the event, then immediately de-activate it manually.
        if InputEventType == Enum.InputEventType.Press then self:setActive(InputName, true); self.InputStates[InputName] = false return end

        -- 'HOLD' case: input is now being held, activate.
        if InputEventType == Enum.InputEventType.Hold and not self:isActive(InputName) then self:setActive(InputName, true) return end
    else

        -- Handle input ended event.
        -- 'HOLD' case: we de-activate as the input is no longer held.
        if InputEventType == Enum.InputEventType.Hold and self:isActive(InputName) then self:setActive(InputName, false) return end

        -- 'RELEASE' case: same logic as press, but for when the input is released.
        if InputEventType == Enum.InputEventType.Release then self:setActive(InputName, true); self.InputStates[InputName] = false return end
    end
end

--- @private
--- Handle input being held/released.
function InputHandler:onInputEvent(InputObject: InputObject, InputBegan: boolean)

    -- Don't do anything unless the handler is enabled.
    if not self.Enabled then return end

    -- Go through all mapped inputs and attempt to handle them if the appropriate key was triggered.
    for InputName,Map in pairs(self.InputMap) do

        for Platform,KeyMapping in pairs(Map) do

            -- If we're not on this platform, we can't continue.
            if Platform ~= PlatformUtil:getClientPlatform() then continue end

            if InputObject.UserInputType == KeyMapping.Key or InputObject.KeyCode == KeyMapping.Key then

                self:handleEventType(InputName, KeyMapping.Type, InputBegan)
            end
        end
    end
end

--- @private
--- Initialize the input handler to listen for actual inputs.
function InputHandler:initialize()

    -- Create connections that listen for InputBegan and InputEnded, proxying the arguments to the :onInputBegan and :onInputEnded functions.
    -- We also keep track of these connections to clean up later with the maid.
    self.Maid:giveTask(UserInputService.InputBegan:Connect(function(InputObject, GameProcessed) if GameProcessed then return end ; self:onInputEvent(InputObject,true) end))
    self.Maid:giveTask(UserInputService.InputEnded:Connect(function(InputObject, GameProcessed) if GameProcessed then return end ; self:onInputEvent(InputObject,false) end))

    -- TODO: Search for mobile buttons.
end

return InputHandler