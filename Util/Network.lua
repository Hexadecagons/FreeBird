--[=[

    @class Network
    Author: Hex (@hexadecagons)

    Simple interface for handling cross-script communication and client-server networking.

]=]

-- DEPENDENCIES
local Debug                         = _G:require("Debug")

-- REFERENCES
local RunService                    = game:GetService("RunService")
local ReplicatedStorage             = game:GetService("ReplicatedStorage")

-- Remote instances, created by :createRemotes(), used to handle networking.
local RemoteEvent                   = nil
local RemoteFunction                = nil

-- MODULE
local Network = {
    Listeners                       = {}; -- Listener functions for handling messages sent through events, stored as [Message] = {...} | Multiple listeners can exist per message, unlike for invokes.
    InvokeListeners                 = {}; -- Listener functions for handling messages sent through invokes, stored as [Message] = Function
    TypeChecking                    = {}; -- Stores types to compare against arguments for each message.
    ThrottlingData                  = {}  -- Data used for throttling.
}

--- Assign typechecking to the arguments of a given message.
function Network:typeCheck(Message: string,...:any )

    Network.TypeChecking[Message] = {...}
end

--- Throttle the frequency at which an event can be fired.
function Network:throttle(Message: string,Frequency: number)

    Network.ThrottlingData[Message] = {
        LastTick = tick();
        Frequency = Frequency
    }
end

--- Fire a function locally.
function Network:FireSelf(Message: string,...: any)

    self.processEvent(Message,...)
end

--- Invoke a function locally.
function Network:InvokeSelf(Message: string,...: any)

   return self.processInvoke(Message,...)
end

--- @server
--- Fire function on client from server.
function Network:FireClient(Player: Player,Message: string,...: any)

    RemoteEvent:FireClient(Player,Message,...)
end

--- @server
--- Fire function on all clients from server.
function Network:FireAllClients(Message: string,...: any)

    RemoteEvent:FireAllClients(Message,...)
end

--- @server
--- Invoke function on client from server.
function Network:InvokeClient(Player: Player,Message: string,...: any)

    return RemoteFunction:InvokeClient(Player,Message,...)
end

--- @client
--- Fire function on server from client.
function Network:FireServer(Message: string,...: any)

    RemoteEvent:FireServer(Message,...)
end

--- @client
--- Invoke function on server from client.
function Network:InvokeServer(Message: string,...: any)

    return RemoteFunction:InvokeServer(Message,...)
end

--- Add a function as listener for processing a given message.
function Network:Listen(Message: string, Function: Function)

    -- If there's no listener table for this message yet, create one.
    if not Network.Listeners[Message] then Network.Listeners[Message] = {} end

    -- Simply associate the function with the message in the listeners table.
    table.insert(Network.Listeners[Message], Function)
end

--- Define function as response on invoke of a message.
function Network:OnInvoke(Message: string, Function: Function)

    -- This function is now fired on invoke!
    Network.InvokeListeners[Message] = Function
end

--- @private
--- Process an event being fired locally.
function Network.processEvent(Message: string,...: any)

    -- Is there any listener functions for this message?
    local Listeners = Network.Listeners[Message]
    if not Listeners then return end

    -- Strictly type check arguments.
    local PassedTypeCheck = Network.processTypeCheck(Message,...)
    if not PassedTypeCheck then return end

    -- Make sure it's not throttled.
    if Network.processThrottlingCheck() then return end

    -- Call the appropriate functions.
    for _,Function in pairs(Listeners) do Function(...) end
end

--- @private
--- Process an invoke being fired locally.
function Network.processInvoke(Message: string,...: any)

    -- Is there an invoke listener for this message?
    local Listener = Network.InvokeListeners[Message]
    if not Listener then Debug:warn("No listener found for: "..Message) return end

    -- Strictly type check arguments.
    local PassedTypeCheck = Network.processTypeCheck(Message,...)
    if not PassedTypeCheck then return end

    -- Make sure it's not throttled.
    if Network.processThrottlingCheck() then return end

    -- Call the listener function and return results.
    return Listener(...)
end

--- @private
--- Process throttling check for a given message.
function Network.processThrottlingCheck(Message: string)

    -- Is there even throttling data for this message?
    local ThrottlingData = Network.ThrottlingData[Message]
    if ThrottlingData then

        -- If not enough time has passed since the last tick, we're trying to fire this event too frequently, return false.
        if tick()-ThrottlingData.LastTick < 1/ThrottlingData.Frequency then

            Debug:warn("Attempt to fire "..Message.." throttled ( Delta: "..1/(tick()-ThrottlingData.LastTick).."hz | Throttle: "..ThrottlingData.Frequency.."hz )")
            return false
        end
    end

    -- We passed the throttling check!
    return true
end

--- @private
--- Process type checking for a message and given arguments.
function Network.processTypeCheck(Message: string, ...: any)

    if Network.TypeChecking[Message] then

        -- Compare each argument to each type entry.
        for Index,Argument in pairs(...) do

            -- Get the type.
            local Type = Network.TypeChecking[Message][Index]

            -- Skip if this argument has no type entry to compare against.
            if not Type then continue end

            -- If type mismatch, abort and output about it.
            if type(Argument) ~= Type then

                Debug:warn(string.format("Type mistmatch : Argument #%s for %s expected to be of type %s : Got %s."),Index,Message,Type,type(Argument))
                return false
            end
        end
    end

    -- We passed if we made it this far.
    return true
end

--- @private
--- @client
--- Process EVENT from SERVER->CLIENT.
function Network.processClientEvent(Message: string,...: any)

    Network.processEvent(Message,...)
end

--- @private
--- @client
--- Process INVOKE from SERVER->CLIENT.
function Network.processClientInvoke(Message: string,...: any)

    return Network.processInvoke(Message,...)
end

--- @private
--- @server
--- Process EVENT from CLIENT->SERVER.
function Network.processServerEvent(Player: Player,Message: string,...: any)

    Network.processEvent(Message,Player,...)
end

--- @private
--- @server
--- Process INVOKE from CLIENT->SERVER.
function Network.processServerInvoke(Player: Player,Message: string,...: any)

    return Network.processInvoke(Message,Player,...)
end

--- @private
--- Create RemoteEvent / RemoteFunction objects.
function Network:createRemotes()

    if RunService:IsClient() then

        -- If we're the client, we look for existing RemoteFunction and RemoteEvent in ReplicatedStorage.
        RemoteEvent = ReplicatedStorage:WaitForChild("NetworkRemoteEvent")
        RemoteFunction = ReplicatedStorage:WaitForChild("NetworkRemoteFunction")
    else

        -- If we're the server, we create it.
        RemoteEvent = Instance.new("RemoteEvent"); RemoteEvent.Name = "NetworkRemoteEvent"; RemoteEvent.Parent = ReplicatedStorage
        RemoteFunction = Instance.new("RemoteFunction"); RemoteFunction.Name = "NetworkRemoteFunction"; RemoteFunction.Parent = ReplicatedStorage
    end
end

--- @private
--- Connect RemoteEvent / RemoteFunction endpoints.
function Network:connectEndpoints()

    -- Client.
    if RunService:IsClient() then

        RemoteEvent.OnClientEvent:Connect(Network.processClientEvent)
        RemoteFunction.OnClientInvoke = Network.processClientInvoke
    else -- Server.

        RemoteEvent.OnServerEvent:Connect(Network.processServerEvent)
        RemoteFunction.OnServerInvoke = Network.processServerInvoke
    end
end

function Network:__init()

    self:createRemotes()
    self:connectEndpoints()
end

return Network