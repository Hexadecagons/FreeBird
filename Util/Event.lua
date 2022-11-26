--[=[

    @class Event
    Author: Hex (@hexadecagons)

    [RBXScriptSignal] emulation used to create custom events.
    Actually just uses a [BindableEvent] and wraps around it!

]=]

-- MODULE
local Event = {}
Event.__index = Event

--- Constructor.
function Event.new()

    local _self = setmetatable({},Event)

    _self.BindableEvent                  = Instance.new("BindableEvent")                    -- The BindableEvent used internally by the object.

    return _self
end

--- Fire the event.
function Event:Fire(...: any)

    self.BindableEvent:Fire(...)
end

--- Connect function to event.
function Event:Connect(Function: Function)

    self.BindableEvent.Event:Connect(Function)
end

--- Wait for event to fire.
function Event:Wait()

    self.BindableEvent.Event:Wait()
end

--- Deconstructor.
function Event:Destroy()

    self.BindableEvent:Destroy()
end

--- @function connect
--- @within Event
--- Alias to support deprecated syntax for weirdos.
Event.connect = Event.Connect

return Event