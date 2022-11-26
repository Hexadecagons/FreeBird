--[=[

    @class PlatformUtil
    Author: Hex (@hexadecagons)

    Utility module for getting the client's platform.

]=]

-- DEPENDENCIES
local Enum                  = _G:require("Enum")

-- REFERENCES
local UserInputService      = game:GetService("UserInputService")

-- MODULE
local PlatformUtil = {}

--- Approximate the client's platform.
function PlatformUtil:getClientPlatform()

    local TouchEnabled      = UserInputService.TouchEnabled
    local KeyboardEnabled   = UserInputService.KeyboardEnabled
    local MouseEnabled      = UserInputService.MouseEnabled
    local GamepadEnabled    = UserInputService.GamepadEnabled

    -- Prioritize console first, this means we will also treat PCs with gamepads plugged in as 'Console'
    if GamepadEnabled then return Enum.PlatformType.Console end

    -- If touch is enabled and there is no mouse or keyboard present, we can confidently assume this is a mobile device.
    if TouchEnabled and not (KeyboardEnabled or MouseEnabled) then return Enum.PlatformType.Mobile end

    -- Otherwise, default to PC.
    return Enum.PlatformType.PC
end

return PlatformUtil