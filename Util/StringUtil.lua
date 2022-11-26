--[=[

    @class StringUtil
    Author: Hex (@hexadecagons)

    Utility module for manipulating strings.

]=]

-- REFERENCES
local RunService                    = game:GetService("RunService")

-- MODULE
local StringUtil = {}

-- Format a given number with commas.
function StringUtil:formatNumberWithComma(Amount: number)

    local Formatted = Amount
    local K

    while true do

        Formatted, K = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')

        if ( K == 0 ) then
            break
        end
    end

    return Formatted
end

--- Format seconds to MM:SS.
function StringUtil:formatSecondsToMMSS(Seconds: number)

	local M = math.floor(Seconds/60)
    local S = math.floor(Seconds - (60*M))

    return string.format("%02i",M)..":"..string.format("%02i",S)
end

--- Add leading zeroes to a given number.
function StringUtil:leadingZeroes(Number: number, Places: number)

    -- Create initial string we'll manipulate to get our output.
    local Output = tostring(Number)

    -- Get how many places the number already extends to.
    local NumberPlaces = #tostring(Number)

    -- Determine how many zeroes to add.
    local ZeroesToAdd = Places-NumberPlaces

    -- Add zeroes to the string at the front.
    for _ = 1, ZeroesToAdd do

        Output = "0"..Output
    end

    return Output
end

--- 'Typewrite' text onto a target instance with a ``Text`` property.
--- @param Target Instance -- Instance with .Text property to write onto.
--- @param Text string -- The text to write in.
--- @param WPM number -- Words per minute to type the text out at
function StringUtil:typeWrite(Target: Instance, Text: string, WPM: number)

    -- We don't want this function call to yield, so defer it to a new thread.
    task.defer(function()

        -- Type in text one letter at a time.
        for i = 1, #Text do
            Target.Text = Text:sub(1,i)

            -- Wait interval between letters to type in order at desired KPS.
            task.wait(1/WPM)
        end
    end)
end

return StringUtil