--[=[

    @class WeldUtil
    Author: Hex (@hexadecagons)

    Utility module for improving quality of life when working with welds.

]=]

-- MODULE
local WeldUtil = {}

--- Create a weld between two parts.
--- @param PreserveCFrames boolean -- If the relative CFrames of both parts should be preserved or not.
function WeldUtil:weldBetween(Part0: BasePart, Part1: BasePart, PreserveCFrames: boolean)

    -- Generate weld between both parts.
    local Weld = Instance.new("Motor6D")
    Weld.Part0 = Part0
    Weld.Part1 = Part1

    -- Preserve relative CFrame.
    if PreserveCFrames then Weld.C1 = Part1.CFrame:ToObjectSpace(Part0.CFrame) end

    -- Name weld so we can easily identify it later.
    Weld.Name = Part1.Name.."_to_"..Part0.Name

    Weld.Parent = Part1

    return Weld
end

--- Weld children of a given model to the MainPart preserving CFrames.
--- Returns array of generated welds for further manipulation.
function WeldUtil:weldChildren(Model: Model, MainPart: BasePart)

    local Welds = {}

    for _,Part in pairs(Model:GetDescendants()) do

        if Part:IsA("BasePart") then

            table.insert(Welds,self:weldBetween(MainPart,Part,true))
        end
    end

    return Welds
end

return WeldUtil