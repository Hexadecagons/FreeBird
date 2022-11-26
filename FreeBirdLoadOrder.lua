--[[

    FreeBirdLoadOrder.lua
    Author: Hex (@hexadecagons)

    Load order for modules initialized by the FreeBird framework.

--]]

return {
    Util    = {
        --[[ INDEPENDANT UTILS ]]--
        {
            "TableUtil";
            "Event";
            "Maid";
            "Signal";
        };
        --[[ ENUMERATIONS ]]--
        {
            "EnumConfig";
            "Enum"
        };
        --[[ DEBUGGER ]]--
        {
            "DebugConfig";
            "Debug";
        };
        --[[ ESSENTIALS ]]--
        {
            "PlatformUtil";
            "InputHandler";
        }
    };
    Shared  = {};
    Client  = {};
    Server  = {}
}