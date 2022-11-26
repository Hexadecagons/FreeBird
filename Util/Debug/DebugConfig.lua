--[[

    DebugConfig.lua
    Author: Hex (@hexadecagons)

    Configuration file for the Debug module.

--]]

return {

    --[[ CUSTOMIZATION ]]--

    PREFIXES = {

        Print                       = "🔣";
        Warn                        = "⚠️";
        Error                       = "❌"

    };

    --[[ :drawValue() ]]--

    DEFAULT_KEY_COLOR               = Color3.fromRGB(255,255,255);
    DEFAULT_VALUE_COLOR             = Color3.fromRGB(116, 255, 3);
    DEFAULT_KEY_ICON                = "rbxassetid://10621456053"
}