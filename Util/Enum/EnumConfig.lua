--[[

    EnumConfig.lua
    Author: Hex (@hexadecagons)

    Configuration file for predefining enumerations.

--]]

return {

    -- Used by PlatformUtil to determine the client's current platform.
    ["PlatformType"] = {"PC";"Mobile";"Console"};

    -- Used by Debug module to differentiate output types.
    ["OutputType"]  = {"Print";"Warn";"Error"};

    -- Used by Input module to handle differentiate input event types.
    ["InputEventType"] = {"Hold";"Press";"Toggle";"Release"}

}