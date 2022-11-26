--[=[

    @class FreeBird
    Author: Hex (@hexadecagons)

    ### 🐦 Module Loader Framework

    FreeBird is the core module responsible for loading and initializing modules in order.

    - FreeBird loads modules in this order: ``Util``>``Shared``>``Client/Server``

    - The load order of individual modules is defined in ``FreeBirdLoadOrder.lua``, this can be used to ensure dependencies load before a certain module.

    - After modules are loaded, they are queued to be initialized if they contain an ``__init`` function.

    ### Require modules with _G!

    FreeBird utilizes ``_G`` to provide easy, global access to the initialized modules.

    ``_G:require(ModuleName)`` will return the module of given name if it has been loaded and initialized.

]=]

-- DEPENDENCIES
local FreeBirdOrder                     = require(script.Parent.FreeBirdLoadOrder)
local FreeBirdConfig                    = require(script.Parent.FreeBirdConfig)

-- REFERENCES
local RunService                        = game:GetService("RunService")

-- VARIABLES
local LoadedModules                     = {} -- Registry containing loaded modules, associated as [Name] = Module.
local InitQueue                         = {} -- Queue containing modules waiting to have their __init function called.

-- MODULE
local FreeBird = {}

--[=[

    Initializes the FreeBird lifecycle.

    :::danger

    Call this function no more than **once** from the ``Server`` and ``Client`` respectively.

    :::

]=]
function FreeBird:init()

    self:print("FreeBird "..FreeBirdConfig.BUILD_STRING)
    self:print("Loading Util")

    -- Load utility modules.
    self:loadFolder(script.Parent:WaitForChild("Util"))

    self:print("Loading Shared")

    -- Load shared modules.
    self:loadFolder(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))

    self:print("Loading Modules")

    -- Load appropriate modules based on if we're client or server.
    if RunService:IsClient() then

        self:loadFolder(game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"):WaitForChild("Client"))
    elseif RunService:IsServer() then

        self:loadFolder(game:GetService("ServerScriptService"):WaitForChild("Server"))
    end

    self:print("Initializing")

    -- Iniitialize modules queued to do so.
    self:initializeQueuedModules()

    self:print("Ready! ^.^")
end

--- Attempt to load a given module.
function FreeBird:load(Module: ModuleScript)

    -- Can't load non ModuleScript objects.
    if not Module:IsA("ModuleScript") then return end

    -- Don't load modules that are already loaded.
    if LoadedModules[Module.Name] then return end

    -- Attempt to require the module.
    local LoadedModule
    local Success, Error = pcall(function() LoadedModule = require(Module) end)

    -- Warn and return if we fail to load the module.
    if not Success then self:warn("Failed to load module: "..Module.Name); warn(Error) end

    -- Register successfuly loaded module.
    LoadedModules[Module.Name] = LoadedModule

    -- Initialize module.
    if type(LoadedModule) == "table" and LoadedModule.__init then table.insert(InitQueue,LoadedModule) end
end

--- Load all modules within a given folder.
function FreeBird:loadFolder(ModuleFolder: Folder)

    -- Are there ordered batches of modules to load for this folder?
    local OrderedBatches = FreeBirdOrder[ModuleFolder.Name]
    if OrderedBatches then

        -- Iterate through each batch of modules.
        for _ = 1, #OrderedBatches do

            local Batch = OrderedBatches[_]

            -- Attempt to load each module in batch.
            for i = 1, #Batch do

                -- Locate the module within the folder.
                local Module
                for _,Child in pairs(ModuleFolder:GetDescendants()) do if Child.Name == Batch[i] and Child:IsA("ModuleScript") then Module = Child end end

                -- Skip if we can't find the module at all.
                if not Module then self:warn("Couldn't find module: "..Batch[i].." in folder: "..ModuleFolder.Name) continue end

                -- Attempt to load the module.
                self:load(Module)
            end
        end
    end

    -- Load the rest of the modules with no particular order.
    for _,Module in pairs (ModuleFolder:GetDescendants()) do if not LoadedModules[Module.Name] then self:load(Module) end end
end

--- @within FreeBird
--- Require a module safely from name.
--- Called through ``_G:require`` for hacky syntax sugar.
function _G:require(ModuleName: string)

    -- Get the module from the loaded module pile.
    local Module = LoadedModules[ModuleName]

    -- Warn if the module could not be required.
    if not Module then FreeBird:warn("Could not require module: "..ModuleName); FreeBird:warn("Attempt by: "..getfenv(2).script.Name) return end

    -- Return the module.
    return Module
end
FreeBird.require = _G.require

--- @private
--- Initialize queued modules.
function FreeBird:initializeQueuedModules()

    -- Go through all modules in the queue.
    for _,Module in pairs(InitQueue) do

        -- Ensure init function exists.
        if Module.__init then

            -- Initialize.
            task.spawn(function() Module:__init() end)
        end
    end

    -- Clear the queue.
    InitQueue = nil
end

--- @private
--- Internal print that utilizes prefix.
function FreeBird:print(Message: string)

    print((RunService:IsClient() and FreeBirdConfig.PREFIXES.Client or FreeBirdConfig.PREFIXES.Server)..FreeBirdConfig.PREFIXES.FreeBird.." "..Message)
end

--- @private
--- Internal warn that utilizes prefix.
function FreeBird:warn(Message: string)

    print((RunService:IsClient() and FreeBirdConfig.PREFIXES.Client or FreeBirdConfig.PREFIXES.Server)..FreeBirdConfig.PREFIXES.FreeBird..FreeBirdConfig.PREFIXES.Warn.." "..Message)
end

return FreeBird