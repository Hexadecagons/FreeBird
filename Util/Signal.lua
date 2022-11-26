--[=[

    @class Signal
    Author: Hex (@hexadecagons)

    Simple interface for handling cross-script communication and client-server networking.

]=]

-- REFERENCES
local RunService                    = game:GetService("RunService")
local ReplicatedStorage             = game:GetService("ReplicatedStorage")

-- Remote instances, created by :createRemotes(), used to handle networking.
local RemoteEvent                   = nil
local RemoteFunction                = nil

-- MODULE
local Signal = {
    Listeners                       = {}; -- Listener functions for handling messages sent through events, stored as [Message] = {...} | Multiple listeners can exist per message, unlike for invokes.
    InvokeListeners                 = {}  -- Listener functions for handling messages sent through invokes, stored as [Message] = Function
}

--- Fire a function locally.
function Signal:Fire(Message: string,...: any)

    self.processEvent(Message,...)
end

--- Invoke a function locally.
function Signal:Invoke(Message: string,...: any)

   return self.processInvoke(Message,...)
end

--- @server
--- Fire function on client from server.
function Signal:FireClient(Player: Player,Message: string,...: any)

    RemoteEvent:FireClient(Player,Message,...)
end

--- @server
--- Fire function on all clients from server.
function Signal:FireAllClients(Message: string,...: any)

    RemoteEvent:FireAllClients(Message,...)
end

--- @server
--- Invoke function on client from server.
function Signal:InvokeClient(Player: Player,Message: string,...: any)

    return RemoteFunction:InvokeClient(Player,Message,...)
end

--- @client
--- Fire function on server from client.
function Signal:FireServer(Message: string,...: any)

    RemoteEvent:FireServer(Message,...)
end

--- @client
--- Invoke function on server from client.
function Signal:InvokeServer(Message: string,...: any)

    return RemoteFunction:InvokeServer(Message,...)
end

--- Add a function as listener for processing a given message.
function Signal:Listen(Message: string, Function: Function)

    -- If there's no listener table for this message yet, create one.
    if not Signal.Listeners[Message] then Signal.Listeners[Message] = {} end

    -- Simply associate the function with the message in the listeners table.
    table.insert(Signal.Listeners[Message], Function)
end

--- Define function as response on invoke of a message.
function Signal:OnInvoke(Message: string, Function: Function)

    -- This function is now fired on invoke!
    Signal.InvokeListeners[Message] = Function
end

--- @private
--- Process an event being fired locally.
function Signal.processEvent(Message: string,...: any)

    -- Is there any listener functions for this message?
    local Listeners = Signal.Listeners[Message]
    if not Listeners then return end

    -- Call the appropriate functions.
    for _,Function in pairs(Listeners) do Function(...) end
end

--- @private
--- Process an invoke being fired locally.
function Signal.processInvoke(Message: string,...: any)

    -- Is there an invoke listener for this message?
    local Listener = Signal.InvokeListeners[Message]
    if not Listener then return end

    -- Call the listener function and return results.
    return Listener(...)
end

--- @private
--- @client
--- Process EVENT from SERVER->CLIENT.
function Signal.processClientEvent(Message: string,...: any)

    Signal.processEvent(Message,...)
end

--- @private
--- @client
--- Process INVOKE from SERVER->CLIENT.
function Signal.processClientInvoke(Message: string,...: any)

    return Signal.processInvoke(Message,...)
end

--- @private
--- @server
--- Process EVENT from CLIENT->SERVER.
function Signal.processServerEvent(Player: Player,Message: string,...: any)

    Signal.processEvent(Message,Player,...)
end

--- @private
--- @server
--- Process INVOKE from CLIENT->SERVER.
function Signal.processServerInvoke(Player: Player,Message: string,...: any)

    return Signal.processInvoke(Message,Player,...)
end

--- @private
--- Create RemoteEvent / RemoteFunction objects.
function Signal:createRemotes()

    if RunService:IsClient() then

        -- If we're the client, we look for existing RemoteFunction and RemoteEvent in ReplicatedStorage.
        RemoteEvent = ReplicatedStorage:WaitForChild("SignalRemoteEvent")
        RemoteFunction = ReplicatedStorage:WaitForChild("SignalRemoteFunction")
    else

        -- If we're the server, we create it.
        RemoteEvent = Instance.new("RemoteEvent"); RemoteEvent.Name = "SignalRemoteEvent"; RemoteEvent.Parent = ReplicatedStorage
        RemoteFunction = Instance.new("RemoteFunction"); RemoteFunction.Name = "SignalRemoteFunction"; RemoteFunction.Parent = ReplicatedStorage
    end
end

--- @private
--- Connect RemoteEvent / RemoteFunction endpoints.
function Signal:connectEndpoints()

    -- Client.
    if RunService:IsClient() then

        RemoteEvent.OnClientEvent:Connect(Signal.processClientEvent)
        RemoteFunction.OnClientInvoke = Signal.processClientInvoke
    else -- Server.

        RemoteEvent.OnServerEvent:Connect(Signal.processServerEvent)
        RemoteFunction.OnServerInvoke = Signal.processServerInvoke
    end
end

function Signal:__init()

    self:createRemotes()
    self:connectEndpoints()
end

return Signal