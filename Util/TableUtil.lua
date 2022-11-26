--[=[

    @class TableUtil
    Author: Hex (@hexadecagons)

    Utility module for working with tables.

]=]

-- MODULE
local TableUtil = {}

--- Deep copy a table and it's contents.
function TableUtil:copy(Table: table)

    return deepCopyTableContent(Table)
end

--- Check if a table contains a given value.
--- The third argument determines if we should search through child tables to locate our value.
--- Returns the key at which the value is contained.
--- Also returns the table within which the key was found, this is useful for deep searches where it can be in a child table.
function TableUtil:contains(Table: table, Value: any, DeepSearch: boolean)

    -- Look for the value in the table, straightforward.
    for Key,_Value in pairs(Table) do

        if _Value == Value then return Key, Table end
    end

    -- If we're performing a deep search, attempt to go through child tables to find the value.
    if DeepSearch then

        for _,Child in pairs(Table) do

            if type(Child) == "table" then

                return self:contains(Child, Value, true)
            end
        end
    end

    -- We still couldn't find it :(
    return false
end

-- Recursive function to deep copy a table's contents.
function deepCopyTableContent(Content: any)

    -- Get the content's type.
    local Type = type(Content)
    local Copy -- Empty variable we write the copy to.

    -- Handle table types.
    if Type == 'table' then

        -- The copy has to be a table.
        Copy = {}

        -- Attempt to reconstruct the table recursively.
        for Key,Value in pairs(Content) do

            Copy[deepCopyTableContent(Key)] = deepCopyTableContent(Value)
        end

        -- Copy the metatable as well.
        setmetatable(Copy, deepCopyTableContent(getmetatable(Content)))
    else

        -- Case for non-table types.
        Copy = Content
    end

    return Copy
end

return TableUtil