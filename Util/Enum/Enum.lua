--[=[

    @class Enum
    Author: Hex (@hexadecagons)

    Custom enumeration module, sort of messy but does the job!

    Automatically initializes enumerations from ``EnumConfig.lua``

]=]

-- MODULE
local EnumRegistry = {}

--- @within Enum
--- Add new enum to registry.
function EnumRegistry:addEnum(Name: string, Elements: table)

    EnumRegistry[Name] = {}

    for Value,Element in pairs(Elements) do

        EnumRegistry[Name][Element] = Value
    end
end

-- Create passthrough to roblox enum and prevent edge case.
setmetatable(EnumRegistry,{__index = function(_,Key)

    -- Solve edge case to prevent FreeBird from having a stroke.
    if Key == "__init" then return nil end

    -- Passthrough to Roblox Enum.
    return Enum[Key]
end})

-- Predefine enums from configuration.
local EnumConfig = _G:require("EnumConfig")
for EnumName,Items in pairs(EnumConfig) do EnumRegistry:addEnum(EnumName, Items) end

return EnumRegistry